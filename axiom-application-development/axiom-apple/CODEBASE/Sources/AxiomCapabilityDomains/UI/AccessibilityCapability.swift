import Foundation
import UIKit
import Accessibility
import AxiomCore
import AxiomCapabilities

// MARK: - Accessibility Capability Configuration

/// Configuration for Accessibility capability
public struct AccessibilityCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableAccessibilitySupport: Bool
    public let enableVoiceOverSupport: Bool
    public let enableSwitchControlSupport: Bool
    public let enableAssistiveTouchSupport: Bool
    public let enableScreenReaderSupport: Bool
    public let enableMagnificationSupport: Bool
    public let enableHearingAidSupport: Bool
    public let enableClosedCaptionSupport: Bool
    public let maxConcurrentChecks: Int
    public let checkTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let complianceLevel: ComplianceLevel
    public let auditMode: AuditMode
    public let supportedGuidelines: [AccessibilityGuideline]
    public let enableAutoFixing: Bool
    public let priorityLevel: PriorityLevel
    
    public enum ComplianceLevel: String, Codable, CaseIterable {
        case basic = "basic"
        case wcag2_0_a = "wcag2_0_a"
        case wcag2_0_aa = "wcag2_0_aa"
        case wcag2_0_aaa = "wcag2_0_aaa"
        case wcag2_1_a = "wcag2_1_a"
        case wcag2_1_aa = "wcag2_1_aa"
        case wcag2_1_aaa = "wcag2_1_aaa"
        case section508 = "section508"
        case ada = "ada"
    }
    
    public enum AuditMode: String, Codable, CaseIterable {
        case automatic = "automatic"
        case manual = "manual"
        case hybrid = "hybrid"
        case continuous = "continuous"
    }
    
    public enum AccessibilityGuideline: String, Codable, CaseIterable {
        case perceivable = "perceivable"
        case operable = "operable"
        case understandable = "understandable"
        case robust = "robust"
        case colorContrast = "colorContrast"
        case textSize = "textSize"
        case focusManagement = "focusManagement"
        case keyboardNavigation = "keyboardNavigation"
        case screenReader = "screenReader"
        case voiceControl = "voiceControl"
        case reducedMotion = "reducedMotion"
        case highContrast = "highContrast"
    }
    
    public enum PriorityLevel: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        enableAccessibilitySupport: Bool = true,
        enableVoiceOverSupport: Bool = true,
        enableSwitchControlSupport: Bool = true,
        enableAssistiveTouchSupport: Bool = true,
        enableScreenReaderSupport: Bool = true,
        enableMagnificationSupport: Bool = true,
        enableHearingAidSupport: Bool = true,
        enableClosedCaptionSupport: Bool = true,
        maxConcurrentChecks: Int = 8,
        checkTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        complianceLevel: ComplianceLevel = .wcag2_1_aa,
        auditMode: AuditMode = .automatic,
        supportedGuidelines: [AccessibilityGuideline] = AccessibilityGuideline.allCases,
        enableAutoFixing: Bool = false,
        priorityLevel: PriorityLevel = .high
    ) {
        self.enableAccessibilitySupport = enableAccessibilitySupport
        self.enableVoiceOverSupport = enableVoiceOverSupport
        self.enableSwitchControlSupport = enableSwitchControlSupport
        self.enableAssistiveTouchSupport = enableAssistiveTouchSupport
        self.enableScreenReaderSupport = enableScreenReaderSupport
        self.enableMagnificationSupport = enableMagnificationSupport
        self.enableHearingAidSupport = enableHearingAidSupport
        self.enableClosedCaptionSupport = enableClosedCaptionSupport
        self.maxConcurrentChecks = maxConcurrentChecks
        self.checkTimeout = checkTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.complianceLevel = complianceLevel
        self.auditMode = auditMode
        self.supportedGuidelines = supportedGuidelines
        self.enableAutoFixing = enableAutoFixing
        self.priorityLevel = priorityLevel
    }
    
    public var isValid: Bool {
        maxConcurrentChecks > 0 &&
        checkTimeout > 0 &&
        cacheSize >= 0 &&
        !supportedGuidelines.isEmpty
    }
    
    public func merged(with other: AccessibilityCapabilityConfiguration) -> AccessibilityCapabilityConfiguration {
        AccessibilityCapabilityConfiguration(
            enableAccessibilitySupport: other.enableAccessibilitySupport,
            enableVoiceOverSupport: other.enableVoiceOverSupport,
            enableSwitchControlSupport: other.enableSwitchControlSupport,
            enableAssistiveTouchSupport: other.enableAssistiveTouchSupport,
            enableScreenReaderSupport: other.enableScreenReaderSupport,
            enableMagnificationSupport: other.enableMagnificationSupport,
            enableHearingAidSupport: other.enableHearingAidSupport,
            enableClosedCaptionSupport: other.enableClosedCaptionSupport,
            maxConcurrentChecks: other.maxConcurrentChecks,
            checkTimeout: other.checkTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            complianceLevel: other.complianceLevel,
            auditMode: other.auditMode,
            supportedGuidelines: other.supportedGuidelines,
            enableAutoFixing: other.enableAutoFixing,
            priorityLevel: other.priorityLevel
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> AccessibilityCapabilityConfiguration {
        var adjustedTimeout = checkTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentChecks = maxConcurrentChecks
        var adjustedCacheSize = cacheSize
        var adjustedAutoFixing = enableAutoFixing
        var adjustedPriorityLevel = priorityLevel
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(checkTimeout, 15.0)
            adjustedConcurrentChecks = min(maxConcurrentChecks, 3)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedAutoFixing = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedPriorityLevel = .critical
        }
        
        return AccessibilityCapabilityConfiguration(
            enableAccessibilitySupport: enableAccessibilitySupport,
            enableVoiceOverSupport: enableVoiceOverSupport,
            enableSwitchControlSupport: enableSwitchControlSupport,
            enableAssistiveTouchSupport: enableAssistiveTouchSupport,
            enableScreenReaderSupport: enableScreenReaderSupport,
            enableMagnificationSupport: enableMagnificationSupport,
            enableHearingAidSupport: enableHearingAidSupport,
            enableClosedCaptionSupport: enableClosedCaptionSupport,
            maxConcurrentChecks: adjustedConcurrentChecks,
            checkTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            complianceLevel: complianceLevel,
            auditMode: auditMode,
            supportedGuidelines: supportedGuidelines,
            enableAutoFixing: adjustedAutoFixing,
            priorityLevel: adjustedPriorityLevel
        )
    }
}

