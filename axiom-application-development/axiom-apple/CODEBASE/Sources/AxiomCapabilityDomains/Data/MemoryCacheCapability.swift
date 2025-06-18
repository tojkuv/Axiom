import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Memory Cache Capability Configuration

/// Configuration for Memory Cache capability
public struct MemoryCacheCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let maxMemorySize: UInt64
    public let maxItemCount: Int
    public let evictionPolicy: EvictionPolicy
    public let enableExpiration: Bool
    public let defaultTTL: TimeInterval
    public let enableMetrics: Bool
    public let compressionThreshold: UInt64
    public let enableSerialization: Bool
    
    public enum EvictionPolicy: String, Codable, CaseIterable {
        case lru = "least-recently-used"
        case lfu = "least-frequently-used"
        case fifo = "first-in-first-out"
        case random = "random"
        case ttl = "time-to-live"
    }
    
    public init(
        maxMemorySize: UInt64 = 50 * 1024 * 1024, // 50MB
        maxItemCount: Int = 1000,
        evictionPolicy: EvictionPolicy = .lru,
        enableExpiration: Bool = true,
        defaultTTL: TimeInterval = 3600, // 1 hour
        enableMetrics: Bool = true,
        compressionThreshold: UInt64 = 10 * 1024, // 10KB
        enableSerialization: Bool = true
    ) {
        self.maxMemorySize = maxMemorySize
        self.maxItemCount = maxItemCount
        self.evictionPolicy = evictionPolicy
        self.enableExpiration = enableExpiration
        self.defaultTTL = defaultTTL
        self.enableMetrics = enableMetrics
        self.compressionThreshold = compressionThreshold
        self.enableSerialization = enableSerialization
    }
    
    public var isValid: Bool {
        maxMemorySize > 0 && maxItemCount > 0 && defaultTTL > 0
    }
    
    public func merged(with other: MemoryCacheCapabilityConfiguration) -> MemoryCacheCapabilityConfiguration {
        MemoryCacheCapabilityConfiguration(
            maxMemorySize: other.maxMemorySize,
            maxItemCount: other.maxItemCount,
            evictionPolicy: other.evictionPolicy,
            enableExpiration: other.enableExpiration,
            defaultTTL: other.defaultTTL,
            enableMetrics: other.enableMetrics,
            compressionThreshold: other.compressionThreshold,
            enableSerialization: other.enableSerialization
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> MemoryCacheCapabilityConfiguration {
        var adjustedMemorySize = maxMemorySize
        var adjustedItemCount = maxItemCount
        var adjustedTTL = defaultTTL
        
        if environment.isLowPowerMode {
            adjustedMemorySize = min(maxMemorySize, 10 * 1024 * 1024) // 10MB limit
            adjustedItemCount = min(maxItemCount, 100)
            adjustedTTL = min(defaultTTL, 300) // 5 minutes
        }
        
        return MemoryCacheCapabilityConfiguration(
            maxMemorySize: adjustedMemorySize,
            maxItemCount: adjustedItemCount,
            evictionPolicy: evictionPolicy,
            enableExpiration: enableExpiration,
            defaultTTL: adjustedTTL,
            enableMetrics: enableMetrics,
            compressionThreshold: compressionThreshold,
            enableSerialization: enableSerialization
        )
    }
}

// MARK: - Cache Item

/// Cached item with metadata
public struct CacheItem: Sendable {
    public let key: String
    public let data: Data
    public let creationTime: Date
    public let lastAccessTime: Date
    public let accessCount: Int
    public let expirationTime: Date?
    public let size: UInt64
    public let isCompressed: Bool
    
    public init(
        key: String,
        data: Data,
        creationTime: Date = Date(),
        lastAccessTime: Date = Date(),
        accessCount: Int = 0,
        expirationTime: Date? = nil,
        isCompressed: Bool = false
    ) {
        self.key = key
        self.data = data
        self.creationTime = creationTime
        self.lastAccessTime = lastAccessTime
        self.accessCount = accessCount
        self.expirationTime = expirationTime
        self.size = UInt64(data.count)
        self.isCompressed = isCompressed
    }
    
    public var isExpired: Bool {
        guard let expirationTime = expirationTime else { return false }
        return Date() > expirationTime
    }
    
    public func accessed() -> CacheItem {
        CacheItem(
            key: key,
            data: data,
            creationTime: creationTime,
            lastAccessTime: Date(),
            accessCount: accessCount + 1,
            expirationTime: expirationTime,
            isCompressed: isCompressed
        )
    }
}

// MARK: - Cache Metrics

/// Cache performance metrics
public struct CacheMetrics: Sendable, Codable {
    public let hitCount: Int
    public let missCount: Int
    public let evictionCount: Int
    public let totalItems: Int
    public let totalSize: UInt64
    public let hitRate: Double
    public let avgAccessTime: TimeInterval
    public let lastCleanupTime: Date
    
    public init(
        hitCount: Int = 0,
        missCount: Int = 0,
        evictionCount: Int = 0,
        totalItems: Int = 0,
        totalSize: UInt64 = 0,
        avgAccessTime: TimeInterval = 0,
        lastCleanupTime: Date = Date()
    ) {
        self.hitCount = hitCount
        self.missCount = missCount
        self.evictionCount = evictionCount
        self.totalItems = totalItems
        self.totalSize = totalSize
        self.hitRate = hitCount + missCount > 0 ? Double(hitCount) / Double(hitCount + missCount) : 0
        self.avgAccessTime = avgAccessTime
        self.lastCleanupTime = lastCleanupTime
    }
}

// MARK: - Memory Cache Resource

/// Memory cache resource management
public actor MemoryCacheCapabilityResource: AxiomCapabilityResource {
    private let configuration: MemoryCacheCapabilityConfiguration
    private var cache: [String: CacheItem] = [:]
    private var accessOrder: [String] = [] // For LRU
    private var accessFrequency: [String: Int] = [:] // For LFU
    private var metrics = CacheMetrics()
    private var cleanupTimer: Timer?
    
    public init(configuration: MemoryCacheCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public func allocate() async throws {
        // Start cleanup timer if expiration is enabled
        if configuration.enableExpiration {
            await startCleanupTimer()
        }
    }
    
    public func deallocate() async {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        cache.removeAll()
        accessOrder.removeAll()
        accessFrequency.removeAll()
        metrics = CacheMetrics()
    }
    
    public var isAllocated: Bool {
        true // Memory cache is always available
    }
    
    public func updateConfiguration(_ configuration: MemoryCacheCapabilityConfiguration) async throws {
        // Memory cache configuration can be updated without reallocation
        await enforceConstraints()
    }
    
    // MARK: - Cache Operations
    
    public func store(_ data: Data, forKey key: String, ttl: TimeInterval? = nil) async {
        let expirationTime = configuration.enableExpiration ? 
            Date().addingTimeInterval(ttl ?? configuration.defaultTTL) : nil
        
        // Compress data if it exceeds threshold
        let (finalData, isCompressed) = await compressIfNeeded(data)
        
        let item = CacheItem(
            key: key,
            data: finalData,
            expirationTime: expirationTime,
            isCompressed: isCompressed
        )
        
        // Remove existing item if present
        if cache[key] != nil {
            await removeFromAccessTracking(key)
        }
        
        cache[key] = item
        await updateAccessTracking(key)
        
        // Enforce cache constraints
        await enforceConstraints()
        
        if configuration.enableMetrics {
            await updateMetrics(operation: .store, key: key)
        }
    }
    
    public func retrieve(forKey key: String) async -> Data? {
        let startTime = Date()
        
        guard let item = cache[key] else {
            if configuration.enableMetrics {
                await updateMetrics(operation: .miss, key: key, accessTime: Date().timeIntervalSince(startTime))
            }
            return nil
        }
        
        // Check expiration
        if item.isExpired {
            await remove(forKey: key)
            if configuration.enableMetrics {
                await updateMetrics(operation: .miss, key: key, accessTime: Date().timeIntervalSince(startTime))
            }
            return nil
        }
        
        // Update access tracking
        let updatedItem = item.accessed()
        cache[key] = updatedItem
        await updateAccessTracking(key)
        
        if configuration.enableMetrics {
            await updateMetrics(operation: .hit, key: key, accessTime: Date().timeIntervalSince(startTime))
        }
        
        // Decompress if needed
        return await decompressIfNeeded(updatedItem.data, isCompressed: updatedItem.isCompressed)
    }
    
    public func remove(forKey key: String) async {
        if cache.removeValue(forKey: key) != nil {
            await removeFromAccessTracking(key)
            if configuration.enableMetrics {
                await updateMetrics(operation: .remove, key: key)
            }
        }
    }
    
    public func removeAll() async {
        cache.removeAll()
        accessOrder.removeAll()
        accessFrequency.removeAll()
        
        if configuration.enableMetrics {
            await updateMetrics(operation: .clear)
        }
    }
    
    public func exists(forKey key: String) async -> Bool {
        guard let item = cache[key] else { return false }
        
        if item.isExpired {
            await remove(forKey: key)
            return false
        }
        
        return true
    }
    
    public func getAllKeys() async -> [String] {
        // Filter out expired items
        var validKeys: [String] = []
        var expiredKeys: [String] = []
        
        for (key, item) in cache {
            if item.isExpired {
                expiredKeys.append(key)
            } else {
                validKeys.append(key)
            }
        }
        
        // Remove expired items
        for key in expiredKeys {
            await remove(forKey: key)
        }
        
        return validKeys
    }
    
    public func getMetrics() async -> CacheMetrics {
        metrics
    }
    
    // MARK: - Private Methods
    
    private func updateAccessTracking(_ key: String) async {
        switch configuration.evictionPolicy {
        case .lru:
            accessOrder.removeAll { $0 == key }
            accessOrder.append(key)
        case .lfu:
            accessFrequency[key, default: 0] += 1
        case .fifo, .random, .ttl:
            break // No additional tracking needed
        }
    }
    
    private func removeFromAccessTracking(_ key: String) async {
        accessOrder.removeAll { $0 == key }
        accessFrequency.removeValue(forKey: key)
    }
    
    private func enforceConstraints() async {
        await removeExpiredItems()
        
        while cache.count > configuration.maxItemCount || getCurrentSize() > configuration.maxMemorySize {
            await evictItem()
        }
    }
    
    private func evictItem() async {
        guard !cache.isEmpty else { return }
        
        let keyToEvict: String
        
        switch configuration.evictionPolicy {
        case .lru:
            keyToEvict = accessOrder.first ?? cache.keys.first!
        case .lfu:
            keyToEvict = accessFrequency.min { $0.value < $1.value }?.key ?? cache.keys.first!
        case .fifo:
            keyToEvict = cache.keys.min { cache[$0]!.creationTime < cache[$1]!.creationTime }!
        case .random:
            keyToEvict = cache.keys.randomElement()!
        case .ttl:
            keyToEvict = cache.keys.min { 
                let item1 = cache[$0]!
                let item2 = cache[$1]!
                return (item1.expirationTime ?? Date.distantFuture) < (item2.expirationTime ?? Date.distantFuture)
            }!
        }
        
        await remove(forKey: keyToEvict)
        
        if configuration.enableMetrics {
            await updateMetrics(operation: .evict, key: keyToEvict)
        }
    }
    
    private func removeExpiredItems() async {
        guard configuration.enableExpiration else { return }
        
        let expiredKeys = cache.compactMap { key, item in
            item.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            await remove(forKey: key)
        }
    }
    
    private func getCurrentSize() -> UInt64 {
        cache.values.reduce(0) { $0 + $1.size }
    }
    
    private func compressIfNeeded(_ data: Data) async -> (Data, Bool) {
        guard data.count > configuration.compressionThreshold else {
            return (data, false)
        }
        
        do {
            let compressedData = try (data as NSData).compressed(using: .lz4)
            return (compressedData as Data, true)
        } catch {
            return (data, false)
        }
    }
    
    private func decompressIfNeeded(_ data: Data, isCompressed: Bool) async -> Data {
        guard isCompressed else { return data }
        
        do {
            return try (data as NSData).decompressed(using: .lz4) as Data
        } catch {
            return data
        }
    }
    
    private func startCleanupTimer() async {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task {
                await self?.removeExpiredItems()
            }
        }
    }
    
    private func updateMetrics(operation: CacheOperation, key: String? = nil, accessTime: TimeInterval = 0) async {
        switch operation {
        case .hit:
            metrics = CacheMetrics(
                hitCount: metrics.hitCount + 1,
                missCount: metrics.missCount,
                evictionCount: metrics.evictionCount,
                totalItems: cache.count,
                totalSize: getCurrentSize(),
                avgAccessTime: (metrics.avgAccessTime + accessTime) / 2,
                lastCleanupTime: metrics.lastCleanupTime
            )
        case .miss:
            metrics = CacheMetrics(
                hitCount: metrics.hitCount,
                missCount: metrics.missCount + 1,
                evictionCount: metrics.evictionCount,
                totalItems: cache.count,
                totalSize: getCurrentSize(),
                avgAccessTime: (metrics.avgAccessTime + accessTime) / 2,
                lastCleanupTime: metrics.lastCleanupTime
            )
        case .evict:
            metrics = CacheMetrics(
                hitCount: metrics.hitCount,
                missCount: metrics.missCount,
                evictionCount: metrics.evictionCount + 1,
                totalItems: cache.count,
                totalSize: getCurrentSize(),
                avgAccessTime: metrics.avgAccessTime,
                lastCleanupTime: metrics.lastCleanupTime
            )
        case .store, .remove, .clear:
            metrics = CacheMetrics(
                hitCount: metrics.hitCount,
                missCount: metrics.missCount,
                evictionCount: metrics.evictionCount,
                totalItems: cache.count,
                totalSize: getCurrentSize(),
                avgAccessTime: metrics.avgAccessTime,
                lastCleanupTime: metrics.lastCleanupTime
            )
        }
    }
    
    private enum CacheOperation {
        case hit, miss, store, remove, evict, clear
    }
}

// MARK: - Memory Cache Capability Implementation

/// Memory cache capability providing high-performance in-memory caching with LRU eviction
public actor MemoryCacheCapability: DomainCapability {
    public typealias ConfigurationType = MemoryCacheCapabilityConfiguration
    public typealias ResourceType = MemoryCacheCapabilityResource
    
    private var _configuration: MemoryCacheCapabilityConfiguration
    private var _resources: MemoryCacheCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "memory-cache-capability" }
    
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
    
    public var configuration: MemoryCacheCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: MemoryCacheCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: MemoryCacheCapabilityConfiguration = MemoryCacheCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = MemoryCacheCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: MemoryCacheCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid memory cache configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Memory cache is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Memory cache doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Cache Operations
    
    /// Store data in cache with optional TTL
    public func store<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        let data = try JSONEncoder().encode(value)
        await _resources.store(data, forKey: key, ttl: ttl)
    }
    
    /// Store raw data in cache
    public func storeData(_ data: Data, forKey key: String, ttl: TimeInterval? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        await _resources.store(data, forKey: key, ttl: ttl)
    }
    
    /// Retrieve typed value from cache
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        guard let data = await _resources.retrieve(forKey: key) else {
            return nil
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Retrieve raw data from cache
    public func retrieveData(forKey key: String) async throws -> Data? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        return await _resources.retrieve(forKey: key)
    }
    
    /// Remove item from cache
    public func remove(forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        await _resources.remove(forKey: key)
    }
    
    /// Clear all cache
    public func removeAll() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        await _resources.removeAll()
    }
    
    /// Check if key exists in cache
    public func exists(forKey key: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        return await _resources.exists(forKey: key)
    }
    
    /// Get all cache keys
    public func getAllKeys() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        return await _resources.getAllKeys()
    }
    
    /// Get cache performance metrics
    public func getMetrics() async throws -> CacheMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Memory cache capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Memory cache specific errors
    public static func memoryCacheError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Memory Cache: \(message)")
    }
    
    public static func cacheItemNotFound(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Cache item not found: \(key)")
    }
    
    public static func cacheCapacityExceeded() -> AxiomCapabilityError {
        .operationFailed("Cache capacity exceeded")
    }
}