use crate::error::{Error, Result};
use crate::generators::swift;
use crate::proto::types::ProtoSchema;
use crate::GenerateRequest;
use std::collections::HashMap;
use std::path::PathBuf;

/// Registry for managing language-specific code generators
pub struct GeneratorRegistry {
    /// Map of language names to their generators
    generators: HashMap<String, Box<dyn LanguageGenerator>>,
}

/// Trait for language-specific code generators
#[async_trait::async_trait]
pub trait LanguageGenerator: Send + Sync {
    /// Get the language name this generator supports
    fn language(&self) -> &str;

    /// Generate code for the given schema and request
    async fn generate(
        &self,
        schema: &ProtoSchema,
        request: &GenerateRequest,
    ) -> Result<Vec<String>>;

    /// Validate that the generator can handle the given schema
    fn validate_schema(&self, schema: &ProtoSchema) -> Result<()>;

    /// Get supported file extensions for this language
    fn file_extensions(&self) -> Vec<&str>;
}

impl GeneratorRegistry {
    /// Create a new generator registry with Swift support
    pub async fn new() -> Result<Self> {
        let mut generators: HashMap<String, Box<dyn LanguageGenerator>> = HashMap::new();

        // Register Swift generator
        let swift_generator = swift::SwiftGenerator::new().await?;
        generators.insert("swift".to_string(), Box::new(swift_generator));

        tracing::info!("Initialized generator registry with Swift support");

        Ok(Self { generators })
    }

    /// Generate code for a specific language
    pub async fn generate(
        &self,
        language: &str,
        schema: &ProtoSchema,
        request: &GenerateRequest,
    ) -> Result<Vec<String>> {
        let generator = self.generators.get(language).ok_or_else(|| {
            Error::UnsupportedLanguage(format!(
                "Language '{}' is not supported. Available languages: {}",
                language,
                self.supported_languages().join(", ")
            ))
        })?;

        // Validate schema before generation
        generator.validate_schema(schema)?;

        tracing::info!("Generating {} code for {} services", language, schema.services.len());

        // Generate code
        let start_time = std::time::Instant::now();
        let generated_files = generator.generate(schema, request).await?;
        let generation_time = start_time.elapsed();

        tracing::info!(
            "Generated {} {} files in {:?}",
            generated_files.len(),
            language,
            generation_time
        );

        Ok(generated_files)
    }

    /// Get all supported languages
    pub fn supported_languages(&self) -> Vec<String> {
        let mut languages: Vec<String> = self.generators.keys().cloned().collect();
        languages.sort();
        languages
    }

    /// Check if a language is supported
    pub fn supports_language(&self, language: &str) -> bool {
        self.generators.contains_key(language)
    }

    /// Get generator for a specific language
    pub fn get_generator(&self, language: &str) -> Option<&dyn LanguageGenerator> {
        self.generators.get(language).map(|g| g.as_ref())
    }

    /// Validate that all requested languages are supported
    pub fn validate_languages(&self, languages: &[String]) -> Result<()> {
        for language in languages {
            if !self.supports_language(language) {
                return Err(Error::UnsupportedLanguage(format!(
                    "Language '{}' is not supported. Available languages: {}",
                    language,
                    self.supported_languages().join(", ")
                )));
            }
        }
        Ok(())
    }

    /// Generate for multiple languages in parallel
    pub async fn generate_parallel(
        &self,
        languages: &[String],
        schema: &ProtoSchema,
        request: &GenerateRequest,
    ) -> Result<HashMap<String, Vec<String>>> {
        // Validate all languages first
        self.validate_languages(languages)?;

        let mut results = HashMap::new();

        // Generate for each language
        for language in languages {
            let generated_files = self.generate(language, schema, request).await?;
            results.insert(language.clone(), generated_files);
        }

        Ok(results)
    }

    /// Get statistics about the registry
    pub fn stats(&self) -> RegistryStats {
        RegistryStats {
            supported_languages_count: self.generators.len(),
            supported_languages: self.supported_languages(),
        }
    }
}

/// Statistics about the generator registry
#[derive(Debug, Clone)]
pub struct RegistryStats {
    /// Number of supported languages
    pub supported_languages_count: usize,
    /// List of supported languages
    pub supported_languages: Vec<String>,
}

/// Configuration for code generation
#[derive(Debug, Clone)]
pub struct GenerationConfig {
    /// Output directory
    pub output_dir: PathBuf,
    /// Whether to overwrite existing files
    pub force_overwrite: bool,
    /// Whether to include documentation
    pub include_documentation: bool,
    /// Code style guide
    pub style_guide: String,
    /// Custom template variables
    pub template_vars: HashMap<String, String>,
}

impl GenerationConfig {
    /// Create a new generation config from a request
    pub fn from_request(request: &GenerateRequest) -> Self {
        let options = request.generation_options.as_ref();
        
        Self {
            output_dir: PathBuf::from(&request.output_path),
            force_overwrite: options
                .and_then(|o| o.force_overwrite)
                .unwrap_or(false),
            include_documentation: options
                .and_then(|o| o.include_documentation)
                .unwrap_or(true),
            style_guide: options
                .and_then(|o| o.style_guide.clone())
                .unwrap_or_else(|| "axiom".to_string()),
            template_vars: HashMap::new(),
        }
    }
}

impl Default for GenerationConfig {
    fn default() -> Self {
        Self {
            output_dir: PathBuf::from("./generated"),
            force_overwrite: false,
            include_documentation: true,
            style_guide: "axiom".to_string(),
            template_vars: HashMap::new(),
        }
    }
}

/// Context for template generation
#[derive(Debug, Clone)]
pub struct GenerationContext {
    /// Generation configuration
    pub config: GenerationConfig,
    /// Proto schema being generated
    pub schema: ProtoSchema,
    /// Language-specific configuration
    pub language_config: HashMap<String, serde_json::Value>,
    /// Template variables
    pub variables: HashMap<String, serde_json::Value>,
}

impl GenerationContext {
    /// Create a new generation context
    pub fn new(config: GenerationConfig, schema: ProtoSchema) -> Self {
        Self {
            config,
            schema,
            language_config: HashMap::new(),
            variables: HashMap::new(),
        }
    }

    /// Add language-specific configuration
    pub fn with_language_config(
        mut self,
        language: &str,
        config: serde_json::Value,
    ) -> Self {
        self.language_config.insert(language.to_string(), config);
        self
    }

    /// Add template variable
    pub fn with_variable(mut self, key: &str, value: serde_json::Value) -> Self {
        self.variables.insert(key.to_string(), value);
        self
    }
}

impl Default for GenerationContext {
    fn default() -> Self {
        Self::new(GenerationConfig::default(), ProtoSchema::default())
    }
}