import Foundation
import SwiftUI
import AxiomCore
import AxiomArchitecture

public struct StudioNavigationCoordinator: View {
    @StateObject private var navigationService = StudioNavigationService()
    @State private var showingModal = false
    @State private var modalRoute: StudioRoute?
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: Binding(
            get: { navigationService.navigationStack },
            set: { _ in }
        )) {
            rootView(for: navigationService.currentRoute)
                .navigationDestination(for: StudioRoute.self) { route in
                    destinationView(for: route)
                }
        }
        .sheet(isPresented: $showingModal) {
            if let modalRoute = modalRoute {
                NavigationStack {
                    destinationView(for: modalRoute)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    dismissModal()
                                }
                            }
                        }
                }
            }
        }
        .environmentObject(navigationService)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    @ViewBuilder
    private func rootView(for route: StudioRoute) -> some View {
        let rootRoute = route.isRootRoute ? route : route.category.rootRoute
        switch rootRoute {
        case .personalInfo:
            PersonalInfoRootView()
        case .healthLocation:
            HealthLocationRootView()
        case .contentProcessor:
            ContentProcessorRootView()
        case .mediaHub:
            MediaHubRootView()
        case .performance:
            PerformanceRootView()
        case .settings:
            SettingsRootView()
        default:
            // Fallback for any unexpected routes
            PersonalInfoRootView()
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: StudioRoute) -> some View {
        switch route {
        // Personal Info Routes
        case .taskList:
            TaskListView()
        case .taskDetail:
            TaskDetailView()
        case .createTask:
            CreateTaskView()
        case .editTask:
            EditTaskView()
        case .calendarView:
            CalendarView()
        case .contactList:
            ContactListView()
        case .contactDetail:
            ContactDetailView()
            
        // Health Location Routes
        case .healthDashboard:
            HealthDashboardView()
        case .locationHistory:
            LocationHistoryView()
        case .movementPatterns:
            MovementPatternsView()
        case .locationSettings:
            LocationSettingsView()
            
        // Content Processor Routes
        case .mlModels:
            MLModelsView()
        case .textAnalysis:
            TextAnalysisView()
        case .imageProcessing:
            ImageProcessingView()
        case .speechRecognition:
            SpeechRecognitionView()
            
        // Media Hub Routes
        case .documentBrowser:
            DocumentBrowserView()
        case .photoLibrary:
            PhotoLibraryView()
        case .audioRecordings:
            AudioRecordingsView()
        case .processingQueues:
            ProcessingQueuesView()
            
        // Performance Routes
        case .memoryMonitor:
            MemoryMonitorView()
        case .performanceMetrics:
            PerformanceMetricsView()
        case .capabilityStatus:
            CapabilityStatusView()
        case .systemHealth:
            SystemHealthView()
            
        // Root routes (should not be destinations)
        default:
            EmptyView()
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        navigationService.handleDeepLink(url: url)
    }
    
    private func presentModal(route: StudioRoute) {
        modalRoute = route
        showingModal = true
    }
    
    private func dismissModal() {
        showingModal = false
        modalRoute = nil
    }
}

// MARK: - Root Views

struct PersonalInfoRootView: View {
    @EnvironmentObject private var navigationService: StudioNavigationService
    
    var body: some View {
        TabView {
            TaskListView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tasks")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            ContactListView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Contacts")
                }
        }
        .navigationTitle("Personal Info")
    }
}

struct HealthLocationRootView: View {
    @EnvironmentObject private var navigationService: StudioNavigationService
    
    var body: some View {
        TabView {
            HealthDashboardView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Health")
                }
            
            LocationHistoryView()
                .tabItem {
                    Image(systemName: "location")
                    Text("Location")
                }
            
            MovementPatternsView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Movement")
                }
        }
        .navigationTitle("Health & Location")
    }
}

struct ContentProcessorRootView: View {
    @EnvironmentObject private var navigationService: StudioNavigationService
    
    var body: some View {
        TabView {
            MLModelsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Models")
                }
            
            TextAnalysisView()
                .tabItem {
                    Image(systemName: "text.alignleft")
                    Text("Text")
                }
            
            ImageProcessingView()
                .tabItem {
                    Image(systemName: "photo")
                    Text("Images")
                }
            
            SpeechRecognitionView()
                .tabItem {
                    Image(systemName: "mic")
                    Text("Speech")
                }
        }
        .navigationTitle("Content Processor")
    }
}

struct MediaHubRootView: View {
    @EnvironmentObject private var navigationService: StudioNavigationService
    
    var body: some View {
        TabView {
            DocumentBrowserView()
                .tabItem {
                    Image(systemName: "doc.fill")
                    Text("Documents")
                }
            
            PhotoLibraryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Photos")
                }
            
            AudioRecordingsView()
                .tabItem {
                    Image(systemName: "waveform")
                    Text("Audio")
                }
            
            ProcessingQueuesView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Queue")
                }
        }
        .navigationTitle("Media Hub")
    }
}

