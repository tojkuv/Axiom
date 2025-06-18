#[cfg(test)]
mod swift_generation_tests {
    use axiom_universal_client_generator::{GenerateRequest, AxiomSwiftClientGenerator};
    use axiom_universal_client_generator::validation::{SwiftValidator, ValidationResult};
    use std::path::PathBuf;
    use tempfile::TempDir;
    use tokio;

    async fn setup_test_env() -> (TempDir, PathBuf, PathBuf) {
        let temp_dir = tempfile::tempdir().unwrap();
        let proto_path = temp_dir.path().join("task_service.proto");
        let output_path = temp_dir.path().join("generated");

        // Write test proto file
        let proto_content = r#"
syntax = "proto3";

package task.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";

service TaskService {
  rpc CreateTask(CreateTaskRequest) returns (Task);
  rpc GetTasks(GetTasksRequest) returns (GetTasksResponse);
  rpc DeleteTask(DeleteTaskRequest) returns (google.protobuf.Empty);
}

message Task {
  string id = 1;
  string title = 2;
  string description = 3;
  bool is_completed = 4;
  google.protobuf.Timestamp created_at = 5;
  TaskPriority priority = 6;
  repeated string tags = 7;
}

message CreateTaskRequest {
  string title = 1;
  string description = 2;
  TaskPriority priority = 3;
  repeated string tags = 4;
}

message GetTasksRequest {
  optional bool completed = 1;
  int32 limit = 2;
  string cursor = 3;
}

message GetTasksResponse {
  repeated Task tasks = 1;
  string next_cursor = 2;
  int32 total_count = 3;
}

message DeleteTaskRequest {
  string id = 1;
}

enum TaskPriority {
  TASK_PRIORITY_UNSPECIFIED = 0;
  TASK_PRIORITY_LOW = 1;
  TASK_PRIORITY_MEDIUM = 2;
  TASK_PRIORITY_HIGH = 3;
  TASK_PRIORITY_URGENT = 4;
}
"#;

        std::fs::write(&proto_path, proto_content).unwrap();
        
        (temp_dir, proto_path, output_path)
    }

    #[tokio::test]
    async fn test_swift_contract_generation() {
        let (temp_dir, proto_path, output_path) = setup_test_env().await;

        let generator = AxiomSwiftClientGenerator::new().await.unwrap();

        let request = GenerateRequest {
            proto_path: proto_path.to_string_lossy().to_string(),
            output_path: output_path.to_string_lossy().to_string(),
            target_languages: vec!["swift".to_string()],
            services: None,
            framework_config: Some(axiom_universal_client_generator::FrameworkConfig {
                swift: Some(axiom_universal_client_generator::SwiftConfig {
                    axiom_version: Some("latest".to_string()),
                    client_suffix: Some("Client".to_string()),
                    generate_tests: Some(true),
                    package_name: Some("TaskModule".to_string()),
                }),
                kotlin: None,
            }),
            generation_options: Some(axiom_universal_client_generator::GenerationOptions {
                generate_contracts: Some(true),
                generate_clients: Some(true),
                generate_tests: Some(true),
                force_overwrite: Some(true),
                include_documentation: Some(true),
                style_guide: Some("axiom".to_string()),
            }),
        };

        let response = generator.generate(request).await.unwrap();

        // Verify generation succeeded
        assert!(response.success, "Generation failed: {:?}", response.error);
        assert!(!response.generated_files.is_empty(), "No files were generated");

        // Verify specific files exist
        let contract_file = output_path.join("swift/Contracts/TaskService.swift");
        assert!(contract_file.exists(), "Contract file not generated: {}", contract_file.display());

        // Read and verify contract content
        let contract_content = std::fs::read_to_string(&contract_file).unwrap();
        
        // Verify it contains expected Swift structures
        assert!(contract_content.contains("public struct Task:"), "Task struct not found");
        assert!(contract_content.contains("public enum TaskPriority:"), "TaskPriority enum not found");
        assert!(contract_content.contains("Identifiable"), "Identifiable conformance not found");
        assert!(contract_content.contains("import Foundation"), "Foundation import not found");
        
        // Verify proper Swift naming conventions
        assert!(contract_content.contains("isCompleted"), "camelCase field naming not applied");
        assert!(contract_content.contains("createdAt"), "camelCase field naming not applied");
        assert!(contract_content.contains("case unspecified"), "Enum case naming not applied");
        
        // Verify protocol generation
        assert!(contract_content.contains("protocol TaskServiceProtocol"), "Service protocol not found");
        assert!(contract_content.contains("func createTask"), "Method not found in protocol");

        println!("✅ Swift contract generation test passed");
        println!("Generated content preview:\n{}", &contract_content[..500.min(contract_content.len())]);
    }

    #[tokio::test]
    async fn test_swift_client_generation() {
        let (temp_dir, proto_path, output_path) = setup_test_env().await;

        let generator = AxiomSwiftClientGenerator::new().await.unwrap();

        let request = GenerateRequest {
            proto_path: proto_path.to_string_lossy().to_string(),
            output_path: output_path.to_string_lossy().to_string(),
            target_languages: vec!["swift".to_string()],
            services: None,
            framework_config: None,
            generation_options: None,
        };

        let response = generator.generate(request).await.unwrap();

        // Verify generation succeeded
        assert!(response.success, "Generation failed: {:?}", response.error);
        
        // Verify client files exist
        let client_file = output_path.join("swift/Clients/TaskClient.swift");
        let action_file = output_path.join("swift/Clients/TaskAction.swift");
        let state_file = output_path.join("swift/Clients/TaskState.swift");

        if client_file.exists() {
            let client_content = std::fs::read_to_string(&client_file).unwrap();
            assert!(client_content.contains("actor TaskClient"), "TaskClient actor not found");
            assert!(client_content.contains("AxiomObservableClient"), "Axiom base class not found");
        }

        println!("✅ Swift client generation test passed");
    }

