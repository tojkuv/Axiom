use crate::error::{Error, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};

/// Configuration management for the client generator
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneratorConfig {
    /// Default output directory
    pub default_output_dir: PathBuf,
    /// Default target languages
    pub default_languages: Vec<String>,
    /// Language-specific configurations
    pub language_configs: HashMap<String, LanguageConfig>,
    /// Template directories
    pub template_dirs: Vec<PathBuf>,
    /// Validation settings
    pub validation: ValidationConfig,
    /// Performance settings
    pub performance: PerformanceConfig,
}

/// Language-specific configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LanguageConfig {
    /// Template directory for this language
    pub template_dir: Option<PathBuf>,
    /// File extension
    pub file_extension: String,
    /// Import statements
    pub default_imports: Vec<String>,
    /// Naming conventions
    pub naming_conventions: NamingConventions,
    /// Code style settings
    pub style_settings: StyleSettings,
}

/// Naming convention settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NamingConventions {
    /// Class/struct naming style
    pub class_naming: NamingStyle,
    /// Property/field naming style
    pub property_naming: NamingStyle,
    /// Method naming style
    pub method_naming: NamingStyle,
    /// Constant naming style
    pub constant_naming: NamingStyle,
    /// Enum case naming style
    pub enum_case_naming: NamingStyle,
}

/// Code style settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StyleSettings {
    /// Indentation type (spaces or tabs)
    pub indentation: IndentationType,
    /// Number of spaces per indent level
    pub indent_size: usize,
    /// Maximum line length
    pub max_line_length: usize,
    /// Whether to include documentation
    pub include_documentation: bool,
    /// Whether to include type annotations
    pub include_type_annotations: bool,
}

/// Naming style options
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NamingStyle {
    CamelCase,
    PascalCase,
    SnakeCase,
    KebabCase,
    UpperCase,
    LowerCase,
}

/// Indentation type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum IndentationType {
    Spaces,
    Tabs,
}

/// Validation configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct ValidationConfig {
    /// Maximum file size in bytes
    pub max_file_size: usize,
    /// Maximum number of lines per file
    pub max_lines_per_file: usize,
    /// Whether to validate syntax
    pub validate_syntax: bool,
    /// Whether to validate imports
    pub validate_imports: bool,
    /// Whether to validate compilation
    pub validate_compilation: bool,
    /// Swift version for compilation validation
    pub swift_version: Option<String>,
    /// Additional compiler flags
    pub additional_flags: Vec<String>,
    /// Forbidden patterns in generated code
    pub forbidden_patterns: Vec<String>,
}

/// Performance configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    /// Maximum number of parallel generation tasks
    pub max_parallel_tasks: usize,
    /// Template cache size
    pub template_cache_size: usize,
    /// Whether to enable template caching
    pub enable_template_caching: bool,
}

impl Default for ValidationConfig {
    fn default() -> Self {
        Self {
            max_file_size: 1024 * 1024, // 1MB
            max_lines_per_file: 10000,
            validate_syntax: true,
            validate_imports: true,
            validate_compilation: false,
            swift_version: Some("5.9".to_string()),
            additional_flags: vec![],
            forbidden_patterns: vec![
                "TODO".to_string(),
                "FIXME".to_string(),
                "XXX".to_string(),
            ],
        }
    }
}

impl GeneratorConfig {
    /// Load configuration from file
    pub fn load_from_file(path: &Path) -> Result<Self> {
        if !path.exists() {
            return Ok(Self::default());
        }

        let content = std::fs::read_to_string(path)?;
        
        match path.extension().and_then(|s| s.to_str()) {
            Some("toml") => {
                toml::from_str(&content).map_err(|e| {
                    Error::ConfigError(format!("Failed to parse TOML config: {}", e))
                })
            }
            Some("yaml") | Some("yml") => {
                let yaml_value: yaml_rust::Yaml = yaml_rust::YamlLoader::load_from_str(&content)
                    .map_err(|e| Error::ConfigError(format!("Failed to parse YAML config: {}", e)))?
                    .into_iter()
                    .next()
                    .unwrap_or(yaml_rust::Yaml::Null);
                
                // Convert YAML to JSON then to our struct (simple approach)
                let json_value = yaml_to_json_value(&yaml_value);
                serde_json::from_value(json_value).map_err(|e| {
                    Error::ConfigError(format!("Failed to parse YAML config: {}", e))
                })
            }
            Some("json") => {
                serde_json::from_str(&content).map_err(|e| {
                    Error::ConfigError(format!("Failed to parse JSON config: {}", e))
                })
            }
            _ => Err(Error::ConfigError(
                "Unsupported config file format. Use .toml, .yaml, .yml, or .json".to_string()
            )),
        }
    }

