//! Swift code generation module
//!
//! Generates Swift code compatible with the Axiom Swift framework,
//! including contracts, clients, actions, and state management.

pub mod clients;
pub mod contracts;
pub mod naming;
pub mod templates;
pub mod documentation;
pub mod types;

use crate::error::{Error, Result};
use crate::generators::registry::{LanguageGenerator, GenerationConfig, GenerationContext};
use crate::proto::types::ProtoSchema;
use crate::GenerateRequest;
use std::path::PathBuf;

/// Swift code generator
pub struct SwiftGenerator {
    /// Template engine for Swift code generation
    template_engine: templates::SwiftTemplateEngine,
    /// Naming convention handler
    naming: naming::SwiftNaming,
}

impl SwiftGenerator {
    /// Create a new Swift generator
    pub async fn new() -> Result<Self> {
        let template_engine = templates::SwiftTemplateEngine::new().await?;
        let naming = naming::SwiftNaming::new();

        Ok(Self {
            template_engine,
            naming,
        })
    }

    /// Generate all Swift files for the given schema
    pub async fn generate_all(
        &self,
        schema: &ProtoSchema,
        output_path: PathBuf,
        options: Option<crate::GenerationOptions>,
    ) -> Result<Vec<String>> {
        let request = GenerateRequest {
            proto_path: "".to_string(), // Not used in this context
            output_path: output_path.to_string_lossy().to_string(),
            target_languages: vec!["swift".to_string()],
            services: None,
            framework_config: None,
            generation_options: options,
        };

        self.generate(schema, &request).await
    }
}

#[async_trait::async_trait]
impl LanguageGenerator for SwiftGenerator {
    fn language(&self) -> &str {
        "swift"
    }

    async fn generate(
        &self,
        schema: &ProtoSchema,
        request: &GenerateRequest,
    ) -> Result<Vec<String>> {
        let config = GenerationConfig::from_request(request);
        let context = GenerationContext::new(config, schema.clone());

        let mut generated_files = Vec::new();

        // Generate contracts (models, types)
        if request.generation_options
            .as_ref()
            .and_then(|o| o.generate_contracts)
            .unwrap_or(true)
        {
            let contract_files = contracts::generate_contracts(&context, &self.template_engine, &self.naming).await?;
            generated_files.extend(contract_files);
        }

        // Generate clients (state management, actions)
        if request.generation_options
            .as_ref()
            .and_then(|o| o.generate_clients)
            .unwrap_or(true)
        {
            let client_files = clients::generate_clients(&context, &self.template_engine, &self.naming).await?;
            generated_files.extend(client_files);
        }

        // Generate documentation
        if request.generation_options
            .as_ref()
            .and_then(|o| o.include_documentation)
            .unwrap_or(true)
        {
            let doc_generator = documentation::SwiftDocumentationGenerator::new();
            let doc_files = doc_generator.generate_documentation(&context, &generated_files).await?;
            generated_files.extend(doc_files);
        }

        Ok(generated_files)
    }

    fn validate_schema(&self, schema: &ProtoSchema) -> Result<()> {
        if schema.services.is_empty() {
            return Err(Error::ValidationError(
                "Schema must contain at least one service for Swift generation".to_string(),
            ));
        }

        // Check for unsupported features
        for service in &schema.services {
            for method in &service.methods {
                if method.client_streaming || method.server_streaming {
                    return Err(Error::ValidationError(format!(
                        "Streaming methods are not yet supported in Swift generation: {}.{}",
                        service.name, method.name
                    )));
                }
            }
        }

        Ok(())
    }

    fn file_extensions(&self) -> Vec<&str> {
        vec!["swift"]
    }
}