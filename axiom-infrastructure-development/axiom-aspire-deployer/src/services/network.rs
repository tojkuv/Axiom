use anyhow::Result;
use local_ip_address::local_ip;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use tokio::process::Command;
use tracing::{debug, info, warn};

use crate::config::settings::NetworkConfig;

pub struct NetworkManager {
    config: NetworkConfig,
    local_interface: IpAddr,
    port_mappings: HashMap<String, u16>,
}

impl NetworkManager {
    pub fn new(config: &NetworkConfig) -> Self {
        Self {
            config: config.clone(),
            local_interface: IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)),
            port_mappings: HashMap::new(),
        }
    }
    
    pub async fn configure_local_network(&self, services: &[String], bind_mode: &str) -> Result<Value> {
        info!("Configuring local network for services: {:?}, bind_mode: {}", services, bind_mode);
        
        let local_ip = self.get_local_ip().await?;
        let mut configuration = json!({
            "local_ip": local_ip,
            "bind_mode": bind_mode,
            "configured_services": []
        });
        
        let mut configured_services = Vec::new();
        
        for service in services {
            match self.configure_service_network(service, bind_mode, &local_ip).await {
                Ok(service_config) => {
                    configured_services.push(service_config);
                }
                Err(e) => {
                    warn!("Failed to configure network for service {}: {}", service, e);
                }
            }
        }
        
        configuration["configured_services"] = json!(configured_services);
        
        Ok(configuration)
    }
    
    pub async fn get_network_urls(&self) -> Result<HashMap<String, String>> {
        debug!("Getting network URLs");
        
        let local_ip = self.get_local_ip().await?;
        let mut urls = HashMap::new();
        
        // Default Aspire service ports
        let default_ports = vec![
            ("api", 7001),
            ("notifications", 7002),
            ("dashboard", 15888),
            ("redis", 6379),
        ];
        
        for (service, port) in default_ports {
            let url = if service == "redis" {
                format!("{}:{}", local_ip, port)
            } else {
                format!("https://{}:{}", local_ip, port)
            };
            urls.insert(service.to_string(), url);
        }
        
        // Add any custom port mappings
        for (service, port) in &self.port_mappings {
            let url = format!("https://{}:{}", local_ip, port);
            urls.insert(service.clone(), url);
        }
        
        Ok(urls)
    }
    
    pub async fn scan_for_services(&self) -> Result<Vec<(String, u16)>> {
        debug!("Scanning for services on local network");
        
        let local_ip = self.get_local_ip().await?;
        let mut found_services = Vec::new();
        
        // Parse port range
        let (start_port, end_port) = self.parse_port_range(&self.config.port_scan_range)?;
        
        // Scan ports concurrently
        let mut tasks = Vec::new();
        
        for port in start_port..=end_port {
            let ip = local_ip.clone();
            let task = tokio::spawn(async move {
                Self::check_port_open(&ip, port).await
            });
            tasks.push((port, task));
        }
        
        for (port, task) in tasks {
            if task.await? {
                // Try to identify the service
                if let Ok(service_name) = self.identify_service_on_port(port).await {
                    found_services.push((service_name, port));
                } else {
                    found_services.push((format!("unknown-{}", port), port));
                }
            }
        }
        
        info!("Found {} services on local network", found_services.len());
        Ok(found_services)
    }
    
    pub async fn get_local_ip(&self) -> Result<String> {
        match local_ip() {
            Ok(ip) => Ok(ip.to_string()),
            Err(_) => {
                // Fallback to system command
                self.get_local_ip_via_command().await
            }
        }
    }
    
    pub async fn generate_device_config(&self, device_type: &str, format: &str) -> Result<Value> {
        info!("Generating device config for {}", device_type);
        
        let local_ip = self.get_local_ip().await?;
        let service_urls = self.get_network_urls().await?;
        
        let config = match device_type {
            "ios" => self.generate_ios_config(&local_ip, &service_urls, format).await?,
            "android" => self.generate_android_config(&local_ip, &service_urls, format).await?,
            "web" => self.generate_web_config(&local_ip, &service_urls, format).await?,
            _ => return Err(anyhow::anyhow!("Unsupported device type: {}", device_type)),
        };
        
        Ok(config)
    }
    
    async fn configure_service_network(&self, service: &str, bind_mode: &str, local_ip: &str) -> Result<Value> {
        debug!("Configuring network for service: {}", service);
        
        // This would typically involve configuring the service to bind to the correct interface
        // For now, we'll return configuration information
        
        let bind_address = match bind_mode {
            "localhost" => "127.0.0.1".to_string(),
            "local_network" => local_ip.to_string(),
            "all_interfaces" => "0.0.0.0".to_string(),
            _ => "127.0.0.1".to_string(),
        };
        
        Ok(json!({
            "service": service,
            "bind_address": bind_address,
            "bind_mode": bind_mode,
            "accessible_from_network": bind_mode != "localhost"
        }))
    }
    
    async fn get_local_ip_via_command(&self) -> Result<String> {
        debug!("Getting local IP via system command");
        
        #[cfg(target_os = "macos")]
        {
            let output = Command::new("ifconfig")
                .arg("en0")
                .output()
                .await?;
            
            let output_str = String::from_utf8(output.stdout)?;
            for line in output_str.lines() {
                if line.contains("inet ") && !line.contains("127.0.0.1") {
                    if let Some(ip) = line.split_whitespace().nth(1) {
                        return Ok(ip.to_string());
                    }
                }
            }
        }
        
        #[cfg(target_os = "linux")]
        {
            let output = Command::new("hostname")
                .arg("-I")
                .output()
                .await?;
            
            let output_str = String::from_utf8(output.stdout)?;
            if let Some(ip) = output_str.trim().split_whitespace().next() {
                return Ok(ip.to_string());
            }
        }
        
        #[cfg(target_os = "windows")]
        {
            let output = Command::new("ipconfig")
                .output()
                .await?;
            
            let output_str = String::from_utf8(output.stdout)?;
            for line in output_str.lines() {
                if line.contains("IPv4 Address") {
                    if let Some(ip) = line.split(':').nth(1) {
                        return Ok(ip.trim().to_string());
                    }
                }
            }
        }
        
        // Ultimate fallback
        Ok("127.0.0.1".to_string())
    }
    
    fn parse_port_range(&self, range: &str) -> Result<(u16, u16)> {
        let parts: Vec<&str> = range.split('-').collect();
        if parts.len() != 2 {
            return Err(anyhow::anyhow!("Invalid port range format: {}", range));
        }
        
        let start: u16 = parts[0].parse()?;
        let end: u16 = parts[1].parse()?;
        
        if start > end {
            return Err(anyhow::anyhow!("Invalid port range: start > end"));
        }
        
        Ok((start, end))
    }
    
    async fn check_port_open(ip: &str, port: u16) -> bool {
        use tokio::net::TcpStream;
        use tokio::time::{timeout, Duration};
        
        let addr = format!("{}:{}", ip, port);
        
        match timeout(Duration::from_millis(100), TcpStream::connect(&addr)).await {
            Ok(Ok(_)) => true,
            _ => false,
        }
    }
    
    async fn identify_service_on_port(&self, port: u16) -> Result<String> {
        debug!("Identifying service on port {}", port);
        
        // Common Aspire service ports
        let service_name = match port {
            15888 => "aspire-dashboard",
            7001 => "api",
            7002 => "notifications",
            6379 => "redis",
            5432 => "postgres",
            1433 => "sqlserver",
            _ => "unknown",
        };
        
        Ok(service_name.to_string())
    }
    
    async fn generate_ios_config(&self, local_ip: &str, service_urls: &HashMap<String, String>, format: &str) -> Result<Value> {
        let config = json!({
            "ApiBaseUrl": service_urls.get("api").unwrap_or(&format!("https://{}:7001", local_ip)),
            "NotificationsUrl": service_urls.get("notifications").unwrap_or(&format!("https://{}:7002", local_ip)),
            "Environment": "Development",
            "TrustLocalCertificates": true
        });
        
        match format {
            "plist" => {
                // Convert to plist format (simplified)
                Ok(json!({
                    "format": "plist",
                    "content": format!("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>ApiBaseUrl</key>\n\t<string>{}</string>\n\t<key>NotificationsUrl</key>\n\t<string>{}</string>\n\t<key>Environment</key>\n\t<string>Development</string>\n\t<key>TrustLocalCertificates</key>\n\t<true/>\n</dict>\n</plist>", 
                        service_urls.get("api").unwrap_or(&format!("https://{}:7001", local_ip)),
                        service_urls.get("notifications").unwrap_or(&format!("https://{}:7002", local_ip)))
                }))
            }
            _ => Ok(config),
        }
    }
    
    async fn generate_android_config(&self, local_ip: &str, service_urls: &HashMap<String, String>, format: &str) -> Result<Value> {
        let config = json!({
            "apiBaseUrl": service_urls.get("api").unwrap_or(&format!("https://{}:7001", local_ip)),
            "notificationsUrl": service_urls.get("notifications").unwrap_or(&format!("https://{}:7002", local_ip)),
            "environment": "development",
            "trustLocalCertificates": true,
            "networkSecurityConfig": {
                "domain": local_ip,
                "includeSubdomains": false,
                "trustUserCerts": true
            }
        });
        
        Ok(config)
    }
    
    async fn generate_web_config(&self, local_ip: &str, service_urls: &HashMap<String, String>, format: &str) -> Result<Value> {
        let config = json!({
            "API_BASE_URL": service_urls.get("api").unwrap_or(&format!("https://{}:7001", local_ip)),
            "NOTIFICATIONS_URL": service_urls.get("notifications").unwrap_or(&format!("https://{}:7002", local_ip)),
            "ENVIRONMENT": "development",
            "TRUST_LOCAL_CERTIFICATES": true
        });
        
        match format {
            "env" => {
                let env_content = format!(
                    "API_BASE_URL={}\nNOTIFICATIONS_URL={}\nENVIRONMENT=development\nTRUST_LOCAL_CERTIFICATES=true\n",
                    service_urls.get("api").unwrap_or(&format!("https://{}:7001", local_ip)),
                    service_urls.get("notifications").unwrap_or(&format!("https://{}:7002", local_ip))
                );
                
                Ok(json!({
                    "format": "env",
                    "content": env_content
                }))
            }
            _ => Ok(config),
        }
    }
}