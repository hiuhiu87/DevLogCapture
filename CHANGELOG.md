# Changelog

All notable changes to DevLogCapture will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- Nothing yet

## [1.0.0] - 2024-06-27

### Added
- Initial release of DevLogCapture framework
- Real-time console log capture functionality
- Built-in HTTP server on port 8080
- Smart filtering system to reduce noise from system logs
- JSON API endpoints for log access (`/logs`, `/clear`)
- CORS support for cross-origin web requests
- Thread-safe log processing with dedicated queues
- Automatic IP address detection and display
- Custom filter pattern management (add/remove patterns)
- Memory management with automatic log rotation
- Structured logging support (EP_LOG format)
- Comprehensive documentation with DocC
- Example HTML client for viewing logs
- Performance optimizations for minimal app impact

### Features
- **ConsoleCapture**: Main class for log interception
- **HTTPServer**: Internal server for serving logs
- **Smart Filtering**: Built-in filters for common noise patterns
- **Buffer Management**: Efficient handling of large log volumes
- **Network Discovery**: Automatic device IP detection
- **Development Safety**: Designed for debug builds only

### Built-in Filters
- Network-related logs (nw_connection, tcp_*, boringssl, etc.)
- URLSession and CFNetwork logs
- Debug/verbose/trace level logs
- Logs with excessive special characters
- Short or repetitive log entries

### Documentation
- Complete API reference with DocC
- Installation guide with multiple options
- Quick start tutorial
- Advanced configuration examples
- Best practices for secure usage
- Network access and CORS documentation
- Troubleshooting guide
- Performance optimization tips

### Security
- Development-only design with conditional compilation
- Sensitive data filtering recommendations
- Local network only access
- No authentication (intended for development use)

### Compatibility
- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

[Unreleased]: https://github.com/your-username/DevLogCapture/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-username/DevLogCapture/releases/tag/v1.0.0
