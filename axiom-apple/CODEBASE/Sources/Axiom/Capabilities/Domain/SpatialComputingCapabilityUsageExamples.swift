import Foundation
import simd

#if os(visionOS)
import RealityKit
import ARKit
import SwiftUI
#endif

// MARK: - Spatial Computing Usage Examples

/// Examples demonstrating how to use the SpatialComputingCapability
public struct SpatialComputingUsageExamples {
    
    // MARK: - Basic Setup
    
    /// Example: Basic spatial computing capability setup
    public static func basicSetup() async throws {
        // Create configuration
        let config = SpatialComputingConfiguration(
            enableRealityKit: true,
            enableHandTracking: true,
            enableSpatialAudio: true,
            maxEntities: 500,
            handTrackingAccuracy: .high
        )
        
        // Create capability
        let spatialCapability = SpatialComputingCapability(
            configuration: config,
            environment: .production
        )
        
        // Check if supported
        guard await spatialCapability.isSupported() else {
            print("Spatial computing not supported on this platform")
            return
        }
        
        // Activate capability
        try await spatialCapability.activate()
        print("Spatial computing capability activated")
        
        // Deactivate when done
        await spatialCapability.deactivate()
    }
    
    // MARK: - Hand Tracking
    
    /// Example: Hand tracking with gesture recognition
    public static func handTrackingExample() async throws {
        let config = SpatialComputingConfiguration(
            enableHandTracking: true,
            handTrackingAccuracy: .high
        )
        
        let capability = SpatialComputingCapability(configuration: config)
        try await capability.activate()
        
        // Start hand tracking
        try await capability.startHandTracking()
        
        // Listen for hand tracking updates
        Task {
            let handTrackingStream = await capability.handTrackingStream
            for await handTrackingData in handTrackingStream {
                if let leftHand = handTrackingData.leftHand, leftHand.isTracked {
                    print("Left hand position: \(leftHand.position)")
                    print("Left hand confidence: \(leftHand.confidence)")
                }
                
                if let rightHand = handTrackingData.rightHand, rightHand.isTracked {
                    print("Right hand position: \(rightHand.position)")
                    print("Right hand confidence: \(rightHand.confidence)")
                }
            }
        }
        
        // Listen for spatial interactions (gestures)
        Task {
            let spatialInteractionStream = await capability.spatialInteractionStream
            for await interaction in spatialInteractionStream {
                print("Gesture detected: \(interaction.gesture)")
                print("Position: \(interaction.position)")
                print("Confidence: \(interaction.confidence)")
                
                if let entityId = interaction.entityId {
                    print("Interacted with entity: \(entityId)")
                }
            }
        }
    }
    
    // MARK: - Entity Management
    
    /// Example: Creating and managing 3D entities
    public static func entityManagementExample() async throws {
        let capability = SpatialComputingCapability()
        try await capability.activate()
        
        // Create entities at different positions
        let cube1Id = try await capability.createEntity(
            at: SIMD3<Float>(0, 1, -2),
            name: "cube1"
        )
        
        let cube2Id = try await capability.createEntity(
            at: SIMD3<Float>(1, 1, -2),
            name: "cube2"
        )
        
        let sphere1Id = try await capability.createEntity(
            at: SIMD3<Float>(-1, 1, -2),
            name: "sphere1"
        )
        
        print("Created entities: \(cube1Id), \(cube2Id), \(sphere1Id)")
        
        // Check entity count
        let entityCount = await capability.getEntityCount()
        print("Total entities: \(entityCount)")
        
        // Remove specific entity
        try await capability.removeEntity(cube2Id)
        print("Removed entity: \(cube2Id)")
        
        // Final entity count
        let finalCount = await capability.getEntityCount()
        print("Final entity count: \(finalCount)")
    }
    
    // MARK: - Spatial Anchors
    
