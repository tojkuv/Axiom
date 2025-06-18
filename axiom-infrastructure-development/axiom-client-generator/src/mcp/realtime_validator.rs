//! Real-time validation system for enhanced MCP integration
//!
//! This module provides real-time validation feedback during client generation,
//! allowing Claude Code to display progress and catch issues early.

use crate::error::{Error, Result};
use crate::mcp::protocol::ProgressNotification;
use crate::mcp::server::ProgressUpdate;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use tokio::sync::{mpsc, RwLock};
use tracing::{debug, info, warn};

/// Real-time validation state
#[derive(Debug, Clone)]
pub struct ValidationState {
    pub operation_id: String,
    pub total_steps: usize,
    pub completed_steps: usize,
    pub current_stage: String,
    pub issues: Vec<ValidationIssue>,
    pub warnings: Vec<String>,
    pub start_time: std::time::Instant,
}

/// Validation issue with severity and context
#[derive(Debug, Clone)]
pub struct ValidationIssue {
    pub severity: IssueSeverity,
    pub message: String,
    pub file_path: Option<String>,
    pub line_number: Option<usize>,
    pub suggestion: Option<String>,
    pub code: Option<String>,
}

/// Issue severity levels
#[derive(Debug, Clone, PartialEq)]
pub enum IssueSeverity {
    Error,
    Warning,
    Info,
    Suggestion,
}

/// Real-time validator for generation process
pub struct RealtimeValidator {
    state: Arc<RwLock<HashMap<String, ValidationState>>>,
    progress_sender: Option<mpsc::UnboundedSender<ProgressUpdate>>,
}

impl RealtimeValidator {
    /// Create new real-time validator
    pub fn new(progress_sender: Option<mpsc::UnboundedSender<ProgressUpdate>>) -> Self {
        Self {
            state: Arc::new(RwLock::new(HashMap::new())),
            progress_sender,
        }
    }

    /// Start validation for an operation
    pub async fn start_operation(&self, operation_id: String, total_steps: usize) -> Result<()> {
        let state = ValidationState {
            operation_id: operation_id.clone(),
            total_steps,
            completed_steps: 0,
            current_stage: "initializing".to_string(),
            issues: Vec::new(),
            warnings: Vec::new(),
            start_time: std::time::Instant::now(),
        };

        {
            let mut states = self.state.write().await;
            states.insert(operation_id.clone(), state);
        }

        self.send_progress_update(&operation_id, "initializing", 0.0, "Starting validation...").await;
        Ok(())
    }

    /// Update progress for an operation
    pub async fn update_progress(
        &self,
        operation_id: &str,
        stage: &str,
        message: &str,
    ) -> Result<()> {
        let progress = {
            let mut states = self.state.write().await;
            if let Some(state) = states.get_mut(operation_id) {
                state.completed_steps += 1;
                state.current_stage = stage.to_string();
                (state.completed_steps as f32 / state.total_steps as f32) * 100.0
            } else {
                return Err(Error::ValidationError(format!(
                    "Operation not found: {}",
                    operation_id
                )));
            }
        };

        self.send_progress_update(operation_id, stage, progress, message).await;
        Ok(())
    }

    /// Add validation issue
    pub async fn add_issue(
        &self,
        operation_id: &str,
        issue: ValidationIssue,
    ) -> Result<()> {
        {
            let mut states = self.state.write().await;
            if let Some(state) = states.get_mut(operation_id) {
                state.issues.push(issue.clone());
            }
        }

        // Send specific progress update for issues
        let message = match issue.severity {
            IssueSeverity::Error => format!("❌ Error: {}", issue.message),
            IssueSeverity::Warning => format!("⚠️ Warning: {}", issue.message),
            IssueSeverity::Info => format!("ℹ️ Info: {}", issue.message),
            IssueSeverity::Suggestion => format!("💡 Suggestion: {}", issue.message),
        };

        self.send_progress_update(operation_id, "validation", -1.0, &message).await;
        Ok(())
    }