    /// Save configuration to file
    pub fn save_to_file(&self, path: &Path) -> Result<()> {
        let content = match path.extension().and_then(|s| s.to_str()) {
            Some("toml") => {
                toml::to_string_pretty(self).map_err(|e| {
                    Error::ConfigError(format!("Failed to serialize TOML config: {}", e))
                })?
            }
            Some("json") => {
                serde_json::to_string_pretty(self).map_err(|e| {
                    Error::ConfigError(format!("Failed to serialize JSON config: {}", e))
                })?
            }
            _ => {
                return Err(Error::ConfigError(
                    "Unsupported config file format for saving. Use .toml or .json".to_string()
                ));
            }
        };

        std::fs::write(path, content)?;
        Ok(())
    }

    /// Get language configuration
    pub fn get_language_config(&self, language: &str) -> Option<&LanguageConfig> {
        self.language_configs.get(language)
    }

    /// Add or update language configuration
    pub fn set_language_config(&mut self, language: String, config: LanguageConfig) {
        self.language_configs.insert(language, config);
    }

    /// Merge with another configuration (other takes precedence)
    pub fn merge_with(&mut self, other: GeneratorConfig) {
        if !other.default_languages.is_empty() {
            self.default_languages = other.default_languages;
        }
        
        for (lang, config) in other.language_configs {
            self.language_configs.insert(lang, config);
        }
        
        if !other.template_dirs.is_empty() {
            self.template_dirs = other.template_dirs;
        }
    }
}

impl Default for GeneratorConfig {
    fn default() -> Self {
        let mut language_configs = HashMap::new();
        
        // Swift configuration
        language_configs.insert("swift".to_string(), LanguageConfig {
            template_dir: Some(PathBuf::from("templates/swift")),
            file_extension: "swift".to_string(),
            default_imports: vec![
                "Foundation".to_string(),
                "AxiomCore".to_string(),
            ],
            naming_conventions: NamingConventions {
                class_naming: NamingStyle::PascalCase,
                property_naming: NamingStyle::CamelCase,
                method_naming: NamingStyle::CamelCase,
                constant_naming: NamingStyle::CamelCase,
                enum_case_naming: NamingStyle::CamelCase,
            },
            style_settings: StyleSettings {
                indentation: IndentationType::Spaces,
                indent_size: 4,
                max_line_length: 120,
                include_documentation: true,
                include_type_annotations: true,
            },
        });

        // Kotlin configuration
        language_configs.insert("kotlin".to_string(), LanguageConfig {
            template_dir: Some(PathBuf::from("templates/kotlin")),
            file_extension: "kt".to_string(),
            default_imports: vec![
                "kotlinx.serialization.Serializable".to_string(),
                "kotlinx.coroutines.flow.StateFlow".to_string(),
            ],
            naming_conventions: NamingConventions {
                class_naming: NamingStyle::PascalCase,
                property_naming: NamingStyle::CamelCase,
                method_naming: NamingStyle::CamelCase,
                constant_naming: NamingStyle::UpperCase,
                enum_case_naming: NamingStyle::UpperCase,
            },
            style_settings: StyleSettings {
                indentation: IndentationType::Spaces,
                indent_size: 4,
                max_line_length: 120,
                include_documentation: true,
                include_type_annotations: true,
            },
        });

        Self {
            default_output_dir: PathBuf::from("./generated"),
            default_languages: vec!["swift".to_string()],
            language_configs,
            template_dirs: vec![
                PathBuf::from("./templates"),
                PathBuf::from("./src/templates"),
            ],
            validation: ValidationConfig {
                max_file_size: 1024 * 1024, // 1MB
                max_lines_per_file: 10000,
                validate_syntax: true,
                validate_imports: true,
                validate_compilation: false,
                swift_version: Some("5.9".to_string()),
                additional_flags: vec![],
                forbidden_patterns: vec![
                    "TODO".to_string(),
                    "FIXME".to_string(),
                    "XXX".to_string(),
                ],
            },
            performance: PerformanceConfig {
                max_parallel_tasks: num_cpus::get(),
                template_cache_size: 100,
                enable_template_caching: true,
            },
        }
    }
}

