import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Writing failing tests for @Capability macro

final class CapabilityMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Capability": CapabilityMacro.self,
    ]
    
    // Test 1: Basic @Capability macro expansion with id
    func testBasicCapabilityMacroExpansion() throws {
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
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @Capability without id property
    func testCapabilityMacroWithoutId() throws {
        assertMacroExpansion(
            """
            @Capability
            struct SimpleCapability {
            }
            """,
            expandedSource: """
            struct SimpleCapability {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Capability requires an 'id' property",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Add 'let id: String' property")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 3: @Capability on non-struct produces diagnostic
    func testCapabilityMacroOnNonStructProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Capability
            class NetworkCapability {
                let id = "network"
            }
            """,
            expandedSource: """
            class NetworkCapability {
                let id = "network"
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Capability can only be applied to structs",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Change to 'struct'")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 4: @Capability with existing isAvailable method
    func testCapabilityMacroWithExistingIsAvailable() throws {
        assertMacroExpansion(
            """
            @Capability
            struct CustomCapability {
                let id = "custom"
                private let enabled: Bool
                
                func isAvailable() -> Bool {
                    enabled
                }
            }
            """,
            expandedSource: """
            struct CustomCapability {
                let id = "custom"
                private let enabled: Bool
                
                func isAvailable() -> Bool {
                    enabled
                }

                public var description: String {
                    "\\(id)"
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 5: @Capability with existing description property
    func testCapabilityMacroWithExistingDescription() throws {
        assertMacroExpansion(
            """
            @Capability
            struct DetailedCapability {
                let id = "detailed"
                
                var description: String {
                    "Detailed capability: \\(id)"
                }
            }
            """,
            expandedSource: """
            struct DetailedCapability {
                let id = "detailed"
                
                var description: String {
                    "Detailed capability: \\(id)"
                }

                public func isAvailable() -> Bool {
                    true
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 6: @Capability with public modifier
    func testCapabilityMacroWithPublicModifier() throws {
        assertMacroExpansion(
            """
            @Capability
            public struct PublicCapability {
                public let id = "public.capability"
            }
            """,
            expandedSource: """
            public struct PublicCapability {
                public let id = "public.capability"

                public func isAvailable() -> Bool {
                    true
                }

                public var description: String {
                    "\\(id)"
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 7: @Capability with both isAvailable and description existing
    func testCapabilityMacroFullyImplemented() throws {
        assertMacroExpansion(
            """
            @Capability
            struct CompleteCapability {
                let id = "complete"
                
                func isAvailable() -> Bool {
                    false
                }
                
                var description: String {
                    "Complete capability"
                }
            }
            """,
            expandedSource: """
            struct CompleteCapability {
                let id = "complete"
                
                func isAvailable() -> Bool {
                    false
                }
                
                var description: String {
                    "Complete capability"
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 8: @Capability with var id instead of let
    func testCapabilityMacroWithVarId() throws {
        assertMacroExpansion(
            """
            @Capability
            struct MutableCapability {
                var id = "mutable"
            }
            """,
            expandedSource: """
            struct MutableCapability {
                var id = "mutable"

                public func isAvailable() -> Bool {
                    true
                }

                public var description: String {
                    "\\(id)"
                }
            }
            """,
            macros: testMacros
        )
    }
}