import SwiftUI

// MARK: - AxiomView Protocol

/// The core protocol for views that are bound to an AxiomContext
public protocol AxiomView: View {
    associatedtype Context: AxiomContext where Context.View == Self
    
    /// The context that manages this view's state and behavior
    var context: Context { get }
    
    /// Initializes the view with its context
    init(context: Context)
}

// MARK: - View Extensions

public extension View {
    /// Binds this view to an AxiomContext
    func axiomContext<T: AxiomContext>(_ context: T) -> some View {
        self
            .environmentObject(context)
            .task {
                await context.onAppear()
            }
            .onDisappear {
                Task {
                    await context.onDisappear()
                }
            }
    }
    
    /// Adds error handling overlay for context state
    func axiomErrorOverlay<T: ContextState>(_ state: T) -> some View {
        self.overlay(alignment: .top) {
            if let error = state.lastError {
                ErrorBanner(error: error) {
                    state.lastError = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: state.lastError != nil)
            }
        }
    }
    
    /// Adds loading overlay for context state
    func axiomLoadingOverlay<T: ContextState>(_ state: T) -> some View {
        self.overlay {
            if state.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: state.isLoading)
            }
        }
    }
}

// MARK: - Error Banner View

private struct ErrorBanner: View {
    let error: any AxiomError
    let dismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.category.rawValue.capitalized)
                        .font(.headline)
                    
                    if let description = error.errorDescription {
                        Text(description)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            if !error.recoveryActions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(error.recoveryActions.prefix(2).enumerated()), id: \.offset) { _, action in
                        Text(action.description)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
    
    private var iconName: String {
        switch error.severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "exclamationmark.circle"
        case .critical: return "exclamationmark.octagon"
        case .fatal: return "xmark.octagon.fill"
        }
    }
    
    private var iconColor: Color {
        switch error.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        case .fatal: return .red
        }
    }
    
    private var backgroundColor: Color {
        switch error.severity {
        case .info: return .blue.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        case .error: return .red.opacity(0.1)
        case .critical: return .red.opacity(0.2)
        case .fatal: return .red.opacity(0.3)
        }
    }
}