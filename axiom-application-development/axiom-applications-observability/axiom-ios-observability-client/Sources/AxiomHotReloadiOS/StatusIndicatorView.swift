import SwiftUI
import NetworkClient

// MARK: - Enhanced Status Indicator View

/// Advanced visual indicator showing hot reload connection status with user feedback
public struct StatusIndicatorView: View {
    
    let connectionState: ConnectionState
    let configuration: AxiomHotReloadConfiguration
    
    @State private var isAnimating = false
    @State private var showTooltip = false
    @State private var lastStatusChange = Date()
    @State private var connectionQuality: ConnectionQuality = .unknown
    
    public init(
        connectionState: ConnectionState,
        configuration: AxiomHotReloadConfiguration
    ) {
        self.connectionState = connectionState
        self.configuration = configuration
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Enhanced status indicator dot with pulse animation
            statusIndicatorDot
                .frame(
                    width: configuration.statusIndicatorSize.width,
                    height: configuration.statusIndicatorSize.height
                )
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    connectionState == .connecting || connectionState == .reconnecting ? 
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                        .easeInOut(duration: 0.3),
                    value: isAnimating
                )
                .onAppear {
                    updateAnimation()
                }
                .onChange(of: connectionState) { _ in
                    lastStatusChange = Date()
                    updateAnimation()
                }
            
            // Status text with improved styling
            if configuration.showStatusText {
                statusText
                    .font(.caption2)
                    .foregroundColor(statusTextColor)
                    .lineLimit(1)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Connection quality indicator
            if configuration.showConnectionQuality && connectionState == .connected {
                connectionQualityIndicator
                    .transition(.slide)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            enhancedBackground
        )
        .overlay(
            tooltipOverlay
        )
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture {
            handleLongPress()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hot reload connection status")
        .accessibilityValue(statusDisplayText)
        .accessibilityHint("Tap for details, long press for actions")
    }
    
    // MARK: - Enhanced UI Components
    
    @ViewBuilder
    private var statusIndicatorDot: some View {
        Circle()
            .fill(statusColor)
            .overlay(
                // Pulse ring for connecting states
                Group {
                    if connectionState == .connecting || connectionState == .reconnecting {
                        Circle()
                            .stroke(statusColor.opacity(0.5), lineWidth: 2)
                            .scaleEffect(isAnimating ? 2.0 : 1.0)
                            .opacity(isAnimating ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                }
            )
            .overlay(
                // Error indicator
                Group {
                    if connectionState == .error {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            )
            .overlay(
                // Success indicator
                Group {
                    if connectionState == .connected && configuration.showSuccessIndicator {
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            )
    }
    
    @ViewBuilder
    private var statusText: some View {
        Text(statusDisplayText)
            .fontWeight(.medium)
            .animation(.easeInOut(duration: 0.2), value: connectionState)
    }
    
    @ViewBuilder
    private var connectionQualityIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                qualityBar(for: index)
            }
        }
    }
    
    @ViewBuilder
    private func qualityBar(for index: Int) -> some View {
        let color = qualityBarColor(for: index)
        let height = CGFloat(6 + index * 3)
        
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: 3, height: height)
            .animation(.easeInOut.delay(Double(index) * 0.1), value: connectionQuality)
    }
    
    @ViewBuilder
    private var enhancedBackground: some View {
        if configuration.showStatusBackground {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        } else {
            Capsule()
                .fill(Color.black.opacity(0.05))
        }
    }
    
    @ViewBuilder
    private var tooltipOverlay: some View {
        if showTooltip {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusDisplayText)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text(statusDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if connectionState == .connected && configuration.showDebugInfo {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quality: \(connectionQuality.displayName)")
                        Text("Updated: \(lastStatusChange, formatter: timeFormatter)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                if connectionState == .error {
                    Button("Retry Connection") {
                        // This would trigger a reconnection attempt
                        showTooltip = false
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .offset(y: -80)
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .zIndex(1000)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return configuration.statusIndicatorColors.connected
        case .connecting, .reconnecting:
            return configuration.statusIndicatorColors.connecting
        case .disconnected:
            return configuration.statusIndicatorColors.disconnected
        case .error:
            return configuration.statusIndicatorColors.error
        }
    }
    
    private var statusTextColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .secondary
        case .error:
            return .red
        }
    }
    
    private var statusDisplayText: String {
        switch connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting:
            return "Reconnecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        }
    }
    
    private var statusDescription: String {
        switch connectionState {
        case .connected:
            return "Hot reload is active and monitoring file changes"
        case .connecting:
            return "Establishing connection to development server"
        case .reconnecting:
            return "Attempting to restore connection"
        case .disconnected:
            return "Not connected to hot reload server"
        case .error:
            return "Connection failed - tap to retry"
        }
    }
    
    private func qualityBarColor(for index: Int) -> Color {
        let activeBarCount: Int
        switch connectionQuality {
        case .excellent:
            activeBarCount = 3
        case .good:
            activeBarCount = 3
        case .fair:
            activeBarCount = 2
        case .poor:
            activeBarCount = 1
        case .unavailable, .unknown:
            activeBarCount = 0
        }
        
        return index < activeBarCount ? statusColor : .gray.opacity(0.3)
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        if configuration.enableStatusTooltip {
            withAnimation(.spring()) {
                showTooltip.toggle()
            }
            
            // Auto-hide tooltip
            if showTooltip {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeOut) {
                        showTooltip = false
                    }
                }
            }
        }
    }
    
    private func handleLongPress() {
        if configuration.enableDebugMode {
            // Could trigger debug actions like force reconnect, show diagnostics, etc.
            showTooltip = true
            
            // Haptic feedback
            #if canImport(UIKit) && !os(macOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
        }
    }
    
    // MARK: - Animation Control
    
    private func updateAnimation() {
        withAnimation {
            isAnimating = connectionState == .connecting || connectionState == .reconnecting
        }
    }
    
    // MARK: - Formatters
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }
}

// MARK: - Enhanced Configuration Extensions

public extension AxiomHotReloadConfiguration {
    
