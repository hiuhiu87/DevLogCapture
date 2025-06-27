# Network Access

Configure network access and security for remote log viewing.

## Overview

DevLogCapture creates a local HTTP server that serves logs to any device on the same network. Understanding how to configure and secure this access is crucial for both usability and security.

## Network Discovery

### Automatic IP Detection

DevLogCapture automatically detects and displays your device's IP address:

```
✅ HTTP Server ready on port 8080
📱 Device IP: 192.168.1.100
```

### Finding Your Device

The framework looks for the WiFi interface (`en0`) and displays the local IP address. You can access logs from:

- **Same Device**: `http://localhost:8080/logs`
- **Local Network**: `http://192.168.1.100:8080/logs`
- **Other Devices**: Any device on the same WiFi network

## Server Configuration

### Default Settings

```swift
// Default server configuration
let server = HTTPServer()
server.startServer(on: 8080) // Default port 8080
```

### Custom Port

If port 8080 is in use, you can specify a different port:

```swift
// Use a custom port
let server = HTTPServer()
server.startServer(on: 9090)
```

### Port Selection Strategy

Common ports for development:
- `8080` - Default HTTP alternate port
- `3000` - Common development server port
- `8000` - Python SimpleHTTPServer default
- `9090` - Alternative HTTP port

## API Endpoints

### GET /logs

Returns all captured logs in JSON format:

**Request:**
```http
GET /logs HTTP/1.1
Host: 192.168.1.100:8080
```

**Response:**
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

### GET /clear

Clears all stored logs:

**Request:**
```http
GET /clear HTTP/1.1
Host: 192.168.1.100:8080
```

**Response:**
```json
{
  "status": "cleared"
}
```

### OPTIONS

Handles CORS preflight requests:

**Request:**
```http
OPTIONS /logs HTTP/1.1
Host: 192.168.1.100:8080
```

**Response:**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

## CORS Configuration

DevLogCapture includes built-in CORS support for cross-origin requests:

```swift
// Automatically included in all responses
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

This allows web browsers from any origin to access the logs.

## Security Considerations

### Development Only

⚠️ **Important**: DevLogCapture should only be used in development builds:

```swift
#if DEBUG
let consoleCapture = ConsoleCapture()
consoleCapture.start()
#endif
```

### Network Exposure

The HTTP server is accessible to any device on the same network. Consider:

1. **Local Network Only**: The server binds to the local network interface
2. **No Authentication**: Anyone on the network can access logs
3. **Plain HTTP**: No encryption (logs transmitted in plain text)

### Sensitive Information

Be careful about logging sensitive information:

```swift
// ❌ Don't log sensitive data
print("User password: \(password)")
print("API key: \(apiKey)")

// ✅ Use masked logging
print("User password: [REDACTED]")
print("API key: \(apiKey.prefix(4))****")
```

### Production Safety

Ensure DevLogCapture is never included in production builds:

```swift
// Option 1: Conditional compilation
#if DEBUG
import DevLogCapture
#endif

