//! Unit tests for file management functionality

use axiom_universal_client_generator::utils::file_manager::*;
use std::path::PathBuf;
use tempfile::TempDir;

#[tokio::test]
async fn test_swift_file_manager_creation() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    
    assert_eq!(file_manager.base_path(), base_path);
    assert!(file_manager.sources_dir().ends_with("Sources"));
    assert!(file_manager.tests_dir().ends_with("Tests"));
}

#[tokio::test]
async fn test_directory_structure_creation() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    let result = file_manager.create_directory_structure().await;
    
    assert!(result.is_ok());
    
    // Verify directory structure
    assert!(base_path.join("Sources").exists());
    assert!(base_path.join("Tests").exists());
    assert!(base_path.join("Sources").is_dir());
    assert!(base_path.join("Tests").is_dir());
}

#[tokio::test]
async fn test_service_organized_structure() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    let result = file_manager.create_service_structure("TaskService").await;
    
    assert!(result.is_ok());
    
    // Verify service-specific directories
    assert!(base_path.join("Sources/TaskService").exists());
    assert!(base_path.join("Tests/TaskServiceTests").exists());
}

#[tokio::test]
async fn test_file_writing() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let swift_code = r#"
import Foundation

public struct TestStruct {
    public let value: String
}
"#;
    
    let result = file_manager.write_swift_file("TestStruct.swift", swift_code).await;
    assert!(result.is_ok());
    
    let file_path = base_path.join("Sources/TestStruct.swift");
    assert!(file_path.exists());
    
    let content = std::fs::read_to_string(&file_path).unwrap();
    assert!(content.contains("public struct TestStruct"));
}

#[tokio::test]
async fn test_test_file_writing() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let test_code = r#"
import XCTest
@testable import TestModule

class TestStructTests: XCTestCase {
    func testExample() {
        XCTAssertTrue(true)
    }
}
"#;
    
    let result = file_manager.write_test_file("TestStructTests.swift", test_code).await;
    assert!(result.is_ok());
    
    let file_path = base_path.join("Tests/TestStructTests.swift");
    assert!(file_path.exists());
    
    let content = std::fs::read_to_string(&file_path).unwrap();
    assert!(content.contains("class TestStructTests"));
}

#[tokio::test]
async fn test_package_swift_generation() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    
    let package_config = PackageSwiftConfig {
        name: "TestPackage".to_string(),
        dependencies: vec!["AxiomCore".to_string(), "AxiomArchitecture".to_string()],
        swift_version: "5.9".to_string(),
        platforms: vec!["iOS 15.0".to_string(), "macOS 12.0".to_string()],
    };
    
    let result = file_manager.create_package_swift(&package_config).await;
    assert!(result.is_ok());
    
    let package_file = base_path.join("Package.swift");
    assert!(package_file.exists());
    
    let content = std::fs::read_to_string(&package_file).unwrap();
    assert!(content.contains("name: \"TestPackage\""));
    assert!(content.contains("AxiomCore"));
    assert!(content.contains("AxiomArchitecture"));
    assert!(content.contains("swift-tools-version: 5.9"));
}

#[tokio::test]
async fn test_atomic_file_operations() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let file_path = base_path.join("Sources/AtomicTest.swift");
    
    // Test atomic write
    let content1 = "// Version 1";
    let result = file_manager.write_file_atomic(&file_path, content1).await;
    assert!(result.is_ok());
    assert!(file_path.exists());
    
    let read_content = std::fs::read_to_string(&file_path).unwrap();
    assert_eq!(read_content.trim(), "// Version 1");
    
    // Test atomic update
    let content2 = "// Version 2";
    let result = file_manager.write_file_atomic(&file_path, content2).await;
    assert!(result.is_ok());
    
    let read_content = std::fs::read_to_string(&file_path).unwrap();
    assert_eq!(read_content.trim(), "// Version 2");
}

#[tokio::test]
async fn test_file_backup_and_restore() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let file_path = base_path.join("Sources/BackupTest.swift");
    let original_content = "// Original content";
    
    // Create original file
    std::fs::write(&file_path, original_content).unwrap();
    
    // Create backup
    let backup_result = file_manager.create_backup(&file_path).await;
    assert!(backup_result.is_ok());
    let backup_path = backup_result.unwrap();
    assert!(backup_path.exists());
    
    // Modify original file
    std::fs::write(&file_path, "// Modified content").unwrap();
    
    // Restore from backup
    let restore_result = file_manager.restore_from_backup(&file_path, &backup_path).await;
    assert!(restore_result.is_ok());
    
    let restored_content = std::fs::read_to_string(&file_path).unwrap();
    assert_eq!(restored_content.trim(), "// Original content");
}

#[tokio::test]
async fn test_file_conflict_resolution() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let file_path = base_path.join("Sources/ConflictTest.swift");
    
    // Create existing file
    std::fs::write(&file_path, "// Existing content").unwrap();
    
    // Test different conflict resolution strategies
    let new_content = "// New content";
    
    // Strategy: Skip
    let result = file_manager.write_with_conflict_resolution(
        &file_path,
        new_content,
        ConflictResolution::Skip
    ).await;
    assert!(result.is_ok());
    
    let content = std::fs::read_to_string(&file_path).unwrap();
    assert!(content.contains("Existing content")); // Should remain unchanged
    
    // Strategy: Overwrite
    let result = file_manager.write_with_conflict_resolution(
        &file_path,
        new_content,
        ConflictResolution::Overwrite
    ).await;
    assert!(result.is_ok());
    
    let content = std::fs::read_to_string(&file_path).unwrap();
    assert!(content.contains("New content")); // Should be overwritten
}

