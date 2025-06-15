import Foundation
import Network

@MainActor
protocol WebSocketClientDelegate: AnyObject, Sendable {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocketDidReceiveMessage(_ message: String)
}

actor WebSocketClient {
    private let serverHost = "localhost"
    private let serverPort: UInt16 = 9001
    private var connection: NWConnection?
    
    weak var delegate: (any WebSocketClientDelegate)?
    
    func setDelegate(_ delegate: (any WebSocketClientDelegate)?) async {
        self.delegate = delegate
    }
    
    func connect() async {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(serverHost), port: NWEndpoint.Port(rawValue: serverPort)!)
        let parameters = NWParameters.tcp
        
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            Task {
                switch state {
                case .ready:
                    print("📱 TCP connection established, sending WebSocket handshake...")
                    await self?.sendWebSocketHandshake()
                case .failed(let error):
                    print("Connection failed: \(error)")
                    await self?.delegate?.webSocketDidDisconnect()
                case .cancelled:
                    await self?.delegate?.webSocketDidDisconnect()
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: DispatchQueue.global())
    }
    
    private func sendWebSocketHandshake() async {
        let webSocketKey = generateWebSocketKey()
        let handshake = "GET / HTTP/1.1\r\n" +
                       "Host: \(serverHost):\(serverPort)\r\n" +
                       "Upgrade: websocket\r\n" +
                       "Connection: Upgrade\r\n" +
                       "Sec-WebSocket-Key: \(webSocketKey)\r\n" +
                       "Sec-WebSocket-Version: 13\r\n" +
                       "\r\n"
        
        guard let handshakeData = handshake.data(using: .utf8) else {
            print("❌ Failed to create handshake data")
            return
        }
        
        connection?.send(content: handshakeData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("❌ Failed to send handshake: \(error)")
            } else {
                print("✅ WebSocket handshake sent, waiting for response...")
                Task {
                    await self?.waitForHandshakeResponse()
                }
            }
        })
    }
    
    private func waitForHandshakeResponse() async {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let error = error {
                print("❌ Handshake response error: \(error)")
                return
            }
            
            if let data = data, let response = String(data: data, encoding: .utf8) {
                print("📱 Received handshake response: \(response)")
                if response.contains("101 Switching Protocols") {
                    print("✅ WebSocket handshake successful!")
                    Task {
                        await self?.delegate?.webSocketDidConnect()
                        await self?.startListening()
                    }
                } else {
                    print("❌ WebSocket handshake failed")
                }
            }
        }
    }
    
    private func generateWebSocketKey() -> String {
        let keyData = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return keyData.base64EncodedString()
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
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    private func startListening() async {
        guard let connection = connection else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task {
                if let error = error {
                    print("Receive error: \(error)")
                    await self?.delegate?.webSocketDidDisconnect()
                    return
                }
                
                if let data = data, !data.isEmpty {
                    // Try to parse as WebSocket frame first
                    if let frameText = await self?.parseWebSocketFrame(data) {
                        await self?.delegate?.webSocketDidReceiveMessage(frameText)
                    } else if let text = String(data: data, encoding: .utf8) {
                        // Fallback to raw text for compatibility
                        await self?.delegate?.webSocketDidReceiveMessage(text)
                    }
                }
                
                if !isComplete {
                    await self?.startListening()
                }
            }
        }
    }
    
    func send(_ message: String) async throws {
        guard let connection = connection else {
            throw WebSocketError.notConnected
        }
        
        // Create WebSocket frame for the message
        let webSocketFrame = createWebSocketFrame(text: message)
        
        return await withCheckedContinuation { continuation in
            connection.send(content: webSocketFrame, completion: .contentProcessed { error in
                if let error = error {
                    print("Send error: \(error)")
                }
                continuation.resume()
            })
        }
    }
    
    private func createWebSocketFrame(text: String) -> Data {
        guard let payload = text.data(using: .utf8) else { return Data() }
        
        var frame = Data()
        
        // First byte: FIN (1) + RSV (000) + Opcode (0001 for text)
        frame.append(0x81)
        
        // Second byte: MASK (1) + Payload length
        if payload.count < 126 {
            frame.append(UInt8(payload.count | 0x80)) // Set mask bit
        } else if payload.count < 65536 {
            frame.append(126 | 0x80) // Set mask bit
            frame.append(UInt8(payload.count >> 8))
            frame.append(UInt8(payload.count & 0xFF))
        } else {
            // For simplicity, not handling 64-bit length
            frame.append(127 | 0x80) // Set mask bit
            // Add 8 bytes for 64-bit length (simplified)
            for _ in 0..<8 {
                frame.append(0)
            }
        }
        
        // Generate and add masking key (4 bytes)
        let maskingKey = (0..<4).map { _ in UInt8.random(in: 0...255) }
        frame.append(contentsOf: maskingKey)
        
        // Mask and add payload
        var maskedPayload = Data()
        for (index, byte) in payload.enumerated() {
            maskedPayload.append(byte ^ maskingKey[index % 4])
        }
        frame.append(maskedPayload)
        
        return frame
    }
}

enum WebSocketError: Error {
    case notConnected
}