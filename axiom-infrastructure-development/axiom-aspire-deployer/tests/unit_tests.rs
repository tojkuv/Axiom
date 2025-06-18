// Unit tests for all modules

mod config_tests {
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
}

mod mcp_protocol_tests {
    use axiom_aspire_mcp::mcp::protocol::{McpRequest, McpResponse, McpError, ServiceStatus};
    use serde_json::json;

    #[test]
    fn test_mcp_request_creation() {
        let request = McpRequest::new(
            json!(1),
            "axiom_aspire_status".to_string(),
            Some(json!({}))
        );
        
        assert_eq!(request.jsonrpc, "2.0");
        assert_eq!(request.id, json!(1));
        assert_eq!(request.method, "axiom_aspire_status");
        assert!(request.params.is_some());
    }

    #[test]
    fn test_mcp_response_success() {
        let response = McpResponse::success(
            json!(1),
            json!({"status": "success"})
        );
        
        assert_eq!(response.jsonrpc, "2.0");
        assert_eq!(response.id, json!(1));
        assert!(response.result.is_some());
        assert!(response.error.is_none());
        assert_eq!(response.result.unwrap()["status"], "success");
    }

    #[test]
    fn test_mcp_response_error() {
        let error = McpError::new(-32601, "Method not found".to_string());
        let response = McpResponse::error(json!(1), error);
        
        assert_eq!(response.jsonrpc, "2.0");
        assert_eq!(response.id, json!(1));
        assert!(response.result.is_none());
        assert!(response.error.is_some());
        
        let err = response.error.unwrap();
        assert_eq!(err.code, -32601);
        assert_eq!(err.message, "Method not found");
    }

    #[test]
    fn test_service_status_creation() {
        let status = ServiceStatus {
            name: "api".to_string(),
            status: "running".to_string(),
            url: Some("https://localhost:7001".to_string()),
            health: "healthy".to_string(),
            uptime: Some("2h 30m".to_string()),
            last_check: chrono::Utc::now(),
        };
        
        assert_eq!(status.name, "api");
        assert_eq!(status.status, "running");
        assert_eq!(status.health, "healthy");
        assert!(status.url.is_some());
        assert!(status.uptime.is_some());
    }
}

mod service_discovery_tests {
    use axiom_aspire_mcp::services::AspireServiceDiscovery;
    use wiremock::{MockServer, Mock, ResponseTemplate};
    use wiremock::matchers::{method, path};
    use serde_json::json;

    #[tokio::test]
    async fn test_discover_services_success() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/api/v1/resources"))
            .respond_with(ResponseTemplate::new(200).set_body_json(json!([
                {
                    "name": "api",
                    "resourceType": "project",
                    "displayName": "API Service",
                    "state": "Running",
                    "urls": [{"name": "http", "url": "https://localhost:7001"}]
                }
            ])))
            .mount(&mock_server)
            .await;
        
        let discovery = AspireServiceDiscovery::new(&mock_server.uri());
        let services = discovery.discover_services().await.unwrap();
        
        assert_eq!(services.len(), 1);
        let api_service = &services[0];
        assert_eq!(api_service.name, "api");
        assert_eq!(api_service.status, "Running");
        assert_eq!(api_service.health, "healthy");
        assert_eq!(api_service.url, Some("https://localhost:7001".to_string()));
    }

    #[tokio::test]
    async fn test_discover_services_connection_error() {
        // Use invalid URL to simulate connection error
        let discovery = AspireServiceDiscovery::new("http://localhost:99999");
        let services = discovery.discover_services().await.unwrap();
        
        // Should return empty list on connection error
        assert_eq!(services.len(), 0);
    }

    #[tokio::test]
    async fn test_get_service_urls() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/api/v1/resources"))
            .respond_with(ResponseTemplate::new(200).set_body_json(json!([
                {
                    "name": "api",
                    "resourceType": "project",
                    "displayName": "API Service",
                    "state": "Running",
                    "urls": [{"name": "http", "url": "https://localhost:7001"}]
                }
            ])))
            .mount(&mock_server)
            .await;
        
        let discovery = AspireServiceDiscovery::new(&mock_server.uri());
        let service_urls = discovery.get_service_urls().await.unwrap();
        
        assert_eq!(service_urls.api, Some("https://localhost:7001".to_string()));
        assert!(service_urls.dashboard.is_some());
    }
}

mod health_monitor_tests {
    use axiom_aspire_mcp::services::HealthMonitor;
    use wiremock::{MockServer, Mock, ResponseTemplate};
    use wiremock::matchers::{method, path};
    use serde_json::json;

    #[tokio::test]
    async fn test_health_monitor_creation() {
        let _monitor = HealthMonitor::new(5000);
        // Just testing that creation works without panicking
        assert!(true);
    }

    #[tokio::test]
    async fn test_perform_health_check_basic() {
        let monitor = HealthMonitor::new(1000);
        let result = monitor.perform_health_check(false).await.unwrap();
        
        // Should return some health check results
        assert_eq!(result.len(), 2); // aspire-dashboard and aspire-dashboard-api
        
        // Check that we get aspire dashboard health checks
        let dashboard_health = result.iter().find(|r| r.service_name == "aspire-dashboard");
        assert!(dashboard_health.is_some());
        
        let dashboard_api_health = result.iter().find(|r| r.service_name == "aspire-dashboard-api");
        assert!(dashboard_api_health.is_some());
    }

    #[tokio::test]
    async fn test_perform_health_check_deep() {
        let monitor = HealthMonitor::new(1000);
        let result = monitor.perform_health_check(true).await.unwrap();
        
        // Deep check should return more results (2 basic + 3 deep = 5 total)
        assert!(result.len() >= 5);
        
        // Should include system, network, and process checks
        let service_names: Vec<String> = result.iter().map(|r| r.service_name.clone()).collect();
        assert!(service_names.contains(&"system".to_string()));
        assert!(service_names.contains(&"network".to_string()));
        assert!(service_names.contains(&"processes".to_string()));
        assert!(service_names.contains(&"aspire-dashboard".to_string()));
        assert!(service_names.contains(&"aspire-dashboard-api".to_string()));
    }

    #[tokio::test]
    async fn test_check_specific_service_success() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/health"))
            .respond_with(ResponseTemplate::new(200).set_body_json(json!({"status": "healthy"})))
            .mount(&mock_server)
            .await;
        
        let monitor = HealthMonitor::new(1000);
        let result = monitor.check_specific_service(&mock_server.uri(), "test-service").await.unwrap();
        
        assert_eq!(result.service_name, "test-service");
        assert!(result.is_healthy);
        assert_eq!(result.status_code, Some(200));
        assert!(result.error_message.is_none());
        assert!(result.response_time_ms > 0);
    }

    #[tokio::test]
    async fn test_check_specific_service_failure() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/health"))
            .respond_with(ResponseTemplate::new(500))
            .mount(&mock_server)
            .await;
        
        let monitor = HealthMonitor::new(1000);
        let result = monitor.check_specific_service(&mock_server.uri(), "test-service").await.unwrap();
        
        assert_eq!(result.service_name, "test-service");
        assert!(!result.is_healthy);
        assert_eq!(result.status_code, Some(500));
    }
}

mod network_manager_tests {
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
        let _manager = NetworkManager::new(&config);
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
        
        // URLs should contain proper format
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
    async fn test_generate_device_config_unsupported_device() {
        let config = create_test_config();
        let manager = NetworkManager::new(&config);
        
        let result = manager.generate_device_config("nintendo-switch", "json").await;
        
        // Should return error for unsupported device type
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Unsupported device type"));
    }
}