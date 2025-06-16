import Foundation
import Logging
import HotReloadProtocol

public final class SwiftUIJSONGenerator {
    private let logger: Logger
    private let configuration: SwiftUIJSONGeneratorConfiguration
    
    public init(
        configuration: SwiftUIJSONGeneratorConfiguration = SwiftUIJSONGeneratorConfiguration(),
        logger: Logger = Logger(label: "axiom.hotreload.swiftui.json")
    ) {
        self.configuration = configuration
        self.logger = logger
    }
    
    public func generateHotReloadMessage(
        from parseResult: SwiftUIParseResult,
        changeType: ChangeType = .modified
    ) throws -> BaseMessage {
        
        logger.debug("Generating hot reload message for: \(parseResult.filePath)")
        
        guard parseResult.success, let swiftUIJSON = parseResult.swiftUIJSON else {
            throw SwiftUIJSONGeneratorError.parseResultInvalid
        }
        
        let fileName = URL(fileURLWithPath: parseResult.filePath).lastPathComponent
        let checksum = generateChecksum(for: parseResult.content)
        
        let payload = FileChangedPayload(
            filePath: parseResult.filePath,
            fileName: fileName,
            fileContent: try generateCompactJSON(from: swiftUIJSON),
            changeType: changeType,
            checksum: checksum
        )
        
        let message = BaseMessage(
            type: .fileChanged,
            platform: .ios,
            payload: .fileChanged(payload)
        )
        
        logger.debug("Generated hot reload message with \(swiftUIJSON.views.count) views")
        return message
    }
    
    public func generateSwiftUILayoutJSON(from parseResult: SwiftUIParseResult) throws -> SwiftUILayoutJSON {
        guard parseResult.success, let swiftUIJSON = parseResult.swiftUIJSON else {
            throw SwiftUIJSONGeneratorError.parseResultInvalid
        }
        
        let fileName = URL(fileURLWithPath: parseResult.filePath).lastPathComponent
        let checksum = generateChecksum(for: parseResult.content)
        
        let metadata = LayoutMetadata(
            fileName: fileName,
            checksum: checksum,
            previewTraits: extractPreviewTraits(from: parseResult)
        )
        
        return SwiftUILayoutJSON(
            views: swiftUIJSON.views,
            metadata: metadata
        )
    }
    
    public func generateViewJSON(from ast: SwiftUIASTNode, stateInfo: SwiftUIStateInfo?) -> SwiftUIViewJSON {
        logger.debug("Converting AST node to SwiftUI JSON: \(ast.type)")
        
        // Convert AST node to SwiftUI view
        let properties = extractProperties(from: ast)
        let children = ast.children.map { generateViewJSON(from: $0, stateInfo: stateInfo) }
        let modifiers = extractModifiers(from: ast)
        let state = extractStateFromNode(ast, stateInfo: stateInfo)
        
        return SwiftUIViewJSON(
            type: mapASTTypeToSwiftUIType(ast.type),
            properties: properties,
            children: children.isEmpty ? nil : children,
            modifiers: modifiers.isEmpty ? nil : modifiers,
            state: state.isEmpty ? nil : state
        )
    }
    
