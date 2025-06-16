import Foundation
import Combine
import HotReloadProtocol

public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: ConnectionManager, didReceiveMessage message: BaseMessage)
    func connectionManager(_ manager: ConnectionManager, didChangeConnectionState state: ConnectionState)
    func connectionManager(_ manager: ConnectionManager, didEncounterError error: Error)
    func connectionManager(_ manager: ConnectionManager, didReceiveNetworkError error: NetworkError)
    func connectionManager(_ manager: ConnectionManager, didAttemptRecovery success: Bool)
}

@MainActor
public final class ConnectionManager: ObservableObject {
    
    public weak var delegate: ConnectionManagerDelegate?
    
    // Published properties for SwiftUI integration
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var lastError: Error?
    @Published public private(set) var reconnectAttempts: Int = 0
    @Published public private(set) var serverInfo: ServerInfo?
    @Published public private(set) var connectionQuality: ConnectionQuality = .unknown
    @Published public private(set) var networkDiagnostics: NetworkDiagnostics?
    
    private let webSocketClient: WebSocketClient
    private let messageHandler: MessageHandler
    private let configuration: ConnectionConfiguration
    private let errorHandler: NetworkErrorHandler
    private var cancellables = Set<AnyCancellable>()
    private var connectionStateTimer: Timer?
    private var isRegistered = false
    
    public init(
        configuration: ConnectionConfiguration,
        messageHandler: MessageHandler = MessageHandler()
    ) {
        self.configuration = configuration
        self.messageHandler = messageHandler
        
        // Setup error handler
        let errorConfig = ErrorHandlingConfiguration(
            enableAutoRecovery: configuration.enableAutoReconnect,
            maxRetryAttempts: configuration.maxReconnectAttempts,
            baseRetryDelay: configuration.baseReconnectDelay,
            maxRetryDelay: configuration.maxReconnectDelay
        )
        self.errorHandler = NetworkErrorHandler(configuration: errorConfig)
        
        let wsConfig = WebSocketConfiguration(
            host: configuration.host,
            port: configuration.port,
            path: configuration.path,
            clientId: configuration.clientId,
            clientName: configuration.clientName,
            enableAutoReconnect: configuration.enableAutoReconnect,
            maxReconnectAttempts: configuration.maxReconnectAttempts,
            baseReconnectDelay: configuration.baseReconnectDelay,
            maxReconnectDelay: configuration.maxReconnectDelay,
            enableHeartbeat: configuration.enableHeartbeat,
            heartbeatInterval: configuration.heartbeatInterval
        )
        
        self.webSocketClient = WebSocketClient(configuration: wsConfig)
        
        setupWebSocketDelegate()
        setupMessageHandler()
        observeConnectionState()
        setupErrorHandler()
    }
    
    deinit {
        // Clean up timer synchronously
        connectionStateTimer?.invalidate()
        // Disconnect will be handled when object is deallocated
    }
    
    // MARK: - Public API
    
    public func connect() {
        guard connectionState != .connected && connectionState != .connecting else {
            return
        }
        
        webSocketClient.connect()
    }
    
    public func disconnect() {
        isRegistered = false
        webSocketClient.disconnect()
    }
    
    public func sendMessage(_ message: BaseMessage) throws {
        guard isConnected else {
            throw ConnectionManagerError.notConnected
        }
        
        try webSocketClient.send(message)
    }
    
    public func sendStateSync(stateData: [String: AnyCodable], fileName: String, operation: StateOperation = .sync) throws {
        let payload = StateSyncPayload(
            stateData: stateData,
            fileName: fileName,
            operation: operation
        )
        
        let message = BaseMessage(
            type: .stateSync,
            clientId: configuration.clientId,
            platform: .ios,
            payload: .stateSync(payload)
        )
        
        try sendMessage(message)
    }
    
    public func requestPreviewSwitch(to fileName: String, preserveState: Bool = true) throws {
        let payload = PreviewSwitchPayload(
            targetFile: fileName,
            preserveState: preserveState
        )
        
        let message = BaseMessage(
            type: .previewSwitch,
            clientId: configuration.clientId,
            platform: .ios,
            payload: .previewSwitch(payload)
        )
        
        try sendMessage(message)
    }
    
    // MARK: - Connection Management
    
    private func setupWebSocketDelegate() {
        webSocketClient.delegate = self
    }
    
    private func setupMessageHandler() {
        messageHandler.delegate = self
    }
    
    private func observeConnectionState() {
        // Observe WebSocket connection state changes
        webSocketClient.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateConnectionState(state)
            }
            .store(in: &cancellables)
        
        // Observe errors
        webSocketClient.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupErrorHandler() {
        // Observe error handler properties
        errorHandler.$connectionQuality
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quality in
                self?.connectionQuality = quality
            }
            .store(in: &cancellables)
        
