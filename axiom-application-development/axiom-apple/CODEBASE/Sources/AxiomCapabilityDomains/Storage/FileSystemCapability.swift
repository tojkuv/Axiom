import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - File System Capability Configuration

/// Configuration for File System capability
public struct FileSystemCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let baseDirectory: FileSystemDirectory
    public let enableSecureAccess: Bool
    public let maxFileSize: UInt64
    public let allowedExtensions: Set<String>
    public let enableBackup: Bool
    public let enableEncryption: Bool
    public let maxConcurrentOperations: Int
    
    public enum FileSystemDirectory: String, Codable, CaseIterable {
        case documents = "Documents"
        case caches = "Caches"
        case temporary = "tmp"
        case applicationSupport = "Application Support"
        case downloads = "Downloads"
        case custom = "Custom"
        
        public var searchPathDirectory: FileManager.SearchPathDirectory {
            switch self {
            case .documents:
                return .documentDirectory
            case .caches:
                return .cachesDirectory
            case .temporary:
                return .itemReplacementDirectory
            case .applicationSupport:
                return .applicationSupportDirectory
            case .downloads:
                return .downloadsDirectory
            case .custom:
                return .documentDirectory
            }
        }
    }
    
    public init(
        baseDirectory: FileSystemDirectory = .documents,
        enableSecureAccess: Bool = true,
        maxFileSize: UInt64 = 100 * 1024 * 1024, // 100MB
        allowedExtensions: Set<String> = ["txt", "json", "plist", "xml", "csv"],
        enableBackup: Bool = true,
        enableEncryption: Bool = false,
        maxConcurrentOperations: Int = 10
    ) {
        self.baseDirectory = baseDirectory
        self.enableSecureAccess = enableSecureAccess
        self.maxFileSize = maxFileSize
        self.allowedExtensions = allowedExtensions
        self.enableBackup = enableBackup
        self.enableEncryption = enableEncryption
        self.maxConcurrentOperations = maxConcurrentOperations
    }
    
    public var isValid: Bool {
        maxFileSize > 0 && maxConcurrentOperations > 0
    }
    
    public func merged(with other: FileSystemCapabilityConfiguration) -> FileSystemCapabilityConfiguration {
        FileSystemCapabilityConfiguration(
            baseDirectory: other.baseDirectory,
            enableSecureAccess: other.enableSecureAccess,
            maxFileSize: other.maxFileSize,
            allowedExtensions: other.allowedExtensions,
            enableBackup: other.enableBackup,
            enableEncryption: other.enableEncryption,
            maxConcurrentOperations: other.maxConcurrentOperations
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> FileSystemCapabilityConfiguration {
        var adjustedOperations = maxConcurrentOperations
        var adjustedEncryption = enableEncryption
        var adjustedFileSize = maxFileSize
        
        if environment.isLowPowerMode {
            adjustedOperations = max(1, maxConcurrentOperations / 2)
            adjustedFileSize = min(maxFileSize, 50 * 1024 * 1024) // 50MB limit
        }
        
        if environment.isDebug {
            adjustedEncryption = false // Disable encryption in debug for easier inspection
        }
        
        return FileSystemCapabilityConfiguration(
            baseDirectory: baseDirectory,
            enableSecureAccess: enableSecureAccess,
            maxFileSize: adjustedFileSize,
            allowedExtensions: allowedExtensions,
            enableBackup: enableBackup,
            enableEncryption: adjustedEncryption,
            maxConcurrentOperations: adjustedOperations
        )
    }
}

// MARK: - File System Operations

/// File system operation types
public enum FileSystemOperation: Sendable {
    case read(String)
    case write(String, Data)
    case delete(String)
    case move(String, String)
    case copy(String, String)
    case createDirectory(String)
    case list(String)
}

/// File metadata
public struct FileMetadata: Sendable, Codable {
    public let path: String
    public let size: UInt64
    public let creationDate: Date
    public let modificationDate: Date
    public let isDirectory: Bool
    public let permissions: String
    public let isHidden: Bool
    
    public init(
        path: String,
        size: UInt64,
        creationDate: Date,
        modificationDate: Date,
        isDirectory: Bool,
        permissions: String,
        isHidden: Bool
    ) {
        self.path = path
        self.size = size
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.isDirectory = isDirectory
        self.permissions = permissions
        self.isHidden = isHidden
    }
}

// MARK: - File System Resource

/// File system resource management
public actor FileSystemCapabilityResource: AxiomCapabilityResource {
    private let configuration: FileSystemCapabilityConfiguration
    private var baseURL: URL?
    private let fileManager = FileManager.default
    private let operationQueue = OperationQueue()
    
    public init(configuration: FileSystemCapabilityConfiguration) {
        self.configuration = configuration
        self.operationQueue.maxConcurrentOperationCount = configuration.maxConcurrentOperations
    }
    
    public func allocate() async throws {
        // Get base directory URL
        let searchPath = configuration.baseDirectory.searchPathDirectory
        let urls = fileManager.urls(for: searchPath, in: .userDomainMask)
        
        guard let baseURL = urls.first else {
            throw AxiomCapabilityError.initializationFailed("Failed to get base directory URL")
        }
        
        self.baseURL = baseURL
        
        // Create base directory if it doesn't exist
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        
        // Set backup attributes if needed
        if !configuration.enableBackup {
            try setBackupAttribute(for: baseURL, shouldBackup: false)
        }
    }
    
    public func deallocate() async {
        operationQueue.cancelAllOperations()
        baseURL = nil
    }
    
    public var isAllocated: Bool {
        baseURL != nil
    }
    
    public func updateConfiguration(_ configuration: FileSystemCapabilityConfiguration) async throws {
        // File system configuration changes require reallocation
        if isAllocated {
            await deallocate()
            try await allocate()
        }
    }
    
    // MARK: - File System Access
    
    public func getBaseURL() -> URL? {
        baseURL
    }
    
    public func resolveURL(for path: String) throws -> URL {
        guard let baseURL = baseURL else {
            throw AxiomCapabilityError.resourceAllocationFailed("Base URL not available")
        }
        
        // Ensure path is relative and secure
        let cleanPath = sanitizePath(path)
        let url = baseURL.appendingPathComponent(cleanPath)
        
        // Ensure resolved URL is within base directory
        guard url.path.hasPrefix(baseURL.path) else {
            throw AxiomCapabilityError.operationFailed("Path \(path) is outside allowed directory")
        }
        
        return url
    }
    
    private func sanitizePath(_ path: String) -> String {
        // Remove dangerous path components
        let components = path.components(separatedBy: "/")
        let sanitized = components.compactMap { component in
            // Remove empty, current directory, and parent directory references
            if component.isEmpty || component == "." || component == ".." {
                return nil
            }
            return component
        }
        return sanitized.joined(separator: "/")
    }
    
    private func setBackupAttribute(for url: URL, shouldBackup: Bool) throws {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = !shouldBackup
        try url.setResourceValues(resourceValues)
    }
    
    public func validateFileExtension(_ path: String) -> Bool {
        guard !configuration.allowedExtensions.isEmpty else { return true }
        
        let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        return configuration.allowedExtensions.contains(pathExtension)
    }
    
    public func validateFileSize(_ size: UInt64) -> Bool {
        size <= configuration.maxFileSize
    }
}

// MARK: - File System Capability Implementation

/// File system capability providing secure file operations
public actor FileSystemCapability: DomainCapability {
    public typealias ConfigurationType = FileSystemCapabilityConfiguration
    public typealias ResourceType = FileSystemCapabilityResource
    
    private var _configuration: FileSystemCapabilityConfiguration
    private var _resources: FileSystemCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "filesystem-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: FileSystemCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: FileSystemCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: FileSystemCapabilityConfiguration = FileSystemCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = FileSystemCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.deallocate()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: FileSystemCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid file system configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // File system is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // File system access within app sandbox doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - File Operations
    
    /// Read file content
    public func readFile(at path: String) async throws -> Data {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        
        guard await _resources.validateFileExtension(path) else {
            throw AxiomCapabilityError.operationFailed("File extension not allowed: \(path)")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: url)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to read file: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Write file content
    public func writeFile(at path: String, data: Data) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        
        guard await _resources.validateFileExtension(path) else {
            throw AxiomCapabilityError.operationFailed("File extension not allowed: \(path)")
        }
        
        guard await _resources.validateFileSize(UInt64(data.count)) else {
            throw AxiomCapabilityError.operationFailed("File size exceeds limit: \(data.count) bytes")
        }
        
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create directory if needed
                    let directory = url.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                    
                    // Write data
                    try data.write(to: url)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to write file: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Delete file or directory
    public func deleteItem(at path: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try FileManager.default.removeItem(at: url)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to delete item: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Move file or directory
    public func moveItem(from sourcePath: String, to destinationPath: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let sourceURL = try await _resources.resolveURL(for: sourcePath)
        let destinationURL = try await _resources.resolveURL(for: destinationPath)
        
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create destination directory if needed
                    let destinationDirectory = destinationURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
                    
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to move item: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Copy file or directory
    public func copyItem(from sourcePath: String, to destinationPath: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let sourceURL = try await _resources.resolveURL(for: sourcePath)
        let destinationURL = try await _resources.resolveURL(for: destinationPath)
        
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create destination directory if needed
                    let destinationDirectory = destinationURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
                    
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to copy item: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Create directory
    public func createDirectory(at path: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to create directory: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// List directory contents
    public func listDirectory(at path: String) async throws -> [FileMetadata] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [
                        .fileSizeKey,
                        .creationDateKey,
                        .contentModificationDateKey,
                        .isDirectoryKey,
                        .posixPermissionsKey,
                        .isHiddenKey
                    ], options: [])
                    
                    let metadata = contents.compactMap { itemURL -> FileMetadata? in
                        do {
                            let resourceValues = try itemURL.resourceValues(forKeys: [
                                .fileSizeKey,
                                .creationDateKey,
                                .contentModificationDateKey,
                                .isDirectoryKey,
                                .posixPermissionsKey,
                                .isHiddenKey
                            ])
                            
                            return FileMetadata(
                                path: itemURL.lastPathComponent,
                                size: UInt64(resourceValues.fileSize ?? 0),
                                creationDate: resourceValues.creationDate ?? Date(),
                                modificationDate: resourceValues.contentModificationDate ?? Date(),
                                isDirectory: resourceValues.isDirectory ?? false,
                                permissions: String(format: "%o", resourceValues.posixPermissions ?? 0),
                                isHidden: resourceValues.isHidden ?? false
                            )
                        } catch {
                            return nil
                        }
                    }
                    
                    continuation.resume(returning: metadata)
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to list directory: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Check if file or directory exists
    public func itemExists(at path: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Get file metadata
    public func getMetadata(for path: String) async throws -> FileMetadata {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("File system capability not available")
        }
        
        let url = try await _resources.resolveURL(for: path)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [
                        .fileSizeKey,
                        .creationDateKey,
                        .contentModificationDateKey,
                        .isDirectoryKey,
                        .posixPermissionsKey,
                        .isHiddenKey
                    ])
                    
                    let metadata = FileMetadata(
                        path: path,
                        size: UInt64(resourceValues.fileSize ?? 0),
                        creationDate: resourceValues.creationDate ?? Date(),
                        modificationDate: resourceValues.contentModificationDate ?? Date(),
                        isDirectory: resourceValues.isDirectory ?? false,
                        permissions: String(format: "%o", resourceValues.posixPermissions ?? 0),
                        isHidden: resourceValues.isHidden ?? false
                    )
                    
                    continuation.resume(returning: metadata)
                } catch {
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Failed to get metadata: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// File system specific errors
    public static func fileSystemError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("File System: \(message)")
    }
    
    public static func fileNotFound(_ path: String) -> AxiomCapabilityError {
        .operationFailed("File not found: \(path)")
    }
    
    public static func fileAccessDenied(_ path: String) -> AxiomCapabilityError {
        .permissionDenied("File access denied: \(path)")
    }
    
    public static func fileSizeExceeded(_ size: UInt64, limit: UInt64) -> AxiomCapabilityError {
        .operationFailed("File size \(size) exceeds limit \(limit)")
    }
}