# Universal Shell GUI Framework

A lightweight, cross-platform GUI framework for shell scripts that provides interactive menus, dialogs, and user interfaces without external dependencies.

## Features

- **Cross-platform compatibility**: Works on macOS, Linux, and Windows (with WSL)
- **No external dependencies**: Pure shell implementation
- **Interactive menus**: Hierarchical menu system with navigation
- **Dialog boxes**: Confirmation, input, and selection dialogs
- **Progress indicators**: Visual feedback for long-running operations
- **Color support**: Automatic detection and graceful fallback
- **Keyboard navigation**: Full keyboard support with arrow keys
- **Customizable themes**: Easy theming and styling options

## Quick Start

```bash
# Source the framework
source gui_framework.sh

# Create a simple menu
create_menu "Main Menu" "Option 1:Do something" "Option 2:Do something else" "Quit:exit"
```

## Installation

### Option 1: Direct Download
```bash
curl -O https://raw.githubusercontent.com/jagoff/shell-gui-framework/main/gui_framework.sh
source gui_framework.sh
```

### Option 2: Git Clone
```bash
git clone https://github.com/jagoff/shell-gui-framework.git
cd shell-gui-framework
source gui_framework.sh
```

### Option 3: Setup Script
```bash
curl -sSL https://raw.githubusercontent.com/jagoff/shell-gui-framework/main/setup-gui.sh | bash
```

## Examples

Check the `examples/` directory for complete working examples:

- `basic_menu_example.sh` - Simple menu demonstration
- `demo_quit_functionality.sh` - Advanced menu with quit handling

## Documentation

- [GUI Specification](docs/GUI_SPECIFICATION.md) - Technical details and API reference
- [GUI README](docs/GUI_README.md) - User guide and examples
- [Universal GUI Framework](docs/UNIVERSAL_GUI_FRAMEWORK.md) - Architecture overview

## Usage

### Basic Menu
```bash
source gui_framework.sh

# Simple menu
create_menu "Choose an option:" \
    "Install:install_package" \
    "Configure:configure_system" \
    "Quit:exit"
```

### Confirmation Dialog
```bash
if show_confirmation "Do you want to proceed?"; then
    echo "User confirmed"
else
    echo "User cancelled"
fi
```

### Input Dialog
```bash
user_input=$(show_input_dialog "Enter your name:")
echo "Hello, $user_input!"
```

### Progress Bar
```bash
show_progress_bar "Processing..." 0
# ... do work ...
show_progress_bar "Processing..." 50
# ... more work ...
show_progress_bar "Processing..." 100
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/jagoff/shell-gui-framework/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jagoff/shell-gui-framework/discussions)

## Related Projects

This framework is used by:
- [zsh-starship-migration](https://github.com/jagoff/zsh-starship-migration) - ZSH to Starship migration tool 