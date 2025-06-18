import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Data Cache Capability Configuration

/// Configuration for Data Cache capability
public struct DataCacheCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let strategy: CacheStrategy
    public let memoryConfig: MemoryCacheConfig
    public let diskConfig: DiskCacheConfig
    public let enableTieredCaching: Bool
    public let dataTypes: Set<DataTypeIdentifier>
    public let compressionEnabled: Bool
    public let encryptionEnabled: Bool
    public let syncStrategy: SyncStrategy
    public let evictionPolicy: EvictionPolicy
    public let enableAnalytics: Bool
    
    public enum CacheStrategy: String, Codable, CaseIterable {
        case memoryOnly = "memory-only"
        case diskOnly = "disk-only"
        case tiered = "tiered"
        case writeThrough = "write-through"
        case writeBack = "write-back"
        case adaptive = "adaptive"
    }
    
    public enum SyncStrategy: String, Codable, CaseIterable {
        case immediate = "immediate"
        case deferred = "deferred"
        case batched = "batched"
        case background = "background"
    }
    
    public enum EvictionPolicy: String, Codable, CaseIterable {
        case lru = "least-recently-used"
        case lfu = "least-frequently-used"
        case ttl = "time-to-live"
        case size = "size-based"
        case smart = "smart-adaptive"
    }
    
    public struct MemoryCacheConfig: Codable {
        public let maxSize: UInt64
        public let maxItems: Int
        public let ttl: TimeInterval
        
        public init(maxSize: UInt64 = 50 * 1024 * 1024, maxItems: Int = 1000, ttl: TimeInterval = 3600) {
            self.maxSize = maxSize
            self.maxItems = maxItems
            self.ttl = ttl
        }
    }
    
    public struct DiskCacheConfig: Codable {
        public let maxSize: UInt64
        public let maxItems: Int
        public let ttl: TimeInterval
        
        public init(maxSize: UInt64 = 500 * 1024 * 1024, maxItems: Int = 10000, ttl: TimeInterval = 86400) {
            self.maxSize = maxSize
            self.maxItems = maxItems
            self.ttl = ttl
        }
    }
    
    public struct DataTypeIdentifier: Hashable, Codable {
        public let name: String
        public let version: String
        
        public init(name: String, version: String = "1.0") {
            self.name = name
            self.version = version
        }
    }
    
    public init(
        strategy: CacheStrategy = .tiered,
        memoryConfig: MemoryCacheConfig = MemoryCacheConfig(),
        diskConfig: DiskCacheConfig = DiskCacheConfig(),
        enableTieredCaching: Bool = true,
        dataTypes: Set<DataTypeIdentifier> = [],
        compressionEnabled: Bool = true,
        encryptionEnabled: Bool = false,
        syncStrategy: SyncStrategy = .deferred,
        evictionPolicy: EvictionPolicy = .smart,
        enableAnalytics: Bool = true
    ) {
        self.strategy = strategy
        self.memoryConfig = memoryConfig
        self.diskConfig = diskConfig
        self.enableTieredCaching = enableTieredCaching
        self.dataTypes = dataTypes
        self.compressionEnabled = compressionEnabled
        self.encryptionEnabled = encryptionEnabled
        self.syncStrategy = syncStrategy
        self.evictionPolicy = evictionPolicy
        self.enableAnalytics = enableAnalytics
    }
    
    public var isValid: Bool {
        memoryConfig.maxSize > 0 && diskConfig.maxSize > 0 && 
        memoryConfig.maxItems > 0 && diskConfig.maxItems > 0
    }
    
    public func merged(with other: DataCacheCapabilityConfiguration) -> DataCacheCapabilityConfiguration {
        DataCacheCapabilityConfiguration(
            strategy: other.strategy,
            memoryConfig: other.memoryConfig,
            diskConfig: other.diskConfig,
            enableTieredCaching: other.enableTieredCaching,
            dataTypes: dataTypes.union(other.dataTypes),
            compressionEnabled: other.compressionEnabled,
            encryptionEnabled: other.encryptionEnabled,
            syncStrategy: other.syncStrategy,
            evictionPolicy: other.evictionPolicy,
            enableAnalytics: other.enableAnalytics
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> DataCacheCapabilityConfiguration {
        var adjustedMemoryConfig = memoryConfig
        var adjustedDiskConfig = diskConfig
        var adjustedEncryption = encryptionEnabled
        
        if environment.isLowPowerMode {
            adjustedMemoryConfig = MemoryCacheConfig(
                maxSize: min(memoryConfig.maxSize, 10 * 1024 * 1024), // 10MB limit
                maxItems: min(memoryConfig.maxItems, 100),
                ttl: min(memoryConfig.ttl, 300) // 5 minutes
            )
            adjustedDiskConfig = DiskCacheConfig(
                maxSize: min(diskConfig.maxSize, 100 * 1024 * 1024), // 100MB limit
                maxItems: min(diskConfig.maxItems, 1000),
                ttl: min(diskConfig.ttl, 3600) // 1 hour
            )
        }
        
        if environment.isDebug {
            adjustedEncryption = false // Disable encryption in debug
        }
        
        return DataCacheCapabilityConfiguration(
            strategy: strategy,
            memoryConfig: adjustedMemoryConfig,
            diskConfig: adjustedDiskConfig,
            enableTieredCaching: enableTieredCaching,
            dataTypes: dataTypes,
            compressionEnabled: compressionEnabled,
            encryptionEnabled: adjustedEncryption,
            syncStrategy: syncStrategy,
            evictionPolicy: evictionPolicy,
            enableAnalytics: enableAnalytics
        )
    }
}

// MARK: - Cached Data Item

/// Cached data item with rich metadata
public struct CachedDataItem: Sendable, Codable {
    public let key: String
    public let dataType: DataCacheCapabilityConfiguration.DataTypeIdentifier
    public let data: Data
    public let metadata: DataMetadata
    public let creationTime: Date
    public let lastAccessTime: Date
    public let accessCount: Int
    public let expirationTime: Date?
    public let size: UInt64
    public let isCompressed: Bool
    public let isEncrypted: Bool
    public let checksum: String
    public let version: String
    
    public struct DataMetadata: Sendable, Codable {
        public let sourceURL: URL?
        public let contentType: String?
        public let encoding: String?
        public let tags: [String]
        public let customAttributes: [String: String]
        
        public init(
            sourceURL: URL? = nil,
            contentType: String? = nil,
            encoding: String? = nil,
            tags: [String] = [],
            customAttributes: [String: String] = [:]
        ) {
            self.sourceURL = sourceURL
            self.contentType = contentType
            self.encoding = encoding
            self.tags = tags
            self.customAttributes = customAttributes
        }
    }
    
    public init(
        key: String,
        dataType: DataCacheCapabilityConfiguration.DataTypeIdentifier,
        data: Data,
        metadata: DataMetadata = DataMetadata(),
        creationTime: Date = Date(),
        lastAccessTime: Date = Date(),
        accessCount: Int = 0,
        expirationTime: Date? = nil,
        isCompressed: Bool = false,
        isEncrypted: Bool = false,
        version: String = "1.0"
    ) {
        self.key = key
        self.dataType = dataType
        self.data = data
        self.metadata = metadata
        self.creationTime = creationTime
        self.lastAccessTime = lastAccessTime
        self.accessCount = accessCount
        self.expirationTime = expirationTime
        self.size = UInt64(data.count)
        self.isCompressed = isCompressed
        self.isEncrypted = isEncrypted
        self.checksum = data.sha256
        self.version = version
    }
    
    public var isExpired: Bool {
        guard let expirationTime = expirationTime else { return false }
        return Date() > expirationTime
    }
    
    public func accessed() -> CachedDataItem {
        CachedDataItem(
            key: key,
            dataType: dataType,
            data: data,
            metadata: metadata,
            creationTime: creationTime,
            lastAccessTime: Date(),
            accessCount: accessCount + 1,
            expirationTime: expirationTime,
            isCompressed: isCompressed,
            isEncrypted: isEncrypted,
            version: version
        )
    }
}

// MARK: - Cache Analytics

/// Data cache analytics and metrics
public struct DataCacheAnalytics: Sendable, Codable {
    public let memoryStats: CacheStats
    public let diskStats: CacheStats
    public let overallStats: CacheStats
    public let dataTypeStats: [String: CacheStats]
    public let performanceMetrics: PerformanceMetrics
    public let lastUpdated: Date
    
    public struct CacheStats: Sendable, Codable {
        public let hitCount: Int
        public let missCount: Int
        public let evictionCount: Int
        public let itemCount: Int
        public let totalSize: UInt64
        public let hitRate: Double
        public let averageAccessTime: TimeInterval
        
        public init(
            hitCount: Int = 0,
            missCount: Int = 0,
            evictionCount: Int = 0,
            itemCount: Int = 0,
            totalSize: UInt64 = 0,
            averageAccessTime: TimeInterval = 0
        ) {
            self.hitCount = hitCount
            self.missCount = missCount
            self.evictionCount = evictionCount
            self.itemCount = itemCount
            self.totalSize = totalSize
            self.hitRate = hitCount + missCount > 0 ? Double(hitCount) / Double(hitCount + missCount) : 0
            self.averageAccessTime = averageAccessTime
        }
    }
    
    public struct PerformanceMetrics: Sendable, Codable {
        public let averageStoreTime: TimeInterval
        public let averageRetrieveTime: TimeInterval
        public let compressionRatio: Double
        public let memoryEfficiency: Double
        public let diskEfficiency: Double
        
        public init(
            averageStoreTime: TimeInterval = 0,
            averageRetrieveTime: TimeInterval = 0,
            compressionRatio: Double = 1.0,
            memoryEfficiency: Double = 1.0,
            diskEfficiency: Double = 1.0
        ) {
            self.averageStoreTime = averageStoreTime
            self.averageRetrieveTime = averageRetrieveTime
            self.compressionRatio = compressionRatio
            self.memoryEfficiency = memoryEfficiency
            self.diskEfficiency = diskEfficiency
        }
    }
    
    public init(
        memoryStats: CacheStats = CacheStats(),
        diskStats: CacheStats = CacheStats(),
        overallStats: CacheStats = CacheStats(),
        dataTypeStats: [String: CacheStats] = [:],
        performanceMetrics: PerformanceMetrics = PerformanceMetrics(),
        lastUpdated: Date = Date()
    ) {
        self.memoryStats = memoryStats
        self.diskStats = diskStats
        self.overallStats = overallStats
        self.dataTypeStats = dataTypeStats
        self.performanceMetrics = performanceMetrics
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Data Cache Resource

/// Data cache resource management with tiered caching
public actor DataCacheCapabilityResource: AxiomCapabilityResource {
    private let configuration: DataCacheCapabilityConfiguration
    private var memoryCache: MemoryCacheCapabilityResource?
    private var diskCache: DiskCacheCapabilityResource?
    private var analytics = DataCacheAnalytics()
    private var syncQueue: [CachedDataItem] = []
    private var syncTimer: Timer?
    private let operationQueue = OperationQueue()
    
    public init(configuration: DataCacheCapabilityConfiguration) {
        self.configuration = configuration
        self.operationQueue.maxConcurrentOperationCount = 4
        self.operationQueue.qualityOfService = .utility
    }
    
    public func allocate() async throws {
        // Initialize memory cache if needed
        if configuration.strategy != .diskOnly {
            let memoryConfig = MemoryCacheCapabilityConfiguration(
                maxMemorySize: configuration.memoryConfig.maxSize,
                maxItemCount: configuration.memoryConfig.maxItems,
                defaultTTL: configuration.memoryConfig.ttl,
                enableCompression: configuration.compressionEnabled
            )
            memoryCache = MemoryCacheCapabilityResource(configuration: memoryConfig)
            try await memoryCache?.allocate()
        }
        
        // Initialize disk cache if needed
        if configuration.strategy != .memoryOnly {
            let diskConfig = DiskCacheCapabilityConfiguration(
                maxDiskSize: configuration.diskConfig.maxSize,
                maxItemCount: configuration.diskConfig.maxItems,
                defaultTTL: configuration.diskConfig.ttl,
                enableCompression: configuration.compressionEnabled,
                enableEncryption: configuration.encryptionEnabled
            )
            diskCache = DiskCacheCapabilityResource(configuration: diskConfig)
            try await diskCache?.allocate()
        }
        
        // Start sync timer for deferred operations
        if configuration.syncStrategy != .immediate {
            await startSyncTimer()
        }
    }
    
    public func deallocate() async {
        syncTimer?.invalidate()
        syncTimer = nil
        
        // Flush pending sync operations
        await flushSyncQueue()
        
        await memoryCache?.deallocate()
        await diskCache?.deallocate()
        
        memoryCache = nil
        diskCache = nil
        
        operationQueue.cancelAllOperations()
        syncQueue.removeAll()
        analytics = DataCacheAnalytics()
    }
    
    public var isAllocated: Bool {
        (configuration.strategy == .diskOnly ? diskCache?.isAllocated == true : true) &&
        (configuration.strategy == .memoryOnly ? memoryCache?.isAllocated == true : true)
    }
    
    public func updateConfiguration(_ configuration: DataCacheCapabilityConfiguration) async throws {
        // Configuration updates require resource reallocation
        await deallocate()
        try await allocate()
    }
    
    // MARK: - Cache Operations
    
    public func store<T: Codable>(_ value: T, forKey key: String, dataType: DataCacheCapabilityConfiguration.DataTypeIdentifier, metadata: CachedDataItem.DataMetadata = CachedDataItem.DataMetadata(), ttl: TimeInterval? = nil) async throws {
        let startTime = Date()
        
        // Encode data
        let data = try JSONEncoder().encode(value)
        
        // Create cached item
        let expirationTime = ttl.map { Date().addingTimeInterval($0) }
        let item = CachedDataItem(
            key: key,
            dataType: dataType,
            data: data,
            metadata: metadata,
            expirationTime: expirationTime,
            isCompressed: configuration.compressionEnabled,
            isEncrypted: configuration.encryptionEnabled
        )
        
        // Store according to strategy
        try await storeItem(item)
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateStoreAnalytics(dataType: dataType.name, duration: Date().timeIntervalSince(startTime))
        }
    }
    
    public func storeData(_ data: Data, forKey key: String, dataType: DataCacheCapabilityConfiguration.DataTypeIdentifier, metadata: CachedDataItem.DataMetadata = CachedDataItem.DataMetadata(), ttl: TimeInterval? = nil) async throws {
        let startTime = Date()
        
        // Create cached item
        let expirationTime = ttl.map { Date().addingTimeInterval($0) }
        let item = CachedDataItem(
            key: key,
            dataType: dataType,
            data: data,
            metadata: metadata,
            expirationTime: expirationTime,
            isCompressed: configuration.compressionEnabled,
            isEncrypted: configuration.encryptionEnabled
        )
        
        // Store according to strategy
        try await storeItem(item)
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateStoreAnalytics(dataType: dataType.name, duration: Date().timeIntervalSince(startTime))
        }
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        let startTime = Date()
        
        guard let data = try await retrieveData(forKey: key) else {
            if configuration.enableAnalytics {
                await updateRetrieveAnalytics(hit: false, duration: Date().timeIntervalSince(startTime))
            }
            return nil
        }
        
        let result = try JSONDecoder().decode(type, from: data)
        
        if configuration.enableAnalytics {
            await updateRetrieveAnalytics(hit: true, duration: Date().timeIntervalSince(startTime))
        }
        
        return result
    }
    
    public func retrieveData(forKey key: String) async throws -> Data? {
        let startTime = Date()
        
        // Try memory cache first for tiered strategy
        if configuration.strategy == .tiered || configuration.strategy == .memoryOnly {
            if let data = await memoryCache?.retrieve(forKey: key) {
                if configuration.enableAnalytics {
                    await updateRetrieveAnalytics(hit: true, fromMemory: true, duration: Date().timeIntervalSince(startTime))
                }
                return data
            }
        }
        
        // Try disk cache
        if configuration.strategy != .memoryOnly {
            if let data = try await diskCache?.retrieve(forKey: key) {
                // Promote to memory cache if using tiered strategy
                if configuration.strategy == .tiered, let memoryCache = memoryCache {
                    await memoryCache.store(data, forKey: key)
                }
                
                if configuration.enableAnalytics {
                    await updateRetrieveAnalytics(hit: true, fromMemory: false, duration: Date().timeIntervalSince(startTime))
                }
                return data
            }
        }
        
        if configuration.enableAnalytics {
            await updateRetrieveAnalytics(hit: false, duration: Date().timeIntervalSince(startTime))
        }
        
        return nil
    }
    
    public func remove(forKey key: String) async throws {
        // Remove from both caches
        await memoryCache?.remove(forKey: key)
        await diskCache?.remove(forKey: key)
    }
    
    public func removeAll() async throws {
        await memoryCache?.removeAll()
        await diskCache?.removeAll()
        
        // Clear analytics
        if configuration.enableAnalytics {
            analytics = DataCacheAnalytics()
        }
    }
    
    public func exists(forKey key: String) async -> Bool {
        if configuration.strategy != .diskOnly {
            if await memoryCache?.exists(forKey: key) == true {
                return true
            }
        }
        
        if configuration.strategy != .memoryOnly {
            return await diskCache?.exists(forKey: key) == true
        }
        
        return false
    }
    
    public func getAllKeys() async -> [String] {
        var allKeys = Set<String>()
        
        if configuration.strategy != .diskOnly {
            let memoryKeys = await memoryCache?.getAllKeys() ?? []
            allKeys.formUnion(memoryKeys)
        }
        
        if configuration.strategy != .memoryOnly {
            let diskKeys = await diskCache?.getAllKeys() ?? []
            allKeys.formUnion(diskKeys)
        }
        
        return Array(allKeys)
    }
    
    public func getAnalytics() async -> DataCacheAnalytics {
        if configuration.enableAnalytics {
            return analytics
        } else {
            return DataCacheAnalytics()
        }
    }
    
    public func getCacheSize() async -> (memory: UInt64, disk: UInt64, total: UInt64) {
        let memorySize = await memoryCache?.getCacheSize() ?? 0
        let diskSize = await diskCache?.getCacheSize() ?? 0
        return (memory: memorySize, disk: diskSize, total: memorySize + diskSize)
    }
    
    public func getItemCount() async -> (memory: Int, disk: Int, total: Int) {
        let memoryCount = await memoryCache?.getItemCount() ?? 0
        let diskCount = await diskCache?.getItemCount() ?? 0
        return (memory: memoryCount, disk: diskCount, total: memoryCount + diskCount)
    }
    
    // MARK: - Private Methods
    
    private func storeItem(_ item: CachedDataItem) async throws {
        switch configuration.strategy {
        case .memoryOnly:
            await memoryCache?.store(item.data, forKey: item.key)
            
        case .diskOnly:
            try await diskCache?.store(item.data, forKey: item.key)
            
        case .tiered:
            // Store in memory first, then disk
            await memoryCache?.store(item.data, forKey: item.key)
            try await diskCache?.store(item.data, forKey: item.key)
            
        case .writeThrough:
            // Write to both simultaneously
            async let memoryStore = memoryCache?.store(item.data, forKey: item.key)
            async let diskStore = diskCache?.store(item.data, forKey: item.key)
            
            await memoryStore
            try await diskStore
            
        case .writeBack:
            // Write to memory immediately, disk later
            await memoryCache?.store(item.data, forKey: item.key)
            
            if configuration.syncStrategy == .immediate {
                try await diskCache?.store(item.data, forKey: item.key)
            } else {
                syncQueue.append(item)
            }
            
        case .adaptive:
            // Choose strategy based on data characteristics
            if item.size < 10_000 { // Small items go to memory
                await memoryCache?.store(item.data, forKey: item.key)
            } else { // Large items go to disk
                try await diskCache?.store(item.data, forKey: item.key)
            }
        }
    }
    
    private func startSyncTimer() async {
        let interval: TimeInterval = switch configuration.syncStrategy {
        case .immediate: return 0
        case .deferred: return 5.0
        case .batched: return 10.0
        case .background: return 60.0
        }
        
        guard interval > 0 else { return }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.flushSyncQueue()
            }
        }
    }
    
    private func flushSyncQueue() async {
        guard !syncQueue.isEmpty else { return }
        
        let itemsToSync = syncQueue
        syncQueue.removeAll()
        
        for item in itemsToSync {
            try? await diskCache?.store(item.data, forKey: item.key)
        }
    }
    
    private func updateStoreAnalytics(dataType: String, duration: TimeInterval) async {
        // Update analytics for store operations
        // Implementation would update the analytics struct
    }
    
    private func updateRetrieveAnalytics(hit: Bool, fromMemory: Bool = false, duration: TimeInterval) async {
        // Update analytics for retrieve operations
        // Implementation would update the analytics struct
    }
}

