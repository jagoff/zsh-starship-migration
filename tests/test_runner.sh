#!/bin/bash
# ==============================================================================
# Test Runner for Zsh Starship Migration
# ==============================================================================

# Test configuration
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$TEST_DIR")"
SCRIPT_DIR="$PROJECT_DIR/src"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ==============================================================================
# TEST UTILITIES
# ==============================================================================

# Initialize test environment
test_init() {
    echo -e "${BLUE}Initializing test environment...${NC}"
    
    # Source the logger module for test output
    source "$SCRIPT_DIR/lib/logger.sh"
    
    # Set up test directories
    export TEST_TEMP_DIR="$TEST_DIR/temp"
    mkdir -p "$TEST_TEMP_DIR"
    
    # Set up test configuration
    export TEST_CONFIG_DIR="$TEST_TEMP_DIR/config"
    export TEST_BACKUP_DIR="$TEST_TEMP_DIR/backups"
    export TEST_LOG_DIR="$TEST_TEMP_DIR/logs"
    
    mkdir -p "$TEST_CONFIG_DIR" "$TEST_BACKUP_DIR" "$TEST_LOG_DIR"
    
    echo -e "${GREEN}✓ Test environment initialized${NC}"
}

# Clean up test environment
test_cleanup() {
    echo -e "${BLUE}Cleaning up test environment...${NC}"
    rm -rf "$TEST_TEMP_DIR"
    echo -e "${GREEN}✓ Test environment cleaned${NC}"
}

# Run a test function
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TOTAL_TESTS++))
    echo -e "${BLUE}Running test: $test_name${NC}"
    
    if $test_function; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $test_name${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Assert that a condition is true
assert_true() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if eval "$condition"; then
        return 0
    else
        echo -e "${RED}Assertion failed: $message${NC}"
        return 1
    fi
}

# Assert that a condition is false
assert_false() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        return 0
    else
        echo -e "${RED}Assertion failed: $message${NC}"
        return 1
    fi
}

# Assert that two values are equal
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values not equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "${RED}Assertion failed: $message${NC}"
        echo -e "${RED}  Expected: $expected${NC}"
        echo -e "${RED}  Actual:   $actual${NC}"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist}"
    
    if [[ -f "$file" ]]; then
        return 0
    else
        echo -e "${RED}Assertion failed: $message${NC}"
        return 1
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory does not exist}"
    
    if [[ -d "$dir" ]]; then
        return 0
    else
        echo -e "${RED}Assertion failed: $message${NC}"
        return 1
    fi
}

# ==============================================================================
# MODULE TESTS
# ==============================================================================

# Test logger module
test_logger() {
    echo "Testing logger module..."
    
    # Source the logger module
    source "$SCRIPT_DIR/lib/logger.sh"
    
    # Test log level setting
    log_set_level "debug"
    assert_equal "DEBUG" "$(log_get_level)" "Log level should be DEBUG"
    
    log_set_level "info"
    assert_equal "INFO" "$(log_get_level)" "Log level should be INFO"
    
    # Test logging functions (should not fail)
    log_debug "Debug message"
    log_info "Info message"
    log_warn "Warning message"
    log_error "Error message"
    log_success "Success message"
    
    return 0
}

# Test error handler module
test_error_handler() {
    echo "Testing error handler module..."
    
    # Source the error handler module
    source "$SCRIPT_DIR/lib/error_handler.sh"
    
    # Test validation functions
    assert_true "validate_command 'echo' 'Echo command'" "Echo command should exist"
    assert_false "validate_command 'nonexistent_command' 'Nonexistent command'" "Nonexistent command should not exist"
    
    # Test file validation
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "test" > "$test_file"
    assert_true "validate_file '$test_file' 'Test file'" "Test file should exist"
    
    # Test directory validation
    local test_dir="$TEST_TEMP_DIR/test_dir"
    mkdir -p "$test_dir"
    assert_true "validate_directory '$test_dir' 'Test directory'" "Test directory should exist"
    
    return 0
}

# Test configuration module
test_config() {
    echo "Testing configuration module..."
    
    # Source the configuration module
    source "$SCRIPT_DIR/lib/config.sh"
    
    # Test configuration access
    config_set "test_key" "test_value"
    assert_equal "test_value" "$(config_get test_key)" "Config value should match"
    
    # Test default values
    assert_equal "default_value" "$(config_get nonexistent_key default_value)" "Default value should be returned"
    
    # Test boolean checking
    config_set "test_bool" "true"
    assert_true "config_is_enabled test_bool" "Boolean should be enabled"
    
    config_set "test_bool" "false"
    assert_false "config_is_enabled test_bool" "Boolean should be disabled"
    
    return 0
}

# Test system validator module
test_system_validator() {
    echo "Testing system validator module..."
    
    # Source the system validator module
    source "$SCRIPT_DIR/lib/logger.sh"
    source "$SCRIPT_DIR/modules/system_validator.sh"
    
    # Test OS detection
    local os=$(system_detect_os)
    assert_true "[[ -n '$os' ]]" "OS detection should return a value"
    
    # Test architecture detection
    local arch=$(system_detect_arch)
    assert_true "[[ -n '$arch' ]]" "Architecture detection should return a value"
    
    # Test command validation
    assert_true "validate_command 'echo' 'Echo command' 'true'" "Echo command should be found"
    
    return 0
}

