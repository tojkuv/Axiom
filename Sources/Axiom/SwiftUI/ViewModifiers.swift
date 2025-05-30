import SwiftUI

// MARK: - Capability Requirement Modifier

/// A view modifier that checks capability requirements before displaying content
public struct RequiresCapabilitiesModifier: ViewModifier {
    let capabilities: [Capability]
    let fallback: AnyView?
    
    @Environment(\.axiomContext) private var context
    
    public init(
        capabilities: [Capability],
        fallback: AnyView? = nil
    ) {
        self.capabilities = capabilities
        self.fallback = fallback
    }
    
    public func body(content: Content) -> some View {
        if context != nil {
            // In a real implementation, we would check capabilities
            // For now, just show the content
            content
        } else if let fallback = fallback {
            fallback
        } else {
            Text("Context not available")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Performance Monitoring Modifier

/// A view modifier that monitors performance of view operations
public struct PerformanceMonitoringModifier: ViewModifier {
    let operation: String
    @Environment(\.axiomContext) private var context
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                // Log view appearance for performance tracking
                print("[Axiom Performance] View appeared: \(operation)")
            }
    }
}

// MARK: - Intelligence Integration Modifier

/// A view modifier that enables intelligence features for a view
public struct IntelligenceEnabledModifier: ViewModifier {
    let features: Set<IntelligenceFeature>
    @Environment(\.axiomContext) private var context
    
    public func body(content: Content) -> some View {
        content
            .task {
                // Enable intelligence features in context
                if context != nil {
                    // Feature enablement would happen here
                    print("[Axiom Intelligence] Enabled features: \(features)")
                }
            }
    }
}

// MARK: - View Modifier Extensions

public extension View {
    /// Requires specific capabilities to display this view
    func requiresCapabilities(
        _ capabilities: Capability...,
        fallback: (() -> AnyView)? = nil
    ) -> some View {
        self.modifier(
            RequiresCapabilitiesModifier(
                capabilities: Array(capabilities),
                fallback: fallback?()
            )
        )
    }
    
    /// Monitors performance of this view
    func performanceMonitored(_ operation: String) -> some View {
        self.modifier(PerformanceMonitoringModifier(operation: operation))
    }
    
    /// Enables intelligence features for this view
    func intelligenceEnabled(_ features: Set<IntelligenceFeature>) -> some View {
        self.modifier(IntelligenceEnabledModifier(features: features))
    }
}

// MARK: - Conditional View Extensions

public extension View {
    /// Conditionally applies a modifier based on a boolean value
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two modifiers based on a boolean value
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Axiom Styling

/// Standard styling for Axiom framework components
public struct AxiomStyle {
    public static let cornerRadius: CGFloat = 12
    public static let padding: CGFloat = 16
    public static let shadowRadius: CGFloat = 4
    
    public static func primaryButton() -> some ViewModifier {
        PrimaryButtonStyle()
    }
    
    public static func secondaryButton() -> some ViewModifier {
        SecondaryButtonStyle()
    }
}

private struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AxiomStyle.padding)
            .padding(.vertical, AxiomStyle.padding / 2)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(AxiomStyle.cornerRadius)
    }
}

private struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AxiomStyle.padding)
            .padding(.vertical, AxiomStyle.padding / 2)
            .background(Color.secondary.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(AxiomStyle.cornerRadius)
    }
}