use crate::error::{Error, Result};
use std::path::Path;
use std::process::Command;

/// Swift code validation framework for generated client code
pub struct SwiftValidator {
    pub temp_project_path: Option<String>,
}

impl SwiftValidator {
    pub fn new() -> Self {
        Self {
            temp_project_path: None,
        }
    }

    /// Validate Swift files using syntax checking and basic compilation
    pub async fn validate_files(&self, file_paths: &[String]) -> Result<ValidationResult> {
        let mut result = ValidationResult::new();

        for file_path in file_paths {
            if file_path.ends_with(".swift") {
                let file_result = self.validate_single_file(file_path).await?;
                result.merge(file_result);
            }
        }

        Ok(result)
    }

    /// Validate a single Swift file
    async fn validate_single_file(&self, file_path: &str) -> Result<ValidationResult> {
        let mut result = ValidationResult::new();
        let path = Path::new(file_path);

        if !path.exists() {
            result.errors.push(format!("File does not exist: {}", file_path));
            return Ok(result);
        }

        let content = std::fs::read_to_string(path)
            .map_err(|e| Error::IoError(e))?;

        // Basic syntax validation
        self.validate_syntax(&content, file_path, &mut result);

        // Template validation
        self.validate_template_processing(&content, file_path, &mut result);

        // Swift-specific validation
        self.validate_swift_patterns(&content, file_path, &mut result);

        // Axiom integration validation
        self.validate_axiom_integration(&content, file_path, &mut result);

        Ok(result)
    }

    /// Validate basic syntax patterns
    fn validate_syntax(&self, content: &str, file_path: &str, result: &mut ValidationResult) {
        // Check balanced braces
        let open_braces = content.matches('{').count();
        let close_braces = content.matches('}').count();
        if open_braces != close_braces {
            result.errors.push(format!("{}: Unbalanced braces ({} open, {} close)", file_path, open_braces, close_braces));
        }

        // Check balanced parentheses
        let open_parens = content.matches('(').count();
        let close_parens = content.matches(')').count();
        if open_parens != close_parens {
            result.errors.push(format!("{}: Unbalanced parentheses ({} open, {} close)", file_path, open_parens, close_parens));
        }

        // Check balanced brackets
        let open_brackets = content.matches('[').count();
        let close_brackets = content.matches(']').count();
        if open_brackets != close_brackets {
            result.errors.push(format!("{}: Unbalanced brackets ({} open, {} close)", file_path, open_brackets, close_brackets));
        }

        result.files_validated += 1;
    }

    /// Validate that template processing completed successfully
    fn validate_template_processing(&self, content: &str, file_path: &str, result: &mut ValidationResult) {
        // Check for unprocessed template variables
        if content.contains("{{") || content.contains("}}") {
            let template_vars: Vec<&str> = content.lines()
                .enumerate()
                .filter(|(_, line)| line.contains("{{") || line.contains("}}"))
                .map(|(line_num, line)| line.trim())
                .collect();
                
            let error_msg = format!(
                "{}: Contains unprocessed template variables. Found {} instances:\n{}",
                file_path,
                template_vars.len(),
                template_vars.iter().take(3).enumerate()
                    .map(|(i, line)| format!("  Line {}: {}", i + 1, line))
                    .collect::<Vec<_>>()
                    .join("\n")
            );
            result.errors.push(error_msg);
        }

        // Check for template artifacts
        if content.contains("{% ") || content.contains(" %}") {
            let template_logic: Vec<&str> = content.lines()
                .enumerate()
                .filter(|(_, line)| line.contains("{% ") || line.contains(" %}"))
                .map(|(line_num, line)| line.trim())
                .collect();
                
            let error_msg = format!(
                "{}: Contains unprocessed template logic. Found {} instances:\n{}",
                file_path,
                template_logic.len(),
                template_logic.iter().take(3).enumerate()
                    .map(|(i, line)| format!("  Line {}: {}", i + 1, line))
                    .collect::<Vec<_>>()
                    .join("\n")
            );
            result.errors.push(error_msg);
        }
    }

