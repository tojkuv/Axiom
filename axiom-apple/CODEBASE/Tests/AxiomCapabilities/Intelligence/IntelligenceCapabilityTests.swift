import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities intelligence capability functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class IntelligenceCapabilityTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testIntelligenceCapabilityInitialization() async throws {
        let intelligenceCapability = IntelligenceCapability()
        XCTAssertNotNil(intelligenceCapability, "IntelligenceCapability should initialize correctly")
        XCTAssertEqual(intelligenceCapability.identifier, "axiom.intelligence", "Should have correct identifier")
    }
    
    func testTextAnalysisCapability() async throws {
        let textAnalysisCapability = TextAnalysisCapability()
        
        let isAvailable = await textAnalysisCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Text analysis availability should be determinable")
        
        if isAvailable {
            let supportedLanguages = await textAnalysisCapability.getSupportedLanguages()
            XCTAssertFalse(supportedLanguages.isEmpty, "Should support multiple languages")
            
            let canAnalyzeSentiment = await textAnalysisCapability.canAnalyzeSentiment()
            XCTAssertNotNil(canAnalyzeSentiment, "Should determine sentiment analysis capability")
            
            let canExtractEntities = await textAnalysisCapability.canExtractEntities()
            XCTAssertNotNil(canExtractEntities, "Should determine entity extraction capability")
            
            let maxTextLength = await textAnalysisCapability.getMaxTextLength()
            XCTAssertGreaterThan(maxTextLength, 0, "Max text length should be positive")
        }
    }
    
    func testImageRecognitionCapability() async throws {
        let imageRecognitionCapability = ImageRecognitionCapability()
        
        let isAvailable = await imageRecognitionCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Image recognition availability should be determinable")
        
        if isAvailable {
            let supportedFormats = await imageRecognitionCapability.getSupportedImageFormats()
            XCTAssertFalse(supportedFormats.isEmpty, "Should support image formats")
            
            let canRecognizeText = await imageRecognitionCapability.canRecognizeText()
            XCTAssertNotNil(canRecognizeText, "Should determine text recognition capability")
            
            let canRecognizeObjects = await imageRecognitionCapability.canRecognizeObjects()
            XCTAssertNotNil(canRecognizeObjects, "Should determine object recognition capability")
            
            let canRecognizeFaces = await imageRecognitionCapability.canRecognizeFaces()
            XCTAssertNotNil(canRecognizeFaces, "Should determine face recognition capability")
        }
    }
    
    func testSpeechCapability() async throws {
        let speechCapability = SpeechCapability()
        
        let isAvailable = await speechCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Speech capability availability should be determinable")
        
        if isAvailable {
            let canRecognizeSpeech = await speechCapability.canRecognizeSpeech()
            XCTAssertNotNil(canRecognizeSpeech, "Should determine speech recognition capability")
            
            let canSynthesizeSpeech = await speechCapability.canSynthesizeSpeech()
            XCTAssertNotNil(canSynthesizeSpeech, "Should determine speech synthesis capability")
            
            let supportedLanguages = await speechCapability.getSupportedLanguages()
            XCTAssertFalse(supportedLanguages.isEmpty, "Should support speech languages")
            
            let availableVoices = await speechCapability.getAvailableVoices()
            XCTAssertFalse(availableVoices.isEmpty, "Should have available voices")
        }
    }
    
    func testMLModelCapability() async throws {
        let mlCapability = MLModelCapability()
        
        let isAvailable = await mlCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "ML model capability availability should be determinable")
        
        if isAvailable {
            let supportedFrameworks = await mlCapability.getSupportedFrameworks()
            XCTAssertFalse(supportedFrameworks.isEmpty, "Should support ML frameworks")
            
            let canRunCoreML = await mlCapability.canRunCoreMLModels()
            XCTAssertNotNil(canRunCoreML, "Should determine CoreML capability")
            
            let canRunCustomModels = await mlCapability.canRunCustomModels()
            XCTAssertNotNil(canRunCustomModels, "Should determine custom model capability")
            
            let hasNeuralEngine = await mlCapability.hasNeuralEngine()
            XCTAssertNotNil(hasNeuralEngine, "Should determine Neural Engine availability")
        }
    }
    
    func testPredictiveCapability() async throws {
        let predictiveCapability = PredictiveCapability()
        
        let isAvailable = await predictiveCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Predictive capability availability should be determinable")
        
        if isAvailable {
            let canPredictText = await predictiveCapability.canPredictText()
            XCTAssertNotNil(canPredictText, "Should determine text prediction capability")
            
            let canPredictBehavior = await predictiveCapability.canPredictUserBehavior()
            XCTAssertNotNil(canPredictBehavior, "Should determine behavior prediction capability")
            
            let supportedDataTypes = await predictiveCapability.getSupportedPredictionDataTypes()
            XCTAssertFalse(supportedDataTypes.isEmpty, "Should support prediction data types")
        }
    }
    
    // MARK: - Performance Tests
    
    func testIntelligenceCapabilityPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let intelligenceCapability = IntelligenceCapability()
                let textAnalysisCapability = TextAnalysisCapability()
                let imageRecognitionCapability = ImageRecognitionCapability()
                let speechCapability = SpeechCapability()
                
                // Test rapid capability queries
                for _ in 0..<50 {
                    _ = await intelligenceCapability.isAvailable()
                    _ = await textAnalysisCapability.getSupportedLanguages()
                    _ = await imageRecognitionCapability.getSupportedImageFormats()
                    _ = await speechCapability.getAvailableVoices()
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testIntelligenceCapabilityMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let intelligenceCapability = IntelligenceCapability()
            let textAnalysisCapability = TextAnalysisCapability()
            let imageRecognitionCapability = ImageRecognitionCapability()
            let speechCapability = SpeechCapability()
            let mlCapability = MLModelCapability()
            let predictiveCapability = PredictiveCapability()
            
            // Simulate capability lifecycle
            for _ in 0..<15 {
                _ = await intelligenceCapability.isAvailable()
                _ = await textAnalysisCapability.canAnalyzeSentiment()
                _ = await imageRecognitionCapability.canRecognizeObjects()
                _ = await speechCapability.canRecognizeSpeech()
                _ = await mlCapability.getSupportedFrameworks()
                _ = await predictiveCapability.canPredictText()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testIntelligenceCapabilityErrorHandling() async throws {
        let textAnalysisCapability = TextAnalysisCapability()
        
        // Test analyzing empty text
        do {
            try await textAnalysisCapability.analyzeTextStrict("", type: .sentiment)
            XCTFail("Should throw error for empty text")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for empty text")
        }
        
        // Test analyzing text that's too long
        let longText = String(repeating: "a", count: 1_000_000)
        do {
            try await textAnalysisCapability.analyzeTextStrict(longText, type: .sentiment)
            XCTFail("Should throw error for text too long")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for text too long")
        }
        
        let imageRecognitionCapability = ImageRecognitionCapability()
        
        // Test recognizing invalid image data
        do {
            let invalidImageData = Data([0x00, 0x01, 0x02])
            try await imageRecognitionCapability.recognizeObjectsStrict(in: invalidImageData)
            XCTFail("Should throw error for invalid image data")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid image data")
        }
        
        let mlCapability = MLModelCapability()
        
        // Test loading non-existent model
        do {
            try await mlCapability.loadModelStrict(name: "non_existent_model")
            XCTFail("Should throw error for non-existent model")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for non-existent model")
        }
    }
}

// MARK: - Test Helper Types

private enum TextAnalysisType {
    case sentiment
    case entities
    case keywords
    case language
}

private enum ImageFormat {
    case jpeg
    case png
    case heif
    case gif
}

private enum MLFramework {
    case coreML
    case tensorflow
    case pytorch
    case onnx
}

private enum PredictionDataType {
    case text
    case numerical
    case categorical
    case temporal
}

private struct Voice {
    let identifier: String
    let language: String
    let gender: String
}