import Foundation
import UIKit
import AxiomCore
import AxiomCapabilities

// MARK: - Handoff Capability Configuration

/// Configuration for Handoff capability
public struct HandoffCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableHandoff: Bool
    public let enableAutomaticSync: Bool
    public let enableUserActivity: Bool
    public let enableWebpageHandoff: Bool
    public let enableDocumentHandoff: Bool
    public let syncTimeout: TimeInterval
    public let activityTypes: Set<String>
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableBackgroundSync: Bool
    public let maxActivitiesHistory: Int
    public let compressionEnabled: Bool
    
    public init(
        enableHandoff: Bool = true,
        enableAutomaticSync: Bool = true,
        enableUserActivity: Bool = true,
        enableWebpageHandoff: Bool = true,
        enableDocumentHandoff: Bool = true,
        syncTimeout: TimeInterval = 30.0,
        activityTypes: Set<String> = [],
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableBackgroundSync: Bool = true,
        maxActivitiesHistory: Int = 100,
        compressionEnabled: Bool = true
    ) {
        self.enableHandoff = enableHandoff
        self.enableAutomaticSync = enableAutomaticSync
        self.enableUserActivity = enableUserActivity
        self.enableWebpageHandoff = enableWebpageHandoff
        self.enableDocumentHandoff = enableDocumentHandoff
        self.syncTimeout = syncTimeout
        self.activityTypes = activityTypes
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableBackgroundSync = enableBackgroundSync
        self.maxActivitiesHistory = maxActivitiesHistory
        self.compressionEnabled = compressionEnabled
    }
    
    public var isValid: Bool {
        syncTimeout > 0 && maxActivitiesHistory > 0
    }
    
    public func merged(with other: HandoffCapabilityConfiguration) -> HandoffCapabilityConfiguration {
        HandoffCapabilityConfiguration(
            enableHandoff: other.enableHandoff,
            enableAutomaticSync: other.enableAutomaticSync,
            enableUserActivity: other.enableUserActivity,
            enableWebpageHandoff: other.enableWebpageHandoff,
            enableDocumentHandoff: other.enableDocumentHandoff,
            syncTimeout: other.syncTimeout,
            activityTypes: other.activityTypes,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableBackgroundSync: other.enableBackgroundSync,
            maxActivitiesHistory: other.maxActivitiesHistory,
            compressionEnabled: other.compressionEnabled
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> HandoffCapabilityConfiguration {
        var adjustedTimeout = syncTimeout
        var adjustedLogging = enableLogging
        var adjustedBackgroundSync = enableBackgroundSync
        var adjustedHistoryLimit = maxActivitiesHistory
        
        if environment.isLowPowerMode {
            adjustedTimeout = max(syncTimeout, 60.0) // Increase timeout
            adjustedBackgroundSync = false
            adjustedHistoryLimit = min(maxActivitiesHistory, 20)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return HandoffCapabilityConfiguration(
            enableHandoff: enableHandoff,
            enableAutomaticSync: enableAutomaticSync,
            enableUserActivity: enableUserActivity,
            enableWebpageHandoff: enableWebpageHandoff,
            enableDocumentHandoff: enableDocumentHandoff,
            syncTimeout: adjustedTimeout,
            activityTypes: activityTypes,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableBackgroundSync: adjustedBackgroundSync,
            maxActivitiesHistory: adjustedHistoryLimit,
            compressionEnabled: compressionEnabled
        )
    }
}

// MARK: - Handoff Types

/// User activity information for Handoff
public struct HandoffActivity: Sendable, Identifiable, Codable {
    public let id: UUID
    public let activityType: String
    public let title: String?
    public let subtitle: String?
    public let userInfo: [String: String]
    public let webpageURL: URL?
    public let targetContentIdentifier: String?
    public let keywords: Set<String>
    public let isEligibleForHandoff: Bool
    public let isEligibleForSearch: Bool
    public let isEligibleForPublicIndexing: Bool
    public let expirationDate: Date?
    public let timestamp: Date
    public let sourceDevice: DeviceInfo
    public let priority: Priority
    
    public enum Priority: String, Sendable, Codable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case urgent = "urgent"
    }
    
    public struct DeviceInfo: Sendable, Codable {
        public let deviceName: String
        public let deviceModel: String
        public let systemVersion: String
        public let bundleIdentifier: String
        
        public init(deviceName: String, deviceModel: String, systemVersion: String, bundleIdentifier: String) {
            self.deviceName = deviceName
            self.deviceModel = deviceModel
            self.systemVersion = systemVersion
            self.bundleIdentifier = bundleIdentifier
        }
    }
    
    public init(
        activityType: String,
        title: String? = nil,
        subtitle: String? = nil,
        userInfo: [String: String] = [:],
        webpageURL: URL? = nil,
        targetContentIdentifier: String? = nil,
        keywords: Set<String> = [],
        isEligibleForHandoff: Bool = true,
        isEligibleForSearch: Bool = false,
        isEligibleForPublicIndexing: Bool = false,
        expirationDate: Date? = nil,
        priority: Priority = .normal
    ) {
        self.id = UUID()
        self.activityType = activityType
        self.title = title
        self.subtitle = subtitle
        self.userInfo = userInfo
        self.webpageURL = webpageURL
        self.targetContentIdentifier = targetContentIdentifier
        self.keywords = keywords
        self.isEligibleForHandoff = isEligibleForHandoff
        self.isEligibleForSearch = isEligibleForSearch
        self.isEligibleForPublicIndexing = isEligibleForPublicIndexing
        self.expirationDate = expirationDate
        self.timestamp = Date()
        self.priority = priority
        
        // Get device information
        self.sourceDevice = DeviceInfo(
            deviceName: UIDevice.current.name,
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "unknown"
        )
    }
    
    public var isExpired: Bool {
        if let expirationDate = expirationDate {
            return Date() > expirationDate
        }
        return false
    }
    
    public var ageInSeconds: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

/// Handoff session information
public struct HandoffSession: Sendable, Identifiable {
    public let id: UUID
    public let activity: HandoffActivity
    public let status: SessionStatus
    public let startTime: Date
    public let endTime: Date?
    public let transferredBytes: Int
    public let duration: TimeInterval?
    public let error: HandoffError?
    
    public enum SessionStatus: String, Sendable, Codable, CaseIterable {
        case initiated = "initiated"
        case connecting = "connecting"
        case transferring = "transferring"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
    }
    
    public init(
        activity: HandoffActivity,
        status: SessionStatus = .initiated,
        transferredBytes: Int = 0,
        error: HandoffError? = nil
    ) {
        self.id = UUID()
        self.activity = activity
        self.status = status
        self.startTime = Date()
        self.endTime = status.isFinished ? Date() : nil
        self.transferredBytes = transferredBytes
        self.duration = endTime?.timeIntervalSince(startTime)
        self.error = error
    }
    
    public var isFinished: Bool {
        status.isFinished
    }
    
    public var wasSuccessful: Bool {
        status == .completed
    }
}

extension HandoffSession.SessionStatus {
    public var isFinished: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .initiated, .connecting, .transferring:
            return false
        }
    }
}

