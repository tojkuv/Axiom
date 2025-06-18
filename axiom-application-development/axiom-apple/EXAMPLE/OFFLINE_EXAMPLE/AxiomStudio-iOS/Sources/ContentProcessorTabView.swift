import SwiftUI
import AxiomStudio_Shared

struct ContentProcessorTabView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedContentTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedContentTab) {
                MLModelsView()
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("Models")
                    }
                    .tag(0)
                
                TextAnalysisView()
                    .tabItem {
                        Image(systemName: "text.alignleft")
                        Text("Text")
                    }
                    .tag(1)
                
                ImageProcessingView()
                    .tabItem {
                        Image(systemName: "photo")
                        Text("Images")
                    }
                    .tag(2)
                
                SpeechRecognitionView()
                    .tabItem {
                        Image(systemName: "mic")
                        Text("Speech")
                    }
                    .tag(3)
            }
            .navigationTitle("AI Content Processor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Download Models") {
                            // Handle model download
                        }
                        Button("Clear Cache") {
                            // Handle cache clearing
                        }
                        Button("Settings") {
                            // Navigate to AI settings
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct MLModelsView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var mlModels: [MLModel] = []
    @State private var isLoadingModels = false
    
    var body: some View {
        VStack {
            if mlModels.isEmpty && !isLoadingModels {
                EmptyMLModelsView()
            } else {
                List {
                    Section("Available Models") {
                        ForEach(mlModels, id: \.id) { model in
                            MLModelRowView(model: model) {
                                Task {
                                    await toggleModel(model)
                                }
                            }
                        }
                    }
                    
                    Section("Model Performance") {
                        ModelPerformanceView()
                    }
                }
            }
        }
        .refreshable {
            await loadMLModels()
        }
        .onAppear {
            Task {
                await loadMLModels()
            }
        }
    }
    
    private func loadMLModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        
        do {
            try await orchestrator.processAction(.contentProcessor(.loadMLModels))
            let state = await orchestrator.applicationState
            mlModels = state.contentProcessor.availableMLModels
        } catch {
            print("Failed to load ML models: \(error)")
        }
    }
    
    private func toggleModel(_ model: MLModel) async {
        do {
            if model.isLoaded {
                try await orchestrator.processAction(.contentProcessor(.unloadModel(model.id)))
            } else {
                try await orchestrator.processAction(.contentProcessor(.loadModel(model.id)))
            }
            await loadMLModels()
        } catch {
            print("Failed to toggle model: \(error)")
        }
    }
}

struct MLModelRowView: View {
    let model: MLModel
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                
                Text(model.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Size: \(model.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(model.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Toggle("", isOn: .constant(model.isLoaded))
                    .labelsHidden()
                    .onChange(of: model.isLoaded) { _, _ in
                        onToggle()
                    }
                
                if model.isLoaded {
                    Text("Loaded")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyMLModelsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Models Available")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("ML models will appear here once they're downloaded")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh Models") {
                // Handle refresh
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ModelPerformanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.orange)
                
                Text("Performance Metrics")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Inference Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("~45ms")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Memory Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("128 MB")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TextAnalysisView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var inputText = ""
    @State private var analysisResults: [TextAnalysisResult] = []
    @State private var selectedAnalysisType = TextAnalysisType.sentiment
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Input")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis Type")
                    .font(.headline)
                
                Picker("Analysis Type", selection: $selectedAnalysisType) {
                    ForEach(TextAnalysisType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Button(action: {
                Task {
                    await analyzeText()
                }
            }) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isAnalyzing ? "Analyzing..." : "Analyze Text")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
            
            if !analysisResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Analysis Results")
                        .font(.headline)
                    
                    ForEach(analysisResults, id: \.id) { result in
                        TextAnalysisResultView(result: result)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func analyzeText() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            try await orchestrator.processText(inputText, analysisType: selectedAnalysisType)
            let state = await orchestrator.applicationState
            analysisResults = Array(state.contentProcessor.textAnalysisResults.prefix(5))
        } catch {
            print("Failed to analyze text: \(error)")
        }
    }
}

struct TextAnalysisResultView: View {
    let result: TextAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.analysisType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(result.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let confidence = result.confidence {
                HStack {
                    Text("Confidence:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(confidence * 100, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red)
                }
            }
            
            Text(result.summary)
                .font(.subheadline)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct ImageProcessingView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var processingResults: [ImageProcessingResult] = []
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Input")
                    .font(.headline)
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Tap to select image")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                Task {
                    await processImage()
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isProcessing ? "Processing..." : "Process Image")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedImage == nil || isProcessing)
            
            if !processingResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Processing Results")
                        .font(.headline)
                    
                    ForEach(processingResults, id: \.id) { result in
                        ImageProcessingResultView(result: result)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func processImage() async {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // In a real implementation, you'd process the image here
        // For now, create a mock result
        let result = ImageProcessingResult(
            processingType: .objectDetection,
            summary: "Detected: Person (95%), Car (78%), Building (65%)",
            confidence: 0.87,
            metadata: [:],
            processedAt: Date()
        )
        
        processingResults.insert(result, at: 0)
    }
}

struct ImageProcessingResultView: View {
    let result: ImageProcessingResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.processingType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let confidence = result.confidence {
                    Text("\(confidence * 100, specifier: "%.0f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(confidence > 0.8 ? .green : .orange)
                }
            }
            
            Text(result.summary)
                .font(.subheadline)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            
            Text(result.processedAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct SpeechRecognitionView: View {
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var speechResults: [SpeechRecognitionResult] = []
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 20) {
                Text(isRecording ? "Listening..." : "Tap to start recording")
                    .font(.headline)
                    .foregroundColor(isRecording ? .red : .primary)
                
                Button(action: {
                    toggleRecording()
                }) {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 60))
                        .foregroundColor(isRecording ? .red : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            if !recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Recognition")
                        .font(.headline)
                    
                    Text(recognizedText)
                        .font(.body)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
            }
            
            if !speechResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognition History")
                        .font(.headline)
                    
                    ForEach(speechResults, id: \.id) { result in
                        SpeechResultView(result: result)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            // Start speech recognition
            recognizedText = "Starting recognition..."
        } else {
            // Stop speech recognition and save result
            if !recognizedText.isEmpty && recognizedText != "Starting recognition..." {
                let result = SpeechRecognitionResult(
                    recognizedText: recognizedText,
                    confidence: 0.92,
                    duration: 5.3,
                    language: "en-US",
                    recognizedAt: Date()
                )
                speechResults.insert(result, at: 0)
            }
            recognizedText = ""
        }
    }
}

struct SpeechResultView: View {
    let result: SpeechRecognitionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Speech Recognition")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(result.confidence * 100, specifier: "%.0f")%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(result.confidence > 0.8 ? .green : .orange)
            }
            
            Text(result.recognizedText)
                .font(.body)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            
            HStack {
                Text("Duration: \(result.duration, specifier: "%.1f")s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(result.recognizedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}