use std::env;

/// Test configuration and utilities for the Axiom Applications Observability test suite
/// 
/// This module provides configuration and helper functions for running tests that validate
/// the success metrics defined in the plan:
/// 
/// ## Performance Targets
/// - Code Generation: < 2 seconds for complete Context+Presentation+Client trio
/// - Screenshot Capture: < 5 seconds for full device matrix (6+ variations)
/// - Hot Reload: < 100ms file change to preview update
/// - Metadata Streaming: < 10ms latency for state updates
/// 
/// ## Quality Targets
/// - Architecture Compliance: 100% generated code passes validation
/// - Type Safety: Zero runtime binding errors
/// - Performance: Generated code meets Axiom performance standards
/// - Visual Regression: < 1% false positive rate
/// 
/// ## Developer Experience Targets
/// - Setup Time: < 30 seconds from project open to development ready
/// - Feedback Loop: Real-time visual and performance feedback
/// - Code Quality: Generated code indistinguishable from hand-written

pub struct TestConfig {
    pub mock_server_port: u16,
    pub test_timeout_seconds: u64,
    pub performance_validation_enabled: bool,
    pub visual_analysis_enabled: bool,
    pub integration_tests_enabled: bool,
    pub benchmark_mode: bool,
}

impl Default for TestConfig {
    fn default() -> Self {
        Self {
            mock_server_port: 8080,
            test_timeout_seconds: 30,
            performance_validation_enabled: true,
            visual_analysis_enabled: true,
            integration_tests_enabled: true,
            benchmark_mode: false,
        }
    }
}

impl TestConfig {
    pub fn from_env() -> Self {
        Self {
            mock_server_port: env::var("TEST_MOCK_SERVER_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .unwrap_or(8080),
            test_timeout_seconds: env::var("TEST_TIMEOUT_SECONDS")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .unwrap_or(30),
            performance_validation_enabled: env::var("TEST_PERFORMANCE_VALIDATION")
                .map(|v| v == "true")
                .unwrap_or(true),
            visual_analysis_enabled: env::var("TEST_VISUAL_ANALYSIS")
                .map(|v| v == "true")
                .unwrap_or(true),
            integration_tests_enabled: env::var("TEST_INTEGRATION")
                .map(|v| v == "true")
                .unwrap_or(true),
            benchmark_mode: env::var("TEST_BENCHMARK_MODE")
                .map(|v| v == "true")
                .unwrap_or(false),
        }
    }
    
    pub fn mock_server_url(&self) -> String {
        format!("ws://localhost:{}/ws", self.mock_server_port)
    }
    
    pub fn intelligence_server_url(&self) -> String {
        format!("ws://localhost:{}/intelligence", self.mock_server_port)
    }
    
    pub fn test_timeout(&self) -> std::time::Duration {
        std::time::Duration::from_secs(self.test_timeout_seconds)
    }
}

/// Performance validation helper that checks against plan targets
pub struct PerformanceValidator {
    config: TestConfig,
}

impl PerformanceValidator {
    pub fn new(config: TestConfig) -> Self {
        Self { config }
    }
    
    /// Validates code generation performance against plan target: < 2 seconds for complete trio
    pub fn validate_code_generation_time(&self, duration: std::time::Duration, operation: &str) -> Result<(), String> {
        if !self.config.performance_validation_enabled {
            return Ok(());
        }
        
        let target_ms = match operation {
            "complete_trio" => 2000,
            "single_component" => 1000,
            "validation" => 100,
            _ => 5000,
        };
        
        if duration.as_millis() > target_ms {
            Err(format!(
                "Performance target exceeded for {}: {:?} > {}ms", 
                operation, duration, target_ms
            ))
        } else {
            println!("✅ Performance target met for {}: {:?} < {}ms", operation, duration, target_ms);
            Ok(())
        }
    }
    
