# DevLogCapture

![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Overview

DevLogCapture enables real-time remote debugging by capturing console output from your iOS application and serving it through a local HTTP server. Perfect for debugging on physical devices, testing, and monitoring app behavior during development.

### ✨ Key Features

- 🔄 **Real-time Log Capture** - Intercepts all console output in real-time
- 🌐 **HTTP Server** - Built-in web server with RESTful API
- 🎯 **Smart Filtering** - Advanced filtering to reduce noise from system logs
- 📱 **Cross-Platform Access** - View logs from any device with a web browser
- 🔍 **Auto Device Discovery** - Automatic IP address detection and display
- ⚡ **High Performance** - Minimal impact on app performance
- 🔒 **Thread-Safe** - Designed for concurrent access and reliability

## Quick Start

### Installation

Clone the repository and build the framework manually:

```bash
# 1. Clone the repository
git clone https://github.com/your-username/DevLogCapture.git
cd DevLogCapture

# 2. Open in Xcode and build
open DevLogCapture.xcodeproj

# 3. Build the framework (Cmd+B in Xcode)
# The built framework will be in DerivedData/DevLogCapture/Build/Products/
```

Then add the built framework to your project:

1. Drag `DevLogCapture.framework` from the build products into your Xcode project
2. Make sure to check "Copy items if needed"
3. Add the framework to your target's "Frameworks, Libraries, and Embedded Content"
4. Set "Embed & Sign" for the framework

### Basic Usage

```swift
import DevLogCapture

class AppDelegate: UIResponder, UIApplicationDelegate {
    let consoleCapture = ConsoleCapture()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Start capturing logs (only in debug builds)
        #if DEBUG
        consoleCapture.start()
        #endif

        return true
    }
}
```

### Generate and View Logs

```swift
// In your app code
print("🚀 App started successfully!")
print("📱 Device: \(UIDevice.current.name)")
print("⏰ Current time: \(Date())")

// Check console for server IP, then visit:
// http://192.168.1.100:8080/logs
```

## Features

### Smart Log Filtering

DevLogCapture automatically filters out noisy system logs while preserving your important application messages:

```swift
// These logs are filtered out automatically:
// - Network connection logs (nw_connection, tcp_input, etc.)
// - URLSession logs
// - Debug/verbose level logs
// - System logs with excessive special characters

// Your app logs are preserved:
print("User login successful")        // ✅ Captured
print("API response received")        // ✅ Captured
print("Error: Network timeout")       // ✅ Captured
```

### Structured Logging

Use structured logging for better organization:

```swift
// Structured logs are always captured regardless of filters
func log(_ message: String, level: String = "INFO") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    print("EP_LOG - \(formatter.string(from: Date())) - [\(level)] \(message)")
}

log("User authentication successful", level: "INFO")
log("Database connection failed", level: "ERROR")
```

### Custom Filtering

Customize filtering for your specific needs:

```swift
let consoleCapture = ConsoleCapture()

// Add custom filter patterns
consoleCapture.addFilterPattern("ThirdPartySDK")
consoleCapture.addFilterPattern("UnnecessaryDebugInfo")

// Remove built-in filters if needed
consoleCapture.removeFilterPattern("nw_connection")

// View current filters
let filters = consoleCapture.getFilterPatterns()
print("Active filters: \(filters)")
```

## API Reference

### HTTP Endpoints

| Endpoint | Method | Description                              |
| -------- | ------ | ---------------------------------------- |
| `/logs`  | GET    | Returns all captured logs in JSON format |
| `/clear` | GET    | Clears all stored logs                   |

### Response Format

```json
{
  "logs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "timestamp": 1640995200.123,
      "time": "14:30:45.123",
      "level": "INFO",
      "message": "🚀 App started successfully!"
    }
  ],
  "count": 1,
  "timestamp": 1640995200.123
}
```

### Core Classes

#### ConsoleCapture

Main class for log capture functionality:

```swift
let consoleCapture = ConsoleCapture()

// Control capture
consoleCapture.start()
consoleCapture.stop()

// Manage filters
consoleCapture.addFilterPattern("pattern")
consoleCapture.removeFilterPattern("pattern")
consoleCapture.getFilterPatterns()
```

#### HTTPServer

Internal HTTP server (automatically managed by ConsoleCapture):

- Serves logs on port 8080
- Supports CORS for web access
- Thread-safe connection handling
- Automatic IP address detection

## Integration Examples

### SwiftUI App

```swift
import SwiftUI
import DevLogCapture

@main
struct MyApp: App {
    let consoleCapture = ConsoleCapture()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if DEBUG
                    consoleCapture.start()
                    #endif
                }
        }
    }
}
```

### UIKit with SceneDelegate

```swift
import DevLogCapture

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    let consoleCapture = ConsoleCapture()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        #if DEBUG
        consoleCapture.start()
        #endif

        // Rest of your scene setup...
    }
}
```

## Web Client

Create a simple HTML client to view logs:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>iOS App Logs</title>
    <style>
      body {
        font-family: monospace;
        margin: 20px;
      }
      .log {
        margin: 5px 0;
        padding: 5px;
        border-left: 3px solid #007aff;
      }
      .time {
        color: #666;
      }
      .message {
        margin-left: 10px;
      }
    </style>
  </head>
  <body>
    <h1>📱 iOS App Logs</h1>
    <button onclick="loadLogs()">🔄 Refresh</button>
    <button onclick="clearLogs()">🗑️ Clear</button>
    <div id="logs"></div>

    <script>
      function loadLogs() {
        const deviceIP = "192.168.1.100"; // Replace with your device IP
        fetch(`http://${deviceIP}:8080/logs`)
          .then((response) => response.json())
          .then((data) => {
            const logsDiv = document.getElementById("logs");
            logsDiv.innerHTML = "";
            data.logs.forEach((log) => {
              const div = document.createElement("div");
              div.className = "log";
              div.innerHTML = `<span class="time">${log.time}</span><span class="message">${log.message}</span>`;
              logsDiv.appendChild(div);
            });
          });
      }

      function clearLogs() {
        const deviceIP = "192.168.1.100";
        fetch(`http://${deviceIP}:8080/clear`).then(() => loadLogs());
      }

      // Auto-refresh every 2 seconds
      setInterval(loadLogs, 2000);
      loadLogs();
    </script>
  </body>
</html>
```

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Installation Options

### Manual Build (Recommended)

Clone and build the framework yourself:

```bash
# 1. Clone the repository
git clone https://github.com/your-username/DevLogCapture.git
cd DevLogCapture

# 2. Open in Xcode
open DevLogCapture.xcodeproj

# 3. Build for your target platform:
# - For iOS Device: Select "Generic iOS Device" and build (Cmd+B)
# - For iOS Simulator: Select any simulator and build (Cmd+B)
# - For Universal: Build for both and create XCFramework (see below)
```

**Creating Universal XCFramework:**

```bash
# Build for iOS Device
xcodebuild archive \
  -project DevLogCapture.xcodeproj \
  -scheme DevLogCapture \
  -destination "generic/platform=iOS" \
  -archivePath "build/ios.xcarchive" \
  SKIP_INSTALL=NO

# Build for iOS Simulator
xcodebuild archive \
  -project DevLogCapture.xcodeproj \
  -scheme DevLogCapture \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "build/ios-simulator.xcarchive" \
  SKIP_INSTALL=NO

# Create XCFramework
xcodebuild -create-xcframework \
  -framework "build/ios.xcarchive/Products/Library/Frameworks/DevLogCapture.framework" \
  -framework "build/ios-simulator.xcarchive/Products/Library/Frameworks/DevLogCapture.framework" \
  -output "DevLogCapture.xcframework"
```

**Integration Steps:**

1. Drag `DevLogCapture.framework` (or `DevLogCapture.xcframework`) into your Xcode project
2. Check "Copy items if needed"
3. Add to your target's "Frameworks, Libraries, and Embedded Content"
4. Set to "Embed & Sign"

### Swift Package Manager (Alternative)

```swift
dependencies: [
    .package(url: "https://github.com/your-username/DevLogCapture", from: "1.0.0")
]
```

### CocoaPods (Alternative)

```ruby
pod 'DevLogCapture', '~> 1.0'
```

## Configuration

### Info.plist Setup

Add network permissions to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses local networking to serve debug logs for development purposes.</string>
<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
</array>
```

### Network Security (Development Only)

For development builds, allow local networking:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Best Practices

### ✅ Do's

- Always wrap in `#if DEBUG` for development-only usage
- Use structured logging for important messages
- Test network connectivity between devices
- Implement proper error handling
- Monitor memory usage with large log volumes

### ❌ Don'ts

- Never include in production builds
- Don't log sensitive information (passwords, tokens, etc.)
- Avoid excessive logging in performance-critical code
- Don't expose the server to public networks

### Security Guidelines

```swift
// ✅ Safe logging
print("User login attempt for user ID: \(userID)")
print("API response status: \(statusCode)")

// ❌ Unsafe logging
print("User password: \(password)")
print("API key: \(apiKey)")
```

## Troubleshooting

### Common Issues

**Cannot connect to server:**

- Verify both devices are on the same WiFi network
- Check the IP address shown in the console
- Ensure port 8080 is not blocked by firewall

**No logs appearing:**

- Confirm the app is generating console output
- Check if logs are being filtered out
- Verify server is running (look for "✅ HTTP Server ready" message)

**Performance issues:**

- Reduce log volume by adding more filter patterns
- Check memory usage if dealing with large log volumes
- Ensure logging is only enabled in debug builds

### Debug Mode

Enable verbose logging to diagnose issues:

```swift
#if DEBUG
print("🔧 DevLogCapture debug mode enabled")
consoleCapture.start()
print("📊 Filter patterns: \(consoleCapture.getFilterPatterns())")
#endif
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/DevLogCapture.git
   cd DevLogCapture
   ```

2. Open in Xcode:

   ```bash
   open DevLogCapture.xcodeproj
   ```

3. Build and test:

   - Press `Cmd+B` to build the framework
   - Press `Cmd+U` to run unit tests
   - Test on both simulator and device

4. Create your changes and submit a pull request

### Building for Distribution

To create a release build:

```bash
# Clean build folder
rm -rf build/

# Build universal framework
./scripts/build-xcframework.sh

# The output will be in DevLogCapture.xcframework
```

## License

DevLogCapture is available under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- 📖 [Full Documentation](https://your-username.github.io/DevLogCapture)
- 🐛 [Issue Tracker](https://github.com/your-username/DevLogCapture/issues)
- 💬 [Discussions](https://github.com/your-username/DevLogCapture/discussions)

## Changelog

### Version 1.0.0

- Initial release
- Real-time log capture
- HTTP server with JSON API
- Smart filtering system
- Cross-platform web client support
- Comprehensive documentation

---

Made with ❤️ for iOS developers who need better debugging tools.
