import Foundation

struct WebSocketMessage: Codable {
    let type: String
    let payload: [String: String]
    let timestamp: Date
    
    init(type: String, payload: [String: String] = [:]) {
        self.type = type
        self.payload = payload
        self.timestamp = Date()
    }
}

class WebSocketClient: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL = URL(string: "ws://localhost:9001")!
    private let session = URLSession(configuration: .default)
    
    var onMessage: ((WebSocketMessage) async -> Void)?
    var onConnectionChange: ((Bool) -> Void)?
    
    init(onMessage: @escaping (WebSocketMessage) async -> Void) {
        self.onMessage = onMessage
        super.init()
    }
    
    func connect() {
        print("🌐 Connecting to WebSocket server at \(serverURL)")
        
        webSocketTask = session.webSocketTask(with: serverURL)
        webSocketTask?.delegate = self
        webSocketTask?.resume()
        
        receiveMessage()
        
        // Send initial connection message
        let connectionMessage = WebSocketMessage(
            type: "client_connected",
            payload: ["clientType": "ios_app", "platform": "iOS"]
        )
        send(message: connectionMessage)
    }
    
    func disconnect() {
        print("🔌 Disconnecting from WebSocket server")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        onConnectionChange?(false)
    }
    
    func send(message: WebSocketMessage) {
        guard let webSocketTask = webSocketTask else {
            print("❌ WebSocket not connected")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ Failed to send message: \(error)")
                }
            }
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                self?.receiveMessage() // Continue receiving
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.onConnectionChange?(false)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseMessage(from: text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMessage(from: text)
            }
        @unknown default:
            print("❌ Unknown message type received")
        }
    }
    
    private func parseMessage(from text: String) {
        guard let data = text.data(using: .utf8) else {
            print("❌ Failed to convert message to data")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(WebSocketMessage.self, from: data)
            
            Task {
                await onMessage?(message)
            }
        } catch {
            print("❌ Failed to decode message: \(error)")
            print("📨 Raw message: \(text)")
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected")
        onConnectionChange?(true)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket disconnected")
        onConnectionChange?(false)
    }
}