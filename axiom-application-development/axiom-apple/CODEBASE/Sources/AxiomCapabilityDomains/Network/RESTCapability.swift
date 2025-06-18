import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - REST Capability Configuration

/// Configuration for REST capability
public struct RESTCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let baseURL: URL?
    public let defaultHeaders: [String: String]
    public let timeout: TimeInterval
    public let retryPolicy: RESTRetryPolicy
    public let contentType: ContentType
    public let acceptType: ContentType
    public let authenticationMethod: AuthenticationMethod
    public let enableCaching: Bool
    public let cachePolicy: CachePolicy
    public let enablePagination: Bool
    public let paginationStyle: PaginationStyle
    public let enableRateLimiting: Bool
    public let rateLimitHeaders: RateLimitHeaders
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let validateStatusCodes: Bool
    public let allowedStatusCodes: Set<Int>
    public let enableHATEOAS: Bool
    public let enableETag: Bool
    public let enableLastModified: Bool
    public let enableContentNegotiation: Bool
    public let maxRetries: Int
    public let retryDelay: TimeInterval
    
    public enum ContentType: String, Codable, CaseIterable, Sendable {
        case json = "application/json"
        case xml = "application/xml"
        case formData = "application/x-www-form-urlencoded"
        case multipartFormData = "multipart/form-data"
        case plainText = "text/plain"
        case html = "text/html"
        case custom = "custom"
    }
    
    public enum AuthenticationMethod: String, Codable, CaseIterable, Sendable {
        case none = "none"
        case basic = "basic"
        case bearer = "bearer"
        case apiKey = "apiKey"
        case oauth2 = "oauth2"
        case custom = "custom"
    }
    
    public enum CachePolicy: String, Codable, CaseIterable, Sendable {
        case never = "never"
        case always = "always"
        case conditional = "conditional"
        case etag = "etag"
        case lastModified = "lastModified"
    }
    
    public enum PaginationStyle: String, Codable, CaseIterable, Sendable {
        case offset = "offset"
        case cursor = "cursor"
        case page = "page"
        case link = "link"
        case none = "none"
    }
    
    public struct RESTRetryPolicy: Codable, Sendable {
        public let maxRetries: Int
        public let baseDelay: TimeInterval
        public let multiplier: Double
        public let jitter: Bool
        public let retryableStatusCodes: Set<Int>
        public let retryableErrors: Set<String>
        
        public init(
            maxRetries: Int = 3,
            baseDelay: TimeInterval = 1.0,
            multiplier: Double = 2.0,
            jitter: Bool = true,
            retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
            retryableErrors: Set<String> = ["timeout", "network"]
        ) {
            self.maxRetries = maxRetries
            self.baseDelay = baseDelay
            self.multiplier = multiplier
            self.jitter = jitter
            self.retryableStatusCodes = retryableStatusCodes
            self.retryableErrors = retryableErrors
        }
    }
    
    public struct RateLimitHeaders: Codable, Sendable {
        public let limitHeader: String
        public let remainingHeader: String
        public let resetHeader: String
        public let retryAfterHeader: String
        
        public init(
            limitHeader: String = "X-RateLimit-Limit",
            remainingHeader: String = "X-RateLimit-Remaining",
            resetHeader: String = "X-RateLimit-Reset",
            retryAfterHeader: String = "Retry-After"
        ) {
            self.limitHeader = limitHeader
            self.remainingHeader = remainingHeader
            self.resetHeader = resetHeader
            self.retryAfterHeader = retryAfterHeader
        }
    }
    
    public init(
        baseURL: URL? = nil,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30.0,
        retryPolicy: RESTRetryPolicy = RESTRetryPolicy(),
        contentType: ContentType = .json,
        acceptType: ContentType = .json,
        authenticationMethod: AuthenticationMethod = .none,
        enableCaching: Bool = true,
        cachePolicy: CachePolicy = .conditional,
        enablePagination: Bool = true,
        paginationStyle: PaginationStyle = .offset,
        enableRateLimiting: Bool = true,
        rateLimitHeaders: RateLimitHeaders = RateLimitHeaders(),
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        validateStatusCodes: Bool = true,
        allowedStatusCodes: Set<Int> = Set(200...299),
        enableHATEOAS: Bool = false,
        enableETag: Bool = true,
        enableLastModified: Bool = true,
        enableContentNegotiation: Bool = true,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.contentType = contentType
        self.acceptType = acceptType
        self.authenticationMethod = authenticationMethod
        self.enableCaching = enableCaching
        self.cachePolicy = cachePolicy
        self.enablePagination = enablePagination
        self.paginationStyle = paginationStyle
        self.enableRateLimiting = enableRateLimiting
        self.rateLimitHeaders = rateLimitHeaders
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.validateStatusCodes = validateStatusCodes
        self.allowedStatusCodes = allowedStatusCodes
        self.enableHATEOAS = enableHATEOAS
        self.enableETag = enableETag
        self.enableLastModified = enableLastModified
        self.enableContentNegotiation = enableContentNegotiation
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    public var isValid: Bool {
        timeout > 0 && 
        retryPolicy.maxRetries >= 0 && 
        retryPolicy.baseDelay >= 0 &&
        maxRetries >= 0 && 
        retryDelay >= 0
    }
    
    public func merged(with other: RESTCapabilityConfiguration) -> RESTCapabilityConfiguration {
        RESTCapabilityConfiguration(
            baseURL: other.baseURL ?? baseURL,
            defaultHeaders: defaultHeaders.merging(other.defaultHeaders) { _, new in new },
            timeout: other.timeout,
            retryPolicy: other.retryPolicy,
            contentType: other.contentType,
            acceptType: other.acceptType,
            authenticationMethod: other.authenticationMethod,
            enableCaching: other.enableCaching,
            cachePolicy: other.cachePolicy,
            enablePagination: other.enablePagination,
            paginationStyle: other.paginationStyle,
            enableRateLimiting: other.enableRateLimiting,
            rateLimitHeaders: other.rateLimitHeaders,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            validateStatusCodes: other.validateStatusCodes,
            allowedStatusCodes: other.allowedStatusCodes,
            enableHATEOAS: other.enableHATEOAS,
            enableETag: other.enableETag,
            enableLastModified: other.enableLastModified,
            enableContentNegotiation: other.enableContentNegotiation,
            maxRetries: other.maxRetries,
            retryDelay: other.retryDelay
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> RESTCapabilityConfiguration {
        var adjustedTimeout = timeout
        var adjustedLogging = enableLogging
        var adjustedRetries = maxRetries
        var adjustedCaching = enableCaching
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 2.0
            adjustedRetries = min(maxRetries, 1)
            adjustedCaching = true // Enable more aggressive caching
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return RESTCapabilityConfiguration(
            baseURL: baseURL,
            defaultHeaders: defaultHeaders,
            timeout: adjustedTimeout,
            retryPolicy: retryPolicy,
            contentType: contentType,
            acceptType: acceptType,
            authenticationMethod: authenticationMethod,
            enableCaching: adjustedCaching,
            cachePolicy: cachePolicy,
            enablePagination: enablePagination,
            paginationStyle: paginationStyle,
            enableRateLimiting: enableRateLimiting,
            rateLimitHeaders: rateLimitHeaders,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            validateStatusCodes: validateStatusCodes,
            allowedStatusCodes: allowedStatusCodes,
            enableHATEOAS: enableHATEOAS,
            enableETag: enableETag,
            enableLastModified: enableLastModified,
            enableContentNegotiation: enableContentNegotiation,
            maxRetries: adjustedRetries,
            retryDelay: retryDelay
        )
    }
}

// MARK: - REST Types

/// REST resource definition
public struct RESTResource: Sendable {
    public let path: String
    public let identifier: String?
    public let version: String?
    public let namespace: String?
    
    public init(path: String, identifier: String? = nil, version: String? = nil, namespace: String? = nil) {
        self.path = path
        self.identifier = identifier
        self.version = version
        self.namespace = namespace
    }
    
    public var fullPath: String {
        var components = [String]()
        
        if let version = version {
            components.append("v\(version)")
        }
        
        if let namespace = namespace {
            components.append(namespace)
        }
        
        components.append(path)
        
        if let identifier = identifier {
            components.append(identifier)
        }
        
        return components.joined(separator: "/")
    }
}

/// REST request options
public struct RESTRequestOptions: Sendable {
    public let headers: [String: String]
    public let queryParameters: [String: String]
    public let cachePolicy: RESTCapabilityConfiguration.CachePolicy?
    public let timeout: TimeInterval?
    public let retryPolicy: RESTCapabilityConfiguration.RESTRetryPolicy?
    public let validateResponse: Bool
    public let followRedirects: Bool
    
    public init(
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        cachePolicy: RESTCapabilityConfiguration.CachePolicy? = nil,
        timeout: TimeInterval? = nil,
        retryPolicy: RESTCapabilityConfiguration.RESTRetryPolicy? = nil,
        validateResponse: Bool = true,
        followRedirects: Bool = true
    ) {
        self.headers = headers
        self.queryParameters = queryParameters
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.validateResponse = validateResponse
        self.followRedirects = followRedirects
    }
}

/// REST response wrapper
public struct RESTResponse<T: Codable>: Sendable {
    public let data: T
    public let statusCode: Int
    public let headers: [String: String]
    public let url: URL?
    public let duration: TimeInterval
    public let fromCache: Bool
    public let pagination: PaginationInfo?
    public let rateLimit: RateLimitInfo?
    public let links: [String: URL]
    
    public init(
        data: T,
        statusCode: Int,
        headers: [String: String],
        url: URL?,
        duration: TimeInterval,
        fromCache: Bool = false,
        pagination: PaginationInfo? = nil,
        rateLimit: RateLimitInfo? = nil,
        links: [String: URL] = [:]
    ) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.url = url
        self.duration = duration
        self.fromCache = fromCache
        self.pagination = pagination
        self.rateLimit = rateLimit
        self.links = links
    }
}

/// Pagination information
public struct PaginationInfo: Sendable {
    public let currentPage: Int?
    public let totalPages: Int?
    public let pageSize: Int?
    public let totalItems: Int?
    public let hasNext: Bool
    public let hasPrevious: Bool
    public let nextCursor: String?
    public let previousCursor: String?
    public let nextURL: URL?
    public let previousURL: URL?
    
    public init(
        currentPage: Int? = nil,
        totalPages: Int? = nil,
        pageSize: Int? = nil,
        totalItems: Int? = nil,
        hasNext: Bool = false,
        hasPrevious: Bool = false,
        nextCursor: String? = nil,
        previousCursor: String? = nil,
        nextURL: URL? = nil,
        previousURL: URL? = nil
    ) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.pageSize = pageSize
        self.totalItems = totalItems
        self.hasNext = hasNext
        self.hasPrevious = hasPrevious
        self.nextCursor = nextCursor
        self.previousCursor = previousCursor
        self.nextURL = nextURL
        self.previousURL = previousURL
    }
}

