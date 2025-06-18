import Foundation
import UIKit
import UniformTypeIdentifiers
import AxiomCore
import AxiomCapabilities

// MARK: - AirDrop Capability Configuration

/// Configuration for AirDrop capability
public struct AirDropCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableAirDrop: Bool
    public let enableReceiving: Bool
    public let enableSending: Bool
    public let maxFileSize: Int64 // bytes
    public let supportedFileTypes: Set<String>
    public let enableProgressTracking: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let transferTimeout: TimeInterval
    public let maxConcurrentTransfers: Int
    public let enableCompression: Bool
    public let compressionQuality: Float
    
    public init(
        enableAirDrop: Bool = true,
        enableReceiving: Bool = true,
        enableSending: Bool = true,
        maxFileSize: Int64 = 100_000_000, // 100MB
        supportedFileTypes: Set<String> = ["public.data", "public.image", "public.text", "public.movie"],
        enableProgressTracking: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        transferTimeout: TimeInterval = 300.0, // 5 minutes
        maxConcurrentTransfers: Int = 3,
        enableCompression: Bool = true,
        compressionQuality: Float = 0.8
    ) {
        self.enableAirDrop = enableAirDrop
        self.enableReceiving = enableReceiving
        self.enableSending = enableSending
        self.maxFileSize = maxFileSize
        self.supportedFileTypes = supportedFileTypes
        self.enableProgressTracking = enableProgressTracking
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.transferTimeout = transferTimeout
        self.maxConcurrentTransfers = maxConcurrentTransfers
        self.enableCompression = enableCompression
        self.compressionQuality = compressionQuality
    }
    
    public var isValid: Bool {
        maxFileSize > 0 &&
        transferTimeout > 0 &&
        maxConcurrentTransfers > 0 &&
        compressionQuality >= 0 && compressionQuality <= 1.0
    }
    
    public func merged(with other: AirDropCapabilityConfiguration) -> AirDropCapabilityConfiguration {
        AirDropCapabilityConfiguration(
            enableAirDrop: other.enableAirDrop,
            enableReceiving: other.enableReceiving,
            enableSending: other.enableSending,
            maxFileSize: other.maxFileSize,
            supportedFileTypes: other.supportedFileTypes,
            enableProgressTracking: other.enableProgressTracking,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            transferTimeout: other.transferTimeout,
            maxConcurrentTransfers: other.maxConcurrentTransfers,
            enableCompression: other.enableCompression,
            compressionQuality: other.compressionQuality
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> AirDropCapabilityConfiguration {
        var adjustedMaxSize = maxFileSize
        var adjustedTimeout = transferTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentTransfers = maxConcurrentTransfers
        
        if environment.isLowPowerMode {
            adjustedMaxSize = min(maxFileSize, 10_000_000) // Reduce to 10MB
            adjustedTimeout = min(transferTimeout, 120.0) // Reduce to 2 minutes
            adjustedConcurrentTransfers = 1
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return AirDropCapabilityConfiguration(
            enableAirDrop: enableAirDrop,
            enableReceiving: enableReceiving,
            enableSending: enableSending,
            maxFileSize: adjustedMaxSize,
            supportedFileTypes: supportedFileTypes,
            enableProgressTracking: enableProgressTracking,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            transferTimeout: adjustedTimeout,
            maxConcurrentTransfers: adjustedConcurrentTransfers,
            enableCompression: enableCompression,
            compressionQuality: compressionQuality
        )
    }
}

// MARK: - AirDrop Types

/// AirDrop transfer item
public struct AirDropItem: Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let type: UTType
    public let size: Int64
    public let data: Data?
    public let url: URL?
    public let metadata: [String: String]
    public let thumbnail: Data?
    public let creationDate: Date
    public let priority: Priority
    
    public enum Priority: String, Sendable, Codable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case urgent = "urgent"
    }
    
    public init(
        name: String,
        type: UTType,
        size: Int64,
        data: Data? = nil,
        url: URL? = nil,
        metadata: [String: String] = [:],
        thumbnail: Data? = nil,
        priority: Priority = .normal
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.size = size
        self.data = data
        self.url = url
        self.metadata = metadata
        self.thumbnail = thumbnail
        self.creationDate = Date()
        self.priority = priority
    }
    
    public var typeIdentifier: String {
        type.identifier
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    public var hasData: Bool {
        data != nil || url != nil
    }
}

/// AirDrop transfer session
public struct AirDropTransfer: Sendable, Identifiable {
    public let id: UUID
    public let direction: Direction
    public let items: [AirDropItem]
    public let status: TransferStatus
    public let progress: Double
    public let startTime: Date
    public let endTime: Date?
    public let totalBytes: Int64
    public let transferredBytes: Int64
    public let transferRate: Double // bytes per second
    public let remainingTime: TimeInterval?
    public let error: AirDropError?
    public let recipientInfo: RecipientInfo?
    public let senderInfo: SenderInfo?
    
    public enum Direction: String, Sendable, Codable, CaseIterable {
        case sending = "sending"
        case receiving = "receiving"
    }
    
    public enum TransferStatus: String, Sendable, Codable, CaseIterable {
        case preparing = "preparing"
        case waiting = "waiting"
        case transferring = "transferring"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        case paused = "paused"
    }
    
    public struct RecipientInfo: Sendable, Codable {
        public let deviceName: String
        public let deviceType: String
        public let isContact: Bool
        public let acceptanceStatus: AcceptanceStatus
        
        public enum AcceptanceStatus: String, Sendable, Codable, CaseIterable {
            case pending = "pending"
            case accepted = "accepted"
            case declined = "declined"
        }
        
        public init(deviceName: String, deviceType: String, isContact: Bool, acceptanceStatus: AcceptanceStatus = .pending) {
            self.deviceName = deviceName
            self.deviceType = deviceType
            self.isContact = isContact
            self.acceptanceStatus = acceptanceStatus
        }
    }
    
    public struct SenderInfo: Sendable, Codable {
        public let deviceName: String
        public let deviceType: String
        public let isContact: Bool
        public let isTrusted: Bool
        
        public init(deviceName: String, deviceType: String, isContact: Bool, isTrusted: Bool) {
            self.deviceName = deviceName
            self.deviceType = deviceType
            self.isContact = isContact
            self.isTrusted = isTrusted
        }
    }
    
    public init(
        direction: Direction,
        items: [AirDropItem],
        status: TransferStatus = .preparing,
        progress: Double = 0.0,
        transferredBytes: Int64 = 0,
        transferRate: Double = 0,
        error: AirDropError? = nil,
        recipientInfo: RecipientInfo? = nil,
        senderInfo: SenderInfo? = nil
    ) {
        self.id = UUID()
        self.direction = direction
        self.items = items
        self.status = status
        self.progress = max(0.0, min(1.0, progress))
        self.startTime = Date()
        self.endTime = status.isFinished ? Date() : nil
        self.totalBytes = items.reduce(0) { $0 + $1.size }
        self.transferredBytes = transferredBytes
        self.transferRate = transferRate
        self.remainingTime = transferRate > 0 ? TimeInterval((totalBytes - transferredBytes)) / transferRate : nil
        self.error = error
        self.recipientInfo = recipientInfo
        self.senderInfo = senderInfo
    }
    
    public var isFinished: Bool {
        status.isFinished
    }
    
    public var wasSuccessful: Bool {
        status == .completed
    }
    
    public var duration: TimeInterval? {
        endTime?.timeIntervalSince(startTime)
    }
}

extension AirDropTransfer.TransferStatus {
    public var isFinished: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .preparing, .waiting, .transferring, .paused:
            return false
        }
    }
}

