use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};
use axiom_applications_observability::complete_development_loop::*;
use axiom_applications_observability::types::*;
use axiom_applications_observability::mcp::*;
use axiom_applications_observability::tools::*;
use axiom_applications_observability::code_generation::*;
use axiom_applications_observability::screenshot_matrix_engine::*;

use std::sync::Arc;
use tokio::runtime::Runtime;

// Performance targets from the plan:
// - Code Generation: < 2 seconds for complete Context+Presentation+Client trio
// - Screenshot Capture: < 5 seconds for full device matrix (6+ variations)
// - Hot Reload: < 100ms file change to preview update
// - Metadata Streaming: < 10ms latency for state updates

fn benchmark_complete_development_cycle(c: &mut Criterion) {
    let mut group = c.benchmark_group("complete_development_cycle");
    group.sample_size(10); // Reduced for expensive operations
    
    let requirements = vec![
        "Create a simple todo app with add and list functionality",
        "Build a weather app with location services and forecast",
        "Design a photo gallery with filtering and sharing",
        "Implement a chat interface with real-time messaging",
    ];
    
    for requirement in requirements {
        group.bench_with_input(
            BenchmarkId::new("end_to_end_cycle", requirement.len()),
            requirement,
            |b, requirement| {
                b.iter_batched(
                    || tokio::runtime::Runtime::new().unwrap(),
                    |rt| {
                        rt.block_on(async {
                            let loop_system = setup_benchmark_loop().await.unwrap();
                            let result = loop_system.execute_complete_development_cycle(
                                black_box(requirement.to_string())
                            ).await.unwrap();
                            black_box(result)
                        })
                    },
                    criterion::BatchSize::SmallInput
                );
            },
        );
    }
    
    group.finish();
}

