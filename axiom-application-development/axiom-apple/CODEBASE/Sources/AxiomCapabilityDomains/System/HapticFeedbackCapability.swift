import Foundation
import UIKit
import CoreHaptics
import AxiomCore
import AxiomCapabilities

// MARK: - Haptic Feedback Capability Configuration

/// Configuration for Haptic Feedback capability
public struct HapticFeedbackCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableCoreHaptics: Bool
    public let enableLegacyHaptics: Bool
    public let enableCustomPatterns: Bool
    public let enablePreloadedPatterns: Bool
    public let intensityScale: Float
    public let sharpnessScale: Float
    public let enableAdaptiveIntensity: Bool
    public let enableBatteryOptimization: Bool
    public let enableAccessibilitySupport: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let maxPatternDuration: TimeInterval
    public let maxConcurrentPatterns: Int
    public let enableDebugMode: Bool
    public let enableThermalManagement: Bool
    
    public init(
        enableCoreHaptics: Bool = true,
        enableLegacyHaptics: Bool = true,
        enableCustomPatterns: Bool = true,
        enablePreloadedPatterns: Bool = true,
        intensityScale: Float = 1.0,
        sharpnessScale: Float = 1.0,
        enableAdaptiveIntensity: Bool = true,
        enableBatteryOptimization: Bool = true,
        enableAccessibilitySupport: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        maxPatternDuration: TimeInterval = 10.0,
        maxConcurrentPatterns: Int = 3,
        enableDebugMode: Bool = false,
        enableThermalManagement: Bool = true
    ) {
        self.enableCoreHaptics = enableCoreHaptics
        self.enableLegacyHaptics = enableLegacyHaptics
        self.enableCustomPatterns = enableCustomPatterns
        self.enablePreloadedPatterns = enablePreloadedPatterns
        self.intensityScale = intensityScale
        self.sharpnessScale = sharpnessScale
        self.enableAdaptiveIntensity = enableAdaptiveIntensity
        self.enableBatteryOptimization = enableBatteryOptimization
        self.enableAccessibilitySupport = enableAccessibilitySupport
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.maxPatternDuration = maxPatternDuration
        self.maxConcurrentPatterns = maxConcurrentPatterns
        self.enableDebugMode = enableDebugMode
        self.enableThermalManagement = enableThermalManagement
    }
    
    public var isValid: Bool {
        intensityScale >= 0 && intensityScale <= 2.0 &&
        sharpnessScale >= 0 && sharpnessScale <= 2.0 &&
        maxPatternDuration > 0 && maxPatternDuration <= 30.0 &&
        maxConcurrentPatterns > 0 && maxConcurrentPatterns <= 10
    }
    
    public func merged(with other: HapticFeedbackCapabilityConfiguration) -> HapticFeedbackCapabilityConfiguration {
        HapticFeedbackCapabilityConfiguration(
            enableCoreHaptics: other.enableCoreHaptics,
            enableLegacyHaptics: other.enableLegacyHaptics,
            enableCustomPatterns: other.enableCustomPatterns,
            enablePreloadedPatterns: other.enablePreloadedPatterns,
            intensityScale: other.intensityScale,
            sharpnessScale: other.sharpnessScale,
            enableAdaptiveIntensity: other.enableAdaptiveIntensity,
            enableBatteryOptimization: other.enableBatteryOptimization,
            enableAccessibilitySupport: other.enableAccessibilitySupport,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            maxPatternDuration: other.maxPatternDuration,
            maxConcurrentPatterns: other.maxConcurrentPatterns,
            enableDebugMode: other.enableDebugMode,
            enableThermalManagement: other.enableThermalManagement
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> HapticFeedbackCapabilityConfiguration {
        var adjustedCoreHaptics = enableCoreHaptics
        var adjustedIntensity = intensityScale
        var adjustedLogging = enableLogging
        var adjustedConcurrent = maxConcurrentPatterns
        
        if environment.isLowPowerMode {
            adjustedCoreHaptics = false // Disable Core Haptics in low power mode
            adjustedIntensity = min(intensityScale, 0.5) // Reduce intensity
            adjustedConcurrent = min(maxConcurrentPatterns, 1) // Limit to 1 pattern
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return HapticFeedbackCapabilityConfiguration(
            enableCoreHaptics: adjustedCoreHaptics,
            enableLegacyHaptics: enableLegacyHaptics,
            enableCustomPatterns: enableCustomPatterns,
            enablePreloadedPatterns: enablePreloadedPatterns,
            intensityScale: adjustedIntensity,
            sharpnessScale: sharpnessScale,
            enableAdaptiveIntensity: enableAdaptiveIntensity,
            enableBatteryOptimization: enableBatteryOptimization,
            enableAccessibilitySupport: enableAccessibilitySupport,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            maxPatternDuration: maxPatternDuration,
            maxConcurrentPatterns: adjustedConcurrent,
            enableDebugMode: enableDebugMode,
            enableThermalManagement: enableThermalManagement
        )
    }
}

// MARK: - Haptic Types

/// Haptic feedback types and patterns
public enum HapticFeedbackType: Sendable, Codable, CaseIterable {
    case impact(HapticImpactStyle)
    case notification(HapticNotificationType)
    case selection
    case pattern(HapticPattern)
    case custom(HapticCustomPattern)
    
    public enum HapticImpactStyle: String, Sendable, Codable, CaseIterable {
        case light = "light"
        case medium = "medium"
        case heavy = "heavy"
        case soft = "soft"      // iOS 13+
        case rigid = "rigid"    // iOS 13+
    }
    
    public enum HapticNotificationType: String, Sendable, Codable, CaseIterable {
        case success = "success"
        case warning = "warning"
        case error = "error"
    }
}

/// Predefined haptic patterns
public enum HapticPattern: String, Sendable, Codable, CaseIterable {
    case heartbeat = "heartbeat"
    case pulse = "pulse"
    case knock = "knock"
    case drumroll = "drumroll"
    case notification = "notification"
    case alarm = "alarm"
    case gentle = "gentle"
    case strong = "strong"
    case rhythm = "rhythm"
    case waves = "waves"
}

/// Custom haptic pattern definition
public struct HapticCustomPattern: Sendable, Codable {
    public let name: String
    public let events: [HapticEvent]
    public let duration: TimeInterval
    public let loops: Int
    public let metadata: [String: String]
    
    public init(
        name: String,
        events: [HapticEvent],
        duration: TimeInterval? = nil,
        loops: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.name = name
        self.events = events
        self.duration = duration ?? events.last?.time ?? 1.0
        self.loops = loops
        self.metadata = metadata
    }
}

/// Individual haptic event within a pattern
public struct HapticEvent: Sendable, Codable {
    public let time: TimeInterval
    public let type: EventType
    public let intensity: Float
    public let sharpness: Float
    public let duration: TimeInterval?
    
    public enum EventType: String, Sendable, Codable, CaseIterable {
        case transient = "transient"    // Short, sharp haptic
        case continuous = "continuous"  // Sustained haptic
        case parameter = "parameter"    // Parameter change
    }
    
    public init(
        time: TimeInterval,
        type: EventType,
        intensity: Float = 1.0,
        sharpness: Float = 1.0,
        duration: TimeInterval? = nil
    ) {
        self.time = time
        self.type = type
        self.intensity = max(0, min(1, intensity))
        self.sharpness = max(0, min(1, sharpness))
        self.duration = duration
    }
}

/// Haptic feedback result
public struct HapticFeedbackResult: Sendable {
    public let id: UUID
    public let type: HapticFeedbackType
    public let success: Bool
    public let duration: TimeInterval
    public let timestamp: Date
    public let error: HapticError?
    public let deviceSupported: Bool
    public let coreHapticsUsed: Bool
    
    public init(
        type: HapticFeedbackType,
        success: Bool,
        duration: TimeInterval,
        error: HapticError? = nil,
        deviceSupported: Bool = true,
        coreHapticsUsed: Bool = false
    ) {
        self.id = UUID()
        self.type = type
        self.success = success
        self.duration = duration
        self.timestamp = Date()
        self.error = error
        self.deviceSupported = deviceSupported
        self.coreHapticsUsed = coreHapticsUsed
    }
}

/// Haptic capability information
public struct HapticCapabilityInfo: Sendable {
    public let supportsCoreHaptics: Bool
    public let supportsLegacyHaptics: Bool
    public let supportsCustomPatterns: Bool
    public let supportsAudioHaptics: Bool
    public let maxPatternComplexity: Int
    public let deviceType: DeviceType
    public let availableEngines: [EngineType]
    
    public enum DeviceType: String, Sendable, Codable, CaseIterable {
        case iPhone = "iPhone"
        case iPad = "iPad"
        case watch = "watch"
        case mac = "mac"
        case unknown = "unknown"
    }
    
    public enum EngineType: String, Sendable, Codable, CaseIterable {
        case coreHaptics = "core-haptics"
        case legacyFeedback = "legacy-feedback"
        case tapticEngine = "taptic-engine"
        case linearActuator = "linear-actuator"
    }
    
    public init(
        supportsCoreHaptics: Bool = false,
        supportsLegacyHaptics: Bool = false,
        supportsCustomPatterns: Bool = false,
        supportsAudioHaptics: Bool = false,
        maxPatternComplexity: Int = 0,
        deviceType: DeviceType = .unknown,
        availableEngines: [EngineType] = []
    ) {
        self.supportsCoreHaptics = supportsCoreHaptics
        self.supportsLegacyHaptics = supportsLegacyHaptics
        self.supportsCustomPatterns = supportsCustomPatterns
        self.supportsAudioHaptics = supportsAudioHaptics
        self.maxPatternComplexity = maxPatternComplexity
        self.deviceType = deviceType
        self.availableEngines = availableEngines
    }
}

/// Haptic feedback metrics
public struct HapticMetrics: Sendable {
    public let totalFeedbackEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageEventDuration: TimeInterval
    public let coreHapticsUsage: Int
    public let legacyHapticsUsage: Int
    public let customPatternsPlayed: Int
    public let feedbacksByType: [String: Int]
    public let errorsByType: [String: Int]
    public let deviceSupport: HapticCapabilityInfo
    public let batteryImpact: Double
    public let thermalImpact: Double
    
    public init(
        totalFeedbackEvents: Int = 0,
        successfulEvents: Int = 0,
        failedEvents: Int = 0,
        averageEventDuration: TimeInterval = 0,
        coreHapticsUsage: Int = 0,
        legacyHapticsUsage: Int = 0,
        customPatternsPlayed: Int = 0,
        feedbacksByType: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        deviceSupport: HapticCapabilityInfo = HapticCapabilityInfo(),
        batteryImpact: Double = 0,
        thermalImpact: Double = 0
    ) {
        self.totalFeedbackEvents = totalFeedbackEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageEventDuration = averageEventDuration
        self.coreHapticsUsage = coreHapticsUsage
        self.legacyHapticsUsage = legacyHapticsUsage
        self.customPatternsPlayed = customPatternsPlayed
        self.feedbacksByType = feedbacksByType
        self.errorsByType = errorsByType
        self.deviceSupport = deviceSupport
        self.batteryImpact = batteryImpact
        self.thermalImpact = thermalImpact
    }
    
    public var successRate: Double {
        totalFeedbackEvents > 0 ? Double(successfulEvents) / Double(totalFeedbackEvents) : 0
    }
    
    public var coreHapticsUtilization: Double {
        let totalUsage = coreHapticsUsage + legacyHapticsUsage
        return totalUsage > 0 ? Double(coreHapticsUsage) / Double(totalUsage) : 0
    }
}

// MARK: - Haptic Resource

/// Haptic feedback resource management
public actor HapticFeedbackCapabilityResource: AxiomCapabilityResource {
    private let configuration: HapticFeedbackCapabilityConfiguration
    private var coreHapticsEngine: CHHapticEngine?
    private var legacyImpactFeedback: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var legacyNotificationFeedback: UINotificationFeedbackGenerator?
    private var legacySelectionFeedback: UISelectionFeedbackGenerator?
    private var activePatterns: Set<UUID> = []
    private var preloadedPatterns: [String: CHHapticPattern] = [:]
    private var metrics: HapticMetrics = HapticMetrics()
    private var capabilityInfo: HapticCapabilityInfo
    private var isEngineRunning: Bool = false
    
    public init(configuration: HapticFeedbackCapabilityConfiguration) {
        self.configuration = configuration
        self.capabilityInfo = HapticCapabilityInfo()
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 10_000_000, // 10MB for haptic patterns and engines
            cpu: 2.0, // Haptic processing
            bandwidth: 0,
            storage: 1_000_000 // 1MB for pattern storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let patternMemory = preloadedPatterns.count * 50_000
            let activeMemory = activePatterns.count * 100_000
            
            return ResourceUsage(
                memory: patternMemory + activeMemory + 1_000_000,
                cpu: isEngineRunning ? 1.0 : 0.1,
                bandwidth: 0,
                storage: preloadedPatterns.count * 25_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        return capabilityInfo.supportsCoreHaptics || capabilityInfo.supportsLegacyHaptics
    }
    
    public func release() async {
        // Stop Core Haptics engine
        coreHapticsEngine?.stop()
        coreHapticsEngine = nil
        isEngineRunning = false
        
        // Release legacy feedback generators
        legacyImpactFeedback.removeAll()
        legacyNotificationFeedback = nil
        legacySelectionFeedback = nil
        
        // Clear patterns and state
        preloadedPatterns.removeAll()
        activePatterns.removeAll()
        metrics = HapticMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Detect device capabilities
        await detectHapticCapabilities()
        
        // Initialize Core Haptics if supported and enabled
        if configuration.enableCoreHaptics && capabilityInfo.supportsCoreHaptics {
            try await initializeCoreHaptics()
        }
        
        // Initialize legacy haptics if enabled
        if configuration.enableLegacyHaptics && capabilityInfo.supportsLegacyHaptics {
            await initializeLegacyHaptics()
        }
        
        // Preload patterns if enabled
        if configuration.enablePreloadedPatterns {
            await preloadStandardPatterns()
        }
    }
    
    internal func updateConfiguration(_ configuration: HapticFeedbackCapabilityConfiguration) async throws {
        // Restart engines if major settings changed
        if configuration.enableCoreHaptics != self.configuration.enableCoreHaptics {
            if configuration.enableCoreHaptics && capabilityInfo.supportsCoreHaptics {
                try await initializeCoreHaptics()
            } else {
                coreHapticsEngine?.stop()
                coreHapticsEngine = nil
                isEngineRunning = false
            }
        }
    }
    
    // MARK: - Haptic Feedback
    
    public func playHapticFeedback(_ type: HapticFeedbackType) async throws -> HapticFeedbackResult {
        let startTime = Date()
        
        // Check thermal state if enabled
        if configuration.enableThermalManagement {
            let thermalState = ProcessInfo.processInfo.thermalState
            if thermalState == .critical {
                throw HapticError.thermalThrottling
            }
        }
        
        // Check concurrent pattern limit
        if activePatterns.count >= configuration.maxConcurrentPatterns {
            throw HapticError.tooManyPatterns(configuration.maxConcurrentPatterns)
        }
        
        var result: HapticFeedbackResult
        
        do {
            switch type {
            case .impact(let style):
                result = try await playImpactFeedback(style)
            case .notification(let notificationType):
                result = try await playNotificationFeedback(notificationType)
            case .selection:
                result = try await playSelectionFeedback()
            case .pattern(let pattern):
                result = try await playPattern(pattern)
            case .custom(let customPattern):
                result = try await playCustomPattern(customPattern)
            }
            
            await updateSuccessMetrics(result: result)
            
        } catch let error as HapticError {
            let duration = Date().timeIntervalSince(startTime)
            result = HapticFeedbackResult(
                type: type,
                success: false,
                duration: duration,
                error: error,
                deviceSupported: capabilityInfo.supportsCoreHaptics || capabilityInfo.supportsLegacyHaptics
            )
            
            await updateFailureMetrics(result: result, error: error)
        }
        
        if configuration.enableLogging {
            await logHapticResult(result)
        }
        
        return result
    }
    
    public func playCustomPattern(_ pattern: HapticCustomPattern) async throws -> HapticFeedbackResult {
        let startTime = Date()
        let patternId = UUID()
        activePatterns.insert(patternId)
        
        defer {
            activePatterns.remove(patternId)
        }
        
        // Validate pattern duration
        if pattern.duration > configuration.maxPatternDuration {
            throw HapticError.patternTooLong(pattern.duration, configuration.maxPatternDuration)
        }
        
        if configuration.enableCoreHaptics && capabilityInfo.supportsCoreHaptics {
            return try await playCoreHapticsCustomPattern(pattern, startTime: startTime)
        } else if configuration.enableLegacyHaptics {
            return try await playLegacyCustomPattern(pattern, startTime: startTime)
        } else {
            throw HapticError.engineUnavailable
        }
    }
    
    public func preloadPattern(_ pattern: HapticCustomPattern) async throws {
        guard configuration.enableCoreHaptics && capabilityInfo.supportsCoreHaptics else {
            throw HapticError.engineUnavailable
        }
        
        guard let engine = coreHapticsEngine else {
            throw HapticError.engineUnavailable
        }
        
        let hapticPattern = try await createCoreHapticsPattern(from: pattern)
        preloadedPatterns[pattern.name] = hapticPattern
        
        if configuration.enableLogging {
            print("[Haptic] 📁 Preloaded pattern: \(pattern.name)")
        }
    }
    
    public func stopAllHaptics() async {
        if let engine = coreHapticsEngine {
            do {
                try engine.stop()
                try engine.start()
            } catch {
                if configuration.enableLogging {
                    print("[Haptic] ⚠️ Failed to restart engine: \(error)")
                }
            }
        }
        
        activePatterns.removeAll()
    }
    
    // MARK: - Capability Information
    
    public func getCapabilityInfo() async -> HapticCapabilityInfo {
        capabilityInfo
    }
    
    public func getMetrics() async -> HapticMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = HapticMetrics(deviceSupport: capabilityInfo)
    }
    
    // MARK: - Private Methods
    
    private func detectHapticCapabilities() async {
        let coreHapticsSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        let legacySupported = true // All iOS devices support legacy haptics
        
        let deviceType: HapticCapabilityInfo.DeviceType
        if UIDevice.current.userInterfaceIdiom == .phone {
            deviceType = .iPhone
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            deviceType = .iPad
        } else {
            deviceType = .unknown
        }
        
        var availableEngines: [HapticCapabilityInfo.EngineType] = []
        if coreHapticsSupported {
            availableEngines.append(.coreHaptics)
            availableEngines.append(.tapticEngine)
        }
        if legacySupported {
            availableEngines.append(.legacyFeedback)
        }
        
        capabilityInfo = HapticCapabilityInfo(
            supportsCoreHaptics: coreHapticsSupported,
            supportsLegacyHaptics: legacySupported,
            supportsCustomPatterns: coreHapticsSupported,
            supportsAudioHaptics: coreHapticsSupported,
            maxPatternComplexity: coreHapticsSupported ? 100 : 10,
            deviceType: deviceType,
            availableEngines: availableEngines
        )
    }
    
    private func initializeCoreHaptics() async throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            throw HapticError.engineUnavailable
        }
        
        do {
            coreHapticsEngine = try CHHapticEngine()
            
            coreHapticsEngine?.stoppedHandler = { [weak self] reason in
                Task { [weak self] in
                    await self?.handleEngineStop(reason: reason)
                }
            }
            
            coreHapticsEngine?.resetHandler = { [weak self] in
                Task { [weak self] in
                    await self?.handleEngineReset()
                }
            }
            
            try coreHapticsEngine?.start()
            isEngineRunning = true
            
            if configuration.enableLogging {
                print("[Haptic] ✅ Core Haptics engine initialized")
            }
            
        } catch {
            throw HapticError.engineInitializationFailed(error.localizedDescription)
        }
    }
    
    private func initializeLegacyHaptics() async {
        // Initialize impact feedback generators
        for style in UIImpactFeedbackGenerator.FeedbackStyle.allCases {
            legacyImpactFeedback[style] = UIImpactFeedbackGenerator(style: style)
            legacyImpactFeedback[style]?.prepare()
        }
        
        // Initialize notification feedback generator
        legacyNotificationFeedback = UINotificationFeedbackGenerator()
        legacyNotificationFeedback?.prepare()
        
        // Initialize selection feedback generator
        legacySelectionFeedback = UISelectionFeedbackGenerator()
        legacySelectionFeedback?.prepare()
        
        if configuration.enableLogging {
            print("[Haptic] ✅ Legacy haptics initialized")
        }
    }
    
    private func preloadStandardPatterns() async {
        guard configuration.enableCoreHaptics && capabilityInfo.supportsCoreHaptics else { return }
        
        let standardPatterns: [HapticPattern: HapticCustomPattern] = [
            .heartbeat: createHeartbeatPattern(),
            .pulse: createPulsePattern(),
            .knock: createKnockPattern(),
            .drumroll: createDrumrollPattern(),
            .gentle: createGentlePattern(),
            .strong: createStrongPattern()
        ]
        
        for (pattern, customPattern) in standardPatterns {
            do {
                try await preloadPattern(customPattern)
            } catch {
                if configuration.enableLogging {
                    print("[Haptic] ⚠️ Failed to preload pattern \(pattern): \(error)")
                }
            }
        }
    }
    
    private func playImpactFeedback(_ style: HapticFeedbackType.HapticImpactStyle) async throws -> HapticFeedbackResult {
        let startTime = Date()
        
        if configuration.enableCoreHaptics && capabilityInfo.supportsCoreHaptics {
            return try await playCoreHapticsImpact(style, startTime: startTime)
        } else if configuration.enableLegacyHaptics {
            return try await playLegacyImpact(style, startTime: startTime)
        } else {
            throw HapticError.engineUnavailable
        }
    }
    
    private func playNotificationFeedback(_ type: HapticFeedbackType.HapticNotificationType) async throws -> HapticFeedbackResult {
        let startTime = Date()
        
        if configuration.enableLegacyHaptics, let generator = legacyNotificationFeedback {
            let legacyType: UINotificationFeedbackGenerator.FeedbackType
            switch type {
            case .success:
                legacyType = .success
            case .warning:
                legacyType = .warning
            case .error:
                legacyType = .error
            }
            
            generator.notificationOccurred(legacyType)
            let duration = Date().timeIntervalSince(startTime)
            
            return HapticFeedbackResult(
                type: .notification(type),
                success: true,
                duration: duration,
                deviceSupported: true,
                coreHapticsUsed: false
            )
        } else {
            throw HapticError.engineUnavailable
        }
    }
    
    private func playSelectionFeedback() async throws -> HapticFeedbackResult {
        let startTime = Date()
        
        if configuration.enableLegacyHaptics, let generator = legacySelectionFeedback {
            generator.selectionChanged()
            let duration = Date().timeIntervalSince(startTime)
            
            return HapticFeedbackResult(
                type: .selection,
                success: true,
                duration: duration,
                deviceSupported: true,
                coreHapticsUsed: false
            )
        } else {
            throw HapticError.engineUnavailable
        }
    }
    
    private func playPattern(_ pattern: HapticPattern) async throws -> HapticFeedbackResult {
        let customPattern = getStandardPattern(pattern)
        return try await playCustomPattern(customPattern)
    }
    
    private func playCoreHapticsImpact(_ style: HapticFeedbackType.HapticImpactStyle, startTime: Date) async throws -> HapticFeedbackResult {
        guard let engine = coreHapticsEngine else {
            throw HapticError.engineUnavailable
        }
        
        let intensity: Float
        let sharpness: Float
        
        switch style {
        case .light:
            intensity = 0.4 * configuration.intensityScale
            sharpness = 0.3 * configuration.sharpnessScale
        case .medium:
            intensity = 0.7 * configuration.intensityScale
            sharpness = 0.5 * configuration.sharpnessScale
        case .heavy:
            intensity = 1.0 * configuration.intensityScale
            sharpness = 0.8 * configuration.sharpnessScale
        case .soft:
            intensity = 0.3 * configuration.intensityScale
            sharpness = 0.2 * configuration.sharpnessScale
        case .rigid:
            intensity = 0.8 * configuration.intensityScale
            sharpness = 1.0 * configuration.sharpnessScale
        }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            let duration = Date().timeIntervalSince(startTime)
            
            return HapticFeedbackResult(
                type: .impact(style),
                success: true,
                duration: duration,
                deviceSupported: true,
                coreHapticsUsed: true
            )
        } catch {
            throw HapticError.playbackFailed(error.localizedDescription)
        }
    }
    
    private func playLegacyImpact(_ style: HapticFeedbackType.HapticImpactStyle, startTime: Date) async throws -> HapticFeedbackResult {
        let legacyStyle: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch style {
        case .light, .soft:
            legacyStyle = .light
        case .medium:
            legacyStyle = .medium
        case .heavy, .rigid:
            legacyStyle = .heavy
        }
        
        guard let generator = legacyImpactFeedback[legacyStyle] else {
            throw HapticError.engineUnavailable
        }
        
        generator.impactOccurred()
        let duration = Date().timeIntervalSince(startTime)
        
        return HapticFeedbackResult(
            type: .impact(style),
            success: true,
            duration: duration,
            deviceSupported: true,
            coreHapticsUsed: false
        )
    }
    
    private func playCoreHapticsCustomPattern(_ pattern: HapticCustomPattern, startTime: Date) async throws -> HapticFeedbackResult {
        guard let engine = coreHapticsEngine else {
            throw HapticError.engineUnavailable
        }
        
        do {
            let hapticPattern = try await createCoreHapticsPattern(from: pattern)
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: 0)
            
            let duration = Date().timeIntervalSince(startTime)
            
            return HapticFeedbackResult(
                type: .custom(pattern),
                success: true,
                duration: duration,
                deviceSupported: true,
                coreHapticsUsed: true
            )
        } catch {
            throw HapticError.playbackFailed(error.localizedDescription)
        }
    }
    
    private func playLegacyCustomPattern(_ pattern: HapticCustomPattern, startTime: Date) async throws -> HapticFeedbackResult {
        // Simplified legacy pattern playback
        // Play a series of impact feedbacks based on pattern events
        
        guard let generator = legacyImpactFeedback[.medium] else {
            throw HapticError.engineUnavailable
        }
        
        for event in pattern.events {
            if event.type == .transient {
                generator.impactOccurred()
                if event.time < pattern.duration {
                    try await Task.sleep(nanoseconds: UInt64(event.time * 1_000_000_000))
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return HapticFeedbackResult(
            type: .custom(pattern),
            success: true,
            duration: duration,
            deviceSupported: true,
            coreHapticsUsed: false
        )
    }
    
    private func createCoreHapticsPattern(from customPattern: HapticCustomPattern) async throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        for event in customPattern.events {
            let intensity = event.intensity * configuration.intensityScale
            let sharpness = event.sharpness * configuration.sharpnessScale
            
            let hapticEvent: CHHapticEvent
            
            switch event.type {
            case .transient:
                hapticEvent = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: event.time
                )
            case .continuous:
                hapticEvent = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: event.time,
                    duration: event.duration ?? 0.1
                )
            case .parameter:
                // Parameter events are used for dynamic changes
                continue
            }
            
            events.append(hapticEvent)
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func getStandardPattern(_ pattern: HapticPattern) -> HapticCustomPattern {
        switch pattern {
        case .heartbeat:
            return createHeartbeatPattern()
        case .pulse:
            return createPulsePattern()
        case .knock:
            return createKnockPattern()
        case .drumroll:
            return createDrumrollPattern()
        case .notification:
            return createNotificationPattern()
        case .alarm:
            return createAlarmPattern()
        case .gentle:
            return createGentlePattern()
        case .strong:
            return createStrongPattern()
        case .rhythm:
            return createRhythmPattern()
        case .waves:
            return createWavesPattern()
        }
    }
    
    // Pattern creation methods
    private func createHeartbeatPattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .transient, intensity: 0.8, sharpness: 0.5),
            HapticEvent(time: 0.15, type: .transient, intensity: 0.6, sharpness: 0.3),
            HapticEvent(time: 0.8, type: .transient, intensity: 0.8, sharpness: 0.5),
            HapticEvent(time: 0.95, type: .transient, intensity: 0.6, sharpness: 0.3)
        ]
        return HapticCustomPattern(name: "heartbeat", events: events, duration: 1.2)
    }
    
    private func createPulsePattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .continuous, intensity: 0.7, sharpness: 0.5, duration: 0.2)
        ]
        return HapticCustomPattern(name: "pulse", events: events, duration: 0.3)
    }
    
    private func createKnockPattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .transient, intensity: 1.0, sharpness: 0.8),
            HapticEvent(time: 0.1, type: .transient, intensity: 1.0, sharpness: 0.8),
            HapticEvent(time: 0.2, type: .transient, intensity: 1.0, sharpness: 0.8)
        ]
        return HapticCustomPattern(name: "knock", events: events, duration: 0.5)
    }
    
    private func createDrumrollPattern() -> HapticCustomPattern {
        var events: [HapticEvent] = []
        for i in 0..<20 {
            let time = Double(i) * 0.05
            events.append(HapticEvent(time: time, type: .transient, intensity: 0.6, sharpness: 0.7))
        }
        return HapticCustomPattern(name: "drumroll", events: events, duration: 1.0)
    }
    
    private func createNotificationPattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .transient, intensity: 0.8, sharpness: 0.5),
            HapticEvent(time: 0.1, type: .transient, intensity: 0.6, sharpness: 0.3),
            HapticEvent(time: 0.2, type: .transient, intensity: 1.0, sharpness: 0.8)
        ]
        return HapticCustomPattern(name: "notification", events: events, duration: 0.5)
    }
    
    private func createAlarmPattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .continuous, intensity: 1.0, sharpness: 1.0, duration: 0.3),
            HapticEvent(time: 0.5, type: .continuous, intensity: 1.0, sharpness: 1.0, duration: 0.3),
            HapticEvent(time: 1.0, type: .continuous, intensity: 1.0, sharpness: 1.0, duration: 0.3)
        ]
        return HapticCustomPattern(name: "alarm", events: events, duration: 1.5)
    }
    
    private func createGentlePattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .continuous, intensity: 0.3, sharpness: 0.2, duration: 0.5)
        ]
        return HapticCustomPattern(name: "gentle", events: events, duration: 0.6)
    }
    
    private func createStrongPattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .transient, intensity: 1.0, sharpness: 1.0),
            HapticEvent(time: 0.05, type: .continuous, intensity: 0.8, sharpness: 0.8, duration: 0.2)
        ]
        return HapticCustomPattern(name: "strong", events: events, duration: 0.3)
    }
    
    private func createRhythmPattern() -> HapticCustomPattern {
        let events = [
            HapticEvent(time: 0.0, type: .transient, intensity: 0.8, sharpness: 0.6),
            HapticEvent(time: 0.25, type: .transient, intensity: 0.6, sharpness: 0.4),
            HapticEvent(time: 0.5, type: .transient, intensity: 1.0, sharpness: 0.8),
            HapticEvent(time: 0.625, type: .transient, intensity: 0.4, sharpness: 0.3)
        ]
        return HapticCustomPattern(name: "rhythm", events: events, duration: 1.0)
    }
    
    private func createWavesPattern() -> HapticCustomPattern {
        var events: [HapticEvent] = []
        for i in 0..<10 {
            let time = Double(i) * 0.1
            let intensity = Float(0.3 + 0.4 * sin(Double(i) * 0.6))
            events.append(HapticEvent(time: time, type: .transient, intensity: intensity, sharpness: 0.5))
        }
        return HapticCustomPattern(name: "waves", events: events, duration: 1.0)
    }
    
    private func handleEngineStop(reason: CHHapticEngine.StoppedReason) async {
        isEngineRunning = false
        
        if configuration.enableLogging {
            print("[Haptic] ⚠️ Engine stopped: \(reason)")
        }
        
        // Try to restart engine
        do {
            try coreHapticsEngine?.start()
            isEngineRunning = true
        } catch {
            if configuration.enableLogging {
                print("[Haptic] ❌ Failed to restart engine: \(error)")
            }
        }
    }
    
    private func handleEngineReset() async {
        if configuration.enableLogging {
            print("[Haptic] 🔄 Engine reset")
        }
        
        // Re-preload patterns after reset
        if configuration.enablePreloadedPatterns {
            await preloadStandardPatterns()
        }
    }
    
    private func updateSuccessMetrics(result: HapticFeedbackResult) async {
        let totalEvents = metrics.totalFeedbackEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        let coreHapticsUsage = metrics.coreHapticsUsage + (result.coreHapticsUsed ? 1 : 0)
        let legacyUsage = metrics.legacyHapticsUsage + (result.coreHapticsUsed ? 0 : 1)
        
        let newAverageDuration = ((metrics.averageEventDuration * Double(metrics.totalFeedbackEvents)) + result.duration) / Double(totalEvents)
        
        var newFeedbacksByType = metrics.feedbacksByType
        let typeKey = getTypeKey(from: result.type)
        newFeedbacksByType[typeKey, default: 0] += 1
        
        let customPatternsPlayed = metrics.customPatternsPlayed + (isCustomPattern(result.type) ? 1 : 0)
        
        metrics = HapticMetrics(
            totalFeedbackEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageEventDuration: newAverageDuration,
            coreHapticsUsage: coreHapticsUsage,
            legacyHapticsUsage: legacyUsage,
            customPatternsPlayed: customPatternsPlayed,
            feedbacksByType: newFeedbacksByType,
            errorsByType: metrics.errorsByType,
            deviceSupport: metrics.deviceSupport,
            batteryImpact: metrics.batteryImpact,
            thermalImpact: metrics.thermalImpact
        )
    }
    
    private func updateFailureMetrics(result: HapticFeedbackResult, error: HapticError) async {
        let totalEvents = metrics.totalFeedbackEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var newErrorsByType = metrics.errorsByType
        let errorKey = String(describing: error)
        newErrorsByType[errorKey, default: 0] += 1
        
        metrics = HapticMetrics(
            totalFeedbackEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageEventDuration: metrics.averageEventDuration,
            coreHapticsUsage: metrics.coreHapticsUsage,
            legacyHapticsUsage: metrics.legacyHapticsUsage,
            customPatternsPlayed: metrics.customPatternsPlayed,
            feedbacksByType: metrics.feedbacksByType,
            errorsByType: newErrorsByType,
            deviceSupport: metrics.deviceSupport,
            batteryImpact: metrics.batteryImpact,
            thermalImpact: metrics.thermalImpact
        )
    }
    
    private func getTypeKey(from type: HapticFeedbackType) -> String {
        switch type {
        case .impact(let style):
            return "impact-\(style.rawValue)"
        case .notification(let notificationType):
            return "notification-\(notificationType.rawValue)"
        case .selection:
            return "selection"
        case .pattern(let pattern):
            return "pattern-\(pattern.rawValue)"
        case .custom(let customPattern):
            return "custom-\(customPattern.name)"
        }
    }
    
    private func isCustomPattern(_ type: HapticFeedbackType) -> Bool {
        switch type {
        case .custom, .pattern:
            return true
        default:
            return false
        }
    }
    
    private func logHapticResult(_ result: HapticFeedbackResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let engineType = result.coreHapticsUsed ? "Core" : "Legacy"
        let typeDescription = getTypeKey(from: result.type)
        
        print("[Haptic] \(statusIcon) \(engineType) \(typeDescription) (\(String(format: "%.3f", result.duration))s)")
        
        if let error = result.error {
            print("[Haptic] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Haptic Capability Implementation

/// Haptic Feedback capability providing comprehensive tactile feedback patterns
public actor HapticFeedbackCapability: DomainCapability {
    public typealias ConfigurationType = HapticFeedbackCapabilityConfiguration
    public typealias ResourceType = HapticFeedbackCapabilityResource
    
    private var _configuration: HapticFeedbackCapabilityConfiguration
    private var _resources: HapticFeedbackCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "haptic-feedback-capability" }
    
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
    
    public var configuration: HapticFeedbackCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: HapticFeedbackCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: HapticFeedbackCapabilityConfiguration = HapticFeedbackCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = HapticFeedbackCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: HapticFeedbackCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Haptic Feedback configuration")
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
        let capabilityInfo = await _resources.getCapabilityInfo()
        return capabilityInfo.supportsCoreHaptics || capabilityInfo.supportsLegacyHaptics
    }
    
    public func requestPermission() async throws {
        // Haptic feedback doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Haptic Feedback Operations
    
    /// Play haptic feedback
    public func playHapticFeedback(_ type: HapticFeedbackType) async throws -> HapticFeedbackResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        return try await _resources.playHapticFeedback(type)
    }
    
    /// Play custom haptic pattern
    public func playCustomPattern(_ pattern: HapticCustomPattern) async throws -> HapticFeedbackResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        return try await _resources.playCustomPattern(pattern)
    }
    
    /// Preload haptic pattern
    public func preloadPattern(_ pattern: HapticCustomPattern) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        try await _resources.preloadPattern(pattern)
    }
    
    /// Stop all haptic feedback
    public func stopAllHaptics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        await _resources.stopAllHaptics()
    }
    
    /// Get device haptic capabilities
    public func getCapabilityInfo() async throws -> HapticCapabilityInfo {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        return await _resources.getCapabilityInfo()
    }
    
    /// Get haptic metrics
    public func getMetrics() async throws -> HapticMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Haptic Feedback capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Play light impact feedback
    public func playLightImpact() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.impact(.light))
    }
    
    /// Play medium impact feedback
    public func playMediumImpact() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.impact(.medium))
    }
    
    /// Play heavy impact feedback
    public func playHeavyImpact() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.impact(.heavy))
    }
    
    /// Play success notification
    public func playSuccessNotification() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.notification(.success))
    }
    
    /// Play warning notification
    public func playWarningNotification() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.notification(.warning))
    }
    
    /// Play error notification
    public func playErrorNotification() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.notification(.error))
    }
    
    /// Play selection feedback
    public func playSelectionFeedback() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.selection)
    }
    
    /// Play heartbeat pattern
    public func playHeartbeat() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.pattern(.heartbeat))
    }
    
    /// Play gentle pattern
    public func playGentle() async throws -> HapticFeedbackResult {
        return try await playHapticFeedback(.pattern(.gentle))
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extensions

extension UIImpactFeedbackGenerator.FeedbackStyle: CaseIterable {
    public static var allCases: [UIImpactFeedbackGenerator.FeedbackStyle] {
        if #available(iOS 13.0, *) {
            return [.light, .medium, .heavy, .soft, .rigid]
        } else {
            return [.light, .medium, .heavy]
        }
    }
}

// MARK: - Error Types

/// Haptic specific errors
public enum HapticError: Error, LocalizedError {
    case engineUnavailable
    case engineInitializationFailed(String)
    case playbackFailed(String)
    case patternTooLong(TimeInterval, TimeInterval)
    case tooManyPatterns(Int)
    case invalidPattern(String)
    case thermalThrottling
    case deviceNotSupported
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .engineUnavailable:
            return "Haptic engine is not available"
        case .engineInitializationFailed(let reason):
            return "Haptic engine initialization failed: \(reason)"
        case .playbackFailed(let reason):
            return "Haptic playback failed: \(reason)"
        case .patternTooLong(let duration, let maxDuration):
            return "Pattern duration (\(duration)s) exceeds maximum (\(maxDuration)s)"
        case .tooManyPatterns(let maxPatterns):
            return "Too many concurrent patterns (max: \(maxPatterns))"
        case .invalidPattern(let reason):
            return "Invalid haptic pattern: \(reason)"
        case .thermalThrottling:
            return "Haptic feedback disabled due to thermal throttling"
        case .deviceNotSupported:
            return "Device does not support haptic feedback"
        case .configurationError(let reason):
            return "Haptic configuration error: \(reason)"
        }
    }
}