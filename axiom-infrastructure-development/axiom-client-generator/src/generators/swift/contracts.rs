use crate::error::{Error, Result};
use crate::generators::registry::GenerationContext;
use crate::generators::swift::{naming::SwiftNaming, templates::SwiftTemplateEngine};
use crate::proto::types::*;
use crate::utils::file_manager::FileManager;
use std::path::PathBuf;
use tera::Context;

/// Generate Swift contract files (models, types, enums)
pub async fn generate_contracts(
    context: &GenerationContext,
    template_engine: &SwiftTemplateEngine,
    naming: &SwiftNaming,
) -> Result<Vec<String>> {
    let mut generated_files = Vec::new();
    
    // Create contracts directory
    let contracts_dir = context.config.output_dir.join("swift/Contracts");
    std::fs::create_dir_all(&contracts_dir)?;

    // Group messages and enums by service/package for better organization
    let services_with_types = group_types_by_service(&context.schema);

    for (service_name, types) in services_with_types {
        let file_path = contracts_dir.join(naming.file_name(&service_name));
        let content = generate_service_contracts(&types, template_engine, naming, context).await?;
        
        FileManager::write_file(&file_path, &content, context.config.force_overwrite).await?;
        generated_files.push(file_path.to_string_lossy().to_string());
    }

    // Generate standalone enums if any
    for enum_type in &context.schema.enums {
        if !is_enum_used_in_service(enum_type, &context.schema) {
            let file_path = contracts_dir.join(naming.file_name(&enum_type.name));
            let content = generate_enum_file(enum_type, template_engine, naming, context).await?;
            
            FileManager::write_file(&file_path, &content, context.config.force_overwrite).await?;
            generated_files.push(file_path.to_string_lossy().to_string());
        }
    }

    Ok(generated_files)
}

/// Group messages and enums by their associated service
fn group_types_by_service(schema: &ProtoSchema) -> Vec<(String, ServiceTypes)> {
    let mut groups = Vec::new();

    for service in &schema.services {
        let mut types = ServiceTypes {
            service: service.clone(),
            messages: Vec::new(),
            enums: Vec::new(),
        };

        // Find messages used by this service
        let mut used_message_names = std::collections::HashSet::new();
        for method in &service.methods {
            collect_used_types(&method.input_type, &mut used_message_names);
            collect_used_types(&method.output_type, &mut used_message_names);
        }

        // Add messages used by this service
        for message in &schema.messages {
            if used_message_names.contains(&message.name) ||
               message.name.starts_with(&service.name.replace("Service", "")) {
                types.messages.push(message.clone());
                
                // Also collect types used within this message
                collect_message_dependencies(message, &mut used_message_names, schema);
            }
        }

        // Add enums used by this service
        for enum_type in &schema.enums {
            if is_enum_used_by_service(enum_type, &types.messages) {
                types.enums.push(enum_type.clone());
            }
        }

        groups.push((service.name.clone(), types));
    }

    groups
}

/// Collect type names referenced by a type string
fn collect_used_types(type_name: &str, used_types: &mut std::collections::HashSet<String>) {
    // Handle fully qualified types and simple types
    let clean_type = type_name.trim_start_matches('.');
    if let Some(last_part) = clean_type.split('.').last() {
        used_types.insert(last_part.to_string());
    } else {
        used_types.insert(clean_type.to_string());
    }
}

/// Collect all types used within a message and its dependencies
fn collect_message_dependencies(
    message: &Message,
    used_types: &mut std::collections::HashSet<String>,
    schema: &ProtoSchema,
) {
    for field in &message.fields {
        collect_used_types(&field.field_type, used_types);
        
        // If this field references another message, collect its dependencies too
        if let Some(referenced_message) = schema.find_message(&field.field_type) {
            if !used_types.contains(&referenced_message.name) {
                used_types.insert(referenced_message.name.clone());
                collect_message_dependencies(referenced_message, used_types, schema);
            }
        }
    }

    // Handle nested messages
    for nested_message in &message.nested_messages {
        used_types.insert(nested_message.name.clone());
        collect_message_dependencies(nested_message, used_types, schema);
    }

    // Handle nested enums
    for nested_enum in &message.nested_enums {
        used_types.insert(nested_enum.name.clone());
    }
}

