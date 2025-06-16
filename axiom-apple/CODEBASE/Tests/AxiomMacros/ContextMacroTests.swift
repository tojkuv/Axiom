import XCTest
import AxiomTesting
@testable import AxiomMacros
@testable import AxiomArchitecture
import SwiftSyntaxMacrosTestSupport

/// Comprehensive tests for AxiomMacros context macro functionality
final class ContextMacroTests: XCTestCase {
    
    // MARK: - Basic Context Macro Tests
    
    func testContextMacroOnClass() throws {
        assertMacroExpansion(
            """
            @AxiomContext(client: TodoClient.self)
            class TodoContext: ObservableObject {
                
            }
            """,
            expandedSource: """
            class TodoContext: ObservableObject {
                
            }
            
            extension TodoContext {
                var client: TodoClient {
                    return TodoClient.shared
                }
                
                private var observationTask: Task<Void, Never>?
                
                func viewAppeared() {
                    startObservation()
                }
                
                func viewDisappeared() {
                    stopObservation()
                }
                
                private func startObservation() {
                    observationTask = Task { @MainActor in
                        for await _ in client.stateStream {
                            await handleStateUpdate()
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                private func handleStateUpdate() async {
                    // Auto-generated state update handling
                    objectWillChange.send()
                }
            }
            """,
            macros: ["AxiomContext": ContextMacro.self]
        )
    }
    
    func testContextMacroWithAutoObserving() throws {
        assertMacroExpansion(
            """
            @Context(observing: UserClient.self)
            @AxiomContext(client: UserClient.self)
            class UserContext: AxiomObservableContext {
                
            }
            """,
            expandedSource: """
            @Context(observing: UserClient.self)
            class UserContext: AxiomObservableContext {
                
            }
            
            extension UserContext {
                var client: UserClient {
                    return UserClient.shared
                }
                
                private var observationTask: Task<Void, Never>?
                var updateTrigger = PassthroughSubject<Void, Never>()
                var isActive = false
                var appearanceCount = 0
                
                func performAppearance() {
                    appearanceCount += 1
                    isActive = true
                    startObservation()
                }
                
                func performDisappearance() {
                    isActive = false
                    stopObservation()
                }
                
                private func startObservation() {
                    observationTask = Task { @MainActor in
                        for await _ in client.stateStream {
                            await handleStateUpdate()
                            triggerUpdate()
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                private func handleStateUpdate() async {
                    objectWillChange.send()
                }
                
                private func triggerUpdate() {
                    updateTrigger.send()
                }
            }
            """,
            macros: [
                "AxiomContext": ContextMacro.self,
                "Context": ContextMacro.self
            ]
        )
    }
    
    // MARK: - Error Handling Tests
    
    func testContextMacroErrorOnStruct() throws {
        XCTAssertThrowsError(
            try ContextMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomContext"))
                ),
                attachedTo: StructDeclSyntax(
                    name: .identifier("TestStruct"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestStruct")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is ContextMacroError)
        }
    }
    
    func testContextMacroErrorOnEnum() throws {
        XCTAssertThrowsError(
            try ContextMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomContext"))
                ),
                attachedTo: EnumDeclSyntax(
                    name: .identifier("TestEnum"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestEnum")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is ContextMacroError)
        }
    }
    
    // MARK: - Parameter Validation Tests
    
    func testContextMacroWithInvalidClientType() throws {
        // Test with missing client parameter
        XCTAssertThrowsError(
            try ContextMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomContext"))
                ),
                attachedTo: ClassDeclSyntax(
                    name: .identifier("TestContext"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestContext")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            if let contextError = error as? ContextMacroError {
                XCTAssertEqual(contextError, .missingClientParameter)
            } else {
                XCTFail("Expected ContextMacroError.missingClientParameter")
            }
        }
    }
    
    // MARK: - Actor Context Tests
    
    func testContextMacroOnActor() throws {
        assertMacroExpansion(
            """
            @AxiomContext(client: TaskClient.self)
            actor TaskContext {
                
            }
            """,
            expandedSource: """
            actor TaskContext {
                
            }
            
            extension TaskContext {
                var client: TaskClient {
                    get async {
                        return await TaskClient.shared
                    }
                }
                
                private var observationTask: Task<Void, Never>?
                
                func startObservation() async {
                    observationTask = Task {
                        for await _ in await client.stateStream {
                            await handleStateUpdate()
                        }
                    }
                }
                
                func stopObservation() async {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                private func handleStateUpdate() async {
                    // Actor-specific state update handling
                }
            }
            """,
            macros: ["AxiomContext": ContextMacro.self]
        )
    }
    
    // MARK: - Performance Tests
    
    func testContextMacroPerformance() throws {
        let iterations = 50
        let expectation = self.expectation(description: "Context macro expansion performance")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for _ in 0..<iterations {
                _ = try? ContextMacro.expansion(
                    of: AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("AxiomContext")),
                        arguments: .argumentList([
                            LabeledExprSyntax(
                                label: .identifier("client"),
                                expression: MemberAccessExprSyntax(
                                    base: IdentifierExprSyntax(identifier: .identifier("TestClient")),
                                    dot: .periodToken(),
                                    name: .identifier("self")
                                )
                            )
                        ])
                    ),
                    attachedTo: ClassDeclSyntax(
                        name: .identifier("TestContext"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestContext")),
                    conformingTo: [],
                    in: TestMacroExpansionContext()
                )
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let averageTime = (endTime - startTime) / Double(iterations)
            
            XCTAssertLessThan(averageTime, 0.002, "Context macro expansion should be fast (< 2ms per expansion)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Complex Context Tests
    
    func testContextMacroWithInheritance() throws {
        assertMacroExpansion(
            """
            @AxiomContext(client: DataClient.self)
            class DataContext: BaseContext {
                
            }
            """,
            expandedSource: """
            class DataContext: BaseContext {
                
            }
            
            extension DataContext {
                var client: DataClient {
                    return DataClient.shared
                }
                
                private var observationTask: Task<Void, Never>?
                
                func viewAppeared() {
                    super.viewAppeared()
                    startObservation()
                }
                
                func viewDisappeared() {
                    super.viewDisappeared()
                    stopObservation()
                }
                
                private func startObservation() {
                    observationTask = Task { @MainActor in
                        for await _ in client.stateStream {
                            await handleStateUpdate()
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                private func handleStateUpdate() async {
                    objectWillChange.send()
                }
            }
            """,
            macros: ["AxiomContext": ContextMacro.self]
        )
    }
}

// MARK: - Test Helper

/// Test macro expansion context for context testing
class TestMacroExpansionContext: MacroExpansionContext {
    func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax(.identifier("\\(name)_\\(UUID().uuidString.prefix(8))"), presence: .present)
    }
    
    func diagnose(_ diagnostic: Diagnostic) {
        // Handle diagnostics in tests
    }
}

// MARK: - ContextMacroError for Testing

enum ContextMacroError: Error, LocalizedError, Equatable {
    case mustBeAppliedToClass
    case mustBeAppliedToActor
    case missingClientParameter
    case invalidClientType(String)
    case invalidParameter(String)
    
    var errorDescription: String? {
        switch self {
        case .mustBeAppliedToClass:
            return "ContextMacro can only be applied to class declarations"
        case .mustBeAppliedToActor:
            return "ContextMacro can only be applied to actor declarations"
        case .missingClientParameter:
            return "ContextMacro requires a client parameter"
        case .invalidClientType(let type):
            return "Invalid client type: \\(type)"
        case .invalidParameter(let param):
            return "Invalid parameter: \\(param)"
        }
    }
}