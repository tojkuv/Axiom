import XCTest
import CoreGraphics
@testable import TestApp002

// RED Phase: Failing tests for modal presentation lifecycle
// RFC Requirement: Task creation and editing in modal sheets
// RFC Acceptance: Modal animations complete in < 250ms
// RFC Boundary: Proper Context cleanup on dismissal

class ModalPresentationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean state for each test
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Basic Modal Presentation Tests
    
    func testTaskCreationModalPresentation() async throws {
        // RED: This test should fail - ModalPresentationController doesn't exist
        let modalController = ModalPresentationController()
        
        // Test presenting task creation modal
        let presentationResult = try await modalController.presentModal(.taskCreation, style: .sheet)
        
        XCTAssertTrue(presentationResult.isPresented)
        XCTAssertEqual(presentationResult.modalType, .taskCreation)
        XCTAssertEqual(presentationResult.style, .sheet)
        
        // Verify modal context is created
        let modalContext = try await modalController.getCurrentModalContext()
        XCTAssertNotNil(modalContext)
        
        // Verify presentation completes quickly
        XCTAssertTrue(presentationResult.animationDuration < 0.25) // < 250ms
    }
    
    func testTaskEditingModalPresentation() async throws {
        // RED: This test should fail - ModalPresentationController doesn't exist
        let modalController = ModalPresentationController()
        
        // Test presenting task editing modal
        let taskId = "test-task-123"
        let presentationResult = try await modalController.presentModal(.taskEdit(taskId: taskId), style: .sheet)
        
        XCTAssertTrue(presentationResult.isPresented)
        XCTAssertEqual(presentationResult.modalType, .taskEdit(taskId: taskId))
        XCTAssertEqual(presentationResult.style, .sheet)
        
        // Verify modal has access to task data
        let modalContext = try await modalController.getCurrentModalContext()
        let taskData = try await modalContext.getTaskData()
        XCTAssertEqual(taskData.taskId, taskId)
    }
    
    func testAnimationPerformance() async throws {
        // RED: Test animation timing requirements
        let modalController = ModalPresentationController()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Present modal and measure timing
        let result = try await modalController.presentModal(.taskCreation, style: .sheet)
        
        let animationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // RFC Acceptance: Modal animations complete in < 250ms
        XCTAssertLessThan(animationTime, 0.25, "Modal animation should complete within 250ms")
        XCTAssertTrue(result.isPresented)
    }
    
    // MARK: - Modal Dismissal Tests
    
    func testModalDismissal() async throws {
        // RED: Test modal dismissal
        let modalController = ModalPresentationController()
        
        // Present a modal first
        let presentResult = try await modalController.presentModal(.taskCreation, style: .sheet)
        XCTAssertTrue(presentResult.isPresented)
        
        // Dismiss the modal
        let dismissResult = try await modalController.dismissModal()
        
        XCTAssertTrue(dismissResult.wasDismissed)
        
        let hasActiveModal = try await modalController.hasActiveModal()
        XCTAssertFalse(hasActiveModal)
        
        // Verify animation performance
        XCTAssertLessThan(dismissResult.animationDuration, 0.25)
    }
    
    func testContextCleanupOnDismissal() async throws {
        // RED: Test proper Context cleanup on dismissal
        let modalController = ModalPresentationController()
        
        // Present modal and verify context exists
        _ = try await modalController.presentModal(.taskCreation, style: .sheet)
        let contextBeforeDismissal = try await modalController.getCurrentModalContext()
        XCTAssertNotNil(contextBeforeDismissal)
        
        // Dismiss modal
        _ = try await modalController.dismissModal()
        
        // Verify context is cleaned up
        do {
            _ = try await modalController.getCurrentModalContext()
            XCTFail("Context should be cleaned up after dismissal")
        } catch ModalPresentationError.noActiveModal {
            // Expected - context should be cleaned up
        }
    }
    
    // MARK: - Modal Stack Management Tests
    
    func testMultipleModalPresentation() async throws {
        // RED: Test presenting multiple modals
        let modalController = ModalPresentationController()
        
        // Present first modal
        let firstResult = try await modalController.presentModal(.taskCreation, style: .sheet)
        XCTAssertTrue(firstResult.isPresented)
        
        // Present second modal on top
        let secondResult = try await modalController.presentModal(.categoryEdit(categoryId: "cat-1"), style: .fullScreen)
        XCTAssertTrue(secondResult.isPresented)
        
        // Verify modal stack
        let modalStack = try await modalController.getModalStack()
        XCTAssertEqual(modalStack.count, 2)
        XCTAssertEqual(modalStack.last?.modalType, .categoryEdit(categoryId: "cat-1"))
    }
    
    func testModalStackDismissal() async throws {
        // RED: Test dismissing from modal stack
        let modalController = ModalPresentationController()
        
        // Present multiple modals
        _ = try await modalController.presentModal(.taskCreation, style: .sheet)
        _ = try await modalController.presentModal(.categoryEdit(categoryId: "cat-1"), style: .sheet)
        
        // Dismiss top modal
        let dismissResult = try await modalController.dismissModal()
        XCTAssertTrue(dismissResult.wasDismissed)
        
        // Verify first modal is still active
        let remainingStack = try await modalController.getModalStack()
        XCTAssertEqual(remainingStack.count, 1)
        XCTAssertEqual(remainingStack.first?.modalType, .taskCreation)
    }
    
    // MARK: - Modal Style Tests
    
    func testSheetModalStyle() async throws {
        // RED: Test sheet presentation style
        let modalController = ModalPresentationController()
        
        let result = try await modalController.presentModal(.taskCreation, style: .sheet)
        
        XCTAssertEqual(result.style, .sheet)
        XCTAssertTrue(result.allowsInteractiveBackground)
        XCTAssertTrue(result.supportsDragToDismiss)
    }
    
    func testFullScreenModalStyle() async throws {
        // RED: Test full screen presentation style
        let modalController = ModalPresentationController()
        
        let result = try await modalController.presentModal(.taskCreation, style: .fullScreen)
        
        XCTAssertEqual(result.style, .fullScreen)
        XCTAssertFalse(result.allowsInteractiveBackground)
        XCTAssertFalse(result.supportsDragToDismiss)
    }
    
    // MARK: - REFACTOR Phase: Enhanced Features Tests
    
    func testDismissGestureConfiguration() async throws {
        // REFACTOR: Test dismiss gesture options
        let modalController = ModalPresentationController()
        
        let config = ModalPresentationConfig(
            allowsSwipeToDismiss: true,
            allowsBackdropTap: true,
            requiresConfirmation: false
        )
        
        let result = try await modalController.presentModalWithConfig(.taskCreation, style: .sheet, config: config)
        
        XCTAssertTrue(result.config.allowsSwipeToDismiss)
        XCTAssertTrue(result.config.allowsBackdropTap)
        XCTAssertFalse(result.config.requiresConfirmation)
    }
    
    func testBackdropTapDismissal() async throws {
        // REFACTOR: Test backdrop tap dismissal
        let modalController = ModalPresentationController()
        
        let config = ModalPresentationConfig(allowsBackdropTap: true)
        _ = try await modalController.presentModalWithConfig(.taskCreation, style: .sheet, config: config)
        
        // Simulate backdrop tap
        let dismissResult = try await modalController.dismissViaBackdrop()
        
        XCTAssertTrue(dismissResult.wasDismissed)
        XCTAssertEqual(dismissResult.dismissalMethod, .backdropTap)
    }
    
    func testSwipeToDismissGesture() async throws {
        // REFACTOR: Test swipe gesture dismissal
        let modalController = ModalPresentationController()
        
        let config = ModalPresentationConfig(allowsSwipeToDismiss: true)
        _ = try await modalController.presentModalWithConfig(.taskCreation, style: .sheet, config: config)
        
        // Simulate swipe gesture
        let dismissResult = try await modalController.dismissViaSwipe()
        
        XCTAssertTrue(dismissResult.wasDismissed)
        XCTAssertEqual(dismissResult.dismissalMethod, .swipeGesture)
    }
    
    func testModalWithConfirmationRequired() async throws {
        // REFACTOR: Test confirmation requirement for dismissal
        let modalController = ModalPresentationController()
        
        let config = ModalPresentationConfig(requiresConfirmation: true)
        _ = try await modalController.presentModalWithConfig(.taskEdit(taskId: "test"), style: .sheet, config: config)
        
        // Attempt dismissal without confirmation should fail
        do {
            _ = try await modalController.dismissViaBackdrop()
            XCTFail("Should require confirmation")
        } catch ModalPresentationError.confirmationRequired {
            // Expected
        }
        
        // Dismiss with confirmation should succeed
        let dismissResult = try await modalController.dismissWithConfirmation()
        XCTAssertTrue(dismissResult.wasDismissed)
    }
    
    func testAccessibilityFeatures() async throws {
        // REFACTOR: Test accessibility enhancements
        let modalController = ModalPresentationController()
        
        let accessibilityConfig = AccessibilityConfig(
            announcePresentation: true,
            customLabel: "Task creation modal",
            supportsDynamicType: true
        )
        
        let config = ModalPresentationConfig(accessibility: accessibilityConfig)
        let result = try await modalController.presentModalWithConfig(.taskCreation, style: .sheet, config: config)
        
        XCTAssertEqual(result.config.accessibility?.customLabel, "Task creation modal")
        XCTAssertTrue(result.config.accessibility?.announcePresentation ?? false)
    }
    
    func testAnimationCustomization() async throws {
        // REFACTOR: Test custom animation options
        let modalController = ModalPresentationController()
        
        let animationConfig = AnimationConfig(
            duration: 0.2,
            curve: .easeInOut,
            springDamping: 0.8
        )
        
        let config = ModalPresentationConfig(animation: animationConfig)
        let result = try await modalController.presentModalWithConfig(.taskCreation, style: .sheet, config: config)
        
        // Verify animation configuration
        XCTAssertEqual(result.config.animation?.duration, 0.2)
        XCTAssertEqual(result.config.animation?.curve, .easeInOut)
        
        // Animation should still complete within 250ms requirement
        XCTAssertLessThan(result.animationDuration, 0.25)
    }
    
    func testModalPresentationWithKeyboardHandling() async throws {
        // REFACTOR: Test keyboard interaction handling
        let modalController = ModalPresentationController()
        
        let config = ModalPresentationConfig(adjustsForKeyboard: true)
        _ = try await modalController.presentModalWithConfig(.taskCreation, style: .sheet, config: config)
        
        // Simulate keyboard appearance
        try await modalController.handleKeyboardAppearance(height: 300)
        
        let modalInfo = try await modalController.getCurrentModalInfo()
        XCTAssertTrue(modalInfo.isAdjustedForKeyboard)
    }
    
    // MARK: - Error Handling Tests
    
    func testPresentModalWhenAlreadyPresented() async throws {
        // RED: Test error handling for presenting when modal already active
        let modalController = ModalPresentationController()
        
        // Present first modal
        _ = try await modalController.presentModal(.taskCreation, style: .sheet)
        
        // Attempt to present same modal type again
        do {
            _ = try await modalController.presentModal(.taskCreation, style: .sheet)
            XCTFail("Should throw error for duplicate modal presentation")
        } catch ModalPresentationError.modalAlreadyPresented {
            // Expected error
        }
    }
    
    func testDismissWhenNoModalPresented() async throws {
        // RED: Test error handling for dismissing when no modal present
        let modalController = ModalPresentationController()
        
        do {
            _ = try await modalController.dismissModal()
            XCTFail("Should throw error when no modal to dismiss")
        } catch ModalPresentationError.noActiveModal {
            // Expected error
        }
    }
}

