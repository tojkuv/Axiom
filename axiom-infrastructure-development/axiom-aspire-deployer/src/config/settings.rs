use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Settings {
    pub server: ServerConfig,
    pub aspire: AspireConfig,
    pub monitoring: MonitoringConfig,
    pub network: NetworkConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub name: String,
    pub version: String,
    pub port: u16,
    pub host: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AspireConfig {
    pub auto_discovery: bool,
    pub dashboard_url: String,
    pub polling_interval_ms: u64,
    pub api_timeout_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonitoringConfig {
    pub monitor_processes: bool,
    pub watch_config_files: bool,
    pub health_check_interval_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkConfig {
    pub local_interface: String,
    pub network_scan_enabled: bool,
    pub port_scan_range: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    pub level: String,
    pub file: Option<String>,
    pub structured: bool,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            server: ServerConfig {
                name: "axiom-aspire-deployer".to_string(),
                version: "1.0.0".to_string(),
                port: 3001,
                host: "127.0.0.1".to_string(),
            },
            aspire: AspireConfig {
                auto_discovery: true,
                dashboard_url: "https://localhost:15888".to_string(),
                polling_interval_ms: 1000,
                api_timeout_ms: 5000,
            },
            monitoring: MonitoringConfig {
                monitor_processes: true,
                watch_config_files: true,
                health_check_interval_ms: 5000,
            },
            network: NetworkConfig {
                local_interface: "0.0.0.0".to_string(),
                network_scan_enabled: true,
                port_scan_range: "7000-8000".to_string(),
            },
            logging: LoggingConfig {
                level: "info".to_string(),
                file: Some("axiom-aspire-mcp.log".to_string()),
                structured: true,
            },
        }
    }
}

impl Settings {
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        if path.as_ref().exists() {
            let content = std::fs::read_to_string(path)?;
            let settings: Settings = toml::from_str(&content)?;
            Ok(settings)
        } else {
            tracing::warn!("Config file not found, using defaults");
            Ok(Settings::default())
        }
    }
    
    pub fn save_to_file<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let content = toml::to_string_pretty(self)?;
        std::fs::write(path, content)?;
        Ok(())
    }
}