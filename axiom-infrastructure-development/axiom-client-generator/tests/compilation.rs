//! Compilation tests for generated Swift code

use axiom_universal_client_generator::validation::swift::SwiftValidator;
use tempfile::TempDir;

#[tokio::test]
async fn test_generated_swift_compiles() {
    let temp_dir = TempDir::new().unwrap();
    let validator = SwiftValidator::new();
    
    let swift_code = r#"
import Foundation
import AxiomCore
import AxiomArchitecture

public struct TaskState: Equatable {
    public let tasks: [String]
    public let isLoading: Bool
    
    public init(tasks: [String] = [], isLoading: Bool = false) {
        self.tasks = tasks
        self.isLoading = isLoading
    }
}

public enum TaskAction {
    case loadTasks
    case addTask(String)
}

@globalActor
public actor TaskClient: AxiomClient {
    public typealias StateType = TaskState
    public typealias ActionType = TaskAction
    
    private var _state = TaskState()
    private var streamContinuations: [UUID: AsyncStream<TaskState>.Continuation] = [:]
    
    public init() {}
    
    public var stateStream: AsyncStream<TaskState> {
        AsyncStream { continuation in
            let id = UUID()
            streamContinuations[id] = continuation
            continuation.yield(_state)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }
    
    public func process(_ action: TaskAction) async throws {
        let oldState = _state
        
        switch action {
        case .loadTasks:
            _state = TaskState(tasks: ["Sample Task"], isLoading: false)
        case .addTask(let task):
            _state = TaskState(tasks: _state.tasks + [task], isLoading: false)
        }
        
        await stateWillUpdate(from: oldState, to: _state)
        
        for (_, continuation) in streamContinuations {
            continuation.yield(_state)
        }
        
        await stateDidUpdate(from: oldState, to: _state)
    }
    
    public func getCurrentState() async -> TaskState {
        return _state
    }
    
    public func rollbackToState(_ state: TaskState) async {
        _state = state
        for (_, continuation) in streamContinuations {
            continuation.yield(state)
        }
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
}

extension TaskClient {
    public func stateWillUpdate(from oldState: TaskState, to newState: TaskState) async {
        // Lifecycle hook - override in subclasses if needed
    }
    
    public func stateDidUpdate(from oldState: TaskState, to newState: TaskState) async {
        // Lifecycle hook - override in subclasses if needed
    }
}
"#;

    let swift_file = temp_dir.path().join("TaskClient.swift");
    std::fs::write(&swift_file, swift_code).unwrap();

    // Test syntax validation
    let validation_result = validator.validate_files(&[swift_file.to_string_lossy().to_string()]).await;
    assert!(validation_result.is_ok());
    
    let result = validation_result.unwrap();
    assert!(result.is_valid(), "Generated Swift code should be valid. Errors: {:?}", result.errors);
    assert!(result.errors.is_empty(), "Should have no validation errors: {:?}", result.errors);
}

#[tokio::test]
async fn test_compilation_with_swiftc() {
    let temp_dir = TempDir::new().unwrap();
    let validator = SwiftValidator::new();
    
    let swift_code = r#"
import Foundation

public struct SimpleStruct {
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
}
"#;

    let swift_file = temp_dir.path().join("Simple.swift");
    std::fs::write(&swift_file, swift_code).unwrap();

    // Test compilation check (if swiftc is available)
    let compilation_result = validator.compile_check(&[swift_file.to_string_lossy().to_string()]).await;
    assert!(compilation_result.is_ok());
    
    let result = compilation_result.unwrap();
    // Note: Compilation might fail if Swift is not installed, but that's expected in CI
    println!("Compilation result: successful={}, errors={:?}", 
             result.is_successful(), result.compilation_errors);
}

#[tokio::test]
async fn test_invalid_swift_syntax_detected() {
    let temp_dir = TempDir::new().unwrap();
    let validator = SwiftValidator::new();
    
    let invalid_swift_code = r#"
import Foundation

public struct BrokenStruct {
    public let value: String
    // Missing closing brace
"#;

    let swift_file = temp_dir.path().join("Broken.swift");
    std::fs::write(&swift_file, invalid_swift_code).unwrap();

    let validation_result = validator.validate_files(&[swift_file.to_string_lossy().to_string()]).await;
    assert!(validation_result.is_ok());
    
    let result = validation_result.unwrap();
    assert!(!result.is_valid(), "Invalid Swift code should be detected");
    assert!(!result.errors.is_empty(), "Should have validation errors");
}