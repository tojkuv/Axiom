use crate::error::{Error, Result};
use crate::validation::{SwiftValidator, ValidationResult, CompilationResult};
use std::collections::HashMap;
use std::path::Path;

/// Test runner for generated code validation and testing
pub struct TestRunner {
    /// Language-specific validators
    validators: HashMap<String, Box<dyn LanguageValidator>>,
}

impl TestRunner {
    pub fn new() -> Self {
        let mut validators: HashMap<String, Box<dyn LanguageValidator>> = HashMap::new();
        validators.insert("swift".to_string(), Box::new(SwiftValidator::new()));
        
        Self {
            validators,
        }
    }

    /// Run comprehensive tests on generated files
    pub async fn run_tests(&self, generated_files: &[String]) -> Result<TestResults> {
        let mut results = TestResults::new();

        // Group files by language
        let files_by_language = self.group_files_by_language(generated_files);

        for (language, files) in files_by_language {
            if let Some(validator) = self.validators.get(&language) {
                let language_result = validator.validate_files(&files).await?;
                results.add_language_result(language, language_result);
            }
        }

        Ok(results)
    }

    /// Group files by their target language based on file extension
    fn group_files_by_language(&self, files: &[String]) -> HashMap<String, Vec<String>> {
        let mut grouped = HashMap::new();

        for file in files {
            let language = self.detect_language(file);
            grouped.entry(language).or_insert_with(Vec::new).push(file.clone());
        }

        grouped
    }

    /// Detect programming language from file path
    fn detect_language(&self, file_path: &str) -> String {
        let path = Path::new(file_path);
        
        if let Some(extension) = path.extension().and_then(|ext| ext.to_str()) {
            match extension {
                "swift" => "swift".to_string(),
                "kt" => "kotlin".to_string(),
                "ts" => "typescript".to_string(),
                _ => "unknown".to_string(),
            }
        } else {
            "unknown".to_string()
        }
    }
}

/// Language-specific validator trait
#[async_trait::async_trait]
pub trait LanguageValidator: Send + Sync {
    async fn validate_files(&self, files: &[String]) -> Result<LanguageTestResult>;
}

/// Test results for all languages
#[derive(Debug, Default)]
pub struct TestResults {
    pub results_by_language: HashMap<String, LanguageTestResult>,
    pub overall_success: bool,
}

impl TestResults {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_language_result(&mut self, language: String, result: LanguageTestResult) {
        let success = result.validation_result.is_valid() && 
                     result.compilation_result.as_ref().map_or(true, |r| r.is_successful());
        
        if !success {
            self.overall_success = false;
        }
        
        self.results_by_language.insert(language, result);
    }

    pub fn total_files_tested(&self) -> usize {
        self.results_by_language.values()
            .map(|r| r.validation_result.files_validated)
            .sum()
    }

    pub fn total_errors(&self) -> usize {
        self.results_by_language.values()
            .map(|r| r.validation_result.errors.len())
            .sum()
    }

    pub fn total_warnings(&self) -> usize {
        self.results_by_language.values()
            .map(|r| r.validation_result.warnings.len())
            .sum()
    }
}

/// Test results for a specific language
#[derive(Debug)]
pub struct LanguageTestResult {
    pub validation_result: ValidationResult,
    pub compilation_result: Option<CompilationResult>,
    pub test_execution_result: Option<TestExecutionResult>,
}

/// Results from executing generated tests
#[derive(Debug, Default)]
pub struct TestExecutionResult {
    pub tests_run: usize,
    pub tests_passed: usize,
    pub tests_failed: usize,
    pub test_output: String,
}

// Implement LanguageValidator for SwiftValidator
#[async_trait::async_trait]
impl LanguageValidator for SwiftValidator {
    async fn validate_files(&self, files: &[String]) -> Result<LanguageTestResult> {
        let validation_result = self.validate_files(files).await?;
        let compilation_result = Some(self.compile_check(files).await?);
        
        Ok(LanguageTestResult {
            validation_result,
            compilation_result,
            test_execution_result: None, // TODO: Implement test execution
        })
    }
}


#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;

    #[tokio::test]
    async fn test_runner_groups_files_correctly() {
        let runner = TestRunner::new();
        
        let files = vec![
            "output/swift/TaskClient.swift".to_string(),
            "output/swift/TaskState.swift".to_string(),
            "output/kotlin/TaskClient.kt".to_string(),
        ];

        let grouped = runner.group_files_by_language(&files);
        
        assert_eq!(grouped.len(), 2);
        assert_eq!(grouped.get("swift").unwrap().len(), 2);
        assert_eq!(grouped.get("kotlin").unwrap().len(), 1);
    }

    #[tokio::test]
    async fn test_language_detection() {
        let runner = TestRunner::new();
        
        assert_eq!(runner.detect_language("file.swift"), "swift");
        assert_eq!(runner.detect_language("file.kt"), "kotlin");
        assert_eq!(runner.detect_language("file.ts"), "typescript");
        assert_eq!(runner.detect_language("file.unknown"), "unknown");
    }
}