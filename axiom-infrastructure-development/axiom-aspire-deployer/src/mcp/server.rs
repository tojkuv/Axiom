use anyhow::Result;
use dashmap::DashMap;
use serde_json::{json, Value};
use std::sync::Arc;
use tokio::net::{TcpListener, TcpStream};
use tracing::{debug, error, info, warn};

use crate::config::Settings;
use crate::mcp::protocol::{McpRequest, McpResponse, ServiceStatus};
use crate::mcp::handlers::RequestHandler;
use crate::services::{AspireServiceDiscovery, AspireOrchestrator, HealthMonitor, NetworkManager};

#[derive(Clone)]
pub struct AxiomAspireMcpServer {
    settings: Settings,
    service_discovery: Arc<AspireServiceDiscovery>,
    orchestrator: Arc<AspireOrchestrator>,
    network_manager: Arc<NetworkManager>,
    health_monitor: Arc<HealthMonitor>,
    service_state: Arc<DashMap<String, ServiceStatus>>,
    handler: Arc<RequestHandler>,
}

impl AxiomAspireMcpServer {
    pub async fn new(settings: Settings) -> Result<Self> {
        info!("Initializing Axiom Aspire MCP Server");
        
        // Create service components
        let service_discovery = Arc::new(
            AspireServiceDiscovery::new(&settings.aspire.dashboard_url)
        );
        
        let orchestrator = Arc::new(
            AspireOrchestrator::new(&settings.aspire.dashboard_url).await?
        );
        
        let network_manager = Arc::new(
            NetworkManager::new(&settings.network)
        );
        
        let health_monitor = Arc::new(
            HealthMonitor::new(settings.monitoring.health_check_interval_ms)
        );
        
        let service_state = Arc::new(DashMap::new());
        
        let handler = Arc::new(RequestHandler::new(
            service_discovery.clone(),
            orchestrator.clone(),
            network_manager.clone(),
            health_monitor.clone(),
            service_state.clone(),
        ));
        
        Ok(Self {
            settings,
            service_discovery,
            orchestrator,
            network_manager,
            health_monitor,
            service_state,
            handler,
        })
    }
    
    pub async fn run(&self, port: u16) -> Result<()> {
        let addr = format!("{}:{}", self.settings.server.host, port);
        let listener = TcpListener::bind(&addr).await?;
        
        info!("MCP Server listening on {}", addr);
        
        // Start background tasks
        self.start_background_tasks().await?;
        
        loop {
            match listener.accept().await {
                Ok((stream, addr)) => {
                    debug!("New connection from {}", addr);
                    let server = self.clone();
                    
                    tokio::spawn(async move {
                        if let Err(e) = server.handle_connection(stream).await {
                            error!("Connection error: {}", e);
                        }
                    });
                }
                Err(e) => {
                    error!("Failed to accept connection: {}", e);
                }
            }
        }
    }
    
    async fn start_background_tasks(&self) -> Result<()> {
        info!("Starting background monitoring tasks");
        
        // Start service discovery polling
        if self.settings.aspire.auto_discovery {
            let discovery = self.service_discovery.clone();
            let state = self.service_state.clone();
            let interval = self.settings.aspire.polling_interval_ms;
            
            tokio::spawn(async move {
                Self::service_discovery_task(discovery, state, interval).await;
            });
        }
        
        // Start health monitoring
        let health_monitor = self.health_monitor.clone();
        let state = self.service_state.clone();
        
        tokio::spawn(async move {
            health_monitor.start_monitoring(state).await;
        });
        
        Ok(())
    }
    
    async fn service_discovery_task(
        discovery: Arc<AspireServiceDiscovery>,
        state: Arc<DashMap<String, ServiceStatus>>,
        interval_ms: u64,
    ) {
        let mut interval = tokio::time::interval(
            std::time::Duration::from_millis(interval_ms)
        );
        
        loop {
            interval.tick().await;
            
            match discovery.discover_services().await {
                Ok(services) => {
                    for service in services {
                        state.insert(service.name.clone(), service);
                    }
                }
                Err(e) => {
                    warn!("Service discovery failed: {}", e);
                }
            }
        }
    }
    
    async fn handle_connection(&self, mut stream: TcpStream) -> Result<()> {
        use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
        
        let (reader, mut writer) = stream.split();
        let mut reader = BufReader::new(reader);
        let mut line = String::new();
        
        loop {
            line.clear();
            match reader.read_line(&mut line).await {
                Ok(0) => break, // Connection closed
                Ok(_) => {
                    if line.trim().is_empty() {
                        continue;
                    }
                    
                    match self.process_request(&line).await {
                        Ok(response) => {
                            let response_json = serde_json::to_string(&response)?;
                            writer.write_all(response_json.as_bytes()).await?;
                            writer.write_all(b"\n").await?;
                            writer.flush().await?;
                        }
                        Err(e) => {
                            error!("Request processing error: {}", e);
                            let error_response = McpResponse::internal_error(
                                json!(null),
                                e.to_string(),
                            );
                            let response_json = serde_json::to_string(&error_response)?;
                            writer.write_all(response_json.as_bytes()).await?;
                            writer.write_all(b"\n").await?;
                            writer.flush().await?;
                        }
                    }
                }
                Err(e) => {
                    error!("Connection read error: {}", e);
                    break;
                }
            }
        }
        
        Ok(())
    }
    
