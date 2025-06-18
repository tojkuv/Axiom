use crate::error::{Error, Result};
use crate::proto::types::*;
use prost_types::descriptor_proto::ExtensionRange;
use std::collections::HashMap;

/// Custom option metadata extractor
pub struct MetadataExtractor;

impl MetadataExtractor {
    /// Extract Axiom-specific options from service options
    pub fn extract_service_options(
        options: &Option<prost_types::ServiceOptions>,
        service_name: &str,
    ) -> Result<AxiomServiceOptions> {
        let mut axiom_options = AxiomServiceOptions {
            client_name: None,
            state_name: None,
            action_name: None,
            import_modules: vec!["AxiomCore".to_string(), "AxiomArchitecture".to_string()],
            generate_tests: Some(true),
            swift_package_name: None,
            collections: Vec::new(),
            supports_pagination: Some(false),
        };

        if let Some(opts) = options {
            // Parse custom options from uninterpreted_option
            for uninterpreted in &opts.uninterpreted_option {
                if let Some(name_part) = uninterpreted.name.first() {
                    let name = &name_part.name_part;
                    if name == "axiom_service" {
                        // Parse the Axiom service options from the value
                        Self::parse_service_options_from_value(&uninterpreted.aggregate_value, &mut axiom_options)?;
                    }
                }
            }
            tracing::debug!("Extracted service options for {}", service_name);
        }

        // Set defaults if not specified
        if axiom_options.client_name.is_none() {
            axiom_options.client_name = Some(Self::generate_client_name(service_name));
        }
        if axiom_options.state_name.is_none() {
            axiom_options.state_name = Some(Self::generate_state_name(service_name));
        }
        if axiom_options.action_name.is_none() {
            axiom_options.action_name = Some(Self::generate_action_name(service_name));
        }

        Ok(axiom_options)
    }

    /// Extract Axiom-specific options from method options
    pub fn extract_method_options(
        options: &Option<prost_types::MethodOptions>,
        method_name: &str,
    ) -> Result<AxiomMethodOptions> {
        let mut axiom_options = AxiomMethodOptions {
            state_update_strategy: Self::infer_state_update_strategy(method_name),
            collection_name: None,
            requires_network: Some(true),
            modifies_state: Some(true),
            show_loading_state: Some(true),
            validation_rules: Vec::new(),
            action_documentation: None,
            id_field_name: None,
            supports_offline: Some(false),
            cache_strategy: CacheStrategy::Memory,
        };

        if let Some(opts) = options {
            // Parse custom options from uninterpreted_option
            for uninterpreted in &opts.uninterpreted_option {
                if let Some(name_part) = uninterpreted.name.first() {
                    let name = &name_part.name_part;
                    if name == "axiom_method" {
                        // Parse the Axiom method options from the value
                        Self::parse_method_options_from_value(&uninterpreted.aggregate_value, &mut axiom_options)?;
                    }
                }
            }
            tracing::debug!("Extracted method options for {}", method_name);
        }

        Ok(axiom_options)
    }

    /// Extract Axiom-specific options from message options
    pub fn extract_message_options(
        options: &Option<prost_types::MessageOptions>,
        message_name: &str,
    ) -> Result<AxiomMessageOptions> {
        let mut axiom_options = AxiomMessageOptions {
            identifiable: false,
            id_field: None,
            equatable: true,
            derived_properties: Vec::new(),
        };

        // Infer settings from message name and structure
        if !message_name.ends_with("Request") && !message_name.ends_with("Response") {
            axiom_options.identifiable = true;
            axiom_options.id_field = Some("id".to_string());
        }

        if let Some(opts) = options {
            // Parse custom options (this would normally use protobuf reflection)
            tracing::debug!("Extracting message options for {}", message_name);
        }

        Ok(axiom_options)
    }

