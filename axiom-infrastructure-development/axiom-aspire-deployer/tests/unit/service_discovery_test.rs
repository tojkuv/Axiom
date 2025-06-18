use axiom_aspire_mcp::services::AspireServiceDiscovery;
use axiom_aspire_mcp::mcp::protocol::{ServiceUrls, ServiceStatus};
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
            },
            {
                "name": "notifications",
                "resourceType": "project", 
                "displayName": "Notifications Service",
                "state": "Running",
                "urls": [{"name": "http", "url": "https://localhost:7002"}]
            }
        ])))
        .mount(&mock_server)
        .await;
    
    let discovery = AspireServiceDiscovery::new(&mock_server.uri());
    let services = discovery.discover_services().await.unwrap();
    
    assert_eq!(services.len(), 2);
    
    let api_service = services.iter().find(|s| s.name == "api").unwrap();
    assert_eq!(api_service.status, "Running");
    assert_eq!(api_service.health, "healthy");
    assert_eq!(api_service.url, Some("https://localhost:7001".to_string()));
    
    let notifications_service = services.iter().find(|s| s.name == "notifications").unwrap();
    assert_eq!(notifications_service.status, "Running");
    assert_eq!(notifications_service.health, "healthy");
    assert_eq!(notifications_service.url, Some("https://localhost:7002".to_string()));
}

#[tokio::test]
async fn test_discover_services_empty_response() {
    let mock_server = MockServer::start().await;
    
    Mock::given(method("GET"))
        .and(path("/api/v1/resources"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([])))
        .mount(&mock_server)
        .await;
    
    let discovery = AspireServiceDiscovery::new(&mock_server.uri());
    let services = discovery.discover_services().await.unwrap();
    
    assert_eq!(services.len(), 0);
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
            },
            {
                "name": "redis",
                "resourceType": "container",
                "displayName": "Redis Cache",
                "state": "Running",
                "urls": [{"name": "tcp", "url": "localhost:6379"}]
            }
        ])))
        .mount(&mock_server)
        .await;
    
    let discovery = AspireServiceDiscovery::new(&mock_server.uri());
    let service_urls = discovery.get_service_urls().await.unwrap();
    
    assert_eq!(service_urls.api, Some("https://localhost:7001".to_string()));
    assert_eq!(service_urls.redis, Some("localhost:6379".to_string()));
    assert_eq!(service_urls.notifications, None);
    assert!(service_urls.dashboard.is_some());
}

#[tokio::test]
async fn test_service_status_mapping() {
    let mock_server = MockServer::start().await;
    
    Mock::given(method("GET"))
        .and(path("/api/v1/resources"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([
            {
                "name": "healthy-service",
                "state": "Running",
                "urls": [{"name": "http", "url": "https://localhost:7001"}]
            },
            {
                "name": "starting-service", 
                "state": "Starting",
                "urls": []
            },
            {
                "name": "failed-service",
                "state": "Failed",
                "urls": []
            },
            {
                "name": "unknown-service",
                "state": null,
                "urls": []
            }
        ])))
        .mount(&mock_server)
        .await;
    
    let discovery = AspireServiceDiscovery::new(&mock_server.uri());
    let services = discovery.discover_services().await.unwrap();
    
    assert_eq!(services.len(), 4);
    
    let healthy = services.iter().find(|s| s.name == "healthy-service").unwrap();
    assert_eq!(healthy.health, "healthy");
    
    let starting = services.iter().find(|s| s.name == "starting-service").unwrap();
    assert_eq!(starting.health, "starting");
    
    let failed = services.iter().find(|s| s.name == "failed-service").unwrap();
    assert_eq!(failed.health, "unhealthy");
    
    let unknown = services.iter().find(|s| s.name == "unknown-service").unwrap();
    assert_eq!(unknown.health, "unknown");
}

#[tokio::test] 
async fn test_discover_services_server_error() {
    let mock_server = MockServer::start().await;
    
    Mock::given(method("GET"))
        .and(path("/api/v1/resources"))
        .respond_with(ResponseTemplate::new(500))
        .mount(&mock_server)
        .await;
    
    let discovery = AspireServiceDiscovery::new(&mock_server.uri());
    let services = discovery.discover_services().await.unwrap();
    
    // Should return empty list on server error
    assert_eq!(services.len(), 0);
}

#[test]
fn test_service_urls_default() {
    let urls = ServiceUrls {
        api: None,
        notifications: None,
        redis: None,
        dashboard: Some("https://localhost:15888".to_string()),
    };
    
    assert!(urls.api.is_none());
    assert!(urls.notifications.is_none());
    assert!(urls.redis.is_none());
    assert!(urls.dashboard.is_some());
}