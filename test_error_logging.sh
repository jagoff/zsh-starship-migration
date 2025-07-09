#!/bin/bash
# ===============================================================================
# Error Logging Test Script
# ===============================================================================
#
# This script demonstrates the error logging functionality by generating
# various types of errors and showing how they are captured in the error.log file.
#
# Usage:
#   ./test_error_logging.sh
#
# ===============================================================================

# Script metadata
readonly SCRIPT_NAME="test_error_logging"
readonly SCRIPT_VERSION="1.0.0"

# Load the logger module
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/src/lib/logger.sh"

# ===============================================================================
# Test Functions
# ===============================================================================

# Test basic error logging
test_basic_errors() {
    log_section "Testing Basic Error Logging"
    
    log_error "This is a test error message"
    log_error "Another test error with context"
    log_fatal "This is a fatal error that will exit the script"
}

# Test error with context
test_error_with_context() {
    log_section "Testing Error with Context"
    
    # Simulate an error in a function
    test_function() {
        log_error "Error occurred in test_function"
    }
    
    test_function
}

# Test error in different scenarios
test_error_scenarios() {
    log_section "Testing Error Scenarios"
    
    # Test error in a subshell
    (log_error "Error in subshell")
    
    # Test error with special characters
    log_error "Error with special chars: @#$%^&*()"
    
    # Test error with newlines
    log_error "Error with\nnewlines\nin message"
    
    # Test error with quotes
    log_error "Error with 'single' and \"double\" quotes"
}

# Test error log management functions
test_error_log_management() {
    log_section "Testing Error Log Management"
    
    echo "Error log path: $(get_error_log_path)"
    echo ""
    
    echo "Error log statistics:"
    show_error_log_stats
    echo ""
    
    echo "Recent errors (last 5):"
    show_recent_errors 5
    echo ""
    
    echo "Searching for 'test' errors:"
    search_errors "test"
    echo ""
}

# ===============================================================================
# Main Execution
# ===============================================================================

main() {
    log_section "Error Logging Test Script"
    log_info "This script will generate various errors to test the error logging system"
    echo ""
    
    # Test error log management first
    test_error_log_management
    
    # Test basic errors
    test_basic_errors
    
    # Test error with context
    test_error_with_context
    
    # Test error scenarios
    test_error_scenarios
    
    log_success "Error logging tests completed"
    echo ""
    log_info "Check the error.log file to see all captured errors"
    echo "Error log file: $(get_error_log_path)"
}

# Only run main if script is executed directly
if [[ "$0" == "$ZSH_NAME" || "$0" == "$0" ]]; then
    main "$@"
fi 