#[tokio::test]
async fn test_file_validation_before_write() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    // Valid Swift code
    let valid_code = r#"
import Foundation

public struct ValidStruct {
    public let value: String
}
"#;
    
    let result = file_manager.write_swift_file_with_validation("ValidStruct.swift", valid_code).await;
    assert!(result.is_ok());
    
    // Invalid Swift code (syntax error)
    let invalid_code = r#"
import Foundation

public struct InvalidStruct {
    public let value: String
    // Missing closing brace
"#;
    
    let result = file_manager.write_swift_file_with_validation("InvalidStruct.swift", invalid_code).await;
    assert!(result.is_err());
    
    // File should not be created
    let file_path = base_path.join("Sources/InvalidStruct.swift");
    assert!(!file_path.exists());
}

#[tokio::test]
async fn test_bulk_file_operations() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let files = vec![
        ("File1.swift", "// File 1 content"),
        ("File2.swift", "// File 2 content"),
        ("File3.swift", "// File 3 content"),
    ];
    
    let result = file_manager.write_bulk_files(files).await;
    assert!(result.is_ok());
    
    // Verify all files were created
    for i in 1..=3 {
        let file_path = base_path.join(format!("Sources/File{}.swift", i));
        assert!(file_path.exists());
        
        let content = std::fs::read_to_string(&file_path).unwrap();
        assert!(content.contains(&format!("File {} content", i)));
    }
}

#[tokio::test]
async fn test_file_metadata_tracking() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let file_content = "// Test content";
    let result = file_manager.write_swift_file("MetadataTest.swift", file_content).await;
    assert!(result.is_ok());
    
    let metadata = file_manager.get_file_metadata("MetadataTest.swift").await;
    assert!(metadata.is_ok());
    
    let file_metadata = metadata.unwrap();
    assert_eq!(file_metadata.file_name, "MetadataTest.swift");
    assert_eq!(file_metadata.file_type, FileType::Swift);
    assert!(file_metadata.size > 0);
    assert!(file_metadata.created_at > 0);
}

#[tokio::test]
async fn test_directory_cleanup() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    // Create some test files
    file_manager.write_swift_file("Test1.swift", "// Test 1").await.unwrap();
    file_manager.write_swift_file("Test2.swift", "// Test 2").await.unwrap();
    file_manager.write_test_file("Test1Tests.swift", "// Test 1 Tests").await.unwrap();
    
    // Verify files exist
    assert!(base_path.join("Sources/Test1.swift").exists());
    assert!(base_path.join("Sources/Test2.swift").exists());
    assert!(base_path.join("Tests/Test1Tests.swift").exists());
    
    // Clean up
    let result = file_manager.cleanup_generated_files().await;
    assert!(result.is_ok());
    
    // Verify files are removed but directories remain
    assert!(!base_path.join("Sources/Test1.swift").exists());
    assert!(!base_path.join("Sources/Test2.swift").exists());
    assert!(!base_path.join("Tests/Test1Tests.swift").exists());
    assert!(base_path.join("Sources").exists());
    assert!(base_path.join("Tests").exists());
}

#[tokio::test]
async fn test_file_permissions() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    let result = file_manager.write_swift_file("PermissionTest.swift", "// Test").await;
    assert!(result.is_ok());
    
    let file_path = base_path.join("Sources/PermissionTest.swift");
    let metadata = std::fs::metadata(&file_path).unwrap();
    
    // Check that file is readable and writable
    assert!(!metadata.permissions().readonly());
}

#[tokio::test]
async fn test_concurrent_file_operations() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    // Spawn multiple concurrent write operations
    let mut handles = vec![];
    
    for i in 0..10 {
        let fm = file_manager.clone();
        let handle = tokio::spawn(async move {
            let file_name = format!("Concurrent{}.swift", i);
            let content = format!("// Concurrent file {}", i);
            fm.write_swift_file(&file_name, &content).await
        });
        handles.push(handle);
    }
    
    // Wait for all operations to complete
    for handle in handles {
        let result = handle.await.unwrap();
        assert!(result.is_ok());
    }
    
    // Verify all files were created
    for i in 0..10 {
        let file_path = base_path.join(format!("Sources/Concurrent{}.swift", i));
        assert!(file_path.exists());
    }
}

#[tokio::test]
async fn test_file_watcher_integration() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    file_manager.create_directory_structure().await.unwrap();
    
    // Set up file watcher
    let watcher_result = file_manager.setup_file_watcher().await;
    assert!(watcher_result.is_ok());
    
    // Create a file and verify it's detected
    file_manager.write_swift_file("WatchedFile.swift", "// Watched").await.unwrap();
    
    // Allow some time for the watcher to detect the change
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    
    let changes = file_manager.get_file_changes().await;
    assert!(changes.is_ok());
    
    let file_changes = changes.unwrap();
    assert!(!file_changes.is_empty());
}