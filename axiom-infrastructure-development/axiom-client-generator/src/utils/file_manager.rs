use crate::error::{Error, Result};
use crate::validation::swift::SwiftValidator;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::fs;
use tokio::io::AsyncWriteExt;
use tokio::sync::Mutex;
use uuid::Uuid;

/// Multi-language file management utilities
pub struct FileManager;

impl FileManager {
    /// Write content to a file with atomic operations
    pub async fn write_file(
        file_path: &Path,
        content: &str,
        force_overwrite: bool,
    ) -> Result<()> {
        // Check if file exists and handle overwrite logic
        if file_path.exists() && !force_overwrite {
            return Err(Error::IoError(std::io::Error::new(
                std::io::ErrorKind::AlreadyExists,
                format!("File already exists: {}", file_path.display()),
            )));
        }

        // Create parent directories if they don't exist
        if let Some(parent) = file_path.parent() {
            fs::create_dir_all(parent).await?;
        }

        // Write to temporary file first for atomic operation
        let temp_path = file_path.with_extension(format!(
            "{}.tmp",
            file_path.extension().and_then(|s| s.to_str()).unwrap_or("tmp")
        ));

        // Write content to temporary file
        let mut temp_file = fs::File::create(&temp_path).await?;
        temp_file.write_all(content.as_bytes()).await?;
        temp_file.flush().await?;
        drop(temp_file);

        // Atomically rename temporary file to final destination
        fs::rename(&temp_path, file_path).await?;

        tracing::debug!("Successfully wrote file: {}", file_path.display());
        Ok(())
    }

    /// Read file content
    pub async fn read_file(file_path: &Path) -> Result<String> {
        let content = fs::read_to_string(file_path).await?;
        Ok(content)
    }

    /// Check if file exists and is readable
    pub async fn file_exists(file_path: &Path) -> bool {
        file_path.exists() && file_path.is_file()
    }

    /// Create directory structure for multi-language output
    pub async fn create_language_directories(
        base_output_path: &Path,
        languages: &[String],
    ) -> Result<Vec<PathBuf>> {
        let mut created_dirs = Vec::new();

        for language in languages {
            let language_dir = base_output_path.join(language);
            let contracts_dir = language_dir.join("Contracts");
            let clients_dir = language_dir.join("Clients");

            // Create language-specific directory structure
            fs::create_dir_all(&contracts_dir).await?;
            fs::create_dir_all(&clients_dir).await?;

            tracing::debug!("Created directories for {}: {}", language, language_dir.display());
            
            created_dirs.push(language_dir);
            created_dirs.push(contracts_dir);
            created_dirs.push(clients_dir);
        }

        Ok(created_dirs)
    }

    /// Clean output directory before generation
    pub async fn clean_output_directory(
        output_path: &Path,
        languages: &[String],
        force: bool,
    ) -> Result<()> {
        if !force {
            return Ok(());
        }

        for language in languages {
            let language_dir = output_path.join(language);
            if language_dir.exists() {
                fs::remove_dir_all(&language_dir).await?;
                tracing::debug!("Cleaned directory: {}", language_dir.display());
            }
        }

        Ok(())
    }

    /// Validate output path is writable
    pub async fn validate_output_path(output_path: &Path) -> Result<()> {
        // Check if path exists or can be created
        if !output_path.exists() {
            fs::create_dir_all(output_path).await?;
        }

        // Test write permissions by creating a temporary file
        let test_file = output_path.join(".write_test");
        fs::write(&test_file, "test").await?;
        fs::remove_file(&test_file).await?;

        Ok(())
    }

    /// Get relative path from base to target
    pub fn get_relative_path(base: &Path, target: &Path) -> Result<PathBuf> {
        target.strip_prefix(base)
            .map(|p| p.to_path_buf())
            .map_err(|e| Error::InvalidPath(format!(
                "Cannot create relative path from {} to {}: {}",
                base.display(),
                target.display(),
                e
            )))
    }

