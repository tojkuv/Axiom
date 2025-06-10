import Foundation
import SwiftUI
import CoreData
import CoreML
import AVFoundation
import Photos
import Network
import UserNotifications

// MARK: - Domain Capability Foundation

/// Base protocol for domain-specific capabilities with enhanced functionality
public protocol DomainCapability: ExtendedCapability {
    associatedtype ConfigurationType: CapabilityConfiguration
    associatedtype ResourceType: CapabilityResource
    
    /// Configuration for this capability
    var configuration: ConfigurationType { get async }
    
    /// Resources managed by this capability
    var resources: ResourceType { get async }
    
    /// Environment this capability is running in
    var environment: CapabilityEnvironment { get async }
    
    /// Update configuration at runtime
    func updateConfiguration(_ configuration: ConfigurationType) async throws
    
    /// Handle environment changes
    func handleEnvironmentChange(_ environment: CapabilityEnvironment) async
}

/// Configuration protocol for capabilities
public protocol CapabilityConfiguration: Codable, Sendable {
    /// Whether this configuration is valid
    var isValid: Bool { get }
    
    /// Merge with another configuration
    func merged(with other: Self) -> Self
    
    /// Environment-specific adjustments
    func adjusted(for environment: CapabilityEnvironment) -> Self
}

/// Resource protocol for capability resource management
public protocol CapabilityResource: Sendable {
    /// Current resource usage
    var currentUsage: ResourceUsage { get async }
    
    /// Maximum allowed usage
    var maxUsage: ResourceUsage { get }
    
    /// Whether resources are available
    var isAvailable: Bool { get async }
    
    /// Allocate resources
    func allocate() async throws
    
    /// Release resources
    func release() async
}

/// Environment types for capabilities
public enum CapabilityEnvironment: String, Codable, Sendable {
    case development
    case testing
    case staging
    case production
    case preview
    
    public var isProduction: Bool {
        self == .production
    }
    
    public var isDebug: Bool {
        self == .development || self == .testing
    }
}

/// Resource usage tracking
public struct ResourceUsage: Codable, Sendable {
    public let memoryBytes: Int64
    public let cpuPercentage: Double
    public let networkBytesPerSecond: Int64
    public let diskBytes: Int64
    
    public init(memory: Int64 = 0, cpu: Double = 0, network: Int64 = 0, disk: Int64 = 0) {
        self.memoryBytes = memory
        self.cpuPercentage = cpu
        self.networkBytesPerSecond = network
        self.diskBytes = disk
    }
    
    public func exceeds(_ limit: ResourceUsage) -> Bool {
        memoryBytes > limit.memoryBytes ||
        cpuPercentage > limit.cpuPercentage ||
        networkBytesPerSecond > limit.networkBytesPerSecond ||
        diskBytes > limit.diskBytes
    }
}

// MARK: - 1. Machine Learning / AI Capabilities

/// Configuration for ML capabilities
public struct MLCapabilityConfiguration: CapabilityConfiguration, Codable {
    public let modelName: String
    public let batchSize: Int
    // MVP: Removing non-Codable types
    // public let computeUnits: MLComputeUnits
    public let useMetalPerformanceShaders: Bool
    // public let cachePolicy: MLModelCachePolicy
    
    public init(
        modelName: String,
        batchSize: Int = 1,
        // computeUnits: MLComputeUnits = .all,
        useMetalPerformanceShaders: Bool = true
        // cachePolicy: MLModelCachePolicy = .auto
    ) {
        self.modelName = modelName
        self.batchSize = batchSize
        // self.computeUnits = computeUnits
        self.useMetalPerformanceShaders = useMetalPerformanceShaders
        // self.cachePolicy = cachePolicy
    }
    
    public var isValid: Bool {
        !modelName.isEmpty && batchSize > 0
    }
    
