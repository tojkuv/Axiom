use crate::error::{Error, Result};
use crate::proto::types::*;
use std::collections::{HashMap, HashSet};

/// Proto schema analyzer for validation and optimization
pub struct ProtoAnalyzer {
    /// Schema being analyzed
    schema: ProtoSchema,
}

impl ProtoAnalyzer {
    /// Create a new analyzer for the given schema
    pub fn new(schema: ProtoSchema) -> Self {
        Self { schema }
    }

    /// Analyze the schema and return analysis results
    pub async fn analyze(&self) -> Result<AnalysisResult> {
        tracing::info!("Starting proto schema analysis");

        let mut result = AnalysisResult::new();

        // Validate schema structure
        self.validate_schema(&mut result)?;

        // Analyze dependencies
        self.analyze_dependencies(&mut result)?;

        // Analyze service patterns
        self.analyze_services(&mut result)?;

        // Analyze message patterns
        self.analyze_messages(&mut result)?;

        // Check for Axiom compatibility
        self.check_axiom_compatibility(&mut result)?;

        tracing::info!("Schema analysis completed with {} warnings", result.warnings.len());

        Ok(result)
    }

    /// Validate basic schema structure
    fn validate_schema(&self, result: &mut AnalysisResult) -> Result<()> {
        // Check for empty schema
        if self.schema.services.is_empty() && self.schema.messages.is_empty() {
            result.errors.push("Schema contains no services or messages".to_string());
            return Ok(());
        }

        // Validate service names
        let mut service_names = HashSet::new();
        for service in &self.schema.services {
            if service.name.is_empty() {
                result.errors.push("Service with empty name found".to_string());
            } else if !service_names.insert(&service.name) {
                result.errors.push(format!("Duplicate service name: {}", service.name));
            }
        }

        // Validate message names
        let mut message_names = HashSet::new();
        for message in &self.schema.messages {
            if message.name.is_empty() {
                result.errors.push("Message with empty name found".to_string());
            } else if !message_names.insert(&message.name) {
                result.warnings.push(format!("Duplicate message name: {}", message.name));
            }
        }

        Ok(())
    }

    /// Analyze dependencies and imports
    fn analyze_dependencies(&self, result: &mut AnalysisResult) -> Result<()> {
        let mut all_dependencies = HashSet::new();

        for file in &self.schema.files {
            for import in &file.imports {
                all_dependencies.insert(import.clone());
            }
        }

        // Check for common missing dependencies
        if self.has_timestamp_usage() && !all_dependencies.contains("google/protobuf/timestamp.proto") {
            result.warnings.push("Detected timestamp usage but no timestamp import found".to_string());
        }

        if self.has_empty_response() && !all_dependencies.contains("google/protobuf/empty.proto") {
            result.warnings.push("Detected empty response but no empty import found".to_string());
        }

        Ok(())
    }

    /// Analyze service patterns
    fn analyze_services(&self, result: &mut AnalysisResult) -> Result<()> {
        for service in &self.schema.services {
            // Check service method patterns
            if service.methods.is_empty() {
                result.warnings.push(format!("Service {} has no methods", service.name));
                continue;
            }

            // Analyze CRUD patterns
            self.analyze_crud_patterns(service, result);

            // Check for streaming methods
            for method in &service.methods {
                if method.client_streaming || method.server_streaming {
                    result.info.push(format!(
                        "Service {} has streaming method {} (not yet supported)",
                        service.name, method.name
                    ));
                }
            }

            // Check for Axiom options
            if service.options.axiom_service.is_none() {
                result.suggestions.push(format!(
                    "Consider adding Axiom service options to {}",
                    service.name
                ));
            }
        }

        Ok(())
    }

    /// Analyze CRUD patterns in services
    fn analyze_crud_patterns(&self, service: &Service, result: &mut AnalysisResult) {
        let method_names: HashSet<String> = service.methods.iter()
            .map(|m| m.name.to_lowercase())
            .collect();

        let create_patterns = ["create", "add", "insert", "new"];
        let read_patterns = ["get", "find", "list", "search", "query"];
        let update_patterns = ["update", "modify", "edit", "patch"];
        let delete_patterns = ["delete", "remove", "destroy"];

        let has_create = method_names.iter().any(|name| {
            create_patterns.iter().any(|pattern| name.contains(pattern))
        });
        let has_read = method_names.iter().any(|name| {
            read_patterns.iter().any(|pattern| name.contains(pattern))
        });
        let has_update = method_names.iter().any(|name| {
            update_patterns.iter().any(|pattern| name.contains(pattern))
        });
        let has_delete = method_names.iter().any(|name| {
            delete_patterns.iter().any(|pattern| name.contains(pattern))
        });

        if has_create && has_read && has_update && has_delete {
            result.info.push(format!("Service {} implements full CRUD pattern", service.name));
        } else {
            let missing: Vec<&str> = [
                ("Create", has_create),
                ("Read", has_read),
                ("Update", has_update),
                ("Delete", has_delete),
            ]
            .iter()
            .filter_map(|(name, has)| if *has { None } else { Some(*name) })
            .collect();

            if !missing.is_empty() {
                result.suggestions.push(format!(
                    "Service {} is missing CRUD operations: {}",
                    service.name,
                    missing.join(", ")
                ));
            }
        }
    }

