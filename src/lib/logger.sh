#!/bin/zsh
# ===============================================================================
# Professional Logging Module
# ===============================================================================
#
# This module provides a comprehensive logging system for shell scripts with:
# - Multiple log levels (DEBUG, INFO, WARN, ERROR, FATAL)
# - Timestamp support
# - Color-coded output
# - Log file support
# - Structured logging
#
# Usage:
#   source "$(dirname "$0")/lib/logger.sh"
#   log_info "This is an info message"
#   log_error "This is an error message"
#   log_debug "This is a debug message"
#
# ===============================================================================

# Prevent multiple sourcing
if [[ -n "${_LOGGER_SOURCED:-}" ]]; then
    return 0
fi
_LOGGER_SOURCED=1

# ===============================================================================
# Configuration
# ===============================================================================

# Default log level (can be overridden by environment variable)
readonly DEFAULT_LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Log levels in order of severity
readonly LOG_LEVELS=("DEBUG" "INFO" "WARN" "ERROR" "FATAL")

# Colores para diferentes niveles de log (compatibles con Bash 3)
get_log_color() {
    case "$1" in
        DEBUG) echo '\033[0;36m' ;; # Cyan
        INFO)  echo '\033[0;34m' ;; # Blue
        WARN)  echo '\033[0;33m' ;; # Yellow
        ERROR) echo '\033[0;31m' ;; # Red
        FATAL) echo '\033[0;35m' ;; # Magenta
        *)     echo '\033[0m'   ;;
    esac
}

# Iconos para diferentes niveles de log (compatibles con Bash 3)
get_log_icon() {
    case "$1" in
        DEBUG) echo '🔍' ;;
        INFO)  echo 'ℹ️' ;;
        WARN)  echo '⚠️' ;;
        ERROR) echo '❌' ;;
        FATAL) echo '💀' ;;
        *)     echo ''   ;;
    esac
}

# Reset color
readonly COLOR_RESET='\033[0m'

# Error log file configuration
readonly ERROR_LOG_FILE="${ERROR_LOG_FILE:-error.log}"
readonly ERROR_LOG_MAX_SIZE="${ERROR_LOG_MAX_SIZE:-10485760}"  # 10MB default
readonly ERROR_LOG_MAX_FILES="${ERROR_LOG_MAX_FILES:-5}"       # Keep 5 files

# ===============================================================================
# Internal Functions
# ===============================================================================

# Get numeric level for comparison
_log_get_level_num() {
    local level="$1"
    local i=0
    for lvl in $LOG_LEVELS; do
        if [[ "$lvl" == "$level" ]]; then
            echo "$i"
            return 0
        fi
        i=$((i+1))
    done
    echo "1"  # Default to INFO level
}

# Check if a log level should be displayed
_log_should_display() {
    local message_level="$1"
    local current_level_num
    local message_level_num
    
    current_level_num=$(_log_get_level_num "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}")
    message_level_num=$(_log_get_level_num "$message_level")
    
    [[ $message_level_num -ge $current_level_num ]]
}

# Get timestamp
_log_get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get detailed timestamp for error logs
_log_get_detailed_timestamp() {
    date '+%Y-%m-%d %H:%M:%S.%3N'
}

# Format log message
_log_format_message() {
    local level="$1"
    local message="$2"
    local timestamp
    local color
    local icon
    
    timestamp=$(_log_get_timestamp)
    color="$(get_log_color "$level")"
    icon="$(get_log_icon "$level")"
    
    printf "%s %s %s%s%s\n" "$timestamp" "$icon" "$color" "$message" "$COLOR_RESET"
}

# Write to log file if configured
_log_write_to_file() {
    local level="$1"
    local message="$2"
    
    if [[ -n "${LOG_FILE:-}" ]]; then
        local timestamp
        timestamp=$(_log_get_timestamp)
        printf "[%s] %s: %s\n" "$timestamp" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Write error to error log file
_log_write_error_to_file() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    
    # Only log ERROR and FATAL levels to error log
    if [[ "$level" == "ERROR" || "$level" == "FATAL" ]]; then
        local timestamp
        local error_entry
        local script_info
        
        timestamp=$(_log_get_detailed_timestamp)
        script_info="[${SCRIPT_NAME:-unknown}:${BASH_LINENO[1]:-0}]"
        
        # Create error entry with context
        error_entry="[${timestamp}] ${level} ${script_info}: ${message}"
        if [[ -n "$context" ]]; then
            error_entry="${error_entry} | Context: ${context}"
        fi
        
        # Add stack trace for errors
        if [[ "$level" == "ERROR" || "$level" == "FATAL" ]]; then
            error_entry="${error_entry} | Stack: ${FUNCNAME[*]:-unknown}"
        fi
        
        # Write to error log file
        printf "%s\n" "$error_entry" >> "$ERROR_LOG_FILE" 2>/dev/null || true
        
        # Rotate error log if needed
        _log_rotate_error_file
    fi
}

