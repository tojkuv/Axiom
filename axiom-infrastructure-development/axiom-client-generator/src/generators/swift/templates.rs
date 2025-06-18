use crate::error::{Error, Result};
use std::collections::HashMap;
use tera::{Context, Tera};

/// Swift template engine using Tera
pub struct SwiftTemplateEngine {
    /// Tera template engine
    tera: Tera,
}

impl SwiftTemplateEngine {
    /// Create a new Swift template engine
    pub async fn new() -> Result<Self> {
        let mut tera = Tera::new("src/templates/swift/**/*.tera")
            .map_err(|e| Error::TemplateError(format!("Failed to initialize Tera: {}", e)))?;

        // Register custom filters and functions
        Self::register_swift_filters(&mut tera)?;
        Self::register_swift_functions(&mut tera)?;

        // Add built-in templates if external templates not found
        Self::add_builtin_templates(&mut tera)?;

        Ok(Self { tera })
    }

    /// Create a new Swift template engine with custom template directory
    pub fn with_template_dir(template_dir: &std::path::Path) -> Result<Self> {
        let template_pattern = format!("{}/**/*.tera", template_dir.display());
        let mut tera = Tera::new(&template_pattern)
            .map_err(|e| Error::TemplateError(format!("Failed to initialize Tera: {}", e)))?;

        // Register custom filters and functions
        Self::register_swift_filters(&mut tera)?;
        Self::register_swift_functions(&mut tera)?;

        Ok(Self { tera })
    }

    /// Initialize templates (currently a no-op since templates are initialized in new())
    pub async fn initialize_templates(&mut self) -> Result<()> {
        // Templates are already initialized in new(), this is here for API compatibility
        Ok(())
    }

    /// Get access to the underlying Tera engine
    pub fn get_tera(&self) -> &Tera {
        &self.tera
    }

    /// Render a client actor template
    pub async fn render_client_actor(&self, context: &Context) -> Result<String> {
        self.render("clients/client_actor.swift.tera", context)
    }

    /// Render a state struct template
    pub async fn render_state_struct(&self, context: &Context) -> Result<String> {
        self.render("clients/state_struct.swift.tera", context)
    }

    /// Render an action enum template
    pub async fn render_action_enum(&self, context: &Context) -> Result<String> {
        self.render("clients/action_enum.swift.tera", context)
    }

    /// Render a message struct template
    pub async fn render_message_struct(&self, context: &Context) -> Result<String> {
        self.render("contracts/message.swift.tera", context)
    }

    /// Render a service contract template
    pub async fn render_service_contract(&self, context: &Context) -> Result<String> {
        self.render("contracts/service.swift.tera", context)
    }

    /// Render a test file template
    pub async fn render_test_file(&self, context: &Context) -> Result<String> {
        self.render("clients/test_file.swift.tera", context)
    }

    /// Render a Swift contract template
    pub fn render_contract(&self, template_name: &str, context: &Context) -> Result<String> {
        let template_path = format!("contracts/{}.swift.tera", template_name);
        self.tera
            .render(&template_path, context)
            .map_err(|e| Error::TemplateError(format!("Failed to render {}: {}", template_path, e)))
    }

    /// Render a Swift client template
    pub fn render_client(&self, template_name: &str, context: &Context) -> Result<String> {
        let template_path = format!("clients/{}.swift.tera", template_name);
        self.tera
            .render(&template_path, context)
            .map_err(|e| Error::TemplateError(format!("Failed to render {}: {}", template_path, e)))
    }

    /// Render an arbitrary template
    pub fn render(&self, template_name: &str, context: &Context) -> Result<String> {
        self.tera
            .render(template_name, context)
            .map_err(|e| Error::TemplateError(format!("Failed to render {}: {}", template_name, e)))
    }

    /// Register Swift-specific filters
    fn register_swift_filters(tera: &mut Tera) -> Result<()> {
        // Filter to convert to Swift type
        tera.register_filter("swift_type", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let type_str = value.as_str().unwrap_or("");
            let swift_type = match type_str {
                "string" => "String",
                "bool" => "Bool",
                "int32" | "sint32" | "sfixed32" => "Int32",
                "int64" | "sint64" | "sfixed64" => "Int64",
                "uint32" | "fixed32" => "UInt32", 
                "uint64" | "fixed64" => "UInt64",
                "float" => "Float",
                "double" => "Double",
                "bytes" => "Data",
                _ if type_str.contains("Timestamp") => "Date",
                _ if type_str.contains("Duration") => "TimeInterval",
                _ if type_str.contains("Empty") => "Void",
                _ if type_str.starts_with('.') => {
                    // Handle fully qualified types like .google.protobuf.Timestamp
                    type_str.split('.').last().unwrap_or(type_str)
                },
                _ => type_str,
            };
            Ok(tera::Value::String(swift_type.to_string()))
        });