// MARK: - Accessibility Types

/// Accessibility audit request
public struct AccessibilityAuditRequest: Sendable, Identifiable {
    public let id: UUID
    public let target: AuditTarget
    public let auditType: AuditType
    public let guidelines: [AccessibilityCapabilityConfiguration.AccessibilityGuideline]
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct AuditTarget: Sendable {
        public let targetType: TargetType
        public let identifier: String
        public let viewHierarchy: ViewHierarchyDescriptor?
        public let screenDescriptor: ScreenDescriptor?
        public let applicationContext: ApplicationContext?
        
        public enum TargetType: String, Sendable, CaseIterable {
            case view = "view"
            case viewController = "viewController"
            case screen = "screen"
            case application = "application"
            case component = "component"
            case customElement = "customElement"
        }
        
        public struct ViewHierarchyDescriptor: Sendable {
            public let rootViewId: String
            public let viewTree: [ViewDescriptor]
            public let depth: Int
            public let totalViews: Int
            
            public struct ViewDescriptor: Sendable {
                public let id: String
                public let className: String
                public let accessibilityIdentifier: String?
                public let accessibilityLabel: String?
                public let accessibilityHint: String?
                public let accessibilityValue: String?
                public let accessibilityTraits: [String]
                public let frame: CGRect
                public let isAccessibilityElement: Bool
                public let isHidden: Bool
                public let alpha: CGFloat
                public let children: [ViewDescriptor]
                
                public init(id: String, className: String, accessibilityIdentifier: String?, accessibilityLabel: String?, accessibilityHint: String?, accessibilityValue: String?, accessibilityTraits: [String], frame: CGRect, isAccessibilityElement: Bool, isHidden: Bool, alpha: CGFloat, children: [ViewDescriptor]) {
                    self.id = id
                    self.className = className
                    self.accessibilityIdentifier = accessibilityIdentifier
                    self.accessibilityLabel = accessibilityLabel
                    self.accessibilityHint = accessibilityHint
                    self.accessibilityValue = accessibilityValue
                    self.accessibilityTraits = accessibilityTraits
                    self.frame = frame
                    self.isAccessibilityElement = isAccessibilityElement
                    self.isHidden = isHidden
                    self.alpha = alpha
                    self.children = children
                }
            }
            
            public init(rootViewId: String, viewTree: [ViewDescriptor], depth: Int, totalViews: Int) {
                self.rootViewId = rootViewId
                self.viewTree = viewTree
                self.depth = depth
                self.totalViews = totalViews
            }
        }
        
        public struct ScreenDescriptor: Sendable {
            public let screenId: String
            public let screenTitle: String?
            public let navigationContext: String?
            public let contentArea: CGRect
            public let safeArea: UIEdgeInsets
            public let colorScheme: String
            public let userInterfaceStyle: String
            public let preferredContentSizeCategory: String
            
            public init(screenId: String, screenTitle: String?, navigationContext: String?, contentArea: CGRect, safeArea: UIEdgeInsets, colorScheme: String, userInterfaceStyle: String, preferredContentSizeCategory: String) {
                self.screenId = screenId
                self.screenTitle = screenTitle
                self.navigationContext = navigationContext
                self.contentArea = contentArea
                self.safeArea = safeArea
                self.colorScheme = colorScheme
                self.userInterfaceStyle = userInterfaceStyle
                self.preferredContentSizeCategory = preferredContentSizeCategory
            }
        }
        
        public struct ApplicationContext: Sendable {
            public let appName: String
            public let appVersion: String
            public let supportedOrientations: [String]
            public let accessibilitySettings: AccessibilitySettings
            public let localization: LocalizationInfo
            
            public struct AccessibilitySettings: Sendable {
                public let isVoiceOverRunning: Bool
                public let isSwitchControlRunning: Bool
                public let isAssistiveTouchRunning: Bool
                public let isGuidedAccessEnabled: Bool
                public let isBoldTextEnabled: Bool
                public let isButtonShapesEnabled: Bool
                public let isReduceMotionEnabled: Bool
                public let isReduceTransparencyEnabled: Bool
                public let isInvertColorsEnabled: Bool
                public let isDarkerSystemColorsEnabled: Bool
                public let preferredContentSizeCategory: String
                
                public init(isVoiceOverRunning: Bool, isSwitchControlRunning: Bool, isAssistiveTouchRunning: Bool, isGuidedAccessEnabled: Bool, isBoldTextEnabled: Bool, isButtonShapesEnabled: Bool, isReduceMotionEnabled: Bool, isReduceTransparencyEnabled: Bool, isInvertColorsEnabled: Bool, isDarkerSystemColorsEnabled: Bool, preferredContentSizeCategory: String) {
                    self.isVoiceOverRunning = isVoiceOverRunning
                    self.isSwitchControlRunning = isSwitchControlRunning
                    self.isAssistiveTouchRunning = isAssistiveTouchRunning
                    self.isGuidedAccessEnabled = isGuidedAccessEnabled
                    self.isBoldTextEnabled = isBoldTextEnabled
                    self.isButtonShapesEnabled = isButtonShapesEnabled
                    self.isReduceMotionEnabled = isReduceMotionEnabled
                    self.isReduceTransparencyEnabled = isReduceTransparencyEnabled
                    self.isInvertColorsEnabled = isInvertColorsEnabled
                    self.isDarkerSystemColorsEnabled = isDarkerSystemColorsEnabled
                    self.preferredContentSizeCategory = preferredContentSizeCategory
                }
            }
            
            public struct LocalizationInfo: Sendable {
                public let currentLanguage: String
                public let supportedLanguages: [String]
                public let layoutDirection: String
                public let regionCode: String
                
                public init(currentLanguage: String, supportedLanguages: [String], layoutDirection: String, regionCode: String) {
                    self.currentLanguage = currentLanguage
                    self.supportedLanguages = supportedLanguages
                    self.layoutDirection = layoutDirection
                    self.regionCode = regionCode
                }
            }
            
            public init(appName: String, appVersion: String, supportedOrientations: [String], accessibilitySettings: AccessibilitySettings, localization: LocalizationInfo) {
                self.appName = appName
                self.appVersion = appVersion
                self.supportedOrientations = supportedOrientations
                self.accessibilitySettings = accessibilitySettings
                self.localization = localization
            }
        }
        
        public init(targetType: TargetType, identifier: String, viewHierarchy: ViewHierarchyDescriptor? = nil, screenDescriptor: ScreenDescriptor? = nil, applicationContext: ApplicationContext? = nil) {
            self.targetType = targetType
            self.identifier = identifier
            self.viewHierarchy = viewHierarchy
            self.screenDescriptor = screenDescriptor
            self.applicationContext = applicationContext
        }
    }
    
