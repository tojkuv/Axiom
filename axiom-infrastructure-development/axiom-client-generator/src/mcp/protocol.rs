use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// MCP request message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpRequest {
    pub jsonrpc: String,
    pub id: serde_json::Value,
    pub method: String,
    pub params: Option<serde_json::Value>,
}

/// MCP response message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpResponse {
    pub jsonrpc: String,
    pub id: serde_json::Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<McpError>,
}

/// MCP error object
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpError {
    pub code: i32,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,
}

/// MCP notification message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpNotification {
    pub jsonrpc: String,
    pub method: String,
    pub params: Option<serde_json::Value>,
}

/// Server capabilities
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerCapabilities {
    pub tools: Option<ToolsCapability>,
    pub prompts: Option<PromptsCapability>,
    pub resources: Option<ResourcesCapability>,
    pub logging: Option<LoggingCapability>,
}

/// Tools capability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolsCapability {
    pub list_changed: Option<bool>,
}

/// Prompts capability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PromptsCapability {
    pub list_changed: Option<bool>,
}

/// Resources capability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourcesCapability {
    pub subscribe: Option<bool>,
    pub list_changed: Option<bool>,
}

/// Logging capability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingCapability {}

/// Server information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerInfo {
    pub name: String,
    pub version: String,
}

/// Client information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClientInfo {
    pub name: String,
    pub version: String,
}

/// Initialize request parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InitializeParams {
    #[serde(rename = "protocolVersion")]
    pub protocol_version: String,
    pub capabilities: ClientCapabilities,
    #[serde(rename = "clientInfo")]
    pub client_info: ClientInfo,
}

/// Client capabilities
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClientCapabilities {
    pub roots: Option<RootsCapability>,
    pub sampling: Option<SamplingCapability>,
}

/// Roots capability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RootsCapability {
    #[serde(rename = "listChanged")]
    pub list_changed: Option<bool>,
}

/// Sampling capability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SamplingCapability {}

/// Initialize result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InitializeResult {
    #[serde(rename = "protocolVersion")]
    pub protocol_version: String,
    pub capabilities: ServerCapabilities,
    #[serde(rename = "serverInfo")]
    pub server_info: ServerInfo,
}

/// Tool definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tool {
    pub name: String,
    pub description: String,
    #[serde(rename = "inputSchema")]
    pub input_schema: serde_json::Value,
}

/// Tool call request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallToolParams {
    pub name: String,
    pub arguments: Option<HashMap<String, serde_json::Value>>,
}

/// Tool call result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallToolResult {
    pub content: Vec<ToolContent>,
    #[serde(rename = "isError")]
    pub is_error: Option<bool>,
}

/// Tool content with enhanced formatting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolContent {
    #[serde(rename = "type")]
    pub content_type: String,
    pub text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mime_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,
}

impl ToolContent {
    pub fn text(content: String) -> Self {
        Self {
            content_type: "text".to_string(),
            text: content,
            mime_type: None,
            data: None,
        }
    }
    
    pub fn json(value: serde_json::Value) -> Self {
        Self {
            content_type: "json".to_string(),
            text: value.to_string(),
            mime_type: Some("application/json".to_string()),
            data: Some(value),
        }
    }
}

/// Progress notification for real-time feedback
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProgressNotification {
    pub operation_id: String,
    pub stage: String,
    pub progress: f32, // 0.0 to 100.0, -1.0 for error
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
    pub timestamp: u64,
}

/// Enhanced error with context
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnhancedMcpError {
    pub code: i32,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<ErrorContext>,
    pub timestamp: u64,
}

/// Error context for better debugging
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorContext {
    pub operation: String,
    pub stage: String,
    pub suggestion: Option<String>,
    pub documentation_link: Option<String>,
}

/// Error codes as defined by the MCP specification
pub mod error_codes {
    pub const PARSE_ERROR: i32 = -32700;
    pub const INVALID_REQUEST: i32 = -32600;
    pub const METHOD_NOT_FOUND: i32 = -32601;
    pub const INVALID_PARAMS: i32 = -32602;
    pub const INTERNAL_ERROR: i32 = -32603;
}

impl McpError {
    pub fn parse_error(message: &str) -> Self {
        Self {
            code: error_codes::PARSE_ERROR,
            message: message.to_string(),
            data: None,
        }
    }

