import XCTest
import AxiomTesting
@testable import AxiomMacros
@testable import AxiomCapabilities
import SwiftSyntaxMacrosTestSupport

/// Comprehensive tests for AxiomMacros capability macro functionality
final class CapabilityMacroTests: XCTestCase {
    
    // MARK: - Basic Capability Macro Tests
    
    func testCapabilityMacroOnStruct() throws {
        assertMacroExpansion(
            """
            @AxiomCapability("analytics")
            struct AnalyticsCapability {
                let trackingId: String
                let isEnabled: Bool
            }
            """,
            expandedSource: """
            struct AnalyticsCapability {
                let trackingId: String
                let isEnabled: Bool
            }
            
            extension AnalyticsCapability: AxiomCapability {
                var id: String {
                    return "analytics"
                }
                
                var isAvailable: Bool {
                    return isEnabled
                }
                
                func activate() async throws {
                    // Auto-generated activation logic
                    guard isAvailable else {
                        throw AxiomError.capabilityError(.unavailable("Analytics capability is not available"))
                    }
                    // Capability-specific activation code would go here
                }
                
                func deactivate() async {
                    // Auto-generated deactivation logic
                    // Capability-specific cleanup code would go here
                }
                
                func shutdown() async throws {
                    await deactivate()
                    // Additional shutdown procedures
                }
            }
            
            extension AnalyticsCapability: Sendable {
                // Sendable conformance for thread safety
            }
            """,
            macros: ["AxiomCapability": CapabilityMacro.self]
        )
    }
    
    func testCapabilityMacroOnClass() throws {
        assertMacroExpansion(
            """
            @AxiomCapability("network")
            class NetworkCapability: ObservableObject {
                @Published var connectionStatus: String = "disconnected"
            }
            """,
            expandedSource: """
            class NetworkCapability: ObservableObject {
                @Published var connectionStatus: String = "disconnected"
            }
            
            extension NetworkCapability: AxiomCapability {
                var id: String {
                    return "network"
                }
                
                var isAvailable: Bool {
                    return connectionStatus != "unavailable"
                }
                
                func activate() async throws {
                    guard isAvailable else {
                        throw AxiomError.capabilityError(.unavailable("Network capability is not available"))
                    }
                    await MainActor.run {
                        connectionStatus = "connecting"
                    }
                    // Capability-specific activation code would go here
                    await MainActor.run {
                        connectionStatus = "connected"
                    }
                }
                
                func deactivate() async {
                    await MainActor.run {
                        connectionStatus = "disconnected"
                    }
                }
                
                func shutdown() async throws {
                    await deactivate()
                }
            }
            """,
            macros: ["AxiomCapability": CapabilityMacro.self]
        )
    }
    
    func testCapabilityMacroOnActor() throws {
        assertMacroExpansion(
            """
            @AxiomCapability("storage")
            actor StorageCapability {
                private var data: [String: Data] = [:]
            }
            """,
            expandedSource: """
            actor StorageCapability {
                private var data: [String: Data] = [:]
            }
            
            extension StorageCapability: AxiomCapability {
                var id: String {
                    return "storage"
                }
                
                var isAvailable: Bool {
                    return true
                }
                
                func activate() async throws {
                    // Actor-specific activation logic
                    guard isAvailable else {
                        throw AxiomError.capabilityError(.unavailable("Storage capability is not available"))
                    }
                }
                
                func deactivate() async {
                    // Actor-specific deactivation logic
                    data.removeAll()
                }
                
                func shutdown() async throws {
                    await deactivate()
                }
            }
            """,
            macros: ["AxiomCapability": CapabilityMacro.self]
        )
    }
    
    // MARK: - Extended Capability Tests
    
    func testExtendedCapabilityMacro() throws {
        assertMacroExpansion(
            """
            @AxiomCapability("ml")
            struct MLCapability: ExtendedCapability {
                let modelName: String
                let enableGPU: Bool
            }
            """,
            expandedSource: """
            struct MLCapability: ExtendedCapability {
                let modelName: String
                let enableGPU: Bool
            }
            
            extension MLCapability: AxiomExtendedCapability {
                var id: String {
                    return "ml"
                }
                
                var isAvailable: Bool {
                    return !modelName.isEmpty
                }
                
                func activate() async throws {
                    guard isAvailable else {
                        throw AxiomError.capabilityError(.unavailable("ML capability is not available"))
                    }
                    
                    // Extended capability initialization
                    try await initializeResources()
                    try await validateConfiguration()
                }
                
                func deactivate() async {
                    await releaseResources()
                }
                
                func shutdown() async throws {
                    await deactivate()
                    await performCleanup()
                }
                
                func initializeResources() async throws {
                    // Resource initialization logic
                    if enableGPU {
                        // GPU-specific initialization
                    }
                }
                
                func releaseResources() async {
                    // Resource cleanup logic
                }
                
                func validateConfiguration() async throws {
                    // Configuration validation logic
                    guard !modelName.isEmpty else {
                        throw AxiomError.capabilityError(.configurationError("Model name cannot be empty"))
                    }
                }
                
                func performCleanup() async {
                    // Extended cleanup procedures
                }
            }
            
            extension MLCapability: Sendable {
                // Sendable conformance for thread safety
            }
            """,
            macros: ["AxiomCapability": CapabilityMacro.self]
        )
    }
    
    // MARK: - Error Handling Tests
    
