use axiom_aspire_mcp::mcp::protocol::{McpRequest, McpResponse, McpError, ServiceStatus};
use serde_json::{json, Value};

#[test]
fn test_mcp_request_creation() {
    let request = McpRequest::new(
        json!(1),
        "axiom_aspire_status".to_string(),
        Some(json!({}))
    );
    
    assert_eq!(request.jsonrpc, "2.0");
    assert_eq!(request.id, json!(1));
    assert_eq!(request.method, "axiom_aspire_status");
    assert!(request.params.is_some());
}

#[test]
fn test_mcp_response_success() {
    let response = McpResponse::success(
        json!(1),
        json!({"status": "success"})
    );
    
    assert_eq!(response.jsonrpc, "2.0");
    assert_eq!(response.id, json!(1));
    assert!(response.result.is_some());
    assert!(response.error.is_none());
    assert_eq!(response.result.unwrap()["status"], "success");
}

#[test]
fn test_mcp_response_error() {
    let error = McpError::new(-32601, "Method not found".to_string());
    let response = McpResponse::error(json!(1), error);
    
    assert_eq!(response.jsonrpc, "2.0");
    assert_eq!(response.id, json!(1));
    assert!(response.result.is_none());
    assert!(response.error.is_some());
    
    let err = response.error.unwrap();
    assert_eq!(err.code, -32601);
    assert_eq!(err.message, "Method not found");
}

#[test]
fn test_mcp_response_method_not_found() {
    let response = McpResponse::method_not_found(json!(1));
    
    assert!(response.error.is_some());
    let err = response.error.unwrap();
    assert_eq!(err.code, -32601);
    assert_eq!(err.message, "Method not found");
}

#[test]
fn test_mcp_response_invalid_params() {
    let response = McpResponse::invalid_params(json!(1), "Missing required parameter".to_string());
    
    assert!(response.error.is_some());
    let err = response.error.unwrap();
    assert_eq!(err.code, -32602);
    assert!(err.message.contains("Invalid params"));
}

#[test]
fn test_mcp_response_internal_error() {
    let response = McpResponse::internal_error(json!(1), "Database connection failed".to_string());
    
    assert!(response.error.is_some());
    let err = response.error.unwrap();
    assert_eq!(err.code, -32603);
    assert!(err.message.contains("Internal error"));
}

#[test]
fn test_service_status_creation() {
    let status = ServiceStatus {
        name: "api".to_string(),
        status: "running".to_string(),
        url: Some("https://localhost:7001".to_string()),
        health: "healthy".to_string(),
        uptime: Some("2h 30m".to_string()),
        last_check: chrono::Utc::now(),
    };
    
    assert_eq!(status.name, "api");
    assert_eq!(status.status, "running");
    assert_eq!(status.health, "healthy");
    assert!(status.url.is_some());
    assert!(status.uptime.is_some());
}

#[test]
fn test_mcp_request_serialization() {
    let request = McpRequest::new(
        json!(1),
        "axiom_aspire_start".to_string(),
        Some(json!({"profile": "Development", "watch": false}))
    );
    
    let serialized = serde_json::to_string(&request).unwrap();
    let deserialized: McpRequest = serde_json::from_str(&serialized).unwrap();
    
    assert_eq!(deserialized.jsonrpc, "2.0");
    assert_eq!(deserialized.method, "axiom_aspire_start");
    assert_eq!(deserialized.id, json!(1));
}

#[test]
fn test_mcp_response_serialization() {
    let response = McpResponse::success(
        json!(1),
        json!({"services": [], "total_services": 0})
    );
    
    let serialized = serde_json::to_string(&response).unwrap();
    let deserialized: McpResponse = serde_json::from_str(&serialized).unwrap();
    
    assert_eq!(deserialized.jsonrpc, "2.0");
    assert_eq!(deserialized.id, json!(1));
    assert!(deserialized.result.is_some());
}