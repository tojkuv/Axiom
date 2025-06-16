import SwiftUI
import HotReloadProtocol

// MARK: - Parameter Extraction Helpers

extension SwiftUIModifierApplicator {
    
    // MARK: - Basic Type Extraction
    
    internal func extractString(from parameters: [String: PropertyValue], key: String) -> String? {
        guard case .string(let value) = parameters[key] else { return nil }
        return value
    }
    
    internal func extractInt(from parameters: [String: PropertyValue], key: String) -> Int? {
        switch parameters[key] {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        default:
            return nil
        }
    }
    
    internal func extractDouble(from parameters: [String: PropertyValue], key: String) -> Double? {
        switch parameters[key] {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        default:
            return nil
        }
    }
    
    internal func extractCGFloat(from parameters: [String: PropertyValue], key: String) -> CGFloat? {
        if let double = extractDouble(from: parameters, key: key) {
            return CGFloat(double)
        }
        return nil
    }
    
    internal func extractOptionalCGFloat(from parameters: [String: PropertyValue], key: String) -> CGFloat? {
        return extractCGFloat(from: parameters, key: key)
    }
    
    internal func extractBool(from parameters: [String: PropertyValue], key: String) -> Bool? {
        guard case .bool(let value) = parameters[key] else { return nil }
        return value
    }
    
    // MARK: - Color Extraction
    
    internal func extractColor(from parameters: [String: PropertyValue], key: String) -> Color? {
        guard case .color(let colorValue) = parameters[key] else {
            // Try to extract as string color name
            if let colorString = extractString(from: parameters, key: key) {
                return colorFromString(colorString)
            }
            return nil
        }
        
        switch colorValue.type {
        case .rgb:
            let red = colorValue.red ?? 0
            let green = colorValue.green ?? 0
            let blue = colorValue.blue ?? 0
            let alpha = colorValue.alpha ?? 1
            return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
            
        case .system:
            if let systemColor = colorValue.systemColor {
                return systemColorFromString(systemColor)
            }
            return nil
            
        case .custom:
            // Handle custom colors
            return Color.gray
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color? {
        switch colorString.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "black": return .black
        case "white": return .white
        case "gray", "grey": return .gray
        case "clear": return .clear
        case "primary": return .primary
        case "secondary": return .secondary
        case "accentcolor": return .accentColor
        default: return nil
        }
    }
    
    private func systemColorFromString(_ systemColor: String) -> Color? {
        switch systemColor.lowercased() {
        case "label": return .primary
        case "secondarylabel": return .secondary
        case "systembackground": 
            #if canImport(UIKit) && !os(macOS)
            return Color(.systemBackground)
            #else
            return Color.gray.opacity(0.1)
            #endif
        case "secondarysystembackground": 
            #if canImport(UIKit) && !os(macOS)
            return Color(.secondarySystemBackground)
            #else
            return Color.gray.opacity(0.05)
            #endif
        case "systemred": return .red
        case "systemgreen": return .green
        case "systemblue": return .blue
        case "systemyellow": return .yellow
        case "systemorange": return .orange
        case "systempurple": return .purple
        case "systempink": return .pink
        case "systemgray": return .gray
        default: return nil
        }
    }
    
    // MARK: - Font Extraction
    
    internal func extractFont(from parameters: [String: PropertyValue]) -> Font? {
        guard case .font(let fontValue) = parameters["font"] else {
            // Try to extract font from size parameter
            if let size = extractCGFloat(from: parameters, key: "size") {
                return .system(size: size)
            }
            
            // Try to extract from style parameter
            if let style = extractString(from: parameters, key: "style") {
                return fontFromStyle(style)
            }
            
            return nil
        }
        
        let size = CGFloat(fontValue.size)
        
        // Handle custom font name
        if let name = fontValue.name {
            return .custom(name, size: size)
        }
        
        // Handle system font with weight and design
        var font = Font.system(size: size)
        
        if let weight = fontValue.weight {
            if #available(macOS 13.0, iOS 16.0, *) {
                font = font.weight(fontWeightFromString(weight))
            }
        }
        
        if let design = fontValue.design {
            // Font design is not available in this SwiftUI version
            // Skip design application for compatibility
            _ = fontDesignFromString(design) // Keep the function for future use
        }
        
        return font
    }
    
    private func fontFromStyle(_ style: String) -> Font? {
        switch style.lowercased() {
        case "largetitle": return .largeTitle
        case "title": return .title
        case "title2": return .title2
        case "title3": return .title3
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "body": return .body
        case "callout": return .callout
        case "footnote": return .footnote
        case "caption": return .caption
        case "caption2": return .caption2
        default: return nil
        }
    }
    
