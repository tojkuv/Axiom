use anyhow::Result;
use dashmap::DashMap;
use serde_json::{json, Value};
use std::sync::Arc;
use tracing::{debug, info, warn};

use crate::mcp::protocol::{McpRequest, McpResponse, ServiceStatus, EndpointCallRequest, EndpointCallResponse};
use crate::services::{AspireServiceDiscovery, AspireOrchestrator, HealthMonitor, NetworkManager};

pub struct RequestHandler {
    service_discovery: Arc<AspireServiceDiscovery>,
    orchestrator: Arc<AspireOrchestrator>,
    network_manager: Arc<NetworkManager>,
    health_monitor: Arc<HealthMonitor>,
    service_state: Arc<DashMap<String, ServiceStatus>>,
}

impl RequestHandler {
    pub fn new(
        service_discovery: Arc<AspireServiceDiscovery>,
        orchestrator: Arc<AspireOrchestrator>,
        network_manager: Arc<NetworkManager>,
        health_monitor: Arc<HealthMonitor>,
        service_state: Arc<DashMap<String, ServiceStatus>>,
    ) -> Self {
        Self {
            service_discovery,
            orchestrator,
            network_manager,
            health_monitor,
            service_state,
        }
    }
    
    pub async fn handle_request(&self, request: McpRequest) -> Result<McpResponse> {
        debug!("Handling request: {}", request.method);
        
        match request.method.as_str() {
            "axiom_aspire_start" => self.handle_aspire_start(request).await,
            "axiom_aspire_stop" => self.handle_aspire_stop(request).await,
            "axiom_aspire_restart" => self.handle_aspire_restart(request).await,
            "axiom_aspire_status" => self.handle_aspire_status(request).await,
            "axiom_aspire_health" => self.handle_aspire_health(request).await,
            "axiom_get_service_urls" => self.handle_get_service_urls(request).await,
            "axiom_call_endpoint" => self.handle_call_endpoint(request).await,
            "axiom_configure_local_network" => self.handle_configure_local_network(request).await,
            "axiom_get_network_urls" => self.handle_get_network_urls(request).await,
            _ => Ok(McpResponse::method_not_found(request.id)),
        }
    }
    
