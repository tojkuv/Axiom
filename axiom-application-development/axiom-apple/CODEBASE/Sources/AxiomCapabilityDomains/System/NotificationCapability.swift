import Foundation
import UserNotifications
import UIKit
import AxiomCore
import AxiomCapabilities

// MARK: - Notification Capability Configuration

/// Configuration for Notification capability
public struct NotificationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableLocalNotifications: Bool
    public let enablePushNotifications: Bool
    public let enableBadgeUpdates: Bool
    public let enableSoundNotifications: Bool
    public let enableCriticalAlerts: Bool
    public let enableProvisionalAuthorization: Bool
    public let enableNotificationActions: Bool
    public let enableNotificationCategories: Bool
    public let enableRichNotifications: Bool
    public let enableNotificationHistory: Bool
    public let maxHistoryCount: Int
    public let historyRetentionDays: Int
    public let enableScheduledNotifications: Bool
    public let maxScheduledNotifications: Int
    public let enableLocationBasedNotifications: Bool
    public let enableTimeBasedNotifications: Bool
    public let enableIntervalNotifications: Bool
    public let defaultNotificationSound: String?
    public let enableCustomSounds: Bool
    public let enableGroupedNotifications: Bool
    public let enableNotificationExtensions: Bool
    public let enableNotificationAnalytics: Bool
    public let enableQuietHours: Bool
    public let quietHoursStart: String // HH:mm format
    public let quietHoursEnd: String // HH:mm format
    public let enableDoNotDisturb: Bool
    public let enableSmartDelivery: Bool
    public let deliveryOptimization: DeliveryOptimization
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let notificationPriority: NotificationPriority
    public let enableEncryption: Bool
    
    public enum DeliveryOptimization: String, Codable, CaseIterable, Sendable {
        case immediate = "immediate"
        case optimized = "optimized"
        case batched = "batched"
        case timeSensitive = "timeSensitive"
    }
    
    public enum NotificationPriority: String, Codable, CaseIterable, Sendable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        enableLocalNotifications: Bool = true,
        enablePushNotifications: Bool = true,
        enableBadgeUpdates: Bool = true,
        enableSoundNotifications: Bool = true,
        enableCriticalAlerts: Bool = false,
        enableProvisionalAuthorization: Bool = false,
        enableNotificationActions: Bool = true,
        enableNotificationCategories: Bool = true,
        enableRichNotifications: Bool = true,
        enableNotificationHistory: Bool = true,
        maxHistoryCount: Int = 1000,
        historyRetentionDays: Int = 30,
        enableScheduledNotifications: Bool = true,
        maxScheduledNotifications: Int = 64,
        enableLocationBasedNotifications: Bool = false,
        enableTimeBasedNotifications: Bool = true,
        enableIntervalNotifications: Bool = true,
        defaultNotificationSound: String? = nil,
        enableCustomSounds: Bool = true,
        enableGroupedNotifications: Bool = true,
        enableNotificationExtensions: Bool = false,
        enableNotificationAnalytics: Bool = true,
        enableQuietHours: Bool = false,
        quietHoursStart: String = "22:00",
        quietHoursEnd: String = "07:00",
        enableDoNotDisturb: Bool = false,
        enableSmartDelivery: Bool = false,
        deliveryOptimization: DeliveryOptimization = .optimized,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        notificationPriority: NotificationPriority = .normal,
        enableEncryption: Bool = false
    ) {
        self.enableLocalNotifications = enableLocalNotifications
        self.enablePushNotifications = enablePushNotifications
        self.enableBadgeUpdates = enableBadgeUpdates
        self.enableSoundNotifications = enableSoundNotifications
        self.enableCriticalAlerts = enableCriticalAlerts
        self.enableProvisionalAuthorization = enableProvisionalAuthorization
        self.enableNotificationActions = enableNotificationActions
        self.enableNotificationCategories = enableNotificationCategories
        self.enableRichNotifications = enableRichNotifications
        self.enableNotificationHistory = enableNotificationHistory
        self.maxHistoryCount = maxHistoryCount
        self.historyRetentionDays = historyRetentionDays
        self.enableScheduledNotifications = enableScheduledNotifications
        self.maxScheduledNotifications = maxScheduledNotifications
        self.enableLocationBasedNotifications = enableLocationBasedNotifications
        self.enableTimeBasedNotifications = enableTimeBasedNotifications
        self.enableIntervalNotifications = enableIntervalNotifications
        self.defaultNotificationSound = defaultNotificationSound
        self.enableCustomSounds = enableCustomSounds
        self.enableGroupedNotifications = enableGroupedNotifications
        self.enableNotificationExtensions = enableNotificationExtensions
        self.enableNotificationAnalytics = enableNotificationAnalytics
        self.enableQuietHours = enableQuietHours
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.enableDoNotDisturb = enableDoNotDisturb
        self.enableSmartDelivery = enableSmartDelivery
        self.deliveryOptimization = deliveryOptimization
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.notificationPriority = notificationPriority
        self.enableEncryption = enableEncryption
    }
    
    public var isValid: Bool {
        maxHistoryCount > 0 &&
        historyRetentionDays > 0 &&
        maxScheduledNotifications > 0 &&
        isValidTimeFormat(quietHoursStart) &&
        isValidTimeFormat(quietHoursEnd)
    }
    
    private func isValidTimeFormat(_ time: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time) != nil
    }
    
    public func merged(with other: NotificationCapabilityConfiguration) -> NotificationCapabilityConfiguration {
        NotificationCapabilityConfiguration(
            enableLocalNotifications: other.enableLocalNotifications,
            enablePushNotifications: other.enablePushNotifications,
            enableBadgeUpdates: other.enableBadgeUpdates,
            enableSoundNotifications: other.enableSoundNotifications,
            enableCriticalAlerts: other.enableCriticalAlerts,
            enableProvisionalAuthorization: other.enableProvisionalAuthorization,
            enableNotificationActions: other.enableNotificationActions,
            enableNotificationCategories: other.enableNotificationCategories,
            enableRichNotifications: other.enableRichNotifications,
            enableNotificationHistory: other.enableNotificationHistory,
            maxHistoryCount: other.maxHistoryCount,
            historyRetentionDays: other.historyRetentionDays,
            enableScheduledNotifications: other.enableScheduledNotifications,
            maxScheduledNotifications: other.maxScheduledNotifications,
            enableLocationBasedNotifications: other.enableLocationBasedNotifications,
            enableTimeBasedNotifications: other.enableTimeBasedNotifications,
            enableIntervalNotifications: other.enableIntervalNotifications,
            defaultNotificationSound: other.defaultNotificationSound ?? defaultNotificationSound,
            enableCustomSounds: other.enableCustomSounds,
            enableGroupedNotifications: other.enableGroupedNotifications,
            enableNotificationExtensions: other.enableNotificationExtensions,
            enableNotificationAnalytics: other.enableNotificationAnalytics,
            enableQuietHours: other.enableQuietHours,
            quietHoursStart: other.quietHoursStart,
            quietHoursEnd: other.quietHoursEnd,
            enableDoNotDisturb: other.enableDoNotDisturb,
            enableSmartDelivery: other.enableSmartDelivery,
            deliveryOptimization: other.deliveryOptimization,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            notificationPriority: other.notificationPriority,
            enableEncryption: other.enableEncryption
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> NotificationCapabilityConfiguration {
        var adjustedLogging = enableLogging
        var adjustedOptimization = deliveryOptimization
        var adjustedMaxScheduled = maxScheduledNotifications
        
        if environment.isLowPowerMode {
            adjustedOptimization = .batched
            adjustedMaxScheduled = min(maxScheduledNotifications, 32)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return NotificationCapabilityConfiguration(
            enableLocalNotifications: enableLocalNotifications,
            enablePushNotifications: enablePushNotifications,
            enableBadgeUpdates: enableBadgeUpdates,
            enableSoundNotifications: enableSoundNotifications,
            enableCriticalAlerts: enableCriticalAlerts,
            enableProvisionalAuthorization: enableProvisionalAuthorization,
            enableNotificationActions: enableNotificationActions,
            enableNotificationCategories: enableNotificationCategories,
            enableRichNotifications: enableRichNotifications,
            enableNotificationHistory: enableNotificationHistory,
            maxHistoryCount: maxHistoryCount,
            historyRetentionDays: historyRetentionDays,
            enableScheduledNotifications: enableScheduledNotifications,
            maxScheduledNotifications: adjustedMaxScheduled,
            enableLocationBasedNotifications: enableLocationBasedNotifications,
            enableTimeBasedNotifications: enableTimeBasedNotifications,
            enableIntervalNotifications: enableIntervalNotifications,
            defaultNotificationSound: defaultNotificationSound,
            enableCustomSounds: enableCustomSounds,
            enableGroupedNotifications: enableGroupedNotifications,
            enableNotificationExtensions: enableNotificationExtensions,
            enableNotificationAnalytics: enableNotificationAnalytics,
            enableQuietHours: enableQuietHours,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
            enableDoNotDisturb: enableDoNotDisturb,
            enableSmartDelivery: enableSmartDelivery,
            deliveryOptimization: adjustedOptimization,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            notificationPriority: notificationPriority,
            enableEncryption: enableEncryption
        )
    }
}

// MARK: - Notification Types

/// Notification authorization status
public enum NotificationAuthorizationStatus: String, Codable, CaseIterable, Sendable {
    case notDetermined = "notDetermined"
    case denied = "denied"
    case authorized = "authorized"
    case provisional = "provisional"
    case ephemeral = "ephemeral"
}

/// Local notification request
public struct LocalNotificationRequest: Sendable {
    public let identifier: String
    public let title: String
    public let subtitle: String?
    public let body: String
    public let badge: Int?
    public let sound: NotificationSound?
    public let category: String?
    public let userInfo: [String: Any]?
    public let attachments: [NotificationAttachment]?
    public let trigger: NotificationTrigger?
    public let threadIdentifier: String?
    public let targetContentIdentifier: String?
    public let interruptionLevel: InterruptionLevel?
    public let relevanceScore: Double?
    
    public enum InterruptionLevel: String, Codable, CaseIterable, Sendable {
        case passive = "passive"
        case active = "active"
        case timeSensitive = "timeSensitive"
        case critical = "critical"
    }
    
    public init(
        identifier: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        body: String,
        badge: Int? = nil,
        sound: NotificationSound? = .default,
        category: String? = nil,
        userInfo: [String: Any]? = nil,
        attachments: [NotificationAttachment]? = nil,
        trigger: NotificationTrigger? = nil,
        threadIdentifier: String? = nil,
        targetContentIdentifier: String? = nil,
        interruptionLevel: InterruptionLevel? = nil,
        relevanceScore: Double? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.badge = badge
        self.sound = sound
        self.category = category
        self.userInfo = userInfo
        self.attachments = attachments
        self.trigger = trigger
        self.threadIdentifier = threadIdentifier
        self.targetContentIdentifier = targetContentIdentifier
        self.interruptionLevel = interruptionLevel
        self.relevanceScore = relevanceScore
    }
}

/// Notification trigger types
public enum NotificationTrigger: Sendable {
    case immediate
    case timeInterval(TimeInterval, repeats: Bool)
    case dateComponents(DateComponents, repeats: Bool)
    case calendar(Date, repeats: Bool)
    case location(latitude: Double, longitude: Double, radius: Double, notifyOnEntry: Bool, notifyOnExit: Bool)
    
    public var unTrigger: UNNotificationTrigger? {
        switch self {
        case .immediate:
            return nil
        case .timeInterval(let interval, let repeats):
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        case .dateComponents(let components, let repeats):
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        case .calendar(let date, let repeats):
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        case .location(let lat, let lon, let radius, let onEntry, let onExit):
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), radius: radius, identifier: UUID().uuidString)
            region.notifyOnEntry = onEntry
            region.notifyOnExit = onExit
            return UNLocationNotificationTrigger(region: region, repeats: false)
        }
    }
}

