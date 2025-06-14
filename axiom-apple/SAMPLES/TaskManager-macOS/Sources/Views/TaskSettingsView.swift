import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Settings View (macOS)

/// Comprehensive settings view for macOS Task Manager with desktop-specific preferences
public struct TaskSettingsView: View, PresentationProtocol {
    public typealias ContextType = TaskSettingsContext
    
    @ObservedObject public var context: TaskSettingsContext
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: SettingsCategory = .general
    @State private var showingDiagnostics = false
    @State private var showingClearDataConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var diagnosticText = ""
    
    public init(context: TaskSettingsContext) {
        self.context = context
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebarView
                .frame(width: 200)
            
            Divider()
            
            // Main content
            mainContentView
                .frame(minWidth: 500)
        }
        .frame(width: 750, height: 600)
        .onAppear {
            _Concurrency.Task { await context.appeared() }
        }
        .alert("Clear All Data", isPresented: $showingClearDataConfirmation) {
            Button("Clear All", role: .destructive) {
                _Concurrency.Task { await context.clearAllTasks() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all tasks. This action cannot be undone.")
        }
        .alert("Reset to Defaults", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                _Concurrency.Task { await context.resetToDefaults() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all settings to their default values.")
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView(diagnosticText: diagnosticText)
        }
        .alert("Error", isPresented: .constant(context.error != nil)) {
            Button("OK") {
                _Concurrency.Task { await context.clearError() }
            }
        } message: {
            if let error = context.error {
                Text(error)
            }
        }
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if context.isSaving {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.6)
                        
                        Text("Saving...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            
            Divider()
            
            // Categories
            List(SettingsCategory.allCases, id: \.self, selection: $selectedCategory) { category in
                Label(category.title, systemImage: category.systemImage)
                    .tag(category)
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            // Footer actions
            VStack(spacing: 8) {
                Button("Reset All Settings") {
                    showingResetConfirmation = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category header
                HStack {
                    Text(selectedCategory.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Category content
                Group {
                    switch selectedCategory {
                    case .general:
                        generalSettings
                    case .defaults:
                        defaultsSettings
                    case .appearance:
                        appearanceSettings
                    case .notifications:
                        notificationSettings
                    case .advanced:
                        advancedSettings
                    case .dataManagement:
                        dataManagementSettings
                    case .about:
                        aboutSettings
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Display Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show completed tasks", isOn: Binding(
                        get: { context.showCompletedTasks },
                        set: { newValue in _Concurrency.Task { await context.updateShowCompletedTasks(newValue) } }
                    ))
                    
                    Toggle("Auto-archive completed tasks", isOn: Binding(
                        get: { context.autoArchiveCompleted },
                        set: { newValue in _Concurrency.Task { await context.updateAutoArchiveCompleted(newValue) } }
                    ))
                    
                    if context.autoArchiveCompleted {
                        HStack {
                            Text("Archive after:")
                            
                            Stepper(
                                "\(context.autoArchiveDays) days",
                                value: Binding(
                                    get: { context.autoArchiveDays },
                                    set: { newValue in _Concurrency.Task { await context.updateAutoArchiveDays(newValue) } }
                                ),
                                in: 1...365
                            )
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            
            SettingsSection("Window Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show in Dock", isOn: Binding(
                        get: { context.showInDock },
                        set: { newValue in _Concurrency.Task { await context.updateShowInDock(newValue) } }
                    ))
                    
                    Toggle("Launch at Login", isOn: Binding(
                        get: { context.launchAtLogin },
                        set: { newValue in _Concurrency.Task { await context.updateLaunchAtLogin(newValue) } }
                    ))
                    
                    HStack {
                        Text("Window Opacity:")
                        
                        Slider(
                            value: Binding(
                                get: { context.windowOpacity },
                                set: { newValue in _Concurrency.Task { await context.updateWindowOpacity(newValue) } }
                            ),
                            in: 0.3...1.0,
                            step: 0.1
                        ) {
                            Text("Opacity")
                        } minimumValueLabel: {
                            Text("30%")
                        } maximumValueLabel: {
                            Text("100%")
                        }
                        
                        Text("\(Int(context.windowOpacity * 100))%")
                            .frame(width: 40)
                    }
                }
            }
            
            SettingsSection("Interface") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Use native menu bar", isOn: Binding(
                        get: { context.useNativeMenuBar },
                        set: { newValue in _Concurrency.Task { await context.updateUseNativeMenuBar(newValue) } }
                    ))
                    
                    Toggle("Show toolbar", isOn: Binding(
                        get: { context.showToolbar },
                        set: { newValue in _Concurrency.Task { await context.updateShowToolbar(newValue) } }
                    ))
                    
                    Toggle("Show status bar", isOn: Binding(
                        get: { context.showStatusBar },
                        set: { newValue in _Concurrency.Task { await context.updateShowStatusBar(newValue) } }
                    ))
                    
                    Toggle("Compact mode", isOn: Binding(
                        get: { context.compactMode },
                        set: { newValue in _Concurrency.Task { await context.updateCompactMode(newValue) } }
                    ))
                }
            }
        }
    }
    
    // MARK: - Defaults Settings
    
    private var defaultsSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("New Task Defaults") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Default Priority:")
                            .frame(width: 120, alignment: .leading)
                        
                        Picker("Priority", selection: Binding(
                            get: { context.defaultPriority },
                            set: { newValue in _Concurrency.Task { await context.updateDefaultPriority(newValue) } }
                        )) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Label(priority.displayName, systemImage: priority.systemImageName)
                                    .tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Default Category:")
                            .frame(width: 120, alignment: .leading)
                        
                        Picker("Category", selection: Binding(
                            get: { context.defaultCategory },
                            set: { newValue in _Concurrency.Task { await context.updateDefaultCategory(newValue) } }
                        )) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.systemImageName)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Default View:")
                            .frame(width: 120, alignment: .leading)
                        
                        Picker("View Mode", selection: Binding(
                            get: { context.defaultViewMode },
                            set: { newValue in _Concurrency.Task { await context.updateDefaultViewMode(newValue) } }
                        )) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Text(mode.displayName)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Default Sort:")
                            .frame(width: 120, alignment: .leading)
                        
                        Picker("Sort Order", selection: Binding(
                            get: { context.defaultSortOrder },
                            set: { newValue in _Concurrency.Task { await context.updateDefaultSortOrder(newValue, ascending: context.defaultSortAscending) } }
                        )) {
                            ForEach(Task.SortOrder.allCases, id: \.self) { sortOrder in
                                Text(sortOrder.displayName)
                                    .tag(sortOrder)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        
                        Toggle("Ascending", isOn: Binding(
                            get: { context.defaultSortAscending },
                            set: { newValue in _Concurrency.Task { await context.updateDefaultSortOrder(context.defaultSortOrder, ascending: newValue) } }
                        ))
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Appearance Settings
    
    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Color Scheme") {
                Picker("Appearance", selection: Binding(
                    get: { context.colorScheme },
                    set: { newValue in _Concurrency.Task { await context.updateColorScheme(newValue) } }
                )) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            SettingsSection("Preview") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Sample Task")
                            .font(.headline)
                        
                        Spacer()
                        
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("This is how tasks will appear with your current settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Work")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(3)
                        
                        Spacer()
                        
                        Text("Due Tomorrow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Notification Settings
    
    private var notificationSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable notifications", isOn: Binding(
                        get: { context.enableNotifications },
                        set: { newValue in _Concurrency.Task { await context.updateEnableNotifications(newValue) } }
                    ))
                    
                    if context.enableNotifications {
                        Group {
                            HStack {
                                Text("Daily reminder:")
                                
                                DatePicker(
                                    "Time",
                                    selection: Binding(
                                        get: { context.notificationTime },
                                        set: { newValue in _Concurrency.Task { await context.updateNotificationTime(newValue) } }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                            }
                            
                            HStack {
                                Text("Reminder offset:")
                                
                                Picker("Offset", selection: Binding(
                                    get: { context.reminderOffset },
                                    set: { newValue in _Concurrency.Task { await context.updateReminderOffset(newValue) } }
                                )) {
                                    Text("1 hour before").tag(TimeInterval(-3600))
                                    Text("30 minutes before").tag(TimeInterval(-1800))
                                    Text("15 minutes before").tag(TimeInterval(-900))
                                    Text("5 minutes before").tag(TimeInterval(-300))
                                    Text("At due time").tag(TimeInterval(0))
                                }
                                .pickerStyle(.menu)
                            }
                            
                            Toggle("Sound enabled", isOn: Binding(
                                get: { context.soundEnabled },
                                set: { newValue in _Concurrency.Task { await context.updateEnableNotifications(newValue) } }
                            ))
                            
                            Toggle("Badge enabled", isOn: Binding(
                                get: { context.badgeEnabled },
                                set: { newValue in _Concurrency.Task { await context.updateEnableNotifications(newValue) } }
                            ))
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Settings
    
    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Performance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Auto-save interval:")
                        
                        Stepper(
                            "\(Int(context.autoSaveInterval))s",
                            value: Binding(
                                get: { Int(context.autoSaveInterval) },
                                set: { newValue in _Concurrency.Task { await context.updateAutoSaveInterval(TimeInterval(newValue)) } }
                            ),
                            in: 10...300,
                            step: 5
                        )
                    }
                }
            }
            
            SettingsSection("Backup") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable automatic backup", isOn: Binding(
                        get: { context.backupEnabled },
                        set: { newValue in _Concurrency.Task { await context.updateBackupEnabled(newValue) } }
                    ))
                    
                    if context.backupEnabled {
                        Group {
                            HStack {
                                Text("Backup frequency:")
                                
                                Picker("Frequency", selection: Binding(
                                    get: { context.backupFrequency },
                                    set: { newValue in _Concurrency.Task { await context.updateBackupFrequency(newValue) } }
                                )) {
                                    ForEach(BackupFrequency.allCases, id: \.self) { frequency in
                                        Text(frequency.displayName)
                                            .tag(frequency)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            
                            HStack {
                                Text("Max backups:")
                                
                                Stepper(
                                    "\(context.maxBackups)",
                                    value: Binding(
                                        get: { context.maxBackups },
                                        set: { newValue in _Concurrency.Task { await context.updateMaxBackups(newValue) } }
                                    ),
                                    in: 1...100
                                )
                            }
                            
                            Button("Create Backup Now") {
                                _Concurrency.Task { await context.createBackup() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            
            SettingsSection("Debug") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable debug mode", isOn: Binding(
                        get: { context.enableDebugMode },
                        set: { newValue in _Concurrency.Task { await context.updateEnableDebugMode(newValue) } }
                    ))
                    
                    Toggle("Enable analytics", isOn: Binding(
                        get: { context.enableAnalytics },
                        set: { newValue in _Concurrency.Task { await context.updateEnableAnalytics(newValue) } }
                    ))
                    
                    Button("Show Diagnostic Info") {
                        _Concurrency.Task {
                            diagnosticText = await context.generateDiagnosticInfo()
                            showingDiagnostics = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Data Management Settings
    
    private var dataManagementSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Storage Information") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total tasks:")
                        Spacer()
                        Text("\(context.totalTasks)")
                    }
                    
                    HStack {
                        Text("Completed tasks:")
                        Spacer()
                        Text("\(context.completedTasks)")
                    }
                    
                    HStack {
                        Text("Storage used:")
                        Spacer()
                        Text(context.storageUsageDescription)
                    }
                    
                    if context.hasRecentBackup, let lastBackup = context.lastBackupDate {
                        HStack {
                            Text("Last backup:")
                            Spacer()
                            Text(RelativeDateTimeFormatter().localizedString(for: lastBackup, relativeTo: Date()))
                        }
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
            
            SettingsSection("Export & Import") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Export Tasks") {
                            _Concurrency.Task { await context.exportTasks() }
                        }
                        .disabled(context.isExporting || context.totalTasks == 0)
                        
                        if context.isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("\(Int(context.exportProgress * 100))%")
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Button("Import Tasks") {
                            // Handle import
                        }
                        .disabled(context.isImporting)
                        
                        if context.isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("\(Int(context.importProgress * 100))%")
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            SettingsSection("Data Management", destructive: true) {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Delete Completed Tasks") {
                        _Concurrency.Task { await context.deleteCompletedTasks() }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                    .disabled(context.completedTasks == 0)
                    
                    Button("Clear All Data") {
                        showingClearDataConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(context.totalTasks == 0)
                }
            }
        }
    }
    
    // MARK: - About Settings
    
    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Application") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Version:")
                        Spacer()
                        Text("1.0.0")
                    }
                    
                    HStack {
                        Text("Build:")
                        Spacer()
                        Text("1001")
                    }
                    
                    HStack {
                        Text("Framework:")
                        Spacer()
                        Text("Axiom Framework")
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
            
            SettingsSection("Statistics") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tasks created:")
                        Spacer()
                        Text("\(context.totalTasks)")
                    }
                    
                    HStack {
                        Text("Completion rate:")
                        Spacer()
                        Text("\(Int(context.tasksCompletionPercentage * 100))%")
                    }
                    
                    if context.totalTasks > 0 {
                        ProgressView(value: context.tasksCompletionPercentage)
                            .tint(.blue)
                    }
                }
            }
            
            SettingsSection("Support") {
                VStack(alignment: .leading, spacing: 8) {
                    Link("Documentation", destination: URL(string: "https://example.com/docs")!)
                    Link("Report Bug", destination: URL(string: "https://example.com/bug")!)
                    Link("Feature Request", destination: URL(string: "https://example.com/feature")!)
                }
            }
        }
    }
}

