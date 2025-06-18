//! Test fixtures for consistent test data

use std::path::{Path, PathBuf};

/// Fixture manager for loading test data
pub struct TestFixtures {
    fixtures_dir: PathBuf,
}

impl TestFixtures {
    pub fn new() -> Self {
        let fixtures_dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures");
        Self { fixtures_dir }
    }
    
    /// Load a proto fixture file
    pub fn load_proto(&self, filename: &str) -> String {
        let path = self.fixtures_dir.join("proto").join(filename);
        std::fs::read_to_string(&path)
            .unwrap_or_else(|_| panic!("Failed to load proto fixture: {}", path.display()))
    }
    
    /// Load an expected Swift output fixture
    pub fn load_expected_swift(&self, filename: &str) -> String {
        let path = self.fixtures_dir.join("expected_swift").join(filename);
        std::fs::read_to_string(&path)
            .unwrap_or_else(|_| panic!("Failed to load Swift fixture: {}", path.display()))
    }
    
    /// Load a configuration fixture
    pub fn load_config(&self, filename: &str) -> String {
        let path = self.fixtures_dir.join("config").join(filename);
        std::fs::read_to_string(&path)
            .unwrap_or_else(|_| panic!("Failed to load config fixture: {}", path.display()))
    }
    
    /// Get the path to a proto fixture
    pub fn proto_path(&self, filename: &str) -> PathBuf {
        self.fixtures_dir.join("proto").join(filename)
    }
    
    /// Get the path to the proto fixtures directory
    pub fn proto_dir(&self) -> PathBuf {
        self.fixtures_dir.join("proto")
    }
    
    /// Get the path to the expected Swift fixtures directory
    pub fn expected_swift_dir(&self) -> PathBuf {
        self.fixtures_dir.join("expected_swift")
    }
    
    /// Get the path to the config fixtures directory
    pub fn config_dir(&self) -> PathBuf {
        self.fixtures_dir.join("config")
    }
    
    /// List all available proto fixtures
    pub fn list_proto_fixtures(&self) -> Vec<String> {
        self.list_files_in_dir(&self.proto_dir(), "proto")
    }
    
    /// List all available Swift fixtures
    pub fn list_swift_fixtures(&self) -> Vec<String> {
        self.list_files_in_dir(&self.expected_swift_dir(), "swift")
    }
    
    /// List all available config fixtures
    pub fn list_config_fixtures(&self) -> Vec<String> {
        self.list_files_in_dir(&self.config_dir(), "json")
    }
    
    fn list_files_in_dir(&self, dir: &Path, extension: &str) -> Vec<String> {
        if !dir.exists() {
            return vec![];
        }
        
        std::fs::read_dir(dir)
            .unwrap_or_else(|_| panic!("Failed to read directory: {}", dir.display()))
            .filter_map(|entry| {
                let entry = entry.ok()?;
                let path = entry.path();
                if path.is_file() && path.extension()?.to_str()? == extension {
                    path.file_name()?.to_str().map(String::from)
                } else {
                    None
                }
            })
            .collect()
    }
}

impl Default for TestFixtures {
    fn default() -> Self {
        Self::new()
    }
}

/// Predefined fixture constants
pub mod fixtures {
    pub const TASK_SERVICE_PROTO: &str = "task_service.proto";
    pub const USER_SERVICE_PROTO: &str = "user_service.proto";
    
    pub const TASK_CLIENT_SWIFT: &str = "TaskClient.swift";
    pub const TASK_STATE_SWIFT: &str = "TaskState.swift";
    pub const TASK_ACTION_SWIFT: &str = "TaskAction.swift";
    
    pub const TEST_CONFIG_JSON: &str = "test_config.json";
}

/// Fixture data for proto files
pub mod proto_fixtures {
    use super::TestFixtures;
    
    /// Get the task service proto content
    pub fn task_service() -> String {
        TestFixtures::new().load_proto(super::fixtures::TASK_SERVICE_PROTO)
    }
    
    /// Get the user service proto content
    pub fn user_service() -> String {
        TestFixtures::new().load_proto(super::fixtures::USER_SERVICE_PROTO)
    }
    
    /// Get a simple proto for basic testing
    pub fn simple_proto() -> String {
        r#"
syntax = "proto3";

package simple;

service SimpleService {
    rpc GetMessage(GetMessageRequest) returns (Message);
}

message GetMessageRequest {
    string id = 1;
}

message Message {
    string id = 1;
    string content = 2;
}
"#.to_string()
    }
    
    /// Get a proto with various field types for comprehensive testing
    pub fn comprehensive_proto() -> String {
        r#"
syntax = "proto3";

package comprehensive;

import "google/protobuf/timestamp.proto";

service ComprehensiveService {
    rpc TestMethod(TestRequest) returns (TestResponse);
}

message TestRequest {
    string string_field = 1;
    int32 int32_field = 2;
    int64 int64_field = 3;
    uint32 uint32_field = 4;
    uint64 uint64_field = 5;
    bool bool_field = 6;
    float float_field = 7;
    double double_field = 8;
    bytes bytes_field = 9;
    repeated string repeated_field = 10;
    map<string, string> map_field = 11;
    google.protobuf.Timestamp timestamp_field = 12;
    NestedMessage nested_field = 13;
    TestEnum enum_field = 14;
}

message TestResponse {
    bool success = 1;
    string message = 2;
}

message NestedMessage {
    string value = 1;
}

enum TestEnum {
    TEST_ENUM_UNSPECIFIED = 0;
    TEST_ENUM_VALUE1 = 1;
    TEST_ENUM_VALUE2 = 2;
}
"#.to_string()
    }
}