/// Notification sound
public enum NotificationSound: Sendable {
    case none
    case `default`
    case critical(Double) // volume 0.0-1.0
    case custom(String) // filename
    
    public var unSound: UNNotificationSound? {
        switch self {
        case .none:
            return nil
        case .default:
            return .default
        case .critical(let volume):
            return .defaultCritical
        case .custom(let filename):
            return UNNotificationSound(named: UNNotificationSoundName(filename))
        }
    }
}

/// Notification attachment
public struct NotificationAttachment: Sendable {
    public let identifier: String
    public let url: URL
    public let type: AttachmentType
    public let options: [String: Any]?
    
    public enum AttachmentType: String, Codable, CaseIterable, Sendable {
        case image = "image"
        case video = "video"
        case audio = "audio"
        case gif = "gif"
    }
    
    public init(
        identifier: String = UUID().uuidString,
        url: URL,
        type: AttachmentType,
        options: [String: Any]? = nil
    ) {
        self.identifier = identifier
        self.url = url
        self.type = type
        self.options = options
    }
    
    public var unAttachment: UNNotificationAttachment? {
        try? UNNotificationAttachment(identifier: identifier, url: url, options: options)
    }
}

/// Notification category
public struct NotificationCategory: Sendable {
    public let identifier: String
    public let actions: [NotificationAction]
    public let intentIdentifiers: [String]?
    public let options: CategoryOptions
    
