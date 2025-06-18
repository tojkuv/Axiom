import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - GraphQL Capability Configuration

/// Configuration for GraphQL capability
public struct GraphQLCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let endpoint: URL
    public let subscriptionEndpoint: URL?
    public let headers: [String: String]
    public let timeout: TimeInterval
    public let enableCaching: Bool
    public let cachePolicy: CachePolicy
    public let cacheTTL: TimeInterval
    public let maxCacheSize: Int
    public let enableBatching: Bool
    public let batchInterval: TimeInterval
    public let maxBatchSize: Int
    public let enableSubscriptions: Bool
    public let subscriptionProtocol: SubscriptionProtocol
    public let enableIntrospection: Bool
    public let enableQueryValidation: Bool
    public let enablePerformanceMonitoring: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let retryPolicy: RetryPolicy
    public let errorPolicy: ErrorPolicy
    public let authenticationMethod: AuthenticationMethod
    
    public enum CachePolicy: String, Codable, CaseIterable, Sendable {
        case cacheFirst = "cache-first"
        case networkFirst = "network-first"
        case cacheOnly = "cache-only"
        case networkOnly = "network-only"
        case cacheAndNetwork = "cache-and-network"
    }
    
    public enum SubscriptionProtocol: String, Codable, CaseIterable, Sendable {
        case webSocket = "websocket"
        case serverSentEvents = "sse"
        case webSocketSubprotocol = "graphql-ws"
        case webSocketTransport = "graphql-transport-ws"
    }
    
    public enum ErrorPolicy: String, Codable, CaseIterable, Sendable {
        case none = "none"
        case ignore = "ignore"
        case all = "all"
    }
    
    public enum AuthenticationMethod: String, Codable, CaseIterable, Sendable {
        case none = "none"
        case bearer = "bearer"
        case apiKey = "apiKey"
        case custom = "custom"
    }
    
    public struct RetryPolicy: Codable, Sendable {
        public let maxRetries: Int
        public let baseDelay: TimeInterval
        public let multiplier: Double
        public let jitter: Bool
        public let retryableErrors: Set<String>
        
        public init(
            maxRetries: Int = 3,
            baseDelay: TimeInterval = 1.0,
            multiplier: Double = 2.0,
            jitter: Bool = true,
            retryableErrors: Set<String> = ["NETWORK_ERROR", "TIMEOUT"]
        ) {
            self.maxRetries = maxRetries
            self.baseDelay = baseDelay
            self.multiplier = multiplier
            self.jitter = jitter
            self.retryableErrors = retryableErrors
        }
    }
    
    public init(
        endpoint: URL,
        subscriptionEndpoint: URL? = nil,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30.0,
        enableCaching: Bool = true,
        cachePolicy: CachePolicy = .cacheFirst,
        cacheTTL: TimeInterval = 300.0, // 5 minutes
        maxCacheSize: Int = 100,
        enableBatching: Bool = false,
        batchInterval: TimeInterval = 0.1,
        maxBatchSize: Int = 10,
        enableSubscriptions: Bool = false,
        subscriptionProtocol: SubscriptionProtocol = .webSocket,
        enableIntrospection: Bool = false,
        enableQueryValidation: Bool = true,
        enablePerformanceMonitoring: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        retryPolicy: RetryPolicy = RetryPolicy(),
        errorPolicy: ErrorPolicy = .none,
        authenticationMethod: AuthenticationMethod = .none
    ) {
        self.endpoint = endpoint
        self.subscriptionEndpoint = subscriptionEndpoint
        self.headers = headers
        self.timeout = timeout
        self.enableCaching = enableCaching
        self.cachePolicy = cachePolicy
        self.cacheTTL = cacheTTL
        self.maxCacheSize = maxCacheSize
        self.enableBatching = enableBatching
        self.batchInterval = batchInterval
        self.maxBatchSize = maxBatchSize
        self.enableSubscriptions = enableSubscriptions
        self.subscriptionProtocol = subscriptionProtocol
        self.enableIntrospection = enableIntrospection
        self.enableQueryValidation = enableQueryValidation
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.retryPolicy = retryPolicy
        self.errorPolicy = errorPolicy
        self.authenticationMethod = authenticationMethod
    }
    
    public var isValid: Bool {
        timeout > 0 &&
        cacheTTL > 0 &&
        maxCacheSize > 0 &&
        batchInterval > 0 &&
        maxBatchSize > 0 &&
        retryPolicy.maxRetries >= 0 &&
        retryPolicy.baseDelay >= 0
    }
    
    public func merged(with other: GraphQLCapabilityConfiguration) -> GraphQLCapabilityConfiguration {
        GraphQLCapabilityConfiguration(
            endpoint: other.endpoint,
            subscriptionEndpoint: other.subscriptionEndpoint ?? subscriptionEndpoint,
            headers: headers.merging(other.headers) { _, new in new },
            timeout: other.timeout,
            enableCaching: other.enableCaching,
            cachePolicy: other.cachePolicy,
            cacheTTL: other.cacheTTL,
            maxCacheSize: other.maxCacheSize,
            enableBatching: other.enableBatching,
            batchInterval: other.batchInterval,
            maxBatchSize: other.maxBatchSize,
            enableSubscriptions: other.enableSubscriptions,
            subscriptionProtocol: other.subscriptionProtocol,
            enableIntrospection: other.enableIntrospection,
            enableQueryValidation: other.enableQueryValidation,
            enablePerformanceMonitoring: other.enablePerformanceMonitoring,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            retryPolicy: other.retryPolicy,
            errorPolicy: other.errorPolicy,
            authenticationMethod: other.authenticationMethod
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> GraphQLCapabilityConfiguration {
        var adjustedTimeout = timeout
        var adjustedLogging = enableLogging
        var adjustedCaching = enableCaching
        var adjustedBatching = enableBatching
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 2.0
            adjustedCaching = true // Enable more aggressive caching
            adjustedBatching = true // Enable batching to reduce requests
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return GraphQLCapabilityConfiguration(
            endpoint: endpoint,
            subscriptionEndpoint: subscriptionEndpoint,
            headers: headers,
            timeout: adjustedTimeout,
            enableCaching: adjustedCaching,
            cachePolicy: cachePolicy,
            cacheTTL: cacheTTL,
            maxCacheSize: maxCacheSize,
            enableBatching: adjustedBatching,
            batchInterval: batchInterval,
            maxBatchSize: maxBatchSize,
            enableSubscriptions: enableSubscriptions,
            subscriptionProtocol: subscriptionProtocol,
            enableIntrospection: enableIntrospection,
            enableQueryValidation: enableQueryValidation,
            enablePerformanceMonitoring: enablePerformanceMonitoring,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            retryPolicy: retryPolicy,
            errorPolicy: errorPolicy,
            authenticationMethod: authenticationMethod
        )
    }
}

// MARK: - GraphQL Types

/// GraphQL operation type
public enum GraphQLOperationType: String, Codable, CaseIterable, Sendable {
    case query = "query"
    case mutation = "mutation"
    case subscription = "subscription"
}

/// GraphQL query definition
public struct GraphQLQuery: Sendable {
    public let operationType: GraphQLOperationType
    public let operationName: String?
    public let query: String
    public let variables: [String: Any]?
    public let cacheKey: String?
    public let cacheTTL: TimeInterval?
    
    public init(
        operationType: GraphQLOperationType = .query,
        operationName: String? = nil,
        query: String,
        variables: [String: Any]? = nil,
        cacheKey: String? = nil,
        cacheTTL: TimeInterval? = nil
    ) {
        self.operationType = operationType
        self.operationName = operationName
        self.query = query
        self.variables = variables
        self.cacheKey = cacheKey
        self.cacheTTL = cacheTTL
    }
    
    public var requestBody: [String: Any] {
        var body: [String: Any] = ["query": query]
        
        if let variables = variables {
            body["variables"] = variables
        }
        
        if let operationName = operationName {
            body["operationName"] = operationName
        }
        
        return body
    }
    
    public var computedCacheKey: String {
        if let cacheKey = cacheKey {
            return cacheKey
        }
        
        // Generate cache key from query and variables
        var components = [query]
        
        if let variables = variables {
            let sortedVars = variables.sorted { $0.key < $1.key }
            for (key, value) in sortedVars {
                components.append("\(key):\(value)")
            }
        }
        
        return components.joined(separator: "|").sha256
    }
}

/// GraphQL response wrapper
public struct GraphQLResponse<T: Codable>: Sendable {
    public let data: T?
    public let errors: [GraphQLError]?
    public let extensions: [String: AnyCodable]?
    public let fromCache: Bool
    public let duration: TimeInterval
    public let operationType: GraphQLOperationType
    public let operationName: String?
    
    public init(
        data: T?,
        errors: [GraphQLError]? = nil,
        extensions: [String: AnyCodable]? = nil,
        fromCache: Bool = false,
        duration: TimeInterval = 0,
        operationType: GraphQLOperationType = .query,
        operationName: String? = nil
    ) {
        self.data = data
        self.errors = errors
        self.extensions = extensions
        self.fromCache = fromCache
        self.duration = duration
        self.operationType = operationType
        self.operationName = operationName
    }
    
    public var hasErrors: Bool {
        errors?.isEmpty == false
    }
    
    public var isSuccessful: Bool {
        data != nil && !hasErrors
    }
}

/// GraphQL error
public struct GraphQLError: Codable, Sendable {
    public let message: String
    public let locations: [GraphQLLocation]?
    public let path: [AnyCodable]?
    public let extensions: [String: AnyCodable]?
    
    public init(
        message: String,
        locations: [GraphQLLocation]? = nil,
        path: [AnyCodable]? = nil,
        extensions: [String: AnyCodable]? = nil
    ) {
        self.message = message
        self.locations = locations
        self.path = path
        self.extensions = extensions
    }
}

/// GraphQL error location
public struct GraphQLLocation: Codable, Sendable {
    public let line: Int
    public let column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}

/// GraphQL subscription message
public struct GraphQLSubscriptionMessage: Sendable {
    public let id: String?
    public let type: String
    public let payload: [String: Any]?
    
    public init(id: String? = nil, type: String, payload: [String: Any]? = nil) {
        self.id = id
        self.type = type
        self.payload = payload
    }
}

/// GraphQL batch query
public struct GraphQLBatch: Sendable {
    public let queries: [GraphQLQuery]
    public let batchId: String
    
    public init(queries: [GraphQLQuery], batchId: String = UUID().uuidString) {
        self.queries = queries
        self.batchId = batchId
    }
    
    public var requestBody: [[String: Any]] {
        queries.map { $0.requestBody }
    }
}

/// GraphQL cache entry
internal struct GraphQLCacheEntry: Sendable {
    let data: Data
    let timestamp: Date
    let ttl: TimeInterval
    let operationType: GraphQLOperationType
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

/// GraphQL metrics
public struct GraphQLMetrics: Sendable {
    public let totalQueries: Int
    public let totalMutations: Int
    public let totalSubscriptions: Int
    public let cacheHits: Int
    public let cacheMisses: Int
    public let averageQueryDuration: TimeInterval
    public let averageMutationDuration: TimeInterval
    public let errorCount: Int
    public let batchCount: Int
    public let subscriptionCount: Int
    
    public init(
        totalQueries: Int = 0,
        totalMutations: Int = 0,
        totalSubscriptions: Int = 0,
        cacheHits: Int = 0,
        cacheMisses: Int = 0,
        averageQueryDuration: TimeInterval = 0,
        averageMutationDuration: TimeInterval = 0,
        errorCount: Int = 0,
        batchCount: Int = 0,
        subscriptionCount: Int = 0
    ) {
        self.totalQueries = totalQueries
        self.totalMutations = totalMutations
        self.totalSubscriptions = totalSubscriptions
        self.cacheHits = cacheHits
        self.cacheMisses = cacheMisses
        self.averageQueryDuration = averageQueryDuration
        self.averageMutationDuration = averageMutationDuration
        self.errorCount = errorCount
        self.batchCount = batchCount
        self.subscriptionCount = subscriptionCount
    }
    
    public var cacheHitRatio: Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }
    
    public var totalOperations: Int {
        totalQueries + totalMutations + totalSubscriptions
    }
}

// MARK: - GraphQL Resource

/// GraphQL resource management
public actor GraphQLCapabilityResource: AxiomCapabilityResource {
    private let configuration: GraphQLCapabilityConfiguration
    private var httpClient: HTTPClientCapability?
    private var webSocketClient: WebSocketCapability?
    private var queryCache: [String: GraphQLCacheEntry] = [:]
    private var batchQueue: [GraphQLQuery] = []
    private var batchTimer: Timer?
    private var subscriptions: [String: AsyncStream<GraphQLSubscriptionMessage>.Continuation] = [:]
    private var metrics: GraphQLMetrics = GraphQLMetrics()
    private var queryDurations: [TimeInterval] = []
    private var mutationDurations: [TimeInterval] = []
    
    public init(configuration: GraphQLCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxCacheSize * 100_000, // 100KB per cache entry
            cpu: 15.0, // 15% CPU for GraphQL operations
            bandwidth: 5_000_000, // 5MB/s bandwidth
            storage: configuration.maxCacheSize * 50_000 // 50KB per cache entry
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let cacheSize = queryCache.reduce(0) { sum, entry in
                sum + entry.value.data.count
            }
            
            return ResourceUsage(
                memory: cacheSize,
                cpu: httpClient != nil ? 10.0 : 0.1,
                bandwidth: 0, // Dynamic based on active operations
                storage: cacheSize
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        httpClient != nil
    }
    
    public func release() async {
        await httpClient?.deactivate()
        await webSocketClient?.deactivate()
        httpClient = nil
        webSocketClient = nil
        queryCache.removeAll()
        batchQueue.removeAll()
        batchTimer?.invalidate()
        batchTimer = nil
        
        // Finish all subscription streams
        for continuation in subscriptions.values {
            continuation.finish()
        }
        subscriptions.removeAll()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Create HTTP client for GraphQL operations
        let httpConfig = HTTPClientCapabilityConfiguration(
            timeout: configuration.timeout,
            enableLogging: configuration.enableLogging,
            enableMetrics: configuration.enableMetrics
        )
        
        httpClient = HTTPClientCapability(configuration: httpConfig)
        try await httpClient?.activate()
        
        // Create WebSocket client for subscriptions if enabled
        if configuration.enableSubscriptions {
            if let subscriptionEndpoint = configuration.subscriptionEndpoint {
                let wsConfig = WebSocketCapabilityConfiguration(
                    url: subscriptionEndpoint,
                    enableLogging: configuration.enableLogging,
                    enableMetrics: configuration.enableMetrics
                )
                
                webSocketClient = WebSocketCapability(configuration: wsConfig)
                try await webSocketClient?.activate()
            }
        }
        
        // Start batch timer if batching is enabled
        if configuration.enableBatching {
            startBatchTimer()
        }
    }
    
    internal func updateConfiguration(_ configuration: GraphQLCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - GraphQL Operations
    
    public func executeQuery<T: Codable>(
        _ query: GraphQLQuery,
        responseType: T.Type
    ) async throws -> GraphQLResponse<T> {
        guard let client = httpClient else {
            throw GraphQLError.clientNotAvailable
        }
        
        let startTime = Date()
        
        // Check cache first for queries
        if query.operationType == .query && configuration.enableCaching {
            if let cachedResponse = getCachedResponse(for: query, responseType: responseType) {
                await updateMetrics(
                    operationType: query.operationType,
                    duration: Date().timeIntervalSince(startTime),
                    fromCache: true
                )
                return cachedResponse
            }
        }
        
        // Build HTTP request
        let httpRequest = try buildHTTPRequest(for: query)
        
        // Execute request
        let httpResponse = try await client.execute(httpRequest)
        let duration = Date().timeIntervalSince(startTime)
        
        // Parse GraphQL response
        let graphqlResponse: GraphQLResponse<T> = try parseResponse(
            httpResponse: httpResponse,
            responseType: responseType,
            query: query,
            duration: duration
        )
        
        // Cache successful query responses
        if query.operationType == .query && configuration.enableCaching && graphqlResponse.isSuccessful {
            cacheResponse(for: query, data: httpResponse.data)
        }
        
        // Update metrics
        await updateMetrics(
            operationType: query.operationType,
            duration: duration,
            hasErrors: graphqlResponse.hasErrors
        )
        
        return graphqlResponse
    }
    
    public func executeBatch(_ batch: GraphQLBatch) async throws -> [GraphQLResponse<AnyCodable>] {
        guard let client = httpClient else {
            throw GraphQLError.clientNotAvailable
        }
        
        let startTime = Date()
        
        // Build batch HTTP request
        let httpRequest = try buildBatchHTTPRequest(for: batch)
        
        // Execute request
        let httpResponse = try await client.execute(httpRequest)
        let duration = Date().timeIntervalSince(startTime)
        
        // Parse batch response
        let responses: [GraphQLResponse<AnyCodable>] = try parseBatchResponse(
            httpResponse: httpResponse,
            batch: batch,
            duration: duration
        )
        
        // Update metrics
        await updateBatchMetrics(batch: batch, duration: duration, responses: responses)
        
        return responses
    }
    
    public func subscribe(
        _ query: GraphQLQuery
    ) -> AsyncStream<GraphQLSubscriptionMessage> {
        guard configuration.enableSubscriptions else {
            return AsyncStream { continuation in
                continuation.finish()
            }
        }
        
        return AsyncStream { continuation in
            let subscriptionId = UUID().uuidString
            subscriptions[subscriptionId] = continuation
            
            Task {
                await startSubscription(query: query, subscriptionId: subscriptionId)
            }
        }
    }
    
    public func addToBatch(_ query: GraphQLQuery) async {
        guard configuration.enableBatching else {
            return
        }
        
        batchQueue.append(query)
        
        if batchQueue.count >= configuration.maxBatchSize {
            await processBatch()
        }
    }
    
    public func getMetrics() -> GraphQLMetrics {
        metrics
    }
    
    public func clearCache() {
        queryCache.removeAll()
    }
    
    public func invalidateCache(for pattern: String) {
        for (key, _) in queryCache {
            if key.contains(pattern) {
                queryCache.removeValue(forKey: key)
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func buildHTTPRequest(for query: GraphQLQuery) throws -> HTTPRequest {
        let bodyData = try JSONSerialization.data(withJSONObject: query.requestBody)
        
        var headers = configuration.headers
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        return HTTPRequest(
            url: configuration.endpoint,
            method: .POST,
            headers: headers,
            body: bodyData,
            timeout: configuration.timeout
        )
    }
    
    private func buildBatchHTTPRequest(for batch: GraphQLBatch) throws -> HTTPRequest {
        let bodyData = try JSONSerialization.data(withJSONObject: batch.requestBody)
        
        var headers = configuration.headers
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        return HTTPRequest(
            url: configuration.endpoint,
            method: .POST,
            headers: headers,
            body: bodyData,
            timeout: configuration.timeout
        )
    }
    
    private func parseResponse<T: Codable>(
        httpResponse: HTTPResponse,
        responseType: T.Type,
        query: GraphQLQuery,
        duration: TimeInterval
    ) throws -> GraphQLResponse<T> {
        let json = try JSONSerialization.jsonObject(with: httpResponse.data) as? [String: Any]
        
        guard let json = json else {
            throw GraphQLError.invalidResponse("Invalid JSON response")
        }
        
        let data: T?
        if let dataJson = json["data"] {
            let dataData = try JSONSerialization.data(withJSONObject: dataJson)
            data = try JSONDecoder().decode(responseType, from: dataData)
        } else {
            data = nil
        }
        
        let errors: [GraphQLError]?
        if let errorsJson = json["errors"] as? [[String: Any]] {
            errors = try errorsJson.map { errorJson in
                let errorData = try JSONSerialization.data(withJSONObject: errorJson)
                return try JSONDecoder().decode(GraphQLError.self, from: errorData)
            }
        } else {
            errors = nil
        }
        
        let extensions: [String: AnyCodable]?
        if let extensionsJson = json["extensions"] as? [String: Any] {
            extensions = try extensionsJson.mapValues { value in
                let valueData = try JSONSerialization.data(withJSONObject: value)
                return try JSONDecoder().decode(AnyCodable.self, from: valueData)
            }
        } else {
            extensions = nil
        }
        
        return GraphQLResponse(
            data: data,
            errors: errors,
            extensions: extensions,
            fromCache: false,
            duration: duration,
            operationType: query.operationType,
            operationName: query.operationName
        )
    }
    
    private func parseBatchResponse(
        httpResponse: HTTPResponse,
        batch: GraphQLBatch,
        duration: TimeInterval
    ) throws -> [GraphQLResponse<AnyCodable>] {
        let json = try JSONSerialization.jsonObject(with: httpResponse.data) as? [[String: Any]]
        
        guard let json = json else {
            throw GraphQLError.invalidResponse("Invalid batch JSON response")
        }
        
        return try zip(json, batch.queries).map { (responseJson, query) in
            let data: AnyCodable?
            if let dataJson = responseJson["data"] {
                let dataData = try JSONSerialization.data(withJSONObject: dataJson)
                data = try JSONDecoder().decode(AnyCodable.self, from: dataData)
            } else {
                data = nil
            }
            
            let errors: [GraphQLError]?
            if let errorsJson = responseJson["errors"] as? [[String: Any]] {
                errors = try errorsJson.map { errorJson in
                    let errorData = try JSONSerialization.data(withJSONObject: errorJson)
                    return try JSONDecoder().decode(GraphQLError.self, from: errorData)
                }
            } else {
                errors = nil
            }
            
            return GraphQLResponse<AnyCodable>(
                data: data,
                errors: errors,
                duration: duration / Double(batch.queries.count), // Distribute duration
                operationType: query.operationType,
                operationName: query.operationName
            )
        }
    }
    
    private func getCachedResponse<T: Codable>(
        for query: GraphQLQuery,
        responseType: T.Type
    ) -> GraphQLResponse<T>? {
        let cacheKey = query.computedCacheKey
        guard let entry = queryCache[cacheKey], !entry.isExpired else {
            if queryCache[cacheKey]?.isExpired == true {
                queryCache.removeValue(forKey: cacheKey)
            }
            return nil
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: entry.data) as? [String: Any]
            guard let json = json, let dataJson = json["data"] else { return nil }
            
            let dataData = try JSONSerialization.data(withJSONObject: dataJson)
            let data = try JSONDecoder().decode(responseType, from: dataData)
            
            return GraphQLResponse(
                data: data,
                fromCache: true,
                operationType: query.operationType,
                operationName: query.operationName
            )
        } catch {
            queryCache.removeValue(forKey: cacheKey)
            return nil
        }
    }
    
    private func cacheResponse(for query: GraphQLQuery, data: Data) {
        let cacheKey = query.computedCacheKey
        let ttl = query.cacheTTL ?? configuration.cacheTTL
        
        queryCache[cacheKey] = GraphQLCacheEntry(
            data: data,
            timestamp: Date(),
            ttl: ttl,
            operationType: query.operationType
        )
        
        // Simple cache size management
        if queryCache.count > configuration.maxCacheSize {
            let oldestKey = queryCache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let key = oldestKey {
                queryCache.removeValue(forKey: key)
            }
        }
    }
    
    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: configuration.batchInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.processBatch()
            }
        }
    }
    
    private func processBatch() async {
        guard !batchQueue.isEmpty else { return }
        
        let queries = Array(batchQueue)
        batchQueue.removeAll()
        
        let batch = GraphQLBatch(queries: queries)
        
        do {
            _ = try await executeBatch(batch)
        } catch {
            // Handle batch execution error
            if configuration.enableLogging {
                print("[GraphQL] Batch execution failed: \(error)")
            }
        }
    }
    
    private func startSubscription(query: GraphQLQuery, subscriptionId: String) async {
        guard let wsClient = webSocketClient else { return }
        
        do {
            try await wsClient.connect()
            
            // Send subscription start message
            let startMessage = GraphQLSubscriptionMessage(
                id: subscriptionId,
                type: "start",
                payload: query.requestBody
            )
            
            let messageData = try JSONSerialization.data(withJSONObject: [
                "id": startMessage.id as Any,
                "type": startMessage.type,
                "payload": startMessage.payload as Any
            ])
            
            try await wsClient.sendData(messageData)
            
            // Listen for messages
            let eventStream = await wsClient.getEventStream()
            for await event in eventStream {
                switch event {
                case .message(let message):
                    switch message {
                    case .data(let data):
                        if let subscriptionMessage = parseSubscriptionMessage(data) {
                            if let continuation = subscriptions[subscriptionId] {
                                continuation.yield(subscriptionMessage)
                            }
                        }
                    default:
                        break
                    }
                case .disconnected:
                    subscriptions[subscriptionId]?.finish()
                    subscriptions.removeValue(forKey: subscriptionId)
                    break
                default:
                    break
                }
            }
        } catch {
            subscriptions[subscriptionId]?.finish()
            subscriptions.removeValue(forKey: subscriptionId)
        }
    }
    
    private func parseSubscriptionMessage(_ data: Data) -> GraphQLSubscriptionMessage? {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let json = json,
                  let type = json["type"] as? String else { return nil }
            
            return GraphQLSubscriptionMessage(
                id: json["id"] as? String,
                type: type,
                payload: json["payload"] as? [String: Any]
            )
        } catch {
            return nil
        }
    }
    
    private func updateMetrics(
        operationType: GraphQLOperationType,
        duration: TimeInterval,
        fromCache: Bool = false,
        hasErrors: Bool = false
    ) async {
        switch operationType {
        case .query:
            queryDurations.append(duration)
            metrics = GraphQLMetrics(
                totalQueries: metrics.totalQueries + 1,
                totalMutations: metrics.totalMutations,
                totalSubscriptions: metrics.totalSubscriptions,
                cacheHits: fromCache ? metrics.cacheHits + 1 : metrics.cacheHits,
                cacheMisses: fromCache ? metrics.cacheMisses : metrics.cacheMisses + 1,
                averageQueryDuration: queryDurations.reduce(0, +) / Double(queryDurations.count),
                averageMutationDuration: metrics.averageMutationDuration,
                errorCount: hasErrors ? metrics.errorCount + 1 : metrics.errorCount,
                batchCount: metrics.batchCount,
                subscriptionCount: metrics.subscriptionCount
            )
            
        case .mutation:
            mutationDurations.append(duration)
            metrics = GraphQLMetrics(
                totalQueries: metrics.totalQueries,
                totalMutations: metrics.totalMutations + 1,
                totalSubscriptions: metrics.totalSubscriptions,
                cacheHits: metrics.cacheHits,
                cacheMisses: metrics.cacheMisses,
                averageQueryDuration: metrics.averageQueryDuration,
                averageMutationDuration: mutationDurations.reduce(0, +) / Double(mutationDurations.count),
                errorCount: hasErrors ? metrics.errorCount + 1 : metrics.errorCount,
                batchCount: metrics.batchCount,
                subscriptionCount: metrics.subscriptionCount
            )
            
        case .subscription:
            metrics = GraphQLMetrics(
                totalQueries: metrics.totalQueries,
                totalMutations: metrics.totalMutations,
                totalSubscriptions: metrics.totalSubscriptions + 1,
                cacheHits: metrics.cacheHits,
                cacheMisses: metrics.cacheMisses,
                averageQueryDuration: metrics.averageQueryDuration,
                averageMutationDuration: metrics.averageMutationDuration,
                errorCount: hasErrors ? metrics.errorCount + 1 : metrics.errorCount,
                batchCount: metrics.batchCount,
                subscriptionCount: metrics.subscriptionCount + 1
            )
        }
    }
    
    private func updateBatchMetrics(
        batch: GraphQLBatch,
        duration: TimeInterval,
        responses: [GraphQLResponse<AnyCodable>]
    ) async {
        let errorCount = responses.filter { $0.hasErrors }.count
        
        metrics = GraphQLMetrics(
            totalQueries: metrics.totalQueries,
            totalMutations: metrics.totalMutations,
            totalSubscriptions: metrics.totalSubscriptions,
            cacheHits: metrics.cacheHits,
            cacheMisses: metrics.cacheMisses,
            averageQueryDuration: metrics.averageQueryDuration,
            averageMutationDuration: metrics.averageMutationDuration,
            errorCount: metrics.errorCount + errorCount,
            batchCount: metrics.batchCount + 1,
            subscriptionCount: metrics.subscriptionCount
        )
    }
}

// MARK: - GraphQL Capability Implementation

/// GraphQL capability providing GraphQL client with caching
public actor GraphQLCapability: DomainCapability {
    public typealias ConfigurationType = GraphQLCapabilityConfiguration
    public typealias ResourceType = GraphQLCapabilityResource
    
    private var _configuration: GraphQLCapabilityConfiguration
    private var _resources: GraphQLCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "graphql-capability" }
    
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
    
    public var configuration: GraphQLCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: GraphQLCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: GraphQLCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = GraphQLCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: GraphQLCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid GraphQL configuration")
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
        // GraphQL is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // GraphQL doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - GraphQL Operations
    
    /// Execute GraphQL query
    public func query<T: Codable>(
        _ queryString: String,
        variables: [String: Any]? = nil,
        operationName: String? = nil,
        cacheKey: String? = nil,
        responseType: T.Type
    ) async throws -> GraphQLResponse<T> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("GraphQL capability not available")
        }
        
        let query = GraphQLQuery(
            operationType: .query,
            operationName: operationName,
            query: queryString,
            variables: variables,
            cacheKey: cacheKey
        )
        
        return try await _resources.executeQuery(query, responseType: responseType)
    }
    
    /// Execute GraphQL mutation
    public func mutation<T: Codable>(
        _ mutationString: String,
        variables: [String: Any]? = nil,
        operationName: String? = nil,
        responseType: T.Type
    ) async throws -> GraphQLResponse<T> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("GraphQL capability not available")
        }
        
        let mutation = GraphQLQuery(
            operationType: .mutation,
            operationName: operationName,
            query: mutationString,
            variables: variables
        )
        
        return try await _resources.executeQuery(mutation, responseType: responseType)
    }
    
    /// Start GraphQL subscription
    public func subscription(
        _ subscriptionString: String,
        variables: [String: Any]? = nil,
        operationName: String? = nil
    ) async throws -> AsyncStream<GraphQLSubscriptionMessage> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("GraphQL capability not available")
        }
        
        let subscription = GraphQLQuery(
            operationType: .subscription,
            operationName: operationName,
            query: subscriptionString,
            variables: variables
        )
        
        return await _resources.subscribe(subscription)
    }
    
    /// Execute batch queries
    public func batch(_ queries: [GraphQLQuery]) async throws -> [GraphQLResponse<AnyCodable>] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("GraphQL capability not available")
        }
        
        let batch = GraphQLBatch(queries: queries)
        return try await _resources.executeBatch(batch)
    }
    
    /// Add query to batch queue
    public func addToBatch(_ query: GraphQLQuery) async {
        await _resources.addToBatch(query)
    }
    
    /// Get GraphQL metrics
    public func getMetrics() async -> GraphQLMetrics {
        await _resources.getMetrics()
    }
    
    /// Clear query cache
    public func clearCache() async {
        await _resources.clearCache()
    }
    
    /// Invalidate cache entries matching pattern
    public func invalidateCache(for pattern: String) async {
        await _resources.invalidateCache(for: pattern)
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// GraphQL specific errors
public enum GraphQLError: Error, LocalizedError {
    case clientNotAvailable
    case invalidResponse(String)
    case serverError([GraphQLError])
    case networkError(Error)
    case subscriptionNotSupported
    case batchingNotSupported
    case cacheError(String)
    case validationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .clientNotAvailable:
            return "GraphQL client is not available"
        case .invalidResponse(let message):
            return "Invalid GraphQL response: \(message)"
        case .serverError(let errors):
            return "GraphQL server errors: \(errors.map { $0.message }.joined(separator: ", "))"
        case .networkError(let error):
            return "GraphQL network error: \(error.localizedDescription)"
        case .subscriptionNotSupported:
            return "GraphQL subscriptions are not supported or enabled"
        case .batchingNotSupported:
            return "GraphQL batching is not supported or enabled"
        case .cacheError(let message):
            return "GraphQL cache error: \(message)"
        case .validationError(let message):
            return "GraphQL validation error: \(message)"
        }
    }
}

// MARK: - Extensions

extension String {
    var sha256: String {
        // Simple hash implementation for cache keys
        let data = self.data(using: .utf8) ?? Data()
        return data.base64EncodedString()
    }
}