    public enum AuditType: String, Sendable, CaseIterable {
        case full = "full"
        case quick = "quick"
        case focused = "focused"
        case compliance = "compliance"
        case performance = "performance"
        case usability = "usability"
        case screenReader = "screenReader"
        case keyboard = "keyboard"
        case colorContrast = "colorContrast"
        case textSize = "textSize"
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(target: AuditTarget, auditType: AuditType = .full, guidelines: [AccessibilityCapabilityConfiguration.AccessibilityGuideline] = AccessibilityCapabilityConfiguration.AccessibilityGuideline.allCases, priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.target = target
        self.auditType = auditType
        self.guidelines = guidelines
        self.priority = priority
        self.metadata = metadata
    }
}

/// Accessibility audit result
public struct AccessibilityAuditResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let overallScore: Double
    public let complianceLevel: AccessibilityCapabilityConfiguration.ComplianceLevel
    public let issues: [AccessibilityIssue]
    public let recommendations: [AccessibilityRecommendation]
    public let metrics: AccessibilityMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: AccessibilityError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct AccessibilityIssue: Sendable, Identifiable {
        public let id: UUID
        public let issueType: IssueType
        public let severity: Severity
        public let guideline: AccessibilityCapabilityConfiguration.AccessibilityGuideline
        public let description: String
        public let location: IssueLocation
        public let impact: Impact
        public let suggestedFix: String?
        public let codeExample: String?
        public let wcagReference: String?
        
        public enum IssueType: String, Sendable, CaseIterable {
            case missingAccessibilityLabel = "missingAccessibilityLabel"
            case missingAccessibilityHint = "missingAccessibilityHint"
            case incorrectAccessibilityTraits = "incorrectAccessibilityTraits"
            case insufficientColorContrast = "insufficientColorContrast"
            case tooSmallTouchTarget = "tooSmallTouchTarget"
            case keyboardNavigationIssue = "keyboardNavigationIssue"
            case focusManagementIssue = "focusManagementIssue"
            case screenReaderIssue = "screenReaderIssue"
            case duplicateAccessibilityId = "duplicateAccessibilityId"
            case inaccessibleContent = "inaccessibleContent"
            case motionSensitivity = "motionSensitivity"
            case audioVideoIssue = "audioVideoIssue"
            case timingIssue = "timingIssue"
            case seizureRisk = "seizureRisk"
            case cognitiveOverload = "cognitiveOverload"
        }
        
        public enum Severity: String, Sendable, CaseIterable {
            case info = "info"
            case minor = "minor"
            case major = "major"
            case critical = "critical"
            case blocker = "blocker"
        }
        
        public struct IssueLocation: Sendable {
            public let elementId: String
            public let elementType: String
            public let className: String
            public let accessibilityIdentifier: String?
            public let frame: CGRect
            public let xpath: String?
            public let hierarchyPath: [String]
            
            public init(elementId: String, elementType: String, className: String, accessibilityIdentifier: String?, frame: CGRect, xpath: String?, hierarchyPath: [String]) {
                self.elementId = elementId
                self.elementType = elementType
                self.className = className
                self.accessibilityIdentifier = accessibilityIdentifier
                self.frame = frame
                self.xpath = xpath
                self.hierarchyPath = hierarchyPath
            }
        }
        
        public enum Impact: String, Sendable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case severe = "severe"
        }
        
        public init(issueType: IssueType, severity: Severity, guideline: AccessibilityCapabilityConfiguration.AccessibilityGuideline, description: String, location: IssueLocation, impact: Impact, suggestedFix: String? = nil, codeExample: String? = nil, wcagReference: String? = nil) {
            self.id = UUID()
            self.issueType = issueType
            self.severity = severity
            self.guideline = guideline
            self.description = description
            self.location = location
            self.impact = impact
            self.suggestedFix = suggestedFix
            self.codeExample = codeExample
            self.wcagReference = wcagReference
        }
    }
    
    public struct AccessibilityRecommendation: Sendable, Identifiable {
        public let id: UUID
        public let recommendationType: RecommendationType
        public let priority: Priority
        public let description: String
        public let implementation: String
        public let estimatedEffort: EffortLevel
        public let benefitLevel: BenefitLevel
        public let targetGuideline: AccessibilityCapabilityConfiguration.AccessibilityGuideline
        
        public enum RecommendationType: String, Sendable, CaseIterable {
            case enhancement = "enhancement"
            case optimization = "optimization"
            case bestPractice = "bestPractice"
            case compliance = "compliance"
            case usability = "usability"
            case performance = "performance"
        }
        
        public enum Priority: String, Sendable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
        }
        
        public enum EffortLevel: String, Sendable, CaseIterable {
            case minimal = "minimal"
            case low = "low"
            case medium = "medium"
            case high = "high"
            case extensive = "extensive"
        }
        
        public enum BenefitLevel: String, Sendable, CaseIterable {
            case minimal = "minimal"
            case low = "low"
            case medium = "medium"
            case high = "high"
            case transformative = "transformative"
        }
        
        public init(recommendationType: RecommendationType, priority: Priority, description: String, implementation: String, estimatedEffort: EffortLevel, benefitLevel: BenefitLevel, targetGuideline: AccessibilityCapabilityConfiguration.AccessibilityGuideline) {
            self.id = UUID()
            self.recommendationType = recommendationType
            self.priority = priority
            self.description = description
            self.implementation = implementation
            self.estimatedEffort = estimatedEffort
            self.benefitLevel = benefitLevel
            self.targetGuideline = targetGuideline
        }
    }
    
    public struct AccessibilityMetrics: Sendable {
        public let totalElements: Int
        public let accessibleElements: Int
        public let inaccessibleElements: Int
        public let elementsWithLabels: Int
        public let elementsWithHints: Int
        public let keyboardAccessibleElements: Int
        public let screenReaderAccessibleElements: Int
        public let contrastRatio: Double
        public let averageTouchTargetSize: CGSize
        public let focusableElements: Int
        public let compliancePercentage: Double
        
        public init(totalElements: Int, accessibleElements: Int, inaccessibleElements: Int, elementsWithLabels: Int, elementsWithHints: Int, keyboardAccessibleElements: Int, screenReaderAccessibleElements: Int, contrastRatio: Double, averageTouchTargetSize: CGSize, focusableElements: Int, compliancePercentage: Double) {
            self.totalElements = totalElements
            self.accessibleElements = accessibleElements
            self.inaccessibleElements = inaccessibleElements
            self.elementsWithLabels = elementsWithLabels
            self.elementsWithHints = elementsWithHints
            self.keyboardAccessibleElements = keyboardAccessibleElements
            self.screenReaderAccessibleElements = screenReaderAccessibleElements
            self.contrastRatio = contrastRatio
            self.averageTouchTargetSize = averageTouchTargetSize
            self.focusableElements = focusableElements
            self.compliancePercentage = compliancePercentage
        }
    }
    
    public init(requestId: UUID, overallScore: Double, complianceLevel: AccessibilityCapabilityConfiguration.ComplianceLevel, issues: [AccessibilityIssue], recommendations: [AccessibilityRecommendation], metrics: AccessibilityMetrics, processingTime: TimeInterval, success: Bool, error: AccessibilityError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.overallScore = overallScore
        self.complianceLevel = complianceLevel
        self.issues = issues
        self.recommendations = recommendations
        self.metrics = metrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var criticalIssueCount: Int {
        issues.filter { $0.severity == .critical || $0.severity == .blocker }.count
    }
    
    public var accessibilityCompliance: Double {
        guard metrics.totalElements > 0 else { return 0.0 }
        return Double(metrics.accessibleElements) / Double(metrics.totalElements)
    }
    
    public var improvementAreas: [AccessibilityCapabilityConfiguration.AccessibilityGuideline] {
        let issueGuidelines = issues.map { $0.guideline }
        return Array(Set(issueGuidelines))
    }
}

