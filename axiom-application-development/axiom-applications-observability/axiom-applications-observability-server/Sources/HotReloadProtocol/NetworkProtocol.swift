import Foundation

public protocol HotReloadProtocol {
    func sendMessage(_ message: BaseMessage) async throws
    func receiveMessage() async throws -> BaseMessage
    func registerMessageHandler<T: Codable>(_ messageType: MessageType, handler: @escaping (T) async throws -> Void)
    func close() async throws
}

public struct StateSynchronizationProtocol {
    
    public enum SyncOperation {
        case snapshot
        case restore
        case merge
        case clear
        case diff
    }
    
    public struct StateSnapshot: Codable {
        public let fileName: String
        public let timestamp: String
        public let platform: Platform
        public let stateData: StateContainer
        public let metadata: StateMetadata
        
        public init(fileName: String, platform: Platform, stateData: StateContainer, metadata: StateMetadata) {
            self.fileName = fileName
            self.timestamp = ISO8601DateFormatter().string(from: Date())
            self.platform = platform
            self.stateData = stateData
            self.metadata = metadata
        }
    }
    
    public struct StateContainer: Codable {
        public let swiftUIState: [String: StateValue]?
        public let composeState: [String: ComposeStateValue]?
        public let globalState: [String: AnyCodable]?
        
        public init(swiftUIState: [String: StateValue]? = nil, composeState: [String: ComposeStateValue]? = nil, globalState: [String: AnyCodable]? = nil) {
            self.swiftUIState = swiftUIState
            self.composeState = composeState
            self.globalState = globalState
        }
    }
    
    public struct StateMetadata: Codable {
        public let checksum: String
        public let stateVersion: String
        public let preservationStrategy: PreservationStrategy
        public let stateKeys: [String]
        public let dependencies: [String]
        
        public init(checksum: String, stateVersion: String = "1.0.0", preservationStrategy: PreservationStrategy, stateKeys: [String], dependencies: [String] = []) {
            self.checksum = checksum
            self.stateVersion = stateVersion
            self.preservationStrategy = preservationStrategy
            self.stateKeys = stateKeys
            self.dependencies = dependencies
        }
    }
    
    public enum PreservationStrategy: String, Codable {
        case preserveAll = "preserve_all"
        case preserveMatching = "preserve_matching"
        case clearAll = "clear_all"
        case selective = "selective"
        case fileScope = "file_scope"
    }
    
    public struct StateDiff: Codable {
        public let added: [String: AnyCodable]
        public let modified: [String: StateDiffEntry]
        public let removed: [String]
        
        public init(added: [String: AnyCodable] = [:], modified: [String: StateDiffEntry] = [:], removed: [String] = []) {
            self.added = added
            self.modified = modified
            self.removed = removed
        }
    }
    
    public struct StateDiffEntry: Codable {
        public let oldValue: AnyCodable
        public let newValue: AnyCodable
        public let timestamp: String
        
        public init(oldValue: AnyCodable, newValue: AnyCodable) {
            self.oldValue = oldValue
            self.newValue = newValue
            self.timestamp = ISO8601DateFormatter().string(from: Date())
        }
    }
    
    public static func createSnapshot(for fileName: String, platform: Platform, stateData: StateContainer) -> StateSnapshot {
        let metadata = StateMetadata(
            checksum: generateChecksum(for: stateData),
            preservationStrategy: .fileScope,
            stateKeys: extractStateKeys(from: stateData),
            dependencies: []
        )
        
        return StateSnapshot(
            fileName: fileName,
            platform: platform,
            stateData: stateData,
            metadata: metadata
        )
    }
    
    public static func shouldPreserveState(
        currentFile: String,
        newFile: String,
        strategy: PreservationStrategy
    ) -> Bool {
        switch strategy {
        case .preserveAll:
            return true
        case .clearAll:
            return false
        case .fileScope:
            return currentFile == newFile
        case .preserveMatching, .selective:
            return currentFile == newFile
        }
    }
    
    public static func mergeState(
        existing: StateContainer,
        incoming: StateContainer,
        strategy: PreservationStrategy
    ) -> StateContainer {
        switch strategy {
        case .preserveAll:
            return existing
        case .clearAll:
            return incoming
        case .fileScope, .preserveMatching:
            return StateContainer(
                swiftUIState: mergeStateDictionary(existing: existing.swiftUIState, incoming: incoming.swiftUIState),
                composeState: mergeComposeStateDictionary(existing: existing.composeState, incoming: incoming.composeState),
                globalState: mergeGlobalStateDictionary(existing: existing.globalState, incoming: incoming.globalState)
            )
        case .selective:
            return incoming
        }
    }
    
