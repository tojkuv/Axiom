use anyhow::Result;
use reqwest::{Client, Method, Response};
use serde_json::Value;
use std::collections::HashMap;
use std::time::{Duration, Instant};
use tracing::{debug, warn};

use crate::mcp::protocol::{EndpointCallRequest, EndpointCallResponse};

pub struct HttpClient {
    client: Client,
}

impl HttpClient {
    pub fn new() -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .danger_accept_invalid_certs(true) // For local development
            .redirect(reqwest::redirect::Policy::limited(3))
            .build()
            .expect("Failed to create HTTP client");
        
        Self { client }
    }
    
    pub async fn call_endpoint(&self, request: EndpointCallRequest) -> Result<EndpointCallResponse> {
        debug!("Calling endpoint: {} {}", request.method, request.endpoint);
        
        let start_time = Instant::now();
        
        // Parse method
        let method = match request.method.to_uppercase().as_str() {
            "GET" => Method::GET,
            "POST" => Method::POST,
            "PUT" => Method::PUT,
            "DELETE" => Method::DELETE,
            "PATCH" => Method::PATCH,
            "HEAD" => Method::HEAD,
            "OPTIONS" => Method::OPTIONS,
            _ => return Err(anyhow::anyhow!("Unsupported HTTP method: {}", request.method)),
        };
        
        // Build request
        let mut req_builder = self.client.request(method, &request.endpoint);
        
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
                
                // Extract headers
                let headers: HashMap<String, String> = response
                    .headers()
                    .iter()
                    .map(|(k, v)| (k.to_string(), v.to_str().unwrap_or("").to_string()))
                    .collect();
                
                // Extract body
                let body = self.extract_response_body(response).await?;
                
                Ok(EndpointCallResponse {
                    status,
                    headers,
                    body,
                    duration,
                })
            }
            Err(e) => {
                let duration = start_time.elapsed().as_millis() as u64;
                warn!("HTTP request failed: {}", e);
                
                // Return error response
                Ok(EndpointCallResponse {
                    status: 0,
                    headers: HashMap::new(),
                    body: serde_json::json!({
                        "error": e.to_string(),
                        "type": "network_error"
                    }),
                    duration,
                })
            }
        }
    }
    
    pub async fn get(&self, url: &str, headers: Option<HashMap<String, String>>) -> Result<EndpointCallResponse> {
        let request = EndpointCallRequest {
            service: "external".to_string(),
            endpoint: url.to_string(),
            method: "GET".to_string(),
            headers,
            body: None,
            timeout: Some(30),
        };
        
        self.call_endpoint(request).await
    }
    
    pub async fn post(&self, url: &str, body: Option<Value>, headers: Option<HashMap<String, String>>) -> Result<EndpointCallResponse> {
        let request = EndpointCallRequest {
            service: "external".to_string(),
            endpoint: url.to_string(),
            method: "POST".to_string(),
            headers,
            body,
            timeout: Some(30),
        };
        
        self.call_endpoint(request).await
    }
    
    pub async fn put(&self, url: &str, body: Option<Value>, headers: Option<HashMap<String, String>>) -> Result<EndpointCallResponse> {
        let request = EndpointCallRequest {
            service: "external".to_string(),
            endpoint: url.to_string(),
            method: "PUT".to_string(),
            headers,
            body,
            timeout: Some(30),
        };
        
        self.call_endpoint(request).await
    }
    
    pub async fn delete(&self, url: &str, headers: Option<HashMap<String, String>>) -> Result<EndpointCallResponse> {
        let request = EndpointCallRequest {
            service: "external".to_string(),
            endpoint: url.to_string(),
            method: "DELETE".to_string(),
            headers,
            body: None,
            timeout: Some(30),
        };
        
        self.call_endpoint(request).await
    }
    
    pub async fn head(&self, url: &str, headers: Option<HashMap<String, String>>) -> Result<EndpointCallResponse> {
        let request = EndpointCallRequest {
            service: "external".to_string(),
            endpoint: url.to_string(),
            method: "HEAD".to_string(),
            headers,
            body: None,
            timeout: Some(10),
        };
        
        self.call_endpoint(request).await
    }
    
    pub async fn check_health(&self, url: &str) -> Result<bool> {
        debug!("Checking health of {}", url);
        
        let health_urls = vec![
            format!("{}/health", url.trim_end_matches('/')),
            format!("{}/healthz", url.trim_end_matches('/')),
            format!("{}/_health", url.trim_end_matches('/')),
            url.to_string(), // Fallback to base URL
        ];
        
        for health_url in health_urls {
            match self.head(&health_url, None).await {
                Ok(response) => {
                    if response.status >= 200 && response.status < 400 {
                        return Ok(true);
                    }
                }
                Err(_) => continue,
            }
        }
        
        Ok(false)
    }
    
    pub async fn test_connectivity(&self, url: &str) -> Result<(bool, u64)> {
        debug!("Testing connectivity to {}", url);
        
        let start_time = Instant::now();
        
        match self.head(url, None).await {
            Ok(response) => {
                let duration = start_time.elapsed().as_millis() as u64;
                let is_reachable = response.status > 0; // Any response means reachable
                Ok((is_reachable, duration))
            }
            Err(_) => {
                let duration = start_time.elapsed().as_millis() as u64;
                Ok((false, duration))
            }
        }
    }
    
    pub async fn run_endpoint_tests(&self, base_url: &str, test_suite: &str) -> Result<Vec<EndpointTestResult>> {
        debug!("Running endpoint test suite: {}", test_suite);
        
        let test_endpoints = match test_suite {
            "smoke" => self.get_smoke_test_endpoints(),
            "integration" => self.get_integration_test_endpoints(),
            "full" => self.get_full_test_endpoints(),
            _ => return Err(anyhow::anyhow!("Unknown test suite: {}", test_suite)),
        };
        
        let mut results = Vec::new();
        
        for test in test_endpoints {
            let full_url = format!("{}{}", base_url.trim_end_matches('/'), test.endpoint);
            
            let method = test.method.clone();
            let endpoint = test.endpoint.clone();
            
            let request = EndpointCallRequest {
                service: "test".to_string(),
                endpoint: full_url,
                method: test.method,
                headers: test.headers,
                body: test.body,
                timeout: Some(30),
            };
            
            let start_time = Instant::now();
            match self.call_endpoint(request).await {
                Ok(response) => {
                    let success = test.expected_status.map(|s| s == response.status).unwrap_or(response.status < 400);
                    
                    results.push(EndpointTestResult {
                        endpoint,
                        method: method.clone(),
                        success,
                        status_code: response.status,
                        duration: response.duration,
                        error: None,
                    });
                }
                Err(e) => {
                    let duration = start_time.elapsed().as_millis() as u64;
                    results.push(EndpointTestResult {
                        endpoint,
                        method,
                        success: false,
                        status_code: 0,
                        duration,
                        error: Some(e.to_string()),
                    });
                }
            }
        }
        
        Ok(results)
    }
    
    async fn extract_response_body(&self, response: Response) -> Result<Value> {
        let content_type = response.headers()
            .get("content-type")
            .and_then(|v| v.to_str().ok())
            .unwrap_or("");
        
        if content_type.contains("application/json") {
            match response.json::<Value>().await {
                Ok(json) => Ok(json),
                Err(_) => Ok(serde_json::json!({})),
            }
        } else if content_type.contains("text/") {
            match response.text().await {
                Ok(text) => Ok(serde_json::json!({"text": text})),
                Err(_) => Ok(serde_json::json!({})),
            }
        } else {
            // For binary content, just return basic info
            match response.bytes().await {
                Ok(bytes) => Ok(serde_json::json!({
                    "type": "binary",
                    "size": bytes.len()
                })),
                Err(_) => Ok(serde_json::json!({})),
            }
        }
    }
    
    fn get_smoke_test_endpoints(&self) -> Vec<EndpointTest> {
        vec![
            EndpointTest {
                endpoint: "/health".to_string(),
                method: "GET".to_string(),
                headers: None,
                body: None,
                expected_status: Some(200),
            },
            EndpointTest {
                endpoint: "/".to_string(),
                method: "GET".to_string(),
                headers: None,
                body: None,
                expected_status: None,
            },
        ]
    }
    
    fn get_integration_test_endpoints(&self) -> Vec<EndpointTest> {
        let mut tests = self.get_smoke_test_endpoints();
        tests.extend(vec![
            EndpointTest {
                endpoint: "/api/health".to_string(),
                method: "GET".to_string(),
                headers: None,
                body: None,
                expected_status: Some(200),
            },
            EndpointTest {
                endpoint: "/api/status".to_string(),
                method: "GET".to_string(),
                headers: None,
                body: None,
                expected_status: Some(200),
            },
        ]);
        tests
    }
    
    fn get_full_test_endpoints(&self) -> Vec<EndpointTest> {
        let mut tests = self.get_integration_test_endpoints();
        tests.extend(vec![
            EndpointTest {
                endpoint: "/api/version".to_string(),
                method: "GET".to_string(),
                headers: None,
                body: None,
                expected_status: Some(200),
            },
            EndpointTest {
                endpoint: "/metrics".to_string(),
                method: "GET".to_string(),
                headers: None,
                body: None,
                expected_status: None,
            },
        ]);
        tests
    }
}

#[derive(Debug)]
struct EndpointTest {
    endpoint: String,
    method: String,
    headers: Option<HashMap<String, String>>,
    body: Option<Value>,
    expected_status: Option<u16>,
}

#[derive(Debug)]
pub struct EndpointTestResult {
    pub endpoint: String,
    pub method: String,
    pub success: bool,
    pub status_code: u16,
    pub duration: u64,
    pub error: Option<String>,
}