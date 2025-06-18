import Foundation

public struct TestDataFactory {
    
    public static func createTestTask(
        id: UUID = UUID(),
        title: String = "Test Task",
        description: String? = "Test Description",
        priority: TaskPriority = .medium,
        category: TaskCategory = .general,
        status: TaskStatus = .pending,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> StudioTask {
        return StudioTask(
            id: id,
            title: title,
            description: description,
            priority: priority,
            category: category,
            status: status,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    public static func createTestTasks(count: Int = 5) -> [StudioTask] {
        let priorities: [TaskPriority] = [.low, .medium, .high, .critical, .medium]
        let categories: [TaskCategory] = [.general, .work, .personal, .health, .learning]
        
        return (0..<count).map { index in
            createTestTask(
                title: "Test Task \(index + 1)",
                priority: priorities[index % priorities.count],
                category: categories[index % categories.count]
            )
        }
    }
    
    public static func createTestContact(
        id: UUID = UUID(),
        identifier: String = UUID().uuidString,
        givenName: String = "John",
        familyName: String = "Doe",
        organizationName: String? = nil
    ) -> Contact {
        return Contact(
            id: id,
            identifier: identifier,
            givenName: givenName,
            familyName: familyName,
            organizationName: organizationName,
            phoneNumbers: [PhoneNumber(value: "+1234567890", label: "mobile")],
            emailAddresses: [EmailAddress(value: "\(givenName.lowercased()).\(familyName.lowercased())@example.com", label: "work")]
        )
    }
    
    public static func createTestContacts(count: Int = 3) -> [Contact] {
        let firstNames = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank"]
        let lastNames = ["Doe", "Smith", "Johnson", "Brown", "Wilson", "Garcia", "Miller", "Davis"]
        
        return (0..<count).map { index in
            let firstName = firstNames[index % firstNames.count]
            let lastName = lastNames[index % lastNames.count]
            return createTestContact(
                givenName: firstName,
                familyName: lastName
            )
        }
    }
    
    public static func createTestCalendarEvent(
        id: String = UUID().uuidString,
        title: String = "Test Event",
        startDate: Date = Date(),
        endDate: Date? = nil,
        calendarTitle: String = "Test Calendar",
        calendarIdentifier: String = "test-calendar"
    ) -> CalendarEvent {
        let actualEndDate = endDate ?? startDate.addingTimeInterval(3600)
        
        return CalendarEvent(
            id: id,
            title: title,
            startDate: startDate,
            endDate: actualEndDate,
            calendarTitle: calendarTitle,
            calendarIdentifier: calendarIdentifier
        )
    }
    
    public static func createTestHealthMetric(
        type: HealthMetricType = .stepCount,
        value: Double = 1000,
        unit: String = "count",
        date: Date = Date()
    ) -> HealthMetric {
        return HealthMetric(
            type: type,
            value: value,
            unit: unit,
            date: date
        )
    }
    
    public static func createTestLocationData(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        timestamp: Date = Date()
    ) -> LocationData {
        return LocationData(
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: 5.0,
            timestamp: timestamp,
            locationName: "Test Location"
        )
    }
    
    public static func createTestDocument(
        fileName: String = "test-document.pdf",
        fileType: DocumentType = .pdf,
        fileSize: Int64 = 1024
    ) -> Document {
        return Document(
            fileName: fileName,
            filePath: "/test/path/\(fileName)",
            fileType: fileType,
            fileSize: fileSize
        )
    }
    
    public static func createTestPhoto(
        fileName: String = "test-photo.jpg",
        width: Int = 1920,
        height: Int = 1080,
        fileSize: Int64 = 2048
    ) -> Photo {
        return Photo(
            fileName: fileName,
            filePath: "/test/photos/\(fileName)",
            width: width,
            height: height,
            fileSize: fileSize
        )
    }
    
    public static func createTestAudioFile(
        fileName: String = "test-audio.m4a",
        duration: TimeInterval = 60.0,
        fileSize: Int64 = 512,
        format: AudioFormat = .m4a
    ) -> AudioFile {
        return AudioFile(
            fileName: fileName,
            filePath: "/test/audio/\(fileName)",
            duration: duration,
            fileSize: fileSize,
            format: format
        )
    }
    
    public static func createTestMLModel(
        name: String = "TestModel",
        modelType: MLModelType = .textClassification,
        filePath: String = "/test/models/TestModel.mlmodel"
    ) -> MLModel {
        return MLModel(
            name: name,
            modelType: modelType,
            filePath: filePath,
            isLoaded: true,
            accuracy: 0.95
        )
    }
    
    public static func createTestTextAnalysisResult(
        sourceText: String = "This is a test text",
        analysisType: TextAnalysisType = .sentiment,
        confidence: Double = 0.9
    ) -> TextAnalysisResult {
        return TextAnalysisResult(
            sourceText: sourceText,
            analysisType: analysisType,
            sentiment: SentimentResult(
                sentiment: .positive,
                confidence: confidence,
                positiveScore: 0.8,
                negativeScore: 0.1,
                neutralScore: 0.1
            ),
            confidence: confidence
        )
    }
    
    public static func createTestPerformanceMetric(
        metricType: PerformanceMetricType = .memoryUsage,
        value: Double = 50.0,
        unit: String = "MB"
    ) -> PerformanceMetric {
        return PerformanceMetric(
            metricType: metricType,
            value: value,
            unit: unit
        )
    }
    
    public static func createTestMemoryUsage(
        totalMemory: UInt64 = 4_000_000_000,
        usedMemory: UInt64 = 2_000_000_000,
        appMemoryUsage: UInt64 = 100_000_000
    ) -> MemoryUsage {
        return MemoryUsage(
            totalMemory: totalMemory,
            usedMemory: usedMemory,
            freeMemory: totalMemory - usedMemory,
            appMemoryUsage: appMemoryUsage
        )
    }
    
    public static func createTestApplicationState() -> StudioApplicationState {
        return StudioApplicationState(
            personalInfo: PersonalInfoState(
                tasks: createTestTasks(count: 3),
                contacts: createTestContacts(count: 2)
            ),
            healthLocation: HealthLocationState(
                healthMetrics: [createTestHealthMetric()],
                locationData: [createTestLocationData()]
            ),
            contentProcessor: ContentProcessorState(
                mlModels: [createTestMLModel()],
                textAnalysisResults: [createTestTextAnalysisResult()]
            ),
            mediaHub: MediaHubState(
                documents: [createTestDocument()],
                photos: [createTestPhoto()],
                audioFiles: [createTestAudioFile()]
            ),
            performance: PerformanceState(
                memoryUsage: createTestMemoryUsage(),
                performanceMetrics: [createTestPerformanceMetric()]
            )
        )
    }
}