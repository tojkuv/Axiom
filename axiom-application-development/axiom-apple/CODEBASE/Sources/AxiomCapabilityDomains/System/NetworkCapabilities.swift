import Foundation
import AxiomCapabilities
import AxiomCore
import Network

// MARK: - Network Capability Configuration

/// Network capability configuration
public struct NetworkCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let timeout: TimeInterval
    public let maxConcurrentConnections: Int
    public let connectionTimeout: TimeInterval
    public let allowsCellularAccess: Bool
    public let enableLogging: Bool
    public let enableCaching: Bool
    public let cachePolicy: URLRequest.CachePolicy
    
    // Custom Codable implementation to handle URLRequest.CachePolicy
    private enum CodingKeys: String, CodingKey {
        case timeout
        case maxConcurrentConnections
        case connectionTimeout
        case allowsCellularAccess
        case enableLogging
        case enableCaching
        case cachePolicyRawValue
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        maxConcurrentConnections = try container.decode(Int.self, forKey: .maxConcurrentConnections)
        connectionTimeout = try container.decode(TimeInterval.self, forKey: .connectionTimeout)
        allowsCellularAccess = try container.decode(Bool.self, forKey: .allowsCellularAccess)
        enableLogging = try container.decode(Bool.self, forKey: .enableLogging)
        enableCaching = try container.decode(Bool.self, forKey: .enableCaching)
        
        let cachePolicyRawValue = try container.decode(UInt.self, forKey: .cachePolicyRawValue)
        cachePolicy = URLRequest.CachePolicy(rawValue: cachePolicyRawValue) ?? .useProtocolCachePolicy
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeout, forKey: .timeout)
        try container.encode(maxConcurrentConnections, forKey: .maxConcurrentConnections)
        try container.encode(connectionTimeout, forKey: .connectionTimeout)
        try container.encode(allowsCellularAccess, forKey: .allowsCellularAccess)
        try container.encode(enableLogging, forKey: .enableLogging)
        try container.encode(enableCaching, forKey: .enableCaching)
        try container.encode(cachePolicy.rawValue, forKey: .cachePolicyRawValue)
    }
    
    public init(
        timeout: TimeInterval = 30.0,
        maxConcurrentConnections: Int = 10,
        connectionTimeout: TimeInterval = 15.0,
        allowsCellularAccess: Bool = true,
        enableLogging: Bool = false,
        enableCaching: Bool = true,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.timeout = timeout
        self.maxConcurrentConnections = maxConcurrentConnections
        self.connectionTimeout = connectionTimeout
        self.allowsCellularAccess = allowsCellularAccess
        self.enableLogging = enableLogging
        self.enableCaching = enableCaching
        self.cachePolicy = cachePolicy
    }
    
    public var isValid: Bool {
        return timeout > 0 && 
               maxConcurrentConnections > 0 &&
               connectionTimeout > 0
    }
    
    public func merged(with other: NetworkCapabilityConfiguration) -> NetworkCapabilityConfiguration {
        return NetworkCapabilityConfiguration(
            timeout: other.timeout,
            maxConcurrentConnections: other.maxConcurrentConnections,
            connectionTimeout: other.connectionTimeout,
            allowsCellularAccess: other.allowsCellularAccess,
            enableLogging: other.enableLogging,
            enableCaching: other.enableCaching,
            cachePolicy: other.cachePolicy
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> NetworkCapabilityConfiguration {
        var adjustedTimeout = timeout
        var adjustedLogging = enableLogging
        var adjustedCellular = allowsCellularAccess
        
        if environment.isDebug {
            adjustedTimeout *= 2.0 // More lenient in debug
            adjustedLogging = true
        }
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 1.5 // More lenient on battery
            adjustedCellular = false // Preserve battery
        }
        
        return NetworkCapabilityConfiguration(
            timeout: adjustedTimeout,
            maxConcurrentConnections: maxConcurrentConnections,
            connectionTimeout: connectionTimeout,
            allowsCellularAccess: adjustedCellular,
            enableLogging: adjustedLogging,
            enableCaching: enableCaching,
            cachePolicy: cachePolicy
        )
    }
}

// MARK: - Network Status

/// Network status information
public struct NetworkStatus: Sendable, Equatable, Codable {
    public let isConnected: Bool
    public let connectionType: ConnectionType?
    public let timestamp: Date
    
    public enum ConnectionType: String, Codable, Sendable {
        case wifi
        case cellular
        case wired
        case other
    }
    
    public init(isConnected: Bool, connectionType: ConnectionType?, timestamp: Date = Date()) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.timestamp = timestamp
    }
    
    public var isWiFi: Bool { connectionType == .wifi }
    public var isCellular: Bool { connectionType == .cellular }
    public var isWired: Bool { connectionType == .wired }
}

// MARK: - Network Execution Context

/// Context for network request execution
public struct NetworkExecutionContext: Sendable {
    public let requestId: UUID
    public let startTime: Date
    public let metadata: [String: String]
    