    public struct CategoryOptions: OptionSet, Sendable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let customDismissAction = CategoryOptions(rawValue: 1 << 0)
        public static let allowInCarPlay = CategoryOptions(rawValue: 1 << 1)
        public static let hiddenPreviewsShowTitle = CategoryOptions(rawValue: 1 << 2)
        public static let hiddenPreviewsShowSubtitle = CategoryOptions(rawValue: 1 << 3)
        public static let allowAnnouncement = CategoryOptions(rawValue: 1 << 4)
    }
    
    public init(
        identifier: String,
        actions: [NotificationAction],
        intentIdentifiers: [String]? = nil,
        options: CategoryOptions = []
    ) {
        self.identifier = identifier
        self.actions = actions
        self.intentIdentifiers = intentIdentifiers
        self.options = options
    }
    
    public var unCategory: UNNotificationCategory {
        var unOptions: UNNotificationCategoryOptions = []
        if options.contains(.customDismissAction) { unOptions.insert(.customDismissAction) }
        if options.contains(.allowInCarPlay) { unOptions.insert(.allowInCarPlay) }
        if options.contains(.hiddenPreviewsShowTitle) { unOptions.insert(.hiddenPreviewsShowTitle) }
        if options.contains(.hiddenPreviewsShowSubtitle) { unOptions.insert(.hiddenPreviewsShowSubtitle) }
        
        return UNNotificationCategory(
            identifier: identifier,
            actions: actions.compactMap { $0.unAction },
            intentIdentifiers: intentIdentifiers ?? [],
            options: unOptions
        )
    }
}

/// Notification action
public struct NotificationAction: Sendable {
    public let identifier: String
    public let title: String
    public let options: ActionOptions
    public let textInputButtonTitle: String?
    public let textInputPlaceholder: String?
    
    public struct ActionOptions: OptionSet, Sendable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let authenticationRequired = ActionOptions(rawValue: 1 << 0)
        public static let destructive = ActionOptions(rawValue: 1 << 1)
        public static let foreground = ActionOptions(rawValue: 1 << 2)
    }
    
    public init(
        identifier: String,
        title: String,
        options: ActionOptions = [],
        textInputButtonTitle: String? = nil,
        textInputPlaceholder: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.options = options
        self.textInputButtonTitle = textInputButtonTitle
        self.textInputPlaceholder = textInputPlaceholder
    }
    
    public var unAction: UNNotificationAction? {
        var unOptions: UNNotificationActionOptions = []
        if options.contains(.authenticationRequired) { unOptions.insert(.authenticationRequired) }
        if options.contains(.destructive) { unOptions.insert(.destructive) }
        if options.contains(.foreground) { unOptions.insert(.foreground) }
        
        if let buttonTitle = textInputButtonTitle, let placeholder = textInputPlaceholder {
            return UNTextInputNotificationAction(
                identifier: identifier,
                title: title,
                options: unOptions,
                textInputButtonTitle: buttonTitle,
                textInputPlaceholder: placeholder
            )
        } else {
            return UNNotificationAction(
                identifier: identifier,
                title: title,
                options: unOptions
            )
        }
    }
}

/// Notification response
public struct NotificationResponse: Sendable {
    public let notification: DeliveredNotification
    public let actionIdentifier: String
    public let userText: String?
    public let timestamp: Date
    
