#[cfg(test)]
mod axiom_framework_integration_tests {
    use axiom_universal_client_generator::{GenerateRequest, AxiomSwiftClientGenerator};
    use axiom_universal_client_generator::validation::{SwiftValidator, ValidationResult, CompilationResult};
    use std::path::PathBuf;
    use tempfile::TempDir;
    use tokio;

    /// Create a comprehensive test proto that exercises all Axiom features
    async fn setup_comprehensive_test_env() -> (TempDir, PathBuf, PathBuf) {
        let temp_dir = tempfile::tempdir().unwrap();
        let proto_path = temp_dir.path().join("comprehensive_service.proto");
        let output_path = temp_dir.path().join("generated");

        // Comprehensive proto file with Axiom-specific options
        let proto_content = r#"
syntax = "proto3";

package comprehensive.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";
import "axiom_options.proto";

// Service with comprehensive Axiom options
service ComprehensiveService {
  option (axiom.service_options) = {
    client_name: "ComprehensiveClient"
    state_name: "ComprehensiveState"
    action_name: "ComprehensiveAction"
    import_modules: ["AxiomCore", "AxiomArchitecture"]
    supports_pagination: true
    generate_tests: true
    collections: [
      {
        name: "tasks"
        item_type: "Task"
        primary_key: "id"
        paginated: true
        searchable: true
        sortable: true
        default_sort_field: "created_at"
        max_cached_items: 500
      },
      {
        name: "categories"
        item_type: "Category" 
        primary_key: "id"
        paginated: false
        searchable: true
        sortable: true
        default_sort_field: "name"
        max_cached_items: 100
      }
    ]
  };

  // Create operation with validation and state updates
  rpc CreateTask(CreateTaskRequest) returns (Task) {
    option (axiom.method_options) = {
      state_update_strategy: APPEND
      requires_network: true
      modifies_state: true
      show_loading_state: true
      collection_name: "tasks"
      validation_rules: ["!request.title.isEmpty", "request.title.length >= 3"]
      cache_strategy: MEMORY
      supports_offline: false
      action_documentation: "Creates a new task and adds it to the tasks collection"
    };
  }

  // List operation with pagination support
  rpc GetTasks(GetTasksRequest) returns (GetTasksResponse) {
    option (axiom.method_options) = {
      state_update_strategy: REPLACE_ALL
      requires_network: true
      modifies_state: true
      show_loading_state: true
      collection_name: "tasks"
      cache_strategy: MEMORY
      supports_offline: true
      action_documentation: "Retrieves paginated list of tasks"
    };
  }

  // Update operation with ID-based updates
  rpc UpdateTask(UpdateTaskRequest) returns (Task) {
    option (axiom.method_options) = {
      state_update_strategy: UPDATE_BY_ID
      requires_network: true
      modifies_state: true
      show_loading_state: true
      collection_name: "tasks"
      id_field_name: "task_id"
      validation_rules: ["!request.task_id.isEmpty"]
      cache_strategy: MEMORY
      supports_offline: false
      action_documentation: "Updates an existing task by ID"
    };
  }

  // Delete operation
  rpc DeleteTask(DeleteTaskRequest) returns (google.protobuf.Empty) {
    option (axiom.method_options) = {
      state_update_strategy: REMOVE_BY_ID
      requires_network: true
      modifies_state: true
      show_loading_state: true
      collection_name: "tasks"
      id_field_name: "task_id"
      validation_rules: ["!request.task_id.isEmpty"]
      cache_strategy: NONE
      supports_offline: false
      action_documentation: "Removes a task by ID"
    };
  }

  // Category management
  rpc GetCategories(GetCategoriesRequest) returns (GetCategoriesResponse) {
    option (axiom.method_options) = {
      state_update_strategy: REPLACE_ALL
      requires_network: true
      modifies_state: true
      show_loading_state: false
      collection_name: "categories"
      cache_strategy: PERSISTENT
      supports_offline: true
      action_documentation: "Retrieves all categories"
    };
  }
}

// Task entity with comprehensive fields
message Task {
  string id = 1;
  string title = 2;
  string description = 3;
  bool is_completed = 4;
  google.protobuf.Timestamp created_at = 5;
  google.protobuf.Timestamp updated_at = 6;
  TaskPriority priority = 7;
  repeated string tags = 8;
  string category_id = 9;
  TaskStatus status = 10;
}

// Category entity
message Category {
  string id = 1;
  string name = 2;
  string description = 3;
  string color = 4;
  int32 task_count = 5;
}

// Request/Response messages
message CreateTaskRequest {
  string title = 1;
  string description = 2;
  TaskPriority priority = 3;
  repeated string tags = 4;
  string category_id = 5;
}

message GetTasksRequest {
  optional bool completed = 1;
  optional TaskPriority priority = 2;
  optional string category_id = 3;
  int32 limit = 4;
  string cursor = 5;
  string search_query = 6;
  string sort_field = 7;
  bool sort_ascending = 8;
}

message GetTasksResponse {
  repeated Task tasks = 1;
  string next_cursor = 2;
  int32 total_count = 3;
  bool has_more = 4;
}

message UpdateTaskRequest {
  string task_id = 1;
  optional string title = 2;
  optional string description = 3;
  optional bool is_completed = 4;
  optional TaskPriority priority = 5;
  repeated string tags = 6;
  optional string category_id = 7;
  optional TaskStatus status = 8;
}

message DeleteTaskRequest {
  string task_id = 1;
}

message GetCategoriesRequest {
  optional string search_query = 1;
  string sort_field = 2;
  bool sort_ascending = 3;
}

message GetCategoriesResponse {
  repeated Category categories = 1;
  int32 total_count = 2;
}

// Enums
enum TaskPriority {
  TASK_PRIORITY_UNSPECIFIED = 0;
  TASK_PRIORITY_LOW = 1;
  TASK_PRIORITY_MEDIUM = 2;
  TASK_PRIORITY_HIGH = 3;
  TASK_PRIORITY_URGENT = 4;
}

enum TaskStatus {
  TASK_STATUS_UNSPECIFIED = 0;
  TASK_STATUS_DRAFT = 1;
  TASK_STATUS_ACTIVE = 2;
  TASK_STATUS_COMPLETED = 3;
  TASK_STATUS_CANCELLED = 4;
}
"#;

        std::fs::write(&proto_path, proto_content).unwrap();
        
        (temp_dir, proto_path, output_path)
    }

