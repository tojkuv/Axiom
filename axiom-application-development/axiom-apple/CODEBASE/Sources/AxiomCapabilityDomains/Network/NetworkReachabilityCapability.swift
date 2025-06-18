import Foundation
import Network
import SystemConfiguration
import AxiomCore
import AxiomCapabilities

// MARK: - Network Reachability Capability Configuration

/// Configuration for Network Reachability capability
public struct NetworkReachabilityCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableCellularMonitoring: Bool
    public let enableWiFiMonitoring: Bool
    public let enableExpensivePathMonitoring: Bool
    public let enableConstrainedPathMonitoring: Bool
    public let monitoringInterval: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let hostToMonitor: String?
    public let enableInterfaceMonitoring: Bool
    public let requiredInterfaces: [NetworkInterfaceType]
    
    public init(
        enableCellularMonitoring: Bool = true,
        enableWiFiMonitoring: Bool = true,
        enableExpensivePathMonitoring: Bool = true,
        enableConstrainedPathMonitoring: Bool = true,
        monitoringInterval: TimeInterval = 1.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        hostToMonitor: String? = nil,
        enableInterfaceMonitoring: Bool = true,
        requiredInterfaces: [NetworkInterfaceType] = []
    ) {
        self.enableCellularMonitoring = enableCellularMonitoring
        self.enableWiFiMonitoring = enableWiFiMonitoring
        self.enableExpensivePathMonitoring = enableExpensivePathMonitoring
        self.enableConstrainedPathMonitoring = enableConstrainedPathMonitoring
        self.monitoringInterval = monitoringInterval
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.hostToMonitor = hostToMonitor
        self.enableInterfaceMonitoring = enableInterfaceMonitoring
        self.requiredInterfaces = requiredInterfaces
    }
    
    public var isValid: Bool {
        monitoringInterval > 0
    }
    
    public func merged(with other: NetworkReachabilityCapabilityConfiguration) -> NetworkReachabilityCapabilityConfiguration {
        NetworkReachabilityCapabilityConfiguration(
            enableCellularMonitoring: other.enableCellularMonitoring,
            enableWiFiMonitoring: other.enableWiFiMonitoring,
            enableExpensivePathMonitoring: other.enableExpensivePathMonitoring,
            enableConstrainedPathMonitoring: other.enableConstrainedPathMonitoring,
            monitoringInterval: other.monitoringInterval,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            hostToMonitor: other.hostToMonitor ?? hostToMonitor,
            enableInterfaceMonitoring: other.enableInterfaceMonitoring,
            requiredInterfaces: other.requiredInterfaces.isEmpty ? requiredInterfaces : other.requiredInterfaces
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> NetworkReachabilityCapabilityConfiguration {
        var adjustedInterval = monitoringInterval
        var adjustedLogging = enableLogging
        var adjustedCellular = enableCellularMonitoring
        
        if environment.isLowPowerMode {
            adjustedInterval = max(monitoringInterval, 5.0) // Less frequent monitoring
            adjustedCellular = true // Important for power management
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return NetworkReachabilityCapabilityConfiguration(
            enableCellularMonitoring: adjustedCellular,
            enableWiFiMonitoring: enableWiFiMonitoring,
            enableExpensivePathMonitoring: enableExpensivePathMonitoring,
            enableConstrainedPathMonitoring: enableConstrainedPathMonitoring,
            monitoringInterval: adjustedInterval,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            hostToMonitor: hostToMonitor,
            enableInterfaceMonitoring: enableInterfaceMonitoring,
            requiredInterfaces: requiredInterfaces
        )
    }
}

// MARK: - Network Reachability Types

/// Network connection types
public enum NetworkConnectionType: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case wifi = "wifi"
    case cellular = "cellular"
    case wired = "wired"
    case loopback = "loopback"
    case other = "other"
}

/// Network interface types
public enum NetworkInterfaceType: String, Codable, CaseIterable, Sendable {
    case wifi = "wifi"
    case cellular = "cellular"
    case wiredEthernet = "wiredEthernet"
    case loopback = "loopback"
    case other = "other"
}

/// Network path status
public enum NetworkPathStatus: String, Codable, CaseIterable, Sendable {
    case satisfied = "satisfied"
    case unsatisfied = "unsatisfied"
    case requiresConnection = "requiresConnection"
}

/// Network reachability status
public struct NetworkReachabilityStatus: Sendable, Codable {
    public let isReachable: Bool
    public let connectionType: NetworkConnectionType
    public let pathStatus: NetworkPathStatus
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let supportsDNS: Bool
    public let supportsIPv4: Bool
    public let supportsIPv6: Bool
    public let availableInterfaces: [NetworkInterfaceType]
    public let timestamp: Date
    public let localWiFiAddress: String?
    public let publicIPAddress: String?
    
    public init(
        isReachable: Bool,
        connectionType: NetworkConnectionType,
        pathStatus: NetworkPathStatus,
        isExpensive: Bool = false,
        isConstrained: Bool = false,
        supportsDNS: Bool = false,
        supportsIPv4: Bool = false,
        supportsIPv6: Bool = false,
        availableInterfaces: [NetworkInterfaceType] = [],
        timestamp: Date = Date(),
        localWiFiAddress: String? = nil,
        publicIPAddress: String? = nil
    ) {
        self.isReachable = isReachable
        self.connectionType = connectionType
        self.pathStatus = pathStatus
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.supportsDNS = supportsDNS
        self.supportsIPv4 = supportsIPv4
        self.supportsIPv6 = supportsIPv6
        self.availableInterfaces = availableInterfaces
        self.timestamp = timestamp
        self.localWiFiAddress = localWiFiAddress
        self.publicIPAddress = publicIPAddress
    }
    
    public var connectionQuality: NetworkConnectionQuality {
        if !isReachable {
            return .none
        } else if isExpensive || isConstrained {
            return .poor
        } else if connectionType == .cellular {
            return .fair
        } else if connectionType == .wifi {
            return .good
        } else {
            return .excellent
        }
    }
}

/// Network connection quality levels
public enum NetworkConnectionQuality: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
    
    public var score: Int {
        switch self {
        case .none: return 0
        case .poor: return 1
        case .fair: return 2
        case .good: return 3
        case .excellent: return 4
        }
    }
}

