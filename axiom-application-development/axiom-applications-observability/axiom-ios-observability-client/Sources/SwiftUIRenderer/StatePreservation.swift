import Foundation
import SwiftUI
import CryptoKit
#if canImport(UIKit) && !os(macOS)
import UIKit
#endif
import HotReloadProtocol

// MARK: - State Preservation Manager

@MainActor
public final class StatePreservation: ObservableObject {
    
    // MARK: - Types
    
    public struct StateSnapshot: Codable {
        public let fileHash: String
        public let timestamp: Date
        public let layoutHash: String
        public let stateData: [String: AnyCodable]
        public let metadata: StateMetadata
        
        public init(
            fileHash: String,
            layoutHash: String,
            stateData: [String: AnyCodable],
            metadata: StateMetadata = StateMetadata()
        ) {
            self.fileHash = fileHash
            self.timestamp = Date()
            self.layoutHash = layoutHash
            self.stateData = stateData
            self.metadata = metadata
        }
    }
    
    public struct StateMetadata: Codable {
        public let version: String
        public let platform: String
        public let deviceId: String
        public let appVersion: String?
        
        public init(
            version: String = "1.0.0",
            platform: String = "iOS",
            deviceId: String = {
                #if canImport(UIKit) && !os(macOS)
                return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                #else
                return UUID().uuidString
                #endif
            }(),
            appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ) {
            self.version = version
            self.platform = platform
            self.deviceId = deviceId
            self.appVersion = appVersion
        }
    }
    
    public struct PreservationResult {
        public let success: Bool
        public let preservedKeys: [String]
        public let restoredKeys: [String]
        public let incompatibleKeys: [String]
        public let reason: String?
        
        public init(
            success: Bool,
            preservedKeys: [String] = [],
            restoredKeys: [String] = [],
            incompatibleKeys: [String] = [],
            reason: String? = nil
        ) {
            self.success = success
            self.preservedKeys = preservedKeys
            self.restoredKeys = restoredKeys
            self.incompatibleKeys = incompatibleKeys
            self.reason = reason
        }
    }
    
    // MARK: - Properties
    
    @Published public private(set) var lastSnapshot: StateSnapshot?
    @Published public private(set) var preservationEnabled: Bool = true
    @Published public private(set) var lastPreservationResult: PreservationResult?
    
    private let configuration: StatePreservationConfiguration
    private let fileManager = FileManager.default
    private var snapshotHistory: [StateSnapshot] = []
    
