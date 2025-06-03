import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Writing failing tests for @Presentation macro

final class PresentationMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Presentation": PresentationMacro.self,
    ]
    
    // Test 1: Basic @Presentation macro expansion with context
    func testBasicPresentationMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Presentation
            struct HomeView {
                let context: HomeContext
            }
            """,
            expandedSource: """
            struct HomeView {
                let context: HomeContext

                var body: some View {
                    Text("HomeView")
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @Presentation with @ObservedObject context
    func testPresentationMacroWithObservedObjectContext() throws {
        assertMacroExpansion(
            """
            @Presentation
            struct ProfileView {
                @ObservedObject var context: ProfileContext
            }
            """,
            expandedSource: """
            struct ProfileView {
                @ObservedObject var context: ProfileContext

                var body: some View {
                    Text("ProfileView")
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: @Presentation on non-struct produces diagnostic
    func testPresentationMacroOnNonStructProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Presentation
            class HomeView {
                let context: HomeContext
            }
            """,
            expandedSource: """
            class HomeView {
                let context: HomeContext
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Presentation can only be applied to structs",
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
    
    // Test 4: @Presentation without context property produces diagnostic
    func testPresentationMacroWithoutContextProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Presentation
            struct HomeView {
                let title: String
            }
            """,
            expandedSource: """
            struct HomeView {
                let title: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Presentation requires a 'context' property",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Add 'var context: YourContext' property")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 5: @Presentation with existing body property
    func testPresentationMacroWithExistingBody() throws {
        assertMacroExpansion(
            """
            @Presentation
            struct CustomView {
                @ObservedObject var context: CustomContext
                
                var body: some View {
                    VStack {
                        Text("Custom Implementation")
                    }
                }
            }
            """,
            expandedSource: """
            struct CustomView {
                @ObservedObject var context: CustomContext
                
                var body: some View {
                    VStack {
                        Text("Custom Implementation")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 6: @Presentation with public modifier
    func testPresentationMacroWithPublicModifier() throws {
        assertMacroExpansion(
            """
            @Presentation
            public struct PublicView {
                public let context: PublicContext
            }
            """,
            expandedSource: """
            public struct PublicView {
                public let context: PublicContext

                public var body: some View {
                    Text("PublicView")
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 7: @Presentation with multiple context-like properties
    func testPresentationMacroWithMultipleContextProperties() throws {
        assertMacroExpansion(
            """
            @Presentation
            struct ComplexView {
                @ObservedObject var context: MainContext
                let subContext: SubContext
                var otherContext: OtherContext?
            }
            """,
            expandedSource: """
            struct ComplexView {
                @ObservedObject var context: MainContext
                let subContext: SubContext
                var otherContext: OtherContext?

                var body: some View {
                    Text("ComplexView")
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 8: @Presentation with generic context type
    func testPresentationMacroWithGenericContext() throws {
        assertMacroExpansion(
            """
            @Presentation
            struct GenericView<C: Context> {
                let context: C
            }
            """,
            expandedSource: """
            struct GenericView<C: Context> {
                let context: C

                var body: some View {
                    Text("GenericView")
                }
            }
            """,
            macros: testMacros
        )
    }
}