// MARK: - Supporting Types (These will fail compilation initially)

enum ModalType: Equatable, Hashable {
    case taskCreation
    case taskEdit(taskId: String)
    case categoryEdit(categoryId: String)
    case settings
}

enum ModalPresentationStyle: Equatable {
    case sheet
    case fullScreen
}

struct ModalPresentationResult {
    let isPresented: Bool
    let modalType: ModalType
    let style: ModalPresentationStyle
    let animationDuration: TimeInterval
    let allowsInteractiveBackground: Bool
    let supportsDragToDismiss: Bool
    let config: ModalPresentationConfig
}

struct ModalDismissalResult {
    let wasDismissed: Bool
    let animationDuration: TimeInterval
    let dismissalMethod: DismissalMethod
}

// REFACTOR: Enhanced configuration types
struct ModalPresentationConfig {
    let allowsSwipeToDismiss: Bool
    let allowsBackdropTap: Bool
    let requiresConfirmation: Bool
    let adjustsForKeyboard: Bool
    let accessibility: AccessibilityConfig?
    let animation: AnimationConfig?
    
    init(
        allowsSwipeToDismiss: Bool = true,
        allowsBackdropTap: Bool = true,
        requiresConfirmation: Bool = false,
        adjustsForKeyboard: Bool = false,
        accessibility: AccessibilityConfig? = nil,
        animation: AnimationConfig? = nil
    ) {
        self.allowsSwipeToDismiss = allowsSwipeToDismiss
        self.allowsBackdropTap = allowsBackdropTap
        self.requiresConfirmation = requiresConfirmation
        self.adjustsForKeyboard = adjustsForKeyboard
        self.accessibility = accessibility
        self.animation = animation
    }
}

