use crate::error::{Error, Result};
use std::path::Path;

/// Code validation utilities
pub struct ValidationUtils;

impl ValidationUtils {
    /// Validate that a path exists and is accessible
    pub fn validate_path_exists(path: &Path) -> Result<()> {
        if !path.exists() {
            return Err(Error::InvalidPath(format!(
                "Path does not exist: {}",
                path.display()
            )));
        }
        Ok(())
    }

    /// Validate that a path is a valid proto file
    pub fn validate_proto_file(path: &Path) -> Result<()> {
        Self::validate_path_exists(path)?;
        
        if !path.is_file() {
            return Err(Error::InvalidPath(format!(
                "Path is not a file: {}",
                path.display()
            )));
        }

        if path.extension().map_or(true, |ext| ext != "proto") {
            return Err(Error::InvalidPath(format!(
                "File is not a .proto file: {}",
                path.display()
            )));
        }

        Ok(())
    }

    /// Validate that a directory contains proto files
    pub fn validate_proto_directory(path: &Path) -> Result<()> {
        Self::validate_path_exists(path)?;
        
        if !path.is_dir() {
            return Err(Error::InvalidPath(format!(
                "Path is not a directory: {}",
                path.display()
            )));
        }

        // Check if directory contains any .proto files
        let has_proto_files = walkdir::WalkDir::new(path)
            .into_iter()
            .filter_map(|e| e.ok())
            .any(|entry| {
                entry.path().is_file() && 
                entry.path().extension().map_or(false, |ext| ext == "proto")
            });

        if !has_proto_files {
            return Err(Error::InvalidPath(format!(
                "Directory contains no .proto files: {}",
                path.display()
            )));
        }

        Ok(())
    }

    /// Validate output directory can be created/written to
    pub fn validate_output_directory(path: &Path) -> Result<()> {
        if path.exists() {
            if !path.is_dir() {
                return Err(Error::InvalidPath(format!(
                    "Output path exists but is not a directory: {}",
                    path.display()
                )));
            }
        } else {
            // Try to create the directory to test permissions
            if let Some(parent) = path.parent() {
                if parent.exists() && !parent.is_dir() {
                    return Err(Error::InvalidPath(format!(
                        "Parent path exists but is not a directory: {}",
                        parent.display()
                    )));
                }
            }
        }
        Ok(())
    }

    /// Validate language is supported
    pub fn validate_language(language: &str, supported_languages: &[String]) -> Result<()> {
        if !supported_languages.contains(&language.to_string()) {
            return Err(Error::UnsupportedLanguage(format!(
                "Language '{}' is not supported. Supported languages: {}",
                language,
                supported_languages.join(", ")
            )));
        }
        Ok(())
    }

    /// Validate service name format
    pub fn validate_service_name(name: &str) -> Result<()> {
        if name.is_empty() {
            return Err(Error::ValidationError(
                "Service name cannot be empty".to_string()
            ));
        }

        if !name.chars().next().unwrap().is_alphabetic() {
            return Err(Error::ValidationError(
                "Service name must start with a letter".to_string()
            ));
        }

        if !name.chars().all(|c| c.is_alphanumeric() || c == '_') {
            return Err(Error::ValidationError(
                "Service name can only contain letters, numbers, and underscores".to_string()
            ));
        }

        Ok(())
    }

    /// Validate generated code syntax (basic check)
    pub fn validate_generated_code_basic(code: &str, language: &str) -> Result<()> {
        match language {
            "swift" => Self::validate_swift_code_basic(code),
            "kotlin" => Self::validate_kotlin_code_basic(code),
            "typescript" => Self::validate_typescript_code_basic(code),
            _ => Ok(()), // Skip validation for unknown languages
        }
    }

    /// Basic Swift code validation
    fn validate_swift_code_basic(code: &str) -> Result<()> {
        // Check for balanced braces
        let open_braces = code.matches('{').count();
        let close_braces = code.matches('}').count();
        if open_braces != close_braces {
            return Err(Error::ValidationError(
                "Swift code has unbalanced braces".to_string()
            ));
        }

        // Check for balanced parentheses
        let open_parens = code.matches('(').count();
        let close_parens = code.matches(')').count();
        if open_parens != close_parens {
            return Err(Error::ValidationError(
                "Swift code has unbalanced parentheses".to_string()
            ));
        }

        Ok(())
    }

