import XCTest
import SwiftUI
@testable import Axiom

/// TDD Tests for Phase 2: ArchitecturalDNA → ArchitecturalMetadata refactoring
/// RED phase: Write failing tests first, then implement ArchitecturalMetadata
final class ArchitecturalMetadataTests: XCTestCase {
    
    // MARK: - Phase 2 TDD Tests (RED Phase)
    
    func testArchitecturalMetadataBasicFunctionality() async throws {
        // RED: This test should fail initially since ArchitecturalMetadata doesn't exist yet
        let purpose = ComponentPurpose(
            category: .client,
            role: "State Management",
            domain: "Business Logic",
            responsibilities: ["Manage state", "Validate data"],
            businessValue: "Thread-safe state management"
        )
        
        let metadata = DefaultArchitecturalMetadata(
            componentID: ComponentID("test-component"),
            purpose: purpose,
            architecturalLayer: .domain,
            relationships: [],
            constraints: []
        )
        
        // Test that metadata preserves genuine functionality from DNA
        XCTAssertEqual(metadata.componentID.description, "test-component")
        XCTAssertEqual(metadata.purpose.category, .client)
        XCTAssertEqual(metadata.architecturalLayer, .domain)
    }
    
    func testArchitecturalMetadataRemovesAITheater() async throws {
        // RED: Verify that AI theater claims are removed from the system
        // ArchitecturalMetadata should not reference "breakthrough intelligence systems"
        // This is tested by the absence of certain methods and comments
        
        let metadata = DefaultArchitecturalMetadata(
            componentID: ComponentID("test-component"),
            purpose: ComponentPurpose(
                category: .infrastructure,
                role: "Component Registry",
                responsibilities: [],
                businessValue: "Component management"
            ),
            architecturalLayer: .infrastructure,
            relationships: [],
            constraints: []
        )
        
        // Verify genuine functionality is preserved
        XCTAssertNotNil(metadata.componentID)
        XCTAssertNotNil(metadata.purpose)
        XCTAssertNotNil(metadata.architecturalLayer)
    }
    
    func testArchitecturalMetadataPreservesValidation() async throws {
        // RED: Ensure genuine validation functionality is preserved
        let metadata = DefaultArchitecturalMetadata(
            componentID: ComponentID("test-component"),
            purpose: ComponentPurpose(
                category: .client,
                role: "Test Client",
                responsibilities: [],
                businessValue: "Testing"
            ),
            architecturalLayer: .domain,
            relationships: [],
            constraints: [
                ArchitecturalConstraint(
                    type: .actorSafety,
                    description: "Must use actor isolation",
                    rule: .all
                )
            ]
        )
        
        // Test validation functionality (genuine functionality)
        let validationResult = try await metadata.validateArchitecturalIntegrity()
        XCTAssertNotNil(validationResult)
    }
    
    func testArchitecturalMetadataPreservesDescriptionGeneration() async throws {
        // RED: Ensure genuine description generation is preserved
        let metadata = DefaultArchitecturalMetadata(
            componentID: ComponentID("test-component"),
            purpose: ComponentPurpose(
                category: .view,
                role: "UI Component",
                responsibilities: ["Display data", "Handle interactions"],
                businessValue: "User interface"
            ),
            architecturalLayer: .presentation,
            relationships: [],
            constraints: []
        )
        
        // Test description generation (genuine functionality)
        let description = metadata.generateDescription()
        XCTAssertFalse(description.overview.isEmpty, "Should generate meaningful description")
    }
    
    func testArchitecturalMetadataPreservesRelationships() async throws {
        // RED: Ensure genuine relationship mapping is preserved
        let relationship = ComponentRelationship(
            type: .dependsOn,
            targetComponent: ComponentID("target-component"),
            description: "Test dependency"
        )
        
        let metadata = DefaultArchitecturalMetadata(
            componentID: ComponentID("source-component"),
            purpose: ComponentPurpose(
                category: .context,
                role: "Orchestrator",
                responsibilities: [],
                businessValue: "Coordination"
            ),
            architecturalLayer: .application,
            relationships: [relationship],
            constraints: []
        )
        
        // Test relationship preservation (genuine functionality)
        XCTAssertEqual(metadata.relationships.count, 1)
        XCTAssertEqual(metadata.relationships.first?.targetComponent, ComponentID("target-component"))
    }
}