/// Rate limit information
public struct RateLimitInfo: Sendable {
    public let limit: Int?
    public let remaining: Int?
    public let reset: Date?
    public let retryAfter: TimeInterval?
    
    public init(limit: Int? = nil, remaining: Int? = nil, reset: Date? = nil, retryAfter: TimeInterval? = nil) {
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
        self.retryAfter = retryAfter
    }
}

/// REST error response
public struct RESTErrorResponse: Codable, Sendable {
    public let code: String?
    public let message: String
    public let details: [String: AnyCodable]?
    public let timestamp: Date?
    public let path: String?
    public let method: String?
    public let statusCode: Int?
    
    public init(
        code: String? = nil,
        message: String,
        details: [String: AnyCodable]? = nil,
        timestamp: Date? = nil,
        path: String? = nil,
        method: String? = nil,
        statusCode: Int? = nil
    ) {
        self.code = code
        self.message = message
        self.details = details
        self.timestamp = timestamp
        self.path = path
        self.method = method
        self.statusCode = statusCode
    }
}

/// Type-erased Codable wrapper
public struct AnyCodable: Codable, Sendable {
    private let value: Any
    
    public init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - REST Resource

/// REST resource management
public actor RESTCapabilityResource: AxiomCapabilityResource {
    private let configuration: RESTCapabilityConfiguration
    private var httpClient: HTTPClientCapability?
    private var responseCache: [String: (data: Data, timestamp: Date)] = [:]
    private var rateLimitState: [String: RateLimitInfo] = [:]
    
    public init(configuration: RESTCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 50_000_000, // 50MB for caching and HTTP operations
            cpu: 10.0, // 10% CPU for REST operations
            bandwidth: 10_000_000, // 10MB/s bandwidth
            storage: 100_000_000 // 100MB for cache storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let cacheSize = responseCache.reduce(0) { sum, entry in
                sum + entry.value.data.count
            }
            
            return ResourceUsage(
                memory: cacheSize,
                cpu: httpClient != nil ? 5.0 : 0.1,
                bandwidth: 0, // Dynamic based on active requests
                storage: cacheSize
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        httpClient != nil
    }
    
    public func release() async {
        await httpClient?.deactivate()
        httpClient = nil
        responseCache.removeAll()
        rateLimitState.removeAll()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Create HTTP client with REST-optimized configuration
        let httpConfig = HTTPClientCapabilityConfiguration(
            baseURL: configuration.baseURL,
            timeout: configuration.timeout,
            retryCount: configuration.maxRetries,
            retryDelay: configuration.retryDelay,
            enableLogging: configuration.enableLogging,
            enableMetrics: configuration.enableMetrics
        )
        
        httpClient = HTTPClientCapability(configuration: httpConfig)
        try await httpClient?.activate()
    }
    
    internal func updateConfiguration(_ configuration: RESTCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - REST Operations
    
    public func executeRequest<T: Codable>(
        method: HTTPMethod,
        resource: RESTResource,
        body: Data? = nil,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        guard let client = httpClient else {
            throw RESTError.clientNotAvailable
        }
        
        // Build URL
        let url = try buildURL(for: resource, queryParameters: options.queryParameters)
        
        // Build headers
        let headers = buildHeaders(options: options)
        
        // Check cache
        if method == .GET, configuration.enableCaching {
            if let cachedResponse = getCachedResponse(for: url.absoluteString, responseType: responseType) {
                return cachedResponse
            }
        }
        
        // Check rate limiting
        if configuration.enableRateLimiting {
            try await checkRateLimit(for: url.host ?? "")
        }
        
        // Create HTTP request
        let httpRequest = HTTPRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            timeout: options.timeout ?? configuration.timeout
        )
        
        // Execute request
        let startTime = Date()
        let httpResponse = try await client.execute(httpRequest)
        let duration = Date().timeIntervalSince(startTime)
        
        // Parse response
        let restResponse: RESTResponse<T> = try parseResponse(
            httpResponse: httpResponse,
            responseType: responseType,
            duration: duration
        )
        
        // Update cache
        if method == .GET, configuration.enableCaching {
            cacheResponse(for: url.absoluteString, data: httpResponse.data)
        }
        
        // Update rate limit state
        if configuration.enableRateLimiting {
            updateRateLimit(from: httpResponse.headers, host: url.host ?? "")
        }
        
        return restResponse
    }
    
    // MARK: - CRUD Operations
    
    public func get<T: Codable>(
        resource: RESTResource,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        try await executeRequest(
            method: .GET,
            resource: resource,
            options: options,
            responseType: responseType
        )
    }
    
    public func post<T: Codable, U: Codable>(
        resource: RESTResource,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        let bodyData = try JSONEncoder().encode(body)
        return try await executeRequest(
            method: .POST,
            resource: resource,
            body: bodyData,
            options: options,
            responseType: responseType
        )
    }
    
    public func put<T: Codable, U: Codable>(
        resource: RESTResource,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        let bodyData = try JSONEncoder().encode(body)
        return try await executeRequest(
            method: .PUT,
            resource: resource,
            body: bodyData,
            options: options,
            responseType: responseType
        )
    }
    
    public func patch<T: Codable, U: Codable>(
        resource: RESTResource,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        let bodyData = try JSONEncoder().encode(body)
        return try await executeRequest(
            method: .PATCH,
            resource: resource,
            body: bodyData,
            options: options,
            responseType: responseType
        )
    }
    
    public func delete<T: Codable>(
        resource: RESTResource,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        try await executeRequest(
            method: .DELETE,
            resource: resource,
            options: options,
            responseType: responseType
        )
    }
    
    // MARK: - Private Implementation
    
    private func buildURL(for resource: RESTResource, queryParameters: [String: String]) throws -> URL {
        let baseURL = configuration.baseURL ?? URL(string: "https://api.example.com")!
        var components = URLComponents(url: baseURL.appendingPathComponent(resource.fullPath), resolvingAgainstBaseURL: true)!
        
        if !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw RESTError.invalidURL(components.string ?? "")
        }
        
        return url
    }
    
