import Foundation

public protocol APIContract {
    /// The semantic version of this API
    static var apiVersion: String { get }
    
    /// Human-readable name for this API
    static var apiName: String { get }
    
    /// Documentation URL for this API
    static var documentationURL: URL? { get }
    
    /// Indicates if this API is stable for production use
    static var isStable: Bool { get }
    
    /// Deprecation notice if applicable
    static var deprecationNotice: String? { get }
    
    /// Required capabilities for this API
    static var requiredCapabilities: Set<String> { get }
}

public extension APIContract {
    static var documentationURL: URL? { nil }
    static var isStable: Bool { true }
    static var deprecationNotice: String? { nil }
    static var requiredCapabilities: Set<String> { [] }
}