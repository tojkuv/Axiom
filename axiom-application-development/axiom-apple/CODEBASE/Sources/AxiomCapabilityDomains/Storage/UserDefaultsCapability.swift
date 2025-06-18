import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - UserDefaults Capability Configuration

/// Configuration for UserDefaults capability
public struct UserDefaultsCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let suiteName: String?
    public let enableKeyObservation: Bool
    public let enableAutomaticBackup: Bool
    public let keyPrefix: String
    public let enableTypeValidation: Bool
    public let maxValueSize: Int
    public let enableSecureDefaults: Bool
    
    public init(
        suiteName: String? = nil,
        enableKeyObservation: Bool = true,
        enableAutomaticBackup: Bool = true,
        keyPrefix: String = "",
        enableTypeValidation: Bool = true,
        maxValueSize: Int = 1024 * 1024, // 1MB
        enableSecureDefaults: Bool = false
    ) {
        self.suiteName = suiteName
        self.enableKeyObservation = enableKeyObservation
        self.enableAutomaticBackup = enableAutomaticBackup
        self.keyPrefix = keyPrefix
        self.enableTypeValidation = enableTypeValidation
        self.maxValueSize = maxValueSize
        self.enableSecureDefaults = enableSecureDefaults
    }
    
    public var isValid: Bool {
        maxValueSize > 0
    }
    
    public func merged(with other: UserDefaultsCapabilityConfiguration) -> UserDefaultsCapabilityConfiguration {
        UserDefaultsCapabilityConfiguration(
            suiteName: other.suiteName,
            enableKeyObservation: other.enableKeyObservation,
            enableAutomaticBackup: other.enableAutomaticBackup,
            keyPrefix: other.keyPrefix,
            enableTypeValidation: other.enableTypeValidation,
            maxValueSize: other.maxValueSize,
            enableSecureDefaults: other.enableSecureDefaults
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> UserDefaultsCapabilityConfiguration {
        var adjustedObservation = enableKeyObservation
        var adjustedValueSize = maxValueSize
        var adjustedSecurity = enableSecureDefaults
        
        if environment.isLowPowerMode {
            adjustedObservation = false
            adjustedValueSize = min(maxValueSize, 512 * 1024) // 512KB limit
        }
        
        if environment.isDebug {
            adjustedSecurity = false // Disable security in debug for easier inspection
        }
        
        return UserDefaultsCapabilityConfiguration(
            suiteName: suiteName,
            enableKeyObservation: adjustedObservation,
            enableAutomaticBackup: enableAutomaticBackup,
            keyPrefix: keyPrefix,
            enableTypeValidation: enableTypeValidation,
            maxValueSize: adjustedValueSize,
            enableSecureDefaults: adjustedSecurity
        )
    }
}

// MARK: - UserDefaults Value Types

/// Supported UserDefaults value types
public enum UserDefaultsValue: Sendable, Codable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case data(Data)
    case stringArray([String])
    case integerArray([Int])
    case url(URL)
    case date(Date)
    
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    private enum ValueType: String, Codable {
        case string, integer, double, boolean, data, stringArray, integerArray, url, date
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        
        switch type {
        case .string:
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case .integer:
            let value = try container.decode(Int.self, forKey: .value)
            self = .integer(value)
        case .double:
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        case .boolean:
            let value = try container.decode(Bool.self, forKey: .value)
            self = .boolean(value)
        case .data:
            let value = try container.decode(Data.self, forKey: .value)
            self = .data(value)
        case .stringArray:
            let value = try container.decode([String].self, forKey: .value)
            self = .stringArray(value)
        case .integerArray:
            let value = try container.decode([Int].self, forKey: .value)
            self = .integerArray(value)
        case .url:
            let value = try container.decode(URL.self, forKey: .value)
            self = .url(value)
        case .date:
            let value = try container.decode(Date.self, forKey: .value)
            self = .date(value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .string(let value):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(value, forKey: .value)
        case .integer(let value):
            try container.encode(ValueType.integer, forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(value, forKey: .value)
        case .boolean(let value):
            try container.encode(ValueType.boolean, forKey: .type)
            try container.encode(value, forKey: .value)
        case .data(let value):
            try container.encode(ValueType.data, forKey: .type)
            try container.encode(value, forKey: .value)
        case .stringArray(let value):
            try container.encode(ValueType.stringArray, forKey: .type)
            try container.encode(value, forKey: .value)
        case .integerArray(let value):
            try container.encode(ValueType.integerArray, forKey: .type)
            try container.encode(value, forKey: .value)
        case .url(let value):
            try container.encode(ValueType.url, forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode(ValueType.date, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - UserDefaults Key Observer

/// UserDefaults key change observer
public protocol UserDefaultsKeyObserver: AnyObject {
    func userDefaultsDidChange(key: String, oldValue: Any?, newValue: Any?)
}

/// UserDefaults observation context
public class UserDefaultsObservationContext {
    public let key: String
    public weak var observer: UserDefaultsKeyObserver?
    
    public init(key: String, observer: UserDefaultsKeyObserver) {
        self.key = key
        self.observer = observer
    }
}

// MARK: - UserDefaults Resource

/// UserDefaults resource management
public actor UserDefaultsCapabilityResource: AxiomCapabilityResource {
    private let configuration: UserDefaultsCapabilityConfiguration
    private var userDefaults: UserDefaults?
    private var keyObservations: [String: UserDefaultsObservationContext] = [:]
    
    public init(configuration: UserDefaultsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxValueSize * 100, // Estimate max memory usage
            cpu: 1.0, // Low CPU usage
            bandwidth: 0,
            storage: configuration.maxValueSize * 1000 // Estimate storage usage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let keyCount = keyObservations.count
            let estimatedMemory = keyCount * 1000 // 1KB per key estimate
            
            return ResourceUsage(
                memory: estimatedMemory,
                cpu: configuration.enableKeyObservation ? 0.5 : 0.1,
                bandwidth: 0,
                storage: estimatedMemory * 10 // Storage is usually more than memory
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        userDefaults != nil
    }
    
    public func release() async {
        if configuration.enableKeyObservation {
            NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: userDefaults)
        }
        
        keyObservations.removeAll()
        userDefaults = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Create UserDefaults instance
        if let suiteName = configuration.suiteName {
            userDefaults = UserDefaults(suiteName: suiteName)
        } else {
            userDefaults = UserDefaults.standard
        }
        
        guard userDefaults != nil else {
            throw AxiomCapabilityError.initializationFailed("Failed to create UserDefaults instance")
        }
        
        // Set up key observation if enabled
        if configuration.enableKeyObservation {
            NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: userDefaults,
                queue: .main
            ) { [weak self] notification in
                Task {
                    await self?.handleUserDefaultsChange(notification)
                }
            }
        }
    }
    
    internal func updateConfiguration(_ configuration: UserDefaultsCapabilityConfiguration) async throws {
        // UserDefaults configuration changes require reallocation
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - UserDefaults Access
    
    public func getUserDefaults() -> UserDefaults? {
        userDefaults
    }
    
    public func addKeyObserver(for key: String, observer: UserDefaultsKeyObserver) {
        let context = UserDefaultsObservationContext(key: key, observer: observer)
        keyObservations[key] = context
    }
    
    public func removeKeyObserver(for key: String) {
        keyObservations.removeValue(forKey: key)
    }
    
    private func handleUserDefaultsChange(_ notification: Notification) {
        // Notify observers of key changes
        for (key, context) in keyObservations {
            if let observer = context.observer {
                let newValue = userDefaults?.object(forKey: key)
                observer.userDefaultsDidChange(key: key, oldValue: nil, newValue: newValue)
            }
        }
    }
    
    public func formatKey(_ key: String) -> String {
        if configuration.keyPrefix.isEmpty {
            return key
        }
        return "\(configuration.keyPrefix).\(key)"
    }
    
    public func validateValueSize(_ value: Any) -> Bool {
        // Estimate size of value
        if let data = value as? Data {
            return data.count <= configuration.maxValueSize
        }
        
        if let string = value as? String {
            return string.utf8.count <= configuration.maxValueSize
        }
        
        // For other types, use a rough estimation
        let estimate = MemoryLayout.size(ofValue: value)
        return estimate <= configuration.maxValueSize
    }
}

// MARK: - UserDefaults Capability Implementation

/// UserDefaults capability providing type-safe user preferences
public actor UserDefaultsCapability: DomainCapability {
    public typealias ConfigurationType = UserDefaultsCapabilityConfiguration
    public typealias ResourceType = UserDefaultsCapabilityResource
    
    private var _configuration: UserDefaultsCapabilityConfiguration
    private var _resources: UserDefaultsCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "userdefaults-capability" }
    
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
    
    public var configuration: UserDefaultsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: UserDefaultsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: UserDefaultsCapabilityConfiguration = UserDefaultsCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = UserDefaultsCapabilityResource(configuration: self._configuration)
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
        await _resources.deallocate()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: UserDefaultsCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid UserDefaults configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // UserDefaults is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // UserDefaults doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - UserDefaults Operations
    
    /// Set value for key
    public func setValue<T>(_ value: T, forKey key: String) async throws where T: Sendable {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        // Validate value size
        guard await _resources.validateValueSize(value) else {
            throw AxiomCapabilityError.operationFailed("Value size exceeds limit for key: \(key)")
        }
        
        // Type validation
        if await _configuration.enableTypeValidation {
            guard isValidUserDefaultsType(value) else {
                throw AxiomCapabilityError.operationFailed("Invalid type for UserDefaults key: \(key)")
            }
        }
        
        await MainActor.run {
            userDefaults.set(value, forKey: formattedKey)
            
            if _configuration.enableAutomaticBackup {
                userDefaults.synchronize()
            }
        }
    }
    
    /// Get value for key
    public func getValue<T>(forKey key: String, as type: T.Type, defaultValue: T? = nil) async throws -> T? where T: Sendable {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        return await MainActor.run {
            let value = userDefaults.object(forKey: formattedKey) as? T
            return value ?? defaultValue
        }
    }
    
    /// Get string value
    public func getString(forKey key: String, defaultValue: String? = nil) async throws -> String? {
        try await getValue(forKey: key, as: String.self, defaultValue: defaultValue)
    }
    
    /// Get integer value
    public func getInteger(forKey key: String, defaultValue: Int = 0) async throws -> Int {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        return await MainActor.run {
            userDefaults.integer(forKey: formattedKey)
        }
    }
    
    /// Get double value
    public func getDouble(forKey key: String, defaultValue: Double = 0.0) async throws -> Double {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        return await MainActor.run {
            userDefaults.double(forKey: formattedKey)
        }
    }
    
    /// Get boolean value
    public func getBoolean(forKey key: String, defaultValue: Bool = false) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        return await MainActor.run {
            userDefaults.bool(forKey: formattedKey)
        }
    }
    
    /// Get data value
    public func getData(forKey key: String) async throws -> Data? {
        try await getValue(forKey: key, as: Data.self)
    }
    
    /// Get URL value
    public func getURL(forKey key: String) async throws -> URL? {
        try await getValue(forKey: key, as: URL.self)
    }
    
    /// Get date value
    public func getDate(forKey key: String) async throws -> Date? {
        try await getValue(forKey: key, as: Date.self)
    }
    
    /// Remove value for key
    public func removeValue(forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        await MainActor.run {
            userDefaults.removeObject(forKey: formattedKey)
            
            if _configuration.enableAutomaticBackup {
                userDefaults.synchronize()
            }
        }
    }
    
    /// Check if key exists
    public func keyExists(_ key: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        
        return await MainActor.run {
            userDefaults.object(forKey: formattedKey) != nil
        }
    }
    
    /// Get all keys with prefix
    public func getAllKeys() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        return await MainActor.run {
            let allKeys = userDefaults.dictionaryRepresentation().keys
            let prefix = _configuration.keyPrefix
            
            if prefix.isEmpty {
                return Array(allKeys)
            } else {
                return allKeys.filter { $0.hasPrefix("\(prefix).") }
            }
        }
    }
    
    /// Synchronize UserDefaults
    public func synchronize() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let userDefaults = await _resources.getUserDefaults()
        guard let userDefaults = userDefaults else {
            throw AxiomCapabilityError.resourceAllocationFailed("UserDefaults not available")
        }
        
        await MainActor.run {
            userDefaults.synchronize()
        }
    }
    
    // MARK: - Key Observation
    
    /// Add observer for key changes
    public func addObserver(for key: String, observer: UserDefaultsKeyObserver) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        guard await _configuration.enableKeyObservation else {
            throw AxiomCapabilityError.operationFailed("Key observation is disabled")
        }
        
        let formattedKey = await _resources.formatKey(key)
        await _resources.addKeyObserver(for: formattedKey, observer: observer)
    }
    
    /// Remove observer for key
    public func removeObserver(for key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("UserDefaults capability not available")
        }
        
        let formattedKey = await _resources.formatKey(key)
        await _resources.removeKeyObserver(for: formattedKey)
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    private func isValidUserDefaultsType<T>(_ value: T) -> Bool {
        return value is String ||
               value is Int ||
               value is Double ||
               value is Float ||
               value is Bool ||
               value is Data ||
               value is Date ||
               value is URL ||
               value is Array<String> ||
               value is Array<Int> ||
               value is Array<Double> ||
               value is Array<Bool> ||
               value is Dictionary<String, String> ||
               value is Dictionary<String, Int> ||
               value is Dictionary<String, Double> ||
               value is Dictionary<String, Bool>
    }
}

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// UserDefaults specific errors
    public static func userDefaultsError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("UserDefaults: \(message)")
    }
    
    public static func invalidUserDefaultsType(_ type: String) -> AxiomCapabilityError {
        .operationFailed("Invalid UserDefaults type: \(type)")
    }
    
    public static func userDefaultsKeyNotFound(_ key: String) -> AxiomCapabilityError {
        .operationFailed("UserDefaults key not found: \(key)")
    }
}