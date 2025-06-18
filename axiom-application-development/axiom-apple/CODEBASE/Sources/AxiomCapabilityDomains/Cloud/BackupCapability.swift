import Foundation
import CryptoKit
import AxiomCore
import AxiomCapabilities

// MARK: - Backup Capability Configuration

/// Configuration for Backup capability
public struct BackupCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableEncryption: Bool
    public let compressionLevel: Int
    public let maxBackupSize: Int
    public let retentionDays: Int
    public let enableIncrementalBackup: Bool
    public let enableCloudBackup: Bool
    public let cloudProvider: CloudBackupProvider
    public let backupSchedule: BackupSchedule
    public let excludePatterns: [String]
    public let includeUserData: Bool
    public let includePreferences: Bool
    public let includeDocuments: Bool
    public let enableVerification: Bool
    
    public init(
        enableEncryption: Bool = true,
        compressionLevel: Int = 6,
        maxBackupSize: Int = 500 * 1024 * 1024, // 500MB
        retentionDays: Int = 30,
        enableIncrementalBackup: Bool = true,
        enableCloudBackup: Bool = true,
        cloudProvider: CloudBackupProvider = .iCloudDrive,
        backupSchedule: BackupSchedule = .daily,
        excludePatterns: [String] = ["*.tmp", "*.cache", "*.log"],
        includeUserData: Bool = true,
        includePreferences: Bool = true,
        includeDocuments: Bool = true,
        enableVerification: Bool = true
    ) {
        self.enableEncryption = enableEncryption
        self.compressionLevel = compressionLevel
        self.maxBackupSize = maxBackupSize
        self.retentionDays = retentionDays
        self.enableIncrementalBackup = enableIncrementalBackup
        self.enableCloudBackup = enableCloudBackup
        self.cloudProvider = cloudProvider
        self.backupSchedule = backupSchedule
        self.excludePatterns = excludePatterns
        self.includeUserData = includeUserData
        self.includePreferences = includePreferences
        self.includeDocuments = includeDocuments
        self.enableVerification = enableVerification
    }
    
    public var isValid: Bool {
        compressionLevel >= 0 && compressionLevel <= 9 &&
        maxBackupSize > 0 &&
        retentionDays > 0
    }
    
    public func merged(with other: BackupCapabilityConfiguration) -> BackupCapabilityConfiguration {
        BackupCapabilityConfiguration(
            enableEncryption: other.enableEncryption,
            compressionLevel: other.compressionLevel,
            maxBackupSize: other.maxBackupSize,
            retentionDays: other.retentionDays,
            enableIncrementalBackup: other.enableIncrementalBackup,
            enableCloudBackup: other.enableCloudBackup,
            cloudProvider: other.cloudProvider,
            backupSchedule: other.backupSchedule,
            excludePatterns: other.excludePatterns,
            includeUserData: other.includeUserData,
            includePreferences: other.includePreferences,
            includeDocuments: other.includeDocuments,
            enableVerification: other.enableVerification
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> BackupCapabilityConfiguration {
        var adjustedSize = maxBackupSize
        var adjustedIncremental = enableIncrementalBackup
        var adjustedCloud = enableCloudBackup
        var adjustedSchedule = backupSchedule
        
        if environment.isLowPowerMode {
            adjustedSize = min(maxBackupSize, 100 * 1024 * 1024) // 100MB limit
            adjustedIncremental = true // More efficient
            adjustedCloud = false // Avoid network usage
            adjustedSchedule = .manual // Don't run automatically
        }
        
        if environment.isDebug {
            adjustedSchedule = .manual // Manual control in debug
        }
        
        return BackupCapabilityConfiguration(
            enableEncryption: enableEncryption,
            compressionLevel: compressionLevel,
            maxBackupSize: adjustedSize,
            retentionDays: retentionDays,
            enableIncrementalBackup: adjustedIncremental,
            enableCloudBackup: adjustedCloud,
            cloudProvider: cloudProvider,
            backupSchedule: adjustedSchedule,
            excludePatterns: excludePatterns,
            includeUserData: includeUserData,
            includePreferences: includePreferences,
            includeDocuments: includeDocuments,
            enableVerification: enableVerification
        )
    }
}

// MARK: - Backup Types

/// Cloud backup providers
public enum CloudBackupProvider: String, Codable, CaseIterable, Sendable {
    case iCloudDrive = "icloud_drive"
    case none = "none"
}

/// Backup schedule options
public enum BackupSchedule: String, Codable, CaseIterable, Sendable {
    case manual = "manual"
    case daily = "daily"
    case weekly = "weekly"
    case automatic = "automatic"
}

/// Backup metadata
public struct BackupMetadata: Sendable, Codable {
    public let id: UUID
    public let name: String
    public let creationDate: Date
    public let size: Int64
    public let isEncrypted: Bool
    public let isCompressed: Bool
    public let isIncremental: Bool
    public let checksum: String
    public let version: String
    public let platform: String
    public let includedComponents: [String]
    
    public init(
        id: UUID = UUID(),
        name: String,
        creationDate: Date = Date(),
        size: Int64,
        isEncrypted: Bool,
        isCompressed: Bool,
        isIncremental: Bool,
        checksum: String,
        version: String,
        platform: String,
        includedComponents: [String]
    ) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.size = size
        self.isEncrypted = isEncrypted
        self.isCompressed = isCompressed
        self.isIncremental = isIncremental
        self.checksum = checksum
        self.version = version
        self.platform = platform
        self.includedComponents = includedComponents
    }
}

