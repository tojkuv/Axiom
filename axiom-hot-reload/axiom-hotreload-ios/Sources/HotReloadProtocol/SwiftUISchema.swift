import Foundation

public struct SwiftUIViewJSON: Codable {
    public let type: String
    public let id: String
    public let properties: [String: PropertyValue]
    public let children: [SwiftUIViewJSON]?
    public let modifiers: [SwiftUIModifierJSON]?
    public let state: [String: StateValue]?
    
    public init(
        type: String,
        id: String = UUID().uuidString,
        properties: [String: PropertyValue] = [:],
        children: [SwiftUIViewJSON]? = nil,
        modifiers: [SwiftUIModifierJSON]? = nil,
        state: [String: StateValue]? = nil
    ) {
        self.type = type
        self.id = id
        self.properties = properties
        self.children = children
        self.modifiers = modifiers
        self.state = state
    }
}

public struct SwiftUIModifierJSON: Codable {
    public let name: String
    public let parameters: [String: PropertyValue]
    
    public init(name: String, parameters: [String: PropertyValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

public indirect enum PropertyValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case color(ColorValue)
    case font(FontValue)
    case edge(EdgeValue)
    case alignment(AlignmentValue)
    case array([PropertyValue])
    case binding(BindingValue)
    case action(ActionValue)
    case image(ImageValue)
    case nullValue
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .nullValue
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(ColorValue.self) {
            self = .color(value)
        } else if let value = try? container.decode(FontValue.self) {
            self = .font(value)
        } else if let value = try? container.decode(EdgeValue.self) {
            self = .edge(value)
        } else if let value = try? container.decode(AlignmentValue.self) {
            self = .alignment(value)
        } else if let value = try? container.decode([PropertyValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(BindingValue.self) {
            self = .binding(value)
        } else if let value = try? container.decode(ActionValue.self) {
            self = .action(value)
        } else if let value = try? container.decode(ImageValue.self) {
            self = .image(value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode PropertyValue"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .color(let value):
            try container.encode(value)
        case .font(let value):
            try container.encode(value)
        case .edge(let value):
            try container.encode(value)
        case .alignment(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .binding(let value):
            try container.encode(value)
        case .action(let value):
            try container.encode(value)
        case .image(let value):
            try container.encode(value)
        case .nullValue:
            try container.encodeNil()
        }
    }
}

public struct ColorValue: Codable {
    public let type: ColorType
    public let red: Double?
    public let green: Double?
    public let blue: Double?
    public let alpha: Double?
    public let systemColor: String?
    
    public init(type: ColorType, red: Double? = nil, green: Double? = nil, blue: Double? = nil, alpha: Double? = 1.0, systemColor: String? = nil) {
        self.type = type
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.systemColor = systemColor
    }
}

public enum ColorType: String, Codable {
    case rgb = "rgb"
    case system = "system"
    case custom = "custom"
}

public struct FontValue: Codable {
    public let name: String?
    public let size: Double
    public let weight: String?
    public let design: String?
    public let style: String?
    
    public init(name: String? = nil, size: Double, weight: String? = nil, design: String? = nil, style: String? = nil) {
        self.name = name
        self.size = size
        self.weight = weight
        self.design = design
        self.style = style
    }
}

public struct EdgeValue: Codable {
    public let top: Double?
    public let leading: Double?
    public let bottom: Double?
    public let trailing: Double?
    public let all: Double?
    
    public init(top: Double? = nil, leading: Double? = nil, bottom: Double? = nil, trailing: Double? = nil, all: Double? = nil) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
        self.all = all
    }
}

public struct AlignmentValue: Codable {
    public let horizontal: String
    public let vertical: String
    
    public init(horizontal: String = "center", vertical: String = "center") {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

public struct BindingValue: Codable {
    public let stateKey: String
    public let defaultValue: PropertyValue
    public let type: String
    
    public init(stateKey: String, defaultValue: PropertyValue, type: String) {
        self.stateKey = stateKey
        self.defaultValue = defaultValue
        self.type = type
    }
}

public struct ActionValue: Codable {
    public let type: ActionType
    public let target: String?
    public let parameters: [String: PropertyValue]?
    
    public init(type: ActionType, target: String? = nil, parameters: [String: PropertyValue]? = nil) {
        self.type = type
        self.target = target
        self.parameters = parameters
    }
}

public enum ActionType: String, Codable {
    case tap = "tap"
    case longPress = "longPress"
    case gesture = "gesture"
    case navigation = "navigation"
    case state = "state"
    case custom = "custom"
}

public struct ImageValue: Codable {
    public let type: ImageType
    public let name: String?
    public let systemName: String?
    public let url: String?
    public let data: String?
    
    public init(type: ImageType, name: String? = nil, systemName: String? = nil, url: String? = nil, data: String? = nil) {
        self.type = type
        self.name = name
        self.systemName = systemName
        self.url = url
        self.data = data
    }
}

public enum ImageType: String, Codable {
    case asset = "asset"
    case system = "system"
    case url = "url"
    case data = "data"
}

public enum StateValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([StateValue])
    case dictionary([String: StateValue])
    case nullValue
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .nullValue
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([StateValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: StateValue].self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode StateValue"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .nullValue:
            try container.encodeNil()
        }
    }
}

public struct SwiftUIViewRegistry {
    public static let supportedViews: [String] = [
        "Text",
        "VStack",
        "HStack",
        "ZStack",
        "Button",
        "Image",
        "TextField",
        "SecureField",
        "Toggle",
        "Slider",
        "Stepper",
        "Picker",
        "DatePicker",
        "ColorPicker",
        "ProgressView",
        "Link",
        "Label",
        "GroupBox",
        "DisclosureGroup",
        "List",
        "ForEach",
        "LazyVStack",
        "LazyHStack",
        "ScrollView",
        "TabView",
        "NavigationView",
        "NavigationStack",
        "Sheet",
        "Alert",
        "ActionSheet",
        "Popover",
        "ContextMenu",
        "Rectangle",
        "Circle",
        "Ellipse",
        "Capsule",
        "RoundedRectangle",
        "Path",
        "Spacer",
        "Divider",
        "EmptyView",
        "AnyView"
    ]
    
    public static let supportedModifiers: [String] = [
        "frame",
        "padding",
        "background",
        "foregroundColor",
        "font",
        "bold",
        "italic",
        "underline",
        "strikethrough",
        "cornerRadius",
        "clipShape",
        "shadow",
        "opacity",
        "scaleEffect",
        "rotationEffect",
        "offset",
        "overlay",
        "border",
        "aspectRatio",
        "clipped",
        "disabled",
        "hidden",
        "allowsHitTesting",
        "contentShape",
        "gesture",
        "onTapGesture",
        "onLongPressGesture",
        "onAppear",
        "onDisappear",
        "onChange",
        "animation",
        "transition",
        "zIndex",
        "layoutPriority",
        "accessibility"
    ]
}

public struct SwiftUILayoutJSON: Codable {
    public let views: [SwiftUIViewJSON]
    public let metadata: LayoutMetadata
    
    public init(views: [SwiftUIViewJSON], metadata: LayoutMetadata) {
        self.views = views
        self.metadata = metadata
    }
}

public struct LayoutMetadata: Codable {
    public let fileName: String
    public let timestamp: String
    public let version: String
    public let checksum: String
    public let previewTraits: PreviewTraits?
    
    public init(fileName: String, timestamp: String = ISO8601DateFormatter().string(from: Date()), version: String = "1.0.0", checksum: String, previewTraits: PreviewTraits? = nil) {
        self.fileName = fileName
        self.timestamp = timestamp
        self.version = version
        self.checksum = checksum
        self.previewTraits = previewTraits
    }
}

public struct PreviewTraits: Codable {
    public let deviceName: String?
    public let orientation: String?
    public let colorScheme: String?
    public let locale: String?
    public let accessibilityEnabled: Bool?
    
    public init(deviceName: String? = nil, orientation: String? = nil, colorScheme: String? = nil, locale: String? = nil, accessibilityEnabled: Bool? = nil) {
        self.deviceName = deviceName
        self.orientation = orientation
        self.colorScheme = colorScheme
        self.locale = locale
        self.accessibilityEnabled = accessibilityEnabled
    }
}