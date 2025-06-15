import SwiftUI
import Foundation

@MainActor
class LiveExecutionEngine: ObservableObject {
    @Published var currentLiveView: AnyView?
    @Published var stateManager = LiveStateManager()
    @Published var isExecuting = false
    
    private var currentViewName: String?
    
    func executeCompiledView(_ compiledView: LiveCompiledView) {
        print("🚀 LiveExecutionEngine: Executing \(compiledView.viewName)")
        isExecuting = true
        currentViewName = compiledView.viewName
        
        // 1. Initialize state variables
        initializeState(compiledView.stateVariables)
        
        // 2. Generate live SwiftUI view
        let liveView = generateLiveView(from: compiledView)
        
        // 3. Update published view
        currentLiveView = liveView
        isExecuting = false
        
        print("✅ LiveExecutionEngine: Successfully executing \(compiledView.viewName)")
    }
    
    private func initializeState(_ stateVariables: [StateVariable]) {
        print("🔧 Initializing \(stateVariables.count) state variables")
        
        for stateVar in stateVariables {
            switch stateVar.defaultValue {
            case .int(let value):
                stateManager.setValue(value, for: stateVar.name)
            case .string(let value):
                stateManager.setValue(value, for: stateVar.name)
            case .bool(let value):
                stateManager.setValue(value, for: stateVar.name)
            case .double(let value):
                stateManager.setValue(value, for: stateVar.name)
            case .raw(let value):
                stateManager.setValue(value, for: stateVar.name)
            case .none:
                stateManager.setValue(Optional<Any>.none as Any?, for: stateVar.name)
            }
            print("🔧 Set \(stateVar.name) = \(stateVar.defaultValue)")
        }
    }
    
    private func generateLiveView(from compiledView: LiveCompiledView) -> AnyView {
        print("🎨 Generating live view for \(compiledView.viewName)")
        
        let view = LiveViewBuilder.buildView(
            structure: compiledView.viewStructure,
            stateManager: stateManager,
            interactions: compiledView.interactions
        )
        
        return AnyView(view)
    }
}

// MARK: - Live State Manager

@MainActor
class LiveStateManager: ObservableObject {
    @Published var state: [String: Any] = [:]
    
    func setValue<T>(_ value: T, for key: String) {
        state[key] = value
        objectWillChange.send()
        print("📊 State updated: \(key) = \(value)")
    }
    
    func getValue<T>(for key: String, as type: T.Type) -> T? {
        return state[key] as? T
    }
    
    func getValue(for key: String) -> Any? {
        return state[key]
    }
    
    func increment(_ key: String) {
        if let current = state[key] as? Int {
            setValue(current + 1, for: key)
        }
    }
    
    func decrement(_ key: String) {
        if let current = state[key] as? Int {
            setValue(current - 1, for: key)
        }
    }
    
    func toggle(_ key: String) {
        if let current = state[key] as? Bool {
            setValue(!current, for: key)
        }
    }
    
    func reset(_ key: String, to defaultValue: Any) {
        setValue(defaultValue, for: key)
    }
}

// MARK: - Live View Builder

struct LiveViewBuilder {
    static func buildView(
        structure: ViewStructure,
        stateManager: LiveStateManager,
        interactions: [ViewInteraction]
    ) -> some View {
        Group {
            switch structure.type {
            case .text:
                buildText(structure: structure, stateManager: stateManager)
            case .button:
                buildButton(structure: structure, stateManager: stateManager, interactions: interactions)
            case .vstack:
                buildVStack(structure: structure, stateManager: stateManager, interactions: interactions)
            case .hstack:
                buildHStack(structure: structure, stateManager: stateManager, interactions: interactions)
            case .container:
                buildContainer(structure: structure, stateManager: stateManager, interactions: interactions)
            }
        }
    }
    
    @ViewBuilder
    static func buildText(structure: ViewStructure, stateManager: LiveStateManager) -> some View {
        if let contentObj = structure.properties["content"], let content = contentObj.value as? String {
            // Check if content contains state variable interpolation
            if content.contains("\\(") {
                buildDynamicText(template: content, stateManager: stateManager)
            } else {
                Text(content)
            }
        } else {
            Text("Dynamic Text")
        }
    }
    
    @ViewBuilder
    static func buildDynamicText(template: String, stateManager: LiveStateManager) -> some View {
        // For now, show the template as-is since we can't call async from here
        Text(template)
    }
    