/// Backup operation context
public struct BackupOperationContext: Sendable {
    public let operationId: UUID
    public let startTime: Date
    public let operationType: BackupOperationType
    public let metadata: [String: String]
    
    public init(
        operationId: UUID = UUID(),
        startTime: Date = Date(),
        operationType: BackupOperationType,
        metadata: [String: String] = [:]
    ) {
        self.operationId = operationId
        self.startTime = startTime
        self.operationType = operationType
        self.metadata = metadata
    }
}

/// Backup operation types
public enum BackupOperationType: String, Codable, CaseIterable, Sendable {
    case create = "create"
    case restore = "restore"
    case verify = "verify"
    case delete = "delete"
    case list = "list"
}

/// Backup operation result
public struct BackupOperationResult: Sendable {
    public let success: Bool
    public let metadata: BackupMetadata?
    public let duration: TimeInterval
    public let context: BackupOperationContext
    public let error: String?
    public let bytesProcessed: Int64
    
    public init(
        success: Bool,
        metadata: BackupMetadata? = nil,
        duration: TimeInterval,
        context: BackupOperationContext,
        error: String? = nil,
        bytesProcessed: Int64 = 0
    ) {
        self.success = success
        self.metadata = metadata
        self.duration = duration
        self.context = context
        self.error = error
        self.bytesProcessed = bytesProcessed
    }
}

// MARK: - Backup Resource

