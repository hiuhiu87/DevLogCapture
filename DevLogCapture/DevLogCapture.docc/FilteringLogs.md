# Filtering Logs

Master the art of log filtering to focus on what matters.

## Overview

DevLogCapture includes a sophisticated filtering system designed to reduce noise and help you focus on relevant logs. The framework automatically filters out system logs, network spam, and other low-value output while preserving your application's important messages.

## Built-in Filtering

### System Log Filters

The framework automatically filters out these common system log patterns:

```swift
private var filterPatterns = [
    "nw_connection",      // Network connection logs
    "nw_endpoint",        // Network endpoint logs
    "nw_resolver",        // DNS resolver logs
    "nw_path_evaluator",  // Network path evaluation
    "tcp_input",          // TCP input logs
    "tcp_output",         // TCP output logs
    "boringssl",          // SSL/TLS logs
    "[connection]",       // Connection status logs
    "[network]",          // General network logs
    "TIC Read Status",    // Network reading status
    "TIC TCP Conn",       // TCP connection logs
    "Task <",             // URLSession task logs
    "NSURLSession",       // URLSession logs
    "CFNetwork",          // Core Foundation network logs
    "HTTP load failed",   // HTTP error logs
    "Connection invalid", // Connection error logs
]
```

### Log Level Filters

These log levels are filtered out by default:

```swift
private let filterLogLevels = [
    "debug",
    "verbose", 
    "trace",
]
```

### Content-Based Filtering

The framework also applies intelligent content filtering:

- **Special Characters**: Logs with too many special characters (likely binary data)
- **Short Messages**: Logs shorter than 3 characters
- **Numeric Only**: Logs containing only numbers
- **Repetitive Content**: Logs with very low character diversity

## Custom Filtering

### Adding Filter Patterns

```swift
let consoleCapture = ConsoleCapture()

// Filter out specific libraries
consoleCapture.addFilterPattern("Alamofire")
consoleCapture.addFilterPattern("Firebase")

// Filter out specific log prefixes
consoleCapture.addFilterPattern("[ThirdPartySDK]")

// Filter out error codes you don't care about
consoleCapture.addFilterPattern("Error code: 404")

consoleCapture.start()
```

### Removing Filter Patterns

```swift
// Remove a built-in filter if you want to see those logs
consoleCapture.removeFilterPattern("nw_connection")

// Remove your custom filters
consoleCapture.removeFilterPattern("Alamofire")
```

### Viewing Current Filters

```swift
let currentFilters = consoleCapture.getFilterPatterns()
print("Active filters: \(currentFilters)")
```

## Structured Log Detection

### EP_LOG Format

DevLogCapture recognizes structured logs in this format:

```
EP_LOG - YYYY-MM-DD HH:mm:ss.SSSS - [LEVEL] Message
```

Logs matching this pattern are **always included**, regardless of other filters:

```swift
// This will always appear in the log capture
print("EP_LOG - 2024-06-27 14:30:45.1234 - [INFO] User authentication successful")
```

### Custom Structured Logging

Create a logging utility to ensure your important logs are captured:

```swift
class Logger {
    static func info(_ message: String) {
        log(message, level: "INFO")
    }
    
    static func warning(_ message: String) {
        log(message, level: "WARNING")
    }
    
    static func error(_ message: String) {
        log(message, level: "ERROR")
    }
    
    private static func log(_ message: String, level: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        print("EP_LOG - \(formatter.string(from: Date())) - [\(level)] \(message)")
    }
}

// Usage - these will always be captured
Logger.info("App started successfully")
Logger.warning("Low memory warning received")
Logger.error("Failed to connect to server")
```

## Advanced Filtering Strategies

### Environment-Specific Filtering

```swift
class LogFilter {
    static func setupFilters(for environment: AppEnvironment) {
        let consoleCapture = ConsoleCapture()
        
        switch environment {
        case .development:
            // In development, filter less to see more details
            consoleCapture.removeFilterPattern("debug")
            
        case .staging:
            // In staging, filter moderately
            consoleCapture.addFilterPattern("DetailedDebugInfo")
            
        case .production:
            // This should never run in production, but just in case
            consoleCapture.addFilterPattern(".*") // Filter everything
        }
    }
}
```

