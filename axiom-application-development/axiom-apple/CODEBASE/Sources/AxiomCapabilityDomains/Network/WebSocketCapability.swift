import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - WebSocket Capability Configuration

/// Configuration for WebSocket capability
public struct WebSocketCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let url: URL
    public let protocols: [String]
    public let enableCompression: Bool
    public let enableAutomaticPong: Bool
    public let pingInterval: TimeInterval
    public let timeoutInterval: TimeInterval
    public let maxFrameSize: Int
    public let maxMessageSize: Int
    public let enableReconnection: Bool
    public let reconnectionDelay: TimeInterval
    public let maxReconnectionAttempts: Int
    public let reconnectionBackoffMultiplier: Double
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let customHeaders: [String: String]
    
    public init(
        url: URL,
        protocols: [String] = [],
        enableCompression: Bool = true,
        enableAutomaticPong: Bool = true,
        pingInterval: TimeInterval = 30.0,
        timeoutInterval: TimeInterval = 10.0,
        maxFrameSize: Int = 16384, // 16KB
        maxMessageSize: Int = 1048576, // 1MB
        enableReconnection: Bool = true,
        reconnectionDelay: TimeInterval = 1.0,
        maxReconnectionAttempts: Int = 5,
        reconnectionBackoffMultiplier: Double = 2.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        customHeaders: [String: String] = [:]
    ) {
        self.url = url
        self.protocols = protocols
        self.enableCompression = enableCompression
        self.enableAutomaticPong = enableAutomaticPong
        self.pingInterval = pingInterval
        self.timeoutInterval = timeoutInterval
        self.maxFrameSize = maxFrameSize
        self.maxMessageSize = maxMessageSize
        self.enableReconnection = enableReconnection
        self.reconnectionDelay = reconnectionDelay
        self.maxReconnectionAttempts = maxReconnectionAttempts
        self.reconnectionBackoffMultiplier = reconnectionBackoffMultiplier
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.customHeaders = customHeaders
    }
    
    public var isValid: Bool {
        url.scheme == "ws" || url.scheme == "wss" &&
        pingInterval > 0 &&
        timeoutInterval > 0 &&
        maxFrameSize > 0 &&
        maxMessageSize > 0 &&
        reconnectionDelay >= 0 &&
        maxReconnectionAttempts >= 0 &&
        reconnectionBackoffMultiplier > 0
    }
    
    public func merged(with other: WebSocketCapabilityConfiguration) -> WebSocketCapabilityConfiguration {
        WebSocketCapabilityConfiguration(
            url: other.url,
            protocols: other.protocols.isEmpty ? protocols : other.protocols,
            enableCompression: other.enableCompression,
            enableAutomaticPong: other.enableAutomaticPong,
            pingInterval: other.pingInterval,
            timeoutInterval: other.timeoutInterval,
            maxFrameSize: other.maxFrameSize,
            maxMessageSize: other.maxMessageSize,
            enableReconnection: other.enableReconnection,
            reconnectionDelay: other.reconnectionDelay,
            maxReconnectionAttempts: other.maxReconnectionAttempts,
            reconnectionBackoffMultiplier: other.reconnectionBackoffMultiplier,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            customHeaders: customHeaders.merging(other.customHeaders) { _, new in new }
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> WebSocketCapabilityConfiguration {
        var adjustedPingInterval = pingInterval
        var adjustedReconnection = enableReconnection
        var adjustedLogging = enableLogging
        var adjustedMaxAttempts = maxReconnectionAttempts
        
        if environment.isLowPowerMode {
            adjustedPingInterval *= 2.0 // Less frequent pings
            adjustedReconnection = false // No automatic reconnection
            adjustedMaxAttempts = min(maxReconnectionAttempts, 2)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return WebSocketCapabilityConfiguration(
            url: url,
            protocols: protocols,
            enableCompression: enableCompression,
            enableAutomaticPong: enableAutomaticPong,
            pingInterval: adjustedPingInterval,
            timeoutInterval: timeoutInterval,
            maxFrameSize: maxFrameSize,
            maxMessageSize: maxMessageSize,
            enableReconnection: adjustedReconnection,
            reconnectionDelay: reconnectionDelay,
            maxReconnectionAttempts: adjustedMaxAttempts,
            reconnectionBackoffMultiplier: reconnectionBackoffMultiplier,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            customHeaders: customHeaders
        )
    }
}

// MARK: - WebSocket Types

/// WebSocket connection state
public enum WebSocketState: String, Codable, CaseIterable, Sendable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case disconnecting = "disconnecting"
    case reconnecting = "reconnecting"
    case failed = "failed"
}

/// WebSocket message types
public enum WebSocketMessage: Sendable {
    case text(String)
    case data(Data)
    case ping(Data?)
    case pong(Data?)
}

/// WebSocket event types
public enum WebSocketEvent: Sendable {
    case connected(String?) // Selected protocol
    case disconnected(WebSocketCloseCode, String?)
    case message(WebSocketMessage)
    case error(Error)
    case ping(Data?)
    case pong(Data?)
}

/// WebSocket close codes
public enum WebSocketCloseCode: Int, Codable, CaseIterable, Sendable {
    case normal = 1000
    case goingAway = 1001
    case protocolError = 1002
    case unsupportedData = 1003
    case noStatusReceived = 1005
    case abnormalClosure = 1006
    case invalidFramePayloadData = 1007
    case policyViolation = 1008
    case messageTooBig = 1009
    case mandatoryExtension = 1010
    case internalServerError = 1011
    case serviceRestart = 1012
    case tryAgainLater = 1013
    case badGateway = 1014
    case tlsHandshake = 1015
    
    public var canReconnect: Bool {
        switch self {
        case .normal, .goingAway, .serviceRestart, .tryAgainLater:
            return true
        default:
            return false
        }
    }
}

/// WebSocket metrics
public struct WebSocketMetrics: Sendable {
    public let connectionCount: Int
    public let reconnectionCount: Int
    public let messagesSent: Int
    public let messagesReceived: Int
    public let bytesSent: Int64
    public let bytesReceived: Int64
    public let averageLatency: TimeInterval
    public let connectionUptime: TimeInterval
    public let lastError: String?
    
    public init(
        connectionCount: Int = 0,
        reconnectionCount: Int = 0,
        messagesSent: Int = 0,
        messagesReceived: Int = 0,
        bytesSent: Int64 = 0,
        bytesReceived: Int64 = 0,
        averageLatency: TimeInterval = 0,
        connectionUptime: TimeInterval = 0,
        lastError: String? = nil
    ) {
        self.connectionCount = connectionCount
        self.reconnectionCount = reconnectionCount
        self.messagesSent = messagesSent
        self.messagesReceived = messagesReceived
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.averageLatency = averageLatency
        self.connectionUptime = connectionUptime
        self.lastError = lastError
    }
}

// MARK: - WebSocket Resource

/// WebSocket resource management
public actor WebSocketCapabilityResource: AxiomCapabilityResource {
    private let configuration: WebSocketCapabilityConfiguration
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var connectionState: WebSocketState = .disconnected
    private var selectedProtocol: String?
    private var reconnectionAttempts: Int = 0
    private var connectionStartTime: Date?
    private var pingTimer: Timer?
    private var eventStreamContinuation: AsyncStream<WebSocketEvent>.Continuation?
    private var metrics: WebSocketMetrics = WebSocketMetrics()
    
    public init(configuration: WebSocketCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxMessageSize * 10, // Buffer for multiple messages
            cpu: 5.0, // WebSocket processing can be CPU intensive
            bandwidth: configuration.maxMessageSize, // Per message bandwidth
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let isConnected = connectionState == .connected
            return ResourceUsage(
                memory: isConnected ? configuration.maxMessageSize : 0,
                cpu: isConnected ? 2.0 : 0.1,
                bandwidth: isConnected ? 1000 : 0, // 1KB/s baseline
                storage: 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        urlSession != nil
    }
    
    public func release() async {
        await disconnect()
        pingTimer?.invalidate()
        pingTimer = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        eventStreamContinuation?.finish()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        urlSession = URLSession(configuration: sessionConfig)
    }
    
    internal func updateConfiguration(_ configuration: WebSocketCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - WebSocket Access
    
    public func getConnectionState() -> WebSocketState {
        connectionState
    }
    
    public func getSelectedProtocol() -> String? {
        selectedProtocol
    }
    
    public func getMetrics() -> WebSocketMetrics {
        metrics
    }
    
    public func connect() async throws {
        guard let session = urlSession else {
            throw WebSocketError.notInitialized
        }
        
        guard connectionState == .disconnected || connectionState == .failed else {
            throw WebSocketError.invalidState("Cannot connect from state: \(connectionState)")
        }
        
        connectionState = .connecting
        connectionStartTime = Date()
        
        var request = URLRequest(url: configuration.url)
        request.timeoutInterval = configuration.timeoutInterval
        
        // Add custom headers
        for (key, value) in configuration.customHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        webSocketTask = session.webSocketTask(with: request, protocols: configuration.protocols)
        
        // Start receiving messages
        startReceiving()
        
        webSocketTask?.resume()
        
        // Start ping timer if configured
        if configuration.pingInterval > 0 {
            startPingTimer()
        }
        
        connectionState = .connected
        selectedProtocol = webSocketTask?.response?.value(forHTTPHeaderField: "Sec-WebSocket-Protocol")
        
        metrics = WebSocketMetrics(
            connectionCount: metrics.connectionCount + 1,
            reconnectionCount: metrics.reconnectionCount,
            messagesSent: metrics.messagesSent,
            messagesReceived: metrics.messagesReceived,
            bytesSent: metrics.bytesSent,
            bytesReceived: metrics.bytesReceived,
            averageLatency: metrics.averageLatency,
            connectionUptime: 0,
            lastError: nil
        )
        
        eventStreamContinuation?.yield(.connected(selectedProtocol))
    }
    
    public func disconnect(code: WebSocketCloseCode = .normal, reason: String? = nil) async {
        guard connectionState == .connected || connectionState == .connecting else {
            return
        }
        
        connectionState = .disconnecting
        
        pingTimer?.invalidate()
        pingTimer = nil
        
        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: code.rawValue) ?? .normalClosure
        let reasonData = reason?.data(using: .utf8)
        
        webSocketTask?.cancel(with: closeCode, reason: reasonData)
        webSocketTask = nil
        
        connectionState = .disconnected
        
        // Update metrics
        if let startTime = connectionStartTime {
            let uptime = Date().timeIntervalSince(startTime)
            metrics = WebSocketMetrics(
                connectionCount: metrics.connectionCount,
                reconnectionCount: metrics.reconnectionCount,
                messagesSent: metrics.messagesSent,
                messagesReceived: metrics.messagesReceived,
                bytesSent: metrics.bytesSent,
                bytesReceived: metrics.bytesReceived,
                averageLatency: metrics.averageLatency,
                connectionUptime: uptime,
                lastError: metrics.lastError
            )
        }
        
        eventStreamContinuation?.yield(.disconnected(code, reason))
    }
    
    public func send(_ message: WebSocketMessage) async throws {
        guard connectionState == .connected, let task = webSocketTask else {
            throw WebSocketError.notConnected
        }
        
        let urlSessionMessage: URLSessionWebSocketTask.Message
        var messageSize: Int64 = 0
        
        switch message {
        case .text(let string):
            guard string.utf8.count <= configuration.maxMessageSize else {
                throw WebSocketError.messageTooLarge
            }
            urlSessionMessage = .string(string)
            messageSize = Int64(string.utf8.count)
            
        case .data(let data):
            guard data.count <= configuration.maxMessageSize else {
                throw WebSocketError.messageTooLarge
            }
            urlSessionMessage = .data(data)
            messageSize = Int64(data.count)
            
        case .ping(let data):
            if let data = data {
                try await task.sendPing(pongReceiveHandler: { _ in })
            } else {
                try await task.sendPing(pongReceiveHandler: { _ in })
            }
            return
            
        case .pong:
            // Pongs are sent automatically
            return
        }
        
        try await task.send(urlSessionMessage)
        
        // Update metrics
        metrics = WebSocketMetrics(
            connectionCount: metrics.connectionCount,
            reconnectionCount: metrics.reconnectionCount,
            messagesSent: metrics.messagesSent + 1,
            messagesReceived: metrics.messagesReceived,
            bytesSent: metrics.bytesSent + messageSize,
            bytesReceived: metrics.bytesReceived,
            averageLatency: metrics.averageLatency,
            connectionUptime: metrics.connectionUptime,
            lastError: metrics.lastError
        )
    }
    
    public var eventStream: AsyncStream<WebSocketEvent> {
        AsyncStream { continuation in
            self.eventStreamContinuation = continuation
        }
    }
    
    public func reconnect() async throws {
        guard configuration.enableReconnection else {
            throw WebSocketError.reconnectionDisabled
        }
        
        guard reconnectionAttempts < configuration.maxReconnectionAttempts else {
            throw WebSocketError.maxReconnectionAttemptsReached
        }
        
        connectionState = .reconnecting
        reconnectionAttempts += 1
        
        // Calculate delay with exponential backoff
        let delay = configuration.reconnectionDelay * pow(configuration.reconnectionBackoffMultiplier, Double(reconnectionAttempts - 1))
        
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        do {
            try await connect()
            reconnectionAttempts = 0 // Reset on successful connection
            
            metrics = WebSocketMetrics(
                connectionCount: metrics.connectionCount,
                reconnectionCount: metrics.reconnectionCount + 1,
                messagesSent: metrics.messagesSent,
                messagesReceived: metrics.messagesReceived,
                bytesSent: metrics.bytesSent,
                bytesReceived: metrics.bytesReceived,
                averageLatency: metrics.averageLatency,
                connectionUptime: metrics.connectionUptime,
                lastError: nil
            )
            
        } catch {
            connectionState = .failed
            
            metrics = WebSocketMetrics(
                connectionCount: metrics.connectionCount,
                reconnectionCount: metrics.reconnectionCount,
                messagesSent: metrics.messagesSent,
                messagesReceived: metrics.messagesReceived,
                bytesSent: metrics.bytesSent,
                bytesReceived: metrics.bytesReceived,
                averageLatency: metrics.averageLatency,
                connectionUptime: metrics.connectionUptime,
                lastError: error.localizedDescription
            )
            
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func startReceiving() {
        guard let task = webSocketTask else { return }
        
        Task {
            do {
                let message = try await task.receive()
                await handleReceivedMessage(message)
                
                // Continue receiving if still connected
                if connectionState == .connected {
                    startReceiving()
                }
            } catch {
                await handleConnectionError(error)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) async {
        var messageSize: Int64 = 0
        let webSocketMessage: WebSocketMessage
        
        switch message {
        case .string(let string):
            webSocketMessage = .text(string)
            messageSize = Int64(string.utf8.count)
            
        case .data(let data):
            webSocketMessage = .data(data)
            messageSize = Int64(data.count)
            
        @unknown default:
            return
        }
        
        // Update metrics
        metrics = WebSocketMetrics(
            connectionCount: metrics.connectionCount,
            reconnectionCount: metrics.reconnectionCount,
            messagesSent: metrics.messagesSent,
            messagesReceived: metrics.messagesReceived + 1,
            bytesSent: metrics.bytesSent,
            bytesReceived: metrics.bytesReceived + messageSize,
            averageLatency: metrics.averageLatency,
            connectionUptime: metrics.connectionUptime,
            lastError: metrics.lastError
        )
        
        eventStreamContinuation?.yield(.message(webSocketMessage))
    }
    
    private func handleConnectionError(_ error: Error) async {
        connectionState = .failed
        
        metrics = WebSocketMetrics(
            connectionCount: metrics.connectionCount,
            reconnectionCount: metrics.reconnectionCount,
            messagesSent: metrics.messagesSent,
            messagesReceived: metrics.messagesReceived,
            bytesSent: metrics.bytesSent,
            bytesReceived: metrics.bytesReceived,
            averageLatency: metrics.averageLatency,
            connectionUptime: metrics.connectionUptime,
            lastError: error.localizedDescription
        )
        
        eventStreamContinuation?.yield(.error(error))
        
        // Attempt reconnection if enabled
        if configuration.enableReconnection && reconnectionAttempts < configuration.maxReconnectionAttempts {
            try? await reconnect()
        }
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: configuration.pingInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                try? await self?.send(.ping(nil))
            }
        }
    }
}

// MARK: - WebSocket Capability Implementation

/// WebSocket capability providing real-time bidirectional communication
public actor WebSocketCapability: DomainCapability {
    public typealias ConfigurationType = WebSocketCapabilityConfiguration
    public typealias ResourceType = WebSocketCapabilityResource
    
    private var _configuration: WebSocketCapabilityConfiguration
    private var _resources: WebSocketCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "websocket-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: WebSocketCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: WebSocketCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: WebSocketCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = WebSocketCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: WebSocketCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid WebSocket configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // WebSocket is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // WebSocket doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - WebSocket Operations
    
    /// Connect to WebSocket server
    public func connect() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("WebSocket capability not available")
        }
        
        try await _resources.connect()
    }
    
    /// Disconnect from WebSocket server
    public func disconnect(code: WebSocketCloseCode = .normal, reason: String? = nil) async {
        guard await isAvailable else { return }
        await _resources.disconnect(code: code, reason: reason)
    }
    
    /// Send text message
    public func sendText(_ text: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("WebSocket capability not available")
        }
        
        try await _resources.send(.text(text))
    }
    
    /// Send binary data
    public func sendData(_ data: Data) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("WebSocket capability not available")
        }
        
        try await _resources.send(.data(data))
    }
    
    /// Send JSON object
    public func sendJSON<T: Codable>(_ object: T, encoder: JSONEncoder = JSONEncoder()) async throws {
        let data = try encoder.encode(object)
        try await sendData(data)
    }
    
    /// Send ping frame
    public func ping(data: Data? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("WebSocket capability not available")
        }
        
        try await _resources.send(.ping(data))
    }
    
    /// Get connection state
    public func getConnectionState() async -> WebSocketState {
        await _resources.getConnectionState()
    }
    
    /// Get selected protocol
    public func getSelectedProtocol() async -> String? {
        await _resources.getSelectedProtocol()
    }
    
    /// Get event stream for WebSocket events
    public func getEventStream() async -> AsyncStream<WebSocketEvent> {
        await _resources.eventStream
    }
    
    /// Manually trigger reconnection
    public func reconnect() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("WebSocket capability not available")
        }
        
        try await _resources.reconnect()
    }
    
    /// Get connection metrics
    public func getMetrics() async -> WebSocketMetrics {
        await _resources.getMetrics()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// WebSocket specific errors
public enum WebSocketError: Error, LocalizedError {
    case notInitialized
    case notConnected
    case invalidState(String)
    case messageTooLarge
    case reconnectionDisabled
    case maxReconnectionAttemptsReached
    case invalidURL
    case connectionFailed(Error)
    case protocolError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "WebSocket is not initialized"
        case .notConnected:
            return "WebSocket is not connected"
        case .invalidState(let state):
            return "Invalid WebSocket state: \(state)"
        case .messageTooLarge:
            return "Message size exceeds maximum allowed size"
        case .reconnectionDisabled:
            return "Automatic reconnection is disabled"
        case .maxReconnectionAttemptsReached:
            return "Maximum reconnection attempts reached"
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionFailed(let error):
            return "WebSocket connection failed: \(error.localizedDescription)"
        case .protocolError(let message):
            return "WebSocket protocol error: \(message)"
        }
    }
}