    /// Validate proto file in real-time
    pub async fn validate_proto_file(
        &self,
        operation_id: &str,
        proto_path: &Path,
    ) -> Result<Vec<ValidationIssue>> {
        let mut issues = Vec::new();

        self.update_progress(operation_id, "proto_syntax", "Checking proto syntax...").await?;

        // Check if file exists
        if !proto_path.exists() {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Error,
                message: format!("Proto file not found: {}", proto_path.display()),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Verify the file path and ensure the proto file exists".to_string()),
                code: Some("PROTO_NOT_FOUND".to_string()),
            });
            return Ok(issues);
        }

        // Read and validate proto content
        let content = match tokio::fs::read_to_string(proto_path).await {
            Ok(content) => content,
            Err(e) => {
                issues.push(ValidationIssue {
                    severity: IssueSeverity::Error,
                    message: format!("Failed to read proto file: {}", e),
                    file_path: Some(proto_path.to_string_lossy().to_string()),
                    line_number: None,
                    suggestion: Some("Check file permissions and encoding".to_string()),
                    code: Some("PROTO_READ_ERROR".to_string()),
                });
                return Ok(issues);
            }
        };

        self.update_progress(operation_id, "proto_content", "Analyzing proto content...").await?;

        // Validate syntax and structure
        issues.extend(self.validate_proto_syntax(&content, proto_path).await);
        
        self.update_progress(operation_id, "axiom_options", "Checking Axiom options...").await?;
        
        // Validate Axiom-specific options
        issues.extend(self.validate_axiom_options(&content, proto_path).await);

        // Report issues
        for issue in &issues {
            self.add_issue(operation_id, issue.clone()).await?;
        }

        Ok(issues)
    }

    /// Validate generated Swift code in real-time
    pub async fn validate_generated_code(
        &self,
        operation_id: &str,
        output_path: &Path,
    ) -> Result<Vec<ValidationIssue>> {
        let mut issues = Vec::new();

        self.update_progress(operation_id, "code_structure", "Validating code structure...").await?;

        // Check if output directory exists
        if !output_path.exists() {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Error,
                message: "Output directory not found".to_string(),
                file_path: Some(output_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Ensure the output directory is created".to_string()),
                code: Some("OUTPUT_DIR_NOT_FOUND".to_string()),
            });
            return Ok(issues);
        }

        // Validate Swift files
        if let Ok(entries) = tokio::fs::read_dir(output_path).await {
            let mut entries = entries;
            while let Ok(Some(entry)) = entries.next_entry().await {
                if let Some(ext) = entry.path().extension() {
                    if ext == "swift" {
                        let swift_issues = self.validate_swift_file(&entry.path()).await;
                        issues.extend(swift_issues);
                    }
                }
            }
        }

        self.update_progress(operation_id, "axiom_integration", "Checking Axiom integration...").await?;

        // Validate Axiom framework integration
        issues.extend(self.validate_axiom_integration(output_path).await);

        // Report issues
        for issue in &issues {
            self.add_issue(operation_id, issue.clone()).await?;
        }

        Ok(issues)
    }

    /// Complete validation operation
    pub async fn complete_operation(&self, operation_id: &str) -> Result<ValidationState> {
        let state = {
            let mut states = self.state.write().await;
            states.remove(operation_id)
        };

        if let Some(state) = state {
            let duration = state.start_time.elapsed();
            let message = format!(
                "Validation completed in {}ms. {} issues found.",
                duration.as_millis(),
                state.issues.len()
            );
            
            self.send_progress_update(operation_id, "completed", 100.0, &message).await;
            Ok(state)
        } else {
            Err(Error::ValidationError(format!(
                "Operation not found: {}",
                operation_id
            )))
        }
    }

    /// Send progress update through channel
    async fn send_progress_update(&self, operation_id: &str, stage: &str, progress: f32, message: &str) {
        if let Some(ref sender) = self.progress_sender {
            let update = ProgressUpdate {
                operation_id: operation_id.to_string(),
                stage: stage.to_string(),
                progress,
                message: message.to_string(),
                details: None,
            };
            
            if let Err(e) = sender.send(update) {
                warn!("Failed to send progress update: {}", e);
            }
        }
    }

    /// Validate proto file syntax
    async fn validate_proto_syntax(&self, content: &str, proto_path: &Path) -> Vec<ValidationIssue> {
        let mut issues = Vec::new();

        // Check for syntax version
        if !content.contains("syntax = \"proto3\"") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Error,
                message: "Proto file must use proto3 syntax".to_string(),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: Some(1),
                suggestion: Some("Add 'syntax = \"proto3\";' at the top of the file".to_string()),
                code: Some("MISSING_SYNTAX".to_string()),
            });
        }

        // Check for package declaration
        if !content.contains("package ") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Warning,
                message: "Proto file should include a package declaration".to_string(),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Add 'package your.package.name;' declaration".to_string()),
                code: Some("MISSING_PACKAGE".to_string()),
            });
        }

        // Check for service definitions
        if !content.contains("service ") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Info,
                message: "No service definitions found".to_string(),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Add service definitions to generate clients".to_string()),
                code: Some("NO_SERVICES".to_string()),
            });
        }

        issues
    }

    /// Validate Axiom-specific options
    async fn validate_axiom_options(&self, content: &str, proto_path: &Path) -> Vec<ValidationIssue> {
        let mut issues = Vec::new();

        // Check for axiom_options import
        if !content.contains("import \"axiom_options.proto\"") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Error,
                message: "Missing axiom_options.proto import".to_string(),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Add 'import \"axiom_options.proto\";' to use Axiom features".to_string()),
                code: Some("MISSING_AXIOM_IMPORT".to_string()),
            });
        }

        // Check for service options
        if content.contains("service ") && !content.contains("option (axiom.service_options)") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Warning,
                message: "Service definitions should include Axiom service options".to_string(),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Add 'option (axiom.service_options) = { ... };' to services".to_string()),
                code: Some("MISSING_SERVICE_OPTIONS".to_string()),
            });
        }

        // Check for method options
        if content.contains("rpc ") && !content.contains("option (axiom.method_options)") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Suggestion,
                message: "RPC methods can benefit from Axiom method options".to_string(),
                file_path: Some(proto_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Consider adding 'option (axiom.method_options) = { ... };' to RPC methods".to_string()),
                code: Some("CONSIDER_METHOD_OPTIONS".to_string()),
            });
        }

        issues
    }

    /// Validate Swift file
    async fn validate_swift_file(&self, swift_path: &Path) -> Vec<ValidationIssue> {
        let mut issues = Vec::new();

        let content = match tokio::fs::read_to_string(swift_path).await {
            Ok(content) => content,
            Err(_) => return issues,
        };

        // Check for proper imports
        if !content.contains("import AxiomCore") || !content.contains("import AxiomArchitecture") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Warning,
                message: "Missing required Axiom framework imports".to_string(),
                file_path: Some(swift_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Add 'import AxiomCore' and 'import AxiomArchitecture'".to_string()),
                code: Some("MISSING_IMPORTS".to_string()),
            });
        }

        // Check for actor-based clients
        if content.contains("Client") && !content.contains("@globalActor") && !content.contains("actor ") {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Suggestion,
                message: "Consider using actor-based client for thread safety".to_string(),
                file_path: Some(swift_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Use 'actor' keyword for client classes".to_string()),
                code: Some("CONSIDER_ACTOR".to_string()),
            });
        }

        issues
    }

    /// Validate Axiom framework integration
    async fn validate_axiom_integration(&self, output_path: &Path) -> Vec<ValidationIssue> {
        let mut issues = Vec::new();

        // Check for required client files
        let client_path = output_path.join("Clients");
        if !client_path.exists() {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Error,
                message: "Clients directory not found".to_string(),
                file_path: Some(output_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Ensure client generation is enabled".to_string()),
                code: Some("NO_CLIENTS_DIR".to_string()),
            });
        }

        // Check for documentation
        let docs_path = output_path.join("Documentation");
        if !docs_path.exists() {
            issues.push(ValidationIssue {
                severity: IssueSeverity::Info,
                message: "Documentation directory not found".to_string(),
                file_path: Some(output_path.to_string_lossy().to_string()),
                line_number: None,
                suggestion: Some("Enable documentation generation for better developer experience".to_string()),
                code: Some("NO_DOCS_DIR".to_string()),
            });
        }

        issues
    }
}

impl IssueSeverity {
    pub fn to_emoji(&self) -> &'static str {
        match self {
            IssueSeverity::Error => "❌",
            IssueSeverity::Warning => "⚠️",
            IssueSeverity::Info => "ℹ️",
            IssueSeverity::Suggestion => "💡",
        }
    }
}