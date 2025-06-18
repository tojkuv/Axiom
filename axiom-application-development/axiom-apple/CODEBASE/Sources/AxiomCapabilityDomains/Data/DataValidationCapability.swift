import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Data Validation Capability Configuration

/// Configuration for Data Validation capability
public struct DataValidationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableRealTimeValidation: Bool
    public let enableBatchValidation: Bool
    public let validationTimeout: TimeInterval
    public let batchSize: Int
    public let enableCustomValidators: Bool
    public let enableSchemaValidation: Bool
    public let enableBusinessRuleValidation: Bool
    public let enableCrossFieldValidation: Bool
    public let enableAsyncValidation: Bool
    public let validationStrategies: [String: ValidationStrategy]
    public let severityLevels: Set<ValidationSeverity>
    public let enableAnalytics: Bool
    public let maxValidationErrors: Int
    public let enableCaching: Bool
    public let cacheTimeout: TimeInterval
    
    public enum ValidationStrategy: String, Codable, CaseIterable {
        case strict = "strict"           // Fail on any violation
        case lenient = "lenient"         // Allow warnings, fail on errors
        case permissive = "permissive"   // Log violations but don't fail
        case adaptive = "adaptive"       // Adjust based on context
        case custom = "custom"           // Use custom validation logic
    }
    
    public enum ValidationSeverity: String, Codable, CaseIterable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"
    }
    
    public init(
        enableRealTimeValidation: Bool = true,
        enableBatchValidation: Bool = true,
        validationTimeout: TimeInterval = 30,
        batchSize: Int = 1000,
        enableCustomValidators: Bool = true,
        enableSchemaValidation: Bool = true,
        enableBusinessRuleValidation: Bool = true,
        enableCrossFieldValidation: Bool = true,
        enableAsyncValidation: Bool = true,
        validationStrategies: [String: ValidationStrategy] = [:],
        severityLevels: Set<ValidationSeverity> = [.warning, .error, .critical],
        enableAnalytics: Bool = true,
        maxValidationErrors: Int = 100,
        enableCaching: Bool = true,
        cacheTimeout: TimeInterval = 300
    ) {
        self.enableRealTimeValidation = enableRealTimeValidation
        self.enableBatchValidation = enableBatchValidation
        self.validationTimeout = validationTimeout
        self.batchSize = batchSize
        self.enableCustomValidators = enableCustomValidators
        self.enableSchemaValidation = enableSchemaValidation
        self.enableBusinessRuleValidation = enableBusinessRuleValidation
        self.enableCrossFieldValidation = enableCrossFieldValidation
        self.enableAsyncValidation = enableAsyncValidation
        self.validationStrategies = validationStrategies
        self.severityLevels = severityLevels
        self.enableAnalytics = enableAnalytics
        self.maxValidationErrors = maxValidationErrors
        self.enableCaching = enableCaching
        self.cacheTimeout = cacheTimeout
    }
    
    public var isValid: Bool {
        validationTimeout > 0 && batchSize > 0 && maxValidationErrors > 0 && cacheTimeout > 0
    }
    
    public func merged(with other: DataValidationCapabilityConfiguration) -> DataValidationCapabilityConfiguration {
        DataValidationCapabilityConfiguration(
            enableRealTimeValidation: other.enableRealTimeValidation,
            enableBatchValidation: other.enableBatchValidation,
            validationTimeout: other.validationTimeout,
            batchSize: other.batchSize,
            enableCustomValidators: other.enableCustomValidators,
            enableSchemaValidation: other.enableSchemaValidation,
            enableBusinessRuleValidation: other.enableBusinessRuleValidation,
            enableCrossFieldValidation: other.enableCrossFieldValidation,
            enableAsyncValidation: other.enableAsyncValidation,
            validationStrategies: validationStrategies.merging(other.validationStrategies) { _, new in new },
            severityLevels: severityLevels.union(other.severityLevels),
            enableAnalytics: other.enableAnalytics,
            maxValidationErrors: other.maxValidationErrors,
            enableCaching: other.enableCaching,
            cacheTimeout: other.cacheTimeout
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> DataValidationCapabilityConfiguration {
        var adjustedTimeout = validationTimeout
        var adjustedBatchSize = batchSize
        var adjustedCacheTimeout = cacheTimeout
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(validationTimeout, 10) // Shorter timeout
            adjustedBatchSize = min(batchSize, 100) // Smaller batches
            adjustedCacheTimeout = min(cacheTimeout, 60) // Shorter cache timeout
        }
        
        return DataValidationCapabilityConfiguration(
            enableRealTimeValidation: enableRealTimeValidation,
            enableBatchValidation: enableBatchValidation,
            validationTimeout: adjustedTimeout,
            batchSize: adjustedBatchSize,
            enableCustomValidators: enableCustomValidators,
            enableSchemaValidation: enableSchemaValidation,
            enableBusinessRuleValidation: enableBusinessRuleValidation,
            enableCrossFieldValidation: enableCrossFieldValidation,
            enableAsyncValidation: enableAsyncValidation,
            validationStrategies: validationStrategies,
            severityLevels: severityLevels,
            enableAnalytics: enableAnalytics,
            maxValidationErrors: maxValidationErrors,
            enableCaching: enableCaching,
            cacheTimeout: adjustedCacheTimeout
        )
    }
}

