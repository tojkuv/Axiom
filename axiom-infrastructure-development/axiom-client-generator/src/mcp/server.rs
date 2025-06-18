use crate::error::{Error, Result};
use crate::mcp::{handlers::McpHandlers, protocol::*};
use crate::AxiomSwiftClientGenerator;
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::io::{self, AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::sync::{mpsc, RwLock};
use tokio::time::{interval, Duration};
use tracing::{debug, error, info, warn};

/// Session state for tracking operations
#[derive(Debug, Clone)]
struct SessionState {
    client_info: Option<ClientInfo>,
    last_generation_time: Option<std::time::Instant>,
    generation_cache: HashMap<String, Value>,
}

/// MCP server for Axiom Swift Client Generator with enhanced performance
pub struct AxiomMcpServer {
    generator: Arc<AxiomSwiftClientGenerator>,
    handlers: McpHandlers,
    session_state: Arc<RwLock<SessionState>>,
    progress_sender: Option<mpsc::UnboundedSender<ProgressUpdate>>,
}

/// Progress update for real-time feedback
#[derive(Debug, Clone)]
pub struct ProgressUpdate {
    pub operation_id: String,
    pub stage: String,
    pub progress: f32,
    pub message: String,
    pub details: Option<Value>,
}

impl AxiomMcpServer {
    /// Create a new MCP server with enhanced capabilities
    pub async fn new() -> Result<Self> {
        let generator = Arc::new(AxiomSwiftClientGenerator::new().await?);
        let handlers = McpHandlers::new();
        let session_state = Arc::new(RwLock::new(SessionState {
            client_info: None,
            last_generation_time: None,
            generation_cache: HashMap::new(),
        }));

        Ok(Self {
            generator,
            handlers,
            session_state,
            progress_sender: None,
        })
    }

    /// Create server with progress reporting
    pub async fn new_with_progress(progress_sender: mpsc::UnboundedSender<ProgressUpdate>) -> Result<Self> {
        let mut server = Self::new().await?;
        server.progress_sender = Some(progress_sender);
        Ok(server)
    }

    /// Run the MCP server with enhanced performance and batching
    pub async fn run(&self) -> Result<()> {
        info!("Starting Axiom Universal Client Generator MCP Server v{}", env!("CARGO_PKG_VERSION"));
        info!("Enhanced features: progress reporting, caching, real-time validation");

        let stdin = io::stdin();
        let mut stdout = io::stdout();
        let mut reader = BufReader::new(stdin);
        
        // Message batching for improved performance
        let (message_tx, mut message_rx) = mpsc::unbounded_channel::<String>();
        let (response_tx, mut response_rx) = mpsc::unbounded_channel::<String>();
        
        // Spawn message processor
        let server_clone = self.clone();
        let processor_handle = tokio::spawn(async move {
            while let Some(message) = message_rx.recv().await {
                match server_clone.handle_message(&message).await {
                    Ok(Some(response)) => {
                        if let Ok(response_json) = serde_json::to_string(&response) {
                            let _ = response_tx.send(response_json);
                        }
                    }
                    Ok(None) => {}
                    Err(e) => {
                        error!("Error processing message: {}", e);
                        let error_response = McpResponse::error(
                            Value::Null,
                            McpError::internal_error(&e.to_string()),
                        );
                        if let Ok(error_json) = serde_json::to_string(&error_response) {
                            let _ = response_tx.send(error_json);
                        }
                    }
                }
            }
        });
        
        // Spawn response writer
        let writer_handle = tokio::spawn(async move {
            while let Some(response) = response_rx.recv().await {
                debug!("Sending MCP response: {}", response);
                if let Err(e) = stdout.write_all(response.as_bytes()).await {
                    error!("Failed to write response: {}", e);
                    break;
                }
                if let Err(e) = stdout.write_all(b"\n").await {
                    error!("Failed to write newline: {}", e);
                    break;
                }
                if let Err(e) = stdout.flush().await {
                    error!("Failed to flush output: {}", e);
                    break;
                }
            }
        });
        
        // Cache cleanup timer
        let session_state = self.session_state.clone();
        let cleanup_handle = tokio::spawn(async move {
            let mut cleanup_interval = interval(Duration::from_secs(300)); // 5 minutes
            loop {
                cleanup_interval.tick().await;
                let mut state = session_state.write().await;
                
                // Clean old cache entries
                if let Some(last_gen) = state.last_generation_time {
                    if last_gen.elapsed() > Duration::from_secs(600) { // 10 minutes
                        state.generation_cache.clear();
                        debug!("Cleaned generation cache");
                    }
                }
            }
        });

        // Main message reading loop
        loop {
            let mut line = String::new();
            match reader.read_line(&mut line).await {
                Ok(0) => {
                    info!("EOF reached, shutting down MCP server");
                    break;
                }
                Ok(_) => {
                    let line = line.trim();
                    if line.is_empty() {
                        continue;
                    }

                    debug!("Received MCP message: {}", line);
                    
                    // Send to processor
                    if let Err(e) = message_tx.send(line.to_string()) {
                        error!("Failed to queue message: {}", e);
                        break;
                    }
                }
                Err(e) => {
                    error!("Error reading from stdin: {}", e);
                    break;
                }
            }
        }
        
        // Cleanup
        processor_handle.abort();
        writer_handle.abort();
        cleanup_handle.abort();

        Ok(())
    }

    /// Handle an incoming MCP message
    async fn handle_message(&self, message: &str) -> Result<Option<McpResponse>> {
        // Try to parse as request first
        if let Ok(request) = serde_json::from_str::<McpRequest>(message) {
            return Ok(Some(self.handle_request(request).await));
        }

        // Try to parse as notification
        if let Ok(notification) = serde_json::from_str::<McpNotification>(message) {
            self.handle_notification(notification).await?;
            return Ok(None);
        }

        Err(Error::McpError("Invalid message format".to_string()))
    }

    /// Handle MCP request
    async fn handle_request(&self, request: McpRequest) -> McpResponse {
        match request.method.as_str() {
            "initialize" => self.handle_initialize(request).await,
            "tools/list" => self.handle_tools_list(request).await,
            "tools/call" => self.handle_tools_call(request).await,
            _ => McpResponse::error(
                request.id,
                McpError::method_not_found(&request.method),
            ),
        }
    }

    /// Handle MCP notification
    async fn handle_notification(&self, notification: McpNotification) -> Result<()> {
        match notification.method.as_str() {
            "notifications/initialized" => {
                tracing::info!("Client initialized");
            }
            "notifications/cancelled" => {
                tracing::info!("Operation cancelled");
            }
            _ => {
                tracing::warn!("Unknown notification method: {}", notification.method);
            }
        }
        Ok(())
    }

    /// Handle initialize request with enhanced session tracking
    async fn handle_initialize(&self, request: McpRequest) -> McpResponse {
        match self.handlers.handle_initialize(request.params.clone()).await {
            Ok(result) => {
                // Store client info in session state
                if let Some(params) = request.params {
                    if let Ok(init_params) = serde_json::from_value::<InitializeParams>(params) {
                        let mut state = self.session_state.write().await;
                        state.client_info = Some(init_params.client_info.clone());
                        info!("Client connected: {} v{}", 
                            init_params.client_info.name, 
                            init_params.client_info.version
                        );
                    }
                }
                
                McpResponse::success(request.id, serde_json::to_value(result).unwrap())
            }
            Err(e) => McpResponse::error(request.id, McpError::internal_error(&e.to_string())),
        }
    }

    /// Handle tools/list request
    async fn handle_tools_list(&self, request: McpRequest) -> McpResponse {
        match self.handlers.handle_tools_list().await {
            Ok(tools) => {
                let result = serde_json::json!({
                    "tools": tools
                });
                McpResponse::success(request.id, result)
            }
            Err(e) => McpResponse::error(request.id, McpError::internal_error(&e.to_string())),
        }
    }

    /// Handle tools/call request with enhanced caching and progress reporting
    async fn handle_tools_call(&self, request: McpRequest) -> McpResponse {
        let params = match request.params {
            Some(params) => params,
            None => {
                return McpResponse::error(
                    request.id,
                    McpError::invalid_params("Missing tool call parameters"),
                );
            }
        };

        let call_params: CallToolParams = match serde_json::from_value(params) {
            Ok(params) => params,
            Err(e) => {
                return McpResponse::error(
                    request.id,
                    McpError::invalid_params(&format!("Invalid tool call parameters: {}", e)),
                );
            }
        };

        // Check cache for repeated calls
        let cache_key = format!("{}:{}", call_params.name, 
            serde_json::to_string(&call_params.arguments).unwrap_or_default());
        
        {
            let state = self.session_state.read().await;
            if let Some(cached_result) = state.generation_cache.get(&cache_key) {
                debug!("Returning cached result for tool call: {}", call_params.name);
                return McpResponse::success(request.id, cached_result.clone());
            }
        }

        // Send progress update if available
        if let Some(ref sender) = self.progress_sender {
            let _ = sender.send(ProgressUpdate {
                operation_id: request.id.to_string(),
                stage: "starting".to_string(),
                progress: 0.0,
                message: format!("Starting {}", call_params.name),
                details: None,
            });
        }

        let start_time = std::time::Instant::now();
        
        match self.handlers.handle_tool_call(&self.generator, call_params, self.progress_sender.clone()).await {
            Ok(result) => {
                let result_value = serde_json::to_value(&result).unwrap();
                
                // Cache successful results
                {
                    let mut state = self.session_state.write().await;
                    state.generation_cache.insert(cache_key, result_value.clone());
                    state.last_generation_time = Some(start_time);
                }
                
                // Send completion progress
                if let Some(ref sender) = self.progress_sender {
                    let _ = sender.send(ProgressUpdate {
                        operation_id: request.id.to_string(),
                        stage: "completed".to_string(),
                        progress: 100.0,
                        message: "Operation completed successfully".to_string(),
                        details: Some(serde_json::json!({
                            "duration_ms": start_time.elapsed().as_millis()
                        })),
                    });
                }
                
                McpResponse::success(request.id, result_value)
            }
            Err(e) => {
                error!("Tool call failed: {}", e);
                
                // Send error progress
                if let Some(ref sender) = self.progress_sender {
                    let _ = sender.send(ProgressUpdate {
                        operation_id: request.id.to_string(),
                        stage: "failed".to_string(),
                        progress: -1.0,
                        message: format!("Operation failed: {}", e),
                        details: None,
                    });
                }
                
                let error_result = CallToolResult {
                    content: vec![ToolContent::text(format!("Error: {}", e))],
                    is_error: Some(true),
                };
                McpResponse::success(request.id, serde_json::to_value(error_result).unwrap())
            }
        }
    }

    /// Call a tool directly (for testing)
    pub async fn call_tool(&self, tool_name: &str, arguments: Value) -> Result<Value> {
        let params = CallToolParams {
            name: tool_name.to_string(),
            arguments: Some(serde_json::from_value(arguments)?),
        };

        let result = self.handlers.handle_tool_call(&self.generator, params, None).await?;
        Ok(serde_json::to_value(result)?)
    }
    
    /// Get session statistics
    pub async fn get_session_stats(&self) -> Value {
        let state = self.session_state.read().await;
        serde_json::json!({
            "client_info": state.client_info,
            "cache_entries": state.generation_cache.len(),
            "last_generation": state.last_generation_time.map(|t| t.elapsed().as_secs()),
            "server_version": env!("CARGO_PKG_VERSION")
        })
    }
}

// Make server cloneable for async processing
impl Clone for AxiomMcpServer {
    fn clone(&self) -> Self {
        Self {
            generator: self.generator.clone(),
            handlers: self.handlers.clone(),
            session_state: self.session_state.clone(),
            progress_sender: self.progress_sender.clone(),
        }
    }
}