    /// Show status text alongside the indicator
    var showStatusText: Bool {
        enableDebugMode || showDebugInfo
    }
    
    /// Show connection quality bars
    var showConnectionQuality: Bool {
        enableDebugMode
    }
    
    /// Show background behind status indicator
    var showStatusBackground: Bool {
        enableDebugMode
    }
    
    /// Enable status tooltip on tap
    var enableStatusTooltip: Bool {
        true
    }
    
    /// Show success checkmark when connected
    var showSuccessIndicator: Bool {
        enableDebugMode
    }
}

// MARK: - Connection Quality Extension

public extension ConnectionQuality {
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .unavailable:
            return "Unavailable"
        case .unknown:
            return "Unknown"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct StatusIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Group {
                StatusIndicatorView(
                    connectionState: .connected,
                    configuration: .development()
                )
                .previewDisplayName("Connected")
                
                StatusIndicatorView(
                    connectionState: .connecting,
                    configuration: .development()
                )
                .previewDisplayName("Connecting")
                
                StatusIndicatorView(
                    connectionState: .reconnecting,
                    configuration: .development()
                )
                .previewDisplayName("Reconnecting")
                
                StatusIndicatorView(
                    connectionState: .disconnected,
                    configuration: .development()
                )
                .previewDisplayName("Disconnected")
                
                StatusIndicatorView(
                    connectionState: .error,
                    configuration: .development()
                )
                .previewDisplayName("Error")
            }
            
            Divider()
            
            // Production style previews
            Group {
                StatusIndicatorView(
                    connectionState: .connected,
                    configuration: .production()
                )
                .previewDisplayName("Production - Connected")
                
                StatusIndicatorView(
                    connectionState: .error,
                    configuration: .production()
                )
                .previewDisplayName("Production - Error")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
#endif