/// Handoff continuation result
public struct HandoffContinuationResult: Sendable {
    public let activity: HandoffActivity
    public let success: Bool
    public let restoredState: [String: Any]?
    public let error: HandoffError?
    public let continuationTime: TimeInterval
    
    public init(
        activity: HandoffActivity,
        success: Bool,
        restoredState: [String: Any]? = nil,
        error: HandoffError? = nil,
        continuationTime: TimeInterval
    ) {
        self.activity = activity
        self.success = success
        self.restoredState = restoredState
        self.error = error
        self.continuationTime = continuationTime
    }
}

/// Handoff metrics
public struct HandoffMetrics: Sendable {
    public let totalActivities: Int
    public let successfulHandoffs: Int
    public let failedHandoffs: Int
    public let averageContinuationTime: TimeInterval
    public let totalDataTransferred: Int
    public let activitiesByType: [String: Int]
    public let deviceConnections: [String: Int]
    public let errorsByType: [String: Int]
    public let handoffFrequency: Double
    public let successRate: Double
    
    public init(
        totalActivities: Int = 0,
        successfulHandoffs: Int = 0,
        failedHandoffs: Int = 0,
        averageContinuationTime: TimeInterval = 0,
        totalDataTransferred: Int = 0,
        activitiesByType: [String: Int] = [:],
        deviceConnections: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        handoffFrequency: Double = 0,
        successRate: Double = 0
    ) {
        self.totalActivities = totalActivities
        self.successfulHandoffs = successfulHandoffs
        self.failedHandoffs = failedHandoffs
        self.averageContinuationTime = averageContinuationTime
        self.totalDataTransferred = totalDataTransferred
        self.activitiesByType = activitiesByType
        self.deviceConnections = deviceConnections
        self.errorsByType = errorsByType
        self.handoffFrequency = handoffFrequency
        self.successRate = totalActivities > 0 ? Double(successfulHandoffs) / Double(totalActivities) : 0
    }
}