/// Convert YAML value to JSON value (simplified)
fn yaml_to_json_value(yaml: &yaml_rust::Yaml) -> serde_json::Value {
    match yaml {
        yaml_rust::Yaml::Real(r) => {
            if let Ok(f) = r.parse::<f64>() {
                serde_json::Value::Number(serde_json::Number::from_f64(f).unwrap_or_else(|| {
                    serde_json::Number::from(0)
                }))
            } else {
                serde_json::Value::Number(serde_json::Number::from(0))
            }
        }
        yaml_rust::Yaml::Integer(i) => serde_json::Value::Number(serde_json::Number::from(*i)),
        yaml_rust::Yaml::String(s) => serde_json::Value::String(s.clone()),
        yaml_rust::Yaml::Boolean(b) => serde_json::Value::Bool(*b),
        yaml_rust::Yaml::Array(arr) => {
            serde_json::Value::Array(arr.iter().map(yaml_to_json_value).collect())
        }
        yaml_rust::Yaml::Hash(hash) => {
            let mut map = serde_json::Map::new();
            for (key, value) in hash {
                if let yaml_rust::Yaml::String(key_str) = key {
                    map.insert(key_str.clone(), yaml_to_json_value(value));
                }
            }
            serde_json::Value::Object(map)
        }
        yaml_rust::Yaml::Null => serde_json::Value::Null,
        _ => serde_json::Value::Null,
    }
}

/// Style guide options for code generation
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub enum StyleGuide {
    Axiom,
    SwiftStandard,
    Custom,
}

impl StyleGuide {
    pub fn from_string(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "axiom" => StyleGuide::Axiom,
            "swift-standard" => StyleGuide::SwiftStandard,
            "custom" => StyleGuide::Custom,
            _ => StyleGuide::Axiom, // Default fallback
        }
    }
    
    pub fn to_string(&self) -> String {
        match self {
            StyleGuide::Axiom => "axiom".to_string(),
            StyleGuide::SwiftStandard => "swift-standard".to_string(),
            StyleGuide::Custom => "custom".to_string(),
        }
    }
}

impl Default for StyleGuide {
    fn default() -> Self {
        StyleGuide::Axiom
    }
}

/// Swift generation configuration for tests
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct SwiftGenerationConfig {
    pub axiom_version: String,
    pub client_suffix: String,
    pub generate_tests: bool,
    pub generate_contracts: bool,
    pub generate_clients: bool,
    pub force_overwrite: bool,
    pub include_documentation: bool,
    pub style_guide: StyleGuide,
    pub module_imports: Vec<String>,
    pub package_name: Option<String>,
}

impl Default for SwiftGenerationConfig {
    fn default() -> Self {
        Self {
            axiom_version: "latest".to_string(),
            client_suffix: "Client".to_string(),
            generate_tests: true,
            generate_contracts: true,
            generate_clients: true,
            force_overwrite: false,
            include_documentation: true,
            style_guide: StyleGuide::Axiom,
            module_imports: vec!["AxiomCore".to_string(), "AxiomArchitecture".to_string()],
            package_name: None,
        }
    }
}

impl SwiftGenerationConfig {
    pub fn validate(&self) -> Result<()> {
        if self.client_suffix.is_empty() {
            return Err(Error::ConfigError("Client suffix cannot be empty".to_string()));
        }
        
        if let Some(ref package_name) = self.package_name {
            if package_name.chars().next().map_or(false, |c| c.is_ascii_digit()) {
                return Err(Error::ConfigError("Package name cannot start with a digit".to_string()));
            }
        }
        
        Ok(())
    }
    
    pub fn merge_with(&self, other: &SwiftGenerationConfig) -> SwiftGenerationConfig {
        SwiftGenerationConfig {
            axiom_version: other.axiom_version.clone(),
            client_suffix: other.client_suffix.clone(),
            generate_tests: other.generate_tests,
            generate_contracts: other.generate_contracts,
            generate_clients: other.generate_clients,
            force_overwrite: other.force_overwrite,
            include_documentation: other.include_documentation,
            style_guide: other.style_guide.clone(),
            module_imports: other.module_imports.clone(),
            package_name: other.package_name.clone(),
        }
    }
    