    /// Infer state update strategy from method name
    fn infer_state_update_strategy(method_name: &str) -> StateUpdateStrategy {
        let name_lower = method_name.to_lowercase();

        if name_lower.contains("create") || name_lower.contains("add") || name_lower.contains("insert") {
            StateUpdateStrategy::Append
        } else if name_lower.contains("get") || name_lower.contains("list") || name_lower.contains("find") {
            StateUpdateStrategy::ReplaceAll
        } else if name_lower.contains("update") || name_lower.contains("modify") || name_lower.contains("edit") {
            StateUpdateStrategy::UpdateById
        } else if name_lower.contains("delete") || name_lower.contains("remove") {
            StateUpdateStrategy::RemoveById
        } else {
            StateUpdateStrategy::Custom
        }
    }

    /// Parse proto comments and documentation
    pub fn extract_documentation(
        source_code_info: &Option<prost_types::SourceCodeInfo>,
        path: &[i32],
    ) -> Option<String> {
        if let Some(info) = source_code_info {
            for location in &info.location {
                if location.path == path {
                    if let Some(leading_comments) = &location.leading_comments {
                        return Some(leading_comments.trim().to_string());
                    }
                    if let Some(trailing_comments) = &location.trailing_comments {
                        return Some(trailing_comments.trim().to_string());
                    }
                }
            }
        }
        None
    }

    /// Extract field documentation from proto comments
    pub fn extract_field_documentation(
        source_code_info: &Option<prost_types::SourceCodeInfo>,
        message_index: i32,
        field_index: i32,
    ) -> Option<String> {
        // Path for field: [4, message_index, 2, field_index]
        // 4 = message_type, 2 = field
        let path = vec![4, message_index, 2, field_index];
        Self::extract_documentation(source_code_info, &path)
    }

    /// Extract service documentation from proto comments
    pub fn extract_service_documentation(
        source_code_info: &Option<prost_types::SourceCodeInfo>,
        service_index: i32,
    ) -> Option<String> {
        // Path for service: [6, service_index]
        // 6 = service
        let path = vec![6, service_index];
        Self::extract_documentation(source_code_info, &path)
    }

    /// Extract method documentation from proto comments
    pub fn extract_method_documentation(
        source_code_info: &Option<prost_types::SourceCodeInfo>,
        service_index: i32,
        method_index: i32,
    ) -> Option<String> {
        // Path for method: [6, service_index, 2, method_index]
        // 6 = service, 2 = method
        let path = vec![6, service_index, 2, method_index];
        Self::extract_documentation(source_code_info, &path)
    }

    /// Generate default client name from service name
    pub fn generate_client_name(service_name: &str) -> String {
        if service_name.ends_with("Service") {
            format!("{}Client", &service_name[..service_name.len() - 7])
        } else {
            format!("{}Client", service_name)
        }
    }

    /// Generate default state name from service name
    pub fn generate_state_name(service_name: &str) -> String {
        if service_name.ends_with("Service") {
            format!("{}State", &service_name[..service_name.len() - 7])
        } else {
            format!("{}State", service_name)
        }
    }

    /// Generate default action name from service name
    pub fn generate_action_name(service_name: &str) -> String {
        if service_name.ends_with("Service") {
            format!("{}Action", &service_name[..service_name.len() - 7])
        } else {
            format!("{}Action", service_name)
        }
    }

    /// Generate collection name from entity name
    pub fn infer_collection_name(entity_name: &str) -> String {
        // Simple pluralization
        let name_lower = entity_name.to_lowercase();
        if name_lower.ends_with('s') {
            name_lower
        } else if name_lower.ends_with('y') {
            format!("{}ies", &name_lower[..name_lower.len() - 1])
        } else {
            format!("{}s", name_lower)
        }
    }

