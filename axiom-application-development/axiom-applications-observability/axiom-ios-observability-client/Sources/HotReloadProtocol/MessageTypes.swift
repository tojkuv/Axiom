import Foundation

public enum MessageType: String, Codable, CaseIterable {
    case fileChanged = "file_changed"
    case previewSwitch = "preview_switch"
    case stateSync = "state_sync"
    case clientRegister = "client_register"
    case ping = "ping"
    case pong = "pong"
    case error = "error"
    case connectionStatus = "connection_status"
    case capabilityNegotiation = "capability_negotiation"
    case metadata = "metadata"
}

public enum Platform: String, Codable, CaseIterable {
    case ios = "ios"
    case android = "android"
}

public struct BaseMessage: Codable {
    public let type: MessageType
    public let timestamp: String
    public let messageId: String
    public let clientId: String?
    public let platform: Platform?
    public let version: String
    public let payload: MessagePayload
    
    public init(
        type: MessageType,
        timestamp: String = ISO8601DateFormatter().string(from: Date()),
        messageId: String = UUID().uuidString,
        clientId: String? = nil,
        platform: Platform? = nil,
        version: String = "1.0.0",
        payload: MessagePayload
    ) {
        self.type = type
        self.timestamp = timestamp
        self.messageId = messageId
        self.clientId = clientId
        self.platform = platform
        self.version = version
        self.payload = payload
    }
}

public enum MessagePayload: Codable {
    case fileChanged(FileChangedPayload)
    case previewSwitch(PreviewSwitchPayload)
    case stateSync(StateSyncPayload)
    case clientRegister(ClientRegisterPayload)
    case ping(PingPayload)
    case pong(PongPayload)
    case error(ErrorPayload)
    case connectionStatus(ConnectionStatusPayload)
    case capabilityNegotiation(CapabilityNegotiationPayload)
    case metadata(MetadataPayload)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(FileChangedPayload.self) {
            self = .fileChanged(value)
        } else if let value = try? container.decode(PreviewSwitchPayload.self) {
            self = .previewSwitch(value)
        } else if let value = try? container.decode(StateSyncPayload.self) {
            self = .stateSync(value)
        } else if let value = try? container.decode(ClientRegisterPayload.self) {
            self = .clientRegister(value)
        } else if let value = try? container.decode(PingPayload.self) {
            self = .ping(value)
        } else if let value = try? container.decode(PongPayload.self) {
            self = .pong(value)
        } else if let value = try? container.decode(ErrorPayload.self) {
            self = .error(value)
        } else if let value = try? container.decode(ConnectionStatusPayload.self) {
            self = .connectionStatus(value)
        } else if let value = try? container.decode(CapabilityNegotiationPayload.self) {
            self = .capabilityNegotiation(value)
        } else if let value = try? container.decode(MetadataPayload.self) {
            self = .metadata(value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode MessagePayload"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .fileChanged(let payload):
            try container.encode(payload)
        case .previewSwitch(let payload):
            try container.encode(payload)
        case .stateSync(let payload):
            try container.encode(payload)
        case .clientRegister(let payload):
            try container.encode(payload)
        case .ping(let payload):
            try container.encode(payload)
        case .pong(let payload):
            try container.encode(payload)
        case .error(let payload):
            try container.encode(payload)
        case .connectionStatus(let payload):
            try container.encode(payload)
        case .capabilityNegotiation(let payload):
            try container.encode(payload)
        case .metadata(let payload):
            try container.encode(payload)
        }
    }
}

public struct FileChangedPayload: Codable {
    public let filePath: String
    public let fileName: String
    public let fileContent: String
    public let changeType: ChangeType
    public let checksum: String
    
    public init(filePath: String, fileName: String, fileContent: String, changeType: ChangeType, checksum: String) {
        self.filePath = filePath
        self.fileName = fileName
        self.fileContent = fileContent
        self.changeType = changeType
        self.checksum = checksum
    }
}

public enum ChangeType: String, Codable {
    case created = "created"
    case modified = "modified"
    case deleted = "deleted"
    case renamed = "renamed"
}

public struct PreviewSwitchPayload: Codable {
    public let targetFile: String
    public let preserveState: Bool
    
    public init(targetFile: String, preserveState: Bool = true) {
        self.targetFile = targetFile
        self.preserveState = preserveState
    }
}

public struct StateSyncPayload: Codable {
    public let stateData: [String: AnyCodable]
    public let fileName: String
    public let operation: StateOperation
    
    public init(stateData: [String: AnyCodable], fileName: String, operation: StateOperation) {
        self.stateData = stateData
        self.fileName = fileName
        self.operation = operation
    }
}

public enum StateOperation: String, Codable {
    case preserve = "preserve"
    case restore = "restore"
    case clear = "clear"
    case sync = "sync"
}

public struct ClientRegisterPayload: Codable {
    public let platform: Platform
    public let clientName: String
    public let capabilities: [ClientCapability]
    public let deviceInfo: DeviceInfo
    