    /// Validate Swift-specific patterns and conventions
    fn validate_swift_patterns(&self, content: &str, file_path: &str, result: &mut ValidationResult) {
        // Check for required imports
        if file_path.contains("Client") && !content.contains("import Foundation") {
            result.warnings.push(format!(
                "{}: Missing Foundation import. Add 'import Foundation' at the top of the file.", 
                file_path
            ));
        }

        // Check for proper access control
        if !content.contains("public ") && !file_path.contains("Test") {
            result.warnings.push(format!(
                "{}: No public declarations found. Ensure types are marked 'public' for external use:\n  Example: public struct MyState {{ ... }}", 
                file_path
            ));
        }

        // Check for Swift naming conventions
        if content.contains("_") && file_path.contains("Client") {
            let lines_with_underscore: Vec<(usize, &str)> = content.lines()
                .enumerate()
                .filter(|(_, line)| {
                    line.contains("_") && 
                    !line.trim().starts_with("//") && 
                    !line.contains("private") &&
                    !line.contains("@_") // Allow compiler attributes
                })
                .collect();
            
            if !lines_with_underscore.is_empty() {
                let examples: String = lines_with_underscore.iter()
                    .take(3)
                    .map(|(line_num, line)| format!("  Line {}: {}", line_num + 1, line.trim()))
                    .collect::<Vec<_>>()
                    .join("\n");
                    
                result.warnings.push(format!(
                    "{}: Potential Swift naming convention violations (underscores in public API).\n  Use camelCase instead:\n{}\n  Suggestion: Convert snake_case to camelCase (e.g., user_id → userId)", 
                    file_path, examples
                ));
            }
        }

        // Validate actor usage with detailed guidance
        if content.contains("actor ") {
            if !content.contains("@globalActor") && file_path.contains("Client") {
                result.warnings.push(format!(
                    "{}: Client actor should use @globalActor for proper isolation.\n  Add '@globalActor' annotation before 'actor' declaration:\n  Example: @globalActor\n           public actor MyClient {{ ... }}", 
                    file_path
                ));
            }
            
            // Check for proper actor protocol conformance
            if content.contains("actor ") && !content.contains(": AxiomClient") && file_path.contains("Client") {
                result.warnings.push(format!(
                    "{}: Client actor should conform to AxiomClient protocol.\n  Update declaration: actor MyClient: AxiomClient {{ ... }}", 
                    file_path
                ));
            }
        }

        // Validate protocol conformance with specific guidance
        if content.contains(": Sendable") && content.contains("actor ") {
            result.warnings.push(format!(
                "{}: Actor types are Sendable by default, no need to explicitly conform.\n  Remove ': Sendable' from actor declaration.", 
                file_path
            ));
        }

        // Check for proper error handling patterns
        if content.contains("func ") && content.contains("throws") && !content.contains("AxiomError") {
            result.warnings.push(format!(
                "{}: Consider using AxiomError for consistent error handling across the framework.\n  Example: func myMethod() throws -> ResultType // change to → func myMethod() throws(AxiomError) -> ResultType", 
                file_path
            ));
        }

        // Validate async/await patterns
        if content.contains("async ") && content.contains("func ") {
            let async_funcs_without_await = content.lines()
                .filter(|line| line.contains("async") && line.contains("func") && !content.contains("await"))
                .count();
                
            if async_funcs_without_await > 0 {
                result.warnings.push(format!(
                    "{}: Async functions detected but no 'await' calls found. Ensure async functions actually perform asynchronous work.", 
                    file_path
                ));
            }
        }
    }

