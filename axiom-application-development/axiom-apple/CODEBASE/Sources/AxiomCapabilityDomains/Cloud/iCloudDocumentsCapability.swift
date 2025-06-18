import Foundation
import FileProvider
import UniformTypeIdentifiers
import AxiomCore
import AxiomCapabilities

// MARK: - iCloud Documents Capability Configuration

/// Configuration for iCloud Documents capability
public struct iCloudDocumentsCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let containerIdentifier: String?
    public let enableDocumentScanning: Bool
    public let enableVersionConflictResolution: Bool
    public let enableMetadataQueries: Bool
    public let maxDocumentSize: Int
    public let allowedDocumentTypes: [String]
    public let enableCoordination: Bool
    public let coordinationTimeout: TimeInterval
    public let enableBackgroundDownloads: Bool
    
    public init(
        containerIdentifier: String? = nil,
        enableDocumentScanning: Bool = true,
        enableVersionConflictResolution: Bool = true,
        enableMetadataQueries: Bool = true,
        maxDocumentSize: Int = 100 * 1024 * 1024, // 100MB
        allowedDocumentTypes: [String] = ["public.data"],
        enableCoordination: Bool = true,
        coordinationTimeout: TimeInterval = 30.0,
        enableBackgroundDownloads: Bool = true
    ) {
        self.containerIdentifier = containerIdentifier
        self.enableDocumentScanning = enableDocumentScanning
        self.enableVersionConflictResolution = enableVersionConflictResolution
        self.enableMetadataQueries = enableMetadataQueries
        self.maxDocumentSize = maxDocumentSize
        self.allowedDocumentTypes = allowedDocumentTypes
        self.enableCoordination = enableCoordination
        self.coordinationTimeout = coordinationTimeout
        self.enableBackgroundDownloads = enableBackgroundDownloads
    }
    
    public var isValid: Bool {
        maxDocumentSize > 0 && coordinationTimeout > 0 && !allowedDocumentTypes.isEmpty
    }
    
    public func merged(with other: iCloudDocumentsCapabilityConfiguration) -> iCloudDocumentsCapabilityConfiguration {
        iCloudDocumentsCapabilityConfiguration(
            containerIdentifier: other.containerIdentifier ?? containerIdentifier,
            enableDocumentScanning: other.enableDocumentScanning,
            enableVersionConflictResolution: other.enableVersionConflictResolution,
            enableMetadataQueries: other.enableMetadataQueries,
            maxDocumentSize: other.maxDocumentSize,
            allowedDocumentTypes: other.allowedDocumentTypes,
            enableCoordination: other.enableCoordination,
            coordinationTimeout: other.coordinationTimeout,
            enableBackgroundDownloads: other.enableBackgroundDownloads
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> iCloudDocumentsCapabilityConfiguration {
        var adjustedSize = maxDocumentSize
        var adjustedQueries = enableMetadataQueries
        var adjustedBackgroundDownloads = enableBackgroundDownloads
        
        if environment.isLowPowerMode {
            adjustedSize = min(maxDocumentSize, 10 * 1024 * 1024) // 10MB limit
            adjustedQueries = false
            adjustedBackgroundDownloads = false
        }
        
        return iCloudDocumentsCapabilityConfiguration(
            containerIdentifier: containerIdentifier,
            enableDocumentScanning: enableDocumentScanning,
            enableVersionConflictResolution: enableVersionConflictResolution,
            enableMetadataQueries: adjustedQueries,
            maxDocumentSize: adjustedSize,
            allowedDocumentTypes: allowedDocumentTypes,
            enableCoordination: enableCoordination,
            coordinationTimeout: coordinationTimeout,
            enableBackgroundDownloads: adjustedBackgroundDownloads
        )
    }
}

// MARK: - iCloud Document Types

/// iCloud document states
public enum iCloudDocumentState: String, Codable, CaseIterable, Sendable {
    case normal
    case downloading
    case uploaded
    case inConflict
    case notUploaded
}

/// Document metadata
public struct iCloudDocumentMetadata: Sendable, Codable {
    public let url: URL
    public let name: String
    public let contentType: String
    public let fileSize: Int64
    public let creationDate: Date
    public let modificationDate: Date
    public let downloadStatus: iCloudDocumentState
    public let isDownloaded: Bool
    public let hasUnresolvedConflicts: Bool
    public let downloadingError: String?
    
    public init(
        url: URL,
        name: String,
        contentType: String,
        fileSize: Int64,
        creationDate: Date,
        modificationDate: Date,
        downloadStatus: iCloudDocumentState,
        isDownloaded: Bool,
        hasUnresolvedConflicts: Bool,
        downloadingError: String? = nil
    ) {
        self.url = url
        self.name = name
        self.contentType = contentType
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.downloadStatus = downloadStatus
        self.isDownloaded = isDownloaded
        self.hasUnresolvedConflicts = hasUnresolvedConflicts
        self.downloadingError = downloadingError
    }
}

/// Document operation context
public struct iCloudDocumentOperationContext: Sendable {
    public let operationId: UUID
    public let startTime: Date
    public let operationType: String
    public let metadata: [String: String]
    
    public init(
        operationId: UUID = UUID(),
        startTime: Date = Date(),
        operationType: String,
        metadata: [String: String] = [:]
    ) {
        self.operationId = operationId
        self.startTime = startTime
        self.operationType = operationType
        self.metadata = metadata
    }
}

// MARK: - iCloud Documents Resource

/// iCloud Documents resource management
public actor iCloudDocumentsCapabilityResource: AxiomCapabilityResource {
    private let configuration: iCloudDocumentsCapabilityConfiguration
    private var ubiquityContainer: URL?
    private var documentsDirectory: URL?
    private var metadataQuery: NSMetadataQuery?
    private var coordinatedReads: Set<String> = []
    private var coordinatedWrites: Set<String> = []
    
    public init(configuration: iCloudDocumentsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxDocumentSize,
            cpu: 3.0, // Document coordination can be CPU intensive
            bandwidth: configuration.maxDocumentSize, // For downloads/uploads
            storage: configuration.maxDocumentSize * 10 // Estimate for document storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let coordinatedOperations = coordinatedReads.count + coordinatedWrites.count
            let estimatedMemory = coordinatedOperations * 10_000 // 10KB per operation
            
            return ResourceUsage(
                memory: estimatedMemory,
                cpu: configuration.enableMetadataQueries ? 2.0 : 1.0,
                bandwidth: 0, // Dynamic based on operations
                storage: estimatedMemory * 5 // Estimate for cached data
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        ubiquityContainer != nil && documentsDirectory != nil
    }
    
    public func release() async {
        // Stop metadata queries
        metadataQuery?.stop()
        metadataQuery = nil
        
        // Clear coordination tracking
        coordinatedReads.removeAll()
        coordinatedWrites.removeAll()
        
        // Clear directory references
        ubiquityContainer = nil
        documentsDirectory = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Get ubiquity container
        if let containerIdentifier = configuration.containerIdentifier {
            ubiquityContainer = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)
        } else {
            ubiquityContainer = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        }
        
        guard let ubiquityContainer = ubiquityContainer else {
            throw AxiomCapabilityError.initializationFailed("iCloud container not available. Ensure iCloud Documents capability is enabled.")
        }
        
        // Set up documents directory
        documentsDirectory = ubiquityContainer.appendingPathComponent("Documents")
        
        // Create documents directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: documentsDirectory!,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Set up metadata query if enabled
        if configuration.enableMetadataQueries {
            try await setupMetadataQuery()
        }
    }
    
    internal func updateConfiguration(_ configuration: iCloudDocumentsCapabilityConfiguration) async throws {
        // iCloud Documents configuration changes require reallocation
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - iCloud Documents Access
    
    public func getUbiquityContainer() -> URL? {
        ubiquityContainer
    }
    
    public func getDocumentsDirectory() -> URL? {
        documentsDirectory
    }
    
    public func addCoordinatedRead(_ identifier: String) {
        coordinatedReads.insert(identifier)
    }
    
    public func removeCoordinatedRead(_ identifier: String) {
        coordinatedReads.remove(identifier)
    }
    
    public func addCoordinatedWrite(_ identifier: String) {
        coordinatedWrites.insert(identifier)
    }
    
    public func removeCoordinatedWrite(_ identifier: String) {
        coordinatedWrites.remove(identifier)
    }
    
    public func getMetadataQuery() -> NSMetadataQuery? {
        metadataQuery
    }
    
    // MARK: - Private Setup Methods
    
    private func setupMetadataQuery() async throws {
        metadataQuery = NSMetadataQuery()
        guard let metadataQuery = metadataQuery else { return }
        
        // Set up query for documents
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        // Set up notification observers
        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: metadataQuery,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleMetadataQueryUpdate()
            }
        }
        
        // Start the query
        metadataQuery.start()
    }
    
    private func handleMetadataQueryUpdate() async {
        // Handle metadata query updates
        // This would typically notify observers of document changes
    }
}

