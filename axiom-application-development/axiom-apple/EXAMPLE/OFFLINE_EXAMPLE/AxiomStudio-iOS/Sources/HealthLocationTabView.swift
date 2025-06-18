import SwiftUI
import AxiomStudio_Shared

struct HealthLocationTabView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedHealthTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedHealthTab) {
                HealthDashboardView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Health")
                    }
                    .tag(0)
                
                LocationView()
                    .tabItem {
                        Image(systemName: "location.fill")
                        Text("Location")
                    }
                    .tag(1)
                
                MovementView()
                    .tabItem {
                        Image(systemName: "figure.walk")
                        Text("Movement")
                    }
                    .tag(2)
            }
            .navigationTitle("Health & Location")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Record Health Data") {
                            // Navigate to health data recording
                        }
                        Button("Location Settings") {
                            Task {
                                try? await orchestrator.navigate(to: .locationSettings)
                            }
                        }
                        Button("Privacy Settings") {
                            // Navigate to privacy settings
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}

struct HealthDashboardView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var healthMetrics: [HealthMetric] = []
    @State private var systemHealthSummary: SystemHealthSummary?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let summary = systemHealthSummary {
                    SystemHealthCard(summary: summary)
                }
                
                HealthMetricsSection(metrics: healthMetrics)
                
                HealthInsightsSection()
                
                QuickActionsSection()
            }
            .padding()
        }
        .refreshable {
            await loadHealthData()
        }
        .onAppear {
            Task {
                await loadHealthData()
            }
        }
    }
    
    private func loadHealthData() async {
        systemHealthSummary = await orchestrator.getSystemHealthSummary()
        // Load health metrics from state
        let state = await orchestrator.applicationState
        healthMetrics = Array(state.healthLocation.healthMetrics.prefix(10))
    }
}

struct SystemHealthCard: View {
    let summary: SystemHealthSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("System Health")
                    .font(.headline)
                
                Spacer()
                
                Text(summary.overallStatus.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(summary.overallStatus.color.opacity(0.2))
                    .foregroundColor(summary.overallStatus.color)
                    .cornerRadius(8)
            }
            
            HStack(spacing: 20) {
                HealthMetricView(
                    title: "Memory",
                    value: String(format: "%.1f GB", summary.memoryUsage / 1024 / 1024 / 1024),
                    color: summary.memoryUsage > 8_000_000_000 ? .orange : .green
                )
                
                HealthMetricView(
                    title: "Battery",
                    value: String(format: "%.0f%%", summary.batteryLevel * 100),
                    color: summary.batteryLevel < 0.2 ? .red : .green
                )
                
                HealthMetricView(
                    title: "Thermal",
                    value: summary.thermalState.displayName,
                    color: summary.thermalState == .nominal ? .green : .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct HealthMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct HealthMetricsSection: View {
    let metrics: [HealthMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Metrics")
                .font(.title2)
                .fontWeight(.semibold)
            
            if metrics.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Health Data")
                        .font(.headline)
                    
                    Text("Health metrics will appear here when HealthKit is enabled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(metrics, id: \.id) { metric in
                        HealthMetricCard(metric: metric)
                    }
                }
            }
        }
    }
}

struct HealthMetricCard: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.type.iconName)
                    .foregroundColor(metric.type.color)
                
                Text(metric.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text(metric.formattedValue)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(metric.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct HealthInsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InsightCard(
                    icon: "lightbulb.fill",
                    title: "Movement Goal",
                    description: "You're 73% towards your daily step goal",
                    color: .blue
                )
                
                InsightCard(
                    icon: "moon.fill",
                    title: "Sleep Pattern",
                    description: "Your average sleep duration increased this week",
                    color: .purple
                )
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Log Data",
                    color: .green
                ) {
                    // Handle log data action
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "View Trends",
                    color: .blue
                ) {
                    // Handle view trends action
                }
                
                QuickActionButton(
                    icon: "gear.circle.fill",
                    title: "Settings",
                    color: .orange
                ) {
                    // Handle settings action
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
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
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationView: View {
    @State private var locationData: [LocationData] = []
    
    var body: some View {
        VStack {
            if locationData.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Location Services Disabled")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Enable location services to see your location history and movement patterns")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Enable Location Services") {
                        // Handle enable location services
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List(locationData, id: \.id) { location in
                    LocationRowView(location: location)
                }
            }
        }
    }
}

struct LocationRowView: View {
    let location: LocationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                
                Text("Location Update")
                    .font(.headline)
                
                Spacer()
                
                Text(location.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Lat: \(location.latitude, specifier: "%.4f"), Lng: \(location.longitude, specifier: "%.4f")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if location.horizontalAccuracy > 0 {
                Text("Accuracy: \(location.horizontalAccuracy, specifier: "%.1f")m")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MovementView: View {
    @State private var movementPatterns: [MovementPattern] = []
    
    var body: some View {
        VStack {
            if movementPatterns.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "figure.walk.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Movement Data")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Movement patterns will appear here as you use the app")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(movementPatterns, id: \.id) { pattern in
                    MovementPatternRowView(pattern: pattern)
                }
            }
        }
    }
}

struct MovementPatternRowView: View {
    let pattern: MovementPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
                
                Text("Movement Pattern")
                    .font(.headline)
                
                Spacer()
                
                Text(pattern.detectedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Distance: \(pattern.distance, specifier: "%.1f")m")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(pattern.locations.count) locations recorded")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding(.vertical, 4)
    }
}