# Rotate error log file if it exceeds max size
_log_rotate_error_file() {
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        local file_size
        file_size=$(stat -f%z "$ERROR_LOG_FILE" 2>/dev/null || stat -c%s "$ERROR_LOG_FILE" 2>/dev/null || echo 0)
        
        if [[ $file_size -gt $ERROR_LOG_MAX_SIZE ]]; then
            local backup_file
            local i
            
            # Remove oldest backup if we have max files
            if [[ -f "${ERROR_LOG_FILE}.${ERROR_LOG_MAX_FILES}" ]]; then
                rm -f "${ERROR_LOG_FILE}.${ERROR_LOG_MAX_FILES}"
            fi
            
            # Shift existing backups
            for ((i=ERROR_LOG_MAX_FILES-1; i>=1; i--)); do
                if [[ -f "${ERROR_LOG_FILE}.${i}" ]]; then
                    mv "${ERROR_LOG_FILE}.${i}" "${ERROR_LOG_FILE}.$((i+1))"
                fi
            done
            
            # Move current file to backup
            mv "$ERROR_LOG_FILE" "${ERROR_LOG_FILE}.1"
            
            # Create new error log file
            touch "$ERROR_LOG_FILE"
            printf "[%s] INFO: Error log rotated\n" "$(_log_get_timestamp)" >> "$ERROR_LOG_FILE"
        fi
    fi
}

