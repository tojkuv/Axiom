use heck::{ToPascalCase, ToSnakeCase, ToLowerCamelCase};

/// Swift naming convention handler
pub struct SwiftNaming;

impl SwiftNaming {
    /// Create a new Swift naming handler
    pub fn new() -> Self {
        Self
    }

    /// Convert to Swift class/struct name (PascalCase)
    pub fn type_name(&self, name: &str) -> String {
        name.to_pascal_case()
    }

    /// Convert to Swift property name (camelCase)
    pub fn property_name(&self, name: &str) -> String {
        let camel = name.to_lower_camel_case();
        // Handle Swift reserved words
        self.escape_reserved_word(&camel)
    }

    /// Convert to Swift method name (camelCase)
    pub fn method_name(&self, name: &str) -> String {
        let camel = name.to_lower_camel_case();
        self.escape_reserved_word(&camel)
    }

    /// Convert to Swift enum case name (camelCase)
    pub fn enum_case_name(&self, name: &str) -> String {
        // Remove common prefixes for cleaner enum cases
        let cleaned = self.clean_enum_case(name);
        let camel = cleaned.to_lower_camel_case();
        self.escape_reserved_word(&camel)
    }

    /// Convert to Swift constant name (camelCase)
    pub fn constant_name(&self, name: &str) -> String {
        name.to_lower_camel_case()
    }

    /// Convert to Swift file name
    pub fn file_name(&self, name: &str) -> String {
        format!("{}.swift", name.to_pascal_case())
    }

    /// Generate Swift client name
    pub fn client_name(&self, service_name: &str) -> String {
        let base = if service_name.ends_with("Service") {
            &service_name[..service_name.len() - 7]
        } else {
            service_name
        };
        format!("{}Client", base.to_pascal_case())
    }

    /// Generate Swift state name
    pub fn state_name(&self, service_name: &str) -> String {
        let base = if service_name.ends_with("Service") {
            &service_name[..service_name.len() - 7]
        } else {
            service_name
        };
        format!("{}State", base.to_pascal_case())
    }

    /// Generate Swift action name
    pub fn action_name(&self, service_name: &str) -> String {
        let base = if service_name.ends_with("Service") {
            &service_name[..service_name.len() - 7]
        } else {
            service_name
        };
        format!("{}Action", base.to_pascal_case())
    }

    /// Generate collection property name for state
    pub fn collection_property_name(&self, entity_name: &str) -> String {
        let singular = self.singularize(entity_name);
        self.pluralize(&singular.to_lower_camel_case())
    }

    /// Convert proto field type to Swift type
    pub fn swift_type(&self, proto_type: &str) -> String {
        match proto_type {
            "double" => "Double".to_string(),
            "float" => "Float".to_string(),
            "int32" | "sint32" | "sfixed32" => "Int32".to_string(),
            "int64" | "sint64" | "sfixed64" => "Int64".to_string(),
            "uint32" | "fixed32" => "UInt32".to_string(),
            "uint64" | "fixed64" => "UInt64".to_string(),
            "bool" => "Bool".to_string(),
            "string" => "String".to_string(),
            "bytes" => "Data".to_string(),
            _ => {
                // Handle message and enum types
                if proto_type.starts_with('.') {
                    // Fully qualified type name
                    let parts: Vec<&str> = proto_type.split('.').collect();
                    parts.last().map_or(proto_type, |v| v).to_pascal_case()
                } else if proto_type.contains("Timestamp") {
                    "Date".to_string()
                } else if proto_type.contains("Empty") {
                    "Void".to_string()
                } else {
                    proto_type.to_pascal_case()
                }
            }
        }
    }

    /// Check if field should be optional in Swift
    pub fn is_optional_field(&self, proto_type: &str, field_name: &str) -> bool {
        // Proto3 fields are optional by default except for primitives with zero values
        match proto_type {
            "bool" | "int32" | "int64" | "uint32" | "uint64" | "float" | "double" => false,
            "string" => field_name.to_lowercase().contains("optional") || field_name.ends_with("?"),
            _ => true, // Messages, enums, and other types are optional
        }
    }

