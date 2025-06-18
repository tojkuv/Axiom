use heck::{ToLowerCamelCase, ToPascalCase, ToSnakeCase, ToKebabCase};

/// Cross-language naming utilities
pub struct NamingUtils;

impl NamingUtils {
    /// Convert to camelCase
    pub fn to_camel_case(input: &str) -> String {
        input.to_lower_camel_case()
    }

    /// Convert to PascalCase
    pub fn to_pascal_case(input: &str) -> String {
        input.to_pascal_case()
    }

    /// Convert to snake_case
    pub fn to_snake_case(input: &str) -> String {
        input.to_snake_case()
    }

    /// Convert to kebab-case
    pub fn to_kebab_case(input: &str) -> String {
        input.to_kebab_case()
    }

    /// Convert proto service name to client name
    pub fn service_to_client_name(service_name: &str) -> String {
        let base = if service_name.ends_with("Service") {
            &service_name[..service_name.len() - 7]
        } else {
            service_name
        };
        format!("{}Client", base.to_pascal_case())
    }

    /// Convert proto service name to state name
    pub fn service_to_state_name(service_name: &str) -> String {
        let base = if service_name.ends_with("Service") {
            &service_name[..service_name.len() - 7]
        } else {
            service_name
        };
        format!("{}State", base.to_pascal_case())
    }

    /// Convert proto service name to action name
    pub fn service_to_action_name(service_name: &str) -> String {
        let base = if service_name.ends_with("Service") {
            &service_name[..service_name.len() - 7]
        } else {
            service_name
        };
        format!("{}Action", base.to_pascal_case())
    }

    /// Sanitize filename for filesystem
    pub fn sanitize_filename(name: &str) -> String {
        name.chars()
            .map(|c| match c {
                '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
                c if c.is_control() => '_',
                c => c,
            })
            .collect()
    }

    /// Generate unique identifier
    pub fn generate_unique_id(prefix: &str) -> String {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis();
        format!("{}_{}", prefix, timestamp)
    }

