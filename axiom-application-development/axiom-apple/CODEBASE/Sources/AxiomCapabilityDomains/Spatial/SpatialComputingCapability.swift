import Foundation
import AxiomCapabilities
import AxiomCore
import simd

#if os(visionOS)
import RealityKit
import ARKit
import AVFAudio
import SwiftUI
#endif

// MARK: - Spatial Computing Configuration

/// Configuration for spatial computing capability
public struct SpatialComputingConfiguration: AxiomCapabilityConfiguration {
    public let enableRealityKit: Bool
    public let enableHandTracking: Bool
    public let enableEyeTracking: Bool
    public let enableSpatialAudio: Bool
    public let maxEntities: Int
    public let spatialAudioRadius: Float
    public let handTrackingAccuracy: HandTrackingAccuracy
    public let immersiveSpaceStyle: ImmersiveSpaceStyle
    public let spatialInteractionRange: Float
    public let requestTimeout: TimeInterval
    
    public init(
        enableRealityKit: Bool = true,
        enableHandTracking: Bool = true,
        enableEyeTracking: Bool = false,
        enableSpatialAudio: Bool = true,
        maxEntities: Int = 1000,
        spatialAudioRadius: Float = 10.0,
        handTrackingAccuracy: HandTrackingAccuracy = .high,
        immersiveSpaceStyle: ImmersiveSpaceStyle = .mixed,
        spatialInteractionRange: Float = 2.0,
        requestTimeout: TimeInterval = 30.0
    ) {
        self.enableRealityKit = enableRealityKit
        self.enableHandTracking = enableHandTracking
        self.enableEyeTracking = enableEyeTracking
        self.enableSpatialAudio = enableSpatialAudio
        self.maxEntities = maxEntities
        self.spatialAudioRadius = spatialAudioRadius
        self.handTrackingAccuracy = handTrackingAccuracy
        self.immersiveSpaceStyle = immersiveSpaceStyle
        self.spatialInteractionRange = spatialInteractionRange
        self.requestTimeout = requestTimeout
    }
    
    public var isValid: Bool {
        return maxEntities > 0 &&
               spatialAudioRadius > 0 &&
               spatialInteractionRange > 0 &&
               requestTimeout > 0
    }
    
    public func merged(with other: SpatialComputingConfiguration) -> SpatialComputingConfiguration {
        return SpatialComputingConfiguration(
            enableRealityKit: other.enableRealityKit,
            enableHandTracking: other.enableHandTracking,
            enableEyeTracking: other.enableEyeTracking,
            enableSpatialAudio: other.enableSpatialAudio,
            maxEntities: other.maxEntities,
            spatialAudioRadius: other.spatialAudioRadius,
            handTrackingAccuracy: other.handTrackingAccuracy,
            immersiveSpaceStyle: other.immersiveSpaceStyle,
            spatialInteractionRange: other.spatialInteractionRange,
            requestTimeout: other.requestTimeout
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> SpatialComputingConfiguration {
        var adjustedMaxEntities = maxEntities
        var adjustedTimeout = requestTimeout
        var adjustedAccuracy = handTrackingAccuracy
        
        if environment.isLowPowerMode {
            adjustedMaxEntities = min(maxEntities, 500) // Reduce entity count
            adjustedTimeout *= 1.5
            adjustedAccuracy = .medium // Lower accuracy for better performance
        }
        
        if environment.isDebug {
            adjustedTimeout *= 2.0 // More lenient in debug
        }
        
        return SpatialComputingConfiguration(
            enableRealityKit: enableRealityKit,
            enableHandTracking: enableHandTracking,
            enableEyeTracking: enableEyeTracking,
            enableSpatialAudio: enableSpatialAudio,
            maxEntities: adjustedMaxEntities,
            spatialAudioRadius: spatialAudioRadius,
            handTrackingAccuracy: adjustedAccuracy,
            immersiveSpaceStyle: immersiveSpaceStyle,
            spatialInteractionRange: spatialInteractionRange,
            requestTimeout: adjustedTimeout
        )
    }
}

// MARK: - Spatial Computing Data Types

/// Hand tracking accuracy levels
public enum HandTrackingAccuracy: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    
    #if os(visionOS)
    var arkitConfiguration: ARHandTrackingConfiguration.TrackingMode {
        switch self {
        case .low:
            return .coarse
        case .medium:
            return .fine
        case .high:
            return .fine
        }
    }
    #endif
}

/// Immersive space styles
public enum ImmersiveSpaceStyle: String, Codable, CaseIterable, Sendable {
    case mixed
    case full
    case progressive
    