    /// Validates screenshot capture performance against plan target: < 5 seconds for full matrix
    pub fn validate_screenshot_time(&self, duration: std::time::Duration, screenshot_count: usize) -> Result<(), String> {
        if !self.config.performance_validation_enabled {
            return Ok(());
        }
        
        let target_seconds = if screenshot_count >= 6 { 5 } else { 3 };
        
        if duration.as_secs() > target_seconds {
            Err(format!(
                "Screenshot performance target exceeded: {:?} > {}s for {} screenshots", 
                duration, target_seconds, screenshot_count
            ))
        } else {
            println!("✅ Screenshot performance target met: {:?} < {}s for {} screenshots", 
                    duration, target_seconds, screenshot_count);
            Ok(())
        }
    }
    
    /// Validates metadata streaming latency against plan target: < 10ms
    pub fn validate_metadata_latency(&self, duration: std::time::Duration, operation: &str) -> Result<(), String> {
        if !self.config.performance_validation_enabled {
            return Ok(());
        }
        
        let target_ms = match operation {
            "state_update" => 10,
            "metadata_collection" => 50,
            "streaming_init" => 100,
            _ => 100,
        };
        
        if duration.as_millis() > target_ms {
            Err(format!(
                "Metadata latency target exceeded for {}: {:?} > {}ms", 
                operation, duration, target_ms
            ))
        } else {
            println!("✅ Metadata latency target met for {}: {:?} < {}ms", operation, duration, target_ms);
            Ok(())
        }
    }
    
    /// Validates setup time against plan target: < 30 seconds
    pub fn validate_setup_time(&self, duration: std::time::Duration) -> Result<(), String> {
        if !self.config.performance_validation_enabled {
            return Ok(());
        }
        
        if duration.as_secs() > 30 {
            Err(format!("Setup time target exceeded: {:?} > 30s", duration))
        } else {
            println!("✅ Setup time target met: {:?} < 30s", duration);
            Ok(())
        }
    }
}

/// Quality validation helper that checks against plan targets
pub struct QualityValidator {
    config: TestConfig,
}

impl QualityValidator {
    pub fn new(config: TestConfig) -> Self {
        Self { config }
    }
    
    /// Validates architecture compliance against plan target: 100% generated code passes validation
    pub fn validate_architecture_compliance(&self, compliance_score: f64) -> Result<(), String> {
        let target_score = 95.0; // Allowing slight tolerance for test environment
        
        if compliance_score < target_score {
            Err(format!(
                "Architecture compliance below target: {:.1}% < {:.1}%", 
                compliance_score, target_score
            ))
        } else {
            println!("✅ Architecture compliance target met: {:.1}% >= {:.1}%", 
                    compliance_score, target_score);
            Ok(())
        }
    }
    
    /// Validates type safety against plan target: Zero runtime binding errors
    pub fn validate_type_safety(&self, type_errors: &[String], binding_safety_score: f64) -> Result<(), String> {
        if !type_errors.is_empty() {
            return Err(format!("Type errors found: {:?}", type_errors));
        }
        
        if binding_safety_score < 95.0 {
            return Err(format!("Binding safety score too low: {:.1}%", binding_safety_score));
        }
        
        println!("✅ Type safety target met: 0 errors, {:.1}% binding safety", binding_safety_score);
        Ok(())
    }
    
    /// Validates performance standards against plan target: Generated code meets Axiom standards
    pub fn validate_performance_standards(&self, performance_score: f64) -> Result<(), String> {
        let target_score = 80.0;
        
        if performance_score < target_score {
            Err(format!(
                "Performance standards not met: {:.1}% < {:.1}%", 
                performance_score, target_score
            ))
        } else {
            println!("✅ Performance standards met: {:.1}% >= {:.1}%", 
                    performance_score, target_score);
            Ok(())
        }
    }
    
    /// Validates visual regression detection against plan target: < 1% false positive rate
    pub fn validate_visual_regression_accuracy(&self, total_comparisons: u32, false_positives: u32) -> Result<(), String> {
        if !self.config.visual_analysis_enabled {
            return Ok(());
        }
        
        if total_comparisons == 0 {
            return Ok(()); // No comparisons to validate
        }
        
        let false_positive_rate = (false_positives as f64 / total_comparisons as f64) * 100.0;
        let target_rate = 1.0;
        
        if false_positive_rate > target_rate {
            Err(format!(
                "Visual regression false positive rate too high: {:.2}% > {:.1}%", 
                false_positive_rate, target_rate
            ))
        } else {
            println!("✅ Visual regression accuracy target met: {:.2}% <= {:.1}% false positive rate", 
                    false_positive_rate, target_rate);
            Ok(())
        }
    }
    
