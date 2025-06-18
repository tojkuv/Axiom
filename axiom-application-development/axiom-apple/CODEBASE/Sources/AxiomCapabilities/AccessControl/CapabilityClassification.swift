import Foundation
import AxiomCore

// MARK: - Capability Classification Registry

/// Provides classification information for all AxiomApple Framework capabilities
public enum CapabilityClassification {
    
    // MARK: - Local Capabilities (Context Access Only)
    
    /// UI Domain - Local Rendering and Input Capabilities
    public static let uiLocalCapabilities: [String] = [
        "SwiftUIRenderingCapability",
        "UIKitRenderingCapability", 
        "MetalRenderingCapability",
        "CoreAnimationCapability",
        "TouchInputCapability",
        "KeyboardInputCapability",
        "MouseInputCapability",
        "GestureRecognitionCapability",
        "AccessibilityCapability",
        "DynamicTypeCapability",
        "HighContrastCapability",
        "ReducedMotionCapability",
        "ARRenderingCapability",
        "GameControllerCapability",
        "ApplePencilCapability",
        "3DTouchCapability"
    ]
    
    /// Intelligence Domain - Local ML and Processing Capabilities
    public static let intelligenceLocalCapabilities: [String] = [
        "CoreMLCapability",
        "CreateMLCapability", 
        "VisionCapability",
        "NaturalLanguageCapability",
        "ImageClassificationCapability",
        "ObjectDetectionCapability",
        "FaceRecognitionCapability",
        "TextRecognitionCapability",
        "SpeechRecognitionCapability",
        "TextToSpeechCapability",
        "AudioAnalysisCapability",
        "VoiceAnalysisCapability",
        "SentimentAnalysisCapability",
        "LanguageDetectionCapability"
    ]
    
    /// Data Domain - Local Storage and Processing Capabilities
    public static let dataLocalCapabilities: [String] = [
        "CoreDataCapability",
        "FileSystemCapability",
        "KeychainCapability",
        "UserDefaultsCapability",
        "DataCacheCapability",
        "ImageCacheCapability",
        "MemoryCacheCapability",
        "DiskCacheCapability",
        "DataValidationCapability",
        "DataMigrationCapability"
    ]
    
    /// System Domain - Local Device Capabilities
    public static let systemLocalCapabilities: [String] = [
        "DeviceInfoCapability",
        "BatteryCapability",
        "NotificationCapability",
        "CameraCapability",
        "PhotoLibraryCapability",
        "ContactsCapability",
        "CalendarCapability",
        "LocationCapability",
        "BiometricCapability",
        "HapticFeedbackCapability",
        "AudioPlaybackCapability",
        "AudioRecordingCapability"
    ]
    
    // MARK: - External Service Capabilities (Client Access Only)
    
    /// Network Domain - External Service Capabilities
    public static let networkExternalCapabilities: [String] = [
        "HTTPClientCapability",
        "WebSocketCapability",
        "OAuth2Capability",
        "JSONRPCCapability",
        "ProtobufCapability",
        "CertificatePinningCapability",
        "APIKeyCapability",
        "OfflineCapability",
        "RequestQueueCapability",
        "RateLimitCapability",
        "NetworkAnalyticsCapability"
    ]
    
    /// Data Domain - External Sync and Cloud Capabilities
    public static let dataExternalCapabilities: [String] = [
        "BackgroundSyncCapability",
        "ConflictResolutionCapability",
        "CloudStorageCapability",
        "DatabaseSyncCapability"
    ]
    
    /// Intelligence Domain - External AI Service Capabilities
    public static let intelligenceExternalCapabilities: [String] = [
        "TranslationCapability",
        "PredictiveAnalyticsCapability",
        "CloudMLCapability",
        "ChatbotCapability"
    ]
    
    // MARK: - Classification Helpers
    
    /// All local capabilities (accessible by Contexts)
    public static var allLocalCapabilities: [String] {
        return uiLocalCapabilities +
               intelligenceLocalCapabilities +
               dataLocalCapabilities +
               systemLocalCapabilities
    }
    
    /// All external service capabilities (accessible by Clients)
    public static var allExternalServiceCapabilities: [String] {
        return networkExternalCapabilities +
               dataExternalCapabilities +
               intelligenceExternalCapabilities
    }
    
    /// All capabilities in the framework
    public static var allCapabilities: [String] {
        return allLocalCapabilities + allExternalServiceCapabilities
    }
    
    /// Check if a capability name represents a local capability
    public static func isLocalCapability(_ capabilityName: String) -> Bool {
        return allLocalCapabilities.contains(capabilityName)
    }
    
    /// Check if a capability name represents an external service capability
    public static func isExternalServiceCapability(_ capabilityName: String) -> Bool {
        return allExternalServiceCapabilities.contains(capabilityName)
    }
    
    /// Get the category for a capability name
    public static func getCategory(for capabilityName: String) -> CapabilityCategory {
        if isLocalCapability(capabilityName) {
            return .local
        } else if isExternalServiceCapability(capabilityName) {
            return .externalService
        } else {
            return .unclassified
        }
    }
    
    /// Get the domain for a capability name
    public static func getDomain(for capabilityName: String) -> CapabilityDomain? {
        if uiLocalCapabilities.contains(capabilityName) {
            return .ui
        } else if intelligenceLocalCapabilities.contains(capabilityName) || 
                  intelligenceExternalCapabilities.contains(capabilityName) {
            return .intelligence
        } else if dataLocalCapabilities.contains(capabilityName) || 
                  dataExternalCapabilities.contains(capabilityName) {
            return .data
        } else if systemLocalCapabilities.contains(capabilityName) {
            return .system
        } else if networkExternalCapabilities.contains(capabilityName) {
            return .network
        }
        return nil
    }
    
