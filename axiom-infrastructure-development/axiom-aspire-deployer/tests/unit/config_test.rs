use axiom_aspire_mcp::config::Settings;
use std::fs;
use tempfile::tempdir;

#[test]
fn test_default_settings() {
    let settings = Settings::default();
    
    assert_eq!(settings.server.name, "axiom-aspire-deployer");
    assert_eq!(settings.server.port, 3001);
    assert_eq!(settings.aspire.dashboard_url, "https://localhost:15888");
    assert!(settings.aspire.auto_discovery);
    assert!(settings.monitoring.monitor_processes);
}

#[test]
fn test_settings_from_file() {
    let dir = tempdir().unwrap();
    let file_path = dir.path().join("test_config.toml");
    
    let config_content = r#"
[server]
name = "test-server"
version = "1.0.0"
port = 4000
host = "0.0.0.0"

[aspire]
auto_discovery = false
dashboard_url = "https://test:9999"
polling_interval_ms = 2000
api_timeout_ms = 10000

[monitoring]
monitor_processes = false
watch_config_files = false
health_check_interval_ms = 3000

[network]
local_interface = "127.0.0.1"
network_scan_enabled = false
port_scan_range = "8000-9000"

[logging]
level = "debug"
file = "test.log"
structured = false
"#;
    
    fs::write(&file_path, config_content).unwrap();
    
    let settings = Settings::from_file(&file_path).unwrap();
    
    assert_eq!(settings.server.name, "test-server");
    assert_eq!(settings.server.port, 4000);
    assert_eq!(settings.aspire.dashboard_url, "https://test:9999");
    assert!(!settings.aspire.auto_discovery);
    assert!(!settings.monitoring.monitor_processes);
    assert_eq!(settings.logging.level, "debug");
}

#[test]
fn test_settings_from_nonexistent_file() {
    let settings = Settings::from_file("nonexistent_file.toml").unwrap();
    
    // Should return default settings
    assert_eq!(settings.server.name, "axiom-aspire-deployer");
    assert_eq!(settings.server.port, 3001);
}