    /// Example: Creating and managing spatial anchors
    public static func spatialAnchorsExample() async throws {
        let capability = SpatialComputingCapability()
        try await capability.activate()
        
        // Create spatial anchors
        let anchor1 = try await capability.createSpatialAnchor(
            at: SIMD3<Float>(0, 0, -1)
        )
        
        let anchor2 = try await capability.createSpatialAnchor(
            at: SIMD3<Float>(2, 0, -1),
            orientation: simd_quatf(angle: .pi / 4, axis: SIMD3<Float>(0, 1, 0))
        )
        
        print("Created anchors: \(anchor1.id), \(anchor2.id)")
        
        // Get all anchors
        let allAnchors = await capability.getAllSpatialAnchors()
        print("Total anchors: \(allAnchors.count)")
        
        for anchor in allAnchors {
            print("Anchor \(anchor.id): position=\(anchor.position), tracked=\(anchor.isTracked)")
        }
        
        // Remove anchor
        try await capability.removeSpatialAnchor(anchor1.id)
        print("Removed anchor: \(anchor1.id)")
    }
    
    // MARK: - Spatial Audio
    
    /// Example: Playing spatial audio
    public static func spatialAudioExample() async throws {
        let config = SpatialComputingConfiguration(
            enableSpatialAudio: true,
            spatialAudioRadius: 5.0
        )
        
        let capability = SpatialComputingCapability(configuration: config)
        try await capability.activate()
        
        // Create sample audio data (in real app, load from file)
        let audioData = Data(count: 1024) // Placeholder data
        
        // Play spatial audio at different positions
        try await capability.playSpatialAudio(
            data: audioData,
            at: SIMD3<Float>(1, 0, -2),
            volume: 0.8
        )
        
        try await capability.playSpatialAudio(
            data: audioData,
            at: SIMD3<Float>(-1, 0, -2),
            volume: 0.6
        )
        
        print("Spatial audio playing at multiple positions")
    }
    
    // MARK: - Raycast Interactions
    
    /// Example: Performing raycast for spatial interactions
    public static func raycastExample() async throws {
        let capability = SpatialComputingCapability()
        try await capability.activate()
        
        // Create some entities to interact with
        let _ = try await capability.createEntity(
            at: SIMD3<Float>(0, 1, -2),
            name: "target"
        )
        
        // Perform raycast from user position toward entity
        let origin = SIMD3<Float>(0, 1.7, 0) // Approximate eye level
        let direction = simd_normalize(SIMD3<Float>(0, 1, -2) - origin)
        
        let interactions = try await capability.performRaycast(
            from: origin,
            direction: direction
        )
        
        for interaction in interactions {
            print("Hit entity: \(interaction.entityId ?? "unknown")")
            print("Hit position: \(interaction.position)")
            print("Hit confidence: \(interaction.confidence)")
        }
        
        if interactions.isEmpty {
            print("No interactions found")
        }
    }
    
    // MARK: - Immersive Spaces
    
    /// Example: Managing immersive spaces
    public static func immersiveSpaceExample() async throws {
        let config = SpatialComputingConfiguration(
            immersiveSpaceStyle: .mixed
        )
        
        let capability = SpatialComputingCapability(configuration: config)
        try await capability.activate()
        
        // Check initial state
        let initialState = await capability.getImmersiveSpaceState()
        print("Initial immersive space state: \(initialState)")
        
        // Open immersive space
        try await capability.openImmersiveSpace()
        print("Immersive space opened")
        
        let openState = await capability.getImmersiveSpaceState()
        print("Current immersive space state: \(openState)")
        
        // Do some work in immersive space
        let entityId = try await capability.createEntity(
            at: SIMD3<Float>(0, 1, -2),
            name: "immersive_entity"
        )
        print("Created entity in immersive space: \(entityId)")
        
        // Close immersive space
        try await capability.closeImmersiveSpace()
        print("Immersive space closed")
        
        let finalState = await capability.getImmersiveSpaceState()
        print("Final immersive space state: \(finalState)")
    }
    
