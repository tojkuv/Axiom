//! MCP protocol integration tests

use axiom_universal_client_generator::mcp::protocol::*;
use serde_json::json;

#[test]
fn test_tool_call_request_serialization() {
    let request = ToolCallRequest {
        method: "tools/call".to_string(),
        params: ToolCallParams {
            name: "axiom_generate_swift_client".to_string(),
            arguments: json!({
                "proto_path": "example.proto",
                "output_path": "./generated",
                "target_languages": ["swift"]
            }),
        },
    };

    let serialized = serde_json::to_string(&request).unwrap();
    assert!(serialized.contains("tools/call"));
    assert!(serialized.contains("axiom_generate_swift_client"));
    assert!(serialized.contains("example.proto"));
}

#[test]
fn test_tool_call_response_serialization() {
    let response = ToolCallResponse {
        content: vec![
            ToolContent::text("Generation completed successfully".to_string()),
            ToolContent::text(json!({
                "generated_files": ["TaskClient.swift", "TaskState.swift"],
                "success": true
            }).to_string()),
        ],
        is_error: false,
    };

    let serialized = serde_json::to_string(&response).unwrap();
    assert!(serialized.contains("Generation completed successfully"));
    assert!(serialized.contains("TaskClient.swift"));
    assert!(!serialized.contains("\"is_error\":true"));
}

#[test]
fn test_tool_call_error_response() {
    let error_response = ToolCallResponse {
        content: vec![
            ToolContent::text("Error: Failed to parse proto file".to_string()),
        ],
        is_error: true,
    };

    let serialized = serde_json::to_string(&error_response).unwrap();
    assert!(serialized.contains("Error: Failed to parse proto file"));
    assert!(serialized.contains("\"isError\":true"));
}

#[test]
fn test_list_tools_request() {
    let request = ListToolsRequest {
        method: "tools/list".to_string(),
        params: None,
    };

    let serialized = serde_json::to_string(&request).unwrap();
    assert!(serialized.contains("tools/list"));
}

#[test]
fn test_list_tools_response() {
    let tool = Tool {
        name: "axiom_generate_swift_client".to_string(),
        description: "Generate Axiom-compatible Swift client code from gRPC proto files".to_string(),
        input_schema: json!({
            "type": "object",
            "properties": {
                "proto_path": {
                    "type": "string",
                    "description": "Path to proto file or directory"
                },
                "output_path": {
                    "type": "string", 
                    "description": "Output directory for generated files"
                },
                "target_languages": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "Programming languages to generate"
                }
            },
            "required": ["proto_path", "output_path"]
        }),
    };

    let response = ListToolsResponse {
        tools: vec![tool],
    };

    let serialized = serde_json::to_string(&response).unwrap();
    assert!(serialized.contains("axiom_generate_swift_client"));
    assert!(serialized.contains("Generate Axiom-compatible Swift client"));
    assert!(serialized.contains("proto_path"));
    assert!(serialized.contains("output_path"));
}

#[tokio::test]
async fn test_progress_notification() {
    let notification = ProgressNotification {
        operation_id: "gen_123".to_string(),
        stage: "generation".to_string(),
        progress: 50.0,
        message: "Generating Swift client files".to_string(),
        details: None,
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64,
    };

    let mcp_notification = notification.to_notification();
    let serialized = serde_json::to_string(&mcp_notification).unwrap();
    assert!(serialized.contains("notifications/progress"));
    assert!(serialized.contains("gen_123"));
    assert!(serialized.contains("50"));
}

#[test]
fn test_tool_content_types() {
    let text_content = ToolContent::text("Simple text content".to_string());
    let json_content = ToolContent::json(json!({"key": "value"}));
    
    // Test serialization
    let text_serialized = serde_json::to_string(&text_content).unwrap();
    let json_serialized = serde_json::to_string(&json_content).unwrap();
    
    assert!(text_serialized.contains("Simple text content"));
    assert!(json_serialized.contains("key"));
    assert!(json_serialized.contains("value"));
}