/// Backup resource management
public actor BackupCapabilityResource: AxiomCapabilityResource {
    private let configuration: BackupCapabilityConfiguration
    private var localBackupDirectory: URL?
    private var cloudBackupDirectory: URL?
    private var activeOperations: Set<UUID> = []
    private var encryptionKey: SymmetricKey?
    private var lastBackupDate: Date?
    
    public init(configuration: BackupCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxBackupSize / 10, // 10% of backup size for processing
            cpu: 15.0, // Backup operations are CPU intensive
            bandwidth: configuration.enableCloudBackup ? configuration.maxBackupSize : 0,
            storage: configuration.maxBackupSize * 2 // For backup storage and temporary files
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let operationCount = activeOperations.count
            let estimatedMemory = operationCount * 10_000_000 // 10MB per operation
            
            return ResourceUsage(
                memory: estimatedMemory,
                cpu: Double(operationCount * 5), // 5% CPU per operation
                bandwidth: 0, // Dynamic based on operations
                storage: estimatedMemory // Temporary storage during operations
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        localBackupDirectory != nil
    }
    
    public func release() async {
        activeOperations.removeAll()
        encryptionKey = nil
        lastBackupDate = nil
        localBackupDirectory = nil
        cloudBackupDirectory = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Set up local backup directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localBackupDirectory = documentsURL.appendingPathComponent("Backups")
        
        // Create backup directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: localBackupDirectory!,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Set up cloud backup directory if enabled
        if configuration.enableCloudBackup {
            if let ubiquityContainer = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
                cloudBackupDirectory = ubiquityContainer.appendingPathComponent("Backups")
                try FileManager.default.createDirectory(
                    at: cloudBackupDirectory!,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
        
        // Generate encryption key if encryption is enabled
        if configuration.enableEncryption {
            encryptionKey = SymmetricKey(size: .bits256)
        }
    }
    
    internal func updateConfiguration(_ configuration: BackupCapabilityConfiguration) async throws {
        // Backup configuration changes require reallocation
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Backup Access
    
    public func getLocalBackupDirectory() -> URL? {
        localBackupDirectory
    }
    
    public func getCloudBackupDirectory() -> URL? {
        cloudBackupDirectory
    }
    
    public func addActiveOperation(_ operationId: UUID) {
        activeOperations.insert(operationId)
    }
    
    public func removeActiveOperation(_ operationId: UUID) {
        activeOperations.remove(operationId)
    }
    
    public func getEncryptionKey() -> SymmetricKey? {
        encryptionKey
    }
    
    public func setLastBackupDate(_ date: Date) {
        lastBackupDate = date
    }
    
    public func getLastBackupDate() -> Date? {
        lastBackupDate
    }
}

// MARK: - Backup Capability Implementation

/// Backup capability providing data backup and restore functionality
public actor BackupCapability: DomainCapability {
    public typealias ConfigurationType = BackupCapabilityConfiguration
    public typealias ResourceType = BackupCapabilityResource
    
    private var _configuration: BackupCapabilityConfiguration
    private var _resources: BackupCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "backup-capability" }
    
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
    
    public var configuration: BackupCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: BackupCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: BackupCapabilityConfiguration = BackupCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = BackupCapabilityResource(configuration: self._configuration)
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
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: BackupCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Backup configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Backup is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Backup doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Backup Operations
    
    /// Create a backup
    public func createBackup(name: String? = nil) async throws -> BackupOperationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Backup capability not available")
        }
        
        let context = BackupOperationContext(operationType: .create)
        let startTime = ContinuousClock.now
        
        await _resources.addActiveOperation(context.operationId)
        defer { Task { await _resources.removeActiveOperation(context.operationId) } }
        
        do {
            let backupName = name ?? "Backup_\(DateFormatter.backupFormatter.string(from: Date()))"
            let metadata = try await performBackup(name: backupName)
            let duration = ContinuousClock.now - startTime
            
            await _resources.setLastBackupDate(Date())
            
            return BackupOperationResult(
                success: true,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context,
                bytesProcessed: metadata.size
            )
        } catch {
            let duration = ContinuousClock.now - startTime
            return BackupOperationResult(
                success: false,
                duration: duration.timeInterval,
                context: context,
                error: error.localizedDescription
            )
        }
    }
    
    /// Restore from backup
    public func restoreBackup(_ metadata: BackupMetadata) async throws -> BackupOperationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Backup capability not available")
        }
        
        let context = BackupOperationContext(operationType: .restore)
        let startTime = ContinuousClock.now
        
        await _resources.addActiveOperation(context.operationId)
        defer { Task { await _resources.removeActiveOperation(context.operationId) } }
        
        do {
            try await performRestore(metadata: metadata)
            let duration = ContinuousClock.now - startTime
            
            return BackupOperationResult(
                success: true,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context,
                bytesProcessed: metadata.size
            )
        } catch {
            let duration = ContinuousClock.now - startTime
            return BackupOperationResult(
                success: false,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context,
                error: error.localizedDescription
            )
        }
    }
    
    /// List available backups
    public func listBackups() async throws -> [BackupMetadata] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Backup capability not available")
        }
        
        guard let backupDirectory = await _resources.getLocalBackupDirectory() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Backup directory not available")
        }
        
        var backups: [BackupMetadata] = []
        
        // List local backups
        let localBackups = try listBackupsInDirectory(backupDirectory)
        backups.append(contentsOf: localBackups)
        
        // List cloud backups if enabled
        if _configuration.enableCloudBackup,
           let cloudDirectory = await _resources.getCloudBackupDirectory() {
            let cloudBackups = try listBackupsInDirectory(cloudDirectory)
            backups.append(contentsOf: cloudBackups)
        }
        
        // Remove duplicates and sort by creation date
        let uniqueBackups = Dictionary(grouping: backups, by: { $0.id }).compactMapValues { $0.first }
        return Array(uniqueBackups.values).sorted { $0.creationDate > $1.creationDate }
    }
    
    /// Delete backup
    public func deleteBackup(_ metadata: BackupMetadata) async throws -> BackupOperationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Backup capability not available")
        }
        
        let context = BackupOperationContext(operationType: .delete)
        let startTime = ContinuousClock.now
        
        do {
            try await performDelete(metadata: metadata)
            let duration = ContinuousClock.now - startTime
            
            return BackupOperationResult(
                success: true,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context
            )
        } catch {
            let duration = ContinuousClock.now - startTime
            return BackupOperationResult(
                success: false,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context,
                error: error.localizedDescription
            )
        }
    }
    
    /// Verify backup integrity
    public func verifyBackup(_ metadata: BackupMetadata) async throws -> BackupOperationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Backup capability not available")
        }
        
        let context = BackupOperationContext(operationType: .verify)
        let startTime = ContinuousClock.now
        
        do {
            let isValid = try await performVerification(metadata: metadata)
            let duration = ContinuousClock.now - startTime
            
            return BackupOperationResult(
                success: isValid,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context,
                error: isValid ? nil : "Backup verification failed"
            )
        } catch {
            let duration = ContinuousClock.now - startTime
            return BackupOperationResult(
                success: false,
                metadata: metadata,
                duration: duration.timeInterval,
                context: context,
                error: error.localizedDescription
            )
        }
    }
    
    // MARK: - Private Implementation Methods
    
    private func performBackup(name: String) async throws -> BackupMetadata {
        guard let backupDirectory = await _resources.getLocalBackupDirectory() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Backup directory not available")
        }
        
        // Collect data to backup
        var dataToBackup: [String: Data] = [:]
        var includedComponents: [String] = []
        
        if _configuration.includeUserData {
            dataToBackup["user_data"] = try await collectUserData()
            includedComponents.append("user_data")
        }
        
        if _configuration.includePreferences {
            dataToBackup["preferences"] = try await collectPreferences()
            includedComponents.append("preferences")
        }
        
        if _configuration.includeDocuments {
            dataToBackup["documents"] = try await collectDocuments()
            includedComponents.append("documents")
        }
        
        // Create backup archive
        let backupId = UUID()
        let backupFileName = "\(name)_\(backupId.uuidString).backup"
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        let archiveData = try await createArchive(dataToBackup)
        var finalData = archiveData
        
        // Compress if enabled
        if _configuration.compressionLevel > 0 {
            finalData = try await compressData(finalData, level: _configuration.compressionLevel)
        }
        
        // Encrypt if enabled
        if _configuration.enableEncryption,
           let encryptionKey = await _resources.getEncryptionKey() {
            finalData = try await encryptData(finalData, key: encryptionKey)
        }
        
        // Check size limit
        guard finalData.count <= _configuration.maxBackupSize else {
            throw AxiomCapabilityError.operationFailed("Backup size exceeds maximum allowed size")
        }
        
        // Write backup file
        try finalData.write(to: backupURL)
        
        // Create metadata
        let checksum = SHA256.hash(data: finalData).compactMap { String(format: "%02x", $0) }.joined()
        let metadata = BackupMetadata(
            id: backupId,
            name: name,
            size: Int64(finalData.count),
            isEncrypted: _configuration.enableEncryption,
            isCompressed: _configuration.compressionLevel > 0,
            isIncremental: _configuration.enableIncrementalBackup,
            checksum: checksum,
            version: "1.0",
            platform: "iOS",
            includedComponents: includedComponents
        )
        
        // Save metadata
        let metadataURL = backupDirectory.appendingPathComponent("\(backupFileName).metadata")
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
        
        // Upload to cloud if enabled
        if _configuration.enableCloudBackup,
           let cloudDirectory = await _resources.getCloudBackupDirectory() {
            let cloudBackupURL = cloudDirectory.appendingPathComponent(backupFileName)
            let cloudMetadataURL = cloudDirectory.appendingPathComponent("\(backupFileName).metadata")
            try finalData.write(to: cloudBackupURL)
            try metadataData.write(to: cloudMetadataURL)
        }
        
        return metadata
    }
    
    private func performRestore(metadata: BackupMetadata) async throws {
        guard let backupDirectory = await _resources.getLocalBackupDirectory() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Backup directory not available")
        }
        
        let backupFileName = "\(metadata.name)_\(metadata.id.uuidString).backup"
        var backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        // Try cloud backup if local not found
        if !FileManager.default.fileExists(atPath: backupURL.path),
           let cloudDirectory = await _resources.getCloudBackupDirectory() {
            backupURL = cloudDirectory.appendingPathComponent(backupFileName)
        }
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw AxiomCapabilityError.operationFailed("Backup file not found")
        }
        
        var backupData = try Data(contentsOf: backupURL)
        
        // Decrypt if encrypted
        if metadata.isEncrypted,
           let encryptionKey = await _resources.getEncryptionKey() {
            backupData = try await decryptData(backupData, key: encryptionKey)
        }
        
        // Decompress if compressed
        if metadata.isCompressed {
            backupData = try await decompressData(backupData)
        }
        
        // Extract archive
        let restoredData = try await extractArchive(backupData)
        
        // Restore data
        try await restoreData(restoredData)
    }
    
    private func performDelete(metadata: BackupMetadata) async throws {
        guard let backupDirectory = await _resources.getLocalBackupDirectory() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Backup directory not available")
        }
        
        let backupFileName = "\(metadata.name)_\(metadata.id.uuidString).backup"
        let metadataFileName = "\(backupFileName).metadata"
        
        // Delete local files
        let localBackupURL = backupDirectory.appendingPathComponent(backupFileName)
        let localMetadataURL = backupDirectory.appendingPathComponent(metadataFileName)
        
        try? FileManager.default.removeItem(at: localBackupURL)
        try? FileManager.default.removeItem(at: localMetadataURL)
        
        // Delete cloud files if enabled
        if _configuration.enableCloudBackup,
           let cloudDirectory = await _resources.getCloudBackupDirectory() {
            let cloudBackupURL = cloudDirectory.appendingPathComponent(backupFileName)
            let cloudMetadataURL = cloudDirectory.appendingPathComponent(metadataFileName)
            
            try? FileManager.default.removeItem(at: cloudBackupURL)
            try? FileManager.default.removeItem(at: cloudMetadataURL)
        }
    }
    
    private func performVerification(metadata: BackupMetadata) async throws -> Bool {
        guard let backupDirectory = await _resources.getLocalBackupDirectory() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Backup directory not available")
        }
        
        let backupFileName = "\(metadata.name)_\(metadata.id.uuidString).backup"
        var backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        // Try cloud backup if local not found
        if !FileManager.default.fileExists(atPath: backupURL.path),
           let cloudDirectory = await _resources.getCloudBackupDirectory() {
            backupURL = cloudDirectory.appendingPathComponent(backupFileName)
        }
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            return false
        }
        
        let backupData = try Data(contentsOf: backupURL)
        let checksum = SHA256.hash(data: backupData).compactMap { String(format: "%02x", $0) }.joined()
        
        return checksum == metadata.checksum
    }
    
    private func listBackupsInDirectory(_ directory: URL) throws -> [BackupMetadata] {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        let metadataURLs = fileURLs.filter { $0.pathExtension == "metadata" }
        var backups: [BackupMetadata] = []
        
        for url in metadataURLs {
            do {
                let data = try Data(contentsOf: url)
                let metadata = try JSONDecoder().decode(BackupMetadata.self, from: data)
                backups.append(metadata)
            } catch {
                // Skip invalid metadata files
                continue
            }
        }
        
        return backups
    }
    
    // MARK: - Data Collection Methods
    
    private func collectUserData() async throws -> Data {
        // Collect application-specific user data
        // This is a placeholder implementation
        let userData = ["user_data": "placeholder"]
        return try JSONEncoder().encode(userData)
    }
    
    private func collectPreferences() async throws -> Data {
        // Collect user preferences and settings
        let preferences = UserDefaults.standard.dictionaryRepresentation()
        // Filter to only Codable types
        let codablePreferences = preferences.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue.stringValue
            }
            return String(describing: value)
        }
        return try JSONEncoder().encode(codablePreferences)
    }
    
    private func collectDocuments() async throws -> Data {
        // Collect document data
        // This is a placeholder implementation
        let documents = ["documents": "placeholder"]
        return try JSONEncoder().encode(documents)
    }
    
    // MARK: - Archive Operations
    
    private func createArchive(_ data: [String: Data]) async throws -> Data {
        // Create a simple archive format
        return try JSONEncoder().encode(data)
    }
    
    private func extractArchive(_ data: Data) async throws -> [String: Data] {
        // Extract from simple archive format
        return try JSONDecoder().decode([String: Data].self, from: data)
    }
    
    // MARK: - Compression Operations
    
    private func compressData(_ data: Data, level: Int) async throws -> Data {
        // Implement compression using NSData compression
        return try (data as NSData).compressed(using: .lzfse) as Data
    }
    
    private func decompressData(_ data: Data) async throws -> Data {
        // Implement decompression
        return try (data as NSData).decompressed(using: .lzfse) as Data
    }
    
    // MARK: - Encryption Operations
    
    private func encryptData(_ data: Data, key: SymmetricKey) async throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        return sealedBox.combined
    }
    
    private func decryptData(_ data: Data, key: SymmetricKey) async throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(sealedBox, using: key)
    }
    
    // MARK: - Restore Operations
    
    private func restoreData(_ data: [String: Data]) async throws {
        // Restore the backed up data
        // This is a placeholder implementation
        for (component, componentData) in data {
            print("Restoring component: \(component) (\(componentData.count) bytes)")
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}


// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Backup specific errors
    public static func backupError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Backup: \(message)")
    }
    
    public static func backupSizeExceeded() -> AxiomCapabilityError {
        .operationFailed("Backup size exceeds maximum allowed size")
    }
    
    public static func backupNotFound(_ name: String) -> AxiomCapabilityError {
        .operationFailed("Backup '\(name)' not found")
    }
    
    public static func backupCorrupted(_ name: String) -> AxiomCapabilityError {
        .operationFailed("Backup '\(name)' is corrupted")
    }
}