/// Accessibility capability metrics
public struct AccessibilityCapabilityMetrics: Sendable {
    public let totalAudits: Int
    public let successfulAudits: Int
    public let failedAudits: Int
    public let averageProcessingTime: TimeInterval
    public let auditsByType: [String: Int]
    public let issuesByCategory: [String: Int]
    public let averageComplianceScore: Double
    public let improvementTrends: [String: Double]
    public let errorsByType: [String: Int]
    public let throughputPerHour: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let fastestAudit: TimeInterval
        public let slowestAudit: TimeInterval
        public let averageIssuesPerAudit: Double
        public let averageRecommendationsPerAudit: Double
        public let complianceDistribution: [String: Int]
        public let mostCommonIssues: [String: Int]
        
        public init(fastestAudit: TimeInterval = 0, slowestAudit: TimeInterval = 0, averageIssuesPerAudit: Double = 0, averageRecommendationsPerAudit: Double = 0, complianceDistribution: [String: Int] = [:], mostCommonIssues: [String: Int] = [:]) {
            self.fastestAudit = fastestAudit
            self.slowestAudit = slowestAudit
            self.averageIssuesPerAudit = averageIssuesPerAudit
            self.averageRecommendationsPerAudit = averageRecommendationsPerAudit
            self.complianceDistribution = complianceDistribution
            self.mostCommonIssues = mostCommonIssues
        }
    }
    
    public init(totalAudits: Int = 0, successfulAudits: Int = 0, failedAudits: Int = 0, averageProcessingTime: TimeInterval = 0, auditsByType: [String: Int] = [:], issuesByCategory: [String: Int] = [:], averageComplianceScore: Double = 0, improvementTrends: [String: Double] = [:], errorsByType: [String: Int] = [:], throughputPerHour: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalAudits = totalAudits
        self.successfulAudits = successfulAudits
        self.failedAudits = failedAudits
        self.averageProcessingTime = averageProcessingTime
        self.auditsByType = auditsByType
        self.issuesByCategory = issuesByCategory
        self.averageComplianceScore = averageComplianceScore
        self.improvementTrends = improvementTrends
        self.errorsByType = errorsByType
        self.throughputPerHour = averageProcessingTime > 0 ? 3600.0 / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalAudits > 0 ? Double(successfulAudits) / Double(totalAudits) : 0
    }
}

// MARK: - Accessibility Resource

