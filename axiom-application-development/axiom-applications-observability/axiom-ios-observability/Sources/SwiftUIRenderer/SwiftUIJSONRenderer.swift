import SwiftUI
import HotReloadProtocol
import NetworkClient

public protocol SwiftUIJSONRendererDelegate: AnyObject {
    func renderer(_ renderer: SwiftUIJSONRenderer, didRenderView view: AnyView, from layout: SwiftUILayoutJSON)
    func renderer(_ renderer: SwiftUIJSONRenderer, didFailToRender error: SwiftUIRenderError)
    func renderer(_ renderer: SwiftUIJSONRenderer, didUpdateState state: [String: Any], for viewId: String)
}

@MainActor
public final class SwiftUIJSONRenderer: ObservableObject {
    
    public weak var delegate: SwiftUIJSONRendererDelegate?
    
    @Published public private(set) var currentLayout: SwiftUILayoutJSON?
    @Published public private(set) var renderedView: AnyView?
    @Published public private(set) var isRendering: Bool = false
    @Published public private(set) var lastError: SwiftUIRenderError?
    @Published public private(set) var renderingStats: RenderingStats = RenderingStats()
    
    private let configuration: SwiftUIRenderConfiguration
    private let viewFactory: SwiftUIViewFactory
    private let modifierApplicator: SwiftUIModifierApplicator
    private let stateManager: SwiftUIStateManager
    private let statePreservation: StatePreservation
    private let fallbackUIProvider: FallbackUIProvider
    
    // Rendering cache
    private var viewCache: [String: AnyView] = [:]
    private var propertyCache: [String: [String: Any]] = [:]
    
    public init(
        configuration: SwiftUIRenderConfiguration = SwiftUIRenderConfiguration(),
        stateManager: SwiftUIStateManager,
        statePreservation: StatePreservation? = nil
    ) {
        self.configuration = configuration
        self.stateManager = stateManager
        self.statePreservation = statePreservation ?? StatePreservation(
            configuration: configuration.enableStatePreservation ? 
                StatePreservationConfiguration.development() : 
                StatePreservationConfiguration.production()
        )
        self.viewFactory = SwiftUIViewFactory(configuration: configuration.viewFactoryConfig)
        self.modifierApplicator = SwiftUIModifierApplicator(configuration: configuration.modifierConfig)
        
        // Configure fallback UI based on render configuration
        let fallbackConfig = FallbackUIConfiguration(
            showDebugInfo: configuration.enableDebugInfo,
            enableAnimations: !configuration.strictModeEnabled
        )
        self.fallbackUIProvider = FallbackUIProvider(configuration: fallbackConfig)
    }
    
    // MARK: - Public API
    
    public func render(layout: SwiftUILayoutJSON) {
        Task { @MainActor in
            await performRender(layout: layout)
        }
    }
    
    public func render(from message: BaseMessage) throws {
        guard case .fileChanged(let payload) = message.payload else {
            throw SwiftUIRenderError.invalidMessage("Expected fileChanged message")
        }
        
        // Parse SwiftUI layout from file content
        let layout = try parseSwiftUILayout(from: payload.fileContent)
        render(layout: layout)
    }
    
    public func updateState(_ stateData: [String: AnyCodable], preserveExisting: Bool = true) {
        stateManager.updateState(stateData, preserveExisting: preserveExisting)
        
        // Re-render current layout with updated state
        if let layout = currentLayout {
            render(layout: layout)
        }
    }
    
    public func clearCache() {
        viewCache.removeAll()
        propertyCache.removeAll()
    }
    
    public func reset() {
        currentLayout = nil
        renderedView = nil
        lastError = nil
        stateManager.clearAllState()
        clearCache()
        
        if configuration.enableStatePreservation {
            statePreservation.clearAllPreservedState()
        }
    }
    
    // MARK: - Rendering Implementation
    
