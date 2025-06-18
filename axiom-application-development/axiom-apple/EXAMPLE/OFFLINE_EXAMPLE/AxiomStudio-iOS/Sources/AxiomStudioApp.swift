import SwiftUI
import AxiomCore
import AxiomArchitecture
import AxiomStudio_Shared

@main
struct AxiomStudioApp: App {
    @StateObject private var orchestrator: StudioOrchestrator
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        do {
            let orchestrator = try StudioOrchestrator()
            self._orchestrator = StateObject(wrappedValue: orchestrator)
        } catch {
            fatalError("Failed to initialize StudioOrchestrator: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(orchestrator)
                .task {
                    await orchestrator.initialize()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        Task {
                            // Save any pending data when app goes to background
                            await saveApplicationState()
                        }
                    case .active:
                        // App became active - refresh data if needed
                        Task {
                            await refreshApplicationData()
                        }
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
    
    @MainActor
    private func saveApplicationState() async {
        do {
            try await orchestrator.processAction(.personalInfo(.saveData))
            try await orchestrator.processAction(.healthLocation(.saveData))
            try await orchestrator.processAction(.contentProcessor(.saveModels))
            try await orchestrator.processAction(.mediaHub(.saveProcessingQueues))
        } catch {
            print("Failed to save application state: \(error)")
        }
    }
    
    @MainActor
    private func refreshApplicationData() async {
        do {
            try await orchestrator.processAction(.performance(.updateMetrics))
        } catch {
            print("Failed to refresh application data: \(error)")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if orchestrator.isInitialized {
                MainTabView(selectedTab: $selectedTab)
            } else if let error = orchestrator.initializationError {
                ErrorView(error: error)
            } else {
                LoadingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: orchestrator.isInitialized)
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PersonalInfoTabView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Personal")
                }
                .tag(0)
            
            HealthLocationTabView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Health")
                }
                .tag(1)
            
            ContentProcessorTabView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI")
                }
                .tag(2)
            
            MediaHubTabView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Media")
                }
                .tag(3)
            
            PerformanceTabView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Performance")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing AxiomStudio...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Setting up capabilities and loading data")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Initialization Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                // In a real app, you might want to retry initialization
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}