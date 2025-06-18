import Foundation
import CoreMotion
import AxiomCore
import AxiomCapabilities

// MARK: - Device Motion Capability Configuration

/// Configuration for Device Motion capability
public struct DeviceMotionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableAccelerometer: Bool
    public let enableGyroscope: Bool
    public let enableMagnetometer: Bool
    public let enableDeviceMotion: Bool
    public let enableAttitudeUpdates: Bool
    public let updateInterval: TimeInterval
    public let accelerometerUpdateInterval: TimeInterval
    public let gyroscopeUpdateInterval: TimeInterval
    public let magnetometerUpdateInterval: TimeInterval
    public let enableMotionDetection: Bool
    public let motionThreshold: Double
    public let enableGestureRecognition: Bool
    public let enableShakeDetection: Bool
    public let shakeThreshold: Double
    public let enableOrientationTracking: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableBackgroundUpdates: Bool
    public let maxHistorySize: Int
    public let enablePedometer: Bool
    public let enableStepCounting: Bool
    public let enableActivityClassification: Bool
    
    public init(
        enableAccelerometer: Bool = true,
        enableGyroscope: Bool = true,
        enableMagnetometer: Bool = true,
        enableDeviceMotion: Bool = true,
        enableAttitudeUpdates: Bool = true,
        updateInterval: TimeInterval = 0.1, // 10 Hz
        accelerometerUpdateInterval: TimeInterval = 0.02, // 50 Hz
        gyroscopeUpdateInterval: TimeInterval = 0.02, // 50 Hz  
        magnetometerUpdateInterval: TimeInterval = 0.1, // 10 Hz
        enableMotionDetection: Bool = true,
        motionThreshold: Double = 0.1,
        enableGestureRecognition: Bool = true,
        enableShakeDetection: Bool = true,
        shakeThreshold: Double = 2.5,
        enableOrientationTracking: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableBackgroundUpdates: Bool = false,
        maxHistorySize: Int = 1000,
        enablePedometer: Bool = true,
        enableStepCounting: Bool = true,
        enableActivityClassification: Bool = true
    ) {
        self.enableAccelerometer = enableAccelerometer
        self.enableGyroscope = enableGyroscope
        self.enableMagnetometer = enableMagnetometer
        self.enableDeviceMotion = enableDeviceMotion
        self.enableAttitudeUpdates = enableAttitudeUpdates
        self.updateInterval = updateInterval
        self.accelerometerUpdateInterval = accelerometerUpdateInterval
        self.gyroscopeUpdateInterval = gyroscopeUpdateInterval
        self.magnetometerUpdateInterval = magnetometerUpdateInterval
        self.enableMotionDetection = enableMotionDetection
        self.motionThreshold = motionThreshold
        self.enableGestureRecognition = enableGestureRecognition
        self.enableShakeDetection = enableShakeDetection
        self.shakeThreshold = shakeThreshold
        self.enableOrientationTracking = enableOrientationTracking
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableBackgroundUpdates = enableBackgroundUpdates
        self.maxHistorySize = maxHistorySize
        self.enablePedometer = enablePedometer
        self.enableStepCounting = enableStepCounting
        self.enableActivityClassification = enableActivityClassification
    }
    
    public var isValid: Bool {
        updateInterval > 0 && updateInterval <= 1.0 &&
        accelerometerUpdateInterval > 0 && accelerometerUpdateInterval <= 1.0 &&
        gyroscopeUpdateInterval > 0 && gyroscopeUpdateInterval <= 1.0 &&
        magnetometerUpdateInterval > 0 && magnetometerUpdateInterval <= 1.0 &&
        motionThreshold > 0 &&
        shakeThreshold > 0 &&
        maxHistorySize > 0
    }
    
    public func merged(with other: DeviceMotionCapabilityConfiguration) -> DeviceMotionCapabilityConfiguration {
        DeviceMotionCapabilityConfiguration(
            enableAccelerometer: other.enableAccelerometer,
            enableGyroscope: other.enableGyroscope,
            enableMagnetometer: other.enableMagnetometer,
            enableDeviceMotion: other.enableDeviceMotion,
            enableAttitudeUpdates: other.enableAttitudeUpdates,
            updateInterval: other.updateInterval,
            accelerometerUpdateInterval: other.accelerometerUpdateInterval,
            gyroscopeUpdateInterval: other.gyroscopeUpdateInterval,
            magnetometerUpdateInterval: other.magnetometerUpdateInterval,
            enableMotionDetection: other.enableMotionDetection,
            motionThreshold: other.motionThreshold,
            enableGestureRecognition: other.enableGestureRecognition,
            enableShakeDetection: other.enableShakeDetection,
            shakeThreshold: other.shakeThreshold,
            enableOrientationTracking: other.enableOrientationTracking,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableBackgroundUpdates: other.enableBackgroundUpdates,
            maxHistorySize: other.maxHistorySize,
            enablePedometer: other.enablePedometer,
            enableStepCounting: other.enableStepCounting,
            enableActivityClassification: other.enableActivityClassification
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> DeviceMotionCapabilityConfiguration {
        var adjustedInterval = updateInterval
        var adjustedLogging = enableLogging
        var adjustedBackground = enableBackgroundUpdates
        var adjustedHistorySize = maxHistorySize
        var adjustedGestures = enableGestureRecognition
        
        if environment.isLowPowerMode {
            adjustedInterval = max(updateInterval, 0.5) // Reduce to 2 Hz max
            adjustedBackground = false
            adjustedHistorySize = min(maxHistorySize, 100)
            adjustedGestures = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return DeviceMotionCapabilityConfiguration(
            enableAccelerometer: enableAccelerometer,
            enableGyroscope: enableGyroscope,
            enableMagnetometer: enableMagnetometer,
            enableDeviceMotion: enableDeviceMotion,
            enableAttitudeUpdates: enableAttitudeUpdates,
            updateInterval: adjustedInterval,
            accelerometerUpdateInterval: accelerometerUpdateInterval,
            gyroscopeUpdateInterval: gyroscopeUpdateInterval,
            magnetometerUpdateInterval: magnetometerUpdateInterval,
            enableMotionDetection: enableMotionDetection,
            motionThreshold: motionThreshold,
            enableGestureRecognition: adjustedGestures,
            enableShakeDetection: enableShakeDetection,
            shakeThreshold: shakeThreshold,
            enableOrientationTracking: enableOrientationTracking,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableBackgroundUpdates: adjustedBackground,
            maxHistorySize: adjustedHistorySize,
            enablePedometer: enablePedometer,
            enableStepCounting: enableStepCounting,
            enableActivityClassification: enableActivityClassification
        )
    }
}

// MARK: - Device Motion Types

/// Device motion data
public struct DeviceMotionData: Sendable {
    public let timestamp: Date
    public let accelerometer: AccelerometerData?
    public let gyroscope: GyroscopeData?
    public let magnetometer: MagnetometerData?
    public let attitude: AttitudeData?
    public let gravity: Vector3D?
    public let userAcceleration: Vector3D?
    public let rotationRate: Vector3D?
    public let magneticField: MagneticFieldData?
    
    public init(
        accelerometer: AccelerometerData? = nil,
        gyroscope: GyroscopeData? = nil,
        magnetometer: MagnetometerData? = nil,
        attitude: AttitudeData? = nil,
        gravity: Vector3D? = nil,
        userAcceleration: Vector3D? = nil,
        rotationRate: Vector3D? = nil,
        magneticField: MagneticFieldData? = nil
    ) {
        self.timestamp = Date()
        self.accelerometer = accelerometer
        self.gyroscope = gyroscope
        self.magnetometer = magnetometer
        self.attitude = attitude
        self.gravity = gravity
        self.userAcceleration = userAcceleration
        self.rotationRate = rotationRate
        self.magneticField = magneticField
    }
}

/// 3D vector data structure
public struct Vector3D: Sendable, Codable {
    public let x: Double
    public let y: Double
    public let z: Double
    
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public var magnitude: Double {
        sqrt(x * x + y * y + z * z)
    }
    
    public var normalized: Vector3D {
        let mag = magnitude
        guard mag > 0 else { return Vector3D(x: 0, y: 0, z: 0) }
        return Vector3D(x: x / mag, y: y / mag, z: z / mag)
    }
    
    public func dotProduct(with other: Vector3D) -> Double {
        return x * other.x + y * other.y + z * other.z
    }
    
    public func crossProduct(with other: Vector3D) -> Vector3D {
        return Vector3D(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }
}

/// Accelerometer data
public struct AccelerometerData: Sendable, Codable {
    public let acceleration: Vector3D
    public let timestamp: Date
    
    public init(acceleration: Vector3D) {
        self.acceleration = acceleration
        self.timestamp = Date()
    }
    
    public init(x: Double, y: Double, z: Double) {
        self.acceleration = Vector3D(x: x, y: y, z: z)
        self.timestamp = Date()
    }
}

/// Gyroscope data
public struct GyroscopeData: Sendable, Codable {
    public let rotationRate: Vector3D
    public let timestamp: Date
    
    public init(rotationRate: Vector3D) {
        self.rotationRate = rotationRate
        self.timestamp = Date()
    }
    
    public init(x: Double, y: Double, z: Double) {
        self.rotationRate = Vector3D(x: x, y: y, z: z)
        self.timestamp = Date()
    }
}

/// Magnetometer data
public struct MagnetometerData: Sendable, Codable {
    public let magneticField: Vector3D
    public let timestamp: Date
    
    public init(magneticField: Vector3D) {
        self.magneticField = magneticField
        self.timestamp = Date()
    }
    
    public init(x: Double, y: Double, z: Double) {
        self.magneticField = Vector3D(x: x, y: y, z: z)
        self.timestamp = Date()
    }
}

/// Device attitude data
public struct AttitudeData: Sendable, Codable {
    public let roll: Double      // Rotation around X-axis (radians)
    public let pitch: Double     // Rotation around Y-axis (radians)
    public let yaw: Double       // Rotation around Z-axis (radians)
    public let quaternion: Quaternion
    public let rotationMatrix: RotationMatrix
    public let timestamp: Date
    
    public init(roll: Double, pitch: Double, yaw: Double, quaternion: Quaternion, rotationMatrix: RotationMatrix) {
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
        self.quaternion = quaternion
        self.rotationMatrix = rotationMatrix
        self.timestamp = Date()
    }
}

/// Quaternion representation
public struct Quaternion: Sendable, Codable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let w: Double
    
    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

/// Rotation matrix
public struct RotationMatrix: Sendable, Codable {
    public let m11: Double
    public let m12: Double
    public let m13: Double
    public let m21: Double
    public let m22: Double
    public let m23: Double
    public let m31: Double
    public let m32: Double
    public let m33: Double
    
    public init(m11: Double, m12: Double, m13: Double,
                m21: Double, m22: Double, m23: Double,
                m31: Double, m32: Double, m33: Double) {
        self.m11 = m11; self.m12 = m12; self.m13 = m13
        self.m21 = m21; self.m22 = m22; self.m23 = m23
        self.m31 = m31; self.m32 = m32; self.m33 = m33
    }
}

/// Magnetic field data with calibration
public struct MagneticFieldData: Sendable, Codable {
    public let field: Vector3D
    public let accuracy: CalibrationType
    public let timestamp: Date
    
    public enum CalibrationType: String, Sendable, Codable, CaseIterable {
        case uncalibrated = "uncalibrated"
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
    
    public init(field: Vector3D, accuracy: CalibrationType) {
        self.field = field
        self.accuracy = accuracy
        self.timestamp = Date()
    }
}

/// Motion events and gestures
public struct MotionEvent: Sendable, Identifiable {
    public let id: UUID
    public let type: MotionEventType
    public let intensity: Double
    public let direction: Vector3D?
    public let duration: TimeInterval
    public let timestamp: Date
    public let confidence: Double
    public let metadata: [String: String]
    
    public enum MotionEventType: String, Sendable, Codable, CaseIterable {
        case shake = "shake"
        case tilt = "tilt"
        case rotation = "rotation"
        case tap = "tap"
        case freefall = "freefall"
        case impact = "impact"
        case walking = "walking"
        case running = "running"
        case stationary = "stationary"
        case vehicle = "vehicle"
        case custom = "custom"
    }
    
    public init(
        type: MotionEventType,
        intensity: Double,
        direction: Vector3D? = nil,
        duration: TimeInterval = 0,
        confidence: Double = 1.0,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.intensity = intensity
        self.direction = direction
        self.duration = duration
        self.timestamp = Date()
        self.confidence = confidence
        self.metadata = metadata
    }
}

/// Device orientation
public enum DeviceOrientation: String, Sendable, Codable, CaseIterable {
    case unknown = "unknown"
    case portrait = "portrait"
    case portraitUpsideDown = "portrait-upside-down"
    case landscapeLeft = "landscape-left"
    case landscapeRight = "landscape-right"
    case faceUp = "face-up"
    case faceDown = "face-down"
}

/// Step counting data
public struct StepData: Sendable, Codable {
    public let stepCount: Int
    public let startDate: Date
    public let endDate: Date
    public let distance: Double? // in meters
    public let averagePace: Double? // steps per second
    public let floorsAscended: Int?
    public let floorsDescended: Int?
    
    public init(
        stepCount: Int,
        startDate: Date,
        endDate: Date,
        distance: Double? = nil,
        averagePace: Double? = nil,
        floorsAscended: Int? = nil,
        floorsDescended: Int? = nil
    ) {
        self.stepCount = stepCount
        self.startDate = startDate
        self.endDate = endDate
        self.distance = distance
        self.averagePace = averagePace
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
    }
    
    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    public var stepsPerMinute: Double {
        duration > 0 ? Double(stepCount) / (duration / 60.0) : 0
    }
}

/// Motion metrics
public struct MotionMetrics: Sendable {
    public let totalMotionEvents: Int
    public let shakeEvents: Int
    public let tiltEvents: Int
    public let rotationEvents: Int
    public let averageAcceleration: Double
    public let maxAcceleration: Double
    public let averageRotationRate: Double
    public let maxRotationRate: Double
    public let orientationChanges: Int
    public let stepsCounted: Int
    public let distanceTraveled: Double
    public let activeTimePercentage: Double
    public let calibrationQuality: Double
    public let sensorAvailability: [String: Bool]
    
    public init(
        totalMotionEvents: Int = 0,
        shakeEvents: Int = 0,
        tiltEvents: Int = 0,
        rotationEvents: Int = 0,
        averageAcceleration: Double = 0,
        maxAcceleration: Double = 0,
        averageRotationRate: Double = 0,
        maxRotationRate: Double = 0,
        orientationChanges: Int = 0,
        stepsCounted: Int = 0,
        distanceTraveled: Double = 0,
        activeTimePercentage: Double = 0,
        calibrationQuality: Double = 0,
        sensorAvailability: [String: Bool] = [:]
    ) {
        self.totalMotionEvents = totalMotionEvents
        self.shakeEvents = shakeEvents
        self.tiltEvents = tiltEvents
        self.rotationEvents = rotationEvents
        self.averageAcceleration = averageAcceleration
        self.maxAcceleration = maxAcceleration
        self.averageRotationRate = averageRotationRate
        self.maxRotationRate = maxRotationRate
        self.orientationChanges = orientationChanges
        self.stepsCounted = stepsCounted
        self.distanceTraveled = distanceTraveled
        self.activeTimePercentage = activeTimePercentage
        self.calibrationQuality = calibrationQuality
        self.sensorAvailability = sensorAvailability
    }
}

// MARK: - Device Motion Resource

/// Device motion resource management
public actor DeviceMotionCapabilityResource: AxiomCapabilityResource {
    private let configuration: DeviceMotionCapabilityConfiguration
    private let motionManager: CMMotionManager
    private let pedometer: CMPedometer?
    private let altimeter: CMAltimeter?
    private var motionHistory: [DeviceMotionData] = []
    private var stepHistory: [StepData] = []
    private var motionEvents: [MotionEvent] = []
    private var metrics: MotionMetrics = MotionMetrics()
    private var currentOrientation: DeviceOrientation = .unknown
    private var lastShakeTime: Date?
    private var motionDataStreamContinuation: AsyncStream<DeviceMotionData>.Continuation?
    private var motionEventStreamContinuation: AsyncStream<MotionEvent>.Continuation?
    private var orientationStreamContinuation: AsyncStream<DeviceOrientation>.Continuation?
    private var stepCountStreamContinuation: AsyncStream<StepData>.Continuation?
    
    // Motion detection state
    private var accelerationBuffer: [Vector3D] = []
    private var rotationBuffer: [Vector3D] = []
    private let bufferSize = 10
    
    public init(configuration: DeviceMotionCapabilityConfiguration) {
        self.configuration = configuration
        self.motionManager = CMMotionManager()
        self.pedometer = CMPedometer.isStepCountingAvailable() ? CMPedometer() : nil
        self.altimeter = CMAltimeter.isRelativeAltitudeAvailable() ? CMAltimeter() : nil
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 20_000_000, // 20MB for motion data and processing
            cpu: 3.0, // Motion processing and analysis
            bandwidth: 0,
            storage: 5_000_000 // 5MB for motion history
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historyMemory = motionHistory.count * 2_000
            let eventsMemory = motionEvents.count * 500
            let isActive = motionManager.isDeviceMotionActive
            
            return ResourceUsage(
                memory: historyMemory + eventsMemory + 1_000_000,
                cpu: isActive ? 2.0 : 0.1,
                bandwidth: 0,
                storage: (motionHistory.count + stepHistory.count) * 1_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        return motionManager.isDeviceMotionAvailable ||
               motionManager.isAccelerometerAvailable ||
               motionManager.isGyroAvailable ||
               motionManager.isMagnetometerAvailable
    }
    
    public func release() async {
        stopAllMotionUpdates()
        
        motionHistory.removeAll()
        stepHistory.removeAll()
        motionEvents.removeAll()
        accelerationBuffer.removeAll()
        rotationBuffer.removeAll()
        
        motionDataStreamContinuation?.finish()
        motionEventStreamContinuation?.finish()
        orientationStreamContinuation?.finish()
        stepCountStreamContinuation?.finish()
        
        metrics = MotionMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Configure motion manager
        motionManager.deviceMotionUpdateInterval = configuration.updateInterval
        motionManager.accelerometerUpdateInterval = configuration.accelerometerUpdateInterval
        motionManager.gyroUpdateInterval = configuration.gyroscopeUpdateInterval
        motionManager.magnetometerUpdateInterval = configuration.magnetometerUpdateInterval
        
        // Start motion updates
        await startMotionUpdates()
        
        // Start step counting if available and enabled
        if configuration.enableStepCounting {
            await startStepCounting()
        }
        
        // Initialize sensor availability metrics
        await updateSensorAvailability()
    }
    
    internal func updateConfiguration(_ configuration: DeviceMotionCapabilityConfiguration) async throws {
        // Update intervals if they changed
        if configuration.updateInterval != self.configuration.updateInterval {
            motionManager.deviceMotionUpdateInterval = configuration.updateInterval
        }
        
        // Restart updates if necessary
        if !motionManager.isDeviceMotionActive && 
           (configuration.enableDeviceMotion || configuration.enableAccelerometer || configuration.enableGyroscope) {
            await startMotionUpdates()
        }
    }
    
    // MARK: - Motion Streams
    
    public var motionDataStream: AsyncStream<DeviceMotionData> {
        AsyncStream { continuation in
            self.motionDataStreamContinuation = continuation
        }
    }
    
    public var motionEventStream: AsyncStream<MotionEvent> {
        AsyncStream { continuation in
            self.motionEventStreamContinuation = continuation
        }
    }
    
    public var orientationStream: AsyncStream<DeviceOrientation> {
        AsyncStream { continuation in
            self.orientationStreamContinuation = continuation
        }
    }
    
    public var stepCountStream: AsyncStream<StepData> {
        AsyncStream { continuation in
            self.stepCountStreamContinuation = continuation
        }
    }
    
    // MARK: - Motion Data Access
    
    public func getCurrentMotionData() async -> DeviceMotionData? {
        return motionHistory.last
    }
    
    public func getMotionHistory(since: Date? = nil, limit: Int? = nil) async -> [DeviceMotionData] {
        var filtered = motionHistory
        
        if let since = since {
            filtered = filtered.filter { $0.timestamp >= since }
        }
        
        if let limit = limit {
            filtered = Array(filtered.suffix(limit))
        }
        
        return filtered
    }
    
    public func getMotionEvents(since: Date? = nil) async -> [MotionEvent] {
        if let since = since {
            return motionEvents.filter { $0.timestamp >= since }
        }
        return motionEvents
    }
    
    public func getCurrentOrientation() async -> DeviceOrientation {
        return currentOrientation
    }
    
    public func getStepData(for date: Date) async -> StepData? {
        return stepHistory.first { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
    }
    
    public func getStepHistory(since: Date? = nil) async -> [StepData] {
        if let since = since {
            return stepHistory.filter { $0.startDate >= since }
        }
        return stepHistory
    }
    
    // MARK: - Sensor Availability
    
    public func getSensorAvailability() async -> [String: Bool] {
        return [
            "accelerometer": motionManager.isAccelerometerAvailable,
            "gyroscope": motionManager.isGyroAvailable,
            "magnetometer": motionManager.isMagnetometerAvailable,
            "deviceMotion": motionManager.isDeviceMotionAvailable,
            "pedometer": CMPedometer.isStepCountingAvailable(),
            "altimeter": CMAltimeter.isRelativeAltitudeAvailable(),
            "floorCounting": CMPedometer.isFloorCountingAvailable(),
            "distanceAvailable": CMPedometer.isDistanceAvailable(),
            "paceAvailable": CMPedometer.isPaceAvailable(),
            "cadenceAvailable": CMPedometer.isCadenceAvailable()
        ]
    }
    
    // MARK: - Calibration
    
    public func startMagnetometerCalibration() async -> Bool {
        guard motionManager.isMagnetometerAvailable else { return false }
        
        // Start magnetometer updates to encourage calibration
        if !motionManager.isMagnetometerActive {
            motionManager.startMagnetometerUpdates()
        }
        
        return true
    }
    
    public func getMagnetometerCalibrationAccuracy() async -> MagneticFieldData.CalibrationType {
        // This would typically be obtained from the magnetometer data
        // For now, return a default value
        return .medium
    }
    
    // MARK: - Gesture Recognition
    
    public func enableCustomGestureRecognition(_ gestureHandler: @escaping (MotionEvent) -> Void) async {
        // Custom gesture recognition would be implemented here
        // This is a simplified placeholder
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> MotionMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = MotionMetrics()
    }
    
    // MARK: - Private Methods
    
    private func startMotionUpdates() async {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        // Start device motion updates
        if configuration.enableDeviceMotion && motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: operationQueue) { [weak self] (motion, error) in
                Task { [weak self] in
                    await self?.handleDeviceMotionUpdate(motion: motion, error: error)
                }
            }
        }
        
        // Start accelerometer updates
        if configuration.enableAccelerometer && motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] (data, error) in
                Task { [weak self] in
                    await self?.handleAccelerometerUpdate(data: data, error: error)
                }
            }
        }
        
        // Start gyroscope updates
        if configuration.enableGyroscope && motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: operationQueue) { [weak self] (data, error) in
                Task { [weak self] in
                    await self?.handleGyroscopeUpdate(data: data, error: error)
                }
            }
        }
        
        // Start magnetometer updates
        if configuration.enableMagnetometer && motionManager.isMagnetometerAvailable {
            motionManager.startMagnetometerUpdates(to: operationQueue) { [weak self] (data, error) in
                Task { [weak self] in
                    await self?.handleMagnetometerUpdate(data: data, error: error)
                }
            }
        }
    }
    
    private func startStepCounting() async {
        guard let pedometer = pedometer, CMPedometer.isStepCountingAvailable() else { return }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        
        pedometer.startUpdates(from: startDate) { [weak self] (data, error) in
            Task { [weak self] in
                await self?.handlePedometerUpdate(data: data, error: error)
            }
        }
    }
    
    private func stopAllMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        pedometer?.stopUpdates()
    }
    
    private func handleDeviceMotionUpdate(motion: CMDeviceMotion?, error: Error?) async {
        guard let motion = motion, error == nil else {
            if configuration.enableLogging, let error = error {
                print("[Motion] ⚠️ Device motion error: \(error)")
            }
            return
        }
        
        let accelerometer = AccelerometerData(
            x: motion.userAcceleration.x,
            y: motion.userAcceleration.y,
            z: motion.userAcceleration.z
        )
        
        let gyroscope = GyroscopeData(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        )
        
        let magnetometer = MagnetometerData(
            x: motion.magneticField.field.x,
            y: motion.magneticField.field.y,
            z: motion.magneticField.field.z
        )
        
        let attitude = AttitudeData(
            roll: motion.attitude.roll,
            pitch: motion.attitude.pitch,
            yaw: motion.attitude.yaw,
            quaternion: Quaternion(
                x: motion.attitude.quaternion.x,
                y: motion.attitude.quaternion.y,
                z: motion.attitude.quaternion.z,
                w: motion.attitude.quaternion.w
            ),
            rotationMatrix: RotationMatrix(
                m11: motion.attitude.rotationMatrix.m11,
                m12: motion.attitude.rotationMatrix.m12,
                m13: motion.attitude.rotationMatrix.m13,
                m21: motion.attitude.rotationMatrix.m21,
                m22: motion.attitude.rotationMatrix.m22,
                m23: motion.attitude.rotationMatrix.m23,
                m31: motion.attitude.rotationMatrix.m31,
                m32: motion.attitude.rotationMatrix.m32,
                m33: motion.attitude.rotationMatrix.m33
            )
        )
        
        let gravity = Vector3D(
            x: motion.gravity.x,
            y: motion.gravity.y,
            z: motion.gravity.z
        )
        
        let userAcceleration = Vector3D(
            x: motion.userAcceleration.x,
            y: motion.userAcceleration.y,
            z: motion.userAcceleration.z
        )
        
        let rotationRate = Vector3D(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        )
        
        let magneticFieldAccuracy: MagneticFieldData.CalibrationType
        switch motion.magneticField.accuracy {
        case .uncalibrated:
            magneticFieldAccuracy = .uncalibrated
        case .low:
            magneticFieldAccuracy = .low
        case .medium:
            magneticFieldAccuracy = .medium
        case .high:
            magneticFieldAccuracy = .high
        @unknown default:
            magneticFieldAccuracy = .uncalibrated
        }
        
        let magneticField = MagneticFieldData(
            field: Vector3D(
                x: motion.magneticField.field.x,
                y: motion.magneticField.field.y,
                z: motion.magneticField.field.z
            ),
            accuracy: magneticFieldAccuracy
        )
        
        let motionData = DeviceMotionData(
            accelerometer: accelerometer,
            gyroscope: gyroscope,
            magnetometer: magnetometer,
            attitude: attitude,
            gravity: gravity,
            userAcceleration: userAcceleration,
            rotationRate: rotationRate,
            magneticField: magneticField
        )
        
        await processMotionData(motionData)
    }
    
    private func handleAccelerometerUpdate(data: CMAccelerometerData?, error: Error?) async {
        guard let data = data, error == nil else { return }
        
        let accelerometer = AccelerometerData(
            x: data.acceleration.x,
            y: data.acceleration.y,
            z: data.acceleration.z
        )
        
        let motionData = DeviceMotionData(accelerometer: accelerometer)
        await processMotionData(motionData)
    }
    
    private func handleGyroscopeUpdate(data: CMGyroData?, error: Error?) async {
        guard let data = data, error == nil else { return }
        
        let gyroscope = GyroscopeData(
            x: data.rotationRate.x,
            y: data.rotationRate.y,
            z: data.rotationRate.z
        )
        
        let motionData = DeviceMotionData(gyroscope: gyroscope)
        await processMotionData(motionData)
    }
    
    private func handleMagnetometerUpdate(data: CMMagnetometerData?, error: Error?) async {
        guard let data = data, error == nil else { return }
        
        let magnetometer = MagnetometerData(
            x: data.magneticField.x,
            y: data.magneticField.y,
            z: data.magneticField.z
        )
        
        let motionData = DeviceMotionData(magnetometer: magnetometer)
        await processMotionData(motionData)
    }
    
    private func handlePedometerUpdate(data: CMPedometerData?, error: Error?) async {
        guard let data = data, error == nil else { return }
        
        let stepData = StepData(
            stepCount: data.numberOfSteps.intValue,
            startDate: data.startDate,
            endDate: data.endDate,
            distance: data.distance?.doubleValue,
            averagePace: data.averageActivePace?.doubleValue,
            floorsAscended: data.floorsAscended?.intValue,
            floorsDescended: data.floorsDescended?.intValue
        )
        
        stepHistory.append(stepData)
        await trimStepHistory()
        
        stepCountStreamContinuation?.yield(stepData)
        
        await updateStepMetrics(stepData)
        
        if configuration.enableLogging {
            print("[Motion] 👣 Steps: \(stepData.stepCount), Distance: \(stepData.distance ?? 0)m")
        }
    }
    
    private func processMotionData(_ motionData: DeviceMotionData) async {
        // Add to history
        motionHistory.append(motionData)
        await trimMotionHistory()
        
        // Update buffers for motion detection
        if let acceleration = motionData.userAcceleration {
            accelerationBuffer.append(acceleration)
            if accelerationBuffer.count > bufferSize {
                accelerationBuffer.removeFirst()
            }
        }
        
        if let rotation = motionData.rotationRate {
            rotationBuffer.append(rotation)
            if rotationBuffer.count > bufferSize {
                rotationBuffer.removeFirst()
            }
        }
        
        // Detect motion events
        await detectMotionEvents(from: motionData)
        
        // Update orientation
        await updateOrientation(from: motionData)
        
        // Update metrics
        await updateMotionMetrics(motionData)
        
        // Emit motion data
        motionDataStreamContinuation?.yield(motionData)
        
        if configuration.enableLogging {
            await logMotionData(motionData)
        }
    }
    
    private func detectMotionEvents(from motionData: DeviceMotionData) async {
        // Shake detection
        if configuration.enableShakeDetection {
            await detectShake(from: motionData)
        }
        
        // Motion detection
        if configuration.enableMotionDetection {
            await detectGeneralMotion(from: motionData)
        }
        
        // Gesture recognition
        if configuration.enableGestureRecognition {
            await recognizeGestures(from: motionData)
        }
    }
    
    private func detectShake(from motionData: DeviceMotionData) async {
        guard let acceleration = motionData.userAcceleration else { return }
        
        let magnitude = acceleration.magnitude
        
        if magnitude > configuration.shakeThreshold {
            // Debounce shake events
            if let lastShake = lastShakeTime, Date().timeIntervalSince(lastShake) < 1.0 {
                return
            }
            
            let shakeEvent = MotionEvent(
                type: .shake,
                intensity: magnitude,
                direction: acceleration.normalized,
                confidence: min(1.0, magnitude / (configuration.shakeThreshold * 2))
            )
            
            motionEvents.append(shakeEvent)
            motionEventStreamContinuation?.yield(shakeEvent)
            lastShakeTime = Date()
            
            if configuration.enableLogging {
                print("[Motion] 📳 Shake detected: intensity \(String(format: "%.2f", magnitude))")
            }
        }
    }
    
    private func detectGeneralMotion(from motionData: DeviceMotionData) async {
        guard let acceleration = motionData.userAcceleration else { return }
        
        let magnitude = acceleration.magnitude
        
        if magnitude > configuration.motionThreshold {
            // Classify motion type based on patterns
            let motionType: MotionEvent.MotionEventType
            
            if magnitude > 2.0 {
                motionType = .impact
            } else if magnitude > 1.0 {
                motionType = .walking
            } else {
                motionType = .tilt
            }
            
            let motionEvent = MotionEvent(
                type: motionType,
                intensity: magnitude,
                direction: acceleration.normalized,
                confidence: 0.8
            )
            
            motionEvents.append(motionEvent)
            motionEventStreamContinuation?.yield(motionEvent)
        }
    }
    
    private func recognizeGestures(from motionData: DeviceMotionData) async {
        // Simplified gesture recognition
        // In a real implementation, this would use more sophisticated algorithms
        
        guard let rotation = motionData.rotationRate else { return }
        
        let rotationMagnitude = rotation.magnitude
        
        if rotationMagnitude > 3.0 {
            let rotationEvent = MotionEvent(
                type: .rotation,
                intensity: rotationMagnitude,
                direction: rotation.normalized,
                confidence: 0.7
            )
            
            motionEvents.append(rotationEvent)
            motionEventStreamContinuation?.yield(rotationEvent)
        }
    }
    
    private func updateOrientation(from motionData: DeviceMotionData) async {
        guard let attitude = motionData.attitude else { return }
        
        let newOrientation: DeviceOrientation
        
        // Simple orientation detection based on roll and pitch
        let roll = abs(attitude.roll)
        let pitch = abs(attitude.pitch)
        
        if roll < 0.5 && pitch < 0.5 {
            newOrientation = .portrait
        } else if roll > 1.5 {
            newOrientation = attitude.roll > 0 ? .landscapeLeft : .landscapeRight
        } else if pitch > 1.5 {
            newOrientation = attitude.pitch > 0 ? .faceDown : .faceUp
        } else {
            newOrientation = .unknown
        }
        
        if newOrientation != currentOrientation {
            currentOrientation = newOrientation
            orientationStreamContinuation?.yield(newOrientation)
            
            if configuration.enableLogging {
                print("[Motion] 📱 Orientation changed: \(newOrientation.rawValue)")
            }
        }
    }
    
    private func updateMotionMetrics(_ motionData: DeviceMotionData) async {
        var totalEvents = metrics.totalMotionEvents
        var shakeEvents = metrics.shakeEvents
        var tiltEvents = metrics.tiltEvents
        var rotationEvents = metrics.rotationEvents
        var avgAcceleration = metrics.averageAcceleration
        var maxAcceleration = metrics.maxAcceleration
        var avgRotation = metrics.averageRotationRate
        var maxRotation = metrics.maxRotationRate
        
        if let acceleration = motionData.userAcceleration {
            let magnitude = acceleration.magnitude
            avgAcceleration = (avgAcceleration * Double(totalEvents) + magnitude) / Double(totalEvents + 1)
            maxAcceleration = max(maxAcceleration, magnitude)
            totalEvents += 1
        }
        
        if let rotation = motionData.rotationRate {
            let magnitude = rotation.magnitude
            avgRotation = (avgRotation * Double(totalEvents) + magnitude) / Double(totalEvents + 1)
            maxRotation = max(maxRotation, magnitude)
        }
        
        // Count motion events by type
        let recentEvents = motionEvents.filter { Date().timeIntervalSince($0.timestamp) < 3600 } // Last hour
        shakeEvents = recentEvents.filter { $0.type == .shake }.count
        tiltEvents = recentEvents.filter { $0.type == .tilt }.count
        rotationEvents = recentEvents.filter { $0.type == .rotation }.count
        
        metrics = MotionMetrics(
            totalMotionEvents: totalEvents,
            shakeEvents: shakeEvents,
            tiltEvents: tiltEvents,
            rotationEvents: rotationEvents,
            averageAcceleration: avgAcceleration,
            maxAcceleration: maxAcceleration,
            averageRotationRate: avgRotation,
            maxRotationRate: maxRotation,
            orientationChanges: metrics.orientationChanges,
            stepsCounted: metrics.stepsCounted,
            distanceTraveled: metrics.distanceTraveled,
            activeTimePercentage: metrics.activeTimePercentage,
            calibrationQuality: metrics.calibrationQuality,
            sensorAvailability: metrics.sensorAvailability
        )
    }
    
    private func updateStepMetrics(_ stepData: StepData) async {
        metrics = MotionMetrics(
            totalMotionEvents: metrics.totalMotionEvents,
            shakeEvents: metrics.shakeEvents,
            tiltEvents: metrics.tiltEvents,
            rotationEvents: metrics.rotationEvents,
            averageAcceleration: metrics.averageAcceleration,
            maxAcceleration: metrics.maxAcceleration,
            averageRotationRate: metrics.averageRotationRate,
            maxRotationRate: metrics.maxRotationRate,
            orientationChanges: metrics.orientationChanges,
            stepsCounted: stepData.stepCount,
            distanceTraveled: stepData.distance ?? metrics.distanceTraveled,
            activeTimePercentage: metrics.activeTimePercentage,
            calibrationQuality: metrics.calibrationQuality,
            sensorAvailability: metrics.sensorAvailability
        )
    }
    
    private func updateSensorAvailability() async {
        let availability = await getSensorAvailability()
        
        metrics = MotionMetrics(
            totalMotionEvents: metrics.totalMotionEvents,
            shakeEvents: metrics.shakeEvents,
            tiltEvents: metrics.tiltEvents,
            rotationEvents: metrics.rotationEvents,
            averageAcceleration: metrics.averageAcceleration,
            maxAcceleration: metrics.maxAcceleration,
            averageRotationRate: metrics.averageRotationRate,
            maxRotationRate: metrics.maxRotationRate,
            orientationChanges: metrics.orientationChanges,
            stepsCounted: metrics.stepsCounted,
            distanceTraveled: metrics.distanceTraveled,
            activeTimePercentage: metrics.activeTimePercentage,
            calibrationQuality: metrics.calibrationQuality,
            sensorAvailability: availability
        )
    }
    
    private func trimMotionHistory() async {
        if motionHistory.count > configuration.maxHistorySize {
            motionHistory = Array(motionHistory.suffix(configuration.maxHistorySize))
        }
        
        // Remove entries older than 24 hours
        let dayAgo = Date().addingTimeInterval(-86400)
        motionHistory.removeAll { $0.timestamp < dayAgo }
    }
    
    private func trimStepHistory() async {
        // Keep only last 30 days of step data
        let monthAgo = Date().addingTimeInterval(-2_592_000)
        stepHistory.removeAll { $0.startDate < monthAgo }
    }
    
    private func logMotionData(_ motionData: DeviceMotionData) async {
        if let acceleration = motionData.userAcceleration {
            let magnitude = acceleration.magnitude
            if magnitude > 0.1 {
                print("[Motion] 📱 Acceleration: \(String(format: "%.3f", magnitude))g")
            }
        }
        
        if let rotation = motionData.rotationRate {
            let magnitude = rotation.magnitude
            if magnitude > 0.5 {
                print("[Motion] 🌀 Rotation: \(String(format: "%.3f", magnitude)) rad/s")
            }
        }
    }
}

