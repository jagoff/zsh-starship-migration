#!/bin/zsh
# ===============================================================================
# Professional System Validation Module
# ===============================================================================
#
# This module provides comprehensive system validation for the migration script:
# - Operating system detection and validation
# - Architecture detection (Intel vs Apple Silicon)
# - Dependency checking
# - Network connectivity validation
# - Homebrew validation
# - Zsh and Oh My Zsh detection
# - System resource validation
#
# Usage:
#   source "$(dirname "$0")/modules/system_validator.sh"
#   validate_system_requirements
#
# ===============================================================================

# Prevent multiple sourcing
if [[ -n "${_SYSTEM_VALIDATOR_SOURCED:-}" ]]; then
    return 0
fi
_SYSTEM_VALIDATOR_SOURCED=1

# ===============================================================================
# Configuration
# ===============================================================================

# Minimum system requirements
readonly MIN_MACOS_VERSION="10.15"  # Catalina
readonly MIN_ZSH_VERSION="5.0"
readonly MIN_GIT_VERSION="2.0"
readonly MIN_BREW_VERSION="2.0"

# Required commands
readonly REQUIRED_COMMANDS=(
    "zsh"
    "git"
    "brew"
    "curl"
    "wget"
)

# Optional but recommended commands
readonly RECOMMENDED_COMMANDS=(
    "gcc"
    "make"
    "cmake"
    "pkg-config"
)

# Network endpoints to test
readonly NETWORK_ENDPOINTS=(
    "https://github.com"
    "https://brew.sh"
    "https://starship.rs"
)

# ===============================================================================
# Internal Functions
# ===============================================================================

# Compare version strings
_compare_versions() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    
    # Fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # Fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    
    return 0
}

# Extract version from command output
_extract_version() {
    local command="$1"
    local version_pattern="$2"
    
    local output
    if output=$("$command" --version 2>/dev/null); then
        if [[ "$output" =~ $version_pattern ]]; then
            echo "${BASH_REMATCH[1]}"
        else
            echo "unknown"
        fi
    else
        echo "not_found"
    fi
}

# Test network connectivity
_test_network_endpoint() {
    local endpoint="$1"
    local timeout="${2:-10}"
    
    if curl --silent --connect-timeout "$timeout" --max-time "$timeout" "$endpoint" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check disk space
_check_disk_space() {
    local path="$1"
    local required_mb="$2"
    
    local available_mb
    available_mb=$(df -m "$path" | awk 'NR==2 {print $4}')
    
    if [[ "$available_mb" -ge "$required_mb" ]]; then
        return 0
    else
        return 1
    fi
}

# ===============================================================================
# Validation Functions
# ===============================================================================

# Validate operating system
validate_operating_system() {
    log_section "Operating System Validation"
    
    local os_type
    local os_version
    local os_name
    
    # Check OS type
    os_type="$OSTYPE"
    if [[ "$os_type" != "darwin"* ]]; then
        log_error "Unsupported operating system: $os_type"
        log_error "This script is designed for macOS only"
        return $EXIT_VALIDATION_ERROR
    fi
    
    log_success "Operating system: macOS detected"
    
    # Get macOS version
    if command -v sw_vers >/dev/null 2>&1; then
        os_version=$(sw_vers -productVersion)
        os_name=$(sw_vers -productName)
        log_info "macOS version: $os_name $os_version"
        
        # Check minimum version
        if _compare_versions "$os_version" "$MIN_MACOS_VERSION" == 2; then
            log_error "macOS version $os_version is below minimum required version $MIN_MACOS_VERSION"
            log_error "Please upgrade to macOS $MIN_MACOS_VERSION or later"
            return $EXIT_VALIDATION_ERROR
        fi
        
        log_success "macOS version meets minimum requirements"
    else
        log_warn "Could not determine macOS version"
    fi
    
    return 0
}

# Validate system architecture
validate_architecture() {
    log_section "Architecture Validation"
    
    local arch
    local processor
    
    # Get architecture
    arch=$(uname -m)
    processor=$(uname -p)
    
    log_info "Architecture: $arch"
    log_info "Processor: $processor"
    
    case "$arch" in
        "x86_64")
            log_success "Intel (x86_64) architecture detected"
            ;;
        "arm64")
            log_success "Apple Silicon (ARM64) architecture detected"
            ;;
        *)
            log_warn "Unknown architecture: $arch"
            ;;
    esac
    
    # Check if running under Rosetta
    if [[ "$arch" == "x86_64" ]] && [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" == "1" ]]; then
        log_warn "Running under Rosetta translation layer"
        log_warn "Performance may be affected"
    fi
    
    return 0
}

