import SwiftUI

// Use ErrorSeverity from ErrorFoundation directly

// MARK: - Recovery Option Protocol

/// Protocol for recovery options that can be displayed in UI
public protocol RecoveryOption: Hashable, CaseIterable, Sendable {
    var title: String { get }
    var description: String { get }
    var icon: String { get }
    var isPrimary: Bool { get }
}

// MARK: - Error Icon View

/// Icon view for different error severities
public struct ErrorIconView: View {
    let severity: ErrorSeverity
    let size: CGFloat
    
    public init(severity: ErrorSeverity, size: CGFloat = 48) {
        self.severity = severity
        self.size = size
    }
    
    public var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundColor(iconColor)
            .accessibilityLabel(Text("Error icon for \(String(describing: severity)) severity"))
    }
    
    private var iconName: String {
        switch severity {
        case .debug, .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
    
    private var iconColor: Color {
        switch severity {
        case .debug, .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        }
    }
}

// MARK: - Recovery Action Button

/// Button for recovery actions with proper styling and accessibility
public struct RecoveryActionButton<Option: RecoveryOption>: View {
    let option: Option
    let onTap: () async -> Void
    let isLoading: Bool
    
    public init(
        option: Option,
        isLoading: Bool = false,
        onTap: @escaping () async -> Void
    ) {
        self.option = option
        self.isLoading = isLoading
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: {
            Task {
                await onTap()
            }
        }) {
            HStack {
                if !option.icon.isEmpty {
                    Image(systemName: option.icon)
                        .foregroundColor(option.isPrimary ? .white : .accentColor)
                }
                
                Text(option.title)
                    .fontWeight(option.isPrimary ? .semibold : .regular)
                    .foregroundColor(option.isPrimary ? .white : .accentColor)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: option.isPrimary ? .white : .accentColor))
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(option.isPrimary ? Color.accentColor : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: option.isPrimary ? 0 : 1)
                    )
            )
        }
        .disabled(isLoading)
        .accessibilityLabel(Text(option.title))
        .accessibilityHint(Text(option.description))
        .accessibilityAddTraits(option.isPrimary ? .isButton : [])
    }
}

// MARK: - Error Recovery View

/// Main error recovery view with standardized styling and accessibility
public struct ErrorRecoveryView<Option: RecoveryOption>: View {
    let error: AxiomError
    let recoveryOptions: [Option]
    let onRecovery: @Sendable (Option) async -> Void
    let onDismiss: () -> Void
    
    private let isRecovering = false
    private let recoveryProgress: Double = 0
    private let activeRecoveryOption: Option? = nil
    
