import Foundation
import WidgetKit
import SwiftUI
import AxiomCore
import AxiomCapabilities

// MARK: - Widget Capability Configuration

/// Configuration for Widget capability
public struct WidgetCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableWidgets: Bool
    public let enableTimelineUpdates: Bool
    public let enableDynamicConfiguration: Bool
    public let supportedFamilies: Set<String>
    public let maxTimelineEntries: Int
    public let timelineUpdateInterval: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableBackgroundUpdates: Bool
    public let cacheEntries: Bool
    public let compressionEnabled: Bool
    
    public init(
        enableWidgets: Bool = true,
        enableTimelineUpdates: Bool = true,
        enableDynamicConfiguration: Bool = true,
        supportedFamilies: Set<String> = ["systemSmall", "systemMedium", "systemLarge"],
        maxTimelineEntries: Int = 100,
        timelineUpdateInterval: TimeInterval = 900.0, // 15 minutes
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableBackgroundUpdates: Bool = true,
        cacheEntries: Bool = true,
        compressionEnabled: Bool = true
    ) {
        self.enableWidgets = enableWidgets
        self.enableTimelineUpdates = enableTimelineUpdates
        self.enableDynamicConfiguration = enableDynamicConfiguration
        self.supportedFamilies = supportedFamilies
        self.maxTimelineEntries = maxTimelineEntries
        self.timelineUpdateInterval = timelineUpdateInterval
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableBackgroundUpdates = enableBackgroundUpdates
        self.cacheEntries = cacheEntries
        self.compressionEnabled = compressionEnabled
    }
    
    public var isValid: Bool {
        maxTimelineEntries > 0 && timelineUpdateInterval > 0
    }
    
    public func merged(with other: WidgetCapabilityConfiguration) -> WidgetCapabilityConfiguration {
        WidgetCapabilityConfiguration(
            enableWidgets: other.enableWidgets,
            enableTimelineUpdates: other.enableTimelineUpdates,
            enableDynamicConfiguration: other.enableDynamicConfiguration,
            supportedFamilies: other.supportedFamilies,
            maxTimelineEntries: other.maxTimelineEntries,
            timelineUpdateInterval: other.timelineUpdateInterval,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableBackgroundUpdates: other.enableBackgroundUpdates,
            cacheEntries: other.cacheEntries,
            compressionEnabled: other.compressionEnabled
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> WidgetCapabilityConfiguration {
        var adjustedInterval = timelineUpdateInterval
        var adjustedLogging = enableLogging
        var adjustedBackgroundUpdates = enableBackgroundUpdates
        var adjustedMaxEntries = maxTimelineEntries
        
        if environment.isLowPowerMode {
            adjustedInterval = max(timelineUpdateInterval, 3600.0) // Increase to 1 hour minimum
            adjustedBackgroundUpdates = false
            adjustedMaxEntries = min(maxTimelineEntries, 20)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return WidgetCapabilityConfiguration(
            enableWidgets: enableWidgets,
            enableTimelineUpdates: enableTimelineUpdates,
            enableDynamicConfiguration: enableDynamicConfiguration,
            supportedFamilies: supportedFamilies,
            maxTimelineEntries: adjustedMaxEntries,
            timelineUpdateInterval: adjustedInterval,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableBackgroundUpdates: adjustedBackgroundUpdates,
            cacheEntries: cacheEntries,
            compressionEnabled: compressionEnabled
        )
    }
}

// MARK: - Widget Types

/// Widget family enumeration
public enum WidgetFamily: String, Sendable, Codable, CaseIterable {
    case systemSmall = "systemSmall"
    case systemMedium = "systemMedium"
    case systemLarge = "systemLarge"
    case systemExtraLarge = "systemExtraLarge"
    case accessoryCircular = "accessoryCircular"
    case accessoryRectangular = "accessoryRectangular"
    case accessoryInline = "accessoryInline"
    
    public var displayName: String {
        switch self {
        case .systemSmall:
            return "Small"
        case .systemMedium:
            return "Medium"
        case .systemLarge:
            return "Large"
        case .systemExtraLarge:
            return "Extra Large"
        case .accessoryCircular:
            return "Circular"
        case .accessoryRectangular:
            return "Rectangular"
        case .accessoryInline:
            return "Inline"
        }
    }
    
    public var dimensions: (width: Int, height: Int) {
        switch self {
        case .systemSmall:
            return (158, 158)
        case .systemMedium:
            return (338, 158)
        case .systemLarge:
            return (338, 354)
        case .systemExtraLarge:
            return (715, 354)
        case .accessoryCircular:
            return (76, 76)
        case .accessoryRectangular:
            return (172, 76)
        case .accessoryInline:
            return (200, 20)
        }
    }
}

/// Widget timeline entry
public struct WidgetTimelineEntry: Sendable, Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let relevance: Double
    public let content: WidgetContent
    public let family: WidgetFamily
    public let configuration: WidgetConfiguration?
    public let deepLinkURL: URL?
    public let isPlaceholder: Bool
    public let expirationDate: Date?
    
    public struct WidgetContent: Sendable, Codable {
        public let title: String?
        public let subtitle: String?
        public let body: String?
        public let imageData: Data?
        public let symbolName: String?
        public let color: String? // Hex color
        public let metadata: [String: String]
        
        public init(
            title: String? = nil,
            subtitle: String? = nil,
            body: String? = nil,
            imageData: Data? = nil,
            symbolName: String? = nil,
            color: String? = nil,
            metadata: [String: String] = [:]
        ) {
            self.title = title
            self.subtitle = subtitle
            self.body = body
            self.imageData = imageData
            self.symbolName = symbolName
            self.color = color
            self.metadata = metadata
        }
    }
    
    public struct WidgetConfiguration: Sendable, Codable {
        public let parameters: [String: String]
        public let userConfigurable: Bool
        public let supportedFamilies: [WidgetFamily]
        
        public init(
            parameters: [String: String] = [:],
            userConfigurable: Bool = false,
            supportedFamilies: [WidgetFamily] = []
        ) {
            self.parameters = parameters
            self.userConfigurable = userConfigurable
            self.supportedFamilies = supportedFamilies
        }
    }
    
    public init(
        date: Date,
        relevance: Double = 0.5,
        content: WidgetContent,
        family: WidgetFamily,
        configuration: WidgetConfiguration? = nil,
        deepLinkURL: URL? = nil,
        isPlaceholder: Bool = false,
        expirationDate: Date? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.relevance = max(0.0, min(1.0, relevance))
        self.content = content
        self.family = family
        self.configuration = configuration
        self.deepLinkURL = deepLinkURL
        self.isPlaceholder = isPlaceholder
        self.expirationDate = expirationDate
    }
    
    public var isExpired: Bool {
        if let expirationDate = expirationDate {
            return Date() > expirationDate
        }
        return false
    }
    
    public var age: TimeInterval {
        Date().timeIntervalSince(date)
    }
}

/// Widget timeline information
public struct WidgetTimeline: Sendable, Identifiable {
    public let id: UUID
    public let kind: String
    public let entries: [WidgetTimelineEntry]
    public let policy: ReloadPolicy
    public let creationDate: Date
    public let nextReloadDate: Date?
    public let isActive: Bool
    
    public enum ReloadPolicy: String, Sendable, Codable, CaseIterable {
        case atEnd = "atEnd"
        case after = "after"
        case never = "never"
    }
    
    public init(
        kind: String,
        entries: [WidgetTimelineEntry],
        policy: ReloadPolicy = .atEnd,
        nextReloadDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.kind = kind
        self.entries = entries
        self.policy = policy
        self.creationDate = Date()
        self.nextReloadDate = nextReloadDate
        self.isActive = isActive
    }
    
    public var currentEntry: WidgetTimelineEntry? {
        let now = Date()
        return entries.first { $0.date <= now }
    }
    
    public var nextEntry: WidgetTimelineEntry? {
        let now = Date()
        return entries.first { $0.date > now }
    }
}

/// Widget update request
public struct WidgetUpdateRequest: Sendable {
    public let kind: String?
    public let family: WidgetFamily?
    public let configuration: WidgetTimelineEntry.WidgetConfiguration?
    public let urgency: UpdateUrgency
    public let reason: UpdateReason
    public let metadata: [String: String]
    
    public enum UpdateUrgency: String, Sendable, Codable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public enum UpdateReason: String, Sendable, Codable, CaseIterable {
        case dataChanged = "dataChanged"
        case userRequest = "userRequest"
        case scheduled = "scheduled"
        case systemRequest = "systemRequest"
        case backgroundRefresh = "backgroundRefresh"
    }
    
    public init(
        kind: String? = nil,
        family: WidgetFamily? = nil,
        configuration: WidgetTimelineEntry.WidgetConfiguration? = nil,
        urgency: UpdateUrgency = .normal,
        reason: UpdateReason = .dataChanged,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.family = family
        self.configuration = configuration
        self.urgency = urgency
        self.reason = reason
        self.metadata = metadata
    }
}

/// Widget metrics
public struct WidgetMetrics: Sendable {
    public let totalWidgets: Int
    public let activeTimelines: Int
    public let totalTimelineEntries: Int
    public let totalUpdates: Int
    public let successfulUpdates: Int
    public let failedUpdates: Int
    public let averageUpdateTime: TimeInterval
    public let widgetsByFamily: [String: Int]
    public let updatesByReason: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let dataUsage: Int64
    
    public init(
        totalWidgets: Int = 0,
        activeTimelines: Int = 0,
        totalTimelineEntries: Int = 0,
        totalUpdates: Int = 0,
        successfulUpdates: Int = 0,
        failedUpdates: Int = 0,
        averageUpdateTime: TimeInterval = 0,
        widgetsByFamily: [String: Int] = [:],
        updatesByReason: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        cacheHitRate: Double = 0,
        dataUsage: Int64 = 0
    ) {
        self.totalWidgets = totalWidgets
        self.activeTimelines = activeTimelines
        self.totalTimelineEntries = totalTimelineEntries
        self.totalUpdates = totalUpdates
        self.successfulUpdates = successfulUpdates
        self.failedUpdates = failedUpdates
        self.averageUpdateTime = averageUpdateTime
        self.widgetsByFamily = widgetsByFamily
        self.updatesByReason = updatesByReason
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.dataUsage = dataUsage
    }
    
    public var successRate: Double {
        totalUpdates > 0 ? Double(successfulUpdates) / Double(totalUpdates) : 0
    }
}

// MARK: - Widget Resource

/// Widget resource management
public actor WidgetCapabilityResource: AxiomCapabilityResource {
    private let configuration: WidgetCapabilityConfiguration
    private var registeredTimelines: [String: WidgetTimeline] = [:]
    private var timelineCache: [String: [WidgetTimelineEntry]] = [:]
    private var updateQueue: [WidgetUpdateRequest] = []
    private var metrics: WidgetMetrics = WidgetMetrics()
    private var timelineStreamContinuation: AsyncStream<WidgetTimeline>.Continuation?
    private var updateStreamContinuation: AsyncStream<WidgetUpdateRequest>.Continuation?
    private var updateTimer: Timer?
    private var updateCount: Int = 0
    private var lastUpdateTime: Date = Date()
    
    public init(configuration: WidgetCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 15_000_000, // 15MB for timeline management
            cpu: 1.0, // Timeline processing and updates
            bandwidth: 0,
            storage: 10_000_000 // 10MB for timeline cache
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let timelineMemory = registeredTimelines.count * 500_000
            let cacheMemory = timelineCache.values.flatMap { $0 }.count * 50_000
            let queueMemory = updateQueue.count * 1_000
            
            return ResourceUsage(
                memory: timelineMemory + cacheMemory + queueMemory + 1_000_000,
                cpu: registeredTimelines.isEmpty ? 0.1 : 0.5,
                bandwidth: 0,
                storage: timelineCache.values.flatMap { $0 }.count * 25_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Widgets are available on iOS 14+, macOS 11+
        if #available(iOS 14.0, macOS 11.0, *) {
            return configuration.enableWidgets
        }
        return false
    }
    
    public func release() async {
        registeredTimelines.removeAll()
        timelineCache.removeAll()
        updateQueue.removeAll()
        
        updateTimer?.invalidate()
        updateTimer = nil
        
        timelineStreamContinuation?.finish()
        updateStreamContinuation?.finish()
        
        metrics = WidgetMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Setup update timer
        if configuration.enableTimelineUpdates {
            await setupUpdateTimer()
        }
    }
    
    internal func updateConfiguration(_ configuration: WidgetCapabilityConfiguration) async throws {
        // Restart timer if interval changed
        if configuration.timelineUpdateInterval != self.configuration.timelineUpdateInterval {
            await setupUpdateTimer()
        }
    }
    
    // MARK: - Timeline Streams
    
    public var timelineStream: AsyncStream<WidgetTimeline> {
        AsyncStream { continuation in
            self.timelineStreamContinuation = continuation
        }
    }
    
    public var updateStream: AsyncStream<WidgetUpdateRequest> {
        AsyncStream { continuation in
            self.updateStreamContinuation = continuation
        }
    }
    
    // MARK: - Timeline Management
    
    public func registerTimeline(_ timeline: WidgetTimeline) async throws {
        guard configuration.enableWidgets else {
            throw WidgetError.widgetsDisabled
        }
        
        registeredTimelines[timeline.kind] = timeline
        
        // Cache timeline entries if enabled
        if configuration.cacheEntries {
            timelineCache[timeline.kind] = timeline.entries
        }
        
        timelineStreamContinuation?.yield(timeline)
        
        await updateTimelineMetrics(timeline)
        
        if configuration.enableLogging {
            await logTimeline(timeline, action: "Registered")
        }
    }
    
    public func unregisterTimeline(_ kind: String) async {
        registeredTimelines.removeValue(forKey: kind)
        timelineCache.removeValue(forKey: kind)
        
        if configuration.enableLogging {
            print("[Widget] 🗑️ Unregistered timeline: \(kind)")
        }
    }
    
    public func getTimeline(for kind: String) async -> WidgetTimeline? {
        return registeredTimelines[kind]
    }
    
    public func getRegisteredTimelines() async -> [WidgetTimeline] {
        return Array(registeredTimelines.values)
    }
    
    public func updateTimeline(_ timeline: WidgetTimeline) async throws {
        guard registeredTimelines[timeline.kind] != nil else {
            throw WidgetError.timelineNotFound(timeline.kind)
        }
        
        registeredTimelines[timeline.kind] = timeline
        
        // Update cache
        if configuration.cacheEntries {
            timelineCache[timeline.kind] = timeline.entries
        }
        
        timelineStreamContinuation?.yield(timeline)
        
        // Trigger widget update
        if #available(iOS 14.0, macOS 11.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: timeline.kind)
        }
        
        await updateTimelineMetrics(timeline)
        
        if configuration.enableLogging {
            await logTimeline(timeline, action: "Updated")
        }
    }
    
    // MARK: - Timeline Entries
    
    public func addTimelineEntry(_ entry: WidgetTimelineEntry, to kind: String) async throws {
        guard var timeline = registeredTimelines[kind] else {
            throw WidgetError.timelineNotFound(kind)
        }
        
        var updatedEntries = timeline.entries
        updatedEntries.append(entry)
        
        // Sort entries by date
        updatedEntries.sort { $0.date < $1.date }
        
        // Limit entries
        if updatedEntries.count > configuration.maxTimelineEntries {
            updatedEntries = Array(updatedEntries.suffix(configuration.maxTimelineEntries))
        }
        
        let updatedTimeline = WidgetTimeline(
            kind: timeline.kind,
            entries: updatedEntries,
            policy: timeline.policy,
            nextReloadDate: timeline.nextReloadDate,
            isActive: timeline.isActive
        )
        
        try await updateTimeline(updatedTimeline)
    }
    
    public func removeTimelineEntry(_ entryId: UUID, from kind: String) async throws {
        guard var timeline = registeredTimelines[kind] else {
            throw WidgetError.timelineNotFound(kind)
        }
        
        let updatedEntries = timeline.entries.filter { $0.id != entryId }
        
        let updatedTimeline = WidgetTimeline(
            kind: timeline.kind,
            entries: updatedEntries,
            policy: timeline.policy,
            nextReloadDate: timeline.nextReloadDate,
            isActive: timeline.isActive
        )
        
        try await updateTimeline(updatedTimeline)
    }
    
    public func getTimelineEntries(for kind: String, family: WidgetFamily? = nil) async -> [WidgetTimelineEntry] {
        var entries: [WidgetTimelineEntry] = []
        
        // Try cache first
        if configuration.cacheEntries, let cachedEntries = timelineCache[kind] {
            entries = cachedEntries
        } else if let timeline = registeredTimelines[kind] {
            entries = timeline.entries
        }
        
        // Filter by family if specified
        if let family = family {
            entries = entries.filter { $0.family == family }
        }
        
        // Remove expired entries
        entries = entries.filter { !$0.isExpired }
        
        return entries
    }
    
    public func getCurrentEntry(for kind: String, family: WidgetFamily? = nil) async -> WidgetTimelineEntry? {
        let entries = await getTimelineEntries(for: kind, family: family)
        let now = Date()
        
        return entries.filter { $0.date <= now }.last
    }
    
    public func getNextEntry(for kind: String, family: WidgetFamily? = nil) async -> WidgetTimelineEntry? {
        let entries = await getTimelineEntries(for: kind, family: family)
        let now = Date()
        
        return entries.first { $0.date > now }
    }
    
    // MARK: - Widget Updates
    
    public func requestUpdate(_ request: WidgetUpdateRequest) async {
        updateQueue.append(request)
        updateStreamContinuation?.yield(request)
        
        // Process high priority updates immediately
        if request.urgency == .critical || request.urgency == .high {
            await processUpdateRequest(request)
        }
        
        if configuration.enableLogging {
            await logUpdateRequest(request)
        }
    }
    
    public func requestReload(for kind: String? = nil, urgency: WidgetUpdateRequest.UpdateUrgency = .normal) async {
        let request = WidgetUpdateRequest(
            kind: kind,
            urgency: urgency,
            reason: .userRequest
        )
        
        await requestUpdate(request)
    }
    
    public func processUpdateQueue() async {
        let pendingUpdates = updateQueue
        updateQueue.removeAll()
        
        for request in pendingUpdates {
            await processUpdateRequest(request)
        }
        
        if configuration.enableLogging && !pendingUpdates.isEmpty {
            print("[Widget] 📦 Processed \(pendingUpdates.count) update requests")
        }
    }
    
    // MARK: - Widget Information
    
    public func getSupportedFamilies() async -> [WidgetFamily] {
        return configuration.supportedFamilies.compactMap { WidgetFamily(rawValue: $0) }
    }
    
    public func isFamilySupported(_ family: WidgetFamily) async -> Bool {
        return configuration.supportedFamilies.contains(family.rawValue)
    }
    
    public func getWidgetInfo(for kind: String) async -> WidgetInfo? {
        guard let timeline = registeredTimelines[kind] else { return nil }
        
        let entries = timeline.entries
        let families = Set(entries.map { $0.family })
        
        return WidgetInfo(
            kind: kind,
            supportedFamilies: Array(families),
            totalEntries: entries.count,
            isActive: timeline.isActive,
            lastUpdate: timeline.creationDate,
            nextUpdate: timeline.nextReloadDate
        )
    }
    
    public struct WidgetInfo: Sendable {
        public let kind: String
        public let supportedFamilies: [WidgetFamily]
        public let totalEntries: Int
        public let isActive: Bool
        public let lastUpdate: Date
        public let nextUpdate: Date?
        
        public init(kind: String, supportedFamilies: [WidgetFamily], totalEntries: Int, isActive: Bool, lastUpdate: Date, nextUpdate: Date?) {
            self.kind = kind
            self.supportedFamilies = supportedFamilies
            self.totalEntries = totalEntries
            self.isActive = isActive
            self.lastUpdate = lastUpdate
            self.nextUpdate = nextUpdate
        }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> WidgetMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = WidgetMetrics()
    }
    
    // MARK: - Private Methods
    
    private func setupUpdateTimer() async {
        updateTimer?.invalidate()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: configuration.timelineUpdateInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.processUpdateQueue()
                await self?.performScheduledUpdates()
            }
        }
    }
    
    private func performScheduledUpdates() async {
        for timeline in registeredTimelines.values {
            if timeline.policy == .atEnd && timeline.entries.allSatisfy({ $0.date <= Date() }) {
                let request = WidgetUpdateRequest(
                    kind: timeline.kind,
                    urgency: .normal,
                    reason: .scheduled
                )
                await requestUpdate(request)
            }
        }
    }
    
    private func processUpdateRequest(_ request: WidgetUpdateRequest) async {
        let startTime = Date()
        updateCount += 1
        
        do {
            if #available(iOS 14.0, macOS 11.0, *) {
                if let kind = request.kind {
                    WidgetCenter.shared.reloadTimelines(ofKind: kind)
                } else {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await updateSuccessMetrics(request: request, duration: duration)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            await updateFailureMetrics(request: request, duration: duration, error: error)
        }
    }
    
    private func updateTimelineMetrics(_ timeline: WidgetTimeline) async {
        let totalTimelines = registeredTimelines.count
        let activeTimelines = registeredTimelines.values.filter { $0.isActive }.count
        let totalEntries = registeredTimelines.values.reduce(0) { $0 + $1.entries.count }
        
        var widgetsByFamily = metrics.widgetsByFamily
        for entry in timeline.entries {
            widgetsByFamily[entry.family.rawValue, default: 0] += 1
        }
        
        metrics = WidgetMetrics(
            totalWidgets: totalTimelines,
            activeTimelines: activeTimelines,
            totalTimelineEntries: totalEntries,
            totalUpdates: metrics.totalUpdates,
            successfulUpdates: metrics.successfulUpdates,
            failedUpdates: metrics.failedUpdates,
            averageUpdateTime: metrics.averageUpdateTime,
            widgetsByFamily: widgetsByFamily,
            updatesByReason: metrics.updatesByReason,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            dataUsage: metrics.dataUsage
        )
    }
    
    private func updateSuccessMetrics(request: WidgetUpdateRequest, duration: TimeInterval) async {
        let totalUpdates = metrics.totalUpdates + 1
        let successfulUpdates = metrics.successfulUpdates + 1
        
        let newAverageUpdateTime = ((metrics.averageUpdateTime * Double(metrics.totalUpdates)) + duration) / Double(totalUpdates)
        
        var updatesByReason = metrics.updatesByReason
        updatesByReason[request.reason.rawValue, default: 0] += 1
        
        metrics = WidgetMetrics(
            totalWidgets: metrics.totalWidgets,
            activeTimelines: metrics.activeTimelines,
            totalTimelineEntries: metrics.totalTimelineEntries,
            totalUpdates: totalUpdates,
            successfulUpdates: successfulUpdates,
            failedUpdates: metrics.failedUpdates,
            averageUpdateTime: newAverageUpdateTime,
            widgetsByFamily: metrics.widgetsByFamily,
            updatesByReason: updatesByReason,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            dataUsage: metrics.dataUsage
        )
    }
    
    private func updateFailureMetrics(request: WidgetUpdateRequest, duration: TimeInterval, error: Error) async {
        let totalUpdates = metrics.totalUpdates + 1
        let failedUpdates = metrics.failedUpdates + 1
        
        var errorsByType = metrics.errorsByType
        let errorKey = String(describing: type(of: error))
        errorsByType[errorKey, default: 0] += 1
        
        metrics = WidgetMetrics(
            totalWidgets: metrics.totalWidgets,
            activeTimelines: metrics.activeTimelines,
            totalTimelineEntries: metrics.totalTimelineEntries,
            totalUpdates: totalUpdates,
            successfulUpdates: metrics.successfulUpdates,
            failedUpdates: failedUpdates,
            averageUpdateTime: metrics.averageUpdateTime,
            widgetsByFamily: metrics.widgetsByFamily,
            updatesByReason: metrics.updatesByReason,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            dataUsage: metrics.dataUsage
        )
    }
    
    private func logTimeline(_ timeline: WidgetTimeline, action: String) async {
        let entryCount = timeline.entries.count
        let families = Set(timeline.entries.map { $0.family.rawValue }).joined(separator: ", ")
        let activeIcon = timeline.isActive ? "✅" : "⏸️"
        
        print("[Widget] \(activeIcon) \(action): \(timeline.kind) (\(entryCount) entries, \(families))")
    }
    
    private func logUpdateRequest(_ request: WidgetUpdateRequest) async {
        let urgencyIcon = switch request.urgency {
        case .low: "🔵"
        case .normal: "🟢"
        case .high: "🟠"
        case .critical: "🔴"
        }
        
        let target = request.kind ?? "All Widgets"
        print("[Widget] \(urgencyIcon) Update requested: \(target) (\(request.reason.rawValue))")
    }
}

