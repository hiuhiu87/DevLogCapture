# Best Practices

Essential guidelines for using DevLogCapture effectively and safely.

## Development Workflow

### Environment Separation

Always separate development and production builds:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    #if DEBUG || INTERNAL_BUILD
    let consoleCapture = ConsoleCapture()
    #endif
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setupLogging()
        
        return true
    }
    
    private func setupLogging() {
        #if DEBUG
        // Full logging for development
        consoleCapture.start()
        print("🔧 Development mode: Full logging enabled")
        
        #elseif INTERNAL_BUILD
        // Limited logging for internal testing
        consoleCapture.addFilterPattern("verbose")
        consoleCapture.start()
        print("🧪 Internal build: Filtered logging enabled")
        
        #else
        // No logging for production
        print("🚀 Production mode: No log capture")
        #endif
    }
}
```

### Build Configurations

Set up proper build configurations in Xcode:

1. **DEBUG**: Full logging, minimal filtering
2. **INTERNAL**: Moderate logging, some filtering
3. **RELEASE**: No DevLogCapture at all

```swift
// In your build settings, define custom flags
#if DEBUG
    #define ENABLE_LOG_CAPTURE 1
    #define LOG_LEVEL_VERBOSE 1
#elseif INTERNAL
    #define ENABLE_LOG_CAPTURE 1
    #define LOG_LEVEL_INFO 1
#else
    // Production - no logging flags
#endif
```

## Logging Strategy

### Structured Logging

Use a consistent logging format for better parsing and filtering:

```swift
protocol LoggerProtocol {
    func log(_ message: String, level: LogLevel, category: LogCategory)
}

enum LogLevel: String, CaseIterable {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

enum LogCategory: String, CaseIterable {
    case app = "APP"
    case network = "NET"
    case database = "DB"
    case auth = "AUTH"
    case ui = "UI"
    case analytics = "ANALYTICS"
}

class AppLogger: LoggerProtocol {
    static let shared = AppLogger()
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return formatter
    }()
    
    func log(_ message: String, level: LogLevel = .info, category: LogCategory = .app) {
        let timestamp = formatter.string(from: Date())
        print("EP_LOG - \(timestamp) - [\(level.rawValue)] [\(category.rawValue)] \(message)")
    }
    
    // Convenience methods
    func info(_ message: String, category: LogCategory = .app) {
        log(message, level: .info, category: category)
    }
    
    func warning(_ message: String, category: LogCategory = .app) {
        log(message, level: .warning, category: category)
    }
    
    func error(_ message: String, category: LogCategory = .app) {
        log(message, level: .error, category: category)
    }
}

// Usage
AppLogger.shared.info("User login successful", category: .auth)
AppLogger.shared.warning("API rate limit approaching", category: .network)
AppLogger.shared.error("Database connection failed", category: .database)
```

### Contextual Information

Include relevant context in your logs:

```swift
extension AppLogger {
    func logUserAction(_ action: String, userId: String? = nil, metadata: [String: Any] = [:]) {
        var message = "User action: \(action)"
        
        if let userId = userId {
            message += " | User: \(userId)"
        }
        
        if !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            message += " | \(metadataString)"
        }
        
        log(message, level: .info, category: .analytics)
    }
    
    func logNetworkRequest(_ url: String, method: String, statusCode: Int? = nil, duration: TimeInterval? = nil) {
        var message = "\(method) \(url)"
        
        if let statusCode = statusCode {
            message += " | Status: \(statusCode)"
        }
        
        if let duration = duration {
            message += " | Duration: \(String(format: "%.3f", duration))s"
        }
        
        let level: LogLevel = {
            guard let code = statusCode else { return .info }
            if code >= 400 { return .error }
            if code >= 300 { return .warning }
            return .info
        }()
        
        log(message, level: level, category: .network)
    }
}

// Usage
AppLogger.shared.logUserAction("login", userId: "user123", metadata: ["method": "oauth", "provider": "google"])
AppLogger.shared.logNetworkRequest("https://api.example.com/users", method: "GET", statusCode: 200, duration: 0.45)
```

## Security Best Practices

### Sensitive Data Protection

Never log sensitive information:

```swift
class SecureLogger {
    private static let sensitivePatterns = [
        "password", "token", "key", "secret", "credential",
        "ssn", "credit", "card", "bank", "account"
    ]
    
