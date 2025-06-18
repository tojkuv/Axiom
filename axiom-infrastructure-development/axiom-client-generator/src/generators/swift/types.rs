//! Swift type definitions and utilities

use crate::proto::types::*;
use serde::{Deserialize, Serialize};

/// Swift-specific type mappings and utilities
#[derive(Debug, Clone)]
pub struct SwiftTypeMapper;

impl SwiftTypeMapper {
    /// Convert proto type to Swift type
    pub fn proto_to_swift_type(proto_type: &str) -> String {
        match proto_type {
            "string" => "String".to_string(),
            "bool" => "Bool".to_string(),
            "int32" | "sint32" | "sfixed32" => "Int32".to_string(),
            "int64" | "sint64" | "sfixed64" => "Int64".to_string(),
            "uint32" | "fixed32" => "UInt32".to_string(),
            "uint64" | "fixed64" => "UInt64".to_string(),
            "float" => "Float".to_string(),
            "double" => "Double".to_string(),
            "bytes" => "Data".to_string(),
            _ if proto_type.contains("Timestamp") => "Date".to_string(),
            _ if proto_type.contains("Duration") => "TimeInterval".to_string(),
            _ if proto_type.contains("Empty") => "Void".to_string(),
            _ if proto_type.starts_with('.') => {
                // Handle fully qualified types like .google.protobuf.Timestamp
                proto_type.split('.').last().unwrap_or(proto_type).to_string()
            },
            _ => proto_type.to_string(),
        }
    }

    /// Check if a type should be optional
    pub fn is_optional_type(field: &Field) -> bool {
        matches!(field.label, FieldLabel::Optional)
    }

    /// Check if a type is a collection type
    pub fn is_collection_type(field: &Field) -> bool {
        matches!(field.label, FieldLabel::Repeated)
    }

    /// Convert to Swift collection type
    pub fn to_swift_collection_type(element_type: &str) -> String {
        format!("[{}]", Self::proto_to_swift_type(element_type))
    }
}

/// Swift naming utilities
#[derive(Debug, Clone)]
pub struct SwiftNamingUtils;

impl SwiftNamingUtils {
    /// Convert to PascalCase for types
    pub fn to_pascal_case(input: &str) -> String {
        use heck::ToPascalCase;
        input.to_pascal_case()
    }

    /// Convert to camelCase for properties and methods
    pub fn to_camel_case(input: &str) -> String {
        use heck::ToLowerCamelCase;
        let camel = input.to_lower_camel_case();
        
        // Handle Swift reserved words
        match camel.as_str() {
            "class" | "struct" | "enum" | "protocol" | "extension" | "func" | "var" | "let" |
            "if" | "else" | "for" | "while" | "do" | "switch" | "case" | "default" |
            "break" | "continue" | "return" | "throw" | "throws" | "try" | "catch" |
            "import" | "public" | "private" | "internal" | "fileprivate" | "open" |
            "static" | "final" | "override" | "required" | "convenience" | "lazy" |
            "weak" | "unowned" | "indirect" | "mutating" | "nonmutating" | "dynamic" |
            "optional" | "inout" | "associatedtype" | "precedencegroup" | "operator" |
            "prefix" | "postfix" | "infix" | "left" | "right" | "none" | "assignment" => {
                format!("`{}`", camel)
            }
            _ => camel,
        }
    }

    /// Check if identifier is a Swift reserved word
    pub fn is_reserved_word(word: &str) -> bool {
        matches!(word,
            "class" | "struct" | "enum" | "protocol" | "extension" | "func" | "var" | "let" |
            "if" | "else" | "for" | "while" | "do" | "switch" | "case" | "default" |
            "break" | "continue" | "return" | "throw" | "throws" | "try" | "catch" |
            "import" | "public" | "private" | "internal" | "fileprivate" | "open" |
            "static" | "final" | "override" | "required" | "convenience" | "lazy" |
            "weak" | "unowned" | "indirect" | "mutating" | "nonmutating" | "dynamic" |
            "optional" | "inout" | "associatedtype" | "precedencegroup" | "operator" |
            "prefix" | "postfix" | "infix" | "left" | "right" | "none" | "assignment"
        )
    }
}