// MARK: - Validation Rule

/// Represents a data validation rule
public struct ValidationRule: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let field: String?
    public let entityType: String?
    public let ruleType: RuleType
    public let severity: DataValidationCapabilityConfiguration.ValidationSeverity
    public let condition: ValidationCondition
    public let validator: DataValidator
    public let isEnabled: Bool
    public let metadata: [String: String]
    
    public enum RuleType: String, Codable, CaseIterable {
        case required = "required"
        case format = "format"
        case range = "range"
        case length = "length"
        case pattern = "pattern"
        case unique = "unique"
        case reference = "reference"
        case business = "business"
        case custom = "custom"
        case crossField = "cross-field"
        case conditional = "conditional"
    }
    
    public init(
        name: String,
        description: String = "",
        field: String? = nil,
        entityType: String? = nil,
        ruleType: RuleType,
        severity: DataValidationCapabilityConfiguration.ValidationSeverity = .error,
        condition: ValidationCondition = .always,
        validator: DataValidator,
        isEnabled: Bool = true,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.field = field
        self.entityType = entityType
        self.ruleType = ruleType
        self.severity = severity
        self.condition = condition
        self.validator = validator
        self.isEnabled = isEnabled
        self.metadata = metadata
    }
}

// MARK: - Validation Condition

/// Conditions under which validation rules apply
public enum ValidationCondition: Sendable {
    case always
    case onCreate
    case onUpdate
    case onDelete
    case conditional(condition: @Sendable (Data) async -> Bool)
    case fieldPresent(field: String)
    case fieldAbsent(field: String)
    case fieldEquals(field: String, value: Any)
    case custom(condition: @Sendable (Data) async -> Bool)
}

// MARK: - Data Validator

/// Represents a data validation function
public struct DataValidator: Sendable {
    public let name: String
    public let validate: @Sendable (Data, ValidationContext) async throws -> ValidationResult
    
    public init(
        name: String,
        validate: @escaping @Sendable (Data, ValidationContext) async throws -> ValidationResult
    ) {
        self.name = name
        self.validate = validate
    }
}

// MARK: - Validation Context

/// Context information for validation
public struct ValidationContext: Sendable {
    public let entityType: String?
    public let entityId: String?
    public let operation: Operation
    public let existingData: Data?
    public let metadata: [String: String]
    
    public enum Operation: String, Codable, CaseIterable {
        case create = "create"
        case update = "update"
        case delete = "delete"
        case read = "read"
        case validate = "validate"
    }
    
    public init(
        entityType: String? = nil,
        entityId: String? = nil,
        operation: Operation = .validate,
        existingData: Data? = nil,
        metadata: [String: String] = [:]
    ) {
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.existingData = existingData
        self.metadata = metadata
    }
}

