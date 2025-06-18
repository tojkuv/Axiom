use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Complete proto schema representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtoSchema {
    /// List of proto files
    pub files: Vec<ProtoFile>,
    /// All services across all files
    pub services: Vec<Service>,
    /// All messages across all files
    pub messages: Vec<Message>,
    /// All enums across all files
    pub enums: Vec<Enum>,
    /// Import dependencies
    pub dependencies: Vec<String>,
}

/// Individual proto file representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtoFile {
    /// File path
    pub path: String,
    /// Package name
    pub package: String,
    /// Syntax version (proto2 or proto3)
    pub syntax: String,
    /// Import statements
    pub imports: Vec<String>,
    /// Services defined in this file
    pub services: Vec<String>,
    /// Messages defined in this file
    pub messages: Vec<String>,
    /// Enums defined in this file
    pub enums: Vec<String>,
}

/// gRPC service definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Service {
    /// Service name
    pub name: String,
    /// Package containing this service
    pub package: String,
    /// File where this service is defined
    pub file_path: String,
    /// Service methods
    pub methods: Vec<Method>,
    /// Service-level options
    pub options: ServiceOptions,
    /// Documentation/comments
    pub documentation: Option<String>,
}

/// gRPC service method
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Method {
    /// Method name
    pub name: String,
    /// Input message type
    pub input_type: String,
    /// Output message type
    pub output_type: String,
    /// Whether input is streaming
    pub client_streaming: bool,
    /// Whether output is streaming
    pub server_streaming: bool,
    /// Method-level options
    pub options: MethodOptions,
    /// Documentation/comments
    pub documentation: Option<String>,
}

/// Proto message definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    /// Message name
    pub name: String,
    /// Package containing this message
    pub package: String,
    /// File where this message is defined
    pub file_path: String,
    /// Message fields
    pub fields: Vec<Field>,
    /// Nested messages
    pub nested_messages: Vec<Message>,
    /// Nested enums
    pub nested_enums: Vec<Enum>,
    /// Message-level options
    pub options: MessageOptions,
    /// Documentation/comments
    pub documentation: Option<String>,
}

/// Proto message field
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Field {
    /// Field name
    pub name: String,
    /// Field type (string, int32, bool, etc.)
    pub field_type: String,
    /// Field number
    pub number: i32,
    /// Field label (optional, required, repeated)
    pub label: FieldLabel,
    /// Default value if any
    pub default_value: Option<String>,
    /// Field-level options
    pub options: FieldOptions,
    /// Documentation/comments
    pub documentation: Option<String>,
}

/// Field label types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum FieldLabel {
    Optional,
    Required,
    Repeated,
}

/// Proto enum definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Enum {
    /// Enum name
    pub name: String,
    /// Package containing this enum
    pub package: String,
    /// File where this enum is defined
    pub file_path: String,
    /// Enum values
    pub values: Vec<EnumValue>,
    /// Enum-level options
    pub options: EnumOptions,
    /// Documentation/comments
    pub documentation: Option<String>,
}

/// Proto enum value
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnumValue {
    /// Value name
    pub name: String,
    /// Value number
    pub number: i32,
    /// Value-level options
    pub options: EnumValueOptions,
    /// Documentation/comments
    pub documentation: Option<String>,
}

/// Service-level options including Axiom-specific ones
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ServiceOptions {
    /// Axiom-specific service options
    pub axiom_service: Option<AxiomServiceOptions>,
    /// Standard gRPC options
    pub standard_options: HashMap<String, String>,
}

/// Method-level options including Axiom-specific ones
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct MethodOptions {
    /// Axiom-specific method options
    pub axiom_method: Option<AxiomMethodOptions>,
    /// Standard gRPC options
    pub standard_options: HashMap<String, String>,
}

/// Message-level options including Axiom-specific ones
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct MessageOptions {
    /// Axiom-specific message options
    pub axiom_message: Option<AxiomMessageOptions>,
    /// Standard proto options
    pub standard_options: HashMap<String, String>,
}

/// Field-level options
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct FieldOptions {
    /// Axiom-specific field options
    pub axiom_field: Option<AxiomFieldOptions>,
    /// Standard proto field options
    pub standard_options: HashMap<String, String>,
}

/// Enum-level options
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct EnumOptions {
    /// Standard proto enum options
    pub standard_options: HashMap<String, String>,
}

/// Enum value-level options
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct EnumValueOptions {
    /// Standard proto enum value options
    pub standard_options: HashMap<String, String>,
}

/// Axiom-specific service options
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AxiomServiceOptions {
    /// Override default client name
    pub client_name: Option<String>,
    /// Override default state name
    pub state_name: Option<String>,
    /// Override default action name
    pub action_name: Option<String>,
    /// Base import modules for generated Swift code
    pub import_modules: Vec<String>,
    /// Whether to generate test files
    pub generate_tests: Option<bool>,
    /// Custom package name for Swift imports
    pub swift_package_name: Option<String>,
    /// Collections managed by this service
    pub collections: Vec<AxiomCollection>,
    /// Whether this service supports pagination
    pub supports_pagination: Option<bool>,
}