/// Swift code generation context
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SwiftGenerationContext {
    /// Service being generated
    pub service: Service,
    /// Messages in the service
    pub messages: Vec<Message>,
    /// Enums in the service
    pub enums: Vec<Enum>,
    /// Swift-specific configuration
    pub swift_config: SwiftConfig,
}

/// Swift framework configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SwiftConfig {
    /// Target Axiom Swift framework version
    pub axiom_version: Option<String>,
    /// Suffix for generated client classes
    pub client_suffix: Option<String>,
    /// Generate XCTest files
    pub generate_tests: Option<bool>,
    /// Swift package name for imports
    pub package_name: Option<String>,
    /// Additional imports to include
    pub additional_imports: Vec<String>,
}

impl Default for SwiftConfig {
    fn default() -> Self {
        Self {
            axiom_version: Some("1.0.0".to_string()),
            client_suffix: Some("Client".to_string()),
            generate_tests: Some(false),
            package_name: None,
            additional_imports: vec![
                "Foundation".to_string(),
                "AxiomCore".to_string(),
                "AxiomArchitecture".to_string(),
            ],
        }
    }
}

/// Swift template context for rendering
#[derive(Debug, Clone, Serialize)]
pub struct SwiftTemplateContext {
    /// Service name
    pub service_name: String,
    /// Client class name
    pub client_name: String,
    /// State struct name
    pub state_name: String,
    /// Action enum name
    pub action_name: String,
    /// Methods in the service
    pub methods: Vec<SwiftMethod>,
    /// Message types
    pub messages: Vec<SwiftMessage>,
    /// Enum types
    pub enums: Vec<SwiftEnum>,
    /// Import statements
    pub imports: Vec<String>,
    /// Package name
    pub package_name: Option<String>,
}

/// Swift method representation
#[derive(Debug, Clone, Serialize)]
pub struct SwiftMethod {
    /// Method name in Swift style
    pub name: String,
    /// Input parameter type
    pub input_type: String,
    /// Output return type
    pub output_type: String,
    /// Whether method is async
    pub is_async: bool,
    /// Whether method throws
    pub throws: bool,
    /// State update strategy
    pub state_update: String,
    /// Documentation
    pub documentation: Option<String>,
}

/// Swift message representation
#[derive(Debug, Clone, Serialize)]
pub struct SwiftMessage {
    /// Message name in Swift style
    pub name: String,
    /// Fields in the message
    pub fields: Vec<SwiftField>,
    /// Whether this is a state root
    pub is_state_root: bool,
    /// Documentation
    pub documentation: Option<String>,
}

/// Swift field representation
#[derive(Debug, Clone, Serialize)]
pub struct SwiftField {
    /// Field name in Swift style
    pub name: String,
    /// Field type in Swift
    pub field_type: String,
    /// Whether field is optional
    pub is_optional: bool,
    /// Whether field is a collection
    pub is_collection: bool,
    /// Default value if any
    pub default_value: Option<String>,
    /// Documentation
    pub documentation: Option<String>,
}

/// Swift enum representation
#[derive(Debug, Clone, Serialize)]
pub struct SwiftEnum {
    /// Enum name in Swift style
    pub name: String,
    /// Cases in the enum
    pub cases: Vec<SwiftEnumCase>,
    /// Documentation
    pub documentation: Option<String>,
}

/// Swift enum case representation
#[derive(Debug, Clone, Serialize)]
pub struct SwiftEnumCase {
    /// Case name in Swift style
    pub name: String,
    /// Raw value if any
    pub raw_value: Option<i32>,
    /// Documentation
    pub documentation: Option<String>,
}