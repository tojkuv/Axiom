import Foundation
import SwiftUI
import Charts
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Statistics Context (macOS)

/// Context for displaying comprehensive task statistics and analytics on macOS
@MainActor
public final class TaskStatisticsContext: ClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    
    // Core Statistics
    @Published public private(set) var statistics: TaskStatistics?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: String? = nil
    @Published public private(set) var lastUpdated: Date?
    
    // Time Range Selection
    @Published public var selectedTimeRange: TimeRange = .thisMonth
    @Published public var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published public var customEndDate: Date = Date()
    
    // Chart and View Configuration
    @Published public var selectedChartType: ChartType = .overview
    @Published public var showDetailedBreakdown: Bool = false
    @Published public var groupByCategory: Bool = true
    @Published public var showTrends: Bool = true
    @Published public var exportFormat: ExportFormat = .csv
    
    // Advanced Analytics
    @Published public private(set) var productivityTrends: [ProductivityDataPoint] = []
    @Published public private(set) var categoryBreakdown: [CategoryStatistic] = []
    @Published public private(set) var priorityDistribution: [PriorityStatistic] = []
    @Published public private(set) var completionTrends: [CompletionTrendPoint] = []
    @Published public private(set) var weeklyPatterns: [WeeklyPattern] = []
    @Published public private(set) var monthlyComparison: [MonthlyComparison] = []
    
    // Performance Metrics
    @Published public private(set) var averageCompletionTime: TimeInterval = 0
    @Published public private(set) var tasksCreatedThisWeek: Int = 0
    @Published public private(set) var tasksCompletedThisWeek: Int = 0
    @Published public private(set) var overdueTasksCount: Int = 0
    @Published public private(set) var productivityScore: Double = 0.0
    @Published public private(set) var streakInfo: StreakInfo?
    
    // Export and Sharing
    @Published public private(set) var isExporting: Bool = false
    @Published public private(set) var exportProgress: Double = 0.0
    @Published public private(set) var exportURL: URL?
    @Published public private(set) var exportSuccess: Bool = false
    
    // MARK: - Private Properties
    private var refreshTimer: Timer?
    private var analyticsCache: [String: Any] = [:]
    private let cacheExpiryDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public override init(client: TaskClient) {
        super.init(client: client)
        setupAutoRefresh()
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        await loadStatistics()
        await generateAnalytics()
    }
    
    public override func disappeared() async {
        await super.disappeared()
        stopAutoRefresh()
    }
    
    public override func handleStateUpdate(_ state: TaskManagerState) async {
        await MainActor.run {
            lastUpdated = Date()
        }
        
        // Debounce statistics updates to avoid excessive recalculation
        _Concurrency.Task {
            try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            await loadStatistics()
            await generateAnalytics()
        }
    }
    
    // MARK: - Statistics Loading
    
    public func loadStatistics() async {
        await setLoading(true)
        
        do {
            let stats = await client.getStatistics()
            await MainActor.run {
                statistics = stats
                lastUpdated = Date()
                error = nil
            }
        } catch {
            await setError("Failed to load statistics: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    public func refreshStatistics() async {
        await loadStatistics()
        await generateAnalytics()
    }
    
    // MARK: - Analytics Generation
    
    private func generateAnalytics() async {
        guard let stats = statistics else { return }
        
        await generateProductivityTrends()
        await generateCategoryBreakdown(from: stats)
        await generatePriorityDistribution(from: stats)
        await generateCompletionTrends()
        await generateWeeklyPatterns()
        await generateMonthlyComparison()
        await calculatePerformanceMetrics(from: stats)
        await calculateStreakInfo()
    }
    
    private func generateProductivityTrends() async {
        let state = await client.getCurrentState()
        let tasks = state.tasks
        
        let trends = await withTaskGroup(of: ProductivityDataPoint?.self) { group in
            var results: [ProductivityDataPoint] = []
            
            for dayOffset in 0..<30 {
                group.addTask {
                    guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) else { return nil as ProductivityDataPoint? }
                    
                    let dayTasks = tasks.filter { task in
                        Calendar.current.isDate(task.createdAt, inSameDayAs: date)
                    }
                    
                    let completedCount = dayTasks.filter { $0.isCompleted }.count
                    let createdCount = dayTasks.count
                    
                    return ProductivityDataPoint(
                        date: date,
                        tasksCreated: createdCount,
                        tasksCompleted: completedCount,
                        productivityScore: createdCount > 0 ? Double(completedCount) / Double(createdCount) : 0.0
                    )
                }
            }
            
            for await result in group {
                if let dataPoint = result {
                    results.append(dataPoint)
                }
            }
            
            return results.sorted { $0.date < $1.date }
        }
        
        await MainActor.run {
            productivityTrends = trends
        }
    }
    
    private func generateCategoryBreakdown(from stats: TaskStatistics) async {
        let breakdown = stats.tasksByCategory.map { categoryPair in
            CategoryStatistic(
                category: categoryPair.key,
                count: categoryPair.value,
                percentage: stats.totalTasks > 0 ? Double(categoryPair.value) / Double(stats.totalTasks) : 0.0
            )
        }.sorted { $0.count > $1.count }
        
        await MainActor.run {
            categoryBreakdown = breakdown
        }
    }
    
    private func generatePriorityDistribution(from stats: TaskStatistics) async {
        let distribution = stats.tasksByPriority.map { priorityPair in
            PriorityStatistic(
                priority: priorityPair.key,
                count: priorityPair.value,
                percentage: stats.totalTasks > 0 ? Double(priorityPair.value) / Double(stats.totalTasks) : 0.0
            )
        }.sorted { $0.priority.rawValue > $1.priority.rawValue }
        
        await MainActor.run {
            priorityDistribution = distribution
        }
    }
    
    private func generateCompletionTrends() async {
        let state = await client.getCurrentState()
        let tasks = state.tasks.filter { $0.isCompleted }
        
        let trends = await withTaskGroup(of: CompletionTrendPoint?.self) { group in
            var results: [CompletionTrendPoint] = []
            
            for weekOffset in 0..<12 {
                group.addTask {
                    guard let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()) else { return nil as CompletionTrendPoint? }
                    guard let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) else { return nil as CompletionTrendPoint? }
                    
                    let weekTasks = tasks.filter { task in
                        if let completedAt = task.completedAt {
                            return completedAt >= weekStart && completedAt <= weekEnd
                        }
                        return false
                    }
                    
                    return CompletionTrendPoint(
                        weekStart: weekStart,
                        weekEnd: weekEnd,
                        completedTasks: weekTasks.count,
                        averageCompletionTime: weekTasks.compactMap { task in
                            guard let completedAt = task.completedAt else { return nil }
                            return completedAt.timeIntervalSince(task.createdAt)
                        }.average
                    )
                }
            }
            
            for await result in group {
                if let trendPoint = result {
                    results.append(trendPoint)
                }
            }
            
            return results.sorted { $0.weekStart < $1.weekStart }
        }
        
        await MainActor.run {
            completionTrends = trends
        }
    }
    
    private func generateWeeklyPatterns() async {
        let state = await client.getCurrentState()
        let tasks = state.tasks
        
        let patterns = (1...7).map { dayOfWeek in
            let dayTasks = tasks.filter { task in
                Calendar.current.component(.weekday, from: task.createdAt) == dayOfWeek
            }
            
            let completedTasks = dayTasks.filter { $0.isCompleted }
            
            return WeeklyPattern(
                dayOfWeek: dayOfWeek,
                dayName: Calendar.current.weekdaySymbols[dayOfWeek - 1],
                tasksCreated: dayTasks.count,
                tasksCompleted: completedTasks.count,
                averageProductivity: dayTasks.count > 0 ? Double(completedTasks.count) / Double(dayTasks.count) : 0.0
            )
        }
        
        await MainActor.run {
            weeklyPatterns = patterns
        }
    }
    
    private func generateMonthlyComparison() async {
        let state = await client.getCurrentState()
        let tasks = state.tasks
        
        let comparison = await withTaskGroup(of: MonthlyComparison?.self) { group in
            var results: [MonthlyComparison] = []
            
            for monthOffset in 0..<6 {
                group.addTask {
                    guard let monthDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: Date()) else { return nil as MonthlyComparison? }
                    
                    let monthTasks = tasks.filter { task in
                        Calendar.current.isDate(task.createdAt, equalTo: monthDate, toGranularity: .month)
                    }
                    
                    let completedTasks = monthTasks.filter { $0.isCompleted }
                    
                    return MonthlyComparison(
                        month: monthDate,
                        monthName: DateFormatter.monthYear.string(from: monthDate),
                        tasksCreated: monthTasks.count,
                        tasksCompleted: completedTasks.count,
                        completionRate: monthTasks.count > 0 ? Double(completedTasks.count) / Double(monthTasks.count) : 0.0
                    )
                }
            }
            
            for await result in group {
                if let monthData = result {
                    results.append(monthData)
                }
            }
            
            return results.sorted { $0.month < $1.month }
        }
        
        await MainActor.run {
            monthlyComparison = comparison
        }
    }
    
    private func calculatePerformanceMetrics(from stats: TaskStatistics) async {
        let state = await client.getCurrentState()
        let tasks = state.tasks
        
        // Calculate average completion time
        let completedTasks = tasks.filter { $0.isCompleted && $0.completedAt != nil }
        let completionTimes = completedTasks.compactMap { task -> TimeInterval? in
            guard let completedAt = task.completedAt else { return nil }
            return completedAt.timeIntervalSince(task.createdAt)
        }
        
        // Calculate this week's metrics
        let thisWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let thisWeekTasks = tasks.filter { $0.createdAt >= thisWeekStart }
        let thisWeekCompleted = thisWeekTasks.filter { $0.isCompleted }
        
        // Calculate overdue tasks
        let now = Date()
        let overdueTasks = tasks.filter { task in
            !task.isCompleted && (task.dueDate?.compare(now) == .orderedAscending)
        }
        
        // Calculate productivity score (0-100)
        let totalScore = (stats.completedTasks > 0 && stats.totalTasks > 0) ?
            (Double(stats.completedTasks) / Double(stats.totalTasks)) * 100 : 0.0
        
        await MainActor.run {
            averageCompletionTime = completionTimes.average
            tasksCreatedThisWeek = thisWeekTasks.count
            tasksCompletedThisWeek = thisWeekCompleted.count
            overdueTasksCount = overdueTasks.count
            productivityScore = totalScore
        }
    }
    
    private func calculateStreakInfo() async {
        let state = await client.getCurrentState()
        let completedTasks = state.tasks.filter { $0.isCompleted }.sorted { 
            ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt)
        }
        
        var currentStreak = 0
        var longestStreak = 0
        var currentDate = Date()
        
        // Calculate current and longest streak
        for task in completedTasks {
            let taskDate = task.completedAt ?? task.createdAt
            
            if Calendar.current.isDate(taskDate, inSameDayAs: currentDate) ||
               Calendar.current.isDate(taskDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        let lastCompletionDate = completedTasks.first?.completedAt ?? completedTasks.first?.createdAt
        
        await MainActor.run {
            streakInfo = StreakInfo(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastCompletionDate: lastCompletionDate
            )
        }
    }
    
    // MARK: - Time Range Management
    
    public func updateTimeRange(_ range: TimeRange) async {
        await MainActor.run {
            selectedTimeRange = range
            
            switch range {
            case .thisWeek:
                customStartDate = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                customEndDate = Date()
            case .thisMonth:
                customStartDate = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
                customEndDate = Date()
            case .lastThreeMonths:
                customStartDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
                customEndDate = Date()
            case .thisYear:
                customStartDate = Calendar.current.dateInterval(of: .year, for: Date())?.start ?? Date()
                customEndDate = Date()
            case .custom:
                break // Use existing custom dates
            }
        }
        
        await generateAnalytics()
    }
    
    public func updateCustomDateRange(start: Date, end: Date) async {
        await MainActor.run {
            selectedTimeRange = .custom
            customStartDate = start
            customEndDate = end
        }
        
        await generateAnalytics()
    }
    
    // MARK: - Export Functionality
    
    public func exportStatistics() async {
        await setExporting(true)
        await MainActor.run { exportProgress = 0.0 }
        
        do {
            // Simulate export progress
            for i in 1...10 {
                await MainActor.run { exportProgress = Double(i) / 10.0 }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            
            let exportData = generateExportData()
            let documentsURL = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask).first!
            let fileName = "task_statistics_\(DateFormatter.timestamp.string(from: Date())).\(exportFormat.fileExtension)"
            let exportURL = documentsURL.appendingPathComponent(fileName)
            
            try exportData.write(to: exportURL, atomically: true, encoding: .utf8)
            
            await MainActor.run {
                self.exportURL = exportURL
                exportSuccess = true
            }
            
        } catch {
            await setError("Failed to export statistics: \(error.localizedDescription)")
        }
        
        await setExporting(false)
    }
    
    private func generateExportData() -> String {
        guard let stats = statistics else { return "" }
        
        switch exportFormat {
        case .csv:
            return generateCSVExport(stats: stats)
        case .json:
            return generateJSONExport(stats: stats)
        case .html:
            return generateHTMLExport(stats: stats)
        }
    }
    
    private func generateCSVExport(stats: TaskStatistics) -> String {
        var csv = "Metric,Value\n"
        csv += "Total Tasks,\(stats.totalTasks)\n"
        csv += "Completed Tasks,\(stats.completedTasks)\n"
        csv += "Pending Tasks,\(stats.pendingTasks)\n"
        csv += "Overdue Tasks,\(stats.overdueTasks)\n"
        csv += "Completion Rate,\(Int(stats.completionPercentage * 100))%\n"
        csv += "\nCategory,Task Count\n"
        
        for category in categoryBreakdown {
            csv += "\(category.category.displayName),\(category.count)\n"
        }
        
        csv += "\nPriority,Task Count\n"
        for priority in priorityDistribution {
            csv += "\(priority.priority.displayName),\(priority.count)\n"
        }
        
        return csv
    }
    
    private func generateJSONExport(stats: TaskStatistics) -> String {
        let exportData: [String: Any] = [
            "exportDate": DateFormatter.iso8601.string(from: Date()),
            "statistics": [
                "totalTasks": stats.totalTasks,
                "completedTasks": stats.completedTasks,
                "pendingTasks": stats.pendingTasks,
                "overdueTasks": stats.overdueTasks,
                "completionRate": stats.completionPercentage
            ],
            "categoryBreakdown": categoryBreakdown.map { [
                "category": $0.category.rawValue,
                "count": $0.count,
                "percentage": $0.percentage
            ]},
            "priorityDistribution": priorityDistribution.map { [
                "priority": $0.priority.rawValue,
                "count": $0.count,
                "percentage": $0.percentage
            ]},
            "productivityScore": productivityScore,
            "streakInfo": [
                "current": streakInfo?.currentStreak ?? 0,
                "longest": streakInfo?.longestStreak ?? 0
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func generateHTMLExport(stats: TaskStatistics) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Task Manager Statistics</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .stat { margin: 10px 0; }
                .section { margin: 20px 0; border-top: 1px solid #ccc; padding-top: 10px; }
            </style>
        </head>
        <body>
            <h1>Task Manager Statistics</h1>
            <p>Generated: \(DateFormatter.readable.string(from: Date()))</p>
            
            <div class="section">
                <h2>Overview</h2>
                <div class="stat">Total Tasks: \(stats.totalTasks)</div>
                <div class="stat">Completed Tasks: \(stats.completedTasks)</div>
                <div class="stat">Pending Tasks: \(stats.pendingTasks)</div>
                <div class="stat">Overdue Tasks: \(stats.overdueTasks)</div>
                <div class="stat">Completion Rate: \(Int(stats.completionPercentage * 100))%</div>
            </div>
            
            <div class="section">
                <h2>Productivity</h2>
                <div class="stat">Productivity Score: \(Int(productivityScore))/100</div>
                <div class="stat">Current Streak: \(streakInfo?.currentStreak ?? 0) days</div>
                <div class="stat">Longest Streak: \(streakInfo?.longestStreak ?? 0) days</div>
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                await self?.refreshStatistics()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
        }
    }
    
    private func setExporting(_ exporting: Bool) async {
        await MainActor.run {
            isExporting = exporting
            if !exporting {
                exportProgress = 0.0
            }
        }
    }
    
    private func setError(_ errorMessage: String) async {
        await MainActor.run {
            error = errorMessage
        }
    }
    
    public func clearError() async {
        await MainActor.run {
            error = nil
        }
    }
    
    public func clearExportState() async {
        await MainActor.run {
            exportSuccess = false
            exportURL = nil
        }
    }
    
    // MARK: - Computed Properties
    
    public var formattedProductivityScore: String {
        return String(format: "%.0f", productivityScore)
    }
    
    public var hasStatistics: Bool {
        statistics != nil && statistics!.totalTasks > 0
    }
    
    public var selectedTimeRangeDescription: String {
        switch selectedTimeRange {
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        case .lastThreeMonths:
            return "Last 3 Months"
        case .thisYear:
            return "This Year"
        case .custom:
            return "Custom Range"
        }
    }
}

// MARK: - Supporting Types

public enum TimeRange: String, CaseIterable {
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case lastThreeMonths = "lastThreeMonths"
    case thisYear = "thisYear"
    case custom = "custom"
}

public enum ChartType: String, CaseIterable {
    case overview = "overview"
    case categories = "categories"
    case priorities = "priorities"
    case trends = "trends"
    case productivity = "productivity"
}

public enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case json = "json"
    case html = "html"
    
    public var fileExtension: String {
        return rawValue
    }
    
    public var displayName: String {
        return rawValue.uppercased()
    }
}

public struct ProductivityDataPoint {
    public let date: Date
    public let tasksCreated: Int
    public let tasksCompleted: Int
    public let productivityScore: Double
}

public struct CategoryStatistic {
    public let category: TaskManager_Shared.Category
    public let count: Int
    public let percentage: Double
}

public struct PriorityStatistic {
    public let priority: Priority
    public let count: Int
    public let percentage: Double
}

public struct CompletionTrendPoint {
    public let weekStart: Date
    public let weekEnd: Date
    public let completedTasks: Int
    public let averageCompletionTime: TimeInterval
}

public struct WeeklyPattern {
    public let dayOfWeek: Int
    public let dayName: String
    public let tasksCreated: Int
    public let tasksCompleted: Int
    public let averageProductivity: Double
}

public struct MonthlyComparison {
    public let month: Date
    public let monthName: String
    public let tasksCreated: Int
    public let tasksCompleted: Int
    public let completionRate: Double
}

public struct StreakInfo {
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastCompletionDate: Date?
}

// MARK: - Extensions

extension Array where Element == TimeInterval {
    var average: TimeInterval {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / TimeInterval(count)
    }
}

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
    
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}