// MARK: - Handoff Resource

/// Handoff resource management
public actor HandoffCapabilityResource: AxiomCapabilityResource {
    private let configuration: HandoffCapabilityConfiguration
    private var currentActivity: NSUserActivity?
    private var activityHistory: [HandoffActivity] = []
    private var sessions: [HandoffSession] = []
    private var metrics: HandoffMetrics = HandoffMetrics()
    private var activityStreamContinuation: AsyncStream<HandoffActivity>.Continuation?
    private var sessionStreamContinuation: AsyncStream<HandoffSession>.Continuation?
    private var continuationHandlers: [String: (NSUserActivity) -> Bool] = [:]
    
    public init(configuration: HandoffCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 5_000_000, // 5MB for activity management
            cpu: 1.0, // Low CPU usage for coordination
            bandwidth: 10_000_000, // 10MB for activity data transfer
            storage: 2_000_000 // 2MB for activity history
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historyMemory = activityHistory.count * 1_000
            let sessionMemory = sessions.count * 500
            
            return ResourceUsage(
                memory: historyMemory + sessionMemory + 500_000,
                cpu: currentActivity != nil ? 0.5 : 0.1,
                bandwidth: 0, // Dynamic based on active transfers
                storage: activityHistory.count * 500
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Handoff is available on iOS 8+, macOS 10.10+
        return true
    }
    
    public func release() async {
        currentActivity?.invalidate()
        currentActivity = nil
        
        activityHistory.removeAll()
        sessions.removeAll()
        continuationHandlers.removeAll()
        
        activityStreamContinuation?.finish()
        sessionStreamContinuation?.finish()
        
        metrics = HandoffMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Setup handoff delegates and notifications
        await setupHandoffObservers()
    }
    
    internal func updateConfiguration(_ configuration: HandoffCapabilityConfiguration) async throws {
        // Configuration updates don't require restart for handoff
    }
    
    // MARK: - Activity Streams
    
    public var activityStream: AsyncStream<HandoffActivity> {
        AsyncStream { continuation in
            self.activityStreamContinuation = continuation
        }
    }
    
    public var sessionStream: AsyncStream<HandoffSession> {
        AsyncStream { continuation in
            self.sessionStreamContinuation = continuation
        }
    }
    
    // MARK: - Activity Management
    
    public func createActivity(_ activity: HandoffActivity) async throws -> NSUserActivity {
        guard configuration.enableHandoff else {
            throw HandoffError.handoffDisabled
        }
        
        let userActivity = NSUserActivity(activityType: activity.activityType)
        userActivity.title = activity.title
        userActivity.userInfo = activity.userInfo
        userActivity.webpageURL = activity.webpageURL
        userActivity.targetContentIdentifier = activity.targetContentIdentifier
        userActivity.keywords = activity.keywords
        userActivity.isEligibleForHandoff = activity.isEligibleForHandoff && configuration.enableUserActivity
        userActivity.isEligibleForSearch = activity.isEligibleForSearch
        userActivity.isEligibleForPublicIndexing = activity.isEligibleForPublicIndexing
        userActivity.expirationDate = activity.expirationDate
        
        currentActivity = userActivity
        activityHistory.append(activity)
        await trimActivityHistory()
        
        activityStreamContinuation?.yield(activity)
        
        await updateActivityMetrics(activity)
        
        if configuration.enableLogging {
            await logActivity(activity, action: "Created")
        }
        
        return userActivity
    }
    
    public func updateCurrentActivity(_ activity: HandoffActivity) async throws {
        guard let currentActivity = currentActivity else {
            throw HandoffError.noActiveActivity
        }
        
        currentActivity.title = activity.title
        currentActivity.userInfo = activity.userInfo
        currentActivity.webpageURL = activity.webpageURL
        currentActivity.targetContentIdentifier = activity.targetContentIdentifier
        currentActivity.keywords = activity.keywords
        currentActivity.needsSave = true
        
        activityStreamContinuation?.yield(activity)
        
        if configuration.enableLogging {
            await logActivity(activity, action: "Updated")
        }
    }
    
    public func invalidateCurrentActivity() async {
        guard let currentActivity = currentActivity else { return }
        
        currentActivity.invalidate()
        self.currentActivity = nil
        
        if configuration.enableLogging {
            print("[Handoff] 🚫 Activity invalidated")
        }
    }
    
    public func getCurrentActivity() async -> HandoffActivity? {
        guard let nsActivity = currentActivity else { return nil }
        
        return HandoffActivity(
            activityType: nsActivity.activityType,
            title: nsActivity.title,
            userInfo: nsActivity.userInfo as? [String: String] ?? [:],
            webpageURL: nsActivity.webpageURL,
            targetContentIdentifier: nsActivity.targetContentIdentifier,
            keywords: nsActivity.keywords,
            isEligibleForHandoff: nsActivity.isEligibleForHandoff,
            isEligibleForSearch: nsActivity.isEligibleForSearch,
            isEligibleForPublicIndexing: nsActivity.isEligibleForPublicIndexing,
            expirationDate: nsActivity.expirationDate
        )
    }
    
    public func getActivityHistory(since: Date? = nil) async -> [HandoffActivity] {
        if let since = since {
            return activityHistory.filter { $0.timestamp >= since }
        }
        return activityHistory
    }
    
    // MARK: - Continuation Handling
    
    public func registerContinuationHandler(for activityType: String, handler: @escaping (NSUserActivity) -> Bool) async {
        continuationHandlers[activityType] = handler
    }
    
    public func unregisterContinuationHandler(for activityType: String) async {
        continuationHandlers.removeValue(forKey: activityType)
    }
    
    public func handleContinuation(_ userActivity: NSUserActivity) async -> HandoffContinuationResult {
        let startTime = Date()
        
        guard configuration.enableHandoff else {
            let error = HandoffError.handoffDisabled
            return HandoffContinuationResult(
                activity: createActivityFromNSUserActivity(userActivity),
                success: false,
                error: error,
                continuationTime: Date().timeIntervalSince(startTime)
            )
        }
        
        let activity = createActivityFromNSUserActivity(userActivity)
        
        // Check if we have a handler for this activity type
        if let handler = continuationHandlers[userActivity.activityType] {
            let success = handler(userActivity)
            let result = HandoffContinuationResult(
                activity: activity,
                success: success,
                restoredState: userActivity.userInfo,
                continuationTime: Date().timeIntervalSince(startTime)
            )
            
            await updateContinuationMetrics(result)
            
            if configuration.enableLogging {
                await logContinuation(result)
            }
            
            return result
        } else {
            let error = HandoffError.noHandlerRegistered(userActivity.activityType)
            let result = HandoffContinuationResult(
                activity: activity,
                success: false,
                error: error,
                continuationTime: Date().timeIntervalSince(startTime)
            )
            
            await updateContinuationMetrics(result)
            
            return result
        }
    }
    
    // MARK: - Session Management
    
    public func getSessions(since: Date? = nil) async -> [HandoffSession] {
        if let since = since {
            return sessions.filter { $0.startTime >= since }
        }
        return sessions
    }
    
    public func getActiveSessions() async -> [HandoffSession] {
        return sessions.filter { !$0.isFinished }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> HandoffMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = HandoffMetrics()
    }
    
    // MARK: - Private Methods
    
    private func setupHandoffObservers() async {
        // Setup app delegate methods would be called here
        // In a real implementation, this would integrate with the app delegate
    }
    
    private func createActivityFromNSUserActivity(_ userActivity: NSUserActivity) -> HandoffActivity {
        return HandoffActivity(
            activityType: userActivity.activityType,
            title: userActivity.title,
            userInfo: userActivity.userInfo as? [String: String] ?? [:],
            webpageURL: userActivity.webpageURL,
            targetContentIdentifier: userActivity.targetContentIdentifier,
            keywords: userActivity.keywords,
            isEligibleForHandoff: userActivity.isEligibleForHandoff,
            isEligibleForSearch: userActivity.isEligibleForSearch,
            isEligibleForPublicIndexing: userActivity.isEligibleForPublicIndexing,
            expirationDate: userActivity.expirationDate
        )
    }
    
    private func updateActivityMetrics(_ activity: HandoffActivity) async {
        let totalActivities = metrics.totalActivities + 1
        
        var activitiesByType = metrics.activitiesByType
        activitiesByType[activity.activityType, default: 0] += 1
        
        metrics = HandoffMetrics(
            totalActivities: totalActivities,
            successfulHandoffs: metrics.successfulHandoffs,
            failedHandoffs: metrics.failedHandoffs,
            averageContinuationTime: metrics.averageContinuationTime,
            totalDataTransferred: metrics.totalDataTransferred,
            activitiesByType: activitiesByType,
            deviceConnections: metrics.deviceConnections,
            errorsByType: metrics.errorsByType,
            handoffFrequency: metrics.handoffFrequency,
            successRate: metrics.successRate
        )
    }
    
    private func updateContinuationMetrics(_ result: HandoffContinuationResult) async {
        let successfulHandoffs = metrics.successfulHandoffs + (result.success ? 1 : 0)
        let failedHandoffs = metrics.failedHandoffs + (result.success ? 0 : 1)
        let totalHandoffs = successfulHandoffs + failedHandoffs
        
        let newAverageContinuationTime = totalHandoffs > 0 ?
            ((metrics.averageContinuationTime * Double(totalHandoffs - 1)) + result.continuationTime) / Double(totalHandoffs) :
            result.continuationTime
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        var deviceConnections = metrics.deviceConnections
        let deviceKey = result.activity.sourceDevice.deviceName
        deviceConnections[deviceKey, default: 0] += 1
        
        metrics = HandoffMetrics(
            totalActivities: metrics.totalActivities,
            successfulHandoffs: successfulHandoffs,
            failedHandoffs: failedHandoffs,
            averageContinuationTime: newAverageContinuationTime,
            totalDataTransferred: metrics.totalDataTransferred,
            activitiesByType: metrics.activitiesByType,
            deviceConnections: deviceConnections,
            errorsByType: errorsByType,
            handoffFrequency: metrics.handoffFrequency,
            successRate: totalHandoffs > 0 ? Double(successfulHandoffs) / Double(totalHandoffs) : 0
        )
    }
    
    private func trimActivityHistory() async {
        if activityHistory.count > configuration.maxActivitiesHistory {
            activityHistory = Array(activityHistory.suffix(configuration.maxActivitiesHistory))
        }
        
        // Remove expired activities
        activityHistory.removeAll { $0.isExpired }
        
        // Remove activities older than 24 hours
        let dayAgo = Date().addingTimeInterval(-86400)
        activityHistory.removeAll { $0.timestamp < dayAgo }
    }
    
    private func logActivity(_ activity: HandoffActivity, action: String) async {
        let priorityIcon = switch activity.priority {
        case .low: "🔵"
        case .normal: "🟢"
        case .high: "🟠"
        case .urgent: "🔴"
        }
        
        let title = activity.title ?? "Untitled"
        print("[Handoff] \(priorityIcon) \(action): \(activity.activityType) - \(title)")
    }
    
    private func logContinuation(_ result: HandoffContinuationResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.continuationTime)
        
        print("[Handoff] \(statusIcon) Continuation: \(result.activity.activityType) (\(timeStr)s)")
        
        if let error = result.error {
            print("[Handoff] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Handoff Capability Implementation

/// Handoff capability providing comprehensive Continuity support between Apple devices
public actor HandoffCapability: DomainCapability {
    public typealias ConfigurationType = HandoffCapabilityConfiguration
    public typealias ResourceType = HandoffCapabilityResource
    
    private var _configuration: HandoffCapabilityConfiguration
    private var _resources: HandoffCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "handoff-capability" }
    
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
    
    public var configuration: HandoffCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: HandoffCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: HandoffCapabilityConfiguration = HandoffCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = HandoffCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: HandoffCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Handoff configuration")
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
        // Handoff is supported on iOS 8+, macOS 10.10+
        return true
    }
    
    public func requestPermission() async throws {
        // Handoff doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Handoff Operations
    
    /// Create and activate a user activity for handoff
    public func createActivity(_ activity: HandoffActivity) async throws -> NSUserActivity {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return try await _resources.createActivity(activity)
    }
    
    /// Update the current active user activity
    public func updateCurrentActivity(_ activity: HandoffActivity) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        try await _resources.updateCurrentActivity(activity)
    }
    
    /// Invalidate the current user activity
    public func invalidateCurrentActivity() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        await _resources.invalidateCurrentActivity()
    }
    
    /// Get the current active user activity
    public func getCurrentActivity() async throws -> HandoffActivity? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.getCurrentActivity()
    }
    
    /// Get activity stream
    public func getActivityStream() async throws -> AsyncStream<HandoffActivity> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.activityStream
    }
    
    /// Get activity history
    public func getActivityHistory(since: Date? = nil) async throws -> [HandoffActivity] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.getActivityHistory(since: since)
    }
    
    /// Register a continuation handler for a specific activity type
    public func registerContinuationHandler(for activityType: String, handler: @escaping (NSUserActivity) -> Bool) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        await _resources.registerContinuationHandler(for: activityType, handler: handler)
    }
    
    /// Unregister a continuation handler
    public func unregisterContinuationHandler(for activityType: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        await _resources.unregisterContinuationHandler(for: activityType)
    }
    
    /// Handle incoming user activity continuation
    public func handleContinuation(_ userActivity: NSUserActivity) async throws -> HandoffContinuationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.handleContinuation(userActivity)
    }
    
    /// Get session stream
    public func getSessionStream() async throws -> AsyncStream<HandoffSession> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.sessionStream
    }
    
    /// Get session history
    public func getSessions(since: Date? = nil) async throws -> [HandoffSession] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.getSessions(since: since)
    }
    
    /// Get active sessions
    public func getActiveSessions() async throws -> [HandoffSession] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.getActiveSessions()
    }
    
    /// Get handoff metrics
    public func getMetrics() async throws -> HandoffMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Handoff capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Create a webpage handoff activity
    public func createWebpageActivity(url: URL, title: String? = nil) async throws -> NSUserActivity {
        let activity = HandoffActivity(
            activityType: NSUserActivityTypeBrowsingWeb,
            title: title ?? url.absoluteString,
            webpageURL: url,
            isEligibleForHandoff: _configuration.enableWebpageHandoff
        )
        
        return try await createActivity(activity)
    }
    
    /// Create a document handoff activity
    public func createDocumentActivity(activityType: String, documentURL: URL, title: String? = nil) async throws -> NSUserActivity {
        let activity = HandoffActivity(
            activityType: activityType,
            title: title ?? documentURL.lastPathComponent,
            targetContentIdentifier: documentURL.absoluteString,
            isEligibleForHandoff: _configuration.enableDocumentHandoff
        )
        
        return try await createActivity(activity)
    }
    
    /// Check if handoff is currently active
    public func isHandoffActive() async throws -> Bool {
        return try await getCurrentActivity() != nil
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Handoff specific errors
public enum HandoffError: Error, LocalizedError {
    case handoffDisabled
    case noActiveActivity
    case invalidActivityType(String)
    case noHandlerRegistered(String)
    case continuationFailed(String)
    case syncTimeout
    case deviceNotReachable
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .handoffDisabled:
            return "Handoff is disabled"
        case .noActiveActivity:
            return "No active user activity"
        case .invalidActivityType(let type):
            return "Invalid activity type: \(type)"
        case .noHandlerRegistered(let type):
            return "No continuation handler registered for: \(type)"
        case .continuationFailed(let reason):
            return "Handoff continuation failed: \(reason)"
        case .syncTimeout:
            return "Handoff sync timeout"
        case .deviceNotReachable:
            return "Target device not reachable"
        case .configurationError(let reason):
            return "Handoff configuration error: \(reason)"
        }
    }
}