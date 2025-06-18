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
        WindowGroup("AxiomStudio") {
            ContentView()
                .environmentObject(orchestrator)
                .task {
                    await orchestrator.initialize()
                }
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            AppCommands()
        }
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(orchestrator)
        }
        
        // Performance monitor window
        WindowGroup("Performance Monitor", id: "performance") {
            PerformanceWindowView()
                .environmentObject(orchestrator)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        
        // Document browser window
        WindowGroup("Document Browser", id: "documents") {
            DocumentBrowserWindowView()
                .environmentObject(orchestrator)
                .frame(minWidth: 900, minHeight: 650)
        }
        .windowStyle(.titleBar)
    }
}

struct ContentView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedSidebarItem: SidebarItem = .personalInfo
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        Group {
            if orchestrator.isInitialized {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView(selectedItem: $selectedSidebarItem)
                        .frame(minWidth: 200)
                } detail: {
                    DetailView(selectedItem: selectedSidebarItem)
                        .frame(minWidth: 600)
                }
                .navigationSplitViewStyle(.balanced)
            } else if let error = orchestrator.initializationError {
                ErrorView(error: error)
            } else {
                LoadingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: orchestrator.isInitialized)
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case personalInfo = "Personal Info"
    case healthLocation = "Health & Location"
    case contentProcessor = "AI Content Processor"
    case mediaHub = "Media Hub"
    case performance = "Performance"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .personalInfo: return "person.crop.circle"
        case .healthLocation: return "heart.fill"
        case .contentProcessor: return "brain.head.profile"
        case .mediaHub: return "folder.fill"
        case .performance: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var route: StudioRoute {
        switch self {
        case .personalInfo: return .personalInfo
        case .healthLocation: return .healthLocation
        case .contentProcessor: return .contentProcessor
        case .mediaHub: return .mediaHub
        case .performance: return .performance
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    
    var body: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            NavigationLink(value: item) {
                Label(item.rawValue, systemImage: item.iconName)
            }
        }
        .navigationTitle("AxiomStudio")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Window") {
                        openNewWindow()
                    }
                    
                    Button("Performance Monitor") {
                        openPerformanceWindow()
                    }
                    
                    Button("Document Browser") {
                        openDocumentBrowser()
                    }
                    
                    Divider()
                    
                    Button("Settings...") {
                        openSettings()
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                try? await orchestrator.navigate(to: newValue.route)
            }
        }
    }
    
    private func openNewWindow() {
        if let url = URL(string: "axiomstudio://window/main") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openPerformanceWindow() {
        if let url = URL(string: "axiomstudio://window/performance") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openDocumentBrowser() {
        if let url = URL(string: "axiomstudio://window/documents") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

struct DetailView: View {
    let selectedItem: SidebarItem
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    
    var body: some View {
        Group {
            switch selectedItem {
            case .personalInfo:
                PersonalInfoDetailView()
            case .healthLocation:
                HealthLocationDetailView()
            case .contentProcessor:
                ContentProcessorDetailView()
            case .mediaHub:
                MediaHubDetailView()
            case .performance:
                PerformanceDetailView()
            }
        }
        .navigationTitle(selectedItem.rawValue)
        .navigationSubtitle(navigationSubtitle(for: selectedItem))
    }
    
    private func navigationSubtitle(for item: SidebarItem) -> String {
        switch item {
        case .personalInfo:
            return "Tasks, Calendar, and Contacts"
        case .healthLocation:
            return "Health Metrics and Location Data"
        case .contentProcessor:
            return "AI and Machine Learning Tools"
        case .mediaHub:
            return "File and Media Management"
        case .performance:
            return "System Monitoring and Analysis"
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing AxiomStudio...")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Setting up capabilities and loading data")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Initialization Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Retry") {
                // In a real app, you might want to retry initialization
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - App Commands

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Task") {
                // Create new task
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New Document") {
                // Import new document
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Divider()
            
            Button("New Window") {
                // Open new window
            }
            .keyboardShortcut("n", modifiers: [.command, .option])
        }
        
        CommandGroup(after: .toolbar) {
            Button("Show Performance Monitor") {
                // Open performance window
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            
            Button("Show Document Browser") {
                // Open document browser
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        
        CommandMenu("Data") {
            Button("Export All Data") {
                // Export data
            }
            
            Button("Import Data") {
                // Import data
            }
            
            Divider()
            
            Button("Clear Cache") {
                // Clear application cache
            }
            
            Button("Reset Application") {
                // Reset application state
            }
        }
    }
}

// MARK: - Specialized Windows

struct PerformanceWindowView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    
    var body: some View {
        PerformanceDetailView()
            .navigationTitle("Performance Monitor")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Export Metrics") {
                        // Handle metrics export
                    }
                }
            }
    }
}

struct DocumentBrowserWindowView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    
    var body: some View {
        MediaHubDetailView()
            .navigationTitle("Document Browser")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Import Documents") {
                        // Handle document import
                    }
                }
            }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "lock")
                }
                .tag(1)
            
            PerformanceSettingsView()
                .tabItem {
                    Label("Performance", systemImage: "speedometer")
                }
                .tag(2)
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(3)
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                Toggle("Launch at startup", isOn: .constant(false))
                Toggle("Show in menu bar", isOn: .constant(true))
                Toggle("Auto-save data", isOn: .constant(true))
                
                Picker("Theme", selection: .constant("Auto")) {
                    Text("Auto").tag("Auto")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
                
                Picker("Default view", selection: .constant("Personal Info")) {
                    Text("Personal Info").tag("Personal Info")
                    Text("Health & Location").tag("Health & Location")
                    Text("AI Content Processor").tag("AI Content Processor")
                    Text("Media Hub").tag("Media Hub")
                    Text("Performance").tag("Performance")
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                Toggle("Allow location tracking", isOn: .constant(false))
                Toggle("Allow health data access", isOn: .constant(false))
                Toggle("Allow contact access", isOn: .constant(false))
                Toggle("Allow calendar access", isOn: .constant(false))
                
                Divider()
                
                Toggle("Analytics and diagnostics", isOn: .constant(true))
                Toggle("Crash reporting", isOn: .constant(true))
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PerformanceSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                Toggle("Real-time monitoring", isOn: .constant(true))
                
                HStack {
                    Text("Monitoring interval")
                    Spacer()
                    Picker("", selection: .constant(2)) {
                        Text("1 second").tag(1)
                        Text("2 seconds").tag(2)
                        Text("5 seconds").tag(5)
                        Text("10 seconds").tag(10)
                    }
                    .frame(width: 100)
                }
                
                Toggle("Background processing", isOn: .constant(true))
                Toggle("Hardware acceleration", isOn: .constant(true))
                
                Divider()
                
                HStack {
                    Text("Memory usage limit")
                    Spacer()
                    Picker("", selection: .constant(1024)) {
                        Text("512 MB").tag(512)
                        Text("1 GB").tag(1024)
                        Text("2 GB").tag(2048)
                        Text("Unlimited").tag(0)
                    }
                    .frame(width: 100)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                Toggle("Developer mode", isOn: .constant(false))
                Toggle("Debug logging", isOn: .constant(false))
                Toggle("Experimental features", isOn: .constant(false))
                
                Divider()
                
                HStack {
                    Text("Data directory")
                    Spacer()
                    Button("Change...") {
                        // Handle directory change
                    }
                }
                
                HStack {
                    Text("Cache directory")
                    Spacer()
                    Button("Change...") {
                        // Handle directory change
                    }
                }
                
                Divider()
                
                Button("Export Settings") {
                    // Export settings
                }
                
                Button("Import Settings") {
                    // Import settings
                }
                
                Button("Reset to Defaults") {
                    // Reset settings
                }
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
}