import Foundation
import UIKit
import os

/**
 # ConsoleCapture
 
 The main class responsible for capturing console output and serving it via HTTP.
 
 ## Overview
 
 ConsoleCapture intercepts stdout to capture all console output from your iOS application.
 It processes, filters, and serves these logs through a built-in HTTP server, making them
 accessible from any device on the same network.
 
 ## Usage
 
 ```swift
 let consoleCapture = ConsoleCapture()
 
 // Start capturing logs
 consoleCapture.start()
 
 // Your app logs will now be captured
 print("This will be captured and served via HTTP")
 
 // Stop capturing when done
 consoleCapture.stop()
 ```
 
 ## Features
 
 - **Real-time Capture**: Intercepts stdout in real-time
 - **Smart Filtering**: Automatically filters out system noise
 - **HTTP Server**: Built-in server on port 8080
 - **Thread Safety**: Safe for concurrent access
 - **Memory Management**: Automatic log rotation and cleanup
 - **Custom Filtering**: Add/remove custom filter patterns
 
 ## Log Filtering
 
 The class includes intelligent filtering to reduce noise:
 - Network-related logs (nw_connection, tcp_*, etc.)
 - URLSession and HTTP logs
 - Debug/verbose/trace level logs
 - Logs with excessive special characters
 - Very short or repetitive logs
 
 ## Structured Logging
 
 Logs matching the EP_LOG format are always captured:
 ```
 EP_LOG - YYYY-MM-DD HH:mm:ss.SSSS - [LEVEL] Message
 ```
 
 ## Security
 
 ⚠️ **Development Only**: This class should only be used in development builds.
 Always wrap usage in conditional compilation:
 
 ```swift
 #if DEBUG
 consoleCapture.start()
 #endif
 ```
 */
public class ConsoleCapture {
    private let server = HTTPServer()
    private var pipe: Pipe?
    private var originalStdout: Int32 = 0
    private var isCapturing = false

    private var logBuffer = Data()
    private let bufferQueue = DispatchQueue(
        label: "com.consolecapture.buffer",
        qos: .utility
    )

    private let logDatePattern =
        #"^EP_LOG - \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{4} - "#

    private var filterPatterns = [
        "nw_connection",
        "nw_endpoint",
        "nw_resolver",
        "nw_path_evaluator",
        "tcp_input",
        "tcp_output",
        "boringssl",
        "[connection]",
        "[network]",
        "TIC Read Status",
        "TIC TCP Conn",
        "Task <",
        "NSURLSession",
        "CFNetwork",
        "HTTP load failed",
        "Connection invalid",
    ]

    private let filterLogLevels = [
        "debug",
        "verbose",
        "trace",
    ]

    /**
     Initializes a new ConsoleCapture instance.
     
     Creates a new console capture instance with default filter patterns.
     The HTTP server is created but not started until `start()` is called.
     */
    public init() {}