    private var preservationDirectory: URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDir.appendingPathComponent("AxiomHotReload/StatePreservation", isDirectory: true)
    }
    
    // MARK: - Initialization
    
    public init(configuration: StatePreservationConfiguration = StatePreservationConfiguration()) {
        self.configuration = configuration
        setupPreservationDirectory()
        loadSnapshotHistory()
    }
    
    // MARK: - Public API
    
    /// Create a state snapshot for the current layout and state
    public func createSnapshot(
        from layout: SwiftUILayoutJSON,
        stateManager: SwiftUIStateManager
    ) -> StateSnapshot {
        let fileHash = calculateFileHash(from: layout)
        let layoutHash = calculateLayoutHash(from: layout)
        let stateData = stateManager.getAllState()
        
        let snapshot = StateSnapshot(
            fileHash: fileHash,
            layoutHash: layoutHash,
            stateData: stateData
        )
        
        lastSnapshot = snapshot
        
        if configuration.enableSnapshotHistory {
            addToHistory(snapshot)
        }
        
        if configuration.enablePersistence {
            saveSnapshot(snapshot)
        }
        
        return snapshot
    }
    
    /// Attempt to restore state from a compatible snapshot
    public func restoreState(
        for layout: SwiftUILayoutJSON,
        into stateManager: SwiftUIStateManager
    ) -> PreservationResult {
        guard preservationEnabled else {
            return PreservationResult(success: false, reason: "State preservation disabled")
        }
        
        let currentFileHash = calculateFileHash(from: layout)
        let currentLayoutHash = calculateLayoutHash(from: layout)
        
        // Try to find compatible snapshot
        if let compatibleSnapshot = findCompatibleSnapshot(
            fileHash: currentFileHash,
            layoutHash: currentLayoutHash
        ) {
            return restoreFromSnapshot(compatibleSnapshot, into: stateManager)
        }
        
        return PreservationResult(success: false, reason: "No compatible snapshot found")
    }
    
    /// Determine if state should be preserved for a layout change
    public func shouldPreserveState(
        from oldLayout: SwiftUILayoutJSON?,
        to newLayout: SwiftUILayoutJSON
    ) -> Bool {
        guard preservationEnabled, let oldLayout = oldLayout else { return false }
        
        let oldFileHash = calculateFileHash(from: oldLayout)
        let newFileHash = calculateFileHash(from: newLayout)
        let oldLayoutHash = calculateLayoutHash(from: oldLayout)
        let newLayoutHash = calculateLayoutHash(from: newLayout)
        
        // Same file, check layout compatibility
        if oldFileHash == newFileHash {
            return calculateLayoutCompatibility(oldLayoutHash, newLayoutHash) >= configuration.minimumCompatibilityThreshold
        }
        
        // Different files - preserve only if explicitly enabled
        return configuration.preserveAcrossFiles
    }
    
    /// Clear all preserved state
    public func clearAllPreservedState() {
        lastSnapshot = nil
        snapshotHistory.removeAll()
        clearStoredSnapshots()
        
        lastPreservationResult = PreservationResult(
            success: true,
            reason: "All preserved state cleared"
        )
    }
    
    /// Get preservation statistics
    public func getPreservationStats() -> PreservationStats {
        return PreservationStats(
            totalSnapshots: snapshotHistory.count,
            lastSnapshotDate: lastSnapshot?.timestamp,
            preservationEnabled: preservationEnabled,
            storageUsed: calculateStorageUsage(),
            compatibilityThreshold: configuration.minimumCompatibilityThreshold
        )
    }
    
    // MARK: - Private Methods
    
    private func setupPreservationDirectory() {
        do {
            try fileManager.createDirectory(
                at: preservationDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Failed to create preservation directory: \(error)")
            preservationEnabled = false
        }
    }
    
    private func calculateFileHash(from layout: SwiftUILayoutJSON) -> String {
        // Use the file path or content for hashing
        let hashData = "\(layout.metadata.fileName)\(layout.metadata.timestamp)".data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: hashData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func calculateLayoutHash(from layout: SwiftUILayoutJSON) -> String {
        // Create a structural hash of the layout (ignoring dynamic content)
        let structuralData = extractStructuralData(from: layout)
        let hashData = structuralData.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: hashData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func extractStructuralData(from layout: SwiftUILayoutJSON) -> String {
        // Extract only structural elements for compatibility checking
        var structural: [String] = []
        
        for view in layout.views {
            structural.append(extractViewStructure(view))
        }
        
        return structural.joined(separator: "|")
    }
    
    private func extractViewStructure(_ view: SwiftUIViewJSON) -> String {
        var structure = view.type
        
        // Add key properties that affect state binding
        if let state = view.state {
            structure += ":" + state.keys.sorted().joined(separator: ",")
        }
        
        // Add children structure recursively
        if let children = view.children {
            let childStructures = children.map { extractViewStructure($0) }
            structure += "(" + childStructures.joined(separator: ",") + ")"
        }
        
        return structure
    }
    
    private func calculateLayoutCompatibility(_ hash1: String, _ hash2: String) -> Double {
        if hash1 == hash2 { return 1.0 }
        
        // Simple compatibility heuristic - in production this could be more sophisticated
        // For now, consider layouts incompatible if hashes differ
        return 0.0
    }
    
    private func findCompatibleSnapshot(fileHash: String, layoutHash: String) -> StateSnapshot? {
        // First try exact file and layout match
        if let exactMatch = snapshotHistory.first(where: {
            $0.fileHash == fileHash && $0.layoutHash == layoutHash
        }) {
            return exactMatch
        }
        
        // If preserving across files is enabled, try file hash match with compatible layout
        if configuration.preserveAcrossFiles {
            return snapshotHistory.first { snapshot in
                snapshot.fileHash == fileHash &&
                calculateLayoutCompatibility(snapshot.layoutHash, layoutHash) >= configuration.minimumCompatibilityThreshold
            }
        }
        
        return nil
    }
    
    private func restoreFromSnapshot(
        _ snapshot: StateSnapshot,
        into stateManager: SwiftUIStateManager
    ) -> PreservationResult {
        var restoredKeys: [String] = []
        var incompatibleKeys: [String] = []
        
        for (key, value) in snapshot.stateData {
            do {
                // Convert AnyCodable back to StateValue
                if let stateValue = convertToStateValue(value) {
                    stateManager.setState(key: key, value: stateValue)
                    restoredKeys.append(key)
                } else {
                    incompatibleKeys.append(key)
                }
            } catch {
                incompatibleKeys.append(key)
            }
        }
        
        let result = PreservationResult(
            success: true,
            restoredKeys: restoredKeys,
            incompatibleKeys: incompatibleKeys,
            reason: "Restored from snapshot created at \(snapshot.timestamp)"
        )
        
        lastPreservationResult = result
        return result
    }
    
    private func convertToStateValue(_ anyCodable: AnyCodable) -> StateValue? {
        switch anyCodable.value {
        case let string as String:
            return .string(string)
        case let int as Int:
            return .int(int)
        case let double as Double:
            return .double(double)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            // Convert array elements to StateValue if possible
            let stateArray = array.compactMap { element -> StateValue? in
                let anyCodableElement = AnyCodable(element)
                return convertToStateValue(anyCodableElement)
            }
            return .array(stateArray)
        case let dict as [String: Any]:
            // Convert dictionary values to StateValue if possible
            var stateDict: [String: StateValue] = [:]
            for (key, value) in dict {
                let anyCodableValue = AnyCodable(value)
                if let stateValue = convertToStateValue(anyCodableValue) {
                    stateDict[key] = stateValue
                }
            }
            return .dictionary(stateDict)
        default:
            return nil
        }
    }
    
    private func addToHistory(_ snapshot: StateSnapshot) {
        snapshotHistory.append(snapshot)
        
        // Limit history size
        if snapshotHistory.count > configuration.maxSnapshotHistory {
            snapshotHistory.removeFirst(snapshotHistory.count - configuration.maxSnapshotHistory)
        }
    }
    
    private func saveSnapshot(_ snapshot: StateSnapshot) {
        let filename = "snapshot_\(snapshot.fileHash)_\(Int(snapshot.timestamp.timeIntervalSince1970)).json"
        let url = preservationDirectory.appendingPathComponent(filename)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(snapshot)
            try data.write(to: url)
        } catch {
            print("Failed to save snapshot: \(error)")
        }
    }
    
    private func loadSnapshotHistory() {
        guard configuration.enablePersistence else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: preservationDirectory, includingPropertiesForKeys: nil)
            let snapshotFiles = files.filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("snapshot_") }
            
            for file in snapshotFiles {
                if let snapshot = loadSnapshot(from: file) {
                    snapshotHistory.append(snapshot)
                }
            }
            
            // Sort by timestamp
            snapshotHistory.sort { $0.timestamp < $1.timestamp }
            
            // Take the most recent one as last snapshot
            lastSnapshot = snapshotHistory.last
            
        } catch {
            print("Failed to load snapshot history: \(error)")
        }
    }
    
    private func loadSnapshot(from url: URL) -> StateSnapshot? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(StateSnapshot.self, from: data)
        } catch {
            print("Failed to load snapshot from \(url): \(error)")
            return nil
        }
    }
    
    private func clearStoredSnapshots() {
        do {
            let files = try fileManager.contentsOfDirectory(at: preservationDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear stored snapshots: \(error)")
        }
    }
    
    private func calculateStorageUsage() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: preservationDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return Int64(files.compactMap { url in
                try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            }.reduce(0, +))
        } catch {
            return 0
        }
    }
}

