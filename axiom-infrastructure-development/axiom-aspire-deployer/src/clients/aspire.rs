use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::time::Duration;
use tracing::{debug, warn, info};

#[derive(Debug, Serialize, Deserialize)]
pub struct AspireResource {
    pub name: String,
    #[serde(rename = "resourceType")]
    pub resource_type: String,
    #[serde(rename = "displayName")]
    pub display_name: String,
    pub uid: Option<String>,
    pub state: Option<String>,
    #[serde(rename = "stateDetail")]  
    pub state_detail: Option<String>,
    #[serde(rename = "createdAt")]
    pub created_at: Option<String>,
    pub properties: Option<HashMap<String, Value>>,
    pub environment: Option<HashMap<String, String>>,
    pub urls: Option<Vec<AspireUrl>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AspireUrl {
    pub name: String,
    pub url: String,
    #[serde(rename = "isInternal")]
    pub is_internal: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AspireLogEntry {
    pub timestamp: String,
    pub level: String,
    pub message: String,
    pub source: Option<String>,
    pub properties: Option<HashMap<String, Value>>,
}

pub struct AspireDashboardClient {
    client: Client,
    base_url: String,
}

impl AspireDashboardClient {
    pub fn new(dashboard_url: &str) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .danger_accept_invalid_certs(true) // For local development
            .build()
            .expect("Failed to create Aspire dashboard client");
        
        Self {
            client,
            base_url: dashboard_url.to_string(),
        }
    }
    
    pub async fn get_resources(&self) -> Result<Vec<AspireResource>> {
        debug!("Getting resources from Aspire dashboard");
        
        let url = format!("{}/api/v1/resources", self.base_url);
        
        match self.client.get(&url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let resources: Vec<AspireResource> = response.json().await?;
                    debug!("Retrieved {} resources", resources.len());
                    Ok(resources)
                } else {
                    warn!("Dashboard returned status: {}", response.status());
                    Ok(Vec::new())
                }
            }
            Err(e) => {
                warn!("Failed to get resources: {}", e);
                Err(e.into())
            }
        }
    }
    
    pub async fn get_resource(&self, resource_name: &str) -> Result<Option<AspireResource>> {
        debug!("Getting resource: {}", resource_name);
        
        let resources = self.get_resources().await?;
        Ok(resources.into_iter().find(|r| r.name == resource_name))
    }
    
    pub async fn restart_resource(&self, resource_name: &str) -> Result<()> {
        info!("Restarting resource: {}", resource_name);
        
        let url = format!("{}/api/v1/resources/{}/restart", self.base_url, resource_name);
        
        match self.client.post(&url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    debug!("Successfully restarted resource: {}", resource_name);
                    Ok(())
                } else {
                    let error_msg = format!("Failed to restart resource, status: {}", response.status());
                    warn!("{}", error_msg);
                    Err(anyhow::anyhow!(error_msg))
                }
            }
            Err(e) => {
                warn!("Failed to send restart request: {}", e);
                Err(e.into())
            }
        }
    }
    
    pub async fn get_resource_logs(&self, resource_name: &str, tail: Option<usize>) -> Result<Vec<AspireLogEntry>> {
        debug!("Getting logs for resource: {}", resource_name);
        
        let mut url = format!("{}/api/v1/resources/{}/logs", self.base_url, resource_name);
        
        if let Some(tail_count) = tail {
            url.push_str(&format!("?tail={}", tail_count));
        }
        
        match self.client.get(&url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    // The actual log format may vary, this is a simplified implementation
                    let logs: Vec<AspireLogEntry> = response.json().await.unwrap_or_else(|_| Vec::new());
                    debug!("Retrieved {} log entries", logs.len());
                    Ok(logs)
                } else {
                    warn!("Failed to get logs, status: {}", response.status());
                    Ok(Vec::new())
                }
            }
            Err(e) => {
                warn!("Failed to get logs: {}", e);
                Ok(Vec::new()) // Return empty logs instead of error
            }
        }
    }
    
    pub async fn stream_logs(&self, resource_name: &str) -> Result<tokio::sync::mpsc::Receiver<AspireLogEntry>> {
        debug!("Starting log stream for resource: {}", resource_name);
        
        let (tx, rx) = tokio::sync::mpsc::channel(100);
        let url = format!("{}/api/v1/resources/{}/logs/stream", self.base_url, resource_name);
        let client = self.client.clone();
        
        tokio::spawn(async move {
            // This would implement SSE (Server-Sent Events) or WebSocket streaming
            // For now, we'll simulate with periodic polling
            let mut interval = tokio::time::interval(Duration::from_secs(1));
            
            loop {
                interval.tick().await;
                
                // In a real implementation, this would be a persistent connection
                match client.get(&url).send().await {
                    Ok(response) => {
                        if response.status().is_success() {
                            if let Ok(logs) = response.json::<Vec<AspireLogEntry>>().await {
                                for log in logs {
                                    if tx.send(log).await.is_err() {
                                        debug!("Log stream receiver closed");
                                        return;
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => {
                        warn!("Log streaming error: {}", e);
                        tokio::time::sleep(Duration::from_secs(5)).await;
                    }
                }
            }
        });
        
        Ok(rx)
    }
    
    pub async fn get_dashboard_info(&self) -> Result<Value> {
        debug!("Getting dashboard info");
        
        let url = format!("{}/api/v1/info", self.base_url);
        
        match self.client.get(&url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let info: Value = response.json().await?;
                    Ok(info)
                } else {
                    Ok(serde_json::json!({
                        "status": "unavailable",
                        "error": format!("HTTP {}", response.status())
                    }))
                }
            }
            Err(e) => {
                Ok(serde_json::json!({
                    "status": "unavailable",
                    "error": e.to_string()
                }))
            }
        }
    }
    
    pub async fn check_health(&self) -> Result<bool> {
        debug!("Checking dashboard health");
        
        // Try the resources endpoint as health check
        let url = format!("{}/api/v1/resources", self.base_url);
        
        match self.client.head(&url).send().await {
            Ok(response) => Ok(response.status().is_success()),
            Err(_) => Ok(false),
        }
    }
    
    pub async fn get_metrics(&self) -> Result<Value> {
        debug!("Getting dashboard metrics");
        
        let url = format!("{}/api/v1/metrics", self.base_url);
        
        match self.client.get(&url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let metrics: Value = response.json().await?;
                    Ok(metrics)
                } else {
                    Ok(serde_json::json!({
                        "status": "unavailable",
                        "message": "Metrics endpoint not available"
                    }))
                }
            }
            Err(e) => {
                Ok(serde_json::json!({
                    "status": "error",
                    "message": e.to_string()
                }))
            }
        }
    }
    
    pub async fn execute_command(&self, resource_name: &str, command: &str) -> Result<Value> {
        debug!("Executing command '{}' on resource: {}", command, resource_name);
        
        let url = format!("{}/api/v1/resources/{}/execute", self.base_url, resource_name);
        let payload = serde_json::json!({
            "command": command
        });
        
        match self.client.post(&url).json(&payload).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let result: Value = response.json().await?;
                    Ok(result)
                } else {
                    Err(anyhow::anyhow!("Command execution failed: {}", response.status()))
                }
            }
            Err(e) => {
                Err(anyhow::anyhow!("Failed to execute command: {}", e))
            }
        }
    }
}