    private func buildHeaders(options: RESTRequestOptions) -> [String: String] {
        var headers = configuration.defaultHeaders
        
        // Content-Type header
        if configuration.contentType != .custom {
            headers["Content-Type"] = configuration.contentType.rawValue
        }
        
        // Accept header
        if configuration.acceptType != .custom {
            headers["Accept"] = configuration.acceptType.rawValue
        }
        
        // Add custom headers from options
        for (key, value) in options.headers {
            headers[key] = value
        }
        
        return headers
    }
    
    private func getCachedResponse<T: Codable>(for key: String, responseType: T.Type) -> RESTResponse<T>? {
        guard let cached = responseCache[key] else { return nil }
        
        // Check cache expiration (simple TTL)
        let cacheAge = Date().timeIntervalSince(cached.timestamp)
        if cacheAge > 300 { // 5 minutes TTL
            responseCache.removeValue(forKey: key)
            return nil
        }
        
        do {
            let data = try JSONDecoder().decode(responseType, from: cached.data)
            return RESTResponse(
                data: data,
                statusCode: 200,
                headers: [:],
                url: URL(string: key),
                duration: 0,
                fromCache: true
            )
        } catch {
            return nil
        }
    }
    
    private func cacheResponse(for key: String, data: Data) {
        responseCache[key] = (data: data, timestamp: Date())
        
        // Simple cache size management
        if responseCache.count > 100 {
            let oldestKey = responseCache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let key = oldestKey {
                responseCache.removeValue(forKey: key)
            }
        }
    }
    
