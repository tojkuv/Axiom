import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Starscream
import HotReloadProtocol

public protocol WebSocketClientDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didConnect: Bool)
    func webSocketClient(_ client: WebSocketClient, didDisconnect error: Error?)
    func webSocketClient(_ client: WebSocketClient, didReceiveMessage message: BaseMessage)
    func webSocketClient(_ client: WebSocketClient, didReceiveError error: Error)
}

public final class WebSocketClient: NSObject, ObservableObject {
    
    public weak var delegate: WebSocketClientDelegate?
    
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    @Published public private(set) var lastError: Error?
    
    private var webSocket: WebSocket?
    private let configuration: WebSocketConfiguration
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private var isManualDisconnect = false
    
    public init(configuration: WebSocketConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Public API
    
    public func connect() {
        guard connectionState != .connected && connectionState != .connecting else {
            return
        }
        
        isManualDisconnect = false
        updateConnectionState(.connecting)
        
        do {
            let url = try buildWebSocketURL()
            var request = URLRequest(url: url)
            
            // Add headers
            configuration.customHeaders.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            webSocket = WebSocket(request: request)
            webSocket?.delegate = self
            webSocket?.connect()
            
            startPingTimer()
            
        } catch {
            updateConnectionState(.disconnected)
            lastError = error
            delegate?.webSocketClient(self, didReceiveError: error)
        }
    }
    
    public func disconnect() {
        isManualDisconnect = true
        stopReconnectTimer()
        stopPingTimer()
        
        webSocket?.disconnect()
        webSocket = nil
        updateConnectionState(.disconnected)
    }
    
    public func send(_ message: BaseMessage) throws {
        guard connectionState == .connected else {
            throw WebSocketClientError.notConnected
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(message)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        
        webSocket?.write(string: jsonString)
    }
    
    public func registerClient(capabilities: [ClientCapability] = [], deviceInfo: DeviceInfo? = nil) throws {
        let defaultDeviceInfo = deviceInfo ?? DeviceInfo.current()
        
        let payload = ClientRegisterPayload(
            platform: .ios,
            clientName: configuration.clientName,
            capabilities: capabilities,
            deviceInfo: defaultDeviceInfo
        )
        
        let message = BaseMessage(
            type: .clientRegister,
            clientId: configuration.clientId,
            platform: .ios,
            payload: .clientRegister(payload)
        )
        
        try send(message)
    }
    
    // MARK: - Private Methods
    
    private func buildWebSocketURL() throws -> URL {
        guard var components = URLComponents(string: "ws://\(configuration.host):\(configuration.port)") else {
            throw WebSocketClientError.invalidURL("Invalid host or port")
        }
        
        if !configuration.path.isEmpty {
            components.path = configuration.path
        }
        
        if !configuration.queryParameters.isEmpty {
            components.queryItems = configuration.queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = components.url else {
            throw WebSocketClientError.invalidURL("Failed to construct WebSocket URL")
        }
        
        return url
    }
    
    private func updateConnectionState(_ newState: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionState = newState
        }
    }
    
    private func startReconnectTimer() {
        guard configuration.enableAutoReconnect && !isManualDisconnect else { return }
        
        stopReconnectTimer()
        
        let delay = min(
            configuration.baseReconnectDelay * pow(2.0, Double(reconnectAttempts)),
            configuration.maxReconnectDelay
        )
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func attemptReconnect() {
        guard !isManualDisconnect && reconnectAttempts < configuration.maxReconnectAttempts else {
            updateConnectionState(.disconnected)
            return
        }
        
        reconnectAttempts += 1
        updateConnectionState(.reconnecting)
        
        connect()
    }
    
    private func startPingTimer() {
        guard configuration.enableHeartbeat else { return }
        
        stopPingTimer()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: configuration.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        let payload = PingPayload(sequence: Int.random(in: 0...1000))
        let message = BaseMessage(
            type: .ping,
            clientId: configuration.clientId,
            platform: .ios,
            payload: .ping(payload)
        )
        
        do {
            try send(message)
        } catch {
            // Ping failed, connection might be dead
            delegate?.webSocketClient(self, didReceiveError: error)
        }
    }
    
    private func handleIncomingMessage(_ text: String) {
        do {
            let data = text.data(using: .utf8) ?? Data()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let message = try decoder.decode(BaseMessage.self, from: data)
            
            DispatchQueue.main.async {
                self.delegate?.webSocketClient(self, didReceiveMessage: message)
            }
            
            // Handle pong responses
            if case .pong = message.payload {
                // Connection is alive, reset reconnect attempts
                reconnectAttempts = 0
            }
            
        } catch {
            let decodingError = WebSocketClientError.messageDecodingFailed(error.localizedDescription)
            delegate?.webSocketClient(self, didReceiveError: decodingError)
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        lastError = error
        updateConnectionState(.disconnected)
        delegate?.webSocketClient(self, didDisconnect: error)
        
        // Start reconnection if enabled
        if configuration.enableAutoReconnect && !isManualDisconnect {
            startReconnectTimer()
        }
    }
}

// MARK: - WebSocketDelegate

extension WebSocketClient: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(_):
            updateConnectionState(.connected)
            reconnectAttempts = 0
            delegate?.webSocketClient(self, didConnect: true)
            
        case .disconnected(let reason, let code):
            let error = WebSocketClientError.disconnected(reason: reason, code: code)
            handleConnectionError(error)
            
        case .text(let text):
            handleIncomingMessage(text)
            
        case .binary(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleIncomingMessage(text)
            } else {
                let error = WebSocketClientError.invalidBinaryMessage
                delegate?.webSocketClient(self, didReceiveError: error)
            }
            
        case .ping:
            webSocket?.write(pong: Data())
            
        case .pong:
            // Pong received, connection is alive
            break
            
        case .viabilityChanged(let isViable):
            if !isViable {
                let error = WebSocketClientError.connectionNotViable
                handleConnectionError(error)
            }
            
        case .reconnectSuggested(let shouldReconnect):
            if shouldReconnect && configuration.enableAutoReconnect {
                startReconnectTimer()
            }
            
        case .cancelled:
            updateConnectionState(.disconnected)
            
        case .error(let error):
            let wsError = error ?? WebSocketClientError.unknownError
            handleConnectionError(wsError)
            
        case .peerClosed:
            updateConnectionState(.disconnected)
            let error = WebSocketClientError.disconnected(reason: "Peer closed connection", code: 0)
            handleConnectionError(error)
        }
    }
}

// MARK: - Supporting Types

public enum ConnectionState: String, CaseIterable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case error = "error"
}