    #if os(visionOS)
    var swiftUIStyle: ImmersionStyle {
        switch self {
        case .mixed:
            return .mixed
        case .full:
            return .full
        case .progressive:
            return .progressive
        }
    }
    #endif
}

/// Spatial gesture types
public enum SpatialGesture: String, Codable, CaseIterable, Sendable {
    case tap
    case pinch
    case swipe
    case rotate
    case scale
    case longPress
    case drag
}

/// Hand tracking data
public struct HandTrackingData: Sendable, Codable {
    public let leftHand: HandData?
    public let rightHand: HandData?
    public let timestamp: Date
    
    public init(leftHand: HandData?, rightHand: HandData?, timestamp: Date = Date()) {
        self.leftHand = leftHand
        self.rightHand = rightHand
        self.timestamp = timestamp
    }
}

// MARK: - Codable Quaternion Wrapper

/// Codable wrapper for simd_quatf
public struct CodableQuaternion: Sendable, Codable {
    public let x: Float
    public let y: Float
    public let z: Float
    public let w: Float
    
    public init(_ quat: simd_quatf) {
        self.x = quat.vector.x
        self.y = quat.vector.y
        self.z = quat.vector.z
        self.w = quat.vector.w
    }
    
    public var quaternion: simd_quatf {
        return simd_quatf(vector: SIMD4<Float>(x, y, z, w))
    }
}

/// Individual hand data
public struct HandData: Sendable, Codable {
    public let isTracked: Bool
    public let confidence: Float
    public let position: SIMD3<Float>
    public let orientation: CodableQuaternion
    public let joints: [HandJoint]
    
    public init(
        isTracked: Bool,
        confidence: Float,
        position: SIMD3<Float>,
        orientation: simd_quatf,
        joints: [HandJoint] = []
    ) {
        self.isTracked = isTracked
        self.confidence = confidence
        self.position = position
        self.orientation = CodableQuaternion(orientation)
        self.joints = joints
    }
    
    /// Convenience property to get simd_quatf
    public var orientationQuaternion: simd_quatf {
        return orientation.quaternion
    }
}

/// Hand joint data
public struct HandJoint: Sendable, Codable {
    public let name: String
    public let position: SIMD3<Float>
    public let orientation: CodableQuaternion
    public let isTracked: Bool
    
    public init(name: String, position: SIMD3<Float>, orientation: simd_quatf, isTracked: Bool) {
        self.name = name
        self.position = position
        self.orientation = CodableQuaternion(orientation)
        self.isTracked = isTracked
    }
    
    /// Convenience property to get simd_quatf
    public var orientationQuaternion: simd_quatf {
        return orientation.quaternion
    }
}

/// Spatial interaction result
public struct SpatialInteraction: Sendable, Codable {
    public let gesture: SpatialGesture
    public let position: SIMD3<Float>
    public let entityId: String?
    public let timestamp: Date
    public let confidence: Float
    
    public init(
        gesture: SpatialGesture,
        position: SIMD3<Float>,
        entityId: String? = nil,
        timestamp: Date = Date(),
        confidence: Float = 1.0
    ) {
        self.gesture = gesture
        self.position = position
        self.entityId = entityId
        self.timestamp = timestamp
        self.confidence = confidence
    }
}

/// Spatial anchor data
public struct SpatialAnchor: Sendable, Codable, Identifiable {
    public let id: String
    public let position: SIMD3<Float>
    public let orientation: simd_quatf
    public let isTracked: Bool
    public let timestamp: Date
    