// MARK: - Validation Result

/// Result of data validation
public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let violations: [ValidationViolation]
    public let warnings: [ValidationViolation]
    public let metadata: [String: String]
    public let validatedAt: Date
    public let duration: TimeInterval
    
    public init(
        isValid: Bool,
        violations: [ValidationViolation] = [],
        warnings: [ValidationViolation] = [],
        metadata: [String: String] = [:],
        duration: TimeInterval = 0
    ) {
        self.isValid = isValid
        self.violations = violations
        self.warnings = warnings
        self.metadata = metadata
        self.validatedAt = Date()
        self.duration = duration
    }
    
    public var hasErrors: Bool {
        violations.contains { $0.severity == .error || $0.severity == .critical }
    }
    
    public var hasWarnings: Bool {
        !warnings.isEmpty || violations.contains { $0.severity == .warning }
    }
}

// MARK: - Validation Violation

/// Represents a validation violation
public struct ValidationViolation: Sendable, Identifiable {
    public let id: UUID
    public let rule: String
    public let field: String?
    public let severity: DataValidationCapabilityConfiguration.ValidationSeverity
    public let message: String
    public let code: String?
    public let actualValue: String?
    public let expectedValue: String?
    public let path: String?
    public let metadata: [String: String]
    public let detectedAt: Date
    
    public init(
        rule: String,
        field: String? = nil,
        severity: DataValidationCapabilityConfiguration.ValidationSeverity,
        message: String,
        code: String? = nil,
        actualValue: String? = nil,
        expectedValue: String? = nil,
        path: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.rule = rule
        self.field = field
        self.severity = severity
        self.message = message
        self.code = code
        self.actualValue = actualValue
        self.expectedValue = expectedValue
        self.path = path
        self.metadata = metadata
        self.detectedAt = Date()
    }
}

// MARK: - Validation Schema

/// Represents a validation schema for an entity type
public struct ValidationSchema: Sendable, Identifiable {
    public let id: UUID
    public let entityType: String
    public let version: String
    public let rules: [ValidationRule]
    public let createdAt: Date
    public let updatedAt: Date
    public let metadata: [String: String]
    
    public init(
        entityType: String,
        version: String = "1.0",
        rules: [ValidationRule] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.version = version
        self.rules = rules
        self.createdAt = Date()
        self.updatedAt = Date()
        self.metadata = metadata
    }
}

// MARK: - Validation Analytics

/// Validation analytics and metrics
public struct ValidationAnalytics: Sendable, Codable {
    public let totalValidations: Int
    public let successfulValidations: Int
    public let failedValidations: Int
    public let totalViolations: Int
    public let violationsBySeverity: [String: Int]
    public let violationsByRule: [String: Int]
    public let violationsByField: [String: Int]
    public let averageValidationTime: TimeInterval
    public let successRate: Double
    public let mostCommonViolations: [String: Int]
    public let validationsByEntityType: [String: Int]
    public let performanceMetrics: PerformanceMetrics
    public let lastUpdated: Date
    
    public struct PerformanceMetrics: Sendable, Codable {
        public let averageRecordsPerSecond: Double
        public let averageMemoryUsage: UInt64
        public let peakMemoryUsage: UInt64
        public let cacheHitRate: Double
        
        public init(
            averageRecordsPerSecond: Double = 0,
            averageMemoryUsage: UInt64 = 0,
            peakMemoryUsage: UInt64 = 0,
            cacheHitRate: Double = 0
        ) {
            self.averageRecordsPerSecond = averageRecordsPerSecond
            self.averageMemoryUsage = averageMemoryUsage
            self.peakMemoryUsage = peakMemoryUsage
            self.cacheHitRate = cacheHitRate
        }
    }
    
