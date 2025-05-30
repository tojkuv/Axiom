import Foundation

// MARK: - Capability Validation Engine

/// High-performance capability validation with caching and graceful degradation
public actor CapabilityValidationEngine {
    // MARK: Properties
    
    private let config: CapabilityValidationConfig
    private let cache: ValidationCache
    private let degradationHandler: GracefulDegradationHandler
    private var performanceTracker: ValidationPerformanceTracker
    
    // MARK: Initialization
    
    public init(config: CapabilityValidationConfig = .default) {
        self.config = config
        self.cache = ValidationCache()
        self.degradationHandler = GracefulDegradationHandler()
        self.performanceTracker = ValidationPerformanceTracker()
    }
    
    // MARK: Validation Methods
    
    /// Validates a single capability with full validation pipeline
    public func validateCapability(
        _ capability: Capability,
        context: CapabilityContext,
        availableCapabilities: Set<Capability>
    ) async throws -> ValidationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            performanceTracker.recordValidation(duration: duration)
        }
        
        // Fast path: Check cache first
        if let cachedResult = await cache.getCachedResult(for: capability) {
            performanceTracker.recordCacheHit()
            return cachedResult
        }
        
        performanceTracker.recordCacheMiss()
        
        // Perform validation
        let result = try await performValidation(
            capability: capability,
            context: context,
            availableCapabilities: availableCapabilities
        )
        
        // Cache the result
        await cache.cacheResult(result, for: capability)
        
        return result
    }
    
    /// Validates multiple capabilities with batch optimization
    public func validateCapabilities(
        _ capabilities: [Capability],
        context: CapabilityContext,
        availableCapabilities: Set<Capability>
    ) async throws -> [Capability: ValidationResult] {
        var results: [Capability: ValidationResult] = [:]
        
        // Check cache for all capabilities first
        let (cached, uncached) = await cache.getBatchResults(for: capabilities)
        results.merge(cached) { _, new in new }
        
        // Validate uncached capabilities
        for capability in uncached {
            let result = try await performValidation(
                capability: capability,
                context: context,
                availableCapabilities: availableCapabilities
            )
            results[capability] = result
            await cache.cacheResult(result, for: capability)
        }
        
        return results
    }
    
    /// Validates with graceful degradation if capabilities are unavailable
    public func validateWithDegradation(
        _ capability: Capability,
        context: CapabilityContext,
        availableCapabilities: Set<Capability>
    ) async -> DegradationResult {
        do {
            let result = try await validateCapability(
                capability,
                context: context,
                availableCapabilities: availableCapabilities
            )
            
            if result.isValid {
                return .success(result)
            } else {
                return await degradationHandler.handleUnavailable(
                    capability: capability,
                    context: context,
                    errors: result.errors
                )
            }
        } catch {
            return await degradationHandler.handleError(
                capability: capability,
                context: context,
                error: error
            )
        }
    }
    
    // MARK: Private Methods
    
    private func performValidation(
        capability: Capability,
        context: CapabilityContext,
        availableCapabilities: Set<Capability>
    ) async throws -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Basic availability check
        if !availableCapabilities.contains(capability) {
            errors.append("Capability '\(capability.displayName)' is not available")
        }
        
        // Environment-specific validation
        try await validateEnvironment(capability: capability, errors: &errors, warnings: &warnings)
        
        // Permission validation
        try await validatePermissions(capability: capability, errors: &errors, warnings: &warnings)
        
        // Context-specific validation
        try await validateContext(capability: capability, context: context, errors: &errors, warnings: &warnings)
        
        return ValidationResult(
            capability: capability,
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            timestamp: Date()
        )
    }
    
    private func validateEnvironment(
        capability: Capability,
        errors: inout [String],
        warnings: inout [String]
    ) async throws {
        // Development capabilities only in debug
        #if !DEBUG
        if capability.domain == .development {
            errors.append("Development capabilities not available in release builds")
        }
        #endif
        
        // Platform-specific validation
        #if os(macOS)
        if capability == .camera && !config.allowDevelopmentCapabilities {
            warnings.append("Camera access may require additional permissions on macOS")
        }
        #endif
    }
    
    private func validatePermissions(
        capability: Capability,
        errors: inout [String],
        warnings: inout [String]
    ) async throws {
        guard capability.requiresUserPermission else { return }
        
        // In a real implementation, would check actual system permissions
        // For now, just note that permission is required
        warnings.append("Capability '\(capability.displayName)' requires user permission")
    }
    
    private func validateContext(
        capability: Capability,
        context: CapabilityContext,
        errors: inout [String],
        warnings: inout [String]
    ) async throws {
        // Component-specific validation
        if context.component.description.contains("Test") && capability.domain == .application {
            warnings.append("Application capabilities used in test context")
        }
        
        // Operation-specific validation
        if context.operation == "background" && capability == .camera {
            errors.append("Camera not available in background operations")
        }
    }
}

// MARK: - Enhanced Validation Result

/// Extended validation result with additional metadata
public struct ValidationResult: Sendable {
    public let capability: Capability
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    public let timestamp: Date
    