    func testCapabilityMacroErrorOnProtocol() throws {
        XCTAssertThrowsError(
            try CapabilityMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomCapability")),
                    arguments: .argumentList([
                        LabeledExprSyntax(
                            expression: StringLiteralExprSyntax(content: "test")
                        )
                    ])
                ),
                attachedTo: ProtocolDeclSyntax(
                    name: .identifier("TestProtocol"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingMembersOf: ProtocolDeclSyntax(
                    name: .identifier("TestProtocol"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is CapabilityMacroError)
        }
    }
    
    func testCapabilityMacroErrorOnEnum() throws {
        XCTAssertThrowsError(
            try CapabilityMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomCapability")),
                    arguments: .argumentList([
                        LabeledExprSyntax(
                            expression: StringLiteralExprSyntax(content: "test")
                        )
                    ])
                ),
                attachedTo: EnumDeclSyntax(
                    name: .identifier("TestEnum"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingMembersOf: EnumDeclSyntax(
                    name: .identifier("TestEnum"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is CapabilityMacroError)
        }
    }
    
    func testCapabilityMacroErrorMissingIdentifier() throws {
        XCTAssertThrowsError(
            try CapabilityMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomCapability"))
                ),
                attachedTo: StructDeclSyntax(
                    name: .identifier("TestCapability"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingMembersOf: StructDeclSyntax(
                    name: .identifier("TestCapability"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                in: TestMacroExpansionContext()
            )
        ) { error in
            if let capabilityError = error as? CapabilityMacroError {
                XCTAssertEqual(capabilityError, .missingCapabilityIdentifier)
            } else {
                XCTFail("Expected CapabilityMacroError.missingCapabilityIdentifier")
            }
        }
    }
    
    // MARK: - Parameter Validation Tests
    
    func testCapabilityMacroWithInvalidIdentifier() throws {
        XCTAssertThrowsError(
            try CapabilityMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomCapability")),
                    arguments: .argumentList([
                        LabeledExprSyntax(
                            expression: StringLiteralExprSyntax(content: "")
                        )
                    ])
                ),
                attachedTo: StructDeclSyntax(
                    name: .identifier("TestCapability"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingMembersOf: StructDeclSyntax(
                    name: .identifier("TestCapability"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                in: TestMacroExpansionContext()
            )
        ) { error in
            if let capabilityError = error as? CapabilityMacroError {
                XCTAssertEqual(capabilityError, .invalidCapabilityIdentifier(""))
            } else {
                XCTFail("Expected CapabilityMacroError.invalidCapabilityIdentifier")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testCapabilityMacroPerformance() throws {
        let iterations = 50
        let expectation = self.expectation(description: "Capability macro expansion performance")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for i in 0..<iterations {
                _ = try? CapabilityMacro.expansion(
                    of: AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("AxiomCapability")),
                        arguments: .argumentList([
                            LabeledExprSyntax(
                                expression: StringLiteralExprSyntax(content: "test_\\(i)")
                            )
                        ])
                    ),
                    attachedTo: StructDeclSyntax(
                        name: .identifier("TestCapability"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    providingMembersOf: StructDeclSyntax(
                        name: .identifier("TestCapability"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    in: TestMacroExpansionContext()
                )
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let averageTime = (endTime - startTime) / Double(iterations)
            
            XCTAssertLessThan(averageTime, 0.003, "Capability macro expansion should be fast (< 3ms per expansion)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Complex Capability Tests
    
    func testCapabilityMacroWithGenericType() throws {
        assertMacroExpansion(
            """
            @AxiomCapability("generic")
            struct GenericCapability<T: Codable>: ObservableObject {
                let data: T
                @Published var isProcessing: Bool = false
            }
            """,
            expandedSource: """
            struct GenericCapability<T: Codable>: ObservableObject {
                let data: T
                @Published var isProcessing: Bool = false
            }
            
            extension GenericCapability: AxiomCapability {
                var id: String {
                    return "generic"
                }
                
                var isAvailable: Bool {
                    return !isProcessing
                }
                
                func activate() async throws {
                    guard isAvailable else {
                        throw AxiomError.capabilityError(.unavailable("Generic capability is not available"))
                    }
                    await MainActor.run {
                        isProcessing = true
                    }
                    // Generic capability activation
                    await MainActor.run {
                        isProcessing = false
                    }
                }
                
                func deactivate() async {
                    await MainActor.run {
                        isProcessing = false
                    }
                }
                
                func shutdown() async throws {
                    await deactivate()
                }
            }
            """,
            macros: ["AxiomCapability": CapabilityMacro.self]
        )
    }
}

// MARK: - Test Helper

/// Test macro expansion context for capability testing
class TestMacroExpansionContext: MacroExpansionContext {
    func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax(.identifier("\\(name)_\\(UUID().uuidString.prefix(8))"), presence: .present)
    }
    
    func diagnose(_ diagnostic: Diagnostic) {
        // Handle diagnostics in tests
    }
}

// MARK: - CapabilityMacroError for Testing

enum CapabilityMacroError: Error, LocalizedError, Equatable {
    case mustBeAppliedToStructOrClass
    case missingCapabilityIdentifier
    case invalidCapabilityIdentifier(String)
    case invalidParameter(String)
    
    var errorDescription: String? {
        switch self {
        case .mustBeAppliedToStructOrClass:
            return "CapabilityMacro can only be applied to struct or class declarations"
        case .missingCapabilityIdentifier:
            return "CapabilityMacro requires a capability identifier parameter"
        case .invalidCapabilityIdentifier(let id):
            return "Invalid capability identifier: '\\(id)'"
        case .invalidParameter(let param):
            return "Invalid parameter: \\(param)"
        }
    }
}