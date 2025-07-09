#!/bin/zsh
# ===============================================================================
# Professional Error Handling Module
# ===============================================================================
#
# This module provides comprehensive error handling for shell scripts with:
# - Standardized exit codes
# - Error context tracking
# - Stack traces
# - Error recovery mechanisms
# - Safe execution wrappers
#
# Usage:
#   source "$(dirname "$0")/lib/error_handler.sh"
#   trap 'error_handler' ERR
#   safe_execute "command" "description"
#
# ===============================================================================

# Prevent multiple sourcing
if [[ -n "${_ERROR_HANDLER_SOURCED:-}" ]]; then
    return 0
fi
_ERROR_HANDLER_SOURCED=1

# ===============================================================================
# Configuration
# ===============================================================================

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_INVALID_ARGUMENT=2
readonly EXIT_FILE_NOT_FOUND=3
readonly EXIT_PERMISSION_DENIED=4
readonly EXIT_COMMAND_NOT_FOUND=5
readonly EXIT_NETWORK_ERROR=6
readonly EXIT_TIMEOUT=7
readonly EXIT_INSUFFICIENT_RESOURCES=8
readonly EXIT_CONFIGURATION_ERROR=9
readonly EXIT_DEPENDENCY_ERROR=10
readonly EXIT_VALIDATION_ERROR=11
readonly EXIT_BACKUP_ERROR=12
readonly EXIT_ROLLBACK_ERROR=13

# Error context
ERROR_CONTEXT=""
ERROR_COMMAND=""
ERROR_LINE=""
ERROR_FUNCTION=""

# Error recovery
ERROR_RECOVERY_ENABLED=true
ERROR_RECOVERY_ATTEMPTS=0
readonly MAX_RECOVERY_ATTEMPTS=3

# ===============================================================================
# Internal Functions
# ===============================================================================

# Get error description from exit code
_get_error_description() {
    local exit_code="$1"
    case "$exit_code" in
        $EXIT_SUCCESS) echo "Success" ;;
        $EXIT_GENERAL_ERROR) echo "General error" ;;
        $EXIT_INVALID_ARGUMENT) echo "Invalid argument" ;;
        $EXIT_FILE_NOT_FOUND) echo "File not found" ;;
        $EXIT_PERMISSION_DENIED) echo "Permission denied" ;;
        $EXIT_COMMAND_NOT_FOUND) echo "Command not found" ;;
        $EXIT_NETWORK_ERROR) echo "Network error" ;;
        $EXIT_TIMEOUT) echo "Timeout" ;;
        $EXIT_INSUFFICIENT_RESOURCES) echo "Insufficient resources" ;;
        $EXIT_CONFIGURATION_ERROR) echo "Configuration error" ;;
        $EXIT_DEPENDENCY_ERROR) echo "Dependency error" ;;
        $EXIT_VALIDATION_ERROR) echo "Validation error" ;;
        $EXIT_BACKUP_ERROR) echo "Backup error" ;;
        $EXIT_ROLLBACK_ERROR) echo "Rollback error" ;;
        *) echo "Unknown error" ;;
    esac
}

# Get stack trace
_get_stack_trace() {
    local frame=0
    local stack_trace=""
    
    while caller "$frame" >/dev/null 2>&1; do
        local line_info
        line_info=$(caller "$frame")
        local line_num=$(echo "$line_info" | cut -d' ' -f1)
        local func_name=$(echo "$line_info" | cut -d' ' -f2)
        local script_name=$(echo "$line_info" | cut -d' ' -f3)
        
        stack_trace+="  at $func_name ($script_name:$line_num)\n"
        ((frame++))
    done
    
    echo -e "$stack_trace"
}

# ===============================================================================
# Public Error Handling Functions
# ===============================================================================

# Set error context
set_error_context() {
    ERROR_CONTEXT="$1"
}

# Clear error context
clear_error_context() {
    ERROR_CONTEXT=""
}

# Main error handler (called by trap)
error_handler() {
    local exit_code=$?
    local error_desc
    local stack_trace
    
    # Get error information
    error_desc=$(_get_error_description "$exit_code")
    stack_trace=$(_get_stack_trace)
    
    # Log error details
    log_error "Error occurred (exit code: $exit_code - $error_desc)"
    
    if [[ -n "$ERROR_CONTEXT" ]]; then
        log_error "Context: $ERROR_CONTEXT"
    fi
    
    if [[ -n "$ERROR_COMMAND" ]]; then
        log_error "Command: $ERROR_COMMAND"
    fi
    
    if [[ -n "$ERROR_FUNCTION" ]]; then
        log_error "Function: $ERROR_FUNCTION"
    fi
    
    if [[ -n "$ERROR_LINE" ]]; then
        log_error "Line: $ERROR_LINE"
    fi
    
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        log_debug "Stack trace:\n$stack_trace"
    fi
    
    # Attempt recovery if enabled
    if [[ "$ERROR_RECOVERY_ENABLED" == "true" && $ERROR_RECOVERY_ATTEMPTS -lt $MAX_RECOVERY_ATTEMPTS ]]; then
        ((ERROR_RECOVERY_ATTEMPTS++))
        log_warn "Attempting recovery (attempt $ERROR_RECOVERY_ATTEMPTS/$MAX_RECOVERY_ATTEMPTS)"
        
        if error_recovery_handler; then
            log_success "Recovery successful"
            return 0
        else
            log_error "Recovery failed"
        fi
    fi
    
    # Exit with the original error code
    exit "$exit_code"
}

