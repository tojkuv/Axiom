import Testing
import Foundation
@testable import TestApp002Core

@Suite("Permission Error Handling - REFACTOR Phase")
struct PermissionErrorHandlingTestsRefactor {
    
    // MARK: - Permission Prompt Tests
    
    @Test("Should prompt user for file system permissions when needed")
    func testPromptsForFileSystemPermissions() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .notDetermined)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        // Request permission
        let result = await permissionService.requestPermission(for: .fileSystem)
        
        #expect(result.prompted == true, "Should prompt for permissions")
        #expect(result.explanation != nil, "Should provide explanation")
        #expect(result.explanation?.contains("store data") == true, "Should explain why file access is needed")
    }
    
    @Test("Should prompt user for network permissions with clear explanation")
    func testPromptsForNetworkPermissionsWithExplanation() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.network, status: .notDetermined)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        let result = await permissionService.requestPermission(for: .network)
        
        #expect(result.prompted == true, "Should prompt for permissions")
        #expect(result.explanation?.contains("sync") == true, "Should explain syncing needs network")
        #expect(result.fallbackOptions.count > 0, "Should provide fallback options")
    }
    
    @Test("Should provide settings deep link when permissions are denied")
    func testProvidesSettingsDeepLink() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.notifications, status: .denied)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        let guidance = await permissionService.getPermissionGuidance(for: .notifications)
        
        #expect(guidance.settingsURL != nil, "Should provide settings URL")
        #expect(guidance.instructions.count > 0, "Should provide step-by-step instructions")
        #expect(guidance.instructions.contains { $0.contains("Settings") }, "Should mention Settings app")
    }
    
    // MARK: - User Guidance Tests
    
    @Test("Should show educational content about permissions")
    func testShowsEducationalContent() async throws {
        let permissionService = PermissionService()
        
        let education = await permissionService.getPermissionEducation()
        
        #expect(education.whyNeeded.count == 3, "Should explain all three permission types")
        #expect(education.privacyAssurances.count > 0, "Should provide privacy assurances")
        #expect(education.canChangeAnytime == true, "Should mention permissions can be changed")
    }
    
    @Test("Should provide context-sensitive permission requests")
    func testContextSensitivePermissionRequests() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.notifications, status: .notDetermined)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        // Request in context of setting a reminder
        let context = PermissionContext(
            action: .settingReminder,
            feature: "Task Due Date Reminder"
        )
        
        let result = await permissionService.requestPermission(for: .notifications, context: context)
        
        #expect(result.explanation?.contains("reminder") == true, "Should mention reminders in context")
        #expect(result.timing == .justInTime, "Should request just-in-time")
    }
    
    @Test("Should batch permission requests intelligently")
    func testBatchesPermissionRequestsIntelligently() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .notDetermined)
        await permissionManager.setPermission(.network, status: .notDetermined)
        await permissionManager.setPermission(.notifications, status: .notDetermined)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        // Request all permissions for initial setup
        let results = await permissionService.requestPermissionsForInitialSetup()
        
        #expect(results.count == 2, "Should only request essential permissions initially")
        #expect(results.contains { $0.type == .fileSystem }, "Should request file system for core functionality")
        #expect(results.contains { $0.type == .network }, "Should request network for syncing")
        #expect(!results.contains { $0.type == .notifications }, "Should defer notification permission")
    }
    
    // MARK: - Permission State Management Tests
    
    @Test("Should remember permission request history")
    func testRemembersPermissionRequestHistory() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.notifications, status: .denied)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        // First request
        _ = await permissionService.requestPermission(for: .notifications)
        
        // Second request
        let result = await permissionService.requestPermission(for: .notifications)
        
        #expect(result.previouslyDenied == true, "Should remember previous denial")
        #expect(result.timeSinceLastPrompt != nil, "Should track time since last prompt")
        #expect(result.shouldRespectUserChoice == true, "Should respect user's previous choice")
    }
    
    @Test("Should provide permission status dashboard")
    func testProvidesPermissionStatusDashboard() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .authorized)
        await permissionManager.setPermission(.network, status: .denied)
        await permissionManager.setPermission(.notifications, status: .notDetermined)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        let dashboard = await permissionService.getPermissionDashboard()
        
        #expect(dashboard.permissions.count == 3, "Should show all permissions")
        #expect(dashboard.permissions[.fileSystem]?.status == .authorized, "Should show correct status")
        #expect(dashboard.permissions[.network]?.impact != nil, "Should explain impact of denied permissions")
        #expect(dashboard.overallHealth == .partial, "Should indicate partial functionality")
    }
    
    @Test("Should handle permission changes gracefully")
    func testHandlesPermissionChangesGracefully() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.network, status: .denied)
        
        let permissionService = PermissionService()
        await permissionService.setPermissionManager(permissionManager)
        
        // Subscribe to permission changes
        var changeNotified = false
        await permissionService.onPermissionChange { change in
            changeNotified = true
            #expect(change.type == .network, "Should identify changed permission")
            #expect(change.oldStatus == .denied, "Should track old status")
            #expect(change.newStatus == .authorized, "Should track new status")
        }
        
        // Simulate permission change
        await permissionManager.setPermission(.network, status: .authorized)
        await permissionService.checkForPermissionChanges()
        
        #expect(changeNotified == true, "Should notify of permission changes")
    }
}

