import Foundation

public struct SwiftUIViewJSON: Codable {
    public let type: String
    public let properties: [String: SwiftUIPropertyValue]?
    public let children: [SwiftUIViewJSON]?
    public let modifiers: [SwiftUIModifierJSON]?
    
    public init(
        type: String,
        properties: [String: SwiftUIPropertyValue]? = nil,
        children: [SwiftUIViewJSON]? = nil,
        modifiers: [SwiftUIModifierJSON]? = nil
    ) {
        self.type = type
        self.properties = properties
        self.children = children
        self.modifiers = modifiers
    }
}

public enum SwiftUIPropertyValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([String])
    case binding(String)
    case action(String)
    case color(String)
}

public struct SwiftUIModifierJSON: Codable {
    public let name: String
    public let parameters: [String: SwiftUIPropertyValue]
    
    public init(name: String, parameters: [String: SwiftUIPropertyValue]) {
        self.name = name
        self.parameters = parameters
    }
}

public struct ComposeComponentJSON: Codable {
    public let type: String
    public let parameters: [String: ComposeParameterValue]?
    public let children: [ComposeComponentJSON]?
    public let modifiers: [ComposeModifierJSON]?
    
    public init(
        type: String,
        parameters: [String: ComposeParameterValue]? = nil,
        children: [ComposeComponentJSON]? = nil,
        modifiers: [ComposeModifierJSON]? = nil
    ) {
        self.type = type
        self.parameters = parameters
        self.children = children
        self.modifiers = modifiers
    }
}

public enum ComposeParameterValue: Codable {
    case string(String)
    case arrangement(ComposeArrangementValue)
    case padding(ComposePaddingValue)
}

public struct ComposeArrangementValue: Codable {
    public let type: String
    public let spacing: ComposeDpValue?
    
    public init(type: String, spacing: ComposeDpValue? = nil) {
        self.type = type
        self.spacing = spacing
    }
}

public struct ComposeDpValue: Codable {
    public let value: Int
    
    public init(value: Int) {
        self.value = value
    }
}

public struct ComposePaddingValue: Codable {
    public let all: ComposeDpValue?
    
    public init(all: ComposeDpValue? = nil) {
        self.all = all
    }
}

public struct ComposeModifierJSON: Codable {
    public let name: String
    public let parameters: [String: ComposeParameterValue]
    
    public init(name: String, parameters: [String: ComposeParameterValue]) {
        self.name = name
        self.parameters = parameters
    }
}

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else {
            value = "unknown"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else {
            try container.encode("unknown")
        }
    }
}

public struct StateSynchronizationProtocol {
    public struct StateContainer: Codable {
        public let swiftUIState: [String: SwiftUIPropertyValue]?
        public let composeState: [String: ComposeParameterValue]?
        public let globalState: [String: AnyCodable]?
        
        public init(
            swiftUIState: [String: SwiftUIPropertyValue]? = nil,
            composeState: [String: ComposeParameterValue]? = nil,
            globalState: [String: AnyCodable]? = nil
        ) {
            self.swiftUIState = swiftUIState
            self.composeState = composeState
            self.globalState = globalState
        }
    }
    
    public struct StateSnapshot: Codable {
        public let fileName: String
        public let platform: Platform
        public let metadata: StateMetadata
        public let stateData: StateContainer
        
        public init(fileName: String, platform: Platform, metadata: StateMetadata, stateData: StateContainer) {
            self.fileName = fileName
            self.platform = platform
            self.metadata = metadata
            self.stateData = stateData
        }
    }
    
    public struct StateMetadata: Codable {
        public let preservationStrategy: PreservationStrategy
        public let timestamp: Date
        
        public init(preservationStrategy: PreservationStrategy) {
            self.preservationStrategy = preservationStrategy
            self.timestamp = Date()
        }
    }
    
    public enum PreservationStrategy: String, Codable {
        case fileScope = "file_scope"
        case globalScope = "global_scope"
    }
    
    public static func createSnapshot(
        for fileName: String,
        platform: Platform,
        stateData: StateContainer
    ) -> StateSnapshot {
        return StateSnapshot(
            fileName: fileName,
            platform: platform,
            metadata: StateMetadata(preservationStrategy: .fileScope),
            stateData: stateData
        )
    }
    
    public static func mergeState(
        existing: StateContainer,
        incoming: StateContainer,
        strategy: PreservationStrategy
    ) -> StateContainer {
        return StateContainer(
            swiftUIState: incoming.swiftUIState ?? existing.swiftUIState,
            composeState: incoming.composeState ?? existing.composeState,
            globalState: incoming.globalState ?? existing.globalState
        )
    }
}