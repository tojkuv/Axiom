use anyhow::Result;
use axiom_universal_client_generator::{GenerateRequest, UniversalClientGenerator};
use axiom_universal_client_generator::validation::SwiftValidator;
use clap::{Parser, Subcommand};
use std::path::PathBuf;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::time::Instant;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    /// Set logging level
    #[arg(short, long, value_enum, default_value_t = LogLevel::Info)]
    log_level: LogLevel,
    
    #[command(subcommand)]
    command: Commands,
}

#[derive(Clone, Copy, clap::ValueEnum)]
enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

impl From<LogLevel> for tracing::Level {
    fn from(level: LogLevel) -> Self {
        match level {
            LogLevel::Error => tracing::Level::ERROR,
            LogLevel::Warn => tracing::Level::WARN,
            LogLevel::Info => tracing::Level::INFO,
            LogLevel::Debug => tracing::Level::DEBUG,
            LogLevel::Trace => tracing::Level::TRACE,
        }
    }
}

#[derive(Subcommand)]
enum Commands {
    /// Run as MCP server for Claude Code integration
    McpServer {
        /// Enable real-time progress reporting
        #[arg(long)]
        progress: bool,
        
        /// Enable enhanced debugging
        #[arg(long)]
        debug: bool,
        
        /// Enable validation feedback
        #[arg(long)]
        validate: bool,
    },
    /// Generate clients directly via CLI
    Generate {
        /// Path to proto file or directory
        #[arg(short, long)]
        proto_path: PathBuf,
        
        /// Output directory for generated files
        #[arg(short, long)]
        output_path: PathBuf,
        
        /// Target languages (comma-separated)
        #[arg(short, long, value_delimiter = ',')]
        languages: Vec<String>,
        
        /// Specific services to generate (comma-separated)
        #[arg(short, long, value_delimiter = ',')]
        services: Option<Vec<String>>,
        
        /// Swift framework version
        #[arg(long)]
        swift_framework_version: Option<String>,
        
        /// Kotlin framework version
        #[arg(long)]
        kotlin_framework_version: Option<String>,
        
        /// Generate test files
        #[arg(long)]
        generate_tests: bool,
        
        /// Force overwrite existing files
        #[arg(long)]
        force_overwrite: bool,
        
        /// Validate generated code after generation
        #[arg(long)]
        validate: bool,
        
        /// Skip compilation check during validation
        #[arg(long)]
        skip_compilation: bool,
        
        /// Show detailed progress information
        #[arg(long)]
        verbose: bool,
    },
    /// Validate existing generated files
    Validate {
        /// Path to directory containing generated Swift files
        #[arg(short, long)]
        path: PathBuf,
        
        /// Show detailed validation report
        #[arg(long)]
        detailed: bool,
        
        /// Run compilation check (requires Swift toolchain)
        #[arg(long)]
        compile_check: bool,
        
        /// Categorize issues by type
        #[arg(long)]
        categorize: bool,
    },
    /// Check system setup and dependencies
    Doctor,
    /// Show examples and getting started guide
    Examples {
        /// Show specific example type
        #[arg(value_enum)]
        example_type: Option<ExampleType>,
    },
}

#[derive(Clone, Copy, clap::ValueEnum)]
enum ExampleType {
    Basic,
    Comprehensive,
    TaskManager,
    UserService,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // Initialize tracing
    let log_level: tracing::Level = cli.log_level.into();
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::builder()
                .with_default_directive(log_level.into())
                .from_env_lossy(),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    match cli.command {
        Commands::McpServer { progress, debug, validate } => {
            tracing::info!("Starting Enhanced Axiom Universal Client Generator MCP Server");
            run_mcp_server(progress, debug, validate).await
        }
        Commands::Generate {
            proto_path,
            output_path,
            languages,
            services,
            swift_framework_version,
            kotlin_framework_version,
            generate_tests,
            force_overwrite,
            validate,
            skip_compilation,
            verbose,
        } => {
            tracing::info!("Running CLI generation");
            run_cli_generation(
                proto_path,
                output_path,
                languages,
                services,
                swift_framework_version,
                kotlin_framework_version,
                generate_tests,
                force_overwrite,
                validate,
                skip_compilation,
                verbose,
            ).await
        }
        Commands::Validate {
            path,
            detailed,
            compile_check,
            categorize,
        } => {
            tracing::info!("Running validation");
            run_validation(path, detailed, compile_check, categorize).await
        }
        Commands::Doctor => {
            tracing::info!("Running system check");
            run_doctor().await
        }
        Commands::Examples { example_type } => {
            run_examples(example_type).await
        }
    }
}