/// Accessibility resource management
@available(iOS 13.0, macOS 10.15, *)
public actor AccessibilityCapabilityResource: AxiomCapabilityResource {
    private let configuration: AccessibilityCapabilityConfiguration
    private var activeAudits: [UUID: AccessibilityAuditRequest] = [:]
    private var auditHistory: [AccessibilityAuditResult] = [:]
    private var resultCache: [String: AccessibilityAuditResult] = [:]
    private var auditEngine: AccessibilityAuditEngine = AccessibilityAuditEngine()
    private var complianceChecker: ComplianceChecker = ComplianceChecker()
    private var issueDetector: IssueDetector = IssueDetector()
    private var recommendationEngine: RecommendationEngine = RecommendationEngine()
    private var metrics: AccessibilityCapabilityMetrics = AccessibilityCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<AccessibilityAuditResult>.Continuation?
    
    // Helper classes for accessibility processing
    private class AccessibilityAuditEngine {
        func performAudit(
            _ request: AccessibilityAuditRequest,
            configuration: AccessibilityCapabilityConfiguration
        ) async -> (issues: [AccessibilityAuditResult.AccessibilityIssue], metrics: AccessibilityAuditResult.AccessibilityMetrics) {
            
            var issues: [AccessibilityAuditResult.AccessibilityIssue] = []
            
            // Simulate comprehensive accessibility audit
            if let viewHierarchy = request.target.viewHierarchy {
                issues.append(contentsOf: await auditViewHierarchy(viewHierarchy, guidelines: request.guidelines))
            }
            
            if let screenDescriptor = request.target.screenDescriptor {
                issues.append(contentsOf: await auditScreen(screenDescriptor, guidelines: request.guidelines))
            }
            
            if let appContext = request.target.applicationContext {
                issues.append(contentsOf: await auditApplication(appContext, guidelines: request.guidelines))
            }
            
            let metrics = calculateMetrics(from: request.target, issues: issues)
            
            return (issues: issues, metrics: metrics)
        }
        
        private func auditViewHierarchy(_ hierarchy: AccessibilityAuditRequest.AuditTarget.ViewHierarchyDescriptor, guidelines: [AccessibilityCapabilityConfiguration.AccessibilityGuideline]) async -> [AccessibilityAuditResult.AccessibilityIssue] {
            var issues: [AccessibilityAuditResult.AccessibilityIssue] = []
            
            for view in hierarchy.viewTree {
                issues.append(contentsOf: await auditView(view, guidelines: guidelines))
            }
            
            return issues
        }
        
        private func auditView(_ view: AccessibilityAuditRequest.AuditTarget.ViewHierarchyDescriptor.ViewDescriptor, guidelines: [AccessibilityCapabilityConfiguration.AccessibilityGuideline]) async -> [AccessibilityAuditResult.AccessibilityIssue] {
            var issues: [AccessibilityAuditResult.AccessibilityIssue] = []
            
            let location = AccessibilityAuditResult.AccessibilityIssue.IssueLocation(
                elementId: view.id,
                elementType: view.className,
                className: view.className,
                accessibilityIdentifier: view.accessibilityIdentifier,
                frame: view.frame,
                xpath: nil,
                hierarchyPath: [view.className]
            )
            
            // Check for missing accessibility labels
            if guidelines.contains(.screenReader) && view.isAccessibilityElement && (view.accessibilityLabel?.isEmpty ?? true) {
                let issue = AccessibilityAuditResult.AccessibilityIssue(
                    issueType: .missingAccessibilityLabel,
                    severity: .major,
                    guideline: .screenReader,
                    description: "Element is missing accessibility label",
                    location: location,
                    impact: .high,
                    suggestedFix: "Add descriptive accessibility label",
                    codeExample: "element.accessibilityLabel = \"Descriptive label\"",
                    wcagReference: "WCAG 2.1 - 4.1.2 Name, Role, Value"
                )
                issues.append(issue)
            }
            
            // Check touch target size
            if guidelines.contains(.operable) && view.frame.size.width < 44 || view.frame.size.height < 44 {
                let issue = AccessibilityAuditResult.AccessibilityIssue(
                    issueType: .tooSmallTouchTarget,
                    severity: .major,
                    guideline: .operable,
                    description: "Touch target is smaller than recommended 44x44 points",
                    location: location,
                    impact: .medium,
                    suggestedFix: "Increase touch target size to at least 44x44 points",
                    codeExample: "button.frame.size = CGSize(width: 44, height: 44)",
                    wcagReference: "WCAG 2.1 - 2.5.5 Target Size"
                )
                issues.append(issue)
            }
            
            // Check keyboard navigation
            if guidelines.contains(.keyboardNavigation) && view.isAccessibilityElement && view.accessibilityTraits.isEmpty {
                let issue = AccessibilityAuditResult.AccessibilityIssue(
                    issueType: .keyboardNavigationIssue,
                    severity: .minor,
                    guideline: .keyboardNavigation,
                    description: "Element lacks proper accessibility traits for keyboard navigation",
                    location: location,
                    impact: .medium,
                    suggestedFix: "Add appropriate accessibility traits",
                    codeExample: "element.accessibilityTraits = .button",
                    wcagReference: "WCAG 2.1 - 2.1.1 Keyboard"
                )
                issues.append(issue)
            }
            
            // Recursively audit children
            for child in view.children {
                issues.append(contentsOf: await auditView(child, guidelines: guidelines))
            }
            
            return issues
        }
        
        private func auditScreen(_ screen: AccessibilityAuditRequest.AuditTarget.ScreenDescriptor, guidelines: [AccessibilityCapabilityConfiguration.AccessibilityGuideline]) async -> [AccessibilityAuditResult.AccessibilityIssue] {
            var issues: [AccessibilityAuditResult.AccessibilityIssue] = []
            
            // Check if screen has title for navigation
            if guidelines.contains(.understandable) && screen.screenTitle?.isEmpty ?? true {
                let location = AccessibilityAuditResult.AccessibilityIssue.IssueLocation(
                    elementId: screen.screenId,
                    elementType: "Screen",
                    className: "UIViewController",
                    accessibilityIdentifier: screen.screenId,
                    frame: screen.contentArea,
                    xpath: nil,
                    hierarchyPath: ["Screen"]
                )
                
                let issue = AccessibilityAuditResult.AccessibilityIssue(
                    issueType: .screenReaderIssue,
                    severity: .major,
                    guideline: .understandable,
                    description: "Screen lacks a descriptive title",
                    location: location,
                    impact: .high,
                    suggestedFix: "Add a clear, descriptive title to the screen",
                    codeExample: "self.title = \"Screen Title\"",
                    wcagReference: "WCAG 2.1 - 2.4.2 Page Titled"
                )
                issues.append(issue)
            }
            
            return issues
        }
        
        private func auditApplication(_ app: AccessibilityAuditRequest.AuditTarget.ApplicationContext, guidelines: [AccessibilityCapabilityConfiguration.AccessibilityGuideline]) async -> [AccessibilityAuditResult.AccessibilityIssue] {
            var issues: [AccessibilityAuditResult.AccessibilityIssue] = []
            
            let location = AccessibilityAuditResult.AccessibilityIssue.IssueLocation(
                elementId: "app",
                elementType: "Application",
                className: "UIApplication",
                accessibilityIdentifier: app.appName,
                frame: .zero,
                xpath: nil,
                hierarchyPath: ["Application"]
            )
            
            // Check if app supports dynamic type
            if guidelines.contains(.textSize) && !app.accessibilitySettings.preferredContentSizeCategory.contains("accessibility") {
                let issue = AccessibilityAuditResult.AccessibilityIssue(
                    issueType: .inaccessibleContent,
                    severity: .minor,
                    guideline: .textSize,
                    description: "App may not fully support dynamic type scaling",
                    location: location,
                    impact: .medium,
                    suggestedFix: "Ensure all text scales with dynamic type settings",
                    codeExample: "label.adjustsFontForContentSizeCategory = true",
                    wcagReference: "WCAG 2.1 - 1.4.4 Resize text"
                )
                issues.append(issue)
            }
            
            return issues
        }
        
        private func calculateMetrics(from target: AccessibilityAuditRequest.AuditTarget, issues: [AccessibilityAuditResult.AccessibilityIssue]) -> AccessibilityAuditResult.AccessibilityMetrics {
            let totalElements = target.viewHierarchy?.totalViews ?? 10
            let inaccessibleElements = issues.count
            let accessibleElements = totalElements - inaccessibleElements
            
            return AccessibilityAuditResult.AccessibilityMetrics(
                totalElements: totalElements,
                accessibleElements: accessibleElements,
                inaccessibleElements: inaccessibleElements,
                elementsWithLabels: max(0, accessibleElements - 2),
                elementsWithHints: max(0, accessibleElements - 3),
                keyboardAccessibleElements: max(0, accessibleElements - 1),
                screenReaderAccessibleElements: accessibleElements,
                contrastRatio: 4.8, // Simulated
                averageTouchTargetSize: CGSize(width: 48, height: 48),
                focusableElements: accessibleElements,
                compliancePercentage: totalElements > 0 ? Double(accessibleElements) / Double(totalElements) * 100 : 0
            )
        }
    }
    
    private class ComplianceChecker {
        func checkCompliance(issues: [AccessibilityAuditResult.AccessibilityIssue], level: AccessibilityCapabilityConfiguration.ComplianceLevel) -> Double {
            let criticalIssues = issues.filter { $0.severity == .critical || $0.severity == .blocker }
            let majorIssues = issues.filter { $0.severity == .major }
            
            let totalScore = 100.0
            let criticalPenalty = Double(criticalIssues.count) * 15.0
            let majorPenalty = Double(majorIssues.count) * 5.0
            
            return max(0, totalScore - criticalPenalty - majorPenalty)
        }
    }
    
    private class IssueDetector {
        func prioritizeIssues(_ issues: [AccessibilityAuditResult.AccessibilityIssue]) -> [AccessibilityAuditResult.AccessibilityIssue] {
            return issues.sorted { issue1, issue2 in
                let severity1 = severityValue(issue1.severity)
                let severity2 = severityValue(issue2.severity)
                
                if severity1 != severity2 {
                    return severity1 > severity2
                }
                
                return impactValue(issue1.impact) > impactValue(issue2.impact)
            }
        }
        
        private func severityValue(_ severity: AccessibilityAuditResult.AccessibilityIssue.Severity) -> Int {
            switch severity {
            case .blocker: return 5
            case .critical: return 4
            case .major: return 3
            case .minor: return 2
            case .info: return 1
            }
        }
        
        private func impactValue(_ impact: AccessibilityAuditResult.AccessibilityIssue.Impact) -> Int {
            switch impact {
            case .severe: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }
    
    private class RecommendationEngine {
        func generateRecommendations(from issues: [AccessibilityAuditResult.AccessibilityIssue]) -> [AccessibilityAuditResult.AccessibilityRecommendation] {
            var recommendations: [AccessibilityAuditResult.AccessibilityRecommendation] = []
            
            // Group issues by type and generate recommendations
            let groupedIssues = Dictionary(grouping: issues) { $0.issueType }
            
            for (issueType, issueGroup) in groupedIssues {
                let recommendation = createRecommendation(for: issueType, issues: issueGroup)
                recommendations.append(recommendation)
            }
            
            // Add general best practice recommendations
            recommendations.append(AccessibilityAuditResult.AccessibilityRecommendation(
                recommendationType: .bestPractice,
                priority: .medium,
                description: "Implement comprehensive accessibility testing",
                implementation: "Add accessibility unit tests and UI tests to your CI/CD pipeline",
                estimatedEffort: .medium,
                benefitLevel: .high,
                targetGuideline: .robust
            ))
            
            return recommendations
        }
        
        private func createRecommendation(for issueType: AccessibilityAuditResult.AccessibilityIssue.IssueType, issues: [AccessibilityAuditResult.AccessibilityIssue]) -> AccessibilityAuditResult.AccessibilityRecommendation {
            switch issueType {
            case .missingAccessibilityLabel:
                return AccessibilityAuditResult.AccessibilityRecommendation(
                    recommendationType: .compliance,
                    priority: .high,
                    description: "Add accessibility labels to \(issues.count) elements",
                    implementation: "Review each element and add descriptive accessibility labels",
                    estimatedEffort: .medium,
                    benefitLevel: .high,
                    targetGuideline: .perceivable
                )
            case .tooSmallTouchTarget:
                return AccessibilityAuditResult.AccessibilityRecommendation(
                    recommendationType: .usability,
                    priority: .medium,
                    description: "Increase touch target sizes for \(issues.count) elements",
                    implementation: "Ensure all interactive elements are at least 44x44 points",
                    estimatedEffort: .low,
                    benefitLevel: .high,
                    targetGuideline: .operable
                )
            default:
                return AccessibilityAuditResult.AccessibilityRecommendation(
                    recommendationType: .enhancement,
                    priority: .medium,
                    description: "Address \(issueType.rawValue) issues",
                    implementation: "Review and fix identified accessibility issues",
                    estimatedEffort: .medium,
                    benefitLevel: .medium,
                    targetGuideline: .robust
                )
            }
        }
    }
    
    public init(configuration: AccessibilityCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 150_000_000, // 150MB for accessibility auditing
            cpu: 2.5, // High CPU usage for comprehensive analysis
            bandwidth: 0,
            storage: 50_000_000 // 50MB for audit results and caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let auditMemory = activeAudits.count * 20_000_000 // ~20MB per active audit
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let historyMemory = auditHistory.count * 50_000
            let analysisMemory = 30_000_000 // Analysis engine overhead
            
            return ResourceUsage(
                memory: auditMemory + cacheMemory + historyMemory + analysisMemory,
                cpu: activeAudits.isEmpty ? 0.2 : 2.0,
                bandwidth: 0,
                storage: resultCache.count * 50_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Accessibility capability is available on iOS 13+
        if #available(iOS 13.0, *) {
            return configuration.enableAccessibilitySupport
        }
        return false
    }
    
    public func release() async {
        activeAudits.removeAll()
        auditHistory.removeAll()
        resultCache.removeAll()
        
        auditEngine = AccessibilityAuditEngine()
        complianceChecker = ComplianceChecker()
        issueDetector = IssueDetector()
        recommendationEngine = RecommendationEngine()
        
        resultStreamContinuation?.finish()
        
        metrics = AccessibilityCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        auditEngine = AccessibilityAuditEngine()
        complianceChecker = ComplianceChecker()
        issueDetector = IssueDetector()
        recommendationEngine = RecommendationEngine()
        
        if configuration.enableLogging {
            print("[Accessibility] 🚀 Accessibility capability initialized")
            print("[Accessibility] 📋 Compliance level: \(configuration.complianceLevel.rawValue)")
        }
    }
    
    internal func updateConfiguration(_ configuration: AccessibilityCapabilityConfiguration) async throws {
        // Update accessibility configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<AccessibilityAuditResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Accessibility Auditing
    
    public func performAudit(_ request: AccessibilityAuditRequest) async throws -> AccessibilityAuditResult {
        guard configuration.enableAccessibilitySupport else {
            throw AccessibilityError.accessibilityDisabled
        }
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(for: request)
            if let cachedResult = resultCache[cacheKey] {
                await updateCacheHitMetrics()
                return cachedResult
            }
        }
        
        let startTime = Date()
        activeAudits[request.id] = request
        
        do {
            // Perform accessibility audit
            let (issues, auditMetrics) = await auditEngine.performAudit(request, configuration: configuration)
            
            // Check compliance
            let complianceScore = complianceChecker.checkCompliance(issues: issues, level: configuration.complianceLevel)
            
            // Prioritize issues
            let prioritizedIssues = issueDetector.prioritizeIssues(issues)
            
            // Generate recommendations
            let recommendations = recommendationEngine.generateRecommendations(from: prioritizedIssues)
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = AccessibilityAuditResult(
                requestId: request.id,
                overallScore: complianceScore,
                complianceLevel: configuration.complianceLevel,
                issues: prioritizedIssues,
                recommendations: recommendations,
                metrics: auditMetrics,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeAudits.removeValue(forKey: request.id)
            auditHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logAudit(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = AccessibilityAuditResult(
                requestId: request.id,
                overallScore: 0.0,
                complianceLevel: configuration.complianceLevel,
                issues: [],
                recommendations: [],
                metrics: AccessibilityAuditResult.AccessibilityMetrics(
                    totalElements: 0,
                    accessibleElements: 0,
                    inaccessibleElements: 0,
                    elementsWithLabels: 0,
                    elementsWithHints: 0,
                    keyboardAccessibleElements: 0,
                    screenReaderAccessibleElements: 0,
                    contrastRatio: 0,
                    averageTouchTargetSize: .zero,
                    focusableElements: 0,
                    compliancePercentage: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? AccessibilityError ?? AccessibilityError.auditFailed(error.localizedDescription)
            )
            
            activeAudits.removeValue(forKey: request.id)
            auditHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logAudit(result)
            }
            
            throw error
        }
    }
    
    public func getActiveAudits() async -> [AccessibilityAuditRequest] {
        return Array(activeAudits.values)
    }
    
    public func getAuditHistory(since: Date? = nil) async -> [AccessibilityAuditResult] {
        if let since = since {
            return auditHistory.filter { $0.timestamp >= since }
        }
        return auditHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> AccessibilityCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = AccessibilityCapabilityMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for request: AccessibilityAuditRequest) -> String {
        let targetHash = request.target.identifier.hashValue
        let typeHash = request.auditType.rawValue.hashValue
        let guidelinesHash = request.guidelines.description.hashValue
        
        return "\(targetHash)_\(typeHash)_\(guidelinesHash)"
    }
    
    private func updateCacheHitMetrics() async {
        // Update cache hit metrics
    }
    
    private func updateSuccessMetrics(_ result: AccessibilityAuditResult) async {
        let totalAudits = metrics.totalAudits + 1
        let successfulAudits = metrics.successfulAudits + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAudits)) + result.processingTime) / Double(totalAudits)
        let newAverageComplianceScore = ((metrics.averageComplianceScore * Double(metrics.successfulAudits)) + result.overallScore) / Double(successfulAudits)
        
        var auditsByType = metrics.auditsByType
        auditsByType["accessibility", default: 0] += 1
        
        var issuesByCategory = metrics.issuesByCategory
        for issue in result.issues {
            issuesByCategory[issue.issueType.rawValue, default: 0] += 1
        }
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let fastestAudit = metrics.successfulAudits == 0 ? result.processingTime : min(performanceStats.fastestAudit, result.processingTime)
        let slowestAudit = max(performanceStats.slowestAudit, result.processingTime)
        let newAverageIssuesPerAudit = ((performanceStats.averageIssuesPerAudit * Double(metrics.successfulAudits)) + Double(result.issues.count)) / Double(successfulAudits)
        let newAverageRecommendationsPerAudit = ((performanceStats.averageRecommendationsPerAudit * Double(metrics.successfulAudits)) + Double(result.recommendations.count)) / Double(successfulAudits)
        
        var complianceDistribution = performanceStats.complianceDistribution
        let complianceKey = getComplianceKey(score: result.overallScore)
        complianceDistribution[complianceKey, default: 0] += 1
        
        var mostCommonIssues = performanceStats.mostCommonIssues
        for issue in result.issues {
            mostCommonIssues[issue.issueType.rawValue, default: 0] += 1
        }
        
        performanceStats = AccessibilityCapabilityMetrics.PerformanceStats(
            fastestAudit: fastestAudit,
            slowestAudit: slowestAudit,
            averageIssuesPerAudit: newAverageIssuesPerAudit,
            averageRecommendationsPerAudit: newAverageRecommendationsPerAudit,
            complianceDistribution: complianceDistribution,
            mostCommonIssues: mostCommonIssues
        )
        
        metrics = AccessibilityCapabilityMetrics(
            totalAudits: totalAudits,
            successfulAudits: successfulAudits,
            failedAudits: metrics.failedAudits,
            averageProcessingTime: newAverageProcessingTime,
            auditsByType: auditsByType,
            issuesByCategory: issuesByCategory,
            averageComplianceScore: newAverageComplianceScore,
            improvementTrends: metrics.improvementTrends,
            errorsByType: metrics.errorsByType,
            throughputPerHour: metrics.throughputPerHour,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: AccessibilityAuditResult) async {
        let totalAudits = metrics.totalAudits + 1
        let failedAudits = metrics.failedAudits + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = AccessibilityCapabilityMetrics(
            totalAudits: totalAudits,
            successfulAudits: metrics.successfulAudits,
            failedAudits: failedAudits,
            averageProcessingTime: metrics.averageProcessingTime,
            auditsByType: metrics.auditsByType,
            issuesByCategory: metrics.issuesByCategory,
            averageComplianceScore: metrics.averageComplianceScore,
            improvementTrends: metrics.improvementTrends,
            errorsByType: errorsByType,
            throughputPerHour: metrics.throughputPerHour,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func getComplianceKey(score: Double) -> String {
        switch score {
        case 90...100: return "excellent"
        case 75...89: return "good"
        case 60...74: return "fair"
        case 40...59: return "poor"
        default: return "critical"
        }
    }
    
    private func logAudit(_ result: AccessibilityAuditResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let scoreStr = String(format: "%.1f", result.overallScore)
        let issueCount = result.issues.count
        let criticalCount = result.criticalIssueCount
        let compliance = result.complianceLevel.rawValue
        
        print("[Accessibility] \(statusIcon) Audit: \(scoreStr)/100 score, \(issueCount) issues (\(criticalCount) critical), \(compliance) compliance (\(timeStr)s)")
        
        if let error = result.error {
            print("[Accessibility] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Accessibility Capability Implementation

/// Accessibility capability providing comprehensive accessibility integration
@available(iOS 13.0, macOS 10.15, *)
public actor AccessibilityCapability: DomainCapability {
    public typealias ConfigurationType = AccessibilityCapabilityConfiguration
    public typealias ResourceType = AccessibilityCapabilityResource
    
    private var _configuration: AccessibilityCapabilityConfiguration
    private var _resources: AccessibilityCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "accessibility-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: AccessibilityCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: AccessibilityCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: AccessibilityCapabilityConfiguration = AccessibilityCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = AccessibilityCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: AccessibilityCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Accessibility configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Accessibility is supported on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Accessibility doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Accessibility Operations
    
    /// Perform accessibility audit
    public func performAudit(_ request: AccessibilityAuditRequest) async throws -> AccessibilityAuditResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        return try await _resources.performAudit(request)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<AccessibilityAuditResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active audits
    public func getActiveAudits() async throws -> [AccessibilityAuditRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        return await _resources.getActiveAudits()
    }
    
    /// Get audit history
    public func getAuditHistory(since: Date? = nil) async throws -> [AccessibilityAuditResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        return await _resources.getAuditHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> AccessibilityCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Accessibility capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create view hierarchy audit request
    public func createViewAuditRequest(viewId: String, viewTree: [AccessibilityAuditRequest.AuditTarget.ViewHierarchyDescriptor.ViewDescriptor]) -> AccessibilityAuditRequest {
        let viewHierarchy = AccessibilityAuditRequest.AuditTarget.ViewHierarchyDescriptor(
            rootViewId: viewId,
            viewTree: viewTree,
            depth: calculateDepth(viewTree),
            totalViews: countViews(viewTree)
        )
        
        let target = AccessibilityAuditRequest.AuditTarget(
            targetType: .view,
            identifier: viewId,
            viewHierarchy: viewHierarchy
        )
        
        return AccessibilityAuditRequest(target: target, auditType: .full)
    }
    
    /// Create screen audit request
    public func createScreenAuditRequest(screenId: String, title: String? = nil) -> AccessibilityAuditRequest {
        let screenDescriptor = AccessibilityAuditRequest.AuditTarget.ScreenDescriptor(
            screenId: screenId,
            screenTitle: title,
            navigationContext: nil,
            contentArea: CGRect(x: 0, y: 0, width: 375, height: 667),
            safeArea: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0),
            colorScheme: "light",
            userInterfaceStyle: "light",
            preferredContentSizeCategory: "large"
        )
        
        let target = AccessibilityAuditRequest.AuditTarget(
            targetType: .screen,
            identifier: screenId,
            screenDescriptor: screenDescriptor
        )
        
        return AccessibilityAuditRequest(target: target, auditType: .full)
    }
    
    /// Create quick accessibility check
    public func createQuickAuditRequest(elementId: String) -> AccessibilityAuditRequest {
        let target = AccessibilityAuditRequest.AuditTarget(
            targetType: .view,
            identifier: elementId
        )
        
        return AccessibilityAuditRequest(
            target: target,
            auditType: .quick,
            guidelines: [.perceivable, .operable]
        )
    }
    
    /// Check if accessibility features are enabled
    public func getAccessibilityStatus() async throws -> AccessibilityAuditRequest.AuditTarget.ApplicationContext.AccessibilitySettings {
        return AccessibilityAuditRequest.AuditTarget.ApplicationContext.AccessibilitySettings(
            isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
            isSwitchControlRunning: UIAccessibility.isSwitchControlRunning,
            isAssistiveTouchRunning: UIAccessibility.isAssistiveTouchRunning,
            isGuidedAccessEnabled: UIAccessibility.isGuidedAccessEnabled,
            isBoldTextEnabled: UIAccessibility.isBoldTextEnabled,
            isButtonShapesEnabled: UIAccessibility.isButtonShapesEnabled,
            isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            isReduceTransparencyEnabled: UIAccessibility.isReduceTransparencyEnabled,
            isInvertColorsEnabled: UIAccessibility.isInvertColorsEnabled,
            isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled,
            preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory.rawValue
        )
    }
    
    /// Get average compliance score
    public func getAverageComplianceScore() async throws -> Double {
        let metrics = try await getMetrics()
        return metrics.averageComplianceScore
    }
    
    // MARK: - Private Methods
    
    private func calculateDepth(_ views: [AccessibilityAuditRequest.AuditTarget.ViewHierarchyDescriptor.ViewDescriptor]) -> Int {
        guard !views.isEmpty else { return 0 }
        return 1 + views.map { calculateDepth($0.children) }.max()!
    }
    
    private func countViews(_ views: [AccessibilityAuditRequest.AuditTarget.ViewHierarchyDescriptor.ViewDescriptor]) -> Int {
        return views.count + views.reduce(0) { count, view in
            count + countViews(view.children)
        }
    }
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Accessibility specific errors
public enum AccessibilityError: Error, LocalizedError {
    case accessibilityDisabled
    case auditFailed(String)
    case invalidTarget
    case complianceCheckFailed
    case recommendationGenerationFailed
    case unsupportedGuideline(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .accessibilityDisabled:
            return "Accessibility support is disabled"
        case .auditFailed(let reason):
            return "Accessibility audit failed: \(reason)"
        case .invalidTarget:
            return "Invalid audit target provided"
        case .complianceCheckFailed:
            return "Compliance check failed"
        case .recommendationGenerationFailed:
            return "Recommendation generation failed"
        case .unsupportedGuideline(let guideline):
            return "Unsupported accessibility guideline: \(guideline)"
        case .configurationError(let reason):
            return "Accessibility configuration error: \(reason)"
        }
    }
}