    /// Basic Kotlin code validation
    fn validate_kotlin_code_basic(code: &str) -> Result<()> {
        // Check for balanced braces
        let open_braces = code.matches('{').count();
        let close_braces = code.matches('}').count();
        if open_braces != close_braces {
            return Err(Error::ValidationError(
                "Kotlin code has unbalanced braces".to_string()
            ));
        }

        // Check for balanced parentheses
        let open_parens = code.matches('(').count();
        let close_parens = code.matches(')').count();
        if open_parens != close_parens {
            return Err(Error::ValidationError(
                "Kotlin code has unbalanced parentheses".to_string()
            ));
        }

        Ok(())
    }

    /// Basic TypeScript code validation
    fn validate_typescript_code_basic(code: &str) -> Result<()> {
        // Check for balanced braces
        let open_braces = code.matches('{').count();
        let close_braces = code.matches('}').count();
        if open_braces != close_braces {
            return Err(Error::ValidationError(
                "TypeScript code has unbalanced braces".to_string()
            ));
        }

        // Check for balanced parentheses
        let open_parens = code.matches('(').count();
        let close_parens = code.matches(')').count();
        if open_parens != close_parens {
            return Err(Error::ValidationError(
                "TypeScript code has unbalanced parentheses".to_string()
            ));
        }

        Ok(())
    }

    /// Validate that required imports are present
    pub fn validate_imports_present(code: &str, required_imports: &[&str], language: &str) -> Result<()> {
        let import_keyword = match language {
            "swift" => "import",
            "kotlin" => "import",
            "typescript" => "import",
            _ => return Ok(()), // Skip for unknown languages
        };

        for required_import in required_imports {
            let import_statement = format!("{} {}", import_keyword, required_import);
            if !code.contains(&import_statement) {
                return Err(Error::ValidationError(format!(
                    "Required import missing: {}",
                    import_statement
                )));
            }
        }

        Ok(())
    }

    /// Validate that code doesn't contain forbidden patterns
    pub fn validate_no_forbidden_patterns(code: &str, forbidden_patterns: &[&str]) -> Result<()> {
        for pattern in forbidden_patterns {
            if code.contains(pattern) {
                return Err(Error::ValidationError(format!(
                    "Code contains forbidden pattern: {}",
                    pattern
                )));
            }
        }
        Ok(())
    }

    /// Validate file size is reasonable
    pub fn validate_file_size(content: &str, max_size_bytes: usize) -> Result<()> {
        let size = content.len();
        if size > max_size_bytes {
            return Err(Error::ValidationError(format!(
                "Generated file is too large: {} bytes (max: {} bytes)",
                size, max_size_bytes
            )));
        }
        Ok(())
    }

    /// Validate line count is reasonable
    pub fn validate_line_count(content: &str, max_lines: usize) -> Result<()> {
        let line_count = content.lines().count();
        if line_count > max_lines {
            return Err(Error::ValidationError(format!(
                "Generated file has too many lines: {} (max: {})",
                line_count, max_lines
            )));
        }
        Ok(())
    }

    /// Comprehensive validation for generated code
    pub fn validate_generated_file(
        content: &str,
        language: &str,
        required_imports: &[&str],
        forbidden_patterns: &[&str],
        max_size_bytes: usize,
        max_lines: usize,
    ) -> Result<()> {
        // Basic syntax validation
        Self::validate_generated_code_basic(content, language)?;
        
        // Import validation
        Self::validate_imports_present(content, required_imports, language)?;
        
        // Forbidden pattern validation
        Self::validate_no_forbidden_patterns(content, forbidden_patterns)?;
        
        // Size validation
        Self::validate_file_size(content, max_size_bytes)?;
        
        // Line count validation
        Self::validate_line_count(content, max_lines)?;

        Ok(())
    }
}