use axiom_aspire_mcp::services::HealthMonitor;
use wiremock::{MockServer, Mock, ResponseTemplate};
use wiremock::matchers::{method, path};
use serde_json::json;

#[tokio::test]
async fn test_health_monitor_creation() {
    let monitor = HealthMonitor::new(5000);
    // Just testing that creation works without panicking
    assert!(true);
}

#[tokio::test]
async fn test_perform_health_check_basic() {
    let monitor = HealthMonitor::new(1000);
    let result = monitor.perform_health_check(false).await.unwrap();
    
    // Should return some health check results
    assert!(result.len() >= 1);
    
    // Check that we get system health
    let system_health = result.iter().find(|r| r.service_name == "system");
    assert!(system_health.is_some());
}

#[tokio::test]
async fn test_perform_health_check_deep() {
    let monitor = HealthMonitor::new(1000);
    let result = monitor.perform_health_check(true).await.unwrap();
    
    // Deep check should return more results
    assert!(result.len() >= 3);
    
    // Should include system, network, and process checks
    let service_names: Vec<String> = result.iter().map(|r| r.service_name.clone()).collect();
    assert!(service_names.contains(&"system".to_string()));
    assert!(service_names.contains(&"network".to_string()));
    assert!(service_names.contains(&"processes".to_string()));
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
    assert!(result.response_time_ms > 0);
}

#[tokio::test]
async fn test_check_specific_service_connection_error() {
    let monitor = HealthMonitor::new(1000);
    let result = monitor.check_specific_service("http://localhost:99999", "test-service").await.unwrap();
    
    assert_eq!(result.service_name, "test-service");
    assert!(!result.is_healthy);
    assert!(result.error_message.is_some());
    assert!(result.error_message.unwrap().contains("Connection failed"));
}

#[tokio::test]
async fn test_check_specific_service_fallback_url() {
    let mock_server = MockServer::start().await;
    
    // Health endpoint fails, but main URL succeeds
    Mock::given(method("GET"))
        .and(path("/health"))
        .respond_with(ResponseTemplate::new(404))
        .mount(&mock_server)
        .await;
    
    Mock::given(method("GET"))
        .and(path("/"))
        .respond_with(ResponseTemplate::new(200))
        .mount(&mock_server)
        .await;
    
    let monitor = HealthMonitor::new(1000);
    let result = monitor.check_specific_service(&mock_server.uri(), "test-service").await.unwrap();
    
    assert_eq!(result.service_name, "test-service");
    assert!(result.is_healthy);
    assert_eq!(result.status_code, Some(200));
}

#[test]
fn test_health_check_result_creation() {
    use axiom_aspire_mcp::services::health::HealthCheckResult;
    
    let result = HealthCheckResult {
        service_name: "test".to_string(),
        is_healthy: true,
        response_time_ms: 150,
        status_code: Some(200),
        error_message: None,
        details: Some(serde_json::json!({"version": "1.0.0"})),
    };
    
    assert_eq!(result.service_name, "test");
    assert!(result.is_healthy);
    assert_eq!(result.response_time_ms, 150);
    assert_eq!(result.status_code, Some(200));
    assert!(result.error_message.is_none());
    assert!(result.details.is_some());
}

#[tokio::test]
async fn test_system_health_check() {
    let monitor = HealthMonitor::new(1000);
    let results = monitor.perform_health_check(true).await.unwrap();
    
    let system_result = results.iter().find(|r| r.service_name == "system").unwrap();
    
    // System health should have details about CPU and memory
    assert!(system_result.details.is_some());
    let details = system_result.details.as_ref().unwrap();
    assert!(details.get("cpu_usage_percent").is_some());
    assert!(details.get("memory_usage_percent").is_some());
    assert!(details.get("available_memory_mb").is_some());
    assert!(details.get("total_memory_mb").is_some());
}

#[tokio::test]
async fn test_network_health_check() {
    let monitor = HealthMonitor::new(1000);
    let results = monitor.perform_health_check(true).await.unwrap();
    
    let network_result = results.iter().find(|r| r.service_name == "network").unwrap();
    
    // Network health should have test details
    assert!(network_result.details.is_some());
    let details = network_result.details.as_ref().unwrap();
    assert!(details.get("successful_tests").is_some());
    assert!(details.get("total_tests").is_some());
    assert!(details.get("test_urls").is_some());
}

#[tokio::test]
async fn test_process_health_check() {
    let monitor = HealthMonitor::new(1000);
    let results = monitor.perform_health_check(true).await.unwrap();
    
    let process_result = results.iter().find(|r| r.service_name == "processes").unwrap();
    
    // Process health should have dotnet process count
    assert!(process_result.details.is_some());
    let details = process_result.details.as_ref().unwrap();
    assert!(details.get("dotnet_process_count").is_some());
    assert!(details.get("processes").is_some());
}