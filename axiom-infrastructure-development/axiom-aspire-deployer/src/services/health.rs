use anyhow::Result;
use dashmap::DashMap;
use reqwest::Client;
use serde_json::{json, Value};
use std::sync::Arc;
use std::time::Duration;
use tracing::{debug, warn, error};

use crate::mcp::protocol::ServiceStatus;

pub struct HealthMonitor {
    client: Client,
    check_interval: Duration,
}

#[derive(Debug, serde::Serialize)]
pub struct HealthCheckResult {
    pub service_name: String,
    pub is_healthy: bool,
    pub response_time_ms: u64,
    pub status_code: Option<u16>,
    pub error_message: Option<String>,
    pub details: Option<Value>,
}

impl HealthMonitor {
    pub fn new(check_interval_ms: u64) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .danger_accept_invalid_certs(true)
            .build()
            .expect("Failed to create HTTP client for health monitoring");
        
        Self {
            client,
            check_interval: Duration::from_millis(check_interval_ms),
        }
    }
    
    pub async fn start_monitoring(&self, service_state: Arc<DashMap<String, ServiceStatus>>) {
        debug!("Starting health monitoring with interval: {:?}", self.check_interval);
        
        let mut interval = tokio::time::interval(self.check_interval);
        
        loop {
            interval.tick().await;
            
            let services: Vec<(String, ServiceStatus)> = service_state
                .iter()
                .map(|entry| (entry.key().clone(), entry.value().clone()))
                .collect();
            
            for (service_name, mut service_status) in services {
                if let Some(url) = &service_status.url {
                    match self.check_service_health(url, &service_name).await {
                        Ok(health_result) => {
                            service_status.health = if health_result.is_healthy {
                                "healthy".to_string()
                            } else {
                                "unhealthy".to_string()
                            };
                            service_status.last_check = chrono::Utc::now();
                            service_state.insert(service_name, service_status);
                        }
                        Err(e) => {
                            warn!("Health check failed for {}: {}", service_name, e);
                            service_status.health = "unknown".to_string();
                            service_status.last_check = chrono::Utc::now();
                            service_state.insert(service_name, service_status);
                        }
                    }
                }
            }
        }
    }
    
    pub async fn perform_health_check(&self, deep_check: bool) -> Result<Vec<HealthCheckResult>> {
        debug!("Performing health check (deep: {})", deep_check);
        
        // For this implementation, we'll check common health endpoints
        let health_endpoints = vec![
            ("aspire-dashboard", "https://localhost:15888/health"),
            ("aspire-dashboard-api", "https://localhost:15888/api/v1/resources"),
        ];
        
        let mut results = Vec::new();
        
        for (service_name, endpoint) in health_endpoints {
            match self.check_service_health(endpoint, service_name).await {
                Ok(result) => results.push(result),
                Err(e) => {
                    results.push(HealthCheckResult {
                        service_name: service_name.to_string(),
                        is_healthy: false,
                        response_time_ms: 0,
                        status_code: None,
                        error_message: Some(e.to_string()),
                        details: None,
                    });
                }
            }
        }
        
        if deep_check {
            results.extend(self.perform_deep_health_checks().await?);
        }
        
        Ok(results)
    }
    
    async fn check_service_health(&self, url: &str, service_name: &str) -> Result<HealthCheckResult> {
        debug!("Checking health for {} at {}", service_name, url);
        
        let start = std::time::Instant::now();
        
        // Try health endpoint first
        let health_url = if url.ends_with("/health") {
            url.to_string()
        } else {
            format!("{}/health", url.trim_end_matches('/'))
        };
        
        match self.client.get(&health_url).send().await {
            Ok(response) => {
                let response_time_ms = start.elapsed().as_millis() as u64;
                let status_code = response.status().as_u16();
                let is_healthy = response.status().is_success();
                
                let details = if is_healthy {
                    match response.json::<Value>().await {
                        Ok(json) => Some(json),
                        Err(_) => Some(json!({"status": "ok"})),
                    }
                } else {
                    None
                };
                
                Ok(HealthCheckResult {
                    service_name: service_name.to_string(),
                    is_healthy,
                    response_time_ms,
                    status_code: Some(status_code),
                    error_message: None,
                    details,
                })
            }
            Err(e) => {
                // If health endpoint fails, try the main URL
                match self.client.get(url).send().await {
                    Ok(response) => {
                        let response_time_ms = start.elapsed().as_millis() as u64;
                        let status_code = response.status().as_u16();
                        let is_healthy = response.status().is_success();
                        
                        Ok(HealthCheckResult {
                            service_name: service_name.to_string(),
                            is_healthy,
                            response_time_ms,
                            status_code: Some(status_code),
                            error_message: if !is_healthy {
                                Some(format!("HTTP {}", status_code))
                            } else {
                                None
                            },
                            details: None,
                        })
                    }
                    Err(e2) => {
                        let response_time_ms = start.elapsed().as_millis() as u64;
                        
                        Ok(HealthCheckResult {
                            service_name: service_name.to_string(),
                            is_healthy: false,
                            response_time_ms,
                            status_code: None,
                            error_message: Some(format!("Connection failed: {}", e2)),
                            details: Some(json!({
                                "primary_error": e.to_string(),
                                "fallback_error": e2.to_string()
                            })),
                        })
                    }
                }
            }
        }
    }
    
    async fn perform_deep_health_checks(&self) -> Result<Vec<HealthCheckResult>> {
        debug!("Performing deep health checks");
        
        let mut results = Vec::new();
        
        // Check system resources
        let system_health = self.check_system_health().await?;
        results.push(system_health);
        
        // Check network connectivity
        let network_health = self.check_network_connectivity().await?;
        results.push(network_health);
        
        // Check process health
        let process_health = self.check_process_health().await?;
        results.push(process_health);
        
        Ok(results)
    }
    
    async fn check_system_health(&self) -> Result<HealthCheckResult> {
        use sysinfo::System;
        
        let system = System::new_all();
        let available_memory = system.available_memory();
        let total_memory = system.total_memory();
        let memory_usage_percent = ((total_memory - available_memory) as f64 / total_memory as f64) * 100.0;
        
        let cpu_usage = system.global_cpu_info().cpu_usage();
        
        let is_healthy = memory_usage_percent < 90.0 && cpu_usage < 90.0;
        
        Ok(HealthCheckResult {
            service_name: "system".to_string(),
            is_healthy,
            response_time_ms: 0,
            status_code: None,
            error_message: if !is_healthy {
                Some(format!("High resource usage: CPU {}%, Memory {}%", cpu_usage, memory_usage_percent))
            } else {
                None
            },
            details: Some(json!({
                "cpu_usage_percent": cpu_usage,
                "memory_usage_percent": memory_usage_percent,
                "available_memory_mb": available_memory / 1024 / 1024,
                "total_memory_mb": total_memory / 1024 / 1024
            })),
        })
    }
    
    async fn check_network_connectivity(&self) -> Result<HealthCheckResult> {
        let start = std::time::Instant::now();
        
        // Test connectivity to common endpoints
        let test_urls = vec![
            "https://google.com",
            "https://microsoft.com",
        ];
        
        let mut successful_tests = 0;
        
        for url in &test_urls {
            if let Ok(response) = self.client.head(*url).send().await {
                if response.status().is_success() {
                    successful_tests += 1;
                }
            }
        }
        
        let response_time_ms = start.elapsed().as_millis() as u64;
        let is_healthy = successful_tests > 0;
        
        Ok(HealthCheckResult {
            service_name: "network".to_string(),
            is_healthy,
            response_time_ms,
            status_code: None,
            error_message: if !is_healthy {
                Some("No network connectivity".to_string())
            } else {
                None
            },
            details: Some(json!({
                "successful_tests": successful_tests,
                "total_tests": test_urls.len(),
                "test_urls": test_urls
            })),
        })
    }
    
    async fn check_process_health(&self) -> Result<HealthCheckResult> {
        use sysinfo::System;
        
        let mut system = System::new_all();
        system.refresh_processes();
        
        let dotnet_processes: Vec<_> = system
            .processes()
            .values()
            .filter(|process| {
                let name = process.name().to_lowercase();
                name.contains("dotnet") || name.contains("aspire")
            })
            .collect();
        
        let is_healthy = !dotnet_processes.is_empty();
        
        Ok(HealthCheckResult {
            service_name: "processes".to_string(),
            is_healthy,
            response_time_ms: 0,
            status_code: None,
            error_message: if !is_healthy {
                Some("No .NET/Aspire processes found".to_string())
            } else {
                None
            },
            details: Some(json!({
                "dotnet_process_count": dotnet_processes.len(),
                "processes": dotnet_processes.iter().map(|p| json!({
                    "pid": p.pid().as_u32(),
                    "name": p.name(),
                    "cpu_usage": p.cpu_usage(),
                    "memory": p.memory()
                })).collect::<Vec<_>>()
            })),
        })
    }
    
    pub async fn check_specific_service(&self, service_url: &str, service_name: &str) -> Result<HealthCheckResult> {
        self.check_service_health(service_url, service_name).await
    }
}