        errorHandler.$currentError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.delegate?.connectionManager(self!, didReceiveNetworkError: error)
                }
            }
            .store(in: &cancellables)
        
        // Listen for recovery attempts
        NotificationCenter.default.publisher(for: .networkErrorRecoveryAttempted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRecoveryAttempt()
            }
            .store(in: &cancellables)
        
        // Periodically update network diagnostics
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNetworkDiagnostics()
            }
            .store(in: &cancellables)
    }
    
    private func updateConnectionState(_ newState: ConnectionState) {
        let oldState = connectionState
        connectionState = newState
        isConnected = (newState == .connected)
        
        // Handle state transitions
        switch newState {
        case .connected:
            handleConnectionEstablished()
        case .disconnected:
            handleConnectionLost()
        case .reconnecting:
            reconnectAttempts += 1
        default:
            break
        }
        
        // Notify delegate of state change
        if oldState != newState {
            delegate?.connectionManager(self, didChangeConnectionState: newState)
        }
    }
    
    private func handleConnectionEstablished() {
        reconnectAttempts = 0
        
        // Register with server if not already registered
        if !isRegistered {
            Task {
                await registerWithServer()
            }
        }
        
        // Start connection monitoring
        startConnectionMonitoring()
    }
    
    private func handleConnectionLost() {
        isRegistered = false
        serverInfo = nil
        stopConnectionMonitoring()
    }
    
    private func registerWithServer() async {
        do {
            let capabilities = [
                ClientCapability(name: "swiftui_rendering", version: "1.0.0"),
                ClientCapability(name: "state_preservation", version: "1.0.0"),
                ClientCapability(name: "hot_reload", version: "1.0.0")
            ]
            
            try webSocketClient.registerClient(
                capabilities: capabilities,
                deviceInfo: DeviceInfo.current()
            )
            
            isRegistered = true
            
        } catch {
            handleError(ConnectionManagerError.registrationFailed(error))
        }
    }
    
    private func startConnectionMonitoring() {
        stopConnectionMonitoring()
        
        connectionStateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.monitorConnection()
            }
        }
    }
    
    private func stopConnectionMonitoring() {
        connectionStateTimer?.invalidate()
        connectionStateTimer = nil
    }
    
    private func monitorConnection() {
        // Send periodic ping if connection seems stale
        if isConnected && !isRegistered {
            Task {
                await registerWithServer()
            }
        }
    }
    
    private func handleError(_ error: Error) {
        lastError = error
        
        // Enhanced error handling with context
        let context = ErrorContext(
            operation: "WebSocket Connection",
            attemptNumber: reconnectAttempts + 1,
            metadata: [
                "host": configuration.host,
                "port": configuration.port,
                "connectionState": String(describing: connectionState)
            ]
        )
        
        errorHandler.handleError(error, context: context)
        delegate?.connectionManager(self, didEncounterError: error)
    }
    
    private func handleRecoveryAttempt() {
        // Attempt to reconnect
        if connectionState == .disconnected {
            connect()
            delegate?.connectionManager(self, didAttemptRecovery: true)
        } else {
            delegate?.connectionManager(self, didAttemptRecovery: false)
        }
    }
    
    private func updateNetworkDiagnostics() {
        networkDiagnostics = errorHandler.getNetworkDiagnostics()
    }
    
    // MARK: - Public Error Handling API
    
    /// Get user-friendly error message for the current error
    public func getCurrentErrorMessage() -> ErrorMessage? {
        guard let networkError = errorHandler.currentError else { return nil }
        return errorHandler.getUserFriendlyMessage(for: networkError)
    }
    
    /// Manually trigger error recovery
    public func triggerRecovery() {
        errorHandler.triggerRecovery()
    }
    
    /// Clear current error state
    public func clearError() {
        lastError = nil
        errorHandler.clearError()
    }
    
    /// Get detailed network diagnostics
    public func getNetworkDiagnostics() -> NetworkDiagnostics {
        return errorHandler.getNetworkDiagnostics()
    }
}

// MARK: - WebSocketClientDelegate

@MainActor
extension ConnectionManager: WebSocketClientDelegate {
    public func webSocketClient(_ client: WebSocketClient, didConnect: Bool) {
        // Connection state is handled via Published property observation
    }
    
    public func webSocketClient(_ client: WebSocketClient, didDisconnect error: Error?) {
        if let error = error {
            handleError(error)
        }
    }
    
    public func webSocketClient(_ client: WebSocketClient, didReceiveMessage message: BaseMessage) {
        // Process message through message handler
        messageHandler.handleMessage(message)
    }
    
    public func webSocketClient(_ client: WebSocketClient, didReceiveError error: Error) {
        handleError(error)
    }
}

// MARK: - MessageHandlerDelegate