    /// Copy file with backup
    pub async fn copy_with_backup(
        source: &Path,
        destination: &Path,
        create_backup: bool,
    ) -> Result<()> {
        if destination.exists() && create_backup {
            let backup_path = destination.with_extension(format!(
                "{}.backup",
                destination.extension().and_then(|s| s.to_str()).unwrap_or("bak")
            ));
            fs::copy(destination, backup_path).await?;
        }

        fs::copy(source, destination).await?;
        Ok(())
    }

    /// Move file with conflict resolution
    pub async fn move_with_conflict_resolution(
        source: &Path,
        destination: &Path,
        resolution: ConflictResolution,
    ) -> Result<()> {
        if destination.exists() {
            match resolution {
                ConflictResolution::Overwrite => {
                    // Remove existing file
                    fs::remove_file(destination).await?;
                }
                ConflictResolution::Skip => {
                    // Don't move, just return
                    return Ok(());
                }
                ConflictResolution::Rename => {
                    // Find unique name
                    let new_destination = Self::find_unique_name(destination).await?;
                    fs::rename(source, new_destination).await?;
                    return Ok(());
                }
                ConflictResolution::Backup => {
                    // Create backup first
                    let backup_path = destination.with_extension(format!(
                        "{}.backup",
                        destination.extension().and_then(|s| s.to_str()).unwrap_or("bak")
                    ));
                    fs::copy(destination, backup_path).await?;
                    fs::remove_file(destination).await?;
                }
                ConflictResolution::Merge => {
                    // Future feature: intelligent content merging
                    return Err(Error::ValidationError("Merge strategy not yet implemented for move operations".to_string()));
                }
                ConflictResolution::Error => {
                    return Err(Error::IoError(std::io::Error::new(
                        std::io::ErrorKind::AlreadyExists,
                        format!("Destination file already exists: {}", destination.display()),
                    )));
                }
            }
        }

        fs::rename(source, destination).await?;
        Ok(())
    }

    /// Find a unique filename by appending numbers
    async fn find_unique_name(base_path: &Path) -> Result<PathBuf> {
        let base_stem = base_path.file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("file");
        let extension = base_path.extension()
            .and_then(|s| s.to_str())
            .unwrap_or("");
        let parent = base_path.parent()
            .unwrap_or(Path::new("."));

        for i in 1..=999 {
            let new_name = if extension.is_empty() {
                format!("{}-{}", base_stem, i)
            } else {
                format!("{}-{}.{}", base_stem, i, extension)
            };
            let new_path = parent.join(new_name);
            
            if !new_path.exists() {
                return Ok(new_path);
            }
        }

        Err(Error::IoError(std::io::Error::new(
            std::io::ErrorKind::AlreadyExists,
            "Could not find unique filename after 999 attempts",
        )))
    }

    /// Get file size in bytes
    pub async fn file_size(file_path: &Path) -> Result<u64> {
        let metadata = fs::metadata(file_path).await?;
        Ok(metadata.len())
    }

    /// Get file modification time
    pub async fn file_modified_time(file_path: &Path) -> Result<std::time::SystemTime> {
        let metadata = fs::metadata(file_path).await?;
        metadata.modified().map_err(|e| Error::IoError(e))
    }

    /// Check if file has been modified since a given time
    pub async fn is_file_newer_than(
        file_path: &Path,
        reference_time: std::time::SystemTime,
    ) -> Result<bool> {
        let modified_time = Self::file_modified_time(file_path).await?;
        Ok(modified_time > reference_time)
    }

    /// List files in directory with pattern matching
    pub async fn list_files_with_pattern(
        directory: &Path,
        pattern: &str,
    ) -> Result<Vec<PathBuf>> {
        let mut files = Vec::new();
        let glob_pattern = glob::Pattern::new(pattern)
            .map_err(|e| Error::InvalidPath(format!("Invalid glob pattern: {}", e)))?;

        let mut entries = fs::read_dir(directory).await?;
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.is_file() {
                if let Some(file_name) = path.file_name().and_then(|n| n.to_str()) {
                    if glob_pattern.matches(file_name) {
                        files.push(path);
                    }
                }
            }
        }