    private static func mergeStateDictionary(
        existing: [String: StateValue]?,
        incoming: [String: StateValue]?
    ) -> [String: StateValue]? {
        guard let existing = existing else { return incoming }
        guard let incoming = incoming else { return existing }
        
        var merged = existing
        for (key, value) in incoming {
            merged[key] = value
        }
        return merged
    }
    
    private static func mergeComposeStateDictionary(
        existing: [String: ComposeStateValue]?,
        incoming: [String: ComposeStateValue]?
    ) -> [String: ComposeStateValue]? {
        guard let existing = existing else { return incoming }
        guard let incoming = incoming else { return existing }
        
        var merged = existing
        for (key, value) in incoming {
            merged[key] = value
        }
        return merged
    }
    
    private static func mergeGlobalStateDictionary(
        existing: [String: AnyCodable]?,
        incoming: [String: AnyCodable]?
    ) -> [String: AnyCodable]? {
        guard let existing = existing else { return incoming }
        guard let incoming = incoming else { return existing }
        
        var merged = existing
        for (key, value) in incoming {
            merged[key] = value
        }
        return merged
    }
    
    private static func generateChecksum(for stateData: StateContainer) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        guard let data = try? encoder.encode(stateData),
              let string = String(data: data, encoding: .utf8) else {
            return UUID().uuidString
        }
        
        return string.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
    
    private static func extractStateKeys(from stateData: StateContainer) -> [String] {
        var keys: [String] = []
        
        if let swiftUIState = stateData.swiftUIState {
            keys.append(contentsOf: swiftUIState.keys)
        }
        
        if let composeState = stateData.composeState {
            keys.append(contentsOf: composeState.keys)
        }
        
        if let globalState = stateData.globalState {
            keys.append(contentsOf: globalState.keys)
        }
        
        return Array(Set(keys)).sorted()
    }
}

public struct ConnectionProtocol {
    
    public struct HandshakeRequest: Codable {
        public let clientId: String
        public let platform: Platform
        public let version: String
        public let capabilities: [ClientCapability]
        public let deviceInfo: DeviceInfo
        
        public init(clientId: String, platform: Platform, version: String, capabilities: [ClientCapability], deviceInfo: DeviceInfo) {
            self.clientId = clientId
            self.platform = platform
            self.version = version
            self.capabilities = capabilities
            self.deviceInfo = deviceInfo
        }
    }
    
    public struct HandshakeResponse: Codable {
        public let accepted: Bool
        public let serverVersion: String
        public let sessionId: String
        public let supportedCapabilities: [ClientCapability]
        public let heartbeatInterval: TimeInterval
        public let errorMessage: String?
        
        public init(accepted: Bool, serverVersion: String, sessionId: String, supportedCapabilities: [ClientCapability], heartbeatInterval: TimeInterval = 30.0, errorMessage: String? = nil) {
            self.accepted = accepted
            self.serverVersion = serverVersion
            self.sessionId = sessionId
            self.supportedCapabilities = supportedCapabilities
            self.heartbeatInterval = heartbeatInterval
            self.errorMessage = errorMessage
        }
    }
    
    public struct HeartbeatMessage: Codable {
        public let sequence: Int
        public let timestamp: String
        public let serverLoad: Double?
        
        public init(sequence: Int, serverLoad: Double? = nil) {
            self.sequence = sequence
            self.timestamp = ISO8601DateFormatter().string(from: Date())
            self.serverLoad = serverLoad
        }
    }
    
    public struct ReconnectInfo: Codable {
        public let reason: ReconnectReason
        public let retryAfter: TimeInterval
        public let maxRetries: Int
        public let backoffStrategy: BackoffStrategy
        
        public init(reason: ReconnectReason, retryAfter: TimeInterval = 1.0, maxRetries: Int = 5, backoffStrategy: BackoffStrategy = .exponential) {
            self.reason = reason
            self.retryAfter = retryAfter
            self.maxRetries = maxRetries
            self.backoffStrategy = backoffStrategy
        }
    }
    
    public enum ReconnectReason: String, Codable {
        case serverRestart = "server_restart"
        case networkError = "network_error"
        case protocolMismatch = "protocol_mismatch"
        case clientError = "client_error"
        case serverOverload = "server_overload"
        case maintenance = "maintenance"
    }
    
    public enum BackoffStrategy: String, Codable {
        case linear = "linear"
        case exponential = "exponential"
        case fixed = "fixed"
    }
}

