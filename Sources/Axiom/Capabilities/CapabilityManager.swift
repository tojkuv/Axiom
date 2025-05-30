import Foundation

// MARK: - Capability Manager

/// Enhanced capability manager with caching and performance optimization
public actor CapabilityManager {
    // MARK: Properties
    
    private var availableCapabilities: Set<Capability> = []
    private var leases: [CapabilityID: CapabilityLease] = [:]
    private var cache: CapabilityCache
    private let validator: CapabilityValidator
    private let validationEngine: CapabilityValidationEngine
    
    // Performance tracking
    private var validationMetrics: ValidationMetrics
    
    // MARK: Initialization
    
    public init(config: CapabilityValidationConfig = .default) {
        self.cache = CapabilityCache()
        self.validator = CapabilityValidator()
        self.validationEngine = CapabilityValidationEngine(config: config)
        self.validationMetrics = ValidationMetrics()
    }
    
    // MARK: Capability Management
    
    /// Validates that a capability is available
    public func validate(_ capability: Capability) async throws {
        // Fast cache lookup (90% of cases)
        if let cachedResult = await cache.lookup(capability) {
            validationMetrics.recordCacheHit()
            guard cachedResult.isValid else {
                throw CapabilityError.denied(capability)
            }
            return
        }
        
        // Runtime validation (10% of cases)
        validationMetrics.recordCacheMiss()
        let isValid = availableCapabilities.contains(capability)
        let result = Axiom.ValidationResult(
            capability: capability,
            isValid: isValid,
            errors: isValid ? [] : ["Capability '\(capability.displayName)' is not available"]
        )
        await cache.store(capability, result: result)
        
        guard isValid else {
            throw CapabilityError.unavailable(capability)
        }
    }
    
    /// Validates multiple capabilities at once
    public func validateAll(_ capabilities: [Capability]) async throws {
        for capability in capabilities {
            try await validate(capability)
        }
    }
    
    /// Enhanced validation with context and graceful degradation
    public func validateWithContext(
        _ capability: Capability,
        context: CapabilityContext
    ) async throws -> Axiom.ValidationResult {
        return try await validationEngine.validateCapability(
            capability,
            context: context,
            availableCapabilities: availableCapabilities
        )
    }
    
    /// Validates with graceful degradation
    public func validateWithDegradation(
        _ capability: Capability,
        context: CapabilityContext
    ) async -> DegradationResult {
        return await validationEngine.validateWithDegradation(
            capability,
            context: context,
            availableCapabilities: availableCapabilities
        )
    }
    
    /// Batch validation with enhanced engine
    public func validateBatch(
        _ capabilities: [Capability],
        context: CapabilityContext
    ) async throws -> [Capability: Axiom.ValidationResult] {
        return try await validationEngine.validateCapabilities(
            capabilities,
            context: context,
            availableCapabilities: availableCapabilities
        )
    }
    
    /// Requests a lease for a capability
    public func requestLease(for capability: Capability, duration: TimeInterval = 3600) async throws -> CapabilityLease {
        try await validate(capability)
        
        let lease = CapabilityLeaseImpl(
            id: UUID().uuidString,
            capability: capability,
            expiration: Date().addingTimeInterval(duration)
        )
        
        leases[CapabilityID(capability.rawValue)] = lease
        
        // Schedule lease expiration
        Task {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await expireLease(lease)
        }
        
        return lease
    }
    
    /// Renews a capability lease
    public func renewLease(_ lease: CapabilityLease, duration: TimeInterval = 3600) async throws -> CapabilityLease {
        guard leases[CapabilityID(lease.capability.rawValue)] != nil else {
            throw CapabilityError.expired(lease)
        }
        
        return try await requestLease(for: lease.capability, duration: duration)
    }
    
    /// Revokes a capability lease
    public func revokeLease(_ lease: CapabilityLease) async {
        leases.removeValue(forKey: CapabilityID(lease.capability.rawValue))
        await cache.invalidate(lease.capability)
    }
    
    /// Adds a capability to the available set
    public func addCapability(_ capability: Capability) async {
        availableCapabilities.insert(capability)
        await cache.invalidate(capability)
    }
    
    /// Removes a capability from the available set
    public func removeCapability(_ capability: Capability) async {
        availableCapabilities.remove(capability)
        leases.removeValue(forKey: CapabilityID(capability.rawValue))
        await cache.invalidate(capability)
    }
    
    /// Adds capabilities from a domain
    public func addDomain(_ domain: CapabilityDomain) async {
        for capability in domain.capabilities {
            await addCapability(capability)
        }
    }
    
    /// Removes capabilities from a domain
    public func removeDomain(_ domain: CapabilityDomain) async {
        for capability in domain.capabilities {
            await removeCapability(capability)
        }
    }
    
    // MARK: Query Methods
    
    /// Returns all available capabilities
    public func getAvailableCapabilities() -> Set<Capability> {
        availableCapabilities
    }
    
    /// Returns all active leases
    public func activeLeases() -> [CapabilityLease] {
        Array(leases.values)
    }
    
    /// Checks if a capability is available
    public func isAvailable(_ capability: Capability) -> Bool {
        availableCapabilities.contains(capability)
    }
    
    /// Checks if a capability is available (async version for consistency)
    public func hasCapability(_ capability: Capability) async -> Bool {
        isAvailable(capability)
    }
    
    /// Validates that all capabilities are available
    public func validateCapabilities(_ capabilities: [Capability]) async throws -> Bool {
        var allAvailable = true
        for capability in capabilities {
            if !isAvailable(capability) {
                allAvailable = false
                break
            }
        }
        return allAvailable
    }
    
    /// Returns performance metrics
    public func metrics() -> ValidationMetrics {
        validationMetrics
    }
    
    // MARK: Private Methods
    
    private func expireLease(_ lease: CapabilityLease) async {
        leases.removeValue(forKey: CapabilityID(lease.capability.rawValue))
    }
}

