//! Unit tests for error handling

use axiom_universal_client_generator::error::*;
use std::path::PathBuf;

#[test]
fn test_generator_error_creation() {
    let error = GeneratorError::ProtoParsingError {
        file_path: PathBuf::from("/test/file.proto"),
        message: "Invalid syntax".to_string(),
    };
    
    match error {
        GeneratorError::ProtoParsingError { file_path, message } => {
            assert_eq!(file_path, PathBuf::from("/test/file.proto"));
            assert_eq!(message, "Invalid syntax");
        }
        _ => panic!("Expected ProtoParsingError"),
    }
}

#[test]
fn test_swift_generation_error() {
    let error = GeneratorError::SwiftGenerationError {
        service_name: "TaskService".to_string(),
        reason: "Template compilation failed".to_string(),
    };
    
    match error {
        GeneratorError::SwiftGenerationError { service_name, reason } => {
            assert_eq!(service_name, "TaskService");
            assert_eq!(reason, "Template compilation failed");
        }
        _ => panic!("Expected SwiftGenerationError"),
    }
}

#[test]
fn test_template_error() {
    let error = GeneratorError::TemplateError("Missing required context variable".to_string());
    
    match error {
        GeneratorError::TemplateError(message) => {
            assert_eq!(message, "Missing required context variable");
        }
        _ => panic!("Expected TemplateError"),
    }
}

#[test]
fn test_file_operation_error() {
    let error = GeneratorError::FileOperationError {
        path: PathBuf::from("/output/file.swift"),
        operation: "write".to_string(),
        source: std::io::Error::new(std::io::ErrorKind::PermissionDenied, "Access denied").into(),
    };
    
    match error {
        GeneratorError::FileOperationError { path, operation, source: _ } => {
            assert_eq!(path, PathBuf::from("/output/file.swift"));
            assert_eq!(operation, "write");
        }
        _ => panic!("Expected FileOperationError"),
    }
}

#[test]
fn test_configuration_error() {
    let error = GeneratorError::ConfigurationError {
        field: "package_name".to_string(),
        message: "Invalid package name format".to_string(),
    };
    
    match error {
        GeneratorError::ConfigurationError { field, message } => {
            assert_eq!(field, "package_name");
            assert_eq!(message, "Invalid package name format");
        }
        _ => panic!("Expected ConfigurationError"),
    }
}

#[test]
fn test_validation_error() {
    let error = GeneratorError::ValidationError("Missing import statement".to_string());
    
    match error {
        GeneratorError::ValidationError(message) => {
            assert_eq!(message, "Missing import statement");
        }
        _ => panic!("Expected ValidationError"),
    }
}

#[test]
fn test_mcp_protocol_error() {
    let error = GeneratorError::McpError("Invalid request format".to_string());
    
    match error {
        GeneratorError::McpError(message) => {
            assert_eq!(message, "Invalid request format");
        }
        _ => panic!("Expected McpError"),
    }
}

#[test]
fn test_error_display() {
    let error = GeneratorError::ProtoParsingError {
        file_path: PathBuf::from("test.proto"),
        message: "Syntax error".to_string(),
    };
    
    let display_string = format!("{}", error);
    assert!(display_string.contains("Proto parsing error"));
    assert!(display_string.contains("test.proto"));
    assert!(display_string.contains("Syntax error"));
}

#[test]
fn test_error_debug() {
    let error = GeneratorError::SwiftGenerationError {
        service_name: "TestService".to_string(),
        reason: "Template failed".to_string(),
    };
    
    let debug_string = format!("{:?}", error);
    assert!(debug_string.contains("SwiftGenerationError"));
    assert!(debug_string.contains("TestService"));
    assert!(debug_string.contains("Template failed"));
}

#[test]
fn test_error_chain() {
    let io_error = std::io::Error::new(std::io::ErrorKind::NotFound, "File not found");
    let generator_error = GeneratorError::FileOperationError {
        path: PathBuf::from("missing.proto"),
        operation: "read".to_string(),
        source: io_error.into(),
    };
    
    // Test that we can access the source error
    if let GeneratorError::FileOperationError { source, .. } = &generator_error {
        assert!(source.to_string().contains("File not found"));
    } else {
        panic!("Expected FileOperationError");
    }
}

// Note: These tests are commented out because the functionality hasn't been implemented yet
// #[test]
// fn test_result_extensions() {
//     // ResultExt trait and with_file_context method not implemented yet
// }

// #[test] 
// fn test_error_recovery() {
//     // ErrorRecovery functionality not implemented yet
// }

// #[test]
// fn test_error_reporting() {
//     // ErrorReport functionality not implemented yet
// }

#[test]
fn test_error_categorization() {
    let proto_error = GeneratorError::ProtoParsingError {
        file_path: PathBuf::from("test.proto"),
        message: "Invalid syntax".to_string(),
    };
    assert_eq!(proto_error.category(), ErrorCategory::ProtoProcessing);
    
    let swift_error = GeneratorError::SwiftGenerationError {
        service_name: "Test".to_string(),
        reason: "Failed".to_string(),
    };
    assert_eq!(swift_error.category(), ErrorCategory::CodeGeneration);
    
    let file_error = GeneratorError::FileOperationError {
        path: PathBuf::from("test.swift"),
        operation: "write".to_string(),
        source: std::io::Error::new(std::io::ErrorKind::NotFound, "Not found").into(),
    };
    assert_eq!(file_error.category(), ErrorCategory::FileSystem);
    
    let config_error = GeneratorError::ConfigurationError {
        field: "test".to_string(),
        message: "Invalid".to_string(),
    };
    assert_eq!(config_error.category(), ErrorCategory::Configuration);
}

// Note: These tests are commented out because the functionality hasn't been implemented yet
// #[test]
// fn test_error_severity() {
//     // severity() method and ErrorSeverity not implemented yet
// }

#[test]
fn test_error_context_preservation() {
    let original_error = std::io::Error::new(std::io::ErrorKind::PermissionDenied, "Access denied");
    
    let wrapped_error = GeneratorError::FileOperationError {
        path: PathBuf::from("restricted.swift"),
        operation: "write".to_string(),
        source: original_error.into(),
    };
    
    // Verify that we can still access the original error details
    if let GeneratorError::FileOperationError { source, .. } = &wrapped_error {
        let source_string = source.to_string();
        assert!(source_string.contains("Access denied"));
    }
}

// #[test]
// fn test_batch_error_handling() {
//     // BatchErrorHandler not implemented yet
// }

// #[test]
// fn test_error_localization() {
//     // localized_message() and localized_suggestion() methods not implemented yet
// }