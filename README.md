# 🎨 Universal Shell GUI Framework

> **The definitive standard for beautiful, modern CLI interfaces in shell projects**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash/Zsh](https://img.shields.io/badge/Shell-Bash%2FZsh-blue.svg)](https://www.gnu.org/software/bash/)
[![GUI: Gum](https://img.shields.io/badge/GUI-Gum-green.svg)](https://github.com/charmbracelet/gum)
[![Version: 1.1.0](https://img.shields.io/badge/Version-1.1.0-orange.svg)](https://github.com/jagoff/universal-shell-gui-framework)

A universal framework for creating stunning, interactive command-line interfaces using `gum`. This framework provides a standardized approach to building modern, user-friendly shell applications with consistent design patterns, robust error handling, and intuitive 'q' quit functionality.

## ✨ Features

- 🎯 **Universal**: Works with any shell project (bash, zsh, etc.)
- 🎨 **Beautiful**: Modern, colorful interfaces with emojis and icons
- 🔧 **Robust**: Compatible with all versions of `gum`
- 📱 **Interactive**: Menus, confirmations, multi-select, and more
- 🛡️ **Safe**: TTY detection and error handling
- 🚪 **Quit-friendly**: Press 'q' to exit any component
- 📚 **Well-documented**: Complete examples and best practices
- 🚀 **Fast**: Lightweight and efficient

## 🚀 Quick Start

### 1. Install Dependencies
```bash
# Install gum (required)
brew install gum

# Verify installation
gum --version
```

### 2. Include the Framework
```bash
#!/bin/bash
# Your script with beautiful GUI

# Include the framework
source ./gui_framework.sh

# Initialize the framework
init_gui_framework

# Use the functions
main() {
    local action=$(show_gui_menu \
        "My Project" \
        "Select the action you want to perform" \
        "Choose an option:" \
        "🚀 Install" \
        "⚙️  Configure" \
        "▶️  Run" \
        "❌ Exit")
    
    case "$action" in
        "🚀 Install") install_project ;;
        "⚙️  Configure") configure_project ;;
        "▶️  Run") run_project ;;
        "❌ Exit") exit 0 ;;
    esac
}

main "$@"
```

## 📁 Repository Structure

```
universal-shell-gui-framework/
├── README.md                           # This file
├── gui_framework.sh                    # Core framework (v1.1.0)
├── LICENSE                             # MIT License
├── examples/
│   ├── demo_quit_functionality.sh      # Demo of 'q' quit feature
│   └── zsh_starship_migration.sh       # Real-world example
└── docs/
    ├── UNIVERSAL_GUI_FRAMEWORK.md      # Complete framework guide
    ├── GUI_SPECIFICATION.md            # GUI design specifications
    ├── GUI_README.md                   # GUI usage guide
    ├── ERROR_LOGGING.md                # Error handling guide
    ├── INTERACTIVE_MODE_FIX.md         # Interactive mode solutions
    ├── TERMINAL_HANG_FIX.md            # Terminal hang solutions
    ├── PLUGIN_INSTALLATION_FIX.md      # Plugin installation fixes
    └── ICONV_ERROR_FIX.md              # Iconv error solutions
```

## 🎯 Core Components

### Menus
```bash
# Single selection menu
local choice=$(show_gui_menu \
    "Title" \
    "Subtitle" \
    "Header:" \
    "Option 1" \
    "Option 2" \
    "Option 3")

# Multi-selection menu
local selections=$(show_gui_multi_select \
    "Title" \
    "Subtitle" \
    "Header:" \
    3 \
    "Feature 1" \
    "Feature 2" \
    "Feature 3")
```

### Confirmations
```bash
if show_gui_confirmation "Do you want to continue?"; then
    echo "User confirmed"
else
    echo "User cancelled or quit"
fi
```

### Input
```bash
local name=$(show_gui_input "Enter your name:" "John Doe")
```

### Progress & Spinners
```bash
show_gui_spinner "Installing..." sleep 3
show_gui_progress "Downloading..." 75
```

## 🚪 Quit Functionality

**Press 'q' to exit any component!** This is now a standard feature across all GUI components:

- **Menus**: `←→ toggle • enter submit • q Quit`
- **Multi-select**: `←→ toggle • space select • enter submit • q Quit`
- **Confirmations**: `y Yes, continue • n No, cancel • q Quit`
- **Inputs**: `type and enter submit • q Quit`

## 🎨 Design Principles

### Color Scheme
- 🔴 **Red**: Errors and critical alerts
- 🟢 **Green**: Success and confirmations  
- 🔵 **Blue**: Information and titles
- 🟡 **Yellow**: Warnings and prompts
- 🟣 **Purple**: Special highlights
- ⚪ **Gray**: Secondary text

### Icons & Emojis
- 📋 Section headers
- ✅ Success indicators
- ❌ Error indicators
- ⚠️  Warnings
- 🔧 Configuration
- 🚀 Actions
- 🎯 Targets

## 📚 Documentation

- **[Universal GUI Framework](docs/UNIVERSAL_GUI_FRAMEWORK.md)** - Complete implementation guide
- **[GUI Specification](docs/GUI_SPECIFICATION.md)** - Design and component specifications
- **[GUI README](docs/GUI_README.md)** - GUI usage and examples
- **[Error Logging](docs/ERROR_LOGGING.md)** - Error handling best practices

## 🔧 Installation

### Option 1: Direct Download
```bash
# Download the framework
curl -O https://raw.githubusercontent.com/jagoff/universal-shell-gui-framework/main/gui_framework.sh

# Make it executable
chmod +x gui_framework.sh

# Include in your script
source ./gui_framework.sh
```

### Option 2: Git Clone
```bash
# Clone the repository
git clone https://github.com/jagoff/universal-shell-gui-framework.git

# Copy the framework to your project
cp universal-shell-gui-framework/gui_framework.sh ./gui_framework.sh

# Include in your script
source ./gui_framework.sh
```

## 🎯 Usage Examples

### Basic Menu with Quit
```bash
#!/bin/bash
source ./gui_framework.sh
init_gui_framework

main() {
    local action=$(show_gui_menu \
        "My Application" \
        "What would you like to do?" \
        "Select an action:" \
        "🚀 Start" \
        "⚙️  Settings" \
        "📊 Status" \
        "❌ Quit")
    
    case "$action" in
        "🚀 Start") start_app ;;
        "⚙️  Settings") open_settings ;;
        "📊 Status") show_status ;;
        "❌ Quit") exit 0 ;;
    esac
}

main "$@"
```

### Multi-Step Process with Quit
```bash
#!/bin/bash
source ./gui_framework.sh
init_gui_framework

deploy_app() {
    # Step 1: Environment selection
    local env=$(show_gui_menu \
        "Deployment" \
        "Select deployment environment" \
        "Environment:" \
        "🟢 Development" \
        "🟡 Staging" \
        "🔴 Production")
    
    # Step 2: Confirmation
    if show_gui_confirmation "Deploy to $env?"; then
        # Step 3: Progress
        show_gui_spinner "Deploying to $env..." sleep 5
        log_success "Deployment completed!"
    fi
}
```

### Try the Demo
```bash
# Run the quit functionality demo
./examples/demo_quit_functionality.sh
```

## 🔄 Version History

### v1.1.0 (Current)
- ✅ Added 'q' quit functionality to all GUI components
- ✅ Updated legends to show quit instructions
- ✅ Translated all confirmation options to English
- ✅ Enhanced error handling and user experience
- ✅ Added comprehensive demo script

### v1.0.0
- ✅ Initial release with core GUI components
- ✅ Universal color scheme and logging
- ✅ Gum version compatibility detection
- ✅ TTY detection and error handling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Charmbracelet](https://charm.sh/) for the amazing `gum` tool
- The shell scripting community for best practices
- All contributors who help improve this framework

---

**Made with ❤️ for the shell community**

> *"Beautiful interfaces shouldn't be limited to web apps"* 