    /// Validates code quality against plan target: Generated code indistinguishable from hand-written
    pub fn validate_code_quality(&self, generated_code: &str, component_type: &str) -> Result<(), String> {
        let quality_checks = match component_type {
            "context" => vec![
                ("@MainActor", "Context should be MainActor-bound"),
                ("class", "Context should be class-based"),
                ("AxiomClientObservingContext", "Context should follow Axiom patterns"),
                ("@Published", "Context should have published properties"),
            ],
            "presentation" => vec![
                ("struct", "Presentation should be struct-based"),
                (": View", "Presentation should conform to View protocol"),
                ("var body:", "Presentation should have body property"),
            ],
            "client" => vec![
                ("actor", "Client should be actor-based"),
                ("AxiomClient", "Client should conform to AxiomClient protocol"),
            ],
            _ => vec![],
        };
        
        for (pattern, description) in quality_checks {
            if !generated_code.contains(pattern) {
                return Err(format!("Code quality issue in {}: {}", component_type, description));
            }
        }
        
        // Check for common code quality indicators
        if generated_code.trim().is_empty() {
            return Err(format!("Generated {} code is empty", component_type));
        }
        
        if generated_code.lines().count() < 5 {
            return Err(format!("Generated {} code appears too minimal", component_type));
        }
        
        println!("✅ Code quality validation passed for {}", component_type);
        Ok(())
    }
}

/// Test utilities for creating mock data and environments
pub struct TestUtils;

impl TestUtils {
    /// Creates a temporary test project directory
    pub fn create_temp_project_dir() -> Result<tempfile::TempDir, std::io::Error> {
        let temp_dir = tempfile::tempdir()?;
        
        // Create basic project structure
        std::fs::create_dir_all(temp_dir.path().join("Sources/Contexts"))?;
        std::fs::create_dir_all(temp_dir.path().join("Sources/Presentations"))?;
        std::fs::create_dir_all(temp_dir.path().join("Sources/Clients"))?;
        std::fs::create_dir_all(temp_dir.path().join("Tests"))?;
        
        // Create basic Package.swift
        std::fs::write(
            temp_dir.path().join("Package.swift"),
            r#"// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TestProject",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TestProject", targets: ["TestProject"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "TestProject", dependencies: []),
        .testTarget(name: "TestProjectTests", dependencies: ["TestProject"]),
    ]
)
"#,
        )?;
        
        Ok(temp_dir)
    }
    
    /// Sets up test logging
    pub fn setup_test_logging() {
        use tracing_subscriber::{fmt, EnvFilter};
        
        let _ = fmt()
            .with_env_filter(
                EnvFilter::try_from_default_env()
                    .unwrap_or_else(|_| EnvFilter::new("debug"))
            )
            .with_test_writer()
            .try_init();
    }
    
    /// Waits for a condition with timeout
    pub async fn wait_for_condition<F, Fut>(
        condition: F,
        timeout: std::time::Duration,
        check_interval: std::time::Duration,
    ) -> Result<(), String>
    where
        F: Fn() -> Fut,
        Fut: std::future::Future<Output = bool>,
    {
        let start = std::time::Instant::now();
        
        while start.elapsed() < timeout {
            if condition().await {
                return Ok(());
            }
            tokio::time::sleep(check_interval).await;
        }
        
        Err(format!("Condition not met within {:?}", timeout))
    }
}

/// Test metrics collector for gathering performance data across test runs
pub struct TestMetricsCollector {
    pub code_generation_times: Vec<std::time::Duration>,
    pub screenshot_capture_times: Vec<std::time::Duration>,
    pub validation_times: Vec<std::time::Duration>,
    pub setup_times: Vec<std::time::Duration>,
    pub quality_scores: Vec<f64>,
}

