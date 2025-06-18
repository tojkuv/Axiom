use crate::error::{Error, Result};
use crate::proto::types::*;
use crate::proto::metadata::MetadataExtractor;
use prost_types::{
    DescriptorProto, EnumDescriptorProto, FieldDescriptorProto, FileDescriptorProto,
    MethodDescriptorProto, ServiceDescriptorProto,
};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

/// Proto file parser using prost/tonic
pub struct ProtoParser {
    /// Include paths for proto compilation
    include_paths: Vec<PathBuf>,
}

impl ProtoParser {
    /// Create a new proto parser
    pub async fn new() -> Result<Self> {
        Ok(Self {
            include_paths: vec![
                PathBuf::from("."),
                PathBuf::from("proto"),
                PathBuf::from("../proto"),
            ],
        })
    }

    /// Parse proto files from a path (file or directory)
    pub async fn parse(&self, path: &str) -> Result<ProtoSchema> {
        let path = Path::new(path);
        
        if !path.exists() {
            return Err(Error::ProtoFileNotFound(path.to_string_lossy().to_string()));
        }

        let proto_files = if path.is_file() {
            vec![path.to_path_buf()]
        } else {
            self.find_proto_files(path)?
        };

        if proto_files.is_empty() {
            return Err(Error::ProtoParsingError {
                file_path: std::path::PathBuf::from(path),
                message: "No proto files found".to_string(),
            });
        }

        tracing::info!("Found {} proto files to parse", proto_files.len());

        let mut schema = ProtoSchema::new();
        
        for proto_file in proto_files {
            let file_schema = self.parse_file(&proto_file).await?;
            self.merge_schema(&mut schema, file_schema)?;
        }

        tracing::info!(
            "Parsed schema: {} services, {} messages, {} enums",
            schema.services.len(),
            schema.messages.len(),
            schema.enums.len()
        );

        Ok(schema)
    }

    /// Find all .proto files in a directory
    fn find_proto_files(&self, dir: &Path) -> Result<Vec<PathBuf>> {
        let mut proto_files = Vec::new();

        for entry in WalkDir::new(dir)
            .follow_links(true)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path.is_file() && path.extension().map_or(false, |ext| ext == "proto") {
                proto_files.push(path.to_path_buf());
            }
        }