    /// Validate custom options for consistency
    pub fn validate_options(service: &Service) -> Result<Vec<String>> {
        let mut warnings = Vec::new();

        // Check if all methods have consistent collection names
        let collection_names: Vec<_> = service
            .methods
            .iter()
            .filter_map(|m| {
                m.options
                    .axiom_method
                    .as_ref()
                    .and_then(|opts| opts.collection_name.as_ref())
            })
            .collect();

        if collection_names.len() > 1 {
            let unique_names: std::collections::HashSet<_> = collection_names.into_iter().collect();
            if unique_names.len() > 1 {
                warnings.push(format!(
                    "Service {} methods use different collection names: {:?}",
                    service.name,
                    unique_names
                ));
            }
        }

        // Check for missing ID fields in update/delete operations
        for method in &service.methods {
            if let Some(axiom_opts) = &method.options.axiom_method {
                match axiom_opts.state_update_strategy {
                    StateUpdateStrategy::UpdateById | StateUpdateStrategy::RemoveById => {
                        if axiom_opts.id_field_name.is_none() {
                            warnings.push(format!(
                                "Method {} requires ID field for {} operation",
                                method.name,
                                match axiom_opts.state_update_strategy {
                                    StateUpdateStrategy::UpdateById => "update",
                                    StateUpdateStrategy::RemoveById => "delete",
                                    _ => "unknown",
                                }
                            ));
                        }
                    }
                    _ => {}
                }
            }
        }

        Ok(warnings)
    }

    /// Extract Axiom-specific field options
    pub fn extract_field_options(
        options: &Option<prost_types::FieldOptions>,
        field_name: &str,
    ) -> Result<Option<AxiomFieldOptions>> {
        if let Some(opts) = options {
            for uninterpreted in &opts.uninterpreted_option {
                if let Some(name_part) = uninterpreted.name.first() {
                    let name = &name_part.name_part;
                    if name == "axiom_field" {
                        let mut field_options = AxiomFieldOptions {
                            is_id_field: None,
                            searchable: None,
                            sortable: None,
                            required: None,
                            validation_pattern: None,
                            min_value: None,
                            max_value: None,
                            min_length: None,
                            max_length: None,
                            exclude_from_equality: None,
                        };
                        Self::parse_field_options_from_value(&uninterpreted.aggregate_value, &mut field_options)?;
                        return Ok(Some(field_options));
                    }
                }
            }
        }
        Ok(None)
    }

    /// Parse service options from protobuf aggregate value
    fn parse_service_options_from_value(
        aggregate_value: &Option<String>,
        options: &mut AxiomServiceOptions,
    ) -> Result<()> {
        if let Some(value) = aggregate_value {
            // Simple parser for the aggregate value format
            // In a real implementation, this would use proper protobuf parsing
            if value.contains("client_name:") {
                if let Some(name) = Self::extract_string_value(value, "client_name") {
                    options.client_name = Some(name);
                }
            }
            if value.contains("state_name:") {
                if let Some(name) = Self::extract_string_value(value, "state_name") {
                    options.state_name = Some(name);
                }
            }
            if value.contains("action_name:") {
                if let Some(name) = Self::extract_string_value(value, "action_name") {
                    options.action_name = Some(name);
                }
            }
            if value.contains("supports_pagination:") {
                if let Some(val) = Self::extract_bool_value(value, "supports_pagination") {
                    options.supports_pagination = Some(val);
                }
            }
            tracing::debug!("Parsed service options from aggregate value");
        }
        Ok(())
    }

