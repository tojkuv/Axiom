import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - JSON-RPC Capability Configuration

/// Configuration for JSON-RPC capability
public struct JSONRPCCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let serverURL: URL
    public let rpcVersion: String
    public let timeout: TimeInterval
    public let retryCount: Int
    public let retryDelay: TimeInterval
    public let enableBatching: Bool
    public let maxBatchSize: Int
    public let enableNotifications: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let customHeaders: [String: String]
    public let authenticationMethod: AuthenticationMethod
    public let enableRequestValidation: Bool
    public let enableResponseValidation: Bool
    
    public enum AuthenticationMethod: String, Codable, CaseIterable {
        case none = "none"
        case basic = "basic"
        case bearer = "bearer"
        case apiKey = "api-key"
        case custom = "custom"
    }
    
    public init(
        serverURL: URL,
        rpcVersion: String = "2.0",
        timeout: TimeInterval = 30.0,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0,
        enableBatching: Bool = true,
        maxBatchSize: Int = 10,
        enableNotifications: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        customHeaders: [String: String] = [:],
        authenticationMethod: AuthenticationMethod = .none,
        enableRequestValidation: Bool = true,
        enableResponseValidation: Bool = true
    ) {
        self.serverURL = serverURL
        self.rpcVersion = rpcVersion
        self.timeout = timeout
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        self.enableBatching = enableBatching
        self.maxBatchSize = maxBatchSize
        self.enableNotifications = enableNotifications
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.customHeaders = customHeaders
        self.authenticationMethod = authenticationMethod
        self.enableRequestValidation = enableRequestValidation
        self.enableResponseValidation = enableResponseValidation
    }
    
    public var isValid: Bool {
        timeout > 0 && retryCount >= 0 && retryDelay >= 0 && maxBatchSize > 0
    }
    
    public func merged(with other: JSONRPCCapabilityConfiguration) -> JSONRPCCapabilityConfiguration {
        JSONRPCCapabilityConfiguration(
            serverURL: other.serverURL,
            rpcVersion: other.rpcVersion,
            timeout: other.timeout,
            retryCount: other.retryCount,
            retryDelay: other.retryDelay,
            enableBatching: other.enableBatching,
            maxBatchSize: other.maxBatchSize,
            enableNotifications: other.enableNotifications,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            customHeaders: customHeaders.merging(other.customHeaders) { _, new in new },
            authenticationMethod: other.authenticationMethod,
            enableRequestValidation: other.enableRequestValidation,
            enableResponseValidation: other.enableResponseValidation
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> JSONRPCCapabilityConfiguration {
        var adjustedTimeout = timeout
        var adjustedRetries = retryCount
        var adjustedLogging = enableLogging
        var adjustedBatchSize = maxBatchSize
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 1.5
            adjustedRetries = min(retryCount, 1)
            adjustedBatchSize = min(maxBatchSize, 3)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return JSONRPCCapabilityConfiguration(
            serverURL: serverURL,
            rpcVersion: rpcVersion,
            timeout: adjustedTimeout,
            retryCount: adjustedRetries,
            retryDelay: retryDelay,
            enableBatching: enableBatching,
            maxBatchSize: adjustedBatchSize,
            enableNotifications: enableNotifications,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            customHeaders: customHeaders,
            authenticationMethod: authenticationMethod,
            enableRequestValidation: enableRequestValidation,
            enableResponseValidation: enableResponseValidation
        )
    }
}

// MARK: - JSON-RPC Types

/// JSON-RPC request
public struct JSONRPCRequest: Sendable, Codable {
    public let jsonrpc: String
    public let method: String
    public let params: JSONRPCParameters?
    public let id: JSONRPCId?
    
    public init(method: String, params: JSONRPCParameters? = nil, id: JSONRPCId? = nil, jsonrpc: String = "2.0") {
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
        self.id = id
    }
    
    /// Convenience initializer for notification (no id)
    public static func notification(method: String, params: JSONRPCParameters? = nil) -> JSONRPCRequest {
        JSONRPCRequest(method: method, params: params, id: nil)
    }
    
    /// Check if this is a notification
    public var isNotification: Bool {
        id == nil
    }
}

/// JSON-RPC response
public struct JSONRPCResponse: Sendable, Codable {
    public let jsonrpc: String
    public let result: AnyCodable?
    public let error: JSONRPCError?
    public let id: JSONRPCId?
    
    public init(result: AnyCodable? = nil, error: JSONRPCError? = nil, id: JSONRPCId? = nil, jsonrpc: String = "2.0") {
        self.jsonrpc = jsonrpc
        self.result = result
        self.error = error
        self.id = id
    }
}

/// JSON-RPC batch request
public struct JSONRPCBatchRequest: Sendable, Codable {
    public let requests: [JSONRPCRequest]
    
    public init(requests: [JSONRPCRequest]) {
        self.requests = requests
    }
}

/// JSON-RPC batch response
public struct JSONRPCBatchResponse: Sendable, Codable {
    public let responses: [JSONRPCResponse]
    
    public init(responses: [JSONRPCResponse]) {
        self.responses = responses
    }
}

/// JSON-RPC parameters
public enum JSONRPCParameters: Sendable, Codable {
    case array([AnyCodable])
    case object([String: AnyCodable])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let arrayValue = try? container.decode([AnyCodable].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: AnyCodable].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.typeMismatch(JSONRPCParameters.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected array or object"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

/// JSON-RPC identifier
public enum JSONRPCId: Sendable, Codable, Hashable {
    case string(String)
    case number(Int)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let numberValue = try? container.decode(Int.self) {
            self = .number(numberValue)
        } else {
            throw DecodingError.typeMismatch(JSONRPCId.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string, number, or null"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let string):
            try container.encode(string)
        case .number(let number):
            try container.encode(number)
        case .null:
            try container.encodeNil()
        }
    }
}

/// JSON-RPC error
public struct JSONRPCError: Sendable, Codable, Error {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
    
    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    // Standard JSON-RPC 2.0 errors
    public static let parseError = JSONRPCError(code: -32700, message: "Parse error")
    public static let invalidRequest = JSONRPCError(code: -32600, message: "Invalid Request")
    public static let methodNotFound = JSONRPCError(code: -32601, message: "Method not found")
    public static let invalidParams = JSONRPCError(code: -32602, message: "Invalid params")
    public static let internalError = JSONRPCError(code: -32603, message: "Internal error")
}

/// Type-erased Codable value
public struct AnyCodable: Sendable, Codable {
    public let value: Any
    
    public init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else if let objectValue = try? container.decode([String: AnyCodable].self) {
            value = objectValue
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode AnyCodable"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [AnyCodable]:
            try container.encode(arrayValue)
        case let objectValue as [String: AnyCodable]:
            try container.encode(objectValue)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value of type \(type(of: value))"))
        }
    }
}

/// JSON-RPC call result
public struct JSONRPCResult<T: Codable>: Sendable {
    public let result: T?
    public let error: JSONRPCError?
    public let requestId: JSONRPCId?
    public let duration: TimeInterval
    
    public init(result: T? = nil, error: JSONRPCError? = nil, requestId: JSONRPCId? = nil, duration: TimeInterval = 0) {
        self.result = result
        self.error = error
        self.requestId = requestId
        self.duration = duration
    }
    
    public var isSuccess: Bool {
        error == nil && result != nil
    }
    
    public var isError: Bool {
        error != nil
    }
}

/// JSON-RPC metrics
public struct JSONRPCMetrics: Sendable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let totalBatchRequests: Int
    public let totalNotifications: Int
    public let averageResponseTime: TimeInterval
    public let errorsByCode: [Int: Int]
    public let methodCallCounts: [String: Int]
    
    public init(
        totalRequests: Int = 0,
        successfulRequests: Int = 0,
        failedRequests: Int = 0,
        totalBatchRequests: Int = 0,
        totalNotifications: Int = 0,
        averageResponseTime: TimeInterval = 0,
        errorsByCode: [Int: Int] = [:],
        methodCallCounts: [String: Int] = [:]
    ) {
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.totalBatchRequests = totalBatchRequests
        self.totalNotifications = totalNotifications
        self.averageResponseTime = averageResponseTime
        self.errorsByCode = errorsByCode
        self.methodCallCounts = methodCallCounts
    }
    
    public var successRate: Double {
        totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0
    }
}

// MARK: - JSON-RPC Resource

/// JSON-RPC resource management
public actor JSONRPCCapabilityResource: AxiomCapabilityResource {
    private let configuration: JSONRPCCapabilityConfiguration
    private var httpClient: HTTPClientCapability?
    private var requestIdCounter: Int = 0
    private var pendingRequests: [JSONRPCId: Date] = [:]
    private var batchQueue: [JSONRPCRequest] = []
    private var metrics: JSONRPCMetrics = JSONRPCMetrics()
    
    public init(configuration: JSONRPCCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxBatchSize * 100_000, // 100KB per request
            cpu: 2.0, // JSON serialization/deserialization
            bandwidth: configuration.maxBatchSize * 50_000, // 50KB per request
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            return ResourceUsage(
                memory: (pendingRequests.count + batchQueue.count) * 50_000,
                cpu: pendingRequests.isEmpty ? 0.1 : 1.0,
                bandwidth: pendingRequests.isEmpty ? 0 : 25_000,
                storage: 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        httpClient != nil
    }
    
    public func release() async {
        await httpClient?.deactivate()
        httpClient = nil
        pendingRequests.removeAll()
        batchQueue.removeAll()
        metrics = JSONRPCMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize HTTP client for JSON-RPC communication
        let httpConfig = HTTPClientCapabilityConfiguration(
            timeout: configuration.timeout,
            retryCount: configuration.retryCount,
            retryDelay: configuration.retryDelay,
            enableLogging: configuration.enableLogging,
            enableMetrics: configuration.enableMetrics
        )
        
        httpClient = HTTPClientCapability(configuration: httpConfig)
        try await httpClient?.activate()
    }
    
    internal func updateConfiguration(_ configuration: JSONRPCCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - JSON-RPC Operations
    
    public func call<T: Codable>(
        method: String,
        params: JSONRPCParameters? = nil,
        responseType: T.Type
    ) async throws -> JSONRPCResult<T> {
        
        guard let httpClient = httpClient else {
            throw JSONRPCError.internalError
        }
        
        let startTime = Date()
        let requestId = JSONRPCId.number(generateRequestId())
        let request = JSONRPCRequest(method: method, params: params, id: requestId)
        
        pendingRequests[requestId] = startTime
        defer { pendingRequests.removeValue(forKey: requestId) }
        
        do {
            let response = try await sendSingleRequest(request, using: httpClient)
            let duration = Date().timeIntervalSince(startTime)
            
            if let error = response.error {
                await updateMetrics(success: false, duration: duration, error: error)
                return JSONRPCResult<T>(error: error, requestId: requestId, duration: duration)
            }
            
            guard let resultData = response.result else {
                let error = JSONRPCError.internalError
                await updateMetrics(success: false, duration: duration, error: error)
                return JSONRPCResult<T>(error: error, requestId: requestId, duration: duration)
            }
            
            // Decode the result
            let result = try decodeResult(resultData, to: responseType)
            await updateMetrics(success: true, duration: duration, method: method)
            
            return JSONRPCResult<T>(result: result, requestId: requestId, duration: duration)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let rpcError = error as? JSONRPCError ?? JSONRPCError.internalError
            await updateMetrics(success: false, duration: duration, error: rpcError)
            return JSONRPCResult<T>(error: rpcError, requestId: requestId, duration: duration)
        }
    }
    
    public func notify(method: String, params: JSONRPCParameters? = nil) async throws {
        guard let httpClient = httpClient else {
            throw JSONRPCError.internalError
        }
        
        guard configuration.enableNotifications else {
            throw JSONRPCError(code: -32000, message: "Notifications disabled")
        }
        
        let notification = JSONRPCRequest.notification(method: method, params: params)
        
        if configuration.enableBatching && batchQueue.count < configuration.maxBatchSize {
            batchQueue.append(notification)
            
            if batchQueue.count >= configuration.maxBatchSize {
                try await flushBatch(using: httpClient)
            }
        } else {
            _ = try await sendSingleRequest(notification, using: httpClient)
        }
        
        await updateNotificationMetrics(method: method)
    }
    
    public func batchCall<T: Codable>(
        requests: [(method: String, params: JSONRPCParameters?, responseType: T.Type)]
    ) async throws -> [JSONRPCResult<T>] {
        
        guard configuration.enableBatching else {
            throw JSONRPCError(code: -32000, message: "Batching disabled")
        }
        
        guard let httpClient = httpClient else {
            throw JSONRPCError.internalError
        }
        
        let startTime = Date()
        var rpcRequests: [JSONRPCRequest] = []
        var requestMap: [JSONRPCId: T.Type] = [:]
        
        for (method, params, responseType) in requests {
            let requestId = JSONRPCId.number(generateRequestId())
            let request = JSONRPCRequest(method: method, params: params, id: requestId)
            rpcRequests.append(request)
            requestMap[requestId] = responseType
        }
        
        let batchRequest = JSONRPCBatchRequest(requests: rpcRequests)
        let batchResponse = try await sendBatchRequest(batchRequest, using: httpClient)
        let duration = Date().timeIntervalSince(startTime)
        
        var results: [JSONRPCResult<T>] = []
        
        for response in batchResponse.responses {
            guard let responseId = response.id,
                  let responseType = requestMap[responseId] else {
                let error = JSONRPCError.invalidRequest
                results.append(JSONRPCResult<T>(error: error, duration: duration))
                continue
            }
            
            if let error = response.error {
                results.append(JSONRPCResult<T>(error: error, requestId: responseId, duration: duration))
            } else if let resultData = response.result {
                do {
                    let result = try decodeResult(resultData, to: responseType)
                    results.append(JSONRPCResult<T>(result: result, requestId: responseId, duration: duration))
                } catch {
                    let rpcError = JSONRPCError.internalError
                    results.append(JSONRPCResult<T>(error: rpcError, requestId: responseId, duration: duration))
                }
            } else {
                let error = JSONRPCError.internalError
                results.append(JSONRPCResult<T>(error: error, requestId: responseId, duration: duration))
            }
        }
        
        await updateBatchMetrics(success: true, duration: duration, requestCount: requests.count)
        return results
    }
    
    public func flushBatch() async throws {
        guard let httpClient = httpClient else {
            throw JSONRPCError.internalError
        }
        
        try await flushBatch(using: httpClient)
    }
    
    public func getMetrics() async -> JSONRPCMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = JSONRPCMetrics()
    }
    
    // MARK: - Private Methods
    
    private func generateRequestId() -> Int {
        requestIdCounter += 1
        return requestIdCounter
    }
    
    private func sendSingleRequest(_ request: JSONRPCRequest, using httpClient: HTTPClientCapability) async throws -> JSONRPCResponse {
        var urlRequest = URLRequest(url: configuration.serverURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        addAuthenticationHeaders(to: &urlRequest)
        
        // Add custom headers
        for (key, value) in configuration.customHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Serialize request
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        if configuration.enableLogging {
            await logRequest(request)
        }
        
        // Send request
        let httpResponse = try await httpClient.execute(HTTPRequest(
            url: configuration.serverURL,
            method: .POST,
            headers: urlRequest.allHTTPHeaderFields ?? [:],
            body: requestData
        ))
        
        // Parse response
        let response = try JSONDecoder().decode(JSONRPCResponse.self, from: httpResponse.data)
        
        if configuration.enableLogging {
            await logResponse(response)
        }
        
        return response
    }
    
    private func sendBatchRequest(_ batchRequest: JSONRPCBatchRequest, using httpClient: HTTPClientCapability) async throws -> JSONRPCBatchResponse {
        var urlRequest = URLRequest(url: configuration.serverURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        addAuthenticationHeaders(to: &urlRequest)
        
        // Add custom headers
        for (key, value) in configuration.customHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Serialize batch request
        let requestData = try JSONEncoder().encode(batchRequest.requests)
        urlRequest.httpBody = requestData
        
        if configuration.enableLogging {
            await logBatchRequest(batchRequest)
        }
        
        // Send request
        let httpResponse = try await httpClient.execute(HTTPRequest(
            url: configuration.serverURL,
            method: .POST,
            headers: urlRequest.allHTTPHeaderFields ?? [:],
            body: requestData
        ))
        
        // Parse response
        let responses = try JSONDecoder().decode([JSONRPCResponse].self, from: httpResponse.data)
        let batchResponse = JSONRPCBatchResponse(responses: responses)
        
        if configuration.enableLogging {
            await logBatchResponse(batchResponse)
        }
        
        return batchResponse
    }
    
    private func flushBatch(using httpClient: HTTPClientCapability) async throws {
        guard !batchQueue.isEmpty else { return }
        
        let batch = JSONRPCBatchRequest(requests: batchQueue)
        batchQueue.removeAll()
        
        _ = try await sendBatchRequest(batch, using: httpClient)
    }
    
    private func addAuthenticationHeaders(to request: inout URLRequest) {
        switch configuration.authenticationMethod {
        case .none:
            break
        case .basic:
            // Would need credentials - placeholder implementation
            break
        case .bearer:
            // Would need token - placeholder implementation
            break
        case .apiKey:
            // Would need API key - placeholder implementation
            break
        case .custom:
            // Would use delegate pattern - placeholder implementation
            break
        }
    }
    
    private func decodeResult<T: Codable>(_ resultData: AnyCodable, to type: T.Type) throws -> T {
        // Convert AnyCodable back to Data and decode to target type
        let data = try JSONEncoder().encode(resultData)
        return try JSONDecoder().decode(type, from: data)
    }
    
    private func updateMetrics(success: Bool, duration: TimeInterval, method: String? = nil, error: JSONRPCError? = nil) async {
        var newMethodCounts = metrics.methodCallCounts
        var newErrorCounts = metrics.errorsByCode
        
        if let method = method {
            newMethodCounts[method, default: 0] += 1
        }
        
        if let error = error {
            newErrorCounts[error.code, default: 0] += 1
        }
        
        let totalRequests = metrics.totalRequests + 1
        let successfulRequests = metrics.successfulRequests + (success ? 1 : 0)
        let failedRequests = metrics.failedRequests + (success ? 0 : 1)
        
        // Calculate new average response time
        let newAverageResponseTime = ((metrics.averageResponseTime * Double(metrics.totalRequests)) + duration) / Double(totalRequests)
        
        metrics = JSONRPCMetrics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            totalBatchRequests: metrics.totalBatchRequests,
            totalNotifications: metrics.totalNotifications,
            averageResponseTime: newAverageResponseTime,
            errorsByCode: newErrorCounts,
            methodCallCounts: newMethodCounts
        )
    }
    
    private func updateNotificationMetrics(method: String) async {
        var newMethodCounts = metrics.methodCallCounts
        newMethodCounts[method, default: 0] += 1
        
        metrics = JSONRPCMetrics(
            totalRequests: metrics.totalRequests,
            successfulRequests: metrics.successfulRequests,
            failedRequests: metrics.failedRequests,
            totalBatchRequests: metrics.totalBatchRequests,
            totalNotifications: metrics.totalNotifications + 1,
            averageResponseTime: metrics.averageResponseTime,
            errorsByCode: metrics.errorsByCode,
            methodCallCounts: newMethodCounts
        )
    }
    
    private func updateBatchMetrics(success: Bool, duration: TimeInterval, requestCount: Int) async {
        let totalRequests = metrics.totalRequests + requestCount
        let successfulRequests = metrics.successfulRequests + (success ? requestCount : 0)
        let failedRequests = metrics.failedRequests + (success ? 0 : requestCount)
        
        // Calculate new average response time
        let newAverageResponseTime = ((metrics.averageResponseTime * Double(metrics.totalRequests)) + duration) / Double(totalRequests)
        
        metrics = JSONRPCMetrics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            totalBatchRequests: metrics.totalBatchRequests + 1,
            totalNotifications: metrics.totalNotifications,
            averageResponseTime: newAverageResponseTime,
            errorsByCode: metrics.errorsByCode,
            methodCallCounts: metrics.methodCallCounts
        )
    }
    
    private func logRequest(_ request: JSONRPCRequest) async {
        let type = request.isNotification ? "NOTIFICATION" : "REQUEST"
        print("[JSON-RPC] 📤 \(type): \(request.method) (id: \(request.id?.description ?? "nil"))")
    }
    
    private func logResponse(_ response: JSONRPCResponse) async {
        if let error = response.error {
            print("[JSON-RPC] ❌ ERROR: \(error.message) (code: \(error.code), id: \(response.id?.description ?? "nil"))")
        } else {
            print("[JSON-RPC] ✅ SUCCESS: (id: \(response.id?.description ?? "nil"))")
        }
    }
    
    private func logBatchRequest(_ batch: JSONRPCBatchRequest) async {
        print("[JSON-RPC] 📦 BATCH REQUEST: \(batch.requests.count) requests")
    }
    
    private func logBatchResponse(_ batch: JSONRPCBatchResponse) async {
        let errors = batch.responses.filter { $0.error != nil }
        print("[JSON-RPC] 📦 BATCH RESPONSE: \(batch.responses.count) responses (\(errors.count) errors)")
    }
}

// MARK: - JSON-RPC Capability Implementation

/// JSON-RPC capability providing JSON-RPC 2.0 client functionality
public actor JSONRPCCapability: DomainCapability {
    public typealias ConfigurationType = JSONRPCCapabilityConfiguration
    public typealias ResourceType = JSONRPCCapabilityResource
    
    private var _configuration: JSONRPCCapabilityConfiguration
    private var _resources: JSONRPCCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "jsonrpc-capability" }
    
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
    
    public var configuration: JSONRPCCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: JSONRPCCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: JSONRPCCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = JSONRPCCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: JSONRPCCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid JSON-RPC configuration")
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
        // JSON-RPC is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // JSON-RPC doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - JSON-RPC Operations
    
    /// Make a JSON-RPC call
    public func call<T: Codable>(
        method: String,
        params: JSONRPCParameters? = nil,
        responseType: T.Type
    ) async throws -> JSONRPCResult<T> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JSON-RPC capability not available")
        }
        
        return try await _resources.call(method: method, params: params, responseType: responseType)
    }
    
    /// Send a JSON-RPC notification
    public func notify(method: String, params: JSONRPCParameters? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JSON-RPC capability not available")
        }
        
        try await _resources.notify(method: method, params: params)
    }
    
    /// Make multiple JSON-RPC calls in a batch
    public func batchCall<T: Codable>(
        requests: [(method: String, params: JSONRPCParameters?, responseType: T.Type)]
    ) async throws -> [JSONRPCResult<T>] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JSON-RPC capability not available")
        }
        
        return try await _resources.batchCall(requests: requests)
    }
    
    /// Flush any queued notifications
    public func flushBatch() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JSON-RPC capability not available")
        }
        
        try await _resources.flushBatch()
    }
    
    /// Get JSON-RPC metrics
    public func getMetrics() async throws -> JSONRPCMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JSON-RPC capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JSON-RPC capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Call method with array parameters
    public func call<T: Codable>(
        method: String,
        params: [AnyCodable],
        responseType: T.Type
    ) async throws -> JSONRPCResult<T> {
        let rpcParams = JSONRPCParameters.array(params)
        return try await call(method: method, params: rpcParams, responseType: responseType)
    }
    
    /// Call method with object parameters
    public func call<T: Codable>(
        method: String,
        params: [String: AnyCodable],
        responseType: T.Type
    ) async throws -> JSONRPCResult<T> {
        let rpcParams = JSONRPCParameters.object(params)
        return try await call(method: method, params: rpcParams, responseType: responseType)
    }
    
    /// Call method with no parameters
    public func call<T: Codable>(
        method: String,
        responseType: T.Type
    ) async throws -> JSONRPCResult<T> {
        return try await call(method: method, params: nil, responseType: responseType)
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extensions

extension JSONRPCId: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let string):
            return string
        case .number(let number):
            return String(number)
        case .null:
            return "null"
        }
    }
}