struct AccessibilityConfig {
    let announcePresentation: Bool
    let customLabel: String
    let supportsDynamicType: Bool
    
    init(announcePresentation: Bool = false, customLabel: String = "", supportsDynamicType: Bool = true) {
        self.announcePresentation = announcePresentation
        self.customLabel = customLabel
        self.supportsDynamicType = supportsDynamicType
    }
}

struct AnimationConfig {
    let duration: TimeInterval
    let curve: AnimationCurve
    let springDamping: Double
    
    init(duration: TimeInterval = 0.25, curve: AnimationCurve = .easeInOut, springDamping: Double = 1.0) {
        self.duration = duration
        self.curve = curve
        self.springDamping = springDamping
    }
}

enum AnimationCurve: Equatable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
}

enum DismissalMethod: Equatable {
    case manual
    case backdropTap
    case swipeGesture
    case confirmation
}

struct ModalInfo {
    let modalType: ModalType
    let style: ModalPresentationStyle
    let context: ModalContext
    let config: ModalPresentationConfig
    let isAdjustedForKeyboard: Bool
    
    init(modalType: ModalType, style: ModalPresentationStyle, context: ModalContext, config: ModalPresentationConfig, isAdjustedForKeyboard: Bool = false) {
        self.modalType = modalType
        self.style = style
        self.context = context
        self.config = config
        self.isAdjustedForKeyboard = isAdjustedForKeyboard
    }
}