// MARK: - iCloud Documents Capability Implementation

/// iCloud Documents capability providing cloud document synchronization
public actor iCloudDocumentsCapability: DomainCapability {
    public typealias ConfigurationType = iCloudDocumentsCapabilityConfiguration
    public typealias ResourceType = iCloudDocumentsCapabilityResource
    
    private var _configuration: iCloudDocumentsCapabilityConfiguration
    private var _resources: iCloudDocumentsCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "icloud-documents-capability" }
    
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
    
    public var configuration: iCloudDocumentsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: iCloudDocumentsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: iCloudDocumentsCapabilityConfiguration = iCloudDocumentsCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = iCloudDocumentsCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: iCloudDocumentsCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid iCloud Documents configuration")
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
        // Check if iCloud Drive is available
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    public func requestPermission() async throws {
        // iCloud Documents doesn't require explicit permission,
        // but we can check if the user has iCloud enabled
        guard await isSupported() else {
            throw AxiomCapabilityError.permissionDenied("iCloud Drive not available")
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Document Operations
    
    /// Create a new document
    public func createDocument(name: String, content: Data, contentType: String) async throws -> iCloudDocumentMetadata {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("iCloud Documents capability not available")
        }
        
        guard _configuration.allowedDocumentTypes.contains(contentType) else {
            throw AxiomCapabilityError.operationFailed("Document type '\(contentType)' not allowed")
        }
        
        guard content.count <= _configuration.maxDocumentSize else {
            throw AxiomCapabilityError.operationFailed("Document size exceeds maximum allowed size")
        }
        
        guard let documentsDirectory = await _resources.getDocumentsDirectory() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Documents directory not available")
        }
        
        let documentURL = documentsDirectory.appendingPathComponent(name)
        
        if _configuration.enableCoordination {
            try await withCoordinatedWriting(to: documentURL) {
                try content.write(to: documentURL)
            }
            return try await getDocumentMetadata(for: documentURL)
        } else {
            try content.write(to: documentURL)
            return try await getDocumentMetadata(for: documentURL)
        }
    }
    
    /// Read document content
    public func readDocument(at url: URL) async throws -> Data {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("iCloud Documents capability not available")
        }
        
        // Ensure document is downloaded
        try await downloadDocument(at: url)
        
        if _configuration.enableCoordination {
            return try await withCoordinatedReading(from: url) {
                return try Data(contentsOf: url)
            }
        } else {
            return try Data(contentsOf: url)
        }
    }
    
    /// Update document content
    public func updateDocument(at url: URL, content: Data) async throws -> iCloudDocumentMetadata {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("iCloud Documents capability not available")
        }
        
        guard content.count <= _configuration.maxDocumentSize else {
            throw AxiomCapabilityError.operationFailed("Document size exceeds maximum allowed size")
        }
        
        if _configuration.enableCoordination {
            try await withCoordinatedWriting(to: url) {
                try content.write(to: url)
            }
            return try await getDocumentMetadata(for: url)
        } else {
            try content.write(to: url)
            return try await getDocumentMetadata(for: url)
        }
    }
    
    /// Delete document
    public func deleteDocument(at url: URL) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("iCloud Documents capability not available")
        }
        
        if _configuration.enableCoordination {
            try await withCoordinatedWriting(to: url) {
                try FileManager.default.removeItem(at: url)
            }
        } else {
            try FileManager.default.removeItem(at: url)
        }
    }
    
    /// List documents in directory
    public func listDocuments(in directory: URL? = nil) async throws -> [iCloudDocumentMetadata] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("iCloud Documents capability not available")
        }
        
        let targetDirectory: URL?
        if let directory = directory {
            targetDirectory = directory
        } else {
            targetDirectory = await _resources.getDocumentsDirectory()
        }
        guard let targetDirectory = targetDirectory else {
            throw AxiomCapabilityError.resourceAllocationFailed("Target directory not available")
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: targetDirectory,
            includingPropertiesForKeys: [.contentTypeKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        var documents: [iCloudDocumentMetadata] = []
        for url in fileURLs {
            do {
                let metadata = try await getDocumentMetadata(for: url)
                documents.append(metadata)
            } catch {
                // Skip files that can't be read
                continue
            }
        }
        
        return documents
    }
    
    /// Download document from iCloud
    public func downloadDocument(at url: URL) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("iCloud Documents capability not available")
        }
        
        // Simplified download check - in a real implementation this would check iCloud status
        let fileExists = FileManager.default.fileExists(atPath: url.path)
        
        if !fileExists {
            // In a real implementation, this would start downloading from iCloud
            // For now, just check if file exists
            throw AxiomCapabilityError.operationFailed("Document not available locally")
        }
    }
    
    /// Get document metadata
    public func getDocumentMetadata(for url: URL) async throws -> iCloudDocumentMetadata {
        let resourceValues = try url.resourceValues(forKeys: [
            .nameKey,
            .contentTypeKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])
        
        let name = resourceValues.name ?? url.lastPathComponent
        let contentType = resourceValues.contentType?.identifier ?? "public.data"
        let fileSize = Int64(resourceValues.fileSize ?? 0)
        let creationDate = resourceValues.creationDate ?? Date()
        let modificationDate = resourceValues.contentModificationDate ?? Date()
        
        // Simplified iCloud status detection
        let downloadStatus: iCloudDocumentState = .normal
        let isDownloaded = true
        let hasUnresolvedConflicts = false
        let downloadingError: String? = nil
        
        return iCloudDocumentMetadata(
            url: url,
            name: name,
            contentType: contentType,
            fileSize: fileSize,
            creationDate: creationDate,
            modificationDate: modificationDate,
            downloadStatus: downloadStatus,
            isDownloaded: isDownloaded,
            hasUnresolvedConflicts: hasUnresolvedConflicts,
            downloadingError: downloadingError
        )
    }
    
    // MARK: - Coordination Helpers
    
    private func withCoordinatedReading<T>(from url: URL, operation: @escaping () throws -> T) async throws -> T {
        let operationId = UUID().uuidString
        await _resources.addCoordinatedRead(operationId)
        defer { Task { await _resources.removeCoordinatedRead(operationId) } }
        
        return try await withCheckedThrowingContinuation { continuation in
            var error: NSError?
            var coordinator = NSFileCoordinator()
            
            coordinator.coordinate(readingItemAt: url, options: [], error: &error) { (readingURL) in
                do {
                    let result = try operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            if let error = error {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func withCoordinatedWriting<T>(to url: URL, operation: @escaping () throws -> T) async throws -> T {
        let operationId = UUID().uuidString
        await _resources.addCoordinatedWrite(operationId)
        defer { Task { await _resources.removeCoordinatedWrite(operationId) } }
        
        return try await withCheckedThrowingContinuation { continuation in
            var error: NSError?
            var coordinator = NSFileCoordinator()
            
            coordinator.coordinate(writingItemAt: url, options: [], error: &error) { (writingURL) in
                do {
                    let result = try operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            if let error = error {
                continuation.resume(throwing: error)
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
    /// iCloud Documents specific errors
    public static func iCloudDocumentsError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("iCloud Documents: \(message)")
    }
    
    public static func iCloudNotAvailable() -> AxiomCapabilityError {
        .unavailable("iCloud Drive not available")
    }
    
    public static func documentCoordinationFailed(_ error: Error) -> AxiomCapabilityError {
        .operationFailed("Document coordination failed: \(error.localizedDescription)")
    }
}