        files.sort();
        Ok(files)
    }

    /// Create file with template substitution
    pub async fn create_from_template(
        template_content: &str,
        substitutions: &std::collections::HashMap<String, String>,
        output_path: &Path,
        force_overwrite: bool,
    ) -> Result<()> {
        let mut content = template_content.to_string();
        
        // Simple template substitution
        for (key, value) in substitutions {
            let placeholder = format!("{{{}}}", key);
            content = content.replace(&placeholder, value);
        }

        Self::write_file(output_path, &content, force_overwrite).await
    }
}

/// Conflict resolution strategies for file operations
#[derive(Debug, Clone, Copy)]
pub enum ConflictResolution {
    /// Overwrite existing file
    Overwrite,
    /// Skip the operation, leave existing file
    Skip,
    /// Rename the new file to avoid conflict
    Rename,
    /// Return an error
    Error,
    /// Create backup before overwriting
    Backup,
    /// Attempt to merge content (future feature)
    Merge,
}

/// File operation statistics
#[derive(Debug, Clone)]
pub struct FileOperationStats {
    /// Number of files created
    pub files_created: usize,
    /// Number of files overwritten
    pub files_overwritten: usize,
    /// Number of files skipped
    pub files_skipped: usize,
    /// Total bytes written
    pub bytes_written: u64,
    /// Time taken for all operations
    pub operation_time: std::time::Duration,
}

impl FileOperationStats {
    pub fn new() -> Self {
        Self {
            files_created: 0,
            files_overwritten: 0,
            files_skipped: 0,
            bytes_written: 0,
            operation_time: std::time::Duration::default(),
        }
    }
}

/// Enterprise-grade Swift file manager with atomic operations and backup/rollback
#[derive(Clone)]
pub struct SwiftFileManager {
    /// Base directory for all operations
    base_path: PathBuf,
    /// Swift code validator
    validator: Arc<SwiftValidator>,
    /// File change tracker for watching
    file_changes: Arc<Mutex<Vec<FileChange>>>,
    /// Active file locks for concurrent safety
    file_locks: Arc<Mutex<HashMap<PathBuf, ()>>>,
}

/// File operation result with detailed information
#[derive(Debug, Clone)]
pub struct FileOperationResult {
    /// Path of the file that was operated on
    pub file_path: PathBuf,
    /// Whether the operation succeeded
    pub success: bool,
    /// Operation type performed
    pub operation: FileOperation,
    /// Size of the file in bytes
    pub file_size: u64,
    /// Any warnings generated during operation
    pub warnings: Vec<String>,
    /// Backup path if a backup was created
    pub backup_path: Option<PathBuf>,
}

/// Types of file operations
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FileOperation {
    Create,
    Update,
    Delete,
    Backup,
    Restore,
}

/// Configuration for Package.swift generation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PackageSwiftConfig {
    /// Package name
    pub name: String,
    /// Swift package dependencies
    pub dependencies: Vec<String>,
    /// Swift tools version
    pub swift_version: String,
    /// Supported platforms
    pub platforms: Vec<String>,
}

/// File type classification
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FileType {
    Swift,
    Test,
    Package,
    Documentation,
    Configuration,
    Other,
}

/// File metadata information
#[derive(Debug, Clone)]
pub struct FileMetadata {
    /// File name
    pub file_name: String,
    /// File type classification
    pub file_type: FileType,
    /// File size in bytes
    pub size: u64,
    /// Creation timestamp (Unix timestamp)
    pub created_at: u64,
    /// Last modified timestamp (Unix timestamp)
    pub modified_at: u64,
    /// File checksum for integrity verification
    pub checksum: String,
}

/// File change event for file watching
#[derive(Debug, Clone)]
pub struct FileChange {
    /// Path of the changed file
    pub file_path: PathBuf,
    /// Type of change
    pub change_type: ChangeType,
    /// Timestamp of change
    pub timestamp: u64,
}