    // MARK: - Configuration Management
    
    /// Example: Dynamic configuration updates
    public static func configurationExample() async throws {
        let initialConfig = SpatialComputingConfiguration(
            enableRealityKit: true,
            enableHandTracking: false,
            maxEntities: 100
        )
        
        let capability = SpatialComputingCapability(configuration: initialConfig)
        try await capability.activate()
        
        print("Initial configuration:")
        let config1 = await capability.configuration
        print("- Hand tracking: \(config1.enableHandTracking)")
        print("- Max entities: \(config1.maxEntities)")
        
        // Update configuration to enable hand tracking
        let updatedConfig = SpatialComputingConfiguration(
            enableRealityKit: true,
            enableHandTracking: true,
            maxEntities: 500,
            handTrackingAccuracy: .high
        )
        
        try await capability.updateConfiguration(updatedConfig)
        
        print("Updated configuration:")
        let config2 = await capability.configuration
        print("- Hand tracking: \(config2.enableHandTracking)")
        print("- Max entities: \(config2.maxEntities)")
        print("- Hand tracking accuracy: \(config2.handTrackingAccuracy)")
    }
    
    // MARK: - Environment Adaptation
    
    /// Example: Handling environment changes
    public static func environmentAdaptationExample() async throws {
        let config = SpatialComputingConfiguration(
            maxEntities: 1000,
            handTrackingAccuracy: .high
        )
        
        let capability = SpatialComputingCapability(configuration: config)
        try await capability.activate()
        
        print("Normal environment:")
        let normalConfig = await capability.configuration
        print("- Max entities: \(normalConfig.maxEntities)")
        print("- Hand tracking accuracy: \(normalConfig.handTrackingAccuracy)")
        
        // Simulate low power mode
        let lowPowerEnvironment = CapabilityEnvironment(
            isLowPowerMode: true,
            hasNetworkConnection: true,
            deviceClass: .phone
        )
        
        await capability.handleEnvironmentChange(lowPowerEnvironment)
        
        print("Low power environment:")
        let lowPowerConfig = await capability.configuration
        print("- Max entities: \(lowPowerConfig.maxEntities)")
        print("- Hand tracking accuracy: \(lowPowerConfig.handTrackingAccuracy)")
    }
    
    // MARK: - Resource Monitoring
    
    /// Example: Monitoring resource usage
    public static func resourceMonitoringExample() async throws {
        let capability = SpatialComputingCapability()
        try await capability.activate()
        
        let resources = await capability.resources
        
        print("Initial resource usage:")
        let initialUsage = await resources.currentUsage
        print("- Memory: \(initialUsage.memory) bytes")
        print("- CPU: \(initialUsage.cpu)%")
        print("- Bandwidth: \(initialUsage.bandwidth) bytes/s")
        
        // Create some entities
        for i in 0..<10 {
            let _ = try await capability.createEntity(
                at: SIMD3<Float>(Float(i), 1, -2),
                name: "entity_\(i)"
            )
        }
        
        print("Resource usage after creating entities:")
        let updatedUsage = await resources.currentUsage
        print("- Memory: \(updatedUsage.memory) bytes")
        print("- CPU: \(updatedUsage.cpu)%")
        print("- Bandwidth: \(updatedUsage.bandwidth) bytes/s")
        
        print("Max allowed usage:")
        let maxUsage = resources.maxUsage
        print("- Memory: \(maxUsage.memory) bytes")
        print("- CPU: \(maxUsage.cpu)%")
        print("- Bandwidth: \(maxUsage.bandwidth) bytes/s")
        
        print("Usage within limits: \(!updatedUsage.exceeds(maxUsage))")
    }
    
    // MARK: - Error Handling
    
