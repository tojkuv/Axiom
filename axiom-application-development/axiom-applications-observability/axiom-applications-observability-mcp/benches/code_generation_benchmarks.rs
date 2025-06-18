use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId, Throughput};
use axiom_applications_observability::code_generation::*;
use axiom_applications_observability::types::*;
use std::collections::HashMap;
use tokio::runtime::Runtime;

// Specific benchmarks for code generation performance targets:
// Target: < 2 seconds for complete Context+Presentation+Client trio
// Quality target: 100% generated code passes validation

fn benchmark_axiom_code_generator_initialization(c: &mut Criterion) {
    c.bench_function("code_generator_init", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let generator = AxiomCodeGenerator::new().await.unwrap();
                    black_box(generator)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
}

fn benchmark_presentation_generation_by_complexity(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    
    let mut group = c.benchmark_group("presentation_generation");
    
    let test_cases = vec![
        ("simple", create_simple_presentation_spec()),
        ("medium", create_medium_presentation_spec()),
        ("complex", create_complex_presentation_spec()),
        ("enterprise", create_enterprise_presentation_spec()),
    ];
    
    for (complexity, spec) in test_cases {
        group.throughput(Throughput::Elements(spec.ui_components.len() as u64));
        
        group.bench_with_input(
            BenchmarkId::new("generate_presentation", complexity),
            &spec,
            |b, spec| {
                b.iter_batched(
                    || tokio::runtime::Runtime::new().unwrap(),
                    |rt| {
                        rt.block_on(async {
                            let generator = AxiomCodeGenerator::new().await.unwrap();
                            let result = generator.generate_presentation(black_box(spec.clone())).await.unwrap();
                            
                            // Validate quality target: generated code should pass validation
                            assert!(!result.generated_code.is_empty(), "Should generate non-empty code");
                            assert!(result.generated_code.contains("struct"), "Should contain struct definition");
                            assert!(result.generated_code.contains(": View"), "Should conform to View protocol");
                            
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

fn benchmark_context_generation_by_complexity(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    
    let mut group = c.benchmark_group("context_generation");
    
    let test_cases = vec![
        ("simple", create_simple_context_spec()),
        ("medium", create_medium_context_spec()),
        ("complex", create_complex_context_spec()),
        ("enterprise", create_enterprise_context_spec()),
    ];
    
    for (complexity, spec) in test_cases {
        group.throughput(Throughput::Elements(spec.state_properties.len() as u64));
        
        group.bench_with_input(
            BenchmarkId::new("generate_context", complexity),
            &spec,
            |b, spec| {
                b.iter_batched(
                    || tokio::runtime::Runtime::new().unwrap(),
                    |rt| {
                        rt.block_on(async {
                            let generator = AxiomCodeGenerator::new().await.unwrap();
                            let result = generator.generate_context(black_box(spec.clone())).await.unwrap();
                            
                            // Validate quality targets
                            assert!(!result.generated_code.is_empty(), "Should generate non-empty code");
                            assert!(result.generated_code.contains("@MainActor"), "Should be MainActor-bound");
                            assert!(result.generated_code.contains("class"), "Should contain class definition");
                            assert!(result.generated_code.contains("AxiomClientObservingContext"), "Should conform to Axiom pattern");
                            
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

fn benchmark_client_generation_by_complexity(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    
    let mut group = c.benchmark_group("client_generation");
    
    let test_cases = vec![
        ("simple", create_simple_client_spec()),
        ("medium", create_medium_client_spec()),
        ("complex", create_complex_client_spec()),
        ("enterprise", create_enterprise_client_spec()),
    ];
    
    for (complexity, spec) in test_cases {
        group.throughput(Throughput::Elements(spec.actions.len() as u64));
        
        group.bench_with_input(
            BenchmarkId::new("generate_client", complexity),
            &spec,
            |b, spec| {
                b.iter_batched(
                    || tokio::runtime::Runtime::new().unwrap(),
                    |rt| {
                        rt.block_on(async {
                            let generator = AxiomCodeGenerator::new().await.unwrap();
                            let result = generator.generate_mock_client(black_box(spec.clone())).await.unwrap();
                            
                            // Validate quality targets
                            assert!(!result.generated_code.is_empty(), "Should generate non-empty code");
                            assert!(result.generated_code.contains("actor"), "Should be actor-based");
                            assert!(result.generated_code.contains("AxiomClient"), "Should conform to AxiomClient");
                            
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

fn benchmark_complete_trio_generation(c: &mut Criterion) {
    let mut group = c.benchmark_group("complete_trio");
    group.sample_size(10); // Expensive operation
    
    // Primary target: < 2 seconds for complete Context+Presentation+Client trio
    group.bench_function("context_presentation_client_trio", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let generator = AxiomCodeGenerator::new().await.unwrap();
                    
                    let context_spec = create_medium_context_spec();
                    let presentation_spec = create_medium_presentation_spec();
                    let client_spec = create_medium_client_spec();
                    
                    let start = std::time::Instant::now();
                    
                    // Generate complete trio
                    let context_result = generator.generate_context(black_box(context_spec)).await.unwrap();
                    let presentation_result = generator.generate_presentation(black_box(presentation_spec)).await.unwrap();
                    let client_result = generator.generate_mock_client(black_box(client_spec)).await.unwrap();
                    
                    let duration = start.elapsed();
                    
                    // Validate performance target
                    if duration.as_secs() >= 2 {
                        eprintln!("⚠️  WARNING: Code generation trio took {:?}, exceeding 2-second target", duration);
                    }
                    
                    // Validate quality
                    assert!(!context_result.generated_code.is_empty(), "Context should generate code");
                    assert!(!presentation_result.generated_code.is_empty(), "Presentation should generate code");
                    assert!(!client_result.generated_code.is_empty(), "Client should generate code");
                    
                    black_box((context_result, presentation_result, client_result))
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_parallel_generation(c: &mut Criterion) {
    let mut group = c.benchmark_group("parallel_generation");
    group.sample_size(10);
    
    group.bench_function("parallel_trio_generation", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let generator = AxiomCodeGenerator::new().await.unwrap();
                    
                    let context_spec = create_medium_context_spec();
                    let presentation_spec = create_medium_presentation_spec();
                    let client_spec = create_medium_client_spec();
                    
                    let start = std::time::Instant::now();
                    
                    // Generate in parallel
                    let (context_result, presentation_result, client_result) = tokio::join!(
                        generator.generate_context(black_box(context_spec)),
                        generator.generate_presentation(black_box(presentation_spec)),
                        generator.generate_mock_client(black_box(client_spec))
                    );
                    
                    let duration = start.elapsed();
                    
                    // Parallel should be faster than sequential
                    if duration.as_secs() >= 1 {
                        eprintln!("⚠️  WARNING: Parallel generation took {:?}", duration);
                    }
                    
                    let context_result = context_result.unwrap();
                    let presentation_result = presentation_result.unwrap();
                    let client_result = client_result.unwrap();
                    
                    black_box((context_result, presentation_result, client_result))
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_code_validation_performance(c: &mut Criterion) {
    let mut group = c.benchmark_group("code_validation");
    
    group.bench_function("validate_generated_code", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    let generator = AxiomCodeGenerator::new().await.unwrap();
                    let spec = create_medium_presentation_spec();
                    let result = generator.generate_presentation(spec).await.unwrap();
                    
                    // Benchmark the validation process
                    let start = std::time::Instant::now();
                    let validation_result = generator.validate_generated_code(&result.generated_code).await.unwrap();
                    let duration = start.elapsed();
                    
                    // Validation should be fast
                    assert!(duration.as_millis() < 100, "Code validation should be very fast");
                    
                    black_box(validation_result)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

fn benchmark_template_processing_performance(c: &mut Criterion) {
    
    let mut group = c.benchmark_group("template_processing");
    
    let template_sizes = vec![
        ("small", 100),
        ("medium", 500),
        ("large", 1000),
        ("xlarge", 2000),
    ];
    
    for (size_name, lines) in template_sizes {
        group.bench_with_input(
            BenchmarkId::new("process_template", size_name),
            &lines,
            |b, &lines| {
                b.iter_batched(
                    || tokio::runtime::Runtime::new().unwrap(),
                    |rt| {
                        rt.block_on(async {
                            let generator = AxiomCodeGenerator::new().await.unwrap();
                            let template_data = create_template_data_with_size(lines);
                            
                            let result = generator.process_template("presentation", &template_data).await.unwrap();
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

fn benchmark_memory_usage_during_generation(c: &mut Criterion) {
    let mut group = c.benchmark_group("memory_usage");
    
    group.bench_function("memory_efficient_generation", |b| {
        b.iter_batched(
            || tokio::runtime::Runtime::new().unwrap(),
            |rt| {
                rt.block_on(async {
                    // Generate many components to test memory efficiency
                    let generator = AxiomCodeGenerator::new().await.unwrap();
                    
                    let mut results = Vec::new();
                    
                    for i in 0..10 {
                        let spec = create_dynamic_presentation_spec(i);
                        let result = generator.generate_presentation(black_box(spec)).await.unwrap();
                        results.push(result);
                    }
                    
                    // Verify all generations succeeded
                    assert_eq!(results.len(), 10, "Should generate all 10 components");
                    
                    black_box(results)
                })
            },
            criterion::BatchSize::SmallInput
        );
    });
    
    group.finish();
}

// Helper functions to create test specifications

fn create_simple_presentation_spec() -> PresentationSpec {
    PresentationSpec {
        name: "SimpleView".to_string(),
        context_binding: "SimpleContext".to_string(),
        ui_components: vec!["Text".to_string()],
        accessibility_requirements: vec![],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 5.0,
        },
    }
}

fn create_medium_presentation_spec() -> PresentationSpec {
    PresentationSpec {
        name: "MediumView".to_string(),
        context_binding: "MediumContext".to_string(),
        ui_components: vec![
            "NavigationView".to_string(),
            "List".to_string(),
            "SearchBar".to_string(),
            "Button".to_string(),
        ],
        accessibility_requirements: vec!["VoiceOver".to_string()],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 10.0,
        },
    }
}

fn create_complex_presentation_spec() -> PresentationSpec {
    PresentationSpec {
        name: "ComplexView".to_string(),
        context_binding: "ComplexContext".to_string(),
        ui_components: vec![
            "TabView".to_string(),
            "NavigationView".to_string(),
            "List".to_string(),
            "LazyVGrid".to_string(),
            "SearchBar".to_string(),
            "FilterBar".to_string(),
            "FloatingActionButton".to_string(),
            "ProgressView".to_string(),
        ],
        accessibility_requirements: vec![
            "VoiceOver".to_string(),
            "DynamicType".to_string(),
            "HighContrast".to_string(),
        ],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 20.0,
        },
    }
}

fn create_enterprise_presentation_spec() -> PresentationSpec {
    PresentationSpec {
        name: "EnterpriseView".to_string(),
        context_binding: "EnterpriseContext".to_string(),
        ui_components: vec![
            "SplitView".to_string(),
            "Sidebar".to_string(),
            "DetailView".to_string(),
            "Toolbar".to_string(),
            "MenuBar".to_string(),
            "DataTable".to_string(),
            "Chart".to_string(),
            "Dashboard".to_string(),
            "FilterPanel".to_string(),
            "ExportPanel".to_string(),
            "NotificationCenter".to_string(),
            "ContextualMenu".to_string(),
        ],
        accessibility_requirements: vec![
            "VoiceOver".to_string(),
            "DynamicType".to_string(),
            "HighContrast".to_string(),
            "ReducedMotion".to_string(),
            "KeyboardNavigation".to_string(),
        ],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 50.0,
        },
    }
}

fn create_simple_context_spec() -> ContextSpec {
    ContextSpec {
        name: "SimpleContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "text".to_string(),
                property_type: "String".to_string(),
                is_published: true,
                default_value: Some("\"\"".to_string()),
            },
        ],
        client_binding: "SimpleClient".to_string(),
        lifecycle_management: false,
    }
}

fn create_medium_context_spec() -> ContextSpec {
    ContextSpec {
        name: "MediumContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "items".to_string(),
                property_type: "[Item]".to_string(),
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
                name: "searchText".to_string(),
                property_type: "String".to_string(),
                is_published: true,
                default_value: Some("\"\"".to_string()),
            },
        ],
        client_binding: "MediumClient".to_string(),
        lifecycle_management: true,
    }
}

fn create_complex_context_spec() -> ContextSpec {
    ContextSpec {
        name: "ComplexContext".to_string(),
        state_properties: vec![
            StateProperty {
                name: "data".to_string(),
                property_type: "[DataModel]".to_string(),
                is_published: true,
                default_value: Some("[]".to_string()),
            },
            StateProperty {
                name: "filteredData".to_string(),
                property_type: "[DataModel]".to_string(),
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
                name: "error".to_string(),
                property_type: "Error?".to_string(),
                is_published: true,
                default_value: Some("nil".to_string()),
            },
            StateProperty {
                name: "selectedItems".to_string(),
                property_type: "Set<DataModel.ID>".to_string(),
                is_published: true,
                default_value: Some("[]".to_string()),
            },
            StateProperty {
                name: "filters".to_string(),
                property_type: "FilterConfiguration".to_string(),
                is_published: true,
                default_value: Some("FilterConfiguration()".to_string()),
            },
        ],
        client_binding: "ComplexClient".to_string(),
        lifecycle_management: true,
    }
}

fn create_enterprise_context_spec() -> ContextSpec {
    ContextSpec {
        name: "EnterpriseContext".to_string(),
        state_properties: (0..15).map(|i| StateProperty {
            name: format!("property{}", i),
            property_type: "String".to_string(),
            is_published: true,
            default_value: Some("\"\"".to_string()),
        }).collect(),
        client_binding: "EnterpriseClient".to_string(),
        lifecycle_management: true,
    }
}

fn create_simple_client_spec() -> ClientSpec {
    ClientSpec {
        name: "SimpleClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: vec![
            ActionDefinition {
                name: "fetchData".to_string(),
                parameters: vec![],
                return_type: "String".to_string(),
                is_async: true,
            },
        ],
        state_streaming: false,
        mock_implementation: true,
    }
}

fn create_medium_client_spec() -> ClientSpec {
    ClientSpec {
        name: "MediumClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: vec![
            ActionDefinition {
                name: "loadItems".to_string(),
                parameters: vec![],
                return_type: "[Item]".to_string(),
                is_async: true,
            },
            ActionDefinition {
                name: "createItem".to_string(),
                parameters: vec!["item: Item".to_string()],
                return_type: "Item".to_string(),
                is_async: true,
            },
            ActionDefinition {
                name: "updateItem".to_string(),
                parameters: vec!["item: Item".to_string()],
                return_type: "Item".to_string(),
                is_async: true,
            },
        ],
        state_streaming: true,
        mock_implementation: true,
    }
}

fn create_complex_client_spec() -> ClientSpec {
    ClientSpec {
        name: "ComplexClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: (0..8).map(|i| ActionDefinition {
            name: format!("action{}", i),
            parameters: vec![format!("param: String")],
            return_type: "Result<String, Error>".to_string(),
            is_async: true,
        }).collect(),
        state_streaming: true,
        mock_implementation: true,
    }
}

fn create_enterprise_client_spec() -> ClientSpec {
    ClientSpec {
        name: "EnterpriseClient".to_string(),
        protocol_conformance: vec!["AxiomClient".to_string()],
        actions: (0..15).map(|i| ActionDefinition {
            name: format!("enterpriseAction{}", i),
            parameters: vec![format!("param{}: String", i), "completion: @escaping (Result<String, Error>) -> Void".to_string()],
            return_type: "Void".to_string(),
            is_async: true,
        }).collect(),
        state_streaming: true,
        mock_implementation: true,
    }
}

fn create_dynamic_presentation_spec(index: usize) -> PresentationSpec {
    PresentationSpec {
        name: format!("DynamicView{}", index),
        context_binding: format!("DynamicContext{}", index),
        ui_components: vec![
            format!("Component{}", index),
            "Text".to_string(),
            "Button".to_string(),
        ],
        accessibility_requirements: vec![],
        performance_requirements: PerformanceRequirements {
            max_render_time_ms: 16.0,
            max_memory_mb: 5.0,
        },
    }
}

fn create_template_data_with_size(lines: usize) -> HashMap<String, String> {
    let mut data = HashMap::new();
    data.insert("name".to_string(), "BenchmarkView".to_string());
    data.insert("context_binding".to_string(), "BenchmarkContext".to_string());
    
    // Simulate template data of varying sizes
    let large_content = (0..lines).map(|i| format!("Line {}", i)).collect::<Vec<_>>().join("\n");
    data.insert("content".to_string(), large_content);
    
    data
}

// Helper functions use types from the main crate

criterion_group!(
    benches,
    benchmark_axiom_code_generator_initialization,
    benchmark_presentation_generation_by_complexity,
    benchmark_context_generation_by_complexity,
    benchmark_client_generation_by_complexity,
    benchmark_complete_trio_generation,
    benchmark_parallel_generation,
    benchmark_code_validation_performance,
    benchmark_template_processing_performance,
    benchmark_memory_usage_during_generation
);

criterion_main!(benches);