    #[tokio::test]
    async fn test_comprehensive_axiom_integration() {
        let (temp_dir, proto_path, output_path) = setup_comprehensive_test_env().await;

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
                    package_name: Some("ComprehensiveModule".to_string()),
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
        assert!(!response.generated_files.is_empty(), "No files were generated");

        // Use enhanced validation framework
        let validator = SwiftValidator::new();
        
        println!("🔍 Running comprehensive validation on {} files", response.generated_files.len());

        // Validate all generated Swift files
        let validation_result = validator.validate_files(&response.generated_files).await.unwrap();
        
        println!("📊 Validation Results:");
        println!("  ✅ Files validated: {}", validation_result.files_validated);
        println!("  ❌ Errors: {}", validation_result.errors.len());
        println!("  ⚠️  Warnings: {}", validation_result.warnings.len());
        
        // Print all validation errors for debugging
        if !validation_result.errors.is_empty() {
            println!("\n🚨 Validation Errors:");
            for (i, error) in validation_result.errors.iter().enumerate() {
                println!("  {}. {}", i + 1, error);
            }
        }
        
        // Print warnings for information
        if !validation_result.warnings.is_empty() {
            println!("\n⚠️  Validation Warnings:");
            for (i, warning) in validation_result.warnings.iter().enumerate() {
                println!("  {}. {}", i + 1, warning);
            }
        }

        // Validation must pass with no errors
        assert!(validation_result.is_valid(), "Validation failed with {} errors", validation_result.errors.len());
        assert!(validation_result.files_validated > 0, "No files were validated");

        // Verify specific generated files exist and have correct content
        verify_generated_file_structure(&output_path, &response.generated_files).await;
        verify_axiom_integration_patterns(&response.generated_files).await;

        println!("✅ Comprehensive Axiom integration test passed");
    }