    /// Example: Proper error handling
    public static func errorHandlingExample() async {
        do {
            let capability = SpatialComputingCapability()
            
            // Check if platform is supported
            guard await capability.isSupported() else {
                print("Spatial computing not supported - providing fallback experience")
                return
            }
            
            // Try to activate
            try await capability.activate()
            
            // Try operations that might fail
            do {
                let entityId = try await capability.createEntity(at: SIMD3<Float>(0, 1, -2))
                print("Entity created successfully: \(entityId)")
            } catch CapabilityError.resourceAllocationFailed(let reason) {
                print("Resource allocation failed: \(reason)")
                // Handle gracefully - maybe reduce quality or show message
            }
            
            // Try spatial audio
            do {
                let audioData = Data(count: 1024)
                try await capability.playSpatialAudio(data: audioData, at: SIMD3<Float>(0, 0, -1))
            } catch CapabilityError.notAvailable(let feature) {
                print("Spatial audio not available: \(feature)")
                // Fall back to regular audio
            }
            
        } catch CapabilityError.initializationFailed(let reason) {
            print("Failed to initialize spatial computing: \(reason)")
        } catch CapabilityError.permissionRequired(let permission) {
            print("Permission required: \(permission)")
            // Guide user to settings or request permission
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}

// MARK: - SwiftUI Integration Example

#if os(visionOS)
import SwiftUI

/// Example SwiftUI view that uses spatial computing
public struct SpatialComputingView: View {
    @State private var spatialCapability: SpatialComputingCapability?
    @State private var isActive = false
    @State private var entityCount = 0
    @State private var handTrackingData: HandTrackingData?
    
    public var body: some View {
        VStack {
            Text("Spatial Computing Demo")
                .font(.largeTitle)
                .padding()
            
            if isActive {
                VStack {
                    Text("Status: Active")
                        .foregroundColor(.green)
                    
                    Text("Entities: \(entityCount)")
                    
                    if let handData = handTrackingData {
                        VStack {
                            if let leftHand = handData.leftHand {
                                Text("Left Hand: \(leftHand.isTracked ? "Tracked" : "Lost")")
                            }
                            if let rightHand = handData.rightHand {
                                Text("Right Hand: \(rightHand.isTracked ? "Tracked" : "Lost")")
                            }
                        }
                    }
                }
            } else {
                Text("Status: Inactive")
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Activate") {
                    Task {
                        await activateSpatialComputing()
                    }
                }
                .disabled(isActive)
                
                Button("Deactivate") {
                    Task {
                        await deactivateSpatialComputing()
                    }
                }
                .disabled(!isActive)
                
                Button("Add Entity") {
                    Task {
                        await addEntity()
                    }
                }
                .disabled(!isActive)
            }
            .padding()
        }
        .onAppear {
            setupSpatialComputing()
        }
    }
    
    private func setupSpatialComputing() {
        spatialCapability = SpatialComputingCapability()
    }
    
    private func activateSpatialComputing() async {
        guard let capability = spatialCapability else { return }
        
        do {
            try await capability.activate()
            isActive = true
            
            // Start hand tracking
            if await capability.configuration.enableHandTracking {
                try await capability.startHandTracking()
                
                // Listen for hand tracking updates
                Task {
                    for await handData in capability.handTrackingStream {
                        await MainActor.run {
                            handTrackingData = handData
                        }
                    }
                }
            }
            
        } catch {
            print("Failed to activate spatial computing: \(error)")
        }
    }
    
    private func deactivateSpatialComputing() async {
        guard let capability = spatialCapability else { return }
        
        await capability.deactivate()
        isActive = false
        entityCount = 0
        handTrackingData = nil
    }
    
    private func addEntity() async {
        guard let capability = spatialCapability else { return }
        
        do {
            let position = SIMD3<Float>(
                Float.random(in: -2...2),
                Float.random(in: 0...2),
                Float.random(in: -3...(-1))
            )
            
            let _ = try await capability.createEntity(at: position)
            entityCount = await capability.getEntityCount()
            
        } catch {
            print("Failed to create entity: \(error)")
        }
    }
}
#endif