    private func performRender(layout: SwiftUILayoutJSON) async {
        let startTime = Date()
        isRendering = true
        lastError = nil
        
        do {
            // Validate layout
            try validateLayout(layout)
            
            // Handle state preservation
            if configuration.enableStatePreservation {
                handleStatePreservation(for: layout)
            }
            
            // Update current layout
            currentLayout = layout
            
            // Extract and update state from layout
            extractStateFromLayout(layout)
            
            // Render views
            let view = try await renderViews(layout.views)
            
            // Apply any global modifications
            let finalView = try applyGlobalModifications(to: view, layout: layout)
            
            // Update rendered view
            renderedView = finalView
            
            // Create snapshot after successful render
            if configuration.enableStatePreservation {
                createStateSnapshot(for: layout)
            }
            
            // Update stats
            let renderTime = Date().timeIntervalSince(startTime)
            updateRenderingStats(
                renderTime: renderTime,
                viewCount: countViews(in: layout.views),
                success: true
            )
            
            // Notify delegate
            delegate?.renderer(self, didRenderView: finalView, from: layout)
            
        } catch let error as SwiftUIRenderError {
            handleRenderError(error, renderTime: Date().timeIntervalSince(startTime))
        } catch {
            let renderError = SwiftUIRenderError.renderingFailed("Unexpected error: \(error.localizedDescription)")
            handleRenderError(renderError, renderTime: Date().timeIntervalSince(startTime))
        }
        
        isRendering = false
    }
    
    private func validateLayout(_ layout: SwiftUILayoutJSON) throws {
        if layout.views.isEmpty {
            throw SwiftUIRenderError.emptyLayout("Layout contains no views")
        }
        
        // Validate view hierarchy
        for view in layout.views {
            try validateViewRecursive(view)
        }
    }
    
    private func validateViewRecursive(_ view: SwiftUIViewJSON) throws {
        // Check if view type is supported
        if !SwiftUIViewRegistry.supportedViews.contains(view.type) {
            if configuration.strictModeEnabled {
                throw SwiftUIRenderError.unsupportedViewType(view.type)
            }
        }
        
        // Validate children recursively
        if let children = view.children {
            for child in children {
                try validateViewRecursive(child)
            }
        }
        
        // Validate modifiers
        if let modifiers = view.modifiers {
            for modifier in modifiers {
                if !SwiftUIViewRegistry.supportedModifiers.contains(modifier.name) && configuration.strictModeEnabled {
                    throw SwiftUIRenderError.unsupportedModifier(modifier.name)
                }
            }
        }
    }
    
    private func extractStateFromLayout(_ layout: SwiftUILayoutJSON) {
        for view in layout.views {
            extractStateFromViewRecursive(view)
        }
    }
    
    private func extractStateFromViewRecursive(_ view: SwiftUIViewJSON) {
        // Extract state values from view
        if let state = view.state {
            for (key, value) in state {
                stateManager.setState(key: key, value: value)
            }
        }
        
        // Process children recursively
        if let children = view.children {
            for child in children {
                extractStateFromViewRecursive(child)
            }
        }
    }
    
    private func renderViews(_ views: [SwiftUIViewJSON]) async throws -> AnyView {
        if views.count == 1 {
            return try await renderSingleView(views[0])
        } else {
            // Multiple root views - wrap in VStack
            let childViews = try await renderMultipleViews(views)
            return AnyView(
                VStack {
                    ForEach(Array(childViews.enumerated()), id: \.offset) { index, view in
                        view
                    }
                }
            )
        }
    }
    
    private func renderSingleView(_ view: SwiftUIViewJSON) async throws -> AnyView {
        // Check cache first
        if configuration.enableViewCaching, let cachedView = viewCache[view.id] {
            return cachedView
        }
        
        // Create base view
        let baseView = try viewFactory.createView(from: view, stateManager: stateManager)
        
        // Apply modifiers
        let modifiedView = try modifierApplicator.applyModifiers(
            to: baseView,
            modifiers: view.modifiers ?? [],
            stateManager: stateManager
        )
        
        // Render children if any
        let finalView: AnyView
        if let children = view.children, !children.isEmpty {
            let childViews = try await renderMultipleViews(children)
            finalView = try embedChildren(childViews, in: modifiedView, parentType: view.type)
        } else {
            finalView = modifiedView
        }
        
        // Cache if enabled
        if configuration.enableViewCaching {
            viewCache[view.id] = finalView
        }
        
        return finalView
    }
    
    private func renderMultipleViews(_ views: [SwiftUIViewJSON]) async throws -> [AnyView] {
        var renderedViews: [AnyView] = []
        
        for view in views {
            let renderedView = try await renderSingleView(view)
            renderedViews.append(renderedView)
        }
        
        return renderedViews
    }
    