// MARK: - Capability Cache

/// High-performance cache for capability validation results
private actor CapabilityCache {
    private var cache: [Capability: CachedResult] = [:]
    private let maxCacheSize = 100
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    struct CachedResult {
        let result: Axiom.ValidationResult
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }
    
    func lookup(_ capability: Capability) -> Axiom.ValidationResult? {
        guard let cached = cache[capability], !cached.isExpired else {
            return nil
        }
        return cached.result
    }
    
    func store(_ capability: Capability, result: Axiom.ValidationResult) {
        cache[capability] = CachedResult(result: result, timestamp: Date())
        
        // Evict old entries if cache is too large
        if cache.count > maxCacheSize {
            evictOldEntries()
        }
    }
    
    func invalidate(_ capability: Capability) {
        cache.removeValue(forKey: capability)
    }
    
    func invalidateAll() {
        cache.removeAll()
    }
    
    func clear() {
        cache.removeAll()
    }
    
    private func evictOldEntries() {
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(cache.count - maxCacheSize + 10)
        for (capability, _) in toRemove {
            cache.removeValue(forKey: capability)
        }
    }
}

// MARK: - Capability Validator

/// Validates capabilities according to business rules
public struct CapabilityValidator {
    /// Validates a capability request
    public func validate(_ capability: Capability) -> Axiom.ValidationResult {
        var errors: [String] = []
        
        // Check if capability requires user permission
        if capability.requiresUserPermission {
            // In a real implementation, would check actual permissions
            // For now, just note it
        }
        
        // Validate based on environment
        #if DEBUG
        // All capabilities available in debug
        #else
        if capability.domain == .development {
            errors.append("Development capabilities not available in release builds")
        }
        #endif
        
        return Axiom.ValidationResult(
            capability: capability,
            isValid: errors.isEmpty,
            errors: errors
        )
    }
}

// MARK: - Capability Lease Implementation

/// Concrete implementation of CapabilityLease
public struct CapabilityLeaseImpl: CapabilityLease {
    public let id: String
    public let capability: Capability
    public let expiration: Date
    
    public var isValid: Bool {
        Date() < expiration
    }
}

/// Extended CapabilityLease protocol
public protocol CapabilityLease: Sendable {
    var id: String { get }
    var capability: Capability { get }
    var expiration: Date { get }
    var isValid: Bool { get }
}

// MARK: - Validation Metrics

/// Tracks performance metrics for capability validation
public struct ValidationMetrics: Sendable {
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var validationCount: Int = 0
    
    public var cacheHitRate: Double {
        guard validationCount > 0 else { return 0 }
        return Double(cacheHits) / Double(validationCount)
    }
    
    mutating func recordCacheHit() {
        cacheHits += 1
        validationCount += 1
    }
    
    mutating func recordCacheMiss() {
        cacheMisses += 1
        validationCount += 1
    }
}

// MARK: - CapabilityManager Application Extensions

extension CapabilityManager {
    /// Configures the capability manager with available capabilities
    public func configure(availableCapabilities: Set<Capability>) async {
        self.availableCapabilities = availableCapabilities
    }
    
    /// Initializes the capability manager
    public func initialize() async throws {
        // Initialize caches
        await cache.clear()
        // Validation engine doesn't need explicit initialization
    }
    
    /// Refreshes capabilities (checks if new capabilities are available)
    public func refreshCapabilities() async {
        // Refresh capability availability
        await cache.clear()
        validationMetrics = ValidationMetrics()
    }
    
    /// Shuts down the capability manager
    public func shutdown() async {
        await cache.clear()
        availableCapabilities.removeAll()
    }
}