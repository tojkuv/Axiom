import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - HTTP Client Capability Configuration

/// Configuration for HTTP Client capability
public struct HTTPClientCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let baseURL: URL?
    public let timeout: TimeInterval
    public let retryCount: Int
    public let retryDelay: TimeInterval
    public let retryMultiplier: Double
    public let enableAutomaticRetries: Bool
    public let allowedStatusCodes: Set<Int>
    public let userAgent: String
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let maxConcurrentRequests: Int
    public let enableCaching: Bool
    public let cachePolicy: URLRequest.CachePolicy
    
    // Custom Codable implementation to handle complex types
    private enum CodingKeys: String, CodingKey {
        case baseURL, timeout, retryCount, retryDelay, retryMultiplier
        case enableAutomaticRetries, allowedStatusCodes, userAgent
        case enableLogging, enableMetrics, maxConcurrentRequests
        case enableCaching, cachePolicyRawValue
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = try container.decodeIfPresent(URL.self, forKey: .baseURL)
        timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        retryDelay = try container.decode(TimeInterval.self, forKey: .retryDelay)
        retryMultiplier = try container.decode(Double.self, forKey: .retryMultiplier)
        enableAutomaticRetries = try container.decode(Bool.self, forKey: .enableAutomaticRetries)
        allowedStatusCodes = Set(try container.decode([Int].self, forKey: .allowedStatusCodes))
        userAgent = try container.decode(String.self, forKey: .userAgent)
        enableLogging = try container.decode(Bool.self, forKey: .enableLogging)
        enableMetrics = try container.decode(Bool.self, forKey: .enableMetrics)
        maxConcurrentRequests = try container.decode(Int.self, forKey: .maxConcurrentRequests)
        enableCaching = try container.decode(Bool.self, forKey: .enableCaching)
        
        let cachePolicyRawValue = try container.decode(UInt.self, forKey: .cachePolicyRawValue)
        cachePolicy = URLRequest.CachePolicy(rawValue: cachePolicyRawValue) ?? .useProtocolCachePolicy
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(baseURL, forKey: .baseURL)
        try container.encode(timeout, forKey: .timeout)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(retryDelay, forKey: .retryDelay)
        try container.encode(retryMultiplier, forKey: .retryMultiplier)
        try container.encode(enableAutomaticRetries, forKey: .enableAutomaticRetries)
        try container.encode(Array(allowedStatusCodes), forKey: .allowedStatusCodes)
        try container.encode(userAgent, forKey: .userAgent)
        try container.encode(enableLogging, forKey: .enableLogging)
        try container.encode(enableMetrics, forKey: .enableMetrics)
        try container.encode(maxConcurrentRequests, forKey: .maxConcurrentRequests)
        try container.encode(enableCaching, forKey: .enableCaching)
        try container.encode(cachePolicy.rawValue, forKey: .cachePolicyRawValue)
    }
    
    public init(
        baseURL: URL? = nil,
        timeout: TimeInterval = 30.0,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0,
        retryMultiplier: Double = 2.0,
        enableAutomaticRetries: Bool = true,
        allowedStatusCodes: Set<Int> = Set(200...299),
        userAgent: String = "AxiomHTTPClient/1.0",
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        maxConcurrentRequests: Int = 10,
        enableCaching: Bool = true,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        self.retryMultiplier = retryMultiplier
        self.enableAutomaticRetries = enableAutomaticRetries
        self.allowedStatusCodes = allowedStatusCodes
        self.userAgent = userAgent
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.maxConcurrentRequests = maxConcurrentRequests
        self.enableCaching = enableCaching
        self.cachePolicy = cachePolicy
    }
    
    public var isValid: Bool {
        timeout > 0 && retryCount >= 0 && retryDelay >= 0 && retryMultiplier > 0 && maxConcurrentRequests > 0
    }
    
    public func merged(with other: HTTPClientCapabilityConfiguration) -> HTTPClientCapabilityConfiguration {
        HTTPClientCapabilityConfiguration(
            baseURL: other.baseURL ?? baseURL,
            timeout: other.timeout,
            retryCount: other.retryCount,
            retryDelay: other.retryDelay,
            retryMultiplier: other.retryMultiplier,
            enableAutomaticRetries: other.enableAutomaticRetries,
            allowedStatusCodes: other.allowedStatusCodes,
            userAgent: other.userAgent,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            maxConcurrentRequests: other.maxConcurrentRequests,
            enableCaching: other.enableCaching,
            cachePolicy: other.cachePolicy
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> HTTPClientCapabilityConfiguration {
        var adjustedTimeout = timeout
        var adjustedRetries = enableAutomaticRetries
        var adjustedLogging = enableLogging
        var adjustedConcurrent = maxConcurrentRequests
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 1.5
            adjustedRetries = false
            adjustedConcurrent = min(maxConcurrentRequests, 3)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return HTTPClientCapabilityConfiguration(
            baseURL: baseURL,
            timeout: adjustedTimeout,
            retryCount: retryCount,
            retryDelay: retryDelay,
            retryMultiplier: retryMultiplier,
            enableAutomaticRetries: adjustedRetries,
            allowedStatusCodes: allowedStatusCodes,
            userAgent: userAgent,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            maxConcurrentRequests: adjustedConcurrent,
            enableCaching: enableCaching,
            cachePolicy: cachePolicy
        )
    }
}

// MARK: - HTTP Request Types

/// HTTP request method
public enum HTTPMethod: String, Codable, CaseIterable, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

/// HTTP request definition
public struct HTTPRequest: Sendable {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    public let timeout: TimeInterval?
    public let retryPolicy: RetryPolicy?
    
    public init(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil,
        retryPolicy: RetryPolicy? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
        self.retryPolicy = retryPolicy
    }
}

/// HTTP response information
public struct HTTPResponse: Sendable {
    public let data: Data
    public let response: HTTPURLResponse
    public let request: HTTPRequest
    public let duration: TimeInterval
    public let retryCount: Int
    public let fromCache: Bool
    
    public init(
        data: Data,
        response: HTTPURLResponse,
        request: HTTPRequest,
        duration: TimeInterval,
        retryCount: Int = 0,
        fromCache: Bool = false
    ) {
        self.data = data
        self.response = response
        self.request = request
        self.duration = duration
        self.retryCount = retryCount
        self.fromCache = fromCache
    }
    
    public var statusCode: Int {
        response.statusCode
    }
    
    public var headers: [String: String] {
        response.allHeaderFields.reduce(into: [:]) { result, element in
            if let key = element.key as? String, let value = element.value as? String {
                result[key] = value
            }
        }
    }
    
    public var isSuccess: Bool {
        200...299 ~= statusCode
    }
}

/// Retry policy configuration
public struct RetryPolicy: Sendable {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let multiplier: Double
    public let maxDelay: TimeInterval
    public let retryableStatusCodes: Set<Int>
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        multiplier: Double = 2.0,
        maxDelay: TimeInterval = 30.0,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.multiplier = multiplier
        self.maxDelay = maxDelay
        self.retryableStatusCodes = retryableStatusCodes
    }
    
    public static let aggressive = RetryPolicy(maxRetries: 5, baseDelay: 0.5, multiplier: 1.5, maxDelay: 10.0)
    public static let conservative = RetryPolicy(maxRetries: 1, baseDelay: 2.0, multiplier: 1.0, maxDelay: 5.0)
    public static let none = RetryPolicy(maxRetries: 0, baseDelay: 0, multiplier: 1.0, maxDelay: 0)
}

