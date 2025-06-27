# Contributing to DevLogCapture

Thank you for your interest in contributing to DevLogCapture! We welcome contributions from the community and appreciate your help in making this framework better.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. **Check existing issues** to see if it's already reported
2. **Create a new issue** with a clear title and description
3. **Include relevant details**:
   - iOS version
   - Xcode version
   - Device type (simulator/physical)
   - Steps to reproduce
   - Expected vs actual behavior
   - Sample code if applicable

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following our coding standards
4. **Add tests** for new functionality
5. **Update documentation** if needed
6. **Commit your changes** with clear messages
7. **Push to your fork** and submit a pull request

### Pull Request Guidelines

- **Clear title and description** of changes
- **Reference related issues** using keywords (fixes #123)
- **Keep changes focused** - one feature per PR
- **Include tests** for new functionality
- **Update documentation** for API changes
- **Ensure all tests pass**
- **Follow coding style** guidelines

## Development Setup

### Prerequisites

- Xcode 12.0+
- iOS 13.0+ deployment target
- Swift 5.0+

### Setup Instructions

1. Clone your fork:
   ```bash
   git clone https://github.com/your-username/DevLogCapture.git
   cd DevLogCapture
   ```

2. Open in Xcode:
   ```bash
   open DevLogCapture.xcodeproj
   ```

3. Build and run tests:
   - Press `Cmd+U` to run unit tests
   - Ensure all tests pass before making changes

### Project Structure

```
DevLogCapture/
├── DevLogCapture/              # Main framework code
│   ├── DevLogCapture.swift     # Framework entry point
│   ├── ConsoleCapture.swift    # Main capture logic
│   ├── HTTPServer.swift        # HTTP server implementation
│   └── DevLogCapture.docc/     # Documentation
├── Tests/                      # Unit tests
├── Examples/                   # Example projects
└── Documentation/              # Additional docs
```

## Coding Standards

### Swift Style Guide

Follow these conventions:

```swift
// ✅ Good
class ConsoleCapture {
    private let server = HTTPServer()
    private var isCapturing = false
    
    public func start() {
        // Implementation
    }
    
    private func processLogData(_ data: Data) {
        // Implementation
    }
}

// ❌ Avoid
class consolecapture {
    var Server: HTTPServer!
    var isCapturing: Bool = false
    
    func Start() {
        // Implementation
    }
}
```

### Naming Conventions

- **Classes**: PascalCase (`ConsoleCapture`)
- **Methods/Variables**: camelCase (`startCapture`)
- **Constants**: camelCase (`maxLogCount`)
- **Private members**: prefix with underscore if needed (`_internalState`)

### Documentation

- Use Swift's documentation comments (`///` or `/** */`)
- Document all public APIs
- Include code examples where helpful
- Update DocC documentation for new features

```swift
/**
 Starts console log capture and HTTP server.
 
 This method begins intercepting stdout and starts serving logs
 via HTTP on port 8080.
 
 - Warning: Only use in development builds
 - Note: Safe to call multiple times
 
 Example:
 ```swift
 let capture = ConsoleCapture()
 capture.start()
 ```
 */
public func start() {
    // Implementation
}
```

### Error Handling

- Use proper error handling with `Result<T, Error>` or throwing functions
- Avoid force unwrapping (`!`) in production code
- Handle edge cases gracefully

```swift
// ✅ Good
func parseLogData(_ data: Data) -> Result<LogEntry, LogError> {
    guard let string = String(data: data, encoding: .utf8) else {
        return .failure(.invalidEncoding)
    }
    
    // Parse logic...
    return .success(logEntry)
}

// ❌ Avoid
func parseLogData(_ data: Data) -> LogEntry {
    let string = String(data: data, encoding: .utf8)! // Could crash
    // Parse logic...
}
```

## Testing Guidelines

### Unit Tests

- Write tests for all public APIs
- Test edge cases and error conditions
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

```swift
func testAddFilterPattern_AddsNewPattern() {
    // Arrange
    let capture = ConsoleCapture()
    let pattern = "test_pattern"
    
    // Act
    capture.addFilterPattern(pattern)
    
    // Assert
    XCTAssertTrue(capture.getFilterPatterns().contains(pattern))
}
```

### Integration Tests

- Test actual log capture functionality
- Verify HTTP server behavior
- Test on both simulator and device

### Performance Tests

- Measure impact on app performance
- Test with large log volumes
- Verify memory usage stays reasonable

## Documentation

### DocC Documentation

Update documentation in `.docc` files:

- Keep examples current
- Update API references
- Add screenshots if helpful
- Test documentation builds

### README Updates

- Update feature lists
- Add new examples
- Update version compatibility
- Keep installation instructions current

## Release Process

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes, backward compatible

### Before Release

1. Update `CHANGELOG.md`
2. Update version numbers
3. Update documentation
4. Run all tests
5. Test on multiple iOS versions
6. Verify examples work

## Types of Contributions

### Bug Fixes

- Fix crashes or incorrect behavior
- Improve error handling
- Performance improvements
- Memory leak fixes

### Features

- New log filtering options
- Additional HTTP endpoints
- Enhanced web client
- Performance optimizations

### Documentation

- Improve existing docs
- Add code examples
- Create tutorials
- Fix typos

### Testing

- Add missing test coverage
- Improve test reliability
- Add performance tests
- Create integration tests

## Recognition

Contributors will be recognized in:

- `CONTRIBUTORS.md` file
- Release notes
- Documentation credits

## Questions?

- Open an issue for general questions
- Check existing documentation
- Review closed issues for similar problems

Thank you for contributing to DevLogCapture! 🎉
