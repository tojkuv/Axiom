import Foundation

// MARK: - Cache Configuration

/// Configuration for intelligence system caching
public struct CacheConfiguration: Sendable {
    /// Maximum number of items to cache
    public let maxSize: Int
    
    /// Time-to-live for cached items in seconds
    public let ttl: TimeInterval
    
    /// Cache eviction policy
    public let evictionPolicy: EvictionPolicy
    
    /// Memory threshold in bytes for cache management
    public let memoryThreshold: Int
    
    public init(
        maxSize: Int = 100,
        ttl: TimeInterval = 300.0, // 5 minutes
        evictionPolicy: EvictionPolicy = .lru,
        memoryThreshold: Int = 50 * 1024 * 1024 // 50MB
    ) {
        self.maxSize = maxSize
        self.ttl = ttl
        self.evictionPolicy = evictionPolicy
        self.memoryThreshold = memoryThreshold
    }
}

/// Cache eviction policies
public enum EvictionPolicy: String, CaseIterable, Sendable {
    case lru = "lru"           // Least Recently Used
    case fifo = "fifo"         // First In, First Out
    case lfu = "lfu"           // Least Frequently Used
}

// MARK: - Cached Data Types

/// Cached component with metadata
public struct CachedComponent: Sendable {
    public let id: ComponentID
    public let name: String
    public let type: String
    public let cachedAt: Date
    public let data: [String: String]
    public private(set) var accessCount: Int
    public private(set) var lastAccessed: Date
    
    public init(
        id: ComponentID,
        name: String,
        type: String,
        cachedAt: Date,
        data: [String: String],
        accessCount: Int = 0,
        lastAccessed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.cachedAt = cachedAt
        self.data = data
        self.accessCount = accessCount
        self.lastAccessed = lastAccessed ?? cachedAt
    }
    
    /// Update access statistics
    internal func updateAccess() -> CachedComponent {
        CachedComponent(
            id: id,
            name: name,
            type: type,
            cachedAt: cachedAt,
            data: data,
            accessCount: accessCount + 1,
            lastAccessed: Date()
        )
    }
    
    /// Check if this cached item is expired
    public func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }
    
    /// Estimated memory usage in bytes
    public var estimatedMemoryUsage: Int {
        let baseSize = MemoryLayout<CachedComponent>.size
        let stringSize = name.utf8.count + type.utf8.count + id.description.utf8.count
        let dataSize = data.reduce(0) { $0 + $1.key.utf8.count + $1.value.utf8.count }
        return baseSize + stringSize + dataSize
    }
}

/// Cached query result with metadata
public struct CachedQueryResult: Sendable {
    public let query: String
    public let result: QueryResult
    public let cachedAt: Date
    public private(set) var hitCount: Int
    public private(set) var lastAccessed: Date
    
    public init(
        query: String,
        result: QueryResult,
        cachedAt: Date,
        hitCount: Int = 1,
        lastAccessed: Date? = nil
    ) {
        self.query = query
        self.result = result
        self.cachedAt = cachedAt
        self.hitCount = hitCount
        self.lastAccessed = lastAccessed ?? cachedAt
    }
    
    /// Update hit statistics
    internal func updateHit() -> CachedQueryResult {
        CachedQueryResult(
            query: query,
            result: result,
            cachedAt: cachedAt,
            hitCount: hitCount + 1,
            lastAccessed: Date()
        )
    }
    
    /// Check if this cached result is expired
    public func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }
    
    /// Estimated memory usage in bytes
    public var estimatedMemoryUsage: Int {
        let baseSize = MemoryLayout<CachedQueryResult>.size
        let querySize = query.utf8.count
        return baseSize + querySize + 100 // Estimated QueryResult size
    }
}

// MARK: - Intelligence Cache Actor

