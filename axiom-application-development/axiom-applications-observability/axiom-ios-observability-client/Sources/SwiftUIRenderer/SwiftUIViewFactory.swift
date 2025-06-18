import SwiftUI
import HotReloadProtocol

public final class SwiftUIViewFactory {
    
    private let configuration: SwiftUIViewFactoryConfiguration
    
    public init(configuration: SwiftUIViewFactoryConfiguration = SwiftUIViewFactoryConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - View Creation
    
    @MainActor
    public func createView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let viewType = viewJSON.type.lowercased()
        
        switch viewType {
        // Text Views
        case "text":
            return try createTextView(from: viewJSON, stateManager: stateManager)
            
        // Layout Views
        case "vstack":
            return try createVStackView(from: viewJSON, stateManager: stateManager)
        case "hstack":
            return try createHStackView(from: viewJSON, stateManager: stateManager)
        case "zstack":
            return try createZStackView(from: viewJSON, stateManager: stateManager)
        case "lazyvstack":
            return try createLazyVStackView(from: viewJSON, stateManager: stateManager)
        case "lazyhstack":
            return try createLazyHStackView(from: viewJSON, stateManager: stateManager)
            
        // Interactive Views
        case "button":
            return try createButtonView(from: viewJSON, stateManager: stateManager)
        case "toggle":
            return try createToggleView(from: viewJSON, stateManager: stateManager)
        case "slider":
            return try createSliderView(from: viewJSON, stateManager: stateManager)
        case "textfield":
            return try createTextFieldView(from: viewJSON, stateManager: stateManager)
        case "securefield":
            return try createSecureFieldView(from: viewJSON, stateManager: stateManager)
            
        // Image Views
        case "image":
            return try createImageView(from: viewJSON, stateManager: stateManager)
            
        // Shape Views
        case "rectangle":
            return try createRectangleView(from: viewJSON, stateManager: stateManager)
        case "circle":
            return try createCircleView(from: viewJSON, stateManager: stateManager)
        case "ellipse":
            return try createEllipseView(from: viewJSON, stateManager: stateManager)
        case "capsule":
            return try createCapsuleView(from: viewJSON, stateManager: stateManager)
        case "roundedrectangle":
            return try createRoundedRectangleView(from: viewJSON, stateManager: stateManager)
            
        // Utility Views
        case "spacer":
            return AnyView(Spacer())
        case "divider":
            return AnyView(Divider())
        case "emptyview":
            return AnyView(EmptyView())
            
        // List Views
        case "list":
            return try createListView(from: viewJSON, stateManager: stateManager)
        case "scrollview":
            return try createScrollView(from: viewJSON, stateManager: stateManager)
            
        // Navigation Views
        case "navigationview":
            return try createNavigationView(from: viewJSON, stateManager: stateManager)
        case "navigationstack":
            return try createNavigationStackView(from: viewJSON, stateManager: stateManager)
            
        default:
            if configuration.allowUnknownViews {
                return try createFallbackView(for: viewJSON.type)
            } else {
                throw SwiftUIViewFactoryError.unsupportedViewType(viewJSON.type)
            }
        }
    }
    
    // MARK: - Text Views
    
    private func createTextView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let content = extractStringProperty("content", from: viewJSON.properties) ?? 
                     extractStringProperty("text", from: viewJSON.properties) ?? 
                     "Text"
        