    /// Validate Axiom framework integration patterns
    fn validate_axiom_integration(&self, content: &str, file_path: &str, result: &mut ValidationResult) {
        if file_path.contains("Client") {
            // Check for required Axiom imports
            if !content.contains("import AxiomCore") && !content.contains("import AxiomArchitecture") {
                result.errors.push(format!("{}: Missing AxiomCore or AxiomArchitecture import", file_path));
            }

            // Check for proper protocol conformance
            if content.contains("actor ") && !content.contains(": AxiomClient") {
                result.errors.push(format!("{}: Client actor should conform to AxiomClient protocol", file_path));
            }

            // Check for required AxiomClient protocol methods
            if content.contains(": AxiomClient") {
                if !content.contains("var stateStream: AsyncStream") {
                    result.errors.push(format!("{}: Missing stateStream property", file_path));
                }
                if !content.contains("func process(") {
                    result.errors.push(format!("{}: Missing process method", file_path));
                }
                if !content.contains("func getCurrentState(") {
                    result.errors.push(format!("{}: Missing getCurrentState method", file_path));
                }
                if !content.contains("func rollbackToState(") {
                    result.errors.push(format!("{}: Missing rollbackToState method", file_path));
                }
            }

            // Check for lifecycle hooks
            if content.contains("func process(") {
                if !content.contains("stateWillUpdate") || !content.contains("stateDidUpdate") {
                    result.warnings.push(format!("{}: Missing lifecycle hooks (stateWillUpdate/stateDidUpdate)", file_path));
                }
            }

            // Check for proper error handling
            if content.contains("func process(") && !content.contains("AxiomError") {
                result.warnings.push(format!("{}: Should use AxiomError for error handling", file_path));
            }

            // Check for state streaming implementation
            if content.contains("stateStream") && !content.contains("AsyncStream") {
                result.errors.push(format!("{}: stateStream should return AsyncStream", file_path));
            }

            // Check for actor isolation
            if content.contains("actor ") && !content.contains("@globalActor") {
                result.warnings.push(format!("{}: Client actor should use @globalActor", file_path));
            }
        }

        if file_path.contains("State") {
            // Check for AxiomState conformance
            if !content.contains(": AxiomState") {
                result.errors.push(format!("{}: State should conform to AxiomState protocol", file_path));
            }

            // Check for required conformances
            if !content.contains(": Sendable") && !content.contains(", Sendable") {
                result.warnings.push(format!("{}: State should conform to Sendable", file_path));
            }

            if !content.contains(": Equatable") && !content.contains(", Equatable") {
                result.warnings.push(format!("{}: State should conform to Equatable", file_path));
            }

            if !content.contains(": Hashable") && !content.contains(", Hashable") {
                result.warnings.push(format!("{}: State should conform to Hashable", file_path));
            }

            // Check for immutability
            if content.contains("var ") && !content.contains("computed property") {
                let mutable_properties: Vec<&str> = content.lines()
                    .filter(|line| line.contains("public var") || line.contains("internal var"))
                    .collect();
                
                if !mutable_properties.is_empty() {
                    result.warnings.push(format!("{}: State properties should be immutable (use 'let')", file_path));
                }
            }

            // Check for functional update methods
            if content.contains("struct ") {
                let update_methods = ["adding", "with", "updating", "removing", "withLoading", "withError"];
                let has_update_methods = update_methods.iter().any(|method| content.contains(method));
                
                if !has_update_methods {
                    result.warnings.push(format!("{}: State should have functional update methods", file_path));
                }
            }
        }

        if file_path.contains("Action") {
            // Check for Sendable conformance
            if !content.contains(": Sendable") && !content.contains(", Sendable") {
                result.warnings.push(format!("{}: Action should conform to Sendable", file_path));
            }

            // Check for validation methods
            if content.contains("enum ") {
                if !content.contains("var isValid") {
                    result.warnings.push(format!("{}: Action enum should have isValid property", file_path));
                }
                if !content.contains("var validationErrors") {
                    result.warnings.push(format!("{}: Action enum should have validationErrors property", file_path));
                }
            }

            // Check for action metadata
            if content.contains("enum ") {
                let metadata_properties = ["requiresNetworkAccess", "modifiesState", "actionName"];
                let has_metadata = metadata_properties.iter().any(|prop| content.contains(prop));
                
                if !has_metadata {
                    result.warnings.push(format!("{}: Action enum should have metadata properties", file_path));
                }
            }
        }

        // Check for error types integration
        if file_path.contains("Error") || content.contains("AxiomError") {
            if !content.contains("LocalizedError") {
                result.warnings.push(format!("{}: Error types should conform to LocalizedError", file_path));
            }
            if !content.contains("isRecoverable") {
                result.warnings.push(format!("{}: Error types should have isRecoverable property", file_path));
            }
        }
    }

