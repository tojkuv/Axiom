import XCTest
@testable import AxiomHotReloadServer
@testable import HotReloadProtocol
@testable import NetworkCore

final class HotReloadServerTests: XCTestCase {
    
    func testServerConfiguration() throws {
        let config = AxiomHotReloadServer.ServerConfiguration.development()
            .withPort(9090)
            .withSwiftUIDirectory("/tmp")
            .withComposeDirectory("/tmp")
        
        XCTAssertEqual(config.port, 9090)
        XCTAssertEqual(config.swiftUIDirectory, "/tmp")
        XCTAssertEqual(config.composeDirectory, "/tmp")
        XCTAssertEqual(config.host, "localhost")
        XCTAssertTrue(config.enableStatePreservation)
    }
    
    func testConfigurationValidation() throws {
        // Valid configuration should not throw
        let validConfig = AxiomHotReloadServer.ServerConfiguration(
            port: 8080,
            swiftUIDirectory: "/tmp",
            composeDirectory: "/tmp"
        )
        XCTAssertNoThrow(try validConfig.validate())
        
        // Invalid port should throw
        let invalidPortConfig = AxiomHotReloadServer.ServerConfiguration(port: -1)
        XCTAssertThrowsError(try invalidPortConfig.validate()) { error in
            XCTAssertTrue(error is ConfigurationError)
        }
        
        // Invalid max clients should throw
        let invalidMaxClientsConfig = AxiomHotReloadServer.ServerConfiguration(maxClients: 0)
        XCTAssertThrowsError(try invalidMaxClientsConfig.validate()) { error in
            XCTAssertTrue(error is ConfigurationError)
        }
    }
    
    func testMessageTypes() throws {
        // Test BaseMessage creation
        let message = BaseMessage(
            type: .fileChanged,
            platform: .ios,
            payload: .fileChanged(
                FileChangedPayload(
                    filePath: "/path/to/file.swift",
                    fileName: "ContentView.swift",
                    fileContent: "import SwiftUI\n\nstruct ContentView: View { var body: some View { Text(\"Hello\") } }",
                    changeType: .modified,
                    checksum: "abc123"
                )
            )
        )
        
        XCTAssertEqual(message.type, .fileChanged)
        XCTAssertEqual(message.platform, .ios)
        XCTAssertEqual(message.version, "1.0.0")
        
        // Test JSON encoding/decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(BaseMessage.self, from: data)
        
        XCTAssertEqual(message.type, decodedMessage.type)
        XCTAssertEqual(message.platform, decodedMessage.platform)
        XCTAssertEqual(message.version, decodedMessage.version)
    }
    
    func testSwiftUISchema() throws {
        let view = SwiftUIViewJSON(
            type: "VStack",
            properties: [
                "spacing": .double(20)
            ],
            children: [
                SwiftUIViewJSON(
                    type: "Text",
                    properties: [
                        "content": .string("Hello World")
                    ]
                )
            ],
            modifiers: [
                SwiftUIModifierJSON(
                    name: "padding",
                    parameters: ["all": .double(16)]
                )
            ]
        )
        
        XCTAssertEqual(view.type, "VStack")
        XCTAssertEqual(view.children?.count, 1)
        XCTAssertEqual(view.modifiers?.count, 1)
        
        // Test JSON serialization
        let encoder = JSONEncoder()
        let data = try encoder.encode(view)
        
        let decoder = JSONDecoder()
        let decodedView = try decoder.decode(SwiftUIViewJSON.self, from: data)
        
        XCTAssertEqual(view.type, decodedView.type)
        XCTAssertEqual(view.children?.count, decodedView.children?.count)
    }
    
    func testComposeSchema() throws {
        let component = ComposeComponentJSON(
            type: "Column",
            parameters: [
                "verticalArrangement": .arrangement(
                    ComposeArrangementValue(type: "spacedBy", spacing: ComposeDpValue(value: 16))
                )
            ],
            children: [
                ComposeComponentJSON(
                    type: "Text",
                    parameters: [
                        "text": .string("Hello World")
                    ]
                )
            ],
            modifiers: [
                ComposeModifierJSON(
                    name: "padding",
                    parameters: ["all": .padding(ComposePaddingValue(all: ComposeDpValue(value: 16)))]
                )
            ]
        )
        
        XCTAssertEqual(component.type, "Column")
        XCTAssertEqual(component.children?.count, 1)
        XCTAssertEqual(component.modifiers?.count, 1)
        
        // Test JSON serialization
        let encoder = JSONEncoder()
        let data = try encoder.encode(component)
        
        let decoder = JSONDecoder()
        let decodedComponent = try decoder.decode(ComposeComponentJSON.self, from: data)
        
        XCTAssertEqual(component.type, decodedComponent.type)
        XCTAssertEqual(component.children?.count, decodedComponent.children?.count)
    }
    
    func testStateSynchronization() throws {
        let stateData = StateSynchronizationProtocol.StateContainer(
            swiftUIState: ["text": .string("Hello")],
            composeState: ["count": .int(42)],
            globalState: ["theme": AnyCodable("dark")]
        )
        
        let snapshot = StateSynchronizationProtocol.createSnapshot(
            for: "ContentView.swift",
            platform: .ios,
            stateData: stateData
        )
        
        XCTAssertEqual(snapshot.fileName, "ContentView.swift")
        XCTAssertEqual(snapshot.platform, .ios)
        XCTAssertEqual(snapshot.metadata.preservationStrategy, .fileScope)
        
        // Test state merging
        let existingState = StateSynchronizationProtocol.StateContainer(
            swiftUIState: ["text": .string("Old Text")],
            globalState: ["theme": AnyCodable("light")]
        )
        
        let mergedState = StateSynchronizationProtocol.mergeState(
            existing: existingState,
            incoming: stateData,
            strategy: .fileScope
        )
        
        XCTAssertNotNil(mergedState.swiftUIState)
        XCTAssertNotNil(mergedState.composeState)
        XCTAssertNotNil(mergedState.globalState)
    }
}

// MARK: - Test Helpers

extension HotReloadServerTests {
    
    func createTestConfiguration() -> AxiomHotReloadServer.ServerConfiguration {
        return AxiomHotReloadServer.ServerConfiguration(
            host: "localhost",
            port: 0, // Use port 0 for testing to get an available port
            maxClients: 5,
            heartbeatInterval: 5.0,
            swiftUIDirectory: NSTemporaryDirectory(),
            composeDirectory: NSTemporaryDirectory()
        )
    }
}