    pub fn from_environment() -> SwiftGenerationConfig {
        let mut config = SwiftGenerationConfig::default();
        
        if let Ok(version) = std::env::var("AXIOM_VERSION") {
            config.axiom_version = version;
        }
        
        if let Ok(suffix) = std::env::var("AXIOM_CLIENT_SUFFIX") {
            config.client_suffix = suffix;
        }
        
        if let Ok(generate_tests) = std::env::var("AXIOM_GENERATE_TESTS") {
            config.generate_tests = generate_tests.parse().unwrap_or(config.generate_tests);
        }
        
        config
    }
    
    pub fn apply_environment_overrides(mut self) -> SwiftGenerationConfig {
        if let Ok(version) = std::env::var("AXIOM_VERSION") {
            self.axiom_version = version;
        }
        
        if let Ok(suffix) = std::env::var("AXIOM_CLIENT_SUFFIX") {
            self.client_suffix = suffix;
        }
        
        self
    }
}

/// Output directory configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct OutputConfig {
    pub base_path: String,
    pub sources_dir: String,
    pub tests_dir: String,
    pub create_package_swift: bool,
    pub organize_by_service: bool,
}

impl Default for OutputConfig {
    fn default() -> Self {
        Self {
            base_path: "./generated".to_string(),
            sources_dir: "Sources".to_string(),
            tests_dir: "Tests".to_string(),
            create_package_swift: true,
            organize_by_service: true,
        }
    }
}

/// Main generator configuration for tests
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct AxiomGeneratorConfig {
    pub swift: SwiftGenerationConfig,
    pub generation: crate::GenerationOptions,
    pub validation: ValidationConfig,
    pub output: OutputConfig,
    pub proto_paths: Vec<String>,
    pub services: Option<Vec<String>>,
}

impl Default for AxiomGeneratorConfig {
    fn default() -> Self {
        Self {
            swift: SwiftGenerationConfig::default(),
            generation: crate::GenerationOptions::default(),
            validation: ValidationConfig::default(),
            output: OutputConfig::default(),
            proto_paths: vec!["./proto".to_string()],
            services: None,
        }
    }
}

impl AxiomGeneratorConfig {
    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path = path.as_ref();
        if !path.exists() {
            return Err(Error::ConfigError(format!("Config file not found: {}", path.display())));
        }
        
        let content = std::fs::read_to_string(path)?;
        serde_json::from_str(&content).map_err(|e| {
            Error::ConfigError(format!("Failed to parse config file: {}", e))
        })
    }
}

/// Template configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemplateConfig {
    pub custom_template_path: Option<String>,
    pub enable_custom_filters: bool,
    pub template_cache_size: usize,
    pub additional_context: HashMap<String, String>,
}

impl Default for TemplateConfig {
    fn default() -> Self {
        Self {
            custom_template_path: None,
            enable_custom_filters: false,
            template_cache_size: 100,
            additional_context: HashMap::new(),
        }
    }
}

/// Proto configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtoConfig {
    pub include_paths: Vec<String>,
    pub import_paths: Vec<String>,
    pub file_descriptor_set_path: Option<String>,
    pub preserve_proto_names: bool,
    pub enable_custom_options: bool,
}

impl Default for ProtoConfig {
    fn default() -> Self {
        Self {
            include_paths: vec![],
            import_paths: vec![],
            file_descriptor_set_path: None,
            preserve_proto_names: false,
            enable_custom_options: true,
        }
    }
}

/// MCP tool configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpToolConfig {
    pub tool_name: String,
    pub description: String,
    pub timeout_seconds: u64,
    pub max_concurrent_requests: usize,
    pub enable_progress_reporting: bool,
}

impl Default for McpToolConfig {
    fn default() -> Self {
        Self {
            tool_name: "axiom-client-generator".to_string(),
            description: "Generate Axiom framework clients from proto files".to_string(),
            timeout_seconds: 300,
            max_concurrent_requests: 10,
            enable_progress_reporting: true,
        }
    }
}