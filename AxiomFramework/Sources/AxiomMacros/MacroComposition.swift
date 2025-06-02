import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

// MARK: - Macro Composition Framework

/// Protocol for macros that can participate in composition
public protocol ComposableMacro: MemberMacro, AxiomMacro {
    /// Capabilities this macro provides
    static var provides: Set<MacroCapability> { get }
    
    /// Capabilities this macro requires
    static var requires: Set<MacroCapability> { get }
    
    /// Macros this macro conflicts with
    static var conflicts: Set<String> { get }
    
    /// Priority for conflict resolution (higher wins)
    static var priority: MacroPriority { get }
    
    /// Generate code in coordination with other macros
    static func coordinatedExpansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        with coordinator: MacroCoordinator
    ) throws -> [DeclSyntax]
}

/// Capabilities that macros can provide or require
public enum MacroCapability: String, CaseIterable, Hashable {
    case clientManagement
    case crossCuttingConcerns
    case viewIntegration
    case stateObservation
    case intelligenceFeatures
    case capabilityValidation
    case domainModeling
    case lifecycleManagement
    case errorHandling
    case performanceMonitoring
}

/// Priority levels for macro conflict resolution
public enum MacroPriority: Int, Comparable {
    case lowest = 0
    case low = 25
    case normal = 50
    case high = 75
    case highest = 100
    
