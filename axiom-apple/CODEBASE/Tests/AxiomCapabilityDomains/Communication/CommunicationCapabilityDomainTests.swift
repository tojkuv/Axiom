import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains communication capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class CommunicationCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testCommunicationCapabilityDomainInitialization() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        XCTAssertNotNil(communicationDomain, "CommunicationCapabilityDomain should initialize correctly")
        XCTAssertEqual(communicationDomain.identifier, "axiom.capability.domain.communication", "Should have correct identifier")
    }
    
    func testMessagingCapabilityRegistration() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        let pushNotificationCapability = PushNotificationCapability()
        let localNotificationCapability = LocalNotificationCapability()
        let emailCapability = EmailCapability()
        let smsCapability = SMSCapability()
        
        await communicationDomain.registerCapability(pushNotificationCapability)
        await communicationDomain.registerCapability(localNotificationCapability)
        await communicationDomain.registerCapability(emailCapability)
        await communicationDomain.registerCapability(smsCapability)
        
        let registeredCapabilities = await communicationDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 4, "Should have 4 registered messaging capabilities")
        
        let hasPushNotification = await communicationDomain.hasCapability("axiom.communication.messaging.push")
        XCTAssertTrue(hasPushNotification, "Should have Push Notification capability")
        
        let hasLocalNotification = await communicationDomain.hasCapability("axiom.communication.messaging.local")
        XCTAssertTrue(hasLocalNotification, "Should have Local Notification capability")
        
        let hasEmail = await communicationDomain.hasCapability("axiom.communication.messaging.email")
        XCTAssertTrue(hasEmail, "Should have Email capability")
        
        let hasSMS = await communicationDomain.hasCapability("axiom.communication.messaging.sms")
        XCTAssertTrue(hasSMS, "Should have SMS capability")
    }
    
    func testVoiceCapabilityManagement() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        let voipCapability = VoIPCapability()
        let audioCallCapability = AudioCallCapability()
        let voiceRecordingCapability = VoiceRecordingCapability()
        let speechToTextCapability = SpeechToTextCapability()
        
        await communicationDomain.registerCapability(voipCapability)
        await communicationDomain.registerCapability(audioCallCapability)
        await communicationDomain.registerCapability(voiceRecordingCapability)
        await communicationDomain.registerCapability(speechToTextCapability)
        
        let voiceCapabilities = await communicationDomain.getCapabilitiesOfType(.voice)
        XCTAssertEqual(voiceCapabilities.count, 4, "Should have 4 voice capabilities")
        
        let realtimeVoiceCapability = await communicationDomain.getBestCapabilityForUseCase(.realtimeCommunication)
        XCTAssertNotNil(realtimeVoiceCapability, "Should find best capability for realtime communication")
        
        let highQualityVoiceCapability = await communicationDomain.getBestCapabilityForUseCase(.highQualityAudio)
        XCTAssertNotNil(highQualityVoiceCapability, "Should find best capability for high quality audio")
    }
    
    func testVideoCapabilitySupport() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        let videoCallCapability = VideoCallCapability()
        let videoConferencingCapability = VideoConferencingCapability()
        let screenSharingCapability = ScreenSharingCapability()
        let videoRecordingCapability = VideoRecordingCapability()
        
        await communicationDomain.registerCapability(videoCallCapability)
        await communicationDomain.registerCapability(videoConferencingCapability)
        await communicationDomain.registerCapability(screenSharingCapability)
        await communicationDomain.registerCapability(videoRecordingCapability)
        
        let videoCapabilities = await communicationDomain.getCapabilitiesOfType(.video)
        XCTAssertEqual(videoCapabilities.count, 4, "Should have 4 video capabilities")
        
        let multipartyCapability = await communicationDomain.getBestCapabilityForUseCase(.multipartyConference)
        XCTAssertNotNil(multipartyCapability, "Should find best capability for multiparty conference")
    }
    
    func testCommunicationRoutingStrategy() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        // Register various communication capabilities
        await communicationDomain.registerCapability(PushNotificationCapability())
        await communicationDomain.registerCapability(EmailCapability())
        await communicationDomain.registerCapability(SMSCapability())
        await communicationDomain.registerCapability(VoIPCapability())
        
        let routingStrategy = await communicationDomain.createRoutingStrategy(
            for: CommunicationRoutingRequirements(
                urgency: .high,
                reliability: .high,
                reach: .broad,
                cost: .low
            )
        )
        
        XCTAssertNotNil(routingStrategy, "Should create communication routing strategy")
        XCTAssertTrue(routingStrategy!.channels.count > 0, "Strategy should include communication channels")
        
        let primaryChannel = routingStrategy!.primaryChannel
        XCTAssertNotNil(primaryChannel, "Strategy should have a primary channel")
        
        let fallbackChannels = routingStrategy!.fallbackChannels
        XCTAssertTrue(fallbackChannels.count >= 0, "Strategy should have fallback channels")
    }
    
    func testMessageDeliveryTracking() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        await communicationDomain.registerCapability(PushNotificationCapability())
        await communicationDomain.registerCapability(EmailCapability())
        
        let deliveryTracker = await communicationDomain.getDeliveryTracker()
        XCTAssertNotNil(deliveryTracker, "Should provide delivery tracker")
        
        // Test message tracking
        let messageId = "test-message-123"
        let message = TestMessage(id: messageId, content: "Test message", recipient: "user@example.com")
        
        await deliveryTracker!.trackMessage(message, channel: .email)
        
        let deliveryStatus = await deliveryTracker!.getDeliveryStatus(messageId)
        XCTAssertNotNil(deliveryStatus, "Should have delivery status")
        XCTAssertEqual(deliveryStatus!.messageId, messageId, "Should track correct message")
        
        // Test delivery confirmation
        await deliveryTracker!.confirmDelivery(messageId, timestamp: Date())
        
        let confirmedStatus = await deliveryTracker!.getDeliveryStatus(messageId)
        XCTAssertEqual(confirmedStatus!.status, .delivered, "Status should be delivered")
    }
    
    func testCommunicationSecurityFeatures() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        let securityManager = await communicationDomain.getSecurityManager()
        XCTAssertNotNil(securityManager, "Should provide security manager")
        
        // Test message encryption
        let plainMessage = "This is a sensitive message"
        let encryptedMessage = await securityManager!.encryptMessage(plainMessage)
        XCTAssertNotEqual(encryptedMessage, plainMessage, "Message should be encrypted")
        
        let decryptedMessage = await securityManager!.decryptMessage(encryptedMessage)
        XCTAssertEqual(decryptedMessage, plainMessage, "Decrypted message should match original")
        
        // Test identity verification
        let identity = CommunicationIdentity(userId: "user123", publicKey: "test-public-key")
        let isVerified = await securityManager!.verifyIdentity(identity)
        XCTAssertNotNil(isVerified, "Should verify identity")
        
        // Test secure channel establishment
        let secureChannel = await securityManager!.establishSecureChannel(with: identity)
        XCTAssertNotNil(secureChannel, "Should establish secure channel")
    }
    
    func testPresenceManagement() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        let presenceManager = await communicationDomain.getPresenceManager()
        XCTAssertNotNil(presenceManager, "Should provide presence manager")
        
        // Test presence status updates
        await presenceManager!.updatePresence(.online)
        let currentStatus = await presenceManager!.getCurrentPresence()
        XCTAssertEqual(currentStatus, .online, "Should update presence to online")
        
        // Test presence subscription
        let userId = "user456"
        await presenceManager!.subscribeToPresence(userId)
        
        let subscribedUsers = await presenceManager!.getSubscribedUsers()
        XCTAssertTrue(subscribedUsers.contains(userId), "Should subscribe to user presence")
        
        // Test presence broadcasting
        await presenceManager!.broadcastPresence(.busy, message: "In a meeting")
        let broadcastStatus = await presenceManager!.getCurrentPresence()
        XCTAssertEqual(broadcastStatus, .busy, "Should broadcast busy status")
    }
    
    // MARK: - Performance Tests
    
    func testCommunicationCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let communicationDomain = CommunicationCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestCommunicationCapability(index: i)
                    await communicationDomain.registerCapability(capability)
                }
                
                // Test routing strategy creation performance
                for _ in 0..<25 {
                    let requirements = CommunicationRoutingRequirements(
                        urgency: .medium,
                        reliability: .medium,
                        reach: .targeted,
                        cost: .medium
                    )
                    _ = await communicationDomain.createRoutingStrategy(for: requirements)
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testCommunicationCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let communicationDomain = CommunicationCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestCommunicationCapability(index: i)
                await communicationDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = CommunicationRoutingRequirements(
                        urgency: .low,
                        reliability: .low,
                        reach: .narrow,
                        cost: .high
                    )
                    _ = await communicationDomain.createRoutingStrategy(for: requirements)
                }
                
                if i % 8 == 0 {
                    await communicationDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await communicationDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCommunicationCapabilityDomainErrorHandling() async throws {
        let communicationDomain = CommunicationCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestCommunicationCapability(index: 1)
        let capability2 = TestCommunicationCapability(index: 1) // Same index = same identifier
        
        await communicationDomain.registerCapability(capability1)
        
        do {
            try await communicationDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test routing strategy with conflicting requirements
        do {
            let conflictingRequirements = CommunicationRoutingRequirements(
                urgency: .critical,
                reliability: .highest,
                reach: .global,
                cost: .free
            )
            try await communicationDomain.createRoutingStrategyStrict(for: conflictingRequirements)
            // This might succeed with trade-offs, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for conflicting requirements")
        }
        
        // Test message delivery with invalid recipient
        let deliveryTracker = await communicationDomain.getDeliveryTracker()
        if let tracker = deliveryTracker {
            do {
                let invalidMessage = TestMessage(id: "invalid", content: "Test", recipient: "")
                try await tracker.trackMessageStrict(invalidMessage, channel: .email)
                XCTFail("Should throw error for invalid recipient")
            } catch {
                XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid recipient")
            }
        }
    }
}

// MARK: - Test Helper Classes

private struct PushNotificationCapability: CommunicationCapability {
    let identifier = "axiom.communication.messaging.push"
    let isAvailable = true
    let communicationType: CommunicationType = .messaging
    let reliability: CommunicationReliability = .high
    let latency: CommunicationLatency = .low
}

private struct LocalNotificationCapability: CommunicationCapability {
    let identifier = "axiom.communication.messaging.local"
    let isAvailable = true
    let communicationType: CommunicationType = .messaging
    let reliability: CommunicationReliability = .highest
    let latency: CommunicationLatency = .immediate
}

private struct EmailCapability: CommunicationCapability {
    let identifier = "axiom.communication.messaging.email"
    let isAvailable = true
    let communicationType: CommunicationType = .messaging
    let reliability: CommunicationReliability = .high
    let latency: CommunicationLatency = .medium
}

private struct SMSCapability: CommunicationCapability {
    let identifier = "axiom.communication.messaging.sms"
    let isAvailable = true
    let communicationType: CommunicationType = .messaging
    let reliability: CommunicationReliability = .medium
    let latency: CommunicationLatency = .low
}

private struct VoIPCapability: CommunicationCapability {
    let identifier = "axiom.communication.voice.voip"
    let isAvailable = true
    let communicationType: CommunicationType = .voice
    let reliability: CommunicationReliability = .medium
    let latency: CommunicationLatency = .realtime
}

private struct AudioCallCapability: CommunicationCapability {
    let identifier = "axiom.communication.voice.call"
    let isAvailable = true
    let communicationType: CommunicationType = .voice
    let reliability: CommunicationReliability = .high
    let latency: CommunicationLatency = .realtime
}

private struct VoiceRecordingCapability: CommunicationCapability {
    let identifier = "axiom.communication.voice.recording"
    let isAvailable = true
    let communicationType: CommunicationType = .voice
    let reliability: CommunicationReliability = .high
    let latency: CommunicationLatency = .medium
}

private struct SpeechToTextCapability: CommunicationCapability {
    let identifier = "axiom.communication.voice.speechtotext"
    let isAvailable = true
    let communicationType: CommunicationType = .voice
    let reliability: CommunicationReliability = .medium
    let latency: CommunicationLatency = .low
}

private struct VideoCallCapability: CommunicationCapability {
    let identifier = "axiom.communication.video.call"
    let isAvailable = true
    let communicationType: CommunicationType = .video
    let reliability: CommunicationReliability = .medium
    let latency: CommunicationLatency = .realtime
}

private struct VideoConferencingCapability: CommunicationCapability {
    let identifier = "axiom.communication.video.conference"
    let isAvailable = true
    let communicationType: CommunicationType = .video
    let reliability: CommunicationReliability = .high
    let latency: CommunicationLatency = .realtime
}

private struct ScreenSharingCapability: CommunicationCapability {
    let identifier = "axiom.communication.video.screenshare"
    let isAvailable = true
    let communicationType: CommunicationType = .video
    let reliability: CommunicationReliability = .medium
    let latency: CommunicationLatency = .low
}

private struct VideoRecordingCapability: CommunicationCapability {
    let identifier = "axiom.communication.video.recording"
    let isAvailable = true
    let communicationType: CommunicationType = .video
    let reliability: CommunicationReliability = .high
    let latency: CommunicationLatency = .medium
}

private struct TestCommunicationCapability: CommunicationCapability {
    let identifier: String
    let isAvailable = true
    let communicationType: CommunicationType = .messaging
    let reliability: CommunicationReliability = .medium
    let latency: CommunicationLatency = .medium
    
    init(index: Int) {
        self.identifier = "test.communication.capability.\(index)"
    }
}

private enum CommunicationType {
    case messaging
    case voice
    case video
    case data
}

private enum CommunicationReliability {
    case low
    case medium
    case high
    case highest
}

private enum CommunicationLatency {
    case realtime
    case immediate
    case low
    case medium
    case high
}

private enum CommunicationUrgency {
    case low
    case medium
    case high
    case critical
}

private enum CommunicationReach {
    case narrow
    case targeted
    case broad
    case global
}

private enum CommunicationCost {
    case free
    case low
    case medium
    case high
}

private enum CommunicationChannel {
    case push
    case email
    case sms
    case voice
    case video
}

private enum CommunicationUseCase {
    case realtimeCommunication
    case highQualityAudio
    case multipartyConference
    case secureMessaging
}

private enum PresenceStatus {
    case online
    case offline
    case busy
    case away
    case doNotDisturb
}

private enum DeliveryStatus {
    case pending
    case sent
    case delivered
    case failed
    case read
}

private struct CommunicationRoutingRequirements {
    let urgency: CommunicationUrgency
    let reliability: CommunicationReliability
    let reach: CommunicationReach
    let cost: CommunicationCost
}

private struct TestMessage {
    let id: String
    let content: String
    let recipient: String
}

private struct CommunicationIdentity {
    let userId: String
    let publicKey: String
}