import Foundation
import Network
import CommonCrypto

@MainActor
class IntegratedHotReloadServer: ObservableObject {
    @Published var isPreviewerConnected = false
    @Published var connectedClients: Set<String> = []
    
    private var fileMonitor: FileSystemMonitor?
    private let watchedDirectory: URL
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    
    init() {
        self.watchedDirectory = URL(fileURLWithPath: "/Users/tojkuv/Documents/GitHub/axiom-full-stack/workspace-meta-workspace/axiom-ide/SwiftUIViews")
    }
    
    func start() async throws {
        print("🔥 Starting Integrated Hot Reload Server...")
        
        // Start WebSocket server using Network framework
        try await startWebSocketServer()
        
        // Start file monitoring
        await startFileMonitoring()
        
        print("🔥 Integrated Hot Reload Server started on port 9001")
    }
    
    func stop() async {
        // Stop file monitoring
        fileMonitor?.stop()
        fileMonitor = nil
        
        // Stop WebSocket server
        listener?.cancel()
        listener = nil
        
        // Close all connections
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        
        connectedClients.removeAll()
        isPreviewerConnected = false
        
        print("🔥 Integrated Hot Reload Server stopped")
    }
    
    func sendPreviewCommand(_ command: PreviewCommand) async {
        print("🔄 IntegratedHotReloadServer.sendPreviewCommand called for: \(command.fileName)")
        print("🔄 Active connections: \(connections.count)")
        print("🔄 Command content preview: \(String(command.content.prefix(100)))...")
        
        guard !connections.isEmpty else {
            print("❌ No active connections to send preview command")
            return
        }
        
        // Send the command struct directly as JSON wrapped in WebSocket frame
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(command)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("❌ Failed to convert JSON data to string")
                return
            }
            
            // Create WebSocket frame for the JSON message
            let webSocketFrame = createWebSocketFrame(text: jsonString)
            
            print("✅ Successfully encoded command to JSON (\(jsonData.count) bytes)")
            
            for (index, connection) in connections.enumerated() {
                connection.send(content: webSocketFrame, completion: .contentProcessed { error in
                    if let error = error {
                        print("❌ Failed to send message to connection \(index): \(error)")
                    } else {
                        print("✅ Successfully sent message to connection \(index)")
                    }
                })
            }
            