    /// Attempt to compile Swift files using swiftc (if available)
    pub async fn compile_check(&self, file_paths: &[String]) -> Result<CompilationResult> {
        let mut result = CompilationResult::new();

        // Check if Swift compiler is available
        if !self.is_swift_available() {
            result.warnings.push("Swift compiler not available - skipping compilation check".to_string());
            return Ok(result);
        }

        for file_path in file_paths {
            if file_path.ends_with(".swift") {
                match self.try_compile_file(file_path).await {
                    Ok(output) => {
                        result.successful_compilations += 1;
                        if !output.is_empty() {
                            result.warnings.push(format!("{}: {}", file_path, output));
                        }
                    }
                    Err(e) => {
                        result.compilation_errors.push(format!("{}: {}", file_path, e));
                    }
                }
            }
        }

        Ok(result)
    }

    /// Check if Swift compiler is available
    fn is_swift_available(&self) -> bool {
        Command::new("swiftc")
            .arg("--version")
            .output()
            .is_ok()
    }

    /// Try to compile a single Swift file
    async fn try_compile_file(&self, file_path: &str) -> Result<String> {
        let output = Command::new("swiftc")
            .arg("-typecheck")
            .arg(file_path)
            .output()
            .map_err(|e| Error::Validation(format!("Failed to run swiftc: {}", e)))?;

        if output.status.success() {
            Ok(String::from_utf8_lossy(&output.stdout).to_string())
        } else {
            Err(Error::Validation(
                String::from_utf8_lossy(&output.stderr).to_string()
            ))
        }
    }
}

/// Result of Swift validation
#[derive(Debug, Default)]
pub struct ValidationResult {
    pub files_validated: usize,
    pub errors: Vec<String>,
    pub warnings: Vec<String>,
    pub is_valid: bool,
}

impl ValidationResult {
    pub fn new() -> Self {
        Self {
            files_validated: 0,
            errors: Vec::new(),
            warnings: Vec::new(),
            is_valid: true,
        }
    }

    pub fn is_valid(&self) -> bool {
        self.errors.is_empty()
    }

    pub fn merge(&mut self, other: ValidationResult) {
        self.files_validated += other.files_validated;
        self.errors.extend(other.errors);
        self.warnings.extend(other.warnings);
        self.is_valid = self.errors.is_empty();
    }
    
    pub fn add_error(&mut self, error: String) {
        self.errors.push(error);
        self.is_valid = false;
    }
    
    pub fn add_warning(&mut self, warning: String) {
        self.warnings.push(warning);
    }
    
    /// Get a formatted summary of validation results
    pub fn summary(&self) -> String {
        let status = if self.is_valid() { "✅ PASSED" } else { "❌ FAILED" };
        format!(
            "Validation Summary: {}\n  📁 Files validated: {}\n  ❌ Errors: {}\n  ⚠️  Warnings: {}",
            status, self.files_validated, self.errors.len(), self.warnings.len()
        )
    }
    
    /// Get detailed error report with suggestions
    pub fn detailed_report(&self) -> String {
        let mut report = String::new();
        
        report.push_str(&self.summary());
        
        if !self.errors.is_empty() {
            report.push_str("\n\n🚨 ERRORS (must be fixed):\n");
            for (i, error) in self.errors.iter().enumerate() {
                report.push_str(&format!("{}. {}\n", i + 1, error));
            }
        }
        
        if !self.warnings.is_empty() {
            report.push_str("\n\n⚠️  WARNINGS (recommendations):\n");
            for (i, warning) in self.warnings.iter().enumerate() {
                report.push_str(&format!("{}. {}\n", i + 1, warning));
            }
        }
        
        if self.is_valid() {
            report.push_str("\n\n🎉 All validations passed! Your generated Swift code follows Axiom framework patterns correctly.");
        } else {
            report.push_str("\n\n💡 Fix the errors above to ensure your generated code compiles and integrates properly with the Axiom framework.");
        }
        
        report
    }
    