        proto_files.sort();
        Ok(proto_files)
    }

    /// Parse a single proto file
    async fn parse_file(&self, file_path: &Path) -> Result<ProtoSchema> {
        tracing::debug!("Parsing proto file: {}", file_path.display());

        // Read the proto file content
        let content = std::fs::read_to_string(file_path)
            .map_err(|e| Error::ProtoParsingError {
                file_path: file_path.to_path_buf(),
                message: format!("Failed to read {}: {}", file_path.display(), e),
            })?;

        // Parse using protoc/prost
        let file_descriptor = self.compile_proto_file(file_path, &content).await?;

        // Convert to our internal representation
        self.convert_file_descriptor(file_descriptor, file_path)
    }

    /// Compile proto file using protoc
    async fn compile_proto_file(&self, file_path: &Path, _content: &str) -> Result<FileDescriptorProto> {
        // Use tonic-build to compile the proto file
        let mut config = tonic_build::configure();
        
        // Add include paths
        for include_path in &self.include_paths {
            config = config.protoc_arg(format!("--proto_path={}", include_path.display()));
        }

        // This is a simplified version - in reality we'd need to properly configure
        // protoc compilation and handle the file descriptor set
        // For now, we'll create a basic descriptor for development
        self.create_mock_descriptor(file_path)
    }

    /// Create a mock descriptor for development
    fn create_mock_descriptor(&self, file_path: &Path) -> Result<FileDescriptorProto> {
        // Read the proto file content to extract package name and other info
        let content = std::fs::read_to_string(file_path)
            .map_err(|e| Error::ProtoParsingError {
                file_path: file_path.to_path_buf(),
                message: format!("Failed to read {}: {}", file_path.display(), e),
            })?;

        // Extract package name from content
        let package = self.extract_package_from_content(&content);
        
        // Extract services, messages, and enums from content
        let services = self.extract_services_from_content(&content);
        let messages = self.extract_messages_from_content(&content);
        let enums = self.extract_enums_from_content(&content);

        Ok(FileDescriptorProto {
            name: Some(file_path.to_string_lossy().to_string()),
            package: Some(package),
            dependency: vec![],
            public_dependency: vec![],
            weak_dependency: vec![],
            message_type: messages,
            enum_type: enums,
            service: services,
            extension: vec![],
            options: None,
            source_code_info: None,
            syntax: Some("proto3".to_string()),
        })
    }

    /// Convert FileDescriptorProto to our internal representation
    fn convert_file_descriptor(
        &self,
        descriptor: FileDescriptorProto,
        file_path: &Path,
    ) -> Result<ProtoSchema> {
        let package = descriptor.package.clone().unwrap_or_default();
        let syntax = descriptor.syntax.clone().unwrap_or_else(|| "proto3".to_string());

        let mut schema = ProtoSchema::new();

        // Convert file info
        let proto_file = ProtoFile {
            path: file_path.to_string_lossy().to_string(),
            package: package.clone(),
            syntax,
            imports: descriptor.dependency.clone(),
            services: descriptor.service.iter().map(|s| s.name.clone().unwrap_or_default()).collect(),
            messages: descriptor.message_type.iter().map(|m| m.name.clone().unwrap_or_default()).collect(),
            enums: descriptor.enum_type.iter().map(|e| e.name.clone().unwrap_or_default()).collect(),
        };

        schema.files.push(proto_file);

        // Convert services
        for service_desc in descriptor.service {
            let service = self.convert_service(service_desc, &package, file_path)?;
            schema.services.push(service);
        }

        // Convert messages
        for message_desc in descriptor.message_type {
            let message = self.convert_message(message_desc, &package, file_path)?;
            schema.messages.push(message);
        }

        // Convert enums
        for enum_desc in descriptor.enum_type {
            let enum_type = self.convert_enum(enum_desc, &package, file_path)?;
            schema.enums.push(enum_type);
        }

        Ok(schema)
    }

    /// Convert ServiceDescriptorProto to Service
    fn convert_service(
        &self,
        descriptor: ServiceDescriptorProto,
        package: &str,
        file_path: &Path,
    ) -> Result<Service> {
        let name = descriptor.name.clone().unwrap_or_default();
        let mut methods = Vec::new();

        for (method_index, method_desc) in descriptor.method.iter().enumerate() {
            let method = self.convert_method(method_desc.clone(), method_index as i32)?;
            methods.push(method);
        }

        // Extract Axiom service options
        let axiom_service_options = MetadataExtractor::extract_service_options(&descriptor.options, &name)?;
        let service_options = ServiceOptions {
            axiom_service: Some(axiom_service_options),
            standard_options: HashMap::new(),
        };

        Ok(Service {
            name,
            package: package.to_string(),
            file_path: file_path.to_string_lossy().to_string(),
            methods,
            options: service_options,
            documentation: None,
        })
    }

    /// Convert MethodDescriptorProto to Method
    fn convert_method(&self, descriptor: MethodDescriptorProto, method_index: i32) -> Result<Method> {
        let name = descriptor.name.clone().unwrap_or_default();
        
        // Extract Axiom method options
        let axiom_method_options = MetadataExtractor::extract_method_options(&descriptor.options, &name)?;
        let method_options = MethodOptions {
            axiom_method: Some(axiom_method_options),
            standard_options: HashMap::new(),
        };

        Ok(Method {
            name,
            input_type: descriptor.input_type.unwrap_or_default(),
            output_type: descriptor.output_type.unwrap_or_default(),
            client_streaming: descriptor.client_streaming.unwrap_or(false),
            server_streaming: descriptor.server_streaming.unwrap_or(false),
            options: method_options,
            documentation: None,
        })
    }

    /// Convert DescriptorProto to Message
    fn convert_message(
        &self,
        descriptor: DescriptorProto,
        package: &str,
        file_path: &Path,
    ) -> Result<Message> {
        let name = descriptor.name.unwrap_or_default();
        let mut fields = Vec::new();

        for field_desc in descriptor.field {
            let field = self.convert_field(field_desc)?;
            fields.push(field);
        }

        // Handle nested messages and enums
        let mut nested_messages = Vec::new();
        for nested_desc in descriptor.nested_type {
            let nested_message = self.convert_message(nested_desc, package, file_path)?;
            nested_messages.push(nested_message);
        }

        let mut nested_enums = Vec::new();
        for nested_enum_desc in descriptor.enum_type {
            let nested_enum = self.convert_enum(nested_enum_desc, package, file_path)?;
            nested_enums.push(nested_enum);
        }

        Ok(Message {
            name,
            package: package.to_string(),
            file_path: file_path.to_string_lossy().to_string(),
            fields,
            nested_messages,
            nested_enums,
            options: MessageOptions::default(),
            documentation: None,
        })
    }

    /// Convert FieldDescriptorProto to Field
    fn convert_field(&self, descriptor: FieldDescriptorProto) -> Result<Field> {
        let name = descriptor.name.clone().unwrap_or_default();
        
        let label = match descriptor.label() {
            prost_types::field_descriptor_proto::Label::Optional => FieldLabel::Optional,
            prost_types::field_descriptor_proto::Label::Required => FieldLabel::Required,
            prost_types::field_descriptor_proto::Label::Repeated => FieldLabel::Repeated,
        };

        let field_type = match descriptor.r#type() {
            prost_types::field_descriptor_proto::Type::Double => "double".to_string(),
            prost_types::field_descriptor_proto::Type::Float => "float".to_string(),
            prost_types::field_descriptor_proto::Type::Int64 => "int64".to_string(),
            prost_types::field_descriptor_proto::Type::Uint64 => "uint64".to_string(),
            prost_types::field_descriptor_proto::Type::Int32 => "int32".to_string(),
            prost_types::field_descriptor_proto::Type::Fixed64 => "fixed64".to_string(),
            prost_types::field_descriptor_proto::Type::Fixed32 => "fixed32".to_string(),
            prost_types::field_descriptor_proto::Type::Bool => "bool".to_string(),
            prost_types::field_descriptor_proto::Type::String => "string".to_string(),
            prost_types::field_descriptor_proto::Type::Group => "group".to_string(),
            prost_types::field_descriptor_proto::Type::Message => {
                descriptor.type_name.clone().unwrap_or_default()
            }
            prost_types::field_descriptor_proto::Type::Bytes => "bytes".to_string(),
            prost_types::field_descriptor_proto::Type::Uint32 => "uint32".to_string(),
            prost_types::field_descriptor_proto::Type::Enum => {
                descriptor.type_name.clone().unwrap_or_default()
            }
            prost_types::field_descriptor_proto::Type::Sfixed32 => "sfixed32".to_string(),
            prost_types::field_descriptor_proto::Type::Sfixed64 => "sfixed64".to_string(),
            prost_types::field_descriptor_proto::Type::Sint32 => "sint32".to_string(),
            prost_types::field_descriptor_proto::Type::Sint64 => "sint64".to_string(),
        };

        // Extract Axiom field options
        let axiom_field_options = MetadataExtractor::extract_field_options(&descriptor.options, &name)?;
        let field_options = FieldOptions {
            axiom_field: axiom_field_options,
            standard_options: HashMap::new(),
        };

        Ok(Field {
            name,
            field_type,
            number: descriptor.number.unwrap_or(0),
            label,
            default_value: descriptor.default_value,
            options: field_options,
            documentation: None,
        })
    }

    /// Convert EnumDescriptorProto to Enum
    fn convert_enum(
        &self,
        descriptor: EnumDescriptorProto,
        package: &str,
        file_path: &Path,
    ) -> Result<Enum> {
        let name = descriptor.name.unwrap_or_default();
        let mut values = Vec::new();

        for value_desc in descriptor.value {
            let value = EnumValue {
                name: value_desc.name.unwrap_or_default(),
                number: value_desc.number.unwrap_or(0),
                options: EnumValueOptions::default(),
                documentation: None,
            };
            values.push(value);
        }

        Ok(Enum {
            name,
            package: package.to_string(),
            file_path: file_path.to_string_lossy().to_string(),
            values,
            options: EnumOptions::default(),
            documentation: None,
        })
    }

    /// Parse a single proto file 
    pub async fn parse_proto_file(&self, file_path: &std::path::Path) -> Result<ProtoSchema> {
        self.parse_file(file_path).await
    }

    /// Parse all proto files in a directory
    pub async fn parse_proto_directory(&self, dir_path: &std::path::Path) -> Result<ProtoSchema> {
        self.parse(dir_path.to_string_lossy().as_ref()).await
    }

    /// Merge a parsed schema into the main schema
    fn merge_schema(&self, main_schema: &mut ProtoSchema, file_schema: ProtoSchema) -> Result<()> {
        main_schema.files.extend(file_schema.files);
        main_schema.services.extend(file_schema.services);
        main_schema.messages.extend(file_schema.messages);
        main_schema.enums.extend(file_schema.enums);
        main_schema.dependencies.extend(file_schema.dependencies);

        // Remove duplicates
        main_schema.dependencies.sort();
        main_schema.dependencies.dedup();

        Ok(())
    }

    /// Extract package name from proto content
    fn extract_package_from_content(&self, content: &str) -> String {
        for line in content.lines() {
            let line = line.trim();
            if line.starts_with("package ") {
                let package = line
                    .strip_prefix("package ")
                    .unwrap_or("")
                    .trim_end_matches(';')
                    .trim();
                return package.to_string();
            }
        }
        "unknown".to_string()
    }

    /// Extract services from proto content
    fn extract_services_from_content(&self, content: &str) -> Vec<ServiceDescriptorProto> {
        let mut services = Vec::new();
        let mut current_service: Option<String> = None;
        let mut methods = Vec::new();
        let mut brace_count = 0;

        for line in content.lines() {
            let line = line.trim();
            
            if line.starts_with("service ") {
                let service_name = line
                    .strip_prefix("service ")
                    .unwrap_or("")
                    .split_whitespace()
                    .next()
                    .unwrap_or("")
                    .to_string();
                current_service = Some(service_name);
                methods.clear();
                brace_count = 0;
            }
            
            if line.contains('{') {
                brace_count += line.matches('{').count();
            }
            if line.contains('}') {
                let close_count = line.matches('}').count();
                brace_count = brace_count.saturating_sub(close_count);
                
                // End of service definition
                if brace_count == 0 && current_service.is_some() {
                    let service_name = current_service.take().unwrap();
                    services.push(ServiceDescriptorProto {
                        name: Some(service_name),
                        method: methods.clone(),
                        options: None,
                    });
                    methods.clear();
                }
            }
            
            if current_service.is_some() && line.starts_with("rpc ") {
                let method = self.parse_rpc_method(line);
                if let Some(method) = method {
                    methods.push(method);
                }
            }
        }

        services
    }

    /// Parse an RPC method from a line
    fn parse_rpc_method(&self, line: &str) -> Option<MethodDescriptorProto> {
        // Parse line like: "rpc CreateTask(CreateTaskRequest) returns (CreateTaskResponse);"
        let line = line.trim().strip_prefix("rpc ")?;
        
        let parts: Vec<&str> = line.split('(').collect();
        if parts.len() < 2 {
            return None;
        }
        
        let method_name = parts[0].trim().to_string();
        
        // Extract input type
        let input_part = parts[1].split(')').next()?;
        let input_type = input_part.trim().to_string();
        
        // Extract output type
        let output_part = line.split("returns").nth(1)?;
        let output_type = output_part
            .trim()
            .strip_prefix('(')?
            .split(')')
            .next()?
            .trim()
            .to_string();

        Some(MethodDescriptorProto {
            name: Some(method_name),
            input_type: Some(input_type),
            output_type: Some(output_type),
            options: None,
            client_streaming: Some(false),
            server_streaming: Some(false),
        })
    }

    /// Extract messages from proto content
    fn extract_messages_from_content(&self, content: &str) -> Vec<DescriptorProto> {
        let mut messages = Vec::new();
        let mut current_message: Option<String> = None;
        let mut fields = Vec::new();
        let mut brace_count = 0;

        for line in content.lines() {
            let line = line.trim();
            
            if line.starts_with("message ") {
                let message_name = line
                    .strip_prefix("message ")
                    .unwrap_or("")
                    .split_whitespace()
                    .next()
                    .unwrap_or("")
                    .to_string();
                current_message = Some(message_name);
                fields.clear();
                brace_count = 0;
            }
            
            if line.contains('{') {
                brace_count += line.matches('{').count();
            }
            if line.contains('}') {
                let close_count = line.matches('}').count();
                brace_count = brace_count.saturating_sub(close_count);
                
                // End of message definition
                if brace_count == 0 && current_message.is_some() {
                    let message_name = current_message.take().unwrap();
                    messages.push(DescriptorProto {
                        name: Some(message_name),
                        field: fields.clone(),
                        extension: vec![],
                        nested_type: vec![],
                        enum_type: vec![],
                        extension_range: vec![],
                        oneof_decl: vec![],
                        options: None,
                        reserved_range: vec![],
                        reserved_name: vec![],
                    });
                    fields.clear();
                }
            }
            
            if current_message.is_some() && line.contains(" = ") && !line.starts_with("//") {
                let field = self.parse_message_field(line);
                if let Some(field) = field {
                    fields.push(field);
                }
            }
        }

        messages
    }

    /// Parse a message field from a line
    fn parse_message_field(&self, line: &str) -> Option<FieldDescriptorProto> {
        // Parse line like: "string title = 1;" or "repeated Address addresses = 4;"
        let parts: Vec<&str> = line.trim().split('=').collect();
        if parts.len() != 2 {
            return None;
        }
        
        let left_part = parts[0].trim();
        let right_part = parts[1].trim().trim_end_matches(';');
        
        let field_number: i32 = right_part.parse().ok()?;
        
        let left_parts: Vec<&str> = left_part.split_whitespace().collect();
        if left_parts.len() < 2 {
            return None;
        }
        
        // Handle repeated fields
        let (label, type_start_idx) = if left_parts[0] == "repeated" {
            (3, 1) // LABEL_REPEATED = 3
        } else {
            (1, 0) // LABEL_OPTIONAL = 1
        };
        
        if left_parts.len() <= type_start_idx + 1 {
            return None;
        }
        
        let field_type = left_parts[type_start_idx].to_string();
        let field_name = left_parts[type_start_idx + 1].to_string();

        Some(FieldDescriptorProto {
            name: Some(field_name),
            number: Some(field_number),
            label: Some(label),
            r#type: Some(self.convert_field_type(&field_type)),
            type_name: if self.is_primitive_type(&field_type) { 
                None 
            } else { 
                Some(field_type) 
            },
            extendee: None,
            default_value: None,
            oneof_index: None,
            json_name: None,
            options: None,
            proto3_optional: None,
        })
    }

    /// Convert field type to proto field type enum
    fn convert_field_type(&self, field_type: &str) -> i32 {
        match field_type {
            "string" => 9,    // TYPE_STRING
            "int32" => 5,     // TYPE_INT32
            "int64" => 3,     // TYPE_INT64
            "bool" => 8,      // TYPE_BOOL
            "float" => 2,     // TYPE_FLOAT
            "double" => 1,    // TYPE_DOUBLE
            "bytes" => 12,    // TYPE_BYTES
            _ => 11,          // TYPE_MESSAGE
        }
    }

    /// Check if field type is primitive
    fn is_primitive_type(&self, field_type: &str) -> bool {
        matches!(field_type, "string" | "int32" | "int64" | "bool" | "float" | "double" | "bytes")
    }

    /// Extract enums from proto content
    fn extract_enums_from_content(&self, _content: &str) -> Vec<EnumDescriptorProto> {
        // For MVP, we'll implement basic enum parsing later if needed
        vec![]
    }
}