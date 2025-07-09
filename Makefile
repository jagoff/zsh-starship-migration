# ===============================================================================
# Zsh Starship Migration - Professional Makefile
# ===============================================================================
#
# This Makefile provides common development tasks for the zsh-starship-migration
# project, including installation, testing, linting, formatting, and packaging.
#
# Usage:
#   make install          # Install the script
#   make test             # Run all tests
#   make lint             # Check code quality
#   make format           # Format code
#   make build            # Build distribution
#   make clean            # Clean build artifacts
#
# ===============================================================================

# ===============================================================================
# Configuration
# ===============================================================================

# Project information
PROJECT_NAME := zsh-starship-migration
PROJECT_VERSION := 2.0.0
PROJECT_AUTHOR := Professional Shell Scripting Team
PROJECT_DESCRIPTION := Migrate from Oh My Zsh to Starship with modern tools

# Script information
SCRIPT_NAME := zsh-starship-migration.sh
SCRIPT_SOURCE := $(SCRIPT_NAME)
SCRIPT_INSTALL_DIR := /usr/local/bin
SCRIPT_INSTALL_NAME := $(PROJECT_NAME)

# Directories
SRC_DIR := src
LIB_DIR := $(SRC_DIR)/lib
MODULES_DIR := $(SRC_DIR)/modules
TESTS_DIR := tests
DOCS_DIR := docs
DIST_DIR := dist
BUILD_DIR := build

