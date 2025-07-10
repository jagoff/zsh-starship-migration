#!/bin/bash
# demo_quit_functionality.sh - Demo script showcasing 'q' quit functionality
# This script demonstrates how users can exit any GUI component by pressing 'q'

# Source the GUI framework
source "$(dirname "$0")/../gui_framework.sh"

# Initialize the framework
init_gui_framework

# Demo function to show menu with quit functionality
demo_menu() {
    echo -e "\n${C_CYAN}=== Menu Demo ===${C_NC}"
    local choice
    choice=$(show_gui_menu \
        "Main Menu" \
        "Select an option or press 'q' to quit" \
        "Choose your action:" \
        "Option 1: View system info" \
        "Option 2: Check disk space" \
        "Option 3: Show network status" \
        "Option 4: Display user info")
    
    case "$choice" in
        "Option 1: View system info")
            log_success "You selected: View system info"
            ;;
        "Option 2: Check disk space")
            log_success "You selected: Check disk space"
            ;;
        "Option 3: Show network status")
            log_success "You selected: Show network status"
            ;;
        "Option 4: Display user info")
            log_success "You selected: Display user info"
            ;;
    esac
}

# Demo function to show multi-select with quit functionality
demo_multi_select() {
    echo -e "\n${C_CYAN}=== Multi-Select Demo ===${C_NC}"
    local selections
    selections=$(show_gui_multi_select \
        "Package Selection" \
        "Select multiple packages or press 'q' to quit" \
        "Choose packages to install:" \
        3 \
        "nginx" \
        "postgresql" \
        "redis" \
        "docker" \
        "nodejs" \
        "python3")
    
    if [[ -n "$selections" ]]; then
        log_success "Selected packages:"
        echo "$selections" | while read -r package; do
            echo "  - $package"
        done
    fi
}

# Demo function to show confirmation with quit functionality
demo_confirmation() {
    echo -e "\n${C_CYAN}=== Confirmation Demo ===${C_NC}"
    if show_gui_confirmation \
        "Do you want to proceed with the installation?" \
        "Yes, install" \
        "No, cancel"; then
        log_success "User confirmed the action"
    else
        log_info "User cancelled or quit"
    fi
}

# Demo function to show input with quit functionality
demo_input() {
    echo -e "\n${C_CYAN}=== Input Demo ===${C_NC}"
    local user_input
    user_input=$(show_gui_input \
        "Enter your name:" \
        "John Doe")
    
    if [[ -n "$user_input" ]]; then
        log_success "Hello, $user_input!"
    fi
}

# Demo function to show menu with explicit quit option
demo_menu_with_quit() {
    echo -e "\n${C_CYAN}=== Menu with Quit Option Demo ===${C_NC}"
    local choice
    choice=$(show_gui_menu_with_quit \
        "Settings Menu" \
        "Configure your settings or quit" \
        "Choose an option:" \
        "Change theme" \
        "Update preferences" \
        "Reset to defaults" \
        "Export settings")
    
    case "$choice" in
        "Change theme")
            log_success "Theme change selected"
            ;;
        "Update preferences")
            log_success "Preferences update selected"
            ;;
        "Reset to defaults")
            log_success "Reset to defaults selected"
            ;;
        "Export settings")
            log_success "Export settings selected"
            ;;
    esac
}

# Main demo function
main_demo() {
    echo -e "${C_MAGENTA}🎯 Universal Shell GUI Framework - 'q' Quit Demo${C_NC}"
    echo -e "${C_GRAY}This demo shows how you can exit any GUI component by pressing 'q'${C_NC}"
    
    # Show spinner while loading
    show_gui_spinner "Loading demo components..." sleep 2
    
    # Run all demos
    demo_menu
    demo_multi_select
    demo_confirmation
    demo_input
    demo_menu_with_quit
    
    echo -e "\n${C_GREEN}✅ Demo completed! All components support 'q' to quit.${C_NC}"
}

# Run the demo
main_demo 