# Changelog

All notable changes to the Universal Shell GUI Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-07-10

### Added
- 🚪 **'q' Quit Functionality**: Users can now exit any GUI component by pressing 'q'
- 📋 **Enhanced Legends**: All components now show clear navigation instructions
- 🌍 **English Standard**: All confirmation options translated to English ("Yes, continue", "No, cancel")
- 🎯 **New Function**: `show_gui_menu_with_quit()` for menus with explicit quit option
- 📚 **Demo Script**: `examples/demo_quit_functionality.sh` showcasing quit functionality
- 🔄 **Exit Handling**: `handle_quit()` function for consistent exit behavior

### Changed
- 🔄 **Legends Updated**: 
  - Menus: `←→ toggle • enter submit • q Quit`
  - Multi-select: `←→ toggle • space select • enter submit • q Quit`
  - Confirmations: `y Yes, continue • n No, cancel • q Quit`
  - Inputs: `type and enter submit • q Quit`
- 🔄 **Confirmation Options**: Standardized to English only
- 🔄 **Version Bump**: Framework version updated to 1.1.0

### Fixed
- 🐛 **User Experience**: Consistent exit behavior across all components
- 🐛 **Language Consistency**: All user-facing text now in English
- 🐛 **Navigation Clarity**: Clear instructions for all interactions

### Documentation
- 📚 **README Updated**: Added quit functionality documentation
- 📚 **Version History**: Added to README with detailed changelog
- 📚 **Examples Enhanced**: All examples now include quit functionality

## [1.0.0] - 2024-07-10

### Added
- 🎨 **Core Framework**: Universal Shell GUI Framework for bash/zsh
- 🎯 **GUI Components**: 
  - `show_gui_menu()` - Single selection menus
  - `show_gui_multi_select()` - Multi-selection menus
  - `show_gui_confirmation()` - Confirmation dialogs
  - `show_gui_input()` - Text input prompts
  - `show_gui_spinner()` - Loading spinners
  - `show_gui_progress()` - Progress bars
- 🌈 **Color System**: Universal color variables for consistent theming
- 📝 **Logging Functions**: Standardized logging with emojis and colors
- 🔧 **Dependency Management**: Automatic gum installation and version detection
- 🛡️ **Error Handling**: TTY detection and robust error management
- 🔄 **Gum Compatibility**: Support for all gum versions with fallbacks

### Features
- 🎨 **Modern Design**: Beautiful, colorful interfaces with emojis and icons
- 🔧 **Robust**: Compatible with all versions of gum
- 📱 **Interactive**: Full interactive terminal support
- 🛡️ **Safe**: TTY detection and error handling
- 🚀 **Fast**: Lightweight and efficient
- 📚 **Well-documented**: Complete examples and best practices

### Documentation
- 📚 **README.md**: Comprehensive project documentation
- 📚 **Framework Guide**: Complete implementation guide
- 📚 **GUI Specification**: Design and component specifications
- 📚 **Error Logging Guide**: Error handling best practices
- 📚 **Examples**: Real-world usage examples

### Examples
- 🎯 **Demo Script**: `examples/demo_quit_functionality.sh`
- 🚀 **Real-world Example**: `examples/zsh_starship_migration.sh`

---

## Versioning

- **Major**: Breaking changes or major new features
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes and minor improvements

## Contributing

When contributing to this project, please update this changelog with a new entry under the appropriate version section.

---

**For more information, see [README.md](README.md)** 