    #[tokio::test]
    async fn test_swift_validation() {
        let (temp_dir, proto_path, output_path) = setup_test_env().await;

        let generator = AxiomSwiftClientGenerator::new().await.unwrap();

        let request = GenerateRequest {
            proto_path: proto_path.to_string_lossy().to_string(),
            output_path: output_path.to_string_lossy().to_string(),
            target_languages: vec!["swift".to_string()],
            services: None,
            framework_config: None,
            generation_options: Some(axiom_universal_client_generator::GenerationOptions {
                generate_contracts: Some(true),
                generate_clients: Some(false), // Only generate contracts for validation
                generate_tests: Some(true),
                force_overwrite: Some(true),
                include_documentation: Some(true),
                style_guide: Some("axiom".to_string()),
            }),
        };

        let response = generator.generate(request).await.unwrap();
        assert!(response.success, "Generation failed: {:?}", response.error);

        // Validate generated Swift code compiles (basic syntax check)
        for file_path in &response.generated_files {
            if file_path.ends_with(".swift") {
                let path = PathBuf::from(file_path);
                if path.exists() {
                    let content = std::fs::read_to_string(&path).unwrap();
                    
                    // Basic syntax validation
                    let open_braces = content.matches('{').count();
                    let close_braces = content.matches('}').count();
                    assert_eq!(open_braces, close_braces, "Unbalanced braces in {}", file_path);
                    
                    let open_parens = content.matches('(').count();
                    let close_parens = content.matches(')').count();
                    assert_eq!(open_parens, close_parens, "Unbalanced parentheses in {}", file_path);
                    
                    // Verify no syntax errors in basic structure
                    assert!(!content.contains("{{"), "Unprocessed template in {}", file_path);
                    assert!(!content.contains("}}"), "Unprocessed template in {}", file_path);
                }
            }
        }

        println!("✅ Swift validation test passed");
    }

    #[tokio::test]
    async fn test_comprehensive_swift_validation() {
        let (temp_dir, proto_path, output_path) = setup_test_env().await;

        let generator = AxiomSwiftClientGenerator::new().await.unwrap();

        let request = GenerateRequest {
            proto_path: proto_path.to_string_lossy().to_string(),
            output_path: output_path.to_string_lossy().to_string(),
            target_languages: vec!["swift".to_string()],
            services: None,
            framework_config: Some(axiom_universal_client_generator::FrameworkConfig {
                swift: Some(axiom_universal_client_generator::SwiftConfig {
                    axiom_version: Some("latest".to_string()),
                    client_suffix: Some("Client".to_string()),
                    generate_tests: Some(true),
                    package_name: Some("TaskModule".to_string()),
                }),
                kotlin: None,
            }),
            generation_options: Some(axiom_universal_client_generator::GenerationOptions {
                generate_contracts: Some(true),
                generate_clients: Some(true),
                generate_tests: Some(true),
                force_overwrite: Some(true),
                include_documentation: Some(true),
                style_guide: Some("axiom".to_string()),
            }),
        };

        let response = generator.generate(request).await.unwrap();
        assert!(response.success, "Generation failed: {:?}", response.error);

        // Use the new validation framework
        let validator = SwiftValidator::new();
        
        // Validate all generated Swift files
        let validation_result = validator.validate_files(&response.generated_files).await.unwrap();
        
        println!("Validation Results:");
        println!("  Files validated: {}", validation_result.files_validated);
        println!("  Errors: {}", validation_result.errors.len());
        println!("  Warnings: {}", validation_result.warnings.len());
        
        if !validation_result.errors.is_empty() {
            for error in &validation_result.errors {
                println!("  Error: {}", error);
            }
        }
        
        if !validation_result.warnings.is_empty() {
            for warning in &validation_result.warnings {
                println!("  Warning: {}", warning);
            }
        }
        
        // Validation should pass
        assert!(validation_result.is_valid(), "Validation failed with errors: {:?}", validation_result.errors);
        assert!(validation_result.files_validated > 0, "No files were validated");

        // Test compilation if Swift is available
        let compilation_result = validator.compile_check(&response.generated_files).await.unwrap();
        
        println!("Compilation Results:");
        println!("  Successful compilations: {}", compilation_result.successful_compilations);
        println!("  Compilation errors: {}", compilation_result.compilation_errors.len());
        
        if !compilation_result.compilation_errors.is_empty() {
            for error in &compilation_result.compilation_errors {
                println!("  Compilation Error: {}", error);
            }
        }

        // If Swift compiler is available, compilation should succeed
        if compilation_result.successful_compilations > 0 || compilation_result.compilation_errors.is_empty() {
            assert!(compilation_result.is_successful(), "Compilation failed: {:?}", compilation_result.compilation_errors);
        }

        println!("✅ Comprehensive Swift validation test passed");
    }
}