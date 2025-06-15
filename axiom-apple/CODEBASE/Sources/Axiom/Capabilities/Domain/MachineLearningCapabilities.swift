import Foundation
import CoreML

// MARK: - Machine Learning / AI Capabilities

/// Configuration for ML capabilities
public struct MLCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
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
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> MLCapabilityConfiguration {
        if environment.isDebug {
            // Debug/development configuration
            return MLCapabilityConfiguration(
                modelName: modelName,
                batchSize: min(batchSize, 2), // Smaller batches for testing
                // computeUnits: .cpuOnly, // Use CPU for consistent testing
                useMetalPerformanceShaders: false
                // cachePolicy: .disable
            )
        } else if environment.isLowPowerMode {
            // Low power configuration
            return MLCapabilityConfiguration(
                modelName: modelName,
                batchSize: 1,
                // computeUnits: .cpuOnly,
                useMetalPerformanceShaders: false
                // cachePolicy: .disable
            )
        } else {
            // Production configuration
            return self
        }
    }
}

public enum MLModelCachePolicy: String, Codable {
    case auto
    case enable
    case disable
}

/// Resource management for ML capabilities
public actor MLCapabilityResource: AxiomCapabilityResource {
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
            return ResourceUsage(memory: Int(memoryEstimate), cpu: cpuEstimate)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 500_000_000, cpu: 80.0) // 500MB, 80% CPU
    
    public var isAvailable: Bool {
        get async {
            await currentUsage.memory < maxUsage.memory
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
    
    public func isAvailable() async -> Bool {
        // Check if ML is available on device and resources are sufficient
        return true // Simplified - assume ML is available on device
    }
}

/// ML/AI capability implementation
public actor MLCapability: DomainCapability {
    private var _configuration: MLCapabilityConfiguration
    private var _resources: MLCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var predictionQueue: [any MLFeatureProvider] = []
    private var isProcessing = false
    private var _activationTimeout: Duration = .seconds(30)
    
    public init(
        configuration: MLCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment(isDebug: true)
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
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: MLCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid ML configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        _resources = MLCapabilityResource(configuration: _configuration)
        
        if _state == .available {
            try await _resources.allocate()
        }
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
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
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func activate() async throws {
        _state = .unknown
        
        guard await isSupported() else {
            _state = .unavailable
            throw AxiomCapabilityError.notAvailable("Core ML not supported")
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
            throw AxiomCapabilityError.notAvailable("ML capability not available")
        }
        
        let request = MLPredictionRequest(input: input, priority: .userInitiated)
        return try await processPrediction(request, outputType: outputType)
    }
    
    public func batchPredict<Input, Output>(
        inputs: [Input],
        outputType: Output.Type
    ) async throws -> [Output] where Input: MLFeatureProvider, Output: MLFeatureProvider {
        guard _state == .available else {
            throw AxiomCapabilityError.notAvailable("ML capability not available")
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
        throw AxiomCapabilityError.initializationFailed("Mock implementation")
    }
}

/// Prediction request wrapper
private struct MLPredictionRequest<Input: MLFeatureProvider> {
    let input: Input
    let priority: TaskPriority
    let timestamp = Date()
}