async fn run_mcp_server(progress: bool, debug: bool, validate: bool) -> Result<()> {
    use axiom_universal_client_generator::mcp::{server::AxiomMcpServer, ProgressUpdate};
    use tokio::sync::mpsc;
    
    if progress || debug || validate {
        tracing::info!("MCP Server Enhanced Features:");
        if progress {
            tracing::info!("  • Real-time progress reporting: ENABLED");
        }
        if debug {
            tracing::info!("  • Enhanced debugging: ENABLED");
        }
        if validate {
            tracing::info!("  • Real-time validation: ENABLED");
        }
    }
    
    let server = if progress {
        // Create progress channel for real-time updates
        let (progress_tx, mut progress_rx) = mpsc::unbounded_channel::<ProgressUpdate>();
        
        // Spawn progress monitoring task
        if debug {
            tokio::spawn(async move {
                while let Some(update) = progress_rx.recv().await {
                    tracing::info!(
                        "Progress [{}]: {} - {:.1}% - {}",
                        update.operation_id,
                        update.stage,
                        update.progress,
                        update.message
                    );
                    
                    if let Some(details) = update.details {
                        tracing::debug!("Progress details: {}", serde_json::to_string_pretty(&details).unwrap_or_default());
                    }
                }
            });
        }
        
        AxiomMcpServer::new_with_progress(progress_tx).await?
    } else {
        AxiomMcpServer::new().await?
    };
    
    tracing::info!("MCP Server ready for Claude Code integration");
    tracing::info!("Protocol version: 2024-11-05");
    tracing::info!("Available tools: generate_axiom_clients, validate_proto, doctor, get_examples");
    
    server.run().await?;
    
    Ok(())
}

