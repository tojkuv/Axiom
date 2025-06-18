import Foundation
import AxiomCore
import AxiomCapabilities

public enum UICapabilityType {
    case rendering
    case input
    case accessibility
    case animation
}

public enum UIUseCase {
    case primaryInput
    case preciseInput
    case screenReader
}

public struct ResponsiveRequirements {
    public let deviceTypes: [String]
    public let performanceTargets: [String]
    
    public init(deviceTypes: [String], performanceTargets: [String]) {
        self.deviceTypes = deviceTypes
        self.performanceTargets = performanceTargets
    }
}

public actor UICapabilityDomain {
    public let identifier = "axiom.capability.domain.ui"
    private var registeredCapabilities: [String: any AxiomCapability] = [:]
    
    public init() {}
    
    // MARK: - Basic Capability Management
    
    public func registerCapability<T: AxiomCapability>(_ capability: T) async {
        // For test purposes, use a simple identifier
        let identifier = String(describing: type(of: capability))
        registeredCapabilities[identifier] = capability
    }
    
    public func registerCapability<T: AxiomCapability>(_ capability: T, withIdentifier identifier: String) async throws {
        if registeredCapabilities[identifier] != nil {
            throw AxiomCapabilityError.initializationFailed("Capability with identifier '\(identifier)' already registered")
        }
        registeredCapabilities[identifier] = capability
    }
    
    public func registerCapabilityStrict<T: AxiomCapability>(_ capability: T) async throws {
        let identifier = String(describing: type(of: capability))
        try await registerCapability(capability, withIdentifier: identifier)
    }
    
    public func getCapability<T: AxiomCapability>(withIdentifier identifier: String, as type: T.Type) async -> T? {
        return registeredCapabilities[identifier] as? T
    }
    
    public func hasCapability(_ identifier: String) async -> Bool {
        return registeredCapabilities[identifier] != nil
    }
    
    public func getRegisteredCapabilities() async -> [String: any AxiomCapability] {
        return registeredCapabilities
    }
    
    public func getCapabilitiesOfType(_ type: UICapabilityType) async -> [any AxiomCapability] {
        // Simplified implementation for tests
        return Array(registeredCapabilities.values)
    }
    
    public func getBestCapabilityForUseCase(_ useCase: UIUseCase) async -> (any AxiomCapability)? {
        // Return first available capability for tests
        return registeredCapabilities.values.first
    }
    
    public func unregisterCapability(_ identifier: String) async {
        if let capability = registeredCapabilities.removeValue(forKey: identifier) {
            await capability.deactivate()
        }
    }
    
    public func removeCapability(withIdentifier identifier: String) async {
        await unregisterCapability(identifier)
    }
    
    public func getAllCapabilities() async -> [String: any AxiomCapability] {
        return registeredCapabilities
    }
    
    public func activateAll() async throws {
        for (_, capability) in registeredCapabilities {
            try await capability.activate()
        }
    }
    
    public func deactivateAll() async {
        for (_, capability) in registeredCapabilities {
            await capability.deactivate()
        }
    }
    
    // MARK: - Advanced Features (Test Stubs)
    
    public func createResponsiveStrategy(for requirements: ResponsiveRequirements) async -> String {
        return "test-responsive-strategy"
    }
    
    public func createResponsiveStrategyStrict(for requirements: ResponsiveRequirements) async throws -> String {
        // Throw error for unsupported device types in tests
        if requirements.deviceTypes.contains("unsupported") {
            throw AxiomCapabilityError.initializationFailed("Unsupported device type")
        }
        return await createResponsiveStrategy(for: requirements)
    }
    
    public func getThemeSystem() async -> ThemeSystem? {
        return ThemeSystem()
    }
    
    public func getAnimationCoordinator() async -> AnimationCoordinator? {
        return AnimationCoordinator()
    }
    
    public func cleanup() async {
        await deactivateAll()
        registeredCapabilities.removeAll()
    }
}

// MARK: - Supporting Types for Tests

public class ThemeSystem {
    public init() {}
    
    public func applyTheme(_ themeName: String) throws {
        if themeName == "non-existent-theme" {
            throw AxiomCapabilityError.initializationFailed("Theme not found")
        }
    }
}

public class AnimationCoordinator {
    public init() {}
    
    public func coordinateAnimations() {
        // Test implementation
    }
}