    public init(
        id: String = UUID().uuidString,
        position: SIMD3<Float>,
        orientation: simd_quatf,
        isTracked: Bool = true,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.position = position
        self.orientation = orientation
        self.isTracked = isTracked
        self.timestamp = timestamp
    }
}

/// Immersive space state
public enum ImmersiveSpaceState: String, Codable, CaseIterable, Sendable {
    case inactive
    case opening
    case open
    case closing
    case error
}

// MARK: - Spatial Computing Resource

/// Resource management for spatial computing
public actor SpatialComputingResource: AxiomCapabilityResource {
    private var isRealityKitActive: Bool = false
    private var isHandTrackingActive: Bool = false
    private var isSpatialAudioActive: Bool = false
    private var entityCount: Int = 0
    private var _isAvailable: Bool = true
    private let configuration: SpatialComputingConfiguration
    
    public init(configuration: SpatialComputingConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 512_000_000, // 512MB max for spatial computing
            cpu: 30.0, // 30% CPU max
            bandwidth: 10_000, // 10KB/s for spatial data
            storage: 100_000_000 // 100MB for spatial assets
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            var memory = 0
            var cpu = 0.0
            var bandwidth = 0
            
            if isRealityKitActive {
                memory += 200_000_000 // 200MB for RealityKit
                cpu += 15.0
                bandwidth += 5_000
            }
            
            if isHandTrackingActive {
                memory += 50_000_000 // 50MB for hand tracking
                cpu += 8.0
                bandwidth += 2_000
            }
            
            if isSpatialAudioActive {
                memory += 30_000_000 // 30MB for spatial audio
                cpu += 5.0
                bandwidth += 1_500
            }
            
            // Additional usage based on entity count
            memory += entityCount * 10_000 // 10KB per entity
            
            return ResourceUsage(
                memory: memory,
                cpu: cpu,
                bandwidth: bandwidth,
                storage: 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        #if os(visionOS)
        return _isAvailable
        #else
        return false
        #endif
    }
    
    public func release() async {
        isRealityKitActive = false
        isHandTrackingActive = false
        isSpatialAudioActive = false
        entityCount = 0
    }
    
    public func activateRealityKit() async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Spatial computing not available")
        }
        isRealityKitActive = true
    }
    
    public func activateHandTracking() async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Hand tracking not available")
        }
        isHandTrackingActive = true
    }
    
    public func activateSpatialAudio() async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Spatial audio not available")
        }
        isSpatialAudioActive = true
    }
    
    public func deactivateRealityKit() async {
        isRealityKitActive = false
    }
    
    public func deactivateHandTracking() async {
        isHandTrackingActive = false
    }
    
    public func deactivateSpatialAudio() async {
        isSpatialAudioActive = false
    }
    
    public func addEntity() async throws {
        guard entityCount < configuration.maxEntities else {
            throw AxiomCapabilityError.resourceAllocationFailed("Maximum entity count reached")
        }
        entityCount += 1
    }
    
    public func removeEntity() async {
        if entityCount > 0 {
            entityCount -= 1
        }
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
    
    public func getEntityCount() async -> Int {
        return entityCount
    }
}

// MARK: - Spatial Computing Capability

