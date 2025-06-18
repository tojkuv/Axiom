import XCTest
import AxiomTesting
@testable import AxiomCore
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains UI capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class UICapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testUICapabilityDomainInitialization() async throws {
        let uiDomain = UICapabilityDomain()
        XCTAssertNotNil(uiDomain, "UICapabilityDomain should initialize correctly")
        XCTAssertEqual(uiDomain.identifier, "axiom.capability.domain.ui", "Should have correct identifier")
    }
    
    func testRenderingCapabilityRegistration() async throws {
        let uiDomain = UICapabilityDomain()
        
        let metalCapability = MetalRenderingCapability()
        let openglCapability = OpenGLRenderingCapability()
        let coreAnimationCapability = CoreAnimationCapability()
        let swiftUICapability = SwiftUIRenderingCapability()
        
        await uiDomain.registerCapability(metalCapability)
        await uiDomain.registerCapability(openglCapability)
        await uiDomain.registerCapability(coreAnimationCapability)
        await uiDomain.registerCapability(swiftUICapability)
        
        let registeredCapabilities = await uiDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 4, "Should have 4 registered rendering capabilities")
        
        let hasMetal = await uiDomain.hasCapability("axiom.ui.rendering.metal")
        XCTAssertTrue(hasMetal, "Should have Metal capability")
        
        let hasOpenGL = await uiDomain.hasCapability("axiom.ui.rendering.opengl")
        XCTAssertTrue(hasOpenGL, "Should have OpenGL capability")
        
        let hasCoreAnimation = await uiDomain.hasCapability("axiom.ui.rendering.coreanimation")
        XCTAssertTrue(hasCoreAnimation, "Should have Core Animation capability")
        
        let hasSwiftUI = await uiDomain.hasCapability("axiom.ui.rendering.swiftui")
        XCTAssertTrue(hasSwiftUI, "Should have SwiftUI capability")
    }
    
    func testInputCapabilityManagement() async throws {
        let uiDomain = UICapabilityDomain()
        
        let touchCapability = TouchInputCapability()
        let keyboardCapability = KeyboardInputCapability()
        let mouseCapability = MouseInputCapability()
        let gestureCapability = GestureRecognitionCapability()
        
        await uiDomain.registerCapability(touchCapability)
        await uiDomain.registerCapability(keyboardCapability)
        await uiDomain.registerCapability(mouseCapability)
        await uiDomain.registerCapability(gestureCapability)
        
        let inputCapabilities = await uiDomain.getCapabilitiesOfType(.input)
        XCTAssertEqual(inputCapabilities.count, 4, "Should have 4 input capabilities")
        
        let primaryInputCapability = await uiDomain.getBestCapabilityForUseCase(.primaryInput)
        XCTAssertNotNil(primaryInputCapability, "Should find best capability for primary input")
        
        let preciseInputCapability = await uiDomain.getBestCapabilityForUseCase(.preciseInput)
        XCTAssertNotNil(preciseInputCapability, "Should find best capability for precise input")
    }
    
    func testAccessibilityCapabilities() async throws {
        let uiDomain = UICapabilityDomain()
        
        let voiceOverCapability = VoiceOverCapability()
        let switchControlCapability = SwitchControlCapability()
        let magnifierCapability = MagnifierCapability()
        let dynamicTypeCapability = DynamicTypeCapability()
        
        await uiDomain.registerCapability(voiceOverCapability)
        await uiDomain.registerCapability(switchControlCapability)
        await uiDomain.registerCapability(magnifierCapability)
        await uiDomain.registerCapability(dynamicTypeCapability)
        
        let accessibilityCapabilities = await uiDomain.getCapabilitiesOfType(.accessibility)
        XCTAssertEqual(accessibilityCapabilities.count, 4, "Should have 4 accessibility capabilities")
        
        let screenReaderCapability = await uiDomain.getBestCapabilityForUseCase(.screenReader)
        XCTAssertNotNil(screenReaderCapability, "Should find best capability for screen reading")
    }
    
    func testResponsiveDesignCapability() async throws {
        let uiDomain = UICapabilityDomain()
        
        // Register various UI capabilities
        await uiDomain.registerCapability(SwiftUIRenderingCapability())
        await uiDomain.registerCapability(TouchInputCapability())
        await uiDomain.registerCapability(DynamicTypeCapability())
        
        let responsiveStrategy = await uiDomain.createResponsiveStrategy(
            for: ResponsiveRequirements(
                deviceTypes: [.phone, .tablet, .desktop],
                orientations: [.portrait, .landscape],
                accessibilityLevels: [.standard, .enhanced],
                performanceTargets: [.smooth, .efficient]
            )
        )
        
        XCTAssertNotNil(responsiveStrategy, "Should create responsive design strategy")
        XCTAssertTrue(responsiveStrategy!.adaptations.count > 0, "Strategy should include adaptations")
        
        let canAdaptToDevice = await responsiveStrategy!.canAdaptToDevice(.tablet)
        XCTAssertTrue(canAdaptToDevice, "Strategy should support tablet adaptation")
    }
    
    func testThemeSystemCapability() async throws {
        let uiDomain = UICapabilityDomain()
        
        let themeSystem = await uiDomain.getThemeSystem()
        XCTAssertNotNil(themeSystem, "Should provide theme system")
        
        // Test theme registration
        let lightTheme = TestTheme(name: "Light", mode: .light)
        let darkTheme = TestTheme(name: "Dark", mode: .dark)
        let highContrastTheme = TestTheme(name: "High Contrast", mode: .highContrast)
        
        await themeSystem!.registerTheme(lightTheme)
        await themeSystem!.registerTheme(darkTheme)
        await themeSystem!.registerTheme(highContrastTheme)
        
        let availableThemes = await themeSystem!.getAvailableThemes()
        XCTAssertEqual(availableThemes.count, 3, "Should have 3 registered themes")
        
        // Test theme switching
        await themeSystem!.applyTheme(darkTheme.name)
        let currentTheme = await themeSystem!.getCurrentTheme()
        XCTAssertEqual(currentTheme?.name, "Dark", "Should apply dark theme")
    }
    
    func testAnimationCapabilityCoordination() async throws {
        let uiDomain = UICapabilityDomain()
        
        await uiDomain.registerCapability(CoreAnimationCapability())
        await uiDomain.registerCapability(SwiftUIRenderingCapability())
        
        let animationCoordinator = await uiDomain.getAnimationCoordinator()
        XCTAssertNotNil(animationCoordinator, "Should provide animation coordinator")
        
        let animationSequence = await animationCoordinator!.createAnimationSequence([
            AnimationStep(type: .fadeIn, duration: 0.3),
            AnimationStep(type: .scale, duration: 0.2),
            AnimationStep(type: .slideIn, duration: 0.5)
        ])
        
        XCTAssertNotNil(animationSequence, "Should create animation sequence")
        XCTAssertEqual(animationSequence!.steps.count, 3, "Sequence should have 3 steps")
        
        let totalDuration = await animationSequence!.getTotalDuration()
        XCTAssertEqual(totalDuration, 1.0, "Total duration should be 1.0 second")
    }
    
    // MARK: - Performance Tests
    
    func testUICapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let uiDomain = UICapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestUICapability(index: i)
                    await uiDomain.registerCapability(capability)
                }
                
                // Test responsive strategy creation performance
                for _ in 0..<25 {
                    let requirements = ResponsiveRequirements(
                        deviceTypes: [.phone],
                        orientations: [.portrait],
                        accessibilityLevels: [.standard],
                        performanceTargets: [.smooth]
                    )
                    _ = await uiDomain.createResponsiveStrategy(for: requirements)
                }
            },
            maxDuration: .milliseconds(350),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testUICapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let uiDomain = UICapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestUICapability(index: i)
                await uiDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = ResponsiveRequirements(
                        deviceTypes: [.phone, .tablet],
                        orientations: [.portrait, .landscape],
                        accessibilityLevels: [.standard],
                        performanceTargets: [.efficient]
                    )
                    _ = await uiDomain.createResponsiveStrategy(for: requirements)
                }
                
                if i % 8 == 0 {
                    await uiDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await uiDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testUICapabilityDomainErrorHandling() async throws {
        let uiDomain = UICapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestUICapability(index: 1)
        let capability2 = TestUICapability(index: 1) // Same index = same identifier
        
        await uiDomain.registerCapability(capability1)
        
        do {
            try await uiDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test responsive strategy with unsupported device
        do {
            let unsupportedRequirements = ResponsiveRequirements(
                deviceTypes: [.unsupported],
                orientations: [.portrait],
                accessibilityLevels: [.standard],
                performanceTargets: [.smooth]
            )
            try await uiDomain.createResponsiveStrategyStrict(for: unsupportedRequirements)
            XCTFail("Should throw error for unsupported device type")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for unsupported device")
        }
        
        // Test theme system with invalid theme
        let themeSystem = await uiDomain.getThemeSystem()
        if let system = themeSystem {
            do {
                try await system.applyThemeStrict("NonExistentTheme")
                XCTFail("Should throw error for non-existent theme")
            } catch {
                XCTAssertTrue(error is AxiomError, "Should throw AxiomError for non-existent theme")
            }
        }
    }
}

// MARK: - Test Helper Classes

private struct MetalRenderingCapability: UICapability {
    let identifier = "axiom.ui.rendering.metal"
    let isAvailable = true
    let uiType: UIType = .rendering
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .modern
}

private struct OpenGLRenderingCapability: UICapability {
    let identifier = "axiom.ui.rendering.opengl"
    let isAvailable = true
    let uiType: UIType = .rendering
    let performance: UIPerformance = .medium
    let compatibility: UICompatibility = .legacy
}

private struct CoreAnimationCapability: UICapability {
    let identifier = "axiom.ui.rendering.coreanimation"
    let isAvailable = true
    let uiType: UIType = .animation
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .universal
}

private struct SwiftUIRenderingCapability: UICapability {
    let identifier = "axiom.ui.rendering.swiftui"
    let isAvailable = true
    let uiType: UIType = .rendering
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .modern
}

private struct TouchInputCapability: UICapability {
    let identifier = "axiom.ui.input.touch"
    let isAvailable = true
    let uiType: UIType = .input
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .universal
}

private struct KeyboardInputCapability: UICapability {
    let identifier = "axiom.ui.input.keyboard"
    let isAvailable = true
    let uiType: UIType = .input
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .universal
}

private struct MouseInputCapability: UICapability {
    let identifier = "axiom.ui.input.mouse"
    let isAvailable = true
    let uiType: UIType = .input
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .desktop
}

private struct GestureRecognitionCapability: UICapability {
    let identifier = "axiom.ui.input.gesture"
    let isAvailable = true
    let uiType: UIType = .input
    let performance: UIPerformance = .medium
    let compatibility: UICompatibility = .modern
}

private struct VoiceOverCapability: UICapability {
    let identifier = "axiom.ui.accessibility.voiceover"
    let isAvailable = true
    let uiType: UIType = .accessibility
    let performance: UIPerformance = .medium
    let compatibility: UICompatibility = .universal
}

private struct SwitchControlCapability: UICapability {
    let identifier = "axiom.ui.accessibility.switchcontrol"
    let isAvailable = true
    let uiType: UIType = .accessibility
    let performance: UIPerformance = .medium
    let compatibility: UICompatibility = .universal
}

private struct MagnifierCapability: UICapability {
    let identifier = "axiom.ui.accessibility.magnifier"
    let isAvailable = true
    let uiType: UIType = .accessibility
    let performance: UIPerformance = .medium
    let compatibility: UICompatibility = .universal
}

private struct DynamicTypeCapability: UICapability {
    let identifier = "axiom.ui.accessibility.dynamictype"
    let isAvailable = true
    let uiType: UIType = .accessibility
    let performance: UIPerformance = .high
    let compatibility: UICompatibility = .universal
}

private struct TestUICapability: UICapability {
    let identifier: String
    let isAvailable = true
    let uiType: UIType = .rendering
    let performance: UIPerformance = .medium
    let compatibility: UICompatibility = .universal
    
    init(index: Int) {
        self.identifier = "test.ui.capability.\(index)"
    }
}

private enum UIType {
    case rendering
    case input
    case accessibility
    case animation
    case layout
}

private enum UIPerformance {
    case low
    case medium
    case high
}

private enum UICompatibility {
    case legacy
    case modern
    case universal
    case desktop
}

private enum DeviceType {
    case phone
    case tablet
    case desktop
    case tv
    case watch
    case unsupported
}

private enum Orientation {
    case portrait
    case landscape
}

private enum AccessibilityLevel {
    case standard
    case enhanced
    case full
}

private enum PerformanceTarget {
    case smooth
    case efficient
    case balanced
}

private enum UIUseCase {
    case primaryInput
    case preciseInput
    case screenReader
    case highPerformance
}

private enum ThemeMode {
    case light
    case dark
    case highContrast
    case custom
}

private enum AnimationType {
    case fadeIn
    case fadeOut
    case scale
    case slideIn
    case slideOut
    case rotate
}

private struct ResponsiveRequirements {
    let deviceTypes: [DeviceType]
    let orientations: [Orientation]
    let accessibilityLevels: [AccessibilityLevel]
    let performanceTargets: [PerformanceTarget]
}

private struct TestTheme {
    let name: String
    let mode: ThemeMode
}

private struct AnimationStep {
    let type: AnimationType
    let duration: TimeInterval
}