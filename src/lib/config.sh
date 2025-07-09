#!/bin/zsh
# ===============================================================================
# Professional Configuration Management Module
# ===============================================================================
#
# This module provides comprehensive configuration management for shell scripts with:
# - Default configuration values
# - User configuration overrides
# - Environment variable support
# - Configuration validation
# - Configuration file management
# - Configuration saving and loading
#
# Usage:
#   source "$(dirname "$0")/lib/config.sh"
#   config_init
#   config_set "key" "value"
#   value=$(config_get "key")
#
# ===============================================================================

# Prevent multiple sourcing
if [[ -n "${_CONFIG_SOURCED:-}" ]]; then
    return 0
fi
_CONFIG_SOURCED=1

# ===============================================================================
# Configuration
# ===============================================================================

# Configuration storage
typeset -A CONFIG_VALUES
typeset -A CONFIG_DEFAULTS
typeset -A CONFIG_DESCRIPTIONS
typeset -A CONFIG_TYPES
typeset -A CONFIG_VALIDATORS

# Configuration file paths
readonly CONFIG_DIR="$HOME/.config/zsh-starship-migration"
readonly CONFIG_FILE="$CONFIG_DIR/config.conf"
readonly CONFIG_SCHEMA_FILE="$CONFIG_DIR/schema.conf"

# Configuration types
readonly CONFIG_TYPE_STRING="string"
readonly CONFIG_TYPE_INTEGER="integer"
readonly CONFIG_TYPE_BOOLEAN="boolean"
readonly CONFIG_TYPE_PATH="path"
readonly CONFIG_TYPE_URL="url"
readonly CONFIG_TYPE_EMAIL="email"

# ===============================================================================
# Internal Functions
# ===============================================================================

