import Foundation

public struct ComposeComponentJSON: Codable {
    public let type: String
    public let id: String
    public let parameters: [String: ComposeParameterValue]
    public let children: [ComposeComponentJSON]?
    public let modifiers: [ComposeModifierJSON]?
    public let state: [String: ComposeStateValue]?
    
    public init(
        type: String,
        id: String = UUID().uuidString,
        parameters: [String: ComposeParameterValue] = [:],
        children: [ComposeComponentJSON]? = nil,
        modifiers: [ComposeModifierJSON]? = nil,
        state: [String: ComposeStateValue]? = nil
    ) {
        self.type = type
        self.id = id
        self.parameters = parameters
        self.children = children
        self.modifiers = modifiers
        self.state = state
    }
}

public struct ComposeModifierJSON: Codable {
    public let name: String
    public let parameters: [String: ComposeParameterValue]
    
    public init(name: String, parameters: [String: ComposeParameterValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

public indirect enum ComposeParameterValue: Codable {
    case string(String)
    case int(Int)
    case long(Int64)
    case float(Float)
    case double(Double)
    case bool(Bool)
    case color(ComposeColorValue)
    case textStyle(ComposeTextStyleValue)
    case padding(ComposePaddingValue)
    case arrangement(ComposeArrangementValue)
    case alignment(ComposeAlignmentValue)
    case array([ComposeParameterValue])
    case mutableState(ComposeMutableStateValue)
    case lambda(ComposeLambdaValue)
    case shape(ComposeShapeValue)
    case nullValue
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .nullValue
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .long(value)
        } else if let value = try? container.decode(Float.self) {
            self = .float(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(ComposeColorValue.self) {
            self = .color(value)
        } else if let value = try? container.decode(ComposeTextStyleValue.self) {
            self = .textStyle(value)
        } else if let value = try? container.decode(ComposePaddingValue.self) {
            self = .padding(value)
        } else if let value = try? container.decode(ComposeArrangementValue.self) {
            self = .arrangement(value)
        } else if let value = try? container.decode(ComposeAlignmentValue.self) {
            self = .alignment(value)
        } else if let value = try? container.decode([ComposeParameterValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(ComposeMutableStateValue.self) {
            self = .mutableState(value)
        } else if let value = try? container.decode(ComposeLambdaValue.self) {
            self = .lambda(value)
        } else if let value = try? container.decode(ComposeShapeValue.self) {
            self = .shape(value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode ComposeParameterValue"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .long(let value):
            try container.encode(value)
        case .float(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .color(let value):
            try container.encode(value)
        case .textStyle(let value):
            try container.encode(value)
        case .padding(let value):
            try container.encode(value)
        case .arrangement(let value):
            try container.encode(value)
        case .alignment(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .mutableState(let value):
            try container.encode(value)
        case .lambda(let value):
            try container.encode(value)
        case .shape(let value):
            try container.encode(value)
        case .nullValue:
            try container.encodeNil()
        }
    }
}

public struct ComposeColorValue: Codable {
    public let type: ComposeColorType
    public let red: Float?
    public let green: Float?
    public let blue: Float?
    public let alpha: Float?
    public let materialColor: String?
    public let hexValue: String?
    
    public init(type: ComposeColorType, red: Float? = nil, green: Float? = nil, blue: Float? = nil, alpha: Float? = 1.0, materialColor: String? = nil, hexValue: String? = nil) {
        self.type = type
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.materialColor = materialColor
        self.hexValue = hexValue
    }
}

public enum ComposeColorType: String, Codable {
    case rgba = "rgba"
    case material = "material"
    case hex = "hex"
    case hsv = "hsv"
}

public struct ComposeTextStyleValue: Codable {
    public let fontSize: ComposeDpValue?
    public let fontWeight: String?
    public let fontStyle: String?
    public let fontFamily: String?
    public let letterSpacing: ComposeDpValue?
    public let lineHeight: ComposeDpValue?
    public let textAlign: String?
    public let textDecoration: String?
    
    public init(fontSize: ComposeDpValue? = nil, fontWeight: String? = nil, fontStyle: String? = nil, fontFamily: String? = nil, letterSpacing: ComposeDpValue? = nil, lineHeight: ComposeDpValue? = nil, textAlign: String? = nil, textDecoration: String? = nil) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
        self.fontFamily = fontFamily
        self.letterSpacing = letterSpacing
        self.lineHeight = lineHeight
        self.textAlign = textAlign
        self.textDecoration = textDecoration
    }
}

public struct ComposeDpValue: Codable {
    public let value: Float
    public let unit: String
    
    public init(value: Float, unit: String = "dp") {
        self.value = value
        self.unit = unit
    }
}

public struct ComposePaddingValue: Codable {
    public let start: ComposeDpValue?
    public let top: ComposeDpValue?
    public let end: ComposeDpValue?
    public let bottom: ComposeDpValue?
    public let all: ComposeDpValue?
    public let horizontal: ComposeDpValue?
    public let vertical: ComposeDpValue?
    
    public init(start: ComposeDpValue? = nil, top: ComposeDpValue? = nil, end: ComposeDpValue? = nil, bottom: ComposeDpValue? = nil, all: ComposeDpValue? = nil, horizontal: ComposeDpValue? = nil, vertical: ComposeDpValue? = nil) {
        self.start = start
        self.top = top
        self.end = end
        self.bottom = bottom
        self.all = all
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

public struct ComposeArrangementValue: Codable {
    public let type: String
    public let spacing: ComposeDpValue?
    
    public init(type: String, spacing: ComposeDpValue? = nil) {
        self.type = type
        self.spacing = spacing
    }
}

public struct ComposeAlignmentValue: Codable {
    public let horizontal: String?
    public let vertical: String?
    public let alignment: String?
    
    public init(horizontal: String? = nil, vertical: String? = nil, alignment: String? = nil) {
        self.horizontal = horizontal
        self.vertical = vertical
        self.alignment = alignment
    }
}

public struct ComposeMutableStateValue: Codable {
    public let stateKey: String
    public let initialValueType: String
    public let type: String
    
    public init(stateKey: String, initialValueType: String, type: String) {
        self.stateKey = stateKey
        self.initialValueType = initialValueType
        self.type = type
    }
}

public struct ComposeLambdaValue: Codable {
    public let type: ComposeLambdaType
    public let target: String?
    public let parameters: [String: ComposeParameterValue]?
    
    public init(type: ComposeLambdaType, target: String? = nil, parameters: [String: ComposeParameterValue]? = nil) {
        self.type = type
        self.target = target
        self.parameters = parameters
    }
}

public enum ComposeLambdaType: String, Codable {
    case onClick = "onClick"
    case onValueChange = "onValueChange"
    case onCheckedChange = "onCheckedChange"
    case onSelectionChanged = "onSelectionChanged"
    case content = "content"
    case trailing = "trailing"
    case leading = "leading"
    case custom = "custom"
}

public struct ComposeShapeValue: Codable {
    public let type: ComposeShapeType
    public let cornerRadius: ComposeDpValue?
    public let topStart: ComposeDpValue?
    public let topEnd: ComposeDpValue?
    public let bottomStart: ComposeDpValue?
    public let bottomEnd: ComposeDpValue?
    
    public init(type: ComposeShapeType, cornerRadius: ComposeDpValue? = nil, topStart: ComposeDpValue? = nil, topEnd: ComposeDpValue? = nil, bottomStart: ComposeDpValue? = nil, bottomEnd: ComposeDpValue? = nil) {
        self.type = type
        self.cornerRadius = cornerRadius
        self.topStart = topStart
        self.topEnd = topEnd
        self.bottomStart = bottomStart
        self.bottomEnd = bottomEnd
    }
}

public enum ComposeShapeType: String, Codable {
    case rectangle = "rectangle"
    case roundedCorner = "roundedCorner"
    case circle = "circle"
    case cutCorner = "cutCorner"
    case custom = "custom"
}

public enum ComposeStateValue: Codable {
    case string(String)
    case int(Int)
    case long(Int64)
    case float(Float)
    case double(Double)
    case bool(Bool)
    case array([ComposeStateValue])
    case map([String: ComposeStateValue])
    case nullValue
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .nullValue
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .long(value)
        } else if let value = try? container.decode(Float.self) {
            self = .float(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([ComposeStateValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: ComposeStateValue].self) {
            self = .map(value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode ComposeStateValue"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .long(let value):
            try container.encode(value)
        case .float(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .map(let value):
            try container.encode(value)
        case .nullValue:
            try container.encodeNil()
        }
    }
}

public struct ComposeComponentRegistry {
    public static let supportedComponents: [String] = [
        "Text",
        "Column",
        "Row",
        "Box",
        "Button",
        "IconButton",
        "FloatingActionButton",
        "TextField",
        "OutlinedTextField",
        "BasicTextField",
        "Checkbox",
        "RadioButton",
        "Switch",
        "Slider",
        "RangeSlider",
        "ProgressIndicator",
        "LinearProgressIndicator",
        "CircularProgressIndicator",
        "Image",
        "Icon",
        "Surface",
        "Card",
        "Chip",
        "Divider",
        "Spacer",
        "LazyColumn",
        "LazyRow",
        "LazyVerticalGrid",
        "LazyHorizontalGrid",
        "Scaffold",
        "TopAppBar",
        "BottomAppBar",
        "NavigationBar",
        "NavigationRail",
        "BottomNavigation",
        "TabRow",
        "ScrollableTabRow",
        "DropdownMenu",
        "ExposedDropdownMenuBox",
        "ModalBottomSheet",
        "BottomSheet",
        "AlertDialog",
        "DatePicker",
        "TimePicker",
        "Pager",
        "HorizontalPager",
        "VerticalPager"
    ]
    
    public static let supportedModifiers: [String] = [
        "fillMaxSize",
        "fillMaxWidth",
        "fillMaxHeight",
        "size",
        "width",
        "height",
        "padding",
        "margin",
        "background",
        "clip",
        "clipToBounds",
        "alpha",
        "scale",
        "rotate",
        "offset",
        "shadow",
        "border",
        "clickable",
        "selectable",
        "focusable",
        "scrollable",
        "draggable",
        "weight",
        "align",
        "wrapContentSize",
        "wrapContentWidth",
        "wrapContentHeight",
        "aspectRatio",
        "animateContentSize",
        "semantics",
        "testTag",
        "layout",
        "drawBehind",
        "drawWithCache",
        "onGloballyPositioned",
        "onSizeChanged",
        "pointerInput",
        "indication",
        "interactionSource"
    ]
}

public struct ComposeLayoutJSON: Codable {
    public let components: [ComposeComponentJSON]
    public let metadata: ComposeLayoutMetadata
    
    public init(components: [ComposeComponentJSON], metadata: ComposeLayoutMetadata) {
        self.components = components
        self.metadata = metadata
    }
}

public struct ComposeLayoutMetadata: Codable {
    public let fileName: String
    public let timestamp: String
    public let version: String
    public let checksum: String
    public let previewConfiguration: ComposePreviewConfiguration?
    
    public init(fileName: String, timestamp: String = ISO8601DateFormatter().string(from: Date()), version: String = "1.0.0", checksum: String, previewConfiguration: ComposePreviewConfiguration? = nil) {
        self.fileName = fileName
        self.timestamp = timestamp
        self.version = version
        self.checksum = checksum
        self.previewConfiguration = previewConfiguration
    }
}

public struct ComposePreviewConfiguration: Codable {
    public let device: String?
    public let widthDp: Int?
    public let heightDp: Int?
    public let uiMode: String?
    public let locale: String?
    public let fontScale: Float?
    public let showBackground: Bool?
    public let backgroundColor: String?
    
    public init(device: String? = nil, widthDp: Int? = nil, heightDp: Int? = nil, uiMode: String? = nil, locale: String? = nil, fontScale: Float? = nil, showBackground: Bool? = nil, backgroundColor: String? = nil) {
        self.device = device
        self.widthDp = widthDp
        self.heightDp = heightDp
        self.uiMode = uiMode
        self.locale = locale
        self.fontScale = fontScale
        self.showBackground = showBackground
        self.backgroundColor = backgroundColor
    }
}