/// Types of file changes
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ChangeType {
    Created,
    Modified,
    Deleted,
}

impl SwiftFileManager {
    /// Create a new Swift file manager
    pub fn new(base_path: &Path) -> Self {
        Self {
            base_path: base_path.to_path_buf(),
            validator: Arc::new(SwiftValidator::new()),
            file_changes: Arc::new(Mutex::new(Vec::new())),
            file_locks: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    /// Get the base path
    pub fn base_path(&self) -> &Path {
        &self.base_path
    }

    /// Get the Sources directory path
    pub fn sources_dir(&self) -> PathBuf {
        self.base_path.join("Sources")
    }

    /// Get the Tests directory path
    pub fn tests_dir(&self) -> PathBuf {
        self.base_path.join("Tests")
    }

    /// Create the standard Swift package directory structure
    pub async fn create_directory_structure(&self) -> Result<()> {
        fs::create_dir_all(&self.sources_dir()).await?;
        fs::create_dir_all(&self.tests_dir()).await?;
        Ok(())
    }

    /// Create service-specific directory structure
    pub async fn create_service_structure(&self, service_name: &str) -> Result<()> {
        let sources_service_dir = self.sources_dir().join(service_name);
        let tests_service_dir = self.tests_dir().join(format!("{}Tests", service_name));
        
        fs::create_dir_all(&sources_service_dir).await?;
        fs::create_dir_all(&tests_service_dir).await?;
        
        Ok(())
    }

    /// Write a Swift source file
    pub async fn write_swift_file(&self, file_name: &str, content: &str) -> Result<FileOperationResult> {
        let file_path = self.sources_dir().join(file_name);
        self.write_file_internal(&file_path, content, FileType::Swift).await
    }

    /// Write a Swift test file
    pub async fn write_test_file(&self, file_name: &str, content: &str) -> Result<FileOperationResult> {
        let file_path = self.tests_dir().join(file_name);
        self.write_file_internal(&file_path, content, FileType::Test).await
    }

    /// Write a Swift file with validation
    pub async fn write_swift_file_with_validation(&self, file_name: &str, content: &str) -> Result<FileOperationResult> {
        // Validate Swift syntax before writing
        let temp_file = tempfile::NamedTempFile::new()?;
        let temp_path = temp_file.path().with_extension("swift");
        fs::write(&temp_path, content).await?;
        
        let validation_result = self.validator.validate_files(&[temp_path.to_string_lossy().to_string()]).await?;
        
        if !validation_result.is_valid() {
            return Err(Error::ValidationError(format!(
                "Swift validation failed: {:?}", 
                validation_result.errors
            )));
        }

        self.write_swift_file(file_name, content).await
    }

    /// Write file atomically (all-or-nothing operation)
    pub async fn write_file_atomic(&self, file_path: &Path, content: &str) -> Result<FileOperationResult> {
        // Create temporary file with unique name
        let temp_path = file_path.with_extension(format!("tmp.{}", Uuid::new_v4().simple()));
        
        // Write to temporary file
        fs::write(&temp_path, content).await.map_err(|e| {
            Error::IoError(e)
        })?;

        // Atomically rename temporary file to target
        fs::rename(&temp_path, file_path).await.map_err(|e| {
            // Clean up temp file if rename fails
            let _ = std::fs::remove_file(&temp_path);
            Error::IoError(e)
        })?;

        let metadata = fs::metadata(file_path).await?;
        let operation = if metadata.len() > 0 { FileOperation::Update } else { FileOperation::Create };

        Ok(FileOperationResult {
            file_path: file_path.to_path_buf(),
            success: true,
            operation,
            file_size: metadata.len(),
            warnings: Vec::new(),
            backup_path: None,
        })
    }

    /// Create a backup of an existing file
    pub async fn create_backup(&self, file_path: &Path) -> Result<PathBuf> {
        if !file_path.exists() {
            return Err(Error::IoError(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "File does not exist for backup"
            )));
        }

        let backup_dir = self.base_path.join(".backups");
        fs::create_dir_all(&backup_dir).await?;

        let timestamp = chrono::Utc::now().format("%Y%m%d_%H%M%S");
        let file_name = file_path.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unknown");
        
        let backup_path = backup_dir.join(format!("{}_{}.backup", file_name, timestamp));
        fs::copy(file_path, &backup_path).await?;

        Ok(backup_path)
    }

    /// Restore a file from backup
    pub async fn restore_from_backup(&self, file_path: &Path, backup_path: &Path) -> Result<()> {
        if !backup_path.exists() {
            return Err(Error::IoError(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "Backup file does not exist"
            )));
        }

        fs::copy(backup_path, file_path).await?;
        Ok(())
    }

