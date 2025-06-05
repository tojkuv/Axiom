import Foundation

// MARK: - Custom Navigation Pattern Protocol Extensions

/// Protocol for creating custom navigation patterns
public protocol CustomNavigationPattern: NavigationPattern {
    /// Pattern name for identification
    var patternName: String { get }
    
    /// Whether this pattern supports nesting other patterns
    var supportsNesting: Bool { get }
    
    /// Validate a transition between routes
    func validateTransition(from: Route?, to: Route) async -> Bool
    
    /// Handle pattern-specific lifecycle events
    func onActivate() async
    func onDeactivate() async
}

/// Default implementations for custom patterns
public extension CustomNavigationPattern {
    var patternType: NavigationPatternType {
        .custom(patternName)
    }
    
    var supportsNesting: Bool {
        false
    }
    
    func onActivate() async {
        // Default: no-op
    }
    
    func onDeactivate() async {
        // Default: no-op
    }
}

// MARK: - Wizard Navigation Pattern

/// Wizard-style navigation with sequential steps
public actor WizardNavigationPattern: CustomNavigationPattern {
    public let patternName = "wizard"
    private var steps: [Route] = []
    private var currentStepIndex: Int = -1
    private var completedSteps: Set<Int> = []
    private let allowBackNavigation: Bool
    private let requireSequentialCompletion: Bool
    
    public init(
        allowBackNavigation: Bool = true,
        requireSequentialCompletion: Bool = true
    ) {
        self.allowBackNavigation = allowBackNavigation
        self.requireSequentialCompletion = requireSequentialCompletion
    }
    
    public var currentState: NavigationState {
        NavigationState(
            currentRoute: currentRoute,
            history: steps,
            metadata: NavigationMetadata(
                depth: currentStepIndex + 1,
                isPresented: currentStepIndex >= 0,
                selectedTab: "",
                tabCount: steps.count
            )
        )
    }
    
    private var currentRoute: Route? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }
    
    public func navigate(to route: Route) async throws {
        // Find the step index for this route
        if let stepIndex = steps.firstIndex(of: route) {
            try await goToStep(stepIndex)
        } else {
            throw NavigationPatternError.invalidContext("Route not found in wizard steps")
        }
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        guard let targetIndex = steps.firstIndex(of: route) else {
            return false
        }
        
        // Check if we can navigate to this step
        if requireSequentialCompletion && targetIndex > currentStepIndex + 1 {
            // Can't skip ahead
            return false
        }
        
        if !allowBackNavigation && targetIndex < currentStepIndex {
            // Can't go back
            return false
        }
        
        return true
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        // Wizards typically work as root or within stack patterns
        let pattern = await MainActor.run {
            context.pattern
        }
        
        if pattern == .modal || pattern == .tab {
            throw NavigationPatternError.invalidContext("Wizard navigation not supported in \(pattern) context")
        }
    }
    
    public func validateTransition(from: Route?, to: Route) async -> Bool {
        await canNavigate(to: to)
    }
    
    /// Configure wizard steps
    public func configureSteps(_ steps: [Route]) throws {
        guard !steps.isEmpty else {
            throw NavigationPatternError.invalidContext("Wizard must have at least one step")
        }
        
        self.steps = steps
        self.currentStepIndex = -1
        self.completedSteps.removeAll()
    }
    
    /// Start the wizard
    public func start() throws {
        guard !steps.isEmpty else {
            throw NavigationPatternError.invalidContext("Wizard has no steps configured")
        }
        currentStepIndex = 0
    }
    
    /// Move to next step
    public func nextStep() throws {
        guard currentStepIndex >= 0 else {
            throw NavigationPatternError.invalidContext("Wizard not started")
        }
        
        guard currentStepIndex < steps.count - 1 else {
            throw NavigationPatternError.invalidContext("Already at last step")
        }
        
        completedSteps.insert(currentStepIndex)
        currentStepIndex += 1
    }
    
    /// Move to previous step
    public func previousStep() throws {
        guard allowBackNavigation else {
            throw NavigationPatternError.invalidContext("Back navigation not allowed")
        }
        
        guard currentStepIndex > 0 else {
            throw NavigationPatternError.invalidContext("Already at first step")
        }
        
        currentStepIndex -= 1
    }
    
    /// Go to specific step
    private func goToStep(_ index: Int) throws {
        guard index >= 0 && index < steps.count else {
            throw NavigationPatternError.invalidContext("Invalid step index")
        }
        
        if requireSequentialCompletion && index > currentStepIndex + 1 {
            // Check if all previous steps are completed
            for i in 0..<index {
                if !completedSteps.contains(i) {
                    throw NavigationPatternError.invalidContext("Must complete step \(i + 1) first")
                }
            }
        }
        
        if !allowBackNavigation && index < currentStepIndex {
            throw NavigationPatternError.invalidContext("Cannot navigate backward")
        }
        
        currentStepIndex = index
    }
    
    /// Complete current step
    public func completeCurrentStep() {
        if currentStepIndex >= 0 {
            completedSteps.insert(currentStepIndex)
        }
    }
    
    /// Check if wizard is complete
    public var isComplete: Bool {
        completedSteps.count == steps.count
    }
    
    /// Get progress
    public var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(completedSteps.count) / Double(steps.count)
    }
}