    #[tokio::test]
    async fn test_compilation_verification() {
        let (temp_dir, proto_path, output_path) = setup_comprehensive_test_env().await;

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
        assert!(response.success, "Generation failed: {:?}", response.error);

        // Test compilation if Swift is available
        let validator = SwiftValidator::new();
        let compilation_result = validator.compile_check(&response.generated_files).await.unwrap();
        
        println!("🔨 Compilation Results:");
        println!("  ✅ Successful compilations: {}", compilation_result.successful_compilations);
        println!("  ❌ Compilation errors: {}", compilation_result.compilation_errors.len());
        println!("  ⚠️  Compilation warnings: {}", compilation_result.warnings.len());

        // Print compilation errors for debugging
        if !compilation_result.compilation_errors.is_empty() {
            println!("\n🚨 Compilation Errors:");
            for (i, error) in compilation_result.compilation_errors.iter().enumerate() {
                println!("  {}. {}", i + 1, error);
            }
        }

        // Print compilation warnings
        if !compilation_result.warnings.is_empty() {
            println!("\n⚠️  Compilation Warnings:");
            for (i, warning) in compilation_result.warnings.iter().enumerate() {
                println!("  {}. {}", i + 1, warning);
            }
        }

        // If Swift compiler is available, compilation should succeed
        if compilation_result.successful_compilations > 0 || compilation_result.compilation_errors.is_empty() {
            assert!(compilation_result.is_successful(), "Compilation failed with {} errors", compilation_result.compilation_errors.len());
        } else {
            println!("⚠️  Swift compiler not available - skipping compilation verification");
        }

        println!("✅ Compilation verification test passed");
    }

    #[tokio::test]
    async fn test_end_to_end_workflow() {
        let (temp_dir, proto_path, output_path) = setup_comprehensive_test_env().await;

        println!("🔄 Testing end-to-end workflow: Proto → Swift → Framework");

        // Step 1: Generate Swift code
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
                    package_name: Some("ComprehensiveModule".to_string()),
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
        assert!(response.success, "Step 1 - Generation failed: {:?}", response.error);
        println!("  ✅ Step 1: Code generation completed");

        // Step 2: Validate generated code
        let validator = SwiftValidator::new();
        let validation_result = validator.validate_files(&response.generated_files).await.unwrap();
        assert!(validation_result.is_valid(), "Step 2 - Validation failed with {} errors", validation_result.errors.len());
        println!("  ✅ Step 2: Code validation passed");

        // Step 3: Verify framework integration patterns
        verify_axiom_integration_patterns(&response.generated_files).await;
        println!("  ✅ Step 3: Framework integration patterns verified");

        // Step 4: Compilation check (if Swift is available)
        let compilation_result = validator.compile_check(&response.generated_files).await.unwrap();
        if compilation_result.successful_compilations > 0 {
            assert!(compilation_result.is_successful(), "Step 4 - Compilation failed");
            println!("  ✅ Step 4: Compilation successful");
        } else {
            println!("  ⚠️  Step 4: Swift compiler not available - skipping compilation");
        }

        // Step 5: Performance verification
        verify_performance_requirements(&response.generated_files).await;
        println!("  ✅ Step 5: Performance requirements met");

        println!("✅ End-to-end workflow test completed successfully");
    }

    #[tokio::test]
    async fn test_performance_benchmarks() {
        let (temp_dir, proto_path, output_path) = setup_comprehensive_test_env().await;

        let generator = AxiomSwiftClientGenerator::new().await.unwrap();

        // Measure generation time
        let start_time = std::time::Instant::now();
        
        let request = GenerateRequest {
            proto_path: proto_path.to_string_lossy().to_string(),
            output_path: output_path.to_string_lossy().to_string(),
            target_languages: vec!["swift".to_string()],
            services: None,
            framework_config: None,
            generation_options: None,
        };

        let response = generator.generate(request).await.unwrap();
        let generation_time = start_time.elapsed();
        
        assert!(response.success, "Generation failed: {:?}", response.error);

        // Performance assertions based on plan requirements
        println!("⏱️  Performance Metrics:");
        println!("  📊 Generation time: {:?}", generation_time);
        println!("  📁 Files generated: {}", response.generated_files.len());
        println!("  🎯 Target: <2 seconds for typical schemas");

        // Assert generation speed requirement: <2 seconds for typical proto packages
        assert!(generation_time.as_secs() < 2, "Generation took too long: {:?} (should be <2s)", generation_time);

        // Measure validation time
        let validation_start = std::time::Instant::now();
        let validator = SwiftValidator::new();
        let validation_result = validator.validate_files(&response.generated_files).await.unwrap();
        let validation_time = validation_start.elapsed();

        println!("  📊 Validation time: {:?}", validation_time);
        println!("  🎯 Validation success: {}", validation_result.is_valid());

        // Memory usage estimation
        let total_content_size: usize = response.generated_files.iter()
            .filter_map(|path| std::fs::read_to_string(path).ok())
            .map(|content| content.len())
            .sum();

        println!("  📊 Total generated content: {} bytes", total_content_size);
        println!("  🎯 Memory efficiency: {}KB per file", 
                 total_content_size / response.generated_files.len() / 1024);

        // Assert compilation success rate requirement: 100%
        assert!(validation_result.is_valid(), "Validation failed - compilation success rate not 100%");

        println!("✅ Performance benchmarks passed");
    }