    private func embedChildren(_ children: [AnyView], in parentView: AnyView, parentType: String) throws -> AnyView {
        // Handle different container types
        switch parentType.lowercased() {
        case "vstack":
            return AnyView(
                VStack {
                    parentView
                    ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                        child
                    }
                }
            )
        case "hstack":
            return AnyView(
                HStack {
                    parentView
                    ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                        child
                    }
                }
            )
        case "zstack":
            return AnyView(
                ZStack {
                    parentView
                    ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                        child
                    }
                }
            )
        default:
            // For non-container views, just return the parent
            return parentView
        }
    }
    
    private func applyGlobalModifications(to view: AnyView, layout: SwiftUILayoutJSON) throws -> AnyView {
        var modifiedView = view
        
        // Apply preview traits if available
        if let previewTraits = layout.metadata.previewTraits {
            modifiedView = try applyPreviewTraits(to: modifiedView, traits: previewTraits)
        }
        
        // Apply global configuration
        if configuration.enableSafeAreaHandling {
            modifiedView = AnyView(
                modifiedView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            )
        }
        
        return modifiedView
    }
    
    private func applyPreviewTraits(to view: AnyView, traits: PreviewTraits) throws -> AnyView {
        var modifiedView = view
        
        // Apply color scheme
        if let colorScheme = traits.colorScheme {
            let scheme: ColorScheme = colorScheme.lowercased() == "dark" ? .dark : .light
            modifiedView = AnyView(modifiedView.preferredColorScheme(scheme))
        }
        
        // Apply device-specific modifications based on device name
        if traits.deviceName != nil {
            // Could apply device-specific frame sizes here
        }
        
        return modifiedView
    }
    
    // MARK: - Utilities
    
    private func parseSwiftUILayout(from content: String) throws -> SwiftUILayoutJSON {
        guard let data = content.data(using: .utf8) else {
            throw SwiftUIRenderError.invalidJSON("Failed to convert content to data")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(SwiftUILayoutJSON.self, from: data)
        } catch {
            throw SwiftUIRenderError.invalidJSON("Failed to decode SwiftUI layout: \(error.localizedDescription)")
        }
    }
    
    private func countViews(in views: [SwiftUIViewJSON]) -> Int {
        var count = views.count
        for view in views {
            if let children = view.children {
                count += countViews(in: children)
            }
        }
        return count
    }
    
    private func updateRenderingStats(renderTime: TimeInterval, viewCount: Int, success: Bool) {
        renderingStats = RenderingStats(
            totalRenders: renderingStats.totalRenders + 1,
            successfulRenders: renderingStats.successfulRenders + (success ? 1 : 0),
            averageRenderTime: calculateAverageRenderTime(currentAverage: renderingStats.averageRenderTime, newTime: renderTime, totalRenders: renderingStats.totalRenders + 1),
            lastRenderTime: renderTime,
            lastViewCount: viewCount,
            lastRenderTimestamp: Date()
        )
    }
    
    private func calculateAverageRenderTime(currentAverage: TimeInterval, newTime: TimeInterval, totalRenders: Int) -> TimeInterval {
        return ((currentAverage * Double(totalRenders - 1)) + newTime) / Double(totalRenders)
    }
    
    private func handleRenderError(_ error: SwiftUIRenderError, renderTime: TimeInterval) {
        lastError = error
        
        updateRenderingStats(renderTime: renderTime, viewCount: 0, success: false)
        
        // Create enhanced fallback view if enabled
        if configuration.enableFallbackUI {
            renderedView = createEnhancedFallbackView(error: error)
        }
        
        delegate?.renderer(self, didFailToRender: error)
    }
    
    private func createEnhancedFallbackView(error: SwiftUIRenderError) -> AnyView {
        let context = RenderingContext(
            fileName: currentLayout?.metadata.fileName,
            viewCount: currentLayout?.views.count ?? 0,
            renderingTime: renderingStats.lastRenderTime,
            metadata: [
                "totalRenders": renderingStats.totalRenders,
                "successRate": renderingStats.successRate
            ]
        )
        
        return fallbackUIProvider.createRenderingErrorView(error: error, context: context)
    }
    
    // MARK: - State Preservation
    
    private func handleStatePreservation(for layout: SwiftUILayoutJSON) {
        // Attempt to restore compatible state
        let preservationResult = statePreservation.restoreState(for: layout, into: stateManager)
        
        if preservationResult.success {
            if configuration.enableDebugInfo {
                print("🔄 State preserved: \(preservationResult.restoredKeys.count) keys restored")
                if !preservationResult.incompatibleKeys.isEmpty {
                    print("⚠️ Incompatible keys: \(preservationResult.incompatibleKeys)")
                }
            }
        } else {
            if configuration.enableDebugInfo {
                print("❌ State preservation failed: \(preservationResult.reason ?? "Unknown reason")")
            }
        }
    }
    
    private func createStateSnapshot(for layout: SwiftUILayoutJSON) {
        let snapshot = statePreservation.createSnapshot(from: layout, stateManager: stateManager)
        
        if configuration.enableDebugInfo {
            print("📸 State snapshot created: \(snapshot.stateData.count) state keys")
        }
    }
    
    // MARK: - State Preservation Public API
    
    /// Get access to the state preservation manager
    public var statePreservationManager: StatePreservation {
        return statePreservation
    }
    
    /// Check if state should be preserved for a layout change
    public func shouldPreserveState(for newLayout: SwiftUILayoutJSON) -> Bool {
        return statePreservation.shouldPreserveState(from: currentLayout, to: newLayout)
    }
    
    /// Get state preservation statistics
    public func getStatePreservationStats() -> PreservationStats {
        return statePreservation.getPreservationStats()
    }
    
    /// Export state preservation data for debugging
    public func exportStatePreservationData() -> [String: Any] {
        return statePreservation.exportPreservationData()
    }
    
    // MARK: - Fallback UI Public API
    
    /// Create a loading view for connection states
    public func createLoadingView(message: String = "Connecting to hot reload server...") -> AnyView {
        return fallbackUIProvider.createLoadingView(message: message)
    }
    
    /// Create a disconnected view with reconnect functionality
    public func createDisconnectedView(onReconnect: @escaping () -> Void) -> AnyView {
        return fallbackUIProvider.createDisconnectedView(onReconnect: onReconnect)
    }
    
    /// Create a network error view
    public func createNetworkErrorView(error: NetworkError, onRetry: @escaping () -> Void) -> AnyView {
        return fallbackUIProvider.createConnectionErrorView(error: error, onRetry: onRetry)
    }
    
    /// Get the fallback UI provider for custom fallback views
    public var fallbackUI: FallbackUIProvider {
        return fallbackUIProvider
    }
}

