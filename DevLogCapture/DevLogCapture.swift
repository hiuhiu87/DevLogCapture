//
//  DevLogCapture.swift
//  DevLogCapture
//
//  Created by NMH on 26/6/25.
//

import Foundation

/**
 # DevLogCapture Framework
 
 A powerful iOS framework for capturing and remotely viewing console logs via HTTP server.
 
 ## Overview
 
 DevLogCapture enables real-time remote debugging by capturing console output from your iOS application
 and serving it through a local HTTP server. This is particularly useful for debugging on physical devices
 where traditional debugging methods may be limited.
 
 ## Key Components
 
 - ``ConsoleCapture``: Main class that handles log interception and processing
 - ``HTTPServer``: Internal HTTP server that serves captured logs via RESTful API
 
 ## Basic Usage
 
 ```swift
 import DevLogCapture
 
 class AppDelegate: UIResponder, UIApplicationDelegate {
     let consoleCapture = ConsoleCapture()
     
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         #if DEBUG
         consoleCapture.start()
         #endif
         return true
     }
 }
 ```
 
 ## Features
 
 - Real-time console log capture
 - HTTP server on port 8080
 - Smart filtering to reduce noise
 - JSON API for log access
 - Cross-platform web client support
 - Thread-safe operations
 - Minimal performance impact
 
 ## Security Considerations
 
 ⚠️ **Important**: This framework should only be used in development builds.
 Always wrap usage in conditional compilation directives:
 
 ```swift
 #if DEBUG
 consoleCapture.start()
 #endif
 ```
 
 ## Network Access
 
 The HTTP server is accessible at:
 - `http://localhost:8080/logs` (same device)
 - `http://[device-ip]:8080/logs` (network access)
 
 ## API Endpoints
 
 - `GET /logs`: Returns captured logs in JSON format
 - `GET /clear`: Clears all stored logs
 - `OPTIONS`: CORS preflight support
 
 - Important: Only use this framework in development builds
 - Note: Requires network permissions in Info.plist for full functionality
 */

/// The main namespace for DevLogCapture framework
public enum DevLogCapture {
    /// Current version of the framework
    public static let version = "1.0.0"
    
    /// Framework build information
    public static let buildInfo = "DevLogCapture v\(version) - iOS Console Log Capture Framework"
}