// MARK: - Widget Capability Implementation

/// Widget capability providing comprehensive home screen widget support
public actor WidgetCapability: DomainCapability {
    public typealias ConfigurationType = WidgetCapabilityConfiguration
    public typealias ResourceType = WidgetCapabilityResource
    
    private var _configuration: WidgetCapabilityConfiguration
    private var _resources: WidgetCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "widget-capability" }
    
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
    
    public var configuration: WidgetCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: WidgetCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: WidgetCapabilityConfiguration = WidgetCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = WidgetCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: WidgetCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Widget configuration")
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
        // Widgets are supported on iOS 14+, macOS 11+
        if #available(iOS 14.0, macOS 11.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Widgets don't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Timeline Management Operations
    
    /// Register a widget timeline
    public func registerTimeline(_ timeline: WidgetTimeline) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        try await _resources.registerTimeline(timeline)
    }
    
    /// Unregister a widget timeline
    public func unregisterTimeline(_ kind: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        await _resources.unregisterTimeline(kind)
    }
    
    /// Get timeline stream
    public func getTimelineStream() async throws -> AsyncStream<WidgetTimeline> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.timelineStream
    }
    
    /// Get specific timeline
    public func getTimeline(for kind: String) async throws -> WidgetTimeline? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getTimeline(for: kind)
    }
    
    /// Get registered timelines
    public func getRegisteredTimelines() async throws -> [WidgetTimeline] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getRegisteredTimelines()
    }
    
    /// Update timeline
    public func updateTimeline(_ timeline: WidgetTimeline) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        try await _resources.updateTimeline(timeline)
    }
    
    // MARK: - Timeline Entry Operations
    
    /// Add timeline entry
    public func addTimelineEntry(_ entry: WidgetTimelineEntry, to kind: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        try await _resources.addTimelineEntry(entry, to: kind)
    }
    
    /// Remove timeline entry
    public func removeTimelineEntry(_ entryId: UUID, from kind: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        try await _resources.removeTimelineEntry(entryId, from: kind)
    }
    
    /// Get timeline entries
    public func getTimelineEntries(for kind: String, family: WidgetFamily? = nil) async throws -> [WidgetTimelineEntry] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getTimelineEntries(for: kind, family: family)
    }
    
    /// Get current entry
    public func getCurrentEntry(for kind: String, family: WidgetFamily? = nil) async throws -> WidgetTimelineEntry? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getCurrentEntry(for: kind, family: family)
    }
    
    /// Get next entry
    public func getNextEntry(for kind: String, family: WidgetFamily? = nil) async throws -> WidgetTimelineEntry? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getNextEntry(for: kind, family: family)
    }
    
    // MARK: - Widget Update Operations
    
    /// Request widget update
    public func requestUpdate(_ request: WidgetUpdateRequest) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        await _resources.requestUpdate(request)
    }
    
    /// Get update stream
    public func getUpdateStream() async throws -> AsyncStream<WidgetUpdateRequest> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.updateStream
    }
    
    /// Request reload
    public func requestReload(for kind: String? = nil, urgency: WidgetUpdateRequest.UpdateUrgency = .normal) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        await _resources.requestReload(for: kind, urgency: urgency)
    }
    
    /// Process update queue
    public func processUpdateQueue() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        await _resources.processUpdateQueue()
    }
    
    // MARK: - Widget Information Operations
    
    /// Get supported families
    public func getSupportedFamilies() async throws -> [WidgetFamily] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getSupportedFamilies()
    }
    
    /// Check if family is supported
    public func isFamilySupported(_ family: WidgetFamily) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.isFamilySupported(family)
    }
    
    /// Get widget info
    public func getWidgetInfo(for kind: String) async throws -> WidgetCapabilityResource.WidgetInfo? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getWidgetInfo(for: kind)
    }
    
    /// Get widget metrics
    public func getMetrics() async throws -> WidgetMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Widget capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Create simple text widget entry
    public func createTextEntry(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        family: WidgetFamily,
        date: Date = Date()
    ) async throws -> WidgetTimelineEntry {
        let content = WidgetTimelineEntry.WidgetContent(
            title: title,
            subtitle: subtitle,
            body: body
        )
        
        return WidgetTimelineEntry(
            date: date,
            content: content,
            family: family
        )
    }
    
    /// Create image widget entry
    public func createImageEntry(
        title: String? = nil,
        imageData: Data,
        family: WidgetFamily,
        date: Date = Date()
    ) async throws -> WidgetTimelineEntry {
        let content = WidgetTimelineEntry.WidgetContent(
            title: title,
            imageData: imageData
        )
        
        return WidgetTimelineEntry(
            date: date,
            content: content,
            family: family
        )
    }
    
    /// Check if widgets are active
    public func hasActiveWidgets() async throws -> Bool {
        let timelines = try await getRegisteredTimelines()
        return timelines.contains { $0.isActive }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Widget specific errors
public enum WidgetError: Error, LocalizedError {
    case widgetsDisabled
    case timelineNotFound(String)
    case entryNotFound(UUID)
    case familyNotSupported(WidgetFamily)
    case tooManyEntries(Int)
    case updateFailed(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .widgetsDisabled:
            return "Widgets are disabled"
        case .timelineNotFound(let kind):
            return "Timeline not found: \(kind)"
        case .entryNotFound(let id):
            return "Timeline entry not found: \(id)"
        case .familyNotSupported(let family):
            return "Widget family not supported: \(family.rawValue)"
        case .tooManyEntries(let maxEntries):
            return "Too many timeline entries (max: \(maxEntries))"
        case .updateFailed(let reason):
            return "Widget update failed: \(reason)"
        case .configurationError(let reason):
            return "Widget configuration error: \(reason)"
        }
    }
}