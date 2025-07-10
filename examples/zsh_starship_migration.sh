#!/usr/bin/env zsh
clear

# Source the universal GUI framework
source "$(dirname "$0")/../gui_framework.sh"

# ===============================================================================
#
# Oh My Zsh to Starship Migration Script (Multi-platform for any Mac)
#
# Author: Gemini (with AI)
# Version: 1.3.0
#
# This script automates the transition from an Oh My Zsh configuration
# to a "pure" Zsh installation with Starship, plugins and modern
# command line tools.
#
# Main features:
#   - Automatic and safe migration (with backup and rollback)
#   - Installation of Starship, plugins and modern tools (eza, bat, fd, fzf, ripgrep)
#   - Compatible with any Mac (Intel or Apple Silicon)
#   - Detailed report of migration status and environment
#   - Clear logs and robust error handling
#   - Safe for advanced and beginner users
#
# Quick usage:
#   chmod +x zsh_starship_migration.sh
#   ./zsh_starship_migration.sh           # Run migration
#   ./zsh_starship_migration.sh rollback  # Restore previous backup
#   ./zsh_starship_migration.sh report    # Show detailed report
#   ./zsh_starship_migration.sh status    # Current configuration status
#   ./zsh_starship_migration.sh --help    # Help and options
#
# Requires Homebrew installed. If you don't have it, install from https://brew.sh/
#
# ===============================================================================

# --- TEACHING CONTEXT ---
# 'set -e' makes the script terminate immediately if a command fails.
# 'set -o pipefail' ensures that if a command in a pipeline fails,
# the exit code of the entire pipeline is that of the failed command.
# These are fundamental for creating robust and predictable scripts.
set -e
set -o pipefail

# Initialize the universal GUI framework
init_gui_framework

# --- GLOBAL VARIABLES AND COLORS DEFINITION ---
# Using variables for colors and texts improves readability and facilitates
# code maintenance. 'readonly' prevents them from being modified.
readonly C_RED='\033[0;31m'        # #ff0000 - Errors and critical alerts
readonly C_GREEN='\033[0;32m'      # #00ff00 - Success and confirmations
readonly C_BLUE='\033[0;34m'       # #0000ff - Information and titles
readonly C_YELLOW='\033[0;93m'     # #ffff00 - Warnings and prompts
readonly C_CYAN='\033[0;36m'       # #00ffff - Technical information
readonly C_MAGENTA='\033[0;35m'    # #ff00ff - Special highlights
readonly C_WHITE='\033[1;37m'      # White - Main text
readonly C_GRAY='\033[0;90m'       # Gray - Secondary text
readonly C_NC='\033[0m'            # Reset color

# --- UNIVERSAL LOGGING FUNCTIONS ---
log_success() { echo -e "${C_GREEN}✅ $1${C_NC}"; }
log_error() { echo -e "${C_RED}❌ $1${C_NC}" >&2; }
log_warning() { echo -e "${C_YELLOW}⚠️  $1${C_NC}"; }
log_info() { echo -e "${C_BLUE}ℹ️  $1${C_NC}"; }
log_debug() { echo -e "${C_GRAY}[DEBUG] $1${C_NC}"; }
log_verbose() { if [[ "${VERBOSE:-false}" = true ]]; then echo -e "${C_GRAY}   [VERBOSE] $1${C_NC}"; fi; }

# --- EXIT HANDLING ---
handle_quit() {
    local message="${1:-Exiting..."}"
    log_info "$message"
    exit 0
}

# --- GUM VERSION DETECTION ---
get_gum_version() {
    if ! command -v gum >/dev/null; then
        echo "0.0.0"
        return
    fi
    gum --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
}

supports_gum_unselected_flags() {
    local version=$(get_gum_version)
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)
    # gum >= 0.13.0 supports unselected flags
    if (( major > 0 )) || (( major == 0 && minor > 12 )) || (( major == 0 && minor == 12 && patch >= 0 )); then
        return 0
    else
        return 1
    fi
}

# --- DEPENDENCY CHECK ---
check_gui_dependencies() {
    if ! command -v gum >/dev/null; then
        log_warning "Gum is not installed. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gum
        elif command -v apt-get >/dev/null; then
            sudo apt-get update && sudo apt-get install -y gum
        elif command -v yum >/dev/null; then
            sudo yum install -y gum
        else
            log_error "Gum is not available. Please install it manually from: https://github.com/charmbracelet/gum"
            return 1
        fi
    fi
    return 0
}

# --- TTY DETECTION ---
require_tty() {
    if [[ ! -t 0 ]]; then
        log_error "This menu requires an interactive terminal (TTY). Please run the script from a real terminal."
        exit 2
    fi
}

# --- GUM CONFIGURATION (OPTIONAL) ---
setup_gum_config() {
    if supports_gum_unselected_flags; then
        export GUM_CHOOSE_UNSELECTED_FOREGROUND="#ffffff"
        export GUM_CHOOSE_UNSELECTED_BACKGROUND="#333333"
        log_debug "Advanced gum config applied"
    else
        log_debug "Using basic gum config"
    fi
}

# --- FRAMEWORK INITIALIZATION ---
init_gui_framework() {
    check_gui_dependencies
    setup_gum_config
    log_info "GUI framework initialized"
}

# --- MIGRATION SPECIFIC VARIABLES ---
readonly BACKUP_DIR="$HOME/.zsh_starship_backup"
readonly STARSHIP_CONFIG="$HOME/.config/starship.toml"
readonly ZSH_CONFIG="$HOME/.zshrc"
readonly ZSH_PROFILE="$HOME/.zprofile"
readonly ZSH_LOGIN="$HOME/.zlogin"
readonly ZSH_LOGOUT="$HOME/.zlogout"

# Migration status tracking
MIGRATION_STARTED=false
BACKUP_CREATED=false
STARSHIP_INSTALLED=false
PLUGINS_INSTALLED=false
CONFIG_UPDATED=false

# Script execution mode
INTERACTIVE_MODE=true
AUTO_MODE=false
DRY_RUN=false
VERBOSE=false

# These will be activated when parsing input arguments. 