import Foundation

@MainActor
class LiveCompiler {
    private let tempDirectory: URL
    private let swiftCompilerPath = "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    private let sdkPath = "/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk"
    
    init() {
        self.tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("HotReloadLive", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    func generateExecutableSwiftUICode(_ userCode: String, viewName: String) async throws -> LiveCompiledView {
        print("🔥 LiveCompiler: Starting compilation for \(viewName)")
        
        // 1. Extract state variables and view structure
        let analysis = try analyzeSwiftUICode(userCode)
        print("🔥 Found \(analysis.stateVariables.count) state variables")
        
        // 2. Generate executable Swift module
        let executableCode = generateExecutableModule(userCode, viewName: viewName, analysis: analysis)
        
        // 3. Create the compiled view model
        let compiledView = LiveCompiledView(
            viewName: viewName,
            originalCode: userCode,
            executableCode: executableCode,
            stateVariables: analysis.stateVariables,
            viewStructure: analysis.viewStructure,
            interactions: analysis.interactions
        )
        
        print("✅ LiveCompiler: Generated executable view for \(viewName)")
        return compiledView
    }
    
    private func analyzeSwiftUICode(_ source: String) throws -> SwiftUIAnalysis {
        print("🔍 Analyzing SwiftUI code with enhanced regex...")
        
        let analyzer = EnhancedRegexAnalyzer()
        return analyzer.analyze(source)
    }
    
    private func generateExecutableModule(_ userCode: String, viewName: String, analysis: SwiftUIAnalysis) -> String {
        let stateDeclarations = analysis.stateVariables.map { stateVar in
            "@State private var \(stateVar.name): \(stateVar.type) = \(stateVar.defaultValueString)"
        }.joined(separator: "\n    ")
        
        let interactionMethods = analysis.interactions.map { interaction in
            generateInteractionMethod(interaction)
        }.joined(separator: "\n\n    ")
        
        return """
        import SwiftUI
        import Foundation
        
        struct \(viewName)_Live: View {
            \(stateDeclarations)
            
            var body: some View {
                \(analysis.viewStructure.generateSwiftUICode())
            }
            
            \(interactionMethods)
        }
        
        struct \(viewName)_LiveWrapper {
            static func createView() -> AnyView {
                return AnyView(\(viewName)_Live())
            }
            
            static func getStateInfo() -> [String: Any] {
                return [
                    \(analysis.stateVariables.map { stateVar in "\"\\(stateVar.name)\": \"\\(stateVar.type)\"" }.joined(separator: ",\n                    "))
                ]
            }
        }
        """
    }
    
    private func generateInteractionMethod(_ interaction: ViewInteraction) -> String {
        switch interaction.type {
        case .buttonTap:
            return """
            private func \(interaction.name)() {
                \(interaction.action)
            }
            """
        case .textInput:
            return """
            private func handle\(interaction.name.capitalized)Change(_ newValue: String) {
                \(interaction.binding) = newValue
            }
            """
        case .toggle:
            return """
            private func toggle\(interaction.name.capitalized)() {
                \(interaction.binding).toggle()
            }
            """
        }
    }
}

// MARK: - Enhanced Regex Analyzer

class EnhancedRegexAnalyzer {
    func analyze(_ source: String) -> SwiftUIAnalysis {
        print("🔍 Starting enhanced regex analysis...")
        
        let stateVariables = extractStateVariables(from: source)
        let viewStructure = extractViewStructure(from: source)
        let interactions = extractInteractions(from: source)
        
        print("🔍 Found \(stateVariables.count) state variables")
        print("🔍 Found \(viewStructure.children.count) view elements")
        print("🔍 Found \(interactions.count) interactions")
        
        return SwiftUIAnalysis(
            stateVariables: stateVariables,
            viewStructure: viewStructure,
            interactions: interactions,
            computedProperties: []
        )
    }
    
    private func extractStateVariables(from source: String) -> [StateVariable] {
        var stateVars: [StateVariable] = []
        
        // Pattern: @State private var name: Type = value
        let statePattern = #"@State\s+private\s+var\s+(\w+)(?:\s*:\s*(\w+))?\s*=\s*([^\\n]+)"#
        let regex = try! NSRegularExpression(pattern: statePattern)
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        
        for match in matches {
            let nameRange = Range(match.range(at: 1), in: source)!
            let name = String(source[nameRange])
            
            var type = "Any"
            if match.range(at: 2).location != NSNotFound {
                let typeRange = Range(match.range(at: 2), in: source)!
                type = String(source[typeRange])
            }
            
            let valueRange = Range(match.range(at: 3), in: source)!
            let valueString = String(source[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let defaultValue = parseDefaultValue(valueString, inferredType: &type)
            
            let stateVar = StateVariable(
                name: name,
                type: type,
                defaultValue: defaultValue,
                defaultValueString: defaultValue.swiftCode
            )
            stateVars.append(stateVar)
            
            print("🔍 Found state variable: \(name): \(type) = \(defaultValue)")
        }
        
        return stateVars
    }
    
    private func parseDefaultValue(_ valueString: String, inferredType: inout String) -> DefaultValue {
        let trimmed = valueString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Integer
        if let intValue = Int(trimmed) {
            inferredType = "Int"
            return .int(intValue)
        }
        
        // Boolean
        if trimmed == "true" || trimmed == "false" {
            inferredType = "Bool"
            return .bool(trimmed == "true")
        }
        
        // String literal
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            inferredType = "String"
            let stringValue = String(trimmed.dropFirst().dropLast())
            return .string(stringValue)
        }
        
        // Double
        if let doubleValue = Double(trimmed) {
            inferredType = "Double"
            return .double(doubleValue)
        }
        
        return .raw(trimmed)
    }
    
    private func extractViewStructure(from source: String) -> ViewStructure {
        var children: [ViewStructure] = []
        
        // Extract VStack/HStack containers
        let containerPattern = #"(VStack|HStack)(?:\\([^)]*\\))?\s*\\{"#
        let containerRegex = try! NSRegularExpression(pattern: containerPattern)
        let containerMatches = containerRegex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        
        if !containerMatches.isEmpty {
            // We have container views
            children.append(contentsOf: extractChildViews(from: source))
        } else {
            // No container, extract direct views
            children.append(contentsOf: extractChildViews(from: source))
        }
        
        return ViewStructure(type: .container, children: children)
    }
    
    private func extractChildViews(from source: String) -> [ViewStructure] {
        var views: [ViewStructure] = []
        
        // Extract Text views
        let textPattern = #"Text\\("([^"]+)"\\)"#
        let textRegex = try! NSRegularExpression(pattern: textPattern)
        let textMatches = textRegex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        
        for match in textMatches {
            let contentRange = Range(match.range(at: 1), in: source)!
            let content = String(source[contentRange])
            
            var properties: [String: AnyCodable] = ["content": AnyCodable(content)]
            
            // Extract modifiers for this Text view
            let fullMatchRange = Range(match.range, in: source)!
            let fullMatch = String(source[fullMatchRange])
            let afterText = extractModifiersAfterView(source: source, viewMatch: fullMatch, viewRange: fullMatchRange)
            
            if let modifiers = afterText {
                let modifierProps = parseModifiers(modifiers)
                for (key, value) in modifierProps {
                    properties[key] = AnyCodable(value)
                }
            }
            
            views.append(ViewStructure(type: .text, properties: properties))
            print("🔍 Found Text view: \(content)")
        }
        
        // Extract Button views
        let buttonPattern = #"Button\\("([^"]+)"\\)"#
        let buttonRegex = try! NSRegularExpression(pattern: buttonPattern)
        let buttonMatches = buttonRegex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        
        for match in buttonMatches {
            let titleRange = Range(match.range(at: 1), in: source)!
            let title = String(source[titleRange])
            
            let properties: [String: AnyCodable] = ["content": AnyCodable(title)]
            views.append(ViewStructure(type: .button, properties: properties))
            print("🔍 Found Button view: \(title)")
        }
        
        return views
    }
    
    private func extractModifiersAfterView(source: String, viewMatch: String, viewRange: Range<String.Index>) -> String? {
        let startIndex = viewRange.upperBound
        let endIndex = source.endIndex
        
        if startIndex >= endIndex {
            return nil
        }
        
        let afterText = String(source[startIndex..<endIndex])
        
        // Look for modifier chain starting with "."
        let modifierPattern = #"^((?:\\s*\\.\\w+\\([^)]*\\))*)"#
        let regex = try! NSRegularExpression(pattern: modifierPattern)
        let match = regex.firstMatch(in: afterText, range: NSRange(afterText.startIndex..., in: afterText))
        
        if let match = match, let range = Range(match.range(at: 1), in: afterText) {
            return String(afterText[range])
        }
        
        return nil
    }
    
    private func parseModifiers(_ modifierString: String) -> [String: Any] {
        var properties: [String: Any] = [:]
        
        // Extract font modifier
        if let fontMatch = modifierString.range(of: #"\\.font\\(\\.([^)]+)\\)"#, options: .regularExpression) {
            let fontPart = String(modifierString[fontMatch])
            if let fontNameMatch = fontPart.range(of: #"\\.([^)]+)"#, options: .regularExpression) {
                let fontName = String(fontPart[fontNameMatch]).replacingOccurrences(of: ".", with: "")
                properties["font"] = fontName
            }
        }
        
        // Extract foregroundColor modifier
        if let colorMatch = modifierString.range(of: #"\\.foregroundColor\\(\\.([^)]+)\\)"#, options: .regularExpression) {
            let colorPart = String(modifierString[colorMatch])
            if let colorNameMatch = colorPart.range(of: #"\\.([^)]+)"#, options: .regularExpression) {
                let colorName = String(colorPart[colorNameMatch]).replacingOccurrences(of: ".", with: "")
                properties["foregroundColor"] = colorName
            }
        }
        
        // Extract fontWeight modifier
        if let weightMatch = modifierString.range(of: #"\\.fontWeight\\(\\.([^)]+)\\)"#, options: .regularExpression) {
            let weightPart = String(modifierString[weightMatch])
            if let weightNameMatch = weightPart.range(of: #"\\.([^)]+)"#, options: .regularExpression) {
                let weightName = String(weightPart[weightNameMatch]).replacingOccurrences(of: ".", with: "")
                properties["fontWeight"] = weightName
            }
        }
        
        return properties
    }
    
    private func extractInteractions(from source: String) -> [ViewInteraction] {
        var interactions: [ViewInteraction] = []
        
        // Extract button actions
        let buttonActionPattern = #"Button\\("[^"]*"\\)\\s*\\{([^}]+)\\}"#
        let regex = try! NSRegularExpression(pattern: buttonActionPattern)
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        
        for (index, match) in matches.enumerated() {
            let actionRange = Range(match.range(at: 1), in: source)!
            let action = String(source[actionRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let interaction = ViewInteraction(
                name: "button_\(index)",
                type: .buttonTap,
                action: action,
                binding: ""
            )
            interactions.append(interaction)
            print("🔍 Found button interaction: \(action)")
        }
        
        return interactions
    }
}

// MARK: - Data Models

struct LiveCompiledView: Codable, Sendable {
    let viewName: String
    let originalCode: String
    let executableCode: String
    let stateVariables: [StateVariable]
    let viewStructure: ViewStructure
    let interactions: [ViewInteraction]
}

struct SwiftUIAnalysis: Sendable {
    let stateVariables: [StateVariable]
    let viewStructure: ViewStructure
    let interactions: [ViewInteraction]
    let computedProperties: [ComputedProperty]
}

struct StateVariable: Codable, Sendable {
    let name: String
    let type: String
    let defaultValue: DefaultValue
    let defaultValueString: String
}

enum DefaultValue: Codable, Sendable {
    case int(Int)
    case string(String)
    case bool(Bool)
    case double(Double)
    case raw(String)
    case none
    
    var swiftCode: String {
        switch self {
        case .int(let value): return "\(value)"
        case .string(let value): return "\"\(value)\""
        case .bool(let value): return "\(value)"
        case .double(let value): return "\(value)"
        case .raw(let value): return value
        case .none: return "nil"
        }
    }
}

struct ViewStructure: Codable, Sendable {
    let type: ViewType
    var properties: [String: AnyCodable] = [:]
    var children: [ViewStructure] = []
    
    func generateSwiftUICode() -> String {
        switch type {
        case .text:
            let content = properties["content"]?.value as? String ?? "Text"
            return "Text(\"\(content)\")"
        case .vstack:
            let childrenCode = children.map { $0.generateSwiftUICode() }.joined(separator: "\n            ")
            return """
            VStack {
                \(childrenCode)
            }
            """
        case .hstack:
            let childrenCode = children.map { $0.generateSwiftUICode() }.joined(separator: "\n            ")
            return """
            HStack {
                \(childrenCode)
            }
            """
        case .button:
            let title = properties["content"]?.value as? String ?? "Button"
            return """
            Button("\(title)") {
                // Action handled by interaction system
            }
            """
        case .container:
            return children.map { $0.generateSwiftUICode() }.joined(separator: "\n        ")
        }
    }
}

enum ViewType: String, Codable, Sendable {
    case text = "Text"
    case button = "Button"
    case vstack = "VStack"
    case hstack = "HStack"
    case container = "Container"
}

struct ViewInteraction: Codable, Sendable {
    let name: String
    let type: InteractionType
    let action: String
    let binding: String
}

enum InteractionType: Codable, Sendable {
    case buttonTap
    case textInput
    case toggle
}

struct ComputedProperty: Codable, Sendable {
    let name: String
    let returnType: String
    let body: String
}

// Helper for encoding Any values
struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = "unknown"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        default:
            try container.encode(String(describing: value))
        }
    }
}