    public init(platform: Platform, clientName: String, capabilities: [ClientCapability], deviceInfo: DeviceInfo) {
        self.platform = platform
        self.clientName = clientName
        self.capabilities = capabilities
        self.deviceInfo = deviceInfo
    }
}

public struct ClientCapability: Codable {
    public let name: String
    public let version: String
    public let enabled: Bool
    
    public init(name: String, version: String, enabled: Bool = true) {
        self.name = name
        self.version = version
        self.enabled = enabled
    }
}

public struct DeviceInfo: Codable {
    public let deviceModel: String
    public let osVersion: String
    public let screenSize: ScreenSize?
    public let deviceId: String
    
    public init(deviceModel: String, osVersion: String, screenSize: ScreenSize? = nil, deviceId: String) {
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.screenSize = screenSize
        self.deviceId = deviceId
    }
}

public struct ScreenSize: Codable {
    public let width: Double
    public let height: Double
    public let scale: Double
    
    public init(width: Double, height: Double, scale: Double = 1.0) {
        self.width = width
        self.height = height
        self.scale = scale
    }
}

public struct PingPayload: Codable {
    public let sequence: Int
    
    public init(sequence: Int = 0) {
        self.sequence = sequence
    }
}

public struct PongPayload: Codable {
    public let sequence: Int
    public let serverTimestamp: String
    
    public init(sequence: Int, serverTimestamp: String = ISO8601DateFormatter().string(from: Date())) {
        self.sequence = sequence
        self.serverTimestamp = serverTimestamp
    }
}

public struct ErrorPayload: Codable {
    public let errorCode: String
    public let errorMessage: String
    public let errorType: ErrorType
    public let recoverable: Bool
    public let context: [String: AnyCodable]?
    
    public init(errorCode: String, errorMessage: String, errorType: ErrorType, recoverable: Bool = true, context: [String: AnyCodable]? = nil) {
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.errorType = errorType
        self.recoverable = recoverable
        self.context = context
    }
}

public enum ErrorType: String, Codable {
    case parsing = "parsing"
    case network = "network"
    case file = "file"
    case state = "state"
    case client = "client"
    case server = "server"
    case protocolError = "protocol"
}

public struct ConnectionStatusPayload: Codable {
    public let status: ConnectionStatus
    public let clientCount: Int
    public let serverLoad: Double?
    
    public init(status: ConnectionStatus, clientCount: Int, serverLoad: Double? = nil) {
        self.status = status
        self.clientCount = clientCount
        self.serverLoad = serverLoad
    }
}

public enum ConnectionStatus: String, Codable {
    case connected = "connected"
    case disconnected = "disconnected"
    case reconnecting = "reconnecting"
    case error = "error"
}

public struct CapabilityNegotiationPayload: Codable {
    public let supportedCapabilities: [ClientCapability]
    public let recommendedSettings: [String: AnyCodable]
    
    public init(supportedCapabilities: [ClientCapability], recommendedSettings: [String: AnyCodable] = [:]) {
        self.supportedCapabilities = supportedCapabilities
        self.recommendedSettings = recommendedSettings
    }
}

public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.init(())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "AnyCodable value cannot be decoded"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Metadata Payload

public struct MetadataPayload: Codable {
    public let timestamp: Date
    public let contextHierarchy: [MetadataContextInfo]
    public let presentationBindings: [MetadataPresentationBinding]
    public let clientMetrics: [MetadataClientMetric]
    
    public init(timestamp: Date, contextHierarchy: [MetadataContextInfo], presentationBindings: [MetadataPresentationBinding], clientMetrics: [MetadataClientMetric]) {
        self.timestamp = timestamp
        self.contextHierarchy = contextHierarchy
        self.presentationBindings = presentationBindings
        self.clientMetrics = clientMetrics
    }
}

public struct MetadataContextInfo: Codable {
    public let id: String
    public let name: String
    public let parentId: String?
    public let properties: [String: String]
    public let performanceMetrics: MetadataPerformanceMetrics
    
    public init(id: String, name: String, parentId: String?, properties: [String: String], performanceMetrics: MetadataPerformanceMetrics) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.properties = properties
        self.performanceMetrics = performanceMetrics
    }
}

public struct MetadataPerformanceMetrics: Codable {
    public let updateCount: Int
    public let averageUpdateTime: Double
    
    public init(updateCount: Int, averageUpdateTime: Double) {
        self.updateCount = updateCount
        self.averageUpdateTime = averageUpdateTime
    }
}

public struct MetadataPresentationBinding: Codable {
    public let contextId: String
    public let presentationId: String
    public let bindingType: String
    public let isValid: Bool
    
    public init(contextId: String, presentationId: String, bindingType: String, isValid: Bool) {
        self.contextId = contextId
        self.presentationId = presentationId
        self.bindingType = bindingType
        self.isValid = isValid
    }
}

public struct MetadataClientMetric: Codable {
    public let name: String
    public let value: Double
    public let unit: String
    public let timestamp: Date
    
    public init(name: String, value: Double, unit: String, timestamp: Date) {
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}