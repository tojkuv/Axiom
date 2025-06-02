import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations are tested separately
#if canImport(AxiomMacros)
import AxiomMacros

final class ObservableStateMacroTests: XCTestCase {
    
    // MARK: - Basic Functionality Tests
    
    func testObservableStateMacroExpansion() throws {
        assertMacroExpansion(
            """
            @ObservableState
            struct UserState {
                let name: String
                var age: Int
                var isActive: Bool
            }
            """,
            expandedSource: """
            struct UserState {
                let name: String
                var age: Int
                var isActive: Bool

                // MARK: - Observable State Properties
                @Published private var _stateVersion: Int = 0
                
                // MARK: - State Change Notifications
                private func notifyStateChange() {
                    _stateVersion += 1
                }
                
                // MARK: - Observable State Setters
                mutating func setAge(_ newValue: Int) {
                    if age != newValue {
                        age = newValue
                        notifyStateChange()
                    }
                }
                
                mutating func setIsActive(_ newValue: Bool) {
                    if isActive != newValue {
                        isActive = newValue
                        notifyStateChange()
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testObservableStateMacroWithNoVarProperties() throws {
        assertMacroExpansion(
            """
            @ObservableState
            struct ReadOnlyState {
                let id: String
                let timestamp: Date
            }
            """,
            expandedSource: """
            struct ReadOnlyState {
                let id: String
                let timestamp: Date

                // MARK: - Observable State Properties
                @Published private var _stateVersion: Int = 0
                
                // MARK: - State Change Notifications
                private func notifyStateChange() {
                    _stateVersion += 1
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testObservableStateMacroWithComplexTypes() throws {
        assertMacroExpansion(
            """
            @ObservableState
            struct ComplexState {
                var items: [String]
                var metadata: [String: Any]
                var currentIndex: Int?
            }
            """,
            expandedSource: """
            struct ComplexState {
                var items: [String]
                var metadata: [String: Any]
                var currentIndex: Int?

                // MARK: - Observable State Properties
                @Published private var _stateVersion: Int = 0
                
                // MARK: - State Change Notifications
                private func notifyStateChange() {
                    _stateVersion += 1
                }
                
                // MARK: - Observable State Setters
                mutating func setItems(_ newValue: [String]) {
                    if items != newValue {
                        items = newValue
                        notifyStateChange()
                    }
                }
                
                mutating func setCurrentIndex(_ newValue: Int?) {
                    if currentIndex != newValue {
                        currentIndex = newValue
                        notifyStateChange()
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Error Cases
    
    func testObservableStateMacroOnEnum() throws {
        assertMacroExpansion(
            """
            @ObservableState
            enum Status {
                case active, inactive
            }
            """,
            expandedSource: """
            enum Status {
                case active, inactive
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ObservableState can only be applied to structs or classes", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testObservableStateMacroOnActor() throws {
        assertMacroExpansion(
            """
            @ObservableState
            actor DataActor {
                var data: String = ""
            }
            """,
            expandedSource: """
            actor DataActor {
                var data: String = ""
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ObservableState can only be applied to structs or classes", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Integration Tests
    
    func testObservableStateMacroWithExistingMethods() throws {
        assertMacroExpansion(
            """
            @ObservableState
            struct StateWithMethods {
                var count: Int = 0
                
                func increment() {
                    setCount(count + 1)
                }
                
                func reset() {
                    setCount(0)
                }
            }
            """,
            expandedSource: """
            struct StateWithMethods {
                var count: Int = 0
                
                func increment() {
                    setCount(count + 1)
                }
                
                func reset() {
                    setCount(0)
                }

                // MARK: - Observable State Properties
                @Published private var _stateVersion: Int = 0
                
                // MARK: - State Change Notifications
                private func notifyStateChange() {
                    _stateVersion += 1
                }
                
                // MARK: - Observable State Setters
                mutating func setCount(_ newValue: Int) {
                    if count != newValue {
                        count = newValue
                        notifyStateChange()
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testObservableStateMacroWithPrivateProperties() throws {
        assertMacroExpansion(
            """
            @ObservableState
            struct PrivatePropsState {
                private var internalCounter: Int = 0
                var publicCounter: Int = 0
            }
            """,
            expandedSource: """
            struct PrivatePropsState {
                private var internalCounter: Int = 0
                var publicCounter: Int = 0

                // MARK: - Observable State Properties
                @Published private var _stateVersion: Int = 0
                
                // MARK: - State Change Notifications
                private func notifyStateChange() {
                    _stateVersion += 1
                }
                
                // MARK: - Observable State Setters
                mutating func setPublicCounter(_ newValue: Int) {
                    if publicCounter != newValue {
                        publicCounter = newValue
                        notifyStateChange()
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Class Support Tests
    
    func testObservableStateMacroOnClass() throws {
        assertMacroExpansion(
            """
            @ObservableState
            class UserStore {
                var currentUser: String?
                var isLoggedIn: Bool = false
            }
            """,
            expandedSource: """
            class UserStore {
                var currentUser: String?
                var isLoggedIn: Bool = false

                // MARK: - Observable State Properties
                @Published private var _stateVersion: Int = 0
                
                // MARK: - State Change Notifications
                private func notifyStateChange() {
                    _stateVersion += 1
                }
                
                // MARK: - Observable State Setters
                func setCurrentUser(_ newValue: String?) {
                    if currentUser != newValue {
                        currentUser = newValue
                        notifyStateChange()
                    }
                }
                
                func setIsLoggedIn(_ newValue: Bool) {
                    if isLoggedIn != newValue {
                        isLoggedIn = newValue
                        notifyStateChange()
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Test Infrastructure
    
    private let testMacros: [String: Macro.Type] = [
        "ObservableState": ObservableStateMacro.self,
    ]
}

// MARK: - Test Support Extensions

extension ObservableStateMacroTests {
    
    /// Creates a diagnostic spec for easier testing
    private func diagnostic(
        _ message: String,
        line: Int,
        column: Int
    ) -> DiagnosticSpec {
        DiagnosticSpec(message: message, line: line, column: column)
    }
    
    /// Helper for testing macro expansion with custom variations
    private func assertObservableStateMacroExpansion(
        original: String,
        expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let originalWithMacro = """
        @ObservableState
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