use serde::{Deserialize, Serialize};
use crate::types::*;

/// All available MCP tools for Axiom Applications Observability
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AxiomMCPTool {
    /// Generate SwiftUI Presentation layer component
    GeneratePresentation(PresentationSpec),
    
    /// Generate Axiom Context layer component
    GenerateContext(ContextSpec),
    
    /// Generate mock Axiom Client layer component
    GenerateMockClient(ClientSpec),
    
    /// Validate architecture compliance against Axiom patterns
    ValidateArchitecture,
    
    /// Analyze app structure and provide intelligence
    AnalyzeAppStructure,
    
    /// Start streaming performance metrics
    StreamPerformanceMetrics,
    
    /// Capture screenshot matrix across device configurations
    CaptureScreenshotMatrix,
    
    /// Compare visual states for differences
    CompareVisualStates,
    
    /// Detect UI regressions automatically
    DetectUIRegressions,
    
    /// Start a new development session
    StartDevelopmentSession,
    
    /// Process natural language requirement into implementation plan
    ProcessNaturalLanguageRequirement(String),
    
    /// Optimize identified performance bottlenecks
    OptimizePerformanceBottlenecks,
}

/// Results returned by MCP tool execution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ToolResult {
    /// Generated code with validation and performance metrics
    GeneratedCode(GeneratedCode),
    
    /// App structure analysis with recommendations
    AppStructureAnalysis(AppStructureAnalysis),
    
    /// Screenshot matrix with device configurations
    ScreenshotMatrix(ScreenshotMatrix),
    
    /// Visual comparison results
    VisualComparison(VisualComparison),
    
    /// UI regression detection report
    RegressionReport(RegressionReport),
    
    /// Development session information
    DevelopmentSession(DevelopmentSession),
    
    /// Requirement analysis results
    RequirementAnalysis(RequirementAnalysis),
    
    /// Performance bottleneck analysis
    PerformanceBottlenecks(Vec<PerformanceBottleneck>),
    
    /// Architecture validation results
    ValidationResult(ValidationResult),
    
    /// Performance metrics stream ID
    PerformanceStream(String),
    
    /// Complete development loop results
    CompleteLoopResult(CompleteLoopResult),
}

impl AxiomMCPTool {
    /// Get the name of the tool
    pub fn name(&self) -> &'static str {
        match self {
            AxiomMCPTool::GeneratePresentation(_) => "generate_presentation",
            AxiomMCPTool::GenerateContext(_) => "generate_context",
            AxiomMCPTool::GenerateMockClient(_) => "generate_mock_client",
            AxiomMCPTool::ValidateArchitecture => "validate_architecture",
            AxiomMCPTool::AnalyzeAppStructure => "analyze_app_structure",
            AxiomMCPTool::StreamPerformanceMetrics => "stream_performance_metrics",
            AxiomMCPTool::CaptureScreenshotMatrix => "capture_screenshot_matrix",
            AxiomMCPTool::CompareVisualStates => "compare_visual_states",
            AxiomMCPTool::DetectUIRegressions => "detect_ui_regressions",
            AxiomMCPTool::StartDevelopmentSession => "start_development_session",
            AxiomMCPTool::ProcessNaturalLanguageRequirement(_) => "process_natural_language_requirement",
            AxiomMCPTool::OptimizePerformanceBottlenecks => "optimize_performance_bottlenecks",
        }
    }
    
    /// Get the description of the tool
    pub fn description(&self) -> &'static str {
        match self {
            AxiomMCPTool::GeneratePresentation(_) => "Generate SwiftUI Presentation layer component following Axiom patterns",
            AxiomMCPTool::GenerateContext(_) => "Generate MainActor-bound Context layer component with @Published properties",
            AxiomMCPTool::GenerateMockClient(_) => "Generate actor-based Client layer component conforming to AxiomClient protocol",
            AxiomMCPTool::ValidateArchitecture => "Validate architecture compliance against Axiom Context-Presentation-Client patterns",
            AxiomMCPTool::AnalyzeAppStructure => "Analyze app structure and provide intelligence recommendations",
            AxiomMCPTool::StreamPerformanceMetrics => "Start real-time performance metrics streaming for monitoring",
            AxiomMCPTool::CaptureScreenshotMatrix => "Capture screenshot matrix across multiple device configurations",
            AxiomMCPTool::CompareVisualStates => "Compare visual states to detect differences and changes",
            AxiomMCPTool::DetectUIRegressions => "Automatically detect UI regressions with low false positive rate",
            AxiomMCPTool::StartDevelopmentSession => "Start complete development session with hot reload and monitoring",
            AxiomMCPTool::ProcessNaturalLanguageRequirement(_) => "Process natural language requirements into implementation plans",
            AxiomMCPTool::OptimizePerformanceBottlenecks => "Analyze and optimize identified performance bottlenecks",
        }
    }
    
    /// Check if the tool requires specific capabilities
    pub fn required_capabilities(&self) -> Vec<&'static str> {
        match self {
            AxiomMCPTool::GeneratePresentation(_) |
            AxiomMCPTool::GenerateContext(_) |
            AxiomMCPTool::GenerateMockClient(_) => vec!["code_generation"],
            
            AxiomMCPTool::ValidateArchitecture => vec!["intelligence_analysis"],
            
            AxiomMCPTool::AnalyzeAppStructure |
            AxiomMCPTool::ProcessNaturalLanguageRequirement(_) => vec!["intelligence_analysis"],
            
            AxiomMCPTool::StreamPerformanceMetrics |
            AxiomMCPTool::OptimizePerformanceBottlenecks => vec!["performance_monitoring"],
            
            AxiomMCPTool::CaptureScreenshotMatrix |
            AxiomMCPTool::CompareVisualStates |
            AxiomMCPTool::DetectUIRegressions => vec!["visual_analysis"],
            
            AxiomMCPTool::StartDevelopmentSession => vec!["hot_reload_integration"],
        }
    }
    
    /// Get estimated execution time in milliseconds
    pub fn estimated_execution_time_ms(&self) -> u64 {
        match self {
            AxiomMCPTool::GeneratePresentation(_) => 800,
            AxiomMCPTool::GenerateContext(_) => 600,
            AxiomMCPTool::GenerateMockClient(_) => 700,
            AxiomMCPTool::ValidateArchitecture => 150,
            AxiomMCPTool::AnalyzeAppStructure => 200,
            AxiomMCPTool::StreamPerformanceMetrics => 50,
            AxiomMCPTool::CaptureScreenshotMatrix => 4000,
            AxiomMCPTool::CompareVisualStates => 300,
            AxiomMCPTool::DetectUIRegressions => 500,
            AxiomMCPTool::StartDevelopmentSession => 100,
            AxiomMCPTool::ProcessNaturalLanguageRequirement(_) => 250,
            AxiomMCPTool::OptimizePerformanceBottlenecks => 200,
        }
    }
}

