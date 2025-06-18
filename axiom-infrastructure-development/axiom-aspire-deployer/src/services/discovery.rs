use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::Duration;
use tracing::{debug, warn};

use crate::mcp::protocol::{ServiceStatus, ServiceUrls};

#[derive(Debug, Serialize, Deserialize)]
pub struct ResourceInfo {
    pub name: String,
    #[serde(rename = "resourceType")]
    pub resource_type: String,
    pub displayName: String,
    pub uid: Option<String>,
    pub state: Option<String>,
    pub stateDetail: Option<String>,
    pub createdAt: Option<String>,
    pub properties: Option<HashMap<String, serde_json::Value>>,
    pub environment: Option<HashMap<String, String>>,
    pub urls: Option<Vec<UrlInfo>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UrlInfo {
    pub name: String,
    pub url: String,
    pub isInternal: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AspireResourcesResponse {
    pub resources: Vec<ResourceInfo>,
}

pub struct AspireServiceDiscovery {
    client: Client,
    dashboard_url: String,
}

impl AspireServiceDiscovery {
    pub fn new(dashboard_url: &str) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .danger_accept_invalid_certs(true) // For local development
            .build()
            .expect("Failed to create HTTP client");
        
        Self {
            client,
            dashboard_url: dashboard_url.to_string(),
        }
    }
    
    pub async fn discover_services(&self) -> Result<Vec<ServiceStatus>> {
        debug!("Discovering services from Aspire dashboard");
        
        let resources_url = format!("{}/api/v1/resources", self.dashboard_url);
        
        match self.client.get(&resources_url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let resources: Vec<ResourceInfo> = response.json().await?;
                    let services = self.convert_resources_to_services(resources);
                    debug!("Discovered {} services", services.len());
                    Ok(services)
                } else {
                    warn!("Dashboard returned status: {}", response.status());
                    Ok(Vec::new())
                }
            }
            Err(e) => {
                warn!("Failed to connect to Aspire dashboard: {}", e);
                Ok(Vec::new())
            }
        }
    }
    
    pub async fn get_service_urls(&self) -> Result<ServiceUrls> {
        debug!("Getting service URLs from Aspire dashboard");
        
        let services = self.discover_services().await?;
        let mut urls = ServiceUrls {
            api: None,
            notifications: None,
            redis: None,
            dashboard: Some(self.dashboard_url.clone()),
        };
        
        for service in services {
            match service.name.as_str() {
                "api" | "axiom-api" => urls.api = service.url,
                "notifications" | "axiom-notifications" => urls.notifications = service.url,
                "redis" | "axiom-redis" => urls.redis = service.url,
                _ => {}
            }
        }
        
        Ok(urls)
    }
    
    pub async fn check_dashboard_health(&self) -> Result<bool> {
        debug!("Checking Aspire dashboard health");
        
        let health_url = format!("{}/health", self.dashboard_url);
        
        match self.client.get(&health_url).send().await {
            Ok(response) => Ok(response.status().is_success()),
            Err(_) => {
                // Try the resources endpoint as fallback
                let resources_url = format!("{}/api/v1/resources", self.dashboard_url);
                match self.client.get(&resources_url).send().await {
                    Ok(response) => Ok(response.status().is_success()),
                    Err(_) => Ok(false),
                }
            }
        }
    }
    
    fn convert_resources_to_services(&self, resources: Vec<ResourceInfo>) -> Vec<ServiceStatus> {
        resources
            .into_iter()
            .map(|resource| {
                let url = resource.urls
                    .as_ref()
                    .and_then(|urls| urls.first())
                    .map(|url_info| url_info.url.clone());
                
                let health = match resource.state.as_deref() {
                    Some("Running") => "healthy",
                    Some("Starting") => "starting",
                    Some("Stopped") => "stopped",
                    Some("Failed") => "unhealthy",
                    _ => "unknown",
                };
                
                let status = resource.state.unwrap_or_else(|| "unknown".to_string());
                
                ServiceStatus {
                    name: resource.name,
                    status,
                    url,
                    health: health.to_string(),
                    uptime: None, // TODO: Calculate from createdAt
                    last_check: chrono::Utc::now(),
                }
            })
            .collect()
    }
    
    pub async fn get_resource_details(&self, resource_name: &str) -> Result<Option<ResourceInfo>> {
        debug!("Getting details for resource: {}", resource_name);
        
        let resources_url = format!("{}/api/v1/resources", self.dashboard_url);
        
        match self.client.get(&resources_url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let resources: Vec<ResourceInfo> = response.json().await?;
                    Ok(resources.into_iter().find(|r| r.name == resource_name))
                } else {
                    Ok(None)
                }
            }
            Err(e) => {
                warn!("Failed to get resource details: {}", e);
                Err(e.into())
            }
        }
    }
    
    pub async fn get_service_logs(&self, service_name: &str, tail: Option<usize>) -> Result<Vec<String>> {
        debug!("Getting logs for service: {}", service_name);
        
        // This would need to be implemented based on Aspire's logging API
        // For now, return empty logs
        warn!("Service logs not yet implemented for Aspire dashboard");
        Ok(Vec::new())
    }
}