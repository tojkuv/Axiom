import SwiftUI
import Axiom

// MARK: - Clean, Modular ContentView

/// Main content view using organized, modular components
/// This structure makes it easy to:
/// - Test new framework features in isolation
/// - Compare different implementation approaches
/// - Add new examples without breaking existing code
/// - Iterate on framework changes quickly

struct ContentView: View {
    
    @StateObject private var application = RealAxiomApplication()
    
    var body: some View {
        Group {
            if let context = application.context {
                // Main application content with real framework integration
                RealCounterView(context: context)
                    .transition(.opacity)
                
            } else if let error = application.initializationError {
                // Error state with retry capability
                ErrorView(
                    error: error,
                    onRetry: {
                        Task {
                            await application.reinitialize()
                        }
                    }
                )
                .transition(.opacity)
                
            } else {
                // Loading state during initialization
                LoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: application.isInitialized)
        .animation(.easeInOut(duration: 0.3), value: application.initializationError != nil)
        .onAppear {
            if !application.isInitialized && application.initializationError == nil {
                Task {
                    await application.initialize()
                }
            }
        }
    }
}

// MARK: - Error View

/// Error state view with retry functionality
struct ErrorView: View {
    let error: any AxiomError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Initialization Failed")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(error.userMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry Initialization", action: onRetry)
                .buttonStyle(.borderedProminent)
            
            Divider()
                .padding(.vertical)
            
            VStack(spacing: 8) {
                Text("Development Info:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("Error Category: \(error.category.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Development Notes

/*
 
 MODULAR STRUCTURE BENEFITS:
 
 📁 File Organization:
 ├── Models/                     # State and client definitions
 │   ├── CounterState.swift      # Clean state model
 │   └── CounterClient.swift     # Actor-based client implementation
 ├── Contexts/                   # Context orchestration
 │   └── CounterContext.swift    # Streamlined context with auto-binding
 ├── Views/                      # SwiftUI views
 │   ├── CounterView.swift       # Main counter interface
 │   └── LoadingView.swift       # Loading states
 ├── Utils/                      # Application coordination
 │   └── ApplicationCoordinator.swift # Streamlined app setup
 └── Examples/                   # Different implementation approaches
     ├── BasicExample/           # Manual implementation patterns
     ├── StreamlinedExample/     # Using new APIs
     └── ComparisonExample/      # Side-by-side comparisons
 
 🔄 Framework Testing Benefits:
 - Easy to add new examples without breaking existing code
 - Quick comparison between manual and streamlined approaches
 - Isolated testing of specific framework features
 - Clear separation of concerns for debugging
 - Simple integration of new framework capabilities
 
 ⚡ Development Workflow:
 1. Test new framework feature in Examples/
 2. Update relevant component (Models, Contexts, Views)
 3. Integration automatically works through imports
 4. Compare before/after in Examples/
 5. No breaking changes to main app flow
 
 */