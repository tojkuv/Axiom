import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Disk Cache Capability Configuration

/// Configuration for Disk Cache capability
public struct DiskCacheCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let cacheDirectory: CacheDirectory
    public let maxDiskSize: UInt64
    public let maxItemCount: Int
    public let evictionPolicy: EvictionPolicy
    public let enableExpiration: Bool
    public let defaultTTL: TimeInterval
    public let enableCompression: Bool
    public let compressionThreshold: UInt64
    public let enableEncryption: Bool
    public let cleanupInterval: TimeInterval
    public let enableIndexing: Bool
    
    public enum CacheDirectory: String, Codable, CaseIterable {
        case caches = "Caches"
        case documents = "Documents"
        case temporary = "tmp"
        case applicationSupport = "Application Support"
        case custom = "Custom"
        
        public var searchPathDirectory: FileManager.SearchPathDirectory {
            switch self {
            case .caches:
                return .cachesDirectory
            case .documents:
                return .documentDirectory
            case .temporary:
                return .itemReplacementDirectory
            case .applicationSupport:
                return .applicationSupportDirectory
            case .custom:
                return .cachesDirectory
            }
        }
    }
    
    public enum EvictionPolicy: String, Codable, CaseIterable {
        case lru = "least-recently-used"
        case lfu = "least-frequently-used"
        case fifo = "first-in-first-out"
        case size = "largest-first"
        case ttl = "time-to-live"
    }
    
    public init(
        cacheDirectory: CacheDirectory = .caches,
        maxDiskSize: UInt64 = 500 * 1024 * 1024, // 500MB
        maxItemCount: Int = 10000,
        evictionPolicy: EvictionPolicy = .lru,
        enableExpiration: Bool = true,
        defaultTTL: TimeInterval = 86400, // 24 hours
        enableCompression: Bool = true,
        compressionThreshold: UInt64 = 1024, // 1KB
        enableEncryption: Bool = false,
        cleanupInterval: TimeInterval = 3600, // 1 hour
        enableIndexing: Bool = true
    ) {
        self.cacheDirectory = cacheDirectory
        self.maxDiskSize = maxDiskSize
        self.maxItemCount = maxItemCount
        self.evictionPolicy = evictionPolicy
        self.enableExpiration = enableExpiration
        self.defaultTTL = defaultTTL
        self.enableCompression = enableCompression
        self.compressionThreshold = compressionThreshold
        self.enableEncryption = enableEncryption
        self.cleanupInterval = cleanupInterval
        self.enableIndexing = enableIndexing
    }
    
    public var isValid: Bool {
        maxDiskSize > 0 && maxItemCount > 0 && defaultTTL > 0 && cleanupInterval > 0
    }
    
    public func merged(with other: DiskCacheCapabilityConfiguration) -> DiskCacheCapabilityConfiguration {
        DiskCacheCapabilityConfiguration(
            cacheDirectory: other.cacheDirectory,
            maxDiskSize: other.maxDiskSize,
            maxItemCount: other.maxItemCount,
            evictionPolicy: other.evictionPolicy,
            enableExpiration: other.enableExpiration,
            defaultTTL: other.defaultTTL,
            enableCompression: other.enableCompression,
            compressionThreshold: other.compressionThreshold,
            enableEncryption: other.enableEncryption,
            cleanupInterval: other.cleanupInterval,
            enableIndexing: other.enableIndexing
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> DiskCacheCapabilityConfiguration {
        var adjustedDiskSize = maxDiskSize
        var adjustedItemCount = maxItemCount
        var adjustedTTL = defaultTTL
        var adjustedEncryption = enableEncryption
        
        if environment.isLowPowerMode {
            adjustedDiskSize = min(maxDiskSize, 100 * 1024 * 1024) // 100MB limit
            adjustedItemCount = min(maxItemCount, 1000)
            adjustedTTL = min(defaultTTL, 3600) // 1 hour
        }
        
        if environment.isDebug {
            adjustedEncryption = false // Disable encryption in debug for easier inspection
        }
        
        return DiskCacheCapabilityConfiguration(
            cacheDirectory: cacheDirectory,
            maxDiskSize: adjustedDiskSize,
            maxItemCount: adjustedItemCount,
            evictionPolicy: evictionPolicy,
            enableExpiration: enableExpiration,
            defaultTTL: adjustedTTL,
            enableCompression: enableCompression,
            compressionThreshold: compressionThreshold,
            enableEncryption: adjustedEncryption,
            cleanupInterval: cleanupInterval,
            enableIndexing: enableIndexing
        )
    }
}

// MARK: - Disk Cache Item

/// Disk cached item with metadata
public struct DiskCacheItem: Sendable, Codable {
    public let key: String
    public let fileName: String
    public let size: UInt64
    public let creationTime: Date
    public let lastAccessTime: Date
    public let accessCount: Int
    public let expirationTime: Date?
    public let isCompressed: Bool
    public let isEncrypted: Bool
    public let checksum: String
    
    public init(
        key: String,
        fileName: String,
        size: UInt64,
        creationTime: Date = Date(),
        lastAccessTime: Date = Date(),
        accessCount: Int = 0,
        expirationTime: Date? = nil,
        isCompressed: Bool = false,
        isEncrypted: Bool = false,
        checksum: String = ""
    ) {
        self.key = key
        self.fileName = fileName
        self.size = size
        self.creationTime = creationTime
        self.lastAccessTime = lastAccessTime
        self.accessCount = accessCount
        self.expirationTime = expirationTime
        self.isCompressed = isCompressed
        self.isEncrypted = isEncrypted
        self.checksum = checksum
    }
    
    public var isExpired: Bool {
        guard let expirationTime = expirationTime else { return false }
        return Date() > expirationTime
    }
    
    public func accessed() -> DiskCacheItem {
        DiskCacheItem(
            key: key,
            fileName: fileName,
            size: size,
            creationTime: creationTime,
            lastAccessTime: Date(),
            accessCount: accessCount + 1,
            expirationTime: expirationTime,
            isCompressed: isCompressed,
            isEncrypted: isEncrypted,
            checksum: checksum
        )
    }
}

// MARK: - Disk Cache Index

/// Disk cache index for fast lookups
public struct DiskCacheIndex: Sendable, Codable {
    public private(set) var items: [String: DiskCacheItem] = [:]
    public private(set) var totalSize: UInt64 = 0
    public private(set) var lastCleanupTime: Date = Date()
    
    public mutating func addItem(_ item: DiskCacheItem) {
        if let existingItem = items[item.key] {
            totalSize -= existingItem.size
        }
        items[item.key] = item
        totalSize += item.size
    }
    
    public mutating func removeItem(forKey key: String) {
        if let item = items.removeValue(forKey: key) {
            totalSize -= item.size
        }
    }
    
    public mutating func updateLastCleanupTime() {
        lastCleanupTime = Date()
    }
    
    public mutating func clear() {
        items.removeAll()
        totalSize = 0
    }
}

// MARK: - Disk Cache Resource

/// Disk cache resource management
public actor DiskCacheCapabilityResource: AxiomCapabilityResource {
    private let configuration: DiskCacheCapabilityConfiguration
    private var cacheDirectory: URL?
    private var index = DiskCacheIndex()
    private let fileManager = FileManager.default
    private var cleanupTimer: Timer?
    private let operationQueue = OperationQueue()
    
    public init(configuration: DiskCacheCapabilityConfiguration) {
        self.configuration = configuration
        self.operationQueue.maxConcurrentOperationCount = 4
        self.operationQueue.qualityOfService = .utility
    }
    
    public func allocate() async throws {
        // Create cache directory
        let searchPath = configuration.cacheDirectory.searchPathDirectory
        let urls = fileManager.urls(for: searchPath, in: .userDomainMask)
        
        guard let baseURL = urls.first else {
            throw AxiomCapabilityError.initializationFailed("Failed to get cache directory URL")
        }
        
        cacheDirectory = baseURL.appendingPathComponent("AxiomDiskCache")
        
        try fileManager.createDirectory(at: cacheDirectory!, withIntermediateDirectories: true, attributes: nil)
        
        // Load existing index
        try await loadIndex()
        
        // Start cleanup timer
        await startCleanupTimer()
        
        // Initial cleanup
        await performCleanup()
    }
    
    public func deallocate() async {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        operationQueue.cancelAllOperations()
        
        // Save index
        try? await saveIndex()
        
        cacheDirectory = nil
        index.clear()
    }
    
    public var isAllocated: Bool {
        cacheDirectory != nil
    }
    
    public func updateConfiguration(_ configuration: DiskCacheCapabilityConfiguration) async throws {
        // Disk cache configuration changes require cleanup
        await performCleanup()
    }
    
    // MARK: - Cache Operations
    
    public func store(_ data: Data, forKey key: String, ttl: TimeInterval? = nil) async throws {
        guard let cacheDirectory = cacheDirectory else {
            throw AxiomCapabilityError.resourceAllocationFailed("Cache directory not available")
        }
        
        let fileName = generateFileName(for: key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Process data (compress, encrypt)
        let (finalData, isCompressed, isEncrypted) = await processDataForStorage(data)
        
        // Calculate checksum
        let checksum = finalData.sha256
        
        // Write to disk
        try finalData.write(to: fileURL)
        
        // Create cache item
        let expirationTime = configuration.enableExpiration ? 
            Date().addingTimeInterval(ttl ?? configuration.defaultTTL) : nil
        
        let item = DiskCacheItem(
            key: key,
            fileName: fileName,
            size: UInt64(finalData.count),
            expirationTime: expirationTime,
            isCompressed: isCompressed,
            isEncrypted: isEncrypted,
            checksum: checksum
        )
        
        // Update index
        index.addItem(item)
        
        // Save index if enabled
        if configuration.enableIndexing {
            try await saveIndex()
        }
        
        // Enforce constraints
        await enforceConstraints()
    }
    
    public func retrieve(forKey key: String) async throws -> Data? {
        guard let cacheDirectory = cacheDirectory else {
            throw AxiomCapabilityError.resourceAllocationFailed("Cache directory not available")
        }
        
        guard var item = index.items[key] else {
            return nil
        }
        
        // Check expiration
        if item.isExpired {
            await removeItem(forKey: key)
            return nil
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(item.fileName)
        
        // Check file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // File missing, remove from index
            index.removeItem(forKey: key)
            if configuration.enableIndexing {
                try? await saveIndex()
            }
            return nil
        }
        
        // Read data
        let data = try Data(contentsOf: fileURL)
        
        // Verify checksum
        if !item.checksum.isEmpty && data.sha256 != item.checksum {
            // Corrupted file, remove it
            await removeItem(forKey: key)
            throw AxiomCapabilityError.operationFailed("Cache file corrupted: \(key)")
        }
        
        // Update access tracking
        item = item.accessed()
        index.addItem(item)
        
        if configuration.enableIndexing {
            try await saveIndex()
        }
        
        // Process data (decompress, decrypt)
        return await processDataFromStorage(data, isCompressed: item.isCompressed, isEncrypted: item.isEncrypted)
    }
    
    public func remove(forKey key: String) async {
        guard let cacheDirectory = cacheDirectory else { return }
        
        if let item = index.items[key] {
            let fileURL = cacheDirectory.appendingPathComponent(item.fileName)
            try? fileManager.removeItem(at: fileURL)
        }
        
        index.removeItem(forKey: key)
        
        if configuration.enableIndexing {
            try? await saveIndex()
        }
    }
    
    public func removeAll() async {
        guard let cacheDirectory = cacheDirectory else { return }
        
        // Remove all files
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent != "index.json" {
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            // Continue even if some files can't be removed
        }
        
        index.clear()
        
        if configuration.enableIndexing {
            try? await saveIndex()
        }
    }
    
    public func exists(forKey key: String) async -> Bool {
        guard let item = index.items[key] else { return false }
        
        if item.isExpired {
            await removeItem(forKey: key)
            return false
        }
        
        return true
    }
    
    public func getAllKeys() async -> [String] {
        // Filter out expired items
        var validKeys: [String] = []
        var expiredKeys: [String] = []
        
        for (key, item) in index.items {
            if item.isExpired {
                expiredKeys.append(key)
            } else {
                validKeys.append(key)
            }
        }
        
        // Remove expired items
        for key in expiredKeys {
            await removeItem(forKey: key)
        }
        
        return validKeys
    }
    
    public func getCacheSize() async -> UInt64 {
        index.totalSize
    }
    
    public func getItemCount() async -> Int {
        index.items.count
    }
    
    // MARK: - Private Methods
    
    private func removeItem(forKey key: String) async {
        await remove(forKey: key)
    }
    
    private func generateFileName(for key: String) -> String {
        // Use SHA256 hash of key to avoid filesystem issues
        let hash = key.data(using: .utf8)?.sha256 ?? key
        return "\(hash).cache"
    }
    
    private func processDataForStorage(_ data: Data) async -> (Data, Bool, Bool) {
        var finalData = data
        var isCompressed = false
        var isEncrypted = false
        
        // Compress if enabled and data exceeds threshold
        if configuration.enableCompression && data.count > configuration.compressionThreshold {
            do {
                finalData = try (data as NSData).compressed(using: .lz4) as Data
                isCompressed = true
            } catch {
                // Continue with uncompressed data
            }
        }
        
        // Encrypt if enabled (simplified - in production use proper encryption)
        if configuration.enableEncryption {
            // Note: This is a placeholder - implement proper encryption
            isEncrypted = true
        }
        
        return (finalData, isCompressed, isEncrypted)
    }
    
    private func processDataFromStorage(_ data: Data, isCompressed: Bool, isEncrypted: Bool) async -> Data {
        var finalData = data
        
        // Decrypt if needed
        if isEncrypted {
            // Note: This is a placeholder - implement proper decryption
        }
        
        // Decompress if needed
        if isCompressed {
            do {
                finalData = try (data as NSData).decompressed(using: .lz4) as Data
            } catch {
                // Return original data if decompression fails
            }
        }
        
        return finalData
    }
    
    private func enforceConstraints() async {
        await removeExpiredItems()
        
        while index.items.count > configuration.maxItemCount || index.totalSize > configuration.maxDiskSize {
            await evictItem()
        }
    }
    
    private func evictItem() async {
        guard !index.items.isEmpty else { return }
        
        let keyToEvict: String
        
        switch configuration.evictionPolicy {
        case .lru:
            keyToEvict = index.items.min { $0.value.lastAccessTime < $1.value.lastAccessTime }!.key
        case .lfu:
            keyToEvict = index.items.min { $0.value.accessCount < $1.value.accessCount }!.key
        case .fifo:
            keyToEvict = index.items.min { $0.value.creationTime < $1.value.creationTime }!.key
        case .size:
            keyToEvict = index.items.max { $0.value.size < $1.value.size }!.key
        case .ttl:
            keyToEvict = index.items.min { 
                let item1 = $0.value
                let item2 = $1.value
                return (item1.expirationTime ?? Date.distantFuture) < (item2.expirationTime ?? Date.distantFuture)
            }!.key
        }
        
        await removeItem(forKey: keyToEvict)
    }
    
    private func removeExpiredItems() async {
        guard configuration.enableExpiration else { return }
        
        let expiredKeys = index.items.compactMap { key, item in
            item.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            await removeItem(forKey: key)
        }
    }
    
    private func loadIndex() async throws {
        guard let cacheDirectory = cacheDirectory else { return }
        
        let indexURL = cacheDirectory.appendingPathComponent("index.json")
        
        guard fileManager.fileExists(atPath: indexURL.path) else {
            // No existing index, start fresh
            return
        }
        
        do {
            let data = try Data(contentsOf: indexURL)
            index = try JSONDecoder().decode(DiskCacheIndex.self, from: data)
        } catch {
            // Corrupted index, start fresh
            index = DiskCacheIndex()
        }
        
        // Verify files exist and update index
        await validateIndex()
    }
    
    private func saveIndex() async throws {
        guard let cacheDirectory = cacheDirectory else { return }
        
        let indexURL = cacheDirectory.appendingPathComponent("index.json")
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexURL)
    }
    
    private func validateIndex() async {
        guard let cacheDirectory = cacheDirectory else { return }
        
        var itemsToRemove: [String] = []
        
        for (key, item) in index.items {
            let fileURL = cacheDirectory.appendingPathComponent(item.fileName)
            if !fileManager.fileExists(atPath: fileURL.path) {
                itemsToRemove.append(key)
            }
        }
        
        for key in itemsToRemove {
            index.removeItem(forKey: key)
        }
        
        if !itemsToRemove.isEmpty && configuration.enableIndexing {
            try? await saveIndex()
        }
    }
    
    private func startCleanupTimer() async {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: configuration.cleanupInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performCleanup()
            }
        }
    }
    
    private func performCleanup() async {
        await removeExpiredItems()
        await enforceConstraints()
        
        index.updateLastCleanupTime()
        
        if configuration.enableIndexing {
            try? await saveIndex()
        }
    }
}

