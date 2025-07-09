#!/bin/zsh
# ===============================================================================
# Professional Backup Manager Module
# ===============================================================================
#
# This module provides comprehensive backup management for the migration script:
# - Safe backup creation with metadata
# - Backup listing and information
# - Backup restoration and rollback
# - Backup cleanup and maintenance
# - Backup validation and integrity checks
#
# Usage:
#   source "$(dirname "$0")/modules/backup_manager.sh"
#   create_backup "migration_backup"
#   list_backups
#   restore_backup "backup_name"
#
# ===============================================================================

# Prevent multiple sourcing
if [[ -n "${_BACKUP_MANAGER_SOURCED:-}" ]]; then
    return 0
fi
_BACKUP_MANAGER_SOURCED=1

# ===============================================================================
# Configuration
# ===============================================================================

# Backup configuration
readonly BACKUP_BASE_DIR="$HOME/.config/zsh-starship-migration/backups"
readonly BACKUP_METADATA_FILE="backup_metadata.json"
readonly BACKUP_MANIFEST_FILE="backup_manifest.txt"
readonly MAX_BACKUPS=10
readonly BACKUP_RETENTION_DAYS=30

# Files and directories to backup
readonly BACKUP_ITEMS=(
    "$HOME/.zshrc"
    "$HOME/.oh-my-zsh"
    "$HOME/.config/starship.toml"
    "$HOME/.zsh_history"
    "$HOME/.zsh_sessions"
)

# ===============================================================================
# Internal Functions
# ===============================================================================

# Generate backup timestamp
_generate_backup_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Generate backup ID
_generate_backup_id() {
    local prefix="$1"
    local timestamp
    timestamp=$(_generate_backup_timestamp)
    echo "${prefix}_${timestamp}"
}

# Create backup metadata
_create_backup_metadata() {
    local backup_dir="$1"
    local backup_name="$2"
    local description="$3"
    
    local metadata_file="$backup_dir/$BACKUP_METADATA_FILE"
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    
    cat > "$metadata_file" <<EOF
{
    "backup_name": "$backup_name",
    "description": "$description",
    "created_at": "$timestamp",
    "created_by": "$(whoami)",
    "hostname": "$(hostname)",
    "os_version": "$(sw_vers -productVersion 2>/dev/null || echo "unknown")",
    "zsh_version": "$(zsh --version 2>/dev/null | head -n1 || echo "unknown")",
    "oh_my_zsh_version": "$(grep -E '^ZSH_VERSION=' "$HOME/.oh-my-zsh/tools/check_for_upgrade.sh" 2>/dev/null | cut -d'"' -f2 || echo "unknown")",
    "backup_size": "$(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo "unknown")",
    "items_backed_up": $(ls -1 "$backup_dir" | grep -v "$BACKUP_METADATA_FILE" | grep -v "$BACKUP_MANIFEST_FILE" | wc -l)
}
EOF
}

# Create backup manifest
_create_backup_manifest() {
    local backup_dir="$1"
    local manifest_file="$backup_dir/$BACKUP_MANIFEST_FILE"
    
    {
        echo "# Backup Manifest"
        echo "# Generated on: $(date)"
        echo "#"
        
        local item
        for item in "${BACKUP_ITEMS[@]}"; do
            if [[ -e "$item" ]]; then
                local item_type
                if [[ -f "$item" ]]; then
                    item_type="file"
                elif [[ -d "$item" ]]; then
                    item_type="directory"
                else
                    item_type="other"
                fi
                
                local item_size
                item_size=$(du -sh "$item" 2>/dev/null | cut -f1 || echo "unknown")
                
                echo "$item_type|$item|$item_size|$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$item" 2>/dev/null || echo "unknown")"
            fi
        done
    } > "$manifest_file"
}

# Validate backup integrity
_validate_backup_integrity() {
    local backup_dir="$1"
    
    # Check if backup directory exists
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory does not exist: $backup_dir"
        return 1
    fi
    
    # Check if metadata file exists
    if [[ ! -f "$backup_dir/$BACKUP_METADATA_FILE" ]]; then
        log_error "Backup metadata file missing: $backup_dir/$BACKUP_METADATA_FILE"
        return 1
    fi
    
    # Check if manifest file exists
    if [[ ! -f "$backup_dir/$BACKUP_MANIFEST_FILE" ]]; then
        log_error "Backup manifest file missing: $backup_dir/$BACKUP_MANIFEST_FILE"
        return 1
    fi
    
    # Validate JSON metadata
    if ! python3 -m json.tool "$backup_dir/$BACKUP_METADATA_FILE" >/dev/null 2>&1; then
        log_error "Backup metadata file is not valid JSON"
        return 1
    fi
    
    return 0
}

