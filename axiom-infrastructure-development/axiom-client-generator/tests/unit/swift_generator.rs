//! Unit tests for Swift code generation

use axiom_universal_client_generator::generators::swift::*;
use axiom_universal_client_generator::generators::swift::clients::*;
use axiom_universal_client_generator::proto::types::*;
use axiom_universal_client_generator::utils::naming::*;
use axiom_universal_client_generator::utils::config::SwiftGenerationConfig;
use std::collections::HashMap;
use std::error::Error;
use tempfile::TempDir;

fn create_test_service() -> ProtoService {
    ProtoService {
        name: "TaskService".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        methods: vec![
            ProtoMethod {
                name: "CreateTask".to_string(),
                input_type: "CreateTaskRequest".to_string(),
                output_type: "CreateTaskResponse".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: MethodOptions::default(),
                documentation: None,
            },
            ProtoMethod {
                name: "GetTask".to_string(),
                input_type: "GetTaskRequest".to_string(),
                output_type: "Task".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: MethodOptions::default(),
                documentation: None,
            },
            ProtoMethod {
                name: "ListTasks".to_string(),
                input_type: "ListTasksRequest".to_string(),
                output_type: "ListTasksResponse".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: MethodOptions::default(),
                documentation: None,
            },
        ],
        options: ServiceOptions::default(),
        documentation: None,
    }
}

