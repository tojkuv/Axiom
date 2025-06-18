use axiom_aspire_mcp::services::NetworkManager;
use axiom_aspire_mcp::config::settings::NetworkConfig;

fn create_test_config() -> NetworkConfig {
    NetworkConfig {
        local_interface: "0.0.0.0".to_string(),
        network_scan_enabled: true,
        port_scan_range: "7000-8000".to_string(),
    }
}

#[test]
fn test_network_manager_creation() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    // Just testing that creation works without panicking
    assert!(true);
}

#[tokio::test]
async fn test_get_local_ip() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let ip = manager.get_local_ip().await.unwrap();
    
    // Should return some IP address
    assert!(!ip.is_empty());
    assert!(ip.contains('.') || ip.contains(':')); // IPv4 or IPv6
}

#[tokio::test]
async fn test_get_network_urls() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let urls = manager.get_network_urls().await.unwrap();
    
    // Should have default URLs for common services
    assert!(urls.contains_key("api"));
    assert!(urls.contains_key("notifications"));
    assert!(urls.contains_key("dashboard"));
    assert!(urls.contains_key("redis"));
    
    // URLs should contain the local IP
    let api_url = urls.get("api").unwrap();
    assert!(api_url.starts_with("https://"));
    
    let redis_url = urls.get("redis").unwrap();
    assert!(redis_url.contains(":6379")); // Redis default port
}

#[tokio::test]
async fn test_configure_local_network() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let services = vec!["api".to_string(), "notifications".to_string()];
    let result = manager.configure_local_network(&services, "local_network").await.unwrap();
    
    // Should return configuration information
    assert!(result.get("local_ip").is_some());
    assert_eq!(result.get("bind_mode").unwrap(), "local_network");
    
    let configured_services = result.get("configured_services").unwrap().as_array().unwrap();
    assert_eq!(configured_services.len(), 2);
}

#[tokio::test]
async fn test_configure_local_network_localhost_mode() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let services = vec!["api".to_string()];
    let result = manager.configure_local_network(&services, "localhost").await.unwrap();
    
    assert_eq!(result.get("bind_mode").unwrap(), "localhost");
    
    let configured_services = result.get("configured_services").unwrap().as_array().unwrap();
    let service_config = &configured_services[0];
    assert_eq!(service_config.get("bind_address").unwrap(), "127.0.0.1");
    assert_eq!(service_config.get("accessible_from_network").unwrap(), false);
}

#[tokio::test]
async fn test_configure_local_network_all_interfaces_mode() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let services = vec!["api".to_string()];
    let result = manager.configure_local_network(&services, "all_interfaces").await.unwrap();
    
    assert_eq!(result.get("bind_mode").unwrap(), "all_interfaces");
    
    let configured_services = result.get("configured_services").unwrap().as_array().unwrap();
    let service_config = &configured_services[0];
    assert_eq!(service_config.get("bind_address").unwrap(), "0.0.0.0");
    assert_eq!(service_config.get("accessible_from_network").unwrap(), true);
}

#[tokio::test]
async fn test_generate_device_config_ios() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let result = manager.generate_device_config("ios", "json").await.unwrap();
    
    // Should contain iOS-specific configuration
    assert!(result.get("ApiBaseUrl").is_some());
    assert!(result.get("NotificationsUrl").is_some());
    assert_eq!(result.get("Environment").unwrap(), "Development");
    assert_eq!(result.get("TrustLocalCertificates").unwrap(), true);
}

#[tokio::test]
async fn test_generate_device_config_ios_plist() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let result = manager.generate_device_config("ios", "plist").await.unwrap();
    
    // Should return plist format
    assert_eq!(result.get("format").unwrap(), "plist");
    assert!(result.get("content").is_some());
    let content = result.get("content").unwrap().as_str().unwrap();
    assert!(content.contains("<?xml version=\"1.0\""));
    assert!(content.contains("<plist version=\"1.0\">"));
}

#[tokio::test]
async fn test_generate_device_config_android() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let result = manager.generate_device_config("android", "json").await.unwrap();
    
    // Should contain Android-specific configuration
    assert!(result.get("apiBaseUrl").is_some());
    assert!(result.get("notificationsUrl").is_some());
    assert_eq!(result.get("environment").unwrap(), "development");
    assert_eq!(result.get("trustLocalCertificates").unwrap(), true);
    
    // Should have network security config
    assert!(result.get("networkSecurityConfig").is_some());
}

#[tokio::test]
async fn test_generate_device_config_web() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let result = manager.generate_device_config("web", "json").await.unwrap();
    
    // Should contain web-specific configuration
    assert!(result.get("API_BASE_URL").is_some());
    assert!(result.get("NOTIFICATIONS_URL").is_some());
    assert_eq!(result.get("ENVIRONMENT").unwrap(), "development");
    assert_eq!(result.get("TRUST_LOCAL_CERTIFICATES").unwrap(), true);
}

#[tokio::test]
async fn test_generate_device_config_web_env_format() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let result = manager.generate_device_config("web", "env").await.unwrap();
    
    // Should return env format
    assert_eq!(result.get("format").unwrap(), "env");
    assert!(result.get("content").is_some());
    let content = result.get("content").unwrap().as_str().unwrap();
    assert!(content.contains("API_BASE_URL="));
    assert!(content.contains("ENVIRONMENT=development"));
}

#[tokio::test]
async fn test_generate_device_config_unsupported_device() {
    let config = create_test_config();
    let manager = NetworkManager::new(&config);
    
    let result = manager.generate_device_config("nintendo-switch", "json").await;
    
    // Should return error for unsupported device type
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("Unsupported device type"));
}

#[test]
fn test_network_config_creation() {
    let config = NetworkConfig {
        local_interface: "192.168.1.100".to_string(),
        network_scan_enabled: false,
        port_scan_range: "8000-9000".to_string(),
    };
    
    assert_eq!(config.local_interface, "192.168.1.100");
    assert!(!config.network_scan_enabled);
    assert_eq!(config.port_scan_range, "8000-9000");
}