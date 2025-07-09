# Zsh Starship Migration - Professional Edition

A professional-grade script for migrating from Oh My Zsh to a modern Zsh setup with Starship, built following industry best practices for shell scripting.

## ✨ Características

### 🔧 **Detección y Solución Automática de Problemas**
- **Plugin rand-quote**: Detecta y deshabilita automáticamente el plugin que causa errores de `iconv`
- **Módulos custom de Starship**: Remueve módulos no disponibles (`custom_public_ip`, `custom_weather`)
- **Configuración de locale**: Asegura que UTF-8 esté configurado correctamente
- **Validación post-migración**: Verifica que todos los problemas se hayan solucionado

### 🚀 **Migración Inteligente**
- **Análisis automático** de la configuración actual de Oh My Zsh
- **Preservación de aliases, exports y funciones** personalizadas
- **Backup automático** antes de cualquier cambio
- **Rollback completo** en caso de problemas

### ⚡ **Configuración Optimizada**
- **Plugins de Zsh** modernos y productivos
- **Herramientas de desarrollo** actualizadas (eza, bat, fd, rg, fzf)
- **Prompt de Starship** personalizable y funcional
- **Integración completa** con Git, Kubernetes, Docker, AWS

### 🎯 **Modo Interactivo y Automático**
- **Modo interactivo** por defecto para control total y personalización
- **Modo automático** (`--auto`) para instalaciones sin intervención
- **Modo dry-run** (`--dry-run`) para verificar cambios sin aplicarlos
- **Modo verbose** (`--verbose`) para información detallada

## 📋 Requirements