    pub fn invalid_request(message: &str) -> Self {
        Self {
            code: error_codes::INVALID_REQUEST,
            message: message.to_string(),
            data: None,
        }
    }

    pub fn method_not_found(method: &str) -> Self {
        Self {
            code: error_codes::METHOD_NOT_FOUND,
            message: format!("Method not found: {}", method),
            data: None,
        }
    }

    pub fn invalid_params(message: &str) -> Self {
        Self {
            code: error_codes::INVALID_PARAMS,
            message: message.to_string(),
            data: None,
        }
    }

    pub fn internal_error(message: &str) -> Self {
        Self {
            code: error_codes::INTERNAL_ERROR,
            message: message.to_string(),
            data: None,
        }
    }
    
    /// Create error with contextual information
    pub fn contextual_error(code: i32, message: &str, context: serde_json::Value) -> Self {
        Self {
            code,
            message: message.to_string(),
            data: Some(context),
        }
    }
    
    /// Create user-friendly error with suggestions
    pub fn user_error(message: &str, suggestion: &str) -> Self {
        let data = serde_json::json!({
            "suggestion": suggestion,
            "documentation": "https://docs.axiom.com/client-generator",
            "examples": "Use 'get_examples' tool to see available templates"
        });
        
        Self {
            code: error_codes::INVALID_PARAMS,
            message: message.to_string(),
            data: Some(data),
        }
    }
}

impl McpResponse {
    pub fn success(id: serde_json::Value, result: serde_json::Value) -> Self {
        Self {
            jsonrpc: "2.0".to_string(),
            id,
            result: Some(result),
            error: None,
        }
    }

    pub fn error(id: serde_json::Value, error: McpError) -> Self {
        Self {
            jsonrpc: "2.0".to_string(),
            id,
            result: None,
            error: Some(error),
        }
    }
    
    /// Create enhanced error response with context
    pub fn enhanced_error(id: serde_json::Value, error: EnhancedMcpError) -> Self {
        let mcp_error = McpError {
            code: error.code,
            message: error.message,
            data: error.data,
        };
        
        Self {
            jsonrpc: "2.0".to_string(),
            id,
            result: None,
            error: Some(mcp_error),
        }
    }
}


/// Progress notification helpers
impl ProgressNotification {
    pub fn new(operation_id: String, stage: String, progress: f32, message: String) -> Self {
        Self {
            operation_id,
            stage,
            progress,
            message,
            details: None,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64,
        }
    }
    
    pub fn with_details(mut self, details: serde_json::Value) -> Self {
        self.details = Some(details);
        self
    }
    
    pub fn to_notification(&self) -> McpNotification {
        McpNotification {
            jsonrpc: "2.0".to_string(),
            method: "notifications/progress".to_string(),
            params: Some(serde_json::to_value(self).unwrap()),
        }
    }
}

/// Enhanced error helpers
impl EnhancedMcpError {
    pub fn validation_error(message: &str, context: ErrorContext) -> Self {
        Self {
            code: error_codes::INVALID_PARAMS,
            message: message.to_string(),
            data: None,
            context: Some(context),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64,
        }
    }
    
    pub fn generation_error(message: &str, operation: &str, suggestion: Option<&str>) -> Self {
        let context = ErrorContext {
            operation: operation.to_string(),
            stage: "generation".to_string(),
            suggestion: suggestion.map(|s| s.to_string()),
            documentation_link: Some("https://docs.axiom.com/client-generator/troubleshooting".to_string()),
        };
        
        Self {
            code: error_codes::INTERNAL_ERROR,
            message: message.to_string(),
            data: None,
            context: Some(context),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64,
        }
    }
}

/// Tool call request types for MCP tests
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCallRequest {
    pub method: String,
    pub params: ToolCallParams,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCallParams {
    pub name: String,
    pub arguments: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCallResponse {
    pub content: Vec<ToolContent>,
    #[serde(rename = "isError")]
    pub is_error: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListToolsRequest {
    pub method: String,
    pub params: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListToolsResponse {
    pub tools: Vec<Tool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProgressParams {
    #[serde(rename = "progressToken")]
    pub progress_token: String,
    pub progress: f64,
    pub total: Option<f64>,
}