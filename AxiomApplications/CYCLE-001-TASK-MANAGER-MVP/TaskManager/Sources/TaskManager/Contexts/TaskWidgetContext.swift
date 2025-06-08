import Foundation
import Axiom

/// Widget-specific display modes based on size constraints
enum WidgetDisplayMode: Equatable {
    case compact    // Small widget size
    case standard   // Medium widget size
    case detailed   // Large widget size
}

/// Widget size class for layout adaptation
enum WidgetSizeClass: Equatable {
    case small
    case medium
    case large
}

/// Widget display filter options
enum WidgetDisplayFilter: Equatable {
    case all
    case highPriorityOnly
    case dueTodayOnly
    case overdueOnly
}

/// State specific to widget display and functionality
struct WidgetState: Equatable {
    let tasks: [TaskItem]
    let lastUpdated: Date?
    let displayMode: WidgetDisplayMode
    let maxDisplayTasks: Int
    let isLowPowerOptimized: Bool
    let backgroundRefreshEnabled: Bool
    
    init(
        tasks: [TaskItem] = [],
        lastUpdated: Date? = nil,
        displayMode: WidgetDisplayMode = .compact,
        maxDisplayTasks: Int = 3,
        isLowPowerOptimized: Bool = false,
        backgroundRefreshEnabled: Bool = true
    ) {
        self.tasks = tasks
        self.lastUpdated = lastUpdated
        self.displayMode = displayMode
        self.maxDisplayTasks = maxDisplayTasks
        self.isLowPowerOptimized = isLowPowerOptimized
        self.backgroundRefreshEnabled = backgroundRefreshEnabled
    }
}

/// Context for managing widget state and interactions
@MainActor
class TaskWidgetContext: AutoSyncContext<TaskClient> {
    
    // MARK: - Properties
    
    private(set) var widgetState = WidgetState()
    private(set) var updateCount = 0
    private(set) var selectedTask: TaskItem?
    
    private var displayFilter: WidgetDisplayFilter = .all
    private var sizeClass: WidgetSizeClass = .small
    private var updateDebounceTimer: Timer?
    
    // MARK: - Initialization
    
    override init(client: TaskClient) {
        super.init(client: client)
    }
    
    override func syncInitialState() async {
        let currentState = await client.state
        await processStateUpdate(currentState)
    }
    
    // MARK: - Widget State Management
    
    func updateDisplayFilter(_ filter: WidgetDisplayFilter) async throws {
        displayFilter = filter
        await updateWidgetState()
    }
    
    func updateSizeClass(_ sizeClass: WidgetSizeClass) async throws {
        self.sizeClass = sizeClass
        
        // Update display mode and max tasks based on size class
        let (displayMode, maxTasks) = configurationForSizeClass(sizeClass)
        
        widgetState = WidgetState(
            tasks: widgetState.tasks,
            lastUpdated: widgetState.lastUpdated,
            displayMode: displayMode,
            maxDisplayTasks: maxTasks,
            isLowPowerOptimized: widgetState.isLowPowerOptimized,
            backgroundRefreshEnabled: widgetState.backgroundRefreshEnabled
        )
    }
    
    private func configurationForSizeClass(_ sizeClass: WidgetSizeClass) -> (WidgetDisplayMode, Int) {
        switch sizeClass {
        case .small:
            return (.compact, 3)
        case .medium:
            return (.standard, 6)
        case .large:
            return (.detailed, 10)
        }
    }
    
    // MARK: - State Observation
    
    override func handleStateUpdate(_ taskState: TaskState) async {
        // Immediate update for better responsiveness, with debouncing for rapid changes
        updateDebounceTimer?.invalidate()
        
        // Process update immediately for first change
        if updateCount == 0 {
            await processStateUpdate(taskState)
        } else {
            // Debounce subsequent rapid updates for battery optimization
            updateDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                Task { @MainActor in
                    await self.processStateUpdate(taskState)
                }
            }
        }
        
        // Call super to ensure proper framework handling
        await super.handleStateUpdate(taskState)
    }
    
    private func processStateUpdate(_ taskState: TaskState) async {
        updateCount += 1
        
        // Filter tasks based on display filter
        let filteredTasks = applyDisplayFilter(taskState.tasks)
        
        // Limit to max display tasks for performance
        let displayTasks = Array(filteredTasks.prefix(widgetState.maxDisplayTasks))
        
        // Create updated widget state preserving current configuration
        widgetState = createUpdatedWidgetState(
            tasks: displayTasks,
            lastUpdated: Date()
        )
    }
    
    // REFACTOR: Extracted reusable widget state creation pattern
    private func createUpdatedWidgetState(
        tasks: [TaskItem],
        lastUpdated: Date?
    ) -> WidgetState {
        return WidgetState(
            tasks: tasks,
            lastUpdated: lastUpdated,
            displayMode: widgetState.displayMode,
            maxDisplayTasks: widgetState.maxDisplayTasks,
            isLowPowerOptimized: widgetState.isLowPowerOptimized,
            backgroundRefreshEnabled: widgetState.backgroundRefreshEnabled
        )
    }
    
    private func applyDisplayFilter(_ tasks: [TaskItem]) -> [TaskItem] {
        switch displayFilter {
        case .all:
            return tasks.filter { !$0.isCompleted }
        case .highPriorityOnly:
            return tasks.filter { $0.priority == .high && !$0.isCompleted }
        case .dueTodayOnly:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            return tasks.filter { task in
                guard let dueDate = task.dueDate, !task.isCompleted else { return false }
                return dueDate >= today && dueDate < tomorrow
            }
        case .overdueOnly:
            return tasks.filter { $0.isOverdue && !$0.isCompleted }
        }
    }
    
    private func updateWidgetState() async {
        let currentState = await client.state
        await processStateUpdate(currentState)
    }
    
    // MARK: - Deep Link Handling
    
    func handleDeepLink(_ url: URL) async -> Bool {
        guard url.scheme == "taskmanager",
              url.host == "task",
              let taskIdString = url.pathComponents.last,
              let taskId = UUID(uuidString: taskIdString) else {
            return false
        }
        
        // Find the task in current app state (not just widget state)
        let currentState = await client.state
        selectedTask = currentState.tasks.first { $0.id == taskId }
        
        // Deep link is successful if we found the task
        return selectedTask != nil
    }
    
    // MARK: - Environment Handling
    
    func bind(to environment: MockWidgetEnvironment) async {
        // Update widget state based on environment conditions
        let updatedState = WidgetState(
            tasks: widgetState.tasks,
            lastUpdated: widgetState.lastUpdated,
            displayMode: widgetState.displayMode,
            maxDisplayTasks: widgetState.maxDisplayTasks,
            isLowPowerOptimized: environment.isLowPowerMode,
            backgroundRefreshEnabled: environment.isBackgroundRefreshEnabled
        )
        
        // Update the widget state
        widgetState = updatedState
    }
}

// MARK: - Mock Widget Environment (for testing)

class MockWidgetEnvironment {
    private var lowPowerMode = false
    private var backgroundRefreshEnabled = true
    
    func setLowPowerMode(_ enabled: Bool) async {
        lowPowerMode = enabled
    }
    
    func setBackgroundRefreshEnabled(_ enabled: Bool) async {
        backgroundRefreshEnabled = enabled
    }
    
    var isLowPowerMode: Bool { lowPowerMode }
    var isBackgroundRefreshEnabled: Bool { backgroundRefreshEnabled }
}