    async fn process_request(&self, request_line: &str) -> Result<McpResponse> {
        debug!("Processing request: {}", request_line);
        
        let request: McpRequest = serde_json::from_str(request_line.trim())?;
        
        // Handle special MCP protocol methods
        match request.method.as_str() {
            "initialize" => self.handle_initialize(request).await,
            "tools/list" => self.handle_tools_list(request).await,
            "tools/call" => self.handle_tools_call(request).await,
            _ => {
                // Delegate to request handler
                self.handler.handle_request(request).await
            }
        }
    }
    
    async fn handle_initialize(&self, request: McpRequest) -> Result<McpResponse> {
        let result = json!({
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {
                    "listChanged": true
                },
                "logging": {},
                "prompts": {}
            },
            "serverInfo": {
                "name": self.settings.server.name,
                "version": self.settings.server.version
            }
        });
        
        Ok(McpResponse::success(request.id, result))
    }
    
    async fn handle_tools_list(&self, request: McpRequest) -> Result<McpResponse> {
        let tools = self.get_available_tools();
        let result = json!({
            "tools": tools
        });
        
        Ok(McpResponse::success(request.id, result))
    }
    
    async fn handle_tools_call(&self, request: McpRequest) -> Result<McpResponse> {
        if let Some(params) = request.params {
            if let Some(name) = params.get("name").and_then(|v| v.as_str()) {
                let arguments = params.get("arguments").cloned().unwrap_or(json!({}));
                
                // Create internal request for tool execution
                let tool_request = McpRequest {
                    jsonrpc: request.jsonrpc.clone(),
                    id: request.id.clone(),
                    method: name.to_string(),
                    params: Some(arguments),
                };
                
                return self.handler.handle_request(tool_request).await;
            }
        }
        
        Ok(McpResponse::invalid_params(
            request.id,
            "Missing tool name or arguments".to_string(),
        ))
    }
    
    fn get_available_tools(&self) -> Vec<Value> {
        vec![
            json!({
                "name": "axiom_aspire_start",
                "description": "Start Axiom Aspire AppHost with specified profile",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "profile": {
                            "type": "string",
                            "enum": ["Development", "Staging", "Testing"],
                            "default": "Development"
                        },
                        "watch": {
                            "type": "boolean",
                            "default": false
                        }
                    }
                }
            }),
            json!({
                "name": "axiom_aspire_stop",
                "description": "Stop Axiom Aspire AppHost and all services",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            }),
            json!({
                "name": "axiom_aspire_restart",
                "description": "Restart specific service or entire stack",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "service": {
                            "type": "string",
                            "enum": ["api", "notifications", "redis", "all"],
                            "default": "all"
                        }
                    }
                }
            }),
            json!({
                "name": "axiom_aspire_status",
                "description": "Get comprehensive status of all Axiom services",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            }),
            json!({
                "name": "axiom_aspire_health",
                "description": "Detailed health check of all services",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "deep_check": {
                            "type": "boolean",
                            "default": false
                        }
                    }
                }
            }),
            json!({
                "name": "axiom_get_service_urls",
                "description": "Get current service URLs from Aspire dashboard",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            }),
            json!({
                "name": "axiom_call_endpoint",
                "description": "Call Axiom API endpoint for testing",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "service": {
                            "type": "string",
                            "enum": ["api", "notifications"]
                        },
                        "endpoint": {
                            "type": "string"
                        },
                        "method": {
                            "type": "string",
                            "enum": ["GET", "POST", "PUT", "DELETE", "PATCH"],
                            "default": "GET"
                        },
                        "headers": {
                            "type": "object"
                        },
                        "body": {
                            "type": "object"
                        },
                        "timeout": {
                            "type": "number",
                            "default": 30
                        }
                    },
                    "required": ["service", "endpoint"]
                }
            }),
            json!({
                "name": "axiom_configure_local_network",
                "description": "Configure services for local network access",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "network_interface": {
                            "type": "string",
                            "default": "auto"
                        },
                        "expose_services": {
                            "type": "array",
                            "items": {
                                "type": "string",
                                "enum": ["api", "notifications", "redis"]
                            }
                        },
                        "bind_mode": {
                            "type": "string",
                            "enum": ["localhost", "local_network", "all_interfaces"],
                            "default": "localhost"
                        }
                    }
                }
            }),
            json!({
                "name": "axiom_get_network_urls",
                "description": "Get network-accessible URLs for testing from other devices",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            }),
        ]
    }
}