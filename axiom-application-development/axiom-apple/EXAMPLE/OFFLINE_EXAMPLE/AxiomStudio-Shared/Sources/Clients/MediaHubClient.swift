import Foundation
import AxiomCore
import AxiomArchitecture

public actor MediaHubClient: AxiomClient {
    public typealias StateType = MediaHubState
    public typealias ActionType = MediaHubAction
    
    private var _state: MediaHubState
    private let storageCapability: LocalFileStorageCapability
    private var stateStreamContinuation: AsyncStream<MediaHubState>.Continuation?
    
    private var stateHistory: [MediaHubState] = []
    private var currentHistoryIndex: Int = -1
    private let maxHistorySize: Int = 50
    
    private var actionCount: Int = 0
    private var lastActionTime: Date?
    private var isRecording: Bool = false
    
    public init(
        storageCapability: LocalFileStorageCapability,
        initialState: MediaHubState = MediaHubState()
    ) {
        self._state = initialState
        self.storageCapability = storageCapability
        
        self.stateHistory = [initialState]
        self.currentHistoryIndex = 0
    }
    
    public var stateStream: AsyncStream<MediaHubState> {
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
    
    private func setStreamContinuation(_ continuation: AsyncStream<MediaHubState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func process(_ action: MediaHubAction) async throws {
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
    
    public func getCurrentState() async -> MediaHubState {
        return _state
    }
    
    public func rollbackToState(_ state: MediaHubState) async {
        let oldState = _state
        _state = state
        stateStreamContinuation?.yield(state)
        await stateDidUpdate(from: oldState, to: state)
    }
    
    private func processAction(_ action: MediaHubAction, currentState: MediaHubState) async throws -> MediaHubState {
        switch action {
        case .loadDocuments:
            return try await loadDocuments(in: currentState)
            
        case .loadPhotos:
            return try await loadPhotos(in: currentState)
            
        case .loadAudioFiles:
            return try await loadAudioFiles(in: currentState)
            
        case .importDocument(let url):
            return try await importDocument(from: url, in: currentState)
            
        case .importPhoto(let url):
            return try await importPhoto(from: url, in: currentState)
            
        case .recordAudio:
            return try await startAudioRecording(in: currentState)
            
        case .stopRecording:
            return try await stopAudioRecording(in: currentState)
            
        case .processDocument(let documentId):
            return try await processDocument(documentId, in: currentState)
            
        case .processPhoto(let photoId):
            return try await processPhoto(photoId, in: currentState)
            
        case .processAudio(let audioId):
            return try await processAudio(audioId, in: currentState)
            
        case .addDocument(let document):
            return addDocument(document, in: currentState)
            
        case .addPhoto(let photo):
            return addPhoto(photo, in: currentState)
            
        case .addAudioFile(let audioFile):
            return addAudioFile(audioFile, in: currentState)
            
        case .updateProcessingQueue(let queue):
            return updateProcessingQueue(queue, in: currentState)
            
        case .setProcessing(let isProcessing):
            return MediaHubState(
                documents: currentState.documents,
                photos: currentState.photos,
                audioFiles: currentState.audioFiles,
                processingQueues: currentState.processingQueues,
                isProcessing: isProcessing,
                error: currentState.error
            )
            
        case .setError(let error):
            return MediaHubState(
                documents: currentState.documents,
                photos: currentState.photos,
                audioFiles: currentState.audioFiles,
                processingQueues: currentState.processingQueues,
                isProcessing: currentState.isProcessing,
                error: error
            )
        }
    }
    
    // MARK: - Load Operations
    
    private func loadDocuments(in state: MediaHubState) async throws -> MediaHubState {
        do {
            let documents = try await storageCapability.loadArray(Document.self, from: "documents/documents.json")
            return MediaHubState(
                documents: documents,
                photos: state.photos,
                audioFiles: state.audioFiles,
                processingQueues: state.processingQueues,
                isProcessing: false,
                error: nil
            )
        } catch {
            return MediaHubState(
                documents: state.documents,
                photos: state.photos,
                audioFiles: state.audioFiles,
                processingQueues: state.processingQueues,
                isProcessing: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func loadPhotos(in state: MediaHubState) async throws -> MediaHubState {
        do {
            let photos = try await storageCapability.loadArray(Photo.self, from: "photos/photos.json")
            return MediaHubState(
                documents: state.documents,
                photos: photos,
                audioFiles: state.audioFiles,
                processingQueues: state.processingQueues,
                isProcessing: false,
                error: nil
            )
        } catch {
            return MediaHubState(
                documents: state.documents,
                photos: state.photos,
                audioFiles: state.audioFiles,
                processingQueues: state.processingQueues,
                isProcessing: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func loadAudioFiles(in state: MediaHubState) async throws -> MediaHubState {
        do {
            let audioFiles = try await storageCapability.loadArray(AudioFile.self, from: "audio/audio_files.json")
            return MediaHubState(
                documents: state.documents,
                photos: state.photos,
                audioFiles: audioFiles,
                processingQueues: state.processingQueues,
                isProcessing: false,
                error: nil
            )
        } catch {
            return MediaHubState(
                documents: state.documents,
                photos: state.photos,
                audioFiles: state.audioFiles,
                processingQueues: state.processingQueues,
                isProcessing: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    // MARK: - Import Operations
    
    private func importDocument(from url: URL, in state: MediaHubState) async throws -> MediaHubState {
        // Simulate document import
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        guard url.isFileURL else {
            throw MediaHubError.fileAccessDenied(url.absoluteString)
        }
        
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        let documentType: DocumentType
        switch fileExtension {
        case "pdf": documentType = .pdf
        case "txt", "md": documentType = .text
        case "doc", "docx": documentType = .word
        case "xls", "xlsx": documentType = .excel
        case "ppt", "pptx": documentType = .powerpoint
        case "jpg", "jpeg", "png", "gif": documentType = .image
        case "mp3", "wav", "m4a": documentType = .audio
        case "mp4", "mov", "avi": documentType = .video
        case "zip", "rar", "tar": documentType = .archive
        default: documentType = .other
        }
        
        let document = Document(
            fileName: fileName,
            filePath: url.path,
            fileType: documentType,
            fileSize: getFileSize(at: url)
        )
        
        var newDocuments = state.documents
        newDocuments.append(document)
        
        return MediaHubState(
            documents: newDocuments,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: state.processingQueues,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func importPhoto(from url: URL, in state: MediaHubState) async throws -> MediaHubState {
        // Simulate photo import
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard url.isFileURL else {
            throw MediaHubError.fileAccessDenied(url.absoluteString)
        }
        
        let fileName = url.lastPathComponent
        let dimensions = getImageDimensions(at: url)
        
        let photo = Photo(
            fileName: fileName,
            filePath: url.path,
            width: dimensions.width,
            height: dimensions.height,
            fileSize: getFileSize(at: url)
        )
        
        var newPhotos = state.photos
        newPhotos.append(photo)
        
        return MediaHubState(
            documents: state.documents,
            photos: newPhotos,
            audioFiles: state.audioFiles,
            processingQueues: state.processingQueues,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    // MARK: - Recording Operations
    
    private func startAudioRecording(in state: MediaHubState) async throws -> MediaHubState {
        guard !isRecording else {
            throw MediaHubError.processingFailed("Already recording")
        }
        
        isRecording = true
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: state.processingQueues,
            isProcessing: true,
            error: nil
        )
    }
    
    private func stopAudioRecording(in state: MediaHubState) async throws -> MediaHubState {
        guard isRecording else {
            throw MediaHubError.processingFailed("Not currently recording")
        }
        
        isRecording = false
        
        // Simulate creating recorded audio file
        let audioFile = AudioFile(
            fileName: "Recording_\(Date().timeIntervalSince1970).m4a",
            filePath: "/recordings/recording_\(UUID().uuidString).m4a",
            duration: Double.random(in: 10...300),
            fileSize: Int64.random(in: 1024...10485760),
            format: .m4a
        )
        
        var newAudioFiles = state.audioFiles
        newAudioFiles.append(audioFile)
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: newAudioFiles,
            processingQueues: state.processingQueues,
            isProcessing: false,
            error: nil
        )
    }
    
    // MARK: - Processing Operations
    
    private func processDocument(_ documentId: UUID, in state: MediaHubState) async throws -> MediaHubState {
        guard let document = state.documents.first(where: { $0.id == documentId }) else {
            throw MediaHubError.fileNotFound("Document not found")
        }
        
        // Simulate document processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let processingQueue = createProcessingQueue(for: document)
        
        var newQueues = state.processingQueues
        newQueues.append(processingQueue)
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: newQueues,
            isProcessing: true,
            error: nil
        )
    }
    
    private func processPhoto(_ photoId: UUID, in state: MediaHubState) async throws -> MediaHubState {
        guard let photo = state.photos.first(where: { $0.id == photoId }) else {
            throw MediaHubError.fileNotFound("Photo not found")
        }
        
        // Simulate photo processing
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let processingQueue = createProcessingQueue(for: photo)
        
        var newQueues = state.processingQueues
        newQueues.append(processingQueue)
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: newQueues,
            isProcessing: true,
            error: nil
        )
    }
    
    private func processAudio(_ audioId: UUID, in state: MediaHubState) async throws -> MediaHubState {
        guard let audioFile = state.audioFiles.first(where: { $0.id == audioId }) else {
            throw MediaHubError.fileNotFound("Audio file not found")
        }
        
        // Simulate audio processing
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let processingQueue = createProcessingQueue(for: audioFile)
        
        var newQueues = state.processingQueues
        newQueues.append(processingQueue)
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: newQueues,
            isProcessing: true,
            error: nil
        )
    }
    
    // MARK: - Add Operations
    
    private func addDocument(_ document: Document, in state: MediaHubState) -> MediaHubState {
        var newDocuments = state.documents
        newDocuments.append(document)
        
        return MediaHubState(
            documents: newDocuments,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: state.processingQueues,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func addPhoto(_ photo: Photo, in state: MediaHubState) -> MediaHubState {
        var newPhotos = state.photos
        newPhotos.append(photo)
        
        return MediaHubState(
            documents: state.documents,
            photos: newPhotos,
            audioFiles: state.audioFiles,
            processingQueues: state.processingQueues,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func addAudioFile(_ audioFile: AudioFile, in state: MediaHubState) -> MediaHubState {
        var newAudioFiles = state.audioFiles
        newAudioFiles.append(audioFile)
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: newAudioFiles,
            processingQueues: state.processingQueues,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    private func updateProcessingQueue(_ queue: ProcessingQueue, in state: MediaHubState) -> MediaHubState {
        var newQueues = state.processingQueues
        
        if let index = newQueues.firstIndex(where: { $0.id == queue.id }) {
            newQueues[index] = queue
        } else {
            newQueues.append(queue)
        }
        
        return MediaHubState(
            documents: state.documents,
            photos: state.photos,
            audioFiles: state.audioFiles,
            processingQueues: newQueues,
            isProcessing: state.isProcessing,
            error: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return Int64.random(in: 1024...10485760) // Random size between 1KB and 10MB
        }
    }
    
    private func getImageDimensions(at url: URL) -> (width: Int, height: Int) {
        // Simulate image dimension detection
        return (width: Int.random(in: 800...4000), height: Int.random(in: 600...3000))
    }
    
    private func createProcessingQueue(for document: Document) -> ProcessingQueue {
        let items = [
            ProcessingItem(
                sourceId: document.id,
                processingType: .documentIndexing,
                status: .pending
            )
        ]
        
        return ProcessingQueue(
            name: "Document Processing: \(document.fileName)",
            queueType: .documentProcessing,
            items: items,
            status: .processing
        )
    }
    
    private func createProcessingQueue(for photo: Photo) -> ProcessingQueue {
        let items = [
            ProcessingItem(
                sourceId: photo.id,
                processingType: .imageClassification,
                status: .pending
            )
        ]
        
        return ProcessingQueue(
            name: "Photo Processing: \(photo.fileName ?? "Unknown")",
            queueType: .imageProcessing,
            items: items,
            status: .processing
        )
    }
    
    private func createProcessingQueue(for audioFile: AudioFile) -> ProcessingQueue {
        let items = [
            ProcessingItem(
                sourceId: audioFile.id,
                processingType: .speechTranscription,
                status: .pending
            )
        ]
        
        return ProcessingQueue(
            name: "Audio Processing: \(audioFile.fileName)",
            queueType: .speechRecognition,
            items: items,
            status: .processing
        )
    }
    
    private func shouldAutoSave(_ action: MediaHubAction) -> Bool {
        switch action {
        case .addDocument, .addPhoto, .addAudioFile, .importDocument, .importPhoto:
            return true
        default:
            return false
        }
    }
    
    private func autoSave() async throws {
        try await storageCapability.saveArray(_state.documents, to: "documents/documents.json")
        try await storageCapability.saveArray(_state.photos, to: "photos/photos.json")
        try await storageCapability.saveArray(_state.audioFiles, to: "audio/audio_files.json")
        try await storageCapability.saveArray(_state.processingQueues, to: "processing/queues.json")
    }
    
    private func saveStateToHistory(_ state: MediaHubState) {
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
    
    public func getDocumentsByType(_ type: DocumentType) async -> [Document] {
        return _state.documents.filter { $0.fileType == type }
    }
    
    public func getRecentDocuments(limit: Int = 10) async -> [Document] {
        return _state.documents
            .sorted { $0.createdDate > $1.createdDate }
            .prefix(limit)
            .map { $0 }
    }
    
    public func getPhotosByTag(_ tag: String) async -> [Photo] {
        return _state.photos.filter { $0.tags.contains(tag) }
    }
    
    public func getAudioFilesByFormat(_ format: AudioFormat) async -> [AudioFile] {
        return _state.audioFiles.filter { $0.format == format }
    }
    
    public func getActiveProcessingQueues() async -> [ProcessingQueue] {
        return _state.processingQueues.filter { $0.status == .processing }
    }
    
    public func getTotalFileSize() async -> Int64 {
        let documentSize = _state.documents.reduce(0) { $0 + $1.fileSize }
        let photoSize = _state.photos.reduce(0) { $0 + $1.fileSize }
        let audioSize = _state.audioFiles.reduce(0) { $0 + $1.fileSize }
        return documentSize + photoSize + audioSize
    }
    
    public func searchFiles(query: String) async -> (documents: [Document], photos: [Photo], audioFiles: [AudioFile]) {
        let lowercaseQuery = query.lowercased()
        
        let matchingDocuments = _state.documents.filter { document in
            document.fileName.lowercased().contains(lowercaseQuery) ||
            document.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
        
        let matchingPhotos = _state.photos.filter { photo in
            photo.fileName?.lowercased().contains(lowercaseQuery) == true ||
            photo.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
        
        let matchingAudioFiles = _state.audioFiles.filter { audioFile in
            audioFile.fileName.lowercased().contains(lowercaseQuery) ||
            audioFile.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
        
        return (documents: matchingDocuments, photos: matchingPhotos, audioFiles: matchingAudioFiles)
    }
    
    public func isCurrentlyRecording() async -> Bool {
        return isRecording
    }
    
    public func getPerformanceMetrics() async -> MediaHubClientMetrics {
        return MediaHubClientMetrics(
            actionCount: actionCount,
            lastActionTime: lastActionTime,
            stateHistorySize: stateHistory.count,
            currentHistoryIndex: currentHistoryIndex,
            documentCount: _state.documents.count,
            photoCount: _state.photos.count,
            audioFileCount: _state.audioFiles.count,
            processingQueueCount: _state.processingQueues.count,
            totalFileSize: await getTotalFileSize(),
            isCurrentlyRecording: isRecording
        )
    }
}

public struct MediaHubClientMetrics: Sendable, Equatable {
    public let actionCount: Int
    public let lastActionTime: Date?
    public let stateHistorySize: Int
    public let currentHistoryIndex: Int
    public let documentCount: Int
    public let photoCount: Int
    public let audioFileCount: Int
    public let processingQueueCount: Int
    public let totalFileSize: Int64
    public let isCurrentlyRecording: Bool
    
    public init(
        actionCount: Int,
        lastActionTime: Date?,
        stateHistorySize: Int,
        currentHistoryIndex: Int,
        documentCount: Int,
        photoCount: Int,
        audioFileCount: Int,
        processingQueueCount: Int,
        totalFileSize: Int64,
        isCurrentlyRecording: Bool
    ) {
        self.actionCount = actionCount
        self.lastActionTime = lastActionTime
        self.stateHistorySize = stateHistorySize
        self.currentHistoryIndex = currentHistoryIndex
        self.documentCount = documentCount
        self.photoCount = photoCount
        self.audioFileCount = audioFileCount
        self.processingQueueCount = processingQueueCount
        self.totalFileSize = totalFileSize
        self.isCurrentlyRecording = isCurrentlyRecording
    }
}