// MARK: - Permission Service Implementation

actor PermissionService {
    private var permissionManager: MockPermissionManager?
    private var requestHistory: [PermissionType: [PermissionRequest]] = [:]
    private var permissionChangeHandlers: [(PermissionChange) -> Void] = []
    private var lastKnownStatuses: [PermissionType: PermissionStatus] = [:]
    
    func setPermissionManager(_ manager: MockPermissionManager) {
        self.permissionManager = manager
    }
    
    func requestPermission(for type: PermissionType, context: PermissionContext? = nil) async -> PermissionResult {
        guard let manager = permissionManager else {
            return PermissionResult(type: type, prompted: false, granted: false)
        }
        
        let currentStatus = await manager.checkPermission(type)
        let previousRequests = requestHistory[type] ?? []
        let previouslyDenied = previousRequests.contains { $0.result == .denied }
        
        var explanation: String?
        var fallbackOptions: [String] = []
        let timing: PermissionTiming = context != nil ? .justInTime : .onDemand
        
        switch type {
        case .fileSystem:
            explanation = "TestApp002 needs to store data locally to save your tasks and preferences."
            fallbackOptions = ["Use in-memory storage (data won't persist)", "Export/import data manually"]
        case .network:
            explanation = context?.action == .syncing 
                ? "TestApp002 needs network access to sync your tasks across devices."
                : "TestApp002 needs network access to sync tasks and check for updates."
            fallbackOptions = ["Work offline", "Manual sync when connected"]
        case .notifications:
            if context?.action == .settingReminder {
                explanation = "TestApp002 can send you reminders for your tasks at the scheduled time."
            } else {
                explanation = "TestApp002 can notify you about task reminders and important updates."
            }
            fallbackOptions = ["In-app reminders only", "Calendar integration", "Email reminders"]
        }
        
        // Record request
        let request = PermissionRequest(
            timestamp: Date(),
            context: context,
            result: currentStatus
        )
        requestHistory[type, default: []].append(request)
        
        let shouldRespectChoice = previouslyDenied && previousRequests.count > 2
        let timeSinceLastPrompt = previousRequests.last.map { Date().timeIntervalSince($0.timestamp) }
        
        return PermissionResult(
            type: type,
            prompted: currentStatus == .notDetermined,
            granted: currentStatus == .authorized,
            explanation: explanation,
            fallbackOptions: fallbackOptions,
            previouslyDenied: previouslyDenied,
            timeSinceLastPrompt: timeSinceLastPrompt,
            shouldRespectUserChoice: shouldRespectChoice,
            timing: timing
        )
    }
    
    func getPermissionGuidance(for type: PermissionType) async -> PermissionGuidance {
        let settingsURL = URL(string: "app-settings://TestApp002/permissions/\(type)")
        
        var instructions: [String] = []
        switch type {
        case .fileSystem:
            instructions = [
                "Open Settings app",
                "Navigate to Privacy & Security",
                "Select Files and Folders",
                "Find TestApp002",
                "Toggle on to grant access"
            ]
        case .network:
            instructions = [
                "Open Settings app",
                "Find TestApp002",
                "Enable 'Local Network' access",
                "Enable 'Cellular Data' if needed"
            ]
        case .notifications:
            instructions = [
                "Open Settings app",
                "Navigate to Notifications",
                "Find TestApp002",
                "Toggle 'Allow Notifications'",
                "Customize alert style as desired"
            ]
        }
        
        return PermissionGuidance(
            type: type,
            settingsURL: settingsURL,
            instructions: instructions
        )
    }
    
    func getPermissionEducation() async -> PermissionEducation {
        return PermissionEducation(
            whyNeeded: [
                "File System: Saves your tasks and preferences locally",
                "Network: Syncs data across devices and enables collaboration",
                "Notifications: Reminds you about important tasks"
            ],
            privacyAssurances: [
                "Your data stays on your device unless you enable sync",
                "We never share your information with third parties",
                "All network communication is encrypted",
                "You can export and delete your data at any time"
            ],
            canChangeAnytime: true
        )
    }
    
    func requestPermissionsForInitialSetup() async -> [PermissionResult] {
        guard let manager = permissionManager else { return [] }
        
        var results: [PermissionResult] = []
        
        // Only request essential permissions initially
        let essentialPermissions: [PermissionType] = [.fileSystem, .network]
        
        for type in essentialPermissions {
            let status = await manager.checkPermission(type)
            if status == .notDetermined {
                let result = await requestPermission(for: type)
                results.append(result)
            }
        }
        
        return results
    }
    
    func getPermissionDashboard() async -> PermissionDashboard {
        guard let manager = permissionManager else {
            return PermissionDashboard(permissions: [:], overallHealth: .unknown)
        }
        
        var permissions: [PermissionType: PermissionInfo] = [:]
        
        for type in [PermissionType.fileSystem, .network, .notifications] {
            let status = await manager.checkPermission(type)
            let impact = status == .denied ? getImpactDescription(for: type) : nil
            
            permissions[type] = PermissionInfo(
                type: type,
                status: status,
                impact: impact
            )
        }
        
        let deniedCount = permissions.values.filter { $0.status == .denied }.count
        let overallHealth: HealthStatus
        switch deniedCount {
        case 0:
            overallHealth = .full
        case 1:
            overallHealth = .partial
        case 2:
            overallHealth = .limited
        default:
            overallHealth = .minimal
        }
        
        return PermissionDashboard(
            permissions: permissions,
            overallHealth: overallHealth
        )
    }
    
    func onPermissionChange(_ handler: @escaping (PermissionChange) -> Void) async {
        permissionChangeHandlers.append(handler)
    }
    
    func checkForPermissionChanges() async {
        guard let manager = permissionManager else { return }
        
        for type in [PermissionType.fileSystem, .network, .notifications] {
            let currentStatus = await manager.checkPermission(type)
            let lastStatus = lastKnownStatuses[type]
            
            if let lastStatus = lastStatus, lastStatus != currentStatus {
                let change = PermissionChange(
                    type: type,
                    oldStatus: lastStatus,
                    newStatus: currentStatus,
                    timestamp: Date()
                )
                
                for handler in permissionChangeHandlers {
                    handler(change)
                }
            }
            
            lastKnownStatuses[type] = currentStatus
        }
    }
    
    private func getImpactDescription(for type: PermissionType) -> String {
        switch type {
        case .fileSystem:
            return "Tasks won't be saved between app launches"
        case .network:
            return "Tasks won't sync across devices"
        case .notifications:
            return "You won't receive task reminders"
        }
    }
}

