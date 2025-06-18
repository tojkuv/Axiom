//! Test helper utilities for consistent test setup and data management

use axiom_universal_client_generator::proto::types::*;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tempfile::TempDir;

/// Creates a temporary directory for test files
pub fn create_test_temp_dir() -> TempDir {
    TempDir::new().expect("Failed to create temporary directory")
}

/// Creates a test proto file with the given content
pub fn create_test_proto_file(temp_dir: &Path, filename: &str, content: &str) -> PathBuf {
    let proto_path = temp_dir.join(filename);
    std::fs::write(&proto_path, content).expect("Failed to write proto file");
    proto_path
}

/// Creates a test Swift file with the given content
pub fn create_test_swift_file(temp_dir: &Path, filename: &str, content: &str) -> PathBuf {
    let swift_path = temp_dir.join(filename);
    std::fs::write(&swift_path, content).expect("Failed to write Swift file");
    swift_path
}

/// Reads a file from the fixtures directory
pub fn read_fixture_file(relative_path: &str) -> String {
    let fixtures_dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures");
    let file_path = fixtures_dir.join(relative_path);
    std::fs::read_to_string(&file_path)
        .unwrap_or_else(|_| panic!("Failed to read fixture file: {}", file_path.display()))
}

/// Creates a sample TaskService proto service for testing
pub fn create_task_service() -> Service {
    Service {
        name: "TaskService".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        methods: vec![
            Method {
                name: "CreateTask".to_string(),
                input_type: "CreateTaskRequest".to_string(),
                output_type: "CreateTaskResponse".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("createNewTask", StateUpdateStrategy::Append),
                documentation: None,
            },
            Method {
                name: "GetTask".to_string(),
                input_type: "GetTaskRequest".to_string(),
                output_type: "Task".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("fetchTask", StateUpdateStrategy::NoChange),
                documentation: None,
            },
            Method {
                name: "UpdateTask".to_string(),
                input_type: "UpdateTaskRequest".to_string(),
                output_type: "Task".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("modifyTask", StateUpdateStrategy::UpdateById),
                documentation: None,
            },
            Method {
                name: "DeleteTask".to_string(),
                input_type: "DeleteTaskRequest".to_string(),
                output_type: "DeleteTaskResponse".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("removeTask", StateUpdateStrategy::RemoveById),
                documentation: None,
            },
            Method {
                name: "ListTasks".to_string(),
                input_type: "ListTasksRequest".to_string(),
                output_type: "ListTasksResponse".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("loadAllTasks", StateUpdateStrategy::ReplaceAll),
                documentation: None,
            },
        ],
        options: ServiceOptions {
            axiom_service: Some(AxiomServiceOptions {
                client_name: Some("TaskManager".to_string()),
                state_name: Some("TaskState".to_string()),
                action_name: Some("TaskAction".to_string()),
                import_modules: vec!["Foundation".to_string()],
                generate_tests: Some(true),
                swift_package_name: Some("TaskManager".to_string()),
                collections: vec![],
                supports_pagination: Some(true),
            }),
            standard_options: HashMap::new(),
        },
        documentation: None,
    }
}

