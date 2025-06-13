import Foundation

public struct ArchitectureRules {
    public enum Layer: String, CaseIterable {
        case presentation = "Presentation"
        case domain = "Domain"
        case data = "Data"
        case core = "Core"
        
        var allowedDependencies: Set<Layer> {
            switch self {
            case .presentation:
                return [.domain, .core]
            case .domain:
                return [.core]
            case .data:
                return [.domain, .core]
            case .core:
                return []
            }
        }
    }
    
    public struct Violation {
        public let type: ViolationType
        public let sourceLocation: String
        public let message: String
    }
    
    public enum ViolationType {
        case layerViolation
        case circularDependency
        case missingProtocol
        case namingConvention
    }
    
    public static func validate(
        layer: Layer,
        dependencies: Set<String>
    ) -> [Violation] {
        var violations: [Violation] = []
        
        // Check layer dependencies
        for dependency in dependencies {
            if let depLayer = detectLayer(from: dependency),
               !layer.allowedDependencies.contains(depLayer) {
                violations.append(Violation(
                    type: .layerViolation,
                    sourceLocation: dependency,
                    message: "\(layer.rawValue) cannot depend on \(depLayer.rawValue)"
                ))
            }
        }
        
        return violations
    }
    
    private static func detectLayer(from typeName: String) -> Layer? {
        // Implementation to detect layer from type name
        if typeName.contains("View") || typeName.contains("ViewController") {
            return .presentation
        } else if typeName.contains("Service") || typeName.contains("UseCase") {
            return .domain
        } else if typeName.contains("Repository") || typeName.contains("DataSource") {
            return .data
        }
        return .core
    }
}