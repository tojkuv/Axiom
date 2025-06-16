import Foundation
import HotReloadProtocol

public protocol MessageHandlerDelegate: AnyObject {
    func messageHandler(_ handler: MessageHandler, didProcessMessage message: BaseMessage)
    func messageHandler(_ handler: MessageHandler, didFailToProcessMessage error: Error)
}

public final class MessageHandler {
    
    public weak var delegate: MessageHandlerDelegate?
    
    private let configuration: MessageHandlerConfiguration
    private var messageQueue: [BaseMessage] = []
    private let processingQueue = DispatchQueue(label: "com.axiom.messagehandler", qos: .userInitiated)
    
    public init(configuration: MessageHandlerConfiguration = MessageHandlerConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Message Processing
    
    public func handleMessage(_ message: BaseMessage) {
        processingQueue.async { [weak self] in
            self?.processMessage(message)
        }
    }
    
    private func processMessage(_ message: BaseMessage) {
        do {
            // Validate message
            try validateMessage(message)
            
            // Add to queue if enabled
            if configuration.enableMessageQueue {
                addToQueue(message)
            }
            
            // Process based on message type
            try processMessageByType(message)
            
            // Notify delegate of successful processing
            DispatchQueue.main.async {
                self.delegate?.messageHandler(self, didProcessMessage: message)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.delegate?.messageHandler(self, didFailToProcessMessage: error)
            }
        }
    }
    
    private func validateMessage(_ message: BaseMessage) throws {
        // Basic validation
        if message.messageId.isEmpty {
            throw MessageHandlerError.invalidMessage("Message ID is empty")
        }
        
        if message.version.isEmpty {
            throw MessageHandlerError.invalidMessage("Message version is empty")
        }
        
        // Validate timestamp
        let formatter = ISO8601DateFormatter()
        if formatter.date(from: message.timestamp) == nil {
            throw MessageHandlerError.invalidMessage("Invalid timestamp format")
        }
        
        // Type-specific validation
        try validateMessagePayload(message)
    }
    
    private func validateMessagePayload(_ message: BaseMessage) throws {
        switch message.payload {
        case .fileChanged(let payload):
            try validateFileChangedPayload(payload)
        case .stateSync(let payload):
            try validateStateSyncPayload(payload)
        case .error(let payload):
            try validateErrorPayload(payload)
        default:
            // Other message types are valid by default
            break
        }
    }
    
    private func validateFileChangedPayload(_ payload: FileChangedPayload) throws {
        if payload.fileName.isEmpty {
            throw MessageHandlerError.invalidPayload("File name is empty")
        }
        
        if payload.filePath.isEmpty {
            throw MessageHandlerError.invalidPayload("File path is empty")
        }
        
        if payload.checksum.isEmpty {
            throw MessageHandlerError.invalidPayload("Checksum is empty")
        }
        
        // Validate JSON content for SwiftUI files
        if payload.fileName.hasSuffix(".swift") {
            try validateSwiftUIContent(payload.fileContent)
        }
    }
    
    private func validateStateSyncPayload(_ payload: StateSyncPayload) throws {
        if payload.fileName.isEmpty {
            throw MessageHandlerError.invalidPayload("State sync file name is empty")
        }
        
        if payload.stateData.isEmpty && payload.operation != .clear {
            throw MessageHandlerError.invalidPayload("State data is empty for non-clear operation")
        }
    }
    
    private func validateErrorPayload(_ payload: ErrorPayload) throws {
        if payload.errorCode.isEmpty {
            throw MessageHandlerError.invalidPayload("Error code is empty")
        }
        
        if payload.errorMessage.isEmpty {
            throw MessageHandlerError.invalidPayload("Error message is empty")
        }
    }
    
    private func validateSwiftUIContent(_ content: String) throws {
        // Attempt to parse as SwiftUI JSON
        do {
            let data = content.data(using: .utf8) ?? Data()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            _ = try decoder.decode(SwiftUILayoutJSON.self, from: data)
        } catch {
            throw MessageHandlerError.invalidSwiftUIContent("Failed to parse SwiftUI JSON: \(error.localizedDescription)")
        }
    }
    
    private func processMessageByType(_ message: BaseMessage) throws {
        switch message.type {
        case .fileChanged:
            try processFileChangedMessage(message)
        case .stateSync:
            try processStateSyncMessage(message)
        case .previewSwitch:
            try processPreviewSwitchMessage(message)
        case .error:
            try processErrorMessage(message)
        case .connectionStatus:
            try processConnectionStatusMessage(message)
        case .capabilityNegotiation:
            try processCapabilityNegotiationMessage(message)
        case .ping, .pong:
            try processHeartbeatMessage(message)
        case .clientRegister:
            // Client register responses don't need special processing
            break
        }
    }
    
    private func processFileChangedMessage(_ message: BaseMessage) throws {
        guard case .fileChanged(let payload) = message.payload else {
            throw MessageHandlerError.payloadMismatch("Expected fileChanged payload")
        }
        
        // Extract SwiftUI JSON if it's a Swift file
        if payload.fileName.hasSuffix(".swift") {
            let swiftUILayout = try extractSwiftUILayout(from: payload.fileContent)
            
            // Store for potential state preservation
            if configuration.enableStatePreservation {
                storeLayoutForStatePreservation(swiftUILayout, fileName: payload.fileName)
            }
        }
        
        // Log processing if enabled
        if configuration.enableDebugLogging {
            print("📱 Processed file change: \(payload.fileName) (\(payload.changeType.rawValue))")
        }
    }
    
    private func processStateSyncMessage(_ message: BaseMessage) throws {
        guard case .stateSync(let payload) = message.payload else {
            throw MessageHandlerError.payloadMismatch("Expected stateSync payload")
        }
        
        // Handle state operations
        switch payload.operation {
        case .preserve:
            preserveState(payload.stateData, for: payload.fileName)
        case .restore:
            try restoreState(for: payload.fileName)
        case .clear:
            clearState(for: payload.fileName)
        case .sync:
            syncState(payload.stateData, for: payload.fileName)
        }
        
        if configuration.enableDebugLogging {
            print("📱 Processed state sync: \(payload.fileName) (\(payload.operation.rawValue))")
        }
    }
    
    private func processPreviewSwitchMessage(_ message: BaseMessage) throws {
        guard case .previewSwitch(let payload) = message.payload else {
            throw MessageHandlerError.payloadMismatch("Expected previewSwitch payload")
        }
        
        // Handle preview switching logic
        if payload.preserveState && configuration.enableStatePreservation {
            // Preserve current state before switching
            preserveCurrentState()
        }
        
        if configuration.enableDebugLogging {
            print("📱 Processed preview switch: \(payload.targetFile)")
        }
    }
    
    private func processErrorMessage(_ message: BaseMessage) throws {
        guard case .error(let payload) = message.payload else {
            throw MessageHandlerError.payloadMismatch("Expected error payload")
        }
        
        // Log error
        print("❌ Server error [\(payload.errorCode)]: \(payload.errorMessage)")
        
        // Handle recoverable errors
        if payload.recoverable {
            // Implement recovery logic based on error type
            handleRecoverableError(payload)
        }
    }
    
    private func processConnectionStatusMessage(_ message: BaseMessage) throws {
        guard case .connectionStatus(let payload) = message.payload else {
            throw MessageHandlerError.payloadMismatch("Expected connectionStatus payload")
        }
        
        if configuration.enableDebugLogging {
            print("📱 Connection status: \(payload.status.rawValue) (\(payload.clientCount) clients)")
        }
    }
    
    private func processCapabilityNegotiationMessage(_ message: BaseMessage) throws {
        guard case .capabilityNegotiation(let payload) = message.payload else {
            throw MessageHandlerError.payloadMismatch("Expected capabilityNegotiation payload")
        }
        
        if configuration.enableDebugLogging {
            print("📱 Server capabilities: \(payload.supportedCapabilities.map { $0.name }.joined(separator: ", "))")
        }
    }
    
    private func processHeartbeatMessage(_ message: BaseMessage) throws {
        // Heartbeat messages are processed but don't require special handling
        if configuration.enableDebugLogging && message.type == .ping {
            print("💓 Received ping")
        }
    }
    
    // MARK: - SwiftUI Processing
    
    private func extractSwiftUILayout(from content: String) throws -> SwiftUILayoutJSON {
        let data = content.data(using: .utf8) ?? Data()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(SwiftUILayoutJSON.self, from: data)
    }
    
    // MARK: - State Management
    
    private var stateStorage: [String: [String: AnyCodable]] = [:]
    private var layoutStorage: [String: SwiftUILayoutJSON] = [:]
    
    private func preserveState(_ stateData: [String: AnyCodable], for fileName: String) {
        stateStorage[fileName] = stateData
    }
    
    private func restoreState(for fileName: String) throws {
        guard let state = stateStorage[fileName] else {
            throw MessageHandlerError.stateNotFound("No preserved state found for \(fileName)")
        }
        
        // State restoration would be handled by the SwiftUI renderer
        if configuration.enableDebugLogging {
            print("📱 Restored state for \(fileName): \(state.keys.joined(separator: ", "))")
        }
    }
    
    private func clearState(for fileName: String) {
        stateStorage.removeValue(forKey: fileName)
        layoutStorage.removeValue(forKey: fileName)
    }
    
    private func syncState(_ stateData: [String: AnyCodable], for fileName: String) {
        // Merge with existing state
        var existingState = stateStorage[fileName] ?? [:]
        for (key, value) in stateData {
            existingState[key] = value
        }
        stateStorage[fileName] = existingState
    }
    
    private func preserveCurrentState() {
        // This would be implemented to capture current SwiftUI state
        // For now, just log the action
        if configuration.enableDebugLogging {
            print("📱 Preserving current state before preview switch")
        }
    }
    
    private func storeLayoutForStatePreservation(_ layout: SwiftUILayoutJSON, fileName: String) {
        layoutStorage[fileName] = layout
    }
    
    // MARK: - Queue Management
    
    private func addToQueue(_ message: BaseMessage) {
        // Keep queue size manageable
        if messageQueue.count >= configuration.maxQueueSize {
            messageQueue.removeFirst()
        }
        
        messageQueue.append(message)
    }
    
    // MARK: - Error Recovery
    
    private func handleRecoverableError(_ payload: ErrorPayload) {
        switch payload.errorType {
        case .parsing:
            // Could request a simplified version of the content
            break
        case .network:
            // Network errors are usually handled by the connection manager
            break
        case .state:
            // Could reset state and try again
            break
        default:
            break
        }
    }
    
    // MARK: - Public Utilities
    
    public func getMessageHistory() -> [BaseMessage] {
        return processingQueue.sync {
            return Array(messageQueue)
        }
    }
    
    public func clearMessageHistory() {
        processingQueue.async {
            self.messageQueue.removeAll()
        }
    }
    
    public func getStoredState(for fileName: String) -> [String: AnyCodable]? {
        return stateStorage[fileName]
    }
    
    public func getStoredLayout(for fileName: String) -> SwiftUILayoutJSON? {
        return layoutStorage[fileName]
    }
}

// MARK: - Configuration

public struct MessageHandlerConfiguration {
    public let enableMessageQueue: Bool
    public let maxQueueSize: Int
    public let enableStatePreservation: Bool
    public let enableDebugLogging: Bool
    public let validateIncomingMessages: Bool
    public let enableErrorRecovery: Bool
    