    /**
     Starts console log capture and HTTP server.
     
     This method:
     1. Starts the HTTP server on port 8080
     2. Begins capturing stdout to intercept console logs
     3. Generates initial test logs to verify functionality
     
     The server will be accessible at `http://[device-ip]:8080/logs`
     
     - Warning: Only call this in development builds
     - Note: Ignores subsequent calls if already capturing
     */
    public func start() {
        guard !isCapturing else { return }

        signal(SIGPIPE, SIG_IGN)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.server.startServer()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.captureConsoleLogs()
                self.generateTestLogs()
            }
        }
    }

    private func captureConsoleLogs() {
        guard !isCapturing else { return }

        originalStdout = dup(STDOUT_FILENO)
        guard originalStdout > 0 else {
            print("❌ Failed to backup original stdout")
            return
        }

        pipe = Pipe()
        guard let pipe = pipe else { return }

        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        isCapturing = true

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self = self, self.isCapturing else { return }

            let data = handle.availableData
            if !data.isEmpty {
                self.writeToOriginalConsole(data)

                self.bufferQueue.async {
                    self.processLogData(data)
                }
            }
        }

        print("📝 Console capture started with log function support")
    }

    private func writeToOriginalConsole(_ data: Data) {
        guard originalStdout > 0 else { return }

        data.withUnsafeBytes { bytes in
            if let baseAddress = bytes.baseAddress {
                write(originalStdout, baseAddress, data.count)
            }
        }
    }

    private func processLogData(_ newData: Data) {
        logBuffer.append(newData)

        while let newlineRange = logBuffer.range(of: Data([0x0A])) {
            let lineData = logBuffer.subdata(in: 0..<newlineRange.lowerBound)
            logBuffer.removeSubrange(0..<newlineRange.upperBound)

            if let logString = String(data: lineData, encoding: .utf8) {
                let cleanLog = logString.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                if isValidLogEntry(cleanLog) {
                    DispatchQueue.main.async {
                        self.server.addLog(logString)
                    }
                }
            }
        }

        if logBuffer.count > 16384 {
            let bufferString = String(data: logBuffer, encoding: .utf8) ?? ""
            let lines = bufferString.components(separatedBy: .newlines)

            var processedLines: [String] = []
            var remainingData = Data()

            if lines.count > 1 {
                processedLines = Array(lines.dropLast())

                if let lastLineData = lines.last?.data(using: .utf8) {
                    remainingData = lastLineData
                }
            } else {
                let halfPoint = bufferString.count / 2
                let firstHalf = String(bufferString.prefix(halfPoint))
                processedLines = [firstHalf + " [PARTIAL]"]

                if let secondHalf = String(
                    bufferString.suffix(bufferString.count - halfPoint)
                ).data(using: .utf8) {
                    remainingData = secondHalf
                }
            }

            for line in processedLines {
                let cleanLog = line.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                if isValidLogEntry(cleanLog) {
                    DispatchQueue.main.async {
                        self.server.addLog(cleanLog)
                    }
                }
            }

            logBuffer = remainingData
        }
    }

    private func isValidLogEntry(_ log: String) -> Bool {
        guard !log.isEmpty else { return false }

        let trimmedLog = log.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLog.isEmpty else { return false }

        if isFromLogFunction(trimmedLog) {
            return true
        }

        return shouldIncludeOtherLog(trimmedLog)
    }

    private func isFromLogFunction(_ log: String) -> Bool {
        let range = NSRange(location: 0, length: log.utf16.count)
        let regex = try? NSRegularExpression(
            pattern: logDatePattern,
            options: []
        )
        return regex?.firstMatch(in: log, options: [], range: range) != nil
    }

    private func shouldIncludeOtherLog(_ log: String) -> Bool {
        let lowercaseLog = log.lowercased()

        for pattern in filterPatterns {
            if lowercaseLog.contains(pattern.lowercased()) {
                return false
            }
        }

        for level in filterLogLevels {
            if lowercaseLog.contains("[\(level)]")
                || lowercaseLog.contains("\(level):")
            {
                return false
            }
        }

        // Lọc log có quá nhiều ký tự đặc biệt
        let specialCharCount = log.filter {
            !$0.isLetter && !$0.isNumber && !$0.isWhitespace
                && !"[](){}<>.,!?:;\"'-_=+/*@#$%^&|\\".contains($0)
        }.count

        if specialCharCount > log.count / 2 {
            return false
        }

        if log.count < 3 {
            return false
        }

        if log.allSatisfy({ $0.isNumber }) {
            return false
        }

        if Set(log).count <= 2 && log.count > 10 {
            return false
        }

        return true
    }

    private func generateTestLogs() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            print("🚀 Console capture started successfully!")
            print("📱 Device: \(UIDevice.current.name)")
            print("📱 iOS Version: \(UIDevice.current.systemVersion)")
            self.startPeriodicLogs()
        }
    }

    private func startPeriodicLogs() {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd H:m:ss.SSSS"
            let periodicMessage =
                "\(df.string(from: Date())) - Periodic test log"
            print(periodicMessage)
        }
    }

    /**
     Adds a custom filter pattern to exclude matching logs.
     
     Logs containing the specified pattern will be filtered out and not served
     via the HTTP API. This is useful for reducing noise from specific libraries
     or log categories.
     
     - Parameter pattern: The string pattern to filter out
     
     Example:
     ```swift
     consoleCapture.addFilterPattern("ThirdPartySDK")
     consoleCapture.addFilterPattern("Debug:")
     ```
     */
    func addFilterPattern(_ pattern: String) {
        if !filterPatterns.contains(pattern) {
            filterPatterns.append(pattern)
        }
    }

    /**
     Removes a filter pattern to allow matching logs.
     
     Removes a previously added filter pattern, allowing logs containing
     the specified pattern to be captured and served.
     
     - Parameter pattern: The string pattern to stop filtering
     
     Example:
     ```swift
     // Allow network logs that were previously filtered
     consoleCapture.removeFilterPattern("nw_connection")
     ```
     */
    func removeFilterPattern(_ pattern: String) {
        if let index = filterPatterns.firstIndex(of: pattern) {
            filterPatterns.remove(at: index)
        }
    }

    /**
     Returns the current list of active filter patterns.
     
     - Returns: Array of filter pattern strings currently being used
     
     Example:
     ```swift
     let patterns = consoleCapture.getFilterPatterns()
     print("Active filters: \(patterns)")
     ```
     */
    func getFilterPatterns() -> [String] {
        return filterPatterns
    }

    /**
     Stops console log capture and shuts down the HTTP server.
     
     This method:
     1. Stops capturing stdout
     2. Processes any remaining buffered logs
     3. Restores original stdout
     4. Shuts down the HTTP server
     5. Cleans up resources
     
     Safe to call multiple times. Automatically called during deinitialization.
     */
    public func stop() {
        guard isCapturing else { return }

        isCapturing = false

        bufferQueue.sync {
            if !logBuffer.isEmpty {
                if let logString = String(data: logBuffer, encoding: .utf8) {
                    let cleanLog = logString.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    if isValidLogEntry(cleanLog) && !cleanLog.isEmpty {
                        DispatchQueue.main.sync {
                            self.server.addLog(cleanLog + " [FINAL]")
                        }
                    }
                }
                logBuffer.removeAll()
            }
        }

        // Restore original stdout
        if originalStdout > 0 {
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            originalStdout = 0
        }

        // Clean up pipe
        pipe?.fileHandleForReading.readabilityHandler = nil
        pipe?.fileHandleForWriting.closeFile()
        pipe?.fileHandleForReading.closeFile()
        pipe = nil

        server.stopServer()
        print("🛑 Console capture stopped")
    }

    deinit {
        stop()
    }
}