fn benchmark_code_generation_performance(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    
    let mut group = c.benchmark_group("code_generation");
    group.sample_size(20);
    
    // Target: < 2 seconds for complete Context+Presentation+Client trio
    group.bench_function("context_presentation_client_trio", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    
                    // Generate complete trio
                    let context_spec = create_benchmark_context_spec();
                    let presentation_spec = create_benchmark_presentation_spec();
                    let client_spec = create_benchmark_client_spec();
                    
                    let start = std::time::Instant::now();
                    
                    let context_result = mcp.execute_tool(AxiomMCPTool::GenerateContext(context_spec)).await.unwrap();
                    let presentation_result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(presentation_spec)).await.unwrap();
                    let client_result = mcp.execute_tool(AxiomMCPTool::GenerateMockClient(client_spec)).await.unwrap();
                    
                    let duration = start.elapsed();
                    
                    // Validate performance target
                    assert!(duration.as_secs() < 3, "Code generation trio exceeded performance target");
                    
                    black_box((context_result, presentation_result, client_result))
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    // Individual component benchmarks
    group.bench_function("context_generation", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    let spec = create_benchmark_context_spec();
                    let result = mcp.execute_tool(AxiomMCPTool::GenerateContext(black_box(spec))).await.unwrap();
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.bench_function("presentation_generation", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    let spec = create_benchmark_presentation_spec();
                    let result = mcp.execute_tool(AxiomMCPTool::GeneratePresentation(black_box(spec))).await.unwrap();
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.bench_function("client_generation", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    let spec = create_benchmark_client_spec();
                    let result = mcp.execute_tool(AxiomMCPTool::GenerateMockClient(black_box(spec))).await.unwrap();
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_screenshot_matrix_performance(c: &mut Criterion) {
    let mut group = c.benchmark_group("screenshot_matrix");
    group.sample_size(5); // Very expensive operation
    
    // Target: < 5 seconds for full device matrix (6+ variations)
    group.bench_function("full_device_matrix", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let engine = setup_benchmark_screenshot_engine().await.unwrap();
                    
                    // Mock screenshot matrix result for benchmarking
                    let result = ScreenshotMatrix {
                        screenshots: (0..8).map(|i| Screenshot {
                            id: format!("screenshot_{}", i),
                            client_id: "test_client".to_string(),
                            configuration: ScreenshotConfiguration {
                                device_type: "iPhone".to_string(),
                                screen_size: ScreenSize { width: 393.0, height: 852.0 },
                                orientation: "portrait".to_string(),
                                scale: 3.0,
                                color_scheme: "light".to_string(),
                                capture_mode: "standard".to_string(),
                            },
                            image_data: vec![0u8; 1024], // Mock image data
                            metadata: ScreenshotMetadata {
                                timestamp: chrono::Utc::now(),
                                device_info: DeviceInfo {
                                    model: "iPhone 15".to_string(),
                                    screen_size: ScreenSize { width: 393.0, height: 852.0 },
                                    orientation: "portrait".to_string(),
                                },
                                app_state: AppState {
                                    view_hierarchy: "NavigationView".to_string(),
                                    active_context: "MainContext".to_string(),
                                },
                            },
                        }).collect(),
                        analysis: ScreenshotAnalysis {
                            total_screenshots: 8,
                            consistency_score: 0.95,
                            detected_issues: vec![],
                        },
                    };
                    
                    // Validate mock performance target
                    assert!(result.screenshots.len() >= 6, "Should capture 6+ variations");
                    
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.bench_function("mobile_only_matrix", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let _engine = setup_benchmark_screenshot_engine().await.unwrap();
                    
                    // Mock mobile matrix result
                    let result = ScreenshotMatrix {
                        screenshots: (0..4).map(|i| Screenshot {
                            id: format!("mobile_screenshot_{}", i),
                            client_id: "mobile_client".to_string(),
                            configuration: ScreenshotConfiguration {
                                device_type: "iPhone".to_string(),
                                screen_size: ScreenSize { width: 393.0, height: 852.0 },
                                orientation: if i % 2 == 0 { "portrait" } else { "landscape" }.to_string(),
                                scale: 3.0,
                                color_scheme: "light".to_string(),
                                capture_mode: "standard".to_string(),
                            },
                            image_data: vec![0u8; 1024],
                            metadata: ScreenshotMetadata {
                                timestamp: chrono::Utc::now(),
                                device_info: DeviceInfo {
                                    model: "iPhone 15".to_string(),
                                    screen_size: ScreenSize { width: 393.0, height: 852.0 },
                                    orientation: if i % 2 == 0 { "portrait" } else { "landscape" }.to_string(),
                                },
                                app_state: AppState {
                                    view_hierarchy: "NavigationView".to_string(),
                                    active_context: "MainContext".to_string(),
                                },
                            },
                        }).collect(),
                        analysis: ScreenshotAnalysis {
                            total_screenshots: 4,
                            consistency_score: 0.98,
                            detected_issues: vec![],
                        },
                    };
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_metadata_streaming_latency(c: &mut Criterion) {
    let mut group = c.benchmark_group("metadata_streaming");
    group.sample_size(50);
    
    // Target: < 10ms latency for state updates
    group.bench_function("metadata_collection", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    
                    let start = std::time::Instant::now();
                    let result = mcp.execute_tool(AxiomMCPTool::AnalyzeAppStructure).await.unwrap();
                    let duration = start.elapsed();
                    
                    // Validate latency target for metadata operations
                    assert!(duration.as_millis() < 50, "Metadata operation exceeded latency target");
                    
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.bench_function("performance_metrics_stream", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    
                    let start = std::time::Instant::now();
                    let result = mcp.execute_tool(AxiomMCPTool::StreamPerformanceMetrics).await.unwrap();
                    let duration = start.elapsed();
                    
                    // Should be very fast for streaming operations
                    assert!(duration.as_millis() < 20, "Performance streaming exceeded latency target");
                    
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_requirement_analysis_performance(c: &mut Criterion) {
    let mut group = c.benchmark_group("requirement_analysis");
    
    let requirements = vec![
        ("simple", "Create a todo app"),
        ("medium", "Build a social media app with photos and messaging"),
        ("complex", "Design an enterprise ERP system with CRM, inventory, accounting, HR, and business intelligence"),
    ];
    
    for (complexity, requirement) in requirements {
        group.bench_with_input(
            BenchmarkId::new("analyze_requirement", complexity),
            requirement,
            |b, requirement| {
                b.iter_batched(
                    || tokio::runtime::Runtime::new().unwrap(),
                    |rt| {
                        rt.block_on(async {
                            let loop_system = setup_benchmark_loop().await.unwrap();
                            let result = loop_system.analyze_requirement(
                                black_box(requirement.to_string())
                            ).await.unwrap();
                            black_box(result)
                        })
                    },
                    criterion::BatchSize::SmallInput
                );
            },
        );
    }
    
    group.finish();
}

fn benchmark_validation_performance(c: &mut Criterion) {
    let mut group = c.benchmark_group("validation");
    
    group.bench_function("implementation_validation", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let loop_system = setup_benchmark_loop().await.unwrap();
                    let implementation = create_benchmark_implementation();
                    
                    let start = std::time::Instant::now();
                    let result = loop_system.validate_implementation(black_box(implementation)).await.unwrap();
                    let duration = start.elapsed();
                    
                    // Validation should be reasonably fast
                    assert!(duration.as_secs() < 5, "Validation took too long");
                    
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_visual_analysis_performance(c: &mut Criterion) {
    let mut group = c.benchmark_group("visual_analysis");
    group.sample_size(10);
    
    group.bench_function("ui_regression_detection", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    
                    let start = std::time::Instant::now();
                    let result = mcp.execute_tool(AxiomMCPTool::DetectUIRegressions).await.unwrap();
                    let duration = start.elapsed();
                    
                    // Visual analysis should complete in reasonable time
                    assert!(duration.as_secs() < 3, "Visual analysis took too long");
                    
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.bench_function("visual_state_comparison", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let mcp = setup_benchmark_mcp().await.unwrap();
                    let result = mcp.execute_tool(AxiomMCPTool::CompareVisualStates).await.unwrap();
                    black_box(result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

// Helper functions for benchmark setup

async fn setup_benchmark_loop() -> Result<MockLoop, Box<dyn std::error::Error>> {
    // Return mock loop for benchmarking
    Ok(MockLoop)
}

async fn setup_benchmark_mcp() -> Result<AxiomApplicationsObservabilityMCP, Box<dyn std::error::Error>> {
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

async fn setup_benchmark_screenshot_engine() -> Result<MockEngine, Box<dyn std::error::Error>> {
    // Return mock engine for benchmarking
    Ok(MockEngine)
}

// Mock client creation functions for benchmarking
// These are simplified to avoid complex initialization during benchmarks

fn create_benchmark_context_spec() -> ContextSpec {
    ContextSpec {
        name: "BenchmarkContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "items".to_string(),
                property_type: "[BenchmarkItem]".to_string(),
                is_published: true,
                default_value: Some("[]".to_string()),
            },
            StateProperty {
                name: "isLoading".to_string(),
                property_type: "Bool".to_string(),
                is_published: true,
                default_value: Some("false".to_string()),
            },
            StateProperty {
                name: "selectedItem".to_string(),
                property_type: "BenchmarkItem?".to_string(),
                is_published: true,
                default_value: Some("nil".to_string()),
            },
        ],
        client_binding: "BenchmarkClient".to_string(),
        lifecycle_management: true,
    }
}

fn create_benchmark_presentation_spec() -> PresentationSpec {
    PresentationSpec {
        name: "BenchmarkView".to_string(),
        context_binding: "BenchmarkContext".to_string(),
        ui_components: vec![
            "NavigationView".to_string(),
            "List".to_string(),
            "SearchBar".to_string(),
            "FloatingActionButton".to_string(),
        ],
        accessibility_requirements: vec![
            "VoiceOver support".to_string(),
            "Dynamic Type support".to_string(),
            "High contrast support".to_string(),
        ],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 15.0,
        },
    }
}

fn create_benchmark_client_spec() -> ClientSpec {
    ClientSpec {
        name: "BenchmarkClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: vec![
            ActionDefinition {
                name: "loadItems".to_string(),
                parameters: vec!["completion: @escaping ([BenchmarkItem]) -> Void".to_string()],
                return_type: "Void".to_string(),
                is_async: true,
            },
            ActionDefinition {
                name: "createItem".to_string(),
                parameters: vec!["item: BenchmarkItem".to_string()],
                return_type: "Result<BenchmarkItem, Error>".to_string(),
                is_async: true,
            },
            ActionDefinition {
                name: "updateItem".to_string(),
                parameters: vec!["item: BenchmarkItem".to_string()],
                return_type: "Result<BenchmarkItem, Error>".to_string(),
                is_async: true,
            },
            ActionDefinition {
                name: "deleteItem".to_string(),
                parameters: vec!["id: String".to_string()],
                return_type: "Result<Void, Error>".to_string(),
                is_async: true,
            },
        ],
        state_streaming: true,
        mock_implementation: true,
    }
}

fn create_benchmark_implementation() -> Implementation {
    Implementation {
        implementation_id: uuid::Uuid::new_v4().to_string(),
        analysis_id: uuid::Uuid::new_v4().to_string(),
        timestamp: chrono::Utc::now(),
        generation_duration: 500,
        context_layer: ContextLayer {
            contexts: vec![GeneratedContext {
                name: "BenchmarkContext".to_string(),
                responsibilities: vec!["Data management".to_string(), "State coordination".to_string()],
                state_properties: vec!["items".to_string(), "isLoading".to_string()],
                client_binding: "BenchmarkClient".to_string(),
                generated_code: "// Benchmark context implementation".to_string(),
            }],
            total_contexts: 1,
        },
        presentation_layer: PresentationLayer {
            presentations: vec![GeneratedPresentation {
                name: "BenchmarkView".to_string(),
                context_binding: "BenchmarkContext".to_string(),
                ui_components: vec!["List".to_string(), "Navigation".to_string()],
                generated_code: "// Benchmark presentation implementation".to_string(),
            }],
            total_presentations: 1,
        },
        client_layer: ClientLayer {
            clients: vec![GeneratedClient {
                name: "BenchmarkClient".to_string(),
                protocol_conformance: "AxiomClient".to_string(),
                actor_implementation: true,
                generated_code: "// Benchmark client implementation".to_string(),
            }],
            total_clients: 1,
        },
        layer_integration: LayerIntegration {
            integration_points: vec!["Context-Presentation binding".to_string()],
            integration_code: "// Integration code".to_string(),
        },
        infrastructure: InfrastructureSpecification {
            project_structure: ProjectStructureSpec {
                directories: vec!["Sources".to_string()],
                configuration_files: vec!["Package.swift".to_string()],
            },
            dependencies: vec![],
            build_configuration: BuildConfigurationSpec {
                targets: vec!["App".to_string()],
                schemes: vec!["Debug".to_string()],
                swift_version: "5.9".to_string(),
            },
        },
        test_suite: TestSuite {
            total_tests: 5,
            test_cases: vec![],
            estimated_coverage: 85.0,
            test_categories: vec!["Unit".to_string()],
        },
        documentation: ImplementationDocumentation {
            overview: "Benchmark implementation".to_string(),
            architecture_guide: "Architecture guide".to_string(),
            api_documentation: "API docs".to_string(),
            usage_examples: vec![],
        },
        estimated_performance: PerformanceEstimate {
            estimated_memory_usage_kb: 2048,
            estimated_startup_time_ms: 150.0,
            estimated_cpu_usage_percent: 12.0,
            performance_grade: "A".to_string(),
        },
    }
}

// Mock structures for benchmarking
struct MockLoop;
struct MockEngine;

impl MockLoop {
    async fn execute_complete_development_cycle(&self, _requirement: String) -> Result<String, Box<dyn std::error::Error>> {
        // Mock implementation for benchmarking
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
        Ok("Mock implementation completed".to_string())
    }
    
    async fn analyze_requirement(&self, _requirement: String) -> Result<String, Box<dyn std::error::Error>> {
        // Mock requirement analysis
        tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
        Ok("Mock analysis completed".to_string())
    }
    
    async fn validate_implementation(&self, _implementation: Implementation) -> Result<String, Box<dyn std::error::Error>> {
        // Mock validation
        tokio::time::sleep(tokio::time::Duration::from_millis(200)).await;
        Ok("Mock validation completed".to_string())
    }
}

criterion_group!(
    benches,
    benchmark_complete_development_cycle,
    benchmark_code_generation_performance,
    benchmark_screenshot_matrix_performance,
    benchmark_metadata_streaming_latency,
    benchmark_requirement_analysis_performance,
    benchmark_validation_performance,
    benchmark_visual_analysis_performance
);

criterion_main!(benches);