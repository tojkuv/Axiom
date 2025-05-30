import SwiftUI

// IMPORTANT: Use AxiomWorkspace.xcworkspace for development:
// Framework and app projects are coordinated in the workspace
#if canImport(Axiom)
import Axiom
#endif

/// Real iOS app using the actual Axiom Framework
/// Demonstrates all core framework features with real implementations
@main
struct ExampleAppApp: App {
    
    @StateObject private var application = RealAxiomApplication()
    
    var body: some Scene {
        WindowGroup {
            if let context = application.context {
                RealCounterView(context: context)
            } else {
                LoadingView()
                    .onAppear {
                        Task {
                            await application.initialize()
                        }
                    }
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("🧠 Axiom Framework")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("World's First Intelligent iOS Framework")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ProgressView("Initializing Demo...")
                .padding(.top)
        }
        .padding()
    }
}