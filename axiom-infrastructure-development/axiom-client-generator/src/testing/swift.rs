use crate::error::{Error, Result};
use crate::testing::runner::{LanguageValidator, LanguageTestResult, TestExecutionResult};
use crate::validation::{SwiftValidator, ValidationResult, CompilationResult};
use std::path::Path;
use std::process::Command;
use tempfile::TempDir;

/// Swift-specific test runner that can execute XCTest files
pub struct SwiftTestRunner {
    validator: SwiftValidator,
}

impl SwiftTestRunner {
    pub fn new() -> Self {
        Self {
            validator: SwiftValidator::new(),
        }
    }

    /// Run Swift tests using swift test command
    pub async fn run_swift_tests(&self, test_files: &[String]) -> Result<TestExecutionResult> {
        if test_files.is_empty() {
            return Ok(TestExecutionResult::default());
        }

        // Check if Swift toolchain is available
        if !self.is_swift_test_available() {
            return Ok(TestExecutionResult {
                tests_run: 0,
                tests_passed: 0,
                tests_failed: 0,
                test_output: "Swift test toolchain not available".to_string(),
            });
        }

        // Create a temporary Swift package to run tests
        let temp_dir = self.create_test_package(test_files).await?;
        
        // Run swift test
        let result = self.execute_swift_test(&temp_dir).await?;
        
        Ok(result)
    }

    /// Create a temporary Swift package with the test files
    async fn create_test_package(&self, test_files: &[String]) -> Result<TempDir> {
        let temp_dir = tempfile::tempdir()
            .map_err(|e| Error::IoError(e))?;

        let package_dir = temp_dir.path();

        // Create Package.swift
        let package_swift = r#"// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AxiomGeneratedTests",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "AxiomGeneratedTests", targets: ["AxiomGeneratedTests"]),
    ],
    dependencies: [
        // Mock dependencies for testing
    ],
    targets: [
        .target(
            name: "AxiomGeneratedTests",
            dependencies: []
        ),
        .testTarget(
            name: "AxiomGeneratedTestsTests",
            dependencies: ["AxiomGeneratedTests"]
        ),
    ]
)
"#;

        std::fs::write(package_dir.join("Package.swift"), package_swift)
            .map_err(|e| Error::IoError(e))?;

        // Create Sources directory
        let sources_dir = package_dir.join("Sources").join("AxiomGeneratedTests");
        std::fs::create_dir_all(&sources_dir)
            .map_err(|e| Error::IoError(e))?;

        // Create Tests directory  
        let tests_dir = package_dir.join("Tests").join("AxiomGeneratedTestsTests");
        std::fs::create_dir_all(&tests_dir)
            .map_err(|e| Error::IoError(e))?;

        // Copy test files to Tests directory
        for test_file in test_files {
            if let Some(file_name) = Path::new(test_file).file_name() {
                let dest_path = tests_dir.join(file_name);
                
                // Read the test file and modify it to work in the package
                let content = std::fs::read_to_string(test_file)
                    .map_err(|e| Error::IoError(e))?;
                
                let modified_content = self.modify_test_file_for_package(&content);
                
                std::fs::write(&dest_path, modified_content)
                    .map_err(|e| Error::IoError(e))?
            }
        }

        // Create a simple Swift file in Sources to make the package valid
        let simple_swift = r#"
import Foundation