// MARK: - Drill-Down Navigation Pattern

/// Hierarchical drill-down navigation (e.g., master-detail)
public actor DrillDownNavigationPattern: CustomNavigationPattern {
    public let patternName = "drilldown"
    public let supportsNesting = true
    
    private var hierarchyStack: [(parent: Route, children: [Route])] = []
    private var currentLevel: Int = -1
    private var selectedChildIndex: Int = -1
    
    public var currentState: NavigationState {
        NavigationState(
            currentRoute: currentRoute,
            history: flattenedHistory,
            metadata: NavigationMetadata(
                depth: currentLevel + 1,
                isPresented: currentLevel >= 0
            )
        )
    }
    
    private var currentRoute: Route? {
        guard currentLevel >= 0 && currentLevel < hierarchyStack.count else {
            return nil
        }
        
        if selectedChildIndex >= 0 {
            let children = hierarchyStack[currentLevel].children
            if selectedChildIndex < children.count {
                return children[selectedChildIndex]
            }
        }
        
        return hierarchyStack[currentLevel].parent
    }
    
    private var flattenedHistory: [Route] {
        var history: [Route] = []
        for (parent, children) in hierarchyStack {
            history.append(parent)
            history.append(contentsOf: children)
        }
        return history
    }
    
    public func navigate(to route: Route) async throws {
        // Check if this is a child of current level
        if let currentChildren = currentLevel >= 0 ? hierarchyStack[currentLevel].children : nil,
           let childIndex = currentChildren.firstIndex(of: route) {
            selectedChildIndex = childIndex
            return
        }
        
        // Otherwise, treat as new level
        try await drillDown(to: route)
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        // Can navigate to any route in drill-down pattern
        true
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        // Drill-down works well in most contexts
        let pattern = await MainActor.run {
            context.pattern
        }
        
        if pattern == .tab {
            throw NavigationPatternError.invalidContext("Drill-down navigation not recommended in tab context")
        }
    }
    
    public func validateTransition(from: Route?, to: Route) async -> Bool {
        // All transitions are valid in drill-down
        true
    }
    
    /// Drill down to a new level
    public func drillDown(to parent: Route, children: [Route] = []) async throws {
        currentLevel += 1
        
        // Add new level to stack
        if currentLevel < hierarchyStack.count {
            // Replace existing level
            hierarchyStack[currentLevel] = (parent, children)
            // Remove any levels beyond this
            hierarchyStack.removeLast(hierarchyStack.count - currentLevel - 1)
        } else {
            // Add new level
            hierarchyStack.append((parent, children))
        }
        
        selectedChildIndex = -1
    }
    
    /// Navigate back one level
    public func drillUp() throws {
        guard currentLevel > 0 else {
            throw NavigationPatternError.invalidContext("Already at root level")
        }
        
        currentLevel -= 1
        selectedChildIndex = -1
    }
    
    /// Navigate to root
    public func drillToRoot() {
        currentLevel = 0
        selectedChildIndex = -1
        
        // Keep only root level
        if !hierarchyStack.isEmpty {
            let root = hierarchyStack[0]
            hierarchyStack = [root]
        }
    }
    
    /// Update children for current level
    public func updateChildren(_ children: [Route]) throws {
        guard currentLevel >= 0 && currentLevel < hierarchyStack.count else {
            throw NavigationPatternError.invalidContext("No current level to update")
        }
        
        hierarchyStack[currentLevel].children = children
        selectedChildIndex = -1
    }
}

// MARK: - Breadcrumb Navigation Pattern

