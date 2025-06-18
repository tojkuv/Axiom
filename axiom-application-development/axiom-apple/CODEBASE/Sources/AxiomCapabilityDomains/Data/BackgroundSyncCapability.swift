import Foundation
import BackgroundTasks
import AxiomCore
import AxiomCapabilities

// MARK: - Background Sync Capability Configuration

/// Configuration for Background Sync capability
public struct BackgroundSyncCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let syncInterval: TimeInterval
    public let maxSyncDuration: TimeInterval
    public let syncStrategy: SyncStrategy
    public let conflictResolution: ConflictResolutionStrategy
    public let batchSize: Int
    public let maxRetryAttempts: Int
    public let retryBackoffMultiplier: Double
    public let enableOfflineQueue: Bool
    public let enableCompression: Bool
    public let enableEncryption: Bool
    public let syncPriorities: [String: SyncPriority]
    public let networkRequirements: NetworkRequirements
    public let powerRequirements: PowerRequirements
    public let enableAnalytics: Bool
    
    public enum SyncStrategy: String, Codable, CaseIterable {
        case incremental = "incremental"           // Only sync changes
        case full = "full"                         // Full synchronization
        case differential = "differential"         // Delta-based sync
        case prioritized = "prioritized"          // Priority-based sync
        case adaptive = "adaptive"                // Adaptive based on conditions
    }
    
    public enum ConflictResolutionStrategy: String, Codable, CaseIterable {
        case lastWriteWins = "last-write-wins"
        case firstWriteWins = "first-write-wins"
        case merge = "merge"
        case userChooses = "user-chooses"
        case customResolver = "custom-resolver"
    }
    
    public enum SyncPriority: String, Codable, CaseIterable {
        case critical = "critical"    // Must sync immediately
        case high = "high"           // Sync as soon as possible
        case medium = "medium"       // Sync during normal cycles
        case low = "low"            // Sync when convenient
        case deferred = "deferred"   // Sync when resources available
    }
    
    public struct NetworkRequirements: Codable {
        public let requireWiFi: Bool
        public let allowMetered: Bool
        public let minimumBandwidth: UInt64
        public let maxDataUsage: UInt64
        
        public init(
            requireWiFi: Bool = false,
            allowMetered: Bool = true,
            minimumBandwidth: UInt64 = 0,
            maxDataUsage: UInt64 = 50 * 1024 * 1024 // 50MB
        ) {
            self.requireWiFi = requireWiFi
            self.allowMetered = allowMetered
            self.minimumBandwidth = minimumBandwidth
            self.maxDataUsage = maxDataUsage
        }
    }
    
    public struct PowerRequirements: Codable {
        public let requirePluggedIn: Bool
        public let minimumBatteryLevel: Double
        public let enableLowPowerMode: Bool
        
        public init(
            requirePluggedIn: Bool = false,
            minimumBatteryLevel: Double = 0.2, // 20%
            enableLowPowerMode: Bool = false
        ) {
            self.requirePluggedIn = requirePluggedIn
            self.minimumBatteryLevel = minimumBatteryLevel
            self.enableLowPowerMode = enableLowPowerMode
        }
    }
    
    public init(
        syncInterval: TimeInterval = 300,  // 5 minutes
        maxSyncDuration: TimeInterval = 30, // 30 seconds
        syncStrategy: SyncStrategy = .adaptive,
        conflictResolution: ConflictResolutionStrategy = .lastWriteWins,
        batchSize: Int = 100,
        maxRetryAttempts: Int = 3,
        retryBackoffMultiplier: Double = 2.0,
        enableOfflineQueue: Bool = true,
        enableCompression: Bool = true,
        enableEncryption: Bool = false,
        syncPriorities: [String: SyncPriority] = [:],
        networkRequirements: NetworkRequirements = NetworkRequirements(),
        powerRequirements: PowerRequirements = PowerRequirements(),
        enableAnalytics: Bool = true
    ) {
        self.syncInterval = syncInterval
        self.maxSyncDuration = maxSyncDuration
        self.syncStrategy = syncStrategy
        self.conflictResolution = conflictResolution
        self.batchSize = batchSize
        self.maxRetryAttempts = maxRetryAttempts
        self.retryBackoffMultiplier = retryBackoffMultiplier
        self.enableOfflineQueue = enableOfflineQueue
        self.enableCompression = enableCompression
        self.enableEncryption = enableEncryption
        self.syncPriorities = syncPriorities
        self.networkRequirements = networkRequirements
        self.powerRequirements = powerRequirements
        self.enableAnalytics = enableAnalytics
    }
    
    public var isValid: Bool {
        syncInterval > 0 && maxSyncDuration > 0 && batchSize > 0 && maxRetryAttempts >= 0
    }
    
    public func merged(with other: BackgroundSyncCapabilityConfiguration) -> BackgroundSyncCapabilityConfiguration {
        BackgroundSyncCapabilityConfiguration(
            syncInterval: other.syncInterval,
            maxSyncDuration: other.maxSyncDuration,
            syncStrategy: other.syncStrategy,
            conflictResolution: other.conflictResolution,
            batchSize: other.batchSize,
            maxRetryAttempts: other.maxRetryAttempts,
            retryBackoffMultiplier: other.retryBackoffMultiplier,
            enableOfflineQueue: other.enableOfflineQueue,
            enableCompression: other.enableCompression,
            enableEncryption: other.enableEncryption,
            syncPriorities: syncPriorities.merging(other.syncPriorities) { _, new in new },
            networkRequirements: other.networkRequirements,
            powerRequirements: other.powerRequirements,
            enableAnalytics: other.enableAnalytics
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> BackgroundSyncCapabilityConfiguration {
        var adjustedInterval = syncInterval
        var adjustedDuration = maxSyncDuration
        var adjustedBatchSize = batchSize
        var adjustedNetworkReqs = networkRequirements
        var adjustedPowerReqs = powerRequirements
        
        if environment.isLowPowerMode {
            adjustedInterval = max(syncInterval, 900) // At least 15 minutes
            adjustedDuration = min(maxSyncDuration, 10) // Max 10 seconds
            adjustedBatchSize = min(batchSize, 25) // Smaller batches
            adjustedNetworkReqs = NetworkRequirements(
                requireWiFi: true,
                allowMetered: false,
                minimumBandwidth: networkRequirements.minimumBandwidth,
                maxDataUsage: min(networkRequirements.maxDataUsage, 10 * 1024 * 1024) // 10MB max
            )
            adjustedPowerReqs = PowerRequirements(
                requirePluggedIn: true,
                minimumBatteryLevel: max(powerRequirements.minimumBatteryLevel, 0.5), // 50%
                enableLowPowerMode: false
            )
        }
        
        return BackgroundSyncCapabilityConfiguration(
            syncInterval: adjustedInterval,
            maxSyncDuration: adjustedDuration,
            syncStrategy: syncStrategy,
            conflictResolution: conflictResolution,
            batchSize: adjustedBatchSize,
            maxRetryAttempts: maxRetryAttempts,
            retryBackoffMultiplier: retryBackoffMultiplier,
            enableOfflineQueue: enableOfflineQueue,
            enableCompression: enableCompression,
            enableEncryption: enableEncryption,
            syncPriorities: syncPriorities,
            networkRequirements: adjustedNetworkReqs,
            powerRequirements: adjustedPowerReqs,
            enableAnalytics: enableAnalytics
        )
    }
}

// MARK: - Sync Operation

/// Represents a synchronization operation
public struct SyncOperation: Sendable, Codable, Identifiable {
    public let id: UUID
    public let entityType: String
    public let entityId: String
    public let operation: OperationType
    public let data: Data?
    public let timestamp: Date
    public let priority: BackgroundSyncCapabilityConfiguration.SyncPriority
    public let retryCount: Int
    public let lastAttempt: Date?
    public let metadata: [String: String]
    
    public enum OperationType: String, Codable, CaseIterable {
        case create = "create"
        case update = "update"
        case delete = "delete"
        case sync = "sync"
    }
    
    public init(
        entityType: String,
        entityId: String,
        operation: OperationType,
        data: Data? = nil,
        priority: BackgroundSyncCapabilityConfiguration.SyncPriority = .medium,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.data = data
        self.timestamp = Date()
        self.priority = priority
        self.retryCount = 0
        self.lastAttempt = nil
        self.metadata = metadata
    }
    
    public func withRetry() -> SyncOperation {
        SyncOperation(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            data: data,
            timestamp: timestamp,
            priority: priority,
            retryCount: retryCount + 1,
            lastAttempt: Date(),
            metadata: metadata
        )
    }
    
    private init(
        id: UUID,
        entityType: String,
        entityId: String,
        operation: OperationType,
        data: Data?,
        timestamp: Date,
        priority: BackgroundSyncCapabilityConfiguration.SyncPriority,
        retryCount: Int,
        lastAttempt: Date?,
        metadata: [String: String]
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.data = data
        self.timestamp = timestamp
        self.priority = priority
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
        self.metadata = metadata
    }
}

// MARK: - Sync Result

/// Result of a synchronization operation
public struct SyncResult: Sendable {
    public let operation: SyncOperation
    public let status: Status
    public let error: Error?
    public let conflictData: Data?
    public let syncedAt: Date
    public let duration: TimeInterval
    public let bytesTransferred: UInt64
    
    public enum Status: String, Codable, CaseIterable {
        case success = "success"
        case failed = "failed"
        case conflict = "conflict"
        case skipped = "skipped"
        case deferred = "deferred"
    }
    
    public init(
        operation: SyncOperation,
        status: Status,
        error: Error? = nil,
        conflictData: Data? = nil,
        duration: TimeInterval = 0,
        bytesTransferred: UInt64 = 0
    ) {
        self.operation = operation
        self.status = status
        self.error = error
        self.conflictData = conflictData
        self.syncedAt = Date()
        self.duration = duration
        self.bytesTransferred = bytesTransferred
    }
}

// MARK: - Sync Analytics

/// Background sync analytics and metrics
public struct BackgroundSyncAnalytics: Sendable, Codable {
    public let totalOperations: Int
    public let successfulOperations: Int
    public let failedOperations: Int
    public let conflictedOperations: Int
    public let totalBytesTransferred: UInt64
    public let averageSyncDuration: TimeInterval
    public let successRate: Double
    public let conflictRate: Double
    public let operationsByType: [String: Int]
    public let operationsByPriority: [String: Int]
    public let lastSyncTime: Date?
    public let nextScheduledSync: Date?
    public let queueSize: Int
    public let lastUpdated: Date
    
    public init(
        totalOperations: Int = 0,
        successfulOperations: Int = 0,
        failedOperations: Int = 0,
        conflictedOperations: Int = 0,
        totalBytesTransferred: UInt64 = 0,
        averageSyncDuration: TimeInterval = 0,
        operationsByType: [String: Int] = [:],
        operationsByPriority: [String: Int] = [:],
        lastSyncTime: Date? = nil,
        nextScheduledSync: Date? = nil,
        queueSize: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.totalOperations = totalOperations
        self.successfulOperations = successfulOperations
        self.failedOperations = failedOperations
        self.conflictedOperations = conflictedOperations
        self.totalBytesTransferred = totalBytesTransferred
        self.averageSyncDuration = averageSyncDuration
        self.successRate = totalOperations > 0 ? Double(successfulOperations) / Double(totalOperations) : 0
        self.conflictRate = totalOperations > 0 ? Double(conflictedOperations) / Double(totalOperations) : 0
        self.operationsByType = operationsByType
        self.operationsByPriority = operationsByPriority
        self.lastSyncTime = lastSyncTime
        self.nextScheduledSync = nextScheduledSync
        self.queueSize = queueSize
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Background Sync Resource

/// Background sync resource management
public actor BackgroundSyncCapabilityResource: AxiomCapabilityResource {
    private let configuration: BackgroundSyncCapabilityConfiguration
    private var syncQueue: [SyncOperation] = []
    private var offlineQueue: [SyncOperation] = []
    private var isScheduled: Bool = false
    private var isSyncing: Bool = false
    private var analytics = BackgroundSyncAnalytics()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let operationQueue = OperationQueue()
    
    // Delegate for custom sync operations
    public weak var syncDelegate: BackgroundSyncDelegate?
    
    public init(configuration: BackgroundSyncCapabilityConfiguration) {
        self.configuration = configuration
        self.operationQueue.maxConcurrentOperationCount = 1
        self.operationQueue.qualityOfService = .utility
    }
    
    public func allocate() async throws {
        // Register background task identifier
        if #available(iOS 13.0, *) {
            try await registerBackgroundTasks()
        }
        
        // Schedule initial sync
        await scheduleNextSync()
        
        // Load offline queue
        await loadOfflineQueue()
    }
    
    public func deallocate() async {
        operationQueue.cancelAllOperations()
        
        // End background task if active
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Save offline queue
        await saveOfflineQueue()
        
        syncQueue.removeAll()
        offlineQueue.removeAll()
        isScheduled = false
        isSyncing = false
        analytics = BackgroundSyncAnalytics()
    }
    
    public var isAllocated: Bool {
        true // Background sync is conceptually always available
    }
    
    public func updateConfiguration(_ configuration: BackgroundSyncCapabilityConfiguration) async throws {
        // Update scheduling based on new configuration
        await scheduleNextSync()
    }
    
    // MARK: - Sync Operations
    
    public func queueSyncOperation(_ operation: SyncOperation) async {
        // Add to appropriate queue based on priority
        switch operation.priority {
        case .critical:
            syncQueue.insert(operation, at: 0) // Front of queue
            await performImmediateSync()
        case .high:
            syncQueue.insert(operation, at: min(syncQueue.count, 5)) // Near front
        default:
            syncQueue.append(operation)
        }
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateQueueAnalytics()
        }
    }
    
    public func performSync() async -> [SyncResult] {
        guard !isSyncing else {
            return [] // Already syncing
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Check sync conditions
        guard await canPerformSync() else {
            return []
        }
        
        // Start background task
        await startBackgroundTask()
        defer { await endBackgroundTask() }
        
        let startTime = Date()
        var results: [SyncResult] = []
        
        // Process sync queue in batches
        let batchesToProcess = min(configuration.batchSize, syncQueue.count)
        let operationsToSync = Array(syncQueue.prefix(batchesToProcess))
        
        for operation in operationsToSync {
            let result = await performSyncOperation(operation)
            results.append(result)
            
            // Remove from queue if successful
            if result.status == .success {
                syncQueue.removeFirst()
            } else if result.status == .failed && operation.retryCount >= configuration.maxRetryAttempts {
                // Move to offline queue if retries exhausted
                syncQueue.removeFirst()
                if configuration.enableOfflineQueue {
                    offlineQueue.append(operation)
                }
            } else {
                // Update operation with retry
                syncQueue[0] = operation.withRetry()
            }
            
            // Check if we've exceeded max sync duration
            if Date().timeIntervalSince(startTime) > configuration.maxSyncDuration {
                break
            }
        }
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateSyncAnalytics(results: results, duration: Date().timeIntervalSince(startTime))
        }
        
        // Schedule next sync
        await scheduleNextSync()
        
        return results
    }
    
    public func performImmediateSync() async {
        guard await canPerformSync() else { return }
        
        // Process only critical and high priority operations
        let criticalOps = syncQueue.filter { $0.priority == .critical || $0.priority == .high }
        
        for operation in criticalOps {
            let result = await performSyncOperation(operation)
            
            if result.status == .success {
                syncQueue.removeAll { $0.id == operation.id }
            }
        }
    }
    
    public func retryFailedOperations() async -> [SyncResult] {
        guard !offlineQueue.isEmpty else { return [] }
        
        // Move offline operations back to sync queue
        let operationsToRetry = offlineQueue
        offlineQueue.removeAll()
        
        for operation in operationsToRetry {
            await queueSyncOperation(operation)
        }
        
        return await performSync()
    }
    
    public func clearSyncQueue() async {
        syncQueue.removeAll()
        offlineQueue.removeAll()
        
        if configuration.enableAnalytics {
            await updateQueueAnalytics()
        }
    }
    
    public func getSyncQueue() async -> [SyncOperation] {
        syncQueue
    }
    
    public func getOfflineQueue() async -> [SyncOperation] {
        offlineQueue
    }
    
    public func getAnalytics() async -> BackgroundSyncAnalytics {
        if configuration.enableAnalytics {
            return analytics
        } else {
            return BackgroundSyncAnalytics()
        }
    }
    
    // MARK: - Private Methods
    
    private func performSyncOperation(_ operation: SyncOperation) async -> SyncResult {
        let startTime = Date()
        
        do {
            // Use delegate if available, otherwise use default behavior
            if let delegate = syncDelegate {
                let result = try await delegate.performSync(operation: operation)
                return SyncResult(
                    operation: operation,
                    status: result.status,
                    error: result.error,
                    conflictData: result.conflictData,
                    duration: Date().timeIntervalSince(startTime),
                    bytesTransferred: result.bytesTransferred
                )
            } else {
                // Default sync behavior (placeholder)
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                return SyncResult(
                    operation: operation,
                    status: .success,
                    duration: Date().timeIntervalSince(startTime),
                    bytesTransferred: UInt64(operation.data?.count ?? 0)
                )
            }
        } catch {
            return SyncResult(
                operation: operation,
                status: .failed,
                error: error,
                duration: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private func canPerformSync() async -> Bool {
        // Check network requirements
        if configuration.networkRequirements.requireWiFi && !await isWiFiConnected() {
            return false
        }
        
        if !configuration.networkRequirements.allowMetered && await isMeteredConnection() {
            return false
        }
        
        // Check power requirements
        if configuration.powerRequirements.requirePluggedIn && !await isPluggedIn() {
            return false
        }
        
        let batteryLevel = await getBatteryLevel()
        if batteryLevel < configuration.powerRequirements.minimumBatteryLevel {
            return false
        }
        
        if !configuration.powerRequirements.enableLowPowerMode && await isLowPowerModeEnabled() {
            return false
        }
        
        return true
    }
    
    private func scheduleNextSync() async {
        guard !isScheduled else { return }
        
        isScheduled = true
        
        if #available(iOS 13.0, *) {
            await scheduleBackgroundAppRefresh()
        } else {
            await scheduleLegacyBackgroundTask()
        }
    }
    
    @available(iOS 13.0, *)
    private func registerBackgroundTasks() async throws {
        let identifier = "com.axiom.background-sync"
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            Task {
                await self.handleBackgroundAppRefresh(task as! BGAppRefreshTask)
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func scheduleBackgroundAppRefresh() async {
        let identifier = "com.axiom.background-sync"
        
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(configuration.syncInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Handle scheduling error
        }
        
        isScheduled = false
    }
    
    @available(iOS 13.0, *)
    private func handleBackgroundAppRefresh(_ task: BGAppRefreshTask) async {
        // Schedule next background refresh
        await scheduleNextSync()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform sync
        let results = await performSync()
        let success = results.allSatisfy { $0.status == .success }
        
        task.setTaskCompleted(success: success)
    }
    
    private func scheduleLegacyBackgroundTask() async {
        // For iOS < 13, use timer-based approach
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.syncInterval) {
            Task {
                await self.performSync()
                self.isScheduled = false
                await self.scheduleNextSync()
            }
        }
    }
    
    private func startBackgroundTask() async {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "AxiomBackgroundSync") {
            // Expiration handler
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }
    
    private func endBackgroundTask() async {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func loadOfflineQueue() async {
        // Load offline queue from persistent storage
        // Implementation would use UserDefaults or Core Data
    }
    
    private func saveOfflineQueue() async {
        // Save offline queue to persistent storage
        // Implementation would use UserDefaults or Core Data
    }
    
    private func updateQueueAnalytics() async {
        // Update analytics with current queue state
        // Implementation would update the analytics struct
    }
    
    private func updateSyncAnalytics(results: [SyncResult], duration: TimeInterval) async {
        // Update analytics with sync results
        // Implementation would update the analytics struct
    }
    
    // MARK: - System State Checks
    
    private func isWiFiConnected() async -> Bool {
        // Implementation would check network reachability
        true // Placeholder
    }
    
    private func isMeteredConnection() async -> Bool {
        // Implementation would check if connection is metered
        false // Placeholder
    }
    
    private func isPluggedIn() async -> Bool {
        // Implementation would check battery charging state
        UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    private func getBatteryLevel() async -> Double {
        Double(UIDevice.current.batteryLevel)
    }
    
    private func isLowPowerModeEnabled() async -> Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}

// MARK: - Background Sync Delegate

/// Delegate protocol for custom sync operations
public protocol BackgroundSyncDelegate: AnyObject, Sendable {
    func performSync(operation: SyncOperation) async throws -> SyncResult
    func resolveConflict(local: Data, remote: Data, operation: SyncOperation) async throws -> Data
}

// MARK: - Background Sync Capability Implementation

/// Background sync capability providing automated data synchronization
public actor BackgroundSyncCapability: ExternalServiceCapability {
    public typealias ConfigurationType = BackgroundSyncCapabilityConfiguration
    public typealias ResourceType = BackgroundSyncCapabilityResource
    
    private var _configuration: BackgroundSyncCapabilityConfiguration
    private var _resources: BackgroundSyncCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(30)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "background-sync-capability" }
    
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
    
    public var configuration: BackgroundSyncCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: BackgroundSyncCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: BackgroundSyncCapabilityConfiguration = BackgroundSyncCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = BackgroundSyncCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: BackgroundSyncCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid background sync configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Background sync is available on iOS and macOS
        #if os(iOS) || os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    public func requestPermission() async throws {
        // Background sync requires background app refresh permission
        // This would typically be handled at the app level
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Sync Operations
    
    /// Queue a sync operation
    public func queueSyncOperation(_ operation: SyncOperation) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        await _resources.queueSyncOperation(operation)
    }
    
    /// Perform manual sync
    public func performSync() async throws -> [SyncResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        return await _resources.performSync()
    }
    
    /// Perform immediate sync for critical operations
    public func performImmediateSync() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        await _resources.performImmediateSync()
    }
    
    /// Retry failed operations
    public func retryFailedOperations() async throws -> [SyncResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        return await _resources.retryFailedOperations()
    }
    
    /// Clear sync queue
    public func clearSyncQueue() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        await _resources.clearSyncQueue()
    }
    
    /// Get current sync queue
    public func getSyncQueue() async throws -> [SyncOperation] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        return await _resources.getSyncQueue()
    }
    
    /// Get offline queue
    public func getOfflineQueue() async throws -> [SyncOperation] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        return await _resources.getOfflineQueue()
    }
    
    /// Get sync analytics
    public func getAnalytics() async throws -> BackgroundSyncAnalytics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        return await _resources.getAnalytics()
    }
    
    /// Set sync delegate
    public func setSyncDelegate(_ delegate: BackgroundSyncDelegate?) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Background sync capability not available")
        }
        
        _resources.syncDelegate = delegate
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
    /// Background sync specific errors
    public static func backgroundSyncError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Background Sync: \(message)")
    }
    
    public static func syncConflict(_ operation: String) -> AxiomCapabilityError {
        .operationFailed("Sync conflict detected: \(operation)")
    }
    
    public static func syncConditionsNotMet(_ reason: String) -> AxiomCapabilityError {
        .operationFailed("Sync conditions not met: \(reason)")
    }
    
    public static func backgroundTaskRegistrationFailed() -> AxiomCapabilityError {
        .initializationFailed("Failed to register background task")
    }
}