    /// Analyze message patterns
    fn analyze_messages(&self, result: &mut AnalysisResult) -> Result<()> {
        for message in &self.schema.messages {
            // Check for ID fields
            let has_id_field = message.fields.iter().any(|f| {
                f.name.to_lowercase() == "id" || f.name.to_lowercase().ends_with("_id")
            });

            if !has_id_field && !message.name.ends_with("Request") && !message.name.ends_with("Response") {
                result.suggestions.push(format!(
                    "Message {} might benefit from an ID field for Axiom integration",
                    message.name
                ));
            }

            // Check for timestamp fields
            let has_timestamp = message.fields.iter().any(|f| {
                f.field_type.contains("Timestamp") || 
                f.name.to_lowercase().contains("time") ||
                f.name.to_lowercase().contains("date")
            });

            if has_timestamp {
                result.info.push(format!("Message {} uses timestamps", message.name));
            }

            // Check for Axiom message options
            if message.options.axiom_message.is_none() && !message.name.ends_with("Request") && !message.name.ends_with("Response") {
                result.suggestions.push(format!(
                    "Consider adding Axiom message options to {}",
                    message.name
                ));
            }
        }

        Ok(())
    }

    /// Check Axiom framework compatibility
    fn check_axiom_compatibility(&self, result: &mut AnalysisResult) -> Result<()> {
        // Check for services without Axiom options
        let services_without_options = self.schema.services.iter()
            .filter(|s| s.options.axiom_service.is_none())
            .count();

        if services_without_options > 0 {
            result.warnings.push(format!(
                "{} services lack Axiom options, will use defaults",
                services_without_options
            ));
        }

        // Check for unsupported features
        let streaming_methods = self.schema.services.iter()
            .flat_map(|s| &s.methods)
            .filter(|m| m.client_streaming || m.server_streaming)
            .count();

        if streaming_methods > 0 {
            result.warnings.push(format!(
                "{} streaming methods found (not yet supported)",
                streaming_methods
            ));
        }

        Ok(())
    }

    /// Check if schema uses timestamp types
    fn has_timestamp_usage(&self) -> bool {
        self.schema.messages.iter().any(|m| {
            m.fields.iter().any(|f| f.field_type.contains("Timestamp"))
        })
    }

    /// Check if schema uses empty responses
    fn has_empty_response(&self) -> bool {
        self.schema.services.iter().any(|s| {
            s.methods.iter().any(|m| m.output_type.contains("Empty"))
        })
    }
}

/// Result of proto schema analysis
#[derive(Debug, Clone)]
pub struct AnalysisResult {
    /// Critical errors that prevent generation
    pub errors: Vec<String>,
    /// Warnings about potential issues
    pub warnings: Vec<String>,
    /// Informational messages
    pub info: Vec<String>,
    /// Suggestions for improvement
    pub suggestions: Vec<String>,
    /// Analysis statistics
    pub stats: AnalysisStats,
}

/// Statistics from analysis
#[derive(Debug, Clone)]
pub struct AnalysisStats {
    /// Number of services analyzed
    pub services_count: usize,
    /// Number of messages analyzed
    pub messages_count: usize,
    /// Number of enums analyzed
    pub enums_count: usize,
    /// Number of methods analyzed
    pub methods_count: usize,
    /// Number of fields analyzed
    pub fields_count: usize,
}

impl AnalysisResult {
    fn new() -> Self {
        Self {
            errors: Vec::new(),
            warnings: Vec::new(),
            info: Vec::new(),
            suggestions: Vec::new(),
            stats: AnalysisStats {
                services_count: 0,
                messages_count: 0,
                enums_count: 0,
                methods_count: 0,
                fields_count: 0,
            },
        }
    }

    /// Check if there are any blocking errors
    pub fn has_errors(&self) -> bool {
        !self.errors.is_empty()
    }

    /// Get all issues as a formatted string
    pub fn format_issues(&self) -> String {
        let mut output = String::new();

        if !self.errors.is_empty() {
            output.push_str("ERRORS:\n");
            for error in &self.errors {
                output.push_str(&format!("  ❌ {}\n", error));
            }
            output.push('\n');
        }

        if !self.warnings.is_empty() {
            output.push_str("WARNINGS:\n");
            for warning in &self.warnings {
                output.push_str(&format!("  ⚠️  {}\n", warning));
            }
            output.push('\n');
        }

        if !self.suggestions.is_empty() {
            output.push_str("SUGGESTIONS:\n");
            for suggestion in &self.suggestions {
                output.push_str(&format!("  💡 {}\n", suggestion));
            }
            output.push('\n');
        }

        if !self.info.is_empty() {
            output.push_str("INFO:\n");
            for info in &self.info {
                output.push_str(&format!("  ℹ️  {}\n", info));
            }
        }

        output
    }
}