/// Breadcrumb-style navigation with non-linear paths
public actor BreadcrumbNavigationPattern: CustomNavigationPattern {
    public let patternName = "breadcrumb"
    
    private var breadcrumbs: [Route] = []
    private var currentIndex: Int = -1
    
    public var currentState: NavigationState {
        NavigationState(
            currentRoute: currentRoute,
            history: breadcrumbs,
            metadata: NavigationMetadata(
                depth: breadcrumbs.count,
                isPresented: currentIndex >= 0
            )
        )
    }
    
    private var currentRoute: Route? {
        guard currentIndex >= 0 && currentIndex < breadcrumbs.count else {
            return nil
        }
        return breadcrumbs[currentIndex]
    }
    
    public func navigate(to route: Route) async throws {
        // Check if route exists in breadcrumbs
        if let existingIndex = breadcrumbs.firstIndex(of: route) {
            // Jump to existing breadcrumb
            currentIndex = existingIndex
        } else {
            // Add new breadcrumb
            try addBreadcrumb(route)
        }
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        // Can always navigate in breadcrumb pattern
        true
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        // Breadcrumbs work in most contexts
    }
    
    public func validateTransition(from: Route?, to: Route) async -> Bool {
        true
    }
    
    /// Add a new breadcrumb
    public func addBreadcrumb(_ route: Route) throws {
        // Remove any breadcrumbs after current position
        if currentIndex >= 0 && currentIndex < breadcrumbs.count - 1 {
            breadcrumbs.removeLast(breadcrumbs.count - currentIndex - 1)
        }
        
        breadcrumbs.append(route)
        currentIndex = breadcrumbs.count - 1
    }
    
    /// Jump to breadcrumb at index
    public func jumpToBreadcrumb(at index: Int) throws {
        guard index >= 0 && index < breadcrumbs.count else {
            throw NavigationPatternError.invalidContext("Invalid breadcrumb index")
        }
        currentIndex = index
    }
    
    /// Remove breadcrumb at index
    public func removeBreadcrumb(at index: Int) throws {
        guard index >= 0 && index < breadcrumbs.count else {
            throw NavigationPatternError.invalidContext("Invalid breadcrumb index")
        }
        
        breadcrumbs.remove(at: index)
        
        // Adjust current index if needed
        if currentIndex >= index {
            currentIndex = max(0, currentIndex - 1)
        }
        
        if breadcrumbs.isEmpty {
            currentIndex = -1
        }
    }
    
    /// Clear all breadcrumbs
    public func clearBreadcrumbs() {
        breadcrumbs.removeAll()
        currentIndex = -1
    }
    
    /// Get breadcrumb trail
    public var trail: [Route] {
        breadcrumbs
    }
}

// MARK: - Custom Pattern Factory

/// Factory for creating custom navigation patterns
public struct CustomNavigationPatternFactory {
    
    /// Create a wizard pattern
    public static func wizard(
        allowBackNavigation: Bool = true,
        requireSequentialCompletion: Bool = true
    ) -> WizardNavigationPattern {
        WizardNavigationPattern(
            allowBackNavigation: allowBackNavigation,
            requireSequentialCompletion: requireSequentialCompletion
        )
    }
    
    /// Create a drill-down pattern
    public static func drillDown() -> DrillDownNavigationPattern {
        DrillDownNavigationPattern()
    }
    
    /// Create a breadcrumb pattern
    public static func breadcrumb() -> BreadcrumbNavigationPattern {
        BreadcrumbNavigationPattern()
    }
    
    /// Register custom pattern with coordinator
    public static func register<P: CustomNavigationPattern>(
        _ pattern: P,
        with coordinator: NavigationPatternCoordinator
    ) async {
        await coordinator.registerCustomPattern(pattern)
    }
}

// MARK: - Navigation Pattern Coordinator Extensions

public extension NavigationPatternCoordinator {
    
    /// Register a custom navigation pattern
    func registerCustomPattern<P: CustomNavigationPattern>(_ pattern: P) async {
        // This would be implemented to add custom patterns to the coordinator
        // For now, it's a placeholder for the extension point
    }
    
    /// Use custom pattern for navigation
    func navigateUsingCustomPattern<P: CustomNavigationPattern>(
        _ patternType: P.Type,
        to route: Route
    ) async throws {
        // This would look up the registered custom pattern and use it
        // For now, it's a placeholder for the extension point
    }
}