// MARK: - Device Motion Capability Implementation

/// Device Motion capability providing comprehensive motion sensing and analysis
public actor DeviceMotionCapability: DomainCapability {
    public typealias ConfigurationType = DeviceMotionCapabilityConfiguration
    public typealias ResourceType = DeviceMotionCapabilityResource
    
    private var _configuration: DeviceMotionCapabilityConfiguration
    private var _resources: DeviceMotionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "device-motion-capability" }
    
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
    
    public var configuration: DeviceMotionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: DeviceMotionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: DeviceMotionCapabilityConfiguration = DeviceMotionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = DeviceMotionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: DeviceMotionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Device Motion configuration")
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
        return await _resources.isAvailable()
    }
    
    public func requestPermission() async throws {
        // Device motion doesn't require special permissions on iOS
        // Motion & Fitness permission is handled automatically by Core Motion
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Motion Data Operations
    
    /// Get current motion data
    public func getCurrentMotionData() async throws -> DeviceMotionData? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getCurrentMotionData()
    }
    
    /// Get motion data stream
    public func getMotionDataStream() async throws -> AsyncStream<DeviceMotionData> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.motionDataStream
    }
    
    /// Get motion history
    public func getMotionHistory(since: Date? = nil, limit: Int? = nil) async throws -> [DeviceMotionData] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getMotionHistory(since: since, limit: limit)
    }
    
    /// Get motion events
    public func getMotionEvents(since: Date? = nil) async throws -> [MotionEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getMotionEvents(since: since)
    }
    
    /// Get motion event stream
    public func getMotionEventStream() async throws -> AsyncStream<MotionEvent> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.motionEventStream
    }
    
    /// Get current device orientation
    public func getCurrentOrientation() async throws -> DeviceOrientation {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getCurrentOrientation()
    }
    
    /// Get orientation stream
    public func getOrientationStream() async throws -> AsyncStream<DeviceOrientation> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.orientationStream
    }
    
    /// Get step data for specific date
    public func getStepData(for date: Date) async throws -> StepData? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getStepData(for: date)
    }
    
    /// Get step history
    public func getStepHistory(since: Date? = nil) async throws -> [StepData] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getStepHistory(since: since)
    }
    
    /// Get step count stream
    public func getStepCountStream() async throws -> AsyncStream<StepData> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.stepCountStream
    }
    
    /// Get sensor availability
    public func getSensorAvailability() async throws -> [String: Bool] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getSensorAvailability()
    }
    
    /// Start magnetometer calibration
    public func startMagnetometerCalibration() async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.startMagnetometerCalibration()
    }
    
    /// Get magnetometer calibration accuracy
    public func getMagnetometerCalibrationAccuracy() async throws -> MagneticFieldData.CalibrationType {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getMagnetometerCalibrationAccuracy()
    }
    
    /// Get motion metrics
    public func getMetrics() async throws -> MotionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Device Motion capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if device is currently moving
    public func isDeviceMoving() async throws -> Bool {
        guard let motionData = try await getCurrentMotionData() else { return false }
        
        if let acceleration = motionData.userAcceleration {
            return acceleration.magnitude > _configuration.motionThreshold
        }
        
        return false
    }
    
    /// Get current acceleration magnitude
    public func getCurrentAccelerationMagnitude() async throws -> Double {
        guard let motionData = try await getCurrentMotionData() else { return 0 }
        return motionData.userAcceleration?.magnitude ?? 0
    }
    
    /// Get current rotation rate magnitude
    public func getCurrentRotationMagnitude() async throws -> Double {
        guard let motionData = try await getCurrentMotionData() else { return 0 }
        return motionData.rotationRate?.magnitude ?? 0
    }
    
    /// Get today's step count
    public func getTodaysStepCount() async throws -> Int {
        let today = Date()
        let stepData = try await getStepData(for: today)
        return stepData?.stepCount ?? 0
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Device Motion specific errors
public enum DeviceMotionError: Error, LocalizedError {
    case sensorUnavailable(String)
    case updateIntervalTooSmall(TimeInterval)
    case calibrationRequired
    case permissionDenied
    case hardwareNotSupported
    case motionDataCorrupted
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .sensorUnavailable(let sensor):
            return "\(sensor) sensor is not available"
        case .updateIntervalTooSmall(let interval):
            return "Update interval too small: \(interval)s"
        case .calibrationRequired:
            return "Sensor calibration required"
        case .permissionDenied:
            return "Motion & Fitness permission denied"
        case .hardwareNotSupported:
            return "Motion hardware not supported on this device"
        case .motionDataCorrupted:
            return "Motion data is corrupted or invalid"
        case .configurationError(let reason):
            return "Device motion configuration error: \(reason)"
        }
    }
}