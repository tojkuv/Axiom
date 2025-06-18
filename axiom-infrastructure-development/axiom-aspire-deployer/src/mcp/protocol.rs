use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpRequest {
    pub jsonrpc: String,
    pub id: Value,
    pub method: String,
    pub params: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpResponse {
    pub jsonrpc: String,
    pub id: Value,
    pub result: Option<Value>,
    pub error: Option<McpError>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpError {
    pub code: i32,
    pub message: String,
    pub data: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolDefinition {
    pub name: String,
    pub description: String,
    pub input_schema: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceStatus {
    pub name: String,
    pub status: String,
    pub url: Option<String>,
    pub health: String,
    pub uptime: Option<String>,
    pub last_check: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceUrls {
    pub api: Option<String>,
    pub notifications: Option<String>,
    pub redis: Option<String>,
    pub dashboard: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EndpointCallRequest {
    pub service: String,
    pub endpoint: String,
    pub method: String,
    pub headers: Option<HashMap<String, String>>,
    pub body: Option<Value>,
    pub timeout: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EndpointCallResponse {
    pub status: u16,
    pub headers: HashMap<String, String>,
    pub body: Value,
    pub duration: u64,
}

impl McpRequest {
    pub fn new(id: Value, method: String, params: Option<Value>) -> Self {
        Self {
            jsonrpc: "2.0".to_string(),
            id,
            method,
            params,
        }
    }
}

impl McpResponse {
    pub fn success(id: Value, result: Value) -> Self {
        Self {
            jsonrpc: "2.0".to_string(),
            id,
            result: Some(result),
            error: None,
        }
    }
    
    pub fn error(id: Value, error: McpError) -> Self {
        Self {
            jsonrpc: "2.0".to_string(),
            id,
            result: None,
            error: Some(error),
        }
    }
    
    pub fn method_not_found(id: Value) -> Self {
        Self::error(
            id,
            McpError {
                code: -32601,
                message: "Method not found".to_string(),
                data: None,
            },
        )
    }
    
    pub fn invalid_params(id: Value, message: String) -> Self {
        Self::error(
            id,
            McpError {
                code: -32602,
                message: format!("Invalid params: {}", message),
                data: None,
            },
        )
    }
    
    pub fn internal_error(id: Value, message: String) -> Self {
        Self::error(
            id,
            McpError {
                code: -32603,
                message: format!("Internal error: {}", message),
                data: None,
            },
        )
    }
}

impl McpError {
    pub fn new(code: i32, message: String) -> Self {
        Self {
            code,
            message,
            data: None,
        }
    }
}