    /// Parse method options from protobuf aggregate value
    fn parse_method_options_from_value(
        aggregate_value: &Option<String>,
        options: &mut AxiomMethodOptions,
    ) -> Result<()> {
        if let Some(value) = aggregate_value {
            if value.contains("state_update_strategy:") {
                if let Some(strategy) = Self::extract_enum_value(value, "state_update_strategy") {
                    options.state_update_strategy = Self::parse_state_update_strategy(&strategy);
                }
            }
            if value.contains("collection_name:") {
                if let Some(name) = Self::extract_string_value(value, "collection_name") {
                    options.collection_name = Some(name);
                }
            }
            if value.contains("requires_network:") {
                if let Some(val) = Self::extract_bool_value(value, "requires_network") {
                    options.requires_network = Some(val);
                }
            }
            if value.contains("modifies_state:") {
                if let Some(val) = Self::extract_bool_value(value, "modifies_state") {
                    options.modifies_state = Some(val);
                }
            }
            if value.contains("show_loading_state:") {
                if let Some(val) = Self::extract_bool_value(value, "show_loading_state") {
                    options.show_loading_state = Some(val);
                }
            }
            if value.contains("id_field_name:") {
                if let Some(name) = Self::extract_string_value(value, "id_field_name") {
                    options.id_field_name = Some(name);
                }
            }
            tracing::debug!("Parsed method options from aggregate value");
        }
        Ok(())
    }

    /// Parse field options from protobuf aggregate value
    fn parse_field_options_from_value(
        aggregate_value: &Option<String>,
        options: &mut AxiomFieldOptions,
    ) -> Result<()> {
        if let Some(value) = aggregate_value {
            if value.contains("is_id_field:") {
                if let Some(val) = Self::extract_bool_value(value, "is_id_field") {
                    options.is_id_field = Some(val);
                }
            }
            if value.contains("searchable:") {
                if let Some(val) = Self::extract_bool_value(value, "searchable") {
                    options.searchable = Some(val);
                }
            }
            if value.contains("sortable:") {
                if let Some(val) = Self::extract_bool_value(value, "sortable") {
                    options.sortable = Some(val);
                }
            }
            if value.contains("required:") {
                if let Some(val) = Self::extract_bool_value(value, "required") {
                    options.required = Some(val);
                }
            }
            tracing::debug!("Parsed field options from aggregate value");
        }
        Ok(())
    }

    /// Extract string value from aggregate option text
    fn extract_string_value(text: &str, key: &str) -> Option<String> {
        let pattern = format!("{}: \"", key);
        if let Some(start) = text.find(&pattern) {
            let start_pos = start + pattern.len();
            if let Some(end) = text[start_pos..].find('"') {
                return Some(text[start_pos..start_pos + end].to_string());
            }
        }
        None
    }

    /// Extract boolean value from aggregate option text
    fn extract_bool_value(text: &str, key: &str) -> Option<bool> {
        let pattern = format!("{}: ", key);
        if let Some(start) = text.find(&pattern) {
            let start_pos = start + pattern.len();
            if text[start_pos..].starts_with("true") {
                return Some(true);
            } else if text[start_pos..].starts_with("false") {
                return Some(false);
            }
        }
        None
    }

    /// Extract enum value from aggregate option text
    fn extract_enum_value(text: &str, key: &str) -> Option<String> {
        let pattern = format!("{}: ", key);
        if let Some(start) = text.find(&pattern) {
            let start_pos = start + pattern.len();
            if let Some(end) = text[start_pos..].find([' ', '\n', '}']) {
                return Some(text[start_pos..start_pos + end].to_string());
            }
        }
        None
    }

    /// Parse state update strategy from string
    fn parse_state_update_strategy(strategy: &str) -> StateUpdateStrategy {
        match strategy {
            "STATE_UPDATE_STRATEGY_APPEND" => StateUpdateStrategy::Append,
            "STATE_UPDATE_STRATEGY_REPLACE_ALL" => StateUpdateStrategy::ReplaceAll,
            "STATE_UPDATE_STRATEGY_UPDATE_BY_ID" => StateUpdateStrategy::UpdateById,
            "STATE_UPDATE_STRATEGY_REMOVE_BY_ID" => StateUpdateStrategy::RemoveById,
            "STATE_UPDATE_STRATEGY_NO_CHANGE" => StateUpdateStrategy::NoChange,
            "STATE_UPDATE_STRATEGY_CUSTOM" => StateUpdateStrategy::Custom,
            _ => StateUpdateStrategy::Unspecified,
        }
    }
}