# Get backup metadata
_get_backup_metadata() {
    local backup_dir="$1"
    local metadata_file="$backup_dir/$BACKUP_METADATA_FILE"
    
    if [[ -f "$metadata_file" ]]; then
        python3 -c "
import json
import sys
try:
    with open('$metadata_file', 'r') as f:
        data = json.load(f)
    print(json.dumps(data, indent=2))
except Exception as e:
    print(f'Error reading metadata: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
    else
        return 1
    fi
}

# ===============================================================================
# Public Backup Functions
# ===============================================================================

# Initialize backup system
backup_init() {
    log_debug "Initializing backup system"
    
    # Create backup directory
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        mkdir -p "$BACKUP_BASE_DIR" || {
            log_error "Cannot create backup directory: $BACKUP_BASE_DIR"
            return 1
        }
    fi
    
    log_debug "Backup system initialized"
}

# Create a new backup
create_backup() {
    local backup_name="$1"
    local description="${2:-Automatic backup}"
    local dry_run="${3:-false}"
    
    log_section "Creating Backup: $backup_name"
    
    # Generate backup ID
    local backup_id
    backup_id=$(_generate_backup_id "$backup_name")
    local backup_dir="$BACKUP_BASE_DIR/$backup_id"
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "[DRY-RUN] Would create backup: $backup_dir"
        log_warn "[DRY-RUN] Description: $description"
        return 0
    fi
    
    # Create backup directory
    if ! mkdir -p "$backup_dir"; then
        log_error "Cannot create backup directory: $backup_dir"
        return $EXIT_BACKUP_ERROR
    fi
    
    log_step "Creating backup directory: $backup_dir"
    
    # Backup items
    local backed_up_count=0
    local skipped_count=0
    
    for item in "${BACKUP_ITEMS[@]}"; do
        if [[ -e "$item" ]]; then
            local item_name
            item_name=$(basename "$item")
            
            if [[ -f "$item" ]]; then
                # Backup file
                if cp "$item" "$backup_dir/"; then
                    log_success "Backed up file: $item"
                    ((backed_up_count++))
                else
                    log_error "Failed to backup file: $item"
                fi
            elif [[ -d "$item" ]]; then
                # Backup directory
                if cp -R "$item" "$backup_dir/"; then
                    log_success "Backed up directory: $item"
                    ((backed_up_count++))
                else
                    log_error "Failed to backup directory: $item"
                fi
            fi
        else
            log_debug "Skipped non-existent item: $item"
            ((skipped_count++))
        fi
    done
    
    # Create metadata and manifest
    _create_backup_metadata "$backup_dir" "$backup_name" "$description"
    _create_backup_manifest "$backup_dir"
    
    # Validate backup
    if _validate_backup_integrity "$backup_dir"; then
        log_success "Backup created successfully: $backup_id"
        log_info "Backed up $backed_up_count items, skipped $skipped_count items"
        log_info "Backup location: $backup_dir"
        
        # Export backup path for other modules
        export CURRENT_BACKUP_PATH="$backup_dir"
        export CURRENT_BACKUP_ID="$backup_id"
        
        return 0
    else
        log_error "Backup validation failed"
        return $EXIT_BACKUP_ERROR
    fi
}

# List all backups
list_backups() {
    log_section "Available Backups"
    
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        log_warn "No backup directory found: $BACKUP_BASE_DIR"
        return 0
    fi
    
    local backups=()
    local backup_dir
    
    # Find all backup directories
    while IFS= read -r -d '' backup_dir; do
        if [[ -f "$backup_dir/$BACKUP_METADATA_FILE" ]]; then
            backups+=("$backup_dir")
        fi
    done < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "*_*" -print0 2>/dev/null | sort -z)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_info "No backups found"
        return 0
    fi
    
    # Display backup information
    printf "%-30s %-20s %-15s %-10s\n" "Backup ID" "Created" "Size" "Items"
    printf "%-30s %-20s %-15s %-10s\n" "---------" "-------" "----" "-----"
    
    for backup_dir in "${backups[@]}"; do
        local backup_id
        backup_id=$(basename "$backup_dir")
        
        local metadata
        metadata=$(_get_backup_metadata "$backup_dir")
        
        if [[ $? -eq 0 ]]; then
            local created_at
            created_at=$(echo "$metadata" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('created_at', 'unknown'))" 2>/dev/null)
            
            local backup_size
            backup_size=$(echo "$metadata" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('backup_size', 'unknown'))" 2>/dev/null)
            
            local items_count
            items_count=$(echo "$metadata" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('items_backed_up', 'unknown'))" 2>/dev/null)
            
            printf "%-30s %-20s %-15s %-10s\n" "$backup_id" "$created_at" "$backup_size" "$items_count"
        else
            printf "%-30s %-20s %-15s %-10s\n" "$backup_id" "invalid" "unknown" "unknown"
        fi
    done
}