# Get error context information
_log_get_error_context() {
    local context=""
    
    # Add current working directory
    context="${context} PWD: $(pwd)"
    
    # Add user information
    context="${context} USER: ${USER:-unknown}"
    
    # Add script information
    if [[ -n "${SCRIPT_NAME:-}" ]]; then
        context="${context} SCRIPT: ${SCRIPT_NAME}"
    fi
    
    # Add command line arguments
    if [[ $# -gt 0 ]]; then
        context="${context} ARGS: $*"
    fi
    
    echo "$context"
}

# ===============================================================================
# Public Logging Functions
# ===============================================================================

# Log a debug message
log_debug() {
    if _log_should_display "DEBUG"; then
        local message="$*"
        _log_format_message "DEBUG" "$message"
        _log_write_to_file "DEBUG" "$message"
    fi
}

# Log an info message
log_info() {
    if _log_should_display "INFO"; then
        local message="$*"
        _log_format_message "INFO" "$message"
        _log_write_to_file "INFO" "$message"
    fi
}

# Log a warning message
log_warn() {
    if _log_should_display "WARN"; then
        local message="$*"
        _log_format_message "WARN" "$message"
        _log_write_to_file "WARN" "$message"
    fi
}

# Log an error message (to stderr)
log_error() {
    if _log_should_display "ERROR"; then
        local message="$*"
        local context
        context=$(_log_get_error_context "$@")
        
        _log_format_message "ERROR" "$message" >&2
        _log_write_to_file "ERROR" "$message"
        _log_write_error_to_file "ERROR" "$message" "$context"
    fi
}

# Log a fatal message and exit
log_fatal() {
    local message="$*"
    local exit_code="${FATAL_EXIT_CODE:-1}"
    local context
    context=$(_log_get_error_context "$@")
    
    _log_format_message "FATAL" "$message" >&2
    _log_write_to_file "FATAL" "$message"
    _log_write_error_to_file "FATAL" "$message" "$context"
    
    exit "$exit_code"
}

# Log success message
log_success() {
    if _log_should_display "INFO"; then
        local message="$*"
        local timestamp
        timestamp=$(_log_get_timestamp)
        printf "%s ✅ %s%s%s\n" "$timestamp" '\033[0;32m' "$message" "$COLOR_RESET"
        _log_write_to_file "INFO" "SUCCESS: $message"
    fi
}

# Log a section header
log_section() {
    if _log_should_display "INFO"; then
        local message="$*"
        local timestamp
        timestamp=$(_log_get_timestamp)
        printf "%s 📋 %s%s%s\n" "$timestamp" '\033[1;34m' "$message" "$COLOR_RESET"
        _log_write_to_file "INFO" "SECTION: $message"
    fi
}

# Log a step in a process
log_step() {
    if _log_should_display "INFO"; then
        local message="$*"
        local timestamp
        timestamp=$(_log_get_timestamp)
        printf "%s ➤ %s%s%s\n" "$timestamp" '\033[0;36m' "$message" "$COLOR_RESET"
        _log_write_to_file "INFO" "STEP: $message"
    fi
}

# ===============================================================================
# Utility Functions
# ===============================================================================

# Set log level
set_log_level() {
    local level="$1"
    local valid_level=false
    
    for valid in "${LOG_LEVELS[@]}"; do
        if [[ "$level" == "$valid" ]]; then
            valid_level=true
            break
        fi
    done
    
    if [[ "$valid_level" == "true" ]]; then
        export LOG_LEVEL="$level"
        log_debug "Log level set to: $level"
    else
        log_error "Invalid log level: $level. Valid levels: ${LOG_LEVELS[*]}"
        return 1
    fi
}

# Set log file
set_log_file() {
    local file="$1"
    
    if [[ -n "$file" ]]; then
        # Create directory if it doesn't exist
        local dir
        dir=$(dirname "$file")
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null || {
                log_error "Cannot create log directory: $dir"
                return 1
            }
        fi
        
        export LOG_FILE="$file"
        log_debug "Log file set to: $file"
    else
        unset LOG_FILE
        log_debug "Log file disabled"
    fi
}

# Get current log level
get_log_level() {
    echo "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
}

# Check if debug logging is enabled
is_debug_enabled() {
    _log_should_display "DEBUG"
}

# ===============================================================================
# Error Log Management Functions
# ===============================================================================

# Initialize error log file
init_error_log() {
    local log_dir
    log_dir=$(dirname "$ERROR_LOG_FILE")
    
    # Create directory if it doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            echo "ERROR: Cannot create error log directory: $log_dir" >&2
            return 1
        }
    fi
    
    # Create error log file if it doesn't exist
    if [[ ! -f "$ERROR_LOG_FILE" ]]; then
        touch "$ERROR_LOG_FILE" 2>/dev/null || {
            echo "ERROR: Cannot create error log file: $ERROR_LOG_FILE" >&2
            return 1
        }
        
        # Add header to new error log file
        printf "[%s] INFO: Error log initialized for %s\n" "$(_log_get_timestamp)" "${SCRIPT_NAME:-unknown script}" >> "$ERROR_LOG_FILE"
        printf "[%s] INFO: Error log file: %s\n" "$(_log_get_timestamp)" "$ERROR_LOG_FILE" >> "$ERROR_LOG_FILE"
        printf "[%s] INFO: Max size: %s bytes, Max files: %s\n" "$(_log_get_timestamp)" "$ERROR_LOG_MAX_SIZE" "$ERROR_LOG_MAX_FILES" >> "$ERROR_LOG_FILE"
        printf "[%s] INFO: ==========================================\n" "$(_log_get_timestamp)" >> "$ERROR_LOG_FILE"
    fi
    
    log_debug "Error log initialized: $ERROR_LOG_FILE"
}

# Get error log file path
get_error_log_path() {
    echo "$ERROR_LOG_FILE"
}

# Show error log statistics
show_error_log_stats() {
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        local total_errors
        local fatal_errors
        local file_size
        local last_error
        
        total_errors=$(grep -c "ERROR\|FATAL" "$ERROR_LOG_FILE" 2>/dev/null || echo 0)
        fatal_errors=$(grep -c "FATAL" "$ERROR_LOG_FILE" 2>/dev/null || echo 0)
        file_size=$(stat -f%z "$ERROR_LOG_FILE" 2>/dev/null || stat -c%s "$ERROR_LOG_FILE" 2>/dev/null || echo 0)
        last_error=$(tail -n 1 "$ERROR_LOG_FILE" 2>/dev/null || echo "No errors logged")
        
        echo "Error Log Statistics:"
        echo "  File: $ERROR_LOG_FILE"
        echo "  Size: $file_size bytes"
        echo "  Total errors: $total_errors"
        echo "  Fatal errors: $fatal_errors"
        echo "  Last error: $last_error"
    else
        echo "Error log file not found: $ERROR_LOG_FILE"
    fi
}

# Clear error log
clear_error_log() {
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        > "$ERROR_LOG_FILE"
        printf "[%s] INFO: Error log cleared\n" "$(_log_get_timestamp)" >> "$ERROR_LOG_FILE"
        log_info "Error log cleared: $ERROR_LOG_FILE"
    else
        log_warn "Error log file not found: $ERROR_LOG_FILE"
    fi
}

# Show recent errors
show_recent_errors() {
    local count="${1:-10}"
    
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        echo "Recent errors (last $count):"
        echo "=========================================="
        tail -n "$count" "$ERROR_LOG_FILE" 2>/dev/null || echo "No errors found"
    else
        echo "Error log file not found: $ERROR_LOG_FILE"
    fi
}

# Search errors by pattern
search_errors() {
    local pattern="$1"
    
    if [[ -z "$pattern" ]]; then
        log_error "Search pattern is required"
        return 1
    fi
    
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        echo "Errors matching pattern '$pattern':"
        echo "=========================================="
        grep -i "$pattern" "$ERROR_LOG_FILE" 2>/dev/null || echo "No matching errors found"
    else
        echo "Error log file not found: $ERROR_LOG_FILE"
    fi
}

# ===============================================================================
# Initialization
# ===============================================================================

# Set default log level if not already set
if [[ -z "${LOG_LEVEL:-}" ]]; then
    export LOG_LEVEL="$DEFAULT_LOG_LEVEL"
fi

# Initialize error log file
init_error_log

# Log module initialization
log_debug "Logger module initialized with level: $LOG_LEVEL" 