    public init(
        notification: DeliveredNotification,
        actionIdentifier: String,
        userText: String? = nil,
        timestamp: Date = Date()
    ) {
        self.notification = notification
        self.actionIdentifier = actionIdentifier
        self.userText = userText
        self.timestamp = timestamp
    }
}

/// Delivered notification
public struct DeliveredNotification: Sendable {
    public let identifier: String
    public let title: String
    public let subtitle: String?
    public let body: String
    public let badge: Int?
    public let sound: NotificationSound?
    public let category: String?
    public let userInfo: [String: Any]?
    public let date: Date
    public let threadIdentifier: String?
    public let isLocal: Bool
    
    public init(
        identifier: String,
        title: String,
        subtitle: String? = nil,
        body: String,
        badge: Int? = nil,
        sound: NotificationSound? = nil,
        category: String? = nil,
        userInfo: [String: Any]? = nil,
        date: Date = Date(),
        threadIdentifier: String? = nil,
        isLocal: Bool = true
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.badge = badge
        self.sound = sound
        self.category = category
        self.userInfo = userInfo
        self.date = date
        self.threadIdentifier = threadIdentifier
        self.isLocal = isLocal
    }
    
    public init(from unNotification: UNNotification) {
        self.identifier = unNotification.request.identifier
        self.title = unNotification.request.content.title
        self.subtitle = unNotification.request.content.subtitle.isEmpty ? nil : unNotification.request.content.subtitle
        self.body = unNotification.request.content.body
        self.badge = unNotification.request.content.badge?.intValue
        self.sound = unNotification.request.content.sound == .default ? .default : .none
        self.category = unNotification.request.content.categoryIdentifier.isEmpty ? nil : unNotification.request.content.categoryIdentifier
        self.userInfo = unNotification.request.content.userInfo
        self.date = unNotification.date
        self.threadIdentifier = unNotification.request.content.threadIdentifier.isEmpty ? nil : unNotification.request.content.threadIdentifier
        self.isLocal = unNotification.request.trigger != nil
    }
}

/// Push notification token
public struct PushNotificationToken: Sendable {
    public let deviceToken: Data
    public let tokenString: String
    public let environment: Environment
    public let registeredAt: Date
    
    public enum Environment: String, Codable, CaseIterable, Sendable {
        case development = "development"
        case production = "production"
    }
    
    public init(deviceToken: Data, environment: Environment = .production) {
        self.deviceToken = deviceToken
        self.tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.environment = environment
        self.registeredAt = Date()
    }
}

/// Notification metrics
public struct NotificationMetrics: Sendable {
    public let localNotificationsSent: Int
    public let pushNotificationsSent: Int
    public let notificationsDelivered: Int
    public let notificationsOpened: Int
    public let notificationsDismissed: Int
    public let actionsExecuted: Int
    public let averageDeliveryTime: TimeInterval
    public let deliveryFailures: Int
    public let permissionRequests: Int
    public let permissionGranted: Int
    public let badgeUpdates: Int
    public let scheduledNotifications: Int
    public let canceledNotifications: Int
    
    public init(
        localNotificationsSent: Int = 0,
        pushNotificationsSent: Int = 0,
        notificationsDelivered: Int = 0,
        notificationsOpened: Int = 0,
        notificationsDismissed: Int = 0,
        actionsExecuted: Int = 0,
        averageDeliveryTime: TimeInterval = 0,
        deliveryFailures: Int = 0,
        permissionRequests: Int = 0,
        permissionGranted: Int = 0,
        badgeUpdates: Int = 0,
        scheduledNotifications: Int = 0,
        canceledNotifications: Int = 0
    ) {
        self.localNotificationsSent = localNotificationsSent
        self.pushNotificationsSent = pushNotificationsSent
        self.notificationsDelivered = notificationsDelivered
        self.notificationsOpened = notificationsOpened
        self.notificationsDismissed = notificationsDismissed
        self.actionsExecuted = actionsExecuted
        self.averageDeliveryTime = averageDeliveryTime
        self.deliveryFailures = deliveryFailures
        self.permissionRequests = permissionRequests
        self.permissionGranted = permissionGranted
        self.badgeUpdates = badgeUpdates
        self.scheduledNotifications = scheduledNotifications
        self.canceledNotifications = canceledNotifications
    }
    
    public var openRate: Double {
        guard notificationsDelivered > 0 else { return 0.0 }
        return Double(notificationsOpened) / Double(notificationsDelivered)
    }
    
    public var permissionGrantRate: Double {
        guard permissionRequests > 0 else { return 0.0 }
        return Double(permissionGranted) / Double(permissionRequests)
    }
    
    public var deliverySuccessRate: Double {
        let totalSent = localNotificationsSent + pushNotificationsSent
        guard totalSent > 0 else { return 0.0 }
        return Double(notificationsDelivered) / Double(totalSent)
    }
}

// MARK: - Notification Resource

