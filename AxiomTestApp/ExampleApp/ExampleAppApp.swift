import SwiftUI

// IMPORTANT: Use AxiomWorkspace.xcworkspace for development:
// Framework and app projects are coordinated in the workspace
#if canImport(Axiom)
import Axiom
#endif

/// Real iOS app using the STREAMLINED Axiom Framework APIs
/// Demonstrates AxiomApplicationBuilder and ContextStateBinder improvements
/// See StreamlinedContentView.swift for implementation details
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