    /// Write file with conflict resolution strategy
    pub async fn write_with_conflict_resolution(
        &self,
        file_path: &Path,
        content: &str,
        strategy: ConflictResolution,
    ) -> Result<FileOperationResult> {
        match strategy {
            ConflictResolution::Skip => {
                if file_path.exists() {
                    let metadata = fs::metadata(file_path).await?;
                    return Ok(FileOperationResult {
                        file_path: file_path.to_path_buf(),
                        success: true,
                        operation: FileOperation::Update,
                        file_size: metadata.len(),
                        warnings: vec!["File skipped due to conflict".to_string()],
                        backup_path: None,
                    });
                }
                self.write_file_atomic(file_path, content).await
            }
            ConflictResolution::Overwrite => {
                self.write_file_atomic(file_path, content).await
            }
            ConflictResolution::Backup => {
                let backup_path = if file_path.exists() {
                    Some(self.create_backup(file_path).await?)
                } else {
                    None
                };
                
                let mut result = self.write_file_atomic(file_path, content).await?;
                result.backup_path = backup_path;
                Ok(result)
            }
            ConflictResolution::Merge => {
                // Future feature: intelligent code merging
                return Err(Error::ValidationError("Merge strategy not yet implemented".to_string()));
            }
            _ => {
                // Handle other existing variants
                self.write_file_atomic(file_path, content).await
            }
        }
    }

    /// Write multiple files in a single operation
    pub async fn write_bulk_files(&self, files: Vec<(&str, &str)>) -> Result<Vec<FileOperationResult>> {
        let mut results = Vec::new();
        
        for (file_name, content) in files {
            let result = self.write_swift_file(file_name, content).await?;
            results.push(result);
        }

        Ok(results)
    }

    /// Get file metadata
    pub async fn get_file_metadata(&self, file_name: &str) -> Result<FileMetadata> {
        let file_path = self.sources_dir().join(file_name);
        let metadata = fs::metadata(&file_path).await?;
        
        let file_type = self.classify_file_type(file_name);
        let content = fs::read(&file_path).await?;
        let checksum = self.calculate_checksum(&content);

        Ok(FileMetadata {
            file_name: file_name.to_string(),
            file_type,
            size: metadata.len(),
            created_at: metadata.created()?.duration_since(std::time::UNIX_EPOCH)?.as_secs(),
            modified_at: metadata.modified()?.duration_since(std::time::UNIX_EPOCH)?.as_secs(),
            checksum,
        })
    }

    /// Clean up all generated files
    pub async fn cleanup_generated_files(&self) -> Result<()> {
        // Remove all Swift files but keep directory structure
        let sources_dir = self.sources_dir();
        if sources_dir.exists() {
            let mut entries = fs::read_dir(&sources_dir).await?;
            while let Some(entry) = entries.next_entry().await? {
                if entry.file_type().await?.is_file() {
                    fs::remove_file(entry.path()).await?;
                }
            }
        }

        let tests_dir = self.tests_dir();
        if tests_dir.exists() {
            let mut entries = fs::read_dir(&tests_dir).await?;
            while let Some(entry) = entries.next_entry().await? {
                if entry.file_type().await?.is_file() {
                    fs::remove_file(entry.path()).await?;
                }
            }
        }

        Ok(())
    }

