import SwiftUI
import HotReloadProtocol
import NetworkClient

// MARK: - Comprehensive Fallback UI System

/// Enhanced fallback UI system for rendering errors and connection issues
public struct FallbackUIProvider {
    
    private let configuration: FallbackUIConfiguration
    
    public init(configuration: FallbackUIConfiguration = FallbackUIConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Fallback View Creation
    
    /// Create fallback view for rendering errors
    public func createRenderingErrorView(
        error: SwiftUIRenderError,
        context: RenderingContext? = nil
    ) -> AnyView {
        switch error {
        case .invalidJSON(let details):
            return createJSONErrorView(details: details)
        case .unsupportedViewType(let type):
            return createUnsupportedViewView(viewType: type)
        case .renderingFailed(let details):
            return createRenderingFailedView(details: details)
        case .emptyLayout(let details):
            return createEmptyLayoutView(details: details)
        default:
            return createGenericErrorView(error: error)
        }
    }
    
    /// Create fallback view for connection errors
    public func createConnectionErrorView(
        error: NetworkError,
        onRetry: @escaping () -> Void
    ) -> AnyView {
        switch error.type {
        case .networkUnavailable:
            return createNetworkUnavailableView(onRetry: onRetry)
        case .serverUnreachable:
            return createServerUnreachableView(error: error, onRetry: onRetry)
        case .timeout:
            return createTimeoutErrorView(onRetry: onRetry)
        case .connectionFailed:
            return createConnectionFailedView(error: error, onRetry: onRetry)
        default:
            return createGenericConnectionErrorView(error: error, onRetry: onRetry)
        }
    }
    
    /// Create loading state view
    public func createLoadingView(message: String = "Connecting...") -> AnyView {
        return AnyView(
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: configuration.accentColor))
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if configuration.showDebugInfo {
                    Text("Hot Reload connecting to server")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(configuration.backgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding()
        )
    }
    
    /// Create disconnected state view
    public func createDisconnectedView(
        onReconnect: @escaping () -> Void
    ) -> AnyView {
        return AnyView(
            VStack(spacing: 20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Hot Reload Disconnected")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Connection to the development server was lost")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: onReconnect) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reconnect")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(configuration.accentColor)
                    .cornerRadius(8)
                }
                
                if configuration.showDebugInfo {
                    Text("Showing fallback content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            }
            .padding()
            .background(configuration.backgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            .padding()
        )
    }
    
    // MARK: - Specific Error Views
    
    private func createJSONErrorView(details: String) -> AnyView {
        return AnyView(
            ErrorCardView(
                icon: "doc.text.fill",
                iconColor: .red,
                title: "JSON Parsing Error",
                description: "The SwiftUI layout data couldn't be parsed.",
                details: configuration.showDebugInfo ? details : nil,
                suggestions: [
                    "Check the server output for syntax errors",
                    "Verify the SwiftUI code compiles correctly",
                    "Restart the hot reload server"
                ],
                configuration: configuration
            )
        )
    }
    
    private func createUnsupportedViewView(viewType: String) -> AnyView {
        return AnyView(
            ErrorCardView(
                icon: "questionmark.square.fill",
                iconColor: .orange,
                title: "Unsupported View",
                description: "The view type '\(viewType)' is not yet supported.",
                details: nil,
                suggestions: [
                    "Use a supported SwiftUI view instead",
                    "Check if the view name is spelled correctly",
                    "This feature may be added in future updates"
                ],
                configuration: configuration
            )
        )
    }
    
    private func createRenderingFailedView(details: String) -> AnyView {
        return AnyView(
            ErrorCardView(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Rendering Failed",
                description: "An error occurred while rendering the SwiftUI view.",
                details: configuration.showDebugInfo ? details : nil,
                suggestions: [
                    "Check for binding or state errors",
                    "Verify all required properties are provided",
                    "Try simplifying the view structure"
                ],
                configuration: configuration
            )
        )
    }
    
    private func createEmptyLayoutView(details: String) -> AnyView {
        return AnyView(
            ErrorCardView(
                icon: "rectangle.dashed",
                iconColor: .gray,
                title: "Empty Layout",
                description: "No views were found in the layout.",
                details: nil,
                suggestions: [
                    "Add some SwiftUI views to your code",
                    "Check if the file is being watched correctly",
                    "Verify the server is parsing the file"
                ],
                configuration: configuration
            )
        )
    }
    
    private func createGenericErrorView(error: SwiftUIRenderError) -> AnyView {
        return AnyView(
            ErrorCardView(
                icon: "exclamationmark.circle.fill",
                iconColor: .red,
                title: "Hot Reload Error",
                description: error.localizedDescription,
                details: configuration.showDebugInfo ? String(describing: error) : nil,
                suggestions: [
                    "Try refreshing the hot reload connection",
                    "Check the server logs for more details",
                    "Restart the development server"
                ],
                configuration: configuration
            )
        )
    }
    
    private func createNetworkUnavailableView(onRetry: @escaping () -> Void) -> AnyView {
        return AnyView(
            NetworkErrorCardView(
                icon: "wifi.slash",
                iconColor: .red,
                title: "No Internet Connection",
                description: "Please check your network connection and try again.",
                details: nil,
                onRetry: onRetry,
                configuration: configuration
            )
        )
    }
    
    private func createServerUnreachableView(error: NetworkError, onRetry: @escaping () -> Void) -> AnyView {
        return AnyView(
            NetworkErrorCardView(
                icon: "server.rack",
                iconColor: .orange,
                title: "Server Unreachable",
                description: "Cannot connect to the hot reload server.",
                details: configuration.showDebugInfo ? "Make sure the development server is running on your local machine." : nil,
                onRetry: onRetry,
                configuration: configuration
            )
        )
    }
    
    private func createTimeoutErrorView(onRetry: @escaping () -> Void) -> AnyView {
        return AnyView(
            NetworkErrorCardView(
                icon: "clock.fill",
                iconColor: .yellow,
                title: "Connection Timeout",
                description: "The connection took too long to respond.",
                details: nil,
                onRetry: onRetry,
                configuration: configuration
            )
        )
    }
    
    private func createConnectionFailedView(error: NetworkError, onRetry: @escaping () -> Void) -> AnyView {
        return AnyView(
            NetworkErrorCardView(
                icon: "network.slash",
                iconColor: .red,
                title: "Connection Failed",
                description: "Failed to establish connection to the server.",
                details: configuration.showDebugInfo ? error.localizedDescription : nil,
                onRetry: onRetry,
                configuration: configuration
            )
        )
    }
    
    private func createGenericConnectionErrorView(error: NetworkError, onRetry: @escaping () -> Void) -> AnyView {
        return AnyView(
            NetworkErrorCardView(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Connection Error",
                description: error.localizedDescription,
                details: nil,
                onRetry: onRetry,
                configuration: configuration
            )
        )
    }
}

// MARK: - Error Card Views

private struct ErrorCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let details: String?
    let suggestions: [String]
    let configuration: FallbackUIConfiguration
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(iconColor)
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Suggestions
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try this:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16, alignment: .leading)
                            
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Debug details (if enabled)
            if let details = details, configuration.showDebugInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showDetails.toggle() }) {
                        HStack {
                            Text("Debug Details")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if showDetails {
                        ScrollView {
                            Text(details)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .frame(maxHeight: 100)
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(configuration.backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding()
    }
}

private struct NetworkErrorCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let details: String?
    let onRetry: () -> Void
    let configuration: FallbackUIConfiguration
    
    @State private var isRetrying = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(iconColor)
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Debug details (if available)
            if let details = details {
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Retry button
            Button(action: performRetry) {
                HStack {
                    if isRetrying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Text(isRetrying ? "Retrying..." : "Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(configuration.accentColor)
                .cornerRadius(8)
            }
            .disabled(isRetrying)
            
            if configuration.showDebugInfo {
                Text("Network error recovery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(configuration.backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding()
    }
    
    private func performRetry() {
        isRetrying = true
        onRetry()
        
        // Reset state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isRetrying = false
        }
    }
}

// MARK: - Configuration

public struct FallbackUIConfiguration {
    public let backgroundColor: Color
    public let accentColor: Color
    public let showDebugInfo: Bool
    public let enableAnimations: Bool
    public let cornerRadius: CGFloat
    public let shadowEnabled: Bool
    
    public init(
        backgroundColor: Color = {
            #if canImport(UIKit) && !os(macOS)
            return Color(.systemBackground)
            #else
            return Color.white
            #endif
        }(),
        accentColor: Color = .blue,
        showDebugInfo: Bool = false,
        enableAnimations: Bool = true,
        cornerRadius: CGFloat = 16,
        shadowEnabled: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.showDebugInfo = showDebugInfo
        self.enableAnimations = enableAnimations
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
    }
    
    public static func development() -> FallbackUIConfiguration {
        return FallbackUIConfiguration(
            showDebugInfo: true,
            enableAnimations: true
        )
    }
    
    public static func production() -> FallbackUIConfiguration {
        return FallbackUIConfiguration(
            showDebugInfo: false,
            enableAnimations: false
        )
    }
}

// MARK: - Supporting Types

public struct RenderingContext {
    public let fileName: String?
    public let viewCount: Int
    public let renderingTime: TimeInterval?
    public let metadata: [String: Any]
    
    public init(
        fileName: String? = nil,
        viewCount: Int = 0,
        renderingTime: TimeInterval? = nil,
        metadata: [String: Any] = [:]
    ) {
        self.fileName = fileName
        self.viewCount = viewCount
        self.renderingTime = renderingTime
        self.metadata = metadata
    }
}