    private func checkRateLimit(for host: String) async throws {
        guard let rateLimit = rateLimitState[host] else { return }
        
        if let remaining = rateLimit.remaining, remaining <= 0 {
            if let reset = rateLimit.reset, Date() < reset {
                throw RESTError.rateLimitExceeded(retryAfter: reset.timeIntervalSinceNow)
            }
        }
    }
    
    private func updateRateLimit(from headers: [String: String], host: String) {
        let limitHeader = configuration.rateLimitHeaders.limitHeader
        let remainingHeader = configuration.rateLimitHeaders.remainingHeader
        let resetHeader = configuration.rateLimitHeaders.resetHeader
        let retryAfterHeader = configuration.rateLimitHeaders.retryAfterHeader
        
        let limit = headers[limitHeader].flatMap { Int($0) }
        let remaining = headers[remainingHeader].flatMap { Int($0) }
        let reset = headers[resetHeader].flatMap { TimeInterval($0) }.map { Date(timeIntervalSince1970: $0) }
        let retryAfter = headers[retryAfterHeader].flatMap { TimeInterval($0) }
        
        rateLimitState[host] = RateLimitInfo(
            limit: limit,
            remaining: remaining,
            reset: reset,
            retryAfter: retryAfter
        )
    }
    
    private func parseResponse<T: Codable>(
        httpResponse: HTTPResponse,
        responseType: T.Type,
        duration: TimeInterval
    ) throws -> RESTResponse<T> {
        // Validate status code
        if configuration.validateStatusCodes && !configuration.allowedStatusCodes.contains(httpResponse.statusCode) {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(RESTErrorResponse.self, from: httpResponse.data) {
                throw RESTError.serverError(httpResponse.statusCode, errorResponse)
            } else {
                throw RESTError.httpError(httpResponse.statusCode, String(data: httpResponse.data, encoding: .utf8) ?? "")
            }
        }
        
        // Parse response data
        let data = try JSONDecoder().decode(responseType, from: httpResponse.data)
        
        // Parse pagination info
        let pagination = parsePaginationInfo(from: httpResponse.headers)
        
        // Parse rate limit info
        let rateLimit = parseRateLimitInfo(from: httpResponse.headers)
        
        // Parse HATEOAS links
        let links = parseLinks(from: httpResponse.headers)
        
        return RESTResponse(
            data: data,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.headers,
            url: httpResponse.request.url,
            duration: duration,
            pagination: pagination,
            rateLimit: rateLimit,
            links: links
        )
    }
    