// Option 2: Build configuration
#if ENABLE_LOG_CAPTURE
import DevLogCapture
#endif
```

## Client Implementation

### JavaScript/Web Client

Create a simple web client to view logs:

```html
<!DOCTYPE html>
<html>
<head>
    <title>iOS App Logs</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            font-family: 'Monaco', 'Menlo', monospace; 
            margin: 0; 
            padding: 20px; 
            background: #1e1e1e; 
            color: #d4d4d4;
        }
        .header { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            margin-bottom: 20px;
        }
        .controls button { 
            margin: 0 5px; 
            padding: 8px 16px; 
            background: #007AFF; 
            color: white; 
            border: none; 
            border-radius: 4px; 
            cursor: pointer;
        }
        .controls button:hover { background: #0056CC; }
        .log { 
            margin: 2px 0; 
            padding: 4px 8px; 
            border-left: 3px solid #007AFF; 
            background: rgba(255,255,255,0.05);
            word-wrap: break-word;
        }
        .time { color: #9CA3AF; font-size: 0.9em; }
        .message { margin-left: 10px; }
        .error { border-left-color: #FF3B30; }
        .warning { border-left-color: #FF9500; }
        #status { 
            position: fixed; 
            top: 10px; 
            right: 10px; 
            padding: 5px 10px; 
            background: #34C759; 
            color: white; 
            border-radius: 4px;
            font-size: 0.8em;
        }
    </style>
</head>
<body>
    <div id="status">Connected</div>
    
    <div class="header">
        <h1>📱 iOS App Logs</h1>
        <div class="controls">
            <button onclick="loadLogs()">🔄 Refresh</button>
            <button onclick="clearLogs()">🗑️ Clear</button>
            <button onclick="toggleAutoRefresh()">⏸️ Pause</button>
        </div>
    </div>
    
    <div id="logs"></div>

    <script>
        let autoRefresh = true;
        let refreshInterval;
        
        function loadLogs() {
            const deviceIP = prompt("Enter device IP:", "192.168.1.100");
            if (!deviceIP) return;
            
            fetch(`http://${deviceIP}:8080/logs`)
                .then(response => response.json())
                .then(data => {
                    displayLogs(data.logs);
                    updateStatus('Connected', '#34C759');
                })
                .catch(error => {
                    console.error('Error:', error);
                    updateStatus('Disconnected', '#FF3B30');
                });
        }
        
        function displayLogs(logs) {
            const logsDiv = document.getElementById('logs');
            logsDiv.innerHTML = '';
            
            logs.forEach(log => {
                const div = document.createElement('div');
                div.className = `log ${getLogClass(log.message)}`;
                div.innerHTML = `
                    <span class="time">${log.time}</span>
                    <span class="message">${escapeHtml(log.message)}</span>
                `;
                logsDiv.appendChild(div);
            });
            
            // Auto-scroll to bottom
            logsDiv.scrollTop = logsDiv.scrollHeight;
        }
        
        function getLogClass(message) {
            if (message.includes('[ERROR]') || message.includes('❌')) return 'error';
            if (message.includes('[WARNING]') || message.includes('⚠️')) return 'warning';
            return '';
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        function clearLogs() {
            if (confirm('Clear all logs?')) {
                const deviceIP = localStorage.getItem('deviceIP');
                fetch(`http://${deviceIP}:8080/clear`)
                    .then(() => loadLogs());
            }
        }
        
        function toggleAutoRefresh() {
            const button = event.target;
            if (autoRefresh) {
                clearInterval(refreshInterval);
                button.textContent = '▶️ Resume';
                updateStatus('Paused', '#FF9500');
            } else {
                startAutoRefresh();
                button.textContent = '⏸️ Pause';
                updateStatus('Connected', '#34C759');
            }
            autoRefresh = !autoRefresh;
        }
        
        function startAutoRefresh() {
            refreshInterval = setInterval(loadLogs, 2000);
        }
        
        function updateStatus(text, color) {
            const status = document.getElementById('status');
            status.textContent = text;
            status.style.backgroundColor = color;
        }
        
        // Initialize
        loadLogs();
        startAutoRefresh();
    </script>
</body>
</html>
```

### Mobile Client (React Native/Flutter)

For cross-platform mobile development:

```javascript
// React Native example
const LogViewer = () => {
  const [logs, setLogs] = useState([]);
  const [deviceIP, setDeviceIP] = useState('192.168.1.100');
  
  const fetchLogs = async () => {
    try {
      const response = await fetch(`http://${deviceIP}:8080/logs`);
      const data = await response.json();
      setLogs(data.logs);
    } catch (error) {
      console.error('Failed to fetch logs:', error);
    }
  };
  
  useEffect(() => {
    const interval = setInterval(fetchLogs, 2000);
    return () => clearInterval(interval);
  }, [deviceIP]);
  
  return (
    <View>
      <TextInput 
        value={deviceIP}
        onChangeText={setDeviceIP}
        placeholder="Device IP"
      />
      <FlatList
        data={logs}
        renderItem={({item}) => (
          <Text>{item.time} - {item.message}</Text>
        )}
      />
    </View>
  );
};
```

## Network Troubleshooting

### Connection Issues

If you can't connect to the server:

1. **Check Network**: Ensure both devices are on the same WiFi network
2. **Verify IP**: Double-check the IP address shown in console
3. **Port Conflicts**: Try a different port if 8080 is in use
4. **Firewall**: Check device firewall settings

### Common Problems

**"Connection Refused"**
- Server might not be running
- Wrong IP address or port
- Network firewall blocking connection

**"CORS Error"**
- Built-in CORS should handle this
- Try accessing directly via browser first

**"Empty Response"**
- Server is running but no logs captured
- Check if app is generating any output

### Debugging Network Issues

```swift
// Add more verbose network logging
print("🌐 Starting HTTP server on all interfaces")
print("📡 Server state: \(listener?.state)")
print("🔗 Active connections: \(connections.count)")
```

## Next Steps

- <doc:BestPractices> - Learn production best practices
- <doc:Configuration> - Advanced configuration options