    /// Get errors by category for better organization
    pub fn categorize_issues(&self) -> std::collections::HashMap<String, Vec<String>> {
        let mut categorized = std::collections::HashMap::new();
        
        for error in &self.errors {
            let category = if error.contains("template") {
                "Template Processing"
            } else if error.contains("AxiomClient") || error.contains("AxiomState") {
                "Axiom Integration"
            } else if error.contains("syntax") || error.contains("braces") || error.contains("parentheses") {
                "Syntax"
            } else if error.contains("import") {
                "Imports"
            } else {
                "General"
            };
            
            categorized.entry(category.to_string())
                .or_insert_with(Vec::new)
                .push(error.clone());
        }
        
        for warning in &self.warnings {
            let category = if warning.contains("naming") {
                "Naming Conventions"
            } else if warning.contains("actor") {
                "Actor Patterns"
            } else if warning.contains("import") {
                "Imports"
            } else if warning.contains("public") {
                "Access Control"
            } else {
                "Best Practices"
            };
            
            categorized.entry(format!("{} (Warnings)", category))
                .or_insert_with(Vec::new)
                .push(warning.clone());
        }
        
        categorized
    }
}

/// Result of Swift compilation check
#[derive(Debug, Default)]
pub struct CompilationResult {
    pub successful_compilations: usize,
    pub compilation_errors: Vec<String>,
    pub warnings: Vec<String>,
}

impl CompilationResult {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_successful(&self) -> bool {
        self.compilation_errors.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;

    #[tokio::test]
    async fn test_validate_valid_swift_file() {
        let validator = SwiftValidator::new();
        
        let temp_file = NamedTempFile::new().unwrap();
        let file_path = temp_file.path().with_extension("swift");
        
        let content = r#"
import Foundation

public struct TestState: Sendable, Equatable {
    public var tasks: [Task] = []
    public var isLoading: Bool = false
}
"#;
        
        std::fs::write(&file_path, content).unwrap();
        
        let result = validator.validate_single_file(file_path.to_string_lossy().as_ref()).await.unwrap();
        
        assert!(result.is_valid(), "Should be valid: {:?}", result.errors);
        assert_eq!(result.files_validated, 1);
    }

    #[tokio::test]
    async fn test_validate_invalid_swift_file() {
        let validator = SwiftValidator::new();
        
        let temp_file = NamedTempFile::new().unwrap();
        let file_path = temp_file.path().with_extension("swift");
        
        let content = r#"
public struct TestState {
    public var tasks: [Task] = []
    // Missing closing brace
"#;
        
        std::fs::write(&file_path, content).unwrap();
        
        let result = validator.validate_single_file(file_path.to_string_lossy().as_ref()).await.unwrap();
        
        assert!(!result.is_valid(), "Should be invalid");
        assert!(!result.errors.is_empty());
    }

    #[tokio::test]
    async fn test_validate_template_artifacts() {
        let validator = SwiftValidator::new();
        
        let temp_file = NamedTempFile::new().unwrap();
        let file_path = temp_file.path().with_extension("swift");
        
        let content = r#"
public struct {{ state_name }}: Sendable {
    {% for field in fields %}
    public var {{ field.name }}: {{ field.type }}
    {% endfor %}
}
"#;
        
        std::fs::write(&file_path, content).unwrap();
        
        let result = validator.validate_single_file(file_path.to_string_lossy().as_ref()).await.unwrap();
        
        assert!(!result.is_valid(), "Should detect template artifacts");
        assert!(result.errors.iter().any(|e| e.contains("unprocessed template")));
    }
}