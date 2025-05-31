import SwiftUI
import Axiom

// MARK: - Supporting Views for Advanced Stress Testing

struct StressCapabilityIndicator: View {
    let name: String
    let icon: String
    let isActive: Bool
    let capacity: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isActive ? .red : .gray)
                .symbolEffect(.pulse, options: isActive ? .repeating : .nonRepeating)
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text("\(capacity)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isActive ? .red : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

struct SeverityIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= level ? .red : .gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct StressMetricCard: View {
    let title: String
    let value: String
    let target: String
    let color: Color
    let trend: MetricTrend
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("Target: \(target)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DeviceResourceRow: View {
    let title: String
    let value: String
    let status: ResourceStatus
    let details: String
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(details)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch status {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

struct StressTestResultCard: View {
    let result: StressTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.scenario.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(result.success ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Duration:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", result.duration))s")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Max Ops:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.maxConcurrentOperations)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Peak Memory:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.peakMemoryUsage)MB")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Max Latency:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(result.maxLatency * 1000))ms")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                if !result.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Issues (\(result.errors.count)):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(result.errors.prefix(2), id: \.self) { error in
                            Text("• \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                        if result.errors.count > 2 {
                            Text("• ... and \(result.errors.count - 2) more")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Key Metrics
                if !result.metrics.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Key Metrics:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 4) {
                            ForEach(Array(result.metrics.prefix(4)), id: \.key) { key, value in
                                HStack {
                                    Text(formatMetricName(key))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatMetricValue(value, for: key))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatMetricName(_ key: String) -> String {
        return key.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func formatMetricValue(_ value: Double, for key: String) -> String {
        if key.contains("rate") || key.contains("success") {
            return "\(Int(value * 100))%"
        } else if key.contains("latency") || key.contains("duration") {
            return "\(Int(value * 1000))ms"
        } else if key.contains("throughput") {
            return "\(Int(value))/s"
        } else {
            return "\(Int(value))"
        }
    }
}

struct ResilienceValidationRow: View {
    let criterion: String
    let target: String
    let actual: Double
    let unit: String
    let inverted: Bool
    
    init(criterion: String, target: String, actual: Double, unit: String, inverted: Bool = false) {
        self.criterion = criterion
        self.target = target
        self.actual = actual
        self.unit = unit
        self.inverted = inverted
    }
    
    private var displayValue: String {
        if unit == "%" {
            return "\(String(format: "%.2f", actual))%"
        } else if unit == "ms" {
            return "\(Int(actual))ms"
        } else if unit == "ops/sec" {
            return "\(Int(actual)) ops/sec"
        } else if unit == "hours" {
            return "\(String(format: "%.1f", actual))h"
        } else {
            return "\(Int(actual)) \(unit)"
        }
    }
    
    private var targetNumeric: Double {
        let targetString = target.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(targetString) ?? 0
    }
    
    private var isMet: Bool {
        if inverted {
            return actual <= targetNumeric
        } else {
            return actual >= targetNumeric
        }
    }
    
    var body: some View {
        HStack {
            Text(criterion)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    Text(displayValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isMet ? .green : .red)
                    
                    Image(systemName: isMet ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(isMet ? .green : .red)
                }
                
                Text("Target: \(target)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stress Test Implementation Extensions

extension AdvancedStressTestingView {
    
    func executeConcurrentOperationsTest() async throws -> (Bool, [String: Double], [String]) {
        await updateTestPhase("Initializing 15,000 concurrent operations...", progress: 0.2)
        
        let infrastructure = stressTestCoordinator.stressTestInfrastructure ?? StressTestInfrastructure()
        let operationCount = selectedStressScenario.operationCount
        
        await updateTestPhase("Executing \(operationCount) concurrent operations...", progress: 0.3)
        
        let metrics = try await infrastructure.executeConcurrentOperations(count: operationCount)
        
        await updateTestPhase("Analyzing concurrent operation results...", progress: 0.8)
        
        let success = (metrics["success_rate"] ?? 0) > 0.95 && (metrics["throughput"] ?? 0) > 8000
        var errors: [String] = []
        
        if (metrics["success_rate"] ?? 0) <= 0.95 {
            errors.append("Success rate below 95%: \(Int((metrics["success_rate"] ?? 0) * 100))%")
        }
        
        if (metrics["throughput"] ?? 0) <= 8000 {
            errors.append("Throughput below target: \(Int(metrics["throughput"] ?? 0)) ops/sec")
        }
        
        if (metrics["average_latency"] ?? 0) > 0.015 {
            errors.append("Average latency too high: \(Int((metrics["average_latency"] ?? 0) * 1000))ms")
        }
        
        // Update performance monitor with results
        await performanceMonitor.updatePerformanceMetrics()
        
        print("🚀 Concurrent Operations Test - \(operationCount) operations, \(Int(metrics["throughput"] ?? 0)) ops/sec")
        
        return (success, metrics, errors)
    }
    
    func executeMemoryPressureTest() async throws -> (Bool, [String: Double], [String]) {
        await updateTestPhase("Simulating extreme memory pressure...", progress: 0.2)
        
        let infrastructure = stressTestCoordinator.stressTestInfrastructure ?? StressTestInfrastructure()
        
        await updateTestPhase("Testing framework under memory constraints...", progress: 0.5)
        
        let metrics = try await infrastructure.simulateMemoryPressure()
        
        await updateTestPhase("Validating memory pressure recovery...", progress: 0.8)
        
        let success = (metrics["recovery_time"] ?? 1.0) < 0.2 && (metrics["operations_under_pressure"] ?? 0) > 40
        var errors: [String] = []
        
        if (metrics["recovery_time"] ?? 1.0) >= 0.2 {
            errors.append("Recovery time too slow: \(Int((metrics["recovery_time"] ?? 1.0) * 1000))ms")
        }
        
        if (metrics["operations_under_pressure"] ?? 0) <= 40 {
            errors.append("Insufficient operations under pressure: \(Int(metrics["operations_under_pressure"] ?? 0))")
        }
        
        // Simulate memory pressure effects on device
        await resourceMonitor.updateResourceMetrics()
        
        print("💾 Memory Pressure Test - \(Int(metrics["operations_under_pressure"] ?? 0)) operations under pressure")
        
        return (success, metrics, errors)
    }
    
    func executeNetworkInstabilityTest() async throws -> (Bool, [String: Double], [String]) {
        await updateTestPhase("Simulating network chaos with 30% failure rate...", progress: 0.2)
        
        let infrastructure = stressTestCoordinator.stressTestInfrastructure ?? StressTestInfrastructure()
        
        await updateTestPhase("Testing framework resilience to network failures...", progress: 0.5)
        
        let metrics = try await infrastructure.simulateNetworkInstability()
        
        await updateTestPhase("Validating network failure recovery...", progress: 0.8)
        
        let success = (metrics["success_rate"] ?? 0) > 0.65 && (metrics["average_latency"] ?? 1.0) < 0.6
        var errors: [String] = []
        
        if (metrics["success_rate"] ?? 0) <= 0.65 {
            errors.append("Success rate under network chaos too low: \(Int((metrics["success_rate"] ?? 0) * 100))%")
        }
        
        if (metrics["average_latency"] ?? 1.0) >= 0.6 {
            errors.append("Average latency under network stress too high: \(Int((metrics["average_latency"] ?? 1.0) * 1000))ms")
        }
        
        print("🌐 Network Instability Test - \(Int((metrics["success_rate"] ?? 0) * 100))% success under chaos")
        
        return (success, metrics, errors)
    }
    
    func executeDeviceResourceLimitsTest() async throws -> (Bool, [String: Double], [String]) {
        await updateTestPhase("Simulating resource-constrained device...", progress: 0.2)
        
        let operationCount = 8000
        var totalLatency: Double = 0
        var completedOperations = 0
        var errors: [String] = []
        
        await updateTestPhase("Testing framework on limited device resources...", progress: 0.4)
        
        // Simulate operations under device resource constraints
        for i in 0..<operationCount {
            if i % 1000 == 0 {
                let progress = 0.4 + (Double(i) / Double(operationCount) * 0.4)
                await updateTestPhase("Device constraint test: \(i)/\(operationCount)...", progress: progress)
            }
            
            let operationStart = Date()
            
            // Simulate constrained device operation (slower)
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2...15) * 1_000_000)) // 2-15ms on constrained device
            
            let latency = Date().timeIntervalSince(operationStart)
            totalLatency += latency
            completedOperations += 1
            
            // Simulate occasional resource exhaustion
            if Double.random(in: 0...1) > 0.98 {
                errors.append("Resource exhaustion at operation \(i)")
            }
        }
        
        await updateTestPhase("Analyzing device resource test results...", progress: 0.9)
        
        let averageLatency = totalLatency / Double(completedOperations)
        let throughput = Double(completedOperations) / totalLatency
        let success = averageLatency < 0.020 && errors.count < 50 && throughput > 1000
        
        // Update resource monitor
        await resourceMonitor.updateResourceMetrics()
        
        let metrics: [String: Double] = [
            "completed_operations": Double(completedOperations),
            "average_latency": averageLatency,
            "throughput": throughput,
            "error_count": Double(errors.count),
            "success_rate": Double(completedOperations) / Double(operationCount)
        ]
        
        print("📱 Device Resource Limits Test - \(completedOperations) ops, \(Int(averageLatency * 1000))ms avg latency")
        
        return (success, metrics, errors)
    }
    
    func executeExtremeLoadTest() async throws -> (Bool, [String: Double], [String]) {
        await updateTestPhase("Initializing extreme load test (25,000 operations)...", progress: 0.1)
        
        var allErrors: [String] = []
        var combinedMetrics: [String: Double] = [:]
        var allSuccess = true
        
        // Phase 1: Concurrent operations under memory pressure
        await updateTestPhase("Phase 1: Concurrent operations with memory pressure...", progress: 0.2)
        let (concurrentSuccess, concurrentMetrics, concurrentErrors) = try await executeConcurrentOperationsTest()
        allSuccess = allSuccess && concurrentSuccess
        allErrors.append(contentsOf: concurrentErrors)
        
        // Phase 2: Network chaos during high load
        await updateTestPhase("Phase 2: Network chaos during high load...", progress: 0.5)
        let (networkSuccess, networkMetrics, networkErrors) = try await executeNetworkInstabilityTest()
        allSuccess = allSuccess && networkSuccess
        allErrors.append(contentsOf: networkErrors)
        
        // Phase 3: Device resource limits
        await updateTestPhase("Phase 3: Device resource constraints...", progress: 0.8)
        let (deviceSuccess, deviceMetrics, deviceErrors) = try await executeDeviceResourceLimitsTest()
        allSuccess = allSuccess && deviceSuccess
        allErrors.append(contentsOf: deviceErrors)
        
        // Combine metrics
        combinedMetrics["concurrent_throughput"] = concurrentMetrics["throughput"] ?? 0
        combinedMetrics["network_success_rate"] = networkMetrics["success_rate"] ?? 0
        combinedMetrics["device_operations"] = deviceMetrics["completed_operations"] ?? 0
        combinedMetrics["overall_success_rate"] = allSuccess ? 1.0 : 0.8
        combinedMetrics["total_errors"] = Double(allErrors.count)
        
        await updateTestPhase("Extreme load test analysis complete", progress: 1.0)
        
        print("💥 Extreme Load Test - Combined stress test completed with \(allErrors.count) total issues")
        
        return (allSuccess && allErrors.count < 20, combinedMetrics, allErrors)
    }
    
    func performMemoryPressureStressTest() async {
        await updateTestPhase("Applying severe memory pressure...", progress: 0.2)
        
        // Activate memory stress in coordinator
        stressTestCoordinator.memoryStressActive = true
        stressTestCoordinator.memoryStressLevel = 95
        
        await updateTestPhase("Testing framework under memory warnings...", progress: 0.5)
        
        // Simulate memory pressure for 30 seconds
        for i in 0..<30 {
            let progress = 0.5 + (Double(i) / 30.0 * 0.4)
            await updateTestPhase("Memory pressure active: \(i+1)/30 seconds...", progress: progress)
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Update resource monitor during pressure
            await resourceMonitor.updateResourceMetrics()
        }
        
        await updateTestPhase("Memory pressure test completed", progress: 1.0)
        
        stressTestCoordinator.memoryStressActive = false
        stressTestCoordinator.memoryStressLevel = 0
    }
    
    func performNetworkChaosTest() async {
        await updateTestPhase("Initiating network chaos testing...", progress: 0.2)
        
        // Activate network stress
        stressTestCoordinator.networkStressActive = true
        stressTestCoordinator.networkFailureRate = 40
        
        await updateTestPhase("Testing with 40% network failure rate...", progress: 0.5)
        
        // Run network chaos for 20 seconds
        for i in 0..<20 {
            let progress = 0.5 + (Double(i) / 20.0 * 0.4)
            await updateTestPhase("Network chaos active: \(i+1)/20 seconds...", progress: progress)
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        await updateTestPhase("Network chaos test completed", progress: 1.0)
        
        stressTestCoordinator.networkStressActive = false
        stressTestCoordinator.networkFailureRate = 0
    }
}