    public init(requestId: UUID = UUID(), startTime: Date = Date(), metadata: [String: String] = [:]) {
        self.requestId = requestId
        self.startTime = startTime
        self.metadata = metadata
    }
}

// MARK: - Network Execution Result

/// Result of network request execution
public struct NetworkExecutionResult: Sendable {
    public let data: Data
    public let response: URLResponse
    public let duration: TimeInterval
    public let context: NetworkExecutionContext
    
    public init(data: Data, response: URLResponse, duration: TimeInterval, context: NetworkExecutionContext) {
        self.data = data
        self.response = response
        self.duration = duration
        self.context = context
    }
    
    /// HTTP status code if applicable
    public var httpStatusCode: Int? {
        (response as? HTTPURLResponse)?.statusCode
    }
    
    /// HTTP headers if applicable
    public var httpHeaders: [String: String]? {
        guard let httpResponse = response as? HTTPURLResponse else { return nil }
        return httpResponse.allHeaderFields.reduce(into: [:]) { result, element in
            if let key = element.key as? String, let value = element.value as? String {
                result[key] = value
            }
        }
    }
}

// MARK: - Network Capability Resource

/// Network resource management
public actor NetworkCapabilityResource: AxiomCapabilityResource {
    private var activeConnections: Set<UUID> = []
    private let maxConnections: Int
    private var _isAvailable: Bool = true
    private var sessionConfiguration: URLSessionConfiguration
    private var urlSession: URLSession?
    private let configuration: NetworkCapabilityConfiguration
    
    public init(configuration: NetworkCapabilityConfiguration) {
        self.configuration = configuration
        self.maxConnections = configuration.maxConcurrentConnections
        self.sessionConfiguration = URLSessionConfiguration.default
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: maxConnections * 2_000_000, // 2MB per connection max
            cpu: Double(maxConnections * 3), // 3% CPU per connection max
            bandwidth: maxConnections * 50_000, // 50KB/s per connection max
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let connectionCount = activeConnections.count
            let estimatedBandwidth = connectionCount * 50_000 // 50KB/s per connection
            
            return ResourceUsage(
                memory: connectionCount * 2_000_000, // 2MB per connection
                cpu: Double(connectionCount * 3), // 3% CPU per connection
                bandwidth: estimatedBandwidth,
                storage: 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        return _isAvailable && activeConnections.count < maxConnections
    }
    
    public func allocate() async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Connection limit reached or resource unavailable")
        }
        
        let connectionId = UUID()
        activeConnections.insert(connectionId)
    }
    
    public func release() async {
        if let connectionId = activeConnections.first {
            activeConnections.remove(connectionId)
        }
    }
    
    public func releaseAll() async {
        activeConnections.removeAll()
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
    
    // MARK: - Session Management
    
    private func configureSession() -> URLSessionConfiguration {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.connectionTimeout
        sessionConfig.httpMaximumConnectionsPerHost = configuration.maxConcurrentConnections
        sessionConfig.allowsCellularAccess = configuration.allowsCellularAccess
        
        if !configuration.enableCaching {
            sessionConfig.urlCache = nil
        }
        
        sessionConfig.requestCachePolicy = configuration.cachePolicy
        return sessionConfig
    }
    
    public func getSession() async -> URLSession {
        if let session = urlSession {
            return session
        }
        
        sessionConfiguration = configureSession()
        let session = URLSession(configuration: sessionConfiguration)
        urlSession = session
        return session
    }
    
    public func updateConfiguration(_ newConfiguration: NetworkCapabilityConfiguration) async {
        sessionConfiguration = configureSession()
        
        // Create new session with updated configuration
        urlSession?.invalidateAndCancel()
        urlSession = URLSession(configuration: sessionConfiguration)
    }
}

// MARK: - Network Monitor

/// Network connectivity monitoring
public actor NetworkMonitor {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var isConnected: Bool = false
    private var connectionType: NetworkStatus.ConnectionType?
    private var stateStreamContinuation: AsyncStream<NetworkStatus>.Continuation?
    
    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.axiom.network-monitor", qos: .utility)
    }
    
    public func start() async {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    public func stop() async {
        monitor.cancel()
        stateStreamContinuation?.finish()
    }
    
    public var status: NetworkStatus {
        get async { 
            NetworkStatus(
                isConnected: isConnected,
                connectionType: connectionType
            )
        }
    }
    
    public var statusStream: AsyncStream<NetworkStatus> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let status = await self?.status {
                    continuation.yield(status)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<NetworkStatus>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    private func handlePathUpdate(_ path: NWPath) async {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .wired
            } else {
                connectionType = .other
            }
        } else {
            connectionType = nil
        }
        
        if wasConnected != isConnected {
            let status = NetworkStatus(isConnected: isConnected, connectionType: connectionType)
            stateStreamContinuation?.yield(status)
        }
    }
}

