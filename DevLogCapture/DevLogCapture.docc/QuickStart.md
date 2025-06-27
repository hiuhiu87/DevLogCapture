# Quick Start

Get up and running with DevLogCapture in minutes.

## Basic Usage

### 1. Import the Framework

```swift
import DevLogCapture
```

### 2. Start Log Capture

```swift
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

### 3. Generate Some Logs

```swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // These logs will be captured and served via HTTP
        print("🚀 App started successfully!")
        print("📱 Device: \(UIDevice.current.name)")
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        
        // Simulate some app activity
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            print("⏰ Periodic check at \(Date())")
        }
    }
}
```

### 4. Access Your Logs

1. Run your app on a device or simulator
2. Check the Xcode console for the server IP address:
   ```
   ✅ HTTP Server ready on port 8080
   📱 Device IP: 192.168.1.100
   ```
3. Open a web browser and navigate to: `http://192.168.1.100:8080/logs`
4. You'll see a JSON response with all captured logs

## API Endpoints

The HTTP server provides several endpoints:

### GET /logs
Returns all captured logs in JSON format:

```json
{
  "logs": [
    {
      "id": "uuid-string",
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

### GET /clear
Clears all stored logs and returns:

```json
{
  "status": "cleared"
}
```

## SwiftUI Integration

For SwiftUI apps, integrate in your `App` file:

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

## Stopping Log Capture

```swift
// Stop capturing logs (usually in applicationWillTerminate)
consoleCapture.stop()
```

## Viewing Logs in Browser

Create a simple HTML page to view logs in a more user-friendly format:

```html
<!DOCTYPE html>
<html>
<head>
    <title>iOS App Logs</title>
    <style>
        body { font-family: monospace; margin: 20px; }
        .log { margin: 5px 0; padding: 5px; border-left: 3px solid #007AFF; }
        .time { color: #666; }
        .message { margin-left: 10px; }
    </style>
</head>
<body>
    <h1>iOS App Logs</h1>
    <button onclick="loadLogs()">Refresh</button>
    <button onclick="clearLogs()">Clear</button>
    <div id="logs"></div>

    <script>
        function loadLogs() {
            fetch('/logs')
                .then(response => response.json())
                .then(data => {
                    const logsDiv = document.getElementById('logs');
                    logsDiv.innerHTML = '';
                    data.logs.forEach(log => {
                        const div = document.createElement('div');
                        div.className = 'log';
                        div.innerHTML = `<span class="time">${log.time}</span><span class="message">${log.message}</span>`;
                        logsDiv.appendChild(div);
                    });
                });
        }
        
        function clearLogs() {
            fetch('/clear').then(() => loadLogs());
        }
        
        // Auto-refresh every 2 seconds
        setInterval(loadLogs, 2000);
        loadLogs();
    </script>
</body>
</html>
```

## Next Steps

- <doc:Configuration> - Learn about advanced configuration options
- <doc:FilteringLogs> - Set up custom log filtering
- <doc:NetworkAccess> - Configure network access and security
