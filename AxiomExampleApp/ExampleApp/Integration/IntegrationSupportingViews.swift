import SwiftUI
import Axiom

// MARK: - Supporting Views for Integration Demo

/// Supporting views that complement the IntegrationDemoView
/// These provide the detailed components referenced in the main integration interface

// MARK: - Overview Feature

struct OverviewFeature: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Architecture Capability

struct ArchitectureCapability: View {
    let name: String
    let description: String
    let sophistication: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(sophistication * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(sophisticationColor)
            }
            
            ProgressView(value: sophistication)
                .progressViewStyle(LinearProgressViewStyle(tint: sophisticationColor))
                .frame(height: 4)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var sophisticationColor: Color {
        switch sophistication {
        case 0.9...:
            return .green
        case 0.8..<0.9:
            return .blue
        case 0.7..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Capability Overview Item

struct CapabilityOverviewItem: View {
    let capability: Capability
    let utilization: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForCapability(capability))
                .font(.title2)
                .foregroundColor(utilizationColor)
            
            Text(capability.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            ProgressView(value: utilization)
                .progressViewStyle(LinearProgressViewStyle(tint: utilizationColor))
                .frame(height: 2)
            
            Text("\(Int(utilization * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var utilizationColor: Color {
        switch utilization {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .blue
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
    
    private func iconForCapability(_ capability: Capability) -> String {
        switch capability {
        case .userManagement:
            return "person.circle"
        case .dataManagement:
            return "cylinder"
        case .stateManagement:
            return "cpu"
        case .intelligenceQueries:
            return "brain"
        case .performanceMonitoring:
            return "speedometer"
        case .caching:
            return "memorychip"
        case .transactionManagement:
            return "creditcard"
        case .errorRecovery:
            return "shield.checkered"
        default:
            return "gear"
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Domain Status

struct DomainStatus: View {
    let isActive: Bool
    let itemCount: Int
    let lastActivity: Date
    
    var body: some View {
        HStack {
            Circle()
                .fill(isActive ? .green : .gray)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .green : .gray)
                
                Text("\(itemCount) items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Last: \(DateFormatter.localizedString(from: lastActivity, dateStyle: .none, timeStyle: .short))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Domain Feature

struct DomainFeature: View {
    let name: String
    let status: FeatureStatus
    let description: String
    
    enum FeatureStatus {
        case active
        case inactive
        case warning
        
        var color: Color {
            switch self {
            case .active: return .green
            case .inactive: return .gray
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .inactive: return "circle"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Cross Domain Event Row

struct CrossDomainEventRow: View {
    let event: CrossDomainEvent
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForEventType(event.type))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(event.sourceContext) → \(event.targetContext)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DateFormatter.localizedString(from: event.timestamp, dateStyle: .none, timeStyle: .short))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    private func iconForEventType(_ type: CrossDomainEventType) -> String {
        switch type {
        case .scenarioStarted, .scenarioCompleted:
            return "play.circle"
        case .scenarioFailed:
            return "xmark.circle"
        case .dataUserSync:
            return "arrow.2.squarepath"
        case .intelligenceAnalysis:
            return "brain"
        case .transactionCoordination:
            return "creditcard"
        case .performanceOptimization:
            return "speedometer"
        case .intelligenceCoordination:
            return "gearshape.2"
        case .stateSync:
            return "arrow.clockwise"
        case .errorRecovery:
            return "shield.checkered"
        }
    }
}

// MARK: - Orchestration Scenario Row

struct OrchestrationScenarioRow: View {
    let scenario: OrchestrationScenario
    let isExecuting: Bool
    let hasResult: Bool
    let onExecute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(scenario.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isExecuting {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button(hasResult ? "Re-run" : "Execute") {
                        onExecute()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            HStack(spacing: 12) {
                ComplexityBadge(complexity: scenario.complexity)
                
                Text("\(scenario.estimatedDuration)s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(scenario.domains.count) domains")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if hasResult {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Complexity Badge

struct ComplexityBadge: View {
    let complexity: ScenarioComplexity
    
    var body: some View {
        Text(complexity.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(complexityColor)
            .cornerRadius(4)
    }
    
    private var complexityColor: Color {
        switch complexity {
        case .basic:
            return .green
        case .intermediate:
            return .blue
        case .advanced:
            return .orange
        case .expert:
            return .red
        }
    }
}

// MARK: - Scenario Result Row

struct ScenarioResultRow: View {
    let result: ScenarioResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.scenarioId.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(String(format: "%.2fs", result.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !result.insights.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(result.insights.prefix(2), id: \.self) { insight in
                        Text("• \(insight)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Coordinated Insight Row

struct CoordinatedInsightRow: View {
    let insight: CoordinatedInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForInsightType(insight.type))
                    .foregroundColor(.purple)
                
                Text(nameForInsightType(insight.type))
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
            
            Text(insight.recommendation)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Text("Impact: \(insight.estimatedImpact)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func iconForInsightType(_ type: CoordinatedInsightType) -> String {
        switch type {
        case .profileOptimization:
            return "person.crop.circle.badge.plus"
        case .performanceImprovement:
            return "speedometer"
        case .dataQualityEnhancement:
            return "checkmark.seal"
        case .securityRecommendation:
            return "shield.checkered"
        case .architecturalOptimization:
            return "building.2"
        case .userExperienceImprovement:
            return "star"
        }
    }
    
    private func nameForInsightType(_ type: CoordinatedInsightType) -> String {
        switch type {
        case .profileOptimization:
            return "Profile Optimization"
        case .performanceImprovement:
            return "Performance Improvement"
        case .dataQualityEnhancement:
            return "Data Quality Enhancement"
        case .securityRecommendation:
            return "Security Recommendation"
        case .architecturalOptimization:
            return "Architectural Optimization"
        case .userExperienceImprovement:
            return "UX Improvement"
        }
    }
}

// MARK: - Additional Supporting Views

struct CapabilityUtilizationRow: View {
    let capability: Capability
    let utilization: Double
    
    var body: some View {
        HStack {
            Text(capability.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            ProgressView(value: utilization)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 80)
            
            Text("\(Int(utilization * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct CapabilityValidationStatus: View {
    let title: String
    let status: ValidationStatus
    let count: Int
    
    enum ValidationStatus {
        case validated
        case pending
        case failed
        
        var color: Color {
            switch self {
            case .validated: return .green
            case .pending: return .orange
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .validated: return "checkmark.shield.fill"
            case .pending: return "clock.shield"
            case .failed: return "xmark.shield.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct AdvancedFeature: View {
    let name: String
    let description: String
    let enabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(enabled ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct IntelligenceSystemStatus: View {
    let coordinationActive: Bool
    let queriesExecuted: Int
    let averageConfidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(coordinationActive ? .green : .orange)
                    .frame(width: 8, height: 8)
                
                Text(coordinationActive ? "Coordination Active" : "Standby")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack {
                Text("Queries Executed:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(queriesExecuted)")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Avg Confidence:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(averageConfidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
    }
}

struct IntelligenceQueryButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IntelligenceFeatureItem: View {
    let feature: IntelligenceFeature
    let enabled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: enabled ? "brain.head.profile" : "brain")
                .font(.title3)
                .foregroundColor(enabled ? .purple : .gray)
            
            Text(feature.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Circle()
                .fill(enabled ? .purple : .gray)
                .frame(width: 6, height: 6)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .opacity(enabled ? 1.0 : 0.5)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct EfficiencyMetric: View {
    let title: String
    let description: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}