// MARK: - Disk Cache Capability Implementation

/// Disk cache capability providing persistent disk-based caching
public actor DiskCacheCapability: DomainCapability {
    public typealias ConfigurationType = DiskCacheCapabilityConfiguration
    public typealias ResourceType = DiskCacheCapabilityResource
    
    private var _configuration: DiskCacheCapabilityConfiguration
    private var _resources: DiskCacheCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "disk-cache-capability" }
    
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
    
    public var configuration: DiskCacheCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: DiskCacheCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: DiskCacheCapabilityConfiguration = DiskCacheCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = DiskCacheCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: DiskCacheCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid disk cache configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Disk cache is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Disk cache doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Cache Operations
    
    /// Store data in disk cache with optional TTL
    public func store<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        let data = try JSONEncoder().encode(value)
        try await _resources.store(data, forKey: key, ttl: ttl)
    }
    
    /// Store raw data in disk cache
    public func storeData(_ data: Data, forKey key: String, ttl: TimeInterval? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        try await _resources.store(data, forKey: key, ttl: ttl)
    }
    
    /// Retrieve typed value from disk cache
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        guard let data = try await _resources.retrieve(forKey: key) else {
            return nil
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Retrieve raw data from disk cache
    public func retrieveData(forKey key: String) async throws -> Data? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        return try await _resources.retrieve(forKey: key)
    }
    
    /// Remove item from disk cache
    public func remove(forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        await _resources.remove(forKey: key)
    }
    
    /// Clear all disk cache
    public func removeAll() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        await _resources.removeAll()
    }
    
    /// Check if key exists in disk cache
    public func exists(forKey key: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        return await _resources.exists(forKey: key)
    }
    
    /// Get all cache keys
    public func getAllKeys() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        return await _resources.getAllKeys()
    }
    
    /// Get cache statistics
    public func getCacheSize() async throws -> UInt64 {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
        }
        
        return await _resources.getCacheSize()
    }
    
    /// Get item count
    public func getItemCount() async throws -> Int {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Disk cache capability not available")
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
    /// Disk cache specific errors
    public static func diskCacheError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Disk Cache: \(message)")
    }
    
    public static func diskCacheItemNotFound(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Disk cache item not found: \(key)")
    }
    
    public static func diskCacheCorrupted(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Disk cache item corrupted: \(key)")
    }
}