/// Spatial computing capability providing visionOS-specific functionality
public actor SpatialComputingCapability: DomainCapability {
    public typealias ConfigurationType = SpatialComputingConfiguration
    public typealias ResourceType = SpatialComputingResource
    
    private var _configuration: SpatialComputingConfiguration
    private var _resources: SpatialComputingResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    
    #if os(visionOS)
    private var realityKitSession: RealityKitSession?
    private var handTrackingProvider: HandTrackingProvider?
    private var spatialAudioEngine: AVAudioEngine?
    private var spatialAnchors: [String: ARAnchor] = [:]
    private var entities: [String: Entity] = [:]
    #endif
    
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    private var handTrackingStreamContinuation: AsyncStream<HandTrackingData>.Continuation?
    private var spatialInteractionStreamContinuation: AsyncStream<SpatialInteraction>.Continuation?
    private var immersiveSpaceState: ImmersiveSpaceState = .inactive
    
    public nonisolated var id: String { "spatial-computing-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStateStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: SpatialComputingConfiguration {
        get async { _configuration }
    }
    
    public var resources: SpatialComputingResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: SpatialComputingConfiguration = SpatialComputingConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = SpatialComputingResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStateStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    private func setHandTrackingStreamContinuation(_ continuation: AsyncStream<HandTrackingData>.Continuation) {
        self.handTrackingStreamContinuation = continuation
    }
    
    private func setSpatialInteractionStreamContinuation(_ continuation: AsyncStream<SpatialInteraction>.Continuation) {
        self.spatialInteractionStreamContinuation = continuation
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: SpatialComputingConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid spatial computing configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await updateSpatialSystems()
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public func isSupported() async -> Bool {
        #if os(visionOS)
        return true
        #else
        return false
        #endif
    }
    
    public func requestPermission() async throws {
        #if os(visionOS)
        // Request ARKit permissions if needed
        if _configuration.enableHandTracking {
            let status = await ARKitSession.queryAuthorization(for: [.handTracking])
            if status[.handTracking] != .allowed {
                throw AxiomCapabilityError.permissionRequired("Hand tracking permission required")
            }
        }
        #else
        throw AxiomCapabilityError.unavailable("Spatial computing only available on visionOS")
        #endif
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public func activate() async throws {
        guard await _resources.isAvailable() else {
            throw AxiomCapabilityError.initializationFailed("Spatial computing resources not available")
        }
        
        guard await isSupported() else {
            throw AxiomCapabilityError.unavailable("Spatial computing not supported on this platform")
        }
        
        try await requestPermission()
        try await setupSpatialSystems()
        
        await transitionTo(.available)
    }
    
    public func deactivate() async {
        await transitionTo(.unavailable)
        await teardownSpatialSystems()
        await _resources.release()
        
        stateStreamContinuation?.finish()
        handTrackingStreamContinuation?.finish()
        spatialInteractionStreamContinuation?.finish()
    }
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    private func setupSpatialSystems() async throws {
        #if os(visionOS)
        // Setup RealityKit
        if _configuration.enableRealityKit {
            try await setupRealityKit()
        }
        
        // Setup Hand Tracking
        if _configuration.enableHandTracking {
            try await setupHandTracking()
        }
        
        // Setup Spatial Audio
        if _configuration.enableSpatialAudio {
            try await setupSpatialAudio()
        }
        #endif
    }
    
    private func teardownSpatialSystems() async {
        #if os(visionOS)
        await _resources.deactivateRealityKit()
        await _resources.deactivateHandTracking()
        await _resources.deactivateSpatialAudio()
        
        realityKitSession = nil
        handTrackingProvider = nil
        spatialAudioEngine?.stop()
        spatialAudioEngine = nil
        spatialAnchors.removeAll()
        entities.removeAll()
        #endif
    }
    
    private func updateSpatialSystems() async throws {
        // Update systems based on new configuration
        #if os(visionOS)
        if _configuration.enableRealityKit && realityKitSession == nil {
            try await setupRealityKit()
        } else if !_configuration.enableRealityKit && realityKitSession != nil {
            await _resources.deactivateRealityKit()
            realityKitSession = nil
        }
        
        if _configuration.enableHandTracking && handTrackingProvider == nil {
            try await setupHandTracking()
        } else if !_configuration.enableHandTracking && handTrackingProvider != nil {
            await _resources.deactivateHandTracking()
            handTrackingProvider = nil
        }
        
        if _configuration.enableSpatialAudio && spatialAudioEngine == nil {
            try await setupSpatialAudio()
        } else if !_configuration.enableSpatialAudio && spatialAudioEngine != nil {
            await _resources.deactivateSpatialAudio()
            spatialAudioEngine?.stop()
            spatialAudioEngine = nil
        }
        #endif
    }
    
    #if os(visionOS)
    private func setupRealityKit() async throws {
        let session = RealityKitSession()
        try await _resources.activateRealityKit()
        self.realityKitSession = session
    }
    
    private func setupHandTracking() async throws {
        let provider = HandTrackingProvider()
        try await _resources.activateHandTracking()
        self.handTrackingProvider = provider
        
        // Start hand tracking updates
        Task {
            for await update in provider.anchorUpdates {
                await handleHandTrackingUpdate(update)
            }
        }
    }
    
    private func setupSpatialAudio() async throws {
        let engine = AVAudioEngine()
        try await _resources.activateSpatialAudio()
        self.spatialAudioEngine = engine
        
        // Configure spatial audio
        let mixer = engine.mainMixerNode
        mixer.outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 2,
            interleaved: false
        )!
        
        try engine.start()
    }
    
    private func handleHandTrackingUpdate(_ update: AnchorUpdate<HandAnchor>) async {
        // Convert ARKit hand tracking data to our format
        let handData = convertHandAnchorToHandData(update.anchor)
        
        // Determine which hand this is and create tracking data
        let trackingData = HandTrackingData(
            leftHand: update.anchor.chirality == .left ? handData : nil,
            rightHand: update.anchor.chirality == .right ? handData : nil
        )
        
        handTrackingStreamContinuation?.yield(trackingData)
        
        // Process gestures
        if let gesture = detectGesture(from: update.anchor) {
            let interaction = SpatialInteraction(
                gesture: gesture,
                position: SIMD3<Float>(update.anchor.originFromAnchorTransform.columns.3.x,
                                     update.anchor.originFromAnchorTransform.columns.3.y,
                                     update.anchor.originFromAnchorTransform.columns.3.z)
            )
            spatialInteractionStreamContinuation?.yield(interaction)
        }
    }
    
    private func convertHandAnchorToHandData(_ anchor: HandAnchor) -> HandData {
        let transform = anchor.originFromAnchorTransform
        let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let orientation = simd_quatf(transform)
        
        // Convert hand skeleton to joints
        let joints = anchor.handSkeleton?.allJoints.compactMap { joint in
            HandJoint(
                name: joint.name.rawValue,
                position: SIMD3<Float>(joint.anchorFromJointTransform.columns.3.x,
                                     joint.anchorFromJointTransform.columns.3.y,
                                     joint.anchorFromJointTransform.columns.3.z),
                orientation: simd_quatf(joint.anchorFromJointTransform),
                isTracked: joint.isTracked
            )
        } ?? []
        
        return HandData(
            isTracked: anchor.isTracked,
            confidence: 1.0, // ARKit doesn't provide confidence for hands
            position: position,
            orientation: orientation,
            joints: joints
        )
    }
    
    private func detectGesture(from anchor: HandAnchor) -> SpatialGesture? {
        // Simple gesture detection based on hand pose
        guard let skeleton = anchor.handSkeleton else { return nil }
        
        // Example: Detect pinch gesture
        if let thumbTip = skeleton.joint(.thumbTip),
           let indexTip = skeleton.joint(.indexFingerTip) {
            let distance = distance(thumbTip.anchorFromJointTransform.columns.3,
                                  indexTip.anchorFromJointTransform.columns.3)
            if distance < 0.02 { // 2cm threshold
                return .pinch
            }
        }
        
        return nil
    }
    #endif
    
    // MARK: - Spatial Computing API
    
    /// Create and place a 3D entity in the scene
    public func createEntity(at position: SIMD3<Float>, name: String? = nil) async throws -> String {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        let entityId = name ?? UUID().uuidString
        let entity = Entity()
        entity.name = entityId
        entity.position = position
        
        entities[entityId] = entity
        try await _resources.addEntity()
        
        return entityId
        #else
        throw AxiomCapabilityError.unavailable("Entity creation only available on visionOS")
        #endif
    }
    
    /// Remove an entity from the scene
    public func removeEntity(_ entityId: String) async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        guard entities[entityId] != nil else {
            throw AxiomCapabilityError.unavailable("Entity not found: \(entityId)")
        }
        
        entities.removeValue(forKey: entityId)
        await _resources.removeEntity()
        #else
        throw AxiomCapabilityError.unavailable("Entity removal only available on visionOS")
        #endif
    }
    
    /// Create a spatial anchor at the specified position
    public func createSpatialAnchor(at position: SIMD3<Float>, orientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)) async throws -> SpatialAnchor {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        let anchorId = UUID().uuidString
        let transform = simd_float4x4(orientation)
        transform.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1.0)
        
        let anchor = ARAnchor(transform: transform)
        spatialAnchors[anchorId] = anchor
        
        return SpatialAnchor(
            id: anchorId,
            position: position,
            orientation: orientation,
            isTracked: true
        )
        #else
        throw AxiomCapabilityError.unavailable("Spatial anchors only available on visionOS")
        #endif
    }
    
    /// Remove a spatial anchor
    public func removeSpatialAnchor(_ anchorId: String) async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        guard spatialAnchors[anchorId] != nil else {
            throw AxiomCapabilityError.unavailable("Spatial anchor not found: \(anchorId)")
        }
        
        spatialAnchors.removeValue(forKey: anchorId)
        #else
        throw AxiomCapabilityError.unavailable("Spatial anchor removal only available on visionOS")
        #endif
    }
    
    /// Start hand tracking updates
    public func startHandTracking() async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        guard _configuration.enableHandTracking else {
            throw AxiomCapabilityError.unavailable("Hand tracking not enabled in configuration")
        }
        
        #if os(visionOS)
        // Hand tracking is automatically started when the provider is created
        #else
        throw AxiomCapabilityError.unavailable("Hand tracking only available on visionOS")
        #endif
    }
    
    /// Stop hand tracking updates
    public func stopHandTracking() async {
        #if os(visionOS)
        // Hand tracking provider will be cleaned up in teardown
        #endif
    }
    
    /// Place spatial audio at the specified position
    public func playSpatialAudio(data: Data, at position: SIMD3<Float>, volume: Float = 1.0) async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        guard _configuration.enableSpatialAudio else {
            throw AxiomCapabilityError.unavailable("Spatial audio not enabled in configuration")
        }
        
        #if os(visionOS)
        guard let engine = spatialAudioEngine else {
            throw AxiomCapabilityError.unavailable("Spatial audio engine not available")
        }
        
        // Create audio player node
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        // Create spatial mixer node
        let spatialMixer = AVAudioEnvironmentNode()
        engine.attach(spatialMixer)
        
        // Connect nodes
        engine.connect(playerNode, to: spatialMixer, format: nil)
        engine.connect(spatialMixer, to: engine.mainMixerNode, format: nil)
        
        // Set spatial position
        spatialMixer.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        spatialMixer.setPlayerPosition(
            AVAudio3DPoint(x: position.x, y: position.y, z: position.z),
            for: playerNode
        )
        
        // Play audio
        playerNode.volume = volume
        playerNode.play()
        #else
        throw AxiomCapabilityError.unavailable("Spatial audio only available on visionOS")
        #endif
    }
    
    /// Perform raycast from the specified position and direction
    public func performRaycast(from origin: SIMD3<Float>, direction: SIMD3<Float>) async throws -> [SpatialInteraction] {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        // Perform raycast against entities
        var interactions: [SpatialInteraction] = []
        
        for (entityId, entity) in entities {
            // Simple distance-based intersection test
            let entityPosition = entity.position
            let toEntity = entityPosition - origin
            let projectedDistance = dot(toEntity, normalize(direction))
            
            if projectedDistance > 0 && projectedDistance <= _configuration.spatialInteractionRange {
                let closestPoint = origin + direction * projectedDistance
                let distance = distance(closestPoint, entityPosition)
                
                if distance < 0.5 { // 50cm hit tolerance
                    let interaction = SpatialInteraction(
                        gesture: .tap,
                        position: closestPoint,
                        entityId: entityId,
                        confidence: max(0.1, 1.0 - distance)
                    )
                    interactions.append(interaction)
                }
            }
        }
        
        return interactions.sorted { $0.confidence > $1.confidence }
        #else
        throw AxiomCapabilityError.unavailable("Raycast only available on visionOS")
        #endif
    }
    
    /// Get current immersive space state
    public func getImmersiveSpaceState() async -> ImmersiveSpaceState {
        return immersiveSpaceState
    }
    
    /// Open immersive space
    public func openImmersiveSpace() async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        immersiveSpaceState = .opening
        // In a real implementation, this would trigger SwiftUI immersive space opening
        immersiveSpaceState = .open
        #else
        throw AxiomCapabilityError.unavailable("Immersive spaces only available on visionOS")
        #endif
    }
    
    /// Close immersive space
    public func closeImmersiveSpace() async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Spatial computing not available")
        }
        
        #if os(visionOS)
        immersiveSpaceState = .closing
        // In a real implementation, this would trigger SwiftUI immersive space closing
        immersiveSpaceState = .inactive
        #else
        throw AxiomCapabilityError.unavailable("Immersive spaces only available on visionOS")
        #endif
    }
    
    /// Stream of hand tracking updates
    public var handTrackingStream: AsyncStream<HandTrackingData> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setHandTrackingStreamContinuation(continuation)
            }
        }
    }
    
    /// Stream of spatial interactions
    public var spatialInteractionStream: AsyncStream<SpatialInteraction> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setSpatialInteractionStreamContinuation(continuation)
            }
        }
    }
    
    /// Get all current spatial anchors
    public func getAllSpatialAnchors() async -> [SpatialAnchor] {
        #if os(visionOS)
        return spatialAnchors.map { (id, anchor) in
            let transform = anchor.transform
            let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            let orientation = simd_quatf(transform)
            
            return SpatialAnchor(
                id: id,
                position: position,
                orientation: orientation,
                isTracked: true
            )
        }
        #else
        return []
        #endif
    }
    
    /// Get current entity count
    public func getEntityCount() async -> Int {
        return await _resources.getEntityCount()
    }
    
    /// Check if platform supports spatial computing
    public func isPlatformSupported() async -> Bool {
        #if os(visionOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - simd_quatf Codable Extension

extension simd_quatf: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Float.self, forKey: .x)
        let y = try container.decode(Float.self, forKey: .y)
        let z = try container.decode(Float.self, forKey: .z)
        let w = try container.decode(Float.self, forKey: .w)
        self.init(ix: x, iy: y, iz: z, r: w)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.imag.x, forKey: .x)
        try container.encode(self.imag.y, forKey: .y)
        try container.encode(self.imag.z, forKey: .z)
        try container.encode(self.real, forKey: .w)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y, z, w
    }
}

// MARK: - Registration Extension

extension AxiomCapabilityRegistry {
    /// Register spatial computing capability
    public func registerSpatialComputing() async throws {
        let capability = SpatialComputingCapability()
        try await register(
            capability,
            requirements: [
                AxiomCapabilityDiscoveryService.Requirement(
                    type: .systemFeature("visionOS"),
                    isMandatory: true
                ),
                AxiomCapabilityDiscoveryService.Requirement(
                    type: .systemFeature("RealityKit"),
                    isMandatory: false
                ),
                AxiomCapabilityDiscoveryService.Requirement(
                    type: .systemFeature("ARKit"),
                    isMandatory: false
                )
            ],
            category: "spatial",
            metadata: AxiomCapabilityMetadata(
                name: "Spatial Computing",
                description: "Comprehensive spatial computing capability for visionOS",
                version: "1.0.0",
                documentation: "Provides RealityKit integration, hand tracking, immersive spaces, spatial interactions, and spatial audio for visionOS applications",
                supportedPlatforms: ["visionOS"],
                minimumOSVersion: "1.0",
                tags: ["spatial", "visionos", "realitykit", "arkit", "immersive"],
                dependencies: ["RealityKit", "ARKit", "AVFAudio"]
            )
        )
    }
}