// MARK: - Supporting Types

public struct RenderingStats {
    public let totalRenders: Int
    public let successfulRenders: Int
    public let averageRenderTime: TimeInterval
    public let lastRenderTime: TimeInterval
    public let lastViewCount: Int
    public let lastRenderTimestamp: Date
    
    public init(
        totalRenders: Int = 0,
        successfulRenders: Int = 0,
        averageRenderTime: TimeInterval = 0,
        lastRenderTime: TimeInterval = 0,
        lastViewCount: Int = 0,
        lastRenderTimestamp: Date = Date()
    ) {
        self.totalRenders = totalRenders
        self.successfulRenders = successfulRenders
        self.averageRenderTime = averageRenderTime
        self.lastRenderTime = lastRenderTime
        self.lastViewCount = lastViewCount
        self.lastRenderTimestamp = lastRenderTimestamp
    }
    
    public var successRate: Double {
        guard totalRenders > 0 else { return 0 }
        return Double(successfulRenders) / Double(totalRenders)
    }
}

public enum SwiftUIRenderError: Error, LocalizedError {
    case invalidMessage(String)
    case invalidJSON(String)
    case emptyLayout(String)
    case unsupportedViewType(String)
    case unsupportedModifier(String)
    case renderingFailed(String)
    case stateManagementFailed(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidMessage(let details):
            return "Invalid message: \(details)"
        case .invalidJSON(let details):
            return "Invalid JSON: \(details)"
        case .emptyLayout(let details):
            return "Empty layout: \(details)"
        case .unsupportedViewType(let type):
            return "Unsupported view type: \(type)"
        case .unsupportedModifier(let modifier):
            return "Unsupported modifier: \(modifier)"
        case .renderingFailed(let details):
            return "Rendering failed: \(details)"
        case .stateManagementFailed(let details):
            return "State management failed: \(details)"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        }
    }
}