    /// Get accessible capabilities for a component type
    public static func getAccessibleCapabilities(for componentType: ComponentType) -> [String] {
        switch componentType {
        case .context:
            return allLocalCapabilities
        case .client:
            return allExternalServiceCapabilities
        }
    }
    
    /// Validate that a capability access is allowed
    public static func validateAccess(
        capabilityName: String, 
        componentType: ComponentType
    ) throws {
        let isLocal = isLocalCapability(capabilityName)
        let isExternal = isExternalServiceCapability(capabilityName)
        
        switch componentType {
        case .context:
            if isExternal {
                throw CapabilityAccessError.unauthorizedAccess(
                    capability: capabilityName,
                    component: "Context",
                    reason: "Contexts cannot access external service capabilities"
                )
            }
            if !isLocal {
                throw CapabilityAccessError.capabilityNotClassified(capabilityName)
            }
            
        case .client:
            if isLocal {
                throw CapabilityAccessError.unauthorizedAccess(
                    capability: capabilityName,
                    component: "Client",
                    reason: "Clients cannot access local device capabilities"
                )
            }
            if !isExternal {
                throw CapabilityAccessError.capabilityNotClassified(capabilityName)
            }
        }
    }
}

// MARK: - Capability Domain

/// Domains that capabilities belong to
public enum CapabilityDomain: String, CaseIterable, Sendable {
    case ui = "UI"
    case intelligence = "Intelligence"
    case data = "Data"
    case system = "System"
    case network = "Network"
    
    /// Get human-readable description
    public var description: String {
        switch self {
        case .ui:
            return "User Interface and Input"
        case .intelligence:
            return "Machine Learning and AI"
        case .data:
            return "Data Storage and Management"
        case .system:
            return "System and Device Integration"
        case .network:
            return "Network and External Services"
        }
    }
}

// MARK: - Access Control Documentation

/// Documentation and guidance for capability access control
public enum CapabilityAccessControlDocumentation {
    
    /// Architecture principles
    public static let principles = """
    AxiomApple Framework Access Control Principles:
    
    1. **Separation of Concerns**
       - Contexts handle local device processing and state management
       - Clients handle external service communication and integration
    
    2. **Security Boundaries**
       - Local capabilities cannot access external services
       - External service capabilities cannot directly access device resources
    
    3. **Type Safety**
       - Access control is enforced at compile time through protocols
       - Runtime validation provides additional safety layer
    
    4. **Clear Responsibilities**
       - Contexts: UI rendering, ML processing, local storage, device sensors
       - Clients: API communication, authentication, data synchronization
    """
    
    /// Usage guidelines
    public static let usageGuidelines = """
    Usage Guidelines:
    
    **For Contexts:**
    - Use for local UI state management
    - Use for on-device ML processing
    - Use for local data storage and caching
    - Use for device sensor and input processing
    
    **For Clients:**
    - Use for API communication
    - Use for authentication and authorization
    - Use for background data synchronization
    - Use for external service integration
    
    **Communication Between Components:**
    - Contexts and Clients communicate through well-defined interfaces
    - Use delegation patterns or async streams for data flow
    - Avoid direct capability sharing between component types
    """
    
    /// Common patterns
    public static let commonPatterns = """
    Common Implementation Patterns:
    
    1. **Context-Client Collaboration:**
       ```swift
       // Context handles local UI
       let uiContext = MyUIContext()
       let renderCapability = try await uiContext.capability(SwiftUIRenderingCapability.self)
       
       // Client handles API communication
       let apiClient = MyAPIClient()
       let httpCapability = try await apiClient.capability(HTTPClientCapability.self)
       
       // Communicate through interfaces
       apiClient.delegate = uiContext
       ```
    
    2. **Data Flow Pattern:**
       ```swift
       // Client fetches data from API
       let data = try await apiClient.fetchData()
       
       // Context processes and displays data locally
       await uiContext.processAndDisplay(data)
       ```
    
    3. **Error Boundaries:**
       ```swift
       // Access control violations are caught at capability access
       do {
           let capability = try await context.capability(HTTPClientCapability.self)
       } catch CapabilityAccessError.unauthorizedAccess {
           // Handle access violation gracefully
       }
       ```
    """
}

// MARK: - Migration Guide

/// Guide for migrating existing code to use access control
public enum AccessControlMigrationGuide {
    
    public static let migrationSteps = """
    Migration Steps for Existing Code:
    
    1. **Identify Component Types:**
       - Determine if your component is a Context (local processing) or Client (external services)
       - Inherit from AxiomContext or AxiomClient accordingly
    
    2. **Update Capability Access:**
       - Replace direct capability instantiation with access control methods
       - Use context.capability() or client.capability() instead of direct init
    
    3. **Handle Access Violations:**
       - Add error handling for CapabilityAccessError cases
       - Restructure code to respect access boundaries
    
    4. **Update Dependencies:**
       - Ensure capability dependencies respect access control rules
       - Local capabilities cannot depend on external service capabilities
    
    5. **Test Access Control:**
       - Add tests to verify access control enforcement
       - Test both successful access and violation scenarios
    """
    
    public static let codeExamples = """
    Before (Direct Access):
    ```swift
    let capability = SwiftUIRenderingCapability()
    try await capability.activate()
    ```
    
    After (Access Controlled):
    ```swift
    class MyContext: AxiomContext {
        func setupUI() async throws {
            let capability = try await self.capability(SwiftUIRenderingCapability.self)
            // Capability is automatically activated and managed
        }
    }
    ```
    """
}