    /// Pluralize English word (simple implementation)
    pub fn pluralize(word: &str) -> String {
        if word.is_empty() {
            return word.to_string();
        }

        let lower = word.to_lowercase();
        
        match lower.as_str() {
            "child" => "children".to_string(),
            "person" => "people".to_string(),
            "man" => "men".to_string(),
            "woman" => "women".to_string(),
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

    /// Singularize English word (simple implementation)
    pub fn singularize(word: &str) -> String {
        if word.is_empty() {
            return word.to_string();
        }

        let lower = word.to_lowercase();
        
        match lower.as_str() {
            "children" => "child".to_string(),
            "people" => "person".to_string(),
            "men" => "man".to_string(),
            "women" => "woman".to_string(),
            _ => {
                if lower.ends_with("ies") && word.len() > 3 {
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

    /// Check if string is valid identifier in most languages
    pub fn is_valid_identifier(name: &str) -> bool {
        if name.is_empty() {
            return false;
        }

        let first_char = name.chars().next().unwrap();
        if !first_char.is_alphabetic() && first_char != '_' {
            return false;
        }

        name.chars().all(|c| c.is_alphanumeric() || c == '_')
    }

    /// Make string a valid identifier
    pub fn make_valid_identifier(name: &str) -> String {
        if name.is_empty() {
            return "identifier".to_string();
        }

        let mut result = String::new();
        
        for (i, c) in name.chars().enumerate() {
            if i == 0 {
                if c.is_alphabetic() || c == '_' {
                    result.push(c);
                } else {
                    result.push('_');
                    if c.is_alphanumeric() {
                        result.push(c);
                    }
                }
            } else if c.is_alphanumeric() || c == '_' {
                result.push(c);
            } else {
                result.push('_');
            }
        }

        if result.is_empty() {
            "identifier".to_string()
        } else {
            result
        }
    }
}

/// Swift-specific naming conventions
pub fn to_swift_type_name(s: &str) -> String {
    // Handle Unicode properly by preserving non-ASCII characters
    if s.is_ascii() {
        handle_acronyms(&s.to_pascal_case())
    } else {
        // For non-ASCII strings, do manual case conversion to preserve Unicode
        let mut result = String::new();
        let mut capitalize_next = true;
        
        for c in s.chars() {
            if c.is_ascii_alphabetic() {
                if capitalize_next {
                    result.push(c.to_ascii_uppercase());
                    capitalize_next = false;
                } else {
                    result.push(c.to_ascii_lowercase());
                }
            } else if c.is_alphabetic() {
                // For Unicode letters, preserve them as-is and capitalize if needed
                if capitalize_next {
                    result.extend(c.to_uppercase());
                    capitalize_next = false;
                } else {
                    result.extend(c.to_lowercase());
                }
            } else {
                // Non-alphabetic characters trigger capitalization of next letter
                capitalize_next = true;
                if c != '_' && c != '-' && c != '.' {
                    result.push(c);
                }
            }
        }
        
        result
    }
}

pub fn to_swift_property_name(s: &str) -> String {
    // Handle Unicode properly by preserving non-ASCII characters
    if s.is_ascii() {
        s.to_lower_camel_case()
    } else {
        // For non-ASCII strings, do manual case conversion to preserve Unicode
        let mut result = String::new();
        let mut capitalize_next = false;
        
        for c in s.chars() {
            if c.is_ascii_alphabetic() {
                if capitalize_next {
                    result.push(c.to_ascii_uppercase());
                    capitalize_next = false;
                } else {
                    result.push(c.to_ascii_lowercase());
                }
            } else if c.is_alphabetic() {
                // For Unicode letters, preserve them as-is and capitalize if needed
                if capitalize_next {
                    result.extend(c.to_uppercase());
                    capitalize_next = false;
                } else {
                    result.extend(c.to_lowercase());
                }
            } else {
                // Non-alphabetic characters trigger capitalization of next letter
                capitalize_next = true;
                if c != '_' && c != '-' && c != '.' {
                    result.push(c);
                }
            }
        }
        
        result
    }
}

pub fn to_swift_method_name(s: &str) -> String {
    s.to_lower_camel_case()
}

pub fn to_swift_enum_case(s: &str) -> String {
    s.to_lower_camel_case()
}

pub fn to_swift_constant_name(s: &str) -> String {
    s.to_lower_camel_case()
}

pub fn to_swift_actor_name(s: &str) -> String {
    let base = if s.ends_with("Service") {
        &s[..s.len() - 7]
    } else {
        s
    };
    format!("{}Client", base.to_pascal_case())
}

pub fn to_swift_actor_name_with_suffix(s: &str, suffix: &str) -> String {
    let base = if s.ends_with("Service") {
        &s[..s.len() - 7]
    } else {
        s
    };
    format!("{}{}", base.to_pascal_case(), suffix)
}

pub fn to_swift_state_name(s: &str) -> String {
    let base = if s.ends_with("Service") {
        &s[..s.len() - 7]
    } else {
        s
    };
    format!("{}State", base.to_pascal_case())
}

pub fn to_swift_action_name(s: &str) -> String {
    let base = if s.ends_with("Service") {
        &s[..s.len() - 7]
    } else {
        s
    };
    format!("{}Action", base.to_pascal_case())
}

pub fn sanitize_swift_identifier(s: &str) -> String {
    let result = s.chars()
        .map(|c| if c.is_alphanumeric() || c == '_' { c } else { '_' })
        .collect::<String>();
    
    let mut final_result = if !result.is_empty() && result.chars().next().unwrap().is_ascii_digit() {
        format!("_{}", result)
    } else {
        result
    };
    
    if is_swift_keyword(&final_result) {
        format!("`{}`", final_result)
    } else {
        final_result
    }
}

pub fn is_swift_keyword(s: &str) -> bool {
    matches!(s, 
        "associatedtype" | "class" | "deinit" | "enum" | "extension" | "fileprivate" | "func" | 
        "import" | "init" | "inout" | "internal" | "let" | "open" | "operator" | "private" | 
        "protocol" | "public" | "rethrows" | "static" | "struct" | "subscript" | "typealias" | 
        "var" | "break" | "case" | "continue" | "default" | "defer" | "do" | "else" | "fallthrough" | 
        "for" | "guard" | "if" | "in" | "repeat" | "return" | "switch" | "where" | "while" | 
        "as" | "catch" | "false" | "is" | "nil" | "super" | "self" | "Self" | "throw" | "throws" | 
        "true" | "try" | "_" | "async" | "await" | "actor" | "final" | "lazy" | "weak" | "unowned" |
        "mutating" | "nonmutating" | "override" | "required" | "convenience" | "dynamic" | 
        "optional" | "indirect"
    )
}

pub fn is_valid_swift_package_name(s: &str) -> bool {
    !s.is_empty() && 
    s.chars().next().unwrap().is_alphabetic() &&
    s.chars().all(|c| c.is_alphanumeric() || c == '_') &&
    !is_swift_keyword(s)
}

pub fn to_swift_file_name(name: &str, type_suffix: &str) -> String {
    let pascal_name = name.to_pascal_case();
    if pascal_name.ends_with(type_suffix) {
        format!("{}.swift", pascal_name)
    } else {
        format!("{}{}.swift", pascal_name, type_suffix)
    }
}

pub fn to_swift_test_file_name(name: &str) -> String {
    format!("{}Tests.swift", name.to_pascal_case())
}

pub fn to_swift_directory_name(name: &str) -> String {
    name.to_pascal_case()
}

pub fn extract_namespace(name: &str) -> String {
    if let Some(dot_pos) = name.rfind('.') {
        name[..dot_pos].to_string()
    } else {
        "".to_string()
    }
}

pub fn to_swift_module_name(name: &str) -> String {
    if let Some(dot_pos) = name.rfind('.') {
        name[dot_pos + 1..].to_pascal_case()
    } else {
        name.to_pascal_case()
    }
}

pub fn handle_acronyms(s: &str) -> String {
    s.replace("HTTPS", "Https")
     .replace("HTTP", "Http")
     .replace("JSON", "Json")
     .replace("XML", "Xml")
     .replace("API", "Api")
     .replace("URL", "Url")
     .replace("UUID", "Uuid")
     .replace("SQL", "Sql")
     .replace("UI", "Ui")
     .replace("iOS", "Ios")
     .replace("ID", "Id")
}

pub fn remove_version_suffix(s: &str) -> String {
    // Handle both lowercase 'v' and uppercase 'V' version suffixes
    let result = if let Some(v_pos) = s.rfind(|c| c == 'v' || c == 'V') {
        if s[v_pos + 1..].chars().all(|c| c.is_ascii_digit()) {
            s[..v_pos].to_string()
        } else {
            s.to_string()
        }
    } else {
        s.to_string()
    };
    
    // Apply acronym handling to the result
    handle_acronyms(&result)
}

pub fn to_singular(s: &str) -> String {
    NamingUtils::singularize(s)
}

pub fn to_plural(s: &str) -> String {
    NamingUtils::pluralize(s)
}

/// Proto type to Swift type mapping
pub fn proto_type_to_swift(proto_type: &str) -> String {
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
        _ => to_swift_type_name(proto_type),
    }
}