- **macOS** (10.15 Catalina or later)
- **Homebrew** ([install here](https://brew.sh/))
- **Zsh** (usually pre-installed on macOS)

## 🛠️ Installation

### Quick Start
```bash
# Clone the repository
git clone https://github.com/your-repo/zsh-starship-migration.git
cd zsh-starship-migration

# Install the script
make install

# Run the migration
./zsh-starship-migration.sh
```

### Development Setup
```bash
# Set up development environment
make setup

# Install development dependencies
make install-dev

# Run tests
make test

# Check code quality
make lint
```

## 🎯 Usage

### Basic Migration
```bash
# Run migration in interactive mode (default)
./zsh-starship-migration.sh

# Preview what would be done (dry-run)
./zsh-starship-migration.sh --dry-run

# Run automatically without prompts
./zsh-starship-migration.sh --auto
```

### Advanced Options
```bash
# Skip installation of modern CLI tools
./zsh-starship-migration.sh --skip-tools

# Enable verbose logging
./zsh-starship-migration.sh --verbose

# Set custom log level
./zsh-starship-migration.sh --log-level debug
```

### Management Commands
```bash
# Check current status
./zsh-starship-migration.sh status

# Generate detailed report
./zsh-starship-migration.sh report

# Show configuration
./zsh-starship-migration.sh config

# List available backups
./zsh-starship-migration.sh backup-list

# Show backup information
./zsh-starship-migration.sh backup-info <backup-name>

# Restore from backup
./zsh-starship-migration.sh rollback
```

## 🏗️ Project Structure

```
zsh-starship-migration/
├── src/
│   ├── lib/                    # Core library modules
│   │   ├── logger.sh          # Professional logging system
│   │   ├── error_handler.sh   # Error handling and validation
│   │   └── config.sh          # Configuration management
│   └── modules/               # Feature modules
│       ├── system_validator.sh # System validation
│       └── backup_manager.sh   # Backup and rollback
├── tests/                     # Test suite
│   └── test_runner.sh         # Test runner
├── docs/                      # Generated documentation
├── dist/                      # Distribution files
├── zsh-starship-migration.sh  # Main script
├── Makefile                   # Build system
├── README.md                  # This file
├── CHANGELOG.md              # Version history
└── LICENSE                   # MIT License
```

## 🧪 Testing

### Run All Tests
```bash
make test
```

### Run Specific Tests
```bash
# Module tests only
make test-modules

# Integration tests only
make test-integration

# Quick syntax tests
make quick-test
```

### Manual Testing
```bash
# Run test suite directly
./tests/test_runner.sh

# Run specific test categories
./tests/test_runner.sh --modules
./tests/test_runner.sh --integration
```

## 🔧 Development

### Code Quality
```bash
# Check code quality
make lint

# Format code
make format

# Run shellcheck
make shellcheck

# Check formatting
make shfmt-check
```

### Build and Package
```bash
# Build distribution
make build

# Create package
make package

# Prepare release
make release
```

### Development Workflow
```bash
# Set up development environment
make setup

# Start development mode (watch for changes)
make dev

# Run in debug mode
make debug

# Check project status
make status
```

## 📊 What Gets Migrated

### Preserved Configuration
- ✅ User aliases
- ✅ Environment variables (exports)
- ✅ Custom functions
- ✅ Oh My Zsh plugins
- ✅ Existing Zsh configuration

### New Features
- 🚀 Starship prompt with modern styling
- 🛠️ Modern CLI tools (eza, bat, fd, ripgrep, fzf)
- 🔌 Essential Zsh plugins
- 🎨 Enhanced terminal experience
- 📱 Responsive and informative prompt

### Installed Tools
- **eza**: Modern `ls` replacement with icons
- **bat**: Enhanced `cat` with syntax highlighting
- **fd**: Fast `find` alternative
- **ripgrep**: High-performance `grep` replacement
- **fzf**: Fuzzy finder for command line

## 🔒 Safety Features

### Backup System
- **Automatic Backups**: Creates timestamped backups before any changes
- **Metadata Tracking**: Detailed backup information and system state
- **Rollback Support**: Easy restoration from any backup
- **Retention Policy**: Automatic cleanup of old backups

### Error Handling
- **Comprehensive Validation**: System requirements and dependencies
- **Graceful Failures**: Detailed error messages and recovery options
- **Safe Execution**: Dry-run mode for testing
- **Progress Tracking**: Real-time status updates

## 🎛️ Configuration

### Environment Variables
```bash
# Set log level
export LOG_LEVEL=debug

# Enable auto mode
export AUTO_MODE=true

# Skip tools installation
export SKIP_TOOLS=true

# Enable dry run
export DRY_RUN=true
```

### Configuration File
The script creates a configuration file at `~/.config/zsh-starship-migration/config.conf` that can be customized.

## 📈 Performance

- **Fast Execution**: Optimized for speed with minimal dependencies
- **Efficient Backups**: Smart backup strategy with compression
- **Minimal Footprint**: Lightweight installation and operation
- **Quick Rollback**: Fast restoration from backups

## 🤝 Contributing

### Development Setup
```bash
# Fork and clone the repository
git clone https://github.com/your-fork/zsh-starship-migration.git
cd zsh-starship-migration

# Set up development environment
make setup

# Run tests to ensure everything works
make test
```

### Code Standards
- Follow shell scripting best practices
- Use the provided logging system
- Add tests for new features
- Update documentation
- Run `make lint` before committing

### Testing Your Changes
```bash
# Run all tests
make test

# Run specific tests
make test-syntax
make test-modules
make test-integration

# Check code quality
make lint
```

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Starship**: For the amazing cross-shell prompt
- **Oh My Zsh**: For the foundation that many users start with
- **Shell scripting community**: For best practices and inspiration

## 🆘 Support

### Common Issues
- **Homebrew not found**: Install from [brew.sh](https://brew.sh/)
- **Permission denied**: Run `chmod +x zsh-starship-migration.sh`
- **Backup failed**: Check disk space and permissions

### Getting Help
- Check the [status command](#management-commands) for system information
- Use [dry-run mode](#basic-migration) to preview changes
- Review the [backup system](#backup-system) for rollback options

### Reporting Issues
Please include:
- macOS version
- Error messages
- Output of `./zsh-starship-migration.sh status`
- Steps to reproduce

---

**Built with ❤️ following professional shell scripting practices** 