// MARK: - Configuration

public struct StatePreservationConfiguration {
    public let enablePersistence: Bool
    public let enableSnapshotHistory: Bool
    public let preserveAcrossFiles: Bool
    public let minimumCompatibilityThreshold: Double
    public let maxSnapshotHistory: Int
    public let snapshotExpirationDays: Int
    
    public init(
        enablePersistence: Bool = true,
        enableSnapshotHistory: Bool = true,
        preserveAcrossFiles: Bool = false,
        minimumCompatibilityThreshold: Double = 0.8,
        maxSnapshotHistory: Int = 50,
        snapshotExpirationDays: Int = 7
    ) {
        self.enablePersistence = enablePersistence
        self.enableSnapshotHistory = enableSnapshotHistory
        self.preserveAcrossFiles = preserveAcrossFiles
        self.minimumCompatibilityThreshold = minimumCompatibilityThreshold
        self.maxSnapshotHistory = maxSnapshotHistory
        self.snapshotExpirationDays = snapshotExpirationDays
    }
    
    public static func development() -> StatePreservationConfiguration {
        return StatePreservationConfiguration(
            enablePersistence: true,
            enableSnapshotHistory: true,
            preserveAcrossFiles: false,
            minimumCompatibilityThreshold: 0.9,
            maxSnapshotHistory: 100
        )
    }
    