struct PerformanceRootView: View {
    @EnvironmentObject private var navigationService: StudioNavigationService
    
    var body: some View {
        TabView {
            MemoryMonitorView()
                .tabItem {
                    Image(systemName: "memorychip")
                    Text("Memory")
                }
            
            PerformanceMetricsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Metrics")
                }
            
            CapabilityStatusView()
                .tabItem {
                    Image(systemName: "gearshape.2")
                    Text("Capabilities")
                }
            
            SystemHealthView()
                .tabItem {
                    Image(systemName: "stethoscope")
                    Text("Health")
                }
        }
        .navigationTitle("Performance")
    }
}

struct SettingsRootView: View {
    @EnvironmentObject private var navigationService: StudioNavigationService
    
    var body: some View {
        List {
            Section("General") {
                NavigationLink("Preferences", destination: EmptyView())
                NavigationLink("Privacy", destination: EmptyView())
                NavigationLink("Permissions", destination: EmptyView())
            }
            
            Section("Data") {
                NavigationLink("Storage", destination: EmptyView())
                NavigationLink("Sync", destination: EmptyView())
                NavigationLink("Export", destination: EmptyView())
            }
            
            Section("About") {
                NavigationLink("Version Info", destination: EmptyView())
                NavigationLink("Support", destination: EmptyView())
                NavigationLink("Credits", destination: EmptyView())
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Placeholder Views (to be implemented)

struct TaskListView: View {
    var body: some View {
        Text("Task List View")
            .navigationTitle("Tasks")
    }
}

struct TaskDetailView: View {
    var body: some View {
        Text("Task Detail View")
            .navigationTitle("Task Detail")
    }
}

struct CreateTaskView: View {
    var body: some View {
        Text("Create Task View")
            .navigationTitle("Create Task")
    }
}

struct EditTaskView: View {
    var body: some View {
        Text("Edit Task View")
            .navigationTitle("Edit Task")
    }
}

struct CalendarView: View {
    var body: some View {
        Text("Calendar View")
            .navigationTitle("Calendar")
    }
}

struct ContactListView: View {
    var body: some View {
        Text("Contact List View")
            .navigationTitle("Contacts")
    }
}

struct ContactDetailView: View {
    var body: some View {
        Text("Contact Detail View")
            .navigationTitle("Contact Detail")
    }
}

struct HealthDashboardView: View {
    var body: some View {
        Text("Health Dashboard View")
            .navigationTitle("Health Dashboard")
    }
}

struct LocationHistoryView: View {
    var body: some View {
        Text("Location History View")
            .navigationTitle("Location History")
    }
}

struct MovementPatternsView: View {
    var body: some View {
        Text("Movement Patterns View")
            .navigationTitle("Movement Patterns")
    }
}

struct LocationSettingsView: View {
    var body: some View {
        Text("Location Settings View")
            .navigationTitle("Location Settings")
    }
}

struct MLModelsView: View {
    var body: some View {
        Text("ML Models View")
            .navigationTitle("ML Models")
    }
}

struct TextAnalysisView: View {
    var body: some View {
        Text("Text Analysis View")
            .navigationTitle("Text Analysis")
    }
}

struct ImageProcessingView: View {
    var body: some View {
        Text("Image Processing View")
            .navigationTitle("Image Processing")
    }
}

struct SpeechRecognitionView: View {
    var body: some View {
        Text("Speech Recognition View")
            .navigationTitle("Speech Recognition")
    }
}

struct DocumentBrowserView: View {
    var body: some View {
        Text("Document Browser View")
            .navigationTitle("Documents")
    }
}

struct PhotoLibraryView: View {
    var body: some View {
        Text("Photo Library View")
            .navigationTitle("Photo Library")
    }
}

struct AudioRecordingsView: View {
    var body: some View {
        Text("Audio Recordings View")
            .navigationTitle("Audio Recordings")
    }
}

struct ProcessingQueuesView: View {
    var body: some View {
        Text("Processing Queues View")
            .navigationTitle("Processing Queues")
    }
}

struct MemoryMonitorView: View {
    var body: some View {
        Text("Memory Monitor View")
            .navigationTitle("Memory Monitor")
    }
}

struct PerformanceMetricsView: View {
    var body: some View {
        Text("Performance Metrics View")
            .navigationTitle("Performance Metrics")
    }
}

struct CapabilityStatusView: View {
    var body: some View {
        Text("Capability Status View")
            .navigationTitle("Capability Status")
    }
}

struct SystemHealthView: View {
    var body: some View {
        Text("System Health View")
            .navigationTitle("System Health")
    }
}