            print("📤 Sent preview command to \(connections.count) clients: \(command.fileName)")
            
        } catch {
            print("❌ Failed to encode preview command: \(error)")
        }
    }
    
    private func startWebSocketServer() async throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        let listener = try NWListener(using: parameters, on: 9001)
        self.listener = listener
        
        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                await self?.handleNewConnection(connection)
            }
        }
        
        listener.start(queue: DispatchQueue.global())
    }
    
    private func handleNewConnection(_ connection: NWConnection) async {
        print("🔌 New client connected")
        
        connection.start(queue: DispatchQueue.global())
        
        // Handle WebSocket handshake first
        await handleWebSocketHandshake(connection)
    }
    
    private func handleWebSocketHandshake(_ connection: NWConnection) async {
        print("🤝 Starting WebSocket handshake process...")
        
        // Wait for HTTP upgrade request
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                print("📨 Received handshake data - size: \(data?.count ?? 0), error: \(String(describing: error))")
                
                if let error = error {
                    print("❌ Handshake receive error: \(error)")
                    return
                }
                
                if let data = data, !data.isEmpty {
                    print("✅ Processing handshake data...")
                    await self?.processWebSocketUpgrade(data, connection: connection)
                } else {
                    print("❌ No data received in handshake")
                }
            }
        }
    }
    
    private func processWebSocketUpgrade(_ data: Data, connection: NWConnection) async {
        guard let request = String(data: data, encoding: .utf8) else { 
            print("❌ Could not decode request data as UTF8")
            return 
        }
        
        print("📨 FULL REQUEST RECEIVED:")
        print(String(repeating: "=", count: 50))
        print(request)
        print(String(repeating: "=", count: 50))
        
        // Check if it's a WebSocket upgrade request
        if request.contains("Upgrade: websocket") {
            // Extract WebSocket key
            let lines = request.components(separatedBy: "\r\n")
            var webSocketKey = ""
            
            for line in lines {
                if line.hasPrefix("Sec-WebSocket-Key:") {
                    webSocketKey = String(line.dropFirst("Sec-WebSocket-Key:".count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
            
            // Generate WebSocket accept key
            let acceptKey = generateWebSocketAcceptKey(webSocketKey)
            
            // Send WebSocket upgrade response
            let response = "HTTP/1.1 101 Switching Protocols\r\n" +
                          "Upgrade: websocket\r\n" +
                          "Connection: Upgrade\r\n" +
                          "Sec-WebSocket-Accept: \(acceptKey)\r\n" +
                          "\r\n"
            
            guard let responseData = response.data(using: .utf8) else { return }
            
            connection.send(content: responseData, completion: .contentProcessed { [weak self] error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ Failed to send WebSocket handshake: \(error)")
                    } else {
                        print("✅ WebSocket handshake completed")
                        await self?.completeWebSocketConnection(connection)
                    }
                }
            })
        }
    }
    
    private func completeWebSocketConnection(_ connection: NWConnection) async {
        connections.append(connection)
        connectedClients.insert(connection.debugDescription)
        
        // Handle connection state changes
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    print("🔌 Client connection ready")
                case .failed(let error):
                    print("❌ Client connection failed: \(error)")
                    await self?.removeConnection(connection)
                case .cancelled:
                    print("🔌 Client connection cancelled")
                    await self?.removeConnection(connection)
                default:
                    break
                }
            }
        }
        
        // Start receiving WebSocket frames
        await startReceiving(on: connection)
        
        print("🔌 WebSocket connection established")
    }
    
    private func generateWebSocketAcceptKey(_ webSocketKey: String) -> String {
        let guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let combined = webSocketKey + guid
        
        guard let data = combined.data(using: .utf8) else { return "" }
        
        let hash = data.withUnsafeBytes { bytes in
            var sha1 = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count), &sha1)
            return Data(sha1)
        }
        
        return hash.base64EncodedString()
    }
    
    private func removeConnection(_ connection: NWConnection) async {
        connections.removeAll { $0 === connection }
        connectedClients.remove(connection.debugDescription)
        
        if connections.isEmpty {
            isPreviewerConnected = false
        }
    }
    
    private func startReceiving(on connection: NWConnection) async {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                if let data = data, !data.isEmpty {
                    // Parse WebSocket frame and extract payload
                    if let payload = self?.parseWebSocketFrame(data) {
                        if let payloadData = payload.data(using: .utf8) {
                            await self?.handleRawMessage(payloadData, from: connection)
                        }
                    } else {
                        // Fallback to raw data if not a WebSocket frame
                        await self?.handleRawMessage(data, from: connection)
                    }
                }
                
                if !isComplete && error == nil {
                    await self?.startReceiving(on: connection)
                }
            }
        }
    }
    
    private func handleRawMessage(_ data: Data, from connection: NWConnection) async {
        guard let message = String(data: data, encoding: .utf8) else { 
            print("❌ Failed to parse raw message as UTF8")
            return 
        }
        
        print("📨 Received raw message: \(message)")
        
        // Parse message for client registration
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("📋 Parsed JSON: \(json ?? [:])")
            
            if let clientType = json?["clientType"] as? String {
                print("📋 Client type: \(clientType)")
                
                if clientType == "iOS_previewer" {
                    isPreviewerConnected = true
                    print("✅ iOS Previewer successfully registered and connected!")
                    
                    // Send initial file discovery
                    await sendFileDiscoveryToClients()
                }
            } else {
                print("❌ No clientType found in JSON")
            }
        } catch {
            print("❌ Failed to parse JSON: \(error)")
        }
    }
    
    private func parseWebSocketFrame(_ data: Data) -> String? {
        guard data.count >= 2 else { return nil }
        
        let bytes = [UInt8](data)
        let firstByte = bytes[0]
        let secondByte = bytes[1]
        
        // Check if it's a text frame (opcode 0x1)
        let opcode = firstByte & 0x0F
        guard opcode == 0x1 else { return nil }
        
        // Check if payload is masked
        let masked = (secondByte & 0x80) != 0
        var payloadLength = Int(secondByte & 0x7F)
        
        var offset = 2
        
        // Handle extended payload length
        if payloadLength == 126 {
            guard data.count >= 4 else { return nil }
            payloadLength = Int(bytes[2]) << 8 | Int(bytes[3])
            offset = 4
        } else if payloadLength == 127 {
            // For simplicity, not handling 64-bit length
            return nil
        }
        
        var maskingKey: [UInt8] = []
        if masked {
            guard data.count >= offset + 4 else { return nil }
            maskingKey = Array(bytes[offset..<offset+4])
            offset += 4
        }
        
        guard data.count >= offset + payloadLength else { return nil }
        
        var payload = Array(bytes[offset..<offset+payloadLength])
        
        // Unmask payload if necessary
        if masked {
            for i in 0..<payload.count {
                payload[i] ^= maskingKey[i % 4]
            }
        }
        
        return String(bytes: payload, encoding: .utf8)
    }
    
    private func sendMessageToClients(_ message: [String: String]) async {
        guard !connections.isEmpty else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("❌ Failed to convert JSON data to string")
                return
            }
            
            // Create WebSocket frame for the JSON message
            let webSocketFrame = createWebSocketFrame(text: jsonString)
            
            for connection in connections {
                connection.send(content: webSocketFrame, completion: .contentProcessed { error in
                    if let error = error {
                        print("❌ Failed to send message: \(error)")
                    }
                })
            }
            
            print("📤 Sent WebSocket message to \(connections.count) clients")
            
        } catch {
            print("❌ Failed to serialize message: \(error)")
        }
    }
    
    private func createWebSocketFrame(text: String) -> Data {
        guard let payload = text.data(using: .utf8) else { return Data() }
        
        var frame = Data()
        
        // First byte: FIN (1) + RSV (000) + Opcode (0001 for text)
        frame.append(0x81)
        
        // Second byte: MASK (0) + Payload length
        if payload.count < 126 {
            frame.append(UInt8(payload.count))
        } else if payload.count < 65536 {
            frame.append(126)
            frame.append(UInt8(payload.count >> 8))
            frame.append(UInt8(payload.count & 0xFF))
        } else {
            // For simplicity, not handling 64-bit length
            frame.append(127)
            // Add 8 bytes for 64-bit length (simplified)
            for _ in 0..<8 {
                frame.append(0)
            }
        }
        
        // Add payload
        frame.append(payload)
        
        return frame
    }
    
    private func sendFileDiscoveryToClients() async {
        let message = [
            "type": "files_discovered",
            "action": "refresh_file_list"
        ]
        await sendMessageToClients(message)
    }
    
    private func startFileMonitoring() async {
        // Create SwiftUIViews directory if it doesn't exist
        try? FileManager.default.createDirectory(at: watchedDirectory, withIntermediateDirectories: true)
        
        print("👀 Monitoring directory: \(watchedDirectory.path)")
        
        fileMonitor = FileSystemMonitor(path: watchedDirectory.path) { [weak self] changedPath in
            Task { @MainActor in
                await self?.handleFileChange(at: changedPath)
            }
        }
        
        fileMonitor?.start()
        
        // Send initial scan of existing files
        await scanExistingFiles()
    }
    
    private func scanExistingFiles() async {
        let fileManager = FileManager.default
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: watchedDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
            )
            
            for fileURL in fileURLs {
                if fileURL.pathExtension == "swift" {
                    await handleFileChange(at: fileURL.path)
                }
            }
        } catch {
            print("❌ Error scanning directory: \(error)")
        }
    }
    
    private func handleFileChange(at filePath: String) async {
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard fileURL.pathExtension == "swift" else { return }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let analysis = analyzeSwiftUIFile(content: content, fileName: fileURL.lastPathComponent)
            
            print("🔍 Analyzed file: \(fileURL.lastPathComponent) -> \(analysis.viewType)")
            
            // Send file updates to all clients
            let fileUpdateMessage = [
                "type": "file_updated",
                "viewName": analysis.viewName,
                "fileName": fileURL.lastPathComponent,
                "sourceCode": content,
                "viewType": analysis.viewType,
                "filePath": filePath
            ]
            
            await sendMessageToClients(fileUpdateMessage)
            
            // Also send updated file discovery
            await sendFileDiscoveryToClients()
            
        } catch {
            print("❌ Error reading file \(filePath): \(error)")
        }
    }
    
    private func analyzeSwiftUIFile(content: String, fileName: String) -> SwiftUIFileAnalysis {
        var viewName = fileName.replacingOccurrences(of: ".swift", with: "")
        var viewType = "default"
        
        // Extract struct name using simple regex
        let visitor = SwiftUIViewVisitor()
        visitor.walk(content)
        
        if let structName = visitor.viewStructName {
            viewName = structName
        }
        
        // Analyze content to determine view type
        let lowercaseContent = content.lowercased()
        if lowercaseContent.contains("counter") {
            viewType = "counter"
        } else if lowercaseContent.contains("button") {
            viewType = "buttons"
        } else if lowercaseContent.contains("card") {
            viewType = "cards"
        } else if lowercaseContent.contains("todo") {
            viewType = "todo"
        }
        
        return SwiftUIFileAnalysis(
            viewName: viewName,
            viewType: viewType,
            hasPreview: content.contains("#Preview") || content.contains("PreviewProvider")
        )
    }
}

// MARK: - Supporting Types

struct SwiftUIFileAnalysis {
    let viewName: String
    let viewType: String
    let hasPreview: Bool
}