    static func sanitize(_ message: String) -> String {
        var sanitized = message
        
        // Remove common sensitive patterns
        for pattern in sensitivePatterns {
            let regex = try? NSRegularExpression(pattern: "\\b\(pattern)[\\s=:]*[\\w\\d]+", options: .caseInsensitive)
            sanitized = regex?.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: NSRange(location: 0, length: sanitized.count),
                withTemplate: "\(pattern): [REDACTED]"
            ) ?? sanitized
        }
        
        // Mask email addresses
        sanitized = sanitized.replacingOccurrences(
            of: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#,
            with: "[EMAIL_REDACTED]",
            options: .regularExpression
        )
        
        return sanitized
    }
}

// Safe logging wrapper
extension AppLogger {
    func safelog(_ message: String, level: LogLevel = .info, category: LogCategory = .app) {
        let sanitized = SecureLogger.sanitize(message)
        log(sanitized, level: level, category: category)
    }
}
```

### Network Security

Implement additional security measures:

```swift
class SecureHTTPServer: HTTPServer {
    private let allowedIPs: Set<String> = ["127.0.0.1", "::1"] // Only localhost
    private let rateLimiter = RateLimiter()
    
    override func handleConnection(_ connection: NWConnection) {
        // IP-based access control
        guard isAllowedConnection(connection) else {
            connection.cancel()
            return
        }
        
        // Rate limiting
        guard rateLimiter.allowRequest() else {
            sendRateLimitResponse(connection)
            return
        }
        
        super.handleConnection(connection)
    }
    
    private func isAllowedConnection(_ connection: NWConnection) -> Bool {
        // Implementation depends on your security requirements
        return true // Simplified for example
    }
}

class RateLimiter {
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]
    private let maxRequests = 100
    private let timeWindow: TimeInterval = 60 // 1 minute
    
    func allowRequest(for ip: String = "default") -> Bool {
        let now = Date()
        
        if let record = requestCounts[ip] {
            if now > record.resetTime {
                requestCounts[ip] = (count: 1, resetTime: now.addingTimeInterval(timeWindow))
                return true
            } else if record.count < maxRequests {
                requestCounts[ip] = (count: record.count + 1, resetTime: record.resetTime)
                return true
            } else {
                return false
            }
        } else {
            requestCounts[ip] = (count: 1, resetTime: now.addingTimeInterval(timeWindow))
            return true
        }
    }
}
```

## Performance Optimization

### Asynchronous Logging

Avoid blocking the main thread:

```swift
class AsyncLogger {
    private let loggingQueue = DispatchQueue(label: "app.logging", qos: .utility)
    private let logBuffer = NSMutableArray()
    private let bufferLock = NSLock()
    
    func log(_ message: String, level: LogLevel = .info) {
        loggingQueue.async {
            let logEntry = self.createLogEntry(message, level: level)
            
            self.bufferLock.lock()
            self.logBuffer.add(logEntry)
            
            // Flush buffer if it gets too large
            if self.logBuffer.count > 50 {
                self.flushBuffer()
            }
            self.bufferLock.unlock()
        }
    }
    
    private func flushBuffer() {
        let entries = logBuffer.copy() as! NSArray
        logBuffer.removeAllObjects()
        
        entries.forEach { entry in
            if let logString = entry as? String {
                print(logString)
            }
        }
    }
    
    private func createLogEntry(_ message: String, level: LogLevel) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return "EP_LOG - \(formatter.string(from: Date())) - [\(level.rawValue)] \(message)"
    }
}
```

### Memory Management

Monitor and manage memory usage:

```swift
class MemoryAwareLogger {
    private let maxLogCount = 1000
    private let maxBufferSize = 1024 * 1024 // 1MB
    private var currentBufferSize = 0
    
    func addLog(_ message: String) {
        let messageSize = message.utf8.count
        
        // Check memory constraints
        if logs.count >= maxLogCount || currentBufferSize + messageSize > maxBufferSize {
            compactLogs()
        }
        
        logs.append(message)
        currentBufferSize += messageSize
    }
    
    private func compactLogs() {
        // Keep only the most recent 50% of logs
        let keepCount = logs.count / 2
        if keepCount > 0 {
            logs = Array(logs.suffix(keepCount))
            
            // Recalculate buffer size
            currentBufferSize = logs.reduce(0) { $0 + $1.utf8.count }
        }
    }
}
```

## Testing and QA

### Integration Testing

Test DevLogCapture in your test suite:

```swift
class DevLogCaptureTests: XCTestCase {
    var consoleCapture: ConsoleCapture!
    