public struct WebSocketConfiguration {
    public let host: String
    public let port: Int
    public let path: String
    public let clientId: String
    public let clientName: String
    public let customHeaders: [String: String]
    public let queryParameters: [String: String]
    public let enableAutoReconnect: Bool
    public let maxReconnectAttempts: Int
    public let baseReconnectDelay: TimeInterval
    public let maxReconnectDelay: TimeInterval
    public let enableHeartbeat: Bool
    public let heartbeatInterval: TimeInterval
    
    public init(
        host: String = "localhost",
        port: Int = 3001,
        path: String = "/",
        clientId: String = UUID().uuidString,
        clientName: String = "iOS Client",
        customHeaders: [String: String] = [:],
        queryParameters: [String: String] = [:],
        enableAutoReconnect: Bool = true,
        maxReconnectAttempts: Int = 10,
        baseReconnectDelay: TimeInterval = 1.0,
        maxReconnectDelay: TimeInterval = 30.0,
        enableHeartbeat: Bool = true,
        heartbeatInterval: TimeInterval = 30.0
    ) {
        self.host = host
        self.port = port
        self.path = path
        self.clientId = clientId
        self.clientName = clientName
        self.customHeaders = customHeaders
        self.queryParameters = queryParameters
        self.enableAutoReconnect = enableAutoReconnect
        self.maxReconnectAttempts = maxReconnectAttempts
        self.baseReconnectDelay = baseReconnectDelay
        self.maxReconnectDelay = maxReconnectDelay
        self.enableHeartbeat = enableHeartbeat
        self.heartbeatInterval = heartbeatInterval
    }
    
    public static func development() -> WebSocketConfiguration {
        return WebSocketConfiguration(
            host: "localhost",
            port: 3001,
            enableAutoReconnect: true,
            maxReconnectAttempts: 5,
            baseReconnectDelay: 0.5
        )
    }
    
    public static func production(host: String, port: Int = 443) -> WebSocketConfiguration {
        return WebSocketConfiguration(
            host: host,
            port: port,
            enableAutoReconnect: true,
            maxReconnectAttempts: 15,
            baseReconnectDelay: 2.0
        )
    }
}

public enum WebSocketClientError: Error, LocalizedError {
    case notConnected
    case invalidURL(String)
    case messageDecodingFailed(String)
    case invalidBinaryMessage
    case connectionNotViable
    case disconnected(reason: String, code: UInt16)
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .invalidURL(let details):
            return "Invalid WebSocket URL: \(details)"
        case .messageDecodingFailed(let details):
            return "Failed to decode message: \(details)"
        case .invalidBinaryMessage:
            return "Received invalid binary message"
        case .connectionNotViable:
            return "WebSocket connection is not viable"
        case .disconnected(let reason, let code):
            return "WebSocket disconnected: \(reason) (code: \(code))"
        case .unknownError:
            return "Unknown WebSocket error occurred"
        }
    }
}

// MARK: - DeviceInfo Extension

extension DeviceInfo {
    public static func current() -> DeviceInfo {
        #if canImport(UIKit) && !os(macOS)
        // iOS/tvOS/watchOS implementation
        #if targetEnvironment(simulator)
        let deviceModel = "iOS Simulator"
        #else
        let deviceModel = UIDevice.current.model
        #endif
        
        let osVersion = UIDevice.current.systemVersion
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        let screenSize = ScreenSize(
            width: Double(UIScreen.main.bounds.width),
            height: Double(UIScreen.main.bounds.height),
            scale: Double(UIScreen.main.scale)
        )
        
        return DeviceInfo(
            deviceModel: deviceModel,
            osVersion: osVersion,
            screenSize: screenSize,
            deviceId: deviceId
        )
        #else
        // macOS or other platforms
        let deviceModel = "macOS"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceId = UUID().uuidString
        
        return DeviceInfo(
            deviceModel: deviceModel,
            osVersion: osVersion,
            screenSize: nil,
            deviceId: deviceId
        )
        #endif
    }
}