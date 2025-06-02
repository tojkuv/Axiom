import XCTest
@testable import Axiom

// MARK: - Phase 4: Documentation and Testing (Final Phase)
// TDD RED PHASE: Tests that validate documentation accuracy (no false AI claims)

final class DocumentationValidationTests: XCTestCase {
    
    func testREADMEContainsNoAITheaterClaims() throws {
        // RED PHASE: Test that main README.md contains no false AI claims
        let readmePath = "/Users/tojkuv/Documents/GitHub/Axiom/README.md"
        
        guard let readmeContent = try? String(contentsOfFile: readmePath) else {
            XCTFail("README.md file not found at expected path")
            return
        }
        
        // These AI theater terms should NOT appear in the cleaned documentation
        let aiTheaterTerms = [
            "natural language interface",
            "natural language queries", 
            "intent-based evolution",
            "pattern recognition",
            "predictive analysis", 
            "adaptive architecture",
            "human-AI collaborative",
            "text-based architectural exploration",
            "AI integration",
            "natural language architectural query"
        ]
        
        for term in aiTheaterTerms {
            XCTAssertFalse(
                readmeContent.lowercased().contains(term.lowercased()),
                "README.md should not contain AI theater term: '\(term)'"
            )
        }
    }
    
    func testREADMEContainsGenuineCapabilities() throws {
        // RED PHASE: Test that README.md contains genuine framework capabilities
        let readmePath = "/Users/tojkuv/Documents/GitHub/Axiom/README.md"
        
        guard let readmeContent = try? String(contentsOfFile: readmePath) else {
            XCTFail("README.md file not found at expected path")
            return
        }
        
        // These genuine capabilities should be present
        let genuineCapabilities = [
            "actor-based state management",
            "swiftui integration", 
            "capability validation",
            "performance monitoring",
            "component registry",
            "architectural constraints",
            "reactive binding"
        ]
        
        for capability in genuineCapabilities {
            XCTAssertTrue(
                readmeContent.lowercased().contains(capability.lowercased()),
                "README.md should contain genuine capability: '\(capability)'"
            )
        }
    }
    
    func testTechnicalDocumentationContainsNoAITheater() throws {
        // RED PHASE: Test that technical specifications contain no false AI claims
        let documentationPaths = [
            "/Users/tojkuv/Documents/GitHub/Axiom/AxiomFramework/Documentation/Technical/API_DESIGN_SPECIFICATION.md",
            "/Users/tojkuv/Documents/GitHub/Axiom/AxiomFramework/Documentation/Technical/INTELLIGENCE_SYSTEM_SPECIFICATION.md",
            "/Users/tojkuv/Documents/GitHub/Axiom/AxiomFramework/Documentation/Technical/MACRO_SYSTEM_SPECIFICATION.md"
        ]
        
        let aiTheaterTerms = [
            "machine learning",
            "artificial intelligence", 
            "self-optimizing",
            "emergent patterns",
            "natural language processing",
            "intent recognition",
            "predictive algorithms",
            "AI-driven"
        ]
        
        for docPath in documentationPaths {
            guard let docContent = try? String(contentsOfFile: docPath) else {
                continue // Skip files that don't exist
            }
            
            for term in aiTheaterTerms {
                XCTAssertFalse(
                    docContent.lowercased().contains(term.lowercased()),
                    "Technical documentation should not contain AI theater term: '\(term)' in \(docPath)"
                )
            }
        }
    }
    
    func testFrameworkFeaturesListIsAccurate() throws {
        // RED PHASE: Test that framework features in README match actual implemented features
        let readmePath = "/Users/tojkuv/Documents/GitHub/Axiom/README.md"
        
        guard let readmeContent = try? String(contentsOfFile: readmePath) else {
            XCTFail("README.md file not found at expected path")
            return
        }
        
        // Features section should NOT contain these false claims
        let falseFeatures = [
            "intelligence queries",
            "system analysis through natural language",
            "architectural analysis and documentation generation",
            "architecture adaptation based on specified requirements",
            "architecture exploration through text interface",
            "code pattern identification and standardization",
            "issue identification and prevention recommendations"
        ]
        
        for feature in falseFeatures {
            XCTAssertFalse(
                readmeContent.lowercased().contains(feature.lowercased()),
                "Framework Features should not claim: '\(feature)'"
            )
        }
    }
    
    func testIntelligenceSystemComponentsRemoved() throws {
        // RED PHASE: Test that "Intelligence System Components" section is removed or cleaned
        let readmePath = "/Users/tojkuv/Documents/GitHub/Axiom/README.md"
        
        guard let readmeContent = try? String(contentsOfFile: readmePath) else {
            XCTFail("README.md file not found at expected path")
            return
        }
        
        // This section should be removed entirely or contain only genuine capabilities
        let problematicSections = [
            "intelligence system components",
            "system analysis features"
        ]
        
        for section in problematicSections {
            if readmeContent.lowercased().contains(section.lowercased()) {
                // If the section exists, it should not contain AI theater
                let aiTheaterInSection = [
                    "intent-based evolution",
                    "natural language queries", 
                    "predictive analysis",
                    "pattern recognition"
                ]
                
                for term in aiTheaterInSection {
                    XCTAssertFalse(
                        readmeContent.lowercased().contains(term.lowercased()),
                        "Intelligence System section should not contain AI theater: '\(term)'"
                    )
                }
            }
        }
    }
    
    func testTestSuiteContainsNoAITheaterMethodCalls() throws {
        // RED PHASE: Test that test suite doesn't call removed AI theater methods
        let testDirectory = "/Users/tojkuv/Documents/GitHub/Axiom/AxiomFramework/Tests/"
        
        // These AI theater methods should NOT be called in tests (they were removed)
        let aiTheaterMethods = [
            "processQuery",
            "analyzeCodePatterns",
            "predictArchitecturalIssues", 
            "generateDocumentation",
            "suggestRefactoring"
        ]
        
        // Check for method calls in test files
        for method in aiTheaterMethods {
            let result = shell("grep -r '\(method)(' \(testDirectory) | grep -v '// Note:' | wc -l")
            let count = Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            
            XCTAssertEqual(count, 0, "Test suite should not call removed AI theater method: '\(method)'")
        }
    }
    
    private func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output
    }
}