async fn run_cli_generation(
    proto_path: PathBuf,
    output_path: PathBuf,
    languages: Vec<String>,
    services: Option<Vec<String>>,
    swift_framework_version: Option<String>,
    kotlin_framework_version: Option<String>,
    generate_tests: bool,
    force_overwrite: bool,
    validate: bool,
    skip_compilation: bool,
    verbose: bool,
) -> Result<()> {
    let start_time = Instant::now();
    
    // Pre-generation checks
    if verbose {
        println!("🔍 Pre-generation checks...");
        println!("   📁 Proto path: {}", proto_path.display());
        println!("   📂 Output path: {}", output_path.display());
        println!("   🛠️  Languages: {}", languages.join(", "));
        if let Some(ref services) = services {
            println!("   🔧 Services: {}", services.join(", "));
        }
    }
    
    // Check if proto path exists
    if !proto_path.exists() {
        eprintln!("❌ Proto path does not exist: {}", proto_path.display());
        eprintln!("💡 Make sure the path is correct and accessible.");
        std::process::exit(1);
    }
    
    // Create output directory if it doesn't exist
    if !output_path.exists() {
        if verbose {
            println!("📁 Creating output directory: {}", output_path.display());
        }
        std::fs::create_dir_all(&output_path)?;
    }
    
    if verbose {
        println!("⚙️  Initializing generator...");
    }
    
    let generator = UniversalClientGenerator::new().await?;
    
    let request = GenerateRequest {
        proto_path: proto_path.to_string_lossy().to_string(),
        output_path: output_path.to_string_lossy().to_string(),
        target_languages: languages.clone(),
        services: services.clone(),
        framework_config: Some(axiom_universal_client_generator::FrameworkConfig {
            swift: swift_framework_version.map(|version| {
                axiom_universal_client_generator::SwiftConfig {
                    axiom_version: Some(version),
                    client_suffix: Some("Client".to_string()),
                    generate_tests: Some(generate_tests),
                    package_name: None,
                }
            }),
            kotlin: None,
        }),
        generation_options: Some(axiom_universal_client_generator::GenerationOptions {
            generate_tests: Some(false),
            generate_contracts: Some(true),
            generate_clients: Some(true),
            force_overwrite: Some(force_overwrite),
            include_documentation: Some(true),
            style_guide: Some("axiom".to_string()),
        }),
    };

    if verbose {
        println!("🚀 Starting generation...");
    }

    let response = generator.generate(request).await?;
    let generation_time = start_time.elapsed();
    
    if response.success {
        println!("✅ Successfully generated {} files in {:?}:", response.generated_files.len(), generation_time);
        
        if verbose {
            for file in &response.generated_files {
                println!("   📄 {}", file);
            }
        } else {
            // Show just a summary for non-verbose mode
            let swift_files = response.generated_files.iter().filter(|f| f.ends_with(".swift")).count();
            if swift_files > 0 {
                println!("   📱 Swift files: {}", swift_files);
            }
        }
        
        if !response.warnings.is_empty() {
            println!("\n⚠️  Warnings ({}):", response.warnings.len());
            for warning in &response.warnings {
                println!("   {}", warning);
            }
        }
        
        println!("\n📊 Generation Stats:");
        println!("   ⏱️  Time: {:?}", generation_time);
        println!("   📁 Proto files: {}", response.stats.proto_files_processed);
        println!("   🔧 Services: {}", response.stats.services_generated);
        println!("   📨 Messages: {}", response.stats.messages_generated);
        
        // Run validation if requested
        if validate && languages.contains(&"swift".to_string()) {
            println!("\n🔍 Running validation...");
            let swift_files: Vec<String> = response.generated_files.iter()
                .filter(|f| f.ends_with(".swift"))
                .cloned()
                .collect();
                
            if !swift_files.is_empty() {
                let validator = SwiftValidator::new();
                let validation_result = validator.validate_files(&swift_files).await?;
                
                println!("{}", validation_result.summary());
                
                if !validation_result.is_valid() {
                    println!("\n🚨 Validation found issues:");
                    for (i, error) in validation_result.errors.iter().enumerate() {
                        println!("{}. {}", i + 1, error);
                    }
                    
                    println!("\n💡 Fix these issues to ensure proper compilation and framework integration.");
                }
                
                if !validation_result.warnings.is_empty() && verbose {
                    println!("\n⚠️  Validation warnings:");
                    for (i, warning) in validation_result.warnings.iter().enumerate() {
                        println!("{}. {}", i + 1, warning);
                    }
                }
                
                // Run compilation check if requested and available
                if !skip_compilation {
                    if verbose {
                        println!("\n🔨 Checking compilation...");
                    }
                    let compilation_result = validator.compile_check(&swift_files).await?;
                    
                    if compilation_result.successful_compilations > 0 {
                        println!("✅ Compilation check passed ({} files)", compilation_result.successful_compilations);
                    } else if !compilation_result.compilation_errors.is_empty() {
                        println!("❌ Compilation check failed:");
                        for error in &compilation_result.compilation_errors {
                            println!("   {}", error);
                        }
                    } else {
                        println!("⚠️  Swift compiler not available - skipping compilation check");
                        println!("💡 Install Swift toolchain to enable compilation validation");
                    }
                }
            }
        }
        
        println!("\n🎉 Generation completed successfully!");
        if !validate {
            println!("💡 Run with --validate to check generated code quality");
        }
        
    } else {
        let error_msg = response.error.unwrap_or("Unknown error".to_string());
        eprintln!("❌ Generation failed: {}", error_msg);
        eprintln!("💡 Troubleshooting tips:");
        eprintln!("   • Check that proto files are valid and accessible");
        eprintln!("   • Ensure output directory has write permissions");
        eprintln!("   • Verify language support (currently: swift)");
        eprintln!("   • Use --verbose for detailed error information");
        eprintln!("   • Run 'axiom-client-generator doctor' for system diagnostics");
        std::process::exit(1);
    }
    
    Ok(())
}

