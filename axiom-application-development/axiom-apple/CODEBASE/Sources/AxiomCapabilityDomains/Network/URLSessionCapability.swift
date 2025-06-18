import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - URLSession Capability Configuration

/// Configuration for URLSession capability
public struct URLSessionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let sessionType: SessionType
    public let timeoutIntervalForRequest: TimeInterval
    public let timeoutIntervalForResource: TimeInterval
    public let httpMaximumConnectionsPerHost: Int
    public let httpShouldUsePipelining: Bool
    public let httpShouldSetCookies: Bool
    public let httpCookieAcceptPolicy: HTTPCookieAcceptPolicy
    public let requestCachePolicy: URLRequest.CachePolicy
    public let allowsCellularAccess: Bool
    public let allowsExpensiveNetworkAccess: Bool
    public let allowsConstrainedNetworkAccess: Bool
    public let waitsForConnectivity: Bool
    public let isDiscretionary: Bool
    public let shouldUseExtendedBackgroundIdleMode: Bool
    public let protocolClasses: [String]
    public let connectionProxyDictionary: [String: Any]?
    public let tlsMinimumSupportedProtocolVersion: TLSProtocolVersion
    public let tlsMaximumSupportedProtocolVersion: TLSProtocolVersion
    public let urlCredentialStorage: URLCredentialStoragePolicy
    public let urlCache: URLCachePolicy?
    public let httpAdditionalHeaders: [String: String]
    public let httpMaximumConnectionLifetime: TimeInterval
    public let enableMultipathServiceType: MultipathServiceType
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let sessionIdentifier: String?
    
    public enum SessionType: String, Codable, CaseIterable, Sendable {
        case `default` = "default"
        case ephemeral = "ephemeral"
        case background = "background"
    }
    
    public enum URLCachePolicy: String, Codable, CaseIterable, Sendable {
        case `default` = "default"
        case disabled = "disabled"
        case custom = "custom"
    }
    
    public enum URLCredentialStoragePolicy: String, Codable, CaseIterable, Sendable {
        case `default` = "default"
        case disabled = "disabled"
    }
    
    public enum TLSProtocolVersion: String, Codable, CaseIterable, Sendable {
        case tlsProtocol10 = "tlsProtocol10"
        case tlsProtocol11 = "tlsProtocol11"
        case tlsProtocol12 = "tlsProtocol12"
        case tlsProtocol13 = "tlsProtocol13"
    }
    
    public enum MultipathServiceType: String, Codable, CaseIterable, Sendable {
        case none = "none"
        case handover = "handover"
        case interactive = "interactive"
        case aggregate = "aggregate"
    }
    
    // Custom Codable implementation to handle complex types
    private enum CodingKeys: String, CodingKey {
        case sessionType, timeoutIntervalForRequest, timeoutIntervalForResource
        case httpMaximumConnectionsPerHost, httpShouldUsePipelining, httpShouldSetCookies
        case httpCookieAcceptPolicyRawValue, requestCachePolicyRawValue
        case allowsCellularAccess, allowsExpensiveNetworkAccess, allowsConstrainedNetworkAccess
        case waitsForConnectivity, isDiscretionary, shouldUseExtendedBackgroundIdleMode
        case protocolClasses, tlsMinimumSupportedProtocolVersion, tlsMaximumSupportedProtocolVersion
        case urlCredentialStorage, urlCache, httpAdditionalHeaders
        case httpMaximumConnectionLifetime, enableMultipathServiceType
        case enableLogging, enableMetrics, sessionIdentifier
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionType = try container.decode(SessionType.self, forKey: .sessionType)
        timeoutIntervalForRequest = try container.decode(TimeInterval.self, forKey: .timeoutIntervalForRequest)
        timeoutIntervalForResource = try container.decode(TimeInterval.self, forKey: .timeoutIntervalForResource)
        httpMaximumConnectionsPerHost = try container.decode(Int.self, forKey: .httpMaximumConnectionsPerHost)
        httpShouldUsePipelining = try container.decode(Bool.self, forKey: .httpShouldUsePipelining)
        httpShouldSetCookies = try container.decode(Bool.self, forKey: .httpShouldSetCookies)
        
        let cookiePolicyRaw = try container.decode(UInt.self, forKey: .httpCookieAcceptPolicyRawValue)
        httpCookieAcceptPolicy = HTTPCookieAcceptPolicy(rawValue: cookiePolicyRaw) ?? .onlyFromMainDocumentDomain
        
        let cachePolicyRaw = try container.decode(UInt.self, forKey: .requestCachePolicyRawValue)
        requestCachePolicy = URLRequest.CachePolicy(rawValue: cachePolicyRaw) ?? .useProtocolCachePolicy
        
        allowsCellularAccess = try container.decode(Bool.self, forKey: .allowsCellularAccess)
        allowsExpensiveNetworkAccess = try container.decode(Bool.self, forKey: .allowsExpensiveNetworkAccess)
        allowsConstrainedNetworkAccess = try container.decode(Bool.self, forKey: .allowsConstrainedNetworkAccess)
        waitsForConnectivity = try container.decode(Bool.self, forKey: .waitsForConnectivity)
        isDiscretionary = try container.decode(Bool.self, forKey: .isDiscretionary)
        shouldUseExtendedBackgroundIdleMode = try container.decode(Bool.self, forKey: .shouldUseExtendedBackgroundIdleMode)
        protocolClasses = try container.decode([String].self, forKey: .protocolClasses)
        tlsMinimumSupportedProtocolVersion = try container.decode(TLSProtocolVersion.self, forKey: .tlsMinimumSupportedProtocolVersion)
        tlsMaximumSupportedProtocolVersion = try container.decode(TLSProtocolVersion.self, forKey: .tlsMaximumSupportedProtocolVersion)
        urlCredentialStorage = try container.decode(URLCredentialStoragePolicy.self, forKey: .urlCredentialStorage)
        urlCache = try container.decodeIfPresent(URLCachePolicy.self, forKey: .urlCache)
        httpAdditionalHeaders = try container.decode([String: String].self, forKey: .httpAdditionalHeaders)
        httpMaximumConnectionLifetime = try container.decode(TimeInterval.self, forKey: .httpMaximumConnectionLifetime)
        enableMultipathServiceType = try container.decode(MultipathServiceType.self, forKey: .enableMultipathServiceType)
        enableLogging = try container.decode(Bool.self, forKey: .enableLogging)
        enableMetrics = try container.decode(Bool.self, forKey: .enableMetrics)
        sessionIdentifier = try container.decodeIfPresent(String.self, forKey: .sessionIdentifier)
        
        // connectionProxyDictionary is complex and not easily serializable, so we'll set it to nil
        connectionProxyDictionary = nil
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionType, forKey: .sessionType)
        try container.encode(timeoutIntervalForRequest, forKey: .timeoutIntervalForRequest)
        try container.encode(timeoutIntervalForResource, forKey: .timeoutIntervalForResource)
        try container.encode(httpMaximumConnectionsPerHost, forKey: .httpMaximumConnectionsPerHost)
        try container.encode(httpShouldUsePipelining, forKey: .httpShouldUsePipelining)
        try container.encode(httpShouldSetCookies, forKey: .httpShouldSetCookies)
        try container.encode(httpCookieAcceptPolicy.rawValue, forKey: .httpCookieAcceptPolicyRawValue)
        try container.encode(requestCachePolicy.rawValue, forKey: .requestCachePolicyRawValue)
        try container.encode(allowsCellularAccess, forKey: .allowsCellularAccess)
        try container.encode(allowsExpensiveNetworkAccess, forKey: .allowsExpensiveNetworkAccess)
        try container.encode(allowsConstrainedNetworkAccess, forKey: .allowsConstrainedNetworkAccess)
        try container.encode(waitsForConnectivity, forKey: .waitsForConnectivity)
        try container.encode(isDiscretionary, forKey: .isDiscretionary)
        try container.encode(shouldUseExtendedBackgroundIdleMode, forKey: .shouldUseExtendedBackgroundIdleMode)
        try container.encode(protocolClasses, forKey: .protocolClasses)
        try container.encode(tlsMinimumSupportedProtocolVersion, forKey: .tlsMinimumSupportedProtocolVersion)
        try container.encode(tlsMaximumSupportedProtocolVersion, forKey: .tlsMaximumSupportedProtocolVersion)
        try container.encode(urlCredentialStorage, forKey: .urlCredentialStorage)
        try container.encodeIfPresent(urlCache, forKey: .urlCache)
        try container.encode(httpAdditionalHeaders, forKey: .httpAdditionalHeaders)
        try container.encode(httpMaximumConnectionLifetime, forKey: .httpMaximumConnectionLifetime)
        try container.encode(enableMultipathServiceType, forKey: .enableMultipathServiceType)
        try container.encode(enableLogging, forKey: .enableLogging)
        try container.encode(enableMetrics, forKey: .enableMetrics)
        try container.encodeIfPresent(sessionIdentifier, forKey: .sessionIdentifier)
    }
    
    public init(
        sessionType: SessionType = .default,
        timeoutIntervalForRequest: TimeInterval = 60.0,
        timeoutIntervalForResource: TimeInterval = 604800.0, // 7 days
        httpMaximumConnectionsPerHost: Int = 6,
        httpShouldUsePipelining: Bool = false,
        httpShouldSetCookies: Bool = true,
        httpCookieAcceptPolicy: HTTPCookieAcceptPolicy = .onlyFromMainDocumentDomain,
        requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        allowsCellularAccess: Bool = true,
        allowsExpensiveNetworkAccess: Bool = true,
        allowsConstrainedNetworkAccess: Bool = true,
        waitsForConnectivity: Bool = false,
        isDiscretionary: Bool = false,
        shouldUseExtendedBackgroundIdleMode: Bool = false,
        protocolClasses: [String] = [],
        connectionProxyDictionary: [String: Any]? = nil,
        tlsMinimumSupportedProtocolVersion: TLSProtocolVersion = .tlsProtocol12,
        tlsMaximumSupportedProtocolVersion: TLSProtocolVersion = .tlsProtocol13,
        urlCredentialStorage: URLCredentialStoragePolicy = .default,
        urlCache: URLCachePolicy? = .default,
        httpAdditionalHeaders: [String: String] = [:],
        httpMaximumConnectionLifetime: TimeInterval = 0,
        enableMultipathServiceType: MultipathServiceType = .none,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        sessionIdentifier: String? = nil
    ) {
        self.sessionType = sessionType
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.timeoutIntervalForResource = timeoutIntervalForResource
        self.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        self.httpShouldUsePipelining = httpShouldUsePipelining
        self.httpShouldSetCookies = httpShouldSetCookies
        self.httpCookieAcceptPolicy = httpCookieAcceptPolicy
        self.requestCachePolicy = requestCachePolicy
        self.allowsCellularAccess = allowsCellularAccess
        self.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        self.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
        self.waitsForConnectivity = waitsForConnectivity
        self.isDiscretionary = isDiscretionary
        self.shouldUseExtendedBackgroundIdleMode = shouldUseExtendedBackgroundIdleMode
        self.protocolClasses = protocolClasses
        self.connectionProxyDictionary = connectionProxyDictionary
        self.tlsMinimumSupportedProtocolVersion = tlsMinimumSupportedProtocolVersion
        self.tlsMaximumSupportedProtocolVersion = tlsMaximumSupportedProtocolVersion
        self.urlCredentialStorage = urlCredentialStorage
        self.urlCache = urlCache
        self.httpAdditionalHeaders = httpAdditionalHeaders
        self.httpMaximumConnectionLifetime = httpMaximumConnectionLifetime
        self.enableMultipathServiceType = enableMultipathServiceType
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.sessionIdentifier = sessionIdentifier
    }
    
    public var isValid: Bool {
        timeoutIntervalForRequest > 0 &&
        timeoutIntervalForResource > 0 &&
        httpMaximumConnectionsPerHost > 0 &&
        httpMaximumConnectionLifetime >= 0
    }
    
    public func merged(with other: URLSessionCapabilityConfiguration) -> URLSessionCapabilityConfiguration {
        URLSessionCapabilityConfiguration(
            sessionType: other.sessionType,
            timeoutIntervalForRequest: other.timeoutIntervalForRequest,
            timeoutIntervalForResource: other.timeoutIntervalForResource,
            httpMaximumConnectionsPerHost: other.httpMaximumConnectionsPerHost,
            httpShouldUsePipelining: other.httpShouldUsePipelining,
            httpShouldSetCookies: other.httpShouldSetCookies,
            httpCookieAcceptPolicy: other.httpCookieAcceptPolicy,
            requestCachePolicy: other.requestCachePolicy,
            allowsCellularAccess: other.allowsCellularAccess,
            allowsExpensiveNetworkAccess: other.allowsExpensiveNetworkAccess,
            allowsConstrainedNetworkAccess: other.allowsConstrainedNetworkAccess,
            waitsForConnectivity: other.waitsForConnectivity,
            isDiscretionary: other.isDiscretionary,
            shouldUseExtendedBackgroundIdleMode: other.shouldUseExtendedBackgroundIdleMode,
            protocolClasses: other.protocolClasses.isEmpty ? protocolClasses : other.protocolClasses,
            connectionProxyDictionary: other.connectionProxyDictionary ?? connectionProxyDictionary,
            tlsMinimumSupportedProtocolVersion: other.tlsMinimumSupportedProtocolVersion,
            tlsMaximumSupportedProtocolVersion: other.tlsMaximumSupportedProtocolVersion,
            urlCredentialStorage: other.urlCredentialStorage,
            urlCache: other.urlCache ?? urlCache,
            httpAdditionalHeaders: httpAdditionalHeaders.merging(other.httpAdditionalHeaders) { _, new in new },
            httpMaximumConnectionLifetime: other.httpMaximumConnectionLifetime,
            enableMultipathServiceType: other.enableMultipathServiceType,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            sessionIdentifier: other.sessionIdentifier ?? sessionIdentifier
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> URLSessionCapabilityConfiguration {
        var adjustedTimeoutRequest = timeoutIntervalForRequest
        var adjustedTimeoutResource = timeoutIntervalForResource
        var adjustedLogging = enableLogging
        var adjustedCellular = allowsCellularAccess
        var adjustedExpensive = allowsExpensiveNetworkAccess
        var adjustedConstrained = allowsConstrainedNetworkAccess
        var adjustedWaitsForConnectivity = waitsForConnectivity
        
        if environment.isLowPowerMode {
            adjustedTimeoutRequest *= 2.0
            adjustedTimeoutResource *= 1.5
            adjustedCellular = false
            adjustedExpensive = false
            adjustedConstrained = false
            adjustedWaitsForConnectivity = true
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return URLSessionCapabilityConfiguration(
            sessionType: sessionType,
            timeoutIntervalForRequest: adjustedTimeoutRequest,
            timeoutIntervalForResource: adjustedTimeoutResource,
            httpMaximumConnectionsPerHost: httpMaximumConnectionsPerHost,
            httpShouldUsePipelining: httpShouldUsePipelining,
            httpShouldSetCookies: httpShouldSetCookies,
            httpCookieAcceptPolicy: httpCookieAcceptPolicy,
            requestCachePolicy: requestCachePolicy,
            allowsCellularAccess: adjustedCellular,
            allowsExpensiveNetworkAccess: adjustedExpensive,
            allowsConstrainedNetworkAccess: adjustedConstrained,
            waitsForConnectivity: adjustedWaitsForConnectivity,
            isDiscretionary: isDiscretionary,
            shouldUseExtendedBackgroundIdleMode: shouldUseExtendedBackgroundIdleMode,
            protocolClasses: protocolClasses,
            connectionProxyDictionary: connectionProxyDictionary,
            tlsMinimumSupportedProtocolVersion: tlsMinimumSupportedProtocolVersion,
            tlsMaximumSupportedProtocolVersion: tlsMaximumSupportedProtocolVersion,
            urlCredentialStorage: urlCredentialStorage,
            urlCache: urlCache,
            httpAdditionalHeaders: httpAdditionalHeaders,
            httpMaximumConnectionLifetime: httpMaximumConnectionLifetime,
            enableMultipathServiceType: enableMultipathServiceType,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            sessionIdentifier: sessionIdentifier
        )
    }
}

// MARK: - URLSession Types

/// URLSession task information
public struct URLSessionTaskInfo: Sendable {
    public let taskIdentifier: Int
    public let originalRequest: URLRequest?
    public let currentRequest: URLRequest?
    public let response: URLResponse?
    public let state: URLSessionTask.State
    public let error: Error?
    public let countOfBytesExpectedToSend: Int64
    public let countOfBytesSent: Int64
    public let countOfBytesExpectedToReceive: Int64
    public let countOfBytesReceived: Int64
    public let taskDescription: String?
    public let priority: URLSessionTask.Priority
    
    public init(
        taskIdentifier: Int,
        originalRequest: URLRequest?,
        currentRequest: URLRequest?,
        response: URLResponse?,
        state: URLSessionTask.State,
        error: Error?,
        countOfBytesExpectedToSend: Int64,
        countOfBytesSent: Int64,
        countOfBytesExpectedToReceive: Int64,
        countOfBytesReceived: Int64,
        taskDescription: String?,
        priority: URLSessionTask.Priority
    ) {
        self.taskIdentifier = taskIdentifier
        self.originalRequest = originalRequest
        self.currentRequest = currentRequest
        self.response = response
        self.state = state
        self.error = error
        self.countOfBytesExpectedToSend = countOfBytesExpectedToSend
        self.countOfBytesSent = countOfBytesSent
        self.countOfBytesExpectedToReceive = countOfBytesExpectedToReceive
        self.countOfBytesReceived = countOfBytesReceived
        self.taskDescription = taskDescription
        self.priority = priority
    }
}

/// URLSession metrics
public struct URLSessionMetrics: Sendable {
    public let sessionIdentifier: String?
    public let totalTasks: Int
    public let activeTasks: Int
    public let completedTasks: Int
    public let failedTasks: Int
    public let totalBytesReceived: Int64
    public let totalBytesSent: Int64
    public let averageTaskDuration: TimeInterval
    public let sessionUptime: TimeInterval
    public let connectionPoolSize: Int
    
    public init(
        sessionIdentifier: String? = nil,
        totalTasks: Int = 0,
        activeTasks: Int = 0,
        completedTasks: Int = 0,
        failedTasks: Int = 0,
        totalBytesReceived: Int64 = 0,
        totalBytesSent: Int64 = 0,
        averageTaskDuration: TimeInterval = 0,
        sessionUptime: TimeInterval = 0,
        connectionPoolSize: Int = 0
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.totalTasks = totalTasks
        self.activeTasks = activeTasks
        self.completedTasks = completedTasks
        self.failedTasks = failedTasks
        self.totalBytesReceived = totalBytesReceived
        self.totalBytesSent = totalBytesSent
        self.averageTaskDuration = averageTaskDuration
        self.sessionUptime = sessionUptime
        self.connectionPoolSize = connectionPoolSize
    }
}

/// URLSession download progress
public struct URLSessionDownloadProgress: Sendable {
    public let taskIdentifier: Int
    public let totalBytesWritten: Int64
    public let totalBytesExpectedToWrite: Int64
    public let bytesWritten: Int64
    public let progress: Double
    public let estimatedTimeRemaining: TimeInterval?
    
    public init(
        taskIdentifier: Int,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
        bytesWritten: Int64,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.taskIdentifier = taskIdentifier
        self.totalBytesWritten = totalBytesWritten
        self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
        self.bytesWritten = bytesWritten
        self.progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

/// URLSession upload progress
public struct URLSessionUploadProgress: Sendable {
    public let taskIdentifier: Int
    public let bytesSent: Int64
    public let totalBytesExpectedToSend: Int64
    public let totalBytesSent: Int64
    public let progress: Double
    public let estimatedTimeRemaining: TimeInterval?
    
    public init(
        taskIdentifier: Int,
        bytesSent: Int64,
        totalBytesExpectedToSend: Int64,
        totalBytesSent: Int64,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.taskIdentifier = taskIdentifier
        self.bytesSent = bytesSent
        self.totalBytesExpectedToSend = totalBytesExpectedToSend
        self.totalBytesSent = totalBytesSent
        self.progress = totalBytesExpectedToSend > 0 ? Double(totalBytesSent) / Double(totalBytesExpectedToSend) : 0.0
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

// MARK: - URLSession Resource

/// URLSession resource management
public actor URLSessionCapabilityResource: AxiomCapabilityResource {
    private let configuration: URLSessionCapabilityConfiguration
    private var urlSession: URLSession?
    private var sessionConfiguration: URLSessionConfiguration?
    private var activeTasks: Set<Int> = []
    private var taskMetrics: [Int: URLSessionTaskInfo] = [:]
    private var sessionStartTime: Date?
    private var sessionMetrics: URLSessionMetrics
    private var downloadProgressStreamContinuation: AsyncStream<URLSessionDownloadProgress>.Continuation?
    private var uploadProgressStreamContinuation: AsyncStream<URLSessionUploadProgress>.Continuation?
    
    public init(configuration: URLSessionCapabilityConfiguration) {
        self.configuration = configuration
        self.sessionMetrics = URLSessionMetrics()
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.httpMaximumConnectionsPerHost * 5_000_000, // 5MB per connection
            cpu: Double(configuration.httpMaximumConnectionsPerHost * 2), // 2% CPU per connection
            bandwidth: configuration.httpMaximumConnectionsPerHost * 1_000_000, // 1MB/s per connection
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let activeTaskCount = activeTasks.count
            return ResourceUsage(
                memory: activeTaskCount * 2_000_000, // 2MB per active task
                cpu: Double(activeTaskCount * 1), // 1% CPU per active task
                bandwidth: activeTaskCount * 500_000, // 500KB/s per active task
                storage: 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        urlSession != nil
    }
    
    public func release() async {
        urlSession?.invalidateAndCancel()
        urlSession = nil
        sessionConfiguration = nil
        activeTasks.removeAll()
        taskMetrics.removeAll()
        downloadProgressStreamContinuation?.finish()
        uploadProgressStreamContinuation?.finish()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        sessionStartTime = Date()
        sessionConfiguration = try createSessionConfiguration()
        
        guard let config = sessionConfiguration else {
            throw AxiomCapabilityError.initializationFailed("Failed to create session configuration")
        }
        
        switch configuration.sessionType {
        case .default:
            urlSession = URLSession(configuration: config, delegate: SessionDelegate(resource: self), delegateQueue: nil)
        case .ephemeral:
            urlSession = URLSession(configuration: config, delegate: SessionDelegate(resource: self), delegateQueue: nil)
        case .background:
            guard let identifier = configuration.sessionIdentifier else {
                throw AxiomCapabilityError.initializationFailed("Background session requires identifier")
            }
            let backgroundConfig = URLSessionConfiguration.background(withIdentifier: identifier)
            urlSession = URLSession(configuration: backgroundConfig, delegate: SessionDelegate(resource: self), delegateQueue: nil)
        }
    }
    
    internal func updateConfiguration(_ configuration: URLSessionCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - URLSession Access
    
    public func getSession() -> URLSession? {
        urlSession
    }
    
    public func getSessionConfiguration() -> URLSessionConfiguration? {
        sessionConfiguration
    }
    
    public func getActiveTasks() -> Set<Int> {
        activeTasks
    }
    
    public func getTaskInfo(_ taskIdentifier: Int) -> URLSessionTaskInfo? {
        taskMetrics[taskIdentifier]
    }
    
    public func getAllTasksInfo() -> [URLSessionTaskInfo] {
        Array(taskMetrics.values)
    }
    
    public func getSessionMetrics() -> URLSessionMetrics {
        let uptime = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let averageDuration = taskMetrics.values.isEmpty ? 0 : taskMetrics.values.map { _ in 1.0 }.reduce(0, +) / Double(taskMetrics.count)
        
        return URLSessionMetrics(
            sessionIdentifier: configuration.sessionIdentifier,
            totalTasks: taskMetrics.count,
            activeTasks: activeTasks.count,
            completedTasks: taskMetrics.values.filter { $0.state == .completed }.count,
            failedTasks: taskMetrics.values.filter { $0.error != nil }.count,
            totalBytesReceived: taskMetrics.values.map { $0.countOfBytesReceived }.reduce(0, +),
            totalBytesSent: taskMetrics.values.map { $0.countOfBytesSent }.reduce(0, +),
            averageTaskDuration: averageDuration,
            sessionUptime: uptime,
            connectionPoolSize: configuration.httpMaximumConnectionsPerHost
        )
    }
    
    public var downloadProgressStream: AsyncStream<URLSessionDownloadProgress> {
        AsyncStream { continuation in
            self.downloadProgressStreamContinuation = continuation
        }
    }
    
    public var uploadProgressStream: AsyncStream<URLSessionUploadProgress> {
        AsyncStream { continuation in
            self.uploadProgressStreamContinuation = continuation
        }
    }
    
    // MARK: - Task Management
    
    internal func addTask(_ task: URLSessionTask) {
        activeTasks.insert(task.taskIdentifier)
        taskMetrics[task.taskIdentifier] = URLSessionTaskInfo(
            taskIdentifier: task.taskIdentifier,
            originalRequest: task.originalRequest,
            currentRequest: task.currentRequest,
            response: task.response,
            state: task.state,
            error: task.error,
            countOfBytesExpectedToSend: task.countOfBytesExpectedToSend,
            countOfBytesSent: task.countOfBytesSent,
            countOfBytesExpectedToReceive: task.countOfBytesExpectedToReceive,
            countOfBytesReceived: task.countOfBytesReceived,
            taskDescription: task.taskDescription,
            priority: task.priority
        )
    }
    
    internal func updateTask(_ task: URLSessionTask) {
        taskMetrics[task.taskIdentifier] = URLSessionTaskInfo(
            taskIdentifier: task.taskIdentifier,
            originalRequest: task.originalRequest,
            currentRequest: task.currentRequest,
            response: task.response,
            state: task.state,
            error: task.error,
            countOfBytesExpectedToSend: task.countOfBytesExpectedToSend,
            countOfBytesSent: task.countOfBytesSent,
            countOfBytesExpectedToReceive: task.countOfBytesExpectedToReceive,
            countOfBytesReceived: task.countOfBytesReceived,
            taskDescription: task.taskDescription,
            priority: task.priority
        )
    }
    
    internal func removeTask(_ taskIdentifier: Int) {
        activeTasks.remove(taskIdentifier)
    }
    
    internal func notifyDownloadProgress(_ progress: URLSessionDownloadProgress) {
        downloadProgressStreamContinuation?.yield(progress)
    }
    
    internal func notifyUploadProgress(_ progress: URLSessionUploadProgress) {
        uploadProgressStreamContinuation?.yield(progress)
    }
    
    // MARK: - Private Methods
    
    private func createSessionConfiguration() throws -> URLSessionConfiguration {
        let config: URLSessionConfiguration
        
        switch configuration.sessionType {
        case .default:
            config = URLSessionConfiguration.default
        case .ephemeral:
            config = URLSessionConfiguration.ephemeral
        case .background:
            guard let identifier = configuration.sessionIdentifier else {
                throw AxiomCapabilityError.initializationFailed("Background session requires identifier")
            }
            config = URLSessionConfiguration.background(withIdentifier: identifier)
        }
        
        // Apply configuration settings
        config.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
        config.timeoutIntervalForResource = configuration.timeoutIntervalForResource
        config.httpMaximumConnectionsPerHost = configuration.httpMaximumConnectionsPerHost
        config.httpShouldUsePipelining = configuration.httpShouldUsePipelining
        config.httpShouldSetCookies = configuration.httpShouldSetCookies
        config.httpCookieAcceptPolicy = configuration.httpCookieAcceptPolicy
        config.requestCachePolicy = configuration.requestCachePolicy
        config.allowsCellularAccess = configuration.allowsCellularAccess
        config.allowsExpensiveNetworkAccess = configuration.allowsExpensiveNetworkAccess
        config.allowsConstrainedNetworkAccess = configuration.allowsConstrainedNetworkAccess
        config.waitsForConnectivity = configuration.waitsForConnectivity
        config.isDiscretionary = configuration.isDiscretionary
        config.shouldUseExtendedBackgroundIdleMode = configuration.shouldUseExtendedBackgroundIdleMode
        
        // Set additional headers
        if !configuration.httpAdditionalHeaders.isEmpty {
            config.httpAdditionalHeaders = configuration.httpAdditionalHeaders
        }
        
        // Set connection lifetime
        if configuration.httpMaximumConnectionLifetime > 0 {
            config.httpMaximumConnectionLifetime = configuration.httpMaximumConnectionLifetime
        }
        
        // Set multipath service type
        switch configuration.enableMultipathServiceType {
        case .none:
            config.multipathServiceType = .none
        case .handover:
            config.multipathServiceType = .handover
        case .interactive:
            config.multipathServiceType = .interactive
        case .aggregate:
            config.multipathServiceType = .aggregate
        }
        
        // Set proxy dictionary if provided
        if let proxyDictionary = configuration.connectionProxyDictionary {
            config.connectionProxyDictionary = proxyDictionary
        }
        
        // Configure URL cache
        switch configuration.urlCache {
        case .disabled:
            config.urlCache = nil
        case .default, .custom, .none:
            break // Use default or keep existing
        }
        
        // Configure credential storage
        switch configuration.urlCredentialStorage {
        case .disabled:
            config.urlCredentialStorage = nil
        case .default:
            break // Use default
        }
        
        return config
    }
}

// MARK: - Session Delegate

internal class SessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    private weak var resource: URLSessionCapabilityResource?
    
    init(resource: URLSessionCapabilityResource) {
        self.resource = resource
        super.init()
    }
    
    // MARK: - URLSessionDelegate
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        // Session became invalid
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Handle authentication challenges
        completionHandler(.performDefaultHandling, nil)
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { [weak resource] in
            await resource?.updateTask(task)
            await resource?.removeTask(task.taskIdentifier)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = URLSessionUploadProgress(
            taskIdentifier: task.taskIdentifier,
            bytesSent: bytesSent,
            totalBytesExpectedToSend: totalBytesExpectedToSend,
            totalBytesSent: totalBytesSent
        )
        
        Task { [weak resource] in
            await resource?.updateTask(task)
            await resource?.notifyUploadProgress(progress)
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = URLSessionDownloadProgress(
            taskIdentifier: downloadTask.taskIdentifier,
            totalBytesWritten: totalBytesWritten,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite,
            bytesWritten: bytesWritten
        )
        
        Task { [weak resource] in
            await resource?.updateTask(downloadTask)
            await resource?.notifyDownloadProgress(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task { [weak resource] in
            await resource?.updateTask(downloadTask)
        }
    }
}

// MARK: - URLSession Capability Implementation

/// URLSession capability providing advanced URL session management
public actor URLSessionCapability: DomainCapability {
    public typealias ConfigurationType = URLSessionCapabilityConfiguration
    public typealias ResourceType = URLSessionCapabilityResource
    
    private var _configuration: URLSessionCapabilityConfiguration
    private var _resources: URLSessionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "urlsession-capability" }
    
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
    
    public var configuration: URLSessionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: URLSessionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: URLSessionCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = URLSessionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: URLSessionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid URLSession configuration")
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
        // URLSession is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // URLSession doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - URLSession Operations
    
    /// Get the underlying URLSession
    public func getSession() async -> URLSession? {
        guard await isAvailable else { return nil }
        return await _resources.getSession()
    }
    
    /// Get session configuration
    public func getSessionConfiguration() async -> URLSessionConfiguration? {
        guard await isAvailable else { return nil }
        return await _resources.getSessionConfiguration()
    }
    
    /// Create a data task
    public func dataTask(with request: URLRequest) async throws -> URLSessionDataTask {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("URLSession capability not available")
        }
        
        guard let session = await _resources.getSession() else {
            throw AxiomCapabilityError.resourceAllocationFailed("URLSession not available")
        }
        
        let task = session.dataTask(with: request)
        await _resources.addTask(task)
        return task
    }
    
    /// Create a download task
    public func downloadTask(with request: URLRequest) async throws -> URLSessionDownloadTask {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("URLSession capability not available")
        }
        
        guard let session = await _resources.getSession() else {
            throw AxiomCapabilityError.resourceAllocationFailed("URLSession not available")
        }
        
        let task = session.downloadTask(with: request)
        await _resources.addTask(task)
        return task
    }
    
    /// Create an upload task
    public func uploadTask(with request: URLRequest, from bodyData: Data) async throws -> URLSessionUploadTask {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("URLSession capability not available")
        }
        
        guard let session = await _resources.getSession() else {
            throw AxiomCapabilityError.resourceAllocationFailed("URLSession not available")
        }
        
        let task = session.uploadTask(with: request, from: bodyData)
        await _resources.addTask(task)
        return task
    }
    
    /// Create an upload task from file
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL) async throws -> URLSessionUploadTask {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("URLSession capability not available")
        }
        
        guard let session = await _resources.getSession() else {
            throw AxiomCapabilityError.resourceAllocationFailed("URLSession not available")
        }
        
        let task = session.uploadTask(with: request, fromFile: fileURL)
        await _resources.addTask(task)
        return task
    }
    
    /// Get active tasks
    public func getActiveTasks() async -> Set<Int> {
        await _resources.getActiveTasks()
    }
    
    /// Get task information
    public func getTaskInfo(_ taskIdentifier: Int) async -> URLSessionTaskInfo? {
        await _resources.getTaskInfo(taskIdentifier)
    }
    
    /// Get all task information
    public func getAllTasksInfo() async -> [URLSessionTaskInfo] {
        await _resources.getAllTasksInfo()
    }
    
    /// Get session metrics
    public func getSessionMetrics() async -> URLSessionMetrics {
        await _resources.getSessionMetrics()
    }
    
    /// Get download progress stream
    public func getDownloadProgressStream() async -> AsyncStream<URLSessionDownloadProgress> {
        await _resources.downloadProgressStream
    }
    
    /// Get upload progress stream
    public func getUploadProgressStream() async -> AsyncStream<URLSessionUploadProgress> {
        await _resources.uploadProgressStream
    }
    
    /// Execute a simple data request with async/await
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let session = await getSession() else {
            throw AxiomCapabilityError.unavailable("URLSession not available")
        }
        
        let task = try await dataTask(with: request)
        defer {
            Task {
                await _resources.removeTask(task.taskIdentifier)
            }
        }
        
        return try await session.data(for: request)
    }
    
    /// Download a file with async/await
    public func download(for request: URLRequest) async throws -> (URL, URLResponse) {
        guard let session = await getSession() else {
            throw AxiomCapabilityError.unavailable("URLSession not available")
        }
        
        let task = try await downloadTask(with: request)
        defer {
            Task {
                await _resources.removeTask(task.taskIdentifier)
            }
        }
        
        return try await session.download(for: request)
    }
    
    /// Upload data with async/await
    public func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse) {
        guard let session = await getSession() else {
            throw AxiomCapabilityError.unavailable("URLSession not available")
        }
        
        let task = try await uploadTask(with: request, from: bodyData)
        defer {
            Task {
                await _resources.removeTask(task.taskIdentifier)
            }
        }
        
        return try await session.upload(for: request, from: bodyData)
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// URLSession specific errors
public enum URLSessionError: Error, LocalizedError {
    case sessionNotAvailable
    case invalidConfiguration(String)
    case taskCreationFailed(String)
    case backgroundSessionNotSupported
    case invalidIdentifier(String)
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotAvailable:
            return "URLSession is not available"
        case .invalidConfiguration(let message):
            return "Invalid URLSession configuration: \(message)"
        case .taskCreationFailed(let message):
            return "Failed to create URLSession task: \(message)"
        case .backgroundSessionNotSupported:
            return "Background URLSession not supported on this platform"
        case .invalidIdentifier(let identifier):
            return "Invalid session identifier: \(identifier)"
        }
    }
}