    public func merged(with other: MLCapabilityConfiguration) -> MLCapabilityConfiguration {
        MLCapabilityConfiguration(
            modelName: other.modelName.isEmpty ? self.modelName : other.modelName,
            batchSize: other.batchSize > 0 ? other.batchSize : self.batchSize,
            // computeUnits: other.computeUnits,
            useMetalPerformanceShaders: other.useMetalPerformanceShaders
            // cachePolicy: other.cachePolicy
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> MLCapabilityConfiguration {
        switch environment {
        case .development, .testing:
            return MLCapabilityConfiguration(
                modelName: modelName,
                batchSize: min(batchSize, 2), // Smaller batches for testing
                // computeUnits: .cpuOnly, // Use CPU for consistent testing
                useMetalPerformanceShaders: false
                // cachePolicy: .disable
            )
        case .production:
            return self
        case .staging:
            return MLCapabilityConfiguration(
                modelName: modelName,
                batchSize: batchSize,
                // computeUnits: .all,
                useMetalPerformanceShaders: useMetalPerformanceShaders
                // cachePolicy: .enable
            )
        case .preview:
            return MLCapabilityConfiguration(
                modelName: modelName,
                batchSize: 1,
                // computeUnits: .cpuOnly,
                useMetalPerformanceShaders: false
                // cachePolicy: .disable
            )
        }
    }
}

public enum MLModelCachePolicy: String, Codable {
    case auto
    case enable
    case disable
}

/// Resource management for ML capabilities
public actor MLCapabilityResource: CapabilityResource {
    private var model: MLModel?
    private var isModelLoaded = false
    private let configuration: MLCapabilityConfiguration
    
    public init(configuration: MLCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            // Estimate based on model size and configuration
            let memoryEstimate: Int64 = isModelLoaded ? 100_000_000 : 0 // 100MB when loaded
            let cpuEstimate = isModelLoaded ? 25.0 : 0.0 // 25% CPU when active
            return ResourceUsage(memory: memoryEstimate, cpu: cpuEstimate)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 500_000_000, cpu: 80.0) // 500MB, 80% CPU
    
    public var isAvailable: Bool {
        get async {
            await currentUsage.memoryBytes < maxUsage.memoryBytes
        }
    }
    
    public func allocate() async throws {
        guard !isModelLoaded else { return }
        
        // Load model configuration
        let modelConfiguration = MLModelConfiguration()
        // MVP: Using default compute units
        // modelConfiguration.computeUnits = configuration.computeUnits
        modelConfiguration.allowLowPrecisionAccumulationOnGPU = configuration.useMetalPerformanceShaders
        
        // Simulate model loading (in real implementation, load from bundle)
        try await Task.sleep(for: .milliseconds(100))
        
        // In real implementation:
        // let modelURL = Bundle.main.url(forResource: configuration.modelName, withExtension: "mlmodelc")!
        // self.model = try MLModel(contentsOf: modelURL, configuration: modelConfiguration)
        
        isModelLoaded = true
    }
    
    public func release() async {
        model = nil
        isModelLoaded = false
    }
}

/// ML/AI capability implementation
public actor MLCapability: DomainCapability {
    private var _configuration: MLCapabilityConfiguration
    private var _resources: MLCapabilityResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var predictionQueue: [any MLFeatureProvider] = []
    private var isProcessing = false
    
    public init(
        configuration: MLCapabilityConfiguration,
        environment: CapabilityEnvironment = .development
    ) {
        self._configuration = configuration
        self._resources = MLCapabilityResource(configuration: configuration)
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: MLCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: MLCapabilityResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: MLCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw CapabilityError.initializationFailed("Invalid ML configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        _resources = MLCapabilityResource(configuration: _configuration)
        
        if _state == .available {
            try await _resources.allocate()
        }
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                continuation.yield(_state)
                continuation.finish()
            }
        }
    }
    
    public func isSupported() async -> Bool {
        // Check if Core ML is available and model exists
        true // Simplified for example
    }
    
    public func requestPermission() async throws {
        // ML capabilities typically don't require explicit permissions
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func activate() async throws {
        _state = .unknown
        
        guard await isSupported() else {
            _state = .unavailable
            throw CapabilityError.notAvailable("Core ML not supported")
        }
        
        try await _resources.allocate()
        _state = .available
    }
    
    public func deactivate() async {
        await _resources.release()
        predictionQueue.removeAll()
        _state = .unavailable
    }
    
    // MARK: - ML-Specific Methods
    
    public func predict<Input, Output>(
        input: Input,
        outputType: Output.Type
    ) async throws -> Output where Input: MLFeatureProvider, Output: MLFeatureProvider {
        guard _state == .available else {
            throw CapabilityError.notAvailable("ML capability not available")
        }
        
        let request = MLPredictionRequest(input: input, priority: .userInitiated)
        return try await processPrediction(request, outputType: outputType)
    }
    
    public func batchPredict<Input, Output>(
        inputs: [Input],
        outputType: Output.Type
    ) async throws -> [Output] where Input: MLFeatureProvider, Output: MLFeatureProvider {
        guard _state == .available else {
            throw CapabilityError.notAvailable("ML capability not available")
        }
        
        var results: [Output] = []
        for input in inputs {
            let result = try await predict(input: input, outputType: outputType)
            results.append(result)
        }
        return results
    }
    
    private func processPrediction<Input, Output>(
        _ request: MLPredictionRequest<Input>,
        outputType: Output.Type
    ) async throws -> Output where Input: MLFeatureProvider, Output: MLFeatureProvider {
        // In real implementation, use the loaded ML model
        try await Task.sleep(for: .milliseconds(50)) // Simulate prediction time
        
        // Return mock result (in real implementation, use model.prediction)
        throw CapabilityError.initializationFailed("Mock implementation")
    }
}

/// Prediction request wrapper
private struct MLPredictionRequest<Input: MLFeatureProvider> {
    let input: Input
    let priority: TaskPriority
    let timestamp = Date()
}

// MARK: - 2. Payment Processing Capabilities

/// Payment capability configuration
public struct PaymentCapabilityConfiguration: CapabilityConfiguration, Codable {
    public let merchantId: String
    // MVP: Removing non-Codable types
    // public let supportedNetworks: [PKPaymentNetwork]
    // public let merchantCapabilities: PKMerchantCapability
    public let countryCode: String
    public let currencyCode: String
    public let sandboxMode: Bool
    public let applePayEnabled: Bool
    
    public init(
        merchantId: String,
        // supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex],
        // merchantCapabilities: PKMerchantCapability = [.capability3DS],
        countryCode: String = "US",
        currencyCode: String = "USD",
        sandboxMode: Bool = true,
        applePayEnabled: Bool = true
    ) {
        self.merchantId = merchantId
        // self.supportedNetworks = supportedNetworks
        // self.merchantCapabilities = merchantCapabilities
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.sandboxMode = sandboxMode
        self.applePayEnabled = applePayEnabled
    }
    
    public var isValid: Bool {
        !merchantId.isEmpty && !countryCode.isEmpty && !currencyCode.isEmpty
    }
    
    public func merged(with other: PaymentCapabilityConfiguration) -> PaymentCapabilityConfiguration {
        PaymentCapabilityConfiguration(
            merchantId: other.merchantId.isEmpty ? merchantId : other.merchantId,
            // supportedNetworks: other.supportedNetworks.isEmpty ? supportedNetworks : other.supportedNetworks,
            // merchantCapabilities: other.merchantCapabilities,
            countryCode: other.countryCode.isEmpty ? countryCode : other.countryCode,
            currencyCode: other.currencyCode.isEmpty ? currencyCode : other.currencyCode,
            sandboxMode: other.sandboxMode,
            applePayEnabled: other.applePayEnabled
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> PaymentCapabilityConfiguration {
        PaymentCapabilityConfiguration(
            merchantId: merchantId,
            // supportedNetworks: supportedNetworks,
            // merchantCapabilities: merchantCapabilities,
            countryCode: countryCode,
            currencyCode: currencyCode,
            sandboxMode: !environment.isProduction,
            applePayEnabled: applePayEnabled
        )
    }
}

/// Payment resource management
public actor PaymentCapabilityResource: CapabilityResource {
    private var paymentController: PKPaymentAuthorizationController?
    private let configuration: PaymentCapabilityConfiguration
    
    public init(configuration: PaymentCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            ResourceUsage(memory: 5_000_000) // 5MB for payment UI
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 20_000_000) // 20MB max
    
    public var isAvailable: Bool {
        get async {
            // MVP: Using default supported networks
            let defaultNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex]
            return PKPaymentAuthorizationController.canMakePayments(usingNetworks: defaultNetworks)
        }
    }
    
    public func allocate() async throws {
        guard await isAvailable else {
            throw CapabilityError.notAvailable("Apple Pay not available")
        }
    }
    
    public func release() async {
        paymentController = nil
    }
}

/// Payment capability implementation
public actor PaymentCapability: DomainCapability {
    private var _configuration: PaymentCapabilityConfiguration
    private var _resources: PaymentCapabilityResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    
    public init(
        configuration: PaymentCapabilityConfiguration,
        environment: CapabilityEnvironment = .development
    ) {
        self._configuration = configuration
        self._resources = PaymentCapabilityResource(configuration: configuration)
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: PaymentCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: PaymentCapabilityResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: PaymentCapabilityConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = PaymentCapabilityResource(configuration: _configuration)
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                continuation.yield(_state)
                continuation.finish()
            }
        }
    }
    
    public func isSupported() async -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }
    