/// AirDrop discovery information
public struct AirDropDevice: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let deviceType: DeviceType
    public let availability: Availability
    public let isContact: Bool
    public let signalStrength: Double // 0.0 to 1.0
    public let lastSeen: Date
    public let supportsModernAirDrop: Bool
    
    public enum DeviceType: String, Sendable, Codable, CaseIterable {
        case iPhone = "iPhone"
        case iPad = "iPad"
        case mac = "Mac"
        case watch = "Watch"
        case unknown = "Unknown"
    }
    
    public enum Availability: String, Sendable, Codable, CaseIterable {
        case everyone = "everyone"
        case contactsOnly = "contacts-only"
        case receiving = "receiving"
        case off = "off"
    }
    
    public init(
        name: String,
        deviceType: DeviceType,
        availability: Availability,
        isContact: Bool,
        signalStrength: Double,
        supportsModernAirDrop: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.deviceType = deviceType
        self.availability = availability
        self.isContact = isContact
        self.signalStrength = max(0.0, min(1.0, signalStrength))
        self.lastSeen = Date()
        self.supportsModernAirDrop = supportsModernAirDrop
    }
    
    public var canReceive: Bool {
        availability != .off
    }
    
    public var ageInSeconds: TimeInterval {
        Date().timeIntervalSince(lastSeen)
    }
}

