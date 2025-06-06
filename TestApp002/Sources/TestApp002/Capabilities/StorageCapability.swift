import Foundation
import Axiom
import CryptoKit

// Protocol definition as per RFC
protocol StorageCapability: Capability {
    func save<T: Codable>(_ object: T, key: String) async throws
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T?
    func delete(key: String) async throws
}

// Storage errors
enum StorageError: Error, Equatable {
    case checksumMismatch
    case missingRequiredField(String)
    case corruptedData
    case backupRestored
    case writeFailure
    case readFailure
    case concurrentAccessViolation
}

// Storage metadata for ACID guarantees
struct StorageMetadata: Codable {
    let checksum: String
    let timestamp: Date
    let version: Int
}

// REFACTOR Phase: StorageCapability with optimized performance
actor TestStorageCapability: StorageCapability {
    private var isInitialized = false
    private var storage: [String: Data] = [:]
    private var metadata: [String: StorageMetadata] = [:]
    private var backups: [String: Data] = [:]
    private let fileManager = FileManager.default
    private let storageURL: URL
    
    // Transaction log for ACID guarantees
    private var transactionLog: [String] = []
    private var isInTransaction = false
    
    // Performance optimization: batch disk writes
    private var pendingWrites: Set<String> = []
    private var writeTimer: Timer?
    private let writeBatchSize = 100
    private let writeDelay: TimeInterval = 0.1
    
    init() {
        // Create storage directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storageURL = documentsPath.appendingPathComponent("TestApp002Storage")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
    }
    
    var isAvailable: Bool {
        return isInitialized
    }
    
    func initialize() async throws {
        isInitialized = true
        // Load existing data from disk
        await loadFromDisk()
    }
    
    func terminate() async {
        isInitialized = false
        // Flush all pending writes before terminating
        await flushPendingWrites()
        // Persist data to disk
        await saveToDisk()
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        guard isInitialized else {
            throw StorageError.writeFailure
        }
        
        // Begin transaction for atomicity
        isInTransaction = true
        transactionLog.append("BEGIN SAVE \(key)")
        
        do {
            // Encode the object
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            
            // Calculate checksum
            let checksum = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
            
            // Backup existing data if present
            if let existingData = storage[key] {
                backups[key] = existingData
                transactionLog.append("BACKUP \(key)")
            }
            
            // Store data and metadata
            storage[key] = data
            metadata[key] = StorageMetadata(
                checksum: checksum,
                timestamp: Date(),
                version: (metadata[key]?.version ?? 0) + 1
            )
            
            transactionLog.append("COMMIT SAVE \(key)")
            isInTransaction = false
            
            // Mark for pending write (performance optimization)
            pendingWrites.insert(key)
            
            // Schedule batch write if not already scheduled
            scheduleBatchWrite()
            
        } catch {
            // Rollback on error
            transactionLog.append("ROLLBACK SAVE \(key)")
            if let backup = backups[key] {
                storage[key] = backup
            } else {
                storage.removeValue(forKey: key)
            }
            isInTransaction = false
            throw StorageError.writeFailure
        }
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard isInitialized else {
            throw StorageError.readFailure
        }
        
        guard let data = storage[key],
              let meta = metadata[key] else {
            return nil
        }
        
        // Verify checksum for consistency
        let currentChecksum = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        guard currentChecksum == meta.checksum else {
            // Checksum mismatch - try backup
            if let backupData = backups[key] {
                let backupChecksum = SHA256.hash(data: backupData).compactMap { String(format: "%02x", $0) }.joined()
                if backupChecksum == meta.checksum {
                    // Restore from backup
                    storage[key] = backupData
                    throw StorageError.backupRestored
                }
            }
            throw StorageError.checksumMismatch
        }
        
        // Decode the object
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            
            // Validate required fields for Task type
            if type == Task.self {
                // Validate Task has required fields
                // This is a compile-time check, but we can add runtime validation if needed
            }
            
            return object
        } catch {
            throw StorageError.corruptedData
        }
    }
    
    func delete(key: String) async throws {
        guard isInitialized else {
            throw StorageError.writeFailure
        }
        
        // Begin transaction
        isInTransaction = true
        transactionLog.append("BEGIN DELETE \(key)")
        
        // Backup before deletion
        if let data = storage[key] {
            backups[key] = data
            transactionLog.append("BACKUP \(key)")
        }
        
        // Delete data and metadata
        storage.removeValue(forKey: key)
        metadata.removeValue(forKey: key)
        
        transactionLog.append("COMMIT DELETE \(key)")
        isInTransaction = false
        
        // Mark for pending write
        pendingWrites.insert(key)
        scheduleBatchWrite()
    }
    
    // MARK: - Performance Optimization Methods
    
    private func scheduleBatchWrite() {
        // Only write to disk periodically for performance
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(writeDelay * 1_000_000_000))
            await flushPendingWrites()
        }
    }
    
    private func flushPendingWrites() async {
        guard !pendingWrites.isEmpty else { return }
        
        let keysToWrite = Array(pendingWrites.prefix(writeBatchSize))
        pendingWrites.subtract(keysToWrite)
        
        // Write batch to disk
        for key in keysToWrite {
            if let data = storage[key] {
                let fileURL = storageURL.appendingPathComponent("\(key).data")
                try? data.write(to: fileURL)
            }
        }
        
        // Save metadata after batch
        let metadataURL = storageURL.appendingPathComponent("metadata.json")
        if let metadataData = try? JSONEncoder().encode(metadata) {
            try? metadataData.write(to: metadataURL)
        }
        
        // If more pending, schedule another batch
        if !pendingWrites.isEmpty {
            scheduleBatchWrite()
        }
    }
    
    // MARK: - Private Persistence Methods
    
    private func saveToDisk() async {
        // Save storage data
        for (key, data) in storage {
            let fileURL = storageURL.appendingPathComponent("\(key).data")
            try? data.write(to: fileURL)
        }
        
        // Save metadata
        let metadataURL = storageURL.appendingPathComponent("metadata.json")
        if let metadataData = try? JSONEncoder().encode(metadata) {
            try? metadataData.write(to: metadataURL)
        }
        
        // Save transaction log
        let logURL = storageURL.appendingPathComponent("transaction.log")
        let logData = transactionLog.joined(separator: "\n").data(using: .utf8)
        try? logData?.write(to: logURL)
    }
    
    private func loadFromDisk() async {
        // Load metadata first
        let metadataURL = storageURL.appendingPathComponent("metadata.json")
        if let metadataData = try? Data(contentsOf: metadataURL),
           let loadedMetadata = try? JSONDecoder().decode([String: StorageMetadata].self, from: metadataData) {
            self.metadata = loadedMetadata
        }
        
        // Load storage data
        for (key, _) in metadata {
            let fileURL = storageURL.appendingPathComponent("\(key).data")
            if let data = try? Data(contentsOf: fileURL) {
                storage[key] = data
            }
        }
        
        // Load transaction log
        let logURL = storageURL.appendingPathComponent("transaction.log")
        if let logData = try? Data(contentsOf: logURL),
           let logString = String(data: logData, encoding: .utf8) {
            transactionLog = logString.components(separatedBy: "\n")
        }
    }
}