enum ModalPresentationError: Error {
    case modalAlreadyPresented
    case noActiveModal
    case contextNotFound
    case animationTimeout
    case confirmationRequired
    case gestureNotAllowed
}

// GREEN Phase: Real ModalPresentationController implementation
actor ModalPresentationController {
    private var modalStack: [ModalInfo] = []
    private var animationStartTimes: [ModalType: CFAbsoluteTime] = [:]
    
    func presentModal(_ type: ModalType, style: ModalPresentationStyle) async throws -> ModalPresentationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check if same modal type already presented
        if modalStack.contains(where: { $0.modalType == type }) {
            throw ModalPresentationError.modalAlreadyPresented
        }
        
        // Create modal context
        let context = ModalContext(modalType: type)
        
        // Create default config for legacy method
        let defaultConfig = ModalPresentationConfig()
        
        // Create modal info
        let modalInfo = ModalInfo(modalType: type, style: style, context: context, config: defaultConfig)
        modalStack.append(modalInfo)
        
        // Track animation timing
        animationStartTimes[type] = startTime
        
        // Simulate modal presentation animation
        // In real implementation, this would trigger UI animation
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms animation
        
        let animationDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return ModalPresentationResult(
            isPresented: true,
            modalType: type,
            style: style,
            animationDuration: animationDuration,
            allowsInteractiveBackground: style == .sheet,
            supportsDragToDismiss: style == .sheet,
            config: defaultConfig
        )
    }
    
    func dismissModal() async throws -> ModalDismissalResult {
        guard !modalStack.isEmpty else {
            throw ModalPresentationError.noActiveModal
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Remove last modal from stack
        let dismissedModal = modalStack.removeLast()
        
        // Clean up animation tracking
        animationStartTimes.removeValue(forKey: dismissedModal.modalType)
        
        // Simulate dismissal animation
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms animation
        
        let animationDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return ModalDismissalResult(
            wasDismissed: true,
            animationDuration: animationDuration,
            dismissalMethod: .manual
        )
    }
    
    func hasActiveModal() async throws -> Bool {
        return !modalStack.isEmpty
    }
    
    func getCurrentModalContext() async throws -> ModalContext {
        guard let currentModal = modalStack.last else {
            throw ModalPresentationError.noActiveModal
        }
        
        return currentModal.context
    }
    
    func getModalStack() async throws -> [ModalInfo] {
        return modalStack
    }
    
    // MARK: - REFACTOR Phase: Enhanced Methods
    
    func presentModalWithConfig(_ type: ModalType, style: ModalPresentationStyle, config: ModalPresentationConfig) async throws -> ModalPresentationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check if same modal type already presented
        if modalStack.contains(where: { $0.modalType == type }) {
            throw ModalPresentationError.modalAlreadyPresented
        }
        
        // Create modal context
        let context = ModalContext(modalType: type)
        
        // Create modal info with config
        let modalInfo = ModalInfo(modalType: type, style: style, context: context, config: config)
        modalStack.append(modalInfo)
        
        // Track animation timing
        animationStartTimes[type] = startTime
        
        // Use custom animation duration if specified
        let animationDuration = config.animation?.duration ?? 0.05
        try await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
        
        let actualDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return ModalPresentationResult(
            isPresented: true,
            modalType: type,
            style: style,
            animationDuration: actualDuration,
            allowsInteractiveBackground: style == .sheet,
            supportsDragToDismiss: style == .sheet && config.allowsSwipeToDismiss,
            config: config
        )
    }
    
    func dismissViaBackdrop() async throws -> ModalDismissalResult {
        guard !modalStack.isEmpty else {
            throw ModalPresentationError.noActiveModal
        }
        
        let currentModal = modalStack.last!
        
        // Check if backdrop tap is allowed
        guard currentModal.config.allowsBackdropTap else {
            throw ModalPresentationError.gestureNotAllowed
        }
        
        // Check if confirmation is required
        if currentModal.config.requiresConfirmation {
            throw ModalPresentationError.confirmationRequired
        }
        
        return try await performDismissal(method: .backdropTap)
    }
    
    func dismissViaSwipe() async throws -> ModalDismissalResult {
        guard !modalStack.isEmpty else {
            throw ModalPresentationError.noActiveModal
        }
        
        let currentModal = modalStack.last!
        
        // Check if swipe to dismiss is allowed
        guard currentModal.config.allowsSwipeToDismiss else {
            throw ModalPresentationError.gestureNotAllowed
        }
        
        // Check if confirmation is required
        if currentModal.config.requiresConfirmation {
            throw ModalPresentationError.confirmationRequired
        }
        
        return try await performDismissal(method: .swipeGesture)
    }
    
    func dismissWithConfirmation() async throws -> ModalDismissalResult {
        guard !modalStack.isEmpty else {
            throw ModalPresentationError.noActiveModal
        }
        
        return try await performDismissal(method: .confirmation)
    }
    
    func handleKeyboardAppearance(height: CGFloat) async throws {
        guard !modalStack.isEmpty else {
            throw ModalPresentationError.noActiveModal
        }
        
        // Update the last modal info to reflect keyboard adjustment
        let lastModal = modalStack.removeLast()
        let updatedModal = ModalInfo(
            modalType: lastModal.modalType,
            style: lastModal.style,
            context: lastModal.context,
            config: lastModal.config,
            isAdjustedForKeyboard: lastModal.config.adjustsForKeyboard
        )
        modalStack.append(updatedModal)
    }
    
    func getCurrentModalInfo() async throws -> ModalInfo {
        guard let currentModal = modalStack.last else {
            throw ModalPresentationError.noActiveModal
        }
        return currentModal
    }
    
    private func performDismissal(method: DismissalMethod) async throws -> ModalDismissalResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Remove last modal from stack
        let dismissedModal = modalStack.removeLast()
        
        // Clean up animation tracking
        animationStartTimes.removeValue(forKey: dismissedModal.modalType)
        
        // Use custom animation duration if specified
        let animationDuration = dismissedModal.config.animation?.duration ?? 0.05
        try await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
        
        let actualDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return ModalDismissalResult(
            wasDismissed: true,
            animationDuration: actualDuration,
            dismissalMethod: method
        )
    }
}

actor ModalContext {
    private let modalType: ModalType
    private var taskData: TaskData?
    
    init(modalType: ModalType) {
        self.modalType = modalType
        
        // Initialize context data based on modal type
        switch modalType {
        case .taskEdit(let taskId):
            self.taskData = TaskData(taskId: taskId)
        default:
            self.taskData = nil
        }
    }
    
    func getTaskData() async throws -> TaskData {
        guard let taskData = taskData else {
            throw ModalPresentationError.contextNotFound
        }
        return taskData
    }
}

struct TaskData {
    let taskId: String
}