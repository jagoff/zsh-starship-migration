#!/bin/bash
# basic_menu_example.sh - Basic menu example using Universal Shell GUI Framework
# This example shows how to create a simple menu with the framework

# Source the GUI framework
source "$(dirname "$0")/../gui_framework.sh"

# Initialize the framework
init_gui_framework

# Function to show system info
show_system_info() {
    log_info "System Information:"
    echo "OS: $(uname -s)"
    echo "Architecture: $(uname -m)"
    echo "Shell: $SHELL"
    echo "User: $USER"
    echo "Home: $HOME"
}

# Function to show disk usage
show_disk_usage() {
    log_info "Disk Usage:"
    df -h | head -10
}

# Function to show network status
show_network_status() {
    log_info "Network Status:"
    if command -v ifconfig >/dev/null; then
        ifconfig | grep -E "inet |status" | head -10
    else
        ip addr show | grep -E "inet |state" | head -10
    fi
}

# Function to show user info
show_user_info() {
    log_info "User Information:"
    echo "Username: $USER"
    echo "UID: $(id -u)"
    echo "Groups: $(id -Gn)"
    echo "Shell: $SHELL"
}

# Main menu function
main_menu() {
    while true; do
        local choice=$(show_gui_menu \
            "System Information Tool" \
            "Select an option to view system information" \
            "Choose an action:" \
            "🖥️  System Info" \
            "💾 Disk Usage" \
            "🌐 Network Status" \
            "👤 User Info" \
            "❌ Exit")
        
        case "$choice" in
            "🖥️  System Info")
                show_system_info
                ;;
            "💾 Disk Usage")
                show_disk_usage
                ;;
            "🌐 Network Status")
                show_network_status
                ;;
            "👤 User Info")
                show_user_info
                ;;
            "❌ Exit")
                log_success "Goodbye!"
                exit 0
                ;;
        esac
        
        # Ask if user wants to continue
        if show_gui_confirmation "Do you want to view more information?"; then
            continue
        else
            log_success "Goodbye!"
            exit 0
        fi
    done
}

# Run the main menu
main_menu 