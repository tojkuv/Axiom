import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Writing failing tests for @State macro

final class StateMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "State": StateMacro.self,
    ]
    
    // Test 1: Basic @State macro expansion
    func testBasicStateMacroExpansion() throws {
        assertMacroExpansion(
            """
            @State
            struct UserState {
                var name: String
                var age: Int
            }
            """,
            expandedSource: """
            struct UserState {
                var name: String
                var age: Int

                init() {
                    self.name = ""
                    self.age = 0
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @State with existing initializer
    func testStateMacroWithExistingInitializer() throws {
        assertMacroExpansion(
            """
            @State
            struct ProductState {
                let id: String
                var name: String
                var price: Double
                
                init() {
                    self.id = UUID().uuidString
                    self.name = ""
                    self.price = 0.0
                }
            }
            """,
            expandedSource: """
            struct ProductState {
                let id: String
                var name: String
                var price: Double
                
                init() {
                    self.id = UUID().uuidString
                    self.name = ""
                    self.price = 0.0
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: @State applied to non-struct should produce diagnostic
    func testStateMacroOnNonStructProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @State
            class MyState {
            }
            """,
            expandedSource: """
            class MyState {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@State can only be applied to struct declarations",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Replace 'class' with 'struct'")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 4: @State with optional properties
    func testStateMacroWithOptionalProperties() throws {
        assertMacroExpansion(
            """
            @State
            struct SessionState {
                var user: User?
                var token: String?
                var isAuthenticated: Bool
            }
            """,
            expandedSource: """
            struct SessionState {
                var user: User?
                var token: String?
                var isAuthenticated: Bool

                init() {
                    self.user = nil
                    self.token = nil
                    self.isAuthenticated = false
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 5: @State with array and dictionary properties
    func testStateMacroWithCollectionProperties() throws {
        assertMacroExpansion(
            """
            @State
            struct CartState {
                var items: [CartItem]
                var metadata: [String: Any]
                var total: Double
            }
            """,
            expandedSource: """
            struct CartState {
                var items: [CartItem]
                var metadata: [String: Any]
                var total: Double

                init() {
                    self.items = []
                    self.metadata = [:]
                    self.total = 0.0
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 6: @State with public modifier
    func testStateMacroWithPublicModifier() throws {
        assertMacroExpansion(
            """
            @State
            public struct AppState {
                public var isLoading: Bool
                public var error: Error?
            }
            """,
            expandedSource: """
            public struct AppState {
                public var isLoading: Bool
                public var error: Error?

                public init() {
                    self.isLoading = false
                    self.error = nil
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 7: @State with computed properties
    func testStateMacroWithComputedProperties() throws {
        assertMacroExpansion(
            """
            @State
            struct OrderState {
                var items: [OrderItem]
                var discount: Double
                
                var subtotal: Double {
                    items.reduce(0) { $0 + $1.price }
                }
                
                var total: Double {
                    subtotal - discount
                }
            }
            """,
            expandedSource: """
            struct OrderState {
                var items: [OrderItem]
                var discount: Double
                
                var subtotal: Double {
                    items.reduce(0) { $0 + $1.price }
                }
                
                var total: Double {
                    subtotal - discount
                }

                init() {
                    self.items = []
                    self.discount = 0.0
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 8: @State with let constants
    func testStateMacroWithConstants() throws {
        assertMacroExpansion(
            """
            @State
            struct ConfigState {
                let version: String
                let environment: String
                var settings: [String: String]
                
                init() {
                    self.version = "1.0.0"
                    self.environment = "production"
                    self.settings = [:]
                }
            }
            """,
            expandedSource: """
            struct ConfigState {
                let version: String
                let environment: String
                var settings: [String: String]
                
                init() {
                    self.version = "1.0.0"
                    self.environment = "production"
                    self.settings = [:]
                }
            }
            """,
            macros: testMacros
        )
    }
}