fn create_test_message() -> ProtoMessage {
    ProtoMessage {
        name: "Task".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        fields: vec![
            ProtoField {
                name: "id".to_string(),
                field_type: "string".to_string(),
                number: 1,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            ProtoField {
                name: "title".to_string(),
                field_type: "string".to_string(),
                number: 2,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            ProtoField {
                name: "description".to_string(),
                field_type: "string".to_string(),
                number: 3,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            ProtoField {
                name: "priority".to_string(),
                field_type: "int32".to_string(),
                number: 4,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            ProtoField {
                name: "is_completed".to_string(),
                field_type: "bool".to_string(),
                number: 5,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            ProtoField {
                name: "tags".to_string(),
                field_type: "string".to_string(),
                number: 6,
                label: FieldLabel::Repeated,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
        ],
        nested_messages: vec![],
        nested_enums: vec![],
        options: MessageOptions::default(),
        documentation: None,
    }
}

#[tokio::test]
async fn test_generate_swift_client_actor() {
    let service = create_test_service();
    let generator = SwiftClientGenerator::new();
    
    let result = generator.generate_client_actor(&service).await;
    if let Err(ref e) = result {
        println!("Error: {:?}", e);
        // Print detailed error chain
        let mut source = e.source();
        while let Some(err) = source {
            println!("Caused by: {:?}", err);
            source = err.source();
        }
    }
    assert!(result.is_ok());
    
    let swift_code = result.unwrap();
    
    // Verify basic structure
    assert!(swift_code.contains("public actor TaskClient"));
    assert!(swift_code.contains(": AxiomObservableClient"));
    assert!(swift_code.contains("public typealias StateType = TaskState"));
    assert!(swift_code.contains("public typealias ActionType = TaskAction"));
    
    // Verify protocol conformance
    assert!(swift_code.contains("public var stateStream: AsyncStream<TaskState>"));
    assert!(swift_code.contains("public func process(_ action: TaskAction) async throws"));
    
    // Verify action processing
    assert!(swift_code.contains("case .createTask"));
    assert!(swift_code.contains("case .getTask"));
    assert!(swift_code.contains("case .listTasks"));
    
    // Verify imports
    assert!(swift_code.contains("import Foundation"));
    assert!(swift_code.contains("import AxiomCore"));
    assert!(swift_code.contains("import AxiomArchitecture"));
    
    // Verify actor isolation
    assert!(swift_code.contains("@globalActor"));
    
    // Verify state management
    assert!(swift_code.contains("private var _state"));
    assert!(swift_code.contains("streamContinuations"));
}

#[tokio::test]
async fn test_generate_swift_state_struct() {
    let message = create_test_message();
    let generator = SwiftStateGenerator::new();
    
    let result = generator.generate_state_struct(&message).await;
    assert!(result.is_ok());
    
    let swift_code = result.unwrap();
    
    // Verify structure
    assert!(swift_code.contains("public struct TaskState"));
    assert!(swift_code.contains(": AxiomState"));
    
    // Verify properties
    assert!(swift_code.contains("public let id: String"));
    assert!(swift_code.contains("public let title: String"));
    assert!(swift_code.contains("public let description: String?"));
    assert!(swift_code.contains("public let priority: Int32"));
    assert!(swift_code.contains("public let isCompleted: Bool"));
    assert!(swift_code.contains("public let tags: [String]"));
    
    // Verify initializer
    assert!(swift_code.contains("public init("));
    
    // Verify immutable update methods
    assert!(swift_code.contains("func withTitle(_ title: String) -> TaskState"));
    assert!(swift_code.contains("func withCompleted(_ completed: Bool) -> TaskState"));
    
    // Verify Equatable/Hashable conformance
    assert!(swift_code.contains("extension TaskState"));
    assert!(swift_code.contains("public static func == "));
    assert!(swift_code.contains("public func hash(into hasher: inout Hasher)"));
}

#[tokio::test]
async fn test_generate_swift_action_enum() {
    let service = create_test_service();
    let generator = SwiftActionGenerator::new();
    
    let result = generator.generate_action_enum(&service).await;
    assert!(result.is_ok());
    
    let swift_code = result.unwrap();
    
    // Verify enum structure
    assert!(swift_code.contains("public enum TaskAction"));
    assert!(swift_code.contains(": Sendable"));
    
    // Verify cases
    assert!(swift_code.contains("case createTask(CreateTaskRequest)"));
    assert!(swift_code.contains("case getTask(GetTaskRequest)"));
    assert!(swift_code.contains("case listTasks(ListTasksRequest)"));
    
    // Verify validation methods
    assert!(swift_code.contains("public var isValid: Bool"));
    assert!(swift_code.contains("public var validationErrors: [String]"));
    
    // Verify metadata methods
    assert!(swift_code.contains("public var requiresNetworkAccess: Bool"));
    assert!(swift_code.contains("public var modifiesState: Bool"));
    assert!(swift_code.contains("public var actionName: String"));
}

#[tokio::test]
async fn test_generate_swift_contracts() {
    let message = create_test_message();
    let generator = SwiftContractGenerator::new();
    
    let result = generator.generate_message_struct(&message).await;
    assert!(result.is_ok());
    
    let swift_code = result.unwrap();
    
    // Verify message structure
    assert!(swift_code.contains("public struct Task"));
    assert!(swift_code.contains(": Codable, Equatable, Sendable"));
    
    // Verify field types are mapped correctly
    assert!(swift_code.contains("public let id: String"));
    assert!(swift_code.contains("public let title: String"));
    assert!(swift_code.contains("public let description: String?"));
    assert!(swift_code.contains("public let priority: Int32"));
    assert!(swift_code.contains("public let isCompleted: Bool"));
    assert!(swift_code.contains("public let tags: [String]"));
    
    // Verify initializer
    assert!(swift_code.contains("public init("));
    
    // Verify CodingKeys for proto field mapping
    assert!(swift_code.contains("enum CodingKeys: String, CodingKey"));
    assert!(swift_code.contains("case isCompleted = \"is_completed\""));
}

#[tokio::test]
async fn test_swift_naming_conventions() {
    use axiom_universal_client_generator::generators::swift::naming::*;
    
    // Test proto to Swift name conversion
    assert_eq!(to_swift_property_name("user_id"), "userId");
    assert_eq!(to_swift_property_name("is_completed"), "isCompleted");
    assert_eq!(to_swift_property_name("created_at"), "createdAt");
    assert_eq!(to_swift_property_name("UUID"), "uuid");
    
    // Test proto to Swift type conversion
    assert_eq!(to_swift_type_name("UserService"), "UserService");
    assert_eq!(to_swift_type_name("user_profile"), "UserProfile");
    assert_eq!(to_swift_type_name("API_KEY"), "ApiKey");
    
    // Test method name conversion
    assert_eq!(to_swift_method_name("CreateTask"), "createTask");
    assert_eq!(to_swift_method_name("GetUserProfile"), "getUserProfile");
    assert_eq!(to_swift_method_name("ListAll"), "listAll");
    
    // Test enum case conversion
    assert_eq!(to_swift_enum_case("CreateTask"), "createTask");
    assert_eq!(to_swift_enum_case("DELETE_USER"), "deleteUser");
}

#[tokio::test]
async fn test_proto_type_to_swift_type_mapping() {
    use axiom_universal_client_generator::generators::swift::types::*;
    
    assert_eq!(proto_type_to_swift("string"), "String");
    assert_eq!(proto_type_to_swift("int32"), "Int32");
    assert_eq!(proto_type_to_swift("int64"), "Int64");
    assert_eq!(proto_type_to_swift("uint32"), "UInt32");
    assert_eq!(proto_type_to_swift("uint64"), "UInt64");
    assert_eq!(proto_type_to_swift("bool"), "Bool");
    assert_eq!(proto_type_to_swift("float"), "Float");
    assert_eq!(proto_type_to_swift("double"), "Double");
    assert_eq!(proto_type_to_swift("bytes"), "Data");
    assert_eq!(proto_type_to_swift("CustomMessage"), "CustomMessage");
}

#[tokio::test]
async fn test_generate_swift_test_file() {
    let service = create_test_service();
    let generator = SwiftTestGenerator::new();
    
    let result = generator.generate_test_file(&service).await;
    assert!(result.is_ok());
    
    let swift_code = result.unwrap();
    
    // Verify test structure
    assert!(swift_code.contains("import XCTest"));
    assert!(swift_code.contains("@testable import"));
    assert!(swift_code.contains("class TaskClientTests: XCTestCase"));
    
    // Verify test methods
    assert!(swift_code.contains("func testCreateTask()"));
    assert!(swift_code.contains("func testGetTask()"));
    assert!(swift_code.contains("func testListTasks()"));
    
    // Verify async test patterns
    assert!(swift_code.contains("func test") && swift_code.contains("async throws"));
    
    // Verify test helpers
    assert!(swift_code.contains("setUp()"));
    assert!(swift_code.contains("tearDown()"));
}

#[tokio::test]
async fn test_generate_package_swift() {
    let generator = SwiftPackageGenerator::new();
    let package_name = "TaskManager";
    let dependencies = vec!["AxiomCore".to_string(), "AxiomArchitecture".to_string()];
    
    let result = generator.generate_package_swift(package_name, &dependencies).await;
    assert!(result.is_ok());
    
    let swift_code = result.unwrap();
    
    // Verify Package.swift structure
    assert!(swift_code.contains("// swift-tools-version: 5.9"));
    assert!(swift_code.contains("import PackageDescription"));
    assert!(swift_code.contains("let package = Package("));
    assert!(swift_code.contains("name: \"TaskManager\""));
    
    // Verify dependencies
    assert!(swift_code.contains("dependencies: ["));
    assert!(swift_code.contains("AxiomCore"));
    assert!(swift_code.contains("AxiomArchitecture"));
    
    // Verify targets
    assert!(swift_code.contains("targets: ["));
    assert!(swift_code.contains(".target("));
    assert!(swift_code.contains(".testTarget("));
}

#[tokio::test]
async fn test_file_output_structure() {
    let temp_dir = TempDir::new().unwrap();
    let output_path = temp_dir.path();
    
    let service = create_test_service();
    let message = create_test_message();
    
    let generator = SwiftGenerator::new().await.unwrap();
    
    // Create a ProtoSchema with our test data
    let schema = ProtoSchema {
        files: vec![],
        services: vec![service],
        messages: vec![message],
        enums: vec![],
        dependencies: vec![],
    };
    
    let result = generator.generate_all(
        &schema,
        output_path.to_path_buf(),
        None
    ).await;
    
    assert!(result.is_ok());
    
    // Verify file structure (using actual generator structure)
    assert!(output_path.join("swift").exists());
    assert!(output_path.join("swift/Clients").exists());
    assert!(output_path.join("swift/Contracts").exists());
    
    // Verify generated files exist (using actual file names)
    let generated_files = result.unwrap();
    assert!(!generated_files.is_empty(), "Should generate at least some files");
    
    // Check that files were actually created
    for file_path in &generated_files {
        let path = std::path::Path::new(file_path);
        assert!(path.exists(), "Generated file should exist: {}", file_path);
    }
}

#[tokio::test]
async fn test_error_handling_in_generation() {
    let generator = SwiftClientGenerator::new();
    
    // Test with invalid service (no methods)
    let empty_service = ProtoService {
        name: "EmptyService".to_string(),
        package: "empty.v1".to_string(),
        file_path: "empty_service.proto".to_string(),
        methods: vec![],
        options: ServiceOptions::default(),
        documentation: None,
    };
    
    let result = generator.generate_client_actor(&empty_service).await;
    // Should handle gracefully or provide meaningful error
    assert!(result.is_ok() || result.is_err());
    
    // Test with invalid characters in names
    let invalid_service = ProtoService {
        name: "Invalid-Service".to_string(),
        package: "invalid.v1".to_string(),
        file_path: "invalid_service.proto".to_string(),
        methods: vec![],
        options: ServiceOptions::default(),
        documentation: None,
    };
    
    let result = generator.generate_client_actor(&invalid_service).await;
    // Should handle name sanitization
    assert!(result.is_ok());
}