# Show backup information
show_backup_info() {
    local backup_id="$1"
    
    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID is required"
        return 1
    fi
    
    local backup_dir="$BACKUP_BASE_DIR/$backup_id"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi
    
    log_section "Backup Information: $backup_id"
    
    # Show metadata
    local metadata
    metadata=$(_get_backup_metadata "$backup_dir")
    
    if [[ $? -eq 0 ]]; then
        echo "$metadata"
    else
        log_error "Cannot read backup metadata"
        return 1
    fi
    
    # Show manifest
    local manifest_file="$backup_dir/$BACKUP_MANIFEST_FILE"
    if [[ -f "$manifest_file" ]]; then
        echo ""
        echo "Backup Contents:"
        echo "================"
        cat "$manifest_file"
    fi
}

# Restore from backup
restore_backup() {
    local backup_id="$1"
    local dry_run="${2:-false}"
    
    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID is required"
        return 1
    fi
    
    local backup_dir="$BACKUP_BASE_DIR/$backup_id"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi
    
    log_section "Restoring from Backup: $backup_id"
    
    # Validate backup integrity
    if ! _validate_backup_integrity "$backup_dir"; then
        log_error "Backup integrity validation failed"
        return $EXIT_BACKUP_ERROR
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "[DRY-RUN] Would restore from backup: $backup_id"
        return 0
    fi
    
    # Create a backup before restoring (safety measure)
    log_step "Creating safety backup before restoration"
    if ! create_backup "pre_restore_safety" "Safety backup before restoring $backup_id"; then
        log_error "Failed to create safety backup"
        return $EXIT_BACKUP_ERROR
    fi
    
    # Restore items
    local restored_count=0
    local failed_count=0
    
    for item in "${BACKUP_ITEMS[@]}"; do
        local item_name
        item_name=$(basename "$item")
        local backup_item="$backup_dir/$item_name"
        
        if [[ -e "$backup_item" ]]; then
            # Create parent directory if needed
            local parent_dir
            parent_dir=$(dirname "$item")
            if [[ ! -d "$parent_dir" ]]; then
                mkdir -p "$parent_dir" || {
                    log_error "Cannot create parent directory: $parent_dir"
                    ((failed_count++))
                    continue
                }
            fi
            
            # Restore item
            if [[ -f "$backup_item" ]]; then
                if cp "$backup_item" "$item"; then
                    log_success "Restored file: $item"
                    ((restored_count++))
                else
                    log_error "Failed to restore file: $item"
                    ((failed_count++))
                fi
            elif [[ -d "$backup_item" ]]; then
                if cp -R "$backup_item" "$(dirname "$item")/"; then
                    log_success "Restored directory: $item"
                    ((restored_count++))
                else
                    log_error "Failed to restore directory: $item"
                    ((failed_count++))
                fi
            fi
        else
            log_debug "Backup item not found: $backup_item"
        fi
    done
    
    log_success "Restoration completed: $restored_count items restored, $failed_count failed"
    return 0
}

# Delete backup
delete_backup() {
    local backup_id="$1"
    local force="${2:-false}"
    
    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID is required"
        return 1
    fi
    
    local backup_dir="$BACKUP_BASE_DIR/$backup_id"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi
    
    log_section "Deleting Backup: $backup_id"
    
    # Confirm deletion unless forced
    if [[ "$force" != "true" ]]; then
        log_warn "This will permanently delete the backup: $backup_id"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Backup deletion cancelled"
            return 0
        fi
    fi
    
    # Delete backup directory
    if rm -rf "$backup_dir"; then
        log_success "Backup deleted: $backup_id"
        return 0
    else
        log_error "Failed to delete backup: $backup_id"
        return $EXIT_BACKUP_ERROR
    fi
}