/// AirDrop metrics
public struct AirDropMetrics: Sendable {
    public let totalTransfers: Int
    public let successfulTransfers: Int
    public let failedTransfers: Int
    public let totalBytesSent: Int64
    public let totalBytesReceived: Int64
    public let averageTransferSpeed: Double
    public let averageTransferTime: TimeInterval
    public let transfersByType: [String: Int]
    public let deviceConnections: [String: Int]
    public let errorsByType: [String: Int]
    public let successRate: Double
    public let compressionEfficiency: Double
    
    public init(
        totalTransfers: Int = 0,
        successfulTransfers: Int = 0,
        failedTransfers: Int = 0,
        totalBytesSent: Int64 = 0,
        totalBytesReceived: Int64 = 0,
        averageTransferSpeed: Double = 0,
        averageTransferTime: TimeInterval = 0,
        transfersByType: [String: Int] = [:],
        deviceConnections: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        successRate: Double = 0,
        compressionEfficiency: Double = 0
    ) {
        self.totalTransfers = totalTransfers
        self.successfulTransfers = successfulTransfers
        self.failedTransfers = failedTransfers
        self.totalBytesSent = totalBytesSent
        self.totalBytesReceived = totalBytesReceived
        self.averageTransferSpeed = averageTransferSpeed
        self.averageTransferTime = averageTransferTime
        self.transfersByType = transfersByType
        self.deviceConnections = deviceConnections
        self.errorsByType = errorsByType
        self.successRate = totalTransfers > 0 ? Double(successfulTransfers) / Double(totalTransfers) : 0
        self.compressionEfficiency = compressionEfficiency
    }
}

// MARK: - AirDrop Resource