    private func parsePaginationInfo(from headers: [String: String]) -> PaginationInfo? {
        // Implementation depends on pagination style
        switch configuration.paginationStyle {
        case .link:
            return parseLinkHeaderPagination(from: headers)
        case .offset, .page, .cursor:
            return parseHeaderBasedPagination(from: headers)
        case .none:
            return nil
        }
    }
    
    private func parseLinkHeaderPagination(from headers: [String: String]) -> PaginationInfo? {
        guard let linkHeader = headers["Link"] else { return nil }
        
        // Parse Link header (RFC 5988)
        var nextURL: URL?
        var previousURL: URL?
        
        let links = linkHeader.components(separatedBy: ",")
        for link in links {
            let parts = link.trimmingCharacters(in: .whitespaces).components(separatedBy: ";")
            guard parts.count >= 2 else { continue }
            
            let urlPart = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            let relPart = parts[1].trimmingCharacters(in: .whitespaces)
            
            if relPart.contains("next") {
                nextURL = URL(string: urlPart)
            } else if relPart.contains("prev") || relPart.contains("previous") {
                previousURL = URL(string: urlPart)
            }
        }
        
        return PaginationInfo(
            hasNext: nextURL != nil,
            hasPrevious: previousURL != nil,
            nextURL: nextURL,
            previousURL: previousURL
        )
    }
    