    public init(
        capability: Capability,
        isValid: Bool,
        errors: [String],
        warnings: [String] = [],
        timestamp: Date = Date()
    ) {
        self.capability = capability
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.timestamp = timestamp
    }
}

// MARK: - Validation Cache

/// High-performance cache for validation results
private actor ValidationCache {
    private var cache: [Capability: CachedValidationResult] = [:]
    private let maxCacheSize = 200
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    struct CachedValidationResult {
        let result: ValidationResult
        let cacheTime: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(cacheTime) > 300
        }
    }
    
    func getCachedResult(for capability: Capability) -> ValidationResult? {
        guard let cached = cache[capability], !cached.isExpired else {
            return nil
        }
        return cached.result
    }
    
    func getBatchResults(for capabilities: [Capability]) -> ([Capability: ValidationResult], [Capability]) {
        var cached: [Capability: ValidationResult] = [:]
        var uncached: [Capability] = []
        
        for capability in capabilities {
            if let result = getCachedResult(for: capability) {
                cached[capability] = result
            } else {
                uncached.append(capability)
            }
        }
        
        return (cached, uncached)
    }
    
    func cacheResult(_ result: ValidationResult, for capability: Capability) {
        cache[capability] = CachedValidationResult(result: result, cacheTime: Date())
        
        // Evict old entries if needed
        if cache.count > maxCacheSize {
            evictOldEntries()
        }
    }
    
    func invalidateCache(for capability: Capability) {
        cache.removeValue(forKey: capability)
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    private func evictOldEntries() {
        let sorted = cache.sorted { $0.value.cacheTime < $1.value.cacheTime }
        let toRemove = sorted.prefix(cache.count - maxCacheSize + 20)
        for (capability, _) in toRemove {
            cache.removeValue(forKey: capability)
        }
    }
}

// MARK: - Graceful Degradation Handler

/// Handles graceful degradation when capabilities are unavailable
public actor GracefulDegradationHandler {
    private var degradationStrategies: [Capability: GracefulDegradation] = [:]
    
    public func registerDegradation(_ degradation: GracefulDegradation) {
        degradationStrategies[degradation.capability] = degradation
    }
    
    public func handleUnavailable(
        capability: Capability,
        context: CapabilityContext,
        errors: [String]
    ) async -> DegradationResult {
        guard let strategy = degradationStrategies[capability] else {
            return .failed(errors)
        }
        
        // Try alternatives first
        for alternative in strategy.alternatives {
            // Check if alternative is available (simplified check)
            if alternative.isAlwaysAvailable {
                return .degraded(alternative, message: "Using \(alternative.displayName) instead of \(capability.displayName)")
            }
        }
        
        // Apply fallback behavior
        switch strategy.fallbackBehavior {
        case .useAlternative:
            if let firstAlternative = strategy.alternatives.first {
                return .degraded(firstAlternative, message: "Fallback to \(firstAlternative.displayName)")
            }
            return .failed(errors)
            
        case .disableFeature:
            return .disabled(message: "Feature disabled due to missing capability: \(capability.displayName)")
            
        case .showWarning(let message):
            return .warning(message)
            
        case .custom(let action):
            await action()
            return .customHandled(message: "Custom degradation applied for \(capability.displayName)")
        }
    }
    
    public func handleError(
        capability: Capability,
        context: CapabilityContext,
        error: Error
    ) async -> DegradationResult {
        return .failed(["Validation error for \(capability.displayName): \(error.localizedDescription)"])
    }
}

// MARK: - Degradation Result

/// Result of graceful degradation
public enum DegradationResult: Sendable {
    case success(ValidationResult)
    case degraded(Capability, message: String)
    case disabled(message: String)
    case warning(String)
    case customHandled(message: String)
    case failed([String])
    
    public var isUsable: Bool {
        switch self {
        case .success, .degraded, .warning, .customHandled:
            return true
        case .disabled, .failed:
            return false
        }
    }
}

// MARK: - Performance Tracker

/// Tracks performance metrics for capability validation
public struct ValidationPerformanceTracker: Sendable {
    private var totalValidations: Int = 0
    private var totalDuration: TimeInterval = 0
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    public mutating func recordValidation(duration: TimeInterval) {
        totalValidations += 1
        totalDuration += duration
    }
    
    public mutating func recordCacheHit() {
        cacheHits += 1
    }
    
    public mutating func recordCacheMiss() {
        cacheMisses += 1
    }
    
    public var averageValidationTime: TimeInterval {
        guard totalValidations > 0 else { return 0 }
        return totalDuration / TimeInterval(totalValidations)
    }
    
    public var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total)
    }
    
    public var metrics: PerformanceMetrics {
        PerformanceMetrics(
            totalValidations: totalValidations,
            averageTime: averageValidationTime,
            cacheHitRate: cacheHitRate
        )
    }
}

// MARK: - Performance Metrics

/// Performance metrics for capability validation
public struct PerformanceMetrics: Sendable {
    public let totalValidations: Int
    public let averageTime: TimeInterval
    public let cacheHitRate: Double
    
    public init(totalValidations: Int, averageTime: TimeInterval, cacheHitRate: Double) {
        self.totalValidations = totalValidations
        self.averageTime = averageTime
        self.cacheHitRate = cacheHitRate
    }
}