/// Network reachability metrics
public struct NetworkReachabilityMetrics: Sendable {
    public let connectionChanges: Int
    public let totalUptime: TimeInterval
    public let totalDowntime: TimeInterval
    public let averageConnectionQuality: Double
    public let lastConnectionChange: Date?
    public let connectionHistory: [NetworkReachabilityStatus]
    
    public init(
        connectionChanges: Int = 0,
        totalUptime: TimeInterval = 0,
        totalDowntime: TimeInterval = 0,
        averageConnectionQuality: Double = 0,
        lastConnectionChange: Date? = nil,
        connectionHistory: [NetworkReachabilityStatus] = []
    ) {
        self.connectionChanges = connectionChanges
        self.totalUptime = totalUptime
        self.totalDowntime = totalDowntime
        self.averageConnectionQuality = averageConnectionQuality
        self.lastConnectionChange = lastConnectionChange
        self.connectionHistory = connectionHistory
    }
}

// MARK: - Network Reachability Resource

/// Network Reachability resource management
public actor NetworkReachabilityCapabilityResource: AxiomCapabilityResource {
    private let configuration: NetworkReachabilityCapabilityConfiguration
    private var pathMonitor: NWPathMonitor?
    private var pathUpdateQueue: DispatchQueue?
    private var currentStatus: NetworkReachabilityStatus
    private var statusStreamContinuation: AsyncStream<NetworkReachabilityStatus>.Continuation?
    private var metrics: NetworkReachabilityMetrics
    private var connectionStartTime: Date?
    private var isMonitoring: Bool = false
    
    public init(configuration: NetworkReachabilityCapabilityConfiguration) {
        self.configuration = configuration
        self.currentStatus = NetworkReachabilityStatus(
            isReachable: false,
            connectionType: .none,
            pathStatus: .unsatisfied
        )
        self.metrics = NetworkReachabilityMetrics()
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 1_000_000, // 1MB for monitoring structures
            cpu: 1.0, // Low CPU usage for monitoring
            bandwidth: 0, // No bandwidth usage
            storage: 100_000 // 100KB for metrics storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            return ResourceUsage(
                memory: isMonitoring ? 500_000 : 100_000,
                cpu: isMonitoring ? 0.5 : 0.1,
                bandwidth: 0,
                storage: metrics.connectionHistory.count * 1000 // Rough estimate
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        pathMonitor != nil
    }
    
    public func release() async {
        await stopMonitoring()
        pathMonitor?.cancel()
        pathMonitor = nil
        pathUpdateQueue = nil
        statusStreamContinuation?.finish()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        pathUpdateQueue = DispatchQueue(label: "com.axiom.network-reachability", qos: .utility)
        
        // Initialize path monitor
        if let host = configuration.hostToMonitor {
            pathMonitor = NWPathMonitor()
            // For host-specific monitoring, we would need to create endpoint
        } else {
            pathMonitor = NWPathMonitor()
        }
        
        guard let monitor = pathMonitor, let queue = pathUpdateQueue else {
            throw AxiomCapabilityError.initializationFailed("Failed to create path monitor")
        }
        
        // Set up path update handler
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.handlePathUpdate(path)
            }
        }
    }
    
    internal func updateConfiguration(_ configuration: NetworkReachabilityCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Network Reachability Access
    
    public func getCurrentStatus() -> NetworkReachabilityStatus {
        currentStatus
    }
    
    public func getMetrics() -> NetworkReachabilityMetrics {
        metrics
    }
    
    public func startMonitoring() async throws {
        guard let monitor = pathMonitor, let queue = pathUpdateQueue else {
            throw NetworkReachabilityError.notInitialized
        }
        
        guard !isMonitoring else {
            throw NetworkReachabilityError.alreadyMonitoring
        }
        
        isMonitoring = true
        connectionStartTime = Date()
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() async {
        guard isMonitoring else { return }
        
        pathMonitor?.cancel()
        isMonitoring = false
        
        // Update metrics
        if let startTime = connectionStartTime {
            let sessionDuration = Date().timeIntervalSince(startTime)
            if currentStatus.isReachable {
                metrics = NetworkReachabilityMetrics(
                    connectionChanges: metrics.connectionChanges,
                    totalUptime: metrics.totalUptime + sessionDuration,
                    totalDowntime: metrics.totalDowntime,
                    averageConnectionQuality: metrics.averageConnectionQuality,
                    lastConnectionChange: metrics.lastConnectionChange,
                    connectionHistory: metrics.connectionHistory
                )
            } else {
                metrics = NetworkReachabilityMetrics(
                    connectionChanges: metrics.connectionChanges,
                    totalUptime: metrics.totalUptime,
                    totalDowntime: metrics.totalDowntime + sessionDuration,
                    averageConnectionQuality: metrics.averageConnectionQuality,
                    lastConnectionChange: metrics.lastConnectionChange,
                    connectionHistory: metrics.connectionHistory
                )
            }
        }
    }
    
    public var statusStream: AsyncStream<NetworkReachabilityStatus> {
        AsyncStream { continuation in
            self.statusStreamContinuation = continuation
            continuation.yield(currentStatus)
        }
    }
    
    public func checkReachability(to host: String) async throws -> Bool {
        guard let url = URL(string: "https://\(host)") else {
            throw NetworkReachabilityError.invalidHost(host)
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    public func getLocalIPAddress() async -> String? {
        var address: String?
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        defer { freeifaddrs(ifaddr) }
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                
                if name == "en0" { // WiFi interface
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        
        return address
    }
    
    // MARK: - Private Methods
    
    private func handlePathUpdate(_ path: NWPath) async {
        let newStatus = createStatus(from: path)
        let oldStatus = currentStatus
        
        // Check if status actually changed
        if newStatus.isReachable != oldStatus.isReachable ||
           newStatus.connectionType != oldStatus.connectionType ||
           newStatus.pathStatus != oldStatus.pathStatus {
            
            currentStatus = newStatus
            
            // Update metrics
            let now = Date()
            var newHistory = metrics.connectionHistory
            newHistory.append(newStatus)
            
            // Keep only last 100 status changes
            if newHistory.count > 100 {
                newHistory = Array(newHistory.suffix(100))
            }
            
            // Calculate average connection quality
            let qualityScores = newHistory.map { $0.connectionQuality.score }
            let averageQuality = qualityScores.isEmpty ? 0 : Double(qualityScores.reduce(0, +)) / Double(qualityScores.count)
            
            metrics = NetworkReachabilityMetrics(
                connectionChanges: metrics.connectionChanges + 1,
                totalUptime: metrics.totalUptime,
                totalDowntime: metrics.totalDowntime,
                averageConnectionQuality: averageQuality,
                lastConnectionChange: now,
                connectionHistory: newHistory
            )
            
            // Notify observers
            statusStreamContinuation?.yield(newStatus)
            
            if configuration.enableLogging {
                await logStatusChange(from: oldStatus, to: newStatus)
            }
        }
    }
    
    private func createStatus(from path: NWPath) -> NetworkReachabilityStatus {
        let pathStatus: NetworkPathStatus
        switch path.status {
        case .satisfied:
            pathStatus = .satisfied
        case .unsatisfied:
            pathStatus = .unsatisfied
        case .requiresConnection:
            pathStatus = .requiresConnection
        @unknown default:
            pathStatus = .unsatisfied
        }
        
        let connectionType: NetworkConnectionType
        let availableInterfaces: [NetworkInterfaceType]
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
            availableInterfaces = [.wifi]
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
            availableInterfaces = [.cellular]
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
            availableInterfaces = [.wiredEthernet]
        } else if path.usesInterfaceType(.loopback) {
            connectionType = .loopback
            availableInterfaces = [.loopback]
        } else {
            connectionType = path.status == .satisfied ? .other : .none
            availableInterfaces = []
        }
        
        return NetworkReachabilityStatus(
            isReachable: path.status == .satisfied,
            connectionType: connectionType,
            pathStatus: pathStatus,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            supportsDNS: path.supportsDNS,
            supportsIPv4: path.supportsIPv4,
            supportsIPv6: path.supportsIPv6,
            availableInterfaces: availableInterfaces,
            timestamp: Date()
        )
    }
    
    private func logStatusChange(from oldStatus: NetworkReachabilityStatus, to newStatus: NetworkReachabilityStatus) async {
        let oldConnection = oldStatus.isReachable ? oldStatus.connectionType.rawValue : "disconnected"
        let newConnection = newStatus.isReachable ? newStatus.connectionType.rawValue : "disconnected"
        
        print("[NetworkReachability] 🔄 Connection changed: \(oldConnection) -> \(newConnection)")
        
        if newStatus.isExpensive {
            print("[NetworkReachability] 💰 Connection is expensive")
        }
        
        if newStatus.isConstrained {
            print("[NetworkReachability] 🚫 Connection is constrained")
        }
    }
}

// MARK: - Network Reachability Capability Implementation

/// Network Reachability capability providing network state monitoring
public actor NetworkReachabilityCapability: DomainCapability {
    public typealias ConfigurationType = NetworkReachabilityCapabilityConfiguration
    public typealias ResourceType = NetworkReachabilityCapabilityResource
    
    private var _configuration: NetworkReachabilityCapabilityConfiguration
    private var _resources: NetworkReachabilityCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "network-reachability-capability" }
    
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
    
    public var configuration: NetworkReachabilityCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: NetworkReachabilityCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: NetworkReachabilityCapabilityConfiguration = NetworkReachabilityCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = NetworkReachabilityCapabilityResource(configuration: self._configuration)
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
            try await _resources.startMonitoring()
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
    
    public func updateConfiguration(_ configuration: NetworkReachabilityCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Network Reachability configuration")
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
        // Network reachability is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Network reachability doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Network Reachability Operations
    
    /// Get current network status
    public func getCurrentStatus() async -> NetworkReachabilityStatus {
        guard await isAvailable else {
            return NetworkReachabilityStatus(isReachable: false, connectionType: .none, pathStatus: .unsatisfied)
        }
        
        return await _resources.getCurrentStatus()
    }
    
    /// Check if network is reachable
    public func isReachable() async -> Bool {
        let status = await getCurrentStatus()
        return status.isReachable
    }
    
    /// Check if connection is expensive (cellular)
    public func isExpensive() async -> Bool {
        let status = await getCurrentStatus()
        return status.isExpensive
    }
    
    /// Check if connection is constrained
    public func isConstrained() async -> Bool {
        let status = await getCurrentStatus()
        return status.isConstrained
    }
    
    /// Get current connection type
    public func getConnectionType() async -> NetworkConnectionType {
        let status = await getCurrentStatus()
        return status.connectionType
    }
    
    /// Get connection quality assessment
    public func getConnectionQuality() async -> NetworkConnectionQuality {
        let status = await getCurrentStatus()
        return status.connectionQuality
    }
    
    /// Get stream of network status changes
    public func getStatusStream() async -> AsyncStream<NetworkReachabilityStatus> {
        await _resources.statusStream
    }
    
    /// Check reachability to specific host
    public func checkReachability(to host: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Reachability capability not available")
        }
        
        return try await _resources.checkReachability(to: host)
    }
    
    /// Get local IP address
    public func getLocalIPAddress() async -> String? {
        guard await isAvailable else { return nil }
        return await _resources.getLocalIPAddress()
    }
    
    /// Get network metrics
    public func getMetrics() async -> NetworkReachabilityMetrics {
        await _resources.getMetrics()
    }
    
    /// Wait for network to become available
    public func waitForConnection(timeout: TimeInterval = 30.0) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Reachability capability not available")
        }
        
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            let status = await getCurrentStatus()
            if status.isReachable {
                return
            }
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        throw NetworkReachabilityError.connectionTimeout
    }
    
    /// Wait for specific connection type
    public func waitForConnectionType(_ type: NetworkConnectionType, timeout: TimeInterval = 30.0) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Reachability capability not available")
        }
        
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            let status = await getCurrentStatus()
            if status.isReachable && status.connectionType == type {
                return
            }
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        throw NetworkReachabilityError.connectionTimeout
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Network Reachability specific errors
public enum NetworkReachabilityError: Error, LocalizedError {
    case notInitialized
    case alreadyMonitoring
    case invalidHost(String)
    case connectionTimeout
    case monitoringFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Network reachability monitor is not initialized"
        case .alreadyMonitoring:
            return "Network reachability monitoring is already active"
        case .invalidHost(let host):
            return "Invalid host for reachability check: \(host)"
        case .connectionTimeout:
            return "Connection timeout while waiting for network"
        case .monitoringFailed(let error):
            return "Network monitoring failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension NetworkReachabilityStatus: Equatable {
    public static func == (lhs: NetworkReachabilityStatus, rhs: NetworkReachabilityStatus) -> Bool {
        return lhs.isReachable == rhs.isReachable &&
               lhs.connectionType == rhs.connectionType &&
               lhs.pathStatus == rhs.pathStatus &&
               lhs.isExpensive == rhs.isExpensive &&
               lhs.isConstrained == rhs.isConstrained
    }
}