//! Standalone test for SwiftFileManager functionality
//! This test verifies that the SwiftFileManager implementation works correctly

use axiom_universal_client_generator::utils::file_manager::*;
use std::path::PathBuf;
use tempfile::TempDir;

#[tokio::test]
async fn test_swift_file_manager_standalone() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    
    // Test basic functionality
    assert_eq!(file_manager.base_path(), base_path);
    assert!(file_manager.sources_dir().ends_with("Sources"));
    assert!(file_manager.tests_dir().ends_with("Tests"));
    
    println!("✅ SwiftFileManager creation test passed");
}

#[tokio::test]
async fn test_directory_structure_standalone() {
    let temp_dir = TempDir::new().unwrap();
    let base_path = temp_dir.path();
    
    let file_manager = SwiftFileManager::new(base_path);
    let result = file_manager.create_directory_structure().await;
    
    assert!(result.is_ok());
    assert!(base_path.join("Sources").exists());
    assert!(base_path.join("Tests").exists());
    
    println!("✅ Directory structure creation test passed");
}

#[tokio::test]
async fn test_file_writing_standalone() {
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
    
    println!("✅ File writing test passed");
}

#[tokio::test]
async fn test_atomic_operations_standalone() {
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
    
    println!("✅ Atomic operations test passed");
}

#[tokio::test]
async fn test_backup_and_restore_standalone() {
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
    
    println!("✅ Backup and restore test passed");
}

#[tokio::test]
async fn test_conflict_resolution_standalone() {
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
    
    println!("✅ Conflict resolution test passed");
}

#[tokio::test]
async fn test_metadata_tracking_standalone() {
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
    
    println!("✅ Metadata tracking test passed");
}

#[tokio::test]
async fn test_package_swift_generation_standalone() {
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
    
    println!("✅ Package.swift generation test passed");
}

// Individual test functions that can be run with `cargo test`
// Each test will be executed independently by the Rust test runner