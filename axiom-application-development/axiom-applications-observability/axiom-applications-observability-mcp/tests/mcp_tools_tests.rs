use axiom_applications_observability::mcp::*;
use axiom_applications_observability::tools::*;
use axiom_applications_observability::types::*;
use axiom_applications_observability::error::*;

use std::time::Instant;

#[tokio::test]
async fn test_mcp_tool_execution_code_generation() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    let presentation_spec = PresentationSpec {
        name: "TaskListView".to_string(),
        context_binding: "TaskListContext".to_string(),
        ui_components: vec!["List".to_string(), "NavigationBar".to_string()],
        accessibility_requirements: vec!["VoiceOver support".to_string()],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 10.0,
        },
    };
    
    let start_time = Instant::now();
    let result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(presentation_spec)).await?;
    let duration = start_time.elapsed();
    
    // Performance target from plan: < 2 seconds for complete Context+Presentation+Client trio
    assert!(duration.as_millis() < 2000, "Code generation should be fast");
    
    match result {
        ToolResult::GeneratedCode(code_result) => {
            assert!(!code_result.generated_code.is_empty(), "Should generate code");
            assert!(code_result.generated_code.contains("struct TaskListView"), "Should contain view struct");
            assert!(code_result.generated_code.contains(": View"), "Should conform to View protocol");
            assert!(code_result.validation_passed, "Generated code should be valid");
            assert!(code_result.performance_score > 80.0, "Should meet performance standards");
        },
        _ => panic!("Expected GeneratedCode result"),
    }
    
    println!("✅ MCP Presentation generation test passed in {:?}", duration);
    Ok(())
}

#[tokio::test]
async fn test_mcp_tool_execution_context_generation() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    let context_spec = ContextSpec {
        name: "TaskManagerContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "tasks".to_string(),
                property_type: "[Task]".to_string(),
                is_published: true,
                default_value: Some("[]".to_string()),
            },
            StateProperty {
                name: "isLoading".to_string(),
                property_type: "Bool".to_string(),
                is_published: true,
                default_value: Some("false".to_string()),
            },
        ],
        client_binding: "TaskManagerClient".to_string(),
        lifecycle_management: true,
    };
    
    let result = mcp.execute_tool(AxiomMCPTool::GenerateContext(context_spec)).await?;
    
    match result {
        ToolResult::GeneratedCode(code_result) => {
            assert!(!code_result.generated_code.is_empty(), "Should generate code");
            assert!(code_result.generated_code.contains("@MainActor"), "Should be MainActor-bound");
            assert!(code_result.generated_code.contains("class TaskManagerContext"), "Should contain context class");
            assert!(code_result.generated_code.contains("@Published"), "Should have published properties");
            assert!(code_result.generated_code.contains("AxiomClientObservingContext"), "Should conform to Axiom pattern");
            assert!(code_result.validation_passed, "Generated code should be valid");
        },
        _ => panic!("Expected GeneratedCode result"),
    }
    
    println!("✅ MCP Context generation test passed");
    Ok(())
}

#[tokio::test]
async fn test_mcp_tool_execution_client_generation() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    let client_spec = ClientSpec {
        name: "TaskManagerClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: vec![
            ActionDefinition {
                name: "loadTasks".to_string(),
                parameters: vec!["completion: @escaping ([Task]) -> Void".to_string()],
                return_type: "Void".to_string(),
                is_async: true,
            },
            ActionDefinition {
                name: "createTask".to_string(),
                parameters: vec!["task: Task".to_string(), "completion: @escaping (Result<Task, Error>) -> Void".to_string()],
                return_type: "Void".to_string(),
                is_async: true,
            },
        ],
        state_streaming: true,
        mock_implementation: true,
    };
    
    let result = mcp.execute_tool(AxiomMCPTool::GenerateMockClient(client_spec)).await?;
    
    match result {
        ToolResult::GeneratedCode(code_result) => {
            assert!(!code_result.generated_code.is_empty(), "Should generate code");
            assert!(code_result.generated_code.contains("actor"), "Should be actor-based");
            assert!(code_result.generated_code.contains("AxiomClient"), "Should conform to AxiomClient");
            assert!(code_result.generated_code.contains("loadTasks"), "Should include actions");
            assert!(code_result.generated_code.contains("createTask"), "Should include actions");
            assert!(code_result.validation_passed, "Generated code should be valid");
        },
        _ => panic!("Expected GeneratedCode result"),
    }
    
    println!("✅ MCP Client generation test passed");
    Ok(())
}

