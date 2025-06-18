//! Unit tests for proto parsing functionality

use axiom_universal_client_generator::proto::{parser::ProtoParser, types::*};
use std::path::PathBuf;
use tempfile::TempDir;

#[tokio::test]
async fn test_parse_simple_service() {
    let proto_content = r#"
syntax = "proto3";

package task;

service TaskService {
    rpc CreateTask(CreateTaskRequest) returns (CreateTaskResponse);
    rpc GetTask(GetTaskRequest) returns (GetTaskResponse);
    rpc UpdateTask(UpdateTaskRequest) returns (UpdateTaskResponse);
    rpc DeleteTask(DeleteTaskRequest) returns (DeleteTaskResponse);
    rpc ListTasks(ListTasksRequest) returns (ListTasksResponse);
}

message CreateTaskRequest {
    string title = 1;
    string description = 2;
    int32 priority = 3;
}

message CreateTaskResponse {
    Task task = 1;
}

message Task {
    string id = 1;
    string title = 2;
    string description = 3;
    int32 priority = 4;
    bool is_completed = 5;
    int64 created_at = 6;
    int64 updated_at = 7;
}
"#;

    let temp_dir = TempDir::new().unwrap();
    let proto_path = temp_dir.path().join("task_service.proto");
    std::fs::write(&proto_path, proto_content).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let result = parser.parse_proto_file(&proto_path).await;
    
    assert!(result.is_ok());
    let proto_file = result.unwrap();
    
    assert_eq!(proto_file.files.len(), 1);
    assert_eq!(proto_file.files[0].package, "task".to_string());
    assert_eq!(proto_file.services.len(), 1);
    
    let service = &proto_file.services[0];
    assert_eq!(service.name, "TaskService");
    assert_eq!(service.methods.len(), 5);
    
    // Verify method names
    let method_names: Vec<&str> = service.methods.iter().map(|m| m.name.as_str()).collect();
    assert!(method_names.contains(&"CreateTask"));
    assert!(method_names.contains(&"GetTask"));
    assert!(method_names.contains(&"UpdateTask"));
    assert!(method_names.contains(&"DeleteTask"));
    assert!(method_names.contains(&"ListTasks"));
    
    // Verify messages
    assert_eq!(proto_file.messages.len(), 3); // CreateTaskRequest, CreateTaskResponse, Task
    
    let task_message = proto_file.messages.iter()
        .find(|m| m.name == "Task")
        .expect("Task message should exist");
    
    assert_eq!(task_message.fields.len(), 7);
    
    // Verify task fields
    let field_names: Vec<&str> = task_message.fields.iter().map(|f| f.name.as_str()).collect();
    assert!(field_names.contains(&"id"));
    assert!(field_names.contains(&"title"));
    assert!(field_names.contains(&"description"));
    assert!(field_names.contains(&"priority"));
    assert!(field_names.contains(&"is_completed"));
    assert!(field_names.contains(&"created_at"));
    assert!(field_names.contains(&"updated_at"));
}

#[tokio::test]
async fn test_parse_nested_messages() {
    let proto_content = r#"
syntax = "proto3";

package user;

message User {
    string id = 1;
    string name = 2;
    Profile profile = 3;
    repeated Address addresses = 4;
}

message Profile {
    string bio = 1;
    string avatar_url = 2;
    Preferences preferences = 3;
}

message Preferences {
    bool email_notifications = 1;
    string theme = 2;
}

message Address {
    string street = 1;
    string city = 2;
    string country = 3;
    bool is_primary = 4;
}
"#;

    let temp_dir = TempDir::new().unwrap();
    let proto_path = temp_dir.path().join("user.proto");
    std::fs::write(&proto_path, proto_content).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let result = parser.parse_proto_file(&proto_path).await;
    
    assert!(result.is_ok());
    let proto_file = result.unwrap();
    
    assert_eq!(proto_file.messages.len(), 4);
    
    // Test nested field types
    let user_message = proto_file.messages.iter()
        .find(|m| m.name == "User")
        .expect("User message should exist");
    
    let profile_field = user_message.fields.iter()
        .find(|f| f.name == "profile")
        .expect("Profile field should exist");
    
    assert_eq!(profile_field.field_type, "Profile");
    assert_ne!(profile_field.label, FieldLabel::Repeated);
    
    let addresses_field = user_message.fields.iter()
        .find(|f| f.name == "addresses")
        .expect("Addresses field should exist");
    
    assert_eq!(addresses_field.field_type, "Address");
    assert_eq!(addresses_field.label, FieldLabel::Repeated);
}