/// Notification resource management
public actor NotificationCapabilityResource: AxiomCapabilityResource {
    private let configuration: NotificationCapabilityConfiguration
    private var notificationCenter: UNUserNotificationCenter
    private var notificationHistory: [DeliveredNotification] = []
    private var scheduledNotifications: [String: LocalNotificationRequest] = [:]
    private var notificationCategories: [String: NotificationCategory] = [:]
    private var pushToken: PushNotificationToken?
    private var metrics: NotificationMetrics = NotificationMetrics()
    private var deliveryTimes: [TimeInterval] = []
    
    // Async streams
    private var notificationResponseContinuation: AsyncStream<NotificationResponse>.Continuation?
    private var pushTokenContinuation: AsyncStream<PushNotificationToken>.Continuation?
    
    public init(configuration: NotificationCapabilityConfiguration) {
        self.configuration = configuration
        self.notificationCenter = UNUserNotificationCenter.current()
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxHistoryCount * 2000, // 2KB per notification
            cpu: 5.0, // 5% CPU for notification processing
            bandwidth: 10_000, // 10KB/s for push notifications
            storage: configuration.maxHistoryCount * 1000 // 1KB per notification record
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historySize = notificationHistory.count * 1500
            let scheduledSize = scheduledNotifications.count * 500
            
            return ResourceUsage(
                memory: historySize + scheduledSize,
                cpu: 2.0,
                bandwidth: 0, // Dynamic based on push notifications
                storage: historySize
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        await getAuthorizationStatus() == .authorized || await getAuthorizationStatus() == .provisional
    }
    
    public func release() async {
        notificationCenter.delegate = nil
        notificationResponseContinuation?.finish()
        pushTokenContinuation?.finish()
        notificationResponseContinuation = nil
        pushTokenContinuation = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Set up notification center delegate
        notificationCenter.delegate = NotificationCenterDelegate(resource: self)
        
        // Register default categories if enabled
        if configuration.enableNotificationCategories {
            await registerDefaultCategories()
        }
        
        await updateMetrics(sessionStarted: true)
    }
    
    internal func updateConfiguration(_ configuration: NotificationCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Authorization
    
    public func getAuthorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .notDetermined
        }
    }
    
    public func requestPermission() async throws -> NotificationAuthorizationStatus {
        var options: UNAuthorizationOptions = [.alert, .sound]
        
        if configuration.enableBadgeUpdates {
            options.insert(.badge)
        }
        
        if configuration.enableCriticalAlerts {
            options.insert(.criticalAlert)
        }
        
        if configuration.enableProvisionalAuthorization {
            options.insert(.provisional)
        }
        
        if configuration.enableNotificationActions {
            options.insert(.providesAppNotificationSettings)
        }
        
        return await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: options) { granted, error in
                Task {
                    await self.updateMetrics(permissionRequest: true, granted: granted)
                    
                    if granted {
                        continuation.resume(returning: .authorized)
                    } else {
                        continuation.resume(returning: .denied)
                    }
                }
            }
        }
    }
    
    // MARK: - Local Notifications
    
    public func scheduleLocalNotification(_ request: LocalNotificationRequest) async throws {
        guard configuration.enableLocalNotifications else {
            throw NotificationError.localNotificationsNotEnabled
        }
        
        guard await isAvailable() else {
            throw NotificationError.permissionDenied
        }
        
        // Check scheduled notification limit
        if scheduledNotifications.count >= configuration.maxScheduledNotifications {
            throw NotificationError.maxScheduledNotificationsReached
        }
        
        // Check quiet hours if enabled
        if configuration.enableQuietHours && await isInQuietHours() {
            // Defer notification until after quiet hours
            let modifiedRequest = try await adjustForQuietHours(request)
            return try await scheduleLocalNotification(modifiedRequest)
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = request.title
        if let subtitle = request.subtitle {
            content.subtitle = subtitle
        }
        content.body = request.body
        
        if let badge = request.badge {
            content.badge = NSNumber(value: badge)
        }
        
        if let sound = request.sound {
            content.sound = sound.unSound
        }
        
        if let category = request.category {
            content.categoryIdentifier = category
        }
        
        if let userInfo = request.userInfo {
            content.userInfo = userInfo
        }
        
        if let threadIdentifier = request.threadIdentifier {
            content.threadIdentifier = threadIdentifier
        }
        
        if let targetContentIdentifier = request.targetContentIdentifier {
            content.targetContentIdentifier = targetContentIdentifier
        }
        
        if let interruptionLevel = request.interruptionLevel {
            switch interruptionLevel {
            case .passive:
                content.interruptionLevel = .passive
            case .active:
                content.interruptionLevel = .active
            case .timeSensitive:
                content.interruptionLevel = .timeSensitive
            case .critical:
                content.interruptionLevel = .critical
            }
        }
        
        if let relevanceScore = request.relevanceScore {
            content.relevanceScore = relevanceScore
        }
        
        // Add attachments if enabled
        if configuration.enableRichNotifications, let attachments = request.attachments {
            content.attachments = attachments.compactMap { $0.unAttachment }
        }
        
        // Create notification request
        let unRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: request.trigger?.unTrigger
        )
        
        // Schedule notification
        try await notificationCenter.add(unRequest)
        
        // Store in scheduled notifications
        scheduledNotifications[request.identifier] = request
        
        await updateMetrics(localNotificationSent: true, scheduled: true)
    }
    
    public func cancelLocalNotification(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotifications.removeValue(forKey: identifier)
        await updateMetrics(canceled: true)
    }
    
    public func cancelAllLocalNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        let count = scheduledNotifications.count
        scheduledNotifications.removeAll()
        await updateMetrics(canceledCount: count)
    }
    
    public func getScheduledNotifications() async -> [LocalNotificationRequest] {
        Array(scheduledNotifications.values)
    }
    
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Push Notifications
    
    public func registerForPushNotifications() -> AsyncStream<PushNotificationToken> {
        AsyncStream { continuation in
            pushTokenContinuation = continuation
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    public func unregisterFromPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
        pushToken = nil
    }
    
    public func getPushToken() -> PushNotificationToken? {
        pushToken
    }
    
    // MARK: - Badge Management
    
    public func setBadgeCount(_ count: Int) async {
        guard configuration.enableBadgeUpdates else { return }
        
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
        
        await updateMetrics(badgeUpdate: true)
    }
    
    public func getBadgeCount() async -> Int {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber
        }
    }
    
    public func clearBadge() async {
        await setBadgeCount(0)
    }
    
    // MARK: - Categories and Actions
    
    public func registerNotificationCategory(_ category: NotificationCategory) async {
        guard configuration.enableNotificationCategories else { return }
        
        notificationCategories[category.identifier] = category
        
        let existingCategories = await notificationCenter.notificationCategories()
        var allCategories = existingCategories
        allCategories.insert(category.unCategory)
        
        notificationCenter.setNotificationCategories(allCategories)
    }
    
    public func registerNotificationCategories(_ categories: [NotificationCategory]) async {
        guard configuration.enableNotificationCategories else { return }
        
        for category in categories {
            notificationCategories[category.identifier] = category
        }
        
        let unCategories = Set(categories.map { $0.unCategory })
        notificationCenter.setNotificationCategories(unCategories)
    }
    
    public func getRegisteredCategories() -> [NotificationCategory] {
        Array(notificationCategories.values)
    }
    
    // MARK: - Notification History
    
    public func getDeliveredNotifications() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
    }
    
    public func removeDeliveredNotification(identifier: String) async {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    public func removeAllDeliveredNotifications() async {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    public func getNotificationHistory() -> [DeliveredNotification] {
        notificationHistory
    }
    
    public func clearNotificationHistory() {
        notificationHistory.removeAll()
    }
    
    // MARK: - Notification Responses
    
    public func getNotificationResponses() -> AsyncStream<NotificationResponse> {
        AsyncStream { continuation in
            notificationResponseContinuation = continuation
        }
    }
    
    // MARK: - Settings and Configuration
    
    public func openNotificationSettings() async {
        await MainActor.run {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    public func getNotificationSettings() async -> UNNotificationSettings {
        await notificationCenter.notificationSettings()
    }
    
    // MARK: - Metrics
    
    public func getMetrics() -> NotificationMetrics {
        metrics
    }
    
    // MARK: - Private Implementation
    
    private func registerDefaultCategories() async {
        let defaultCategories = [
            NotificationCategory(
                identifier: "DEFAULT_ACTION",
                actions: [
                    NotificationAction(identifier: "VIEW", title: "View"),
                    NotificationAction(identifier: "DISMISS", title: "Dismiss")
                ]
            ),
            NotificationCategory(
                identifier: "MESSAGE_CATEGORY",
                actions: [
                    NotificationAction(
                        identifier: "REPLY",
                        title: "Reply",
                        options: .foreground,
                        textInputButtonTitle: "Send",
                        textInputPlaceholder: "Type your reply..."
                    ),
                    NotificationAction(identifier: "MARK_READ", title: "Mark as Read")
                ]
            )
        ]
        
        await registerNotificationCategories(defaultCategories)
    }
    
    private func isInQuietHours() async -> Bool {
        guard configuration.enableQuietHours else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startTime = formatter.date(from: configuration.quietHoursStart),
              let endTime = formatter.date(from: configuration.quietHoursEnd) else {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentDate = calendar.date(from: currentTime) ?? now
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startTimeToday = calendar.date(from: startComponents) ?? startTime
        let endTimeToday = calendar.date(from: endComponents) ?? endTime
        
        if startTimeToday <= endTimeToday {
            // Same day quiet hours
            return currentDate >= startTimeToday && currentDate <= endTimeToday
        } else {
            // Overnight quiet hours
            return currentDate >= startTimeToday || currentDate <= endTimeToday
        }
    }
    
    private func adjustForQuietHours(_ request: LocalNotificationRequest) async throws -> LocalNotificationRequest {
        // Calculate when quiet hours end and schedule for then
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let endTime = formatter.date(from: configuration.quietHoursEnd) else {
            return request
        }
        
        let calendar = Calendar.current
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        var nextEndTime = calendar.nextDate(after: Date(), matching: endComponents, matchingPolicy: .nextTime) ?? Date()
        
        // Add a small buffer
        nextEndTime = nextEndTime.addingTimeInterval(60) // 1 minute buffer
        
        let adjustedTrigger = NotificationTrigger.calendar(nextEndTime, repeats: false)
        
        return LocalNotificationRequest(
            identifier: request.identifier,
            title: request.title,
            subtitle: request.subtitle,
            body: request.body,
            badge: request.badge,
            sound: request.sound,
            category: request.category,
            userInfo: request.userInfo,
            attachments: request.attachments,
            trigger: adjustedTrigger,
            threadIdentifier: request.threadIdentifier,
            targetContentIdentifier: request.targetContentIdentifier,
            interruptionLevel: request.interruptionLevel,
            relevanceScore: request.relevanceScore
        )
    }
    
    private func addToNotificationHistory(_ notification: DeliveredNotification) {
        guard configuration.enableNotificationHistory else { return }
        
        notificationHistory.append(notification)
        
        // Maintain history size limit
        if notificationHistory.count > configuration.maxHistoryCount {
            notificationHistory.removeFirst()
        }
        
        // Clean up old entries
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -configuration.historyRetentionDays, to: Date()) ?? Date.distantPast
        notificationHistory.removeAll { $0.date < cutoffDate }
    }
    
    private func updateMetrics(
        localNotificationSent: Bool = false,
        pushNotificationSent: Bool = false,
        notificationDelivered: Bool = false,
        notificationOpened: Bool = false,
        notificationDismissed: Bool = false,
        actionExecuted: Bool = false,
        deliveryTime: TimeInterval = 0,
        deliveryFailure: Bool = false,
        permissionRequest: Bool = false,
        granted: Bool = false,
        badgeUpdate: Bool = false,
        scheduled: Bool = false,
        canceled: Bool = false,
        canceledCount: Int = 0,
        sessionStarted: Bool = false
    ) async {
        
        if deliveryTime > 0 {
            deliveryTimes.append(deliveryTime)
        }
        
        let avgDeliveryTime = deliveryTimes.isEmpty ? 0 : deliveryTimes.reduce(0, +) / Double(deliveryTimes.count)
        
        metrics = NotificationMetrics(
            localNotificationsSent: localNotificationSent ? metrics.localNotificationsSent + 1 : metrics.localNotificationsSent,
            pushNotificationsSent: pushNotificationSent ? metrics.pushNotificationsSent + 1 : metrics.pushNotificationsSent,
            notificationsDelivered: notificationDelivered ? metrics.notificationsDelivered + 1 : metrics.notificationsDelivered,
            notificationsOpened: notificationOpened ? metrics.notificationsOpened + 1 : metrics.notificationsOpened,
            notificationsDismissed: notificationDismissed ? metrics.notificationsDismissed + 1 : metrics.notificationsDismissed,
            actionsExecuted: actionExecuted ? metrics.actionsExecuted + 1 : metrics.actionsExecuted,
            averageDeliveryTime: avgDeliveryTime,
            deliveryFailures: deliveryFailure ? metrics.deliveryFailures + 1 : metrics.deliveryFailures,
            permissionRequests: permissionRequest ? metrics.permissionRequests + 1 : metrics.permissionRequests,
            permissionGranted: granted ? metrics.permissionGranted + 1 : metrics.permissionGranted,
            badgeUpdates: badgeUpdate ? metrics.badgeUpdates + 1 : metrics.badgeUpdates,
            scheduledNotifications: scheduled ? metrics.scheduledNotifications + 1 : metrics.scheduledNotifications,
            canceledNotifications: canceled ? metrics.canceledNotifications + 1 : (canceledCount > 0 ? metrics.canceledNotifications + canceledCount : metrics.canceledNotifications)
        )
    }
    
    // MARK: - Delegate Handlers
    
    internal func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let notification = DeliveredNotification(from: response.notification)
        addToNotificationHistory(notification)
        
        let userText = (response as? UNTextInputNotificationResponse)?.userText
        
        let notificationResponse = NotificationResponse(
            notification: notification,
            actionIdentifier: response.actionIdentifier,
            userText: userText
        )
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            await updateMetrics(notificationOpened: true)
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            await updateMetrics(notificationDismissed: true)
        } else {
            await updateMetrics(actionExecuted: true)
        }
        
        notificationResponseContinuation?.yield(notificationResponse)
    }
    
    internal func handlePushTokenReceived(_ deviceToken: Data) async {
        let environment: PushNotificationToken.Environment = {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }()
        
        let token = PushNotificationToken(deviceToken: deviceToken, environment: environment)
        pushToken = token
        
        await updateMetrics(pushNotificationSent: false) // Token registration
        pushTokenContinuation?.yield(token)
    }
    
    internal func handlePushTokenError(_ error: Error) async {
        await updateMetrics(deliveryFailure: true)
    }
    
    internal func handleNotificationReceived(_ notification: UNNotification) async {
        let deliveredNotification = DeliveredNotification(from: notification)
        addToNotificationHistory(deliveredNotification)
        await updateMetrics(notificationDelivered: true, deliveryTime: 0.1) // Placeholder delivery time
    }
}

// MARK: - Notification Center Delegate

private class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var resource: NotificationCapabilityResource?
    
    init(resource: NotificationCapabilityResource) {
        self.resource = resource
        super.init()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task {
            await resource?.handleNotificationResponse(response)
            completionHandler()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Task {
            await resource?.handleNotificationReceived(notification)
            completionHandler([.banner, .sound, .badge])
        }
    }
}

// MARK: - Notification Capability Implementation

/// Notification capability providing local and push notifications
public actor NotificationCapability: DomainCapability {
    public typealias ConfigurationType = NotificationCapabilityConfiguration
    public typealias ResourceType = NotificationCapabilityResource
    
    private var _configuration: NotificationCapabilityConfiguration
    private var _resources: NotificationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "notification-capability" }
    
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
    
    public var configuration: NotificationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: NotificationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: NotificationCapabilityConfiguration = NotificationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = NotificationCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: NotificationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Notification configuration")
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
        // Notifications are supported on all iOS devices
        true
    }
    
    public func requestPermission() async throws {
        let status = try await _resources.requestPermission()
        guard status == .authorized || status == .provisional else {
            throw NotificationError.permissionDenied
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Local Notifications
    
    /// Schedule a local notification
    public func scheduleLocalNotification(_ request: LocalNotificationRequest) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Notification capability not available")
        }
        
        try await _resources.scheduleLocalNotification(request)
    }
    
    /// Cancel a local notification
    public func cancelLocalNotification(identifier: String) async {
        await _resources.cancelLocalNotification(identifier: identifier)
    }
    
    /// Cancel all local notifications
    public func cancelAllLocalNotifications() async {
        await _resources.cancelAllLocalNotifications()
    }
    
    /// Get scheduled notifications
    public func getScheduledNotifications() async -> [LocalNotificationRequest] {
        await _resources.getScheduledNotifications()
    }
    
    /// Get pending notifications
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await _resources.getPendingNotifications()
    }
    
    // MARK: - Push Notifications
    
    /// Register for push notifications
    public func registerForPushNotifications() async -> AsyncStream<PushNotificationToken> {
        await _resources.registerForPushNotifications()
    }
    
    /// Unregister from push notifications
    public func unregisterFromPushNotifications() async {
        await _resources.unregisterFromPushNotifications()
    }
    
    /// Get push notification token
    public func getPushToken() async -> PushNotificationToken? {
        await _resources.getPushToken()
    }
    
    // MARK: - Badge Management
    
    /// Set badge count
    public func setBadgeCount(_ count: Int) async {
        await _resources.setBadgeCount(count)
    }
    
    /// Get badge count
    public func getBadgeCount() async -> Int {
        await _resources.getBadgeCount()
    }
    
    /// Clear badge
    public func clearBadge() async {
        await _resources.clearBadge()
    }
    
    // MARK: - Categories and Actions
    
    /// Register notification category
    public func registerNotificationCategory(_ category: NotificationCategory) async {
        await _resources.registerNotificationCategory(category)
    }
    
    /// Register multiple notification categories
    public func registerNotificationCategories(_ categories: [NotificationCategory]) async {
        await _resources.registerNotificationCategories(categories)
    }
    
    /// Get registered categories
    public func getRegisteredCategories() async -> [NotificationCategory] {
        await _resources.getRegisteredCategories()
    }
    
    // MARK: - Notification History
    
    /// Get delivered notifications
    public func getDeliveredNotifications() async -> [UNNotification] {
        await _resources.getDeliveredNotifications()
    }
    
    /// Remove delivered notification
    public func removeDeliveredNotification(identifier: String) async {
        await _resources.removeDeliveredNotification(identifier: identifier)
    }
    
    /// Remove all delivered notifications
    public func removeAllDeliveredNotifications() async {
        await _resources.removeAllDeliveredNotifications()
    }
    
    /// Get notification history
    public func getNotificationHistory() async -> [DeliveredNotification] {
        await _resources.getNotificationHistory()
    }
    
    /// Clear notification history
    public func clearNotificationHistory() async {
        await _resources.clearNotificationHistory()
    }
    
    // MARK: - Notification Responses
    
    /// Get notification responses stream
    public func getNotificationResponses() async -> AsyncStream<NotificationResponse> {
        await _resources.getNotificationResponses()
    }
    
    // MARK: - Settings and Configuration
    
    /// Open notification settings
    public func openNotificationSettings() async {
        await _resources.openNotificationSettings()
    }
    
    /// Get notification settings
    public func getNotificationSettings() async -> UNNotificationSettings {
        await _resources.getNotificationSettings()
    }
    
    /// Get authorization status
    public func getAuthorizationStatus() async -> NotificationAuthorizationStatus {
        await _resources.getAuthorizationStatus()
    }
    
    /// Get metrics
    public func getMetrics() async -> NotificationMetrics {
        await _resources.getMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Send simple notification
    public func sendSimpleNotification(title: String, body: String, delay: TimeInterval = 0) async throws {
        let trigger: NotificationTrigger? = delay > 0 ? .timeInterval(delay, repeats: false) : .immediate
        
        let request = LocalNotificationRequest(
            title: title,
            body: body,
            trigger: trigger
        )
        
        try await scheduleLocalNotification(request)
    }
    
    /// Send notification with badge
    public func sendNotificationWithBadge(title: String, body: String, badge: Int) async throws {
        let request = LocalNotificationRequest(
            title: title,
            body: body,
            badge: badge
        )
        
        try await scheduleLocalNotification(request)
    }
    
    /// Schedule recurring notification
    public func scheduleRecurringNotification(
        title: String,
        body: String,
        dateComponents: DateComponents
    ) async throws {
        let request = LocalNotificationRequest(
            title: title,
            body: body,
            trigger: .dateComponents(dateComponents, repeats: true)
        )
        
        try await scheduleLocalNotification(request)
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Notification specific errors
public enum NotificationError: Error, LocalizedError {
    case permissionDenied
    case localNotificationsNotEnabled
    case pushNotificationsNotEnabled
    case maxScheduledNotificationsReached
    case invalidNotificationRequest
    case notificationNotFound
    case categoryNotFound
    case actionNotFound
    case pushTokenNotAvailable
    case deliveryFailed(Error)
    case schedulingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission denied"
        case .localNotificationsNotEnabled:
            return "Local notifications are not enabled"
        case .pushNotificationsNotEnabled:
            return "Push notifications are not enabled"
        case .maxScheduledNotificationsReached:
            return "Maximum number of scheduled notifications reached"
        case .invalidNotificationRequest:
            return "Invalid notification request"
        case .notificationNotFound:
            return "Notification not found"
        case .categoryNotFound:
            return "Notification category not found"
        case .actionNotFound:
            return "Notification action not found"
        case .pushTokenNotAvailable:
            return "Push notification token not available"
        case .deliveryFailed(let error):
            return "Notification delivery failed: \(error.localizedDescription)"
        case .schedulingFailed(let error):
            return "Notification scheduling failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

import CoreLocation

extension LocalNotificationRequest {
    /// Create location-based notification
    public static func locationBased(
        title: String,
        body: String,
        latitude: Double,
        longitude: Double,
        radius: Double,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = false
    ) -> LocalNotificationRequest {
        LocalNotificationRequest(
            title: title,
            body: body,
            trigger: .location(
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                notifyOnEntry: notifyOnEntry,
                notifyOnExit: notifyOnExit
            )
        )
    }
    
    /// Create time-based notification
    public static func timeBased(
        title: String,
        body: String,
        at date: Date,
        repeats: Bool = false
    ) -> LocalNotificationRequest {
        LocalNotificationRequest(
            title: title,
            body: body,
            trigger: .calendar(date, repeats: repeats)
        )
    }
    
    /// Create daily notification
    public static func daily(
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) -> LocalNotificationRequest {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return LocalNotificationRequest(
            title: title,
            body: body,
            trigger: .dateComponents(dateComponents, repeats: true)
        )
    }
}