    public static func < (lhs: MacroPriority, rhs: MacroPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Coordinates macro composition and conflict resolution
public class MacroCoordinator {
    private var activeMacros: [String: ComposableMacro.Type] = [:]
    private var sharedContext: MacroSharedContext = MacroSharedContext()
    
    public init() {}
    
    /// Register a macro for coordinated expansion
    public func register(_ macro: ComposableMacro.Type, name: String) {
        activeMacros[name] = macro
    }
    
    /// Get list of registered macro names
    public func getRegisteredMacros() -> [String] {
        return Array(activeMacros.keys)
    }
    
    /// Resolve conflicts and determine expansion order
    public func resolveConflicts() throws -> [ComposableMacro.Type] {
        let macros = Array(activeMacros.values)
        
        // 1. Check for explicit conflicts
        try validateExplicitConflicts(macros)
        
        // 2. Analyze capability conflicts
        try validateCapabilityConflicts(macros)
        
        // 3. Determine dependency order
        let orderedMacros = try resolveDependencyOrder(macros)
        
        // 4. Apply priority-based conflict resolution
        return try applyPriorityResolution(orderedMacros)
    }
    
    /// Get shared context for cross-macro communication
    public func getSharedContext() -> MacroSharedContext {
        return sharedContext
    }
    
    // MARK: - Private Conflict Resolution Methods
    
    private func validateExplicitConflicts(_ macros: [ComposableMacro.Type]) throws {
        for macro in macros {
            let macroName = macro.macroName
            let conflicts = macro.conflicts
            
            for other in macros {
                if conflicts.contains(other.macroName) {
                    throw MacroCompositionError.explicitConflict(
                        macro: macroName,
                        conflictsWith: other.macroName,
                        resolution: "Use higher priority macro or combine capabilities"
                    )
                }
            }
        }
    }
    
    private func validateCapabilityConflicts(_ macros: [ComposableMacro.Type]) throws {
        var capabilityProviders: [MacroCapability: [ComposableMacro.Type]] = [:]
        
        // Map capabilities to their providers
        for macro in macros {
            for capability in macro.provides {
                capabilityProviders[capability, default: []].append(macro)
            }
        }
        
        // Check for conflicting providers
        for (capability, providers) in capabilityProviders {
            if providers.count > 1 {
                let sorted = providers.sorted { $0.priority > $1.priority }
                let winner = sorted[0]
                let losers = Array(sorted.dropFirst())
                
                // Emit warning about capability override
                for loser in losers {
                    print("Warning: \(winner.macroName) overrides \(capability) capability from \(loser.macroName)")
                }
            }
        }
    }
    
    private func resolveDependencyOrder(_ macros: [ComposableMacro.Type]) throws -> [ComposableMacro.Type] {
        // Topological sort based on requires/provides relationships
        var result: [ComposableMacro.Type] = []
        var remaining = macros
        var satisfied: Set<MacroCapability> = []
        
        while !remaining.isEmpty {
            let ready = remaining.filter { macro in
                macro.requires.isSubset(of: satisfied)
            }
            
            guard !ready.isEmpty else {
                throw MacroCompositionError.circularDependency(
                    macros: remaining.map { $0.macroName }
                )
            }
            
            // Sort by priority and add to result
            let sortedReady = ready.sorted { $0.priority > $1.priority }
            result.append(contentsOf: sortedReady)
            
            // Update satisfied capabilities and remaining macros
            for macro in sortedReady {
                satisfied.formUnion(macro.provides)
                remaining.removeAll { $0.macroName == macro.macroName }
            }
        }
        
        return result
    }
    
    private func applyPriorityResolution(_ macros: [ComposableMacro.Type]) throws -> [ComposableMacro.Type] {
        // Macros are already sorted by priority in resolveDependencyOrder
        return macros
    }
}

/// Shared context for cross-macro communication
public class MacroSharedContext {
    private var generatedMembers: [String: Set<String>] = [:]
    private var reservedNames: Set<String> = []
    private var capabilities: Set<MacroCapability> = []
    
    public init() {}
    
    /// Register that a macro has generated a specific member
    public func registerGeneratedMember(_ name: String, by macro: String) {
        generatedMembers[macro, default: []].insert(name)
        reservedNames.insert(name)
    }
    
    /// Check if a name is already reserved
    public func isNameReserved(_ name: String) -> Bool {
        return reservedNames.contains(name)
    }
    
    /// Generate unique name with prefix
    public func generateUniqueName(_ baseName: String) -> String {
        var counter = 0
        var candidateName = baseName
        while reservedNames.contains(candidateName) {
            counter += 1
            candidateName = "\(baseName)\(counter)"
        }
        reservedNames.insert(candidateName)
        return candidateName
    }
    
    /// Register capability as provided
    public func registerCapability(_ capability: MacroCapability) {
        capabilities.insert(capability)
    }
    
    /// Check if capability is available
    public func hasCapability(_ capability: MacroCapability) -> Bool {
        return capabilities.contains(capability)
    }
}

/// Errors that can occur during macro composition
public enum MacroCompositionError: Error, LocalizedError {
    case explicitConflict(macro: String, conflictsWith: String, resolution: String)
    case circularDependency(macros: [String])
    case unsatisfiedDependency(macro: String, missing: Set<MacroCapability>)
    case capabilityConflict(capability: MacroCapability, providers: [String])
    
    public var errorDescription: String? {
        switch self {
        case .explicitConflict(let macro, let conflicts, let resolution):
            return "Macro '\(macro)' conflicts with '\(conflicts)'. \(resolution)"
        case .circularDependency(let macros):
            return "Circular dependency detected among macros: \(macros.joined(separator: ", "))"
        case .unsatisfiedDependency(let macro, let missing):
            return "Macro '\(macro)' requires unsatisfied capabilities: \(missing)"
        case .capabilityConflict(let capability, let providers):
            return "Multiple macros provide '\(capability)': \(providers.joined(separator: ", "))"
        }
    }
}

// MARK: - Default Implementations

extension ComposableMacro {
    /// Default implementation provides standard expansion
    public static func coordinatedExpansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        with coordinator: MacroCoordinator
    ) throws -> [DeclSyntax] {
        // Default to standard expansion if no coordination needed
        return try Self.expansion(of: node, providingMembersOf: declaration, in: context)
    }
    
    /// Default empty conflicts
    public static var conflicts: Set<String> { [] }
    
    /// Default normal priority
    public static var priority: MacroPriority { .normal }
    
    /// Default empty requirements
    public static var requires: Set<MacroCapability> { [] }
}

// MARK: - Macro Conformance Extensions

extension ClientMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.clientManagement] }
    public static var priority: MacroPriority { .high }
}

extension ContextMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.clientManagement, .crossCuttingConcerns] }
    public static var priority: MacroPriority { .highest }
}

extension IntelligenceMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.intelligenceFeatures] }
    public static var priority: MacroPriority { .normal }
}

extension ObservableStateMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.stateObservation] }
    public static var priority: MacroPriority { .normal }
}

extension ViewMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.viewIntegration, .lifecycleManagement] }
    public static var priority: MacroPriority { .high }
}

extension CapabilitiesMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.capabilityValidation] }
    public static var priority: MacroPriority { .normal }
}

extension DomainModelMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.domainModeling] }
    public static var priority: MacroPriority { .normal }
}

extension CrossCuttingMacro: ComposableMacro {
    public static var provides: Set<MacroCapability> { [.crossCuttingConcerns] }
    public static var priority: MacroPriority { .normal }
}