# Files
MAIN_SCRIPT := $(SCRIPT_NAME)
LIB_FILES := $(wildcard $(LIB_DIR)/*.sh)
MODULE_FILES := $(wildcard $(MODULES_DIR)/*.sh)
TEST_FILES := $(wildcard $(TESTS_DIR)/*.sh)
DOC_FILES := README.md CHANGELOG.md LICENSE

# Tools
SHELL := /bin/bash
SHELLCHECK := shellcheck
SHFMT := shfmt
GIT := git
TAR := tar
GZIP := gzip

# ===============================================================================
# Default Target
# ===============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(PROJECT_NAME) v$(PROJECT_VERSION) - $(PROJECT_DESCRIPTION)"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make install          # Install the script system-wide"
	@echo "  make test             # Run all tests"
	@echo "  make lint             # Check code quality"
	@echo "  make format           # Format code"
	@echo "  make build            # Build distribution package"

# ===============================================================================
# Installation
# ===============================================================================

.PHONY: install
install: ## Install the script system-wide
	@echo "Installing $(PROJECT_NAME) v$(PROJECT_VERSION)..."
	@sudo cp "$(SCRIPT_SOURCE)" "$(SCRIPT_INSTALL_DIR)/$(SCRIPT_INSTALL_NAME)"
	@sudo chmod +x "$(SCRIPT_INSTALL_DIR)/$(SCRIPT_INSTALL_NAME)"
	@echo "✅ $(PROJECT_NAME) installed to $(SCRIPT_INSTALL_DIR)/$(SCRIPT_INSTALL_NAME)"

.PHONY: install-user
install-user: ## Install the script for current user only
	@echo "Installing $(PROJECT_NAME) v$(PROJECT_VERSION) for current user..."
	@mkdir -p "$(HOME)/.local/bin"
	@cp "$(SCRIPT_SOURCE)" "$(HOME)/.local/bin/$(SCRIPT_INSTALL_NAME)"
	@chmod +x "$(HOME)/.local/bin/$(SCRIPT_INSTALL_NAME)"
	@echo "✅ $(PROJECT_NAME) installed to $(HOME)/.local/bin/$(SCRIPT_INSTALL_NAME)"
	@echo "💡 Add $(HOME)/.local/bin to your PATH if not already there"

.PHONY: uninstall
uninstall: ## Uninstall the script
	@echo "Uninstalling $(PROJECT_NAME)..."
	@sudo rm -f "$(SCRIPT_INSTALL_DIR)/$(SCRIPT_INSTALL_NAME)"
	@rm -f "$(HOME)/.local/bin/$(SCRIPT_INSTALL_NAME)"
	@echo "✅ $(PROJECT_NAME) uninstalled"

# ===============================================================================
# Development Setup
# ===============================================================================

.PHONY: setup
setup: ## Set up development environment
	@echo "Setting up development environment..."
	@mkdir -p $(BUILD_DIR) $(DIST_DIR) $(DOCS_DIR)
	@echo "✅ Development environment set up"

.PHONY: setup-dev
setup-dev: ## Install development dependencies
	@echo "Installing development dependencies..."
	@command -v $(SHELLCHECK) >/dev/null 2>&1 || { echo "❌ shellcheck not found. Install with: brew install shellcheck"; exit 1; }
	@command -v $(SHFMT) >/dev/null 2>&1 || { echo "❌ shfmt not found. Install with: go install mvdan.cc/sh/v3/cmd/shfmt@latest"; exit 1; }
	@echo "✅ Development dependencies installed"

# ===============================================================================
# Testing
# ===============================================================================

.PHONY: test
test: ## Run all tests
	@echo "Running all tests..."
	@$(MAKE) test-syntax
	@$(MAKE) test-modules
	@$(MAKE) test-integration
	@echo "✅ All tests passed"

.PHONY: test-syntax
test-syntax: ## Test script syntax
	@echo "Testing script syntax..."
	@bash -n "$(SCRIPT_SOURCE)" || { echo "❌ Syntax error in $(SCRIPT_SOURCE)"; exit 1; }
	@for file in $(LIB_FILES) $(MODULE_FILES); do \
		bash -n "$$file" || { echo "❌ Syntax error in $$file"; exit 1; }; \
	done
	@echo "✅ Syntax tests passed"

.PHONY: test-modules
test-modules: ## Test individual modules
	@echo "Testing modules..."
	@if [ -f "$(TESTS_DIR)/test_runner.sh" ]; then \
		$(TESTS_DIR)/test_runner.sh --modules; \
	else \
		echo "⚠️  No test runner found, skipping module tests"; \
	fi

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "Running integration tests..."
	@if [ -f "$(TESTS_DIR)/test_runner.sh" ]; then \
		$(TESTS_DIR)/test_runner.sh --integration; \
	else \
		echo "⚠️  No test runner found, skipping integration tests"; \
	fi

.PHONY: test-quick
test-quick: ## Run quick tests only
	@echo "Running quick tests..."
	@$(MAKE) test-syntax
	@echo "✅ Quick tests passed"

# ===============================================================================
# Code Quality
# ===============================================================================

.PHONY: lint
lint: ## Check code quality with shellcheck
	@echo "Checking code quality..."
	@$(SHELLCHECK) --version >/dev/null 2>&1 || { echo "❌ shellcheck not installed"; exit 1; }
	@$(SHELLCHECK) --shell=bash --severity=style "$(SCRIPT_SOURCE)"
	@for file in $(LIB_FILES) $(MODULE_FILES); do \
		$(SHELLCHECK) --shell=bash --severity=style "$$file"; \
	done
	@echo "✅ Code quality check passed"

.PHONY: lint-strict
lint-strict: ## Check code quality with strict settings
	@echo "Checking code quality (strict mode)..."
	@$(SHELLCHECK) --version >/dev/null 2>&1 || { echo "❌ shellcheck not installed"; exit 1; }
	@$(SHELLCHECK) --shell=bash --severity=warning "$(SCRIPT_SOURCE)"
	@for file in $(LIB_FILES) $(MODULE_FILES); do \
		$(SHELLCHECK) --shell=bash --severity=warning "$$file"; \
	done
	@echo "✅ Strict code quality check passed"

.PHONY: format
format: ## Format code with shfmt
	@echo "Formatting code..."
	@$(SHFMT) --version >/dev/null 2>&1 || { echo "❌ shfmt not installed"; exit 1; }
	@$(SHFMT) -w -i 4 -ci "$(SCRIPT_SOURCE)"
	@for file in $(LIB_FILES) $(MODULE_FILES); do \
		$(SHFMT) -w -i 4 -ci "$$file"; \
	done
	@echo "✅ Code formatted"

.PHONY: format-check
format-check: ## Check code formatting
	@echo "Checking code formatting..."
	@$(SHFMT) --version >/dev/null 2>&1 || { echo "❌ shfmt not installed"; exit 1; }
	@$(SHFMT) -d -i 4 -ci "$(SCRIPT_SOURCE)"
	@for file in $(LIB_FILES) $(MODULE_FILES); do \
		$(SHFMT) -d -i 4 -ci "$$file"; \
	done
	@echo "✅ Code formatting check passed"

# ===============================================================================
# Building and Packaging
# ===============================================================================

.PHONY: build
build: ## Build the project
	@echo "Building $(PROJECT_NAME) v$(PROJECT_VERSION)..."
	@mkdir -p $(BUILD_DIR)
	@cp $(SCRIPT_SOURCE) $(BUILD_DIR)/
	@cp -r $(SRC_DIR) $(BUILD_DIR)/
	@cp $(DOC_FILES) $(BUILD_DIR)/
	@echo "✅ Build completed in $(BUILD_DIR)"

.PHONY: package
package: build ## Create distribution package
	@echo "Creating distribution package..."
	@mkdir -p $(DIST_DIR)
	@cd $(BUILD_DIR) && $(TAR) -czf ../$(DIST_DIR)/$(PROJECT_NAME)-$(PROJECT_VERSION).tar.gz .
	@echo "✅ Package created: $(DIST_DIR)/$(PROJECT_NAME)-$(PROJECT_VERSION).tar.gz"

.PHONY: release
release: ## Prepare release package
	@echo "Preparing release package..."
	@$(MAKE) clean
	@$(MAKE) test
	@$(MAKE) lint
	@$(MAKE) package
	@echo "✅ Release package ready: $(DIST_DIR)/$(PROJECT_NAME)-$(PROJECT_VERSION).tar.gz"

# ===============================================================================
# Documentation
# ===============================================================================

.PHONY: docs
docs: ## Generate documentation
	@echo "Generating documentation..."
	@mkdir -p $(DOCS_DIR)
	@echo "# $(PROJECT_NAME) Documentation" > $(DOCS_DIR)/README.md
	@echo "" >> $(DOCS_DIR)/README.md
	@echo "Generated on: $$(date)" >> $(DOCS_DIR)/README.md
	@echo "" >> $(DOCS_DIR)/README.md
	@echo "## Script Information" >> $(DOCS_DIR)/README.md
	@echo "- Version: $(PROJECT_VERSION)" >> $(DOCS_DIR)/README.md
	@echo "- Author: $(PROJECT_AUTHOR)" >> $(DOCS_DIR)/README.md
	@echo "- Description: $(PROJECT_DESCRIPTION)" >> $(DOCS_DIR)/README.md
	@echo "✅ Documentation generated in $(DOCS_DIR)"

.PHONY: man
man: ## Generate man page
	@echo "Generating man page..."
	@mkdir -p $(DOCS_DIR)
	@echo ".TH $(PROJECT_NAME) 1 \"$$(date +%B %Y)\" \"$(PROJECT_VERSION)\" \"$(PROJECT_DESCRIPTION)\"" > $(DOCS_DIR)/$(PROJECT_NAME).1
	@echo ".SH NAME" >> $(DOCS_DIR)/$(PROJECT_NAME).1
	@echo "$(PROJECT_NAME) \\- $(PROJECT_DESCRIPTION)" >> $(DOCS_DIR)/$(PROJECT_NAME).1
	@echo ".SH SYNOPSIS" >> $(DOCS_DIR)/$(PROJECT_NAME).1
	@echo ".B $(PROJECT_NAME)" >> $(DOCS_DIR)/$(PROJECT_NAME).1
	@echo "[OPTIONS] [COMMAND]" >> $(DOCS_DIR)/$(PROJECT_NAME).1
	@echo "✅ Man page generated: $(DOCS_DIR)/$(PROJECT_NAME).1"

# ===============================================================================
# Development Workflow
# ===============================================================================

.PHONY: dev
dev: ## Start development mode (watch for changes)
	@echo "Starting development mode..."
	@echo "Watching for changes in source files..."
	@echo "Press Ctrl+C to stop"
	@while true; do \
		inotifywait -q -e modify $(SCRIPT_SOURCE) $(LIB_FILES) $(MODULE_FILES) || exit 1; \
		echo "File changed, running tests..."; \
		$(MAKE) test-quick; \
	done

.PHONY: debug
debug: ## Run script in debug mode
	@echo "Running $(PROJECT_NAME) in debug mode..."
	@bash -x "$(SCRIPT_SOURCE)" --log-level DEBUG

.PHONY: dry-run
dry-run: ## Run script in dry-run mode
	@echo "Running $(PROJECT_NAME) in dry-run mode..."
	@bash "$(SCRIPT_SOURCE)" --dry-run --verbose

# ===============================================================================
# Maintenance
# ===============================================================================

.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo "✅ Clean completed"

.PHONY: clean-all
clean-all: ## Clean all generated files
	@echo "Cleaning all generated files..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR) $(DOCS_DIR)
	@find . -name "*.tmp" -delete
	@find . -name "*.log" -delete
	@echo "✅ Full clean completed"

# ===============================================================================
# Error Log Management
# ===============================================================================

.PHONY: error-log
error-log: ## Show recent error log entries
	@echo "Showing recent error log entries..."
	@bash "$(SCRIPT_SOURCE)" error-log

.PHONY: error-stats
error-stats: ## Show error log statistics
	@echo "Showing error log statistics..."
	@bash "$(SCRIPT_SOURCE)" error-stats

.PHONY: error-clear
error-clear: ## Clear error log
	@echo "Clearing error log..."
	@bash "$(SCRIPT_SOURCE)" error-clear

.PHONY: error-search
error-search: ## Search error log (usage: make error-search PATTERN="search term")
	@echo "Searching error log for pattern: $(PATTERN)"
	@bash "$(SCRIPT_SOURCE)" error-search "$(PATTERN)"

.PHONY: error-test
error-test: ## Test error logging functionality
	@echo "Testing error logging functionality..."
	@bash test_error_logging.sh

.PHONY: error-monitor
error-monitor: ## Monitor error log in real-time
	@echo "Monitoring error log in real-time..."
	@echo "Press Ctrl+C to stop"
	@tail -f error.log

.PHONY: check
check: ## Run all checks (test, lint, format)
	@echo "Running all checks..."
	@$(MAKE) test
	@$(MAKE) lint
	@$(MAKE) format-check
	@echo "✅ All checks passed"

# ===============================================================================
# Version Management
# ===============================================================================

.PHONY: version
version: ## Show current version
	@echo "$(PROJECT_NAME) v$(PROJECT_VERSION)"

.PHONY: bump-patch
bump-patch: ## Bump patch version
	@echo "Bumping patch version..."
	@$(eval NEW_VERSION := $(shell echo $(PROJECT_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}'))
	@sed -i.bak 's/PROJECT_VERSION := $(PROJECT_VERSION)/PROJECT_VERSION := $(NEW_VERSION)/' $(MAKEFILE_LIST)
	@sed -i.bak 's/readonly SCRIPT_VERSION="$(PROJECT_VERSION)"/readonly SCRIPT_VERSION="$(NEW_VERSION)"/' $(SCRIPT_SOURCE)
	@rm -f $(MAKEFILE_LIST).bak $(SCRIPT_SOURCE).bak
	@echo "✅ Version bumped to $(NEW_VERSION)"

.PHONY: bump-minor
bump-minor: ## Bump minor version
	@echo "Bumping minor version..."
	@$(eval NEW_VERSION := $(shell echo $(PROJECT_VERSION) | awk -F. '{print $$1"."$$2+1".0"}'))
	@sed -i.bak 's/PROJECT_VERSION := $(PROJECT_VERSION)/PROJECT_VERSION := $(NEW_VERSION)/' $(MAKEFILE_LIST)
	@sed -i.bak 's/readonly SCRIPT_VERSION="$(PROJECT_VERSION)"/readonly SCRIPT_VERSION="$(NEW_VERSION)"/' $(SCRIPT_SOURCE)
	@rm -f $(MAKEFILE_LIST).bak $(SCRIPT_SOURCE).bak
	@echo "✅ Version bumped to $(NEW_VERSION)"

.PHONY: bump-major
bump-major: ## Bump major version
	@echo "Bumping major version..."
	@$(eval NEW_VERSION := $(shell echo $(PROJECT_VERSION) | awk -F. '{print $$1+1".0.0"}'))
	@sed -i.bak 's/PROJECT_VERSION := $(PROJECT_VERSION)/PROJECT_VERSION := $(NEW_VERSION)/' $(MAKEFILE_LIST)
	@sed -i.bak 's/readonly SCRIPT_VERSION="$(PROJECT_VERSION)"/readonly SCRIPT_VERSION="$(NEW_VERSION)"/' $(SCRIPT_SOURCE)
	@rm -f $(MAKEFILE_LIST).bak $(SCRIPT_SOURCE).bak
	@echo "✅ Version bumped to $(NEW_VERSION)"

# ===============================================================================
# Git Integration
# ===============================================================================

.PHONY: git-hooks
git-hooks: ## Install git hooks
	@echo "Installing git hooks..."
	@mkdir -p .git/hooks
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo 'make check' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed"

.PHONY: git-tag
git-tag: ## Create git tag for current version
	@echo "Creating git tag v$(PROJECT_VERSION)..."
	@$(GIT) tag -a "v$(PROJECT_VERSION)" -m "Release v$(PROJECT_VERSION)"
	@echo "✅ Git tag v$(PROJECT_VERSION) created"

.PHONY: git-push-tags
git-push-tags: ## Push git tags
	@echo "Pushing git tags..."
	@$(GIT) push --tags
	@echo "✅ Git tags pushed"

# ===============================================================================
# Dependencies
# ===============================================================================

.PHONY: deps
deps: ## Show dependency information
	@echo "Dependencies:"
	@echo "  Required:"
	@echo "    - bash (shell)"
	@echo "    - curl (network)"
	@echo "    - git (version control)"
	@echo "    - brew (package manager)"
	@echo "  Development:"
	@echo "    - shellcheck (linting)"
	@echo "    - shfmt (formatting)"
	@echo "    - make (build system)"

.PHONY: deps-check
deps-check: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v bash >/dev/null 2>&1 || { echo "❌ bash not found"; exit 1; }
	@command -v curl >/dev/null 2>&1 || { echo "❌ curl not found"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "❌ git not found"; exit 1; }
	@command -v brew >/dev/null 2>&1 || { echo "❌ brew not found"; exit 1; }
	@echo "✅ All required dependencies found"

# ===============================================================================
# Utilities
# ===============================================================================

.PHONY: info
info: ## Show project information
	@echo "Project Information:"
	@echo "  Name: $(PROJECT_NAME)"
	@echo "  Version: $(PROJECT_VERSION)"
	@echo "  Author: $(PROJECT_AUTHOR)"
	@echo "  Description: $(PROJECT_DESCRIPTION)"
	@echo "  Script: $(SCRIPT_SOURCE)"
	@echo "  Source files: $(words $(LIB_FILES) $(MODULE_FILES))"
	@echo "  Test files: $(words $(TEST_FILES))"

.PHONY: stats
stats: ## Show code statistics
	@echo "Code Statistics:"
	@echo "  Lines of code: $$(wc -l $(SCRIPT_SOURCE) $(LIB_FILES) $(MODULE_FILES) | tail -1 | awk '{print $$1}')"
	@echo "  Files: $(words $(SCRIPT_SOURCE) $(LIB_FILES) $(MODULE_FILES))"
	@echo "  Functions: $$(grep -c '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()' $(SCRIPT_SOURCE) $(LIB_FILES) $(MODULE_FILES) 2>/dev/null || echo 0)"

.PHONY: validate
validate: ## Validate project structure
	@echo "Validating project structure..."
	@[ -f "$(SCRIPT_SOURCE)" ] || { echo "❌ Main script not found: $(SCRIPT_SOURCE)"; exit 1; }
	@[ -d "$(SRC_DIR)" ] || { echo "❌ Source directory not found: $(SRC_DIR)"; exit 1; }
	@[ -d "$(LIB_DIR)" ] || { echo "❌ Library directory not found: $(LIB_DIR)"; exit 1; }
	@[ -d "$(MODULES_DIR)" ] || { echo "❌ Modules directory not found: $(MODULES_DIR)"; exit 1; }
	@echo "✅ Project structure is valid"

# ===============================================================================
# Phony Targets
# ===============================================================================

.PHONY: all
all: setup test build ## Run all targets (setup, test, build)

.PHONY: ci
ci: deps-check test lint format-check ## Run CI pipeline

.PHONY: release-prep
release-prep: clean test lint format-check build package ## Prepare for release

.PHONY: install-dev
install-dev: setup setup-dev ## Install development environment

.PHONY: shellcheck
shellcheck: lint ## Alias for lint target

.PHONY: shfmt
shfmt: format ## Alias for format target

.PHONY: test-all
test-all: test ## Alias for test target

.PHONY: check-all
check-all: check ## Alias for check target 