import Foundation
import AxiomCore

public struct BuildConfiguration: Sendable {
    public let platform: Platform
    public let buildMode: BuildMode
    public let features: FeatureFlags
    public let environment: Environment
    public let optimizations: OptimizationSettings
    
    public enum Platform: String, CaseIterable, Sendable {
        case iOS, macOS, watchOS, tvOS, visionOS
        
        var minimumVersion: String {
            switch self {
            case .iOS: return "15.0"
            case .macOS: return "12.0"
            case .watchOS: return "8.0"
            case .tvOS: return "15.0"
            case .visionOS: return "1.0"
            }
        }
    }
    
    public enum BuildMode: String, Sendable {
        case debug, release, profile, test
        
        var swiftSettings: [SwiftSetting] {
            switch self {
            case .debug:
                return [.unsafeFlags(["-Onone", "-enable-testing"])]
            case .release:
                return [.unsafeFlags(["-O", "-whole-module-optimization"])]
            case .profile:
                return [.unsafeFlags(["-O", "-enable-testing"])]
            case .test:
                return [.unsafeFlags(["-Onone", "-enable-testing", "-sanitize=thread"])]
            }
        }
    }
    
    public struct FeatureFlags: Sendable {
        public let analyticsEnabled: Bool
        public let performanceMonitoring: Bool
        public let debugLogging: Bool
        public let experimentalFeatures: Set<String>
        
        public static var `default`: FeatureFlags {
            FeatureFlags(
                analyticsEnabled: true,
                performanceMonitoring: true,
                debugLogging: false,
                experimentalFeatures: []
            )
        }
    }
    
    public enum Environment: String, CaseIterable, Sendable {
        case development, staging, production, testing
    }
    
    public struct OptimizationSettings: Sendable {
        public let level: OptimizationLevel
        public let enableWMO: Bool
        public let enableTesting: Bool
        
        public enum OptimizationLevel: Sendable {
            case none, speed, size
        }
        
        public static func standard(for mode: BuildMode) -> OptimizationSettings {
            switch mode {
            case .debug, .test:
                return OptimizationSettings(level: .none, enableWMO: false, enableTesting: true)
            case .release:
                return OptimizationSettings(level: .speed, enableWMO: true, enableTesting: false)
            case .profile:
                return OptimizationSettings(level: .speed, enableWMO: true, enableTesting: true)
            }
        }
    }
    
    public static func standard(
        for platform: Platform,
        mode: BuildMode = .debug
    ) -> BuildConfiguration {
        BuildConfiguration(
            platform: platform,
            buildMode: mode,
            features: .default,
            environment: .development,
            optimizations: .standard(for: mode)
        )
    }
}

public struct SwiftSetting: Sendable {
    public static func unsafeFlags(_ flags: [String]) -> SwiftSetting {
        SwiftSetting()
    }
}

public struct PackageSetting: Sendable {
    public static func platformSpecific(_ platform: BuildConfiguration.Platform, minimumVersion: String) -> PackageSetting {
        PackageSetting()
    }
    
    public static func define(_ name: String) -> PackageSetting {
        PackageSetting()
    }
}

// Package.swift integration
extension BuildConfiguration {
    public var packageSettings: [PackageSetting] {
        var settings: [PackageSetting] = []
        
        // Platform-specific settings
        settings.append(.platformSpecific(platform, minimumVersion: platform.minimumVersion))
        
        // Swift settings from build mode
        // settings.append(contentsOf: buildMode.swiftSettings)
        
        // Feature flags as defines
        if features.analyticsEnabled {
            settings.append(.define("ANALYTICS_ENABLED"))
        }
        
        return settings
    }
}

// Runtime configuration
extension BuildConfiguration {
    /// Shared runtime configuration instance
    public static let shared = BuildConfiguration.current()
    
    /// Current runtime configuration based on compilation flags and environment
    public static func current() -> BuildConfiguration {
        #if os(iOS)
        let platform = Platform.iOS
        #elseif os(macOS)
        let platform = Platform.macOS
        #elseif os(watchOS)
        let platform = Platform.watchOS
        #elseif os(tvOS)
        let platform = Platform.tvOS
        #elseif os(visionOS)
        let platform = Platform.visionOS
        #else
        let platform = Platform.iOS // fallback
        #endif
        
        #if DEBUG
        let mode = BuildMode.debug
        #else
        let mode = BuildMode.release
        #endif
        
        return BuildConfiguration.standard(for: platform, mode: mode)
    }
    
    // Platform support checks
    public var supportsmacOS: Bool { platform == .macOS }
    public var supportsWatchOS: Bool { platform == .watchOS }
    public var supportstvOS: Bool { platform == .tvOS }
    public var supportsiOS: Bool { platform == .iOS }
    public var supportsVisionOS: Bool { platform == .visionOS }
    
    // Build mode checks
    public var isTestBuild: Bool { buildMode == .test }
    public var isDebugBuild: Bool { buildMode == .debug }
    public var isReleaseBuild: Bool { buildMode == .release }
    public var isProfileBuild: Bool { buildMode == .profile }
    
    // Feature checks
    public var isTestingEnabled: Bool { 
        buildMode == .test || buildMode == .debug || optimizations.enableTesting
    }
    public var isLoggingEnabled: Bool { 
        features.debugLogging || buildMode == .debug
    }
    
    // CI environment detection
    public var isCIEnvironment: Bool {
        ProcessInfo.processInfo.environment["CI"] == "true" ||
        ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" ||
        ProcessInfo.processInfo.environment["BITRISE_IO"] == "true"
    }
    
    // Build metadata
    public var buildNumber: String {
        ProcessInfo.processInfo.environment["BUILD_NUMBER"] ?? "0"
    }
    
    public var gitCommitHash: String {
        ProcessInfo.processInfo.environment["GIT_COMMIT_HASH"] ?? "unknown"
    }
}

// Legacy compatibility
@MainActor
public final class LegacyBuildConfiguration: ObservableObject {
    public static let shared = LegacyBuildConfiguration()
    
    private init() {}
    
    public var isDebugBuild: Bool {
        BuildConfiguration.shared.isDebugBuild
    }
    
    public var isTestingEnabled: Bool {
        BuildConfiguration.shared.isTestingEnabled
    }
    
    public var isLoggingEnabled: Bool {
        BuildConfiguration.shared.isLoggingEnabled
    }
}