    internal func fontWeightFromString(_ weight: String) -> Font.Weight {
        switch weight.lowercased() {
        case "ultralight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    
    internal func fontDesignFromString(_ design: String) -> Font.Design {
        switch design.lowercased() {
        case "default": return .default
        case "serif": return .serif
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        default: return .default
        }
    }
    
    // MARK: - Alignment Extraction
    
    internal func extractAlignment(from parameters: [String: PropertyValue]) -> Alignment? {
        guard case .alignment(let alignmentValue) = parameters["alignment"] else {
            return nil
        }
        
        let horizontal = horizontalAlignmentFromString(alignmentValue.horizontal)
        let vertical = verticalAlignmentFromString(alignmentValue.vertical)
        
        return Alignment(horizontal: horizontal, vertical: vertical)
    }
    
    private func horizontalAlignmentFromString(_ alignment: String) -> HorizontalAlignment {
        switch alignment.lowercased() {
        case "leading": return .leading
        case "center": return .center
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    private func verticalAlignmentFromString(_ alignment: String) -> VerticalAlignment {
        switch alignment.lowercased() {
        case "top": return .top
        case "center": return .center
        case "bottom": return .bottom
        case "firsttextbaseline": return .firstTextBaseline
        case "lasttextbaseline": return .lastTextBaseline
        default: return .center
        }
    }
    
    // MARK: - Edge Insets Extraction
    
    internal func extractEdgeInsets(from parameters: [String: PropertyValue]) -> EdgeInsets? {
        guard case .edge(let edgeValue) = parameters["padding"] ?? parameters["edge"] else {
            return nil
        }
        
        if let all = edgeValue.all {
            return EdgeInsets(top: all, leading: all, bottom: all, trailing: all)
        }
        
        return EdgeInsets(
            top: edgeValue.top ?? 0,
            leading: edgeValue.leading ?? 0,
            bottom: edgeValue.bottom ?? 0,
            trailing: edgeValue.trailing ?? 0
        )
    }
}

// MARK: - Configuration

public struct SwiftUIModifierConfiguration {
    public let allowUnknownModifiers: Bool
    public let enableDebugMode: Bool
    public let strictTypeChecking: Bool
    public let enableActionHandling: Bool
    
    public init(
        allowUnknownModifiers: Bool = true,
        enableDebugMode: Bool = false,
        strictTypeChecking: Bool = false,
        enableActionHandling: Bool = true
    ) {
        self.allowUnknownModifiers = allowUnknownModifiers
        self.enableDebugMode = enableDebugMode
        self.strictTypeChecking = strictTypeChecking
        self.enableActionHandling = enableActionHandling
    }
    
    public static func production() -> SwiftUIModifierConfiguration {
        return SwiftUIModifierConfiguration(
            allowUnknownModifiers: false,
            enableDebugMode: false,
            strictTypeChecking: true
        )
    }
    
    public static func development() -> SwiftUIModifierConfiguration {
        return SwiftUIModifierConfiguration(
            allowUnknownModifiers: true,
            enableDebugMode: true,
            strictTypeChecking: false
        )
    }
}

// MARK: - Render Configuration

public struct SwiftUIRenderConfiguration {
    public let viewFactoryConfig: SwiftUIViewFactoryConfiguration
    public let modifierConfig: SwiftUIModifierConfiguration
    public let enableViewCaching: Bool
    public let enableFallbackUI: Bool
    public let enableDebugInfo: Bool
    public let strictModeEnabled: Bool
    public let enableSafeAreaHandling: Bool
    public let enableStatePreservation: Bool
    public let maxRenderTime: TimeInterval
    
    public init(
        viewFactoryConfig: SwiftUIViewFactoryConfiguration = SwiftUIViewFactoryConfiguration(),
        modifierConfig: SwiftUIModifierConfiguration = SwiftUIModifierConfiguration(),
        enableViewCaching: Bool = true,
        enableFallbackUI: Bool = true,
        enableDebugInfo: Bool = false,
        strictModeEnabled: Bool = false,
        enableSafeAreaHandling: Bool = true,
        enableStatePreservation: Bool = true,
        maxRenderTime: TimeInterval = 5.0
    ) {
        self.viewFactoryConfig = viewFactoryConfig
        self.modifierConfig = modifierConfig
        self.enableViewCaching = enableViewCaching
        self.enableFallbackUI = enableFallbackUI
        self.enableDebugInfo = enableDebugInfo
        self.strictModeEnabled = strictModeEnabled
        self.enableSafeAreaHandling = enableSafeAreaHandling
        self.enableStatePreservation = enableStatePreservation
        self.maxRenderTime = maxRenderTime
    }
    
    public static func production() -> SwiftUIRenderConfiguration {
        return SwiftUIRenderConfiguration(
            viewFactoryConfig: .production(),
            modifierConfig: .production(),
            enableViewCaching: true,
            enableFallbackUI: false,
            enableDebugInfo: false,
            strictModeEnabled: true,
            enableStatePreservation: false
        )
    }
    
    public static func development() -> SwiftUIRenderConfiguration {
        return SwiftUIRenderConfiguration(
            viewFactoryConfig: .development(),
            modifierConfig: .development(),
            enableViewCaching: true,
            enableFallbackUI: true,
            enableDebugInfo: true,
            strictModeEnabled: false,
            enableStatePreservation: true
        )
    }
    
    public static func hotReload() -> SwiftUIRenderConfiguration {
        return SwiftUIRenderConfiguration(
            viewFactoryConfig: .development(),
            modifierConfig: .development(),
            enableViewCaching: false, // Disable caching for hot reload
            enableFallbackUI: true,
            enableDebugInfo: false,
            strictModeEnabled: false,
            enableSafeAreaHandling: true,
            enableStatePreservation: true,
            maxRenderTime: 2.0 // Faster timeout for hot reload
        )
    }
}

// MARK: - Errors

public enum SwiftUIModifierError: Error, LocalizedError {
    case unsupportedModifier(String)
    case invalidParameters(String)
    case extractionFailed(String, String)
    case applicationFailed(String, String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedModifier(let modifier):
            return "Unsupported modifier: \(modifier)"
        case .invalidParameters(let details):
            return "Invalid parameters: \(details)"
        case .extractionFailed(let parameter, let details):
            return "Failed to extract parameter '\(parameter)': \(details)"
        case .applicationFailed(let modifier, let details):
            return "Failed to apply modifier '\(modifier)': \(details)"
        }
    }
}