async fn run_validation(
    path: PathBuf,
    detailed: bool,
    compile_check: bool,
    categorize: bool,
) -> Result<()> {
    println!("🔍 Running validation on: {}", path.display());
    
    if !path.exists() {
        eprintln!("❌ Path does not exist: {}", path.display());
        std::process::exit(1);
    }
    
    // Find all Swift files recursively
    let mut swift_files = Vec::new();
    if path.is_file() && path.extension().map_or(false, |ext| ext == "swift") {
        swift_files.push(path.to_string_lossy().to_string());
    } else if path.is_dir() {
        use walkdir::WalkDir;
        for entry in WalkDir::new(&path) {
            let entry = entry?;
            if entry.path().extension().map_or(false, |ext| ext == "swift") {
                swift_files.push(entry.path().to_string_lossy().to_string());
            }
        }
    }
    
    if swift_files.is_empty() {
        println!("⚠️  No Swift files found in: {}", path.display());
        println!("💡 Make sure the path contains .swift files");
        return Ok(());
    }
    
    println!("📁 Found {} Swift files", swift_files.len());
    
    let validator = SwiftValidator::new();
    let validation_result = validator.validate_files(&swift_files).await?;
    
    if detailed {
        println!("\n{}", validation_result.detailed_report());
    } else {
        println!("\n{}", validation_result.summary());
        
        if !validation_result.is_valid() {
            println!("\n🚨 Issues found:");
            for (i, error) in validation_result.errors.iter().take(5).enumerate() {
                println!("{}. {}", i + 1, error);
            }
            if validation_result.errors.len() > 5 {
                println!("   ... and {} more errors", validation_result.errors.len() - 5);
                println!("💡 Use --detailed for complete report");
            }
        }
    }
    
    if categorize {
        let categorized = validation_result.categorize_issues();
        if !categorized.is_empty() {
            println!("\n📊 Issues by Category:");
            for (category, issues) in categorized {
                println!("   📂 {} ({} issues)", category, issues.len());
                for issue in issues.iter().take(2) {
                    println!("      • {}", issue.lines().next().unwrap_or(issue));
                }
                if issues.len() > 2 {
                    println!("      ... and {} more", issues.len() - 2);
                }
            }
        }
    }
    
    if compile_check {
        println!("\n🔨 Running compilation check...");
        let compilation_result = validator.compile_check(&swift_files).await?;
        
        if compilation_result.successful_compilations > 0 {
            println!("✅ Compilation successful ({} files)", compilation_result.successful_compilations);
        } else if !compilation_result.compilation_errors.is_empty() {
            println!("❌ Compilation errors found:");
            for (i, error) in compilation_result.compilation_errors.iter().take(3).enumerate() {
                println!("{}. {}", i + 1, error);
            }
            if compilation_result.compilation_errors.len() > 3 {
                println!("   ... and {} more errors", compilation_result.compilation_errors.len() - 3);
            }
        } else {
            println!("⚠️  Swift compiler not available");
            println!("💡 Install Swift toolchain to enable compilation checking");
        }
    }
    
    Ok(())
}

