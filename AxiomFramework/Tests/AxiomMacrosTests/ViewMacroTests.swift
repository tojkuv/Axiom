import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations are tested separately
#if canImport(AxiomMacros)
import AxiomMacros

final class ViewMacroTests: XCTestCase {
    
    // MARK: - Basic Functionality Tests
    
    func testViewMacroExpansion() throws {
        assertMacroExpansion(
            """
            @View(MyContext)
            struct MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            expandedSource: """
            struct MyView: View {
                var body: some View {
                    Text("Hello")
                }

                @ObservedObject var context: MyContext

                public init(context: MyContext) {
                    self.context = context
                }

                private func axiomOnAppear() async {
                    await context.onAppear()
                }

                private func axiomOnDisappear() async {
                    await context.onDisappear()
                }

                @State private var showingError = false

                private func queryIntelligence(_ query: String) async -> String? {
                    return await context.intelligence.query(query)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testViewMacroWithGenericContext() throws {
        assertMacroExpansion(
            """
            @View(GenericContext<String>)
            struct GenericView: View {
                var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            struct GenericView: View {
                var body: some View {
                    EmptyView()
                }

                @ObservedObject var context: GenericContext<String>

                public init(context: GenericContext<String>) {
                    self.context = context
                }

                private func axiomOnAppear() async {
                    await context.onAppear()
                }

                private func axiomOnDisappear() async {
                    await context.onDisappear()
                }

                @State private var showingError = false

                private func queryIntelligence(_ query: String) async -> String? {
                    return await context.intelligence.query(query)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Error Cases
    
    func testViewMacroOnNonStruct() throws {
        assertMacroExpansion(
            """
            @View(MyContext)
            class MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            expandedSource: """
            class MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@View can only be applied to structs", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testViewMacroOnNonViewStruct() throws {
        assertMacroExpansion(
            """
            @View(MyContext)
            struct MyModel {
                let name: String
            }
            """,
            expandedSource: """
            struct MyModel {
                let name: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@View can only be used in structs that conform to View", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testViewMacroMissingContextArgument() throws {
        assertMacroExpansion(
            """
            @View
            struct MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            expandedSource: """
            struct MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@View requires a context type argument", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testViewMacroInvalidContextType() throws {
        assertMacroExpansion(
            """
            @View(lowercase)
            struct MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            expandedSource: """
            struct MyView: View {
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@View context type must be a valid type identifier", line: 1, column: 7)
            ],
            macros: testMacros
        )
    }
    
    func testViewMacroWithExistingContextProperty() throws {
        assertMacroExpansion(
            """
            @View(MyContext)
            struct MyView: View {
                let context: SomeOtherType
                
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            expandedSource: """
            struct MyView: View {
                let context: SomeOtherType
                
                var body: some View {
                    Text("Hello")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@View cannot be applied to structs that already have a 'context' property", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Integration Tests
    
    func testViewMacroWithExistingProperties() throws {
        assertMacroExpansion(
            """
            @View(UserContext)
            struct UserView: View {
                @State private var username: String = ""
                @Binding var isPresented: Bool
                
                var body: some View {
                    VStack {
                        TextField("Username", text: $username)
                        Button("Close") { isPresented = false }
                    }
                }
            }
            """,
            expandedSource: """
            struct UserView: View {
                @State private var username: String = ""
                @Binding var isPresented: Bool
                
                var body: some View {
                    VStack {
                        TextField("Username", text: $username)
                        Button("Close") { isPresented = false }
                    }
                }

                @ObservedObject var context: UserContext

                public init(context: UserContext) {
                    self.context = context
                }

                private func axiomOnAppear() async {
                    await context.onAppear()
                }

                private func axiomOnDisappear() async {
                    await context.onDisappear()
                }

                @State private var showingError = false

                private func queryIntelligence(_ query: String) async -> String? {
                    return await context.intelligence.query(query)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testViewMacroWithExistingInit() throws {
        assertMacroExpansion(
            """
            @View(DataContext)
            struct DataView: View {
                @State private var data: [String] = []
                
                init(data: [String]) {
                    self._data = State(initialValue: data)
                }
                
                var body: some View {
                    List(data, id: \\.self) { item in
                        Text(item)
                    }
                }
            }
            """,
            expandedSource: """
            struct DataView: View {
                @State private var data: [String] = []
                
                init(data: [String]) {
                    self._data = State(initialValue: data)
                }
                
                var body: some View {
                    List(data, id: \\.self) { item in
                        Text(item)
                    }
                }

                @ObservedObject var context: DataContext

                public init(context: DataContext) {
                    self.context = context
                }

                private func axiomOnAppear() async {
                    await context.onAppear()
                }

                private func axiomOnDisappear() async {
                    await context.onDisappear()
                }

                @State private var showingError = false

                private func queryIntelligence(_ query: String) async -> String? {
                    return await context.intelligence.query(query)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Complex Context Types
    
    func testViewMacroWithNestedGenericContext() throws {
        assertMacroExpansion(
            """
            @View(ComplexContext<Data.Model, String>)
            struct ComplexView: View {
                var body: some View {
                    Text("Complex")
                }
            }
            """,
            expandedSource: """
            struct ComplexView: View {
                var body: some View {
                    Text("Complex")
                }

                @ObservedObject var context: ComplexContext<Data.Model, String>

                public init(context: ComplexContext<Data.Model, String>) {
                    self.context = context
                }

                private func axiomOnAppear() async {
                    await context.onAppear()
                }

                private func axiomOnDisappear() async {
                    await context.onDisappear()
                }

                @State private var showingError = false

                private func queryIntelligence(_ query: String) async -> String? {
                    return await context.intelligence.query(query)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Test Infrastructure
    
    private let testMacros: [String: Macro.Type] = [
        "View": ViewMacro.self,
    ]
}

// MARK: - Test Support Extensions

extension ViewMacroTests {
    
    /// Creates a diagnostic spec for easier testing
    private func diagnostic(
        _ message: String,
        line: Int,
        column: Int
    ) -> DiagnosticSpec {
        DiagnosticSpec(message: message, line: line, column: column)
    }
    
    /// Helper for testing macro expansion with custom context
    private func assertViewMacroExpansion(
        original: String,
        expected: String,
        contextType: String = "TestContext",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let originalWithMacro = """
        @View(\(contextType))
        \(original)
        """
        
        assertMacroExpansion(
            originalWithMacro,
            expandedSource: expected,
            macros: testMacros,
            file: file,
            line: line
        )
    }
}

#endif