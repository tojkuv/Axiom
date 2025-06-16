import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task Settings View (iOS)

/// Settings and preferences view for iOS Task Manager
public struct TaskSettingsView: View, PresentationProtocol {
    public typealias ContextType = TaskSettingsContext
    
    @ObservedObject public var context: TaskSettingsContext
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearDataAlert = false
    @State private var showingDeleteCompletedAlert = false
    @State private var showingResetAlert = false
    @State private var showingDiagnosticInfo = false
    @State private var showingDocumentPicker = false
    @State private var diagnosticText = ""
    
    public init(context: TaskSettingsContext) {
        self.context = context
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                List {
                    defaultsSection
                    displaySection
                    notificationsSection
                    dataManagementSection
                    storageSection
                    statisticsSection
                    advancedSection
                }
                .navigationTitle("Settings")
                .navigationBarItems(trailing: doneButton)
                .onAppear {
                    Task { await context.appeared() }
                }
                
                if let error = context.error {
                    ErrorBanner(message: error) {
                        Task { await context.clearError() }
                    }
                }
                
                if context.exportSuccess {
                    SuccessBanner(message: "Tasks exported successfully!") {
                        Task { await context.clearSuccessStates() }
                    }
                }
                
                if context.importSuccess {
                    SuccessBanner(message: "Tasks imported successfully!") {
                        Task { await context.clearSuccessStates() }
                    }
                }
            }
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Clear All", role: .destructive) {
                Task { await context.clearAllTasks() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all tasks. This action cannot be undone.")
        }
        .alert("Delete Completed Tasks", isPresented: $showingDeleteCompletedAlert) {
            Button("Delete", role: .destructive) {
                Task { await context.deleteCompletedTasks() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all completed tasks. This action cannot be undone.")
        }
        .alert("Reset to Defaults", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                Task { await context.resetToDefaults() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all settings to their default values.")
        }
        .sheet(isPresented: $showingDiagnosticInfo) {
            DiagnosticInfoView(diagnosticText: diagnosticText)
        }
    }
    
    // MARK: - Settings Sections
    
    private var defaultsSection: some View {
        Section("Defaults for New Tasks") {
            Picker("Default Category", selection: Binding(
                get: { context.defaultCategory },
                set: { newValue in Task { await context.updateDefaultCategory(newValue) } }
            )) {
                ForEach(Category.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.systemImageName)
                        .tag(category)
                }
            }
            
            Picker("Default Priority", selection: Binding(
                get: { context.defaultPriority },
                set: { newValue in Task { await context.updateDefaultPriority(newValue) } }
            )) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Label(priority.displayName, systemImage: priority.systemImageName)
                        .tag(priority)
                }
            }
            
            Picker("Default Sort Order", selection: Binding(
                get: { context.defaultSortOrder },
                set: { newValue in Task { await context.updateDefaultSortOrder(newValue, ascending: context.defaultSortAscending) } }
            )) {
                ForEach(Task.SortOrder.allCases, id: \.self) { sortOrder in
                    Text(sortOrder.displayName)
                        .tag(sortOrder)
                }
            }
            
            Toggle("Sort Ascending", isOn: Binding(
                get: { context.defaultSortAscending },
                set: { newValue in Task { await context.updateDefaultSortOrder(context.defaultSortOrder, ascending: newValue) } }
            ))
        }
    }
    
    private var displaySection: some View {
        Section("Display") {
            Toggle("Show Completed Tasks", isOn: Binding(
                get: { context.showCompletedTasks },
                set: { newValue in Task { await context.updateShowCompletedTasks(newValue) } }
            ))
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: Binding(
                get: { context.enableNotifications },
                set: { newValue in Task { await context.updateEnableNotifications(newValue) } }
            ))
            
            if context.enableNotifications {
                DatePicker(
                    "Daily Reminder Time",
                    selection: Binding(
                        get: { context.notificationTime },
                        set: { newValue in Task { await context.updateNotificationTime(newValue) } }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section("Data Management") {
            Button(action: {
                Task { await context.exportTasks() }
            }) {
                HStack {
                    Label("Export Tasks", systemImage: "square.and.arrow.up")
                    
                    Spacer()
                    
                    if context.isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(context.isExporting || context.totalTasks == 0)
            
            Button("Import Tasks") {
                showingDocumentPicker = true
            }
            .disabled(context.isImporting)
            
            if context.hasRecentBackup {
                HStack {
                    Label("Last Backup", systemImage: "clock")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let lastBackup = context.lastBackupDate {
                        Text(RelativeDateTimeFormatter().localizedString(for: lastBackup, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var storageSection: some View {
        Section("Storage") {
            if let storageInfo = context.storageInfo {
                HStack {
                    Label("Storage Used", systemImage: "internaldrive")
                    Spacer()
                    Text(context.storageUsageDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Location", systemImage: "folder")
                    Spacer()
                    Text(storageInfo.isAvailable ? "Available" : "Unavailable")
                        .font(.caption)
                        .foregroundColor(storageInfo.isAvailable ? .green : .red)
                }
                
                if let lastModified = storageInfo.lastModified {
                    HStack {
                        Label("Last Modified", systemImage: "clock")
                        Spacer()
                        Text(DateFormatter.localizedString(from: lastModified, dateStyle: .short, timeStyle: .short))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("Loading storage info...")
                        .foregroundColor(.secondary)
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Button("Refresh Storage Info") {
                Task { await context.loadStorageInfo() }
            }
            .disabled(context.isLoading)
        }
    }
    
    private var statisticsSection: some View {
        Section("Statistics") {
            HStack {
                Label("Total Tasks", systemImage: "list.bullet")
                Spacer()
                Text("\(context.totalTasks)")
                    .fontWeight(.medium)
            }
            
            HStack {
                Label("Completed Tasks", systemImage: "checkmark.circle")
                Spacer()
                Text("\(context.completedTasks)")
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            HStack {
                Label("Completion Rate", systemImage: "chart.pie")
                Spacer()
                Text("\(Int(context.tasksCompletionPercentage * 100))%")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var advancedSection: some View {
        Section("Advanced") {
            Button("Delete Completed Tasks") {
                showingDeleteCompletedAlert = true
            }
            .foregroundColor(.orange)
            .disabled(context.completedTasks == 0)
            
            Button("Clear All Data") {
                showingClearDataAlert = true
            }
            .foregroundColor(.red)
            .disabled(context.totalTasks == 0)
            
            Button("Reset to Defaults") {
                showingResetAlert = true
            }
            .foregroundColor(.orange)
            
            Button("Diagnostic Information") {
                Task {
                    diagnosticText = await context.generateDiagnosticInfo()
                    showingDiagnosticInfo = true
                }
            }
        }
    }
    
    // MARK: - Navigation Items
    
    private var doneButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Diagnostic Info View

private struct DiagnosticInfoView: View {
    let diagnosticText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(diagnosticText)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Diagnostic Info")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Share") {
                    let activityController = UIActivityViewController(
                        activityItems: [diagnosticText],
                        applicationActivities: nil
                    )
                    
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first {
                        window.rootViewController?.present(activityController, animated: true)
                    }
                }
            )
        }
    }
}

// MARK: - Error and Success Banners

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

private struct SuccessBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("OK") {
                    onDismiss()
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}