    public static func production() -> StatePreservationConfiguration {
        return StatePreservationConfiguration(
            enablePersistence: false,
            enableSnapshotHistory: false,
            preserveAcrossFiles: false,
            minimumCompatibilityThreshold: 0.95,
            maxSnapshotHistory: 10
        )
    }
}

// MARK: - Statistics

public struct PreservationStats {
    public let totalSnapshots: Int
    public let lastSnapshotDate: Date?
    public let preservationEnabled: Bool
    public let storageUsed: Int64
    public let compatibilityThreshold: Double
    
    public var storageUsedMB: Double {
        return Double(storageUsed) / (1024 * 1024)
    }
}

// MARK: - Extensions

extension StatePreservation {
    
    /// Clean up old snapshots based on expiration policy
    public func cleanupExpiredSnapshots() {
        let expirationDate = Calendar.current.date(
            byAdding: .day,
            value: -configuration.snapshotExpirationDays,
            to: Date()
        ) ?? Date.distantPast
        
        snapshotHistory.removeAll { $0.timestamp < expirationDate }
        
        // Clean up stored files
        do {
            let files = try fileManager.contentsOfDirectory(at: preservationDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.contentModificationDateKey])
                if let modificationDate = resourceValues.contentModificationDate,
                   modificationDate < expirationDate {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup expired snapshots: \(error)")
        }
    }
    
    /// Export state preservation data for debugging
    public func exportPreservationData() -> [String: Any] {
        return [
            "lastSnapshot": lastSnapshot.map { snapshot in
                [
                    "fileHash": snapshot.fileHash,
                    "layoutHash": snapshot.layoutHash,
                    "timestamp": snapshot.timestamp.iso8601,
                    "stateKeys": Array(snapshot.stateData.keys),
                    "metadata": [
                        "version": snapshot.metadata.version,
                        "platform": snapshot.metadata.platform,
                        "deviceId": snapshot.metadata.deviceId
                    ]
                ]
            } as Any,
            "snapshotHistory": snapshotHistory.map { snapshot in
                [
                    "fileHash": snapshot.fileHash,
                    "timestamp": snapshot.timestamp.iso8601,
                    "stateKeyCount": snapshot.stateData.count
                ]
            },
            "stats": [
                "totalSnapshots": snapshotHistory.count,
                "preservationEnabled": preservationEnabled,
                "storageUsedMB": getPreservationStats().storageUsedMB,
                "configuration": [
                    "enablePersistence": configuration.enablePersistence,
                    "preserveAcrossFiles": configuration.preserveAcrossFiles,
                    "compatibilityThreshold": configuration.minimumCompatibilityThreshold
                ]
            ]
        ]
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601: String {
        return ISO8601DateFormatter().string(from: self)
    }
}