/// Creates a sample Task message for testing
pub fn create_task_message() -> Message {
    Message {
        name: "Task".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        fields: vec![
            Field {
                name: "id".to_string(),
                field_type: "string".to_string(),
                number: 1,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            Field {
                name: "title".to_string(),
                field_type: "string".to_string(),
                number: 2,
                label: FieldLabel::Optional,
                default_value: None,
                options: create_field_options(true, 1, None),
                documentation: None,
            },
            Field {
                name: "description".to_string(),
                field_type: "string".to_string(),
                number: 3,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            Field {
                name: "priority".to_string(),
                field_type: "Priority".to_string(),
                number: 4,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            Field {
                name: "is_completed".to_string(),
                field_type: "bool".to_string(),
                number: 5,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            Field {
                name: "tags".to_string(),
                field_type: "string".to_string(),
                number: 6,
                label: FieldLabel::Repeated,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            Field {
                name: "created_at".to_string(),
                field_type: "google.protobuf.Timestamp".to_string(),
                number: 7,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
        ],
        nested_messages: vec![],
        nested_enums: vec![],
        options: MessageOptions {
            axiom_message: Some(AxiomMessageOptions {
                identifiable: true,
                id_field: Some("id".to_string()),
                equatable: true,
                derived_properties: vec![],
            }),
            standard_options: HashMap::new(),
        },
        documentation: None,
    }
}

/// Creates a sample UserService proto service for testing
pub fn create_user_service() -> Service {
    Service {
        name: "UserService".to_string(),
        package: "user.v1".to_string(),
        file_path: "user_service.proto".to_string(),
        methods: vec![
            Method {
                name: "RegisterUser".to_string(),
                input_type: "RegisterUserRequest".to_string(),
                output_type: "User".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("registerUser", StateUpdateStrategy::Append),
                documentation: None,
            },
            Method {
                name: "GetUser".to_string(),
                input_type: "GetUserRequest".to_string(),
                output_type: "User".to_string(),
                client_streaming: false,
                server_streaming: false,
                options: create_method_options("fetchUser", StateUpdateStrategy::NoChange),
                documentation: None,
            },
        ],
        options: ServiceOptions {
            axiom_service: Some(AxiomServiceOptions {
                client_name: Some("UserClient".to_string()),
                state_name: Some("UserState".to_string()),
                action_name: Some("UserAction".to_string()),
                import_modules: vec!["Foundation".to_string()],
                generate_tests: Some(true),
                swift_package_name: Some("UserManager".to_string()),
                collections: vec![],
                supports_pagination: Some(false),
            }),
            standard_options: HashMap::new(),
        },
        documentation: None,
    }
}

/// Creates a sample User message for testing
pub fn create_user_message() -> Message {
    Message {
        name: "User".to_string(),
        package: "user.v1".to_string(),
        file_path: "user_service.proto".to_string(),
        fields: vec![
            Field {
                name: "id".to_string(),
                field_type: "string".to_string(),
                number: 1,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
            Field {
                name: "email".to_string(),
                field_type: "string".to_string(),
                number: 2,
                label: FieldLabel::Optional,
                default_value: None,
                options: create_field_options(true, 1, Some("email".to_string())),
                documentation: None,
            },
            Field {
                name: "first_name".to_string(),
                field_type: "string".to_string(),
                number: 3,
                label: FieldLabel::Optional,
                default_value: None,
                options: create_field_options(true, 1, None),
                documentation: None,
            },
            Field {
                name: "last_name".to_string(),
                field_type: "string".to_string(),
                number: 4,
                label: FieldLabel::Optional,
                default_value: None,
                options: create_field_options(true, 1, None),
                documentation: None,
            },
        ],
        nested_messages: vec![],
        nested_enums: vec![],
        options: MessageOptions {
            axiom_message: Some(AxiomMessageOptions {
                identifiable: true,
                id_field: Some("id".to_string()),
                equatable: true,
                derived_properties: vec![],
            }),
            standard_options: HashMap::new(),
        },
        documentation: None,
    }
}

/// Creates a complete proto schema structure for testing
pub fn create_complete_proto_schema() -> ProtoSchema {
    let task_service = create_task_service();
    let task_message = create_task_message();
    
    let create_task_request = Message {
        name: "CreateTaskRequest".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        fields: vec![
            Field {
                name: "title".to_string(),
                field_type: "string".to_string(),
                number: 1,
                label: FieldLabel::Optional,
                default_value: None,
                options: create_field_options(true, 1, None),
                documentation: None,
            },
            Field {
                name: "description".to_string(),
                field_type: "string".to_string(),
                number: 2,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
        ],
        nested_messages: vec![],
        nested_enums: vec![],
        options: MessageOptions::default(),
        documentation: None,
    };
    
    let create_task_response = Message {
        name: "CreateTaskResponse".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        fields: vec![
            Field {
                name: "task".to_string(),
                field_type: "Task".to_string(),
                number: 1,
                label: FieldLabel::Optional,
                default_value: None,
                options: FieldOptions::default(),
                documentation: None,
            },
        ],
        nested_messages: vec![],
        nested_enums: vec![],
        options: MessageOptions::default(),
        documentation: None,
    };
    
    let priority_enum = Enum {
        name: "Priority".to_string(),
        package: "task.v1".to_string(),
        file_path: "task_service.proto".to_string(),
        values: vec![
            EnumValue {
                name: "PRIORITY_UNSPECIFIED".to_string(),
                number: 0,
                options: EnumValueOptions::default(),
                documentation: None,
            },
            EnumValue {
                name: "PRIORITY_LOW".to_string(),
                number: 1,
                options: EnumValueOptions::default(),
                documentation: None,
            },
            EnumValue {
                name: "PRIORITY_MEDIUM".to_string(),
                number: 2,
                options: EnumValueOptions::default(),
                documentation: None,
            },
            EnumValue {
                name: "PRIORITY_HIGH".to_string(),
                number: 3,
                options: EnumValueOptions::default(),
                documentation: None,
            },
        ],
        options: EnumOptions::default(),
        documentation: None,
    };
    
    let proto_file = ProtoFile {
        path: "task_service.proto".to_string(),
        package: "task.v1".to_string(),
        syntax: "proto3".to_string(),
        imports: vec![
            "google/protobuf/timestamp.proto".to_string(),
            "axiom_options.proto".to_string(),
        ],
        services: vec!["TaskService".to_string()],
        messages: vec!["Task".to_string(), "CreateTaskRequest".to_string(), "CreateTaskResponse".to_string()],
        enums: vec!["Priority".to_string()],
    };
    
    ProtoSchema {
        files: vec![proto_file],
        services: vec![task_service],
        messages: vec![task_message, create_task_request, create_task_response],
        enums: vec![priority_enum],
        dependencies: vec![
            "google/protobuf/timestamp.proto".to_string(),
            "axiom_options.proto".to_string(),
        ],
    }
}

/// Helper function to create method options
fn create_method_options(swift_action_name: &str, state_update_strategy: StateUpdateStrategy) -> MethodOptions {
    MethodOptions {
        axiom_method: Some(AxiomMethodOptions {
            state_update_strategy,
            collection_name: None,
            requires_network: Some(true),
            modifies_state: Some(state_update_strategy != StateUpdateStrategy::NoChange),
            show_loading_state: Some(true),
            validation_rules: vec![],
            action_documentation: Some(format!("Action: {}", swift_action_name)),
            id_field_name: Some("id".to_string()),
            supports_offline: Some(false),
            cache_strategy: CacheStrategy::Memory,
        }),
        standard_options: HashMap::new(),
    }
}

/// Helper function to create field options
fn create_field_options(required: bool, min_length: i32, validation_pattern: Option<String>) -> FieldOptions {
    FieldOptions {
        axiom_field: Some(AxiomFieldOptions {
            is_id_field: None,
            searchable: Some(true),
            sortable: Some(false),
            required: Some(required),
            validation_pattern,
            min_value: None,
            max_value: None,
            min_length: Some(min_length),
            max_length: None,
            exclude_from_equality: Some(false),
        }),
        standard_options: HashMap::new(),
    }
}

/// Asserts that two strings are equal, ignoring whitespace differences
pub fn assert_swift_code_equal(expected: &str, actual: &str) {
    let normalize = |s: &str| {
        s.lines()
            .map(|line| line.trim())
            .filter(|line| !line.is_empty())
            .collect::<Vec<_>>()
            .join("\n")
    };
    
    let expected_normalized = normalize(expected);
    let actual_normalized = normalize(actual);
    
    if expected_normalized != actual_normalized {
        println!("Expected:");
        println!("{}", expected);
        println!("\nActual:");
        println!("{}", actual);
        panic!("Swift code does not match expected output");
    }
}

/// Asserts that generated Swift code contains specific patterns
pub fn assert_swift_contains_patterns(code: &str, patterns: &[&str]) {
    for pattern in patterns {
        assert!(
            code.contains(pattern),
            "Swift code does not contain expected pattern: '{}'",
            pattern
        );
    }
}

/// Asserts that generated Swift code does not contain specific patterns
pub fn assert_swift_not_contains_patterns(code: &str, patterns: &[&str]) {
    for pattern in patterns {
        assert!(
            !code.contains(pattern),
            "Swift code contains forbidden pattern: '{}'",
            pattern
        );
    }
}

/// Creates a mock API client for testing
pub fn create_mock_api_client() -> MockApiClient {
    MockApiClient::new()
}

/// Mock API client for testing purposes
pub struct MockApiClient {
    responses: HashMap<String, String>,
}

impl MockApiClient {
    pub fn new() -> Self {
        Self {
            responses: HashMap::new(),
        }
    }
    
    pub fn add_response(&mut self, method_name: &str, response: &str) {
        self.responses.insert(method_name.to_string(), response.to_string());
    }
    
    pub fn get_response(&self, method_name: &str) -> Option<&String> {
        self.responses.get(method_name)
    }
}

/// Timing utilities for performance tests
pub struct TestTimer {
    start: std::time::Instant,
}

impl TestTimer {
    pub fn new() -> Self {
        Self {
            start: std::time::Instant::now(),
        }
    }
    
    pub fn elapsed(&self) -> std::time::Duration {
        self.start.elapsed()
    }
    
    pub fn assert_max_duration(&self, max_duration: std::time::Duration) {
        let elapsed = self.elapsed();
        assert!(
            elapsed <= max_duration,
            "Operation took too long: {:?} > {:?}",
            elapsed,
            max_duration
        );
    }
}

/// File system test utilities
pub fn ensure_directory_exists(path: &Path) {
    if !path.exists() {
        std::fs::create_dir_all(path).expect("Failed to create directory");
    }
}

pub fn cleanup_test_files(paths: &[&Path]) {
    for path in paths {
        if path.exists() {
            if path.is_dir() {
                std::fs::remove_dir_all(path).ok();
            } else {
                std::fs::remove_file(path).ok();
            }
        }
    }
}

/// Assertion macros for common test patterns
#[macro_export]
macro_rules! assert_valid_swift_syntax {
    ($code:expr) => {
        // This would integrate with the Swift syntax validator in real implementation
        assert!(!$code.is_empty(), "Swift code cannot be empty");
        assert!($code.contains("import"), "Swift code should contain import statements");
    };
}

#[macro_export]
macro_rules! assert_axiom_client_conformance {
    ($code:expr) => {
        assert!($code.contains(": AxiomClient"), "Code should conform to AxiomClient protocol");
        assert!($code.contains("public typealias StateType"), "Code should define StateType");
        assert!($code.contains("public typealias ActionType"), "Code should define ActionType");
        assert!($code.contains("public var stateStream"), "Code should implement stateStream");
        assert!($code.contains("public func process"), "Code should implement process method");
    };
}