// MARK: - Settings Section View

private struct SettingsSection<Content: View>: View {
    let title: String
    let destructive: Bool
    let content: Content
    
    init(_ title: String, destructive: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.destructive = destructive
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(destructive ? .red : .primary)
            
            content
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
        }
    }
}

// MARK: - Diagnostics View

private struct DiagnosticsView: View {
    let diagnosticText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Diagnostic Information")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ScrollView {
                Text(diagnosticText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            
            HStack {
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(diagnosticText, forType: .string)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save to File") {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.plainText]
                    savePanel.nameFieldStringValue = "task_manager_diagnostics.txt"
                    
                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        try? diagnosticText.write(to: url, atomically: true, encoding: .utf8)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

// MARK: - Settings Category Enum

private enum SettingsCategory: String, CaseIterable {
    case general = "general"
    case defaults = "defaults"
    case appearance = "appearance"
    case notifications = "notifications"
    case advanced = "advanced"
    case dataManagement = "dataManagement"
    case about = "about"
    
    var title: String {
        switch self {
        case .general: return "General"
        case .defaults: return "Defaults"
        case .appearance: return "Appearance"
        case .notifications: return "Notifications"
        case .advanced: return "Advanced"
        case .dataManagement: return "Data Management"
        case .about: return "About"
        }
    }
    
    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .defaults: return "doc.badge.gearshape"
        case .appearance: return "paintbrush"
        case .notifications: return "bell"
        case .advanced: return "terminal"
        case .dataManagement: return "externaldrive"
        case .about: return "info.circle"
        }
    }
}