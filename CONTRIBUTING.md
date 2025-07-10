# Contributing to Universal Shell GUI Framework

Thank you for your interest in contributing to the Universal Shell GUI Framework! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### 1. Fork and Clone
```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/universal-shell-gui-framework.git
cd universal-shell-gui-framework
```

### 2. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 3. Make Your Changes
- Follow the coding standards below
- Add tests if applicable
- Update documentation as needed
- Keep commits atomic and well-described

### 4. Test Your Changes
```bash
# Test the framework
source gui_framework.sh
init_gui_framework

# Run the demo
./examples/demo_quit_functionality.sh
```

### 5. Commit and Push
```bash
git add .
git commit -m "feat: add new GUI component for file selection"
git push origin feature/your-feature-name
```

### 6. Create a Pull Request
- Go to your fork on GitHub
- Click "New Pull Request"
- Fill out the PR template
- Wait for review

## 📋 Pull Request Guidelines

### PR Title Format
Use conventional commit format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests
- `chore:` for maintenance tasks

### PR Description Template
```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested this change locally
- [ ] I have added tests for this change
- [ ] All existing tests pass

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

## 🎨 Coding Standards

### Shell Script Standards
- Use `#!/bin/bash` shebang for bash scripts
- Use `#!/usr/bin/env zsh` for zsh scripts
- Follow [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use meaningful variable names
- Add comments for complex logic

### Framework Standards
- All functions must be prefixed with `show_gui_` for GUI components
- Use the universal color variables (`C_RED`, `C_GREEN`, etc.)
- Include TTY detection for interactive components
- Support 'q' quit functionality in all interactive components
- Use English for all user-facing text

### Example Function Template
```bash
show_gui_new_component() {
    require_tty
    local title="$1"
    local subtitle="$2"
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    echo -e "${C_GRAY}←→ toggle • enter submit • q Quit${C_NC}"
    
    # Your component logic here
    
    # Handle quit functionality
    if [[ -z "$result" ]]; then
        handle_quit "Component cancelled by user"
    fi
    
    echo "$result"
}
```

## 🧪 Testing Guidelines

### Manual Testing
- Test on both bash and zsh
- Test with different gum versions
- Test in interactive and non-interactive terminals
- Test quit functionality ('q' key)
- Test error conditions

### Automated Testing
- Add tests to `/tests` directory
- Use descriptive test names
- Test both success and failure cases
- Ensure tests are portable across systems

## 📚 Documentation Standards

### Code Comments
- Use clear, concise comments
- Explain complex logic
- Document function parameters and return values
- Include usage examples for complex functions

### README Updates
- Update README.md for new features
- Add examples for new components
- Update version history
- Keep installation instructions current

### Documentation Files
- Update relevant docs in `/docs` directory
- Add new documentation files as needed
- Keep examples current and working

## 🐛 Bug Reports

### Before Submitting
- Check existing issues for duplicates
- Test with the latest version
- Try to reproduce the issue consistently

### Bug Report Template
```markdown
## Bug Description
Clear description of the bug.

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- OS: [e.g., macOS 14.0]
- Shell: [e.g., zsh 5.9]
- Gum Version: [e.g., 0.13.0]
- Framework Version: [e.g., 1.1.0]

## Additional Information
Any other context, logs, or screenshots.
```

## 💡 Feature Requests

### Before Submitting
- Check existing issues for similar requests
- Consider if the feature fits the framework's scope
- Think about implementation complexity

### Feature Request Template
```markdown
## Feature Description
Clear description of the feature.

## Use Case
Why this feature would be useful.

## Proposed Implementation
How you think it could be implemented.

## Alternatives Considered
Other approaches you considered.

## Additional Information
Any other context or examples.
```

## 🏷️ Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `question` - Further information is requested

## 📞 Getting Help

- Check the [documentation](docs/)
- Search existing [issues](../../issues)
- Create a new issue if needed
- Join our community discussions

## 🎉 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to the Universal Shell GUI Framework! 🎨 