// MARK: - HTTP Client Resource

/// HTTP Client resource management
public actor HTTPClientCapabilityResource: AxiomCapabilityResource {
    private let configuration: HTTPClientCapabilityConfiguration
    private var urlSession: URLSession?
    private var activeRequests: Set<UUID> = []
    private var requestMetrics: [UUID: HTTPRequestMetrics] = [:]
    
    public init(configuration: HTTPClientCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxConcurrentRequests * 1_000_000, // 1MB per request
            cpu: Double(configuration.maxConcurrentRequests * 2), // 2% CPU per request
            bandwidth: configuration.maxConcurrentRequests * 100_000, // 100KB/s per request
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let requestCount = activeRequests.count
            
            return ResourceUsage(
                memory: requestCount * 1_000_000,
                cpu: Double(requestCount * 2),
                bandwidth: requestCount * 100_000,
                storage: 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        urlSession != nil && activeRequests.count < configuration.maxConcurrentRequests
    }
    
    public func release() async {
        urlSession?.invalidateAndCancel()
        urlSession = nil
        activeRequests.removeAll()
        requestMetrics.removeAll()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.httpMaximumConnectionsPerHost = configuration.maxConcurrentRequests
        sessionConfig.requestCachePolicy = configuration.cachePolicy
        
        if !configuration.enableCaching {
            sessionConfig.urlCache = nil
        }
        
        urlSession = URLSession(configuration: sessionConfig)
    }
    
    internal func updateConfiguration(_ configuration: HTTPClientCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - HTTP Client Access
    
    public func getSession() -> URLSession? {
        urlSession
    }
    
    public func addActiveRequest(_ requestId: UUID) {
        activeRequests.insert(requestId)
        requestMetrics[requestId] = HTTPRequestMetrics(id: requestId, startTime: Date())
    }
    
    public func removeActiveRequest(_ requestId: UUID) {
        activeRequests.remove(requestId)
        if let metrics = requestMetrics[requestId] {
            requestMetrics[requestId] = metrics.completed()
        }
    }
    
    public func getRequestMetrics(_ requestId: UUID) -> HTTPRequestMetrics? {
        requestMetrics[requestId]
    }
    
    public func getAllMetrics() -> [HTTPRequestMetrics] {
        Array(requestMetrics.values)
    }
}

/// HTTP request metrics
public struct HTTPRequestMetrics: Sendable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date?
    public let duration: TimeInterval
    public let retryCount: Int
    public let bytesReceived: Int64
    public let bytesSent: Int64
    
    public init(
        id: UUID,
        startTime: Date,
        endTime: Date? = nil,
        retryCount: Int = 0,
        bytesReceived: Int64 = 0,
        bytesSent: Int64 = 0
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.retryCount = retryCount
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.duration = endTime?.timeIntervalSince(startTime) ?? 0
    }
    
    public func completed(retryCount: Int = 0, bytesReceived: Int64 = 0, bytesSent: Int64 = 0) -> HTTPRequestMetrics {
        HTTPRequestMetrics(
            id: id,
            startTime: startTime,
            endTime: Date(),
            retryCount: retryCount,
            bytesReceived: bytesReceived,
            bytesSent: bytesSent
        )
    }
}

// MARK: - HTTP Client Capability Implementation

/// HTTP Client capability providing RESTful API client with automatic retries
public actor HTTPClientCapability: ExternalServiceCapability {
    public typealias ConfigurationType = HTTPClientCapabilityConfiguration
    public typealias ResourceType = HTTPClientCapabilityResource
    
    private var _configuration: HTTPClientCapabilityConfiguration
    private var _resources: HTTPClientCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "http-client-capability" }
    
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
    
    public var configuration: HTTPClientCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: HTTPClientCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: HTTPClientCapabilityConfiguration = HTTPClientCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = HTTPClientCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: HTTPClientCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid HTTP Client configuration")
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
        // HTTP client is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // HTTP client doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - HTTP Client Operations
    
    /// Execute HTTP request with automatic retries
    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("HTTP Client capability not available")
        }
        
        guard let session = await _resources.getSession() else {
            throw AxiomCapabilityError.resourceAllocationFailed("URL session not available")
        }
        
        let requestId = UUID()
        await _resources.addActiveRequest(requestId)
        defer { Task { await _resources.removeActiveRequest(requestId) } }
        
        // Build URLRequest
        let urlRequest = try buildURLRequest(from: request)
        
        // Execute with retry logic
        return try await executeWithRetries(urlRequest, originalRequest: request, session: session, requestId: requestId)
    }
    
    /// Convenience method for GET requests
    public func get(_ url: URL, headers: [String: String] = [:]) async throws -> HTTPResponse {
        let request = HTTPRequest(url: url, method: .GET, headers: headers)
        return try await execute(request)
    }
    
    /// Convenience method for POST requests with JSON body
    public func post<T: Codable>(_ url: URL, body: T, headers: [String: String] = [:]) async throws -> HTTPResponse {
        var requestHeaders = headers
        requestHeaders["Content-Type"] = "application/json"
        
        let bodyData = try JSONEncoder().encode(body)
        let request = HTTPRequest(url: url, method: .POST, headers: requestHeaders, body: bodyData)
        return try await execute(request)
    }
    
    /// Convenience method for PUT requests with JSON body
    public func put<T: Codable>(_ url: URL, body: T, headers: [String: String] = [:]) async throws -> HTTPResponse {
        var requestHeaders = headers
        requestHeaders["Content-Type"] = "application/json"
        
        let bodyData = try JSONEncoder().encode(body)
        let request = HTTPRequest(url: url, method: .PUT, headers: requestHeaders, body: bodyData)
        return try await execute(request)
    }
    
    /// Convenience method for DELETE requests
    public func delete(_ url: URL, headers: [String: String] = [:]) async throws -> HTTPResponse {
        let request = HTTPRequest(url: url, method: .DELETE, headers: headers)
        return try await execute(request)
    }
    
    /// Download file from URL
    public func download(_ url: URL, to destinationURL: URL) async throws -> HTTPResponse {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("HTTP Client capability not available")
        }
        
        guard let session = await _resources.getSession() else {
            throw AxiomCapabilityError.resourceAllocationFailed("URL session not available")
        }
        
        let requestId = UUID()
        await _resources.addActiveRequest(requestId)
        defer { Task { await _resources.removeActiveRequest(requestId) } }
        
        let startTime = Date()
        let (tempURL, response) = try await session.download(from: url)
        
        // Move downloaded file to destination
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        let data = try Data(contentsOf: destinationURL)
        let httpResponse = response as! HTTPURLResponse
        let duration = Date().timeIntervalSince(startTime)
        
        let request = HTTPRequest(url: url, method: .GET)
        return HTTPResponse(
            data: data,
            response: httpResponse,
            request: request,
            duration: duration
        )
    }
    
    /// Get request metrics
    public func getMetrics() async -> [HTTPRequestMetrics] {
        await _resources.getAllMetrics()
    }
    
    // MARK: - Private Implementation
    
    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        let url = resolveURL(request.url)
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? _configuration.timeout
        urlRequest.cachePolicy = _configuration.cachePolicy
        
        // Set headers
        var headers = request.headers
        headers["User-Agent"] = _configuration.userAgent
        
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        if let body = request.body {
            urlRequest.httpBody = body
        }
        
        return urlRequest
    }
    
    private func resolveURL(_ url: URL) -> URL {
        if let baseURL = _configuration.baseURL, url.scheme == nil {
            return baseURL.appendingPathComponent(url.path)
        }
        return url
    }
    
    private func executeWithRetries(
        _ urlRequest: URLRequest,
        originalRequest: HTTPRequest,
        session: URLSession,
        requestId: UUID
    ) async throws -> HTTPResponse {
        let retryPolicy = originalRequest.retryPolicy ?? RetryPolicy(
            maxRetries: _configuration.retryCount,
            baseDelay: _configuration.retryDelay,
            multiplier: _configuration.retryMultiplier
        )
        
        var lastError: Error?
        var retryCount = 0
        
        while retryCount <= retryPolicy.maxRetries {
            do {
                let startTime = Date()
                let (data, response) = try await session.data(for: urlRequest)
                let duration = Date().timeIntervalSince(startTime)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPClientError.invalidResponse
                }
                
                let httpResponseObj = HTTPResponse(
                    data: data,
                    response: httpResponse,
                    request: originalRequest,
                    duration: duration,
                    retryCount: retryCount
                )
                
                // Check if response is successful
                if _configuration.allowedStatusCodes.contains(httpResponse.statusCode) {
                    if _configuration.enableLogging {
                        await logResponse(httpResponseObj)
                    }
                    return httpResponseObj
                }
                
                // Check if status code is retryable
                if !retryPolicy.retryableStatusCodes.contains(httpResponse.statusCode) {
                    throw HTTPClientError.httpError(httpResponse.statusCode, data)
                }
                
                lastError = HTTPClientError.httpError(httpResponse.statusCode, data)
                
            } catch {
                lastError = error
                
                // Don't retry for certain errors
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .badURL, .unsupportedURL, .cannotParseResponse:
                        throw HTTPClientError.networkError(urlError)
                    default:
                        break
                    }
                }
            }
            
            // Break if we've exhausted retries
            if retryCount >= retryPolicy.maxRetries {
                break
            }
            
            // Calculate delay for next retry
            let delay = min(
                retryPolicy.baseDelay * pow(retryPolicy.multiplier, Double(retryCount)),
                retryPolicy.maxDelay
            )
            
            if _configuration.enableLogging {
                await logRetry(retryCount + 1, delay: delay, error: lastError)
            }
            
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            retryCount += 1
        }
        
        // All retries exhausted
        throw lastError ?? HTTPClientError.requestFailed("Request failed after \(retryPolicy.maxRetries) retries")
    }
    
    private func logResponse(_ response: HTTPResponse) async {
        print("[HTTPClient] ✅ \(response.request.method.rawValue) \(response.request.url) -> \(response.statusCode) (\(String(format: "%.3f", response.duration))s)")
    }
    
    private func logRetry(_ attempt: Int, delay: TimeInterval, error: Error?) async {
        print("[HTTPClient] 🔄 Retry attempt \(attempt) after \(String(format: "%.1f", delay))s - \(error?.localizedDescription ?? "Unknown error")")
    }
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// HTTP Client specific errors
public enum HTTPClientError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int, Data)
    case networkError(URLError)
    case requestFailed(String)
    case invalidURL(String)
    case encodingError(Error)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response received"
        case .httpError(let code, _):
            return "HTTP error: \(code)"
        case .networkError(let urlError):
            return "Network error: \(urlError.localizedDescription)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension HTTPResponse {
    /// Decode JSON response to Codable type
    public func decode<T: Codable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw HTTPClientError.decodingError(error)
        }
    }
    
    /// Get response as String
    public var string: String? {
        String(data: data, encoding: .utf8)
    }
}