        return AnyView(Text(content))
    }
    
    // MARK: - Layout Views
    
    private func createVStackView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let alignment = extractAlignment(from: viewJSON.properties) ?? .center
        let spacing = extractDoubleProperty("spacing", from: viewJSON.properties)
        
        return AnyView(
            VStack(alignment: alignment, spacing: spacing) {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    private func createHStackView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let alignment = extractVerticalAlignment(from: viewJSON.properties) ?? .center
        let spacing = extractDoubleProperty("spacing", from: viewJSON.properties)
        
        return AnyView(
            HStack(alignment: alignment, spacing: spacing) {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    private func createZStackView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let alignment = extractFullAlignment(from: viewJSON.properties) ?? .center
        
        return AnyView(
            ZStack(alignment: alignment) {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    private func createLazyVStackView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let alignment = extractAlignment(from: viewJSON.properties) ?? .center
        let spacing = extractDoubleProperty("spacing", from: viewJSON.properties)
        
        return AnyView(
            LazyVStack(alignment: alignment, spacing: spacing) {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    private func createLazyHStackView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let alignment = extractVerticalAlignment(from: viewJSON.properties) ?? .center
        let spacing = extractDoubleProperty("spacing", from: viewJSON.properties)
        
        return AnyView(
            LazyHStack(alignment: alignment, spacing: spacing) {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    // MARK: - Interactive Views
    
    private func createButtonView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let title = extractStringProperty("title", from: viewJSON.properties) ?? "Button"
        let action = extractAction(from: viewJSON.properties, stateManager: stateManager)
        
        return AnyView(
            Button(title, action: action)
        )
    }
    
    @MainActor
    private func createToggleView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let title = extractStringProperty("title", from: viewJSON.properties) ?? ""
        let binding = extractBooleanBinding(from: viewJSON.properties, stateManager: stateManager) ?? .constant(false)
        
        return AnyView(
            Toggle(title, isOn: binding)
        )
    }
    
    @MainActor
    private func createSliderView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let binding = extractDoubleBinding(from: viewJSON.properties, stateManager: stateManager) ?? .constant(0.5)
        let range = extractDoubleRange(from: viewJSON.properties) ?? (0.0...1.0)
        
        return AnyView(
            Slider(value: binding, in: range)
        )
    }
    
    @MainActor
    private func createTextFieldView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let placeholder = extractStringProperty("placeholder", from: viewJSON.properties) ?? "Enter text"
        let binding = extractStringBinding(from: viewJSON.properties, stateManager: stateManager) ?? .constant("")
        
        return AnyView(
            TextField(placeholder, text: binding)
        )
    }
    
    @MainActor
    private func createSecureFieldView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let placeholder = extractStringProperty("placeholder", from: viewJSON.properties) ?? "Enter password"
        let binding = extractStringBinding(from: viewJSON.properties, stateManager: stateManager) ?? .constant("")
        
        return AnyView(
            SecureField(placeholder, text: binding)
        )
    }
    
    // MARK: - Image Views
    
    private func createImageView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        if let imageValue = extractImageProperty(from: viewJSON.properties) {
            switch imageValue.type {
            case .system:
                if let systemName = imageValue.systemName {
                    return AnyView(Image(systemName: systemName))
                }
            case .asset:
                if let name = imageValue.name {
                    return AnyView(Image(name))
                }
            case .url:
                // For URL images, would need AsyncImage (iOS 15+)
                return AnyView(Image(systemName: "photo"))
            case .data:
                // For data images, would need custom implementation
                return AnyView(Image(systemName: "photo"))
            }
        }
        
        return AnyView(Image(systemName: "photo"))
    }
    
    // MARK: - Shape Views
    
    private func createRectangleView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        return AnyView(Rectangle())
    }
    
    private func createCircleView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        return AnyView(Circle())
    }
    
    private func createEllipseView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        return AnyView(Ellipse())
    }
    
    private func createCapsuleView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        return AnyView(Capsule())
    }
    
    private func createRoundedRectangleView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let cornerRadius = extractDoubleProperty("cornerRadius", from: viewJSON.properties) ?? 10.0
        return AnyView(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    // MARK: - List Views
    
    private func createListView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        return AnyView(
            List {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    private func createScrollView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        let axes = extractScrollAxes(from: viewJSON.properties) ?? .vertical
        let showsIndicators = extractBooleanProperty("showsIndicators", from: viewJSON.properties) ?? true
        
        return AnyView(
            ScrollView(axes, showsIndicators: showsIndicators) {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    // MARK: - Navigation Views
    
    private func createNavigationView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        return AnyView(
            NavigationView {
                // Children will be added by the renderer
                EmptyView()
            }
        )
    }
    
    private func createNavigationStackView(from viewJSON: SwiftUIViewJSON, stateManager: SwiftUIStateManager) throws -> AnyView {
        if #available(macOS 13.0, iOS 16.0, *) {
            return AnyView(
                NavigationStack {
                    // Children will be added by the renderer
                    EmptyView()
                }
            )
        } else {
            return try createNavigationView(from: viewJSON, stateManager: stateManager)
        }
    }
    
    // MARK: - Fallback View
    
    private func createFallbackView(for viewType: String) throws -> AnyView {
        return AnyView(
            VStack {
                Image(systemName: "questionmark.square")
                    .foregroundColor(.secondary)
                Text("Unknown view: \(viewType)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        )
    }
    
    // MARK: - Property Extraction Helpers
    
    private func extractStringProperty(_ key: String, from properties: [String: PropertyValue]) -> String? {
        guard case .string(let value) = properties[key] else { return nil }
        return value
    }
    
    private func extractDoubleProperty(_ key: String, from properties: [String: PropertyValue]) -> CGFloat? {
        switch properties[key] {
        case .double(let value):
            return CGFloat(value)
        case .int(let value):
            return CGFloat(value)
        default:
            return nil
        }
    }
    
    private func extractBooleanProperty(_ key: String, from properties: [String: PropertyValue]) -> Bool? {
        guard case .bool(let value) = properties[key] else { return nil }
        return value
    }
    
    private func extractImageProperty(from properties: [String: PropertyValue]) -> ImageValue? {
        guard case .image(let value) = properties["image"] ?? properties["source"] else { return nil }
        return value
    }
    
    private func extractAlignment(from properties: [String: PropertyValue]) -> HorizontalAlignment? {
        guard case .alignment(let alignment) = properties["alignment"] else { return nil }
        
        switch alignment.horizontal.lowercased() {
        case "leading": return .leading
        case "center": return .center
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    private func extractFullAlignment(from properties: [String: PropertyValue]) -> Alignment? {
        guard case .alignment(let alignment) = properties["alignment"] else { return nil }
        
        let horizontalAlignment: HorizontalAlignment
        switch alignment.horizontal.lowercased() {
        case "leading": horizontalAlignment = .leading
        case "center": horizontalAlignment = .center
        case "trailing": horizontalAlignment = .trailing
        default: horizontalAlignment = .center
        }
        
        let verticalAlignment: VerticalAlignment
        switch alignment.vertical.lowercased() {
        case "top": verticalAlignment = .top
        case "center": verticalAlignment = .center
        case "bottom": verticalAlignment = .bottom
        default: verticalAlignment = .center
        }
        
        return Alignment(horizontal: horizontalAlignment, vertical: verticalAlignment)
    }
    
    private func extractVerticalAlignment(from properties: [String: PropertyValue]) -> VerticalAlignment? {
        guard case .alignment(let alignment) = properties["alignment"] else { return nil }
        
        switch alignment.vertical.lowercased() {
        case "top": return .top
        case "center": return .center
        case "bottom": return .bottom
        default: return .center
        }
    }
    
    private func extractScrollAxes(from properties: [String: PropertyValue]) -> Axis.Set? {
        guard let axesString = extractStringProperty("axes", from: properties) else { return nil }
        
        switch axesString.lowercased() {
        case "horizontal": return .horizontal
        case "vertical": return .vertical
        case "all": return [.horizontal, .vertical]
        default: return .vertical
        }
    }
    
    private func extractDoubleRange(from properties: [String: PropertyValue]) -> ClosedRange<Double>? {
        let min = extractDoubleProperty("min", from: properties) ?? 0.0
        let max = extractDoubleProperty("max", from: properties) ?? 1.0
        return Double(min)...Double(max)
    }
    
    private func extractAction(from properties: [String: PropertyValue], stateManager: SwiftUIStateManager) -> () -> Void {
        // For now, return empty action. In full implementation, would handle action binding
        return { }
    }
    
    @MainActor
    private func extractStringBinding(from properties: [String: PropertyValue], stateManager: SwiftUIStateManager) -> Binding<String>? {
        guard case .binding(let bindingValue) = properties["binding"] ?? properties["text"] else {
            return nil
        }
        
        return stateManager.getStringBinding(for: bindingValue.stateKey)
    }
    
    @MainActor
    private func extractBooleanBinding(from properties: [String: PropertyValue], stateManager: SwiftUIStateManager) -> Binding<Bool>? {
        guard case .binding(let bindingValue) = properties["binding"] ?? properties["isOn"] else {
            return nil
        }
        
        return stateManager.getBooleanBinding(for: bindingValue.stateKey)
    }
    
    @MainActor
    private func extractDoubleBinding(from properties: [String: PropertyValue], stateManager: SwiftUIStateManager) -> Binding<Double>? {
        guard case .binding(let bindingValue) = properties["binding"] ?? properties["value"] else {
            return nil
        }
        
        return stateManager.getDoubleBinding(for: bindingValue.stateKey)
    }
}

// MARK: - Configuration

public struct SwiftUIViewFactoryConfiguration {
    public let allowUnknownViews: Bool
    public let enableDebugMode: Bool
    public let fallbackViewColor: Color
    
    public init(
        allowUnknownViews: Bool = true,
        enableDebugMode: Bool = false,
        fallbackViewColor: Color = .gray
    ) {
        self.allowUnknownViews = allowUnknownViews
        self.enableDebugMode = enableDebugMode
        self.fallbackViewColor = fallbackViewColor
    }
    
    public static func production() -> SwiftUIViewFactoryConfiguration {
        return SwiftUIViewFactoryConfiguration(
            allowUnknownViews: false,
            enableDebugMode: false
        )
    }
    
    public static func development() -> SwiftUIViewFactoryConfiguration {
        return SwiftUIViewFactoryConfiguration(
            allowUnknownViews: true,
            enableDebugMode: true
        )
    }
}

// MARK: - Errors

public enum SwiftUIViewFactoryError: Error, LocalizedError {
    case unsupportedViewType(String)
    case invalidProperties(String)
    case bindingCreationFailed(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedViewType(let type):
            return "Unsupported view type: \(type)"
        case .invalidProperties(let details):
            return "Invalid properties: \(details)"
        case .bindingCreationFailed(let details):
            return "Binding creation failed: \(details)"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        }
    }
}