# Safe execution wrapper
safe_execute() {
    local command="$1"
    local description="${2:-Executing command}"
    local exit_on_error="${3:-true}"
    
    log_step "$description"
    log_debug "Command: $command"
    
    # Set error context
    ERROR_COMMAND="$command"
    ERROR_FUNCTION="${FUNCNAME[1]:-unknown}"
    ERROR_LINE="${BASH_LINENO[0]:-unknown}"
    
    # Execute command
    if eval "$command"; then
        log_success "$description completed"
        return 0
    else
        local exit_code=$?
        log_error "$description failed (exit code: $exit_code)"
        
        if [[ "$exit_on_error" == "true" ]]; then
            exit "$exit_code"
        else
            return "$exit_code"
        fi
    fi
}

# Safe execution with timeout
safe_execute_timeout() {
    local command="$1"
    local timeout="$2"
    local description="${3:-Executing command with timeout}"
    
    log_step "$description (timeout: ${timeout}s)"
    log_debug "Command: $command"
    
    # Set error context
    ERROR_COMMAND="$command"
    ERROR_FUNCTION="${FUNCNAME[1]:-unknown}"
    ERROR_LINE="${BASH_LINENO[0]:-unknown}"
    
    # Execute with timeout
    if timeout "$timeout" bash -c "$command"; then
        log_success "$description completed"
        return 0
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_error "$description timed out after ${timeout}s"
            exit $EXIT_TIMEOUT
        else
            log_error "$description failed (exit code: $exit_code)"
            exit "$exit_code"
        fi
    fi
}

# Validate required command exists
require_command() {
    local command="$1"
    local description="${2:-$command}"
    
    if ! command -v "$command" >/dev/null 2>&1; then
        log_error "Required command not found: $description"
        log_error "Please install $description and try again"
        exit $EXIT_COMMAND_NOT_FOUND
    fi
    
    log_debug "Command found: $command"
}

# Validate required file exists
require_file() {
    local file="$1"
    local description="${2:-$file}"
    
    if [[ ! -f "$file" ]]; then
        log_error "Required file not found: $description"
        exit $EXIT_FILE_NOT_FOUND
    fi
    
    log_debug "File found: $file"
}

# Validate required directory exists
require_directory() {
    local directory="$1"
    local description="${2:-$directory}"
    
    if [[ ! -d "$directory" ]]; then
        log_error "Required directory not found: $description"
        exit $EXIT_FILE_NOT_FOUND
    fi
    
    log_debug "Directory found: $directory"
}

# Validate file is readable
require_readable() {
    local file="$1"
    local description="${2:-$file}"
    
    if [[ ! -r "$file" ]]; then
        log_error "File not readable: $description"
        exit $EXIT_PERMISSION_DENIED
    fi
    
    log_debug "File is readable: $file"
}

# Validate file is writable
require_writable() {
    local file="$1"
    local description="${2:-$file}"
    
    if [[ ! -w "$file" ]]; then
        log_error "File not writable: $description"
        exit $EXIT_PERMISSION_DENIED
    fi
    
    log_debug "File is writable: $file"
}

# ===============================================================================
# Error Recovery
# ===============================================================================

# Default recovery handler (can be overridden)
error_recovery_handler() {
    log_debug "Default recovery handler called"
    return 1  # Default to no recovery
}

# Set custom recovery handler
set_recovery_handler() {
    local handler_function="$1"
    
    if declare -f "$handler_function" >/dev/null 2>&1; then
        error_recovery_handler() {
            "$handler_function"
        }
        log_debug "Recovery handler set to: $handler_function"
    else
        log_error "Recovery handler function not found: $handler_function"
        return 1
    fi
}

# Enable/disable error recovery
set_error_recovery() {
    local enabled="$1"
    
    if [[ "$enabled" == "true" || "$enabled" == "1" ]]; then
        ERROR_RECOVERY_ENABLED=true
        log_debug "Error recovery enabled"
    else
        ERROR_RECOVERY_ENABLED=false
        log_debug "Error recovery disabled"
    fi
}

# Reset recovery attempts
reset_recovery_attempts() {
    ERROR_RECOVERY_ATTEMPTS=0
    log_debug "Recovery attempts reset"
}

# ===============================================================================
# Utility Functions
# ===============================================================================

# Check if last command succeeded
command_succeeded() {
    [[ $? -eq 0 ]]
}

# Check if last command failed
command_failed() {
    [[ $? -ne 0 ]]
}

# Get last exit code
get_last_exit_code() {
    echo $?
}

# Test error handling
test_error_handling() {
    log_info "Testing error handling..."
    
    # Test safe execution
    safe_execute "echo 'test command'" "Test command execution" false
    
    # Test command validation
    require_command "echo" "echo command"
    
    # Test file validation
    require_file "/etc/passwd" "system passwd file"
    
    # Test directory validation
    require_directory "/etc" "system etc directory"
    
    log_success "Error handling tests completed"
}

# ===============================================================================
# Initialization
# ===============================================================================

# Set up error handling
setup_error_handling() {
    # Set up error trap
    trap 'error_handler' ERR
    
    # Set up exit trap for cleanup
    trap 'cleanup_on_exit' EXIT
    
    log_debug "Error handling initialized"
}

# Cleanup function (called on exit)
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_debug "Script completed successfully"
    else
        log_debug "Script exited with code: $exit_code"
    fi
    
    # Clear error context
    clear_error_context
    
    # Reset recovery attempts
    reset_recovery_attempts
}

# Initialize error handling
setup_error_handling 