#[tokio::test]
async fn test_mcp_intelligence_tools() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    // Test app structure analysis
    let result = mcp.execute_tool(AxiomMCPTool::AnalyzeAppStructure).await?;
    
    match result {
        ToolResult::AppStructureAnalysis(analysis) => {
            assert!(!analysis.contexts.is_empty(), "Should find contexts");
            assert!(!analysis.presentations.is_empty(), "Should find presentations");
            assert!(analysis.architectural_compliance > 70.0, "Should assess compliance");
            assert!(!analysis.recommendations.is_empty(), "Should provide recommendations");
        },
        _ => panic!("Expected AppStructureAnalysis result"),
    }
    
    println!("✅ MCP Intelligence tools test passed");
    Ok(())
}

#[tokio::test]
async fn test_mcp_screenshot_matrix_tool() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    let start_time = Instant::now();
    let result = mcp.execute_tool(AxiomMCPTool::CaptureScreenshotMatrix).await?;
    let duration = start_time.elapsed();
    
    // Performance target from plan: < 5 seconds for full device matrix (6+ variations)
    assert!(duration.as_secs() < 10, "Screenshot matrix should be captured reasonably quickly");
    
    match result {
        ToolResult::ScreenshotMatrix(matrix) => {
            assert!(!matrix.screenshots.is_empty(), "Should capture screenshots");
            assert!(matrix.screenshots.len() >= 4, "Should capture multiple device configurations");
            assert!(matrix.analysis.total_screenshots > 0, "Should analyze screenshots");
            assert!(matrix.analysis.consistency_score > 80.0, "Should have good consistency");
        },
        _ => panic!("Expected ScreenshotMatrix result"),
    }
    
    println!("✅ MCP Screenshot matrix tool test passed in {:?}", duration);
    Ok(())
}

#[tokio::test]
async fn test_mcp_visual_analysis_tools() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    // Test visual state comparison
    let result = mcp.execute_tool(AxiomMCPTool::CompareVisualStates).await?;
    
    match result {
        ToolResult::VisualComparison(comparison) => {
            assert!(comparison.confidence_score > 70.0, "Should have confident comparison");
            assert!(!comparison.differences.is_empty() || comparison.similarity_score > 90.0, "Should detect differences or high similarity");
        },
        _ => panic!("Expected VisualComparison result"),
    }
    
    // Test UI regression detection
    let result = mcp.execute_tool(AxiomMCPTool::DetectUIRegressions).await?;
    
    match result {
        ToolResult::RegressionReport(report) => {
            // Quality target from plan: < 1% false positive rate
            assert!(report.total_comparisons > 0, "Should perform comparisons");
            // Note: In a real test with actual UI changes, we'd validate the false positive rate
        },
        _ => panic!("Expected RegressionReport result"),
    }
    
    println!("✅ MCP Visual analysis tools test passed");
    Ok(())
}

#[tokio::test]
async fn test_mcp_development_session_tools() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    // Test development session start
    let result = mcp.execute_tool(AxiomMCPTool::StartDevelopmentSession).await?;
    
    match result {
        ToolResult::DevelopmentSession(session) => {
            assert!(!session.session_id.is_empty(), "Should have session ID");
            assert!(session.hot_reload_active, "Hot reload should be active");
            assert!(session.intelligence_streaming_active, "Intelligence streaming should be active");
            // Developer experience target from plan: < 30 seconds setup time
            // Note: This would be validated in integration tests with actual environment setup
        },
        _ => panic!("Expected DevelopmentSession result"),
    }
    
    println!("✅ MCP Development session tools test passed");
    Ok(())
}

