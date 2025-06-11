import Foundation

@MainActor
public final class BuildConfiguration: ObservableObject {
    public static let shared = BuildConfiguration()
    
    private init() {}
    
    // MARK: - Build Configurations
    
    public var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    public var isReleaseBuild: Bool {
        #if RELEASE
        return true
        #else
        return false
        #endif
    }
    
    public var isTestBuild: Bool {
        #if TESTING
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Feature Flags
    
    public var isTestingEnabled: Bool {
        #if TESTING
        return true
        #elseif DEBUG
        return true
        #else
        return false
        #endif
    }
    
    public var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #elseif TESTING
        return true
        #else
        return ProcessInfo.processInfo.environment["ENABLE_LOGGING"] == "1"
        #endif
    }
    
    public var isPerformanceMonitoringEnabled: Bool {
        #if DEBUG
        return true
        #else
        return ProcessInfo.processInfo.environment["ENABLE_PERF_MONITORING"] == "1"
        #endif
    }
    
    // MARK: - Platform Configuration
    
    public var supportsiOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    public var supportsmacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    public var supportsWatchOS: Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
    }
    
    public var supportstvOS: Bool {
        #if os(tvOS)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Resource Configuration
    
    public var hasResources: Bool {
        return Bundle.main.bundleIdentifier != nil
    }
    
    public var resourceBundle: Bundle? {
        return Bundle.main
    }
    
    // MARK: - CI/CD Configuration
    
    public var isCIEnvironment: Bool {
        return ProcessInfo.processInfo.environment["CI"] == "1" ||
               ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" ||
               ProcessInfo.processInfo.environment["XCODE_CLOUD"] == "1"
    }
    
    public var buildNumber: String {
        return ProcessInfo.processInfo.environment["BUILD_NUMBER"] ?? "0"
    }
    
    public var gitCommitHash: String {
        return ProcessInfo.processInfo.environment["GIT_COMMIT"] ?? "unknown"
    }
}

// MARK: - Conditional Compilation Extensions

public extension BuildConfiguration {
    
    func executeInDebug(_ block: () -> Void) {
        #if DEBUG
        block()
        #endif
    }
    
    func executeInRelease(_ block: () -> Void) {
        #if RELEASE
        block()
        #endif
    }
    
    func executeInTesting(_ block: () -> Void) {
        #if TESTING
        block()
        #endif
    }
}