    public init(
        error: AxiomError,
        recoveryOptions: [Option],
        onRecovery: @escaping @Sendable (Option) async -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.error = error
        self.recoveryOptions = recoveryOptions
        self.onRecovery = onRecovery
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            ErrorIconView(severity: errorSeverity)
                .padding([.top], 8)
            
            // Error Content
            VStack(spacing: 12) {
                Text(error.userFriendlyTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(error.userFriendlyDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            // Recovery Progress or Actions
            if isRecovering {
                recoveryProgressView
            } else {
                recoveryActionsView
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error recovery dialog")
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var recoveryProgressView: some View {
        VStack(spacing: 16) {
            if let activeOption = activeRecoveryOption {
                Text("Attempting: \(activeOption.title)")
                    .font(.headline)
                    .accessibilityLabel("Recovery in progress: \(activeOption.title)")
            }
            
            ProgressView(value: recoveryProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(1.1)
                .accessibilityLabel("Recovery progress")
                .accessibilityValue("\(Int(recoveryProgress * 100))% complete")
            
            Text("Please wait...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var recoveryActionsView: some View {
        VStack(spacing: 12) {
            // Primary actions first
            ForEach(primaryOptions, id: \.self) { option in
                RecoveryActionButton(
                    option: option,
                    isLoading: isRecovering && activeRecoveryOption == option
                ) {
                    await performRecovery(option)
                }
            }
            
            // Secondary actions
            if !secondaryOptions.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(secondaryOptions, id: \.self) { option in
                    RecoveryActionButton(
                        option: option,
                        isLoading: isRecovering && activeRecoveryOption == option
                    ) {
                        await performRecovery(option)
                    }
                }
            }
            
            // Dismiss button
            Button("Dismiss", action: onDismiss)
                .foregroundColor(.secondary)
                .font(.body)
                .padding(.top, 8)
                .accessibilityHint("Dismiss this error dialog")
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var errorSeverity: ErrorSeverity {
        switch error {
        case .validationError:
            return .warning
        case .contextError, .actorError:
            return .error
        case .capabilityError:
            return .warning
        case .infrastructureError:
            return .critical
        default:
            return .error
        }
    }
    
    private var primaryOptions: [Option] {
        return recoveryOptions.filter { $0.isPrimary }
    }
    
    private var secondaryOptions: [Option] {
        return recoveryOptions.filter { !$0.isPrimary }
    }
    
    // MARK: - Actions
    
    private func performRecovery(_ option: Option) async {
        // Simplified for compilation - in real implementation would use binding
        await onRecovery(option)
    }
}

// MARK: - Error Alert Modifier

/// SwiftUI modifier for showing error alerts with recovery options
public struct ErrorAlertModifier<Option: RecoveryOption>: ViewModifier {
    @Binding var error: AxiomError?
    let recoveryOptions: [Option]
    let onRecovery: @Sendable (Option) async -> Void
    
    public func body(content: Content) -> some View {
        content
            .alert(
                error?.userFriendlyTitle ?? "Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { presentedError in
                // Primary action
                if let primaryOption = recoveryOptions.first(where: { $0.isPrimary }) {
                    Button(primaryOption.title) {
                        Task {
                            await onRecovery(primaryOption)
                        }
                    }
                }
                
                // Secondary actions (limited to 2-3 for alert)
                ForEach(Array(recoveryOptions.filter { !$0.isPrimary }.prefix(2)), id: \.self) { option in
                    Button(option.title) {
                        Task {
                            await onRecovery(option)
                        }
                    }
                }
                
                // Dismiss
                Button("Dismiss", role: .cancel) {
                    error = nil
                }
            } message: { presentedError in
                Text(presentedError.userFriendlyDescription)
            }
    }
}

// MARK: - Error State View

/// Full-screen error state view for critical errors
public struct ErrorStateView<Option: RecoveryOption>: View {
    let error: AxiomError
    let recoveryOptions: [Option]
    let onRecovery: @Sendable (Option) async -> Void
    let onDismiss: () -> Void
    
    public init(
        error: AxiomError,
        recoveryOptions: [Option],
        onRecovery: @escaping @Sendable (Option) async -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.error = error
        self.recoveryOptions = recoveryOptions
        self.onRecovery = onRecovery
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ErrorIconView(severity: ErrorSeverity.error, size: 80)
            
            VStack(spacing: 16) {
                Text(error.userFriendlyTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(error.userFriendlyDescription)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                ForEach(recoveryOptions.prefix(3), id: \.self) { option in
                    RecoveryActionButton(option: option) {
                        await onRecovery(option)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button("Dismiss", action: onDismiss)
                .foregroundColor(.secondary)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error state screen")
    }
}

// MARK: - Banner Error View

/// Compact banner-style error view for non-critical errors
public struct BannerErrorView<Option: RecoveryOption>: View {
    let error: AxiomError
    let recoveryOptions: [Option]
    let onRecovery: @Sendable (Option) async -> Void
    let onDismiss: () -> Void
    
    private let isExpanded = false
    
    public init(
        error: AxiomError,
        recoveryOptions: [Option],
        onRecovery: @escaping @Sendable (Option) async -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.error = error
        self.recoveryOptions = recoveryOptions
        self.onRecovery = onRecovery
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Collapsed view
            HStack {
                ErrorIconView(severity: ErrorSeverity.warning, size: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.userFriendlyTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !isExpanded {
                        Text(error.userFriendlyDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Dismiss error")
                
                Button(action: { }) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Error details")
            }
            .padding()
            .contentShape(Rectangle())
            
            // Basic expanded view (always visible for now)
            VStack(alignment: .leading, spacing: 12) {
                Text(error.userFriendlyDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    ForEach(recoveryOptions.prefix(2), id: \.self) { option in
                        Button(option.title) {
                            Task {
                                await onRecovery(option)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(option.isPrimary ? Color.accentColor : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentColor, lineWidth: 1)
                                )
                        )
                        .foregroundColor(option.isPrimary ? .white : .accentColor)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error banner")
    }
}

// MARK: - View Extensions

public extension View {
    /// Shows an error alert with recovery options
    func errorAlert<Option: RecoveryOption>(
        error: Binding<AxiomError?>,
        recoveryOptions: [Option],
        onRecovery: @escaping @Sendable (Option) async -> Void
    ) -> some View {
        self.modifier(ErrorAlertModifier(
            error: error,
            recoveryOptions: recoveryOptions,
            onRecovery: onRecovery
        ))
    }
    
    /// Shows an error recovery overlay
    func errorRecoveryOverlay<Option: RecoveryOption>(
        error: AxiomError?,
        recoveryOptions: [Option],
        onRecovery: @escaping @Sendable (Option) async -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        self.overlay(
            Group {
                if let error = error {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { onDismiss() }
                    
                    ErrorRecoveryView(
                        error: error,
                        recoveryOptions: recoveryOptions,
                        onRecovery: onRecovery,
                        onDismiss: onDismiss
                    )
                }
            }
        )
    }
}

// MARK: - Default Recovery Options

/// Default recovery options that conform to RecoveryOption protocol
public enum DefaultRecoveryOption: String, RecoveryOption {
    case retry = "retry"
    case refresh = "refresh"
    case settings = "settings"
    case support = "support"
    case dismiss = "dismiss"
    
    public var title: String {
        switch self {
        case .retry: return "Try Again"
        case .refresh: return "Refresh"
        case .settings: return "Settings"
        case .support: return "Contact Support"
        case .dismiss: return "Dismiss"
        }
    }
    
    public var description: String {
        switch self {
        case .retry: return "Attempt the operation again"
        case .refresh: return "Refresh the current view"
        case .settings: return "Open app settings"
        case .support: return "Get help from support"
        case .dismiss: return "Close this error message"
        }
    }
    
    public var icon: String {
        switch self {
        case .retry: return "arrow.clockwise"
        case .refresh: return "arrow.triangle.2.circlepath"
        case .settings: return "gear"
        case .support: return "questionmark.circle"
        case .dismiss: return "xmark"
        }
    }
    
    public var isPrimary: Bool {
        switch self {
        case .retry, .refresh: return true
        default: return false
        }
    }
}

// MARK: - Accessibility Helpers

/// Accessibility helpers for error recovery
public struct ErrorRecoveryAccessibility {
    @MainActor public static func announceError(_ error: AxiomError) {
        let announcement = "Error occurred: \(error.userFriendlyTitle). \(error.userFriendlyDescription)"
        
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: announcement)
        #endif
    }
    
    @MainActor public static func announceRecovery(success: Bool, option: String) {
        let announcement = success 
            ? "Recovery successful using \(option)"
            : "Recovery failed using \(option)"
            
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: announcement)
        #endif
    }
}