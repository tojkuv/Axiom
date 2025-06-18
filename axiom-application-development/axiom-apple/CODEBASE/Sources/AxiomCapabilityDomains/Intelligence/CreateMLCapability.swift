import Foundation
import CreateML
import CoreML
import AxiomCore
import AxiomCapabilities

// MARK: - Create ML Capability Configuration

/// Configuration for Create ML capability
public struct CreateMLCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableCreateML: Bool
    public let enableOnDeviceTraining: Bool
    public let enableModelExport: Bool
    public let enableProgressTracking: Bool
    public let maxTrainingDuration: TimeInterval
    public let maxDatasetSize: Int64
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableModelValidation: Bool
    public let enableAutomaticFeatureEngineering: Bool
    public let supportedTaskTypes: Set<String>
    public let trainingCacheSize: Int
    
    public init(
        enableCreateML: Bool = true,
        enableOnDeviceTraining: Bool = true,
        enableModelExport: Bool = true,
        enableProgressTracking: Bool = true,
        maxTrainingDuration: TimeInterval = 3600.0, // 1 hour
        maxDatasetSize: Int64 = 500_000_000, // 500MB
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableModelValidation: Bool = true,
        enableAutomaticFeatureEngineering: Bool = true,
        supportedTaskTypes: Set<String> = ["classifier", "regressor", "recommender", "sound-classifier"],
        trainingCacheSize: Int = 5
    ) {
        self.enableCreateML = enableCreateML
        self.enableOnDeviceTraining = enableOnDeviceTraining
        self.enableModelExport = enableModelExport
        self.enableProgressTracking = enableProgressTracking
        self.maxTrainingDuration = maxTrainingDuration
        self.maxDatasetSize = maxDatasetSize
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableModelValidation = enableModelValidation
        self.enableAutomaticFeatureEngineering = enableAutomaticFeatureEngineering
        self.supportedTaskTypes = supportedTaskTypes
        self.trainingCacheSize = trainingCacheSize
    }
    
    public var isValid: Bool {
        maxTrainingDuration > 0 &&
        maxDatasetSize > 0 &&
        trainingCacheSize > 0
    }
    
    public func merged(with other: CreateMLCapabilityConfiguration) -> CreateMLCapabilityConfiguration {
        CreateMLCapabilityConfiguration(
            enableCreateML: other.enableCreateML,
            enableOnDeviceTraining: other.enableOnDeviceTraining,
            enableModelExport: other.enableModelExport,
            enableProgressTracking: other.enableProgressTracking,
            maxTrainingDuration: other.maxTrainingDuration,
            maxDatasetSize: other.maxDatasetSize,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableModelValidation: other.enableModelValidation,
            enableAutomaticFeatureEngineering: other.enableAutomaticFeatureEngineering,
            supportedTaskTypes: other.supportedTaskTypes,
            trainingCacheSize: other.trainingCacheSize
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CreateMLCapabilityConfiguration {
        var adjustedDuration = maxTrainingDuration
        var adjustedDatasetSize = maxDatasetSize
        var adjustedLogging = enableLogging
        var adjustedCacheSize = trainingCacheSize
        
        if environment.isLowPowerMode {
            adjustedDuration = min(maxTrainingDuration, 600.0) // Reduce to 10 minutes
            adjustedDatasetSize = min(maxDatasetSize, 50_000_000) // Reduce to 50MB
            adjustedCacheSize = min(trainingCacheSize, 2)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return CreateMLCapabilityConfiguration(
            enableCreateML: enableCreateML,
            enableOnDeviceTraining: enableOnDeviceTraining,
            enableModelExport: enableModelExport,
            enableProgressTracking: enableProgressTracking,
            maxTrainingDuration: adjustedDuration,
            maxDatasetSize: adjustedDatasetSize,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableModelValidation: enableModelValidation,
            enableAutomaticFeatureEngineering: enableAutomaticFeatureEngineering,
            supportedTaskTypes: supportedTaskTypes,
            trainingCacheSize: adjustedCacheSize
        )
    }
}

// MARK: - Create ML Types

/// Training dataset information
public struct TrainingDataset: Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let type: DatasetType
    public let size: Int64
    public let featureCount: Int
    public let sampleCount: Int
    public let targetFeature: String?
    public let features: [DatasetFeature]
    public let creationDate: Date
    public let lastModified: Date?
    public let format: DatasetFormat
    public let validation: DatasetValidation?
    
    public enum DatasetType: String, Sendable, Codable, CaseIterable {
        case tabular = "tabular"
        case image = "image"
        case text = "text"
        case audio = "audio"
        case timeSeries = "time-series"
    }
    
    public enum DatasetFormat: String, Sendable, Codable, CaseIterable {
        case csv = "csv"
        case json = "json"
        case coreData = "core-data"
        case imageDirectory = "image-directory"
        case audioDirectory = "audio-directory"
    }
    
    public struct DatasetFeature: Sendable, Codable {
        public let name: String
        public let type: FeatureType
        public let role: FeatureRole
        public let statisticalSummary: StatisticalSummary?
        
        public enum FeatureType: String, Sendable, Codable, CaseIterable {
            case categorical = "categorical"
            case numerical = "numerical"
            case text = "text"
            case image = "image"
            case audio = "audio"
            case datetime = "datetime"
        }
        
        public enum FeatureRole: String, Sendable, Codable, CaseIterable {
            case feature = "feature"
            case target = "target"
            case ignored = "ignored"
            case identifier = "identifier"
        }
        
        public struct StatisticalSummary: Sendable, Codable {
            public let mean: Double?
            public let standardDeviation: Double?
            public let minimum: Double?
            public let maximum: Double?
            public let uniqueCount: Int?
            public let nullCount: Int
            
            public init(mean: Double? = nil, standardDeviation: Double? = nil, minimum: Double? = nil, maximum: Double? = nil, uniqueCount: Int? = nil, nullCount: Int = 0) {
                self.mean = mean
                self.standardDeviation = standardDeviation
                self.minimum = minimum
                self.maximum = maximum
                self.uniqueCount = uniqueCount
                self.nullCount = nullCount
            }
        }
        
        public init(name: String, type: FeatureType, role: FeatureRole, statisticalSummary: StatisticalSummary? = nil) {
            self.name = name
            self.type = type
            self.role = role
            self.statisticalSummary = statisticalSummary
        }
    }
    
    public struct DatasetValidation: Sendable, Codable {
        public let isValid: Bool
        public let errorCount: Int
        public let warningCount: Int
        public let messages: [ValidationMessage]
        
        public struct ValidationMessage: Sendable, Codable {
            public let type: MessageType
            public let message: String
            public let feature: String?
            
            public enum MessageType: String, Sendable, Codable, CaseIterable {
                case error = "error"
                case warning = "warning"
                case info = "info"
            }
            
            public init(type: MessageType, message: String, feature: String? = nil) {
                self.type = type
                self.message = message
                self.feature = feature
            }
        }
        
        public init(isValid: Bool, errorCount: Int, warningCount: Int, messages: [ValidationMessage]) {
            self.isValid = isValid
            self.errorCount = errorCount
            self.warningCount = warningCount
            self.messages = messages
        }
    }
    
    public init(
        name: String,
        type: DatasetType,
        size: Int64,
        featureCount: Int,
        sampleCount: Int,
        targetFeature: String? = nil,
        features: [DatasetFeature] = [],
        format: DatasetFormat,
        validation: DatasetValidation? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.size = size
        self.featureCount = featureCount
        self.sampleCount = sampleCount
        self.targetFeature = targetFeature
        self.features = features
        self.creationDate = Date()
        self.lastModified = nil
        self.format = format
        self.validation = validation
    }
}

/// Training task information
public struct TrainingTask: Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let taskType: TaskType
    public let status: TaskStatus
    public let dataset: TrainingDataset
    public let parameters: TrainingParameters
    public let progress: TrainingProgress
    public let startTime: Date?
    public let endTime: Date?
    public let duration: TimeInterval?
    public let result: TrainingResult?
    public let error: CreateMLError?
    
    public enum TaskType: String, Sendable, Codable, CaseIterable {
        case classifier = "classifier"
        case regressor = "regressor"
        case recommender = "recommender"
        case soundClassifier = "sound-classifier"
        case imageClassifier = "image-classifier"
        case textClassifier = "text-classifier"
        case objectDetector = "object-detector"
        case styleTransfer = "style-transfer"
        case wordTagger = "word-tagger"
        case sentimentClassifier = "sentiment-classifier"
    }
    
    public enum TaskStatus: String, Sendable, Codable, CaseIterable {
        case pending = "pending"
        case preparing = "preparing"
        case training = "training"
        case validating = "validating"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
    }
    
    public struct TrainingParameters: Sendable, Codable {
        public let algorithm: String?
        public let maxIterations: Int?
        public let learningRate: Double?
        public let batchSize: Int?
        public let validationSplit: Double?
        public let featureColumns: [String]?
        public let targetColumn: String?
        public let randomSeed: Int?
        public let customParameters: [String: String]
        
        public init(
            algorithm: String? = nil,
            maxIterations: Int? = nil,
            learningRate: Double? = nil,
            batchSize: Int? = nil,
            validationSplit: Double? = 0.2,
            featureColumns: [String]? = nil,
            targetColumn: String? = nil,
            randomSeed: Int? = nil,
            customParameters: [String: String] = [:]
        ) {
            self.algorithm = algorithm
            self.maxIterations = maxIterations
            self.learningRate = learningRate
            self.batchSize = batchSize
            self.validationSplit = validationSplit
            self.featureColumns = featureColumns
            self.targetColumn = targetColumn
            self.randomSeed = randomSeed
            self.customParameters = customParameters
        }
    }
    
    public struct TrainingProgress: Sendable, Codable {
        public let percentage: Double
        public let currentIteration: Int?
        public let totalIterations: Int?
        public let currentLoss: Double?
        public let validationAccuracy: Double?
        public let estimatedTimeRemaining: TimeInterval?
        public let phase: TrainingPhase
        
        public enum TrainingPhase: String, Sendable, Codable, CaseIterable {
            case initialization = "initialization"
            case preprocessing = "preprocessing"
            case training = "training"
            case validation = "validation"
            case optimization = "optimization"
            case finalization = "finalization"
        }
        
        public init(
            percentage: Double = 0,
            currentIteration: Int? = nil,
            totalIterations: Int? = nil,
            currentLoss: Double? = nil,
            validationAccuracy: Double? = nil,
            estimatedTimeRemaining: TimeInterval? = nil,
            phase: TrainingPhase = .initialization
        ) {
            self.percentage = max(0, min(100, percentage))
            self.currentIteration = currentIteration
            self.totalIterations = totalIterations
            self.currentLoss = currentLoss
            self.validationAccuracy = validationAccuracy
            self.estimatedTimeRemaining = estimatedTimeRemaining
            self.phase = phase
        }
    }
    
    public struct TrainingResult: Sendable, Codable {
        public let modelURL: URL?
        public let accuracy: Double?
        public let precision: Double?
        public let recall: Double?
        public let f1Score: Double?
        public let trainingAccuracy: Double?
        public let validationAccuracy: Double?
        public let finalLoss: Double?
        public let modelSize: Int64?
        public let featureImportance: [String: Double]?
        public let confusionMatrix: [[Int]]?
        
        public init(
            modelURL: URL? = nil,
            accuracy: Double? = nil,
            precision: Double? = nil,
            recall: Double? = nil,
            f1Score: Double? = nil,
            trainingAccuracy: Double? = nil,
            validationAccuracy: Double? = nil,
            finalLoss: Double? = nil,
            modelSize: Int64? = nil,
            featureImportance: [String: Double]? = nil,
            confusionMatrix: [[Int]]? = nil
        ) {
            self.modelURL = modelURL
            self.accuracy = accuracy
            self.precision = precision
            self.recall = recall
            self.f1Score = f1Score
            self.trainingAccuracy = trainingAccuracy
            self.validationAccuracy = validationAccuracy
            self.finalLoss = finalLoss
            self.modelSize = modelSize
            self.featureImportance = featureImportance
            self.confusionMatrix = confusionMatrix
        }
    }
    
    public init(
        name: String,
        taskType: TaskType,
        dataset: TrainingDataset,
        parameters: TrainingParameters = TrainingParameters()
    ) {
        self.id = UUID()
        self.name = name
        self.taskType = taskType
        self.status = .pending
        self.dataset = dataset
        self.parameters = parameters
        self.progress = TrainingProgress()
        self.startTime = nil
        self.endTime = nil
        self.duration = nil
        self.result = nil
        self.error = nil
    }
}

