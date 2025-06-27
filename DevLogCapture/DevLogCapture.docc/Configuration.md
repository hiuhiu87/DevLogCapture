# Configuration

Customize DevLogCapture to fit your development workflow.

## Server Configuration

### Custom Port

By default, the HTTP server runs on port 8080. You can customize this by modifying the `HTTPServer` class:

```swift
// In your custom implementation
let server = HTTPServer()
server.startServer(on: 9090) // Use port 9090 instead
```

### Network Interface

The server automatically binds to all available network interfaces. For security, you might want to restrict this to localhost only during development.

## Log Filtering

DevLogCapture includes intelligent filtering to reduce noise from system logs. You can customize these filters:

### Adding Custom Filter Patterns

```swift
let consoleCapture = ConsoleCapture()

// Add custom patterns to filter out
consoleCapture.addFilterPattern("MyLibrary")
consoleCapture.addFilterPattern("ThirdPartySDK")
consoleCapture.addFilterPattern("unnecessary_debug")

consoleCapture.start()
```

### Removing Filter Patterns

```swift
// Remove a specific filter pattern
consoleCapture.removeFilterPattern("nw_connection")

// View all current filter patterns
let patterns = consoleCapture.getFilterPatterns()
print("Current filters: \(patterns)")
```

### Built-in Filters

The framework comes with sensible defaults that filter out:

**Network-related logs:**
- `nw_connection`
- `nw_endpoint`
- `nw_resolver`
- `nw_path_evaluator`
- `tcp_input`
- `tcp_output`
- `boringssl`

**HTTP/URLSession logs:**
- `NSURLSession`
- `CFNetwork`
- `HTTP load failed`
- `Connection invalid`

**Low-level debug logs:**
- `debug` level logs
- `verbose` level logs
- `trace` level logs

## Custom Log Formatting

### Using Structured Logging

DevLogCapture can detect and handle structured logs. Use a consistent format for better parsing:

```swift
// Recommended format for structured logs
func logMessage(_ message: String, level: String = "INFO") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    print("EP_LOG - \(formatter.string(from: Date())) - [\(level)] \(message)")
}

// Usage
logMessage("User logged in", level: "INFO")
logMessage("API call failed", level: "ERROR")
logMessage("Cache updated", level: "DEBUG")
```

### Custom Log Levels

Define custom log levels for your application:

```swift
enum LogLevel: String {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

func log(_ message: String, level: LogLevel = .info) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    print("EP_LOG - \(formatter.string(from: Date())) - [\(level.rawValue)] \(message)")
}
```

## Memory Management

### Log Buffer Size

DevLogCapture maintains a buffer of the most recent logs. You can configure this by modifying the `HTTPServer` class:

```swift
// In HTTPServer.swift, modify the addLog method
func addLog(_ message: String, level: String = "INFO") {
    queue.async {
        // ... existing code ...
        
        self.logs.append(logEntry)
        
        // Change this value to keep more or fewer logs
        if self.logs.count > 500 { // Default is 100
            self.logs.removeFirst(self.logs.count - 500)
        }
    }
}
```

### Buffer Overflow Handling

The framework automatically handles buffer overflow by:
1. Processing logs in chunks when buffer exceeds 16KB
2. Splitting large log entries with `[PARTIAL]` markers
3. Maintaining thread-safe operations

## Development vs Production

### Conditional Compilation

Always wrap DevLogCapture usage in conditional compilation flags:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    #if DEBUG
    let consoleCapture = ConsoleCapture()
    #endif
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        consoleCapture.start()
        #endif
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        #if DEBUG
        consoleCapture.stop()
        #endif
    }
}
```

### Build Configuration

You can also use build configurations to enable/disable features:

```swift
#if DEBUG || INTERNAL_BUILD
consoleCapture.start()
#endif
```

## Performance Considerations

### Background Queue Usage

DevLogCapture uses dedicated queues for performance:
- **Buffer Queue**: Processes log data (`com.consolecapture.buffer`)
- **Server Queue**: Handles HTTP requests (`server.queue`)
- **Connections Queue**: Manages client connections (`connections.queue`)

### CPU Usage

The framework is designed to have minimal impact on your app's performance:
- Asynchronous log processing
- Efficient string operations
- Smart filtering to reduce processing overhead

### Memory Usage

- Logs are limited to the most recent entries (configurable)
- Automatic cleanup of old logs
- Efficient buffer management for large log entries

## Next Steps

- <doc:FilteringLogs> - Deep dive into log filtering
- <doc:NetworkAccess> - Configure network access
- <doc:BestPractices> - Learn best practices for production use