impl ToolResult {
    /// Check if the tool result indicates success
    pub fn is_success(&self) -> bool {
        match self {
            ToolResult::GeneratedCode(code) => code.validation_passed,
            ToolResult::ValidationResult(validation) => validation.passed,
            ToolResult::CompleteLoopResult(result) => result.success,
            _ => true, // Most other results are informational and considered successful
        }
    }
    
    /// Get a summary description of the result
    pub fn summary(&self) -> String {
        match self {
            ToolResult::GeneratedCode(code) => {
                format!("Generated {} lines of code (validation: {}, performance: {:.1}%)", 
                    code.generated_code.lines().count(),
                    if code.validation_passed { "✅" } else { "❌" },
                    code.performance_score)
            },
            ToolResult::AppStructureAnalysis(analysis) => {
                format!("Found {} contexts, {} presentations, {} clients (compliance: {:.1}%)",
                    analysis.contexts.len(),
                    analysis.presentations.len(), 
                    analysis.clients.len(),
                    analysis.architectural_compliance)
            },
            ToolResult::ScreenshotMatrix(matrix) => {
                format!("Captured {} screenshots (consistency: {:.1}%)",
                    matrix.screenshots.len(),
                    matrix.analysis.consistency_score)
            },
            ToolResult::VisualComparison(comparison) => {
                format!("Visual comparison completed (confidence: {:.1}%, similarity: {:.1}%)",
                    comparison.confidence_score,
                    comparison.similarity_score)
            },
            ToolResult::RegressionReport(report) => {
                format!("Regression analysis: {}/{} regressions detected (FP rate: {:.1}%)",
                    report.regressions_detected,
                    report.total_comparisons,
                    report.false_positive_rate)
            },
            ToolResult::DevelopmentSession(session) => {
                format!("Development session {} started", session.session_id)
            },
            ToolResult::RequirementAnalysis(analysis) => {
                format!("Requirement analyzed: {} complexity (confidence: {:.1}%)",
                    analysis.complexity_estimate,
                    analysis.confidence_score)
            },
            ToolResult::PerformanceBottlenecks(bottlenecks) => {
                format!("Found {} performance bottlenecks",
                    bottlenecks.len())
            },
            ToolResult::ValidationResult(validation) => {
                format!("Validation {} (score: {:.1}%)",
                    if validation.passed { "passed" } else { "failed" },
                    validation.overall_score)
            },
            ToolResult::PerformanceStream(stream_id) => {
                format!("Performance stream {} started", stream_id)
            },
            ToolResult::CompleteLoopResult(result) => {
                format!("Development loop {} (score: {:.1}%)",
                    if result.success { "completed" } else { "failed" },
                    result.validation_result.overall_score)
            },
        }
    }
}