/// Create ML metrics
public struct CreateMLMetrics: Sendable {
    public let totalTrainingTasks: Int
    public let completedTasks: Int
    public let failedTasks: Int
    public let averageTrainingTime: TimeInterval
    public let averageAccuracy: Double
    public let tasksByType: [String: Int]
    public let datasetsByType: [String: Int]
    public let totalDatasetSize: Int64
    public let modelsCreated: Int
    public let averageModelSize: Int64
    public let successRate: Double
    
    public init(
        totalTrainingTasks: Int = 0,
        completedTasks: Int = 0,
        failedTasks: Int = 0,
        averageTrainingTime: TimeInterval = 0,
        averageAccuracy: Double = 0,
        tasksByType: [String: Int] = [:],
        datasetsByType: [String: Int] = [:],
        totalDatasetSize: Int64 = 0,
        modelsCreated: Int = 0,
        averageModelSize: Int64 = 0,
        successRate: Double = 0
    ) {
        self.totalTrainingTasks = totalTrainingTasks
        self.completedTasks = completedTasks
        self.failedTasks = failedTasks
        self.averageTrainingTime = averageTrainingTime
        self.averageAccuracy = averageAccuracy
        self.tasksByType = tasksByType
        self.datasetsByType = datasetsByType
        self.totalDatasetSize = totalDatasetSize
        self.modelsCreated = modelsCreated
        self.averageModelSize = averageModelSize
        self.successRate = totalTrainingTasks > 0 ? Double(completedTasks) / Double(totalTrainingTasks) : 0
    }
}

