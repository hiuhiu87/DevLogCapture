import Foundation
import Network

class HTTPServer {
    private var listener: NWListener?
    private var logs: [[String: Any]] = []
    private let queue = DispatchQueue(label: "server.queue")
    private var connections: [NWConnection] = []
    private let connectionsQueue = DispatchQueue(label: "connections.queue")

    func startServer(on port: NWEndpoint.Port = 8080) {
        signal(SIGPIPE, SIG_IGN)

        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.includePeerToPeer = true

            listener = try NWListener(using: parameters, on: port)

            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("✅ HTTP Server ready on port 8080")
                    self.printDeviceIP()
                case .failed(let error):
                    print("❌ Server failed: \(error)")
                case .cancelled:
                    print("🛑 Server cancelled")
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { connection in
                self.handleConnection(connection)
            }

            listener?.start(queue: queue)

        } catch {
            print("❌ Failed to start server: \(error)")
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connectionsQueue.async {
            self.connections.append(connection)
        }

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                break
            case .failed(_):
                self.removeConnection(connection)
            case .cancelled:
                self.removeConnection(connection)
            default:
                break
            }
        }

        connection.start(queue: queue)

        self.receiveRequest(connection: connection)
    }

    private func removeConnection(_ connection: NWConnection) {
        connectionsQueue.async {
            if let index = self.connections.firstIndex(where: {
                $0 === connection
            }) {
                self.connections.remove(at: index)
            }
        }
    }

    private func receiveRequest(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
            data,
            _,
            isComplete,
            error in

            if let error = error {
                print("⚠️ Receive error: \(error)")
                connection.cancel()
                return
            }

            guard let data = data, !data.isEmpty else {
                if isComplete {
                    connection.cancel()
                }
                return
            }

            let request = String(data: data, encoding: .utf8) ?? ""

            if request.contains("GET /logs") {
                self.sendLogsResponse(connection: connection)
            } else if request.contains("GET /clear") {
                self.clearLogs()
                self.sendClearResponse(connection: connection)
            } else if request.contains("OPTIONS") {
                self.sendOptionsResponse(connection: connection)
            } else {
                self.sendNotFoundResponse(connection: connection)
            }
        }
    }

    private func sendLogsResponse(connection: NWConnection) {
        let response: [String: Any] = [
            "logs": logs,
            "count": logs.count,
            "timestamp": Date().timeIntervalSince1970,
        ]

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: response,
                options: .prettyPrinted
            )
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            let httpResponse = """
                HTTP/1.1 200 OK\r
                Content-Type: application/json\r
                Access-Control-Allow-Origin: *\r
                Access-Control-Allow-Methods: GET, POST, OPTIONS\r
                Access-Control-Allow-Headers: Content-Type, Authorization\r
                Content-Length: \(jsonString.utf8.count)\r
                Connection: close\r
                \r
                \(jsonString)
                """

            self.sendResponse(connection: connection, response: httpResponse)

        } catch {
            print("❌ JSON serialization error: \(error)")
            self.sendErrorResponse(
                connection: connection,
                message: "JSON Error"
            )
        }
    }

    private func sendClearResponse(connection: NWConnection) {
        let jsonResponse = """
            {"status":"cleared"}
            """

        let httpResponse = """
            HTTP/1.1 200 OK\r
            Content-Type: application/json\r
            Access-Control-Allow-Origin: *\r
            Access-Control-Allow-Methods: GET, POST, OPTIONS\r
            Access-Control-Allow-Headers: Content-Type, Authorization\r
            Content-Length: \(jsonResponse.utf8.count)\r
            Connection: close\r
            \r
            \(jsonResponse)
            """

        self.sendResponse(connection: connection, response: httpResponse)
    }

    private func sendOptionsResponse(connection: NWConnection) {
        let httpResponse = """
            HTTP/1.1 200 OK\r
            Access-Control-Allow-Origin: *\r
            Access-Control-Allow-Methods: GET, POST, OPTIONS\r
            Access-Control-Allow-Headers: Content-Type, Authorization\r
            Content-Length: 0\r
            Connection: close\r
            \r
            """

        self.sendResponse(connection: connection, response: httpResponse)
    }

    private func sendNotFoundResponse(connection: NWConnection) {
        let message = "Not Found"
        let httpResponse = """
            HTTP/1.1 404 Not Found\r
            Content-Type: text/plain\r
            Access-Control-Allow-Origin: *\r
            Content-Length: \(message.utf8.count)\r
            Connection: close\r
            \r
            \(message)
            """

        self.sendResponse(connection: connection, response: httpResponse)
    }

    private func sendErrorResponse(connection: NWConnection, message: String) {
        let httpResponse = """
            HTTP/1.1 500 Internal Server Error\r
            Content-Type: text/plain\r
            Access-Control-Allow-Origin: *\r
            Content-Length: \(message.utf8.count)\r
            Connection: close\r
            \r
            \(message)
            """

        self.sendResponse(connection: connection, response: httpResponse)
    }

    private func sendResponse(connection: NWConnection, response: String) {
        guard let data = response.data(using: .utf8) else {
            connection.cancel()
            return
        }

        connection.send(
            content: data,
            completion: .contentProcessed { error in
                if let error = error {
                    print("⚠️ Send error: \(error)")
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    connection.cancel()
                }
            }
        )
    }

    private func printDeviceIP() {
        DispatchQueue.main.async {
            var address = "Unknown"
            var ifaddr: UnsafeMutablePointer<ifaddrs>?

            if getifaddrs(&ifaddr) == 0 {
                var ptr = ifaddr
                while ptr != nil {
                    defer { ptr = ptr?.pointee.ifa_next }

                    guard let interface = ptr?.pointee else { continue }
                    let addrFamily = interface.ifa_addr.pointee.sa_family

                    if addrFamily == UInt8(AF_INET) {
                        let name = String(cString: interface.ifa_name)
                        if name == "en0" {  // WiFi interface
                            var hostname = [CChar](
                                repeating: 0,
                                count: Int(NI_MAXHOST)
                            )
                            let result = getnameinfo(
                                interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname,
                                socklen_t(hostname.count),
                                nil,
                                socklen_t(0),
                                NI_NUMERICHOST
                            )
                            if result == 0 {
                                address = String(cString: hostname)
                            }
                        }
                    }
                }
                freeifaddrs(ifaddr)
            }

            print("📱 Device IP: \(address)")
        }
    }

    func addLog(_ message: String, level: String = "INFO") {
        queue.async {
            let timestamp = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"

            let logEntry: [String: Any] = [
                "id": UUID().uuidString,
                "timestamp": timestamp.timeIntervalSince1970,
                "time": formatter.string(from: timestamp),
                "level": level,
                "message": message,
            ]

            self.logs.append(logEntry)

            if self.logs.count > 100 {
                self.logs.removeFirst(self.logs.count - 100)
            }
        }
    }

    func clearLogs() {
        queue.async {
            self.logs.removeAll()
            print("🗑️ Logs cleared")
        }
    }

    func stopServer() {
        connectionsQueue.async {
            for connection in self.connections {
                connection.cancel()
            }
            self.connections.removeAll()
        }

        listener?.cancel()
        listener = nil

        print("🛑 Server stopped")
    }
}