# Clean up old backups
cleanup_old_backups() {
    local max_age_days="${1:-$BACKUP_RETENTION_DAYS}"
    local dry_run="${2:-false}"
    
    log_section "Cleaning Up Old Backups"
    
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        log_info "No backup directory found"
        return 0
    fi
    
    local current_time
    current_time=$(date +%s)
    local max_age_seconds=$((max_age_days * 24 * 60 * 60))
    local deleted_count=0
    
    # Find old backups
    while IFS= read -r -d '' backup_dir; do
        if [[ -f "$backup_dir/$BACKUP_METADATA_FILE" ]]; then
            local backup_time
            backup_time=$(stat -f "%m" "$backup_dir" 2>/dev/null || echo "0")
            local age_seconds=$((current_time - backup_time))
            
            if [[ $age_seconds -gt $max_age_seconds ]]; then
                local backup_id
                backup_id=$(basename "$backup_dir")
                
                if [[ "$dry_run" == "true" ]]; then
                    log_warn "[DRY-RUN] Would delete old backup: $backup_id (age: $((age_seconds / 86400)) days)"
                else
                    if rm -rf "$backup_dir"; then
                        log_success "Deleted old backup: $backup_id (age: $((age_seconds / 86400)) days)"
                        ((deleted_count++))
                    else
                        log_error "Failed to delete old backup: $backup_id"
                    fi
                fi
            fi
        fi
    done < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "*_*" -print0 2>/dev/null)
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Cleanup simulation completed"
    else
        log_success "Cleanup completed: $deleted_count backups deleted"
    fi
}

# Validate all backups
validate_all_backups() {
    log_section "Validating All Backups"
    
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        log_info "No backup directory found"
        return 0
    fi
    
    local valid_count=0
    local invalid_count=0
    
    while IFS= read -r -d '' backup_dir; do
        if [[ -f "$backup_dir/$BACKUP_METADATA_FILE" ]]; then
            local backup_id
            backup_id=$(basename "$backup_dir")
            
            if _validate_backup_integrity "$backup_dir"; then
                log_success "Backup valid: $backup_id"
                ((valid_count++))
            else
                log_error "Backup invalid: $backup_id"
                ((invalid_count++))
            fi
        fi
    done < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "*_*" -print0 2>/dev/null)
    
    log_info "Validation completed: $valid_count valid, $invalid_count invalid"
    
    if [[ $invalid_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# ===============================================================================
# Utility Functions
# ===============================================================================

# Get backup statistics
get_backup_stats() {
    log_section "Backup Statistics"
    
    if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
        log_info "No backup directory found"
        return 0
    fi
    
    local total_backups=0
    local total_size=0
    local oldest_backup=""
    local newest_backup=""
    
    while IFS= read -r -d '' backup_dir; do
        if [[ -f "$backup_dir/$BACKUP_METADATA_FILE" ]]; then
            ((total_backups++))
            
            local backup_size
            backup_size=$(du -sk "$backup_dir" 2>/dev/null | cut -f1 || echo "0")
            total_size=$((total_size + backup_size))
            
            local backup_id
            backup_id=$(basename "$backup_dir")
            
            if [[ -z "$oldest_backup" ]]; then
                oldest_backup="$backup_id"
            fi
            newest_backup="$backup_id"
        fi
    done < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "*_*" -print0 2>/dev/null | sort -z)
    
    echo "Total backups: $total_backups"
    echo "Total size: $((total_size / 1024))MB"
    echo "Oldest backup: $oldest_backup"
    echo "Newest backup: $newest_backup"
}

# Test backup system
test_backup_system() {
    log_info "Testing backup system..."
    
    # Test backup creation
    if create_backup "test_backup" "Test backup for validation" true; then
        log_success "Backup creation test passed"
    else
        log_error "Backup creation test failed"
        return 1
    fi
    
    # Test backup listing
    if list_backups; then
        log_success "Backup listing test passed"
    else
        log_error "Backup listing test failed"
        return 1
    fi
    
    log_success "Backup system tests completed"
}

# ===============================================================================
# Initialization
# ===============================================================================

# Auto-initialize backup system
backup_init 