import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Enhanced tests for Phase 3 @Capability macro

final class EnhancedCapabilityMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Capability": CapabilityMacro.self,
    ]
    
    // Test 1: @Capability generates runtime validation methods
    func testCapabilityMacroGeneratesRuntimeValidation() throws {
        assertMacroExpansion(
            """
            @Capability
            struct NetworkCapability {
                let id = "axiom.capability.network"
            }
            """,
            expandedSource: """
            struct NetworkCapability {
                let id = "axiom.capability.network"
            
                public func isAvailable() -> Bool {
                    true
                }
            
                public var description: String {
                    "\\(id)"
                }
                
                /// Request permission for this capability
                public func requestPermission() async -> Bool {
                    // Default implementation - override for platform-specific behavior
                    return isAvailable()
                }
                
                /// Validate capability requirements
                public func validate() -> Result<Void, CapabilityError> {
                    if isAvailable() {
                        return .success(())
                    } else {
                        return .failure(.notAvailable(id))
                    }
                }
                
                /// Check if capability can be used with graceful degradation
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else {
                        return .degraded(reason: "Capability \\(id) is not available")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @Capability with parameters for advanced configuration
    func testCapabilityMacroWithParameters() throws {
        assertMacroExpansion(
            """
            @Capability(required: true, fallback: "offline-mode")
            struct NetworkCapability {
                let id = "axiom.capability.network"
            }
            """,
            expandedSource: """
            struct NetworkCapability {
                let id = "axiom.capability.network"
                
                /// Indicates if this capability is required for the application
                public static let isRequired = true
                
                /// Fallback mode when capability is not available
                public static let fallbackMode = "offline-mode"
            
                public func isAvailable() -> Bool {
                    true
                }
            
                public var description: String {
                    "\\(id)"
                }
                
                /// Request permission for this capability
                public func requestPermission() async -> Bool {
                    // Default implementation - override for platform-specific behavior
                    return isAvailable()
                }
                
                /// Validate capability requirements
                public func validate() -> Result<Void, CapabilityError> {
                    if isAvailable() {
                        return .success(())
                    } else {
                        return .failure(.notAvailable(id))
                    }
                }
                
                /// Check if capability can be used with graceful degradation
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else if Self.fallbackMode != "" {
                        return .degraded(reason: "Using fallback: \\(Self.fallbackMode)")
                    } else {
                        return .unavailable(reason: "Required capability \\(id) is not available")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: @Capability with compile-time optimization hints
    func testCapabilityMacroWithOptimizationHints() throws {
        assertMacroExpansion(
            """
            @Capability(compileTime: true)
            struct DebugCapability {
                let id = "axiom.capability.debug"
            }
            """,
            expandedSource: """
            struct DebugCapability {
                let id = "axiom.capability.debug"
                
                /// Compile-time optimization hint
                @inlinable
                public func isAvailable() -> Bool {
                    #if DEBUG
                    return true
                    #else
                    return false
                    #endif
                }
            
                public var description: String {
                    "\\(id)"
                }
                
                /// Request permission for this capability
                @inlinable
                public func requestPermission() async -> Bool {
                    // Compile-time optimized
                    return isAvailable()
                }
                
                /// Validate capability requirements
                @inlinable
                public func validate() -> Result<Void, CapabilityError> {
                    if isAvailable() {
                        return .success(())
                    } else {
                        return .failure(.notAvailable(id))
                    }
                }
                
                /// Check if capability can be used with graceful degradation
                @inlinable
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else {
                        return .degraded(reason: "Capability \\(id) is not available")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 4: @Capability with error handling patterns
    func testCapabilityMacroWithErrorHandling() throws {
        assertMacroExpansion(
            """
            @Capability(errorHandler: true)
            struct FileSystemCapability {
                let id = "axiom.capability.filesystem"
            }
            """,
            expandedSource: """
            struct FileSystemCapability {
                let id = "axiom.capability.filesystem"
            
                public func isAvailable() -> Bool {
                    true
                }
            
                public var description: String {
                    "\\(id)"
                }
                
                /// Request permission for this capability
                public func requestPermission() async -> Bool {
                    // Default implementation - override for platform-specific behavior
                    return isAvailable()
                }
                
                /// Validate capability requirements
                public func validate() -> Result<Void, CapabilityError> {
                    if isAvailable() {
                        return .success(())
                    } else {
                        return .failure(.notAvailable(id))
                    }
                }
                
                /// Check if capability can be used with graceful degradation
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else {
                        return .degraded(reason: "Capability \\(id) is not available")
                    }
                }
                
                /// Handle errors related to this capability
                public func handleError(_ error: Error) -> CapabilityError {
                    if let capError = error as? CapabilityError {
                        return capError
                    } else {
                        return .operationFailed(capability: id, reason: error.localizedDescription)
                    }
                }
                
                /// Perform operation with automatic error handling
                public func performWithErrorHandling<T>(_ operation: () throws -> T) -> Result<T, CapabilityError> {
                    do {
                        let result = try operation()
                        return .success(result)
                    } catch {
                        return .failure(handleError(error))
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}

// MARK: - Supporting Types for Enhanced Capability System

public enum CapabilityError: Error, CustomStringConvertible {
    case notAvailable(String)
    case notGranted(String)
    case operationFailed(capability: String, reason: String)
    
    public var description: String {
        switch self {
        case .notAvailable(let id):
            return "Capability '\(id)' is not available"
        case .notGranted(let id):
            return "Capability '\(id)' was not granted"
        case .operationFailed(let capability, let reason):
            return "Operation failed for capability '\(capability)': \(reason)"
        }
    }
}

public enum CapabilityStatus {
    case available
    case degraded(reason: String)
    case unavailable(reason: String)
}