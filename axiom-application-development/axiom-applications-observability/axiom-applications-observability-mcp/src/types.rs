use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

/// Core types for the Axiom Applications Observability MCP

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PresentationSpec {
    pub name: String,
    pub context_binding: String,
    pub ui_components: Vec<String>,
    pub accessibility_requirements: Vec<String>,
    pub performance_requirements: PerformanceRequirements,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceRequirements {
    pub max_render_time_ms: f64,
    pub max_memory_mb: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextSpec {
    pub name: String,
    pub state_properties: Vec<StateProperty>,
    pub client_binding: String,
    pub lifecycle_management: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateProperty {
    pub name: String,
    pub property_type: String,
    pub is_published: bool,
    pub default_value: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClientSpec {
    pub name: String,
    pub protocol_conformance: Vec<String>,
    pub actions: Vec<ActionDefinition>,
    pub state_streaming: bool,
    pub mock_implementation: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActionDefinition {
    pub name: String,
    pub parameters: Vec<String>,
    pub return_type: String,
    pub is_async: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedCode {
    pub generated_code: String,
    pub validation_passed: bool,
    pub performance_score: f64,
    pub compliance_score: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppStructureAnalysis {
    pub contexts: Vec<String>,
    pub presentations: Vec<String>,
    pub clients: Vec<String>,
    pub architectural_compliance: f64,
    pub recommendations: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreenshotMatrix {
    pub screenshots: Vec<Screenshot>,
    pub analysis: ScreenshotAnalysis,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Screenshot {
    pub id: String,
    pub client_id: String,
    pub configuration: ScreenshotConfiguration,
    pub image_data: Vec<u8>,
    pub metadata: ScreenshotMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreenshotConfiguration {
    pub device_type: String,
    pub screen_size: ScreenSize,
    pub orientation: String,
    pub scale: f64,
    pub color_scheme: String,
    pub capture_mode: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreenSize {
    pub width: f64,
    pub height: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreenshotMetadata {
    pub timestamp: DateTime<Utc>,
    pub device_info: DeviceInfo,
    pub app_state: AppState,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceInfo {
    pub model: String,
    pub screen_size: ScreenSize,
    pub orientation: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppState {
    pub view_hierarchy: String,
    pub active_context: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreenshotAnalysis {
    pub total_screenshots: usize,
    pub consistency_score: f64,
    pub detected_issues: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualComparison {
    pub confidence_score: f64,
    pub similarity_score: f64,
    pub differences: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegressionReport {
    pub total_comparisons: usize,
    pub regressions_detected: usize,
    pub false_positive_rate: f64,
    pub confidence_score: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DevelopmentSession {
    pub session_id: String,
    pub hot_reload_active: bool,
    pub intelligence_streaming_active: bool,
    pub performance_monitoring_active: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RequirementAnalysis {
    pub requirement_id: String,
    pub analysis_timestamp: DateTime<Utc>,
    pub confidence_score: f64,
    pub complexity_estimate: String,
    pub recommended_approach: String,
    pub estimated_components: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceBottleneck {
    pub bottleneck_id: String,
    pub severity: String,
    pub description: String,
    pub optimization_suggestions: Vec<String>,
    pub estimated_improvement: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Implementation {
    pub implementation_id: String,
    pub analysis_id: String,
    pub timestamp: DateTime<Utc>,
    pub generation_duration: u64,
    pub context_layer: ContextLayer,
    pub presentation_layer: PresentationLayer,
    pub client_layer: ClientLayer,
    pub layer_integration: LayerIntegration,
    pub infrastructure: InfrastructureSpecification,
    pub test_suite: TestSuite,
    pub documentation: ImplementationDocumentation,
    pub estimated_performance: PerformanceEstimate,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextLayer {
    pub contexts: Vec<GeneratedContext>,
    pub total_contexts: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedContext {
    pub name: String,
    pub responsibilities: Vec<String>,
    pub state_properties: Vec<String>,
    pub client_binding: String,
    pub generated_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PresentationLayer {
    pub presentations: Vec<GeneratedPresentation>,
    pub total_presentations: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedPresentation {
    pub name: String,
    pub context_binding: String,
    pub ui_components: Vec<String>,
    pub generated_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClientLayer {
    pub clients: Vec<GeneratedClient>,
    pub total_clients: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratedClient {
    pub name: String,
    pub protocol_conformance: String,
    pub actor_implementation: bool,
    pub generated_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayerIntegration {
    pub integration_points: Vec<String>,
    pub integration_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InfrastructureSpecification {
    pub project_structure: ProjectStructureSpec,
    pub dependencies: Vec<String>,
    pub build_configuration: BuildConfigurationSpec,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectStructureSpec {
    pub directories: Vec<String>,
    pub configuration_files: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildConfigurationSpec {
    pub targets: Vec<String>,
    pub schemes: Vec<String>,
    pub swift_version: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestSuite {
    pub total_tests: usize,
    pub test_cases: Vec<String>,
    pub estimated_coverage: f64,
    pub test_categories: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImplementationDocumentation {
    pub overview: String,
    pub architecture_guide: String,
    pub api_documentation: String,
    pub usage_examples: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceEstimate {
    pub estimated_memory_usage_kb: u64,
    pub estimated_startup_time_ms: f64,
    pub estimated_cpu_usage_percent: f64,
    pub performance_grade: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationResult {
    pub passed: bool,
    pub overall_score: f64,
    pub architecture_compliance: f64,
    pub type_safety_score: f64,
    pub performance_score: f64,
    pub issues: Vec<String>,
    pub recommendations: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompleteLoopResult {
    pub success: bool,
    pub requirement_analysis: RequirementAnalysis,
    pub implementation: Implementation,
    pub validation_result: ValidationResult,
    pub optimization_suggestions: Vec<PerformanceBottleneck>,
}

// Default implementations for testing
impl Default for PerformanceRequirements {
    fn default() -> Self {
        Self {
            max_render_time_ms: 16.0,
            max_memory_mb: 10.0,
        }
    }
}

impl Default for ScreenSize {
    fn default() -> Self {
        Self {
            width: 393.0,
            height: 852.0,
        }
    }
}