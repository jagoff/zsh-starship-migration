# Error Logging System

## Overview

The zsh-starship-migration project includes a comprehensive error logging system that captures all errors and fatal messages in a dedicated `error.log` file. This system is designed to help with debugging and troubleshooting issues during migration.

## Features

- **Automatic Error Capture**: All `log_error()` and `log_fatal()` calls are automatically captured
- **Detailed Context**: Each error entry includes timestamp, script location, and stack trace
- **Log Rotation**: Automatic rotation when log file exceeds 10MB (configurable)
- **Search and Analysis**: Built-in tools for searching and analyzing error logs
- **Real-time Monitoring**: Monitor errors as they occur

## Configuration

### Environment Variables

You can customize the error logging behavior using these environment variables:

```bash
# Error log file location (default: error.log)
export ERROR_LOG_FILE="/path/to/your/error.log"

# Maximum log file size in bytes (default: 10485760 = 10MB)
export ERROR_LOG_MAX_SIZE="20971520"

# Maximum number of backup files (default: 5)
export ERROR_LOG_MAX_FILES="10"
```

### Log Levels

The error log captures messages at these levels:
- `ERROR`: Non-fatal errors that don't stop execution
- `FATAL`: Fatal errors that cause script termination

## Usage

### Command Line Interface

The script provides several commands for managing error logs:

```bash
# Show recent error log entries (default: last 20)
./zsh-starship-migration.sh error-log [COUNT]

# Show error log statistics
./zsh-starship-migration.sh error-stats

# Clear error log
./zsh-starship-migration.sh error-clear

# Search errors by pattern
./zsh-starship-migration.sh error-search "pattern"
```

### Makefile Commands

You can also use Makefile targets for error log management:

```bash
# Show recent errors
make error-log

# Show statistics
make error-stats

# Clear error log
make error-clear

# Search errors (specify pattern)
make error-search PATTERN="starship"

# Test error logging
make error-test

# Monitor errors in real-time
make error-monitor
```

## Error Log Format

Each error entry in the log file follows this format:

```
[2024-01-15 14:30:25.123] ERROR [script_name:line_number]: Error message | Context: PWD: /path/to/script USER: username SCRIPT: script_name ARGS: arg1 arg2 | Stack: function1 function2 main
```

### Components

- **Timestamp**: Precise timestamp with milliseconds
- **Level**: ERROR or FATAL
- **Script Info**: Script name and line number where error occurred
- **Message**: The actual error message
- **Context**: Current working directory, user, script name, and arguments
- **Stack**: Function call stack (for debugging)

## Examples

### Basic Error Logging

```bash
# In your script
log_error "Failed to install Starship"
log_fatal "Critical system requirement not met"
```

### Error Log Output

```
[2024-01-15 14:30:25.123] ERROR [zsh-starship-migration:156]: Failed to install Starship | Context: PWD: /Users/fer/repositories/zsh-starship-migration USER: fer SCRIPT: zsh-starship-migration ARGS: --auto | Stack: install_starship perform_migration main
```

### Searching Errors

```bash
# Search for all Starship-related errors
./zsh-starship-migration.sh error-search "starship"

# Search for fatal errors
./zsh-starship-migration.sh error-search "FATAL"

# Search for errors from specific function
./zsh-starship-migration.sh error-search "install_starship"
```

## Best Practices

### 1. Use Descriptive Error Messages

```bash
# Good
log_error "Failed to create backup directory: $backup_dir (Permission denied)"

# Bad
log_error "Backup failed"
```

### 2. Include Relevant Context

```bash
# The system automatically includes context, but you can add more
log_error "Configuration validation failed for key: $config_key"
```

### 3. Use Appropriate Log Levels

```bash
# Use ERROR for recoverable issues
log_error "Plugin installation failed, continuing without it"

# Use FATAL for unrecoverable issues
log_fatal "Required dependency 'starship' not found"
```

### 4. Monitor Error Logs Regularly

```bash
# Check for new errors
make error-stats

# Monitor in real-time during development
make error-monitor
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the script has write permissions to the error log directory
2. **Disk Space**: Large error logs can consume disk space; use rotation settings
3. **Encoding Issues**: Error log uses UTF-8 encoding; ensure terminal supports it

### Debugging Tips

1. **Check Error Context**: Look at the context information to understand the environment
2. **Follow Stack Trace**: Use the stack trace to trace the error back to its source
3. **Search Patterns**: Use search to find related errors or specific error types
4. **Monitor Real-time**: Use `make error-monitor` to see errors as they occur

### Error Log Analysis

```bash
# Get error statistics
make error-stats

# Find most common errors
grep "ERROR" error.log | cut -d'|' -f1 | sort | uniq -c | sort -nr

# Find errors from today
grep "$(date +%Y-%m-%d)" error.log

# Find errors by user
grep "USER: $USER" error.log
```

## Integration with Development Workflow

### Pre-commit Checks

Add error log checks to your development workflow:

```bash
# In your pre-commit hook
if [ -f error.log ] && [ -s error.log ]; then
    echo "Warning: Error log contains entries"
    make error-stats
fi
```

### CI/CD Integration

Include error log analysis in your CI pipeline:

```yaml
# Example GitHub Actions step
- name: Analyze Error Logs
  run: |
    if [ -f error.log ]; then
      echo "Error log analysis:"
      make error-stats
      echo "Recent errors:"
      make error-log
    fi
```

## Advanced Usage

### Custom Error Log Location

```bash
# Set custom error log location
export ERROR_LOG_FILE="/var/log/zsh-migration/errors.log"
./zsh-starship-migration.sh migrate
```

### Error Log Rotation

The system automatically rotates logs when they exceed the size limit:

```bash
# Check current log size
ls -lh error.log

# Manual rotation (if needed)
mv error.log error.log.old
touch error.log
```

### Error Log Archiving

```bash
# Archive old error logs
tar -czf error-logs-$(date +%Y%m%d).tar.gz error.log*

# Clean up old archives
find . -name "error-logs-*.tar.gz" -mtime +30 -delete
```

## API Reference

### Logger Functions

```bash
# Log an error (captured in error.log)
log_error "Error message"

# Log a fatal error and exit (captured in error.log)
log_fatal "Fatal error message"

# Log with custom exit code
FATAL_EXIT_CODE=2 log_fatal "Custom exit code error"
```

### Error Log Management Functions

```bash
# Initialize error log
init_error_log

# Get error log path
get_error_log_path

# Show statistics
show_error_log_stats

# Clear error log
clear_error_log

# Show recent errors
show_recent_errors [COUNT]

# Search errors
search_errors "PATTERN"
```

## Migration from Previous Versions

If you're upgrading from a previous version without error logging:

1. The error log will be automatically created on first run
2. No migration of existing logs is needed
3. New errors will be captured in the new format
4. Old error handling remains compatible

## Support

For issues with the error logging system:

1. Check the error log itself for internal errors
2. Verify file permissions and disk space
3. Review the configuration variables
4. Test with the provided test script: `make error-test`

## Contributing

When contributing to the error logging system:

1. Follow the existing format for error messages
2. Include appropriate context information
3. Test error scenarios thoroughly
4. Update this documentation for new features 