    /// Create Package.swift file
    pub async fn create_package_swift(&self, config: &PackageSwiftConfig) -> Result<()> {
        let package_content = self.generate_package_swift_content(config);
        let package_path = self.base_path.join("Package.swift");
        
        fs::write(&package_path, package_content).await?;
        Ok(())
    }

    /// Set up file watcher (simplified implementation)
    pub async fn setup_file_watcher(&self) -> Result<()> {
        // In a real implementation, this would use a file system watcher
        // For testing purposes, we'll just initialize the tracking
        let mut changes = self.file_changes.lock().await;
        changes.clear();
        Ok(())
    }

    /// Get recorded file changes
    pub async fn get_file_changes(&self) -> Result<Vec<FileChange>> {
        let changes = self.file_changes.lock().await;
        Ok(changes.clone())
    }

    /// Internal file writing implementation
    async fn write_file_internal(&self, file_path: &Path, content: &str, _file_type: FileType) -> Result<FileOperationResult> {
        // Ensure parent directory exists
        if let Some(parent) = file_path.parent() {
            fs::create_dir_all(parent).await?;
        }

        // Record file change
        self.record_file_change(file_path, ChangeType::Created).await;

        // Write file atomically
        self.write_file_atomic(file_path, content).await
    }

    /// Record a file change for watching
    async fn record_file_change(&self, file_path: &Path, change_type: ChangeType) {
        let mut changes = self.file_changes.lock().await;
        changes.push(FileChange {
            file_path: file_path.to_path_buf(),
            change_type,
            timestamp: chrono::Utc::now().timestamp() as u64,
        });
    }

    /// Classify file type based on name and extension
    fn classify_file_type(&self, file_name: &str) -> FileType {
        if file_name.ends_with(".swift") {
            // Only classify as test if it ends with "Tests.swift" (plural)
            if file_name.ends_with("Tests.swift") {
                FileType::Test
            } else {
                FileType::Swift
            }
        } else if file_name == "Package.swift" {
            FileType::Package
        } else if file_name.ends_with(".md") {
            FileType::Documentation
        } else {
            FileType::Other
        }
    }

    /// Calculate SHA-256 checksum for file integrity
    fn calculate_checksum(&self, content: &[u8]) -> String {
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(content);
        format!("{:x}", hasher.finalize())
    }

    /// Generate Package.swift content
    fn generate_package_swift_content(&self, config: &PackageSwiftConfig) -> String {
        let dependencies = if config.dependencies.is_empty() {
            String::new()
        } else {
            let deps: Vec<String> = config.dependencies
                .iter()
                .map(|dep| format!("        .package(name: \"{}\", path: \"../{}\")", dep, dep))
                .collect();
            format!(",\n    dependencies: [\n{}\n    ]", deps.join(",\n"))
        };

        let platforms = if config.platforms.is_empty() {
            String::new()
        } else {
            let plats: Vec<String> = config.platforms
                .iter()
                .map(|plat| {
                    if plat.starts_with("iOS") {
                        format!(".iOS(\"{}\")", plat.replace("iOS ", ""))
                    } else if plat.starts_with("macOS") {
                        format!(".macOS(\"{}\")", plat.replace("macOS ", ""))
                    } else {
                        format!(".platform(\"{}\")", plat)
                    }
                })
                .collect();
            format!("    platforms: [{}],\n", plats.join(", "))
        };

        format!(
            r#"// swift-tools-version: {}

import PackageDescription

let package = Package(
    name: "{}"{}{}
)
"#,
            config.swift_version,
            config.name,
            dependencies,
            if !platforms.is_empty() { format!(",\n{}", platforms.trim_end()) } else { String::new() }
        )
    }
}

/// File manager result type alias
pub type FileManagerResult<T> = std::result::Result<T, Error>;