    public init(
        totalValidations: Int = 0,
        successfulValidations: Int = 0,
        failedValidations: Int = 0,
        totalViolations: Int = 0,
        violationsBySeverity: [String: Int] = [:],
        violationsByRule: [String: Int] = [:],
        violationsByField: [String: Int] = [:],
        averageValidationTime: TimeInterval = 0,
        mostCommonViolations: [String: Int] = [:],
        validationsByEntityType: [String: Int] = [:],
        performanceMetrics: PerformanceMetrics = PerformanceMetrics(),
        lastUpdated: Date = Date()
    ) {
        self.totalValidations = totalValidations
        self.successfulValidations = successfulValidations
        self.failedValidations = failedValidations
        self.totalViolations = totalViolations
        self.violationsBySeverity = violationsBySeverity
        self.violationsByRule = violationsByRule
        self.violationsByField = violationsByField
        self.averageValidationTime = averageValidationTime
        self.successRate = totalValidations > 0 ? Double(successfulValidations) / Double(totalValidations) : 0
        self.mostCommonViolations = mostCommonViolations
        self.validationsByEntityType = validationsByEntityType
        self.performanceMetrics = performanceMetrics
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Data Validation Resource

/// Data validation resource management
public actor DataValidationCapabilityResource: AxiomCapabilityResource {
    private let configuration: DataValidationCapabilityConfiguration
    private var validationSchemas: [String: ValidationSchema] = [:]
    private var registeredValidators: [String: DataValidator] = [:]
    private var validationCache: [String: (result: ValidationResult, timestamp: Date)] = [:]
    private var analytics = ValidationAnalytics()
    private let validationQueue = OperationQueue()
    
    // Delegate for custom validation operations
    public weak var validationDelegate: DataValidationDelegate?
    
    public init(configuration: DataValidationCapabilityConfiguration) {
        self.configuration = configuration
        self.validationQueue.maxConcurrentOperationCount = 4
        self.validationQueue.qualityOfService = .userInitiated
    }
    
    public func allocate() async throws {
        // Register built-in validators
        await registerBuiltInValidators()
        
        // Load validation schemas
        await loadValidationSchemas()
    }
    
    public func deallocate() async {
        validationQueue.cancelAllOperations()
        
        validationSchemas.removeAll()
        registeredValidators.removeAll()
        validationCache.removeAll()
        analytics = ValidationAnalytics()
    }
    
    public var isAllocated: Bool {
        !registeredValidators.isEmpty
    }
    
    public func updateConfiguration(_ configuration: DataValidationCapabilityConfiguration) async throws {
        // Clear cache if caching settings changed
        if !configuration.enableCaching {
            validationCache.removeAll()
        }
    }
    
    // MARK: - Schema Management
    
    public func registerSchema(_ schema: ValidationSchema) async {
        validationSchemas[schema.entityType] = schema
    }
    
    public func getSchema(for entityType: String) async -> ValidationSchema? {
        validationSchemas[entityType]
    }
    
    public func getAllSchemas() async -> [ValidationSchema] {
        Array(validationSchemas.values)
    }
    
    public func removeSchema(for entityType: String) async {
        validationSchemas.removeValue(forKey: entityType)
    }
    
    // MARK: - Validator Management
    
    public func registerValidator(_ validator: DataValidator) async {
        registeredValidators[validator.name] = validator
    }
    
    public func getValidator(named name: String) async -> DataValidator? {
        registeredValidators[name]
    }
    
    public func getAllValidators() async -> [DataValidator] {
        Array(registeredValidators.values)
    }
    
    // MARK: - Validation Operations
    
    public func validateData(
        _ data: Data,
        entityType: String? = nil,
        context: ValidationContext = ValidationContext()
    ) async throws -> ValidationResult {
        
        let startTime = Date()
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(data: data, entityType: entityType, context: context)
            if let cached = validationCache[cacheKey],
               Date().timeIntervalSince(cached.timestamp) < configuration.cacheTimeout {
                await updateCacheHitAnalytics()
                return cached.result
            }
        }
        
        var allViolations: [ValidationViolation] = []
        var allWarnings: [ValidationViolation] = []
        
        // Get validation schema
        var schema: ValidationSchema?
        if let entityType = entityType {
            schema = validationSchemas[entityType]
        }
        
        // Validate against schema rules
        if let schema = schema {
            let (violations, warnings) = await validateAgainstSchema(data: data, schema: schema, context: context)
            allViolations.append(contentsOf: violations)
            allWarnings.append(contentsOf: warnings)
        }
        
        // Perform additional validations
        if configuration.enableSchemaValidation {
            let schemaViolations = await validateDataStructure(data: data, entityType: entityType)
            allViolations.append(contentsOf: schemaViolations)
        }
        
        if configuration.enableBusinessRuleValidation {
            let businessViolations = await validateBusinessRules(data: data, context: context)
            allViolations.append(contentsOf: businessViolations)
        }
        
        if configuration.enableCrossFieldValidation {
            let crossFieldViolations = await validateCrossFieldRules(data: data, schema: schema)
            allViolations.append(contentsOf: crossFieldViolations)
        }
        
        // Custom validation through delegate
        if configuration.enableCustomValidators, let delegate = validationDelegate {
            let customResult = try await delegate.validateData(data, context: context)
            allViolations.append(contentsOf: customResult.violations)
            allWarnings.append(contentsOf: customResult.warnings)
        }
        
        // Determine if validation passed
        let strategy = getValidationStrategy(for: entityType)
        let isValid = determineValidationResult(
            violations: allViolations,
            strategy: strategy
        )
        
        let duration = Date().timeIntervalSince(startTime)
        let result = ValidationResult(
            isValid: isValid,
            violations: allViolations,
            warnings: allWarnings,
            duration: duration
        )
        
        // Cache result
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(data: data, entityType: entityType, context: context)
            validationCache[cacheKey] = (result: result, timestamp: Date())
            await cleanupCache()
        }
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateValidationAnalytics(result: result, entityType: entityType)
        }
        
