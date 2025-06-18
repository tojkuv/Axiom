//! Axiom Swift Client Generator
//! 
//! A Rust-based MCP tool that generates Axiom framework-compatible Swift client code
//! directly from gRPC proto definitions.

pub mod error;
pub mod generators;
pub mod mcp;
pub mod proto;
pub mod utils;
pub mod validation;
pub mod testing;

pub use error::{Error, Result};

use generators::registry::GeneratorRegistry;
use proto::parser::ProtoParser;
use testing::TestRunner;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

/// Main configuration for client generation
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GenerateRequest {
    /// Path to proto file or directory containing proto files
    pub proto_path: String,
    /// Base directory to write generated files
    pub output_path: String,
    /// Languages to generate clients for
    pub target_languages: Vec<String>,
    /// Specific services to generate (if not specified, generates all)
    pub services: Option<Vec<String>>,
    /// Framework-specific configuration
    pub framework_config: Option<FrameworkConfig>,
    /// Generation options
    pub generation_options: Option<GenerationOptions>,
}

/// Framework-specific configuration options
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct FrameworkConfig {
    pub swift: Option<SwiftConfig>,
    pub kotlin: Option<KotlinConfig>,
}

/// Kotlin framework configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct KotlinConfig {
    /// Target Kotlin version
    pub kotlin_version: Option<String>,
    /// Suffix for generated client classes
    pub client_suffix: Option<String>,
    /// Generate test files
    pub generate_tests: Option<bool>,
    /// Package name for generated classes
    pub package_name: Option<String>,
}

/// Swift framework configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SwiftConfig {
    /// Target Axiom Swift framework version
    pub axiom_version: Option<String>,
    /// Suffix for generated client classes
    pub client_suffix: Option<String>,
    /// Generate XCTest files
    pub generate_tests: Option<bool>,
    /// Swift package name for imports
    pub package_name: Option<String>,
}


/// General generation options
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct GenerationOptions {
    /// Generate contract/model files
    pub generate_contracts: Option<bool>,
    /// Generate framework client files
    pub generate_clients: Option<bool>,
    /// Generate test files
    pub generate_tests: Option<bool>,
    /// Overwrite existing files without confirmation
    pub force_overwrite: Option<bool>,
    /// Include comprehensive code documentation
    pub include_documentation: Option<bool>,
    /// Code style guide to follow
    pub style_guide: Option<String>,
}

impl Default for GenerationOptions {
    fn default() -> Self {
        Self {
            generate_contracts: Some(true),
            generate_clients: Some(true),
            generate_tests: Some(true),
            force_overwrite: Some(false),
            include_documentation: Some(true),
            style_guide: Some("axiom".to_string()),
        }
    }
}

/// Response from client generation
#[derive(Debug, Clone, Serialize)]
pub struct GenerateResponse {
    /// Whether generation was successful
    pub success: bool,
    /// List of generated files
    pub generated_files: Vec<String>,
    /// Error message if generation failed
    pub error: Option<String>,
    /// Warnings encountered during generation
    pub warnings: Vec<String>,
    /// Generation statistics
    pub stats: GenerationStats,
    /// Validation results for generated code
    pub validation: Option<ValidationSummary>,
}

/// Statistics from the generation process
#[derive(Debug, Clone, Serialize)]
pub struct GenerationStats {
    /// Time taken for generation in milliseconds
    pub generation_time_ms: u64,
    /// Number of proto files processed
    pub proto_files_processed: usize,
    /// Number of services generated
    pub services_generated: usize,
    /// Number of messages generated
    pub messages_generated: usize,
    /// Total lines of code generated
    pub lines_of_code_generated: usize,
}

/// Summary of validation results across all generated files
#[derive(Debug, Clone, Serialize)]
pub struct ValidationSummary {
    /// Whether all files passed validation
    pub all_valid: bool,
    /// Number of files validated
    pub files_validated: usize,
    /// Total validation errors across all files
    pub total_errors: usize,
    /// Total validation warnings across all files
    pub total_warnings: usize,
    /// Compilation success rate (if compilation was attempted)
    pub compilation_success_rate: Option<f64>,
}