// MARK: - Data Cache Capability Implementation

/// Data cache capability providing intelligent tiered caching
public actor DataCacheCapability: DomainCapability {
    public typealias ConfigurationType = DataCacheCapabilityConfiguration
    public typealias ResourceType = DataCacheCapabilityResource
    
    private var _configuration: DataCacheCapabilityConfiguration
    private var _resources: DataCacheCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "data-cache-capability" }
    
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
    
    public var configuration: DataCacheCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: DataCacheCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: DataCacheCapabilityConfiguration = DataCacheCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = DataCacheCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: DataCacheCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid data cache configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Data cache is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Data cache doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Cache Operations
    
    /// Store typed value in data cache
    public func store<T: Codable>(_ value: T, forKey key: String, dataType: DataCacheCapabilityConfiguration.DataTypeIdentifier, metadata: CachedDataItem.DataMetadata = CachedDataItem.DataMetadata(), ttl: TimeInterval? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        try await _resources.store(value, forKey: key, dataType: dataType, metadata: metadata, ttl: ttl)
    }
    
    /// Store raw data in data cache
    public func storeData(_ data: Data, forKey key: String, dataType: DataCacheCapabilityConfiguration.DataTypeIdentifier, metadata: CachedDataItem.DataMetadata = CachedDataItem.DataMetadata(), ttl: TimeInterval? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        try await _resources.storeData(data, forKey: key, dataType: dataType, metadata: metadata, ttl: ttl)
    }
    
    /// Retrieve typed value from data cache
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return try await _resources.retrieve(type, forKey: key)
    }
    
    /// Retrieve raw data from data cache
    public func retrieveData(forKey key: String) async throws -> Data? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return try await _resources.retrieveData(forKey: key)
    }
    
    /// Remove item from data cache
    public func remove(forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        try await _resources.remove(forKey: key)
    }
    
    /// Clear all data cache
    public func removeAll() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        try await _resources.removeAll()
    }
    
    /// Check if key exists in data cache
    public func exists(forKey key: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return await _resources.exists(forKey: key)
    }
    
    /// Get all cache keys
    public func getAllKeys() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return await _resources.getAllKeys()
    }
    
    /// Get cache analytics
    public func getAnalytics() async throws -> DataCacheAnalytics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return await _resources.getAnalytics()
    }
    
    /// Get cache size information
    public func getCacheSize() async throws -> (memory: UInt64, disk: UInt64, total: UInt64) {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return await _resources.getCacheSize()
    }
    
    /// Get item count information
    public func getItemCount() async throws -> (memory: Int, disk: Int, total: Int) {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data cache capability not available")
        }
        
        return await _resources.getItemCount()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extensions

extension Data {
    var sha256: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Need to import CommonCrypto for SHA256
import CommonCrypto

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Data cache specific errors
    public static func dataCacheError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Data Cache: \(message)")
    }
    
    public static func dataCacheItemNotFound(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Data cache item not found: \(key)")
    }
    
    public static func dataCacheCorrupted(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Data cache item corrupted: \(key)")
    }
    
    public static func dataCacheStrategyUnsupported(_ strategy: String) -> AxiomCapabilityError {
        .operationFailed("Data cache strategy not supported: \(strategy)")
    }
}