    public func requestPermission() async throws {
        // Payment capabilities use system authorization
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func activate() async throws {
        guard await isSupported() else {
            _state = .unavailable
            throw CapabilityError.notAvailable("Apple Pay not supported")
        }
        
        try await _resources.allocate()
        _state = .available
    }
    
    public func deactivate() async {
        await _resources.release()
        _state = .unavailable
    }
    
    // MARK: - Payment-Specific Methods
    
    public func processPayment(
        amount: Decimal,
        description: String,
        shippingType: PKShippingType = .shipping
    ) async throws -> PaymentResult {
        guard _state == .available else {
            throw CapabilityError.notAvailable("Payment capability not available")
        }
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = _configuration.merchantId
        // MVP: Using default values
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = [.capability3DS]
        request.countryCode = _configuration.countryCode
        request.currencyCode = _configuration.currencyCode
        request.shippingType = shippingType
        
        let summaryItem = PKPaymentSummaryItem(
            label: description,
            amount: NSDecimalNumber(decimal: amount)
        )
        request.paymentSummaryItems = [summaryItem]
        
        // In real implementation, present payment authorization controller
        // For now, simulate processing
        try await Task.sleep(for: .seconds(2))
        
        return PaymentResult(
            status: .success,
            transactionId: UUID().uuidString,
            amount: amount,
            currency: _configuration.currencyCode
        )
    }
    
    public func validateMerchant() async throws -> Bool {
        // Validate merchant configuration
        return _configuration.isValid
    }
}

/// Payment processing result
public struct PaymentResult: Codable, Sendable {
    public enum Status: String, Codable {
        case success
        case failed
        case cancelled
        case pending
    }
    