### Feature-Based Filtering

```swift
class FeatureLogger {
    enum Feature: String {
        case authentication = "AUTH"
        case networking = "NET"
        case caching = "CACHE"
        case ui = "UI"
        case analytics = "ANALYTICS"
    }
    
    static func log(_ message: String, feature: Feature, level: String = "INFO") {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        print("EP_LOG - \(formatter.string(from: Date())) - [\(level)] [\(feature.rawValue)] \(message)")
    }
}

// Usage
FeatureLogger.log("User login attempt", feature: .authentication)
FeatureLogger.log("API request started", feature: .networking)
FeatureLogger.log("Cache miss for user data", feature: .caching)
```

### Dynamic Filtering

```swift
class DynamicLogFilter {
    private var enabledFeatures: Set<String> = ["AUTH", "NET"]
    
    func shouldLog(message: String) -> Bool {
        // Custom logic to determine if a log should be included
        for feature in enabledFeatures {
            if message.contains("[\(feature)]") {
                return true
            }
        }
        return false
    }
    
    func enableFeature(_ feature: String) {
        enabledFeatures.insert(feature)
    }
    
    func disableFeature(_ feature: String) {
        enabledFeatures.remove(feature)
    }
}
```

## Performance Impact

### Filter Evaluation

Filters are evaluated in this order for optimal performance:

1. **Empty check**: Skip empty logs immediately
2. **Structured log check**: EP_LOG format logs bypass other filters
3. **Pattern matching**: Check against filter patterns
4. **Content analysis**: Analyze character composition and length

### Optimization Tips

- **Use specific patterns**: `MyFramework.error` is better than `error`
- **Avoid regex**: The framework uses simple string matching for performance
- **Minimize custom filters**: Each additional filter adds processing overhead

## Common Filtering Scenarios

### Mobile Development

```swift
// Filter out iOS simulator noise
consoleCapture.addFilterPattern("SimulatorKit")
consoleCapture.addFilterPattern("CoreSimulator")

// Filter out Xcode debugging output
consoleCapture.addFilterPattern("Xcode")
consoleCapture.addFilterPattern("lldb")
```

### Third-Party Libraries

```swift
// Analytics libraries
consoleCapture.addFilterPattern("Firebase")
consoleCapture.addFilterPattern("Mixpanel")
consoleCapture.addFilterPattern("Amplitude")

// Networking libraries
consoleCapture.addFilterPattern("Alamofire")
consoleCapture.addFilterPattern("URLSession")

// UI frameworks
consoleCapture.addFilterPattern("SnapKit")
consoleCapture.addFilterPattern("Kingfisher")
```

### Development Tools

```swift
// React Native / Flutter (if using hybrid apps)
consoleCapture.addFilterPattern("ReactNative")
consoleCapture.addFilterPattern("Flutter")

// Build tools
consoleCapture.addFilterPattern("CocoaPods")
consoleCapture.addFilterPattern("SwiftPackageManager")
```

## Best Practices

1. **Start Conservative**: Begin with aggressive filtering and gradually reduce
2. **Use Structured Logs**: For important logs, use the EP_LOG format
3. **Test Your Filters**: Verify that important logs aren't being filtered out
4. **Document Custom Filters**: Keep track of what you're filtering and why
5. **Environment-Specific**: Use different filtering strategies for different environments

## Troubleshooting

### Missing Important Logs

If you're not seeing logs you expect:

```swift
// Check current filters
let filters = consoleCapture.getFilterPatterns()
print("Current filters: \(filters)")

// Temporarily remove all custom filters
for pattern in filters {
    consoleCapture.removeFilterPattern(pattern)
}
```

### Too Many Logs

If you're seeing too much noise:

```swift
// Add more aggressive filtering
consoleCapture.addFilterPattern("YourNoisyLibrary")

// Or use structured logging for important messages
Logger.info("This will always be visible")
```

## Next Steps

- <doc:NetworkAccess> - Configure network access and security
- <doc:BestPractices> - Learn production best practices
