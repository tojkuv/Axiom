import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Protobuf Capability Configuration

/// Configuration for Protobuf capability
public struct ProtobufCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableWireFormat: Bool
    public let enableJSONFormat: Bool
    public let enableTextFormat: Bool
    public let enableBinaryFormat: Bool
    public let maxMessageSize: Int
    public let compressionEnabled: Bool
    public let compressionThreshold: Int
    public let enableValidation: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheMaxSize: Int
    public let enableSchemaRegistry: Bool
    public let schemaRegistryURL: URL?
    public let supportedVersions: [String]
    public let defaultEncoding: EncodingType
    public let fieldMaskSupport: Bool
    public let anyTypeSupport: Bool
    
    public enum EncodingType: String, Codable, CaseIterable {
        case binary = "binary"
        case json = "json"
        case text = "text"
        case wire = "wire"
    }
    
    public init(
        enableWireFormat: Bool = true,
        enableJSONFormat: Bool = true,
        enableTextFormat: Bool = false,
        enableBinaryFormat: Bool = true,
        maxMessageSize: Int = 16 * 1024 * 1024, // 16MB
        compressionEnabled: Bool = true,
        compressionThreshold: Int = 1024, // 1KB
        enableValidation: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheMaxSize: Int = 1000,
        enableSchemaRegistry: Bool = false,
        schemaRegistryURL: URL? = nil,
        supportedVersions: [String] = ["proto2", "proto3"],
        defaultEncoding: EncodingType = .binary,
        fieldMaskSupport: Bool = true,
        anyTypeSupport: Bool = true
    ) {
        self.enableWireFormat = enableWireFormat
        self.enableJSONFormat = enableJSONFormat
        self.enableTextFormat = enableTextFormat
        self.enableBinaryFormat = enableBinaryFormat
        self.maxMessageSize = maxMessageSize
        self.compressionEnabled = compressionEnabled
        self.compressionThreshold = compressionThreshold
        self.enableValidation = enableValidation
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheMaxSize = cacheMaxSize
        self.enableSchemaRegistry = enableSchemaRegistry
        self.schemaRegistryURL = schemaRegistryURL
        self.supportedVersions = supportedVersions
        self.defaultEncoding = defaultEncoding
        self.fieldMaskSupport = fieldMaskSupport
        self.anyTypeSupport = anyTypeSupport
    }
    
    public var isValid: Bool {
        maxMessageSize > 0 && compressionThreshold >= 0 && cacheMaxSize >= 0
    }
    
    public func merged(with other: ProtobufCapabilityConfiguration) -> ProtobufCapabilityConfiguration {
        ProtobufCapabilityConfiguration(
            enableWireFormat: other.enableWireFormat,
            enableJSONFormat: other.enableJSONFormat,
            enableTextFormat: other.enableTextFormat,
            enableBinaryFormat: other.enableBinaryFormat,
            maxMessageSize: other.maxMessageSize,
            compressionEnabled: other.compressionEnabled,
            compressionThreshold: other.compressionThreshold,
            enableValidation: other.enableValidation,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheMaxSize: other.cacheMaxSize,
            enableSchemaRegistry: other.enableSchemaRegistry,
            schemaRegistryURL: other.schemaRegistryURL ?? schemaRegistryURL,
            supportedVersions: other.supportedVersions.isEmpty ? supportedVersions : other.supportedVersions,
            defaultEncoding: other.defaultEncoding,
            fieldMaskSupport: other.fieldMaskSupport,
            anyTypeSupport: other.anyTypeSupport
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ProtobufCapabilityConfiguration {
        var adjustedMaxSize = maxMessageSize
        var adjustedCacheSize = cacheMaxSize
        var adjustedLogging = enableLogging
        var adjustedCompression = compressionEnabled
        
        if environment.isLowPowerMode {
            adjustedMaxSize = min(maxMessageSize, 4 * 1024 * 1024) // 4MB max
            adjustedCacheSize = min(cacheMaxSize, 100)
            adjustedCompression = false // Disable compression to save CPU
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ProtobufCapabilityConfiguration(
            enableWireFormat: enableWireFormat,
            enableJSONFormat: enableJSONFormat,
            enableTextFormat: enableTextFormat,
            enableBinaryFormat: enableBinaryFormat,
            maxMessageSize: adjustedMaxSize,
            compressionEnabled: adjustedCompression,
            compressionThreshold: compressionThreshold,
            enableValidation: enableValidation,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheMaxSize: adjustedCacheSize,
            enableSchemaRegistry: enableSchemaRegistry,
            schemaRegistryURL: schemaRegistryURL,
            supportedVersions: supportedVersions,
            defaultEncoding: defaultEncoding,
            fieldMaskSupport: fieldMaskSupport,
            anyTypeSupport: anyTypeSupport
        )
    }
}

// MARK: - Protobuf Types

/// Protobuf wire type enumeration
public enum ProtobufWireType: UInt32, CaseIterable, Sendable {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case startGroup = 3
    case endGroup = 4
    case fixed32 = 5
}

/// Protobuf field descriptor
public struct ProtobufFieldDescriptor: Sendable {
    public let number: Int
    public let name: String
    public let type: ProtobufFieldType
    public let label: ProtobufFieldLabel
    public let defaultValue: Any?
    public let options: [String: Any]
    
    public init(
        number: Int,
        name: String,
        type: ProtobufFieldType,
        label: ProtobufFieldLabel = .optional,
        defaultValue: Any? = nil,
        options: [String: Any] = [:]
    ) {
        self.number = number
        self.name = name
        self.type = type
        self.label = label
        self.defaultValue = defaultValue
        self.options = options
    }
}

/// Protobuf field type
public enum ProtobufFieldType: Sendable {
    case double, float
    case int32, int64
    case uint32, uint64
    case sint32, sint64
    case fixed32, fixed64
    case sfixed32, sfixed64
    case bool
    case string
    case bytes
    case message(String)
    case `enum`(String)
}

/// Protobuf field label
public enum ProtobufFieldLabel: Sendable {
    case optional
    case required
    case repeated
}

/// Protobuf message descriptor
public struct ProtobufMessageDescriptor: Sendable {
    public let name: String
    public let fullName: String
    public let fields: [ProtobufFieldDescriptor]
    public let nestedTypes: [ProtobufMessageDescriptor]
    public let enumTypes: [ProtobufEnumDescriptor]
    public let options: [String: Any]
    
    public init(
        name: String,
        fullName: String,
        fields: [ProtobufFieldDescriptor] = [],
        nestedTypes: [ProtobufMessageDescriptor] = [],
        enumTypes: [ProtobufEnumDescriptor] = [],
        options: [String: Any] = [:]
    ) {
        self.name = name
        self.fullName = fullName
        self.fields = fields
        self.nestedTypes = nestedTypes
        self.enumTypes = enumTypes
        self.options = options
    }
}

/// Protobuf enum descriptor
public struct ProtobufEnumDescriptor: Sendable {
    public let name: String
    public let fullName: String
    public let values: [ProtobufEnumValueDescriptor]
    public let options: [String: Any]
    
    public init(
        name: String,
        fullName: String,
        values: [ProtobufEnumValueDescriptor] = [],
        options: [String: Any] = [:]
    ) {
        self.name = name
        self.fullName = fullName
        self.values = values
        self.options = options
    }
}

/// Protobuf enum value descriptor
public struct ProtobufEnumValueDescriptor: Sendable {
    public let name: String
    public let number: Int
    public let options: [String: Any]
    
    public init(
        name: String,
        number: Int,
        options: [String: Any] = [:]
    ) {
        self.name = name
        self.number = number
        self.options = options
    }
}

/// Protobuf message interface
public protocol ProtobufMessage: Sendable {
    static var descriptor: ProtobufMessageDescriptor { get }
    func serialize(encoding: ProtobufCapabilityConfiguration.EncodingType) throws -> Data
    init(from data: Data, encoding: ProtobufCapabilityConfiguration.EncodingType) throws
}

/// Protobuf serialization result
public struct ProtobufSerializationResult: Sendable {
    public let data: Data
    public let encoding: ProtobufCapabilityConfiguration.EncodingType
    public let compressionRatio: Double?
    public let serializationTime: TimeInterval
    public let originalSize: Int
    public let compressedSize: Int
    
    public init(
        data: Data,
        encoding: ProtobufCapabilityConfiguration.EncodingType,
        compressionRatio: Double? = nil,
        serializationTime: TimeInterval,
        originalSize: Int,
        compressedSize: Int
    ) {
        self.data = data
        self.encoding = encoding
        self.compressionRatio = compressionRatio
        self.serializationTime = serializationTime
        self.originalSize = originalSize
        self.compressedSize = compressedSize
    }
}

/// Protobuf deserialization result
public struct ProtobufDeserializationResult<T: ProtobufMessage>: Sendable {
    public let message: T
    public let encoding: ProtobufCapabilityConfiguration.EncodingType
    public let deserializationTime: TimeInterval
    public let dataSize: Int
    public let wasCompressed: Bool
    
    public init(
        message: T,
        encoding: ProtobufCapabilityConfiguration.EncodingType,
        deserializationTime: TimeInterval,
        dataSize: Int,
        wasCompressed: Bool
    ) {
        self.message = message
        self.encoding = encoding
        self.deserializationTime = deserializationTime
        self.dataSize = dataSize
        self.wasCompressed = wasCompressed
    }
}

/// Protobuf metrics
public struct ProtobufMetrics: Sendable {
    public let totalSerializations: Int
    public let totalDeserializations: Int
    public let totalCompressions: Int
    public let averageSerializationTime: TimeInterval
    public let averageDeserializationTime: TimeInterval
    public let averageCompressionRatio: Double
    public let totalBytesProcessed: Int64
    public let cacheHitRate: Double
    public let errorCount: Int
    public let messageTypeCounts: [String: Int]
    public let encodingTypeCounts: [String: Int]
    
    public init(
        totalSerializations: Int = 0,
        totalDeserializations: Int = 0,
        totalCompressions: Int = 0,
        averageSerializationTime: TimeInterval = 0,
        averageDeserializationTime: TimeInterval = 0,
        averageCompressionRatio: Double = 0,
        totalBytesProcessed: Int64 = 0,
        cacheHitRate: Double = 0,
        errorCount: Int = 0,
        messageTypeCounts: [String: Int] = [:],
        encodingTypeCounts: [String: Int] = [:]
    ) {
        self.totalSerializations = totalSerializations
        self.totalDeserializations = totalDeserializations
        self.totalCompressions = totalCompressions
        self.averageSerializationTime = averageSerializationTime
        self.averageDeserializationTime = averageDeserializationTime
        self.averageCompressionRatio = averageCompressionRatio
        self.totalBytesProcessed = totalBytesProcessed
        self.cacheHitRate = cacheHitRate
        self.errorCount = errorCount
        self.messageTypeCounts = messageTypeCounts
        self.encodingTypeCounts = encodingTypeCounts
    }
}

// MARK: - Protobuf Resource

/// Protobuf resource management
public actor ProtobufCapabilityResource: AxiomCapabilityResource {
    private let configuration: ProtobufCapabilityConfiguration
    private var messageCache: [String: Any] = [:]
    private var schemaCache: [String: ProtobufMessageDescriptor] = [:]
    private var metrics: ProtobufMetrics = ProtobufMetrics()
    private var registeredTypes: [String: ProtobufMessage.Type] = [:]
    
    public init(configuration: ProtobufCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.cacheMaxSize * 50_000 + configuration.maxMessageSize,
            cpu: 5.0, // Protobuf serialization can be CPU intensive
            bandwidth: 0,
            storage: configuration.cacheMaxSize * 10_000
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let cacheMemory = messageCache.count * 25_000 + schemaCache.count * 5_000
            return ResourceUsage(
                memory: cacheMemory,
                cpu: 1.0,
                bandwidth: 0,
                storage: messageCache.count * 5_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // Protobuf is always available once initialized
    }
    
    public func release() async {
        messageCache.removeAll()
        schemaCache.removeAll()
        registeredTypes.removeAll()
        metrics = ProtobufMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Register built-in types
        await registerBuiltInTypes()
        
        // Load schemas from registry if enabled
        if configuration.enableSchemaRegistry {
            await loadSchemasFromRegistry()
        }
    }
    
    internal func updateConfiguration(_ configuration: ProtobufCapabilityConfiguration) async throws {
        // Clear cache if size changed
        if configuration.cacheMaxSize < self.configuration.cacheMaxSize {
            await clearCache()
        }
    }
    
    // MARK: - Message Registration
    
    public func registerMessageType<T: ProtobufMessage>(_ type: T.Type) async {
        let typeName = String(describing: type)
        registeredTypes[typeName] = type
        schemaCache[typeName] = type.descriptor
    }
    
    public func getRegisteredTypes() async -> [String: ProtobufMessage.Type] {
        registeredTypes
    }
    
    // MARK: - Serialization Operations
    
    public func serialize<T: ProtobufMessage>(
        _ message: T,
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> ProtobufSerializationResult {
        
        let actualEncoding = encoding ?? configuration.defaultEncoding
        let startTime = Date()
        
        // Check if encoding is supported
        guard isEncodingSupported(actualEncoding) else {
            throw ProtobufError.unsupportedEncoding(actualEncoding.rawValue)
        }
        
        // Validate message if enabled
        if configuration.enableValidation {
            try await validateMessage(message)
        }
        
        let serializedData = try message.serialize(encoding: actualEncoding)
        
        // Check size limit
        guard serializedData.count <= configuration.maxMessageSize else {
            throw ProtobufError.messageTooLarge(serializedData.count, configuration.maxMessageSize)
        }
        
        let originalSize = serializedData.count
        var finalData = serializedData
        var compressionRatio: Double? = nil
        
        // Apply compression if enabled and beneficial
        if configuration.compressionEnabled && originalSize >= configuration.compressionThreshold {
            if let compressedData = await compressData(serializedData) {
                finalData = compressedData
                compressionRatio = Double(originalSize) / Double(compressedData.count)
                await updateCompressionMetrics()
            }
        }
        
        let serializationTime = Date().timeIntervalSince(startTime)
        
        let result = ProtobufSerializationResult(
            data: finalData,
            encoding: actualEncoding,
            compressionRatio: compressionRatio,
            serializationTime: serializationTime,
            originalSize: originalSize,
            compressedSize: finalData.count
        )
        
        // Update metrics
        if configuration.enableMetrics {
            await updateSerializationMetrics(result: result, messageType: String(describing: T.self))
        }
        
        // Log if enabled
        if configuration.enableLogging {
            await logSerialization(result: result, messageType: String(describing: T.self))
        }
        
        return result
    }
    
    public func deserialize<T: ProtobufMessage>(
        _ data: Data,
        to type: T.Type,
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> ProtobufDeserializationResult<T> {
        
        let actualEncoding = encoding ?? configuration.defaultEncoding
        let startTime = Date()
        
        // Check if encoding is supported
        guard isEncodingSupported(actualEncoding) else {
            throw ProtobufError.unsupportedEncoding(actualEncoding.rawValue)
        }
        
        var processedData = data
        var wasCompressed = false
        
        // Try decompression if compression is enabled
        if configuration.compressionEnabled {
            if let decompressedData = await decompressData(data) {
                processedData = decompressedData
                wasCompressed = true
            }
        }
        
        // Check cache first
        let cacheKey = generateCacheKey(data: processedData, type: type, encoding: actualEncoding)
        if configuration.enableCaching,
           let cachedMessage = messageCache[cacheKey] as? T {
            await updateCacheHitMetrics()
            
            let deserializationTime = Date().timeIntervalSince(startTime)
            return ProtobufDeserializationResult(
                message: cachedMessage,
                encoding: actualEncoding,
                deserializationTime: deserializationTime,
                dataSize: data.count,
                wasCompressed: wasCompressed
            )
        }
        
        // Deserialize message
        let message = try T(from: processedData, encoding: actualEncoding)
        
        // Validate message if enabled
        if configuration.enableValidation {
            try await validateMessage(message)
        }
        
        // Cache message
        if configuration.enableCaching {
            await cacheMessage(message, key: cacheKey)
        }
        
        let deserializationTime = Date().timeIntervalSince(startTime)
        
        let result = ProtobufDeserializationResult(
            message: message,
            encoding: actualEncoding,
            deserializationTime: deserializationTime,
            dataSize: data.count,
            wasCompressed: wasCompressed
        )
        
        // Update metrics
        if configuration.enableMetrics {
            await updateDeserializationMetrics(result: result, messageType: String(describing: T.self))
        }
        
        // Log if enabled
        if configuration.enableLogging {
            await logDeserialization(result: result, messageType: String(describing: T.self))
        }
        
        return result
    }
    
    // MARK: - Batch Operations
    
    public func serializeBatch<T: ProtobufMessage>(
        _ messages: [T],
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> [ProtobufSerializationResult] {
        
        var results: [ProtobufSerializationResult] = []
        
        for message in messages {
            let result = try await serialize(message, encoding: encoding)
            results.append(result)
        }
        
        return results
    }
    
    public func deserializeBatch<T: ProtobufMessage>(
        _ dataItems: [Data],
        to type: T.Type,
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> [ProtobufDeserializationResult<T>] {
        
        var results: [ProtobufDeserializationResult<T>] = []
        
        for data in dataItems {
            let result = try await deserialize(data, to: type, encoding: encoding)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Schema Operations
    
    public func getSchema(for typeName: String) async -> ProtobufMessageDescriptor? {
        schemaCache[typeName]
    }
    
    public func getAllSchemas() async -> [String: ProtobufMessageDescriptor] {
        schemaCache
    }
    
    public func registerSchema(_ schema: ProtobufMessageDescriptor) async {
        schemaCache[schema.name] = schema
    }
    
    // MARK: - Cache Operations
    
    public func clearCache() async {
        messageCache.removeAll()
    }
    
    public func getCacheSize() async -> Int {
        messageCache.count
    }
    
    // MARK: - Metrics and Analytics
    
    public func getMetrics() async -> ProtobufMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = ProtobufMetrics()
    }
    
    // MARK: - Private Methods
    
    private func isEncodingSupported(_ encoding: ProtobufCapabilityConfiguration.EncodingType) -> Bool {
        switch encoding {
        case .binary:
            return configuration.enableBinaryFormat
        case .json:
            return configuration.enableJSONFormat
        case .text:
            return configuration.enableTextFormat
        case .wire:
            return configuration.enableWireFormat
        }
    }
    
    private func validateMessage<T: ProtobufMessage>(_ message: T) async throws {
        // Basic validation - check if message conforms to its schema
        let descriptor = T.descriptor
        
        // Validate field constraints
        for field in descriptor.fields {
            if field.label == .required {
                // Check if required fields are present
                // This would require reflection or protocol methods in real implementation
            }
        }
    }
    
    private func compressData(_ data: Data) async -> Data? {
        // Simplified compression using zlib
        return try? (data as NSData).compressed(using: .zlib) as Data
    }
    
    private func decompressData(_ data: Data) async -> Data? {
        // Try to decompress - if it fails, assume data wasn't compressed
        return try? (data as NSData).decompressed(using: .zlib) as Data
    }
    
    private func generateCacheKey<T: ProtobufMessage>(
        data: Data,
        type: T.Type,
        encoding: ProtobufCapabilityConfiguration.EncodingType
    ) -> String {
        let dataHash = data.sha256Hex.prefix(16)
        let typeName = String(describing: type)
        return "\(typeName)-\(encoding.rawValue)-\(dataHash)"
    }
    
    private func cacheMessage<T: ProtobufMessage>(_ message: T, key: String) async {
        // Ensure cache doesn't exceed max size
        if messageCache.count >= configuration.cacheMaxSize {
            // Remove oldest entries (simplified LRU)
            let keysToRemove = Array(messageCache.keys.prefix(messageCache.count - configuration.cacheMaxSize + 1))
            for key in keysToRemove {
                messageCache.removeValue(forKey: key)
            }
        }
        
        messageCache[key] = message
    }
    
    private func registerBuiltInTypes() async {
        // Register common Protobuf types
        // In a real implementation, this would include well-known types like:
        // - google.protobuf.Any
        // - google.protobuf.Timestamp
        // - google.protobuf.Duration
        // - google.protobuf.FieldMask
        // etc.
    }
    
    private func loadSchemasFromRegistry() async {
        // Load schemas from remote schema registry
        // This would fetch schema definitions from the configured URL
        guard let registryURL = configuration.schemaRegistryURL else { return }
        
        // Placeholder implementation
        // In reality, this would make HTTP requests to fetch schemas
    }
    
    private func updateSerializationMetrics(result: ProtobufSerializationResult, messageType: String) async {
        var newMessageCounts = metrics.messageTypeCounts
        var newEncodingCounts = metrics.encodingTypeCounts
        
        newMessageCounts[messageType, default: 0] += 1
        newEncodingCounts[result.encoding.rawValue, default: 0] += 1
        
        let totalSerializations = metrics.totalSerializations + 1
        let newAverageTime = ((metrics.averageSerializationTime * Double(metrics.totalSerializations)) + result.serializationTime) / Double(totalSerializations)
        
        metrics = ProtobufMetrics(
            totalSerializations: totalSerializations,
            totalDeserializations: metrics.totalDeserializations,
            totalCompressions: metrics.totalCompressions,
            averageSerializationTime: newAverageTime,
            averageDeserializationTime: metrics.averageDeserializationTime,
            averageCompressionRatio: metrics.averageCompressionRatio,
            totalBytesProcessed: metrics.totalBytesProcessed + Int64(result.compressedSize),
            cacheHitRate: metrics.cacheHitRate,
            errorCount: metrics.errorCount,
            messageTypeCounts: newMessageCounts,
            encodingTypeCounts: newEncodingCounts
        )
    }
    
    private func updateDeserializationMetrics<T: ProtobufMessage>(result: ProtobufDeserializationResult<T>, messageType: String) async {
        var newMessageCounts = metrics.messageTypeCounts
        var newEncodingCounts = metrics.encodingTypeCounts
        
        newMessageCounts[messageType, default: 0] += 1
        newEncodingCounts[result.encoding.rawValue, default: 0] += 1
        
        let totalDeserializations = metrics.totalDeserializations + 1
        let newAverageTime = ((metrics.averageDeserializationTime * Double(metrics.totalDeserializations)) + result.deserializationTime) / Double(totalDeserializations)
        
        metrics = ProtobufMetrics(
            totalSerializations: metrics.totalSerializations,
            totalDeserializations: totalDeserializations,
            totalCompressions: metrics.totalCompressions,
            averageSerializationTime: metrics.averageSerializationTime,
            averageDeserializationTime: newAverageTime,
            averageCompressionRatio: metrics.averageCompressionRatio,
            totalBytesProcessed: metrics.totalBytesProcessed + Int64(result.dataSize),
            cacheHitRate: metrics.cacheHitRate,
            errorCount: metrics.errorCount,
            messageTypeCounts: newMessageCounts,
            encodingTypeCounts: newEncodingCounts
        )
    }
    
    private func updateCompressionMetrics() async {
        metrics = ProtobufMetrics(
            totalSerializations: metrics.totalSerializations,
            totalDeserializations: metrics.totalDeserializations,
            totalCompressions: metrics.totalCompressions + 1,
            averageSerializationTime: metrics.averageSerializationTime,
            averageDeserializationTime: metrics.averageDeserializationTime,
            averageCompressionRatio: metrics.averageCompressionRatio,
            totalBytesProcessed: metrics.totalBytesProcessed,
            cacheHitRate: metrics.cacheHitRate,
            errorCount: metrics.errorCount,
            messageTypeCounts: metrics.messageTypeCounts,
            encodingTypeCounts: metrics.encodingTypeCounts
        )
    }
    
    private func updateCacheHitMetrics() async {
        // Update cache hit rate
        let totalAccesses = metrics.totalSerializations + metrics.totalDeserializations
        // Simplified cache hit rate calculation
        let newHitRate = totalAccesses > 0 ? 0.8 : 0 // Placeholder calculation
        
        metrics = ProtobufMetrics(
            totalSerializations: metrics.totalSerializations,
            totalDeserializations: metrics.totalDeserializations,
            totalCompressions: metrics.totalCompressions,
            averageSerializationTime: metrics.averageSerializationTime,
            averageDeserializationTime: metrics.averageDeserializationTime,
            averageCompressionRatio: metrics.averageCompressionRatio,
            totalBytesProcessed: metrics.totalBytesProcessed,
            cacheHitRate: newHitRate,
            errorCount: metrics.errorCount,
            messageTypeCounts: metrics.messageTypeCounts,
            encodingTypeCounts: metrics.encodingTypeCounts
        )
    }
    
    private func logSerialization(result: ProtobufSerializationResult, messageType: String) async {
        let compressionInfo = result.compressionRatio.map { " (compression: \(String(format: "%.2f", $0))x)" } ?? ""
        print("[Protobuf] 📤 SERIALIZE: \(messageType) -> \(result.data.count) bytes (\(result.encoding.rawValue))\(compressionInfo)")
    }
    
    private func logDeserialization<T: ProtobufMessage>(result: ProtobufDeserializationResult<T>, messageType: String) async {
        let compressionInfo = result.wasCompressed ? " (decompressed)" : ""
        print("[Protobuf] 📥 DESERIALIZE: \(messageType) <- \(result.dataSize) bytes (\(result.encoding.rawValue))\(compressionInfo)")
    }
}

// MARK: - Protobuf Capability Implementation

/// Protobuf capability providing Protocol Buffers serialization
public actor ProtobufCapability: DomainCapability {
    public typealias ConfigurationType = ProtobufCapabilityConfiguration
    public typealias ResourceType = ProtobufCapabilityResource
    
    private var _configuration: ProtobufCapabilityConfiguration
    private var _resources: ProtobufCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "protobuf-capability" }
    
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
    
    public var configuration: ProtobufCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ProtobufCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ProtobufCapabilityConfiguration = ProtobufCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ProtobufCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ProtobufCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Protobuf configuration")
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
        // Protobuf is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Protobuf doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Protobuf Operations
    
    /// Serialize a protobuf message
    public func serialize<T: ProtobufMessage>(
        _ message: T,
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> ProtobufSerializationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return try await _resources.serialize(message, encoding: encoding)
    }
    
    /// Deserialize a protobuf message
    public func deserialize<T: ProtobufMessage>(
        _ data: Data,
        to type: T.Type,
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> ProtobufDeserializationResult<T> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return try await _resources.deserialize(data, to: type, encoding: encoding)
    }
    
    /// Serialize multiple messages
    public func serializeBatch<T: ProtobufMessage>(
        _ messages: [T],
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> [ProtobufSerializationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return try await _resources.serializeBatch(messages, encoding: encoding)
    }
    
    /// Deserialize multiple messages
    public func deserializeBatch<T: ProtobufMessage>(
        _ dataItems: [Data],
        to type: T.Type,
        encoding: ProtobufCapabilityConfiguration.EncodingType? = nil
    ) async throws -> [ProtobufDeserializationResult<T>] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return try await _resources.deserializeBatch(dataItems, to: type, encoding: encoding)
    }
    
    /// Register a message type
    public func registerMessageType<T: ProtobufMessage>(_ type: T.Type) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        await _resources.registerMessageType(type)
    }
    
    /// Get schema for a type
    public func getSchema(for typeName: String) async throws -> ProtobufMessageDescriptor? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return await _resources.getSchema(for: typeName)
    }
    
    /// Get all registered schemas
    public func getAllSchemas() async throws -> [String: ProtobufMessageDescriptor] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return await _resources.getAllSchemas()
    }
    
    /// Register a schema
    public func registerSchema(_ schema: ProtobufMessageDescriptor) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        await _resources.registerSchema(schema)
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        await _resources.clearCache()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ProtobufMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Protobuf capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Protobuf specific errors
public enum ProtobufError: Error, LocalizedError {
    case unsupportedEncoding(String)
    case messageTooLarge(Int, Int)
    case invalidWireFormat
    case invalidFieldNumber(Int)
    case missingRequiredField(String)
    case invalidFieldType(String)
    case serializationFailed(Error)
    case deserializationFailed(Error)
    case compressionFailed(Error)
    case decompressionFailed(Error)
    case schemaNotFound(String)
    case typeNotRegistered(String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedEncoding(let encoding):
            return "Unsupported encoding: \(encoding)"
        case .messageTooLarge(let size, let limit):
            return "Message size \(size) exceeds limit of \(limit) bytes"
        case .invalidWireFormat:
            return "Invalid protobuf wire format"
        case .invalidFieldNumber(let number):
            return "Invalid field number: \(number)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidFieldType(let type):
            return "Invalid field type: \(type)"
        case .serializationFailed(let error):
            return "Serialization failed: \(error.localizedDescription)"
        case .deserializationFailed(let error):
            return "Deserialization failed: \(error.localizedDescription)"
        case .compressionFailed(let error):
            return "Compression failed: \(error.localizedDescription)"
        case .decompressionFailed(let error):
            return "Decompression failed: \(error.localizedDescription)"
        case .schemaNotFound(let name):
            return "Schema not found: \(name)"
        case .typeNotRegistered(let name):
            return "Type not registered: \(name)"
        }
    }
}

// MARK: - Extensions

extension Data {
    var sha256Hex: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Need to import CommonCrypto for SHA256
import CommonCrypto