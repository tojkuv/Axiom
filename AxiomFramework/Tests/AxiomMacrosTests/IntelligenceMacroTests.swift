import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations are tested separately
#if canImport(AxiomMacros)
import AxiomMacros

final class IntelligenceMacroTests: XCTestCase {
    
    // MARK: - Basic Functionality Tests
    
    func testIntelligenceMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: ["componentAnalysis", "performanceOptimization"])
            struct AnalyticsContext {
                let dataClient: DataClient
                let intelligence: AxiomIntelligence
            }
            """,
            expandedSource: """
            struct AnalyticsContext {
                let dataClient: DataClient
                let intelligence: AxiomIntelligence

                // MARK: - Intelligence Configuration
                private let intelligenceFeatures: Set<String> = ["componentAnalysis", "performanceOptimization"]
                
                // MARK: - Intelligence Capability Registration
                func registerIntelligenceCapabilities() async {
                    await intelligence.registerCapabilities(features: intelligenceFeatures)
                    await intelligence.enableFeature("componentAnalysis")
                    await intelligence.enableFeature("performanceOptimization")
                }
                
                // MARK: - Intelligence Query Methods
                func queryComponentAnalysis(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("componentAnalysis") else { return nil }
                    return await intelligence.query(query, feature: "componentAnalysis")
                }
                
                func queryPerformanceOptimization(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("performanceOptimization") else { return nil }
                    return await intelligence.query(query, feature: "performanceOptimization")
                }
                
                // MARK: - Intelligence Status Methods
                func isIntelligenceFeatureEnabled(_ feature: String) -> Bool {
                    return intelligenceFeatures.contains(feature)
                }
                
                func getEnabledIntelligenceFeatures() -> Set<String> {
                    return intelligenceFeatures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testIntelligenceMacroWithSingleFeature() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: ["patternDetection"])
            class IntelligenceService {
                let intelligence: AxiomIntelligence
            }
            """,
            expandedSource: """
            class IntelligenceService {
                let intelligence: AxiomIntelligence

                // MARK: - Intelligence Configuration
                private let intelligenceFeatures: Set<String> = ["patternDetection"]
                
                // MARK: - Intelligence Capability Registration
                func registerIntelligenceCapabilities() async {
                    await intelligence.registerCapabilities(features: intelligenceFeatures)
                    await intelligence.enableFeature("patternDetection")
                }
                
                // MARK: - Intelligence Query Methods
                func queryPatternDetection(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("patternDetection") else { return nil }
                    return await intelligence.query(query, feature: "patternDetection")
                }
                
                // MARK: - Intelligence Status Methods
                func isIntelligenceFeatureEnabled(_ feature: String) -> Bool {
                    return intelligenceFeatures.contains(feature)
                }
                
                func getEnabledIntelligenceFeatures() -> Set<String> {
                    return intelligenceFeatures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testIntelligenceMacroWithNoFeatures() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: [])
            struct BasicContext {
                let intelligence: AxiomIntelligence
            }
            """,
            expandedSource: """
            struct BasicContext {
                let intelligence: AxiomIntelligence

                // MARK: - Intelligence Configuration
                private let intelligenceFeatures: Set<String> = []
                
                // MARK: - Intelligence Capability Registration
                func registerIntelligenceCapabilities() async {
                    await intelligence.registerCapabilities(features: intelligenceFeatures)
                }
                
                // MARK: - Intelligence Status Methods
                func isIntelligenceFeatureEnabled(_ feature: String) -> Bool {
                    return intelligenceFeatures.contains(feature)
                }
                
                func getEnabledIntelligenceFeatures() -> Set<String> {
                    return intelligenceFeatures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Error Cases
    
    func testIntelligenceMacroOnEnum() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: ["analysis"])
            enum IntelligenceType {
                case component, performance
            }
            """,
            expandedSource: """
            enum IntelligenceType {
                case component, performance
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Intelligence can only be applied to structs or classes", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testIntelligenceMacroMissingFeatures() throws {
        assertMacroExpansion(
            """
            @Intelligence
            struct MissingFeaturesContext {
                let intelligence: AxiomIntelligence
            }
            """,
            expandedSource: """
            struct MissingFeaturesContext {
                let intelligence: AxiomIntelligence
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Intelligence requires a features array argument", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testIntelligenceMacroMissingIntelligenceProperty() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: ["analysis"])
            struct NoIntelligenceContext {
                let dataClient: DataClient
            }
            """,
            expandedSource: """
            struct NoIntelligenceContext {
                let dataClient: DataClient
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Intelligence requires a property of type AxiomIntelligence", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Integration Tests
    
    func testIntelligenceMacroWithExistingMethods() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: ["naturalLanguageQuery"])
            struct SmartContext {
                let intelligence: AxiomIntelligence
                
                func customQuery(_ text: String) async -> String? {
                    return await intelligence.query(text)
                }
            }
            """,
            expandedSource: """
            struct SmartContext {
                let intelligence: AxiomIntelligence
                
                func customQuery(_ text: String) async -> String? {
                    return await intelligence.query(text)
                }

                // MARK: - Intelligence Configuration
                private let intelligenceFeatures: Set<String> = ["naturalLanguageQuery"]
                
                // MARK: - Intelligence Capability Registration
                func registerIntelligenceCapabilities() async {
                    await intelligence.registerCapabilities(features: intelligenceFeatures)
                    await intelligence.enableFeature("naturalLanguageQuery")
                }
                
                // MARK: - Intelligence Query Methods
                func queryNaturalLanguageQuery(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("naturalLanguageQuery") else { return nil }
                    return await intelligence.query(query, feature: "naturalLanguageQuery")
                }
                
                // MARK: - Intelligence Status Methods
                func isIntelligenceFeatureEnabled(_ feature: String) -> Bool {
                    return intelligenceFeatures.contains(feature)
                }
                
                func getEnabledIntelligenceFeatures() -> Set<String> {
                    return intelligenceFeatures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testIntelligenceMacroWithComplexFeatureNames() throws {
        assertMacroExpansion(
            """
            @Intelligence(features: ["deep_learning_analysis", "ML-pattern-detection", "aiOptimization"])
            actor IntelligentActor {
                let intelligence: AxiomIntelligence
            }
            """,
            expandedSource: """
            actor IntelligentActor {
                let intelligence: AxiomIntelligence

                // MARK: - Intelligence Configuration
                private let intelligenceFeatures: Set<String> = ["deep_learning_analysis", "ML-pattern-detection", "aiOptimization"]
                
                // MARK: - Intelligence Capability Registration
                func registerIntelligenceCapabilities() async {
                    await intelligence.registerCapabilities(features: intelligenceFeatures)
                    await intelligence.enableFeature("deep_learning_analysis")
                    await intelligence.enableFeature("ML-pattern-detection")
                    await intelligence.enableFeature("aiOptimization")
                }
                
                // MARK: - Intelligence Query Methods
                func queryDeepLearningAnalysis(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("deep_learning_analysis") else { return nil }
                    return await intelligence.query(query, feature: "deep_learning_analysis")
                }
                
                func queryMLPatternDetection(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("ML-pattern-detection") else { return nil }
                    return await intelligence.query(query, feature: "ML-pattern-detection")
                }
                
                func queryAiOptimization(_ query: String) async -> String? {
                    guard intelligenceFeatures.contains("aiOptimization") else { return nil }
                    return await intelligence.query(query, feature: "aiOptimization")
                }
                
                // MARK: - Intelligence Status Methods
                func isIntelligenceFeatureEnabled(_ feature: String) -> Bool {
                    return intelligenceFeatures.contains(feature)
                }
                
                func getEnabledIntelligenceFeatures() -> Set<String> {
                    return intelligenceFeatures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Test Infrastructure
    
    private let testMacros: [String: Macro.Type] = [
        "Intelligence": IntelligenceMacro.self,
    ]
}

// MARK: - Test Support Extensions

extension IntelligenceMacroTests {
    
    /// Creates a diagnostic spec for easier testing
    private func diagnostic(
        _ message: String,
        line: Int,
        column: Int
    ) -> DiagnosticSpec {
        DiagnosticSpec(message: message, line: line, column: column)
    }
    
    /// Helper for testing macro expansion with custom features
    private func assertIntelligenceMacroExpansion(
        original: String,
        expected: String,
        features: [String] = ["testFeature"],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let featuresArray = "[\"" + features.joined(separator: "\", \"") + "\"]"
        let originalWithMacro = """
        @Intelligence(features: \(featuresArray))
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