// MARK: - Supporting Types

struct PermissionResult {
    let type: PermissionType
    let prompted: Bool
    let granted: Bool
    let explanation: String?
    let fallbackOptions: [String]
    let previouslyDenied: Bool
    let timeSinceLastPrompt: TimeInterval?
    let shouldRespectUserChoice: Bool
    let timing: PermissionTiming
    
    init(
        type: PermissionType,
        prompted: Bool,
        granted: Bool,
        explanation: String? = nil,
        fallbackOptions: [String] = [],
        previouslyDenied: Bool = false,
        timeSinceLastPrompt: TimeInterval? = nil,
        shouldRespectUserChoice: Bool = false,
        timing: PermissionTiming = .onDemand
    ) {
        self.type = type
        self.prompted = prompted
        self.granted = granted
        self.explanation = explanation
        self.fallbackOptions = fallbackOptions
        self.previouslyDenied = previouslyDenied
        self.timeSinceLastPrompt = timeSinceLastPrompt
        self.shouldRespectUserChoice = shouldRespectUserChoice
        self.timing = timing
    }
}

struct PermissionContext {
    enum Action {
        case settingReminder
        case syncing
        case savingData
        case general
    }
    
    let action: Action
    let feature: String
}

struct PermissionRequest {
    let timestamp: Date
    let context: PermissionContext?
    let result: PermissionStatus
}

struct PermissionGuidance {
    let type: PermissionType
    let settingsURL: URL?
    let instructions: [String]
}

struct PermissionEducation {
    let whyNeeded: [String]
    let privacyAssurances: [String]
    let canChangeAnytime: Bool
}

struct PermissionDashboard {
    let permissions: [PermissionType: PermissionInfo]
    let overallHealth: HealthStatus
}

struct PermissionInfo {
    let type: PermissionType
    let status: PermissionStatus
    let impact: String?
}

struct PermissionChange {
    let type: PermissionType
    let oldStatus: PermissionStatus
    let newStatus: PermissionStatus
    let timestamp: Date
}

enum PermissionTiming {
    case onboarding
    case justInTime
    case onDemand
}

enum HealthStatus {
    case full
    case partial
    case limited
    case minimal
    case unknown
}