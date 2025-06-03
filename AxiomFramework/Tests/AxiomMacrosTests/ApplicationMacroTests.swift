import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Writing failing tests for @Application macro

final class ApplicationMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Application": ApplicationMacro.self,
    ]
    
    // Test 1: Basic @Application macro expansion
    func testBasicApplicationMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Application
            struct MyApp {
                func configure() async throws {
                    // App configuration
                }
            }
            """,
            expandedSource: """
            struct MyApp {
                func configure() async throws {
                    // App configuration
                }

                @main
                static func main() async throws {
                    let app = MyApp()
                    try await app.configure()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @Application without configure method
    func testApplicationMacroWithoutConfigure() throws {
        assertMacroExpansion(
            """
            @Application
            struct SimpleApp {
            }
            """,
            expandedSource: """
            struct SimpleApp {

                func configure() async throws {
                    // Default configuration
                }

                @main
                static func main() async throws {
                    let app = SimpleApp()
                    try await app.configure()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: @Application on non-struct produces diagnostic
    func testApplicationMacroOnNonStructProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Application
            class MyApp {
                func configure() async throws {}
            }
            """,
            expandedSource: """
            class MyApp {
                func configure() async throws {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Application can only be applied to structs",
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
    
    // Test 4: @Application with existing main method
    func testApplicationMacroWithExistingMain() throws {
        assertMacroExpansion(
            """
            @Application
            struct CustomApp {
                func configure() async throws {
                    print("Configuring...")
                }

                @main
                static func main() async throws {
                    print("Custom main")
                    let app = CustomApp()
                    try await app.configure()
                }
            }
            """,
            expandedSource: """
            struct CustomApp {
                func configure() async throws {
                    print("Configuring...")
                }

                @main
                static func main() async throws {
                    print("Custom main")
                    let app = CustomApp()
                    try await app.configure()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 5: @Application with public modifier
    func testApplicationMacroWithPublicModifier() throws {
        assertMacroExpansion(
            """
            @Application
            public struct PublicApp {
                public func configure() async throws {
                    // Configuration
                }
            }
            """,
            expandedSource: """
            public struct PublicApp {
                public func configure() async throws {
                    // Configuration
                }

                @main
                public static func main() async throws {
                    let app = PublicApp()
                    try await app.configure()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 6: @Application with parameters in configure
    func testApplicationMacroWithConfigureParameters() throws {
        assertMacroExpansion(
            """
            @Application
            struct ParameterizedApp {
                func configure(environment: String) async throws {
                    // Configuration with environment
                }
            }
            """,
            expandedSource: """
            struct ParameterizedApp {
                func configure(environment: String) async throws {
                    // Configuration with environment
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "configure() must have no parameters",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove parameters from configure()")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 7: @Application with non-async configure
    func testApplicationMacroWithNonAsyncConfigure() throws {
        assertMacroExpansion(
            """
            @Application
            struct SyncApp {
                func configure() throws {
                    // Synchronous configuration
                }
            }
            """,
            expandedSource: """
            struct SyncApp {
                func configure() throws {
                    // Synchronous configuration
                }

                @main
                static func main() async throws {
                    let app = SyncApp()
                    try app.configure()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 8: @Application with private configure
    func testApplicationMacroWithPrivateConfigure() throws {
        assertMacroExpansion(
            """
            @Application
            struct PrivateApp {
                private func configure() async throws {
                    // Private configuration
                }
            }
            """,
            expandedSource: """
            struct PrivateApp {
                private func configure() async throws {
                    // Private configuration
                }

                @main
                static func main() async throws {
                    let app = PrivateApp()
                    try await app.configure()
                }
            }
            """,
            macros: testMacros
        )
    }
}