    public let status: Status
    public let transactionId: String
    public let amount: Decimal
    public let currency: String
    public let timestamp = Date()
    
    public init(status: Status, transactionId: String, amount: Decimal, currency: String) {
        self.status = status
        self.transactionId = transactionId
        self.amount = amount
        self.currency = currency
    }
}

// MARK: - 3. Analytics and Tracking Capabilities

/// Analytics configuration
public struct AnalyticsCapabilityConfiguration: CapabilityConfiguration {
    public let trackingId: String
    public let batchSize: Int
    public let flushInterval: TimeInterval
    public let enableDebugLogging: Bool
    public let enableCrashReporting: Bool
    public let enablePerformanceMonitoring: Bool
    public let samplingRate: Double
    public let endpoint: URL?
    
    public init(
        trackingId: String,
        batchSize: Int = 20,
        flushInterval: TimeInterval = 30,
        enableDebugLogging: Bool = false,
        enableCrashReporting: Bool = true,
        enablePerformanceMonitoring: Bool = true,
        samplingRate: Double = 1.0,
        endpoint: URL? = nil
    ) {
        self.trackingId = trackingId
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.enableDebugLogging = enableDebugLogging
        self.enableCrashReporting = enableCrashReporting
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.samplingRate = samplingRate
        self.endpoint = endpoint
    }
    