    private func parseHeaderBasedPagination(from headers: [String: String]) -> PaginationInfo? {
        let currentPage = headers["X-Page-Current"].flatMap { Int($0) }
        let totalPages = headers["X-Page-Total"].flatMap { Int($0) }
        let pageSize = headers["X-Page-Size"].flatMap { Int($0) }
        let totalItems = headers["X-Total-Count"].flatMap { Int($0) }
        
        return PaginationInfo(
            currentPage: currentPage,
            totalPages: totalPages,
            pageSize: pageSize,
            totalItems: totalItems,
            hasNext: currentPage != nil && totalPages != nil && currentPage! < totalPages!,
            hasPrevious: currentPage != nil && currentPage! > 1
        )
    }
    
    private func parseRateLimitInfo(from headers: [String: String]) -> RateLimitInfo? {
        guard configuration.enableRateLimiting else { return nil }
        
        let limit = headers[configuration.rateLimitHeaders.limitHeader].flatMap { Int($0) }
        let remaining = headers[configuration.rateLimitHeaders.remainingHeader].flatMap { Int($0) }
        let reset = headers[configuration.rateLimitHeaders.resetHeader].flatMap { TimeInterval($0) }.map { Date(timeIntervalSince1970: $0) }
        let retryAfter = headers[configuration.rateLimitHeaders.retryAfterHeader].flatMap { TimeInterval($0) }
        
        guard limit != nil || remaining != nil || reset != nil || retryAfter != nil else {
            return nil
        }
        
        return RateLimitInfo(limit: limit, remaining: remaining, reset: reset, retryAfter: retryAfter)
    }
    
    private func parseLinks(from headers: [String: String]) -> [String: URL] {
        guard configuration.enableHATEOAS else { return [:] }
        
        var links: [String: URL] = [:]
        
        // Parse custom link headers
        for (key, value) in headers {
            if key.lowercased().hasPrefix("x-link-") {
                let linkName = String(key.dropFirst(7)) // Remove "x-link-" prefix
                if let url = URL(string: value) {
                    links[linkName] = url
                }
            }
        }
        
        return links
    }
}