    public init(
        enableMessageQueue: Bool = true,
        maxQueueSize: Int = 100,
        enableStatePreservation: Bool = true,
        enableDebugLogging: Bool = false,
        validateIncomingMessages: Bool = true,
        enableErrorRecovery: Bool = true
    ) {
        self.enableMessageQueue = enableMessageQueue
        self.maxQueueSize = maxQueueSize
        self.enableStatePreservation = enableStatePreservation
        self.enableDebugLogging = enableDebugLogging
        self.validateIncomingMessages = validateIncomingMessages
        self.enableErrorRecovery = enableErrorRecovery
    }
    
    public static func development() -> MessageHandlerConfiguration {
        return MessageHandlerConfiguration(
            enableDebugLogging: true,
            validateIncomingMessages: true
        )
    }
    
    public static func production() -> MessageHandlerConfiguration {
        return MessageHandlerConfiguration(
            enableDebugLogging: false,
            validateIncomingMessages: false
        )
    }
}

// MARK: - Errors

public enum MessageHandlerError: Error, LocalizedError {
    case invalidMessage(String)
    case invalidPayload(String)
    case payloadMismatch(String)
    case invalidSwiftUIContent(String)
    case stateNotFound(String)
    case processingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidMessage(let details):
            return "Invalid message: \(details)"
        case .invalidPayload(let details):
            return "Invalid payload: \(details)"
        case .payloadMismatch(let details):
            return "Payload mismatch: \(details)"
        case .invalidSwiftUIContent(let details):
            return "Invalid SwiftUI content: \(details)"
        case .stateNotFound(let details):
            return "State not found: \(details)"
        case .processingFailed(let details):
            return "Message processing failed: \(details)"
        }
    }
}