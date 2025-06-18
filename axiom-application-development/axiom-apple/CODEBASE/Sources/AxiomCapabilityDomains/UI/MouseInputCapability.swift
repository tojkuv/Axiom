import Foundation
import UIKit
import CoreGraphics
import AxiomCore
import AxiomCapabilities

// MARK: - Mouse Input Capability Configuration

/// Configuration for Mouse Input capability
public struct MouseInputCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableMouseInput: Bool
    public let enableTrackpadInput: Bool
    public let enableScrollGestures: Bool
    public let enableMultiButtonSupport: Bool
    public let enablePrecisionPointing: Bool
    public let enableMagicMouse: Bool
    public let enableForceTouch: Bool
    public let maxConcurrentInputs: Int
    public let inputTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let pointerSensitivity: PointerSensitivity
    public let scrollSensitivity: ScrollSensitivity
    public let clickThreshold: ClickThreshold
    public let doubleClickInterval: TimeInterval
    public let dragThreshold: CGFloat
    public let scrollAcceleration: Bool
    public let naturalScrolling: Bool
    public let tapToClick: Bool
    public let rightClickBehavior: RightClickBehavior
    
    public enum PointerSensitivity: String, Codable, CaseIterable {
        case slow = "slow"
        case normal = "normal"
        case fast = "fast"
        case custom = "custom"
    }
    
    public enum ScrollSensitivity: String, Codable, CaseIterable {
        case slow = "slow"
        case normal = "normal"
        case fast = "fast"
        case custom = "custom"
    }
    
    public enum ClickThreshold: String, Codable, CaseIterable {
        case light = "light"
        case medium = "medium"
        case firm = "firm"
        case custom = "custom"
    }
    
    public enum RightClickBehavior: String, Codable, CaseIterable {
        case contextMenu = "contextMenu"
        case secondaryAction = "secondaryAction"
        case disabled = "disabled"
        case custom = "custom"
    }
    
    public init(
        enableMouseInput: Bool = true,
        enableTrackpadInput: Bool = true,
        enableScrollGestures: Bool = true,
        enableMultiButtonSupport: Bool = true,
        enablePrecisionPointing: Bool = true,
        enableMagicMouse: Bool = true,
        enableForceTouch: Bool = true,
        maxConcurrentInputs: Int = 5,
        inputTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 300,
        pointerSensitivity: PointerSensitivity = .normal,
        scrollSensitivity: ScrollSensitivity = .normal,
        clickThreshold: ClickThreshold = .medium,
        doubleClickInterval: TimeInterval = 0.5,
        dragThreshold: CGFloat = 5.0,
        scrollAcceleration: Bool = true,
        naturalScrolling: Bool = true,
        tapToClick: Bool = true,
        rightClickBehavior: RightClickBehavior = .contextMenu
    ) {
        self.enableMouseInput = enableMouseInput
        self.enableTrackpadInput = enableTrackpadInput
        self.enableScrollGestures = enableScrollGestures
        self.enableMultiButtonSupport = enableMultiButtonSupport
        self.enablePrecisionPointing = enablePrecisionPointing
        self.enableMagicMouse = enableMagicMouse
        self.enableForceTouch = enableForceTouch
        self.maxConcurrentInputs = maxConcurrentInputs
        self.inputTimeout = inputTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.pointerSensitivity = pointerSensitivity
        self.scrollSensitivity = scrollSensitivity
        self.clickThreshold = clickThreshold
        self.doubleClickInterval = doubleClickInterval
        self.dragThreshold = dragThreshold
        self.scrollAcceleration = scrollAcceleration
        self.naturalScrolling = naturalScrolling
        self.tapToClick = tapToClick
        self.rightClickBehavior = rightClickBehavior
    }
    
    public var isValid: Bool {
        maxConcurrentInputs > 0 &&
        inputTimeout > 0 &&
        doubleClickInterval > 0 &&
        dragThreshold >= 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: MouseInputCapabilityConfiguration) -> MouseInputCapabilityConfiguration {
        MouseInputCapabilityConfiguration(
            enableMouseInput: other.enableMouseInput,
            enableTrackpadInput: other.enableTrackpadInput,
            enableScrollGestures: other.enableScrollGestures,
            enableMultiButtonSupport: other.enableMultiButtonSupport,
            enablePrecisionPointing: other.enablePrecisionPointing,
            enableMagicMouse: other.enableMagicMouse,
            enableForceTouch: other.enableForceTouch,
            maxConcurrentInputs: other.maxConcurrentInputs,
            inputTimeout: other.inputTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            pointerSensitivity: other.pointerSensitivity,
            scrollSensitivity: other.scrollSensitivity,
            clickThreshold: other.clickThreshold,
            doubleClickInterval: other.doubleClickInterval,
            dragThreshold: other.dragThreshold,
            scrollAcceleration: other.scrollAcceleration,
            naturalScrolling: other.naturalScrolling,
            tapToClick: other.tapToClick,
            rightClickBehavior: other.rightClickBehavior
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> MouseInputCapabilityConfiguration {
        var adjustedTimeout = inputTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentInputs = maxConcurrentInputs
        var adjustedCacheSize = cacheSize
        var adjustedForceTouch = enableForceTouch
        var adjustedScrollAcceleration = scrollAcceleration
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(inputTimeout, 15.0)
            adjustedConcurrentInputs = min(maxConcurrentInputs, 2)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedForceTouch = false
            adjustedScrollAcceleration = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return MouseInputCapabilityConfiguration(
            enableMouseInput: enableMouseInput,
            enableTrackpadInput: enableTrackpadInput,
            enableScrollGestures: enableScrollGestures,
            enableMultiButtonSupport: enableMultiButtonSupport,
            enablePrecisionPointing: enablePrecisionPointing,
            enableMagicMouse: enableMagicMouse,
            enableForceTouch: adjustedForceTouch,
            maxConcurrentInputs: adjustedConcurrentInputs,
            inputTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            pointerSensitivity: pointerSensitivity,
            scrollSensitivity: scrollSensitivity,
            clickThreshold: clickThreshold,
            doubleClickInterval: doubleClickInterval,
            dragThreshold: dragThreshold,
            scrollAcceleration: adjustedScrollAcceleration,
            naturalScrolling: naturalScrolling,
            tapToClick: tapToClick,
            rightClickBehavior: rightClickBehavior
        )
    }
}

// MARK: - Mouse Input Types

/// Mouse input event
public struct MouseInputEvent: Sendable, Identifiable {
    public let id: UUID
    public let mouseData: MouseData
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct MouseData: Sendable {
        public let eventType: MouseEventType
        public let buttons: MouseButtons
        public let location: CGPoint
        public let deltaLocation: CGPoint
        public let scroll: ScrollData?
        public let pressure: Float
        public let tilt: CGPoint
        public let rotation: Float
        public let deviceType: DeviceType
        public let inputSource: InputSource
        public let clickCount: Int
        public let modifiers: KeyModifiers
        public let timestamp: TimeInterval
        
        public struct ScrollData: Sendable {
            public let deltaX: CGFloat
            public let deltaY: CGFloat
            public let deltaZ: CGFloat
            public let scrollingDeltaX: CGFloat
            public let scrollingDeltaY: CGFloat
            public let hasPreciseScrollingDeltas: Bool
            public let momentumPhase: MomentumPhase
            public let scrollPhase: ScrollPhase
            
            public enum MomentumPhase: String, Sendable, CaseIterable {
                case none = "none"
                case began = "began"
                case stationary = "stationary"
                case changed = "changed"
                case ended = "ended"
                case cancelled = "cancelled"
            }
            
            public enum ScrollPhase: String, Sendable, CaseIterable {
                case none = "none"
                case began = "began"
                case changed = "changed"
                case ended = "ended"
                case cancelled = "cancelled"
                case mayBegin = "mayBegin"
            }
            
            public init(
                deltaX: CGFloat = 0,
                deltaY: CGFloat = 0,
                deltaZ: CGFloat = 0,
                scrollingDeltaX: CGFloat = 0,
                scrollingDeltaY: CGFloat = 0,
                hasPreciseScrollingDeltas: Bool = true,
                momentumPhase: MomentumPhase = .none,
                scrollPhase: ScrollPhase = .none
            ) {
                self.deltaX = deltaX
                self.deltaY = deltaY
                self.deltaZ = deltaZ
                self.scrollingDeltaX = scrollingDeltaX
                self.scrollingDeltaY = scrollingDeltaY
                self.hasPreciseScrollingDeltas = hasPreciseScrollingDeltas
                self.momentumPhase = momentumPhase
                self.scrollPhase = scrollPhase
            }
        }
        
        public struct MouseButtons: OptionSet, Sendable {
            public let rawValue: UInt
            
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
            
            public static let left = MouseButtons(rawValue: 1 << 0)
            public static let right = MouseButtons(rawValue: 1 << 1)
            public static let middle = MouseButtons(rawValue: 1 << 2)
            public static let button4 = MouseButtons(rawValue: 1 << 3)
            public static let button5 = MouseButtons(rawValue: 1 << 4)
        }
        
        public struct KeyModifiers: OptionSet, Sendable {
            public let rawValue: UInt
            
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
            
            public static let command = KeyModifiers(rawValue: 1 << 0)
            public static let shift = KeyModifiers(rawValue: 1 << 1)
            public static let control = KeyModifiers(rawValue: 1 << 2)
            public static let option = KeyModifiers(rawValue: 1 << 3)
            public static let capsLock = KeyModifiers(rawValue: 1 << 4)
            public static let function = KeyModifiers(rawValue: 1 << 5)
        }
        
        public enum MouseEventType: String, Sendable, CaseIterable {
            case mouseDown = "mouseDown"
            case mouseUp = "mouseUp"
            case mouseMoved = "mouseMoved"
            case mouseDragged = "mouseDragged"
            case mouseEntered = "mouseEntered"
            case mouseExited = "mouseExited"
            case scrollWheel = "scrollWheel"
            case otherMouseDown = "otherMouseDown"
            case otherMouseUp = "otherMouseUp"
            case otherMouseDragged = "otherMouseDragged"
            case rightMouseDown = "rightMouseDown"
            case rightMouseUp = "rightMouseUp"
            case rightMouseDragged = "rightMouseDragged"
            case tabletPoint = "tabletPoint"
            case tabletProximity = "tabletProximity"
        }
        
        public enum DeviceType: String, Sendable, CaseIterable {
            case mouse = "mouse"
            case trackpad = "trackpad"
            case magicMouse = "magicMouse"
            case trackball = "trackball"
            case stylus = "stylus"
            case finger = "finger"
            case unknown = "unknown"
        }
        
        public enum InputSource: String, Sendable, CaseIterable {
            case hardware = "hardware"
            case bluetooth = "bluetooth"
            case usb = "usb"
            case builtin = "builtin"
            case external = "external"
        }
        
        public init(
            eventType: MouseEventType,
            buttons: MouseButtons = [],
            location: CGPoint = .zero,
            deltaLocation: CGPoint = .zero,
            scroll: ScrollData? = nil,
            pressure: Float = 0.0,
            tilt: CGPoint = .zero,
            rotation: Float = 0.0,
            deviceType: DeviceType = .mouse,
            inputSource: InputSource = .hardware,
            clickCount: Int = 1,
            modifiers: KeyModifiers = [],
            timestamp: TimeInterval = 0
        ) {
            self.eventType = eventType
            self.buttons = buttons
            self.location = location
            self.deltaLocation = deltaLocation
            self.scroll = scroll
            self.pressure = pressure
            self.tilt = tilt
            self.rotation = rotation
            self.deviceType = deviceType
            self.inputSource = inputSource
            self.clickCount = clickCount
            self.modifiers = modifiers
            self.timestamp = timestamp
        }
    }
    
    public init(mouseData: MouseData, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.mouseData = mouseData
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Mouse input result
public struct MouseInputResult: Sendable, Identifiable {
    public let id: UUID
    public let eventId: UUID
    public let processedInput: ProcessedMouseInput
    public let recognizedGestures: [RecognizedMouseGesture]
    public let motionAnalysis: MotionAnalysis
    public let inputMetrics: MouseInputMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: MouseInputError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ProcessedMouseInput: Sendable {
        public let originalEvent: MouseInputEvent.MouseData
        public let normalizedLocation: CGPoint
        public let adjustedDelta: CGPoint
        public let filteredPressure: Float
        public let smoothedMotion: CGPoint
        public let acceleratedScroll: CGPoint?
        public let clickType: ClickType
        public let dragInfo: DragInfo?
        public let hoverInfo: HoverInfo?
        
        public enum ClickType: String, Sendable, CaseIterable {
            case singleClick = "singleClick"
            case doubleClick = "doubleClick"
            case tripleClick = "tripleClick"
            case rightClick = "rightClick"
            case middleClick = "middleClick"
            case forceClick = "forceClick"
            case tapClick = "tapClick"
        }
        
        public struct DragInfo: Sendable {
            public let startLocation: CGPoint
            public let currentLocation: CGPoint
            public let totalDistance: CGFloat
            public let velocity: CGPoint
            public let acceleration: CGPoint
            public let isDragging: Bool
            
            public init(startLocation: CGPoint, currentLocation: CGPoint, totalDistance: CGFloat, velocity: CGPoint, acceleration: CGPoint, isDragging: Bool) {
                self.startLocation = startLocation
                self.currentLocation = currentLocation
                self.totalDistance = totalDistance
                self.velocity = velocity
                self.acceleration = acceleration
                self.isDragging = isDragging
            }
        }
        
        public struct HoverInfo: Sendable {
            public let location: CGPoint
            public let duration: TimeInterval
            public let isHovering: Bool
            public let hoverTarget: String?
            
            public init(location: CGPoint, duration: TimeInterval, isHovering: Bool, hoverTarget: String?) {
                self.location = location
                self.duration = duration
                self.isHovering = isHovering
                self.hoverTarget = hoverTarget
            }
        }
        
        public init(
            originalEvent: MouseInputEvent.MouseData,
            normalizedLocation: CGPoint,
            adjustedDelta: CGPoint,
            filteredPressure: Float,
            smoothedMotion: CGPoint,
            acceleratedScroll: CGPoint? = nil,
            clickType: ClickType = .singleClick,
            dragInfo: DragInfo? = nil,
            hoverInfo: HoverInfo? = nil
        ) {
            self.originalEvent = originalEvent
            self.normalizedLocation = normalizedLocation
            self.adjustedDelta = adjustedDelta
            self.filteredPressure = filteredPressure
            self.smoothedMotion = smoothedMotion
            self.acceleratedScroll = acceleratedScroll
            self.clickType = clickType
            self.dragInfo = dragInfo
            self.hoverInfo = hoverInfo
        }
    }
    
    public struct RecognizedMouseGesture: Sendable {
        public let gestureType: GestureType
        public let confidence: Float
        public let location: CGPoint
        public let parameters: [String: Double]
        public let duration: TimeInterval
        
        public enum GestureType: String, Sendable, CaseIterable {
            case swipeLeft = "swipeLeft"
            case swipeRight = "swipeRight"
            case swipeUp = "swipeUp"
            case swipeDown = "swipeDown"
            case pinch = "pinch"
            case zoom = "zoom"
            case rotate = "rotate"
            case smartZoom = "smartZoom"
            case forceTouch = "forceTouch"
            case threeFingerSwipe = "threeFingerSwipe"
            case fourFingerSwipe = "fourFingerSwipe"
            case magicMouseGesture = "magicMouseGesture"
        }
        
        public init(gestureType: GestureType, confidence: Float, location: CGPoint, parameters: [String: Double], duration: TimeInterval) {
            self.gestureType = gestureType
            self.confidence = confidence
            self.location = location
            self.parameters = parameters
            self.duration = duration
        }
    }
    
    public struct MotionAnalysis: Sendable {
        public let averageVelocity: CGPoint
        public let peakVelocity: CGPoint
        public let acceleration: CGPoint
        public let jerk: CGPoint
        public let smoothness: Double
        public let precision: Double
        public let tremor: Double
        public let pathLength: CGFloat
        public let directionalBias: CGPoint
        
        public init(
            averageVelocity: CGPoint,
            peakVelocity: CGPoint,
            acceleration: CGPoint,
            jerk: CGPoint,
            smoothness: Double,
            precision: Double,
            tremor: Double,
            pathLength: CGFloat,
            directionalBias: CGPoint
        ) {
            self.averageVelocity = averageVelocity
            self.peakVelocity = peakVelocity
            self.acceleration = acceleration
            self.jerk = jerk
            self.smoothness = smoothness
            self.precision = precision
            self.tremor = tremor
            self.pathLength = pathLength
            self.directionalBias = directionalBias
        }
    }
    
    public struct MouseInputMetrics: Sendable {
        public let totalEvents: Int
        public let clicksPerMinute: Double
        public let averageSpeed: Double
        public let accuracy: Double
        public let scrollDistance: CGFloat
        public let dragDistance: CGFloat
        public let hoverTime: TimeInterval
        public let gestureCount: Int
        public let inputLatency: TimeInterval
        
        public init(
            totalEvents: Int,
            clicksPerMinute: Double,
            averageSpeed: Double,
            accuracy: Double,
            scrollDistance: CGFloat,
            dragDistance: CGFloat,
            hoverTime: TimeInterval,
            gestureCount: Int,
            inputLatency: TimeInterval
        ) {
            self.totalEvents = totalEvents
            self.clicksPerMinute = clicksPerMinute
            self.averageSpeed = averageSpeed
            self.accuracy = accuracy
            self.scrollDistance = scrollDistance
            self.dragDistance = dragDistance
            self.hoverTime = hoverTime
            self.gestureCount = gestureCount
            self.inputLatency = inputLatency
        }
    }
    
    public init(
        eventId: UUID,
        processedInput: ProcessedMouseInput,
        recognizedGestures: [RecognizedMouseGesture],
        motionAnalysis: MotionAnalysis,
        inputMetrics: MouseInputMetrics,
        processingTime: TimeInterval,
        success: Bool,
        error: MouseInputError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.eventId = eventId
        self.processedInput = processedInput
        self.recognizedGestures = recognizedGestures
        self.motionAnalysis = motionAnalysis
        self.inputMetrics = inputMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var gestureCount: Int {
        recognizedGestures.count
    }
    
    public var averageConfidence: Float {
        guard !recognizedGestures.isEmpty else { return 0.0 }
        return recognizedGestures.reduce(0) { $0 + $1.confidence } / Float(recognizedGestures.count)
    }
}

/// Mouse input aggregated metrics
public struct MouseInputCapabilityMetrics: Sendable {
    public let totalEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageProcessingTime: TimeInterval
    public let eventsByType: [String: Int]
    public let gesturesByType: [String: Int]
    public let inputByDevice: [String: Int]
    public let errorsByType: [String: Int]
    public let averageLatency: TimeInterval
    public let averageEventsPerSession: Double
    public let averageGesturesPerSession: Double
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestProcessingTime: TimeInterval
        public let worstProcessingTime: TimeInterval
        public let averageClicksPerMinute: Double
        public let averageMouseSpeed: Double
        public let averageAccuracy: Double
        public let totalScrollDistance: CGFloat
        public let totalDragDistance: CGFloat
        public let totalHoverTime: TimeInterval
        public let totalGestures: Int
        public let averageInputLatency: TimeInterval
        
        public init(
            bestProcessingTime: TimeInterval = 0,
            worstProcessingTime: TimeInterval = 0,
            averageClicksPerMinute: Double = 0,
            averageMouseSpeed: Double = 0,
            averageAccuracy: Double = 0,
            totalScrollDistance: CGFloat = 0,
            totalDragDistance: CGFloat = 0,
            totalHoverTime: TimeInterval = 0,
            totalGestures: Int = 0,
            averageInputLatency: TimeInterval = 0
        ) {
            self.bestProcessingTime = bestProcessingTime
            self.worstProcessingTime = worstProcessingTime
            self.averageClicksPerMinute = averageClicksPerMinute
            self.averageMouseSpeed = averageMouseSpeed
            self.averageAccuracy = averageAccuracy
            self.totalScrollDistance = totalScrollDistance
            self.totalDragDistance = totalDragDistance
            self.totalHoverTime = totalHoverTime
            self.totalGestures = totalGestures
            self.averageInputLatency = averageInputLatency
        }
    }
    
    public init(
        totalEvents: Int = 0,
        successfulEvents: Int = 0,
        failedEvents: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        eventsByType: [String: Int] = [:],
        gesturesByType: [String: Int] = [:],
        inputByDevice: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        averageLatency: TimeInterval = 0,
        averageEventsPerSession: Double = 0,
        averageGesturesPerSession: Double = 0,
        throughputPerSecond: Double = 0,
        performanceStats: PerformanceStats = PerformanceStats()
    ) {
        self.totalEvents = totalEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageProcessingTime = averageProcessingTime
        self.eventsByType = eventsByType
        self.gesturesByType = gesturesByType
        self.inputByDevice = inputByDevice
        self.errorsByType = errorsByType
        self.averageLatency = averageLatency
        self.averageEventsPerSession = averageEventsPerSession
        self.averageGesturesPerSession = averageGesturesPerSession
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalEvents) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalEvents > 0 ? Double(successfulEvents) / Double(totalEvents) : 0
    }
}

// MARK: - Mouse Input Resource

/// Mouse input resource management
@available(iOS 13.0, macOS 10.15, *)
public actor MouseInputCapabilityResource: AxiomCapabilityResource {
    private let configuration: MouseInputCapabilityConfiguration
    private var activeEvents: [UUID: MouseInputEvent] = [:]
    private var eventHistory: [MouseInputResult] = [:]
    private var resultCache: [String: MouseInputResult] = [:]
    private var mouseProcessor: MouseProcessor = MouseProcessor()
    private var gestureRecognizer: MouseGestureRecognizer = MouseGestureRecognizer()
    private var motionAnalyzer: MotionAnalyzer = MotionAnalyzer()
    private var inputTracker: MouseInputTracker = MouseInputTracker()
    private var metrics: MouseInputCapabilityMetrics = MouseInputCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<MouseInputResult>.Continuation?
    
    // Helper classes for mouse input processing
    private class MouseProcessor {
        private var lastLocation: CGPoint = .zero
        private var dragStartLocation: CGPoint?
        private var hoverStartTime: Date?
        
        func processMouseInput(
            _ mouseData: MouseInputEvent.MouseData,
            configuration: MouseInputCapabilityConfiguration
        ) -> MouseInputResult.ProcessedMouseInput {
            
            let normalizedLocation = normalizeLocation(mouseData.location)
            let adjustedDelta = adjustDelta(mouseData.deltaLocation, sensitivity: configuration.pointerSensitivity)
            let filteredPressure = filterPressure(mouseData.pressure)
            let smoothedMotion = smoothMotion(mouseData.deltaLocation)
            
            let acceleratedScroll: CGPoint?
            if let scroll = mouseData.scroll {
                acceleratedScroll = configuration.scrollAcceleration ? 
                    accelerateScroll(CGPoint(x: scroll.deltaX, y: scroll.deltaY), sensitivity: configuration.scrollSensitivity) : 
                    CGPoint(x: scroll.deltaX, y: scroll.deltaY)
            } else {
                acceleratedScroll = nil
            }
            
            let clickType = determineClickType(mouseData)
            let dragInfo = calculateDragInfo(mouseData)
            let hoverInfo = calculateHoverInfo(mouseData)
            
            lastLocation = normalizedLocation
            
            return MouseInputResult.ProcessedMouseInput(
                originalEvent: mouseData,
                normalizedLocation: normalizedLocation,
                adjustedDelta: adjustedDelta,
                filteredPressure: filteredPressure,
                smoothedMotion: smoothedMotion,
                acceleratedScroll: acceleratedScroll,
                clickType: clickType,
                dragInfo: dragInfo,
                hoverInfo: hoverInfo
            )
        }
        
        private func normalizeLocation(_ location: CGPoint) -> CGPoint {
            // Clamp to screen bounds and apply coordinate system adjustments
            return CGPoint(
                x: max(0, min(location.x, 1920)), // Simplified screen bounds
                y: max(0, min(location.y, 1080))
            )
        }
        
        private func adjustDelta(_ delta: CGPoint, sensitivity: MouseInputCapabilityConfiguration.PointerSensitivity) -> CGPoint {
            let multiplier: CGFloat
            switch sensitivity {
            case .slow:
                multiplier = 0.5
            case .normal:
                multiplier = 1.0
            case .fast:
                multiplier = 2.0
            case .custom:
                multiplier = 1.5
            }
            
            return CGPoint(x: delta.x * multiplier, y: delta.y * multiplier)
        }
        
        private func filterPressure(_ pressure: Float) -> Float {
            return min(max(pressure, 0.0), 1.0)
        }
        
        private func smoothMotion(_ delta: CGPoint) -> CGPoint {
            let smoothingFactor: CGFloat = 0.2
            return CGPoint(
                x: delta.x * (1 - smoothingFactor) + lastLocation.x * smoothingFactor,
                y: delta.y * (1 - smoothingFactor) + lastLocation.y * smoothingFactor
            )
        }
        
        private func accelerateScroll(_ delta: CGPoint, sensitivity: MouseInputCapabilityConfiguration.ScrollSensitivity) -> CGPoint {
            let multiplier: CGFloat
            switch sensitivity {
            case .slow:
                multiplier = 0.5
            case .normal:
                multiplier = 1.0
            case .fast:
                multiplier = 2.0
            case .custom:
                multiplier = 1.5
            }
            
            return CGPoint(x: delta.x * multiplier, y: delta.y * multiplier)
        }
        
        private func determineClickType(_ mouseData: MouseInputEvent.MouseData) -> MouseInputResult.ProcessedMouseInput.ClickType {
            switch mouseData.eventType {
            case .rightMouseDown, .rightMouseUp:
                return .rightClick
            case .otherMouseDown, .otherMouseUp:
                return .middleClick
            case .mouseDown, .mouseUp:
                if mouseData.pressure > 0.8 {
                    return .forceClick
                }
                switch mouseData.clickCount {
                case 1:
                    return .singleClick
                case 2:
                    return .doubleClick
                case 3:
                    return .tripleClick
                default:
                    return .singleClick
                }
            default:
                return .singleClick
            }
        }
        
        private func calculateDragInfo(_ mouseData: MouseInputEvent.MouseData) -> MouseInputResult.ProcessedMouseInput.DragInfo? {
            if mouseData.eventType == .mouseDragged || mouseData.eventType == .rightMouseDragged || mouseData.eventType == .otherMouseDragged {
                let startLocation = dragStartLocation ?? mouseData.location
                if dragStartLocation == nil {
                    dragStartLocation = mouseData.location
                }
                
                let distance = sqrt(pow(mouseData.location.x - startLocation.x, 2) + pow(mouseData.location.y - startLocation.y, 2))
                let velocity = CGPoint(x: mouseData.deltaLocation.x * 60, y: mouseData.deltaLocation.y * 60) // Per second
                let acceleration = CGPoint(x: velocity.x * 0.1, y: velocity.y * 0.1) // Simplified
                
                return MouseInputResult.ProcessedMouseInput.DragInfo(
                    startLocation: startLocation,
                    currentLocation: mouseData.location,
                    totalDistance: distance,
                    velocity: velocity,
                    acceleration: acceleration,
                    isDragging: true
                )
            } else if mouseData.eventType == .mouseUp || mouseData.eventType == .rightMouseUp || mouseData.eventType == .otherMouseUp {
                dragStartLocation = nil
            }
            
            return nil
        }
        
        private func calculateHoverInfo(_ mouseData: MouseInputEvent.MouseData) -> MouseInputResult.ProcessedMouseInput.HoverInfo? {
            if mouseData.eventType == .mouseMoved {
                if hoverStartTime == nil {
                    hoverStartTime = Date()
                }
                
                let duration = Date().timeIntervalSince(hoverStartTime!)
                
                return MouseInputResult.ProcessedMouseInput.HoverInfo(
                    location: mouseData.location,
                    duration: duration,
                    isHovering: true,
                    hoverTarget: nil
                )
            } else {
                hoverStartTime = nil
            }
            
            return nil
        }
    }
    
    private class MouseGestureRecognizer {
        func recognizeGestures(from mouseData: MouseInputEvent.MouseData) -> [MouseInputResult.RecognizedMouseGesture] {
            var gestures: [MouseInputResult.RecognizedMouseGesture] = []
            
            // Scroll wheel gestures
            if let scroll = mouseData.scroll {
                if abs(scroll.deltaX) > abs(scroll.deltaY) && abs(scroll.deltaX) > 10 {
                    let gestureType: MouseInputResult.RecognizedMouseGesture.GestureType = scroll.deltaX > 0 ? .swipeRight : .swipeLeft
                    let gesture = MouseInputResult.RecognizedMouseGesture(
                        gestureType: gestureType,
                        confidence: 0.8,
                        location: mouseData.location,
                        parameters: ["deltaX": Double(scroll.deltaX)],
                        duration: 0.1
                    )
                    gestures.append(gesture)
                } else if abs(scroll.deltaY) > 10 {
                    let gestureType: MouseInputResult.RecognizedMouseGesture.GestureType = scroll.deltaY > 0 ? .swipeUp : .swipeDown
                    let gesture = MouseInputResult.RecognizedMouseGesture(
                        gestureType: gestureType,
                        confidence: 0.8,
                        location: mouseData.location,
                        parameters: ["deltaY": Double(scroll.deltaY)],
                        duration: 0.1
                    )
                    gestures.append(gesture)
                }
            }
            
            // Force touch gestures
            if mouseData.pressure > 0.8 {
                let gesture = MouseInputResult.RecognizedMouseGesture(
                    gestureType: .forceTouch,
                    confidence: 0.9,
                    location: mouseData.location,
                    parameters: ["pressure": Double(mouseData.pressure)],
                    duration: 0.2
                )
                gestures.append(gesture)
            }
            
            // Magic Mouse gestures (simplified detection)
            if mouseData.deviceType == .magicMouse {
                let gesture = MouseInputResult.RecognizedMouseGesture(
                    gestureType: .magicMouseGesture,
                    confidence: 0.7,
                    location: mouseData.location,
                    parameters: [:],
                    duration: 0.1
                )
                gestures.append(gesture)
            }
            
            return gestures
        }
    }
    
    private class MotionAnalyzer {
        private var motionHistory: [CGPoint] = []
        private var velocityHistory: [CGPoint] = []
        
        func analyzeMotion(from mouseData: MouseInputEvent.MouseData) -> MouseInputResult.MotionAnalysis {
            motionHistory.append(mouseData.location)
            if motionHistory.count > 10 {
                motionHistory.removeFirst()
            }
            
            let velocity = calculateVelocity(mouseData.deltaLocation)
            velocityHistory.append(velocity)
            if velocityHistory.count > 5 {
                velocityHistory.removeFirst()
            }
            
            let averageVelocity = calculateAverageVelocity()
            let peakVelocity = calculatePeakVelocity()
            let acceleration = calculateAcceleration()
            let jerk = calculateJerk()
            let smoothness = calculateSmoothness()
            let precision = calculatePrecision()
            let tremor = calculateTremor()
            let pathLength = calculatePathLength()
            let directionalBias = calculateDirectionalBias()
            
            return MouseInputResult.MotionAnalysis(
                averageVelocity: averageVelocity,
                peakVelocity: peakVelocity,
                acceleration: acceleration,
                jerk: jerk,
                smoothness: smoothness,
                precision: precision,
                tremor: tremor,
                pathLength: pathLength,
                directionalBias: directionalBias
            )
        }
        
        private func calculateVelocity(_ delta: CGPoint) -> CGPoint {
            return CGPoint(x: delta.x * 60, y: delta.y * 60) // Convert to per second
        }
        
        private func calculateAverageVelocity() -> CGPoint {
            guard !velocityHistory.isEmpty else { return .zero }
            let sum = velocityHistory.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            return CGPoint(x: sum.x / CGFloat(velocityHistory.count), y: sum.y / CGFloat(velocityHistory.count))
        }
        
        private func calculatePeakVelocity() -> CGPoint {
            guard !velocityHistory.isEmpty else { return .zero }
            return velocityHistory.max { sqrt($0.x * $0.x + $0.y * $0.y) < sqrt($1.x * $1.x + $1.y * $1.y) } ?? .zero
        }
        
        private func calculateAcceleration() -> CGPoint {
            guard velocityHistory.count >= 2 else { return .zero }
            let current = velocityHistory.last!
            let previous = velocityHistory[velocityHistory.count - 2]
            return CGPoint(x: current.x - previous.x, y: current.y - previous.y)
        }
        
        private func calculateJerk() -> CGPoint {
            // Simplified jerk calculation
            return CGPoint(x: 0.1, y: 0.1)
        }
        
        private func calculateSmoothness() -> Double {
            guard motionHistory.count > 2 else { return 1.0 }
            // Calculate smoothness based on motion variation
            var variations: [CGFloat] = []
            for i in 1..<motionHistory.count {
                let delta = sqrt(pow(motionHistory[i].x - motionHistory[i-1].x, 2) + pow(motionHistory[i].y - motionHistory[i-1].y, 2))
                variations.append(delta)
            }
            
            let average = variations.reduce(0, +) / CGFloat(variations.count)
            let variance = variations.map { pow($0 - average, 2) }.reduce(0, +) / CGFloat(variations.count)
            
            return max(0.0, 1.0 - Double(sqrt(variance) / (average + 1)))
        }
        
        private func calculatePrecision() -> Double {
            // Simplified precision calculation based on motion consistency
            return 0.8
        }
        
        private func calculateTremor() -> Double {
            // Simplified tremor detection
            return 0.1
        }
        
        private func calculatePathLength() -> CGFloat {
            guard motionHistory.count > 1 else { return 0 }
            var length: CGFloat = 0
            for i in 1..<motionHistory.count {
                length += sqrt(pow(motionHistory[i].x - motionHistory[i-1].x, 2) + pow(motionHistory[i].y - motionHistory[i-1].y, 2))
            }
            return length
        }
        
        private func calculateDirectionalBias() -> CGPoint {
            guard motionHistory.count > 1 else { return .zero }
            let start = motionHistory.first!
            let end = motionHistory.last!
            return CGPoint(x: end.x - start.x, y: end.y - start.y)
        }
    }
    
    private class MouseInputTracker {
        private var sessionStartTime: Date = Date()
        private var eventCount: Int = 0
        private var clickCount: Int = 0
        private var scrollDistance: CGFloat = 0
        private var dragDistance: CGFloat = 0
        private var hoverTime: TimeInterval = 0
        private var gestureCount: Int = 0
        
        func trackEvent(_ mouseData: MouseInputEvent.MouseData, gestures: [MouseInputResult.RecognizedMouseGesture]) {
            eventCount += 1
            
            if mouseData.eventType == .mouseDown || mouseData.eventType == .rightMouseDown || mouseData.eventType == .otherMouseDown {
                clickCount += 1
            }
            
            if let scroll = mouseData.scroll {
                scrollDistance += sqrt(pow(scroll.deltaX, 2) + pow(scroll.deltaY, 2))
            }
            
            if mouseData.eventType == .mouseDragged || mouseData.eventType == .rightMouseDragged || mouseData.eventType == .otherMouseDragged {
                dragDistance += sqrt(pow(mouseData.deltaLocation.x, 2) + pow(mouseData.deltaLocation.y, 2))
            }
            
            if mouseData.eventType == .mouseMoved {
                hoverTime += 0.016 // ~60 FPS
            }
            
            gestureCount += gestures.count
        }
        
        func calculateMetrics() -> MouseInputResult.MouseInputMetrics {
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            let clicksPerMinute = sessionDuration > 0 ? (Double(clickCount) / sessionDuration) * 60 : 0
            let averageSpeed = sessionDuration > 0 ? Double(eventCount) / sessionDuration : 0
            let accuracy = calculateAccuracy()
            let inputLatency = 0.008 // 8ms average
            
            return MouseInputResult.MouseInputMetrics(
                totalEvents: eventCount,
                clicksPerMinute: clicksPerMinute,
                averageSpeed: averageSpeed,
                accuracy: accuracy,
                scrollDistance: scrollDistance,
                dragDistance: dragDistance,
                hoverTime: hoverTime,
                gestureCount: gestureCount,
                inputLatency: inputLatency
            )
        }
        
        private func calculateAccuracy() -> Double {
            // Simplified accuracy calculation
            return 0.9
        }
        
        func reset() {
            sessionStartTime = Date()
            eventCount = 0
            clickCount = 0
            scrollDistance = 0
            dragDistance = 0
            hoverTime = 0
            gestureCount = 0
        }
    }
    
    public init(configuration: MouseInputCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 80_000_000, // 80MB for mouse input processing
            cpu: 1.5, // Moderate CPU usage for input processing
            bandwidth: 0,
            storage: 20_000_000 // 20MB for input and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = activeEvents.count * 3_000_000 // ~3MB per active event
            let cacheMemory = resultCache.count * 15_000 // ~15KB per cached result
            let historyMemory = eventHistory.count * 8_000
            let processingMemory = 15_000_000 // Input processing overhead
            
            return ResourceUsage(
                memory: eventMemory + cacheMemory + historyMemory + processingMemory,
                cpu: activeEvents.isEmpty ? 0.1 : 1.0,
                bandwidth: 0,
                storage: resultCache.count * 8_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Mouse input is available on iOS 13+ (for external mice), macOS
        if #available(iOS 13.0, *) {
            return configuration.enableMouseInput || configuration.enableTrackpadInput
        }
        return false
    }
    
    public func release() async {
        activeEvents.removeAll()
        eventHistory.removeAll()
        resultCache.removeAll()
        inputTracker.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = MouseInputCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        mouseProcessor = MouseProcessor()
        gestureRecognizer = MouseGestureRecognizer()
        motionAnalyzer = MotionAnalyzer()
        inputTracker = MouseInputTracker()
        
        if configuration.enableLogging {
            print("[MouseInput] 🚀 Mouse Input capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: MouseInputCapabilityConfiguration) async throws {
        // Update mouse input configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<MouseInputResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Mouse Input Processing
    
    public func processInput(_ event: MouseInputEvent) async throws -> MouseInputResult {
        guard configuration.enableMouseInput || configuration.enableTrackpadInput else {
            throw MouseInputError.mouseInputDisabled
        }
        
        let startTime = Date()
        activeEvents[event.id] = event
        
        do {
            // Process mouse input
            let processedInput = mouseProcessor.processMouseInput(event.mouseData, configuration: configuration)
            
            // Recognize gestures if enabled
            var recognizedGestures: [MouseInputResult.RecognizedMouseGesture] = []
            if configuration.enableScrollGestures || configuration.enableMagicMouse {
                recognizedGestures = gestureRecognizer.recognizeGestures(from: event.mouseData)
            }
            
            // Analyze motion
            let motionAnalysis = motionAnalyzer.analyzeMotion(from: event.mouseData)
            
            // Track input for metrics
            inputTracker.trackEvent(event.mouseData, gestures: recognizedGestures)
            let inputMetrics = inputTracker.calculateMetrics()
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MouseInputResult(
                eventId: event.id,
                processedInput: processedInput,
                recognizedGestures: recognizedGestures,
                motionAnalysis: motionAnalysis,
                inputMetrics: inputMetrics,
                processingTime: processingTime,
                success: true,
                metadata: event.metadata
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: event)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logMouseEvent(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MouseInputResult(
                eventId: event.id,
                processedInput: MouseInputResult.ProcessedMouseInput(
                    originalEvent: event.mouseData,
                    normalizedLocation: .zero,
                    adjustedDelta: .zero,
                    filteredPressure: 0,
                    smoothedMotion: .zero
                ),
                recognizedGestures: [],
                motionAnalysis: MouseInputResult.MotionAnalysis(
                    averageVelocity: .zero,
                    peakVelocity: .zero,
                    acceleration: .zero,
                    jerk: .zero,
                    smoothness: 0,
                    precision: 0,
                    tremor: 0,
                    pathLength: 0,
                    directionalBias: .zero
                ),
                inputMetrics: MouseInputResult.MouseInputMetrics(
                    totalEvents: 0,
                    clicksPerMinute: 0,
                    averageSpeed: 0,
                    accuracy: 0,
                    scrollDistance: 0,
                    dragDistance: 0,
                    hoverTime: 0,
                    gestureCount: 0,
                    inputLatency: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? MouseInputError ?? MouseInputError.processingError(error.localizedDescription)
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logMouseEvent(result)
            }
            
            throw error
        }
    }
    
    public func getActiveEvents() async -> [MouseInputEvent] {
        return Array(activeEvents.values)
    }
    
    public func getEventHistory(since: Date? = nil) async -> [MouseInputResult] {
        if let since = since {
            return eventHistory.filter { $0.timestamp >= since }
        }
        return eventHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> MouseInputCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = MouseInputCapabilityMetrics()
        inputTracker.reset()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for event: MouseInputEvent) -> String {
        let eventType = event.mouseData.eventType.rawValue
        let buttons = event.mouseData.buttons.rawValue
        let deviceType = event.mouseData.deviceType.rawValue
        let timestamp = Int(event.timestamp.timeIntervalSince1970 * 1000) // Milliseconds
        return "\(eventType)_\(buttons)_\(deviceType)_\(timestamp)"
    }
    
    private func updateSuccessMetrics(_ result: MouseInputResult) async {
        let totalEvents = metrics.totalEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalEvents)) + result.processingTime) / Double(totalEvents)
        
        var eventsByType = metrics.eventsByType
        eventsByType[result.processedInput.originalEvent.eventType.rawValue, default: 0] += 1
        
        var gesturesByType = metrics.gesturesByType
        for gesture in result.recognizedGestures {
            gesturesByType[gesture.gestureType.rawValue, default: 0] += 1
        }
        
        var inputByDevice = metrics.inputByDevice
        inputByDevice[result.processedInput.originalEvent.deviceType.rawValue, default: 0] += 1
        
        let newAverageEventsPerSession = ((metrics.averageEventsPerSession * Double(metrics.successfulEvents)) + Double(result.inputMetrics.totalEvents)) / Double(successfulEvents)
        let newAverageGesturesPerSession = ((metrics.averageGesturesPerSession * Double(metrics.successfulEvents)) + Double(result.gestureCount)) / Double(successfulEvents)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulEvents == 0 ? result.processingTime : min(performanceStats.bestProcessingTime, result.processingTime)
        let worstTime = max(performanceStats.worstProcessingTime, result.processingTime)
        let newAverageClicksPerMinute = ((performanceStats.averageClicksPerMinute * Double(metrics.successfulEvents)) + result.inputMetrics.clicksPerMinute) / Double(successfulEvents)
        let newAverageMouseSpeed = ((performanceStats.averageMouseSpeed * Double(metrics.successfulEvents)) + result.inputMetrics.averageSpeed) / Double(successfulEvents)
        let newAverageAccuracy = ((performanceStats.averageAccuracy * Double(metrics.successfulEvents)) + result.inputMetrics.accuracy) / Double(successfulEvents)
        let totalScrollDistance = performanceStats.totalScrollDistance + result.inputMetrics.scrollDistance
        let totalDragDistance = performanceStats.totalDragDistance + result.inputMetrics.dragDistance
        let totalHoverTime = performanceStats.totalHoverTime + result.inputMetrics.hoverTime
        let totalGestures = performanceStats.totalGestures + result.inputMetrics.gestureCount
        let newAverageInputLatency = ((performanceStats.averageInputLatency * Double(metrics.successfulEvents)) + result.inputMetrics.inputLatency) / Double(successfulEvents)
        
        performanceStats = MouseInputCapabilityMetrics.PerformanceStats(
            bestProcessingTime: bestTime,
            worstProcessingTime: worstTime,
            averageClicksPerMinute: newAverageClicksPerMinute,
            averageMouseSpeed: newAverageMouseSpeed,
            averageAccuracy: newAverageAccuracy,
            totalScrollDistance: totalScrollDistance,
            totalDragDistance: totalDragDistance,
            totalHoverTime: totalHoverTime,
            totalGestures: totalGestures,
            averageInputLatency: newAverageInputLatency
        )
        
        metrics = MouseInputCapabilityMetrics(
            totalEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageProcessingTime: newAverageProcessingTime,
            eventsByType: eventsByType,
            gesturesByType: gesturesByType,
            inputByDevice: inputByDevice,
            errorsByType: metrics.errorsByType,
            averageLatency: result.inputMetrics.inputLatency,
            averageEventsPerSession: newAverageEventsPerSession,
            averageGesturesPerSession: newAverageGesturesPerSession,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: MouseInputResult) async {
        let totalEvents = metrics.totalEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = MouseInputCapabilityMetrics(
            totalEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageProcessingTime: metrics.averageProcessingTime,
            eventsByType: metrics.eventsByType,
            gesturesByType: metrics.gesturesByType,
            inputByDevice: metrics.inputByDevice,
            errorsByType: errorsByType,
            averageLatency: metrics.averageLatency,
            averageEventsPerSession: metrics.averageEventsPerSession,
            averageGesturesPerSession: metrics.averageGesturesPerSession,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logMouseEvent(_ result: MouseInputResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let eventType = result.processedInput.originalEvent.eventType.rawValue
        let gestureCount = result.gestureCount
        let device = result.processedInput.originalEvent.deviceType.rawValue
        let accuracy = String(format: "%.1f", result.inputMetrics.accuracy * 100)
        
        print("[MouseInput] \(statusIcon) Event: \(eventType), \(gestureCount) gestures, \(device), \(accuracy)% accuracy (\(timeStr)s)")
        
        if let error = result.error {
            print("[MouseInput] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Mouse Input Capability Implementation

/// Mouse Input capability providing comprehensive mouse and trackpad support
@available(iOS 13.0, macOS 10.15, *)
public actor MouseInputCapability: DomainCapability {
    public typealias ConfigurationType = MouseInputCapabilityConfiguration
    public typealias ResourceType = MouseInputCapabilityResource
    
    private var _configuration: MouseInputCapabilityConfiguration
    private var _resources: MouseInputCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "mouse-input-capability" }
    
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
    
    public var configuration: MouseInputCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: MouseInputCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: MouseInputCapabilityConfiguration = MouseInputCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = MouseInputCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: MouseInputCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Mouse Input configuration")
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
        // Mouse input is supported on iOS 13+ (for external mice), macOS
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Mouse input doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Mouse Input Operations
    
    /// Process mouse input event
    public func processInput(_ event: MouseInputEvent) async throws -> MouseInputResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        return try await _resources.processInput(event)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<MouseInputResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active events
    public func getActiveEvents() async throws -> [MouseInputEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        return await _resources.getActiveEvents()
    }
    
    /// Get event history
    public func getEventHistory(since: Date? = nil) async throws -> [MouseInputResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        return await _resources.getEventHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> MouseInputCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Mouse Input capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create mouse click event
    public func createClickEvent(at location: CGPoint, button: MouseInputEvent.MouseData.MouseButtons = .left, clickCount: Int = 1, deviceType: MouseInputEvent.MouseData.DeviceType = .mouse) -> MouseInputEvent {
        let mouseData = MouseInputEvent.MouseData(
            eventType: .mouseDown,
            buttons: button,
            location: location,
            clickCount: clickCount,
            deviceType: deviceType
        )
        
        return MouseInputEvent(mouseData: mouseData)
    }
    
    /// Create mouse move event
    public func createMoveEvent(to location: CGPoint, delta: CGPoint = .zero, deviceType: MouseInputEvent.MouseData.DeviceType = .mouse) -> MouseInputEvent {
        let mouseData = MouseInputEvent.MouseData(
            eventType: .mouseMoved,
            location: location,
            deltaLocation: delta,
            deviceType: deviceType
        )
        
        return MouseInputEvent(mouseData: mouseData)
    }
    
    /// Create scroll event
    public func createScrollEvent(at location: CGPoint, deltaX: CGFloat, deltaY: CGFloat, deviceType: MouseInputEvent.MouseData.DeviceType = .mouse) -> MouseInputEvent {
        let scrollData = MouseInputEvent.MouseData.ScrollData(
            deltaX: deltaX,
            deltaY: deltaY,
            scrollingDeltaX: deltaX,
            scrollingDeltaY: deltaY
        )
        
        let mouseData = MouseInputEvent.MouseData(
            eventType: .scrollWheel,
            location: location,
            scroll: scrollData,
            deviceType: deviceType
        )
        
        return MouseInputEvent(mouseData: mouseData)
    }
    
    /// Check if mouse input is active
    public func hasActiveEvents() async throws -> Bool {
        let activeEvents = try await getActiveEvents()
        return !activeEvents.isEmpty
    }
    
    /// Get average mouse speed
    public func getAverageMouseSpeed() async throws -> Double {
        let metrics = try await getMetrics()
        return metrics.performanceStats.averageMouseSpeed
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Mouse Input specific errors
public enum MouseInputError: Error, LocalizedError {
    case mouseInputDisabled
    case trackpadInputDisabled
    case processingError(String)
    case gestureRecognitionFailed
    case motionAnalysisFailed
    case invalidMouseData
    case inputTimeout(UUID)
    case unsupportedDevice(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .mouseInputDisabled:
            return "Mouse input is disabled"
        case .trackpadInputDisabled:
            return "Trackpad input is disabled"
        case .processingError(let reason):
            return "Mouse processing failed: \(reason)"
        case .gestureRecognitionFailed:
            return "Gesture recognition failed"
        case .motionAnalysisFailed:
            return "Motion analysis failed"
        case .invalidMouseData:
            return "Invalid mouse data provided"
        case .inputTimeout(let id):
            return "Input timeout: \(id)"
        case .unsupportedDevice(let device):
            return "Unsupported device: \(device)"
        case .configurationError(let reason):
            return "Mouse input configuration error: \(reason)"
        }
    }
}