    override func setUp() {
        super.setUp()
        consoleCapture = ConsoleCapture()
    }
    
    override func tearDown() {
        consoleCapture.stop()
        super.tearDown()
    }
    
    func testLogCapture() {
        // Given
        consoleCapture.start()
        
        // When
        print("Test log message")
        
        // Then
        // Add assertions to verify log capture
        // Note: This requires exposing internal state for testing
    }
    
    func testFilterPatterns() {
        // Test filter functionality
        consoleCapture.addFilterPattern("test_filter")
        XCTAssertTrue(consoleCapture.getFilterPatterns().contains("test_filter"))
        
        consoleCapture.removeFilterPattern("test_filter")
        XCTAssertFalse(consoleCapture.getFilterPatterns().contains("test_filter"))
    }
}
```

### QA Guidelines

For QA teams testing apps with DevLogCapture:

1. **Access Logs**: Connect to `http://[device-ip]:8080/logs`
2. **Monitor for Errors**: Look for ERROR level logs
3. **Performance Impact**: Verify app performance isn't degraded
4. **Network Usage**: Monitor for excessive network traffic
5. **Battery Impact**: Check if logging affects battery life

## Deployment Checklist

### Pre-Release Checklist

- [ ] DevLogCapture code wrapped in `#if DEBUG`
- [ ] No sensitive data in logs
- [ ] Build configurations properly set
- [ ] Performance impact tested
- [ ] Network security reviewed

### Code Review Guidelines

When reviewing code that uses DevLogCapture:

```swift
// ✅ Good practices
#if DEBUG
consoleCapture.start()
#endif

AppLogger.shared.info("User action completed")
let sanitized = SecureLogger.sanitize(userInput)

// ❌ Bad practices
consoleCapture.start() // No conditional compilation
print("Password: \(password)") // Sensitive data
AppLogger.shared.log(veryLongString) // Potential memory issue
```

### Monitoring and Alerts

Set up monitoring for production builds:

```swift
#if DEBUG
// DevLogCapture enabled
#else
// Production logging to analytics/crash reporting
Analytics.logEvent("app_started")
CrashReporting.setUserProperty("version", BuildConfig.version)
#endif
```

## Common Pitfalls

### Memory Leaks

Avoid common memory leak patterns:

```swift
// ❌ Strong reference cycle
class MyClass {
    let consoleCapture = ConsoleCapture()
    
    func setup() {
        consoleCapture.onLogReceived = { [self] log in
            self.processLog(log) // Strong reference to self
        }
    }
}

// ✅ Weak reference
class MyClass {
    let consoleCapture = ConsoleCapture()
    
    func setup() {
        consoleCapture.onLogReceived = { [weak self] log in
            self?.processLog(log)
        }
    }
}
```

### Production Leaks

Ensure no DevLogCapture code reaches production:

```swift
// Use build scripts to verify
# check_production_build.sh
#!/bin/bash

if grep -r "DevLogCapture" --include="*.swift" .; then
    echo "❌ DevLogCapture found in production build!"
    exit 1
else
    echo "✅ Production build clean"
fi
```

### Over-Logging

Avoid excessive logging that impacts performance:

```swift
// ❌ Logging in tight loops
for item in largeArray {
    AppLogger.shared.debug("Processing item: \(item)")
}

// ✅ Batch logging
AppLogger.shared.info("Processing \(largeArray.count) items")
// Process items...
AppLogger.shared.info("Completed processing \(largeArray.count) items")
```

## Migration and Updates

### Framework Updates

When updating DevLogCapture:

1. **Test Thoroughly**: Verify compatibility with your app
2. **Review Changes**: Check for breaking changes in API
3. **Update Documentation**: Update your team's documentation
4. **Gradual Rollout**: Test with internal builds first

### Legacy Support

Supporting multiple versions:

```swift
#if canImport(DevLogCapture)
import DevLogCapture

@available(iOS 13.0, *)
class ModernLogCapture {
    let consoleCapture = ConsoleCapture()
    // Modern implementation
}
#endif

// Fallback for older versions
class LegacyLogCapture {
    // Legacy implementation
}
```

This comprehensive documentation should help you and your team use DevLogCapture effectively and safely. Remember to always prioritize security and performance in your implementation.
