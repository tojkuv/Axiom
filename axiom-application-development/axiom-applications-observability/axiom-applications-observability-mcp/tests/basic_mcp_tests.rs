use axiom_applications_observability::*;

#[tokio::test]
async fn test_mcp_initialization() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let config = MCPConfiguration {
        hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
        intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
        simulator_management_enabled: true,
        code_generation_enabled: true,
        visual_analysis_enabled: true,
        performance_monitoring_enabled: true,
    };
    
    let capabilities = MCPCapabilities {
        code_generation: true,
        intelligence_analysis: true,
        hot_reload_integration: true,
        visual_analysis: true,
        simulator_management: true,
        performance_monitoring: true,
    };
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    // Test that we can get stats
    let stats = mcp.get_stats().await;
    assert_eq!(stats.active_sessions, 0);
    assert_eq!(stats.total_operations, 0);
    
    println!("✅ MCP initialization test passed");
    Ok(())
}

#[tokio::test]
async fn test_presentation_generation() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let config = MCPConfiguration {
        hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
        intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
        simulator_management_enabled: true,
        code_generation_enabled: true,
        visual_analysis_enabled: true,
        performance_monitoring_enabled: true,
    };
    
    let capabilities = MCPCapabilities {
        code_generation: true,
        intelligence_analysis: true,
        hot_reload_integration: true,
        visual_analysis: true,
        simulator_management: true,
        performance_monitoring: true,
    };
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    let presentation_spec = PresentationSpec {
        name: "TestView".to_string(),
        context_binding: "TestContext".to_string(),
        ui_components: vec!["Text(\"Hello\")".to_string()],
        accessibility_requirements: vec![],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 10.0,
        },
    };
    
    let result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(presentation_spec)).await?;
    
    match result {
        ToolResult::GeneratedCode(code) => {
            assert!(!code.generated_code.is_empty());
            assert!(code.generated_code.contains("struct TestView"));
            assert!(code.generated_code.contains(": View"));
            assert!(code.validation_passed);
            println!("✅ Presentation generation test passed");
        },
        _ => panic!("Expected GeneratedCode result"),
    }
    
    Ok(())
}

#[tokio::test]
async fn test_context_generation() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let config = MCPConfiguration {
        hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
        intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
        simulator_management_enabled: true,
        code_generation_enabled: true,
        visual_analysis_enabled: true,
        performance_monitoring_enabled: true,
    };
    
    let capabilities = MCPCapabilities {
        code_generation: true,
        intelligence_analysis: true,
        hot_reload_integration: true,
        visual_analysis: true,
        simulator_management: true,
        performance_monitoring: true,
    };
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    let context_spec = ContextSpec {
        name: "TestContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "message".to_string(),
                property_type: "String".to_string(),
                is_published: true,
                default_value: Some("\"Hello\"".to_string()),
            }
        ],
        client_binding: "TestClient".to_string(),
        lifecycle_management: true,
    };
    
    let result = mcp.execute_tool(AxiomMCPTool::GenerateContext(context_spec)).await?;
    
    match result {
        ToolResult::GeneratedCode(code) => {
            assert!(!code.generated_code.is_empty());
            assert!(code.generated_code.contains("@MainActor"));
            assert!(code.generated_code.contains("class TestContext"));
            assert!(code.generated_code.contains("@Published"));
            assert!(code.validation_passed);
            println!("✅ Context generation test passed");
        },
        _ => panic!("Expected GeneratedCode result"),
    }
    
    Ok(())
}