/// Axiom-specific method options
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct AxiomMethodOptions {
    /// How this method affects state
    pub state_update_strategy: StateUpdateStrategy,
    /// Target collection for updates
    pub collection_name: Option<String>,
    /// Whether this method requires network access
    pub requires_network: Option<bool>,
    /// Whether this method modifies state
    pub modifies_state: Option<bool>,
    /// Whether to show loading state for this action
    pub show_loading_state: Option<bool>,
    /// Validation rules for the input
    pub validation_rules: Vec<String>,
    /// Custom documentation for the generated action
    pub action_documentation: Option<String>,
    /// ID field name for operations that work with specific entities
    pub id_field_name: Option<String>,
    /// Whether this method can be executed offline
    pub supports_offline: Option<bool>,
    /// Cache strategy for this method
    pub cache_strategy: CacheStrategy,
}

/// Axiom-specific message options
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AxiomMessageOptions {
    /// Generate Identifiable conformance (Swift)
    pub identifiable: bool,
    /// Field to use as identifier
    pub id_field: Option<String>,
    /// Generate Equatable conformance
    pub equatable: bool,
    /// Additional computed properties
    pub derived_properties: Vec<String>,
}

/// Axiom-specific field options
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AxiomFieldOptions {
    /// Whether this field is used for entity identification
    pub is_id_field: Option<bool>,
    /// Whether this field should be indexed for search
    pub searchable: Option<bool>,
    /// Whether this field can be sorted on
    pub sortable: Option<bool>,
    /// Whether this field is required for validation
    pub required: Option<bool>,
    /// Custom validation pattern (regex)
    pub validation_pattern: Option<String>,
    /// Minimum value for numeric fields
    pub min_value: Option<f64>,
    /// Maximum value for numeric fields
    pub max_value: Option<f64>,
    /// Minimum length for string fields
    pub min_length: Option<i32>,
    /// Maximum length for string fields
    pub max_length: Option<i32>,
    /// Whether this field should be excluded from state equality checks
    pub exclude_from_equality: Option<bool>,
}

/// Collection configuration for state management
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AxiomCollection {
    /// Name of the collection (e.g., "tasks")
    pub name: String,
    /// Type of items in the collection (e.g., "Task")
    pub item_type: String,
    /// Primary key field name for items in this collection
    pub primary_key: Option<String>,
    /// Whether this collection supports pagination
    pub paginated: Option<bool>,
    /// Default sort field for this collection
    pub default_sort_field: Option<String>,
    /// Whether this collection supports search
    pub searchable: Option<bool>,
    /// Maximum number of items to keep in memory
    pub max_cached_items: Option<i32>,
}

/// State update strategies for Axiom framework integration
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum StateUpdateStrategy {
    /// Strategy not specified
    Unspecified,
    /// Add new item to collection
    Append,
    /// Replace entire collection
    ReplaceAll,
    /// Update existing item by ID
    UpdateById,
    /// Remove item by ID
    RemoveById,
    /// Custom update logic required
    Custom,
    /// Method doesn't change state
    NoChange,
}

impl Default for StateUpdateStrategy {
    fn default() -> Self {
        StateUpdateStrategy::Unspecified
    }
}

/// Cache strategies for methods
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum CacheStrategy {
    /// Strategy not specified
    Unspecified,
    /// No caching
    None,
    /// Cache in memory
    Memory,
    /// Cache persistently
    Persistent,
    /// Cache based on conditions
    Conditional,
}

impl Default for CacheStrategy {
    fn default() -> Self {
        CacheStrategy::Unspecified
    }
}

impl Default for ProtoSchema {
    fn default() -> Self {
        Self::new()
    }
}

impl ProtoSchema {
    /// Create a new empty proto schema
    pub fn new() -> Self {
        Self {
            files: Vec::new(),
            services: Vec::new(),
            messages: Vec::new(),
            enums: Vec::new(),
            dependencies: Vec::new(),
        }
    }

    /// Find a service by name
    pub fn find_service(&self, name: &str) -> Option<&Service> {
        self.services.iter().find(|s| s.name == name)
    }

    /// Find a message by name
    pub fn find_message(&self, name: &str) -> Option<&Message> {
        self.messages.iter().find(|m| m.name == name)
    }

    /// Find an enum by name
    pub fn find_enum(&self, name: &str) -> Option<&Enum> {
        self.enums.iter().find(|e| e.name == name)
    }

    /// Get all services in a specific package
    pub fn services_in_package(&self, package: &str) -> Vec<&Service> {
        self.services.iter().filter(|s| s.package == package).collect()
    }
}

/// Type aliases for backward compatibility with tests
pub type ProtoService = Service;
pub type ProtoMessage = Message;
pub type ProtoField = Field;
pub type ProtoMethod = Method;
pub type ProtoEnum = Enum;