# Validate required commands
validate_required_commands() {
    log_section "Required Commands Validation"
    
    local missing_commands=()
    local command
    
    for command in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "$command" >/dev/null 2>&1; then
            local version
            version=$(_extract_version "$command" "([0-9]+\.[0-9]+(\.[0-9]+)?)")
            log_success "Found $command (version: $version)"
        else
            missing_commands+=("$command")
            log_error "Required command not found: $command"
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_error "Please install the missing commands and try again"
        return $EXIT_DEPENDENCY_ERROR
    fi
    
    log_success "All required commands are available"
    return 0
}

# Validate recommended commands
validate_recommended_commands() {
    log_section "Recommended Commands Validation"
    
    local missing_commands=()
    local command
    
    for command in "${RECOMMENDED_COMMANDS[@]}"; do
        if command -v "$command" >/dev/null 2>&1; then
            local version
            version=$(_extract_version "$command" "([0-9]+\.[0-9]+(\.[0-9]+)?)")
            log_success "Found $command (version: $version)"
        else
            missing_commands+=("$command")
            log_warn "Recommended command not found: $command"
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_warn "Missing recommended commands: ${missing_commands[*]}"
        log_warn "These commands may be needed for some features"
    fi
    
    return 0
}

# Validate Homebrew installation
validate_homebrew() {
    log_section "Homebrew Validation"
    
    if ! command -v brew >/dev/null 2>&1; then
        log_error "Homebrew is not installed"
        log_error "Please install Homebrew from https://brew.sh/"
        return $EXIT_DEPENDENCY_ERROR
    fi
    
    # Check Homebrew version
    local brew_version
    brew_version=$(brew --version | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "unknown")
    log_info "Homebrew version: $brew_version"
    
    # Check if Homebrew is working
    if ! brew doctor >/dev/null 2>&1; then
        log_warn "Homebrew installation may have issues"
        log_warn "Run 'brew doctor' for more information"
    else
        log_success "Homebrew installation is healthy"
    fi
    
    # Check Homebrew permissions
    if [[ ! -w "$(brew --prefix)" ]]; then
        log_error "Homebrew directory is not writable"
        log_error "Please fix Homebrew permissions"
        return $EXIT_PERMISSION_DENIED
    fi
    
    log_success "Homebrew validation passed"
    return 0
}