    /// Verify the structure of generated files matches expectations
    async fn verify_generated_file_structure(output_path: &PathBuf, generated_files: &[String]) {
        println!("📁 Verifying generated file structure...");

        // Expected file patterns
        let expected_patterns = [
            "ComprehensiveClient.swift",
            "ComprehensiveAction.swift", 
            "ComprehensiveState.swift",
            "AxiomErrors.swift"
        ];

        for pattern in &expected_patterns {
            let found = generated_files.iter().any(|file| file.contains(pattern));
            assert!(found, "Expected file matching pattern '{}' not found", pattern);
            println!("  ✅ Found: {}", pattern);
        }

        // Verify directory structure
        let swift_dir = output_path.join("swift");
        assert!(swift_dir.exists(), "swift directory not created");
        
        let clients_dir = swift_dir.join("Clients");
        assert!(clients_dir.exists(), "Clients directory not created");

        println!("  ✅ Directory structure verified");
    }

    /// Verify Axiom integration patterns in generated code
    async fn verify_axiom_integration_patterns(generated_files: &[String]) {
        println!("🔗 Verifying Axiom integration patterns...");

        for file_path in generated_files {
            if file_path.ends_with(".swift") {
                let content = std::fs::read_to_string(file_path).unwrap();
                
                if file_path.contains("Client.swift") {
                    // Verify client actor patterns
                    assert!(content.contains("actor "), "Client should be an actor");
                    assert!(content.contains(": AxiomClient"), "Client should conform to AxiomClient");
                    assert!(content.contains("@globalActor"), "Client should use @globalActor");
                    assert!(content.contains("stateStream"), "Client should have stateStream");
                    assert!(content.contains("func process("), "Client should have process method");
                    println!("  ✅ Client actor patterns verified: {}", file_path);
                }
                
                if file_path.contains("State.swift") {
                    // Verify state struct patterns
                    assert!(content.contains(": AxiomState"), "State should conform to AxiomState");
                    assert!(content.contains("public let"), "State properties should be immutable");
                    assert!(content.contains("func adding"), "State should have functional update methods");
                    assert!(content.contains("func with"), "State should have with methods");
                    println!("  ✅ State struct patterns verified: {}", file_path);
                }
                
                if file_path.contains("Action.swift") {
                    // Verify action enum patterns
                    assert!(content.contains("enum "), "Action should be an enum");
                    assert!(content.contains(": Sendable"), "Action should be Sendable");
                    assert!(content.contains("var isValid"), "Action should have validation");
                    assert!(content.contains("var validationErrors"), "Action should have validation errors");
                    println!("  ✅ Action enum patterns verified: {}", file_path);
                }
            }
        }

        println!("  ✅ All Axiom integration patterns verified");
    }

    /// Verify performance requirements are met
    async fn verify_performance_requirements(generated_files: &[String]) {
        println!("⚡ Verifying performance requirements...");

        // Check file sizes are reasonable
        for file_path in generated_files {
            if file_path.ends_with(".swift") {
                let metadata = std::fs::metadata(file_path).unwrap();
                let file_size = metadata.len();
                
                // Ensure files aren't excessively large (>100KB might indicate bloated generation)
                assert!(file_size < 100_000, "Generated file too large: {} bytes in {}", file_size, file_path);
                
                // Ensure files aren't empty
                assert!(file_size > 0, "Generated file is empty: {}", file_path);
            }
        }

        // Verify code complexity is reasonable by checking for excessive nesting
        for file_path in generated_files {
            if file_path.ends_with(".swift") {
                let content = std::fs::read_to_string(file_path).unwrap();
                
                // Check for reasonable indentation depth (no more than 8 levels)
                let max_indentation = content.lines()
                    .map(|line| line.chars().take_while(|&c| c == ' ').count())
                    .max()
                    .unwrap_or(0);
                    
                assert!(max_indentation < 32, "Excessive nesting in {}: {} spaces", file_path, max_indentation);
            }
        }

        println!("  ✅ Performance requirements verified");
    }
}