/// AirDrop resource management
public actor AirDropCapabilityResource: AxiomCapabilityResource {
    private let configuration: AirDropCapabilityConfiguration
    private var activeTransfers: [UUID: AirDropTransfer] = [:]
    private var transferHistory: [AirDropTransfer] = []
    private var discoveredDevices: [UUID: AirDropDevice] = [:]
    private var metrics: AirDropMetrics = AirDropMetrics()
    private var transferStreamContinuation: AsyncStream<AirDropTransfer>.Continuation?
    private var deviceDiscoveryStreamContinuation: AsyncStream<AirDropDevice>.Continuation?
    private var isDiscovering: Bool = false
    
    public init(configuration: AirDropCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 20_000_000, // 20MB for transfer management
            cpu: 2.0, // File processing and network activity
            bandwidth: 100_000_000, // 100MB for file transfers
            storage: 50_000_000 // 50MB for temporary files
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let transferMemory = activeTransfers.count * 1_000_000 // 1MB per transfer
            let historyMemory = transferHistory.count * 10_000
            let deviceMemory = discoveredDevices.count * 1_000
            
            let activeBandwidth = activeTransfers.values.reduce(0) { total, transfer in
                return total + Int(transfer.transferRate)
            }
            
            return ResourceUsage(
                memory: transferMemory + historyMemory + deviceMemory + 2_000_000,
                cpu: activeTransfers.isEmpty ? 0.1 : 1.5,
                bandwidth: activeBandwidth,
                storage: 0 // Dynamic based on active transfers
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // AirDrop is available on iOS 7+, macOS 10.10+
        return configuration.enableAirDrop
    }
    
    public func release() async {
        // Cancel all active transfers
        for transfer in activeTransfers.values {
            await cancelTransfer(transfer.id)
        }
        
        activeTransfers.removeAll()
        transferHistory.removeAll()
        discoveredDevices.removeAll()
        
        transferStreamContinuation?.finish()
        deviceDiscoveryStreamContinuation?.finish()
        
        metrics = AirDropMetrics()
        isDiscovering = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize AirDrop subsystem
        await startDeviceDiscovery()
    }
    
    internal func updateConfiguration(_ configuration: AirDropCapabilityConfiguration) async throws {
        // Configuration updates don't require restart for AirDrop
    }
    
    // MARK: - Transfer Streams
    
    public var transferStream: AsyncStream<AirDropTransfer> {
        AsyncStream { continuation in
            self.transferStreamContinuation = continuation
        }
    }
    
    public var deviceDiscoveryStream: AsyncStream<AirDropDevice> {
        AsyncStream { continuation in
            self.deviceDiscoveryStreamContinuation = continuation
        }
    }
    
    // MARK: - File Sharing
    
    public func shareItems(_ items: [AirDropItem]) async throws -> AirDropTransfer {
        guard configuration.enableSending else {
            throw AirDropError.sendingDisabled
        }
        
        guard activeTransfers.count < configuration.maxConcurrentTransfers else {
            throw AirDropError.tooManyActiveTransfers(configuration.maxConcurrentTransfers)
        }
        
        // Validate items
        for item in items {
            try validateItem(item)
        }
        
        let transfer = AirDropTransfer(
            direction: .sending,
            items: items,
            status: .preparing
        )
        
        activeTransfers[transfer.id] = transfer
        transferStreamContinuation?.yield(transfer)
        
        // Start the actual share process
        await initiateShare(transfer)
        
        if configuration.enableLogging {
            await logTransfer(transfer, action: "Started sharing")
        }
        
        return transfer
    }
    
    public func shareFile(at url: URL) async throws -> AirDropTransfer {
        let item = try await createItemFromURL(url)
        return try await shareItems([item])
    }
    
    public func shareText(_ text: String) async throws -> AirDropTransfer {
        let data = text.data(using: .utf8) ?? Data()
        let item = AirDropItem(
            name: "Text",
            type: .plainText,
            size: Int64(data.count),
            data: data
        )
        return try await shareItems([item])
    }
    
    public func shareImage(_ imageData: Data, name: String = "Image") async throws -> AirDropTransfer {
        let item = AirDropItem(
            name: name,
            type: .image,
            size: Int64(imageData.count),
            data: imageData
        )
        return try await shareItems([item])
    }
    
    // MARK: - Transfer Management
    
    public func getActiveTransfers() async -> [AirDropTransfer] {
        return Array(activeTransfers.values)
    }
    
    public func getTransferHistory(since: Date? = nil) async -> [AirDropTransfer] {
        if let since = since {
            return transferHistory.filter { $0.startTime >= since }
        }
        return transferHistory
    }
    
    public func getTransfer(by id: UUID) async -> AirDropTransfer? {
        return activeTransfers[id] ?? transferHistory.first { $0.id == id }
    }
    
    public func cancelTransfer(_ transferId: UUID) async {
        guard let transfer = activeTransfers[transferId] else { return }
        
        let cancelledTransfer = AirDropTransfer(
            direction: transfer.direction,
            items: transfer.items,
            status: .cancelled,
            progress: transfer.progress,
            transferredBytes: transfer.transferredBytes,
            transferRate: transfer.transferRate,
            error: transfer.error,
            recipientInfo: transfer.recipientInfo,
            senderInfo: transfer.senderInfo
        )
        
        activeTransfers[transferId] = cancelledTransfer
        transferHistory.append(cancelledTransfer)
        activeTransfers.removeValue(forKey: transferId)
        
        transferStreamContinuation?.yield(cancelledTransfer)
        
        await updateTransferMetrics(cancelledTransfer)
        
        if configuration.enableLogging {
            await logTransfer(cancelledTransfer, action: "Cancelled")
        }
    }
    
    public func pauseTransfer(_ transferId: UUID) async throws {
        guard var transfer = activeTransfers[transferId] else {
            throw AirDropError.transferNotFound(transferId)
        }
        
        guard transfer.status == .transferring else {
            throw AirDropError.invalidTransferState(transfer.status)
        }
        
        let pausedTransfer = AirDropTransfer(
            direction: transfer.direction,
            items: transfer.items,
            status: .paused,
            progress: transfer.progress,
            transferredBytes: transfer.transferredBytes,
            transferRate: 0,
            recipientInfo: transfer.recipientInfo,
            senderInfo: transfer.senderInfo
        )
        
        activeTransfers[transferId] = pausedTransfer
        transferStreamContinuation?.yield(pausedTransfer)
        
        if configuration.enableLogging {
            await logTransfer(pausedTransfer, action: "Paused")
        }
    }
    
    public func resumeTransfer(_ transferId: UUID) async throws {
        guard var transfer = activeTransfers[transferId] else {
            throw AirDropError.transferNotFound(transferId)
        }
        
        guard transfer.status == .paused else {
            throw AirDropError.invalidTransferState(transfer.status)
        }
        
        let resumedTransfer = AirDropTransfer(
            direction: transfer.direction,
            items: transfer.items,
            status: .transferring,
            progress: transfer.progress,
            transferredBytes: transfer.transferredBytes,
            transferRate: transfer.transferRate,
            recipientInfo: transfer.recipientInfo,
            senderInfo: transfer.senderInfo
        )
        
        activeTransfers[transferId] = resumedTransfer
        transferStreamContinuation?.yield(resumedTransfer)
        
        if configuration.enableLogging {
            await logTransfer(resumedTransfer, action: "Resumed")
        }
    }
    
    // MARK: - Device Discovery
    
    public func startDeviceDiscovery() async {
        guard !isDiscovering else { return }
        isDiscovering = true
        
        // Simulate device discovery (real implementation would use actual AirDrop APIs)
        await simulateDeviceDiscovery()
        
        if configuration.enableLogging {
            print("[AirDrop] 🔍 Device discovery started")
        }
    }
    
    public func stopDeviceDiscovery() async {
        isDiscovering = false
        
        if configuration.enableLogging {
            print("[AirDrop] 🛑 Device discovery stopped")
        }
    }
    
    public func getDiscoveredDevices() async -> [AirDropDevice] {
        // Remove stale devices (older than 30 seconds)
        let staleThreshold = Date().addingTimeInterval(-30)
        discoveredDevices = discoveredDevices.filter { _, device in
            device.lastSeen > staleThreshold
        }
        
        return Array(discoveredDevices.values)
    }
    
    public func getDevice(by id: UUID) async -> AirDropDevice? {
        return discoveredDevices[id]
    }
    
    // MARK: - Receiving
    
    public func handleIncomingTransfer(_ transfer: AirDropTransfer) async -> Bool {
        guard configuration.enableReceiving else {
            return false
        }
        
        activeTransfers[transfer.id] = transfer
        transferStreamContinuation?.yield(transfer)
        
        // Simulate acceptance (real implementation would show user prompt)
        let shouldAccept = await shouldAcceptIncomingTransfer(transfer)
        
        if shouldAccept {
            await acceptIncomingTransfer(transfer.id)
        } else {
            await declineIncomingTransfer(transfer.id)
        }
        
        return shouldAccept
    }
    
    public func acceptIncomingTransfer(_ transferId: UUID) async {
        guard var transfer = activeTransfers[transferId] else { return }
        
        let acceptedTransfer = AirDropTransfer(
            direction: .receiving,
            items: transfer.items,
            status: .transferring,
            recipientInfo: transfer.recipientInfo,
            senderInfo: transfer.senderInfo
        )
        
        activeTransfers[transferId] = acceptedTransfer
        transferStreamContinuation?.yield(acceptedTransfer)
        
        // Simulate transfer completion
        await simulateTransferCompletion(transferId)
        
        if configuration.enableLogging {
            await logTransfer(acceptedTransfer, action: "Accepted")
        }
    }
    
    public func declineIncomingTransfer(_ transferId: UUID) async {
        guard let transfer = activeTransfers[transferId] else { return }
        
        let declinedTransfer = AirDropTransfer(
            direction: .receiving,
            items: transfer.items,
            status: .cancelled,
            recipientInfo: transfer.recipientInfo,
            senderInfo: transfer.senderInfo
        )
        
        transferHistory.append(declinedTransfer)
        activeTransfers.removeValue(forKey: transferId)
        
        transferStreamContinuation?.yield(declinedTransfer)
        
        if configuration.enableLogging {
            await logTransfer(declinedTransfer, action: "Declined")
        }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> AirDropMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = AirDropMetrics()
    }
    
    // MARK: - Private Methods
    
    private func validateItem(_ item: AirDropItem) throws {
        guard item.size <= configuration.maxFileSize else {
            throw AirDropError.fileTooLarge(item.size, configuration.maxFileSize)
        }
        
        guard configuration.supportedFileTypes.contains(item.typeIdentifier) else {
            throw AirDropError.unsupportedFileType(item.typeIdentifier)
        }
    }
    
    private func createItemFromURL(_ url: URL) async throws -> AirDropItem {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .typeIdentifierKey, .nameKey])
        
        let size = Int64(resourceValues.fileSize ?? 0)
        let typeIdentifier = resourceValues.typeIdentifier ?? "public.data"
        let name = resourceValues.name ?? url.lastPathComponent
        
        guard let utType = UTType(typeIdentifier) else {
            throw AirDropError.unsupportedFileType(typeIdentifier)
        }
        
        return AirDropItem(
            name: name,
            type: utType,
            size: size,
            url: url
        )
    }
    
    private func initiateShare(_ transfer: AirDropTransfer) async {
        // In a real implementation, this would present the AirDrop share sheet
        // For now, we'll simulate the sharing process
        
        let waitingTransfer = AirDropTransfer(
            direction: transfer.direction,
            items: transfer.items,
            status: .waiting
        )
        
        activeTransfers[transfer.id] = waitingTransfer
        transferStreamContinuation?.yield(waitingTransfer)
        
        // Simulate user selection and transfer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task {
                await self.simulateTransferCompletion(transfer.id)
            }
        }
    }
    
    private func simulateTransferCompletion(_ transferId: UUID) async {
        guard let transfer = activeTransfers[transferId] else { return }
        
        let completedTransfer = AirDropTransfer(
            direction: transfer.direction,
            items: transfer.items,
            status: .completed,
            progress: 1.0,
            transferredBytes: transfer.totalBytes,
            transferRate: Double(transfer.totalBytes) / 10.0, // Simulate 10 second transfer
            recipientInfo: transfer.recipientInfo,
            senderInfo: transfer.senderInfo
        )
        
        transferHistory.append(completedTransfer)
        activeTransfers.removeValue(forKey: transferId)
        
        transferStreamContinuation?.yield(completedTransfer)
        
        await updateTransferMetrics(completedTransfer)
        
        if configuration.enableLogging {
            await logTransfer(completedTransfer, action: "Completed")
        }
    }
    
    private func simulateDeviceDiscovery() async {
        // Simulate discovering nearby devices
        let deviceNames = ["John's iPhone", "Sarah's MacBook", "Office iPad", "Lisa's Apple Watch"]
        let deviceTypes: [AirDropDevice.DeviceType] = [.iPhone, .mac, .iPad, .watch]
        
        for (index, name) in deviceNames.enumerated() {
            let device = AirDropDevice(
                name: name,
                deviceType: deviceTypes[index % deviceTypes.count],
                availability: .contactsOnly,
                isContact: index < 2, // First two are contacts
                signalStrength: Double.random(in: 0.3...1.0)
            )
            
            discoveredDevices[device.id] = device
            deviceDiscoveryStreamContinuation?.yield(device)
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
    }
    
    private func shouldAcceptIncomingTransfer(_ transfer: AirDropTransfer) async -> Bool {
        // In a real implementation, this would check user preferences and show prompts
        // For simulation, accept transfers from contacts or small files
        if let senderInfo = transfer.senderInfo {
            return senderInfo.isContact || transfer.totalBytes < 1_000_000 // Accept from contacts or files < 1MB
        }
        return false
    }
    
    private func updateTransferMetrics(_ transfer: AirDropTransfer) async {
        let totalTransfers = metrics.totalTransfers + 1
        let successfulTransfers = metrics.successfulTransfers + (transfer.wasSuccessful ? 1 : 0)
        let failedTransfers = metrics.failedTransfers + (transfer.wasSuccessful ? 0 : 1)
        
        let newTotalBytesSent = metrics.totalBytesSent + (transfer.direction == .sending ? transfer.transferredBytes : 0)
        let newTotalBytesReceived = metrics.totalBytesReceived + (transfer.direction == .receiving ? transfer.transferredBytes : 0)
        
        var transfersByType = metrics.transfersByType
        for item in transfer.items {
            transfersByType[item.typeIdentifier, default: 0] += 1
        }
        
        var deviceConnections = metrics.deviceConnections
        let deviceKey = transfer.recipientInfo?.deviceName ?? transfer.senderInfo?.deviceName ?? "Unknown"
        deviceConnections[deviceKey, default: 0] += 1
        
        let allTransfers = transferHistory + Array(activeTransfers.values)
        let completedTransfers = allTransfers.filter { $0.wasSuccessful }
        
        let averageSpeed = completedTransfers.isEmpty ? 0 : 
            completedTransfers.reduce(0) { $0 + $1.transferRate } / Double(completedTransfers.count)
        
        let averageTime = completedTransfers.isEmpty ? 0 :
            completedTransfers.compactMap { $0.duration }.reduce(0, +) / Double(completedTransfers.count)
        
        metrics = AirDropMetrics(
            totalTransfers: totalTransfers,
            successfulTransfers: successfulTransfers,
            failedTransfers: failedTransfers,
            totalBytesSent: newTotalBytesSent,
            totalBytesReceived: newTotalBytesReceived,
            averageTransferSpeed: averageSpeed,
            averageTransferTime: averageTime,
            transfersByType: transfersByType,
            deviceConnections: deviceConnections,
            errorsByType: metrics.errorsByType,
            successRate: totalTransfers > 0 ? Double(successfulTransfers) / Double(totalTransfers) : 0,
            compressionEfficiency: metrics.compressionEfficiency
        )
    }
    
    private func logTransfer(_ transfer: AirDropTransfer, action: String) async {
        let directionIcon = transfer.direction == .sending ? "📤" : "📥"
        let statusIcon = switch transfer.status {
        case .preparing: "⏳"
        case .waiting: "⏳"
        case .transferring: "🔄"
        case .completed: "✅"
        case .failed: "❌"
        case .cancelled: "🚫"
        case .paused: "⏸️"
        }
        
        let itemCount = transfer.items.count
        let sizeStr = ByteCountFormatter.string(fromByteCount: transfer.totalBytes, countStyle: .file)
        
        print("[AirDrop] \(directionIcon)\(statusIcon) \(action): \(itemCount) item(s), \(sizeStr)")
    }
}

