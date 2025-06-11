import Foundation

public actor BuildSystemValidator {
    public static let shared = BuildSystemValidator()
    
    private init() {}
    
    public func validateBuildConfiguration() async -> BuildValidationResult {
        var issues: [BuildIssue] = []
        var warnings: [BuildWarning] = []
        
        // Validate platform configurations
        await validatePlatformSupport(issues: &issues, warnings: &warnings)
        
        // Validate feature flag consistency
        await validateFeatureFlags(issues: &issues, warnings: &warnings)
        
        // Validate CI configuration
        await validateCIConfiguration(issues: &issues, warnings: &warnings)
        
        return BuildValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
    }
    
    private func validatePlatformSupport(
        issues: inout [BuildIssue],
        warnings: inout [BuildWarning]
    ) async {
        #if os(iOS)
        let config = await BuildConfiguration.shared
        if !config.supportsiOS {
            issues.append(.init(
                type: .platformMismatch,
                description: "Running on iOS but platform support not configured"
            ))
        }
        #elseif os(macOS)
        let config = await BuildConfiguration.shared
        if !(await config.supportsmacOS) {
            issues.append(.init(
                type: .platformMismatch,
                description: "Running on macOS but platform support not configured"
            ))
        }
        #elseif os(watchOS)
        let config = await BuildConfiguration.shared
        if !config.supportsWatchOS {
            issues.append(.init(
                type: .platformMismatch,
                description: "Running on watchOS but platform support not configured"
            ))
        }
        #elseif os(tvOS)
        let config = await BuildConfiguration.shared
        if !config.supportstvOS {
            issues.append(.init(
                type: .platformMismatch,
                description: "Running on tvOS but platform support not configured"
            ))
        }
        #endif
    }
    
    private func validateFeatureFlags(
        issues: inout [BuildIssue],
        warnings: inout [BuildWarning]
    ) async {
        let config = await BuildConfiguration.shared
        
        // Validate feature flag consistency
        let isTestBuild = await config.isTestBuild
        let isTestingEnabled = await config.isTestingEnabled
        let isReleaseBuild = await config.isReleaseBuild
        
        if isTestBuild && !isTestingEnabled {
            issues.append(.init(
                type: .featureFlagConflict,
                description: "Test build detected but testing not enabled"
            ))
        }
        
        if isReleaseBuild && isTestingEnabled {
            warnings.append(.init(
                type: .unusedFeatureFlag,
                description: "Testing enabled in release build - may impact performance"
            ))
        }
    }
    
    private func validateCIConfiguration(
        issues: inout [BuildIssue],
        warnings: inout [BuildWarning]
    ) async {
        let config = await BuildConfiguration.shared
        
        if await config.isCIEnvironment {
            if await config.buildNumber == "0" {
                warnings.append(.init(
                    type: .missingCIData,
                    description: "CI environment detected but build number not set"
                ))
            }
            
            if await config.gitCommitHash == "unknown" {
                warnings.append(.init(
                    type: .missingCIData,
                    description: "CI environment detected but git commit hash not available"
                ))
            }
        }
    }
}

public struct BuildValidationResult: Sendable {
    public let isValid: Bool
    public let issues: [BuildIssue]
    public let warnings: [BuildWarning]
    
    public init(isValid: Bool, issues: [BuildIssue], warnings: [BuildWarning]) {
        self.isValid = isValid
        self.issues = issues
        self.warnings = warnings
    }
}

public struct BuildIssue: Sendable {
    public enum IssueType: Sendable {
        case platformMismatch
        case featureFlagConflict
        case missingConfiguration
    }
    
    public let type: IssueType
    public let description: String
    
    public init(type: IssueType, description: String) {
        self.type = type
        self.description = description
    }
}

public struct BuildWarning: Sendable {
    public enum WarningType: Sendable {
        case missingCIData
        case unusedFeatureFlag
        case performanceConcern
    }
    
    public let type: WarningType
    public let description: String
    
    public init(type: WarningType, description: String) {
        self.type = type
        self.description = description
    }
}