/// Main Swift client generator
pub struct AxiomSwiftClientGenerator {
    parser: ProtoParser,
    registry: GeneratorRegistry,
    test_runner: TestRunner,
}

impl AxiomSwiftClientGenerator {
    /// Create a new client generator instance
    pub async fn new() -> Result<Self> {
        let parser = ProtoParser::new().await?;
        let registry = GeneratorRegistry::new().await?;
        let test_runner = TestRunner::new();
        
        Ok(Self {
            parser,
            registry,
            test_runner,
        })
    }

    /// Generate clients from the given request
    pub async fn generate(&self, request: GenerateRequest) -> Result<GenerateResponse> {
        let start_time = std::time::Instant::now();
        
        tracing::info!("Starting client generation for: {}", request.proto_path);
        
        // Parse proto files
        let schema = self.parser.parse(&request.proto_path).await?;
        
        // Generate for each target language
        let mut generated_files = Vec::new();
        let mut warnings = Vec::new();
        
        for language in &request.target_languages {
            match self.registry.generate(language, &schema, &request).await {
                Ok(mut files) => generated_files.append(&mut files),
                Err(e) => {
                    tracing::error!("Failed to generate {} code: {}", language, e);
                    return Ok(GenerateResponse {
                        success: false,
                        generated_files: vec![],
                        error: Some(format!("Failed to generate {} code: {}", language, e)),
                        warnings,
                        stats: GenerationStats {
                            generation_time_ms: start_time.elapsed().as_millis() as u64,
                            proto_files_processed: 0,
                            services_generated: 0,
                            messages_generated: 0,
                            lines_of_code_generated: 0,
                        },
                        validation: None,
                    });
                }
            }
        }
        
        // Run validation on generated files
        let validation_summary = match self.test_runner.run_tests(&generated_files).await {
            Ok(test_results) => {
                tracing::info!("Validation completed: {} files tested", test_results.total_files_tested());
                
                let compilation_success_rate = if test_results.results_by_language.values()
                    .any(|r| r.compilation_result.is_some()) {
                    let total_compilations: usize = test_results.results_by_language.values()
                        .filter_map(|r| r.compilation_result.as_ref())
                        .map(|r| r.successful_compilations + r.compilation_errors.len())
                        .sum();
                    let successful_compilations: usize = test_results.results_by_language.values()
                        .filter_map(|r| r.compilation_result.as_ref())
                        .map(|r| r.successful_compilations)
                        .sum();
                    
                    if total_compilations > 0 {
                        Some(successful_compilations as f64 / total_compilations as f64)
                    } else {
                        None
                    }
                } else {
                    None
                };

                Some(ValidationSummary {
                    all_valid: test_results.overall_success,
                    files_validated: test_results.total_files_tested(),
                    total_errors: test_results.total_errors(),
                    total_warnings: test_results.total_warnings(),
                    compilation_success_rate,
                })
            }
            Err(e) => {
                tracing::warn!("Validation failed: {}", e);
                warnings.push(format!("Validation failed: {}", e));
                None
            }
        };
        
        let generation_time = start_time.elapsed().as_millis() as u64;
        
        tracing::info!(
            "Successfully generated {} files in {}ms", 
            generated_files.len(), 
            generation_time
        );
        
        Ok(GenerateResponse {
            success: true,
            generated_files,
            error: None,
            warnings,
            stats: GenerationStats {
                generation_time_ms: generation_time,
                proto_files_processed: schema.files.len(),
                services_generated: schema.services.len(),
                messages_generated: schema.messages.len(),
                lines_of_code_generated: 0, // TODO: calculate this
            },
            validation: validation_summary,
        })
    }
}

// Backward compatibility alias
pub type UniversalClientGenerator = AxiomSwiftClientGenerator;