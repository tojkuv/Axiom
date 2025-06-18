import Foundation
import AxiomCore

// MARK: - Comprehensive Capability Classification

/// Complete classification system for all 77 AxiomApple Framework capabilities
/// This enforces the architectural boundaries at compile-time and runtime
public enum ComprehensiveCapabilityClassification {
    
    // MARK: - Local Capabilities (Context Access Only) - 63 Total
    
    /// UI Domain Local Capabilities (16 capabilities)
    public static let uiLocalCapabilities: [String] = [
        "SwiftUIRenderingCapability",      // ✅ Already classified
        "UIKitRenderingCapability",
        "MetalRenderingCapability",
        "CoreAnimationCapability",
        "ARRenderingCapability",
        "TouchInputCapability",
        "KeyboardInputCapability", 
        "MouseInputCapability",
        "GestureRecognitionCapability",
        "GameControllerCapability",
        "ApplePencilCapability",
        "3DTouchCapability",
        "AccessibilityCapability",
        "DynamicTypeCapability",
        "HighContrastCapability",
        "ReducedMotionCapability"
    ]
    
    /// Intelligence Domain Local Capabilities (16 capabilities)
    public static let intelligenceLocalCapabilities: [String] = [
        "CoreMLCapability",                // ✅ Already classified
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
    
    /// System Domain Local Capabilities (16 capabilities)
    public static let systemLocalCapabilities: [String] = [
        "CameraCapability",
        "MicrophoneCapability",
        "LocationCapability",
        "LocationServicesCapability",
        "DeviceMotionCapability",
        "BatteryCapability",
        "ThermalCapability",
        "BiometricCapability",
        "HapticFeedbackCapability",
        "NotificationCapability",
        "ContactsCapability",
        "CalendarCapability",
        "EventKitCapability",
        "HealthKitCapability",
        "SiriIntentsCapability",
        "WidgetCapability",
        "HandoffCapability",
        "AirDropCapability",
        "BackgroundProcessingCapability"
    ]
    
    /// Storage Domain Local Capabilities (5 capabilities)
    public static let storageLocalCapabilities: [String] = [
        "CoreDataCapability",
        "FileSystemCapability", 
        "KeychainCapability",
        "SQLiteCapability",
        "UserDefaultsCapability"
    ]
    
    /// Data Domain Local Capabilities (8 capabilities)
    public static let dataLocalCapabilities: [String] = [
        "DataCacheCapability",
        "ImageCacheCapability",
        "MemoryCacheCapability",
        "DiskCacheCapability",
        "DataValidationCapability",
        "DataMigrationCapability"
    ]
    
    /// Spatial Domain Local Capabilities (1 capability)
    public static let spatialLocalCapabilities: [String] = [
        "SpatialComputingCapability"
    ]
    
    // MARK: - External Service Capabilities (Client Access Only) - 14 Total
    
    /// Network Domain External Service Capabilities (17 capabilities)
    public static let networkExternalCapabilities: [String] = [
        "HTTPClientCapability",            // ✅ Already classified
        "WebSocketCapability",
        "OAuth2Capability",                // ✅ Already classified
        "JSONRPCCapability",
        "ProtobufCapability",
        "GraphQLCapability",
        "RESTCapability",
        "JWTCapability",
        "APIKeyCapability",
        "CertificatePinningCapability",
        "OfflineCapability",
        "RequestQueueCapability",
        "RateLimitCapability",
        "NetworkAnalyticsCapability",
        "NetworkReachabilityCapability",
        "URLSessionCapability"
    ]
    
    /// Data Domain External Service Capabilities (2 capabilities)
    public static let dataExternalCapabilities: [String] = [
        "BackgroundSyncCapability",        // ✅ Already classified
        "ConflictResolutionCapability"
    ]
    
    /// Intelligence Domain External Service Capabilities (2 capabilities)
    public static let intelligenceExternalCapabilities: [String] = [
        "TranslationCapability",
        "PredictiveAnalyticsCapability"
    ]
    
    /// Cloud Domain External Service Capabilities (3 capabilities)
    public static let cloudExternalCapabilities: [String] = [
        "CloudKitCapability",
        "iCloudDocumentsCapability",
        "BackupCapability"
    ]
    
    // MARK: - Comprehensive Classification Maps
    
    /// All local capabilities (accessible by Contexts) - 64 total
    public static var allLocalCapabilities: [String] {
        return uiLocalCapabilities +
               intelligenceLocalCapabilities +
               systemLocalCapabilities +
               storageLocalCapabilities +
               dataLocalCapabilities +
               spatialLocalCapabilities
    }
    
    /// All external service capabilities (accessible by Clients) - 24 total
    public static var allExternalServiceCapabilities: [String] {
        return networkExternalCapabilities +
               dataExternalCapabilities +
               intelligenceExternalCapabilities +
               cloudExternalCapabilities
    }
    
    /// All capabilities in the framework - 88 total
    public static var allCapabilities: [String] {
        return allLocalCapabilities + allExternalServiceCapabilities
    }
    
    // MARK: - Domain Classification
    
    /// Map capability names to their domains
    public static func getDomain(for capabilityName: String) -> CapabilityDomain? {
        if uiLocalCapabilities.contains(capabilityName) {
            return .ui
        } else if intelligenceLocalCapabilities.contains(capabilityName) ||
                  intelligenceExternalCapabilities.contains(capabilityName) {
            return .intelligence
        } else if systemLocalCapabilities.contains(capabilityName) {
            return .system
        } else if storageLocalCapabilities.contains(capabilityName) {
            return .storage
        } else if dataLocalCapabilities.contains(capabilityName) ||
                  dataExternalCapabilities.contains(capabilityName) {
            return .data
        } else if networkExternalCapabilities.contains(capabilityName) {
            return .network
        } else if cloudExternalCapabilities.contains(capabilityName) {
            return .cloud
        } else if spatialLocalCapabilities.contains(capabilityName) {
            return .spatial
        }
        return nil
    }
    
    // MARK: - Access Control Validation
    
    /// Validate capability access is allowed for component type
    public static func validateAccess(
        capabilityName: String,
        componentType: ComponentType
    ) throws {
        let isLocal = allLocalCapabilities.contains(capabilityName)
        let isExternal = allExternalServiceCapabilities.contains(capabilityName)
        
        switch componentType {
        case .context:
            guard isLocal else {
                if isExternal {
                    throw CapabilityAccessError.unauthorizedAccess(
                        capability: capabilityName,
                        component: "Context",
                        reason: "Contexts can only access local device capabilities. Use a Client for external services."
                    )
                } else {
                    throw CapabilityAccessError.capabilityNotClassified(capabilityName)
                }
            }
            
        case .client:
            guard isExternal else {
                if isLocal {
                    throw CapabilityAccessError.unauthorizedAccess(
                        capability: capabilityName,
                        component: "Client", 
                        reason: "Clients can only access external service capabilities. Use a Context for local device features."
                    )
                } else {
                    throw CapabilityAccessError.capabilityNotClassified(capabilityName)
                }
            }
        }
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
    
    /// Check if a capability is properly classified
    public static func isProperlyClassified(_ capabilityName: String) -> Bool {
        return allCapabilities.contains(capabilityName)
    }
    
    /// Get capability category
    public static func getCategory(for capabilityName: String) -> CapabilityCategory {
        if allLocalCapabilities.contains(capabilityName) {
            return .local
        } else if allExternalServiceCapabilities.contains(capabilityName) {
            return .externalService
        } else {
            return .unclassified
        }
    }
    
    // MARK: - Migration Support
    
    /// Capabilities that need to be migrated from DomainCapability
    public static let capabilitiesNeedingMigration: [CapabilityMigration] = [
        // UI Domain
        CapabilityMigration("UIKitRenderingCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("MetalRenderingCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("CoreAnimationCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ARRenderingCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("TouchInputCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("KeyboardInputCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("MouseInputCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("GestureRecognitionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("GameControllerCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ApplePencilCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("3DTouchCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("AccessibilityCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("DynamicTypeCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("HighContrastCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ReducedMotionCapability", from: .domainCapability, to: .localCapability),
        
        // Intelligence Domain  
        CapabilityMigration("CreateMLCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("VisionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("NaturalLanguageCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ImageClassificationCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ObjectDetectionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("FaceRecognitionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("TextRecognitionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("SpeechRecognitionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("TextToSpeechCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("AudioAnalysisCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("VoiceAnalysisCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("SentimentAnalysisCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("LanguageDetectionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("TranslationCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("PredictiveAnalyticsCapability", from: .domainCapability, to: .externalServiceCapability),
        
        // System Domain
        CapabilityMigration("CameraCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("MicrophoneCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("LocationCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("LocationServicesCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("DeviceMotionCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("BatteryCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ThermalCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("BiometricCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("HapticFeedbackCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("NotificationCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ContactsCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("CalendarCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("EventKitCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("HealthKitCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("SiriIntentsCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("WidgetCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("HandoffCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("AirDropCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("BackgroundProcessingCapability", from: .domainCapability, to: .localCapability),
        
        // Storage Domain
        CapabilityMigration("CoreDataCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("FileSystemCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("KeychainCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("SQLiteCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("UserDefaultsCapability", from: .domainCapability, to: .localCapability),
        
        // Data Domain
        CapabilityMigration("DataCacheCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ImageCacheCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("MemoryCacheCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("DiskCacheCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("DataValidationCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("DataMigrationCapability", from: .domainCapability, to: .localCapability),
        CapabilityMigration("ConflictResolutionCapability", from: .domainCapability, to: .externalServiceCapability),
        
        // Network Domain
        CapabilityMigration("WebSocketCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("JSONRPCCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("ProtobufCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("GraphQLCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("RESTCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("JWTCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("APIKeyCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("CertificatePinningCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("OfflineCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("RequestQueueCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("RateLimitCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("NetworkAnalyticsCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("NetworkReachabilityCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("URLSessionCapability", from: .domainCapability, to: .externalServiceCapability),
        
        // Cloud Domain
        CapabilityMigration("CloudKitCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("iCloudDocumentsCapability", from: .domainCapability, to: .externalServiceCapability),
        CapabilityMigration("BackupCapability", from: .domainCapability, to: .externalServiceCapability),
        
        // Spatial Domain
        CapabilityMigration("SpatialComputingCapability", from: .domainCapability, to: .localCapability)
    ]
    
    // MARK: - Statistics
    
    public static var statistics: ClassificationStatistics {
        return ClassificationStatistics(
            totalCapabilities: allCapabilities.count,
            localCapabilities: allLocalCapabilities.count,
            externalServiceCapabilities: allExternalServiceCapabilities.count,
            capabilitiesNeedingMigration: capabilitiesNeedingMigration.count,
            domainBreakdown: [
                "UI": uiLocalCapabilities.count,
                "Intelligence": intelligenceLocalCapabilities.count + intelligenceExternalCapabilities.count,
                "System": systemLocalCapabilities.count,
                "Storage": storageLocalCapabilities.count,
                "Data": dataLocalCapabilities.count + dataExternalCapabilities.count,
                "Network": networkExternalCapabilities.count,
                "Cloud": cloudExternalCapabilities.count,
                "Spatial": spatialLocalCapabilities.count
            ]
        )
    }
}

// MARK: - Enhanced Domain Types

extension CapabilityDomain {
    case storage = "Storage"
    case cloud = "Cloud"
    case spatial = "Spatial"
    
    public var description: String {
        switch self {
        case .ui:
            return "User Interface and Input Processing"
        case .intelligence:
            return "Machine Learning and AI Processing"
        case .data:
            return "Data Management and Synchronization"
        case .system:
            return "System and Device Integration"
        case .network:
            return "Network and External Service Communication"
        case .storage:
            return "Local Data Storage and Persistence"
        case .cloud:
            return "Cloud Services and Storage"
        case .spatial:
            return "Spatial Computing and AR/VR"
        }
    }
}

// MARK: - Migration Support Types

/// Represents a capability migration from one protocol to another
public struct CapabilityMigration: Sendable {
    public let capabilityName: String
    public let fromProtocol: CapabilityProtocol
    public let toProtocol: CapabilityProtocol
    
    public init(_ capabilityName: String, from: CapabilityProtocol, to: CapabilityProtocol) {
        self.capabilityName = capabilityName
        self.fromProtocol = from
        self.toProtocol = to
    }
}

/// Protocol types for capabilities
public enum CapabilityProtocol: String, Sendable, CaseIterable {
    case domainCapability = "DomainCapability"
    case localCapability = "LocalCapability"
    case externalServiceCapability = "ExternalServiceCapability"
}

/// Statistics about capability classification
public struct ClassificationStatistics: Sendable {
    public let totalCapabilities: Int
    public let localCapabilities: Int
    public let externalServiceCapabilities: Int
    public let capabilitiesNeedingMigration: Int
    public let domainBreakdown: [String: Int]
    
    public var migrationPercentage: Double {
        guard totalCapabilities > 0 else { return 0 }
        return Double(capabilitiesNeedingMigration) / Double(totalCapabilities) * 100
    }
    
    public var localPercentage: Double {
        guard totalCapabilities > 0 else { return 0 }
        return Double(localCapabilities) / Double(totalCapabilities) * 100
    }
    
    public var externalPercentage: Double {
        guard totalCapabilities > 0 else { return 0 }
        return Double(externalServiceCapabilities) / Double(totalCapabilities) * 100
    }
}

// MARK: - Validation Utilities

/// Comprehensive validation utilities for capability classification
public enum CapabilityClassificationValidator {
    
    /// Validate that all capabilities are properly classified
    public static func validateAllCapabilities() -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check for duplicate capability names
        let allNames = ComprehensiveCapabilityClassification.allCapabilities
        let uniqueNames = Set(allNames)
        if allNames.count != uniqueNames.count {
            errors.append("Duplicate capability names detected")
        }
        
        // Check for missing migrations
        let migrationNames = Set(ComprehensiveCapabilityClassification.capabilitiesNeedingMigration.map { $0.capabilityName })
        let allClassifiedNames = Set(ComprehensiveCapabilityClassification.allCapabilities)
        
        for migration in ComprehensiveCapabilityClassification.capabilitiesNeedingMigration {
            if !allClassifiedNames.contains(migration.capabilityName) {
                warnings.append("Migration target '\(migration.capabilityName)' not found in classification")
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            totalValidated: allNames.count
        )
    }
    
    /// Validate access patterns for component types
    public static func validateAccessPatterns() -> [AccessPatternValidation] {
        var validations: [AccessPatternValidation] = []
        
        // Validate Context access patterns
        for capability in ComprehensiveCapabilityClassification.allLocalCapabilities {
            let validation = AccessPatternValidation(
                capabilityName: capability,
                componentType: .context,
                isValid: true,
                reason: "Local capability correctly accessible by Context"
            )
            validations.append(validation)
        }
        
        for capability in ComprehensiveCapabilityClassification.allExternalServiceCapabilities {
            let validation = AccessPatternValidation(
                capabilityName: capability,
                componentType: .context,
                isValid: false,
                reason: "External service capability should not be accessible by Context"
            )
            validations.append(validation)
        }
        
        // Validate Client access patterns
        for capability in ComprehensiveCapabilityClassification.allExternalServiceCapabilities {
            let validation = AccessPatternValidation(
                capabilityName: capability,
                componentType: .client,
                isValid: true,
                reason: "External service capability correctly accessible by Client"
            )
            validations.append(validation)
        }
        
        for capability in ComprehensiveCapabilityClassification.allLocalCapabilities {
            let validation = AccessPatternValidation(
                capabilityName: capability,
                componentType: .client,
                isValid: false,
                reason: "Local capability should not be accessible by Client"
            )
            validations.append(validation)
        }
        
        return validations
    }
}

/// Result of validation
public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    public let totalValidated: Int
}

/// Access pattern validation result
public struct AccessPatternValidation: Sendable {
    public let capabilityName: String
    public let componentType: ComponentType
    public let isValid: Bool
    public let reason: String
}