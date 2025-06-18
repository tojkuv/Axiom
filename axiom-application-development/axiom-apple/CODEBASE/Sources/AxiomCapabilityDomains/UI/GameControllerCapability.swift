import Foundation
import GameController
import CoreHaptics
import AxiomCore
import AxiomCapabilities

// MARK: - Game Controller Capability Configuration

/// Configuration for Game Controller capability
public struct GameControllerCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableGameControllerSupport: Bool
    public let enableControllerDiscovery: Bool
    public let enableHapticFeedback: Bool
    public let enableMotionSensing: Bool
    public let enableBatteryMonitoring: Bool
    public let enableProfileManagement: Bool
    public let enableInputRecording: Bool
    public let enableRealTimeInput: Bool
    public let maxConcurrentControllers: Int
    public let inputTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let inputSensitivity: InputSensitivity
    public let deadZoneThreshold: Double
    public let hapticIntensity: Double
    public let inputPollingRate: InputPollingRate
    public let controllerPriority: ControllerPriority
    public let supportedControllers: [ControllerType]
    
    public enum InputSensitivity: String, Codable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case custom = "custom"
    }
    
    public enum InputPollingRate: String, Codable, CaseIterable {
        case standard = "standard"  // 60Hz
        case high = "high"         // 120Hz
        case ultra = "ultra"       // 240Hz
        case adaptive = "adaptive"
    }
    
    public enum ControllerPriority: String, Codable, CaseIterable {
        case firstConnected = "firstConnected"
        case lastConnected = "lastConnected"
        case mfiPreferred = "mfiPreferred"
        case consolePreferred = "consolePreferred"
        case userSelected = "userSelected"
    }
    
    public enum ControllerType: String, Codable, CaseIterable {
        case mfi = "mfi"
        case xbox = "xbox"
        case playstation = "playstation"
        case nintendoSwitch = "nintendoSwitch"
        case generic = "generic"
        case keyboard = "keyboard"
        case mouse = "mouse"
    }
    
    public init(
        enableGameControllerSupport: Bool = true,
        enableControllerDiscovery: Bool = true,
        enableHapticFeedback: Bool = true,
        enableMotionSensing: Bool = true,
        enableBatteryMonitoring: Bool = true,
        enableProfileManagement: Bool = true,
        enableInputRecording: Bool = false,
        enableRealTimeInput: Bool = true,
        maxConcurrentControllers: Int = 4,
        inputTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        inputSensitivity: InputSensitivity = .normal,
        deadZoneThreshold: Double = 0.15,
        hapticIntensity: Double = 1.0,
        inputPollingRate: InputPollingRate = .standard,
        controllerPriority: ControllerPriority = .firstConnected,
        supportedControllers: [ControllerType] = ControllerType.allCases
    ) {
        self.enableGameControllerSupport = enableGameControllerSupport
        self.enableControllerDiscovery = enableControllerDiscovery
        self.enableHapticFeedback = enableHapticFeedback
        self.enableMotionSensing = enableMotionSensing
        self.enableBatteryMonitoring = enableBatteryMonitoring
        self.enableProfileManagement = enableProfileManagement
        self.enableInputRecording = enableInputRecording
        self.enableRealTimeInput = enableRealTimeInput
        self.maxConcurrentControllers = maxConcurrentControllers
        self.inputTimeout = inputTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.inputSensitivity = inputSensitivity
        self.deadZoneThreshold = deadZoneThreshold
        self.hapticIntensity = hapticIntensity
        self.inputPollingRate = inputPollingRate
        self.controllerPriority = controllerPriority
        self.supportedControllers = supportedControllers
    }
    
    public var isValid: Bool {
        maxConcurrentControllers > 0 &&
        inputTimeout > 0 &&
        deadZoneThreshold >= 0 && deadZoneThreshold <= 1 &&
        hapticIntensity >= 0 && hapticIntensity <= 1 &&
        cacheSize >= 0 &&
        !supportedControllers.isEmpty
    }
    
    public func merged(with other: GameControllerCapabilityConfiguration) -> GameControllerCapabilityConfiguration {
        GameControllerCapabilityConfiguration(
            enableGameControllerSupport: other.enableGameControllerSupport,
            enableControllerDiscovery: other.enableControllerDiscovery,
            enableHapticFeedback: other.enableHapticFeedback,
            enableMotionSensing: other.enableMotionSensing,
            enableBatteryMonitoring: other.enableBatteryMonitoring,
            enableProfileManagement: other.enableProfileManagement,
            enableInputRecording: other.enableInputRecording,
            enableRealTimeInput: other.enableRealTimeInput,
            maxConcurrentControllers: other.maxConcurrentControllers,
            inputTimeout: other.inputTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            inputSensitivity: other.inputSensitivity,
            deadZoneThreshold: other.deadZoneThreshold,
            hapticIntensity: other.hapticIntensity,
            inputPollingRate: other.inputPollingRate,
            controllerPriority: other.controllerPriority,
            supportedControllers: other.supportedControllers
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> GameControllerCapabilityConfiguration {
        var adjustedTimeout = inputTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentControllers = maxConcurrentControllers
        var adjustedCacheSize = cacheSize
        var adjustedHapticFeedback = enableHapticFeedback
        var adjustedPollingRate = inputPollingRate
        var adjustedSensitivity = inputSensitivity
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(inputTimeout, 15.0)
            adjustedConcurrentControllers = min(maxConcurrentControllers, 2)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedHapticFeedback = false
            adjustedPollingRate = .standard
            adjustedSensitivity = .low
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return GameControllerCapabilityConfiguration(
            enableGameControllerSupport: enableGameControllerSupport,
            enableControllerDiscovery: enableControllerDiscovery,
            enableHapticFeedback: adjustedHapticFeedback,
            enableMotionSensing: enableMotionSensing,
            enableBatteryMonitoring: enableBatteryMonitoring,
            enableProfileManagement: enableProfileManagement,
            enableInputRecording: enableInputRecording,
            enableRealTimeInput: enableRealTimeInput,
            maxConcurrentControllers: adjustedConcurrentControllers,
            inputTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            inputSensitivity: adjustedSensitivity,
            deadZoneThreshold: deadZoneThreshold,
            hapticIntensity: hapticIntensity,
            inputPollingRate: adjustedPollingRate,
            controllerPriority: controllerPriority,
            supportedControllers: supportedControllers
        )
    }
}

// MARK: - Game Controller Types

/// Game controller input event
public struct GameControllerInputEvent: Sendable, Identifiable {
    public let id: UUID
    public let controllerId: String
    public let inputData: InputData
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct InputData: Sendable {
        public let eventType: InputEventType
        public let controllerInfo: ControllerInfo
        public let buttonStates: ButtonStates?
        public let analogStates: AnalogStates?
        public let motionData: MotionData?
        public let touchpadData: TouchpadData?
        public let batteryLevel: Float?
        public let isConnected: Bool
        
        public enum InputEventType: String, Sendable, CaseIterable {
            case buttonPressed = "buttonPressed"
            case buttonReleased = "buttonReleased"
            case analogChanged = "analogChanged"
            case motionUpdate = "motionUpdate"
            case touchpadChanged = "touchpadChanged"
            case connectionChanged = "connectionChanged"
            case batteryChanged = "batteryChanged"
            case profileChanged = "profileChanged"
        }
        
        public struct ControllerInfo: Sendable {
            public let controllerType: GameControllerCapabilityConfiguration.ControllerType
            public let vendorName: String?
            public let productCategory: String?
            public let deviceHash: String
            public let isWireless: Bool
            public let supportsHaptics: Bool
            public let supportsMotion: Bool
            public let playerIndex: Int?
            
            public init(controllerType: GameControllerCapabilityConfiguration.ControllerType, vendorName: String?, productCategory: String?, deviceHash: String, isWireless: Bool, supportsHaptics: Bool, supportsMotion: Bool, playerIndex: Int?) {
                self.controllerType = controllerType
                self.vendorName = vendorName
                self.productCategory = productCategory
                self.deviceHash = deviceHash
                self.isWireless = isWireless
                self.supportsHaptics = supportsHaptics
                self.supportsMotion = supportsMotion
                self.playerIndex = playerIndex
            }
        }
        
        public struct ButtonStates: Sendable {
            public let buttonA: Bool
            public let buttonB: Bool
            public let buttonX: Bool
            public let buttonY: Bool
            public let leftShoulder: Bool
            public let rightShoulder: Bool
            public let leftTrigger: Float
            public let rightTrigger: Float
            public let dpadUp: Bool
            public let dpadDown: Bool
            public let dpadLeft: Bool
            public let dpadRight: Bool
            public let leftThumbstick: Bool
            public let rightThumbstick: Bool
            public let menu: Bool
            public let options: Bool
            public let home: Bool
            public let share: Bool
            
            public init(buttonA: Bool = false, buttonB: Bool = false, buttonX: Bool = false, buttonY: Bool = false, leftShoulder: Bool = false, rightShoulder: Bool = false, leftTrigger: Float = 0.0, rightTrigger: Float = 0.0, dpadUp: Bool = false, dpadDown: Bool = false, dpadLeft: Bool = false, dpadRight: Bool = false, leftThumbstick: Bool = false, rightThumbstick: Bool = false, menu: Bool = false, options: Bool = false, home: Bool = false, share: Bool = false) {
                self.buttonA = buttonA
                self.buttonB = buttonB
                self.buttonX = buttonX
                self.buttonY = buttonY
                self.leftShoulder = leftShoulder
                self.rightShoulder = rightShoulder
                self.leftTrigger = leftTrigger
                self.rightTrigger = rightTrigger
                self.dpadUp = dpadUp
                self.dpadDown = dpadDown
                self.dpadLeft = dpadLeft
                self.dpadRight = dpadRight
                self.leftThumbstick = leftThumbstick
                self.rightThumbstick = rightThumbstick
                self.menu = menu
                self.options = options
                self.home = home
                self.share = share
            }
        }
        
        public struct AnalogStates: Sendable {
            public let leftThumbstick: ThumbstickData
            public let rightThumbstick: ThumbstickData
            public let leftTrigger: Float
            public let rightTrigger: Float
            
            public struct ThumbstickData: Sendable {
                public let x: Float
                public let y: Float
                public let magnitude: Float
                public let angle: Float
                public let isPressed: Bool
                
                public init(x: Float, y: Float, magnitude: Float, angle: Float, isPressed: Bool) {
                    self.x = x
                    self.y = y
                    self.magnitude = magnitude
                    self.angle = angle
                    self.isPressed = isPressed
                }
            }
            
            public init(leftThumbstick: ThumbstickData, rightThumbstick: ThumbstickData, leftTrigger: Float, rightTrigger: Float) {
                self.leftThumbstick = leftThumbstick
                self.rightThumbstick = rightThumbstick
                self.leftTrigger = leftTrigger
                self.rightTrigger = rightTrigger
            }
        }
        
        public struct MotionData: Sendable {
            public let gravity: SIMD3<Double>
            public let acceleration: SIMD3<Double>
            public let rotationRate: SIMD3<Double>
            public let attitude: SIMD4<Double>
            public let magneticField: SIMD3<Double>?
            public let timestamp: TimeInterval
            
            public init(gravity: SIMD3<Double>, acceleration: SIMD3<Double>, rotationRate: SIMD3<Double>, attitude: SIMD4<Double>, magneticField: SIMD3<Double>? = nil, timestamp: TimeInterval) {
                self.gravity = gravity
                self.acceleration = acceleration
                self.rotationRate = rotationRate
                self.attitude = attitude
                self.magneticField = magneticField
                self.timestamp = timestamp
            }
        }
        
        public struct TouchpadData: Sendable {
            public let primaryTouch: TouchData?
            public let secondaryTouch: TouchData?
            public let isPressed: Bool
            
            public struct TouchData: Sendable {
                public let x: Float
                public let y: Float
                public let force: Float
                public let timestamp: TimeInterval
                
                public init(x: Float, y: Float, force: Float, timestamp: TimeInterval) {
                    self.x = x
                    self.y = y
                    self.force = force
                    self.timestamp = timestamp
                }
            }
            
            public init(primaryTouch: TouchData?, secondaryTouch: TouchData?, isPressed: Bool) {
                self.primaryTouch = primaryTouch
                self.secondaryTouch = secondaryTouch
                self.isPressed = isPressed
            }
        }
        
        public init(eventType: InputEventType, controllerInfo: ControllerInfo, buttonStates: ButtonStates? = nil, analogStates: AnalogStates? = nil, motionData: MotionData? = nil, touchpadData: TouchpadData? = nil, batteryLevel: Float? = nil, isConnected: Bool = true) {
            self.eventType = eventType
            self.controllerInfo = controllerInfo
            self.buttonStates = buttonStates
            self.analogStates = analogStates
            self.motionData = motionData
            self.touchpadData = touchpadData
            self.batteryLevel = batteryLevel
            self.isConnected = isConnected
        }
    }
    
    public init(controllerId: String, inputData: InputData, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.controllerId = controllerId
        self.inputData = inputData
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Game controller input result
public struct GameControllerInputResult: Sendable, Identifiable {
    public let id: UUID
    public let eventId: UUID
    public let processedInput: ProcessedControllerInput
    public let recognizedGestures: [RecognizedControllerGesture]
    public let inputMetrics: ControllerInputMetrics
    public let hapticFeedback: HapticFeedbackResult?
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: GameControllerError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ProcessedControllerInput: Sendable {
        public let originalEvent: GameControllerInputEvent.InputData
        public let filteredInput: FilteredInput
        public let normalizedInput: NormalizedInput
        public let contextualInput: ContextualInput
        public let inputLatency: TimeInterval
        
        public struct FilteredInput: Sendable {
            public let deadZoneApplied: Bool
            public let noiseFiltered: Bool
            public let smoothingApplied: Bool
            public let calibrationApplied: Bool
            public let filteredAnalog: GameControllerInputEvent.InputData.AnalogStates?
            
            public init(deadZoneApplied: Bool, noiseFiltered: Bool, smoothingApplied: Bool, calibrationApplied: Bool, filteredAnalog: GameControllerInputEvent.InputData.AnalogStates?) {
                self.deadZoneApplied = deadZoneApplied
                self.noiseFiltered = noiseFiltered
                self.smoothingApplied = smoothingApplied
                self.calibrationApplied = calibrationApplied
                self.filteredAnalog = filteredAnalog
            }
        }
        
        public struct NormalizedInput: Sendable {
            public let normalizedAnalog: GameControllerInputEvent.InputData.AnalogStates?
            public let normalizedMotion: GameControllerInputEvent.InputData.MotionData?
            public let pressureNormalized: Bool
            public let timingNormalized: Bool
            
            public init(normalizedAnalog: GameControllerInputEvent.InputData.AnalogStates?, normalizedMotion: GameControllerInputEvent.InputData.MotionData?, pressureNormalized: Bool, timingNormalized: Bool) {
                self.normalizedAnalog = normalizedAnalog
                self.normalizedMotion = normalizedMotion
                self.pressureNormalized = pressureNormalized
                self.timingNormalized = timingNormalized
            }
        }
        
        public struct ContextualInput: Sendable {
            public let gameContext: String?
            public let inputPattern: InputPattern
            public let userProfile: String?
            public let adaptiveResponse: Bool
            
            public enum InputPattern: String, Sendable, CaseIterable {
                case button = "button"
                case analog = "analog"
                case motion = "motion"
                case combo = "combo"
                case gesture = "gesture"
                case sequence = "sequence"
            }
            
            public init(gameContext: String?, inputPattern: InputPattern, userProfile: String?, adaptiveResponse: Bool) {
                self.gameContext = gameContext
                self.inputPattern = inputPattern
                self.userProfile = userProfile
                self.adaptiveResponse = adaptiveResponse
            }
        }
        
        public init(originalEvent: GameControllerInputEvent.InputData, filteredInput: FilteredInput, normalizedInput: NormalizedInput, contextualInput: ContextualInput, inputLatency: TimeInterval) {
            self.originalEvent = originalEvent
            self.filteredInput = filteredInput
            self.normalizedInput = normalizedInput
            self.contextualInput = contextualInput
            self.inputLatency = inputLatency
        }
    }
    
    public struct RecognizedControllerGesture: Sendable {
        public let gestureType: GestureType
        public let confidence: Float
        public let duration: TimeInterval
        public let parameters: [String: Double]
        public let triggeredBy: String
        
        public enum GestureType: String, Sendable, CaseIterable {
            case analogSwipe = "analogSwipe"
            case buttonCombo = "buttonCombo"
            case triggerPress = "triggerPress"
            case thumbstickFlick = "thumbstickFlick"
            case dpadSequence = "dpadSequence"
            case motionGesture = "motionGesture"
            case touchpadGesture = "touchpadGesture"
            case customGesture = "customGesture"
        }
        
        public init(gestureType: GestureType, confidence: Float, duration: TimeInterval, parameters: [String: Double], triggeredBy: String) {
            self.gestureType = gestureType
            self.confidence = confidence
            self.duration = duration
            self.parameters = parameters
            self.triggeredBy = triggeredBy
        }
    }
    
    public struct ControllerInputMetrics: Sendable {
        public let inputFrequency: Double
        public let averageLatency: TimeInterval
        public let totalInputs: Int
        public let buttonPresses: Int
        public let analogMovements: Int
        public let motionEvents: Int
        public let accuracy: Double
        public let responsiveness: Double
        
        public init(inputFrequency: Double, averageLatency: TimeInterval, totalInputs: Int, buttonPresses: Int, analogMovements: Int, motionEvents: Int, accuracy: Double, responsiveness: Double) {
            self.inputFrequency = inputFrequency
            self.averageLatency = averageLatency
            self.totalInputs = totalInputs
            self.buttonPresses = buttonPresses
            self.analogMovements = analogMovements
            self.motionEvents = motionEvents
            self.accuracy = accuracy
            self.responsiveness = responsiveness
        }
    }
    
    public struct HapticFeedbackResult: Sendable {
        public let feedbackType: FeedbackType
        public let intensity: Float
        public let duration: TimeInterval
        public let success: Bool
        
        public enum FeedbackType: String, Sendable, CaseIterable {
            case light = "light"
            case medium = "medium"
            case heavy = "heavy"
            case selection = "selection"
            case impact = "impact"
            case notification = "notification"
            case custom = "custom"
        }
        
        public init(feedbackType: FeedbackType, intensity: Float, duration: TimeInterval, success: Bool) {
            self.feedbackType = feedbackType
            self.intensity = intensity
            self.duration = duration
            self.success = success
        }
    }
    
    public init(eventId: UUID, processedInput: ProcessedControllerInput, recognizedGestures: [RecognizedControllerGesture], inputMetrics: ControllerInputMetrics, hapticFeedback: HapticFeedbackResult? = nil, processingTime: TimeInterval, success: Bool, error: GameControllerError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.eventId = eventId
        self.processedInput = processedInput
        self.recognizedGestures = recognizedGestures
        self.inputMetrics = inputMetrics
        self.hapticFeedback = hapticFeedback
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var gestureCount: Int {
        recognizedGestures.count
    }
    
    public var averageGestureConfidence: Float {
        guard !recognizedGestures.isEmpty else { return 0.0 }
        return recognizedGestures.reduce(0) { $0 + $1.confidence } / Float(recognizedGestures.count)
    }
}

/// Game controller capability metrics
public struct GameControllerCapabilityMetrics: Sendable {
    public let totalInputEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageProcessingTime: TimeInterval
    public let eventsByController: [String: Int]
    public let gesturesByType: [String: Int]
    public let inputsByType: [String: Int]
    public let errorsByType: [String: Int]
    public let averageLatency: TimeInterval
    public let averageInputFrequency: Double
    public let controllersConnected: Int
    public let hapticFeedbackDelivered: Int
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestProcessingTime: TimeInterval
        public let worstProcessingTime: TimeInterval
        public let averageButtonsPerSession: Double
        public let averageAnalogMovements: Double
        public let totalGestures: Int
        public let inputAccuracy: Double
        public let controllerReliability: Double
        public let batteryEfficiency: Double
        
        public init(bestProcessingTime: TimeInterval = 0, worstProcessingTime: TimeInterval = 0, averageButtonsPerSession: Double = 0, averageAnalogMovements: Double = 0, totalGestures: Int = 0, inputAccuracy: Double = 0, controllerReliability: Double = 0, batteryEfficiency: Double = 0) {
            self.bestProcessingTime = bestProcessingTime
            self.worstProcessingTime = worstProcessingTime
            self.averageButtonsPerSession = averageButtonsPerSession
            self.averageAnalogMovements = averageAnalogMovements
            self.totalGestures = totalGestures
            self.inputAccuracy = inputAccuracy
            self.controllerReliability = controllerReliability
            self.batteryEfficiency = batteryEfficiency
        }
    }
    
    public init(totalInputEvents: Int = 0, successfulEvents: Int = 0, failedEvents: Int = 0, averageProcessingTime: TimeInterval = 0, eventsByController: [String: Int] = [:], gesturesByType: [String: Int] = [:], inputsByType: [String: Int] = [:], errorsByType: [String: Int] = [:], averageLatency: TimeInterval = 0, averageInputFrequency: Double = 0, controllersConnected: Int = 0, hapticFeedbackDelivered: Int = 0, throughputPerSecond: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalInputEvents = totalInputEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageProcessingTime = averageProcessingTime
        self.eventsByController = eventsByController
        self.gesturesByType = gesturesByType
        self.inputsByType = inputsByType
        self.errorsByType = errorsByType
        self.averageLatency = averageLatency
        self.averageInputFrequency = averageInputFrequency
        self.controllersConnected = controllersConnected
        self.hapticFeedbackDelivered = hapticFeedbackDelivered
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalInputEvents) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalInputEvents > 0 ? Double(successfulEvents) / Double(totalInputEvents) : 0
    }
}

// MARK: - Game Controller Resource

/// Game controller resource management
@available(iOS 13.0, macOS 10.15, *)
public actor GameControllerCapabilityResource: AxiomCapabilityResource {
    private let configuration: GameControllerCapabilityConfiguration
    private var activeEvents: [UUID: GameControllerInputEvent] = [:]
    private var eventHistory: [GameControllerInputResult] = []
    private var resultCache: [String: GameControllerInputResult] = [:]
    private var connectedControllers: [String: GCController] = [:]
    private var controllerManager: ControllerManager = ControllerManager()
    private var inputProcessor: InputProcessor = InputProcessor()
    private var gestureRecognizer: ControllerGestureRecognizer = ControllerGestureRecognizer()
    private var hapticEngine: HapticEngine? = nil
    private var inputTracker: ControllerInputTracker = ControllerInputTracker()
    private var metrics: GameControllerCapabilityMetrics = GameControllerCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<GameControllerInputResult>.Continuation?
    
    // Helper classes for game controller processing
    private class ControllerManager {
        private var discoveryObserver: NSObjectProtocol?
        private var disconnectionObserver: NSObjectProtocol?
        
        func startDiscovery() {
            GCController.startWirelessControllerDiscovery {}
            
            discoveryObserver = NotificationCenter.default.addObserver(
                forName: .GCControllerDidConnect,
                object: nil,
                queue: .main
            ) { notification in
                if let controller = notification.object as? GCController {
                    self.handleControllerConnection(controller)
                }
            }
            
            disconnectionObserver = NotificationCenter.default.addObserver(
                forName: .GCControllerDidDisconnect,
                object: nil,
                queue: .main
            ) { notification in
                if let controller = notification.object as? GCController {
                    self.handleControllerDisconnection(controller)
                }
            }
        }
        
        func stopDiscovery() {
            GCController.stopWirelessControllerDiscovery()
            
            if let observer = discoveryObserver {
                NotificationCenter.default.removeObserver(observer)
                discoveryObserver = nil
            }
            
            if let observer = disconnectionObserver {
                NotificationCenter.default.removeObserver(observer)
                disconnectionObserver = nil
            }
        }
        
        private func handleControllerConnection(_ controller: GCController) {
            // Configure controller input handlers
            configureControllerInputHandlers(controller)
        }
        
        private func handleControllerDisconnection(_ controller: GCController) {
            // Clean up controller resources
        }
        
        private func configureControllerInputHandlers(_ controller: GCController) {
            // Configure gamepad input handlers
            if let gamepad = controller.extendedGamepad {
                configureExtendedGamepadHandlers(gamepad)
            } else if let gamepad = controller.microGamepad {
                configureMicroGamepadHandlers(gamepad)
            }
            
            // Configure motion handlers
            if let motion = controller.motion {
                configureMotionHandlers(motion)
            }
        }
        
        private func configureExtendedGamepadHandlers(_ gamepad: GCExtendedGamepad) {
            // Button handlers
            gamepad.buttonA.valueChangedHandler = { button, value, pressed in
                // Handle button A input
            }
            
            gamepad.buttonB.valueChangedHandler = { button, value, pressed in
                // Handle button B input
            }
            
            // Analog stick handlers
            gamepad.leftThumbstick.valueChangedHandler = { stick, xValue, yValue in
                // Handle left thumbstick input
            }
            
            gamepad.rightThumbstick.valueChangedHandler = { stick, xValue, yValue in
                // Handle right thumbstick input
            }
            
            // Trigger handlers
            gamepad.leftTrigger.valueChangedHandler = { button, value, pressed in
                // Handle left trigger input
            }
            
            gamepad.rightTrigger.valueChangedHandler = { button, value, pressed in
                // Handle right trigger input
            }
        }
        
        private func configureMicroGamepadHandlers(_ gamepad: GCMicroGamepad) {
            gamepad.buttonA.valueChangedHandler = { button, value, pressed in
                // Handle micro gamepad button A
            }
            
            gamepad.buttonX.valueChangedHandler = { button, value, pressed in
                // Handle micro gamepad button X
            }
            
            gamepad.dpad.valueChangedHandler = { dpad, xValue, yValue in
                // Handle micro gamepad dpad
            }
        }
        
        private func configureMotionHandlers(_ motion: GCMotion) {
            motion.valueChangedHandler = { motion in
                // Handle motion input
            }
        }
        
        func getConnectedControllers() -> [GCController] {
            return GCController.controllers()
        }
        
        func getControllerInfo(_ controller: GCController) -> GameControllerInputEvent.InputData.ControllerInfo {
            let controllerType = determineControllerType(controller)
            
            return GameControllerInputEvent.InputData.ControllerInfo(
                controllerType: controllerType,
                vendorName: controller.vendorName,
                productCategory: controller.productCategory,
                deviceHash: controller.deviceHash,
                isWireless: controller.isAttachedToDevice == false,
                supportsHaptics: controller.haptics != nil,
                supportsMotion: controller.motion != nil,
                playerIndex: controller.playerIndex.rawValue
            )
        }
        
        private func determineControllerType(_ controller: GCController) -> GameControllerCapabilityConfiguration.ControllerType {
            if let vendorName = controller.vendorName?.lowercased() {
                if vendorName.contains("xbox") {
                    return .xbox
                } else if vendorName.contains("playstation") || vendorName.contains("sony") {
                    return .playstation
                } else if vendorName.contains("nintendo") {
                    return .nintendoSwitch
                }
            }
            
            if controller.extendedGamepad != nil {
                return .mfi
            }
            
            return .generic
        }
    }
    
    private class InputProcessor {
        func processControllerInput(
            _ event: GameControllerInputEvent,
            configuration: GameControllerCapabilityConfiguration
        ) -> GameControllerInputResult.ProcessedControllerInput {
            
            let startTime = Date()
            
            // Apply dead zone filtering
            let filteredInput = applyFiltering(event.inputData, configuration: configuration)
            
            // Normalize input values
            let normalizedInput = normalizeInput(filteredInput, configuration: configuration)
            
            // Apply contextual processing
            let contextualInput = applyContextualProcessing(normalizedInput, configuration: configuration)
            
            let inputLatency = Date().timeIntervalSince(startTime)
            
            return GameControllerInputResult.ProcessedControllerInput(
                originalEvent: event.inputData,
                filteredInput: filteredInput,
                normalizedInput: normalizedInput,
                contextualInput: contextualInput,
                inputLatency: inputLatency
            )
        }
        
        private func applyFiltering(
            _ inputData: GameControllerInputEvent.InputData,
            configuration: GameControllerCapabilityConfiguration
        ) -> GameControllerInputResult.ProcessedControllerInput.FilteredInput {
            
            var deadZoneApplied = false
            var noiseFiltered = false
            var smoothingApplied = false
            var calibrationApplied = false
            var filteredAnalog: GameControllerInputEvent.InputData.AnalogStates?
            
            if let analog = inputData.analogStates {
                // Apply dead zone to thumbsticks
                let leftFiltered = applyDeadZone(analog.leftThumbstick, threshold: configuration.deadZoneThreshold)
                let rightFiltered = applyDeadZone(analog.rightThumbstick, threshold: configuration.deadZoneThreshold)
                
                filteredAnalog = GameControllerInputEvent.InputData.AnalogStates(
                    leftThumbstick: leftFiltered,
                    rightThumbstick: rightFiltered,
                    leftTrigger: analog.leftTrigger,
                    rightTrigger: analog.rightTrigger
                )
                
                deadZoneApplied = true
                noiseFiltered = true
                smoothingApplied = true
                calibrationApplied = true
            }
            
            return GameControllerInputResult.ProcessedControllerInput.FilteredInput(
                deadZoneApplied: deadZoneApplied,
                noiseFiltered: noiseFiltered,
                smoothingApplied: smoothingApplied,
                calibrationApplied: calibrationApplied,
                filteredAnalog: filteredAnalog
            )
        }
        
        private func applyDeadZone(
            _ thumbstick: GameControllerInputEvent.InputData.AnalogStates.ThumbstickData,
            threshold: Double
        ) -> GameControllerInputEvent.InputData.AnalogStates.ThumbstickData {
            
            let magnitude = sqrt(thumbstick.x * thumbstick.x + thumbstick.y * thumbstick.y)
            
            if magnitude < Float(threshold) {
                return GameControllerInputEvent.InputData.AnalogStates.ThumbstickData(
                    x: 0.0,
                    y: 0.0,
                    magnitude: 0.0,
                    angle: thumbstick.angle,
                    isPressed: thumbstick.isPressed
                )
            }
            
            // Rescale to use full range after dead zone
            let scale = (magnitude - Float(threshold)) / (1.0 - Float(threshold))
            let normalizedX = thumbstick.x / magnitude * scale
            let normalizedY = thumbstick.y / magnitude * scale
            
            return GameControllerInputEvent.InputData.AnalogStates.ThumbstickData(
                x: normalizedX,
                y: normalizedY,
                magnitude: scale,
                angle: atan2(normalizedY, normalizedX),
                isPressed: thumbstick.isPressed
            )
        }
        
        private func normalizeInput(
            _ filteredInput: GameControllerInputResult.ProcessedControllerInput.FilteredInput,
            configuration: GameControllerCapabilityConfiguration
        ) -> GameControllerInputResult.ProcessedControllerInput.NormalizedInput {
            
            return GameControllerInputResult.ProcessedControllerInput.NormalizedInput(
                normalizedAnalog: filteredInput.filteredAnalog,
                normalizedMotion: nil,
                pressureNormalized: true,
                timingNormalized: true
            )
        }
        
        private func applyContextualProcessing(
            _ normalizedInput: GameControllerInputResult.ProcessedControllerInput.NormalizedInput,
            configuration: GameControllerCapabilityConfiguration
        ) -> GameControllerInputResult.ProcessedControllerInput.ContextualInput {
            
            let inputPattern = determineInputPattern(normalizedInput)
            
            return GameControllerInputResult.ProcessedControllerInput.ContextualInput(
                gameContext: nil,
                inputPattern: inputPattern,
                userProfile: nil,
                adaptiveResponse: true
            )
        }
        
        private func determineInputPattern(
            _ input: GameControllerInputResult.ProcessedControllerInput.NormalizedInput
        ) -> GameControllerInputResult.ProcessedControllerInput.ContextualInput.InputPattern {
            
            if input.normalizedAnalog != nil {
                return .analog
            } else if input.normalizedMotion != nil {
                return .motion
            } else {
                return .button
            }
        }
    }
    
    private class ControllerGestureRecognizer {
        func recognizeGestures(from inputEvent: GameControllerInputEvent) -> [GameControllerInputResult.RecognizedControllerGesture] {
            var gestures: [GameControllerInputResult.RecognizedControllerGesture] = []
            
            // Recognize button combos
            if let buttonStates = inputEvent.inputData.buttonStates {
                if let comboGesture = recognizeButtonCombo(buttonStates) {
                    gestures.append(comboGesture)
                }
            }
            
            // Recognize analog gestures
            if let analogStates = inputEvent.inputData.analogStates {
                if let analogGesture = recognizeAnalogGesture(analogStates) {
                    gestures.append(analogGesture)
                }
            }
            
            // Recognize motion gestures
            if let motionData = inputEvent.inputData.motionData {
                if let motionGesture = recognizeMotionGesture(motionData) {
                    gestures.append(motionGesture)
                }
            }
            
            return gestures
        }
        
        private func recognizeButtonCombo(_ buttonStates: GameControllerInputEvent.InputData.ButtonStates) -> GameControllerInputResult.RecognizedControllerGesture? {
            // Recognize common button combinations
            if buttonStates.buttonA && buttonStates.buttonB {
                return GameControllerInputResult.RecognizedControllerGesture(
                    gestureType: .buttonCombo,
                    confidence: 0.9,
                    duration: 0.1,
                    parameters: ["buttons": 2.0],
                    triggeredBy: "A+B"
                )
            }
            
            return nil
        }
        
        private func recognizeAnalogGesture(_ analogStates: GameControllerInputEvent.InputData.AnalogStates) -> GameControllerInputResult.RecognizedControllerGesture? {
            // Recognize thumbstick flicks
            let leftMagnitude = analogStates.leftThumbstick.magnitude
            let rightMagnitude = analogStates.rightThumbstick.magnitude
            
            if leftMagnitude > 0.8 || rightMagnitude > 0.8 {
                return GameControllerInputResult.RecognizedControllerGesture(
                    gestureType: .thumbstickFlick,
                    confidence: 0.8,
                    duration: 0.05,
                    parameters: ["magnitude": Double(max(leftMagnitude, rightMagnitude))],
                    triggeredBy: leftMagnitude > rightMagnitude ? "leftThumbstick" : "rightThumbstick"
                )
            }
            
            return nil
        }
        
        private func recognizeMotionGesture(_ motionData: GameControllerInputEvent.InputData.MotionData) -> GameControllerInputResult.RecognizedControllerGesture? {
            // Recognize controller shake or tilt gestures
            let accelerationMagnitude = sqrt(
                motionData.acceleration.x * motionData.acceleration.x +
                motionData.acceleration.y * motionData.acceleration.y +
                motionData.acceleration.z * motionData.acceleration.z
            )
            
            if accelerationMagnitude > 2.0 {
                return GameControllerInputResult.RecognizedControllerGesture(
                    gestureType: .motionGesture,
                    confidence: 0.7,
                    duration: 0.2,
                    parameters: ["acceleration": accelerationMagnitude],
                    triggeredBy: "motion"
                )
            }
            
            return nil
        }
    }
    
    private class HapticEngine {
        private var hapticEngine: CHHapticEngine?
        
        init() {
            setupHapticEngine()
        }
        
        private func setupHapticEngine() {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            
            do {
                hapticEngine = try CHHapticEngine()
                try hapticEngine?.start()
            } catch {
                print("Haptic engine failed to start: \(error)")
            }
        }
        
        func playHapticFeedback(
            type: GameControllerInputResult.HapticFeedbackResult.FeedbackType,
            intensity: Float,
            duration: TimeInterval
        ) -> GameControllerInputResult.HapticFeedbackResult {
            
            var success = false
            
            if let engine = hapticEngine {
                do {
                    let hapticEvent = createHapticEvent(type: type, intensity: intensity, duration: duration)
                    let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
                    let player = try engine.makePlayer(with: pattern)
                    try player.start(atTime: 0)
                    success = true
                } catch {
                    print("Haptic feedback failed: \(error)")
                }
            }
            
            return GameControllerInputResult.HapticFeedbackResult(
                feedbackType: type,
                intensity: intensity,
                duration: duration,
                success: success
            )
        }
        
        private func createHapticEvent(
            type: GameControllerInputResult.HapticFeedbackResult.FeedbackType,
            intensity: Float,
            duration: TimeInterval
        ) -> CHHapticEvent {
            
            let hapticIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let hapticSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            
            return CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [hapticIntensity, hapticSharpness],
                relativeTime: 0,
                duration: duration
            )
        }
    }
    
    private class ControllerInputTracker {
        private var sessionStartTime: Date = Date()
        private var inputCount: Int = 0
        private var buttonPresses: Int = 0
        private var analogMovements: Int = 0
        private var motionEvents: Int = 0
        private var totalLatency: TimeInterval = 0
        
        func trackInput(_ inputEvent: GameControllerInputEvent, latency: TimeInterval) {
            inputCount += 1
            totalLatency += latency
            
            if inputEvent.inputData.buttonStates != nil {
                buttonPresses += 1
            }
            
            if inputEvent.inputData.analogStates != nil {
                analogMovements += 1
            }
            
            if inputEvent.inputData.motionData != nil {
                motionEvents += 1
            }
        }
        
        func calculateMetrics() -> GameControllerInputResult.ControllerInputMetrics {
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            let inputFrequency = sessionDuration > 0 ? Double(inputCount) / sessionDuration : 0
            let averageLatency = inputCount > 0 ? totalLatency / Double(inputCount) : 0
            
            return GameControllerInputResult.ControllerInputMetrics(
                inputFrequency: inputFrequency,
                averageLatency: averageLatency,
                totalInputs: inputCount,
                buttonPresses: buttonPresses,
                analogMovements: analogMovements,
                motionEvents: motionEvents,
                accuracy: 0.95, // Simplified
                responsiveness: 0.9 // Simplified
            )
        }
        
        func reset() {
            sessionStartTime = Date()
            inputCount = 0
            buttonPresses = 0
            analogMovements = 0
            motionEvents = 0
            totalLatency = 0
        }
    }
    
    public init(configuration: GameControllerCapabilityConfiguration) {
        self.configuration = configuration
        if configuration.enableHapticFeedback {
            self.hapticEngine = HapticEngine()
        }
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 150_000_000, // 150MB for game controller processing
            cpu: 2.5, // High CPU usage for real-time input processing
            bandwidth: 0,
            storage: 50_000_000 // 50MB for controller profiles and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = activeEvents.count * 5_000_000 // ~5MB per active event
            let cacheMemory = resultCache.count * 25_000 // ~25KB per cached result
            let historyMemory = eventHistory.count * 15_000
            let controllerMemory = connectedControllers.count * 10_000_000 // ~10MB per controller
            let processingMemory = 30_000_000 // Controller processing overhead
            
            return ResourceUsage(
                memory: eventMemory + cacheMemory + historyMemory + controllerMemory + processingMemory,
                cpu: activeEvents.isEmpty ? 0.2 : 2.0,
                bandwidth: 0,
                storage: resultCache.count * 15_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Game controller support is available on iOS 13+ with GameController framework
        if #available(iOS 13.0, *) {
            return configuration.enableGameControllerSupport
        }
        return false
    }
    
    public func release() async {
        activeEvents.removeAll()
        eventHistory.removeAll()
        resultCache.removeAll()
        connectedControllers.removeAll()
        
        controllerManager.stopDiscovery()
        controllerManager = ControllerManager()
        inputProcessor = InputProcessor()
        gestureRecognizer = ControllerGestureRecognizer()
        hapticEngine = nil
        inputTracker.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = GameControllerCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        controllerManager = ControllerManager()
        inputProcessor = InputProcessor()
        gestureRecognizer = ControllerGestureRecognizer()
        inputTracker = ControllerInputTracker()
        
        if configuration.enableHapticFeedback {
            hapticEngine = HapticEngine()
        }
        
        if configuration.enableControllerDiscovery {
            controllerManager.startDiscovery()
        }
        
        if configuration.enableLogging {
            print("[GameController] 🚀 Game Controller capability initialized")
            print("[GameController] 🎮 Max controllers: \(configuration.maxConcurrentControllers)")
        }
    }
    
    internal func updateConfiguration(_ configuration: GameControllerCapabilityConfiguration) async throws {
        // Update game controller configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<GameControllerInputResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Game Controller Processing
    
    public func processInput(_ event: GameControllerInputEvent) async throws -> GameControllerInputResult {
        guard configuration.enableGameControllerSupport else {
            throw GameControllerError.gameControllerDisabled
        }
        
        let startTime = Date()
        activeEvents[event.id] = event
        
        do {
            // Process controller input
            let processedInput = inputProcessor.processControllerInput(event, configuration: configuration)
            
            // Recognize gestures if enabled
            let recognizedGestures = gestureRecognizer.recognizeGestures(from: event)
            
            // Track input metrics
            inputTracker.trackInput(event, latency: processedInput.inputLatency)
            let inputMetrics = inputTracker.calculateMetrics()
            
            // Handle haptic feedback if enabled
            var hapticFeedback: GameControllerInputResult.HapticFeedbackResult?
            if configuration.enableHapticFeedback,
               let hapticEngine = hapticEngine,
               event.inputData.eventType == .buttonPressed {
                hapticFeedback = hapticEngine.playHapticFeedback(
                    type: .light,
                    intensity: Float(configuration.hapticIntensity),
                    duration: 0.1
                )
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = GameControllerInputResult(
                eventId: event.id,
                processedInput: processedInput,
                recognizedGestures: recognizedGestures,
                inputMetrics: inputMetrics,
                hapticFeedback: hapticFeedback,
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
                await logControllerEvent(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = GameControllerInputResult(
                eventId: event.id,
                processedInput: GameControllerInputResult.ProcessedControllerInput(
                    originalEvent: event.inputData,
                    filteredInput: GameControllerInputResult.ProcessedControllerInput.FilteredInput(
                        deadZoneApplied: false,
                        noiseFiltered: false,
                        smoothingApplied: false,
                        calibrationApplied: false,
                        filteredAnalog: nil
                    ),
                    normalizedInput: GameControllerInputResult.ProcessedControllerInput.NormalizedInput(
                        normalizedAnalog: nil,
                        normalizedMotion: nil,
                        pressureNormalized: false,
                        timingNormalized: false
                    ),
                    contextualInput: GameControllerInputResult.ProcessedControllerInput.ContextualInput(
                        gameContext: nil,
                        inputPattern: .button,
                        userProfile: nil,
                        adaptiveResponse: false
                    ),
                    inputLatency: 0
                ),
                recognizedGestures: [],
                inputMetrics: GameControllerInputResult.ControllerInputMetrics(
                    inputFrequency: 0,
                    averageLatency: 0,
                    totalInputs: 0,
                    buttonPresses: 0,
                    analogMovements: 0,
                    motionEvents: 0,
                    accuracy: 0,
                    responsiveness: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? GameControllerError ?? GameControllerError.processingError(error.localizedDescription)
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logControllerEvent(result)
            }
            
            throw error
        }
    }
    
    public func getConnectedControllers() async -> [String] {
        return controllerManager.getConnectedControllers().map { $0.deviceHash }
    }
    
    public func getActiveEvents() async -> [GameControllerInputEvent] {
        return Array(activeEvents.values)
    }
    
    public func getEventHistory(since: Date? = nil) async -> [GameControllerInputResult] {
        if let since = since {
            return eventHistory.filter { $0.timestamp >= since }
        }
        return eventHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> GameControllerCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = GameControllerCapabilityMetrics()
        inputTracker.reset()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for event: GameControllerInputEvent) -> String {
        let controllerHash = event.controllerId.hashValue
        let eventTypeHash = event.inputData.eventType.rawValue.hashValue
        let timestamp = Int(event.timestamp.timeIntervalSince1970 * 1000)
        return "\(controllerHash)_\(eventTypeHash)_\(timestamp)"
    }
    
    private func updateSuccessMetrics(_ result: GameControllerInputResult) async {
        let totalEvents = metrics.totalInputEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalInputEvents)) + result.processingTime) / Double(totalEvents)
        let newAverageLatency = ((metrics.averageLatency * Double(metrics.successfulEvents)) + result.inputMetrics.averageLatency) / Double(successfulEvents)
        let newAverageInputFrequency = ((metrics.averageInputFrequency * Double(metrics.successfulEvents)) + result.inputMetrics.inputFrequency) / Double(successfulEvents)
        
        var eventsByController = metrics.eventsByController
        let controllerKey = result.processedInput.originalEvent.controllerInfo.controllerType.rawValue
        eventsByController[controllerKey, default: 0] += 1
        
        var gesturesByType = metrics.gesturesByType
        for gesture in result.recognizedGestures {
            gesturesByType[gesture.gestureType.rawValue, default: 0] += 1
        }
        
        var inputsByType = metrics.inputsByType
        inputsByType[result.processedInput.originalEvent.eventType.rawValue, default: 0] += 1
        
        let hapticFeedbackDelivered = metrics.hapticFeedbackDelivered + (result.hapticFeedback?.success == true ? 1 : 0)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulEvents == 0 ? result.processingTime : min(performanceStats.bestProcessingTime, result.processingTime)
        let worstTime = max(performanceStats.worstProcessingTime, result.processingTime)
        let newAverageButtonsPerSession = ((performanceStats.averageButtonsPerSession * Double(metrics.successfulEvents)) + Double(result.inputMetrics.buttonPresses)) / Double(successfulEvents)
        let newAverageAnalogMovements = ((performanceStats.averageAnalogMovements * Double(metrics.successfulEvents)) + Double(result.inputMetrics.analogMovements)) / Double(successfulEvents)
        let totalGestures = performanceStats.totalGestures + result.gestureCount
        let newInputAccuracy = ((performanceStats.inputAccuracy * Double(metrics.successfulEvents)) + result.inputMetrics.accuracy) / Double(successfulEvents)
        
        performanceStats = GameControllerCapabilityMetrics.PerformanceStats(
            bestProcessingTime: bestTime,
            worstProcessingTime: worstTime,
            averageButtonsPerSession: newAverageButtonsPerSession,
            averageAnalogMovements: newAverageAnalogMovements,
            totalGestures: totalGestures,
            inputAccuracy: newInputAccuracy,
            controllerReliability: performanceStats.controllerReliability,
            batteryEfficiency: performanceStats.batteryEfficiency
        )
        
        metrics = GameControllerCapabilityMetrics(
            totalInputEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageProcessingTime: newAverageProcessingTime,
            eventsByController: eventsByController,
            gesturesByType: gesturesByType,
            inputsByType: inputsByType,
            errorsByType: metrics.errorsByType,
            averageLatency: newAverageLatency,
            averageInputFrequency: newAverageInputFrequency,
            controllersConnected: connectedControllers.count,
            hapticFeedbackDelivered: hapticFeedbackDelivered,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: GameControllerInputResult) async {
        let totalEvents = metrics.totalInputEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = GameControllerCapabilityMetrics(
            totalInputEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageProcessingTime: metrics.averageProcessingTime,
            eventsByController: metrics.eventsByController,
            gesturesByType: metrics.gesturesByType,
            inputsByType: metrics.inputsByType,
            errorsByType: errorsByType,
            averageLatency: metrics.averageLatency,
            averageInputFrequency: metrics.averageInputFrequency,
            controllersConnected: metrics.controllersConnected,
            hapticFeedbackDelivered: metrics.hapticFeedbackDelivered,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logControllerEvent(_ result: GameControllerInputResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let eventType = result.processedInput.originalEvent.eventType.rawValue
        let controllerType = result.processedInput.originalEvent.controllerInfo.controllerType.rawValue
        let gestureCount = result.gestureCount
        let latencyStr = String(format: "%.1f", result.inputMetrics.averageLatency * 1000)
        
        print("[GameController] \(statusIcon) Event: \(eventType), \(controllerType), \(gestureCount) gestures, \(latencyStr)ms latency (\(timeStr)s)")
        
        if let error = result.error {
            print("[GameController] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Game Controller Capability Implementation

/// Game Controller capability providing comprehensive game controller support
@available(iOS 13.0, macOS 10.15, *)
public actor GameControllerCapability: DomainCapability {
    public typealias ConfigurationType = GameControllerCapabilityConfiguration
    public typealias ResourceType = GameControllerCapabilityResource
    
    private var _configuration: GameControllerCapabilityConfiguration
    private var _resources: GameControllerCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(8)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "game-controller-capability" }
    
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
    
    public var configuration: GameControllerCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: GameControllerCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: GameControllerCapabilityConfiguration = GameControllerCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = GameControllerCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: GameControllerCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Game Controller configuration")
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
        // Game Controller is supported on iOS 13+ with GameController framework
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Game Controller doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Game Controller Operations
    
    /// Process controller input event
    public func processInput(_ event: GameControllerInputEvent) async throws -> GameControllerInputResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        return try await _resources.processInput(event)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<GameControllerInputResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get connected controllers
    public func getConnectedControllers() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        return await _resources.getConnectedControllers()
    }
    
    /// Get active events
    public func getActiveEvents() async throws -> [GameControllerInputEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        return await _resources.getActiveEvents()
    }
    
    /// Get event history
    public func getEventHistory(since: Date? = nil) async throws -> [GameControllerInputResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        return await _resources.getEventHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> GameControllerCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Game Controller capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create button press event
    public func createButtonEvent(
        controllerId: String,
        controllerType: GameControllerCapabilityConfiguration.ControllerType = .mfi,
        buttonStates: GameControllerInputEvent.InputData.ButtonStates
    ) -> GameControllerInputEvent {
        let controllerInfo = GameControllerInputEvent.InputData.ControllerInfo(
            controllerType: controllerType,
            vendorName: nil,
            productCategory: nil,
            deviceHash: controllerId,
            isWireless: true,
            supportsHaptics: true,
            supportsMotion: false,
            playerIndex: nil
        )
        
        let inputData = GameControllerInputEvent.InputData(
            eventType: .buttonPressed,
            controllerInfo: controllerInfo,
            buttonStates: buttonStates
        )
        
        return GameControllerInputEvent(controllerId: controllerId, inputData: inputData)
    }
    
    /// Create analog stick event
    public func createAnalogEvent(
        controllerId: String,
        controllerType: GameControllerCapabilityConfiguration.ControllerType = .mfi,
        analogStates: GameControllerInputEvent.InputData.AnalogStates
    ) -> GameControllerInputEvent {
        let controllerInfo = GameControllerInputEvent.InputData.ControllerInfo(
            controllerType: controllerType,
            vendorName: nil,
            productCategory: nil,
            deviceHash: controllerId,
            isWireless: true,
            supportsHaptics: true,
            supportsMotion: false,
            playerIndex: nil
        )
        
        let inputData = GameControllerInputEvent.InputData(
            eventType: .analogChanged,
            controllerInfo: controllerInfo,
            analogStates: analogStates
        )
        
        return GameControllerInputEvent(controllerId: controllerId, inputData: inputData)
    }
    
    /// Check if controllers are connected
    public func hasConnectedControllers() async throws -> Bool {
        let controllers = try await getConnectedControllers()
        return !controllers.isEmpty
    }
    
    /// Get controller count
    public func getConnectedControllerCount() async throws -> Int {
        let controllers = try await getConnectedControllers()
        return controllers.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Game Controller specific errors
public enum GameControllerError: Error, LocalizedError {
    case gameControllerDisabled
    case controllerNotFound(String)
    case processingError(String)
    case inputMappingFailed
    case hapticFeedbackFailed
    case gestureRecognitionFailed
    case controllerConnectionFailed
    case inputTimeout(UUID)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .gameControllerDisabled:
            return "Game controller support is disabled"
        case .controllerNotFound(let id):
            return "Controller not found: \(id)"
        case .processingError(let reason):
            return "Game controller processing failed: \(reason)"
        case .inputMappingFailed:
            return "Input mapping failed"
        case .hapticFeedbackFailed:
            return "Haptic feedback failed"
        case .gestureRecognitionFailed:
            return "Gesture recognition failed"
        case .controllerConnectionFailed:
            return "Controller connection failed"
        case .inputTimeout(let id):
            return "Input timeout: \(id)"
        case .configurationError(let reason):
            return "Game controller configuration error: \(reason)"
        }
    }
}