        // Filter to make optional if needed
        tera.register_filter("optional_if", |value: &tera::Value, args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let condition = args.get("condition").and_then(|v| v.as_bool()).unwrap_or(false);
            let type_str = value.as_str().unwrap_or("");
            
            if condition {
                Ok(tera::Value::String(format!("{}?", type_str)))
            } else {
                Ok(value.clone())
            }
        });

        // Filter to convert to camelCase with Swift reserved word handling
        tera.register_filter("camel_case", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            use heck::ToLowerCamelCase;
            let input = value.as_str().unwrap_or("");
            let camel = input.to_lower_camel_case();
            
            // Handle Swift reserved words
            let escaped = match camel.as_str() {
                "class" | "struct" | "enum" | "protocol" | "extension" | "func" | "var" | "let" |
                "if" | "else" | "for" | "while" | "do" | "switch" | "case" | "default" |
                "break" | "continue" | "return" | "throw" | "throws" | "try" | "catch" |
                "import" | "public" | "private" | "internal" | "fileprivate" | "open" |
                "static" | "final" | "override" | "required" | "convenience" | "init" |
                "deinit" | "subscript" | "operator" | "precedencegroup" | "associatedtype" |
                "typealias" | "where" | "is" | "as" | "any" | "some" | "Self" | "super" |
                "nil" | "true" | "false" | "self" | "Type" | "Protocol" => {
                    format!("`{}`", camel)
                }
                _ => camel,
            };
            
            Ok(tera::Value::String(escaped))
        });

        // Filter to convert to PascalCase
        tera.register_filter("pascal_case", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            use heck::ToPascalCase;
            let pascal = value.as_str().unwrap_or("").to_pascal_case();
            Ok(tera::Value::String(pascal))
        });

        // Filter to clean enum case names
        tera.register_filter("swift_enum_case", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            use heck::ToLowerCamelCase;
            let input = value.as_str().unwrap_or("");
            
            // Remove common prefixes
            let cleaned = if let Some(underscore_pos) = input.find('_') {
                let potential_prefix = &input[..underscore_pos + 1];
                if potential_prefix.chars().all(|c| c.is_uppercase() || c == '_') {
                    &input[underscore_pos + 1..]
                } else {
                    input
                }
            } else {
                input
            };
            
            let camel_case = cleaned.to_lower_camel_case();
            Ok(tera::Value::String(camel_case))
        });

        // Filter to determine if field should be optional
        tera.register_filter("is_optional", |value: &tera::Value, args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let field_type = value.as_str().unwrap_or("");
            let is_proto3 = args.get("proto3").and_then(|v| v.as_bool()).unwrap_or(true);
            
            let is_optional = if is_proto3 {
                !matches!(field_type, "bool" | "int32" | "int64" | "uint32" | "uint64" | "float" | "double")
            } else {
                true
            };
            
            Ok(tera::Value::Bool(is_optional))
        });

        // Filter to capitalize first letter
        tera.register_filter("capitalize", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let input = value.as_str().unwrap_or("");
            if input.is_empty() {
                return Ok(tera::Value::String(String::new()));
            }
            let mut chars = input.chars();
            let first = chars.next().unwrap().to_uppercase().collect::<String>();
            let rest = chars.collect::<String>();
            Ok(tera::Value::String(format!("{}{}", first, rest)))
        });

        // Filter to convert to lowercase
        tera.register_filter("lower", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let input = value.as_str().unwrap_or("");
            Ok(tera::Value::String(input.to_lowercase()))
        });

        // Filter to make singular (simple English pluralization rules)
        tera.register_filter("singular", |value: &tera::Value, _args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let input = value.as_str().unwrap_or("");
            let singular = if input.ends_with("ies") {
                input.strip_suffix("ies").unwrap_or(input).to_string() + "y"
            } else if input.ends_with("es") && input.len() > 2 {
                let without_es = input.strip_suffix("es").unwrap_or(input);
                if without_es.ends_with("s") || without_es.ends_with("sh") || 
                   without_es.ends_with("ch") || without_es.ends_with("x") || 
                   without_es.ends_with("z") {
                    without_es.to_string()
                } else {
                    input.strip_suffix("s").unwrap_or(input).to_string()
                }
            } else if input.ends_with("s") && input.len() > 1 {
                input.strip_suffix("s").unwrap_or(input).to_string()
            } else {
                input.to_string()
            };
            Ok(tera::Value::String(singular))
        });

        Ok(())
    }

    /// Register Swift-specific functions
    fn register_swift_functions(tera: &mut Tera) -> Result<()> {
        // Function to generate import statements
        tera.register_function("swift_imports", |args: &std::collections::HashMap<String, tera::Value>| -> tera::Result<tera::Value> {
            let empty_vec = vec![];
            let imports = args.get("imports")
                .and_then(|v| v.as_array())
                .unwrap_or(&empty_vec);
            
            let mut import_statements = Vec::new();
            import_statements.push("import Foundation".to_string());
            
            for import in imports {
                if let Some(import_str) = import.as_str() {
                    import_statements.push(format!("import {}", import_str));
                }
            }
            
            Ok(tera::Value::String(import_statements.join("\n")))
        });

        Ok(())
    }

    /// Add built-in templates when external ones are not available
    fn add_builtin_templates(tera: &mut Tera) -> Result<()> {
        // Service contract template
        tera.add_raw_template(
            "contracts/service.swift.tera",
            include_str!("../../templates/swift/contracts/service.swift.tera")
        ).ok(); // Ignore errors if template file doesn't exist

        // Message contract template
        tera.add_raw_template(
            "contracts/message.swift.tera", 
            include_str!("../../templates/swift/contracts/message.swift.tera")
        ).ok();

        // Enum contract template
        tera.add_raw_template(
            "contracts/enum.swift.tera",
            include_str!("../../templates/swift/contracts/enum.swift.tera")
        ).ok();

        // Client actor template
        tera.add_raw_template(
            "clients/client_actor.swift.tera",
            include_str!("../../templates/swift/clients/client_actor.swift.tera")
        ).ok();

        // Action enum template
        tera.add_raw_template(
            "clients/action_enum.swift.tera",
            include_str!("../../templates/swift/clients/action_enum.swift.tera")
        ).ok();

        // State struct template
        tera.add_raw_template(
            "clients/state_struct.swift.tera",
            include_str!("../../templates/swift/clients/state_struct.swift.tera")
        ).ok();

        // Test file template
        tera.add_raw_template(
            "clients/test_file.swift.tera",
            include_str!("../../templates/swift/clients/test_file.swift.tera")
        ).ok();

        // Fallback templates with minimal content
        if !tera.get_template_names().any(|name| name == "contracts/service.swift.tera") {
            tera.add_raw_template(
                "contracts/service.swift.tera",
                r#"// Generated Swift service contracts
{{ swift_imports(imports=imports) }}

{% for message in messages %}
// MARK: - {{ message.name }}
public struct {{ message.name | pascal_case }}: Codable {
    {% for field in message.fields %}
    public let {{ field.name | camel_case }}: {{ field.type | swift_type }}{% if field.optional %}?{% endif %}
    {% endfor %}
    
    public init({% for field in message.fields %}{{ field.name | camel_case }}: {{ field.type | swift_type }}{% if field.optional %}? = nil{% endif %}{% if not loop.last %}, {% endif %}{% endfor %}) {
        {% for field in message.fields %}
        self.{{ field.name | camel_case }} = {{ field.name | camel_case }}
        {% endfor %}
    }
}

{% endfor %}
"#,
            )?;
        }

        if !tera.get_template_names().any(|name| name == "clients/client_actor.swift.tera") {
            tera.add_raw_template(
                "clients/client_actor.swift.tera",
                r#"// Generated Swift client
{{ swift_imports(imports=imports) }}

@globalActor
public actor {{ client_name }}: AxiomObservableClient<{{ state_name }}, {{ action_name }}> {
    private let apiClient: {{ service_name }}Client
    
    public init(apiClient: {{ service_name }}Client) {
        self.apiClient = apiClient
        super.init(initialState: {{ state_name }}())
    }
    
    public func process(_ action: {{ action_name }}) async throws {
        switch action {
        {% for method in methods %}
        case .{{ method.name | camel_case }}(let request):
            {% if method.loading_state %}
            updateState { $0.isLoading = true }
            {% endif %}
            do {
                let result = try await apiClient.{{ method.name | camel_case }}(request)
                updateState { state in
                    {% if method.state_update == "append" %}
                    state.{{ method.collection_name | camel_case }}.append(result)
                    {% elif method.state_update == "replace_all" %}
                    state.{{ method.collection_name | camel_case }} = result.{{ method.collection_name | camel_case }}
                    {% elif method.state_update == "update_by_id" %}
                    if let index = state.{{ method.collection_name | camel_case }}.firstIndex(where: { $0.id == result.id }) {
                        state.{{ method.collection_name | camel_case }}[index] = result
                    }
                    {% elif method.state_update == "remove_by_id" %}
                    state.{{ method.collection_name | camel_case }}.removeAll { $0.id == request.id }
                    {% endif %}
                    {% if method.loading_state %}
                    state.isLoading = false
                    {% endif %}
                    state.lastError = nil
                }
            } catch {
                updateState { state in
                    {% if method.loading_state %}
                    state.isLoading = false
                    {% endif %}
                    state.lastError = error
                }
                throw error
            }
        {% endfor %}
        }
    }
}
"#,
            )?;
        }

        Ok(())
    }
}