public struct FileChangeProtocol {
    
    public struct FileChangeNotification: Codable {
        public let filePath: String
        public let fileName: String
        public let changeType: ChangeType
        public let timestamp: String
        public let checksum: String
        public let metadata: FileMetadata
        
        public init(filePath: String, fileName: String, changeType: ChangeType, checksum: String, metadata: FileMetadata) {
            self.filePath = filePath
            self.fileName = fileName
            self.changeType = changeType
            self.timestamp = ISO8601DateFormatter().string(from: Date())
            self.checksum = checksum
            self.metadata = metadata
        }
    }
    
    public struct FileMetadata: Codable {
        public let fileSize: Int64
        public let lastModified: String
        public let encoding: String
        public let lineCount: Int?
        public let platform: Platform
        
        public init(fileSize: Int64, lastModified: String, encoding: String = "utf-8", lineCount: Int? = nil, platform: Platform) {
            self.fileSize = fileSize
            self.lastModified = lastModified
            self.encoding = encoding
            self.lineCount = lineCount
            self.platform = platform
        }
    }
    
    public struct ContentUpdate: Codable {
        public let content: String
        public let contentType: ContentType
        public let encoding: String
        public let checksum: String
        public let patch: PatchData?
        
        public init(content: String, contentType: ContentType, encoding: String = "utf-8", checksum: String, patch: PatchData? = nil) {
            self.content = content
            self.contentType = contentType
            self.encoding = encoding
            self.checksum = checksum
            self.patch = patch
        }
    }
    
    public enum ContentType: String, Codable {
        case swiftUI = "swiftui"
        case compose = "compose"
        case json = "json"
        case plainText = "plain_text"
    }
    
    public struct PatchData: Codable {
        public let operations: [PatchOperation]
        public let baseChecksum: String
        public let targetChecksum: String
        
        public init(operations: [PatchOperation], baseChecksum: String, targetChecksum: String) {
            self.operations = operations
            self.baseChecksum = baseChecksum
            self.targetChecksum = targetChecksum
        }
    }
    
    public struct PatchOperation: Codable {
        public let type: PatchOperationType
        public let line: Int
        public let content: String
        public let length: Int?
        
        public init(type: PatchOperationType, line: Int, content: String, length: Int? = nil) {
            self.type = type
            self.line = line
            self.content = content
            self.length = length
        }
    }
    
    public enum PatchOperationType: String, Codable {
        case insert = "insert"
        case delete = "delete"
        case replace = "replace"
        case move = "move"
    }
}

public struct ErrorRecoveryProtocol {
    
    public struct ErrorReport: Codable {
        public let errorId: String
        public let errorType: ErrorType
        public let severity: ErrorSeverity
        public let message: String
        public let context: ErrorContext
        public let timestamp: String
        public let recoveryAction: RecoveryAction?
        
        public init(errorType: ErrorType, severity: ErrorSeverity, message: String, context: ErrorContext, recoveryAction: RecoveryAction? = nil) {
            self.errorId = UUID().uuidString
            self.errorType = errorType
            self.severity = severity
            self.message = message
            self.context = context
            self.timestamp = ISO8601DateFormatter().string(from: Date())
            self.recoveryAction = recoveryAction
        }
    }
    
    public enum ErrorSeverity: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public struct ErrorContext: Codable {
        public let fileName: String?
        public let lineNumber: Int?
        public let platform: Platform?
        public let operation: String?
        public let additionalInfo: [String: AnyCodable]?
        
        public init(fileName: String? = nil, lineNumber: Int? = nil, platform: Platform? = nil, operation: String? = nil, additionalInfo: [String: AnyCodable]? = nil) {
            self.fileName = fileName
            self.lineNumber = lineNumber
            self.platform = platform
            self.operation = operation
            self.additionalInfo = additionalInfo
        }
    }
    
    public struct RecoveryAction: Codable {
        public let action: RecoveryActionType
        public let description: String
        public let automatic: Bool
        public let parameters: [String: AnyCodable]?
        
        public init(action: RecoveryActionType, description: String, automatic: Bool = false, parameters: [String: AnyCodable]? = nil) {
            self.action = action
            self.description = description
            self.automatic = automatic
            self.parameters = parameters
        }
    }
    
    public enum RecoveryActionType: String, Codable {
        case retry = "retry"
        case fallback = "fallback"
        case reset = "reset"
        case restart = "restart"
        case ignore = "ignore"
        case manual = "manual"
    }
}