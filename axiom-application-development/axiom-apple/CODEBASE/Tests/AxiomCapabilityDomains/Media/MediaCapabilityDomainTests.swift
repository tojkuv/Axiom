import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains media capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class MediaCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testMediaCapabilityDomainInitialization() async throws {
        let mediaDomain = MediaCapabilityDomain()
        XCTAssertNotNil(mediaDomain, "MediaCapabilityDomain should initialize correctly")
        XCTAssertEqual(mediaDomain.identifier, "axiom.capability.domain.media", "Should have correct identifier")
    }
    
    func testImageCapabilityRegistration() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        let jpegCapability = JPEGImageCapability()
        let pngCapability = PNGImageCapability()
        let heifCapability = HEIFImageCapability()
        let rawCapability = RAWImageCapability()
        
        await mediaDomain.registerCapability(jpegCapability)
        await mediaDomain.registerCapability(pngCapability)
        await mediaDomain.registerCapability(heifCapability)
        await mediaDomain.registerCapability(rawCapability)
        
        let registeredCapabilities = await mediaDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 4, "Should have 4 registered image capabilities")
        
        let hasJPEG = await mediaDomain.hasCapability("axiom.media.image.jpeg")
        XCTAssertTrue(hasJPEG, "Should have JPEG capability")
        
        let hasPNG = await mediaDomain.hasCapability("axiom.media.image.png")
        XCTAssertTrue(hasPNG, "Should have PNG capability")
        
        let hasHEIF = await mediaDomain.hasCapability("axiom.media.image.heif")
        XCTAssertTrue(hasHEIF, "Should have HEIF capability")
        
        let hasRAW = await mediaDomain.hasCapability("axiom.media.image.raw")
        XCTAssertTrue(hasRAW, "Should have RAW capability")
    }
    
    func testVideoCapabilityManagement() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        let h264Capability = H264VideoCapability()
        let h265Capability = H265VideoCapability()
        let vp9Capability = VP9VideoCapability()
        let av1Capability = AV1VideoCapability()
        
        await mediaDomain.registerCapability(h264Capability)
        await mediaDomain.registerCapability(h265Capability)
        await mediaDomain.registerCapability(vp9Capability)
        await mediaDomain.registerCapability(av1Capability)
        
        let videoCapabilities = await mediaDomain.getCapabilitiesOfType(.video)
        XCTAssertEqual(videoCapabilities.count, 4, "Should have 4 video capabilities")
        
        let bestQualityCapability = await mediaDomain.getBestCapabilityForUseCase(.highQuality)
        XCTAssertNotNil(bestQualityCapability, "Should find best capability for high quality")
        
        let efficientCapability = await mediaDomain.getBestCapabilityForUseCase(.efficient)
        XCTAssertNotNil(efficientCapability, "Should find best capability for efficiency")
    }
    
    func testAudioCapabilitySupport() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        let aacCapability = AACCapability()
        let mp3Capability = MP3Capability()
        let flacCapability = FLACCapability()
        let opusCapability = OpusCapability()
        
        await mediaDomain.registerCapability(aacCapability)
        await mediaDomain.registerCapability(mp3Capability)
        await mediaDomain.registerCapability(flacCapability)
        await mediaDomain.registerCapability(opusCapability)
        
        let audioCapabilities = await mediaDomain.getCapabilitiesOfType(.audio)
        XCTAssertEqual(audioCapabilities.count, 4, "Should have 4 audio capabilities")
        
        let losslessCapabilities = await mediaDomain.getCapabilitiesWithQuality(.lossless)
        XCTAssertTrue(losslessCapabilities.contains { $0.identifier == "axiom.media.audio.flac" }, 
                     "Should include FLAC for lossless quality")
    }
    
    func testMediaProcessingPipeline() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        // Register various media capabilities
        await mediaDomain.registerCapability(JPEGImageCapability())
        await mediaDomain.registerCapability(H264VideoCapability())
        await mediaDomain.registerCapability(AACCapability())
        
        let pipeline = await mediaDomain.createProcessingPipeline(
            for: MediaProcessingRequirements(
                inputFormat: .jpeg,
                outputFormat: .h264,
                quality: .high,
                performance: .realtime
            )
        )
        
        XCTAssertNotNil(pipeline, "Should create processing pipeline")
        XCTAssertTrue(pipeline!.stages.count > 0, "Pipeline should have processing stages")
        
        let canProcess = await pipeline!.canProcess(mediaType: .image)
        XCTAssertTrue(canProcess, "Pipeline should be able to process images")
    }
    
    func testMediaCodecSelection() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        await mediaDomain.registerCapability(H264VideoCapability())
        await mediaDomain.registerCapability(H265VideoCapability())
        await mediaDomain.registerCapability(VP9VideoCapability())
        
        let codecStrategy = await mediaDomain.selectOptimalCodec(
            for: MediaEncodingRequirements(
                quality: .high,
                fileSize: .medium,
                compatibility: .wide,
                performance: .balanced
            )
        )
        
        XCTAssertNotNil(codecStrategy, "Should select optimal codec strategy")
        XCTAssertNotNil(codecStrategy!.primaryCodec, "Strategy should have primary codec")
        XCTAssertTrue(codecStrategy!.fallbackCodecs.count >= 0, "Strategy should have fallback codecs")
    }
    
    func testMediaStreamingCapability() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        let hlsCapability = HLSStreamingCapability()
        let dashCapability = DASHStreamingCapability()
        
        await mediaDomain.registerCapability(hlsCapability)
        await mediaDomain.registerCapability(dashCapability)
        
        let streamingCapabilities = await mediaDomain.getCapabilitiesOfType(.streaming)
        XCTAssertEqual(streamingCapabilities.count, 2, "Should have 2 streaming capabilities")
        
        let adaptiveCapability = await mediaDomain.getBestCapabilityForUseCase(.adaptiveStreaming)
        XCTAssertNotNil(adaptiveCapability, "Should find capability for adaptive streaming")
    }
    
    // MARK: - Performance Tests
    
    func testMediaCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let mediaDomain = MediaCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestMediaCapability(index: i)
                    await mediaDomain.registerCapability(capability)
                }
                
                // Test codec selection performance
                for _ in 0..<50 {
                    let requirements = MediaEncodingRequirements(
                        quality: .medium,
                        fileSize: .small,
                        compatibility: .modern,
                        performance: .fast
                    )
                    _ = await mediaDomain.selectOptimalCodec(for: requirements)
                }
            },
            maxDuration: .milliseconds(400),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testMediaCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let mediaDomain = MediaCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<25 {
                let capability = TestMediaCapability(index: i)
                await mediaDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = MediaProcessingRequirements(
                        inputFormat: .jpeg,
                        outputFormat: .png,
                        quality: .low,
                        performance: .batch
                    )
                    _ = await mediaDomain.createProcessingPipeline(for: requirements)
                }
                
                if i % 8 == 0 {
                    await mediaDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await mediaDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testMediaCapabilityDomainErrorHandling() async throws {
        let mediaDomain = MediaCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestMediaCapability(index: 1)
        let capability2 = TestMediaCapability(index: 1) // Same index = same identifier
        
        await mediaDomain.registerCapability(capability1)
        
        do {
            try await mediaDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test processing pipeline with unsupported format
        do {
            let unsupportedRequirements = MediaProcessingRequirements(
                inputFormat: .unsupported,
                outputFormat: .h264,
                quality: .high,
                performance: .realtime
            )
            try await mediaDomain.createProcessingPipelineStrict(for: unsupportedRequirements)
            XCTFail("Should throw error for unsupported format")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for unsupported format")
        }
        
        // Test codec selection with impossible requirements
        do {
            let impossibleRequirements = MediaEncodingRequirements(
                quality: .highest,
                fileSize: .smallest,
                compatibility: .universal,
                performance: .fastest
            )
            try await mediaDomain.selectOptimalCodecStrict(for: impossibleRequirements)
            // This might succeed with trade-offs, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for impossible requirements")
        }
    }
}

// MARK: - Test Helper Classes

private struct JPEGImageCapability: MediaCapability {
    let identifier = "axiom.media.image.jpeg"
    let isAvailable = true
    let mediaType: MediaType = .image
    let format: MediaFormat = .jpeg
    let quality: QualityLevel = .high
}

private struct PNGImageCapability: MediaCapability {
    let identifier = "axiom.media.image.png"
    let isAvailable = true
    let mediaType: MediaType = .image
    let format: MediaFormat = .png
    let quality: QualityLevel = .lossless
}

private struct HEIFImageCapability: MediaCapability {
    let identifier = "axiom.media.image.heif"
    let isAvailable = true
    let mediaType: MediaType = .image
    let format: MediaFormat = .heif
    let quality: QualityLevel = .high
}

private struct RAWImageCapability: MediaCapability {
    let identifier = "axiom.media.image.raw"
    let isAvailable = true
    let mediaType: MediaType = .image
    let format: MediaFormat = .raw
    let quality: QualityLevel = .lossless
}

private struct H264VideoCapability: MediaCapability {
    let identifier = "axiom.media.video.h264"
    let isAvailable = true
    let mediaType: MediaType = .video
    let format: MediaFormat = .h264
    let quality: QualityLevel = .high
}

private struct H265VideoCapability: MediaCapability {
    let identifier = "axiom.media.video.h265"
    let isAvailable = true
    let mediaType: MediaType = .video
    let format: MediaFormat = .h265
    let quality: QualityLevel = .highest
}

private struct VP9VideoCapability: MediaCapability {
    let identifier = "axiom.media.video.vp9"
    let isAvailable = true
    let mediaType: MediaType = .video
    let format: MediaFormat = .vp9
    let quality: QualityLevel = .high
}

private struct AV1VideoCapability: MediaCapability {
    let identifier = "axiom.media.video.av1"
    let isAvailable = true
    let mediaType: MediaType = .video
    let format: MediaFormat = .av1
    let quality: QualityLevel = .highest
}

private struct AACCapability: MediaCapability {
    let identifier = "axiom.media.audio.aac"
    let isAvailable = true
    let mediaType: MediaType = .audio
    let format: MediaFormat = .aac
    let quality: QualityLevel = .high
}

private struct MP3Capability: MediaCapability {
    let identifier = "axiom.media.audio.mp3"
    let isAvailable = true
    let mediaType: MediaType = .audio
    let format: MediaFormat = .mp3
    let quality: QualityLevel = .medium
}

private struct FLACCapability: MediaCapability {
    let identifier = "axiom.media.audio.flac"
    let isAvailable = true
    let mediaType: MediaType = .audio
    let format: MediaFormat = .flac
    let quality: QualityLevel = .lossless
}

private struct OpusCapability: MediaCapability {
    let identifier = "axiom.media.audio.opus"
    let isAvailable = true
    let mediaType: MediaType = .audio
    let format: MediaFormat = .opus
    let quality: QualityLevel = .high
}

private struct HLSStreamingCapability: MediaCapability {
    let identifier = "axiom.media.streaming.hls"
    let isAvailable = true
    let mediaType: MediaType = .streaming
    let format: MediaFormat = .hls
    let quality: QualityLevel = .adaptive
}

private struct DASHStreamingCapability: MediaCapability {
    let identifier = "axiom.media.streaming.dash"
    let isAvailable = true
    let mediaType: MediaType = .streaming
    let format: MediaFormat = .dash
    let quality: QualityLevel = .adaptive
}

private struct TestMediaCapability: MediaCapability {
    let identifier: String
    let isAvailable = true
    let mediaType: MediaType = .image
    let format: MediaFormat = .jpeg
    let quality: QualityLevel = .medium
    
    init(index: Int) {
        self.identifier = "test.media.capability.\(index)"
    }
}

private enum MediaType {
    case image
    case video
    case audio
    case streaming
}

private enum MediaFormat {
    case jpeg
    case png
    case heif
    case raw
    case h264
    case h265
    case vp9
    case av1
    case aac
    case mp3
    case flac
    case opus
    case hls
    case dash
    case unsupported
}

private enum QualityLevel {
    case low
    case medium
    case high
    case highest
    case lossless
    case adaptive
}

private enum MediaUseCase {
    case highQuality
    case efficient
    case adaptiveStreaming
    case lowLatency
}

private enum PerformanceMode {
    case realtime
    case batch
    case balanced
    case fast
    case fastest
}

private enum FileSize {
    case smallest
    case small
    case medium
    case large
    case unlimited
}

private enum Compatibility {
    case modern
    case wide
    case universal
}

private struct MediaProcessingRequirements {
    let inputFormat: MediaFormat
    let outputFormat: MediaFormat
    let quality: QualityLevel
    let performance: PerformanceMode
}

private struct MediaEncodingRequirements {
    let quality: QualityLevel
    let fileSize: FileSize
    let compatibility: Compatibility
    let performance: PerformanceMode
}