/// Fixture data for expected Swift output
pub mod swift_fixtures {
    use super::TestFixtures;
    
    /// Get the expected TaskClient Swift code
    pub fn task_client() -> String {
        TestFixtures::new().load_expected_swift(super::fixtures::TASK_CLIENT_SWIFT)
    }
    
    /// Get the expected TaskState Swift code
    pub fn task_state() -> String {
        TestFixtures::new().load_expected_swift(super::fixtures::TASK_STATE_SWIFT)
    }
    
    /// Get the expected TaskAction Swift code
    pub fn task_action() -> String {
        TestFixtures::new().load_expected_swift(super::fixtures::TASK_ACTION_SWIFT)
    }
    
    /// Get a minimal Swift client for testing
    pub fn minimal_client() -> String {
        r#"
import Foundation
import AxiomCore
import AxiomArchitecture

@globalActor
public actor SimpleClient: AxiomClient {
    public typealias StateType = SimpleState
    public typealias ActionType = SimpleAction
    
    private var _state: SimpleState
    
    public init() {
        self._state = SimpleState()
    }
    
    public var stateStream: AsyncStream<SimpleState> {
        AsyncStream { continuation in
            continuation.yield(_state)
        }
    }
    
    public func process(_ action: SimpleAction) async throws {
        // Simple implementation
    }
}
"#.to_string()
    }
}

/// Fixture data for configuration files
pub mod config_fixtures {
    use super::TestFixtures;
    use serde_json::Value;
    
    /// Get the test configuration
    pub fn test_config() -> String {
        TestFixtures::new().load_config(super::fixtures::TEST_CONFIG_JSON)
    }
    
    /// Get the test configuration as JSON value
    pub fn test_config_json() -> Value {
        let config_str = test_config();
        serde_json::from_str(&config_str)
            .expect("Failed to parse test config JSON")
    }
    
    /// Get a minimal configuration for testing
    pub fn minimal_config() -> String {
        r#"
{
  "swift": {
    "axiom_version": "latest",
    "client_suffix": "Client",
    "generate_tests": true
  },
  "generation": {
    "generate_contracts": true,
    "generate_clients": true,
    "force_overwrite": false
  },
  "output": {
    "base_path": "./Generated",
    "sources_dir": "Sources",
    "tests_dir": "Tests"
  },
  "proto_paths": ["./test.proto"]
}
"#.to_string()
    }
    
    /// Get a comprehensive configuration for testing
    pub fn comprehensive_config() -> String {
        r#"
{
  "swift": {
    "axiom_version": "2.0.0",
    "client_suffix": "Manager",
    "generate_tests": true,
    "package_name": "TestPackage",
    "module_imports": ["Foundation", "AxiomCore", "AxiomArchitecture"],
    "style_guide": "axiom"
  },
  "generation": {
    "generate_contracts": true,
    "generate_clients": true,
    "force_overwrite": true,
    "include_documentation": true,
    "generate_tests": true
  },
  "validation": {
    "validate_syntax": true,
    "validate_compilation": true,
    "swift_version": "5.9"
  },
  "output": {
    "base_path": "./Generated/Swift",
    "sources_dir": "Sources",
    "tests_dir": "Tests",
    "create_package_swift": true,
    "organize_by_service": true
  },
  "proto_paths": ["./proto/"],
  "services": ["TestService"]
}
"#.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_fixtures_initialization() {
        let fixtures = TestFixtures::new();
        assert!(fixtures.fixtures_dir.exists());
    }
    
    #[test]
    fn test_proto_fixtures_loading() {
        let task_service = proto_fixtures::task_service();
        assert!(!task_service.is_empty());
        assert!(task_service.contains("service TaskService"));
        
        let user_service = proto_fixtures::user_service();
        assert!(!user_service.is_empty());
        assert!(user_service.contains("service UserService"));
    }
    
    #[test]
    fn test_swift_fixtures_loading() {
        let task_client = swift_fixtures::task_client();
        assert!(!task_client.is_empty());
        assert!(task_client.contains("public actor TaskClient"));
        
        let task_state = swift_fixtures::task_state();
        assert!(!task_state.is_empty());
        assert!(task_state.contains("public struct TaskState"));
        
        let task_action = swift_fixtures::task_action();
        assert!(!task_action.is_empty());
        assert!(task_action.contains("public enum TaskAction"));
    }
    
    #[test]
    fn test_config_fixtures_loading() {
        let test_config = config_fixtures::test_config();
        assert!(!test_config.is_empty());
        
        let config_json = config_fixtures::test_config_json();
        assert!(config_json.is_object());
        assert!(config_json.get("swift").is_some());
        assert!(config_json.get("generation").is_some());
    }
    
    #[test]
    fn test_fixtures_listing() {
        let fixtures = TestFixtures::new();
        
        let proto_fixtures = fixtures.list_proto_fixtures();
        assert!(!proto_fixtures.is_empty());
        
        let swift_fixtures = fixtures.list_swift_fixtures();
        assert!(!swift_fixtures.is_empty());
        
        let config_fixtures = fixtures.list_config_fixtures();
        assert!(!config_fixtures.is_empty());
    }
}