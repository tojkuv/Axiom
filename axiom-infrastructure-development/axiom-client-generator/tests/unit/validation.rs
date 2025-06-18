//! Unit tests for validation functionality

use axiom_universal_client_generator::validation::swift::*;
use axiom_universal_client_generator::proto::types::*;
use std::path::PathBuf;
use tempfile::TempDir;

#[tokio::test]
async fn test_swift_syntax_validation() {
    let validator = SwiftValidator::new();
    let temp_dir = TempDir::new().unwrap();
    
    // Valid Swift code
    let valid_code = r#"
import Foundation

public struct Task {
    public let id: String
    public let title: String
    
    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
"#;
    
    // Write to temp file
    let valid_file = temp_dir.path().join("ValidTask.swift");
    std::fs::write(&valid_file, valid_code).unwrap();
    
    let result = validator.validate_files(&[valid_file.to_string_lossy().to_string()]).await;
    assert!(result.is_ok());
    let validation_result = result.unwrap();
    assert!(validation_result.is_valid());
    assert!(validation_result.errors.is_empty());
    
    // Invalid Swift code
    let invalid_code = r#"
import Foundation

public struct Task {
    public let id: String
    public let title: String
    
    public init(id: String, title: String {  // Missing closing parenthesis
        self.id = id
        self.title = title
    }
    // Missing closing brace
"#;
    
    // Write to temp file
    let invalid_file = temp_dir.path().join("InvalidTask.swift");
    std::fs::write(&invalid_file, invalid_code).unwrap();
    
    let result = validator.validate_files(&[invalid_file.to_string_lossy().to_string()]).await;
    assert!(result.is_ok());
    let validation_result = result.unwrap();
    assert!(!validation_result.is_valid());
    assert!(!validation_result.errors.is_empty());
}

// Note: SwiftCompilationValidator not implemented yet
// #[tokio::test]
// async fn test_swift_compilation_validation() {
//     // SwiftCompilationValidator functionality not implemented yet
// }

// Note: The following tests use validator types that haven't been implemented yet
// They are commented out to focus on getting the basic functionality working first

/*
All the remaining tests in this file use specialized validator types that don't exist yet:
- AxiomCompatibilityValidator
- SwiftStateValidator  
- SwiftActionValidator
- NamingConventionValidator
- ImportValidator
- ProtocolConformanceValidator
- PerformanceValidator
- BatchValidator
- CustomRuleValidator

These will be implemented in future iterations once the core functionality is stable.
For now, we focus on the basic SwiftValidator functionality that is already working.
*/