#[tokio::test]
async fn test_client_generation() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let config = MCPConfiguration {
        hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
        intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
        simulator_management_enabled: true,
        code_generation_enabled: true,
        visual_analysis_enabled: true,
        performance_monitoring_enabled: true,
    };
    
    let capabilities = MCPCapabilities {
        code_generation: true,
        intelligence_analysis: true,
        hot_reload_integration: true,
        visual_analysis: true,
        simulator_management: true,
        performance_monitoring: true,
    };
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    let client_spec = ClientSpec {
        name: "TestClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: vec![
            ActionDefinition {
                name: "fetchData".to_string(),
                parameters: vec![],
                return_type: "String".to_string(),
                is_async: true,
            }
        ],
        state_streaming: true,
        mock_implementation: true,
    };
    
    let result = mcp.execute_tool(AxiomMCPTool::GenerateMockClient(client_spec)).await?;
    
    match result {
        ToolResult::GeneratedCode(code) => {
            assert!(!code.generated_code.is_empty());
            assert!(code.generated_code.contains("actor TestClient"));
            assert!(code.generated_code.contains("AxiomClient"));
            assert!(code.generated_code.contains("fetchData"));
            assert!(code.validation_passed);
            println!("✅ Client generation test passed");
        },
        _ => panic!("Expected GeneratedCode result"),
    }
    
    Ok(())
}

#[tokio::test]
async fn test_architecture_validation() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let config = MCPConfiguration {
        hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
        intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
        simulator_management_enabled: true,
        code_generation_enabled: true,
        visual_analysis_enabled: true,
        performance_monitoring_enabled: true,
    };
    
    let capabilities = MCPCapabilities {
        code_generation: true,
        intelligence_analysis: true,
        hot_reload_integration: true,
        visual_analysis: true,
        simulator_management: true,
        performance_monitoring: true,
    };
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    let result = mcp.execute_tool(AxiomMCPTool::ValidateArchitecture).await?;
    
    match result {
        ToolResult::ValidationResult(validation) => {
            assert!(validation.passed);
            assert!(validation.overall_score > 80.0);
            assert!(validation.architecture_compliance > 90.0);
            println!("✅ Architecture validation test passed");
        },
        _ => panic!("Expected ValidationResult"),
    }
    
    Ok(())
}

#[tokio::test]
async fn test_performance_targets() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let config = MCPConfiguration {
        hot_reload_server_url: "ws://localhost:8080/ws".to_string(),
        intelligence_server_url: "ws://localhost:8080/intelligence".to_string(),
        simulator_management_enabled: true,
        code_generation_enabled: true,
        visual_analysis_enabled: true,
        performance_monitoring_enabled: true,
    };
    
    let capabilities = MCPCapabilities {
        code_generation: true,
        intelligence_analysis: true,
        hot_reload_integration: true,
        visual_analysis: true,
        simulator_management: true,
        performance_monitoring: true,
    };
    
    let mcp = AxiomApplicationsObservabilityMCP::new(config, capabilities).await?;
    
    // Test code generation performance - Target: < 2 seconds for trio
    let start_time = std::time::Instant::now();
    
    let presentation_spec = PresentationSpec {
        name: "PerformanceTestView".to_string(),
        context_binding: "PerformanceTestContext".to_string(),
        ui_components: vec!["Text(\"Performance Test\")".to_string()],
        accessibility_requirements: vec![],
        performance_requirements: PerformanceRequirements::default(),
    };
    
    let context_spec = ContextSpec {
        name: "PerformanceTestContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "value".to_string(),
                property_type: "Int".to_string(),
                is_published: true,
                default_value: Some("0".to_string()),
            }
        ],
        client_binding: "PerformanceTestClient".to_string(),
        lifecycle_management: true,
    };
    
    let client_spec = ClientSpec {
        name: "PerformanceTestClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: vec![
            ActionDefinition {
                name: "performAction".to_string(),
                parameters: vec![],
                return_type: "Void".to_string(),
                is_async: true,
            }
        ],
        state_streaming: true,
        mock_implementation: true,
    };
    
    // Generate trio
    let _presentation_result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(presentation_spec)).await?;
    let _context_result = mcp.execute_tool(AxiomMCPTool::GenerateContext(context_spec)).await?;
    let _client_result = mcp.execute_tool(AxiomMCPTool::GenerateMockClient(client_spec)).await?;
    
    let generation_time = start_time.elapsed();
    
    // Plan target: < 2 seconds for complete trio
    assert!(generation_time.as_millis() < 2000, 
        "Code generation trio exceeded target: {:?} > 2000ms", generation_time);
    
    println!("✅ Performance target test passed: {:?} < 2000ms", generation_time);
    
    Ok(())
}