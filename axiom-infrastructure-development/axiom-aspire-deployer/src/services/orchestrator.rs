use anyhow::Result;
use reqwest::Client;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::time::{Duration, Instant};
use sysinfo::{System, Pid};
use tracing::{debug, info, warn, error};

use crate::mcp::protocol::{EndpointCallRequest, EndpointCallResponse};

#[derive(Debug)]
pub struct AspireProcess {
    pub pid: u32,
    pub name: String,
    pub cmd: String,
    pub start_time: u64,
}

#[derive(Debug)]
pub struct AspireStatus {
    pub is_running: bool,
    pub dashboard_accessible: bool,
    pub processes: Vec<AspireProcess>,
}

pub struct AspireOrchestrator {
    client: Client,
    dashboard_url: String,
    system: System,
}

impl AspireOrchestrator {
    pub async fn new(dashboard_url: &str) -> Result<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .danger_accept_invalid_certs(true)
            .build()?;
        
        let system = System::new_all();
        
        Ok(Self {
            client,
            dashboard_url: dashboard_url.to_string(),
            system,
        })
    }
    
    pub async fn start_aspire(&self, profile: &str, watch: bool) -> Result<()> {
        info!("Starting Aspire with profile: {}, watch: {}", profile, watch);
        
        // Check if Aspire is already running
        if self.is_aspire_running().await? {
            warn!("Aspire appears to be already running");
            return Ok(());
        }
        
        // Since we're a standalone MCP server, we don't actually start the process
        // Instead, we inform the user about the command they need to run
        let watch_flag = if watch { " --watch" } else { "" };
        let command = format!("dotnet run --project <path-to-apphost> --environment {}{}", profile, watch_flag);
        
        info!("To start Aspire, run the following command:");
        info!("  {}", command);
        
        // Wait a moment and check if it's running
        tokio::time::sleep(Duration::from_secs(2)).await;
        
        if !self.is_aspire_running().await? {
            warn!("Aspire is not running. Please start it manually with:");
            warn!("  {}", command);
        }
        
        Ok(())
    }
    
    pub async fn stop_aspire(&self) -> Result<()> {
        info!("Stopping Aspire AppHost");
        
        // Try to stop via dashboard API first
        if let Ok(true) = self.is_dashboard_accessible().await {
            if let Err(e) = self.stop_via_dashboard().await {
                warn!("Failed to stop via dashboard: {}", e);
            }
        }
        
        // Kill processes as backup
        self.kill_aspire_processes().await?;
        
        Ok(())
    }
    
    pub async fn restart_service(&self, service: &str) -> Result<()> {
        info!("Restarting service: {}", service);
        
        if service == "all" {
            return self.restart_all_services().await;
        }
        
        // Try to restart via dashboard API
        let restart_url = format!("{}/api/v1/resources/{}/restart", self.dashboard_url, service);
        
        match self.client.post(&restart_url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    info!("Successfully requested restart for service: {}", service);
                    Ok(())
                } else {
                    warn!("Dashboard returned status {} for restart request", response.status());
                    Err(anyhow::anyhow!("Failed to restart service via dashboard API"))
                }
            }
            Err(e) => {
                warn!("Failed to send restart request: {}", e);
                Err(e.into())
            }
        }
    }
    
    pub async fn get_aspire_status(&self) -> Result<Value> {
        debug!("Getting Aspire status");
        
        let is_running = self.is_aspire_running().await?;
        let dashboard_accessible = self.is_dashboard_accessible().await?;
        let processes = self.detect_aspire_processes().await?;
        
        Ok(json!({
            "is_running": is_running,
            "dashboard_accessible": dashboard_accessible,
            "process_count": processes.len(),
            "processes": processes.iter().map(|p| json!({
                "pid": p.pid,
                "name": p.name,
                "start_time": p.start_time
            })).collect::<Vec<_>>()
        }))
    }
    
    pub async fn call_service_endpoint(&self, request: EndpointCallRequest) -> Result<EndpointCallResponse> {
        debug!("Calling endpoint: {} {}/{}", request.method, request.service, request.endpoint);
        
        // Get service URL
        let service_url = self.get_service_url(&request.service).await?;
        let full_url = format!("{}{}", service_url, request.endpoint);
        
        let start_time = Instant::now();
        
        // Build request
        let mut req_builder = match request.method.as_str() {
            "GET" => self.client.get(&full_url),
            "POST" => self.client.post(&full_url),
            "PUT" => self.client.put(&full_url),
            "DELETE" => self.client.delete(&full_url),
            "PATCH" => self.client.patch(&full_url),
            _ => return Err(anyhow::anyhow!("Unsupported HTTP method: {}", request.method)),
        };
        
        // Add headers
        if let Some(headers) = &request.headers {
            for (key, value) in headers {
                req_builder = req_builder.header(key, value);
            }
        }
        
        // Add body
        if let Some(body) = &request.body {
            req_builder = req_builder.json(body);
        }
        
        // Set timeout
        if let Some(timeout) = request.timeout {
            req_builder = req_builder.timeout(Duration::from_secs(timeout));
        }
        
        // Send request
        match req_builder.send().await {
            Ok(response) => {
                let duration = start_time.elapsed().as_millis() as u64;
                let status = response.status().as_u16();
                
                let headers: HashMap<String, String> = response
                    .headers()
                    .iter()
                    .map(|(k, v)| (k.to_string(), v.to_str().unwrap_or("").to_string()))
                    .collect();
                
                let body = response.json::<Value>().await.unwrap_or(json!({}));
                
                Ok(EndpointCallResponse {
                    status,
                    headers,
                    body,
                    duration,
                })
            }
            Err(e) => {
                error!("Endpoint call failed: {}", e);
                Err(e.into())
            }
        }
    }
    
    async fn is_aspire_running(&self) -> Result<bool> {
        let processes = self.detect_aspire_processes().await?;
        Ok(!processes.is_empty())
    }
    
    async fn is_dashboard_accessible(&self) -> Result<bool> {
        let resources_url = format!("{}/api/v1/resources", self.dashboard_url);
        
        match self.client.get(&resources_url).send().await {
            Ok(response) => Ok(response.status().is_success()),
            Err(_) => Ok(false),
        }
    }
    
    async fn detect_aspire_processes(&self) -> Result<Vec<AspireProcess>> {
        let mut system = System::new_all();
        system.refresh_processes();
        
        let processes = system
            .processes()
            .values()
            .filter(|process| {
                let name = process.name().to_lowercase();
                let cmd = process.cmd().join(" ").to_lowercase();
                
                // Look for .NET processes that might be running Aspire
                (name.contains("dotnet") || name.contains("aspire")) &&
                (cmd.contains("apphost") || cmd.contains("aspire") || cmd.contains("dashboard"))
            })
            .map(|process| AspireProcess {
                pid: process.pid().as_u32(),
                name: process.name().to_string(),
                cmd: process.cmd().join(" "),
                start_time: process.start_time(),
            })
            .collect();
        
        Ok(processes)
    }
    
    async fn stop_via_dashboard(&self) -> Result<()> {
        let stop_url = format!("{}/api/v1/stop", self.dashboard_url);
        
        match self.client.post(&stop_url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    info!("Successfully requested stop via dashboard");
                    Ok(())
                } else {
                    Err(anyhow::anyhow!("Dashboard stop request failed"))
                }
            }
            Err(e) => Err(e.into()),
        }
    }
    
    async fn kill_aspire_processes(&self) -> Result<()> {
        let processes = self.detect_aspire_processes().await?;
        
        for process in processes {
            info!("Terminating process: {} (PID: {})", process.name, process.pid);
            
            #[cfg(unix)]
            {
                use std::process::Command;
                let _ = Command::new("kill")
                    .arg("-TERM")
                    .arg(process.pid.to_string())
                    .output();
            }
            
            #[cfg(windows)]
            {
                use std::process::Command;
                let _ = Command::new("taskkill")
                    .args(&["/PID", &process.pid.to_string(), "/F"])
                    .output();
            }
        }
        
        Ok(())
    }
    
    async fn restart_all_services(&self) -> Result<()> {
        info!("Restarting all services");
        
        // Stop all services first
        self.stop_aspire().await?;
        
        // Wait a moment
        tokio::time::sleep(Duration::from_secs(3)).await;
        
        // Start with default profile
        self.start_aspire("Development", false).await?;
        
        Ok(())
    }
    
    async fn get_service_url(&self, service: &str) -> Result<String> {
        let resources_url = format!("{}/api/v1/resources", self.dashboard_url);
        
        match self.client.get(&resources_url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let resources: Value = response.json().await?;
                    
                    if let Some(services) = resources.as_array() {
                        for svc in services {
                            if let Some(name) = svc.get("name").and_then(|v| v.as_str()) {
                                if name == service || name.contains(service) {
                                    if let Some(urls) = svc.get("urls").and_then(|v| v.as_array()) {
                                        if let Some(url) = urls.first().and_then(|u| u.get("url")).and_then(|v| v.as_str()) {
                                            return Ok(url.to_string());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Err(anyhow::anyhow!("Service {} not found", service))
            }
            Err(e) => Err(e.into()),
        }
    }
}