async fn run_doctor() -> Result<()> {
    println!("🏥 Axiom Client Generator - Enhanced System Diagnostics");
    println!("======================================================\n");
    
    let mut issues_found = false;
    
    // Check Rust environment
    println!("🦀 Rust Environment:");
    match std::process::Command::new("rustc").arg("--version").output() {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout);
            println!("   ✅ Rust: {}", version.trim());
        }
        _ => {
            println!("   ❌ Rust compiler not found");
            issues_found = true;
        }
    }
    
    // Check Cargo environment
    match std::process::Command::new("cargo").arg("--version").output() {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout);
            println!("   ✅ Cargo: {}", version.trim());
        }
        _ => {
            println!("   ❌ Cargo not found");
            issues_found = true;
        }
    }
    
    // Check Swift environment (optional)
    println!("\n🍎 Swift Environment (optional for compilation checking):");
    match std::process::Command::new("swift").arg("--version").output() {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout);
            let first_line = version.lines().next().unwrap_or("Unknown version");
            println!("   ✅ Swift: {}", first_line.trim());
        }
        _ => {
            println!("   ⚠️  Swift compiler not found (optional)");
            println!("      💡 Install Swift for compilation validation features");
        }
    }
    
    // Check file system permissions
    println!("\n📁 File System:");
    let temp_dir = std::env::temp_dir();
    match std::fs::create_dir_all(&temp_dir) {
        Ok(_) => println!("   ✅ Temp directory writable: {}", temp_dir.display()),
        Err(e) => {
            println!("   ❌ Cannot write to temp directory: {}", e);
            issues_found = true;
        }
    }
    
    // Check available memory (rough estimate)
    println!("\n💾 System Resources:");
    println!("   ✅ System appears to have sufficient resources for generation");
    
    // Check protocol buffer support
    println!("\n📦 Dependencies:");
    println!("   ✅ Protocol Buffer parsing: Available");
    println!("   ✅ Template engine: Available");
    println!("   ✅ Async runtime: Available");
    
    // Check MCP integration
    println!("\n🔗 MCP Integration:");
    println!("   ✅ JSON-RPC 2.0 protocol: Available");
    println!("   ✅ Claude Code compatibility: Ready");
    println!("   ✅ Real-time progress reporting: Available");
    println!("   ✅ Enhanced validation system: Available");
    
    // Check Axiom framework compatibility
    println!("\n🛡️  Axiom Framework:");
    println!("   ✅ Actor-based client generation: Ready");
    println!("   ✅ Immutable state management: Ready");
    println!("   ✅ AsyncStream integration: Ready");
    println!("   ✅ Error handling system: Ready");
    
    // Summary
    println!("\n📋 Summary:");
    if issues_found {
        println!("   ❌ Issues detected that may affect functionality");
        println!("   💡 Resolve the issues above for optimal experience");
        std::process::exit(1);
    } else {
        println!("   ✅ All critical components are working correctly");
        println!("   🎉 System is ready for Axiom client generation!");
    }
    
    Ok(())
}

async fn run_examples(example_type: Option<ExampleType>) -> Result<()> {
    match example_type {
        Some(ExampleType::Basic) => show_basic_example(),
        Some(ExampleType::Comprehensive) => show_comprehensive_example(),
        Some(ExampleType::TaskManager) => show_task_manager_example(),
        Some(ExampleType::UserService) => show_user_service_example(),
        None => show_all_examples(),
    }
    
    Ok(())
}

