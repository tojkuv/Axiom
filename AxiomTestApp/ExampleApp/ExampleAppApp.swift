import SwiftUI

// IMPORTANT: Use AxiomWorkspace.xcworkspace for development:
// Framework and app projects are coordinated in the workspace
#if canImport(Axiom)
import Axiom
#endif

/// Sophisticated iOS app showcasing the complete Axiom Framework
/// Demonstrates multi-domain architecture with User and Data domains,
/// cross-domain orchestration, intelligence integration, and advanced capabilities
@main
struct ExampleAppApp: App {
    
    @StateObject private var applicationCoordinator = MultiDomainApplicationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if applicationCoordinator.isFullyInitialized,
                   let userContext = applicationCoordinator.userContext,
                   let dataContext = applicationCoordinator.dataContext {
                    
                    // Main multi-domain integration demo
                    SimpleIntegrationDemoView(
                        userContext: userContext,
                        dataContext: dataContext
                    )
                    .transition(AnyTransition.opacity)
                    
                } else if let error = applicationCoordinator.initializationError {
                    
                    // Sophisticated error handling with recovery
                    MultiDomainErrorView(
                        error: error,
                        onRetry: {
                            Task {
                                await applicationCoordinator.reinitialize()
                            }
                        }
                    )
                    .transition(AnyTransition.opacity)
                    
                } else {
                    
                    // Enhanced loading view with progress
                    MultiDomainLoadingView(
                        progress: applicationCoordinator.initializationProgress,
                        currentStep: applicationCoordinator.currentInitializationStep,
                        status: applicationCoordinator.initializationStatus
                    )
                    .transition(AnyTransition.opacity)
                    
                }
            }
            .onAppear {
                if !applicationCoordinator.isInitialized && applicationCoordinator.initializationError == nil {
                    Task {
                        await applicationCoordinator.initialize()
                    }
                }
            }
        }
    }
}

// MARK: - Multi-Domain Loading View

/// Enhanced loading view showing initialization progress across domains
struct MultiDomainLoadingView: View {
    let progress: Double
    let currentStep: String
    let status: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Framework logo and title
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 2) * 0.1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: Date())
                
                Text("Axiom Framework")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Multi-Domain Architecture")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Initialization progress
            VStack(spacing: 16) {
                Text(status)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 280)
                    
                    Text(currentStep)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // Domain initialization indicators
            HStack(spacing: 20) {
                DomainInitIndicator(
                    name: "User",
                    icon: "person.circle",
                    isActive: progress > 0.6,
                    color: .blue
                )
                
                DomainInitIndicator(
                    name: "Data", 
                    icon: "cylinder",
                    isActive: progress > 0.8,
                    color: .green
                )
                
                DomainInitIndicator(
                    name: "Intelligence",
                    icon: "brain",
                    isActive: progress > 0.4,
                    color: .purple
                )
            }
            
            // Framework capabilities preview
            if progress > 0.3 {
                VStack(spacing: 8) {
                    Text("Initializing Advanced Capabilities")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        CapabilityPreview(name: "Actor State", icon: "cpu")
                        CapabilityPreview(name: "Auto Binding", icon: "link")
                        CapabilityPreview(name: "AI Integration", icon: "brain")
                        CapabilityPreview(name: "Performance", icon: "speedometer")
                    }
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.05), .blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Multi-Domain Error View

/// Sophisticated error view with framework-specific error handling
struct MultiDomainErrorView: View {
    let error: any AxiomError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon and title
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Framework Initialization Failed")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(error.userMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button("Retry Initialization", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                
                Button("Reset to Basic Mode") {
                    // Could fallback to simple counter mode
                }
                .buttonStyle(.bordered)
            }
            
            // Technical error details
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Technical Details:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ErrorDetailRow(label: "Error Category", value: error.category.rawValue)
                ErrorDetailRow(label: "Severity", value: String(describing: error.severity))
                ErrorDetailRow(label: "Component", value: String(describing: error.context.component))
                
                if let description = error.errorDescription {
                    Text("Description: \(description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Supporting Views

private struct DomainInitIndicator: View {
    let name: String
    let icon: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isActive ? color : .gray)
                .opacity(isActive ? 1.0 : 0.5)
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? color : .gray)
            
            Circle()
                .fill(isActive ? color : .gray)
                .frame(width: 8, height: 8)
                .opacity(isActive ? 1.0 : 0.3)
        }
    }
}

private struct CapabilityPreview: View {
    let name: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct ErrorDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}