/// Check if an enum is used by any of the messages
fn is_enum_used_by_service(enum_type: &Enum, messages: &[Message]) -> bool {
    for message in messages {
        if is_enum_used_in_message(enum_type, message) {
            return true;
        }
    }
    false
}

/// Check if an enum is used in a specific message
fn is_enum_used_in_message(enum_type: &Enum, message: &Message) -> bool {
    for field in &message.fields {
        if field.field_type == enum_type.name || field.field_type.ends_with(&format!(".{}", enum_type.name)) {
            return true;
        }
    }

    // Check nested messages
    for nested_message in &message.nested_messages {
        if is_enum_used_in_message(enum_type, nested_message) {
            return true;
        }
    }

    false
}

/// Check if an enum is used in any service
fn is_enum_used_in_service(enum_type: &Enum, schema: &ProtoSchema) -> bool {
    for service in &schema.services {
        for method in &service.methods {
            // Simple check - in a real implementation you'd trace through all referenced types
            if method.input_type.contains(&enum_type.name) || method.output_type.contains(&enum_type.name) {
                return true;
            }
        }
    }

    for message in &schema.messages {
        if is_enum_used_in_message(enum_type, message) {
            return true;
        }
    }

    false
}

/// Generate contracts for a service and its associated types
async fn generate_service_contracts(
    types: &ServiceTypes,
    template_engine: &SwiftTemplateEngine,
    naming: &SwiftNaming,
    context: &GenerationContext,
) -> Result<String> {
    let mut template_context = Context::new();

    // Process service for template
    let service_methods = types.service.methods.iter().map(|method| {
        serde_json::json!({
            "name": naming.method_name(&method.name),
            "input_type": naming.type_name(&method.input_type),
            "output_type": if method.output_type.contains("Empty") { 
                "Void".to_string() 
            } else { 
                naming.type_name(&method.output_type)
            },
            "documentation": method.documentation,
            "client_streaming": method.client_streaming,
            "server_streaming": method.server_streaming
        })
    }).collect::<Vec<_>>();

    let service_info = serde_json::json!({
        "name": types.service.name,
        "methods": service_methods,
        "documentation": types.service.documentation
    });

    template_context.insert("service", &service_info);

    // Process messages for template
    let mut template_messages = Vec::new();
    for message in &types.messages {
        let template_message = process_message_for_template(message, naming, context)?;
        template_messages.push(template_message);
    }
    template_context.insert("messages", &template_messages);

    // Process enums for template
    let mut template_enums = Vec::new();
    for enum_type in &types.enums {
        let template_enum = process_enum_for_template(enum_type, naming)?;
        template_enums.push(template_enum);
    }
    template_context.insert("enums", &template_enums);

    // Add configuration
    if let Some(swift_config) = context.language_config.get("swift") {
        template_context.insert("package_name", &swift_config.get("package_name"));
    }

    // Add imports
    let imports = get_required_imports(&types.messages, &types.enums);
    template_context.insert("imports", &imports);
    template_context.insert("axiom_core", &imports.contains(&"AxiomCore".to_string()));

    template_engine.render_contract("service", &template_context)
}

/// Generate a standalone enum file
async fn generate_enum_file(
    enum_type: &Enum,
    template_engine: &SwiftTemplateEngine,
    naming: &SwiftNaming,
    context: &GenerationContext,
) -> Result<String> {
    let mut template_context = Context::new();

    let template_enum = process_enum_for_template(enum_type, naming)?;
    template_context.insert("enum", &template_enum);

    // Add configuration
    if let Some(swift_config) = context.language_config.get("swift") {
        template_context.insert("package_name", &swift_config.get("package_name"));
    }

    template_engine.render_contract("enum", &template_context)
}