    @ViewBuilder
    static func buildButton(
        structure: ViewStructure,
        stateManager: LiveStateManager,
        interactions: [ViewInteraction]
    ) -> some View {
        let title = structure.properties["content"]?.value as? String ?? "Button"
        
        Button(title) {
            executeButtonAction(title: title, interactions: interactions, stateManager: stateManager)
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    static func buildVStack(
        structure: ViewStructure,
        stateManager: LiveStateManager,
        interactions: [ViewInteraction]
    ) -> some View {
        VStack(spacing: 20) {
            ForEach(0..<structure.children.count, id: \.self) { index in
                buildView(
                    structure: structure.children[index],
                    stateManager: stateManager,
                    interactions: interactions
                )
            }
        }
    }
    
    @ViewBuilder
    static func buildHStack(
        structure: ViewStructure,
        stateManager: LiveStateManager,
        interactions: [ViewInteraction]
    ) -> some View {
        HStack(spacing: 20) {
            ForEach(0..<structure.children.count, id: \.self) { index in
                buildView(
                    structure: structure.children[index],
                    stateManager: stateManager,
                    interactions: interactions
                )
            }
        }
    }
    
    @ViewBuilder
    static func buildContainer(
        structure: ViewStructure,
        stateManager: LiveStateManager,
        interactions: [ViewInteraction]
    ) -> some View {
        VStack {
            ForEach(0..<structure.children.count, id: \.self) { index in
                buildView(
                    structure: structure.children[index],
                    stateManager: stateManager,
                    interactions: interactions
                )
            }
        }
    }
    
    @MainActor
    static func resolveDynamicContent(template: String, stateManager: LiveStateManager) -> String {
        var resolved = template
        
        // Find all \\(variableName) patterns
        let pattern = #"\\(([^)]+)\\)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        // Replace each match with actual state value
        for match in matches.reversed() { // Reverse to maintain string indices
            let matchRange = Range(match.range, in: template)!
            let variableRange = Range(match.range(at: 1), in: template)!
            let variableName = String(template[variableRange])
            
            if let value = stateManager.getValue(for: variableName) {
                resolved.replaceSubrange(matchRange, with: "\\(value)")
            }
        }
        
        return resolved
    }
    
    @MainActor
    static func executeButtonAction(
        title: String,
        interactions: [ViewInteraction],
        stateManager: LiveStateManager
    ) {
        print("🎯 Button tapped: \(title)")
        
        // Simple action mapping based on button text
        if title.lowercased().contains("add") || title.contains("+") {
            stateManager.increment("counter")
        } else if title.lowercased().contains("subtract") || title.contains("-") {
            stateManager.decrement("counter")
        } else if title.lowercased().contains("reset") {
            stateManager.reset("counter", to: 0)
        }
        
        // TODO: Parse actual action code from interactions
        for interaction in interactions {
            if interaction.type == .buttonTap && interaction.name.lowercased().contains(title.lowercased()) {
                executeAction(interaction.action, stateManager: stateManager)
            }
        }
    }
    
    @MainActor
    static func executeAction(_ action: String, stateManager: LiveStateManager) {
        print("🎯 Executing action: \(action)")
        
        // Parse simple actions like "counter += 1", "counter = 0", etc.
        if action.contains("+=") {
            let parts = action.components(separatedBy: "+=")
            if parts.count == 2 {
                let variable = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if let increment = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                    if let current = stateManager.getValue(for: variable, as: Int.self) {
                        stateManager.setValue(current + increment, for: variable)
                    }
                }
            }
        } else if action.contains("-=") {
            let parts = action.components(separatedBy: "-=")
            if parts.count == 2 {
                let variable = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if let decrement = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                    if let current = stateManager.getValue(for: variable, as: Int.self) {
                        stateManager.setValue(current - decrement, for: variable)
                    }
                }
            }
        } else if action.contains("=") && !action.contains("==") {
            let parts = action.components(separatedBy: "=")
            if parts.count == 2 {
                let variable = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let intValue = Int(value) {
                    stateManager.setValue(intValue, for: variable)
                } else if value == "true" || value == "false" {
                    stateManager.setValue(value == "true", for: variable)
                } else {
                    stateManager.setValue(value, for: variable)
                }
            }
        }
    }
}

// MARK: - View Modifiers Extension

extension View {
    @ViewBuilder
    func applyModifiers(_ properties: [String: AnyCodable]) -> some View {
        let baseView = AnyView(self)
        
        if let fontObj = properties["font"], let font = fontObj.value as? String {
            let fontView = AnyView(baseView.font(parseFont(font)))
            if let colorObj = properties["foregroundColor"], let color = colorObj.value as? String {
                let colorView = AnyView(fontView.foregroundColor(parseColor(color)))
                if let weightObj = properties["fontWeight"], let weight = weightObj.value as? String {
                    AnyView(colorView.fontWeight(parseFontWeight(weight)))
                } else {
                    colorView
                }
            } else if let weightObj = properties["fontWeight"], let weight = weightObj.value as? String {
                AnyView(fontView.fontWeight(parseFontWeight(weight)))
            } else {
                fontView
            }
        } else if let colorObj = properties["foregroundColor"], let color = colorObj.value as? String {
            let colorView = AnyView(baseView.foregroundColor(parseColor(color)))
            if let weightObj = properties["fontWeight"], let weight = weightObj.value as? String {
                AnyView(colorView.fontWeight(parseFontWeight(weight)))
            } else {
                colorView
            }
        } else if let weightObj = properties["fontWeight"], let weight = weightObj.value as? String {
            AnyView(baseView.fontWeight(parseFontWeight(weight)))
        } else {
            baseView
        }
    }
    
    private func parseFont(_ fontString: String) -> Font {
        switch fontString.lowercased() {
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
        default: return .body
        }
    }
    
    private func parseColor(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "primary": return .primary
        case "secondary": return .secondary
        default: return .primary
        }
    }
    
    private func parseFontWeight(_ weightString: String) -> Font.Weight {
        switch weightString.lowercased() {
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
}

// MARK: - Data Models (duplicated from macOS for iOS)

struct LiveCompiledView: Codable, Sendable {
    let viewName: String
    let originalCode: String
    let executableCode: String
    let stateVariables: [StateVariable]
    let viewStructure: ViewStructure
    let interactions: [ViewInteraction]
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
}

struct ViewStructure: Codable, Sendable {
    let type: ViewType
    var properties: [String: AnyCodable] = [:]
    var children: [ViewStructure] = []
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