/// Thread-safe intelligence component cache with LRU eviction and TTL expiration
public actor IntelligenceCache {
    private let configuration: CacheConfiguration
    private var cache: [ComponentID: CachedComponent] = [:]
    private var accessOrder: [ComponentID] = []
    private var memoryUsage: Int = 0
    
    public init(configuration: CacheConfiguration = CacheConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Cache Operations
    
    /// Cache a component with automatic eviction management
    public func cacheComponent(_ component: CachedComponent, for id: ComponentID) {
        // Remove if already exists
        if let existing = cache[id] {
            removeFromAccessOrder(id)
            memoryUsage -= existing.estimatedMemoryUsage
        }
        
        // Add to cache
        cache[id] = component
        addToAccessOrder(id)
        memoryUsage += component.estimatedMemoryUsage
        
        // Check for eviction needs
        enforceCapacityLimits()
    }
    
    /// Retrieve a cached component
    public func cachedComponent(for id: ComponentID) -> CachedComponent? {
        guard let component = cache[id] else { return nil }
        
        // Check if expired
        if component.isExpired(ttl: configuration.ttl) {
            removeComponent(for: id)
            return nil
        }
        
        // Update access statistics
        let updatedComponent = component.updateAccess()
        cache[id] = updatedComponent
        updateAccessOrder(id)
        
        return updatedComponent
    }
    
    /// Remove a specific component from cache
    public func removeComponent(for id: ComponentID) {
        if let component = cache[id] {
            cache.removeValue(forKey: id)
            removeFromAccessOrder(id)
            memoryUsage -= component.estimatedMemoryUsage
        }
    }
    
    /// Clear all cached components
    public func clearAll() {
        cache.removeAll()
        accessOrder.removeAll()
        memoryUsage = 0
    }
    
    /// Remove expired entries based on TTL
    public func invalidateExpiredEntries() {
        let expiredIDs = cache.compactMap { (id, component) in
            component.isExpired(ttl: configuration.ttl) ? id : nil
        }
        
        for id in expiredIDs {
            removeComponent(for: id)
        }
    }
    
    // MARK: - Cache Metrics
    
    /// Get current cache size (number of items)
    public func getCacheSize() -> Int {
        cache.count
    }
    
    /// Get current memory usage in bytes
    public func getMemoryUsage() -> Int {
        memoryUsage
    }
    
    /// Get maximum cache size
    public func getMaxSize() -> Int {
        configuration.maxSize
    }
    
    /// Get TTL configuration
    public func getTTL() -> TimeInterval {
        configuration.ttl
    }
    
    /// Get cache hit rate statistics
    public func getCacheStatistics() -> IntelligenceCacheStatistics {
        let totalAccess = cache.values.reduce(0) { $0 + $1.accessCount }
        let averageAge = cache.values.isEmpty ? 0 : 
            cache.values.reduce(0.0) { $0 + Date().timeIntervalSince($1.cachedAt) } / Double(cache.count)
        
        return IntelligenceCacheStatistics(
            totalItems: cache.count,
            memoryUsage: memoryUsage,
            totalAccess: totalAccess,
            averageAge: averageAge,
            oldestItem: cache.values.min { $0.cachedAt < $1.cachedAt }?.cachedAt
        )
    }
    
    // MARK: - Private Cache Management
    
    private func enforceCapacityLimits() {
        // Enforce size limit
        while cache.count > configuration.maxSize {
            evictOldestItem()
        }
        
        // Enforce memory limit
        while memoryUsage > configuration.memoryThreshold {
            evictOldestItem()
        }
    }
    
    private func evictOldestItem() {
        switch configuration.evictionPolicy {
        case .lru:
            evictLRU()
        case .fifo:
            evictFIFO()
        case .lfu:
            evictLFU()
        }
    }
    
    private func evictLRU() {
        guard let oldestID = accessOrder.first else { return }
        removeComponent(for: oldestID)
    }
    
    private func evictFIFO() {
        guard let oldestComponent = cache.values.min(by: { $0.cachedAt < $1.cachedAt }) else { return }
        removeComponent(for: oldestComponent.id)
    }
    
    private func evictLFU() {
        guard let leastUsed = cache.values.min(by: { $0.accessCount < $1.accessCount }) else { return }
        removeComponent(for: leastUsed.id)
    }
    
    private func addToAccessOrder(_ id: ComponentID) {
        accessOrder.append(id)
    }
    
    private func removeFromAccessOrder(_ id: ComponentID) {
        accessOrder.removeAll { $0 == id }
    }
    
    private func updateAccessOrder(_ id: ComponentID) {
        removeFromAccessOrder(id)
        addToAccessOrder(id)
    }
}

// MARK: - Query Result Cache Actor

/// Thread-safe query result cache with pattern-based invalidation
public actor QueryResultCache {
    private let configuration: CacheConfiguration
    private var cache: [String: CachedQueryResult] = [:]
    private var memoryUsage: Int = 0
    
    public init(configuration: CacheConfiguration = CacheConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Cache Operations
    
    /// Cache a query result
    public func cacheResult(_ result: CachedQueryResult, for query: String) {
        // Remove if already exists
        if let existing = cache[query] {
            memoryUsage -= existing.estimatedMemoryUsage
        }
        
        // Add to cache
        cache[query] = result
        memoryUsage += result.estimatedMemoryUsage
        
        // Enforce limits
        enforceCapacityLimits()
    }
    
    /// Retrieve a cached query result
    public func cachedResult(for query: String) -> CachedQueryResult? {
        guard let result = cache[query] else { return nil }
        
        // Check if expired
        if result.isExpired(ttl: configuration.ttl) {
            removeResult(for: query)
            return nil
        }
        
        // Update hit statistics
        let updatedResult = result.updateHit()
        cache[query] = updatedResult
        
        return updatedResult
    }
    
    /// Remove a specific query result from cache
    public func removeResult(for query: String) {
        if let result = cache[query] {
            cache.removeValue(forKey: query)
            memoryUsage -= result.estimatedMemoryUsage
        }
    }
    
    /// Invalidate cache entries by pattern matching
    public func invalidateByPattern(_ pattern: String) {
        let regex = try? NSRegularExpression(pattern: pattern.replacingOccurrences(of: "*", with: ".*"))
        let queriesToRemove = cache.keys.filter { query in
            guard let regex = regex else { return pattern == query }
            let range = NSRange(location: 0, length: query.utf16.count)
            return regex.firstMatch(in: query, range: range) != nil
        }
        
        for query in queriesToRemove {
            removeResult(for: query)
        }
    }
    
    /// Clear all cached results
    public func clearAll() {
        cache.removeAll()
        memoryUsage = 0
    }
    
    /// Remove expired entries based on TTL
    public func invalidateExpiredEntries() {
        let expiredQueries = cache.compactMap { (query, result) in
            result.isExpired(ttl: configuration.ttl) ? query : nil
        }
        
        for query in expiredQueries {
            removeResult(for: query)
        }
    }
    
    // MARK: - Cache Metrics
    
    /// Get current cache size
    public func getCacheSize() -> Int {
        cache.count
    }
    
    /// Get current memory usage
    public func getMemoryUsage() -> Int {
        memoryUsage
    }
    
    // MARK: - Private Management
    
    private func enforceCapacityLimits() {
        // Enforce size limit with LRU eviction
        while cache.count > configuration.maxSize {
            if let oldestQuery = cache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })?.key {
                removeResult(for: oldestQuery)
            }
        }
        
        // Enforce memory limit
        while memoryUsage > configuration.memoryThreshold {
            if let leastUsed = cache.min(by: { $0.value.hitCount < $1.value.hitCount })?.key {
                removeResult(for: leastUsed)
            }
        }
    }
}

// MARK: - Intelligence Cache Statistics

/// Statistics for intelligence cache performance monitoring
public struct IntelligenceCacheStatistics: Sendable {
    public let totalItems: Int
    public let memoryUsage: Int
    public let totalAccess: Int
    public let averageAge: TimeInterval
    public let oldestItem: Date?
    
    public init(totalItems: Int, memoryUsage: Int, totalAccess: Int, averageAge: TimeInterval, oldestItem: Date?) {
        self.totalItems = totalItems
        self.memoryUsage = memoryUsage
        self.totalAccess = totalAccess
        self.averageAge = averageAge
        self.oldestItem = oldestItem
    }
}