    async fn handle_aspire_start(&self, request: McpRequest) -> Result<McpResponse> {
        let params = request.params.unwrap_or(json!({}));
        let profile = params.get("profile")
            .and_then(|v| v.as_str())
            .unwrap_or("Development");
        let watch = params.get("watch")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        
        info!("Starting Aspire with profile: {}, watch: {}", profile, watch);
        
        match self.orchestrator.start_aspire(profile, watch).await {
            Ok(_) => {
                let result = json!({
                    "status": "started",
                    "profile": profile,
                    "watch": watch,
                    "message": "Aspire AppHost start requested successfully"
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Failed to start Aspire: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_aspire_stop(&self, request: McpRequest) -> Result<McpResponse> {
        info!("Stopping Aspire AppHost");
        
        match self.orchestrator.stop_aspire().await {
            Ok(_) => {
                let result = json!({
                    "status": "stopped",
                    "message": "Aspire AppHost stopped successfully"
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Failed to stop Aspire: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_aspire_restart(&self, request: McpRequest) -> Result<McpResponse> {
        let params = request.params.unwrap_or(json!({}));
        let service = params.get("service")
            .and_then(|v| v.as_str())
            .unwrap_or("all");
        
        info!("Restarting service: {}", service);
        
        match self.orchestrator.restart_service(service).await {
            Ok(_) => {
                let result = json!({
                    "status": "restarted",
                    "service": service,
                    "message": format!("Service '{}' restart requested successfully", service)
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Failed to restart service {}: {}", service, e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_aspire_status(&self, request: McpRequest) -> Result<McpResponse> {
        debug!("Getting Aspire status");
        
        let services: Vec<Value> = self.service_state
            .iter()
            .map(|entry| {
                let service = entry.value();
                json!({
                    "name": service.name,
                    "status": service.status,
                    "url": service.url,
                    "health": service.health,
                    "uptime": service.uptime,
                    "last_check": service.last_check.to_rfc3339()
                })
            })
            .collect();
        
        let aspire_status = self.orchestrator.get_aspire_status().await
            .unwrap_or_else(|_| json!({
                "is_running": false,
                "dashboard_accessible": false
            }));
        
        let result = json!({
            "services": services,
            "aspire_status": aspire_status,
            "total_services": services.len()
        });
        
        Ok(McpResponse::success(request.id, result))
    }
    
    async fn handle_aspire_health(&self, request: McpRequest) -> Result<McpResponse> {
        let params = request.params.unwrap_or(json!({}));
        let deep_check = params.get("deep_check")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        
        debug!("Performing health check (deep: {})", deep_check);
        
        match self.health_monitor.perform_health_check(deep_check).await {
            Ok(health_results) => {
                let result = json!({
                    "health_results": health_results,
                    "deep_check": deep_check,
                    "timestamp": chrono::Utc::now().to_rfc3339()
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Health check failed: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_get_service_urls(&self, request: McpRequest) -> Result<McpResponse> {
        debug!("Getting service URLs");
        
        match self.service_discovery.get_service_urls().await {
            Ok(urls) => {
                let result = json!({
                    "api": urls.api,
                    "notifications": urls.notifications,
                    "redis": urls.redis,
                    "dashboard": urls.dashboard
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Failed to get service URLs: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_call_endpoint(&self, request: McpRequest) -> Result<McpResponse> {
        let params = request.params.ok_or_else(|| {
            anyhow::anyhow!("Missing parameters for endpoint call")
        })?;
        
        let call_request: EndpointCallRequest = serde_json::from_value(params)?;
        
        info!("Calling endpoint: {} {}/{}", 
            call_request.method, call_request.service, call_request.endpoint);
        
        match self.orchestrator.call_service_endpoint(call_request).await {
            Ok(response) => {
                let result = json!({
                    "status": response.status,
                    "headers": response.headers,
                    "body": response.body,
                    "duration": response.duration
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Endpoint call failed: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_configure_local_network(&self, request: McpRequest) -> Result<McpResponse> {
        let params = request.params.unwrap_or(json!({}));
        let network_interface = params.get("network_interface")
            .and_then(|v| v.as_str())
            .unwrap_or("auto");
        let expose_services: Vec<String> = params.get("expose_services")
            .and_then(|v| v.as_array())
            .map(|arr| arr.iter()
                .filter_map(|v| v.as_str())
                .map(|s| s.to_string())
                .collect())
            .unwrap_or_else(|| vec!["api".to_string(), "notifications".to_string()]);
        let bind_mode = params.get("bind_mode")
            .and_then(|v| v.as_str())
            .unwrap_or("localhost");
        
        info!("Configuring local network: interface={}, services={:?}, mode={}", 
            network_interface, expose_services, bind_mode);
        
        match self.network_manager.configure_local_network(&expose_services, bind_mode).await {
            Ok(config_result) => {
                let result = json!({
                    "status": "configured",
                    "network_interface": network_interface,
                    "exposed_services": expose_services,
                    "bind_mode": bind_mode,
                    "configuration": config_result
                });
                Ok(McpResponse::success(request.id, result))
            }
            Err(e) => {
                warn!("Network configuration failed: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
    
    async fn handle_get_network_urls(&self, request: McpRequest) -> Result<McpResponse> {
        debug!("Getting network URLs");
        
        match self.network_manager.get_network_urls().await {
            Ok(urls) => {
                Ok(McpResponse::success(request.id, json!(urls)))
            }
            Err(e) => {
                warn!("Failed to get network URLs: {}", e);
                Ok(McpResponse::internal_error(request.id, e.to_string()))
            }
        }
    }
}