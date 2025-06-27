# ``DevLogCapture``

A powerful iOS framework for capturing and remotely viewing console logs via HTTP server.

## Overview

DevLogCapture is a lightweight iOS framework that captures console output from your application and makes it available through a local HTTP server. This enables developers to view real-time logs from iOS devices remotely through a web browser, making debugging and monitoring much easier during development and testing.

### Key Features

- **Real-time Log Capture**: Intercepts and captures all console output from your iOS application
- **HTTP Server**: Built-in web server that serves logs via RESTful API endpoints
- **Smart Filtering**: Advanced filtering system to reduce noise from system logs
- **Cross-Platform Access**: View logs from any device with a web browser on the same network
- **Automatic Device Discovery**: Shows device IP address for easy connection
- **Buffer Management**: Efficiently manages memory with automatic log rotation
- **Thread-Safe Operations**: Designed for concurrent access and high-performance logging

### How It Works

The framework works by redirecting the standard output (stdout) through a pipe, capturing all print statements and console logs. It then processes these logs, applies intelligent filtering to remove noise, and serves them through a local HTTP server on port 8080.

## Topics

### Core Classes

- ``ConsoleCapture``
- ``HTTPServer``

### Getting Started

- <doc:Installation>
- <doc:QuickStart>
- <doc:Configuration>

### Advanced Usage

- <doc:FilteringLogs>
- <doc:NetworkAccess>
- <doc:BestPractices>