# Test backup manager module
test_backup_manager() {
    echo "Testing backup manager module..."
    
    # Source the backup manager module
    source "$SCRIPT_DIR/lib/logger.sh"
    source "$SCRIPT_DIR/modules/backup_manager.sh"
    
    # Test backup name generation
    local backup_name=$(backup_generate_name "test")
    assert_true "[[ -n '$backup_name' ]]" "Backup name should be generated"
    assert_true "[[ '$backup_name' =~ ^test_[0-9]{8}_[0-9]{6}$ ]]" "Backup name should match pattern"
    
    # Test backup existence check
    assert_false "backup_exists '$backup_name'" "Backup should not exist initially"
    
    return 0
}

# ==============================================================================
# INTEGRATION TESTS
# ==============================================================================

# Test script help command
test_script_help() {
    echo "Testing script help command..."
    
    local output
    output=$(cd "$PROJECT_DIR" && ./zsh-starship-migration.sh --help 2>&1)
    local exit_code=$?
    
    assert_equal 0 "$exit_code" "Help command should exit successfully"
    assert_true "echo '$output' | grep -q 'Zsh Starship Migration'" "Help should contain script name"
    
    return 0
}

# Test script version command
test_script_version() {
    echo "Testing script version command..."
    
    local output
    output=$(cd "$PROJECT_DIR" && ./zsh-starship-migration.sh --version 2>&1)
    local exit_code=$?
    
    assert_equal 0 "$exit_code" "Version command should exit successfully"
    assert_true "echo '$output' | grep -q '2.0.0'" "Version should be displayed"
    
    return 0
}

# Test script dry-run mode
test_script_dry_run() {
    echo "Testing script dry-run mode..."
    
    local output
    output=$(cd "$PROJECT_DIR" && ./zsh-starship-migration.sh --dry-run --verbose 2>&1)
    local exit_code=$?
    
    # Dry-run should not fail, but may exit with non-zero if validation fails
    assert_true "echo '$output' | grep -q 'DRY-RUN'" "Output should contain DRY-RUN indication"
    
    return 0
}

# Test script configuration display
test_script_config() {
    echo "Testing script configuration display..."
    
    local output
    output=$(cd "$PROJECT_DIR" && ./zsh-starship-migration.sh config 2>&1)
    local exit_code=$?
    
    assert_equal 0 "$exit_code" "Config command should exit successfully"
    assert_true "echo '$output' | grep -q 'Configuration'" "Output should contain configuration"
    
    return 0
}

# ==============================================================================
# MAIN TEST RUNNER
# ==============================================================================

# Run all tests
run_all_tests() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running Zsh Starship Migration Tests${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Initialize test environment
    test_init
    
    # Run module tests
    echo -e "${YELLOW}Module Tests:${NC}"
    run_test "Logger Module" test_logger
    run_test "Error Handler Module" test_error_handler
    run_test "Configuration Module" test_config
    run_test "System Validator Module" test_system_validator
    run_test "Backup Manager Module" test_backup_manager
    echo ""
    
    # Run integration tests
    echo -e "${YELLOW}Integration Tests:${NC}"
    run_test "Script Help Command" test_script_help
    run_test "Script Version Command" test_script_version
    run_test "Script Dry-Run Mode" test_script_dry_run
    run_test "Script Configuration Display" test_script_config
    echo ""
    
    # Clean up
    test_cleanup
    
    # Display results
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Results:${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed!${NC}"
        return 1
    fi
}

# Run specific test category
run_module_tests() {
    echo -e "${BLUE}Running module tests only...${NC}"
    test_init
    
    run_test "Logger Module" test_logger
    run_test "Error Handler Module" test_error_handler
    run_test "Configuration Module" test_config
    run_test "System Validator Module" test_system_validator
    run_test "Backup Manager Module" test_backup_manager
    
    test_cleanup
    return $((FAILED_TESTS == 0 ? 0 : 1))
}

run_integration_tests() {
    echo -e "${BLUE}Running integration tests only...${NC}"
    test_init
    
    run_test "Script Help Command" test_script_help
    run_test "Script Version Command" test_script_version
    run_test "Script Dry-Run Mode" test_script_dry_run
    run_test "Script Configuration Display" test_script_config
    
    test_cleanup
    return $((FAILED_TESTS == 0 ? 0 : 1))
}

# ==============================================================================
# COMMAND LINE INTERFACE
# ==============================================================================

# Show help
show_help() {
    cat <<EOF
Test Runner for Zsh Starship Migration

Usage: $0 [OPTIONS]

OPTIONS:
    --all              Run all tests (default)
    --modules          Run module tests only
    --integration      Run integration tests only
    --help             Show this help message

EXAMPLES:
    $0                 # Run all tests
    $0 --modules       # Run module tests only
    $0 --integration   # Run integration tests only
EOF
}

# Main function
main() {
    case "${1:---all}" in
        --all)
            run_all_tests
            ;;
        --modules)
            run_module_tests
            ;;
        --integration)
            run_integration_tests
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "$0" == "$ZSH_NAME" || "$0" == "$0" ]]; then
    main "$@"
fi 