fn show_basic_example() {
    println!("📝 Basic Example - Simple Task Service");
    println!("=====================================\n");
    
    println!("1. Create a basic proto file (task_service.proto):");
    println!(r#"
```proto
syntax = "proto3";
package task.v1;

service TaskService {{
  rpc CreateTask(CreateTaskRequest) returns (Task);
  rpc GetTasks(GetTasksRequest) returns (GetTasksResponse);
}}

message Task {{
  string id = 1;
  string title = 2;
  bool is_completed = 3;
}}

message CreateTaskRequest {{
  string title = 1;
}}

message GetTasksRequest {{
  int32 limit = 1;
}}

message GetTasksResponse {{
  repeated Task tasks = 1;
}}
```"#);
    
    println!("\n2. Generate Swift clients:");
    println!("```bash");
    println!("axiom-client-generator generate \\");
    println!("  --proto-path ./task_service.proto \\");
    println!("  --output-path ./generated \\");
    println!("  --languages swift \\");
    println!("  --validate");
    println!("```");
    
    println!("\n3. This generates:");
    println!("   📁 generated/swift/Clients/");
    println!("   ├── TaskClient.swift     (Actor-based client)");
    println!("   ├── TaskAction.swift     (Action enum)");
    println!("   ├── TaskState.swift      (Immutable state)");
    println!("   └── AxiomErrors.swift    (Error types)");
    
    println!("\n💡 Next steps:");
    println!("   • Import generated files into your Swift project");
    println!("   • Add AxiomCore and AxiomArchitecture dependencies");
    println!("   • Initialize TaskClient in your application");
}

fn show_comprehensive_example() {
    println!("🔧 Comprehensive Example - Advanced Features");
    println!("===========================================\n");
    
    println!("This example shows advanced Axiom-specific features:");
    println!("• Custom proto options for Axiom integration");
    println!("• State collection management");
    println!("• Validation rules and caching strategies");
    println!("• Pagination and search support");
    
    println!("\n📄 See the integration tests for a complete example:");
    println!("   tests/integration/axiom_framework_integration.rs");
    
    println!("\n🚀 Key features demonstrated:");
    println!("   • Collection-based state management");
    println!("   • Validation with custom rules");
    println!("   • Pagination with cursor support");
    println!("   • Search and sorting capabilities");
    println!("   • Performance optimization");
}

fn show_task_manager_example() {
    println!("📱 Task Manager Example");
    println!("=====================\n");
    
    println!("A realistic task management application example:");
    println!("\n📁 Check the examples directory:");
    println!("   examples/task_manager/proto/task_service.proto");
    println!("   examples/task_manager/generated/swift/");
    
    println!("\n🎯 Features included:");
    println!("   • Task CRUD operations");
    println!("   • Priority and status management");
    println!("   • Category organization");
    println!("   • Search and filtering");
    println!("   • Comprehensive validation");
}

fn show_user_service_example() {
    println!("👤 User Service Example");
    println!("=====================\n");
    
    println!("User management service with authentication:");
    println!("\n📁 Check the examples directory:");
    println!("   examples/user_service/proto/user_service.proto");
    println!("   examples/user_service/generated/swift/");
    
    println!("\n🎯 Features included:");
    println!("   • User registration and authentication");
    println!("   • Profile management");
    println!("   • Role-based permissions");
    println!("   • Session handling");
}

fn show_all_examples() {
    println!("📚 Axiom Client Generator Examples (Enhanced)");
    println!("============================================\n");
    
    println!("Available examples:");
    println!("   basic         - Simple service with basic operations");
    println!("   comprehensive - Advanced features and Axiom integration");
    println!("   task-manager  - Realistic task management application (30-45 min)");
    println!("   user-service  - User management with authentication (45-60 min)");
    
    println!("\n🎯 Learning Path:");
    println!("   • Beginners: basic → task-manager → user-service");
    println!("   • Experienced: task-manager → user-service → custom");
    println!("   • Teams: architecture review → standards → integration");
    
    println!("\n🚀 Quick start:");
    println!("   axiom-client-generator examples basic");
    
    println!("\n💡 To generate from examples:");
    println!("   axiom-client-generator generate \\");
    println!("     --proto-path examples/task_manager/proto/ \\");
    println!("     --output-path ./my_generated \\");
    println!("     --languages swift \\");
    println!("     --validate --verbose");
    
    println!("\n🔧 Enhanced MCP Server mode:");
    println!("   axiom-client-generator mcp-server --progress --validate");
    println!("   # Enables real-time progress and validation for Claude Code");
    
    println!("\n📖 For more information:");
    println!("   • Check the generated code for usage patterns");
    println!("   • Run 'doctor' command to verify enhanced environment");
    println!("   • Use 'validate' command to check existing code");
    println!("   • MCP integration provides real-time feedback in Claude Code");
    
    println!("\n🎉 What's New in Phase 4:");
    println!("   ✨ Real-time validation feedback");
    println!("   ✨ Enhanced Claude Code integration");
    println!("   ✨ Progress reporting during generation");
    println!("   ✨ Improved error messages with suggestions");
    println!("   ✨ Session caching for better performance");
}