// MARK: - AirDrop Capability Implementation

/// AirDrop capability providing comprehensive peer-to-peer file sharing
public actor AirDropCapability: DomainCapability {
    public typealias ConfigurationType = AirDropCapabilityConfiguration
    public typealias ResourceType = AirDropCapabilityResource
    
    private var _configuration: AirDropCapabilityConfiguration
    private var _resources: AirDropCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "airdrop-capability" }
    
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
    
    public var configuration: AirDropCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: AirDropCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: AirDropCapabilityConfiguration = AirDropCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = AirDropCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: AirDropCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid AirDrop configuration")
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
        // AirDrop is supported on iOS 7+, macOS 10.10+
        return true
    }
    
    public func requestPermission() async throws {
        // AirDrop doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - File Sharing Operations
    
    /// Share multiple items via AirDrop
    public func shareItems(_ items: [AirDropItem]) async throws -> AirDropTransfer {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return try await _resources.shareItems(items)
    }
    
    /// Share a file via AirDrop
    public func shareFile(at url: URL) async throws -> AirDropTransfer {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return try await _resources.shareFile(at: url)
    }
    
    /// Share text via AirDrop
    public func shareText(_ text: String) async throws -> AirDropTransfer {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return try await _resources.shareText(text)
    }
    
    /// Share image via AirDrop
    public func shareImage(_ imageData: Data, name: String = "Image") async throws -> AirDropTransfer {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return try await _resources.shareImage(imageData, name: name)
    }
    
    // MARK: - Transfer Management
    
    /// Get transfer stream
    public func getTransferStream() async throws -> AsyncStream<AirDropTransfer> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.transferStream
    }
    
    /// Get active transfers
    public func getActiveTransfers() async throws -> [AirDropTransfer] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.getActiveTransfers()
    }
    
    /// Get transfer history
    public func getTransferHistory(since: Date? = nil) async throws -> [AirDropTransfer] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.getTransferHistory(since: since)
    }
    
    /// Get specific transfer
    public func getTransfer(by id: UUID) async throws -> AirDropTransfer? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.getTransfer(by: id)
    }
    
    /// Cancel transfer
    public func cancelTransfer(_ transferId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        await _resources.cancelTransfer(transferId)
    }
    
    /// Pause transfer
    public func pauseTransfer(_ transferId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        try await _resources.pauseTransfer(transferId)
    }
    
    /// Resume transfer
    public func resumeTransfer(_ transferId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        try await _resources.resumeTransfer(transferId)
    }
    
    // MARK: - Device Discovery
    
    /// Start device discovery
    public func startDeviceDiscovery() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        await _resources.startDeviceDiscovery()
    }
    
    /// Stop device discovery
    public func stopDeviceDiscovery() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        await _resources.stopDeviceDiscovery()
    }
    
    /// Get device discovery stream
    public func getDeviceDiscoveryStream() async throws -> AsyncStream<AirDropDevice> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.deviceDiscoveryStream
    }
    
    /// Get discovered devices
    public func getDiscoveredDevices() async throws -> [AirDropDevice] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.getDiscoveredDevices()
    }
    
    /// Get specific device
    public func getDevice(by id: UUID) async throws -> AirDropDevice? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.getDevice(by: id)
    }
    
    // MARK: - Receiving Operations
    
    /// Handle incoming transfer
    public func handleIncomingTransfer(_ transfer: AirDropTransfer) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.handleIncomingTransfer(transfer)
    }
    
    /// Accept incoming transfer
    public func acceptIncomingTransfer(_ transferId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        await _resources.acceptIncomingTransfer(transferId)
    }
    
    /// Decline incoming transfer
    public func declineIncomingTransfer(_ transferId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        await _resources.declineIncomingTransfer(transferId)
    }
    
    /// Get AirDrop metrics
    public func getMetrics() async throws -> AirDropMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("AirDrop capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if AirDrop is currently active
    public func isTransferring() async throws -> Bool {
        let activeTransfers = try await getActiveTransfers()
        return !activeTransfers.isEmpty
    }
    
    /// Get total bytes being transferred
    public func getTotalBytesTransferring() async throws -> Int64 {
        let activeTransfers = try await getActiveTransfers()
        return activeTransfers.reduce(0) { $0 + $1.totalBytes }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// AirDrop specific errors
public enum AirDropError: Error, LocalizedError {
    case sendingDisabled
    case receivingDisabled
    case fileTooLarge(Int64, Int64)
    case unsupportedFileType(String)
    case tooManyActiveTransfers(Int)
    case transferNotFound(UUID)
    case invalidTransferState(AirDropTransfer.TransferStatus)
    case deviceNotFound(UUID)
    case deviceNotReachable
    case transferTimeout
    case userCancelled
    case insufficientStorage
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .sendingDisabled:
            return "AirDrop sending is disabled"
        case .receivingDisabled:
            return "AirDrop receiving is disabled"
        case .fileTooLarge(let size, let maxSize):
            let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let maxSizeStr = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
            return "File too large: \(sizeStr) exceeds maximum \(maxSizeStr)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .tooManyActiveTransfers(let maxTransfers):
            return "Too many active transfers (max: \(maxTransfers))"
        case .transferNotFound(let id):
            return "Transfer not found: \(id)"
        case .invalidTransferState(let status):
            return "Invalid transfer state: \(status.rawValue)"
        case .deviceNotFound(let id):
            return "Device not found: \(id)"
        case .deviceNotReachable:
            return "Device not reachable"
        case .transferTimeout:
            return "Transfer timeout"
        case .userCancelled:
            return "Transfer cancelled by user"
        case .insufficientStorage:
            return "Insufficient storage space"
        case .configurationError(let reason):
            return "AirDrop configuration error: \(reason)"
        }
    }
}