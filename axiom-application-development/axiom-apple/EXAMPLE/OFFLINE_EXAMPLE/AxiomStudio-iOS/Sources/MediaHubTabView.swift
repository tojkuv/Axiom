import SwiftUI
import UniformTypeIdentifiers
import AxiomStudio_Shared

struct MediaHubTabView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedMediaTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedMediaTab) {
                DocumentBrowserView()
                    .tabItem {
                        Image(systemName: "doc.fill")
                        Text("Documents")
                    }
                    .tag(0)
                
                PhotoLibraryView()
                    .tabItem {
                        Image(systemName: "photo.on.rectangle")
                        Text("Photos")
                    }
                    .tag(1)
                
                AudioRecordingsView()
                    .tabItem {
                        Image(systemName: "waveform")
                        Text("Audio")
                    }
                    .tag(2)
                
                ProcessingQueuesView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Queue")
                    }
                    .tag(3)
            }
            .navigationTitle("Media Hub")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Import Document") {
                            // Handle document import
                        }
                        Button("Record Audio") {
                            // Handle audio recording
                        }
                        Button("Clear Cache") {
                            // Handle cache clearing
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
    }
}

struct DocumentBrowserView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var documents: [DocumentFile] = []
    @State private var showingDocumentPicker = false
    @State private var searchText = ""
    @State private var sortOrder = DocumentSortOrder.dateModified
    
    var filteredDocuments: [DocumentFile] {
        if searchText.isEmpty {
            return documents.sorted(by: sortOrder.comparator)
        } else {
            return documents
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted(by: sortOrder.comparator)
        }
    }
    
    var body: some View {
        VStack {
            if documents.isEmpty {
                EmptyDocumentsView(onImport: {
                    showingDocumentPicker = true
                })
            } else {
                VStack(spacing: 0) {
                    HStack {
                        SearchBar(text: $searchText)
                        
                        Menu {
                            ForEach(DocumentSortOrder.allCases, id: \.self) { order in
                                Button(order.displayName) {
                                    sortOrder = order
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    List {
                        ForEach(filteredDocuments, id: \.id) { document in
                            DocumentRowView(document: document) {
                                Task {
                                    await openDocument(document)
                                }
                            } onDelete: {
                                Task {
                                    await deleteDocument(document)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await loadDocuments()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadDocuments()
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .text, .plainText, .rtf, .rtfd],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await handleDocumentImport(result)
            }
        }
    }
    
    private func loadDocuments() async {
        let state = await orchestrator.applicationState
        documents = state.mediaHub.documents
    }
    
    private func openDocument(_ document: DocumentFile) async {
        // Handle document opening
        print("Opening document: \(document.name)")
    }
    
    private func deleteDocument(_ document: DocumentFile) async {
        do {
            try await orchestrator.processAction(.mediaHub(.deleteDocument(document.id)))
            await loadDocuments()
        } catch {
            print("Failed to delete document: \(error)")
        }
    }
    
    private func handleDocumentImport(_ result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            for url in urls {
                try await orchestrator.importDocument(from: url)
            }
            await loadDocuments()
        } catch {
            print("Failed to import documents: \(error)")
        }
    }
}

enum DocumentSortOrder: CaseIterable {
    case name
    case dateCreated
    case dateModified
    case size
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .dateCreated: return "Date Created"
        case .dateModified: return "Date Modified"
        case .size: return "Size"
        }
    }
    
    var comparator: (DocumentFile, DocumentFile) -> Bool {
        switch self {
        case .name:
            return { $0.name < $1.name }
        case .dateCreated:
            return { $0.createdAt > $1.createdAt }
        case .dateModified:
            return { $0.modifiedAt > $1.modifiedAt }
        case .size:
            return { $0.size > $1.size }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search documents...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct EmptyDocumentsView: View {
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Documents")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Import documents to get started with file management")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Import Documents") {
                onImport()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct DocumentRowView: View {
    let document: DocumentFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: document.fileType.iconName)
                .foregroundColor(document.fileType.color)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(document.formattedSize)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(document.modifiedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            
            Spacer()
            
            Menu {
                Button("Open") {
                    onOpen()
                }
                Button("Share") {
                    // Handle sharing
                }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen()
        }
    }
}

struct PhotoLibraryView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var photos: [PhotoFile] = []
    @State private var showingImagePicker = false
    @State private var selectedPhoto: PhotoFile?
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 2)
    ]
    
    var body: some View {
        VStack {
            if photos.isEmpty {
                EmptyPhotosView(onImport: {
                    showingImagePicker = true
                })
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(photos, id: \.id) { photo in
                            PhotoThumbnailView(photo: photo) {
                                selectedPhoto = photo
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadPhotos()
                }
            }
        }
        .onAppear {
            Task {
                await loadPhotos()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: .constant(nil))
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
    
    private func loadPhotos() async {
        let state = await orchestrator.applicationState
        photos = state.mediaHub.photos
    }
}

struct EmptyPhotosView: View {
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Photos")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add photos to organize and process your images")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Photos") {
                onImport()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoFile
    let onTap: () -> Void
    
    var body: some View {
        AsyncImage(url: photo.url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    ProgressView()
                        .scaleEffect(0.8)
                )
        }
        .frame(width: 100, height: 100)
        .clipped()
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}

struct PhotoDetailView: View {
    let photo: PhotoFile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                AsyncImage(url: photo.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(photo.filename)
                        .font(.headline)
                    
                    HStack {
                        Text("Size: \(photo.formattedSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let location = photo.location {
                        Text("📍 \(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        // Handle sharing
                    }
                }
            }
        }
    }
}

struct AudioRecordingsView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var audioFiles: [AudioFile] = []
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    
    var body: some View {
        VStack {
            RecordingControlsView(
                isRecording: $isRecording,
                duration: recordingDuration,
                onToggleRecording: toggleRecording
            )
            
            if audioFiles.isEmpty {
                EmptyAudioView()
            } else {
                List {
                    ForEach(audioFiles, id: \.id) { audioFile in
                        AudioFileRowView(audioFile: audioFile) {
                            Task {
                                await playAudio(audioFile)
                            }
                        } onDelete: {
                            Task {
                                await deleteAudio(audioFile)
                            }
                        }
                    }
                }
                .refreshable {
                    await loadAudioFiles()
                }
            }
        }
        .onAppear {
            Task {
                await loadAudioFiles()
            }
        }
    }
    
    private func loadAudioFiles() async {
        let state = await orchestrator.applicationState
        audioFiles = state.mediaHub.audioFiles
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }
    
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Create a new audio file record
        Task {
            await saveRecording()
        }
    }
    
    private func saveRecording() async {
        do {
            try await orchestrator.processAction(.mediaHub(.saveAudioRecording(duration: recordingDuration)))
            await loadAudioFiles()
        } catch {
            print("Failed to save recording: \(error)")
        }
    }
    
    private func playAudio(_ audioFile: AudioFile) async {
        // Handle audio playback
        print("Playing audio: \(audioFile.filename)")
    }
    
    private func deleteAudio(_ audioFile: AudioFile) async {
        do {
            try await orchestrator.processAction(.mediaHub(.deleteAudioFile(audioFile.id)))
            await loadAudioFiles()
        } catch {
            print("Failed to delete audio: \(error)")
        }
    }
}

struct RecordingControlsView: View {
    @Binding var isRecording: Bool
    let duration: TimeInterval
    let onToggleRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isRecording ? "Recording..." : "Tap to record")
                .font(.headline)
                .foregroundColor(isRecording ? .red : .primary)
            
            if isRecording {
                Text(String(format: "%.1f seconds", duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onToggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isRecording ? .red : .blue)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding()
    }
}

struct EmptyAudioView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Audio Recordings")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Record audio notes and voice memos")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct AudioFileRowView: View {
    let audioFile: AudioFile
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(audioFile.filename)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(String(format: "%.1f sec", audioFile.duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(audioFile.recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProcessingQueuesView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var processingQueues: [ProcessingQueue] = []
    
    var body: some View {
        VStack {
            if processingQueues.isEmpty {
                EmptyProcessingQueuesView()
            } else {
                List {
                    ForEach(processingQueues, id: \.id) { queue in
                        ProcessingQueueRowView(queue: queue)
                    }
                }
                .refreshable {
                    await loadProcessingQueues()
                }
            }
        }
        .onAppear {
            Task {
                await loadProcessingQueues()
            }
        }
    }
    
    private func loadProcessingQueues() async {
        let state = await orchestrator.applicationState
        processingQueues = state.mediaHub.processingQueues
    }
}

struct EmptyProcessingQueuesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Processing Queues")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("File processing queues will appear here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ProcessingQueueRowView: View {
    let queue: ProcessingQueue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(queue.name)
                    .font(.headline)
                
                Spacer()
                
                Text(queue.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(queue.status.color.opacity(0.2))
                    .foregroundColor(queue.status.color)
                    .cornerRadius(6)
            }
            
            if !queue.items.isEmpty {
                Text("\(queue.items.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if queue.status == .processing {
                    ProgressView(value: queue.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            
            Text(queue.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding(.vertical, 4)
    }
}