// MARK: - REST Capability Implementation

/// REST capability providing REST API conventions and patterns
public actor RESTCapability: DomainCapability {
    public typealias ConfigurationType = RESTCapabilityConfiguration
    public typealias ResourceType = RESTCapabilityResource
    
    private var _configuration: RESTCapabilityConfiguration
    private var _resources: RESTCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "rest-capability" }
    
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
    
    public var configuration: RESTCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: RESTCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: RESTCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = RESTCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: RESTCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid REST configuration")
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
        // REST is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // REST doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - REST Operations
    
    /// GET request
    public func get<T: Codable>(
        resource: RESTResource,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("REST capability not available")
        }
        
        return try await _resources.get(resource: resource, options: options, responseType: responseType)
    }
    
    /// POST request
    public func post<T: Codable, U: Codable>(
        resource: RESTResource,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("REST capability not available")
        }
        
        return try await _resources.post(resource: resource, body: body, options: options, responseType: responseType)
    }
    
    /// PUT request
    public func put<T: Codable, U: Codable>(
        resource: RESTResource,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("REST capability not available")
        }
        
        return try await _resources.put(resource: resource, body: body, options: options, responseType: responseType)
    }
    
    /// PATCH request
    public func patch<T: Codable, U: Codable>(
        resource: RESTResource,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("REST capability not available")
        }
        
        return try await _resources.patch(resource: resource, body: body, options: options, responseType: responseType)
    }
    
    /// DELETE request
    public func delete<T: Codable>(
        resource: RESTResource,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("REST capability not available")
        }
        
        return try await _resources.delete(resource: resource, options: options, responseType: responseType)
    }
    
    // MARK: - Convenience Methods
    
    /// Get collection of resources
    public func getCollection<T: Codable>(
        path: String,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<[T]> {
        let resource = RESTResource(path: path)
        return try await get(resource: resource, options: options, responseType: [T].self)
    }
    
    /// Get single resource by ID
    public func getResource<T: Codable>(
        path: String,
        id: String,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        let resource = RESTResource(path: path, identifier: id)
        return try await get(resource: resource, options: options, responseType: responseType)
    }
    
    /// Create new resource
    public func createResource<T: Codable, U: Codable>(
        path: String,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        let resource = RESTResource(path: path)
        return try await post(resource: resource, body: body, options: options, responseType: responseType)
    }
    
    /// Update resource by ID
    public func updateResource<T: Codable, U: Codable>(
        path: String,
        id: String,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        let resource = RESTResource(path: path, identifier: id)
        return try await put(resource: resource, body: body, options: options, responseType: responseType)
    }
    
    /// Partially update resource by ID
    public func patchResource<T: Codable, U: Codable>(
        path: String,
        id: String,
        body: T,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: U.Type
    ) async throws -> RESTResponse<U> {
        let resource = RESTResource(path: path, identifier: id)
        return try await patch(resource: resource, body: body, options: options, responseType: responseType)
    }
    
    /// Delete resource by ID
    public func deleteResource<T: Codable>(
        path: String,
        id: String,
        options: RESTRequestOptions = RESTRequestOptions(),
        responseType: T.Type
    ) async throws -> RESTResponse<T> {
        let resource = RESTResource(path: path, identifier: id)
        return try await delete(resource: resource, options: options, responseType: responseType)
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// REST specific errors
public enum RESTError: Error, LocalizedError {
    case clientNotAvailable
    case invalidURL(String)
    case httpError(Int, String)
    case serverError(Int, RESTErrorResponse)
    case rateLimitExceeded(retryAfter: TimeInterval)
    case invalidResponse(String)
    case authenticationFailed(String)
    case authorizationFailed(String)
    case validationFailed([String])
    
    public var errorDescription: String? {
        switch self {
        case .clientNotAvailable:
            return "REST client is not available"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message)"
        case .serverError(let code, let error):
            return "Server error \(code): \(error.message)"
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Retry after \(retryAfter) seconds"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .authorizationFailed(let message):
            return "Authorization failed: \(message)"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        }
    }
}