#[tokio::test]
async fn test_parse_with_axiom_options() {
    let proto_content = r#"
syntax = "proto3";

import "axiom_options.proto";

package task;

service TaskService {
    option (axiom.swift_client_actor) = "TaskManager";
    
    rpc CreateTask(CreateTaskRequest) returns (CreateTaskResponse) {
        option (axiom.swift_action_name) = "createNewTask";
        option (axiom.swift_state_update) = "append";
    };
}

message Task {
    option (axiom.swift_state_root) = true;
    
    string id = 1;
    string title = 2 [(axiom.swift_validation) = "required"];
    bool is_completed = 3;
}
"#;

    let temp_dir = TempDir::new().unwrap();
    let proto_path = temp_dir.path().join("task_with_options.proto");
    std::fs::write(&proto_path, proto_content).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let result = parser.parse_proto_file(&proto_path).await;
    
    // Should parse successfully even with custom options
    assert!(result.is_ok());
    let proto_file = result.unwrap();
    
    assert_eq!(proto_file.services.len(), 1);
    assert_eq!(proto_file.messages.len(), 1);
}

#[tokio::test]
async fn test_parse_invalid_proto() {
    let invalid_proto = r#"
syntax = "proto3";

service InvalidService {
    // Missing request/response types
    rpc BadMethod();
    
    // Invalid syntax
    message {
        string field = 1;
    }
}
"#;

    let temp_dir = TempDir::new().unwrap();
    let proto_path = temp_dir.path().join("invalid.proto");
    std::fs::write(&proto_path, invalid_proto).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let result = parser.parse_proto_file(&proto_path).await;
    
    // Should fail with descriptive error
    assert!(result.is_err());
}

#[tokio::test]
async fn test_parse_directory_with_multiple_protos() {
    let proto1 = r#"
syntax = "proto3";
package service1;
service Service1 {
    rpc Method1(Request1) returns (Response1);
}
message Request1 { string data = 1; }
message Response1 { string result = 1; }
"#;

    let proto2 = r#"
syntax = "proto3";
package service2;
service Service2 {
    rpc Method2(Request2) returns (Response2);
}
message Request2 { int32 value = 1; }
message Response2 { bool success = 1; }
"#;

    let temp_dir = TempDir::new().unwrap();
    std::fs::write(temp_dir.path().join("service1.proto"), proto1).unwrap();
    std::fs::write(temp_dir.path().join("service2.proto"), proto2).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let result = parser.parse_proto_directory(temp_dir.path()).await;
    
    assert!(result.is_ok());
    let proto_files = result.unwrap();
    
    assert_eq!(proto_files.files.len(), 2);
    
    // Verify both services are parsed
    let all_services: Vec<&str> = proto_files.services.iter()
        .map(|s| s.name.as_str())
        .collect();
    
    assert!(all_services.contains(&"Service1"));
    assert!(all_services.contains(&"Service2"));
}

#[tokio::test]
async fn test_extract_field_metadata() {
    let proto_content = r#"
syntax = "proto3";

message Task {
    string id = 1;
    string title = 2;
    string description = 3;
    int32 priority = 4;
    bool is_completed = 5;
    repeated string tags = 6;
    map<string, string> metadata = 7;
    oneof status {
        string pending_reason = 8;
        string completed_reason = 9;
    }
}
"#;

    let temp_dir = TempDir::new().unwrap();
    let proto_path = temp_dir.path().join("task.proto");
    std::fs::write(&proto_path, proto_content).unwrap();

    let parser = ProtoParser::new().await.unwrap();
    let result = parser.parse_proto_file(&proto_path).await;
    
    assert!(result.is_ok());
    let proto_file = result.unwrap();
    
    let task_message = &proto_file.messages[0];
    assert_eq!(task_message.fields.len(), 8); // Including oneof fields
    
    // Test repeated field
    let tags_field = task_message.fields.iter()
        .find(|f| f.name == "tags")
        .expect("tags field should exist");
    assert_eq!(tags_field.label, FieldLabel::Repeated);
    assert_eq!(tags_field.field_type, "string");
    
    // Test map field
    let metadata_field = task_message.fields.iter()
        .find(|f| f.name == "metadata")
        .expect("metadata field should exist");
    assert!(metadata_field.field_type.contains("map"));
}