    public var isValid: Bool {
        !trackingId.isEmpty && batchSize > 0 && samplingRate >= 0 && samplingRate <= 1
    }
    
    public func merged(with other: AnalyticsCapabilityConfiguration) -> AnalyticsCapabilityConfiguration {
        AnalyticsCapabilityConfiguration(
            trackingId: other.trackingId.isEmpty ? trackingId : other.trackingId,
            batchSize: other.batchSize > 0 ? other.batchSize : batchSize,
            flushInterval: other.flushInterval > 0 ? other.flushInterval : flushInterval,
            enableDebugLogging: other.enableDebugLogging,
            enableCrashReporting: other.enableCrashReporting,
            enablePerformanceMonitoring: other.enablePerformanceMonitoring,
            samplingRate: other.samplingRate,
            endpoint: other.endpoint ?? endpoint
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> AnalyticsCapabilityConfiguration {
        AnalyticsCapabilityConfiguration(
            trackingId: trackingId,
            batchSize: environment.isDebug ? min(batchSize, 5) : batchSize,
            flushInterval: environment.isDebug ? min(flushInterval, 10) : flushInterval,
            enableDebugLogging: environment.isDebug,
            enableCrashReporting: environment.isProduction,
            enablePerformanceMonitoring: environment.isProduction,
            samplingRate: environment.isDebug ? 1.0 : samplingRate,
            endpoint: endpoint
        )
    }
}

/// Analytics resource management
public actor AnalyticsCapabilityResource: CapabilityResource {
    private var eventQueue: [AnalyticsEvent] = []
    private var uploadTask: Task<Void, Never>?
    private let configuration: AnalyticsCapabilityConfiguration
    
    public init(configuration: AnalyticsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let memoryBytes = Int64(eventQueue.count * 1000) // Estimate 1KB per event
            let networkBytes = uploadTask != nil ? Int64(10000) : 0 // 10KB/s when uploading
            return ResourceUsage(memory: memoryBytes, network: networkBytes)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 10_000_000, network: 100_000) // 10MB, 100KB/s
    
    public var isAvailable: Bool {
        get async {
            let usage = await currentUsage
            return !usage.exceeds(maxUsage)
        }
    }
    
    public func allocate() async throws {
        // Initialize analytics storage
        eventQueue.reserveCapacity(configuration.batchSize * 2)
    }
    
    public func release() async {
        uploadTask?.cancel()
        uploadTask = nil
        eventQueue.removeAll()
    }
    
    func addEvent(_ event: AnalyticsEvent) async {
        eventQueue.append(event)
        
        if eventQueue.count >= configuration.batchSize {
            await flushEvents()
        }
    }
    
    func flushEvents() async {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToUpload = eventQueue
        eventQueue.removeAll()
        
        uploadTask = Task {
            // Simulate upload
            try? await Task.sleep(for: .seconds(1))
            // In real implementation, send to analytics endpoint
        }
        
        await uploadTask?.value
        uploadTask = nil
    }
}

/// Analytics capability implementation
public actor AnalyticsCapability: DomainCapability {
    private var _configuration: AnalyticsCapabilityConfiguration
    private var _resources: AnalyticsCapabilityResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var flushTimer: Task<Void, Never>?
    
    public init(
        configuration: AnalyticsCapabilityConfiguration,
        environment: CapabilityEnvironment = .development
    ) {
        self._configuration = configuration
        self._resources = AnalyticsCapabilityResource(configuration: configuration)
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: AnalyticsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: AnalyticsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: AnalyticsCapabilityConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = AnalyticsCapabilityResource(configuration: _configuration)
        await startFlushTimer()
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                continuation.yield(_state)
                continuation.finish()
            }
        }
    }
    
    public func isSupported() async -> Bool {
        true // Analytics always supported
    }
    