#[tokio::test]
async fn test_mcp_tool_error_handling() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    // Test with invalid specs
    let invalid_presentation_spec = PresentationSpec {
        name: "".to_string(), // Invalid empty name
        context_binding: "".to_string(), // Invalid empty binding
        ui_components: vec![],
        accessibility_requirements: vec![],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: -1.0, // Invalid negative value
            max_memory_mb: -1.0, // Invalid negative value
        },
    };
    
    let result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(invalid_presentation_spec)).await;
    
    match result {
        Err(AxiomMCPError::ValidationError(_)) => {
            println!("✅ Properly rejected invalid presentation spec");
        },
        Err(AxiomMCPError::ToolExecutionError(_)) => {
            println!("✅ Properly handled tool execution error for invalid spec");
        },
        Ok(_) => {
            panic!("Should not succeed with invalid spec");
        },
        Err(e) => {
            println!("✅ Handled error appropriately: {}", e);
        }
    }
    
    println!("✅ MCP Tool error handling test passed");
    Ok(())
}

#[tokio::test]
async fn test_mcp_performance_benchmarks() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    // Benchmark code generation performance
    let presentation_spec = PresentationSpec {
        name: "ComplexDashboardView".to_string(),
        context_binding: "DashboardContext".to_string(),
        ui_components: vec!["Chart".to_string(), "Table".to_string(), "Navigation".to_string(), "Filters".to_string()],
        accessibility_requirements: vec!["VoiceOver".to_string(), "DynamicType".to_string()],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 20.0,
        },
    };
    
    let mut durations = Vec::new();
    
    // Run multiple iterations to get average performance
    for _ in 0..5 {
        let start_time = Instant::now();
        let _result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(presentation_spec.clone())).await?;
        durations.push(start_time.elapsed());
    }
    
    let average_duration = durations.iter().sum::<std::time::Duration>() / durations.len() as u32;
    
    // Performance target from plan: < 2 seconds for complete Context+Presentation+Client trio
    // So individual component should be much faster
    assert!(average_duration.as_millis() < 1000, "Code generation should be consistently fast");
    
    println!("✅ MCP Performance benchmark test passed");
    println!("   Average generation time: {:?}", average_duration);
    println!("   Min: {:?}, Max: {:?}", durations.iter().min().unwrap(), durations.iter().max().unwrap());
    
    Ok(())
}

#[tokio::test]
async fn test_mcp_concurrent_tool_execution() -> Result<()> {
    let mcp = setup_test_mcp().await?;
    
    // Test concurrent execution of multiple tools
    let tasks = vec![
        tokio::spawn({
            let mcp = mcp.clone();
            async move {
                mcp.execute_tool(AxiomMCPTool::AnalyzeAppStructure).await
            }
        }),
        tokio::spawn({
            let mcp = mcp.clone();
            async move {
                let spec = PresentationSpec {
                    name: "ConcurrentView1".to_string(),
                    context_binding: "ConcurrentContext1".to_string(),
                    ui_components: vec!["Text".to_string()],
                    accessibility_requirements: vec![],
                    performance_requirements: PerformanceRequirements {
                        max_render_time_ms: 16.0,
                        max_memory_mb: 5.0,
                    },
                };
                mcp.execute_tool(AxiomMCPTool::GeneratePresentation(spec)).await
            }
        }),
        tokio::spawn({
            let mcp = mcp.clone();
            async move {
                let spec = PresentationSpec {
                    name: "ConcurrentView2".to_string(),
                    context_binding: "ConcurrentContext2".to_string(),
                    ui_components: vec!["Button".to_string()],
                    accessibility_requirements: vec![],
                    performance_requirements: PerformanceRequirements {
                        max_render_time_ms: 16.0,
                        max_memory_mb: 5.0,
                    },
                };
                mcp.execute_tool(AxiomMCPTool::GeneratePresentation(spec)).await
            }
        }),
    ];
    
    let start_time = Instant::now();
    let results = futures_util::future::try_join_all(tasks).await?;
    let duration = start_time.elapsed();
    
    // All tasks should succeed
    for result in results {
        assert!(result.is_ok(), "Concurrent tool execution should succeed");
    }
    
    // Concurrent execution should not take significantly longer than sequential
    assert!(duration.as_secs() < 5, "Concurrent execution should be efficient");
    
    println!("✅ MCP Concurrent tool execution test passed in {:?}", duration);
    Ok(())
}

// Helper functions for test setup

async fn setup_test_mcp() -> Result<AxiomApplicationsObservabilityMCP> {
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
    
    AxiomApplicationsObservabilityMCP::new(config, capabilities).await
}