/// Process a message for template rendering
fn process_message_for_template(
    message: &Message,
    naming: &SwiftNaming,
    _context: &GenerationContext,
) -> Result<serde_json::Value> {
    let mut template_fields = Vec::new();
    
    for field in &message.fields {
        let swift_type = naming.swift_type(&field.field_type);
        let swift_name = naming.property_name(&field.name);
        
        // Determine field characteristics
        let is_array = matches!(field.label, FieldLabel::Repeated);
        let is_optional = !is_array && (
            matches!(field.label, FieldLabel::Optional) ||
            naming.is_optional_field(&field.field_type, &field.name)
        );
        
        // Handle JSON field name mapping if different from Swift name
        let json_name = if field.name != swift_name {
            field.name.clone()
        } else {
            swift_name.clone()
        };
        
        template_fields.push(serde_json::json!({
            "name": swift_name,
            "swift_type": swift_type,
            "is_array": is_array,
            "is_optional": is_optional,
            "json_name": json_name,
            "documentation": field.documentation,
            "original_type": field.field_type,
            "field_number": field.number
        }));
    }

    // Check Axiom message options
    let axiom_options = message.options.axiom_message.as_ref();
    let identifiable = axiom_options.map(|opts| opts.identifiable).unwrap_or_else(|| {
        // Auto-detect if message should be identifiable (has id field)
        message.fields.iter().any(|f| f.name.to_lowercase() == "id")
    });
    
    let equatable = axiom_options.map(|opts| opts.equatable).unwrap_or(true);
    let hashable = !message.fields.is_empty(); // Most data types should be hashable
    
    // Determine if we need custom CodingKeys
    let needs_coding_keys = template_fields.iter().any(|field| {
        field["name"].as_str() != field["json_name"].as_str()
    });

    Ok(serde_json::json!({
        "name": message.name,
        "fields": template_fields,
        "has_fields": !message.fields.is_empty(),
        "identifiable": identifiable,
        "equatable": equatable,
        "hashable": hashable,
        "coding_keys": needs_coding_keys,
        "documentation": message.documentation
    }))
}

/// Process an enum for template rendering
fn process_enum_for_template(
    enum_type: &Enum,
    naming: &SwiftNaming,
) -> Result<serde_json::Value> {
    let mut template_values = Vec::new();
    
    for value in &enum_type.values {
        let swift_name = naming.enum_case_name(&value.name);
        let proto_name = value.name.clone();
        
        template_values.push(serde_json::json!({
            "swift_name": swift_name,
            "proto_name": proto_name,
            "documentation": value.documentation,
            "number": value.number
        }));
    }

    Ok(serde_json::json!({
        "name": enum_type.name,
        "values": template_values,
        "documentation": enum_type.documentation
    }))
}

/// Get required imports for the generated code
fn get_required_imports(messages: &[Message], _enums: &[Enum]) -> Vec<String> {
    let mut imports = Vec::new();
    
    // Check if we need Foundation for Date, UUID, or other Foundation types
    let needs_foundation = messages.iter().any(|m| {
        m.fields.iter().any(|f| {
            f.field_type.contains("Timestamp") || 
            f.field_type.contains("Duration") ||
            f.field_type == "bytes" // Data type from Foundation
        })
    });
    
    if needs_foundation {
        imports.push("Foundation".to_string());
    }

    // Check if we need any Axiom-specific features
    let needs_axiom_core = messages.iter().any(|m| {
        m.options.axiom_message.is_some() ||
        m.fields.iter().any(|f| f.name.to_lowercase() == "id") // Identifiable support
    });
    
    if needs_axiom_core {
        imports.push("AxiomCore".to_string());
    }

    imports.sort();
    imports.dedup();
    imports
}

/// Helper struct to group types by service
#[derive(Debug, Clone)]
struct ServiceTypes {
    service: Service,
    messages: Vec<Message>,
    enums: Vec<Enum>,
}