    public func requestPermission() async throws {
        // Analytics may require tracking permission in some regions
        if #available(iOS 14, *) {
            // In real implementation, request ATTrackingManager permission
        }
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func activate() async throws {
        try await _resources.allocate()
        await startFlushTimer()
        _state = .available
    }
    
    public func deactivate() async {
        await _resources.flushEvents() // Flush remaining events
        await _resources.release()
        flushTimer?.cancel()
        flushTimer = nil
        _state = .unavailable
    }
    
    // MARK: - Analytics-Specific Methods
    
    public func track(event: String, properties: [String: Any] = [:]) async {
        guard _state == .available else { return }
        
        // Apply sampling
        guard Double.random(in: 0...1) <= _configuration.samplingRate else { return }
        
        let analyticsEvent = AnalyticsEvent(
            name: event,
            properties: properties,
            timestamp: Date(),
            sessionId: await getCurrentSessionId()
        )
        
        await _resources.addEvent(analyticsEvent)
        
        if _configuration.enableDebugLogging {
            print("[Analytics] \(event): \(properties)")
        }
    }
    
    public func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) async {
        var screenProperties = properties
        screenProperties["screen_name"] = screenName
        await track(event: "screen_view", properties: screenProperties)
    }
    
    public func trackUserAction(_ action: String, target: String?, properties: [String: Any] = [:]) async {
        var actionProperties = properties
        actionProperties["action"] = action
        if let target = target {
            actionProperties["target"] = target
        }
        await track(event: "user_action", properties: actionProperties)
    }
    
    public func flush() async {
        await _resources.flushEvents()
    }
    
    private func startFlushTimer() async {
        flushTimer?.cancel()
        flushTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?._configuration.flushInterval ?? 30))
                await self?._resources.flushEvents()
            }
        }
    }
    
    private func getCurrentSessionId() async -> String {
        // In real implementation, maintain session management
        "session-\(UUID().uuidString)"
    }
}

/// Analytics event structure
public struct AnalyticsEvent: Codable, Sendable {
    public let name: String
    public let properties: [String: AnyCodable]
    public let timestamp: Date
    public let sessionId: String
    
    public init(name: String, properties: [String: Any], timestamp: Date, sessionId: String) {
        self.name = name
        self.properties = properties.mapValues { AnyCodable($0) }
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
}

/// Helper for encoding Any values
public struct AnyCodable: Codable, Sendable {
    public let value: Any
    
    public init(_ value: Any) {
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
            value = ""
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
            try container.encode(String(describing: value))
        }
    }
}

// MARK: - PassKit Import for Payment Types

#if canImport(PassKit)
import PassKit
#else
// Mock PKPaymentNetwork for platforms without PassKit
public struct PKPaymentNetwork: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let visa = PKPaymentNetwork(rawValue: "Visa")
    public static let masterCard = PKPaymentNetwork(rawValue: "MasterCard")
    public static let amex = PKPaymentNetwork(rawValue: "Amex")
}

public struct PKMerchantCapability: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let capability3DS = PKMerchantCapability(rawValue: 1 << 0)
}

public enum PKShippingType: Int, Sendable {
    case shipping
    case delivery
    case storePickup
    case servicePickup
}

public class PKPaymentRequest: Sendable {
    public var merchantIdentifier: String = ""
    public var supportedNetworks: [PKPaymentNetwork] = []
    public var merchantCapabilities: PKMerchantCapability = []
    public var countryCode: String = ""
    public var currencyCode: String = ""
    public var shippingType: PKShippingType = .shipping
    public var paymentSummaryItems: [PKPaymentSummaryItem] = []
}

public class PKPaymentSummaryItem: Sendable {
    public let label: String
    public let amount: NSDecimalNumber
    
    public init(label: String, amount: NSDecimalNumber) {
        self.label = label
        self.amount = amount
    }
}

public class PKPaymentAuthorizationController: Sendable {
    public static func canMakePayments() -> Bool { false }
    public static func canMakePayments(usingNetworks networks: [PKPaymentNetwork]) -> Bool { false }
}
#endif