        return result
    }
    
    public func validateBatch(
        _ dataItems: [(data: Data, entityType: String?, context: ValidationContext)]
    ) async throws -> [ValidationResult] {
        
        guard configuration.enableBatchValidation else {
            throw AxiomCapabilityError.dataValidationError("Batch validation not enabled")
        }
        
        var results: [ValidationResult] = []
        
        // Process in batches
        let batchSize = configuration.batchSize
        for i in stride(from: 0, to: dataItems.count, by: batchSize) {
            let endIndex = min(i + batchSize, dataItems.count)
            let batch = Array(dataItems[i..<endIndex])
            
            // Validate batch items concurrently
            let batchResults = await withTaskGroup(of: ValidationResult?.self) { group in
                for item in batch {
                    group.addTask {
                        do {
                            return try await self.validateData(
                                item.data,
                                entityType: item.entityType,
                                context: item.context
                            )
                        } catch {
                            return ValidationResult(
                                isValid: false,
                                violations: [
                                    ValidationViolation(
                                        rule: "validation-error",
                                        severity: .error,
                                        message: "Validation failed: \(error.localizedDescription)"
                                    )
                                ]
                            )
                        }
                    }
                }
                
                var batchResults: [ValidationResult] = []
                for await result in group {
                    if let result = result {
                        batchResults.append(result)
                    }
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    public func validateField(
        _ value: Any,
        field: String,
        entityType: String? = nil,
        rules: [ValidationRule]? = nil
    ) async throws -> ValidationResult {
        
        // Get rules for the field
        var fieldRules: [ValidationRule] = []
        
        if let rules = rules {
            fieldRules = rules.filter { $0.field == field }
        } else if let entityType = entityType,
                  let schema = validationSchemas[entityType] {
            fieldRules = schema.rules.filter { $0.field == field }
        }
        
        var violations: [ValidationViolation] = []
        
        // Validate against each rule
        for rule in fieldRules {
            guard rule.isEnabled else { continue }
            
            let violation = await validateFieldAgainstRule(
                value: value,
                field: field,
                rule: rule
            )
            
            if let violation = violation {
                violations.append(violation)
            }
        }
        
        return ValidationResult(
            isValid: violations.isEmpty,
            violations: violations
        )
    }
    
    public func getAnalytics() async -> ValidationAnalytics {
        if configuration.enableAnalytics {
            return analytics
        } else {
            return ValidationAnalytics()
        }
    }
    
    public func clearCache() async {
        validationCache.removeAll()
    }
    
    public func clearAnalytics() async {
        analytics = ValidationAnalytics()
    }
    
    // MARK: - Private Methods
    
    private func validateAgainstSchema(
        data: Data,
        schema: ValidationSchema,
        context: ValidationContext
    ) async -> ([ValidationViolation], [ValidationViolation]) {
        
        var violations: [ValidationViolation] = []
        var warnings: [ValidationViolation] = []
        
        for rule in schema.rules {
            guard rule.isEnabled else { continue }
            
            // Check if rule condition is met
            let conditionMet = await evaluateCondition(rule.condition, data: data)
            guard conditionMet else { continue }
            
            do {
                let result = try await rule.validator.validate(data, context)
                
                if !result.isValid {
                    for violation in result.violations {
                        if violation.severity == .warning {
                            warnings.append(violation)
                        } else {
                            violations.append(violation)
                        }
                    }
                    warnings.append(contentsOf: result.warnings)
                }
            } catch {
                violations.append(
                    ValidationViolation(
                        rule: rule.name,
                        field: rule.field,
                        severity: .error,
                        message: "Validation error: \(error.localizedDescription)"
                    )
                )
            }
        }
        
        return (violations, warnings)
    }
    
    private func validateDataStructure(data: Data, entityType: String?) async -> [ValidationViolation] {
        var violations: [ValidationViolation] = []
        
        // Basic JSON structure validation
        do {
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            violations.append(
                ValidationViolation(
                    rule: "json-structure",
                    severity: .error,
                    message: "Invalid JSON structure: \(error.localizedDescription)"
                )
            )
        }
        
        return violations
    }
    
    private func validateBusinessRules(data: Data, context: ValidationContext) async -> [ValidationViolation] {
        var violations: [ValidationViolation] = []
        
        // Use delegate for business rule validation
        if let delegate = validationDelegate {
            do {
                let result = try await delegate.validateBusinessRules(data, context: context)
                violations.append(contentsOf: result.violations)
            } catch {
                violations.append(
                    ValidationViolation(
                        rule: "business-rules",
                        severity: .error,
                        message: "Business rule validation failed: \(error.localizedDescription)"
                    )
                )
            }
        }
        
        return violations
    }
    
    private func validateCrossFieldRules(data: Data, schema: ValidationSchema?) async -> [ValidationViolation] {
        var violations: [ValidationViolation] = []
        
        guard let schema = schema else { return violations }
        
        // Get cross-field rules
        let crossFieldRules = schema.rules.filter { $0.ruleType == .crossField }
        
        for rule in crossFieldRules {
            guard rule.isEnabled else { continue }
            
            do {
                let context = ValidationContext()
                let result = try await rule.validator.validate(data, context)
                
                if !result.isValid {
                    violations.append(contentsOf: result.violations)
                }
            } catch {
                violations.append(
                    ValidationViolation(
                        rule: rule.name,
                        severity: .error,
                        message: "Cross-field validation failed: \(error.localizedDescription)"
                    )
                )
            }
        }
        
        return violations
    }
    
    private func validateFieldAgainstRule(
        value: Any,
        field: String,
        rule: ValidationRule
    ) async -> ValidationViolation? {
        
        switch rule.ruleType {
        case .required:
            if value is NSNull || (value as? String)?.isEmpty == true {
                return ValidationViolation(
                    rule: rule.name,
                    field: field,
                    severity: rule.severity,
                    message: "Field '\(field)' is required but was empty or null"
                )
            }
            
        case .format:
            // Add format validation logic
            break
            
        case .range:
            // Add range validation logic
            break
            
        case .length:
            if let stringValue = value as? String,
               let metadata = rule.metadata["maxLength"],
               let maxLength = Int(metadata),
               stringValue.count > maxLength {
                return ValidationViolation(
                    rule: rule.name,
                    field: field,
                    severity: rule.severity,
                    message: "Field '\(field)' exceeds maximum length of \(maxLength)"
                )
            }
            
        case .pattern:
            if let stringValue = value as? String,
               let pattern = rule.metadata["pattern"] {
                do {
                    let regex = try NSRegularExpression(pattern: pattern)
                    let range = NSRange(location: 0, length: stringValue.utf16.count)
                    if regex.firstMatch(in: stringValue, options: [], range: range) == nil {
                        return ValidationViolation(
                            rule: rule.name,
                            field: field,
                            severity: rule.severity,
                            message: "Field '\(field)' does not match required pattern"
                        )
                    }
                } catch {
                    return ValidationViolation(
                        rule: rule.name,
                        field: field,
                        severity: .error,
                        message: "Invalid regex pattern in validation rule"
                    )
                }
            }
            
        default:
            break
        }
        
        return nil
    }
    
    private func evaluateCondition(_ condition: ValidationCondition, data: Data) async -> Bool {
        switch condition {
        case .always:
            return true
        case .onCreate, .onUpdate, .onDelete:
            // Would need context to determine operation type
            return true
        case .conditional(let conditionFunc):
            return await conditionFunc(data)
        case .fieldPresent(let field):
            return await isFieldPresent(field, in: data)
        case .fieldAbsent(let field):
            return !await isFieldPresent(field, in: data)
        case .fieldEquals(let field, let expectedValue):
            return await isFieldEqual(field, to: expectedValue, in: data)
        case .custom(let conditionFunc):
            return await conditionFunc(data)
        }
    }
    
    private func isFieldPresent(_ field: String, in data: Data) async -> Bool {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            return json[field] != nil
        } catch {
            return false
        }
    }
    
    private func isFieldEqual(_ field: String, to expectedValue: Any, in data: Data) async -> Bool {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            
            guard let actualValue = json[field] else {
                return false
            }
            
            // Simplified equality check
            return String(describing: actualValue) == String(describing: expectedValue)
        } catch {
            return false
        }
    }
    
    private func getValidationStrategy(for entityType: String?) -> DataValidationCapabilityConfiguration.ValidationStrategy {
        if let entityType = entityType,
           let strategy = configuration.validationStrategies[entityType] {
            return strategy
        }
        return .strict // Default strategy
    }
    
    private func determineValidationResult(
        violations: [ValidationViolation],
        strategy: DataValidationCapabilityConfiguration.ValidationStrategy
    ) -> Bool {
        
        switch strategy {
        case .strict:
            return violations.isEmpty
        case .lenient:
            return !violations.contains { $0.severity == .error || $0.severity == .critical }
        case .permissive:
            return !violations.contains { $0.severity == .critical }
        case .adaptive, .custom:
            // Would use more sophisticated logic
            return violations.isEmpty
        }
    }
    
    private func generateCacheKey(data: Data, entityType: String?, context: ValidationContext) -> String {
        let dataHash = data.sha256.prefix(16)
        let typeString = entityType ?? "unknown"
        let contextString = "\(context.operation.rawValue)-\(context.entityId ?? "")"
        return "\(dataHash)-\(typeString)-\(contextString)"
    }
    
    private func cleanupCache() async {
        let now = Date()
        validationCache = validationCache.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) < configuration.cacheTimeout
        }
    }
    
    private func registerBuiltInValidators() async {
        // Register common validators
        let requiredValidator = DataValidator(name: "required") { data, context in
            // Simplified required validation
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return ValidationResult(isValid: false, violations: [
                        ValidationViolation(
                            rule: "required",
                            severity: .error,
                            message: "Invalid JSON data"
                        )
                    ])
                }
                
                // Check if any required fields are missing
                // This would be more sophisticated in a real implementation
                return ValidationResult(isValid: true)
            } catch {
                return ValidationResult(isValid: false, violations: [
                    ValidationViolation(
                        rule: "required",
                        severity: .error,
                        message: "JSON parsing failed: \(error.localizedDescription)"
                    )
                ])
            }
        }
        
        registeredValidators["required"] = requiredValidator
        
        // Add more built-in validators as needed
    }
    
    private func loadValidationSchemas() async {
        // Load validation schemas from storage or configuration
        // Placeholder implementation
    }
    
    private func updateValidationAnalytics(result: ValidationResult, entityType: String?) async {
        // Update analytics with validation result
        // Implementation would update the analytics struct
    }
    
    private func updateCacheHitAnalytics() async {
        // Update cache hit analytics
        // Implementation would update the analytics struct
    }
}