public struct GeneratedTestHelper {
    public static func hello() -> String {
        return "Hello from generated tests"
    }
}
"#;
        std::fs::write(sources_dir.join("GeneratedTestHelper.swift"), simple_swift)
            .map_err(|e| Error::IoError(e))?;

        Ok(temp_dir)
    }

    /// Modify test file content to work within a Swift package
    fn modify_test_file_for_package(&self, content: &str) -> String {
        let mut modified = content.to_string();
        
        // Replace common imports that might not be available
        modified = modified.replace("@testable import TaskModule", "import AxiomGeneratedTests");
        modified = modified.replace("import AxiomArchitecture", "// import AxiomArchitecture");
        modified = modified.replace("import AxiomCore", "// import AxiomCore");
        
        // Add mock implementations for missing types
        let mock_implementations = r#"
// Mock implementations for testing
protocol AxiomObservableClient {
    associatedtype State
    associatedtype Action
    
    var state: State { get async }
    func process(_ action: Action) async throws
    func updateState(_ update: @escaping (inout State) -> Void) async
}

extension AxiomObservableClient {
    func updateState(_ update: @escaping (inout State) -> Void) async {
        // Mock implementation
    }
}
"#;
        
        modified = format!("{}\n{}", mock_implementations, modified);
        modified
    }

    /// Execute swift test command
    async fn execute_swift_test(&self, temp_dir: &TempDir) -> Result<TestExecutionResult> {
        let output = Command::new("swift")
            .arg("test")
            .current_dir(temp_dir.path())
            .output()
            .map_err(|e| Error::Validation(format!("Failed to run swift test: {}", e)))?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        let full_output = format!("STDOUT:\n{}\nSTDERR:\n{}", stdout, stderr);

        // Parse the output to extract test results
        let (tests_run, tests_passed, tests_failed) = self.parse_test_output(&stdout);

        Ok(TestExecutionResult {
            tests_run,
            tests_passed,
            tests_failed,
            test_output: full_output,
        })
    }

    /// Parse swift test output to extract test counts
    fn parse_test_output(&self, output: &str) -> (usize, usize, usize) {
        let mut tests_run = 0;
        let mut tests_passed = 0;
        let mut tests_failed = 0;

        for line in output.lines() {
            if line.contains("Test Suite") && line.contains("passed") {
                // Try to extract numbers from lines like "Test Suite 'All tests' passed at 2024-01-01 10:00:00.000."
                // This is a simplified parser - could be more sophisticated
                continue;
            } else if line.contains(" passed (") {
                // Parse individual test results
                tests_run += 1;
                tests_passed += 1;
            } else if line.contains(" failed (") {
                tests_run += 1;
                tests_failed += 1;
            }
        }

        // If we couldn't parse individual tests, try to find summary
        if tests_run == 0 {
            for line in output.lines() {
                if line.contains("tests passed") || line.contains("tests failed") {
                    // Try to extract from summary line
                    if let Some(captures) = regex::Regex::new(r"(\d+) tests?")
                        .ok()
                        .and_then(|re| re.captures(line)) 
                    {
                        if let Ok(count) = captures[1].parse::<usize>() {
                            tests_run = count;
                            if line.contains("passed") {
                                tests_passed = count;
                            } else if line.contains("failed") {
                                tests_failed = count;
                            }
                        }
                    }
                    break;
                }
            }
        }

        (tests_run, tests_passed, tests_failed)
    }

    /// Check if swift test command is available
    fn is_swift_test_available(&self) -> bool {
        Command::new("swift")
            .arg("--version")
            .output()
            .is_ok()
    }
}

#[async_trait::async_trait]
impl LanguageValidator for SwiftTestRunner {
    async fn validate_files(&self, files: &[String]) -> Result<LanguageTestResult> {
        // First run standard validation
        let validation_result = self.validator.validate_files(files).await?;
        let compilation_result = Some(self.validator.compile_check(files).await?);
        
        // Run tests if any test files are present
        let test_files: Vec<String> = files.iter()
            .filter(|f| f.contains("Test") && f.ends_with(".swift"))
            .cloned()
            .collect();
            
        let test_execution_result = if !test_files.is_empty() {
            Some(self.run_swift_tests(&test_files).await?)
        } else {
            None
        };
        
        Ok(LanguageTestResult {
            validation_result,
            compilation_result,
            test_execution_result,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_parse_test_output() {
        let runner = SwiftTestRunner::new();
        
        let output = r#"
Test Suite 'All tests' started at 2024-01-01 10:00:00.000
Test Suite 'TaskClientTests.xctest' started at 2024-01-01 10:00:00.000
Test Case '-[TaskClientTests testCreateTask]' started.
Test Case '-[TaskClientTests testCreateTask]' passed (0.001 seconds).
Test Case '-[TaskClientTests testGetTasks]' started.
Test Case '-[TaskClientTests testGetTasks]' failed (0.002 seconds).
Test Suite 'TaskClientTests.xctest' failed at 2024-01-01 10:00:00.003.
"#;

        let (tests_run, tests_passed, tests_failed) = runner.parse_test_output(output);
        
        assert_eq!(tests_run, 2);
        assert_eq!(tests_passed, 1);
        assert_eq!(tests_failed, 1);
    }
}