// MARK: - Create ML Resource

/// Create ML resource management
@available(iOS 13.0, macOS 10.15, *)
public actor CreateMLCapabilityResource: AxiomCapabilityResource {
    private let configuration: CreateMLCapabilityConfiguration
    private var datasets: [String: TrainingDataset] = [:]
    private var trainingTasks: [UUID: TrainingTask] = [:]
    private var activeTrainingTasks: [UUID: TrainingTask] = [:]
    private var trainingHistory: [TrainingTask] = []
    private var metrics: CreateMLMetrics = CreateMLMetrics()
    private var taskStreamContinuation: AsyncStream<TrainingTask>.Continuation?
    private var progressStreamContinuation: AsyncStream<TrainingTask.TrainingProgress>.Continuation?
    private var datasetStreamContinuation: AsyncStream<TrainingDataset>.Continuation?
    
    public init(configuration: CreateMLCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 200_000_000, // 200MB for training operations
            cpu: 6.0, // High CPU usage for training
            bandwidth: 0,
            storage: 1_000_000_000 // 1GB for datasets and models
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let datasetMemory = datasets.count * 10_000_000 // ~10MB per dataset metadata
            let taskMemory = activeTrainingTasks.count * 50_000_000 // ~50MB per active task
            let historyMemory = trainingHistory.count * 5_000
            
            return ResourceUsage(
                memory: datasetMemory + taskMemory + historyMemory + 20_000_000,
                cpu: activeTrainingTasks.isEmpty ? 0.2 : 5.0,
                bandwidth: 0,
                storage: datasets.values.reduce(0) { $0 + $1.size }
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Create ML is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableCreateML
        }
        return false
    }
    
    public func release() async {
        // Cancel active training tasks
        for task in activeTrainingTasks.values {
            await cancelTrainingTask(task.id)
        }
        
        datasets.removeAll()
        trainingTasks.removeAll()
        activeTrainingTasks.removeAll()
        trainingHistory.removeAll()
        
        taskStreamContinuation?.finish()
        progressStreamContinuation?.finish()
        datasetStreamContinuation?.finish()
        
        metrics = CreateMLMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize Create ML subsystem
        if configuration.enableLogging {
            print("[CreateML] 🚀 Create ML capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: CreateMLCapabilityConfiguration) async throws {
        // Configuration updates for Create ML
    }
    
    // MARK: - Training Streams
    
    public var taskStream: AsyncStream<TrainingTask> {
        AsyncStream { continuation in
            self.taskStreamContinuation = continuation
        }
    }
    
    public var progressStream: AsyncStream<TrainingTask.TrainingProgress> {
        AsyncStream { continuation in
            self.progressStreamContinuation = continuation
        }
    }
    
    public var datasetStream: AsyncStream<TrainingDataset> {
        AsyncStream { continuation in
            self.datasetStreamContinuation = continuation
        }
    }
    
    // MARK: - Dataset Management
    
    public func registerDataset(_ dataset: TrainingDataset) async throws {
        guard configuration.enableCreateML else {
            throw CreateMLError.createMLDisabled
        }
        
        guard dataset.size <= configuration.maxDatasetSize else {
            throw CreateMLError.datasetTooLarge(dataset.size, configuration.maxDatasetSize)
        }
        
        datasets[dataset.name] = dataset
        datasetStreamContinuation?.yield(dataset)
        
        await updateDatasetMetrics(dataset)
        
        if configuration.enableLogging {
            await logDataset(dataset, action: "Registered")
        }
    }
    
    public func getDatasets() async -> [TrainingDataset] {
        return Array(datasets.values)
    }
    
    public func getDataset(name: String) async -> TrainingDataset? {
        return datasets[name]
    }
    
    public func validateDataset(_ dataset: TrainingDataset) async -> TrainingDataset.DatasetValidation {
        var messages: [TrainingDataset.DatasetValidation.ValidationMessage] = []
        var errorCount = 0
        var warningCount = 0
        
        // Basic validation checks
        if dataset.sampleCount == 0 {
            messages.append(.init(type: .error, message: "Dataset has no samples"))
            errorCount += 1
        }
        
        if dataset.featureCount == 0 {
            messages.append(.init(type: .error, message: "Dataset has no features"))
            errorCount += 1
        }
        
        if dataset.targetFeature == nil {
            messages.append(.init(type: .warning, message: "No target feature specified"))
            warningCount += 1
        }
        
        if dataset.sampleCount < 100 {
            messages.append(.init(type: .warning, message: "Small dataset size may affect model quality"))
            warningCount += 1
        }
        
        // Feature validation
        for feature in dataset.features {
            if feature.role == .target && feature.type == .categorical {
                if let stats = feature.statisticalSummary, let uniqueCount = stats.uniqueCount, uniqueCount < 2 {
                    messages.append(.init(type: .error, message: "Target feature must have at least 2 classes", feature: feature.name))
                    errorCount += 1
                }
            }
        }
        
        let isValid = errorCount == 0
        
        return TrainingDataset.DatasetValidation(
            isValid: isValid,
            errorCount: errorCount,
            warningCount: warningCount,
            messages: messages
        )
    }
    
    // MARK: - Training Task Management
    
    public func createTrainingTask(_ task: TrainingTask) async throws -> TrainingTask {
        guard configuration.enableOnDeviceTraining else {
            throw CreateMLError.onDeviceTrainingDisabled
        }
        
        guard configuration.supportedTaskTypes.contains(task.taskType.rawValue) else {
            throw CreateMLError.unsupportedTaskType(task.taskType.rawValue)
        }
        
        // Validate dataset
        let validation = await validateDataset(task.dataset)
        if !validation.isValid {
            throw CreateMLError.invalidDataset(validation.messages.map { $0.message }.joined(separator: ", "))
        }
        
        trainingTasks[task.id] = task
        taskStreamContinuation?.yield(task)
        
        await updateTaskMetrics(task)
        
        if configuration.enableLogging {
            await logTask(task, action: "Created")
        }
        
        return task
    }
    
    public func startTraining(_ taskId: UUID) async throws {
        guard var task = trainingTasks[taskId] else {
            throw CreateMLError.taskNotFound(taskId)
        }
        
        guard task.status == .pending else {
            throw CreateMLError.invalidTaskState(task.status)
        }
        
        // Update task status
        task = TrainingTask(name: task.name, taskType: task.taskType, dataset: task.dataset, parameters: task.parameters)
        trainingTasks[taskId] = task
        activeTrainingTasks[taskId] = task
        
        taskStreamContinuation?.yield(task)
        
        // Start training process
        await performTraining(task)
    }
    
    public func cancelTrainingTask(_ taskId: UUID) async {
        guard var task = trainingTasks[taskId] else { return }
        
        task = TrainingTask(name: task.name, taskType: task.taskType, dataset: task.dataset, parameters: task.parameters)
        
        trainingTasks[taskId] = task
        activeTrainingTasks.removeValue(forKey: taskId)
        trainingHistory.append(task)
        
        taskStreamContinuation?.yield(task)
        
        if configuration.enableLogging {
            await logTask(task, action: "Cancelled")
        }
    }
    
    public func getTrainingTasks() async -> [TrainingTask] {
        return Array(trainingTasks.values)
    }
    
    public func getActiveTrainingTasks() async -> [TrainingTask] {
        return Array(activeTrainingTasks.values)
    }
    
    public func getTrainingHistory() async -> [TrainingTask] {
        return trainingHistory
    }
    
    public func getTrainingTask(id: UUID) async -> TrainingTask? {
        return trainingTasks[id]
    }
    
    // MARK: - Model Export
    
    public func exportModel(_ taskId: UUID, to url: URL) async throws -> URL {
        guard configuration.enableModelExport else {
            throw CreateMLError.modelExportDisabled
        }
        
        guard let task = trainingTasks[taskId] else {
            throw CreateMLError.taskNotFound(taskId)
        }
        
        guard task.status == .completed else {
            throw CreateMLError.taskNotCompleted(taskId)
        }
        
        guard let result = task.result, let modelURL = result.modelURL else {
            throw CreateMLError.noModelAvailable(taskId)
        }
        
        // Copy model to specified location
        try FileManager.default.copyItem(at: modelURL, to: url)
        
        if configuration.enableLogging {
            print("[CreateML] 📤 Exported model for task \(taskId) to \(url.path)")
        }
        
        return url
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> CreateMLMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = CreateMLMetrics()
    }
    
    // MARK: - Private Methods
    
    private func performTraining(_ task: TrainingTask) async {
        let startTime = Date()
        var currentTask = task
        
        do {
            // Simulate training process
            for phase in TrainingTask.TrainingProgress.TrainingPhase.allCases {
                let phaseProgress = TrainingTask.TrainingProgress(
                    percentage: Double(phase.hashValue) * 20,
                    phase: phase
                )
                
                currentTask = TrainingTask(name: task.name, taskType: task.taskType, dataset: task.dataset, parameters: task.parameters)
                trainingTasks[task.id] = currentTask
                
                progressStreamContinuation?.yield(phaseProgress)
                taskStreamContinuation?.yield(currentTask)
                
                // Simulate training time
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second per phase
            }
            
            // Complete training
            let duration = Date().timeIntervalSince(startTime)
            let modelURL = try await createModelFile(for: task)
            
            let result = TrainingTask.TrainingResult(
                modelURL: modelURL,
                accuracy: Double.random(in: 0.8...0.95),
                trainingAccuracy: Double.random(in: 0.85...0.98),
                validationAccuracy: Double.random(in: 0.80...0.92),
                finalLoss: Double.random(in: 0.05...0.20),
                modelSize: Int64.random(in: 1_000_000...10_000_000)
            )
            
            currentTask = TrainingTask(name: task.name, taskType: task.taskType, dataset: task.dataset, parameters: task.parameters)
            
            trainingTasks[task.id] = currentTask
            activeTrainingTasks.removeValue(forKey: task.id)
            trainingHistory.append(currentTask)
            
            taskStreamContinuation?.yield(currentTask)
            
            await updateCompletionMetrics(currentTask, duration: duration)
            
            if configuration.enableLogging {
                await logTask(currentTask, action: "Completed", duration: duration)
            }
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            currentTask = TrainingTask(name: task.name, taskType: task.taskType, dataset: task.dataset, parameters: task.parameters)
            
            trainingTasks[task.id] = currentTask
            activeTrainingTasks.removeValue(forKey: task.id)
            trainingHistory.append(currentTask)
            
            taskStreamContinuation?.yield(currentTask)
            
            await updateFailureMetrics(currentTask, duration: duration)
            
            if configuration.enableLogging {
                await logTask(currentTask, action: "Failed", duration: duration)
            }
        }
    }
    
    private func createModelFile(for task: TrainingTask) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let modelURL = tempDir.appendingPathComponent("\(task.name)_\(task.id.uuidString).mlmodel")
        
        // Create a placeholder model file
        let modelData = "CreateML Model for \(task.name)".data(using: .utf8) ?? Data()
        try modelData.write(to: modelURL)
        
        return modelURL
    }
    
    private func updateDatasetMetrics(_ dataset: TrainingDataset) async {
        let datasetsByType = metrics.datasetsByType
        var updatedDatasetsByType = datasetsByType
        updatedDatasetsByType[dataset.type.rawValue, default: 0] += 1
        
        metrics = CreateMLMetrics(
            totalTrainingTasks: metrics.totalTrainingTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: metrics.failedTasks,
            averageTrainingTime: metrics.averageTrainingTime,
            averageAccuracy: metrics.averageAccuracy,
            tasksByType: metrics.tasksByType,
            datasetsByType: updatedDatasetsByType,
            totalDatasetSize: metrics.totalDatasetSize + dataset.size,
            modelsCreated: metrics.modelsCreated,
            averageModelSize: metrics.averageModelSize,
            successRate: metrics.successRate
        )
    }
    
    private func updateTaskMetrics(_ task: TrainingTask) async {
        let totalTasks = metrics.totalTrainingTasks + 1
        
        var tasksByType = metrics.tasksByType
        tasksByType[task.taskType.rawValue, default: 0] += 1
        
        metrics = CreateMLMetrics(
            totalTrainingTasks: totalTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: metrics.failedTasks,
            averageTrainingTime: metrics.averageTrainingTime,
            averageAccuracy: metrics.averageAccuracy,
            tasksByType: tasksByType,
            datasetsByType: metrics.datasetsByType,
            totalDatasetSize: metrics.totalDatasetSize,
            modelsCreated: metrics.modelsCreated,
            averageModelSize: metrics.averageModelSize,
            successRate: metrics.successRate
        )
    }
    
    private func updateCompletionMetrics(_ task: TrainingTask, duration: TimeInterval) async {
        let completedTasks = metrics.completedTasks + 1
        let modelsCreated = metrics.modelsCreated + 1
        
        let newAverageTrainingTime = ((metrics.averageTrainingTime * Double(metrics.completedTasks)) + duration) / Double(completedTasks)
        
        var newAverageAccuracy = metrics.averageAccuracy
        var newAverageModelSize = metrics.averageModelSize
        
        if let result = task.result {
            if let accuracy = result.accuracy {
                newAverageAccuracy = ((metrics.averageAccuracy * Double(metrics.completedTasks)) + accuracy) / Double(completedTasks)
            }
            if let modelSize = result.modelSize {
                newAverageModelSize = ((metrics.averageModelSize * Int64(metrics.modelsCreated)) + modelSize) / Int64(modelsCreated)
            }
        }
        
        metrics = CreateMLMetrics(
            totalTrainingTasks: metrics.totalTrainingTasks,
            completedTasks: completedTasks,
            failedTasks: metrics.failedTasks,
            averageTrainingTime: newAverageTrainingTime,
            averageAccuracy: newAverageAccuracy,
            tasksByType: metrics.tasksByType,
            datasetsByType: metrics.datasetsByType,
            totalDatasetSize: metrics.totalDatasetSize,
            modelsCreated: modelsCreated,
            averageModelSize: newAverageModelSize,
            successRate: Double(completedTasks) / Double(metrics.totalTrainingTasks)
        )
    }
    
    private func updateFailureMetrics(_ task: TrainingTask, duration: TimeInterval) async {
        let failedTasks = metrics.failedTasks + 1
        
        metrics = CreateMLMetrics(
            totalTrainingTasks: metrics.totalTrainingTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: failedTasks,
            averageTrainingTime: metrics.averageTrainingTime,
            averageAccuracy: metrics.averageAccuracy,
            tasksByType: metrics.tasksByType,
            datasetsByType: metrics.datasetsByType,
            totalDatasetSize: metrics.totalDatasetSize,
            modelsCreated: metrics.modelsCreated,
            averageModelSize: metrics.averageModelSize,
            successRate: Double(metrics.completedTasks) / Double(metrics.totalTrainingTasks)
        )
    }
    
    private func logDataset(_ dataset: TrainingDataset, action: String) async {
        let typeIcon = switch dataset.type {
        case .tabular: "📊"
        case .image: "🖼️"
        case .text: "📝"
        case .audio: "🔊"
        case .timeSeries: "📈"
        }
        
        let sizeStr = ByteCountFormatter.string(fromByteCount: dataset.size, countStyle: .file)
        
        print("[CreateML] \(typeIcon) \(action) dataset: \(dataset.name) - \(dataset.sampleCount) samples, \(sizeStr)")
    }
    
    private func logTask(_ task: TrainingTask, action: String, duration: TimeInterval? = nil) async {
        let statusIcon = switch task.status {
        case .pending: "⏳"
        case .preparing: "⚙️"
        case .training: "🏋️"
        case .validating: "✅"
        case .completed: "🎉"
        case .failed: "❌"
        case .cancelled: "🚫"
        }
        
        let typeIcon = switch task.taskType {
        case .classifier: "🏷️"
        case .regressor: "📊"
        case .recommender: "💡"
        case .soundClassifier: "🔊"
        case .imageClassifier: "🖼️"
        case .textClassifier: "📝"
        case .objectDetector: "🔍"
        case .styleTransfer: "🎨"
        case .wordTagger: "🏷️"
        case .sentimentClassifier: "😊"
        }
        
        let durationStr = duration.map { String(format: " (%.1fs)", $0) } ?? ""
        
        print("[CreateML] \(statusIcon)\(typeIcon) \(action): \(task.name)\(durationStr)")
    }
}

// MARK: - Create ML Capability Implementation

/// Create ML capability providing comprehensive on-device model training
@available(iOS 13.0, macOS 10.15, *)
public actor CreateMLCapability: DomainCapability {
    public typealias ConfigurationType = CreateMLCapabilityConfiguration
    public typealias ResourceType = CreateMLCapabilityResource
    
    private var _configuration: CreateMLCapabilityConfiguration
    private var _resources: CreateMLCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "create-ml-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: CreateMLCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CreateMLCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CreateMLCapabilityConfiguration = CreateMLCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CreateMLCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: CreateMLCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Create ML configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Create ML is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Create ML doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Create ML Operations
    
    /// Register dataset
    public func registerDataset(_ dataset: TrainingDataset) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        try await _resources.registerDataset(dataset)
    }
    
    /// Get datasets
    public func getDatasets() async throws -> [TrainingDataset] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getDatasets()
    }
    
    /// Get dataset stream
    public func getDatasetStream() async throws -> AsyncStream<TrainingDataset> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.datasetStream
    }
    
    /// Get specific dataset
    public func getDataset(name: String) async throws -> TrainingDataset? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getDataset(name: name)
    }
    
    /// Validate dataset
    public func validateDataset(_ dataset: TrainingDataset) async throws -> TrainingDataset.DatasetValidation {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.validateDataset(dataset)
    }
    
    /// Create training task
    public func createTrainingTask(_ task: TrainingTask) async throws -> TrainingTask {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return try await _resources.createTrainingTask(task)
    }
    
    /// Start training
    public func startTraining(_ taskId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        try await _resources.startTraining(taskId)
    }
    
    /// Cancel training task
    public func cancelTrainingTask(_ taskId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        await _resources.cancelTrainingTask(taskId)
    }
    
    /// Get task stream
    public func getTaskStream() async throws -> AsyncStream<TrainingTask> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.taskStream
    }
    
    /// Get progress stream
    public func getProgressStream() async throws -> AsyncStream<TrainingTask.TrainingProgress> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.progressStream
    }
    
    /// Get training tasks
    public func getTrainingTasks() async throws -> [TrainingTask] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getTrainingTasks()
    }
    
    /// Get active training tasks
    public func getActiveTrainingTasks() async throws -> [TrainingTask] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getActiveTrainingTasks()
    }
    
    /// Get training history
    public func getTrainingHistory() async throws -> [TrainingTask] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getTrainingHistory()
    }
    
    /// Get specific training task
    public func getTrainingTask(id: UUID) async throws -> TrainingTask? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getTrainingTask(id: id)
    }
    
    /// Export model
    public func exportModel(_ taskId: UUID, to url: URL) async throws -> URL {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return try await _resources.exportModel(taskId, to: url)
    }
    
    /// Get Create ML metrics
    public func getMetrics() async throws -> CreateMLMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Create ML capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if training is active
    public func hasActiveTraining() async throws -> Bool {
        let activeTasks = try await getActiveTrainingTasks()
        return !activeTasks.isEmpty
    }
    
    /// Get dataset count
    public func getDatasetCount() async throws -> Int {
        let datasets = try await getDatasets()
        return datasets.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Create ML specific errors
public enum CreateMLError: Error, LocalizedError {
    case createMLDisabled
    case onDeviceTrainingDisabled
    case modelExportDisabled
    case datasetTooLarge(Int64, Int64)
    case unsupportedTaskType(String)
    case invalidDataset(String)
    case taskNotFound(UUID)
    case taskNotCompleted(UUID)
    case noModelAvailable(UUID)
    case trainingFailed(String)
    case invalidTaskState(TrainingTask.TaskStatus)
    case datasetValidationFailed([String])
    case insufficientData(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .createMLDisabled:
            return "Create ML is disabled"
        case .onDeviceTrainingDisabled:
            return "On-device training is disabled"
        case .modelExportDisabled:
            return "Model export is disabled"
        case .datasetTooLarge(let size, let maxSize):
            let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let maxSizeStr = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
            return "Dataset too large: \(sizeStr) exceeds maximum \(maxSizeStr)"
        case .unsupportedTaskType(let type):
            return "Unsupported task type: \(type)"
        case .invalidDataset(let reason):
            return "Invalid dataset: \(reason)"
        case .taskNotFound(let id):
            return "Training task not found: \(id)"
        case .taskNotCompleted(let id):
            return "Training task not completed: \(id)"
        case .noModelAvailable(let id):
            return "No model available for task: \(id)"
        case .trainingFailed(let reason):
            return "Training failed: \(reason)"
        case .invalidTaskState(let state):
            return "Invalid task state: \(state.rawValue)"
        case .datasetValidationFailed(let errors):
            return "Dataset validation failed: \(errors.joined(separator: ", "))"
        case .insufficientData(let reason):
            return "Insufficient data: \(reason)"
        case .configurationError(let reason):
            return "Create ML configuration error: \(reason)"
        }
    }
}