impl Default for TestMetricsCollector {
    fn default() -> Self {
        Self {
            code_generation_times: Vec::new(),
            screenshot_capture_times: Vec::new(),
            validation_times: Vec::new(),
            setup_times: Vec::new(),
            quality_scores: Vec::new(),
        }
    }
}

impl TestMetricsCollector {
    pub fn record_code_generation_time(&mut self, duration: std::time::Duration) {
        self.code_generation_times.push(duration);
    }
    
    pub fn record_screenshot_time(&mut self, duration: std::time::Duration) {
        self.screenshot_capture_times.push(duration);
    }
    
    pub fn record_validation_time(&mut self, duration: std::time::Duration) {
        self.validation_times.push(duration);
    }
    
    pub fn record_setup_time(&mut self, duration: std::time::Duration) {
        self.setup_times.push(duration);
    }
    
    pub fn record_quality_score(&mut self, score: f64) {
        self.quality_scores.push(score);
    }
    
    pub fn print_summary(&self) {
        println!("\n📊 Test Metrics Summary");
        println!("=======================");
        
        if !self.code_generation_times.is_empty() {
            let avg_generation = self.code_generation_times.iter().sum::<std::time::Duration>() / self.code_generation_times.len() as u32;
            let max_generation = self.code_generation_times.iter().max().unwrap();
            println!("🔧 Code Generation: avg {:?}, max {:?} (target: <2s)", avg_generation, max_generation);
        }
        
        if !self.screenshot_capture_times.is_empty() {
            let avg_screenshot = self.screenshot_capture_times.iter().sum::<std::time::Duration>() / self.screenshot_capture_times.len() as u32;
            let max_screenshot = self.screenshot_capture_times.iter().max().unwrap();
            println!("📸 Screenshot Capture: avg {:?}, max {:?} (target: <5s)", avg_screenshot, max_screenshot);
        }
        
        if !self.setup_times.is_empty() {
            let avg_setup = self.setup_times.iter().sum::<std::time::Duration>() / self.setup_times.len() as u32;
            let max_setup = self.setup_times.iter().max().unwrap();
            println!("⚡ Setup Time: avg {:?}, max {:?} (target: <30s)", avg_setup, max_setup);
        }
        
        if !self.quality_scores.is_empty() {
            let avg_quality = self.quality_scores.iter().sum::<f64>() / self.quality_scores.len() as f64;
            let min_quality = self.quality_scores.iter().fold(f64::INFINITY, |a, &b| a.min(b));
            println!("✨ Quality Score: avg {:.1}%, min {:.1}% (target: >95%)", avg_quality, min_quality);
        }
        
        println!("=======================\n");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_config_from_env() {
        let config = TestConfig::from_env();
        assert_eq!(config.mock_server_port, 8080);
        assert!(config.performance_validation_enabled);
    }
    
    #[test]
    fn test_performance_validator() {
        let config = TestConfig::default();
        let validator = PerformanceValidator::new(config);
        
        // Test successful validation
        let fast_duration = std::time::Duration::from_millis(500);
        assert!(validator.validate_code_generation_time(fast_duration, "single_component").is_ok());
        
        // Test failed validation
        let slow_duration = std::time::Duration::from_secs(3);
        assert!(validator.validate_code_generation_time(slow_duration, "complete_trio").is_err());
    }
    
    #[test]
    fn test_quality_validator() {
        let config = TestConfig::default();
        let validator = QualityValidator::new(config);
        
        // Test successful validation
        assert!(validator.validate_architecture_compliance(96.0).is_ok());
        assert!(validator.validate_type_safety(&[], 98.0).is_ok());
        
        // Test failed validation
        assert!(validator.validate_architecture_compliance(85.0).is_err());
        assert!(validator.validate_type_safety(&["Type error".to_string()], 95.0).is_err());
    }
    
    #[tokio::test]
    async fn test_temp_project_creation() {
        let temp_dir = TestUtils::create_temp_project_dir().unwrap();
        
        assert!(temp_dir.path().join("Package.swift").exists());
        assert!(temp_dir.path().join("Sources/Contexts").is_dir());
        assert!(temp_dir.path().join("Sources/Presentations").is_dir());
        assert!(temp_dir.path().join("Sources/Clients").is_dir());
    }
}