// MARK: - Data Validation Delegate

/// Delegate protocol for custom validation operations
public protocol DataValidationDelegate: AnyObject, Sendable {
    func validateData(_ data: Data, context: ValidationContext) async throws -> ValidationResult
    func validateBusinessRules(_ data: Data, context: ValidationContext) async throws -> ValidationResult
}

// MARK: - Data Validation Capability Implementation

/// Data validation capability providing comprehensive data integrity validation
public actor DataValidationCapability: DomainCapability {
    public typealias ConfigurationType = DataValidationCapabilityConfiguration
    public typealias ResourceType = DataValidationCapabilityResource
    
    private var _configuration: DataValidationCapabilityConfiguration
    private var _resources: DataValidationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(15)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "data-validation-capability" }
    
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
    
    public var configuration: DataValidationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: DataValidationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: DataValidationCapabilityConfiguration = DataValidationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = DataValidationCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: DataValidationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid data validation configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Data validation is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Data validation doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Validation Operations
    
    /// Validate data against registered schemas and rules
    public func validateData(
        _ data: Data,
        entityType: String? = nil,
        context: ValidationContext = ValidationContext()
    ) async throws -> ValidationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        return try await _resources.validateData(data, entityType: entityType, context: context)
    }
    
    /// Validate multiple data items in batch
    public func validateBatch(
        _ dataItems: [(data: Data, entityType: String?, context: ValidationContext)]
    ) async throws -> [ValidationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        return try await _resources.validateBatch(dataItems)
    }
    
    /// Validate a single field value
    public func validateField(
        _ value: Any,
        field: String,
        entityType: String? = nil,
        rules: [ValidationRule]? = nil
    ) async throws -> ValidationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        return try await _resources.validateField(value, field: field, entityType: entityType, rules: rules)
    }
    
    /// Register validation schema for entity type
    public func registerSchema(_ schema: ValidationSchema) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        await _resources.registerSchema(schema)
    }
    
    /// Get validation schema for entity type
    public func getSchema(for entityType: String) async throws -> ValidationSchema? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        return await _resources.getSchema(for: entityType)
    }
    
    /// Register custom validator
    public func registerValidator(_ validator: DataValidator) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        await _resources.registerValidator(validator)
    }
    
    /// Get validation analytics
    public func getAnalytics() async throws -> ValidationAnalytics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        return await _resources.getAnalytics()
    }
    
    /// Clear validation cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        await _resources.clearCache()
    }
    
    /// Set validation delegate
    public func setValidationDelegate(_ delegate: DataValidationDelegate?) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data validation capability not available")
        }
        
        _resources.validationDelegate = delegate
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extensions

extension Data {
    var sha256: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Need to import CommonCrypto for SHA256
import CommonCrypto

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Data validation specific errors
    public static func dataValidationError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Data Validation: \(message)")
    }
    
    public static func validationRuleFailed(_ rule: String, field: String?) -> AxiomCapabilityError {
        let fieldInfo = field.map { " for field '\($0)'" } ?? ""
        return .operationFailed("Validation rule '\(rule)' failed\(fieldInfo)")
    }
    
    public static func validationSchemaNotFound(_ entityType: String) -> AxiomCapabilityError {
        .operationFailed("Validation schema not found for entity type: \(entityType)")
    }
    
    public static func validatorNotRegistered(_ name: String) -> AxiomCapabilityError {
        .operationFailed("Validator not registered: \(name)")
    }
}