// MARK: - Network Capability Implementation

/// Network capability providing foundational network execution services
public actor NetworkCapability: DomainCapability {
    public typealias ConfigurationType = NetworkCapabilityConfiguration
    public typealias ResourceType = NetworkCapabilityResource
    
    private var _configuration: NetworkCapabilityConfiguration
    private var _resources: NetworkCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    private var networkMonitor: NetworkMonitor
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "network-capability" }
    
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
    
    public var configuration: NetworkCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: NetworkCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: NetworkCapabilityConfiguration = NetworkCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = NetworkCapabilityResource(configuration: self._configuration)
        self._environment = environment
        self.networkMonitor = NetworkMonitor()
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: NetworkCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid network configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public func isSupported() async -> Bool {
        return true // Network capability always supported on iOS
    }
    
    public func requestPermission() async throws {
        // Network capabilities typically don't require explicit permission
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public func activate() async throws {
        guard await _resources.isAvailable() else {
            throw AxiomCapabilityError.initializationFailed("Network resources not available")
        }
        
        await networkMonitor.start()
        
        let networkStatus = await networkMonitor.status
        if !networkStatus.isConnected && !_configuration.allowsCellularAccess {
            throw AxiomCapabilityError.unavailable("Network not available and cellular access disabled")
        }
        
        await transitionTo(AxiomCapabilityState.available)
        try await _resources.allocate()
        
        // Start monitoring network changes
        Task { [weak self] in
            guard let self = self else { return }
            for await status in await self.networkMonitor.statusStream {
                await self.handleNetworkChange(status: status)
            }
        }
    }
    
    public func deactivate() async {
        await transitionTo(AxiomCapabilityState.unavailable)
        await _resources.releaseAll()
        await networkMonitor.stop()
        stateStreamContinuation?.finish()
    }
    
    public func shutdown() async throws {
        await deactivate()
    }
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    private func handleNetworkChange(status: NetworkStatus) async {
        if status.isConnected && _state == .unavailable {
            do {
                try await activate()
            } catch {
                await transitionTo(AxiomCapabilityState.restricted)
            }
        } else if !status.isConnected && _state == AxiomCapabilityState.available {
            await transitionTo(AxiomCapabilityState.unavailable)
        }
    }
    
    // MARK: - Core Network Execution
    
    /// Execute a URLRequest - the foundational network operation
    /// Applications build their own clients on top of this primitive
    public func execute(_ request: URLRequest, context: NetworkExecutionContext = NetworkExecutionContext()) async throws -> NetworkExecutionResult {
        guard _state == AxiomCapabilityState.available else {
            throw AxiomCapabilityError.unavailable("Network capability not available")
        }
        
        let session = await _resources.getSession()
        let startTime = ContinuousClock.now
        
        if _configuration.enableLogging {
            await logRequest(request, context: context)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            let duration = ContinuousClock.now - startTime
            
            let result = NetworkExecutionResult(
                data: data,
                response: response,
                duration: duration.timeInterval,
                context: context
            )
            
            if _configuration.enableLogging {
                await logResponse(result)
            }
            
            return result
            
        } catch let error as URLError {
            if _configuration.enableLogging {
                await logError(error, request: request, context: context)
            }
            throw mapURLError(error)
        } catch {
            if _configuration.enableLogging {
                await logError(error, request: request, context: context)
            }
            throw AxiomNetworkError.requestFailed(error.localizedDescription)
        }
    }
    
    /// Get current network status
    public func getNetworkStatus() async -> NetworkStatus {
        return await networkMonitor.status
    }
    
    /// Get network status stream for monitoring
    public func getNetworkStatusStream() async -> AsyncStream<NetworkStatus> {
        return await networkMonitor.statusStream
    }
    
    // MARK: - Private Helpers
    
    private func mapURLError(_ error: URLError) -> AxiomNetworkError {
        switch error.code {
        case .notConnectedToInternet:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case .badURL:
            return .invalidURL(error.localizedDescription)
        case .secureConnectionFailed:
            return .tlsError(error.localizedDescription)
        default:
            return .requestFailed(error.localizedDescription)
        }
    }
    
    private func logRequest(_ request: URLRequest, context: NetworkExecutionContext) async {
        print("[Network] Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown") [ID: \(context.requestId)]")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("[Network] Headers: \(headers)")
        }
    }
    
    private func logResponse(_ result: NetworkExecutionResult) async {
        let status = result.httpStatusCode ?? 0
        print("[Network] Response: \(status) in \(String(format: "%.3f", result.duration))s [ID: \(result.context.requestId)]")
    }
    
    private func logError(_ error: any Error, request: URLRequest, context: NetworkExecutionContext) async {
        print("[Network] Error: \(error.localizedDescription) for \(request.url?.absoluteString ?? "unknown") [ID: \(context.requestId)]")
    }
}

// MARK: - Duration Extension

extension Duration {
    var timeInterval: TimeInterval {
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}