    /// Escape Swift reserved words
    fn escape_reserved_word(&self, word: &str) -> String {
        match word {
            // Swift keywords
            "class" | "struct" | "enum" | "protocol" | "extension" | "func" | "var" | "let" |
            "if" | "else" | "for" | "while" | "do" | "switch" | "case" | "default" |
            "break" | "continue" | "return" | "throw" | "throws" | "try" | "catch" |
            "import" | "public" | "private" | "internal" | "fileprivate" | "open" |
            "static" | "final" | "override" | "required" | "convenience" | "init" |
            "deinit" | "subscript" | "operator" | "precedencegroup" | "associatedtype" |
            "typealias" | "where" | "is" | "as" | "any" | "some" | "Self" | "super" |
            "nil" | "true" | "false" | "self" | "Type" | "Protocol" => {
                format!("`{}`", word)
            }
            _ => word.to_string(),
        }
    }

    /// Clean enum case names by removing common prefixes
    fn clean_enum_case(&self, name: &str) -> String {
        // Remove common enum prefixes
        let prefixes = [
            "TASK_PRIORITY_",
            "USER_STATUS_",
            "ORDER_STATE_",
            "PAYMENT_METHOD_",
        ];
        
        for prefix in &prefixes {
            if name.starts_with(prefix) {
                return name[prefix.len()..].to_string();
            }
        }

        // Remove generic prefixes
        if let Some(underscore_pos) = name.find('_') {
            let potential_prefix = &name[..underscore_pos + 1];
            if potential_prefix.chars().all(|c| c.is_uppercase() || c == '_') {
                return name[underscore_pos + 1..].to_string();
            }
        }

        name.to_string()
    }

    /// Simple pluralization for English words
    fn pluralize(&self, word: &str) -> String {
        if word.is_empty() {
            return word.to_string();
        }

        let lower = word.to_lowercase();
        
        // Special cases
        match lower.as_str() {
            "child" => "children".to_string(),
            "person" => "people".to_string(),
            "man" => "men".to_string(),
            "woman" => "women".to_string(),
            "foot" => "feet".to_string(),
            "tooth" => "teeth".to_string(),
            "mouse" => "mice".to_string(),
            "goose" => "geese".to_string(),
            _ => {
                if lower.ends_with('s') || lower.ends_with("sh") || lower.ends_with("ch") || 
                   lower.ends_with('x') || lower.ends_with('z') {
                    format!("{}es", word)
                } else if lower.ends_with('y') && word.len() > 1 {
                    let second_last = word.chars().nth(word.len() - 2).unwrap();
                    if !"aeiou".contains(second_last) {
                        format!("{}ies", &word[..word.len() - 1])
                    } else {
                        format!("{}s", word)
                    }
                } else {
                    format!("{}s", word)
                }
            }
        }
    }

    /// Simple singularization for English words
    fn singularize(&self, word: &str) -> String {
        if word.is_empty() {
            return word.to_string();
        }

        let lower = word.to_lowercase();
        
        // Special cases
        match lower.as_str() {
            "children" => "child".to_string(),
            "people" => "person".to_string(),
            "men" => "man".to_string(),
            "women" => "woman".to_string(),
            "feet" => "foot".to_string(),
            "teeth" => "tooth".to_string(),
            "mice" => "mouse".to_string(),
            "geese" => "goose".to_string(),
            _ => {
                if lower.ends_with("ies") && word.len() > 3 {
                    // Don't change the case, just remove 'ies' and add 'y'
                    format!("{}y", &word[..word.len() - 3])
                } else if lower.ends_with("es") && word.len() > 2 {
                    let without_es = &word[..word.len() - 2];
                    let lower_without_es = without_es.to_lowercase();
                    if lower_without_es.ends_with('s') || lower_without_es.ends_with("sh") || 
                       lower_without_es.ends_with("ch") || lower_without_es.ends_with('x') || 
                       lower_without_es.ends_with('z') {
                        without_es.to_string()
                    } else {
                        word[..word.len() - 1].to_string()
                    }
                } else if lower.ends_with('s') && word.len() > 1 {
                    word[..word.len() - 1].to_string()
                } else {
                    word.to_string()
                }
            }
        }
    }
}