# Validate Zsh installation
validate_zsh() {
    log_section "Zsh Validation"
    
    if ! command -v zsh >/dev/null 2>&1; then
        log_error "Zsh is not installed"
        log_error "Please install Zsh and try again"
        return $EXIT_DEPENDENCY_ERROR
    fi
    
    # Check Zsh version
    local zsh_version
    zsh_version=$(zsh --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
    log_info "Zsh version: $zsh_version"
    
    # Check minimum version
    if _compare_versions "$zsh_version" "$MIN_ZSH_VERSION" == 2; then
        log_error "Zsh version $zsh_version is below minimum required version $MIN_ZSH_VERSION"
        log_error "Please upgrade Zsh to version $MIN_ZSH_VERSION or later"
        return $EXIT_VALIDATION_ERROR
    fi
    
    # Check if Zsh is the default shell
    local current_shell
    current_shell=$(echo "$SHELL")
    if [[ "$current_shell" == */zsh ]]; then
        log_success "Zsh is the current shell"
    else
        log_warn "Zsh is not the current shell: $current_shell"
        log_warn "Consider changing your default shell to Zsh"
    fi
    
    log_success "Zsh validation passed"
    return 0
}

# Validate Oh My Zsh installation
validate_oh_my_zsh() {
    log_section "Oh My Zsh Validation"
    
    local omz_dir="$HOME/.oh-my-zsh"
    local zshrc_file="$HOME/.zshrc"
    
    if [[ -d "$omz_dir" ]]; then
        log_success "Oh My Zsh installation found"
        
        # Check Oh My Zsh version
        if [[ -f "$omz_dir/tools/check_for_upgrade.sh" ]]; then
            local omz_version
            omz_version=$(grep -E '^ZSH_VERSION=' "$omz_dir/tools/check_for_upgrade.sh" | cut -d'"' -f2 || echo "unknown")
            log_info "Oh My Zsh version: $omz_version"
        fi
        
        # Check if Oh My Zsh is properly configured
        if [[ -f "$zshrc_file" ]] && grep -q "oh-my-zsh.sh" "$zshrc_file"; then
            log_success "Oh My Zsh is properly configured in ~/.zshrc"
        else
            log_warn "Oh My Zsh is installed but may not be properly configured"
        fi
        
        return 0
    else
        log_warn "Oh My Zsh installation not found"
        log_warn "Migration will proceed with standard Zsh configuration"
        return 0
    fi
}

# Validate network connectivity
validate_network() {
    log_section "Network Connectivity Validation"
    
    local failed_endpoints=()
    local endpoint
    
    for endpoint in "${NETWORK_ENDPOINTS[@]}"; do
        if _test_network_endpoint "$endpoint"; then
            log_success "Network connectivity to $endpoint: OK"
        else
            failed_endpoints+=("$endpoint")
            log_error "Network connectivity to $endpoint: FAILED"
        fi
    done
    
    if [[ ${#failed_endpoints[@]} -gt 0 ]]; then
        log_error "Network connectivity issues detected"
        log_error "Failed endpoints: ${failed_endpoints[*]}"
        log_error "Please check your internet connection"
        return $EXIT_NETWORK_ERROR
    fi
    
    log_success "Network connectivity validation passed"
    return 0
}

# Validate system resources
validate_system_resources() {
    log_section "System Resources Validation"
    
    # Check disk space (require at least 1GB free)
    local home_dir="$HOME"
    if _check_disk_space "$home_dir" 1024; then
        local available_mb
        available_mb=$(df -m "$home_dir" | awk 'NR==2 {print $4}')
        log_success "Disk space: ${available_mb}MB available"
    else
        local available_mb
        available_mb=$(df -m "$home_dir" | awk 'NR==2 {print $4}')
        log_error "Insufficient disk space: ${available_mb}MB available, 1024MB required"
        return $EXIT_INSUFFICIENT_RESOURCES
    fi
    
    # Check memory (require at least 2GB)
    local total_memory_mb
    total_memory_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "0")
    if [[ "$total_memory_mb" -ge 2048 ]]; then
        log_success "Memory: ${total_memory_mb}MB available"
    else
        log_warn "Low memory: ${total_memory_mb}MB available, 2048MB recommended"
    fi
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
    log_info "CPU cores: $cpu_cores"
    
    log_success "System resources validation passed"
    return 0
}

# Validate file permissions
validate_permissions() {
    log_section "File Permissions Validation"
    
    local home_dir="$HOME"
    local config_dir="$HOME/.config"
    
    # Check home directory permissions
    if [[ -r "$home_dir" && -w "$home_dir" ]]; then
        log_success "Home directory permissions: OK"
    else
        log_error "Home directory permissions: FAILED"
        return $EXIT_PERMISSION_DENIED
    fi
    
    # Check config directory permissions
    if [[ ! -d "$config_dir" ]]; then
        if mkdir -p "$config_dir" 2>/dev/null; then
            log_success "Created config directory: $config_dir"
        else
            log_error "Cannot create config directory: $config_dir"
            return $EXIT_PERMISSION_DENIED
        fi
    elif [[ -r "$config_dir" && -w "$config_dir" ]]; then
        log_success "Config directory permissions: OK"
    else
        log_error "Config directory permissions: FAILED"
        return $EXIT_PERMISSION_DENIED
    fi
    
    log_success "File permissions validation passed"
    return 0
}

# ===============================================================================
# Main Validation Function
# ===============================================================================

# Main system validation function
validate_system_requirements() {
    log_info "Starting system requirements validation..."
    
    local validation_results=()
    local overall_success=true
    
    # Run all validation checks
    validation_results+=("Operating System: $(validate_operating_system && echo "PASS" || echo "FAIL")")
    validation_results+=("Architecture: $(validate_architecture && echo "PASS" || echo "FAIL")")
    validation_results+=("Required Commands: $(validate_required_commands && echo "PASS" || echo "FAIL")")
    validation_results+=("Recommended Commands: $(validate_recommended_commands && echo "PASS" || echo "FAIL")")
    validation_results+=("Homebrew: $(validate_homebrew && echo "PASS" || echo "FAIL")")
    validation_results+=("Zsh: $(validate_zsh && echo "PASS" || echo "FAIL")")
    validation_results+=("Oh My Zsh: $(validate_oh_my_zsh && echo "PASS" || echo "FAIL")")
    validation_results+=("Network: $(validate_network && echo "PASS" || echo "FAIL")")
    validation_results+=("System Resources: $(validate_system_resources && echo "PASS" || echo "FAIL")")
    validation_results+=("Permissions: $(validate_permissions && echo "PASS" || echo "FAIL")")
    
    # Display validation summary
    log_section "Validation Summary"
    for result in "${validation_results[@]}"; do
        if [[ "$result" == *"PASS" ]]; then
            log_success "$result"
        else
            log_error "$result"
            overall_success=false
        fi
    done
    
    if [[ "$overall_success" == "true" ]]; then
        log_success "All system requirements validation passed"
        return 0
    else
        log_error "System requirements validation failed"
        log_error "Please fix the issues above and try again"
        return $EXIT_VALIDATION_ERROR
    fi
}

# Quick validation (for dry-run mode)
validate_system_quick() {
    log_info "Performing quick system validation..."
    
    # Only check critical requirements
    validate_operating_system || return $?
    validate_required_commands || return $?
    validate_homebrew || return $?
    validate_zsh || return $?
    
    log_success "Quick system validation passed"
    return 0
}

# ===============================================================================
# Utility Functions
# ===============================================================================

# Get system information
get_system_info() {
    log_section "System Information"
    
    echo "Operating System: $(uname -s) $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"
    echo "Home Directory: $HOME"
    echo "Shell: $SHELL"
    
    if command -v sw_vers >/dev/null 2>&1; then
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "macOS Build: $(sw_vers -buildVersion)"
    fi
    
    echo "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")"
    echo "Memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "Unknown") MB"
    echo "CPU Cores: $(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")"
}

# Test system validation
test_system_validation() {
    log_info "Testing system validation..."
    
    # Test version comparison
    if _compare_versions "1.0" "1.1" == 2; then
        log_success "Version comparison test passed"
    else
        log_error "Version comparison test failed"
        return 1
    fi
    
    # Test network endpoint
    if _test_network_endpoint "https://httpbin.org/get" 5; then
        log_success "Network test passed"
    else
        log_warn "Network test failed (may be offline)"
    fi
    
    log_success "System validation tests completed"
} 