# Validate configuration value
_validate_config_value() {
    local key="$1"
    local value="$2"
    local type="${CONFIG_TYPES[$key]:-$CONFIG_TYPE_STRING}"
    local validator="${CONFIG_VALIDATORS[$key]}"
    
    # Type validation
    case "$type" in
        "$CONFIG_TYPE_INTEGER")
            if [[ ! "$value" =~ ^[0-9]+$ ]]; then
                log_error "Configuration '$key' must be an integer, got: $value"
                return 1
            fi
            ;;
        "$CONFIG_TYPE_BOOLEAN")
            if [[ ! "$value" =~ ^(true|false|yes|no|1|0)$ ]]; then
                log_error "Configuration '$key' must be a boolean, got: $value"
                return 1
            fi
            ;;
        "$CONFIG_TYPE_PATH")
            if [[ ! -e "$value" ]]; then
                log_warn "Configuration '$key' path does not exist: $value"
            fi
            ;;
        "$CONFIG_TYPE_URL")
            if [[ ! "$value" =~ ^https?:// ]]; then
                log_error "Configuration '$key' must be a valid URL, got: $value"
                return 1
            fi
            ;;
        "$CONFIG_TYPE_EMAIL")
            if [[ ! "$value" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                log_error "Configuration '$key' must be a valid email, got: $value"
                return 1
            fi
            ;;
    esac
    
    # Custom validator
    if [[ -n "$validator" ]] && declare -f "$validator" >/dev/null 2>&1; then
        if ! "$validator" "$value"; then
            log_error "Configuration '$key' failed custom validation"
            return 1
        fi
    fi
    
    return 0
}

# Parse configuration line
_parse_config_line() {
    local line="$1"
    local key
    local value
    
    # Skip comments and empty lines
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
        return 0
    fi
    
    # Parse key=value
    if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Remove leading/trailing whitespace
        key="${key#"${key%%[! ]*}"}"
        key="${key%"${key##*[! ]}"}"
        value="${value#"${value%%[! ]*}"}"
        value="${value%"${value##*[! ]}"}"
        
        # Remove quotes if present
        if [[ "$value" =~ ^\"(.*)\"$ ]]; then
            value="${BASH_REMATCH[1]}"
        elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi
        
        # Set configuration value
        config_set "$key" "$value" false
    fi
}

# ===============================================================================
# Public Configuration Functions
# ===============================================================================

# Initialize configuration system
config_init() {
    log_debug "Initializing configuration system"
    
    # Create configuration directory
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR" || {
            log_error "Cannot create configuration directory: $CONFIG_DIR"
            return 1
        }
    fi
    
    # Load configuration
    config_load
    
    log_debug "Configuration system initialized"
}

# Register a configuration option
config_register() {
    local key="$1"
    local default_value="$2"
    local description="$3"
    local type="${4:-$CONFIG_TYPE_STRING}"
    local validator="${5:-}"
    CONFIG_DEFAULTS["$key"]="$default_value"
    CONFIG_DESCRIPTIONS["$key"]="$description"
    CONFIG_TYPES["$key"]="$type"
    if [[ -n "$validator" ]]; then
        CONFIG_VALIDATORS["$key"]="$validator"
    fi
    if [[ -z "${CONFIG_VALUES[$key]:-}" ]]; then
        CONFIG_VALUES["$key"]="$default_value"
    fi
    log_debug "Registered configuration: $key = $default_value ($type)"
}

# Set configuration value
config_set() {
    local key="$1"
    local value="$2"
    local validate="${3:-true}"
    
    if [[ "$validate" == "true" ]]; then
        if ! _validate_config_value "$key" "$value"; then
            return 1
        fi
    fi
    
    CONFIG_VALUES["$key"]="$value"
    log_debug "Configuration set: $key = $value"
}

# Get configuration value
config_get() {
    local key="$1"
    local default_value="$2"
    
    if [[ -n "${CONFIG_VALUES[$key]:-}" ]]; then
        echo "${CONFIG_VALUES[$key]}"
    elif [[ -n "$default_value" ]]; then
        echo "$default_value"
    else
        echo "${CONFIG_DEFAULTS[$key]:-}"
    fi
}

# Check if configuration exists
config_exists() {
    local key="$1"
    [[ -n "${CONFIG_VALUES[$key]:-}" ]]
}

# Get configuration type
config_get_type() {
    local key="$1"
    echo "${CONFIG_TYPES[$key]:-$CONFIG_TYPE_STRING}"
}

# Get configuration description
config_get_description() {
    local key="$1"
    echo "${CONFIG_DESCRIPTIONS[$key]:-}"
}

# Get all configuration keys
config_get_keys() {
    local keys=()
    for key in "${!CONFIG_VALUES[@]}"; do
        keys+=("$key")
    done
    printf '%s\n' "${keys[@]}" | sort
}

# Get all configuration values
config_get_all() {
    local key
    for key in $(config_get_keys); do
        echo "$key=$(config_get "$key")"
    done
}

# Reset configuration to defaults
config_reset() {
    local key="$1"
    
    if [[ -n "$key" ]]; then
        if [[ -n "${CONFIG_DEFAULTS[$key]:-}" ]]; then
            CONFIG_VALUES["$key"]="${CONFIG_DEFAULTS[$key]}"
            log_debug "Reset configuration: $key = ${CONFIG_DEFAULTS[$key]}"
        else
            log_warn "No default value for configuration: $key"
        fi
    else
        # Reset all configurations
        for key in "${!CONFIG_DEFAULTS[@]}"; do
            CONFIG_VALUES["$key"]="${CONFIG_DEFAULTS[$key]}"
        done
        log_debug "Reset all configurations to defaults"
    fi
}

# ===============================================================================
# Configuration File Management
# ===============================================================================

# Load configuration from file
config_load() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_debug "Loading configuration from: $CONFIG_FILE"
        
        local line
        while IFS= read -r line; do
            _parse_config_line "$line"
        done < "$CONFIG_FILE"
        
        log_debug "Configuration loaded from file"
    else
        log_debug "No configuration file found, using defaults"
    fi
}

# Save configuration to file
config_save() {
    log_debug "Saving configuration to: $CONFIG_FILE"
    
    # Create backup of existing file
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup" 2>/dev/null || true
    fi
    
    # Write configuration file
    {
        echo "# Zsh Starship Migration Configuration"
        echo "# Generated on $(date)"
        echo "#"
        echo "# Format: key=value"
        echo "# Lines starting with # are comments"
        echo ""
        
        local key
        for key in $(config_get_keys); do
            local value
            value=$(config_get "$key")
            local description
            description=$(config_get_description "$key")
            
            if [[ -n "$description" ]]; then
                echo "# $description"
            fi
            echo "$key=$value"
            echo ""
        done
    } > "$CONFIG_FILE"
    
    log_debug "Configuration saved to file"
}

# Export configuration to environment variables
config_export() {
    local prefix="${1:-CONFIG_}"
    local key
    local value
    
    for key in $(config_get_keys); do
        value=$(config_get "$key")
        export "${prefix}${key^^}"="$value"
        log_debug "Exported configuration: ${prefix}${key^^}=$value"
    done
}

# Import configuration from environment variables
config_import() {
    local prefix="${1:-CONFIG_}"
    local key
    local env_var
    local value
    
    for key in $(config_get_keys); do
        env_var="${prefix}${key^^}"
        if [[ -n "${!env_var:-}" ]]; then
            value="${!env_var}"
            config_set "$key" "$value"
            log_debug "Imported configuration from environment: $env_var=$value"
        fi
    done
}

# ===============================================================================
# Configuration Validation
# ===============================================================================

# Validate all configurations
config_validate() {
    log_debug "Validating all configurations"
    
    local errors=0
    local key
    
    for key in $(config_get_keys); do
        local value
        value=$(config_get "$key")
        
        if ! _validate_config_value "$key" "$value"; then
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_debug "All configurations are valid"
        return 0
    else
        log_error "Configuration validation failed with $errors error(s)"
        return 1
    fi
}

# Validate specific configuration
config_validate_key() {
    local key="$1"
    local value
    
    value=$(config_get "$key")
    _validate_config_value "$key" "$value"
}

# ===============================================================================
# Configuration Schema
# ===============================================================================

# Generate configuration schema
config_generate_schema() {
    log_debug "Generating configuration schema"
    
    {
        echo "# Zsh Starship Migration Configuration Schema"
        echo "# Generated on $(date)"
        echo "#"
        echo "# This file describes the configuration options available"
        echo "# Format: key=default_value # description (type)"
        echo ""
        
        local key
        for key in $(config_get_keys); do
            local default_value
            default_value="${CONFIG_DEFAULTS[$key]:-}"
            local description
            description=$(config_get_description "$key")
            local type
            type=$(config_get_type "$key")
            
            if [[ -n "$description" ]]; then
                echo "# $description"
            fi
            echo "$key=$default_value # ($type)"
            echo ""
        done
    } > "$CONFIG_SCHEMA_FILE"
    
    log_debug "Configuration schema generated: $CONFIG_SCHEMA_FILE"
}

# ===============================================================================
# Configuration Display
# ===============================================================================

# Show configuration
config_show() {
    local key="$1"
    
    if [[ -n "$key" ]]; then
        # Show specific configuration
        if config_exists "$key"; then
            local value
            value=$(config_get "$key")
            local description
            description=$(config_get_description "$key")
            local type
            type=$(config_get_type "$key")
            
            echo "Configuration: $key"
            echo "  Value: $value"
            echo "  Type: $type"
            if [[ -n "$description" ]]; then
                echo "  Description: $description"
            fi
        else
            log_error "Configuration not found: $key"
            return 1
        fi
    else
        # Show all configurations
        echo "Configuration:"
        echo "=============="
        
        local key
        for key in $(config_get_keys); do
            local value
            value=$(config_get "$key")
            local description
            description=$(config_get_description "$key")
            local type
            type=$(config_get_type "$key")
            
            echo "$key=$value ($type)"
            if [[ -n "$description" ]]; then
                echo "  $description"
            fi
            echo ""
        done
    fi
}

# ===============================================================================
# Utility Functions
# ===============================================================================

# Test configuration system
config_test() {
    log_info "Testing configuration system..."
    
    # Register test configurations
    config_register "test_string" "default" "Test string configuration" "string"
    config_register "test_integer" "42" "Test integer configuration" "integer"
    config_register "test_boolean" "true" "Test boolean configuration" "boolean"
    
    # Test setting and getting values
    config_set "test_string" "custom_value"
    local value
    value=$(config_get "test_string")
    
    if [[ "$value" == "custom_value" ]]; then
        log_success "Configuration set/get test passed"
    else
        log_error "Configuration set/get test failed"
        return 1
    fi
    
    # Test validation
    if config_validate_key "test_integer" "123"; then
        log_success "Integer validation test passed"
    else
        log_error "Integer validation test failed"
        return 1
    fi
    
    if ! config_validate_key "test_integer" "not_a_number"; then
        log_success "Integer validation error test passed"
    else
        log_error "Integer validation error test failed"
        return 1
    fi
    
    log_success "Configuration system tests completed"
}

# ===============================================================================
# Initialization
# ===============================================================================

# Auto-initialize if not already done
if [[ -z "${CONFIG_INITIALIZED:-}" ]]; then
    config_init
    CONFIG_INITIALIZED=1
fi 