import Foundation
import Network
import AxiomCore
import AxiomCapabilities

// MARK: - Offline Capability Configuration

/// Configuration for Offline capability
public struct OfflineCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let maxQueueSize: Int
    public let maxRetryAttempts: Int
    public let retryBackoffMultiplier: Double
    public let maxBackoffDelay: TimeInterval
    public let enablePersistentQueue: Bool
    public let persistentQueuePath: URL?
    public let enableConflictResolution: Bool
    public let conflictResolutionStrategy: ConflictResolutionStrategy
    public let syncBatchSize: Int
    public let networkTimeoutInterval: TimeInterval
    public let enableDataCompression: Bool
    public let compressionThreshold: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableBackgroundSync: Bool
    public let backgroundSyncInterval: TimeInterval
    public let enableDataDeltaSync: Bool
    public let maxCacheAge: TimeInterval
    public let enableOptimisticUpdates: Bool
    public let enableOfflineImageCaching: Bool
    public let maxOfflineCacheSize: Int64
    
    public enum ConflictResolutionStrategy: String, Codable, CaseIterable {
        case clientWins = "client-wins"
        case serverWins = "server-wins"
        case lastModifiedWins = "last-modified-wins"
        case manual = "manual"
        case merge = "merge"
    }
    
    public init(
        maxQueueSize: Int = 1000,
        maxRetryAttempts: Int = 5,
        retryBackoffMultiplier: Double = 2.0,
        maxBackoffDelay: TimeInterval = 300.0, // 5 minutes
        enablePersistentQueue: Bool = true,
        persistentQueuePath: URL? = nil,
        enableConflictResolution: Bool = true,
        conflictResolutionStrategy: ConflictResolutionStrategy = .lastModifiedWins,
        syncBatchSize: Int = 50,
        networkTimeoutInterval: TimeInterval = 30.0,
        enableDataCompression: Bool = true,
        compressionThreshold: Int = 1024, // 1KB
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableBackgroundSync: Bool = true,
        backgroundSyncInterval: TimeInterval = 300.0, // 5 minutes
        enableDataDeltaSync: Bool = true,
        maxCacheAge: TimeInterval = 86400.0, // 24 hours
        enableOptimisticUpdates: Bool = true,
        enableOfflineImageCaching: Bool = true,
        maxOfflineCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    ) {
        self.maxQueueSize = maxQueueSize
        self.maxRetryAttempts = maxRetryAttempts
        self.retryBackoffMultiplier = retryBackoffMultiplier
        self.maxBackoffDelay = maxBackoffDelay
        self.enablePersistentQueue = enablePersistentQueue
        self.persistentQueuePath = persistentQueuePath
        self.enableConflictResolution = enableConflictResolution
        self.conflictResolutionStrategy = conflictResolutionStrategy
        self.syncBatchSize = syncBatchSize
        self.networkTimeoutInterval = networkTimeoutInterval
        self.enableDataCompression = enableDataCompression
        self.compressionThreshold = compressionThreshold
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableBackgroundSync = enableBackgroundSync
        self.backgroundSyncInterval = backgroundSyncInterval
        self.enableDataDeltaSync = enableDataDeltaSync
        self.maxCacheAge = maxCacheAge
        self.enableOptimisticUpdates = enableOptimisticUpdates
        self.enableOfflineImageCaching = enableOfflineImageCaching
        self.maxOfflineCacheSize = maxOfflineCacheSize
    }
    
    public var isValid: Bool {
        maxQueueSize > 0 && 
        maxRetryAttempts >= 0 && 
        retryBackoffMultiplier > 0 && 
        maxBackoffDelay > 0 && 
        syncBatchSize > 0 && 
        networkTimeoutInterval > 0 &&
        maxCacheAge > 0 &&
        maxOfflineCacheSize > 0
    }
    
    public func merged(with other: OfflineCapabilityConfiguration) -> OfflineCapabilityConfiguration {
        OfflineCapabilityConfiguration(
            maxQueueSize: other.maxQueueSize,
            maxRetryAttempts: other.maxRetryAttempts,
            retryBackoffMultiplier: other.retryBackoffMultiplier,
            maxBackoffDelay: other.maxBackoffDelay,
            enablePersistentQueue: other.enablePersistentQueue,
            persistentQueuePath: other.persistentQueuePath ?? persistentQueuePath,
            enableConflictResolution: other.enableConflictResolution,
            conflictResolutionStrategy: other.conflictResolutionStrategy,
            syncBatchSize: other.syncBatchSize,
            networkTimeoutInterval: other.networkTimeoutInterval,
            enableDataCompression: other.enableDataCompression,
            compressionThreshold: other.compressionThreshold,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableBackgroundSync: other.enableBackgroundSync,
            backgroundSyncInterval: other.backgroundSyncInterval,
            enableDataDeltaSync: other.enableDataDeltaSync,
            maxCacheAge: other.maxCacheAge,
            enableOptimisticUpdates: other.enableOptimisticUpdates,
            enableOfflineImageCaching: other.enableOfflineImageCaching,
            maxOfflineCacheSize: other.maxOfflineCacheSize
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> OfflineCapabilityConfiguration {
        var adjustedQueueSize = maxQueueSize
        var adjustedSyncBatch = syncBatchSize
        var adjustedLogging = enableLogging
        var adjustedBackgroundSync = enableBackgroundSync
        var adjustedCacheSize = maxOfflineCacheSize
        
        if environment.isLowPowerMode {
            adjustedQueueSize = min(maxQueueSize, 100)
            adjustedSyncBatch = min(syncBatchSize, 10)
            adjustedBackgroundSync = false
            adjustedCacheSize = min(maxOfflineCacheSize, 10 * 1024 * 1024) // 10MB
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return OfflineCapabilityConfiguration(
            maxQueueSize: adjustedQueueSize,
            maxRetryAttempts: maxRetryAttempts,
            retryBackoffMultiplier: retryBackoffMultiplier,
            maxBackoffDelay: maxBackoffDelay,
            enablePersistentQueue: enablePersistentQueue,
            persistentQueuePath: persistentQueuePath,
            enableConflictResolution: enableConflictResolution,
            conflictResolutionStrategy: conflictResolutionStrategy,
            syncBatchSize: adjustedSyncBatch,
            networkTimeoutInterval: networkTimeoutInterval,
            enableDataCompression: enableDataCompression,
            compressionThreshold: compressionThreshold,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableBackgroundSync: adjustedBackgroundSync,
            backgroundSyncInterval: backgroundSyncInterval,
            enableDataDeltaSync: enableDataDeltaSync,
            maxCacheAge: maxCacheAge,
            enableOptimisticUpdates: enableOptimisticUpdates,
            enableOfflineImageCaching: enableOfflineImageCaching,
            maxOfflineCacheSize: adjustedCacheSize
        )
    }
}

// MARK: - Offline Types

/// Network connectivity status
public enum NetworkStatus: Sendable {
    case online
    case offline
    case limited
    case unknown
}

/// Offline request that needs to be synced
public struct OfflineRequest: Sendable, Codable, Identifiable {
    public let id: UUID
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    public let priority: RequestPriority
    public let createdAt: Date
    public let retryCount: Int
    public let lastAttempt: Date?
    public let isOptimistic: Bool
    public let metadata: [String: String]
    
    public enum HTTPMethod: String, Codable, CaseIterable {
        case GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
    }
    
    public enum RequestPriority: Int, Codable, CaseIterable, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        public static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    public init(
        url: URL,
        method: HTTPMethod,
        headers: [String: String] = [:],
        body: Data? = nil,
        priority: RequestPriority = .normal,
        isOptimistic: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.priority = priority
        self.createdAt = Date()
        self.retryCount = 0
        self.lastAttempt = nil
        self.isOptimistic = isOptimistic
        self.metadata = metadata
    }
    
    public func withRetry() -> OfflineRequest {
        OfflineRequest(
            id: id,
            url: url,
            method: method,
            headers: headers,
            body: body,
            priority: priority,
            createdAt: createdAt,
            retryCount: retryCount + 1,
            lastAttempt: Date(),
            isOptimistic: isOptimistic,
            metadata: metadata
        )
    }
    
    private init(
        id: UUID,
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        priority: RequestPriority,
        createdAt: Date,
        retryCount: Int,
        lastAttempt: Date?,
        isOptimistic: Bool,
        metadata: [String: String]
    ) {
        self.id = id
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.priority = priority
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
        self.isOptimistic = isOptimistic
        self.metadata = metadata
    }
}

/// Sync result for offline requests
public struct SyncResult: Sendable {
    public let request: OfflineRequest
    public let success: Bool
    public let response: HTTPURLResponse?
    public let data: Data?
    public let error: Error?
    public let duration: TimeInterval
    public let conflictDetected: Bool
    
    public init(
        request: OfflineRequest,
        success: Bool,
        response: HTTPURLResponse? = nil,
        data: Data? = nil,
        error: Error? = nil,
        duration: TimeInterval,
        conflictDetected: Bool = false
    ) {
        self.request = request
        self.success = success
        self.response = response
        self.data = data
        self.error = error
        self.duration = duration
        self.conflictDetected = conflictDetected
    }
}

/// Offline metrics
public struct OfflineMetrics: Sendable {
    public let queueSize: Int
    public let totalRequestsQueued: Int
    public let totalRequestsSynced: Int
    public let totalSyncFailures: Int
    public let averageSyncDuration: TimeInterval
    public let conflictsDetected: Int
    public let conflictsResolved: Int
    public let networkStatusChanges: Int
    public let cacheHitRate: Double
    public let dataCompressionRatio: Double
    public let totalBytesOffline: Int64
    public let totalBytesSynced: Int64
    
    public init(
        queueSize: Int = 0,
        totalRequestsQueued: Int = 0,
        totalRequestsSynced: Int = 0,
        totalSyncFailures: Int = 0,
        averageSyncDuration: TimeInterval = 0,
        conflictsDetected: Int = 0,
        conflictsResolved: Int = 0,
        networkStatusChanges: Int = 0,
        cacheHitRate: Double = 0,
        dataCompressionRatio: Double = 0,
        totalBytesOffline: Int64 = 0,
        totalBytesSynced: Int64 = 0
    ) {
        self.queueSize = queueSize
        self.totalRequestsQueued = totalRequestsQueued
        self.totalRequestsSynced = totalRequestsSynced
        self.totalSyncFailures = totalSyncFailures
        self.averageSyncDuration = averageSyncDuration
        self.conflictsDetected = conflictsDetected
        self.conflictsResolved = conflictsResolved
        self.networkStatusChanges = networkStatusChanges
        self.cacheHitRate = cacheHitRate
        self.dataCompressionRatio = dataCompressionRatio
        self.totalBytesOffline = totalBytesOffline
        self.totalBytesSynced = totalBytesSynced
    }
    
    public var syncSuccessRate: Double {
        let totalAttempts = totalRequestsSynced + totalSyncFailures
        return totalAttempts > 0 ? Double(totalRequestsSynced) / Double(totalAttempts) : 0
    }
    
    public var conflictResolutionRate: Double {
        return conflictsDetected > 0 ? Double(conflictsResolved) / Double(conflictsDetected) : 0
    }
}

/// Cached data entry
public struct CachedData: Sendable, Codable {
    public let key: String
    public let data: Data
    public let timestamp: Date
    public let etag: String?
    public let lastModified: String?
    public let contentType: String?
    public let isCompressed: Bool
    
    public init(
        key: String,
        data: Data,
        etag: String? = nil,
        lastModified: String? = nil,
        contentType: String? = nil,
        isCompressed: Bool = false
    ) {
        self.key = key
        self.data = data
        self.timestamp = Date()
        self.etag = etag
        self.lastModified = lastModified
        self.contentType = contentType
        self.isCompressed = isCompressed
    }
    
    public var isExpired: Bool {
        // This would need access to configuration.maxCacheAge
        // For simplicity, using 24 hours
        Date().timeIntervalSince(timestamp) > 86400
    }
    
    public func isExpired(maxAge: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > maxAge
    }
}

// MARK: - Offline Resource

/// Offline resource management
public actor OfflineCapabilityResource: AxiomCapabilityResource {
    private let configuration: OfflineCapabilityConfiguration
    private var networkMonitor: NWPathMonitor?
    private var networkStatus: NetworkStatus = .unknown
    private var requestQueue: [OfflineRequest] = []
    private var offlineCache: [String: CachedData] = [:]
    private var metrics: OfflineMetrics = OfflineMetrics()
    private var networkStatusStreamContinuation: AsyncStream<NetworkStatus>.Continuation?
    private var syncResultStreamContinuation: AsyncStream<SyncResult>.Continuation?
    private var backgroundSyncTimer: Timer?
    private var isSyncing: Bool = false
    
    public init(configuration: OfflineCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxQueueSize * 50_000 + Int(configuration.maxOfflineCacheSize),
            cpu: 3.0, // Network monitoring and sync processing
            bandwidth: configuration.syncBatchSize * 100_000, // 100KB per request
            storage: Int(configuration.maxOfflineCacheSize)
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let queueMemory = requestQueue.count * 25_000
            let cacheMemory = offlineCache.values.reduce(0) { $0 + $1.data.count }
            
            return ResourceUsage(
                memory: queueMemory + cacheMemory,
                cpu: isSyncing ? 2.0 : 0.5,
                bandwidth: isSyncing ? configuration.syncBatchSize * 50_000 : 0,
                storage: cacheMemory
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // Offline capability is always available
    }
    
    public func release() async {
        networkMonitor?.cancel()
        networkMonitor = nil
        backgroundSyncTimer?.invalidate()
        backgroundSyncTimer = nil
        
        if configuration.enablePersistentQueue {
            await savePersistentQueue()
        }
        
        requestQueue.removeAll()
        offlineCache.removeAll()
        networkStatusStreamContinuation?.finish()
        syncResultStreamContinuation?.finish()
        metrics = OfflineMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        await startNetworkMonitoring()
        
        if configuration.enablePersistentQueue {
            await loadPersistentQueue()
        }
        
        if configuration.enableBackgroundSync {
            await startBackgroundSync()
        }
        
        await loadOfflineCache()
    }
    
    internal func updateConfiguration(_ configuration: OfflineCapabilityConfiguration) async throws {
        // Restart background sync if interval changed
        if configuration.enableBackgroundSync && 
           configuration.backgroundSyncInterval != self.configuration.backgroundSyncInterval {
            await startBackgroundSync()
        }
        
        // Trim queue if max size reduced
        if configuration.maxQueueSize < requestQueue.count {
            requestQueue = Array(requestQueue.prefix(configuration.maxQueueSize))
        }
        
        // Clean cache if max size reduced
        if configuration.maxOfflineCacheSize < await getCurrentCacheSize() {
            await trimCache()
        }
    }
    
    // MARK: - Network Monitoring
    
    public var networkStatusStream: AsyncStream<NetworkStatus> {
        AsyncStream { continuation in
            self.networkStatusStreamContinuation = continuation
            
            Task {
                if await self.networkStatus != .unknown {
                    continuation.yield(await self.networkStatus)
                }
            }
        }
    }
    
    public func getCurrentNetworkStatus() async -> NetworkStatus {
        networkStatus
    }
    
    // MARK: - Request Queuing
    
    public func queueRequest(_ request: OfflineRequest) async throws {
        guard requestQueue.count < configuration.maxQueueSize else {
            throw OfflineError.queueFull(configuration.maxQueueSize)
        }
        
        // Insert request based on priority
        let insertIndex = requestQueue.firstIndex { $0.priority < request.priority } ?? requestQueue.count
        requestQueue.insert(request, at: insertIndex)
        
        await updateQueueMetrics()
        
        if configuration.enableLogging {
            await logQueueOperation("QUEUED", request: request)
        }
        
        // Try immediate sync if online
        if networkStatus == .online && !isSyncing {
            await startSync()
        }
    }
    
    public func getQueuedRequests() async -> [OfflineRequest] {
        requestQueue
    }
    
    public func removeQueuedRequest(_ requestId: UUID) async {
        requestQueue.removeAll { $0.id == requestId }
        await updateQueueMetrics()
    }
    
    public func clearQueue() async {
        requestQueue.removeAll()
        await updateQueueMetrics()
    }
    
    // MARK: - Sync Operations
    
    public var syncResultStream: AsyncStream<SyncResult> {
        AsyncStream { continuation in
            self.syncResultStreamContinuation = continuation
        }
    }
    
    public func startSync() async {
        guard !isSyncing && networkStatus == .online else { return }
        
        isSyncing = true
        
        let batchSize = min(configuration.syncBatchSize, requestQueue.count)
        let batch = Array(requestQueue.prefix(batchSize))
        
        if configuration.enableLogging {
            print("[Offline] 🔄 Starting sync batch: \(batch.count) requests")
        }
        
        for request in batch {
            let result = await syncRequest(request)
            syncResultStreamContinuation?.yield(result)
            
            if result.success {
                requestQueue.removeAll { $0.id == request.id }
            } else if request.retryCount >= configuration.maxRetryAttempts {
                requestQueue.removeAll { $0.id == request.id }
                await updateSyncFailureMetrics()
            } else {
                // Update request with retry info
                if let index = requestQueue.firstIndex(where: { $0.id == request.id }) {
                    requestQueue[index] = request.withRetry()
                }
            }
        }
        
        isSyncing = false
        await updateQueueMetrics()
        
        // Continue syncing if there are more requests and we're still online
        if !requestQueue.isEmpty && networkStatus == .online {
            await startSync()
        }
    }
    
    public func forceSyncRequest(_ requestId: UUID) async -> SyncResult? {
        guard let request = requestQueue.first(where: { $0.id == requestId }) else {
            return nil
        }
        
        let result = await syncRequest(request)
        
        if result.success {
            requestQueue.removeAll { $0.id == requestId }
            await updateQueueMetrics()
        }
        
        return result
    }
    
    // MARK: - Cache Operations
    
    public func cacheData(_ data: Data, forKey key: String, headers: [String: String] = [:]) async {
        let compressedData = configuration.enableDataCompression && data.count >= configuration.compressionThreshold ? 
            await compressData(data) ?? data : data
        
        let cachedData = CachedData(
            key: key,
            data: compressedData,
            etag: headers["ETag"],
            lastModified: headers["Last-Modified"],
            contentType: headers["Content-Type"],
            isCompressed: compressedData.count < data.count
        )
        
        offlineCache[key] = cachedData
        await trimCacheIfNeeded()
        await updateCacheMetrics()
    }
    
    public func getCachedData(forKey key: String) async -> CachedData? {
        guard let cached = offlineCache[key] else { return nil }
        
        if cached.isExpired(maxAge: configuration.maxCacheAge) {
            offlineCache.removeValue(forKey: key)
            return nil
        }
        
        await updateCacheHitMetrics()
        return cached
    }
    
    public func removeCachedData(forKey key: String) async {
        offlineCache.removeValue(forKey: key)
    }
    
    public func clearCache() async {
        offlineCache.removeAll()
        await updateCacheMetrics()
    }
    
    public func getCacheSize() async -> Int64 {
        Int64(offlineCache.values.reduce(0) { $0 + $1.data.count })
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> OfflineMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = OfflineMetrics()
    }
    
    // MARK: - Private Methods
    
    private func startNetworkMonitoring() async {
        networkMonitor = NWPathMonitor()
        
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.handleNetworkStatusChange(path)
            }
        }
        
        let queue = DispatchQueue(label: "network-monitor")
        networkMonitor?.start(queue: queue)
    }
    
    private func handleNetworkStatusChange(_ path: NWPath) async {
        let newStatus: NetworkStatus
        
        switch path.status {
        case .satisfied:
            newStatus = path.isExpensive || path.isConstrained ? .limited : .online
        case .unsatisfied:
            newStatus = .offline
        case .requiresConnection:
            newStatus = .offline
        @unknown default:
            newStatus = .unknown
        }
        
        if newStatus != networkStatus {
            networkStatus = newStatus
            await updateNetworkStatusMetrics()
            networkStatusStreamContinuation?.yield(newStatus)
            
            if configuration.enableLogging {
                await logNetworkStatusChange(newStatus)
            }
            
            // Start sync when coming online
            if newStatus == .online && !requestQueue.isEmpty && !isSyncing {
                await startSync()
            }
        }
    }
    
    private func syncRequest(_ request: OfflineRequest) async -> SyncResult {
        let startTime = Date()
        
        var urlRequest = URLRequest(url: request.url, timeoutInterval: configuration.networkTimeoutInterval)
        urlRequest.httpMethod = request.method.rawValue
        
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = request.body {
            urlRequest.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            let httpResponse = response as? HTTPURLResponse
            let duration = Date().timeIntervalSince(startTime)
            
            let result = SyncResult(
                request: request,
                success: true,
                response: httpResponse,
                data: data,
                duration: duration
            )
            
            await updateSyncSuccessMetrics(duration: duration)
            
            if configuration.enableLogging {
                await logSyncResult(result)
            }
            
            return result
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            let result = SyncResult(
                request: request,
                success: false,
                error: error,
                duration: duration
            )
            
            await updateSyncFailureMetrics()
            
            if configuration.enableLogging {
                await logSyncResult(result)
            }
            
            return result
        }
    }
    
    private func startBackgroundSync() async {
        backgroundSyncTimer?.invalidate()
        
        backgroundSyncTimer = Timer.scheduledTimer(withTimeInterval: configuration.backgroundSyncInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performBackgroundSync()
            }
        }
    }
    
    private func performBackgroundSync() async {
        guard networkStatus == .online && !requestQueue.isEmpty && !isSyncing else { return }
        
        if configuration.enableLogging {
            print("[Offline] 📅 Starting background sync")
        }
        
        await startSync()
    }
    
    private func loadPersistentQueue() async {
        guard let queuePath = configuration.persistentQueuePath else { return }
        
        do {
            let data = try Data(contentsOf: queuePath)
            let decoder = JSONDecoder()
            requestQueue = try decoder.decode([OfflineRequest].self, from: data)
            
            if configuration.enableLogging {
                print("[Offline] 📂 Loaded \(requestQueue.count) requests from persistent queue")
            }
        } catch {
            if configuration.enableLogging {
                print("[Offline] ⚠️ Failed to load persistent queue: \(error)")
            }
        }
    }
    
    private func savePersistentQueue() async {
        guard let queuePath = configuration.persistentQueuePath else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(requestQueue)
            try data.write(to: queuePath)
            
            if configuration.enableLogging {
                print("[Offline] 💾 Saved \(requestQueue.count) requests to persistent queue")
            }
        } catch {
            if configuration.enableLogging {
                print("[Offline] ⚠️ Failed to save persistent queue: \(error)")
            }
        }
    }
    
    private func loadOfflineCache() async {
        // Load cached data from disk if persistent storage is enabled
        // Simplified implementation - would load from actual storage
    }
    
    private func compressData(_ data: Data) async -> Data? {
        return try? (data as NSData).compressed(using: .zlib) as Data
    }
    
    private func decompressData(_ data: Data) async -> Data? {
        return try? (data as NSData).decompressed(using: .zlib) as Data
    }
    
    private func trimCacheIfNeeded() async {
        let currentSize = await getCurrentCacheSize()
        
        if currentSize > configuration.maxOfflineCacheSize {
            await trimCache()
        }
    }
    
    private func trimCache() async {
        let sortedEntries = offlineCache.values.sorted { $0.timestamp < $1.timestamp }
        let targetSize = configuration.maxOfflineCacheSize * 3 / 4 // Trim to 75% of max size
        
        var currentSize = await getCurrentCacheSize()
        
        for entry in sortedEntries {
            if currentSize <= targetSize { break }
            
            offlineCache.removeValue(forKey: entry.key)
            currentSize -= Int64(entry.data.count)
        }
    }
    
    private func getCurrentCacheSize() async -> Int64 {
        Int64(offlineCache.values.reduce(0) { $0 + $1.data.count })
    }
    
    private func updateQueueMetrics() async {
        metrics = OfflineMetrics(
            queueSize: requestQueue.count,
            totalRequestsQueued: metrics.totalRequestsQueued + 1,
            totalRequestsSynced: metrics.totalRequestsSynced,
            totalSyncFailures: metrics.totalSyncFailures,
            averageSyncDuration: metrics.averageSyncDuration,
            conflictsDetected: metrics.conflictsDetected,
            conflictsResolved: metrics.conflictsResolved,
            networkStatusChanges: metrics.networkStatusChanges,
            cacheHitRate: metrics.cacheHitRate,
            dataCompressionRatio: metrics.dataCompressionRatio,
            totalBytesOffline: metrics.totalBytesOffline,
            totalBytesSynced: metrics.totalBytesSynced
        )
    }
    
    private func updateSyncSuccessMetrics(duration: TimeInterval) async {
        let totalSynced = metrics.totalRequestsSynced + 1
        let newAverage = ((metrics.averageSyncDuration * Double(metrics.totalRequestsSynced)) + duration) / Double(totalSynced)
        
        metrics = OfflineMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsSynced: totalSynced,
            totalSyncFailures: metrics.totalSyncFailures,
            averageSyncDuration: newAverage,
            conflictsDetected: metrics.conflictsDetected,
            conflictsResolved: metrics.conflictsResolved,
            networkStatusChanges: metrics.networkStatusChanges,
            cacheHitRate: metrics.cacheHitRate,
            dataCompressionRatio: metrics.dataCompressionRatio,
            totalBytesOffline: metrics.totalBytesOffline,
            totalBytesSynced: metrics.totalBytesSynced
        )
    }
    
    private func updateSyncFailureMetrics() async {
        metrics = OfflineMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsSynced: metrics.totalRequestsSynced,
            totalSyncFailures: metrics.totalSyncFailures + 1,
            averageSyncDuration: metrics.averageSyncDuration,
            conflictsDetected: metrics.conflictsDetected,
            conflictsResolved: metrics.conflictsResolved,
            networkStatusChanges: metrics.networkStatusChanges,
            cacheHitRate: metrics.cacheHitRate,
            dataCompressionRatio: metrics.dataCompressionRatio,
            totalBytesOffline: metrics.totalBytesOffline,
            totalBytesSynced: metrics.totalBytesSynced
        )
    }
    
    private func updateNetworkStatusMetrics() async {
        metrics = OfflineMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsSynced: metrics.totalRequestsSynced,
            totalSyncFailures: metrics.totalSyncFailures,
            averageSyncDuration: metrics.averageSyncDuration,
            conflictsDetected: metrics.conflictsDetected,
            conflictsResolved: metrics.conflictsResolved,
            networkStatusChanges: metrics.networkStatusChanges + 1,
            cacheHitRate: metrics.cacheHitRate,
            dataCompressionRatio: metrics.dataCompressionRatio,
            totalBytesOffline: metrics.totalBytesOffline,
            totalBytesSynced: metrics.totalBytesSynced
        )
    }
    
    private func updateCacheMetrics() async {
        // Update cache-related metrics
        let currentSize = await getCurrentCacheSize()
        
        metrics = OfflineMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsSynced: metrics.totalRequestsSynced,
            totalSyncFailures: metrics.totalSyncFailures,
            averageSyncDuration: metrics.averageSyncDuration,
            conflictsDetected: metrics.conflictsDetected,
            conflictsResolved: metrics.conflictsResolved,
            networkStatusChanges: metrics.networkStatusChanges,
            cacheHitRate: metrics.cacheHitRate,
            dataCompressionRatio: metrics.dataCompressionRatio,
            totalBytesOffline: currentSize,
            totalBytesSynced: metrics.totalBytesSynced
        )
    }
    
    private func updateCacheHitMetrics() async {
        // Simplified cache hit rate calculation
        let hitRate = min(1.0, metrics.cacheHitRate + 0.01)
        
        metrics = OfflineMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsSynced: metrics.totalRequestsSynced,
            totalSyncFailures: metrics.totalSyncFailures,
            averageSyncDuration: metrics.averageSyncDuration,
            conflictsDetected: metrics.conflictsDetected,
            conflictsResolved: metrics.conflictsResolved,
            networkStatusChanges: metrics.networkStatusChanges,
            cacheHitRate: hitRate,
            dataCompressionRatio: metrics.dataCompressionRatio,
            totalBytesOffline: metrics.totalBytesOffline,
            totalBytesSynced: metrics.totalBytesSynced
        )
    }
    
    private func logQueueOperation(_ operation: String, request: OfflineRequest) async {
        print("[Offline] 📝 \(operation): \(request.method.rawValue) \(request.url) (priority: \(request.priority))")
    }
    
    private func logNetworkStatusChange(_ status: NetworkStatus) async {
        let icon = switch status {
        case .online: "🟢"
        case .offline: "🔴"
        case .limited: "🟡"
        case .unknown: "⚪"
        }
        print("[Offline] \(icon) Network status: \(status)")
    }
    
    private func logSyncResult(_ result: SyncResult) async {
        let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
        print("[Offline] \(status): \(result.request.method.rawValue) \(result.request.url) (\(String(format: "%.2f", result.duration))s)")
        
        if let error = result.error {
            print("[Offline] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Offline Capability Implementation

/// Offline capability providing offline-first networking and sync
public actor OfflineCapability: DomainCapability {
    public typealias ConfigurationType = OfflineCapabilityConfiguration
    public typealias ResourceType = OfflineCapabilityResource
    
    private var _configuration: OfflineCapabilityConfiguration
    private var _resources: OfflineCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "offline-capability" }
    
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
    
    public var configuration: OfflineCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: OfflineCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: OfflineCapabilityConfiguration = OfflineCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = OfflineCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: OfflineCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Offline configuration")
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
        // Offline capability is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Offline capability doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Offline Operations
    
    /// Queue a request for offline processing
    public func queueRequest(_ request: OfflineRequest) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        try await _resources.queueRequest(request)
    }
    
    /// Queue a URL request for offline processing
    public func queueURLRequest(_ urlRequest: URLRequest, priority: OfflineRequest.RequestPriority = .normal) async throws {
        guard let url = urlRequest.url else {
            throw OfflineError.invalidRequest("URL is required")
        }
        
        let method = OfflineRequest.HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET") ?? .GET
        let headers = urlRequest.allHTTPHeaderFields ?? [:]
        let body = urlRequest.httpBody
        
        let offlineRequest = OfflineRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            priority: priority
        )
        
        try await queueRequest(offlineRequest)
    }
    
    /// Get current network status
    public func getNetworkStatus() async throws -> NetworkStatus {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.getCurrentNetworkStatus()
    }
    
    /// Get network status stream
    public func getNetworkStatusStream() async throws -> AsyncStream<NetworkStatus> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.networkStatusStream
    }
    
    /// Start manual sync
    public func startSync() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        await _resources.startSync()
    }
    
    /// Get sync result stream
    public func getSyncResultStream() async throws -> AsyncStream<SyncResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.syncResultStream
    }
    
    /// Get queued requests
    public func getQueuedRequests() async throws -> [OfflineRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.getQueuedRequests()
    }
    
    /// Force sync specific request
    public func forceSyncRequest(_ requestId: UUID) async throws -> SyncResult? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.forceSyncRequest(requestId)
    }
    
    /// Cache data for offline access
    public func cacheData(_ data: Data, forKey key: String, headers: [String: String] = [:]) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        await _resources.cacheData(data, forKey: key, headers: headers)
    }
    
    /// Get cached data
    public func getCachedData(forKey key: String) async throws -> CachedData? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.getCachedData(forKey: key)
    }
    
    /// Clear offline cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        await _resources.clearCache()
    }
    
    /// Get offline metrics
    public func getMetrics() async throws -> OfflineMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Offline capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Perform a network request with offline fallback
    public func performRequest(_ urlRequest: URLRequest, useCache: Bool = true) async throws -> (Data, URLResponse) {
        let cacheKey = urlRequest.url?.absoluteString ?? UUID().uuidString
        
        // Try to get from cache first if offline or cache requested
        if useCache, let cachedData = try await getCachedData(forKey: cacheKey) {
            let response = HTTPURLResponse(
                url: urlRequest.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": cachedData.contentType ?? "application/octet-stream"]
            )!
            
            let data = cachedData.isCompressed ? 
                await decompressData(cachedData.data) ?? cachedData.data : cachedData.data
            
            return (data, response)
        }
        
        // Try network request
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Cache the response
            if let httpResponse = response as? HTTPURLResponse {
                let headers = httpResponse.allHeaderFields.compactMapValues { $0 as? String }
                try await cacheData(data, forKey: cacheKey, headers: headers)
            }
            
            return (data, response)
            
        } catch {
            // Network failed, queue for later and check cache again
            try await queueURLRequest(urlRequest)
            
            if let cachedData = try await getCachedData(forKey: cacheKey) {
                let response = HTTPURLResponse(
                    url: urlRequest.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": cachedData.contentType ?? "application/octet-stream"]
                )!
                
                let data = cachedData.isCompressed ? 
                    await decompressData(cachedData.data) ?? cachedData.data : cachedData.data
                
                return (data, response)
            }
            
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    private func decompressData(_ data: Data) async -> Data? {
        return try? (data as NSData).decompressed(using: .zlib) as Data
    }
}

// MARK: - Error Types

/// Offline specific errors
public enum OfflineError: Error, LocalizedError {
    case queueFull(Int)
    case invalidRequest(String)
    case syncFailed(String)
    case networkUnavailable
    case cacheError(String)
    case conflictResolutionFailed(String)
    case persistentStorageError(String)
    
    public var errorDescription: String? {
        switch self {
        case .queueFull(let maxSize):
            return "Offline queue is full (max: \(maxSize))"
        case .invalidRequest(let reason):
            return "Invalid offline request: \(reason)"
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        case .networkUnavailable:
            return "Network is unavailable"
        case .cacheError(let reason):
            return "Cache error: \(reason)"
        case .conflictResolutionFailed(let reason):
            return "Conflict resolution failed: \(reason)"
        case .persistentStorageError(let reason):
            return "Persistent storage error: \(reason)"
        }
    }
}