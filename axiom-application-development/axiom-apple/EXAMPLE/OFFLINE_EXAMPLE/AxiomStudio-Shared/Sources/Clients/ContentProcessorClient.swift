import Foundation
import AxiomCore
import AxiomArchitecture

public actor ContentProcessorClient: AxiomClient {
    public typealias StateType = ContentProcessorState
    public typealias ActionType = ContentProcessorAction
    
    private var _state: ContentProcessorState
    private let storageCapability: LocalFileStorageCapability
    private var stateStreamContinuation: AsyncStream<ContentProcessorState>.Continuation?
    
    private var stateHistory: [ContentProcessorState] = []
    private var currentHistoryIndex: Int = -1
    private let maxHistorySize: Int = 50
    
    private var actionCount: Int = 0
    private var lastActionTime: Date?
    private var processingQueue: [ProcessingTask] = []
    private var isProcessing: Bool = false
    
    public init(
        storageCapability: LocalFileStorageCapability,
        initialState: ContentProcessorState = ContentProcessorState()
    ) {
        self._state = initialState
        self.storageCapability = storageCapability
        
        self.stateHistory = [initialState]
        self.currentHistoryIndex = 0
    }
    
    public var stateStream: AsyncStream<ContentProcessorState> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            continuation.yield(self._state)
            
            continuation.onTermination = { _ in
                Task { [weak self] in
                    await self?.setStreamContinuation(nil)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<ContentProcessorState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func process(_ action: ContentProcessorAction) async throws {
        actionCount += 1
        lastActionTime = Date()
        
        let oldState = _state
        let newState = try await processAction(action, currentState: _state)
        
        guard newState != oldState else { return }
        
        await stateWillUpdate(from: oldState, to: newState)
        
        _state = newState
        saveStateToHistory(newState)
        
        stateStreamContinuation?.yield(newState)
        await stateDidUpdate(from: oldState, to: newState)
        
        if shouldAutoSave(action) {
            try await autoSave()
        }
    }
    
    public func getCurrentState() async -> ContentProcessorState {
        return _state
    }
    
    public func rollbackToState(_ state: ContentProcessorState) async {
        let oldState = _state
        _state = state
        stateStreamContinuation?.yield(state)
        await stateDidUpdate(from: oldState, to: state)
    }
    
    private func processAction(_ action: ContentProcessorAction, currentState: ContentProcessorState) async throws -> ContentProcessorState {
        switch action {
        case .loadMLModels:
            return try await loadMLModels(in: currentState)
            
        case .loadMLModel(let modelName):
            return try await loadMLModel(modelName, in: currentState)
            
        case .unloadMLModel(let modelName):
            return try await unloadMLModel(modelName, in: currentState)
            
        case .processText(let text, let analysisType):
            return try await processText(text, analysisType: analysisType, in: currentState)
            
        case .processImage(let imageId, let processingType):
            return try await processImage(imageId, processingType: processingType, in: currentState)
            
        case .processAudio(let audioId):
            return try await processAudio(audioId, in: currentState)
            
        case .addTextAnalysisResult(let result):
            return addTextAnalysisResult(result, in: currentState)
            
        case .addImageProcessingResult(let result):
            return addImageProcessingResult(result, in: currentState)
            
        case .addSpeechRecognitionResult(let result):
            return addSpeechRecognitionResult(result, in: currentState)
            
        case .setProcessing(let isProcessing):
            return ContentProcessorState(
                mlModels: currentState.mlModels,
                textAnalysisResults: currentState.textAnalysisResults,
                imageProcessingResults: currentState.imageProcessingResults,
                speechRecognitionResults: currentState.speechRecognitionResults,
                isProcessing: isProcessing,
                error: currentState.error
            )
            
        case .setError(let error):
            return ContentProcessorState(
                mlModels: currentState.mlModels,
                textAnalysisResults: currentState.textAnalysisResults,
                imageProcessingResults: currentState.imageProcessingResults,
                speechRecognitionResults: currentState.speechRecognitionResults,
                isProcessing: currentState.isProcessing,
                error: error
            )
        }
    }
    
    // MARK: - ML Model Operations
    
    private func loadMLModels(in state: ContentProcessorState) async throws -> ContentProcessorState {
        do {
            let models = try await storageCapability.loadArray(MLModel.self, from: "models/models.json")
            return ContentProcessorState(
                mlModels: models,
                textAnalysisResults: state.textAnalysisResults,
                imageProcessingResults: state.imageProcessingResults,
                speechRecognitionResults: state.speechRecognitionResults,
                isProcessing: false,
                error: nil
            )
        } catch {
            return ContentProcessorState(
                mlModels: state.mlModels,
                textAnalysisResults: state.textAnalysisResults,
                imageProcessingResults: state.imageProcessingResults,
                speechRecognitionResults: state.speechRecognitionResults,
                isProcessing: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func loadMLModel(_ modelName: String, in state: ContentProcessorState) async throws -> ContentProcessorState {
        guard let modelIndex = state.mlModels.firstIndex(where: { $0.name == modelName }) else {
            throw ContentProcessorError.modelNotFound(modelName)
        }
        
        // Simulate model loading delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        var newModels = state.mlModels
        let currentModel = newModels[modelIndex]
        
        newModels[modelIndex] = MLModel(
            id: currentModel.id,
            name: currentModel.name,
            description: currentModel.description,
            modelType: currentModel.modelType,
            filePath: currentModel.filePath,
            isLoaded: true,
            accuracy: currentModel.accuracy,
            lastTrainingDate: currentModel.lastTrainingDate,
            version: currentModel.version
        )
        
        return ContentProcessorState(
            mlModels: newModels,
            textAnalysisResults: state.textAnalysisResults,
            imageProcessingResults: state.imageProcessingResults,
            speechRecognitionResults: state.speechRecognitionResults,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func unloadMLModel(_ modelName: String, in state: ContentProcessorState) async throws -> ContentProcessorState {
        guard let modelIndex = state.mlModels.firstIndex(where: { $0.name == modelName }) else {
            throw ContentProcessorError.modelNotFound(modelName)
        }
        
        var newModels = state.mlModels
        let currentModel = newModels[modelIndex]
        
        newModels[modelIndex] = MLModel(
            id: currentModel.id,
            name: currentModel.name,
            description: currentModel.description,
            modelType: currentModel.modelType,
            filePath: currentModel.filePath,
            isLoaded: false,
            accuracy: currentModel.accuracy,
            lastTrainingDate: currentModel.lastTrainingDate,
            version: currentModel.version
        )
        
        return ContentProcessorState(
            mlModels: newModels,
            textAnalysisResults: state.textAnalysisResults,
            imageProcessingResults: state.imageProcessingResults,
            speechRecognitionResults: state.speechRecognitionResults,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    // MARK: - Text Processing Operations
    
    private func processText(_ text: String, analysisType: TextAnalysisType, in state: ContentProcessorState) async throws -> ContentProcessorState {
        // Check if we have a suitable model loaded
        let suitableModel = state.mlModels.first { model in
            model.isLoaded && (
                (analysisType == .sentiment && model.modelType == .sentimentAnalysis) ||
                (analysisType == .entityRecognition && model.modelType == .naturalLanguageProcessing) ||
                model.modelType == .textClassification
            )
        }
        
        guard suitableModel != nil else {
            throw ContentProcessorError.modelNotFound("No suitable model loaded for \(analysisType)")
        }
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Create simulated analysis result
        let result = try await createTextAnalysisResult(text: text, analysisType: analysisType)
        
        var newResults = state.textAnalysisResults
        newResults.append(result)
        
        // Keep only recent results (last 100)
        if newResults.count > 100 {
            newResults.removeFirst(newResults.count - 100)
        }
        
        return ContentProcessorState(
            mlModels: state.mlModels,
            textAnalysisResults: newResults,
            imageProcessingResults: state.imageProcessingResults,
            speechRecognitionResults: state.speechRecognitionResults,
            isProcessing: false,
            error: nil
        )
    }
    
    private func createTextAnalysisResult(text: String, analysisType: TextAnalysisType) async throws -> TextAnalysisResult {
        switch analysisType {
        case .sentiment:
            return createSentimentAnalysisResult(text: text)
        case .entityRecognition:
            return createEntityRecognitionResult(text: text)
        case .languageDetection:
            return createLanguageDetectionResult(text: text)
        case .keywordExtraction:
            return createKeywordExtractionResult(text: text)
        default:
            return createGenericAnalysisResult(text: text, analysisType: analysisType)
        }
    }
    
    private func createSentimentAnalysisResult(text: String) -> TextAnalysisResult {
        // Simple sentiment analysis simulation
        let positiveWords = ["good", "great", "excellent", "love", "amazing", "wonderful", "fantastic"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "horrible", "disgusting", "worst"]
        
        let lowercaseText = text.lowercased()
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: word).count - 1
        }
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: word).count - 1
        }
        
        let totalWords = positiveCount + negativeCount
        let sentiment: Sentiment
        let positiveScore: Double
        let negativeScore: Double
        let neutralScore: Double
        
        if totalWords == 0 {
            sentiment = .neutral
            positiveScore = 0.33
            negativeScore = 0.33
            neutralScore = 0.34
        } else {
            positiveScore = Double(positiveCount) / Double(totalWords)
            negativeScore = Double(negativeCount) / Double(totalWords)
            neutralScore = 1.0 - positiveScore - negativeScore
            
            if positiveScore > negativeScore {
                sentiment = .positive
            } else if negativeScore > positiveScore {
                sentiment = .negative
            } else {
                sentiment = .neutral
            }
        }
        
        let sentimentResult = SentimentResult(
            sentiment: sentiment,
            confidence: max(positiveScore, negativeScore, neutralScore),
            positiveScore: positiveScore,
            negativeScore: negativeScore,
            neutralScore: neutralScore
        )
        
        return TextAnalysisResult(
            sourceText: text,
            analysisType: .sentiment,
            sentiment: sentimentResult,
            confidence: sentimentResult.confidence
        )
    }
    
    private func createEntityRecognitionResult(text: String) -> TextAnalysisResult {
        // Simple entity recognition simulation
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        let entities = findEntities(in: text, pattern: emailPattern, category: .email)
        
        return TextAnalysisResult(
            sourceText: text,
            analysisType: .entityRecognition,
            entities: entities,
            confidence: entities.isEmpty ? 0.5 : 0.9
        )
    }
    
    private func createLanguageDetectionResult(text: String) -> TextAnalysisResult {
        // Simple language detection simulation
        let language = text.count > 0 ? "en" : "unknown"
        
        return TextAnalysisResult(
            sourceText: text,
            analysisType: .languageDetection,
            language: language,
            confidence: 0.85
        )
    }
    
    private func createKeywordExtractionResult(text: String) -> TextAnalysisResult {
        // Simple keyword extraction simulation
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let keywords = words.filter { $0.count > 4 }.prefix(5)
        let results = Dictionary(uniqueKeysWithValues: keywords.map { ($0, Double.random(in: 0.5...1.0)) })
        
        return TextAnalysisResult(
            sourceText: text,
            analysisType: .keywordExtraction,
            results: results,
            confidence: 0.75
        )
    }
    
    private func createGenericAnalysisResult(text: String, analysisType: TextAnalysisType) -> TextAnalysisResult {
        return TextAnalysisResult(
            sourceText: text,
            analysisType: analysisType,
            confidence: Double.random(in: 0.6...0.9)
        )
    }
    
    private func findEntities(in text: String, pattern: String, category: EntityCategory) -> [NamedEntity] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            return matches.map { match in
                let matchedText = String(text[Range(match.range, in: text)!])
                return NamedEntity(
                    text: matchedText,
                    range: match.range,
                    category: category,
                    confidence: Double.random(in: 0.7...0.95)
                )
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Image Processing Operations
    
    private func processImage(_ imageId: UUID, processingType: ImageProcessingType, in state: ContentProcessorState) async throws -> ContentProcessorState {
        // Simulate image processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let result = createImageProcessingResult(imageId: imageId, processingType: processingType)
        
        var newResults = state.imageProcessingResults
        newResults.append(result)
        
        // Keep only recent results (last 50)
        if newResults.count > 50 {
            newResults.removeFirst(newResults.count - 50)
        }
        
        return ContentProcessorState(
            mlModels: state.mlModels,
            textAnalysisResults: state.textAnalysisResults,
            imageProcessingResults: newResults,
            speechRecognitionResults: state.speechRecognitionResults,
            isProcessing: false,
            error: nil
        )
    }
    
    private func createImageProcessingResult(imageId: UUID, processingType: ImageProcessingType) -> ImageProcessingResult {
        switch processingType {
        case .classification:
            let classifications = [
                ImageClassification(label: "Object", confidence: 0.92),
                ImageClassification(label: "Scene", confidence: 0.87),
                ImageClassification(label: "Nature", confidence: 0.73)
            ]
            return ImageProcessingResult(
                imageId: imageId,
                processingType: processingType,
                classifications: classifications,
                confidence: 0.90
            )
            
        case .objectDetection:
            let objects = [
                DetectedObject(label: "Person", confidence: 0.95, boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.6)),
                DetectedObject(label: "Car", confidence: 0.88, boundingBox: CGRect(x: 0.1, y: 0.7, width: 0.3, height: 0.2))
            ]
            return ImageProcessingResult(
                imageId: imageId,
                processingType: processingType,
                detectedObjects: objects,
                confidence: 0.91
            )
            
        case .textRecognition:
            return ImageProcessingResult(
                imageId: imageId,
                processingType: processingType,
                extractedText: "Sample extracted text from image",
                confidence: 0.85
            )
            
        default:
            return ImageProcessingResult(
                imageId: imageId,
                processingType: processingType,
                confidence: 0.80
            )
        }
    }
    
    // MARK: - Audio Processing Operations
    
    private func processAudio(_ audioId: UUID, in state: ContentProcessorState) async throws -> ContentProcessorState {
        // Simulate speech recognition
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let result = createSpeechRecognitionResult(audioId: audioId)
        
        var newResults = state.speechRecognitionResults
        newResults.append(result)
        
        // Keep only recent results (last 30)
        if newResults.count > 30 {
            newResults.removeFirst(newResults.count - 30)
        }
        
        return ContentProcessorState(
            mlModels: state.mlModels,
            textAnalysisResults: state.textAnalysisResults,
            imageProcessingResults: state.imageProcessingResults,
            speechRecognitionResults: newResults,
            isProcessing: false,
            error: nil
        )
    }
    
    private func createSpeechRecognitionResult(audioId: UUID) -> SpeechRecognitionResult {
        let sampleTexts = [
            "Hello, this is a test of speech recognition.",
            "The weather today is quite nice.",
            "I need to complete my tasks for today.",
            "Can you help me with this project?",
            "Meeting scheduled for tomorrow at 2 PM."
        ]
        
        let transcribedText = sampleTexts.randomElement() ?? "Could not transcribe audio"
        let segments = createSpeechSegments(for: transcribedText)
        
        return SpeechRecognitionResult(
            audioFileId: audioId,
            transcribedText: transcribedText,
            confidence: Double.random(in: 0.75...0.95),
            language: "en-US",
            duration: Double.random(in: 30...120),
            segments: segments
        )
    }
    
    private func createSpeechSegments(for text: String) -> [SpeechSegment] {
        let words = text.components(separatedBy: " ")
        var segments: [SpeechSegment] = []
        var currentTime: TimeInterval = 0
        
        for word in words {
            let duration = TimeInterval.random(in: 0.3...1.2)
            segments.append(SpeechSegment(
                text: word,
                startTime: currentTime,
                duration: duration,
                confidence: Double.random(in: 0.8...0.98)
            ))
            currentTime += duration
        }
        
        return segments
    }
    
    // MARK: - Result Addition Operations
    
    private func addTextAnalysisResult(_ result: TextAnalysisResult, in state: ContentProcessorState) -> ContentProcessorState {
        var newResults = state.textAnalysisResults
        newResults.append(result)
        
        if newResults.count > 100 {
            newResults.removeFirst(newResults.count - 100)
        }
        
        return ContentProcessorState(
            mlModels: state.mlModels,
            textAnalysisResults: newResults,
            imageProcessingResults: state.imageProcessingResults,
            speechRecognitionResults: state.speechRecognitionResults,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func addImageProcessingResult(_ result: ImageProcessingResult, in state: ContentProcessorState) -> ContentProcessorState {
        var newResults = state.imageProcessingResults
        newResults.append(result)
        
        if newResults.count > 50 {
            newResults.removeFirst(newResults.count - 50)
        }
        
        return ContentProcessorState(
            mlModels: state.mlModels,
            textAnalysisResults: state.textAnalysisResults,
            imageProcessingResults: newResults,
            speechRecognitionResults: state.speechRecognitionResults,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func addSpeechRecognitionResult(_ result: SpeechRecognitionResult, in state: ContentProcessorState) -> ContentProcessorState {
        var newResults = state.speechRecognitionResults
        newResults.append(result)
        
        if newResults.count > 30 {
            newResults.removeFirst(newResults.count - 30)
        }
        
        return ContentProcessorState(
            mlModels: state.mlModels,
            textAnalysisResults: state.textAnalysisResults,
            imageProcessingResults: state.imageProcessingResults,
            speechRecognitionResults: newResults,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func shouldAutoSave(_ action: ContentProcessorAction) -> Bool {
        switch action {
        case .addTextAnalysisResult, .addImageProcessingResult, .addSpeechRecognitionResult:
            return true
        default:
            return false
        }
    }
    
    private func autoSave() async throws {
        try await storageCapability.saveArray(_state.mlModels, to: "models/models.json")
        try await storageCapability.saveArray(_state.textAnalysisResults, to: "content/text_analysis.json")
        try await storageCapability.saveArray(_state.imageProcessingResults, to: "content/image_processing.json")
        try await storageCapability.saveArray(_state.speechRecognitionResults, to: "content/speech_recognition.json")
    }
    
    private func saveStateToHistory(_ state: ContentProcessorState) {
        if currentHistoryIndex < stateHistory.count - 1 {
            stateHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        stateHistory.append(state)
        currentHistoryIndex += 1
        
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    // MARK: - Public Query Methods
    
    public func getLoadedModels() async -> [MLModel] {
        return _state.mlModels.filter { $0.isLoaded }
    }
    
    public func getModelByName(_ name: String) async -> MLModel? {
        return _state.mlModels.first { $0.name == name }
    }
    
    public func getRecentTextAnalysis(for type: TextAnalysisType, limit: Int = 10) async -> [TextAnalysisResult] {
        return _state.textAnalysisResults
            .filter { $0.analysisType == type }
            .sorted { $0.processingDate > $1.processingDate }
            .prefix(limit)
            .map { $0 }
    }
    
    public func getImageProcessingResults(for type: ImageProcessingType) async -> [ImageProcessingResult] {
        return _state.imageProcessingResults.filter { $0.processingType == type }
    }
    
    public func getRecentSpeechRecognition(limit: Int = 5) async -> [SpeechRecognitionResult] {
        return _state.speechRecognitionResults
            .sorted { $0.processingDate > $1.processingDate }
            .prefix(limit)
            .map { $0 }
    }
    
    public func isModelLoaded(_ modelName: String) async -> Bool {
        return _state.mlModels.first { $0.name == modelName }?.isLoaded ?? false
    }
    
    public func getProcessingQueueSize() async -> Int {
        return processingQueue.count
    }
    
    public func getPerformanceMetrics() async -> ContentProcessorClientMetrics {
        return ContentProcessorClientMetrics(
            actionCount: actionCount,
            lastActionTime: lastActionTime,
            stateHistorySize: stateHistory.count,
            currentHistoryIndex: currentHistoryIndex,
            loadedModelCount: _state.mlModels.filter { $0.isLoaded }.count,
            totalModelCount: _state.mlModels.count,
            textAnalysisCount: _state.textAnalysisResults.count,
            imageProcessingCount: _state.imageProcessingResults.count,
            speechRecognitionCount: _state.speechRecognitionResults.count,
            isCurrentlyProcessing: isProcessing
        )
    }
}

private struct ProcessingTask {
    let id: UUID
    let type: ProcessingTaskType
    let createdAt: Date
}

private enum ProcessingTaskType {
    case textAnalysis(String, TextAnalysisType)
    case imageProcessing(UUID, ImageProcessingType)
    case speechRecognition(UUID)
}

public struct ContentProcessorClientMetrics: Sendable, Equatable {
    public let actionCount: Int
    public let lastActionTime: Date?
    public let stateHistorySize: Int
    public let currentHistoryIndex: Int
    public let loadedModelCount: Int
    public let totalModelCount: Int
    public let textAnalysisCount: Int
    public let imageProcessingCount: Int
    public let speechRecognitionCount: Int
    public let isCurrentlyProcessing: Bool
    
    public init(
        actionCount: Int,
        lastActionTime: Date?,
        stateHistorySize: Int,
        currentHistoryIndex: Int,
        loadedModelCount: Int,
        totalModelCount: Int,
        textAnalysisCount: Int,
        imageProcessingCount: Int,
        speechRecognitionCount: Int,
        isCurrentlyProcessing: Bool
    ) {
        self.actionCount = actionCount
        self.lastActionTime = lastActionTime
        self.stateHistorySize = stateHistorySize
        self.currentHistoryIndex = currentHistoryIndex
        self.loadedModelCount = loadedModelCount
        self.totalModelCount = totalModelCount
        self.textAnalysisCount = textAnalysisCount
        self.imageProcessingCount = imageProcessingCount
        self.speechRecognitionCount = speechRecognitionCount
        self.isCurrentlyProcessing = isCurrentlyProcessing
    }
}