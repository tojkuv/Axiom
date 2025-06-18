import Foundation
import SQLite3
import AxiomCore
import AxiomCapabilities

// MARK: - SQLite Capability Configuration

/// Configuration for SQLite capability
public struct SQLiteCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let databasePath: String
    public let enableWALMode: Bool
    public let enableForeignKeys: Bool
    public let cacheSize: Int
    public let busyTimeout: Int
    public let maxConnections: Int
    public let enableSecureDelete: Bool
    public let enableMemoryMapping: Bool
    
    public init(
        databasePath: String,
        enableWALMode: Bool = true,
        enableForeignKeys: Bool = true,
        cacheSize: Int = 2000,
        busyTimeout: Int = 30000,
        maxConnections: Int = 10,
        enableSecureDelete: Bool = true,
        enableMemoryMapping: Bool = true
    ) {
        self.databasePath = databasePath
        self.enableWALMode = enableWALMode
        self.enableForeignKeys = enableForeignKeys
        self.cacheSize = cacheSize
        self.busyTimeout = busyTimeout
        self.maxConnections = maxConnections
        self.enableSecureDelete = enableSecureDelete
        self.enableMemoryMapping = enableMemoryMapping
    }
    
    public var isValid: Bool {
        !databasePath.isEmpty && cacheSize > 0 && busyTimeout > 0 && maxConnections > 0
    }
    
    public func merged(with other: SQLiteCapabilityConfiguration) -> SQLiteCapabilityConfiguration {
        SQLiteCapabilityConfiguration(
            databasePath: other.databasePath,
            enableWALMode: other.enableWALMode,
            enableForeignKeys: other.enableForeignKeys,
            cacheSize: other.cacheSize,
            busyTimeout: other.busyTimeout,
            maxConnections: other.maxConnections,
            enableSecureDelete: other.enableSecureDelete,
            enableMemoryMapping: other.enableMemoryMapping
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> SQLiteCapabilityConfiguration {
        var adjustedCacheSize = cacheSize
        var adjustedConnections = maxConnections
        var adjustedWAL = enableWALMode
        
        if environment.isLowPowerMode {
            adjustedCacheSize = max(100, cacheSize / 2)
            adjustedConnections = max(1, maxConnections / 2)
            adjustedWAL = false
        }
        
        if environment.isDebug {
            adjustedConnections = min(adjustedConnections, 5)
        }
        
        return SQLiteCapabilityConfiguration(
            databasePath: databasePath,
            enableWALMode: adjustedWAL,
            enableForeignKeys: enableForeignKeys,
            cacheSize: adjustedCacheSize,
            busyTimeout: busyTimeout,
            maxConnections: adjustedConnections,
            enableSecureDelete: enableSecureDelete,
            enableMemoryMapping: enableMemoryMapping
        )
    }
}

// MARK: - SQLite Connection Pool

/// SQLite connection wrapper
public actor SQLiteConnection {
    private var db: OpaquePointer?
    private let path: String
    private let configuration: SQLiteCapabilityConfiguration
    private var isOpen: Bool = false
    
    public init(path: String, configuration: SQLiteCapabilityConfiguration) {
        self.path = path
        self.configuration = configuration
    }
    
    deinit {
        if isOpen {
            sqlite3_close(db)
        }
    }
    
    public func open() async throws {
        guard !isOpen else { return }
        
        let result = sqlite3_open(path, &db)
        guard result == SQLITE_OK else {
            throw AxiomCapabilityError.initializationFailed("SQLite open failed: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        isOpen = true
        
        // Configure database
        try await configure()
    }
    
    public func close() async {
        guard isOpen else { return }
        sqlite3_close(db)
        db = nil
        isOpen = false
    }
    
    private func configure() async throws {
        // Enable WAL mode
        if configuration.enableWALMode {
            try await execute("PRAGMA journal_mode=WAL")
        }
        
        // Enable foreign keys
        if configuration.enableForeignKeys {
            try await execute("PRAGMA foreign_keys=ON")
        }
        
        // Set cache size
        try await execute("PRAGMA cache_size=\(configuration.cacheSize)")
        
        // Set busy timeout
        sqlite3_busy_timeout(db, Int32(configuration.busyTimeout))
        
        // Enable secure delete
        if configuration.enableSecureDelete {
            try await execute("PRAGMA secure_delete=ON")
        }
        
        // Enable memory mapping
        if configuration.enableMemoryMapping {
            try await execute("PRAGMA mmap_size=268435456") // 256MB
        }
    }
    
    public func execute(_ sql: String) async throws {
        guard isOpen, let db = db else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite connection not open")
        }
        
        let result = sqlite3_exec(db, sql, nil, nil, nil)
        guard result == SQLITE_OK else {
            throw AxiomCapabilityError.operationFailed("SQLite execute failed: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    public func prepare(_ sql: String) async throws -> OpaquePointer? {
        guard isOpen, let db = db else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite connection not open")
        }
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        guard result == SQLITE_OK else {
            throw AxiomCapabilityError.operationFailed("SQLite prepare failed: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        return statement
    }
    
    public var isConnected: Bool {
        isOpen
    }
}

// MARK: - SQLite Connection Pool

/// Connection pool for SQLite
public actor SQLiteConnectionPool {
    private var availableConnections: [SQLiteConnection] = []
    private var busyConnections: Set<ObjectIdentifier> = []
    private let configuration: SQLiteCapabilityConfiguration
    private let maxConnections: Int
    
    public init(configuration: SQLiteCapabilityConfiguration) {
        self.configuration = configuration
        self.maxConnections = configuration.maxConnections
    }
    
    public func getConnection() async throws -> SQLiteConnection {
        // Try to reuse an available connection
        if let connection = availableConnections.first {
            availableConnections.removeFirst()
            busyConnections.insert(ObjectIdentifier(connection))
            return connection
        }
        
        // Create new connection if under limit
        if availableConnections.count + busyConnections.count < maxConnections {
            let connection = SQLiteConnection(path: configuration.databasePath, configuration: configuration)
            try await connection.open()
            busyConnections.insert(ObjectIdentifier(connection))
            return connection
        }
        
        throw AxiomCapabilityError.resourceAllocationFailed("SQLite connection pool exhausted")
    }
    
    public func returnConnection(_ connection: SQLiteConnection) async {
        let id = ObjectIdentifier(connection)
        busyConnections.remove(id)
        
        if await connection.isConnected {
            availableConnections.append(connection)
        }
    }
    
    public func closeAll() async {
        for connection in availableConnections {
            await connection.close()
        }
        availableConnections.removeAll()
        busyConnections.removeAll()
    }
}

// MARK: - SQLite Resource

/// SQLite resource management
public actor SQLiteCapabilityResource: AxiomCapabilityResource {
    private let configuration: SQLiteCapabilityConfiguration
    private var connectionPool: SQLiteConnectionPool?
    
    public init(configuration: SQLiteCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public func allocate() async throws {
        // Ensure database directory exists
        let databaseURL = URL(fileURLWithPath: configuration.databasePath)
        let databaseDirectory = databaseURL.deletingLastPathComponent()
        
        try FileManager.default.createDirectory(
            at: databaseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Create connection pool
        connectionPool = SQLiteConnectionPool(configuration: configuration)
        
        // Test initial connection
        let testConnection = try await connectionPool!.getConnection()
        await connectionPool!.returnConnection(testConnection)
    }
    
    public func deallocate() async {
        await connectionPool?.closeAll()
        connectionPool = nil
    }
    
    public var isAllocated: Bool {
        connectionPool != nil
    }
    
    public func updateConfiguration(_ configuration: SQLiteCapabilityConfiguration) async throws {
        // SQLite configuration changes require reallocation
        if isAllocated {
            await deallocate()
            try await allocate()
        }
    }
    
    // MARK: - Connection Access
    
    public func withConnection<T>(_ operation: (SQLiteConnection) async throws -> T) async throws -> T {
        guard let pool = connectionPool else {
            throw AxiomCapabilityError.resourceAllocationFailed("SQLite connection pool not available")
        }
        
        let connection = try await pool.getConnection()
        defer {
            Task {
                await pool.returnConnection(connection)
            }
        }
        
        return try await operation(connection)
    }
}

// MARK: - SQLite Operations

/// SQLite query result
public struct SQLiteQueryResult: Sendable {
    public let rows: [[String: Any]]
    public let columnCount: Int
    public let rowCount: Int
    
    public init(rows: [[String: Any]] = []) {
        self.rows = rows
        self.columnCount = rows.first?.count ?? 0
        self.rowCount = rows.count
    }
}

/// SQLite operation types
public enum SQLiteOperation: Sendable {
    case query(String)
    case execute(String)
    case transaction([String])
    case batch([String])
}

// MARK: - SQLite Capability Implementation

/// SQLite capability providing direct database access
public actor SQLiteCapability: DomainCapability {
    public typealias ConfigurationType = SQLiteCapabilityConfiguration
    public typealias ResourceType = SQLiteCapabilityResource
    
    private var _configuration: SQLiteCapabilityConfiguration
    private var _resources: SQLiteCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "sqlite-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: SQLiteCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: SQLiteCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: SQLiteCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = SQLiteCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.deallocate()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: SQLiteCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid SQLite configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // SQLite is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // SQLite doesn't require special permissions for local files
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - SQLite Operations
    
    /// Execute a SQL query and return results
    public func query(_ sql: String) async throws -> SQLiteQueryResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite capability not available")
        }
        
        return try await _resources.withConnection { connection in
            guard let statement = try await connection.prepare(sql) else {
                throw AxiomCapabilityError.operationFailed("Failed to prepare SQLite statement")
            }
            
            defer {
                sqlite3_finalize(statement)
            }
            
            var rows: [[String: Any]] = []
            
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: Any] = [:]
                let columnCount = sqlite3_column_count(statement)
                
                for i in 0..<columnCount {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    let columnType = sqlite3_column_type(statement, i)
                    
                    switch columnType {
                    case SQLITE_INTEGER:
                        row[columnName] = sqlite3_column_int64(statement, i)
                    case SQLITE_FLOAT:
                        row[columnName] = sqlite3_column_double(statement, i)
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(statement, i) {
                            row[columnName] = String(cString: text)
                        }
                    case SQLITE_BLOB:
                        let bytes = sqlite3_column_blob(statement, i)
                        let length = sqlite3_column_bytes(statement, i)
                        if let bytes = bytes {
                            row[columnName] = Data(bytes: bytes, count: Int(length))
                        }
                    case SQLITE_NULL:
                        row[columnName] = NSNull()
                    default:
                        row[columnName] = NSNull()
                    }
                }
                
                rows.append(row)
            }
            
            return SQLiteQueryResult(rows: rows)
        }
    }
    
    /// Execute a SQL statement
    public func execute(_ sql: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite capability not available")
        }
        
        try await _resources.withConnection { connection in
            try await connection.execute(sql)
        }
    }
    
    /// Execute multiple statements in a transaction
    public func transaction(_ statements: [String]) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite capability not available")
        }
        
        try await _resources.withConnection { connection in
            try await connection.execute("BEGIN TRANSACTION")
            
            do {
                for statement in statements {
                    try await connection.execute(statement)
                }
                try await connection.execute("COMMIT")
            } catch {
                try await connection.execute("ROLLBACK")
                throw error
            }
        }
    }
    
    /// Execute batch statements
    public func batch(_ statements: [String]) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite capability not available")
        }
        
        try await _resources.withConnection { connection in
            for statement in statements {
                try await connection.execute(statement)
            }
        }
    }
    
    /// Get database file size
    public func getDatabaseSize() async throws -> UInt64 {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("SQLite capability not available")
        }
        
        let databasePath = await _configuration.databasePath
        let attributes = try FileManager.default.attributesOfItem(atPath: databasePath)
        return attributes[.size] as? UInt64 ?? 0
    }
    
    /// Vacuum database to reclaim space
    public func vacuum() async throws {
        try await execute("VACUUM")
    }
    
    /// Analyze database for query optimization
    public func analyze() async throws {
        try await execute("ANALYZE")
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// SQLite specific errors
    public static func sqliteError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("SQLite: \(message)")
    }
    
    public static func sqliteConnectionFailed(_ error: String) -> AxiomCapabilityError {
        .initializationFailed("SQLite connection failed: \(error)")
    }
    
    public static func sqliteQueryFailed(_ error: String) -> AxiomCapabilityError {
        .operationFailed("SQLite query failed: \(error)")
    }
}