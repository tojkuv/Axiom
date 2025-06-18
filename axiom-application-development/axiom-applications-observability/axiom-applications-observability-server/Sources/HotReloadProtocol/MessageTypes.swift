import Foundation
import Crypto

public struct BaseMessage: Codable {
    public let type: MessageType
    public let platform: Platform
    public let payload: MessagePayload
    public let version: String
    
    public init(type: MessageType, platform: Platform, payload: MessagePayload) {
        self.type = type
        self.platform = platform
        self.payload = payload
        self.version = "1.0.0"
    }
}

public enum MessageType: String, Codable {
    case fileChanged = "file_changed"
    case stateSync = "state_sync"
    case error = "error"
}

public enum Platform: String, Codable {
    case ios = "ios"
    case android = "android"
}

public enum MessagePayload: Codable {
    case fileChanged(FileChangedPayload)
    case stateSync(StateSyncPayload)
    case error(ErrorPayload)
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
    case added = "added"
    case modified = "modified"
    case deleted = "deleted"
}

public struct StateSyncPayload: Codable {
    public let state: [String: String]
}

public struct ErrorPayload: Codable {
    public let message: String
    public let code: String
}