@MainActor
extension ConnectionManager: MessageHandlerDelegate {
    public func messageHandler(_ handler: MessageHandler, didProcessMessage message: BaseMessage) {
        // Handle special message types
        switch message.type {
        case .connectionStatus:
            if case .connectionStatus(let payload) = message.payload {
                updateServerInfo(from: payload)
            }
        case .capabilityNegotiation:
            if case .capabilityNegotiation(let payload) = message.payload {
                handleCapabilityNegotiation(payload)
            }
        case .error:
            if case .error(let payload) = message.payload {
                handleServerError(payload)
            }
        default:
            break
        }
        
        // Forward to delegate
        delegate?.connectionManager(self, didReceiveMessage: message)
    }
    
    public func messageHandler(_ handler: MessageHandler, didFailToProcessMessage error: Error) {
        handleError(ConnectionManagerError.messageProcessingFailed(error))
    }
    
    private func updateServerInfo(from payload: ConnectionStatusPayload) {
        serverInfo = ServerInfo(
            status: payload.status,
            clientCount: payload.clientCount,
            serverLoad: payload.serverLoad,
            lastUpdated: Date()
        )
    }
    
    private func handleCapabilityNegotiation(_ payload: CapabilityNegotiationPayload) {
        // Handle server capability negotiation
        // Could update local capabilities based on server recommendations
    }
    
    private func handleServerError(_ payload: ErrorPayload) {
        let error = ConnectionManagerError.serverError(
            code: payload.errorCode,
            message: payload.errorMessage,
            recoverable: payload.recoverable
        )
        handleError(error)
    }
}

// MARK: - Supporting Types

public struct ConnectionConfiguration {
    public let host: String
    public let port: Int
    public let path: String
    public let clientId: String
    public let clientName: String
    public let enableAutoReconnect: Bool
    public let maxReconnectAttempts: Int
    public let baseReconnectDelay: TimeInterval
    public let maxReconnectDelay: TimeInterval
    public let enableHeartbeat: Bool
    public let heartbeatInterval: TimeInterval
    public let enableStatePreservation: Bool
    public let enableDebugLogging: Bool
    
    public init(
        host: String = "localhost",
        port: Int = 3001,
        path: String = "/",
        clientId: String = UUID().uuidString,
        clientName: String = "iOS Hot Reload Client",
        enableAutoReconnect: Bool = true,
        maxReconnectAttempts: Int = 10,
        baseReconnectDelay: TimeInterval = 1.0,
        maxReconnectDelay: TimeInterval = 30.0,
        enableHeartbeat: Bool = true,
        heartbeatInterval: TimeInterval = 30.0,
        enableStatePreservation: Bool = true,
        enableDebugLogging: Bool = false
    ) {
        self.host = host
        self.port = port
        self.path = path
        self.clientId = clientId
        self.clientName = clientName
        self.enableAutoReconnect = enableAutoReconnect
        self.maxReconnectAttempts = maxReconnectAttempts
        self.baseReconnectDelay = baseReconnectDelay
        self.maxReconnectDelay = maxReconnectDelay
        self.enableHeartbeat = enableHeartbeat
        self.heartbeatInterval = heartbeatInterval
        self.enableStatePreservation = enableStatePreservation
        self.enableDebugLogging = enableDebugLogging
    }
    
    public static func development() -> ConnectionConfiguration {
        return ConnectionConfiguration(
            host: "localhost",
            port: 3001,
            enableAutoReconnect: true,
            maxReconnectAttempts: 5,
            baseReconnectDelay: 0.5,
            enableDebugLogging: true
        )
    }
    
    public static func production(host: String, port: Int = 443) -> ConnectionConfiguration {
        return ConnectionConfiguration(
            host: host,
            port: port,
            enableAutoReconnect: true,
            maxReconnectAttempts: 15,
            baseReconnectDelay: 2.0,
            enableDebugLogging: false
        )
    }
}

public struct ServerInfo {
    public let status: ConnectionStatus
    public let clientCount: Int
    public let serverLoad: Double?
    public let lastUpdated: Date
}

public enum ConnectionManagerError: Error, LocalizedError {
    case notConnected
    case registrationFailed(Error)
    case messageProcessingFailed(Error)
    case serverError(code: String, message: String, recoverable: Bool)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Connection manager is not connected to server"
        case .registrationFailed(let error):
            return "Failed to register with server: \(error.localizedDescription)"
        case .messageProcessingFailed(let error):
            return "Failed to process message: \(error.localizedDescription)"
        case .serverError(let code, let message, let recoverable):
            return "Server error [\(code)]: \(message) (recoverable: \(recoverable))"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .notConnected, .registrationFailed, .messageProcessingFailed, .configurationError:
            return true
        case .serverError(_, _, let recoverable):
            return recoverable
        }
    }
}