    private func generateCompactJSON(from swiftUIJSON: SwiftUIJSONOutput) throws -> String {
        let layoutJSON = SwiftUILayoutJSON(
            views: swiftUIJSON.views,
            metadata: LayoutMetadata(
                fileName: "dynamic",
                checksum: UUID().uuidString
            )
        )
        
        let encoder = JSONEncoder()
        if configuration.minimizeOutput {
            encoder.outputFormatting = []
        } else {
            encoder.outputFormatting = [.prettyPrinted]
        }
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(layoutJSON)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private func extractProperties(from ast: SwiftUIASTNode) -> [String: PropertyValue] {
        var properties: [String: PropertyValue] = [:]
        
        // Extract properties from AST node attributes
        for (key, value) in ast.attributes {
            if let propertyValue = parsePropertyValue(value) {
                properties[key] = propertyValue
            }
        }
        
        // Handle common SwiftUI properties
        if ast.type == "Text", let textValue = ast.value {
            properties["content"] = .string(textValue)
        }
        
        return properties
    }
    
    private func extractModifiers(from ast: SwiftUIASTNode) -> [SwiftUIModifierJSON] {
        var modifiers: [SwiftUIModifierJSON] = []
        
        // Extract modifiers from AST (this would be more sophisticated in a full implementation)
        if let paddingValue = ast.attributes["padding"] {
            modifiers.append(SwiftUIModifierJSON(
                name: "padding",
                parameters: ["all": .double(Double(paddingValue) ?? 16.0)]
            ))
        }
        
        if let backgroundValue = ast.attributes["background"] {
            modifiers.append(SwiftUIModifierJSON(
                name: "background",
                parameters: ["color": .string(backgroundValue)]
            ))
        }
        
        return modifiers
    }
    
    private func extractStateFromNode(_ ast: SwiftUIASTNode, stateInfo: SwiftUIStateInfo?) -> [String: StateValue] {
        var state: [String: StateValue] = [:]
        
        // Extract state variables that affect this node
        if let stateInfo = stateInfo {
            for stateVar in stateInfo.stateVariables {
                if ast.attributes.keys.contains(stateVar.name) {
                    state[stateVar.name] = parseStateValue(stateVar.defaultValue)
                }
            }
        }
        
        return state
    }
    
    private func extractPreviewTraits(from parseResult: SwiftUIParseResult) -> PreviewTraits? {
        // Extract preview configuration from comments or annotations
        // This would analyze the code for #Preview or PreviewProvider
        return PreviewTraits(
            deviceName: configuration.defaultDeviceName,
            orientation: "portrait",
            colorScheme: "light"
        )
    }
    
    private func mapASTTypeToSwiftUIType(_ astType: String) -> String {
        // Map internal AST types to SwiftUI view types
        let mapping: [String: String] = [
            "struct": "VStack", // Default mapping for demo
            "text_literal": "Text",
            "button": "Button",
            "vstack": "VStack",
            "hstack": "HStack",
            "zstack": "ZStack"
        ]
        
        return mapping[astType.lowercased()] ?? astType
    }
    
    private func parsePropertyValue(_ value: String) -> PropertyValue? {
        // Parse string value into appropriate PropertyValue type
        if value.hasPrefix("\"") && value.hasSuffix("\"") {
            let stringValue = String(value.dropFirst().dropLast())
            return .string(stringValue)
        }
        
        if let intValue = Int(value) {
            return .int(intValue)
        }
        
        if let doubleValue = Double(value) {
            return .double(doubleValue)
        }
        
        if value.lowercased() == "true" || value.lowercased() == "false" {
            return .bool(value.lowercased() == "true")
        }
        
        return .string(value)
    }
    
    private func parseStateValue(_ value: String?) -> StateValue {
        guard let value = value else { return .nullValue }
        
        if let intValue = Int(value) {
            return .int(intValue)
        }
        
        if let doubleValue = Double(value) {
            return .double(doubleValue)
        }
        
        if value.lowercased() == "true" || value.lowercased() == "false" {
            return .bool(value.lowercased() == "true")
        }
        
        return .string(value)
    }
    
    private func generateChecksum(for content: String) -> String {
        return content.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
}

// MARK: - Configuration

public struct SwiftUIJSONGeneratorConfiguration {
    public let minimizeOutput: Bool
    public let includeMetadata: Bool
    public let includeStateInfo: Bool
    public let defaultDeviceName: String
    public let enablePropertyValidation: Bool
    
    public init(
        minimizeOutput: Bool = true,
        includeMetadata: Bool = true,
        includeStateInfo: Bool = true,
        defaultDeviceName: String = "iPhone 15 Pro",
        enablePropertyValidation: Bool = false
    ) {
        self.minimizeOutput = minimizeOutput
        self.includeMetadata = includeMetadata
        self.includeStateInfo = includeStateInfo
        self.defaultDeviceName = defaultDeviceName
        self.enablePropertyValidation = enablePropertyValidation
    }
    
    public static func forHotReload() -> SwiftUIJSONGeneratorConfiguration {
        return SwiftUIJSONGeneratorConfiguration(
            minimizeOutput: true,
            includeMetadata: true,
            includeStateInfo: true,
            enablePropertyValidation: false
        )
    }
}

// MARK: - Errors

public enum SwiftUIJSONGeneratorError: Error, LocalizedError {
    case parseResultInvalid
    case jsonGenerationFailed(String)
    case unsupportedViewType(String)
    case invalidPropertyValue(String)
    
    public var errorDescription: String? {
        switch self {
        case .parseResultInvalid:
            return "Parse result is invalid or unsuccessful"
        case .jsonGenerationFailed(let details):
            return "JSON generation failed: \(details)"
        case .unsupportedViewType(let type):
            return "Unsupported SwiftUI view type: \(type)"
        case .invalidPropertyValue(let value):
            return "Invalid property value: \(value)"
        }
    }
}