import Foundation
import UIKit
import CoreImage
import ImageIO
import AxiomCore
import AxiomCapabilities

// MARK: - Image Cache Capability Configuration

/// Configuration for Image Cache capability
public struct ImageCacheCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let memoryLimit: UInt64
    public let diskLimit: UInt64
    public let maxItemCount: Int
    public let enableThumbnails: Bool
    public let thumbnailSizes: [ThumbnailSize]
    public let compressionQuality: CompressionQuality
    public let supportedFormats: Set<ImageFormat>
    public let enableProgressive: Bool
    public let enableMemoryWarningHandling: Bool
    public let imageProcessingOptions: ImageProcessingOptions
    public let cachingStrategy: CachingStrategy
    public let evictionPolicy: EvictionPolicy
    public let enableMetrics: Bool
    
    public struct ThumbnailSize: Codable, Hashable {
        public let width: Int
        public let height: Int
        public let scale: CGFloat
        
        public init(width: Int, height: Int, scale: CGFloat = 1.0) {
            self.width = width
            self.height = height
            self.scale = scale
        }
        
        public var cgSize: CGSize {
            CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
        }
    }
    
    public enum CompressionQuality: String, Codable, CaseIterable {
        case lossless = "lossless"
        case high = "high"         // 0.9
        case medium = "medium"     // 0.7
        case low = "low"          // 0.5
        case minimum = "minimum"   // 0.1
        
        public var jpegQuality: CGFloat {
            switch self {
            case .lossless: return 1.0
            case .high: return 0.9
            case .medium: return 0.7
            case .low: return 0.5
            case .minimum: return 0.1
            }
        }
    }
    
    public enum ImageFormat: String, Codable, CaseIterable {
        case jpeg = "jpeg"
        case png = "png"
        case heif = "heif"
        case webp = "webp"
        case gif = "gif"
        case tiff = "tiff"
        case bmp = "bmp"
        
        public var uti: String {
            switch self {
            case .jpeg: return "public.jpeg"
            case .png: return "public.png"
            case .heif: return "public.heif"
            case .webp: return "org.webmproject.webp"
            case .gif: return "com.compuserve.gif"
            case .tiff: return "public.tiff"
            case .bmp: return "com.microsoft.bmp"
            }
        }
    }
    
    public struct ImageProcessingOptions: Codable {
        public let enableResize: Bool
        public let enableCrop: Bool
        public let enableRotation: Bool
        public let enableColorAdjustment: Bool
        public let enableFilters: Bool
        public let maxDimension: Int
        
        public init(
            enableResize: Bool = true,
            enableCrop: Bool = true,
            enableRotation: Bool = true,
            enableColorAdjustment: Bool = false,
            enableFilters: Bool = false,
            maxDimension: Int = 4096
        ) {
            self.enableResize = enableResize
            self.enableCrop = enableCrop
            self.enableRotation = enableRotation
            self.enableColorAdjustment = enableColorAdjustment
            self.enableFilters = enableFilters
            self.maxDimension = maxDimension
        }
    }
    
    public enum CachingStrategy: String, Codable, CaseIterable {
        case aggressive = "aggressive"     // Cache everything
        case smart = "smart"              // Cache based on usage patterns
        case conservative = "conservative" // Cache only frequently accessed
        case onDemand = "on-demand"       // Cache only when explicitly requested
    }
    
    public enum EvictionPolicy: String, Codable, CaseIterable {
        case lru = "least-recently-used"
        case lfu = "least-frequently-used"
        case size = "largest-first"
        case age = "oldest-first"
        case smart = "smart-adaptive"
    }
    
    public init(
        memoryLimit: UInt64 = 100 * 1024 * 1024,  // 100MB
        diskLimit: UInt64 = 1024 * 1024 * 1024,   // 1GB
        maxItemCount: Int = 1000,
        enableThumbnails: Bool = true,
        thumbnailSizes: [ThumbnailSize] = [
            ThumbnailSize(width: 150, height: 150),
            ThumbnailSize(width: 300, height: 300),
            ThumbnailSize(width: 600, height: 600)
        ],
        compressionQuality: CompressionQuality = .high,
        supportedFormats: Set<ImageFormat> = [.jpeg, .png, .heif],
        enableProgressive: Bool = true,
        enableMemoryWarningHandling: Bool = true,
        imageProcessingOptions: ImageProcessingOptions = ImageProcessingOptions(),
        cachingStrategy: CachingStrategy = .smart,
        evictionPolicy: EvictionPolicy = .smart,
        enableMetrics: Bool = true
    ) {
        self.memoryLimit = memoryLimit
        self.diskLimit = diskLimit
        self.maxItemCount = maxItemCount
        self.enableThumbnails = enableThumbnails
        self.thumbnailSizes = thumbnailSizes
        self.compressionQuality = compressionQuality
        self.supportedFormats = supportedFormats
        self.enableProgressive = enableProgressive
        self.enableMemoryWarningHandling = enableMemoryWarningHandling
        self.imageProcessingOptions = imageProcessingOptions
        self.cachingStrategy = cachingStrategy
        self.evictionPolicy = evictionPolicy
        self.enableMetrics = enableMetrics
    }
    
    public var isValid: Bool {
        memoryLimit > 0 && diskLimit > 0 && maxItemCount > 0 && !thumbnailSizes.isEmpty
    }
    
    public func merged(with other: ImageCacheCapabilityConfiguration) -> ImageCacheCapabilityConfiguration {
        ImageCacheCapabilityConfiguration(
            memoryLimit: other.memoryLimit,
            diskLimit: other.diskLimit,
            maxItemCount: other.maxItemCount,
            enableThumbnails: other.enableThumbnails,
            thumbnailSizes: other.thumbnailSizes,
            compressionQuality: other.compressionQuality,
            supportedFormats: supportedFormats.union(other.supportedFormats),
            enableProgressive: other.enableProgressive,
            enableMemoryWarningHandling: other.enableMemoryWarningHandling,
            imageProcessingOptions: other.imageProcessingOptions,
            cachingStrategy: other.cachingStrategy,
            evictionPolicy: other.evictionPolicy,
            enableMetrics: other.enableMetrics
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ImageCacheCapabilityConfiguration {
        var adjustedMemoryLimit = memoryLimit
        var adjustedDiskLimit = diskLimit
        var adjustedItemCount = maxItemCount
        var adjustedQuality = compressionQuality
        
        if environment.isLowPowerMode {
            adjustedMemoryLimit = min(memoryLimit, 25 * 1024 * 1024) // 25MB limit
            adjustedDiskLimit = min(diskLimit, 256 * 1024 * 1024)    // 256MB limit
            adjustedItemCount = min(maxItemCount, 200)
            adjustedQuality = .low // Lower quality to save space/processing
        }
        
        return ImageCacheCapabilityConfiguration(
            memoryLimit: adjustedMemoryLimit,
            diskLimit: adjustedDiskLimit,
            maxItemCount: adjustedItemCount,
            enableThumbnails: enableThumbnails,
            thumbnailSizes: thumbnailSizes,
            compressionQuality: adjustedQuality,
            supportedFormats: supportedFormats,
            enableProgressive: enableProgressive,
            enableMemoryWarningHandling: enableMemoryWarningHandling,
            imageProcessingOptions: imageProcessingOptions,
            cachingStrategy: cachingStrategy,
            evictionPolicy: evictionPolicy,
            enableMetrics: enableMetrics
        )
    }
}

// MARK: - Cached Image Item

/// Cached image item with rich metadata
public struct CachedImageItem: Sendable {
    public let key: String
    public let originalImage: UIImage?
    public let thumbnails: [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage]
    public let imageData: Data
    public let metadata: ImageMetadata
    public let creationTime: Date
    public let lastAccessTime: Date
    public let accessCount: Int
    public let size: UInt64
    public let format: ImageCacheCapabilityConfiguration.ImageFormat
    
    public struct ImageMetadata: Sendable {
        public let dimensions: CGSize
        public let orientation: UIImage.Orientation
        public let colorSpace: String?
        public let dpi: CGFloat
        public let hasAlpha: Bool
        public let isAnimated: Bool
        public let frameCount: Int
        public let sourceURL: URL?
        public let customAttributes: [String: String]
        
        public init(
            dimensions: CGSize,
            orientation: UIImage.Orientation = .up,
            colorSpace: String? = nil,
            dpi: CGFloat = 72.0,
            hasAlpha: Bool = false,
            isAnimated: Bool = false,
            frameCount: Int = 1,
            sourceURL: URL? = nil,
            customAttributes: [String: String] = [:]
        ) {
            self.dimensions = dimensions
            self.orientation = orientation
            self.colorSpace = colorSpace
            self.dpi = dpi
            self.hasAlpha = hasAlpha
            self.isAnimated = isAnimated
            self.frameCount = frameCount
            self.sourceURL = sourceURL
            self.customAttributes = customAttributes
        }
    }
    
    public init(
        key: String,
        originalImage: UIImage?,
        thumbnails: [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage] = [:],
        imageData: Data,
        metadata: ImageMetadata,
        creationTime: Date = Date(),
        lastAccessTime: Date = Date(),
        accessCount: Int = 0,
        format: ImageCacheCapabilityConfiguration.ImageFormat
    ) {
        self.key = key
        self.originalImage = originalImage
        self.thumbnails = thumbnails
        self.imageData = imageData
        self.metadata = metadata
        self.creationTime = creationTime
        self.lastAccessTime = lastAccessTime
        self.accessCount = accessCount
        self.size = UInt64(imageData.count)
        self.format = format
    }
    
    public func accessed() -> CachedImageItem {
        CachedImageItem(
            key: key,
            originalImage: originalImage,
            thumbnails: thumbnails,
            imageData: imageData,
            metadata: metadata,
            creationTime: creationTime,
            lastAccessTime: Date(),
            accessCount: accessCount + 1,
            format: format
        )
    }
}

// MARK: - Image Cache Metrics

/// Image cache performance metrics
public struct ImageCacheMetrics: Sendable, Codable {
    public let hitCount: Int
    public let missCount: Int
    public let evictionCount: Int
    public let thumbnailHits: Int
    public let totalImages: Int
    public let totalSize: UInt64
    public let averageImageSize: UInt64
    public let hitRate: Double
    public let thumbnailHitRate: Double
    public let averageLoadTime: TimeInterval
    public let averageProcessingTime: TimeInterval
    public let memoryUsage: UInt64
    public let diskUsage: UInt64
    public let formatDistribution: [String: Int]
    public let lastUpdated: Date
    
    public init(
        hitCount: Int = 0,
        missCount: Int = 0,
        evictionCount: Int = 0,
        thumbnailHits: Int = 0,
        totalImages: Int = 0,
        totalSize: UInt64 = 0,
        averageLoadTime: TimeInterval = 0,
        averageProcessingTime: TimeInterval = 0,
        memoryUsage: UInt64 = 0,
        diskUsage: UInt64 = 0,
        formatDistribution: [String: Int] = [:],
        lastUpdated: Date = Date()
    ) {
        self.hitCount = hitCount
        self.missCount = missCount
        self.evictionCount = evictionCount
        self.thumbnailHits = thumbnailHits
        self.totalImages = totalImages
        self.totalSize = totalSize
        self.averageImageSize = totalImages > 0 ? totalSize / UInt64(totalImages) : 0
        self.hitRate = hitCount + missCount > 0 ? Double(hitCount) / Double(hitCount + missCount) : 0
        self.thumbnailHitRate = thumbnailHits > 0 && hitCount > 0 ? Double(thumbnailHits) / Double(hitCount) : 0
        self.averageLoadTime = averageLoadTime
        self.averageProcessingTime = averageProcessingTime
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.formatDistribution = formatDistribution
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Image Cache Resource

/// Image cache resource management with specialized image handling
public actor ImageCacheCapabilityResource: AxiomCapabilityResource {
    private let configuration: ImageCacheCapabilityConfiguration
    private var memoryCache: [String: CachedImageItem] = [:]
    private var accessOrder: [String] = []
    private var accessFrequency: [String: Int] = [:]
    private var metrics = ImageCacheMetrics()
    private let imageQueue = OperationQueue()
    private let processingQueue = OperationQueue()
    private var cacheDirectory: URL?
    private let fileManager = FileManager.default
    
    public init(configuration: ImageCacheCapabilityConfiguration) {
        self.configuration = configuration
        self.imageQueue.maxConcurrentOperationCount = 3
        self.imageQueue.qualityOfService = .userInitiated
        self.processingQueue.maxConcurrentOperationCount = 2
        self.processingQueue.qualityOfService = .utility
    }
    
    public func allocate() async throws {
        // Create cache directory
        let cacheDirectories = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard let baseURL = cacheDirectories.first else {
            throw AxiomCapabilityError.initializationFailed("Failed to get cache directory URL")
        }
        
        cacheDirectory = baseURL.appendingPathComponent("AxiomImageCache")
        try fileManager.createDirectory(at: cacheDirectory!, withIntermediateDirectories: true, attributes: nil)
        
        // Setup memory warning handling
        if configuration.enableMemoryWarningHandling {
            setupMemoryWarningHandling()
        }
        
        // Load existing cache index
        await loadCacheIndex()
    }
    
    public func deallocate() async {
        imageQueue.cancelAllOperations()
        processingQueue.cancelAllOperations()
        
        // Save cache index
        await saveCacheIndex()
        
        memoryCache.removeAll()
        accessOrder.removeAll()
        accessFrequency.removeAll()
        metrics = ImageCacheMetrics()
        cacheDirectory = nil
    }
    
    public var isAllocated: Bool {
        cacheDirectory != nil
    }
    
    public func updateConfiguration(_ configuration: ImageCacheCapabilityConfiguration) async throws {
        // Apply memory limits
        await enforceMemoryConstraints()
    }
    
    // MARK: - Image Cache Operations
    
    public func storeImage(_ image: UIImage, forKey key: String, format: ImageCacheCapabilityConfiguration.ImageFormat? = nil) async throws {
        let startTime = Date()
        
        // Determine format
        let imageFormat = format ?? .jpeg
        
        // Convert image to data
        guard let imageData = await convertImageToData(image, format: imageFormat) else {
            throw AxiomCapabilityError.operationFailed("Failed to convert image to data")
        }
        
        // Extract metadata
        let metadata = await extractImageMetadata(from: image, data: imageData)
        
        // Generate thumbnails if enabled
        var thumbnails: [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage] = [:]
        if configuration.enableThumbnails {
            thumbnails = await generateThumbnails(from: image)
        }
        
        // Create cached item
        let item = CachedImageItem(
            key: key,
            originalImage: image,
            thumbnails: thumbnails,
            imageData: imageData,
            metadata: metadata,
            format: imageFormat
        )
        
        // Store in memory
        await storeInMemory(item)
        
        // Store on disk
        try await storeOnDisk(item)
        
        // Update metrics
        if configuration.enableMetrics {
            await updateStoreMetrics(item: item, processingTime: Date().timeIntervalSince(startTime))
        }
        
        // Enforce constraints
        await enforceConstraints()
    }
    
    public func storeImageData(_ data: Data, forKey key: String, format: ImageCacheCapabilityConfiguration.ImageFormat) async throws {
        let startTime = Date()
        
        // Create image from data
        guard let image = UIImage(data: data) else {
            throw AxiomCapabilityError.operationFailed("Failed to create image from data")
        }
        
        // Extract metadata
        let metadata = await extractImageMetadata(from: image, data: data)
        
        // Generate thumbnails if enabled
        var thumbnails: [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage] = [:]
        if configuration.enableThumbnails {
            thumbnails = await generateThumbnails(from: image)
        }
        
        // Create cached item
        let item = CachedImageItem(
            key: key,
            originalImage: image,
            thumbnails: thumbnails,
            imageData: data,
            metadata: metadata,
            format: format
        )
        
        // Store in memory
        await storeInMemory(item)
        
        // Store on disk
        try await storeOnDisk(item)
        
        // Update metrics
        if configuration.enableMetrics {
            await updateStoreMetrics(item: item, processingTime: Date().timeIntervalSince(startTime))
        }
        
        // Enforce constraints
        await enforceConstraints()
    }
    
    public func retrieveImage(forKey key: String) async -> UIImage? {
        let startTime = Date()
        
        // Check memory cache first
        if let item = memoryCache[key] {
            let updatedItem = item.accessed()
            memoryCache[key] = updatedItem
            await updateAccessTracking(key)
            
            if configuration.enableMetrics {
                await updateRetrieveMetrics(hit: true, fromMemory: true, loadTime: Date().timeIntervalSince(startTime))
            }
            
            return updatedItem.originalImage
        }
        
        // Try to load from disk
        if let item = await loadFromDisk(key: key) {
            // Store back in memory
            await storeInMemory(item)
            
            if configuration.enableMetrics {
                await updateRetrieveMetrics(hit: true, fromMemory: false, loadTime: Date().timeIntervalSince(startTime))
            }
            
            return item.originalImage
        }
        
        if configuration.enableMetrics {
            await updateRetrieveMetrics(hit: false, loadTime: Date().timeIntervalSince(startTime))
        }
        
        return nil
    }
    
    public func retrieveThumbnail(forKey key: String, size: ImageCacheCapabilityConfiguration.ThumbnailSize) async -> UIImage? {
        let startTime = Date()
        
        // Check memory cache first
        if let item = memoryCache[key], let thumbnail = item.thumbnails[size] {
            let updatedItem = item.accessed()
            memoryCache[key] = updatedItem
            await updateAccessTracking(key)
            
            if configuration.enableMetrics {
                await updateThumbnailMetrics(hit: true, loadTime: Date().timeIntervalSince(startTime))
            }
            
            return thumbnail
        }
        
        // Try to generate thumbnail from cached image
        if let item = memoryCache[key] ?? await loadFromDisk(key: key),
           let originalImage = item.originalImage {
            
            let thumbnail = await generateThumbnail(from: originalImage, size: size)
            
            // Update item with new thumbnail
            var updatedThumbnails = item.thumbnails
            updatedThumbnails[size] = thumbnail
            
            let updatedItem = CachedImageItem(
                key: item.key,
                originalImage: item.originalImage,
                thumbnails: updatedThumbnails,
                imageData: item.imageData,
                metadata: item.metadata,
                creationTime: item.creationTime,
                lastAccessTime: Date(),
                accessCount: item.accessCount + 1,
                format: item.format
            )
            
            memoryCache[key] = updatedItem
            
            if configuration.enableMetrics {
                await updateThumbnailMetrics(hit: true, loadTime: Date().timeIntervalSince(startTime))
            }
            
            return thumbnail
        }
        
        if configuration.enableMetrics {
            await updateThumbnailMetrics(hit: false, loadTime: Date().timeIntervalSince(startTime))
        }
        
        return nil
    }
    
    public func removeImage(forKey key: String) async {
        // Remove from memory
        memoryCache.removeValue(forKey: key)
        await removeFromAccessTracking(key)
        
        // Remove from disk
        await removeFromDisk(key: key)
    }
    
    public func removeAllImages() async {
        memoryCache.removeAll()
        accessOrder.removeAll()
        accessFrequency.removeAll()
        
        // Clear disk cache
        await clearDiskCache()
        
        // Reset metrics
        if configuration.enableMetrics {
            metrics = ImageCacheMetrics()
        }
    }
    
    public func exists(forKey key: String) async -> Bool {
        if memoryCache[key] != nil {
            return true
        }
        
        return await diskFileExists(key: key)
    }
    
    public func getAllKeys() async -> [String] {
        var allKeys = Set(memoryCache.keys)
        
        // Add disk keys
        if let diskKeys = await getDiskKeys() {
            allKeys.formUnion(diskKeys)
        }
        
        return Array(allKeys)
    }
    
    public func getMetrics() async -> ImageCacheMetrics {
        if configuration.enableMetrics {
            return metrics
        } else {
            return ImageCacheMetrics()
        }
    }
    
    public func getCacheSize() async -> (memory: UInt64, disk: UInt64, total: UInt64) {
        let memorySize = memoryCache.values.reduce(0) { $0 + $1.size }
        let diskSize = await getDiskCacheSize()
        return (memory: memorySize, disk: diskSize, total: memorySize + diskSize)
    }
    
    public func getImageCount() async -> (memory: Int, disk: Int, total: Int) {
        let memoryCount = memoryCache.count
        let diskCount = await getDiskImageCount()
        return (memory: memoryCount, disk: diskCount, total: memoryCount + diskCount)
    }
    
    // MARK: - Private Methods
    
    private func storeInMemory(_ item: CachedImageItem) async {
        memoryCache[item.key] = item
        await updateAccessTracking(item.key)
    }
    
    private func storeOnDisk(_ item: CachedImageItem) async throws {
        guard let cacheDirectory = cacheDirectory else { return }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(item.key).\(item.format.rawValue)")
        try item.imageData.write(to: fileURL)
        
        // Store thumbnails
        if configuration.enableThumbnails {
            for (size, thumbnail) in item.thumbnails {
                let thumbnailURL = cacheDirectory.appendingPathComponent("\(item.key)_\(size.width)x\(size.height).\(item.format.rawValue)")
                if let thumbnailData = await convertImageToData(thumbnail, format: item.format) {
                    try thumbnailData.write(to: thumbnailURL)
                }
            }
        }
    }
    
    private func loadFromDisk(key: String) async -> CachedImageItem? {
        guard let cacheDirectory = cacheDirectory else { return nil }
        
        // Try different formats
        for format in configuration.supportedFormats {
            let fileURL = cacheDirectory.appendingPathComponent("\(key).\(format.rawValue)")
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    guard let image = UIImage(data: data) else { continue }
                    
                    let metadata = await extractImageMetadata(from: image, data: data)
                    
                    // Load thumbnails
                    var thumbnails: [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage] = [:]
                    if configuration.enableThumbnails {
                        for size in configuration.thumbnailSizes {
                            let thumbnailURL = cacheDirectory.appendingPathComponent("\(key)_\(size.width)x\(size.height).\(format.rawValue)")
                            if fileManager.fileExists(atPath: thumbnailURL.path),
                               let thumbnailData = try? Data(contentsOf: thumbnailURL),
                               let thumbnail = UIImage(data: thumbnailData) {
                                thumbnails[size] = thumbnail
                            }
                        }
                    }
                    
                    return CachedImageItem(
                        key: key,
                        originalImage: image,
                        thumbnails: thumbnails,
                        imageData: data,
                        metadata: metadata,
                        format: format
                    )
                } catch {
                    continue
                }
            }
        }
        
        return nil
    }
    
    private func removeFromDisk(key: String) async {
        guard let cacheDirectory = cacheDirectory else { return }
        
        for format in configuration.supportedFormats {
            let fileURL = cacheDirectory.appendingPathComponent("\(key).\(format.rawValue)")
            try? fileManager.removeItem(at: fileURL)
            
            // Remove thumbnails
            for size in configuration.thumbnailSizes {
                let thumbnailURL = cacheDirectory.appendingPathComponent("\(key)_\(size.width)x\(size.height).\(format.rawValue)")
                try? fileManager.removeItem(at: thumbnailURL)
            }
        }
    }
    
    private func convertImageToData(_ image: UIImage, format: ImageCacheCapabilityConfiguration.ImageFormat) async -> Data? {
        switch format {
        case .jpeg:
            return image.jpegData(compressionQuality: configuration.compressionQuality.jpegQuality)
        case .png:
            return image.pngData()
        case .heif:
            if #available(iOS 17.0, macOS 14.0, *) {
                return image.heifData()
            } else {
                return image.jpegData(compressionQuality: configuration.compressionQuality.jpegQuality)
            }
        default:
            return image.jpegData(compressionQuality: configuration.compressionQuality.jpegQuality)
        }
    }
    
    private func extractImageMetadata(from image: UIImage, data: Data) async -> CachedImageItem.ImageMetadata {
        let dimensions = image.size
        let orientation = image.imageOrientation
        
        // Extract additional metadata from image data
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return CachedImageItem.ImageMetadata(dimensions: dimensions, orientation: orientation)
        }
        
        let dpi = (properties[kCGImagePropertyDPIWidth as String] as? CGFloat) ?? 72.0
        let colorSpace = properties[kCGImagePropertyColorModel as String] as? String
        let hasAlpha = (properties[kCGImagePropertyHasAlpha as String] as? Bool) ?? false
        
        return CachedImageItem.ImageMetadata(
            dimensions: dimensions,
            orientation: orientation,
            colorSpace: colorSpace,
            dpi: dpi,
            hasAlpha: hasAlpha
        )
    }
    
    private func generateThumbnails(from image: UIImage) async -> [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage] {
        var thumbnails: [ImageCacheCapabilityConfiguration.ThumbnailSize: UIImage] = [:]
        
        for size in configuration.thumbnailSizes {
            if let thumbnail = await generateThumbnail(from: image, size: size) {
                thumbnails[size] = thumbnail
            }
        }
        
        return thumbnails
    }
    
    private func generateThumbnail(from image: UIImage, size: ImageCacheCapabilityConfiguration.ThumbnailSize) async -> UIImage? {
        let targetSize = size.cgSize
        
        return await withCheckedContinuation { continuation in
            processingQueue.addOperation {
                UIGraphicsBeginImageContextWithOptions(targetSize, false, size.scale)
                image.draw(in: CGRect(origin: .zero, size: targetSize))
                let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func updateAccessTracking(_ key: String) async {
        switch configuration.evictionPolicy {
        case .lru:
            accessOrder.removeAll { $0 == key }
            accessOrder.append(key)
        case .lfu:
            accessFrequency[key, default: 0] += 1
        default:
            break
        }
    }
    
    private func removeFromAccessTracking(_ key: String) async {
        accessOrder.removeAll { $0 == key }
        accessFrequency.removeValue(forKey: key)
    }
    
    private func enforceConstraints() async {
        await enforceMemoryConstraints()
        await enforceDiskConstraints()
    }
    
    private func enforceMemoryConstraints() async {
        let currentSize = memoryCache.values.reduce(0) { $0 + $1.size }
        
        while currentSize > configuration.memoryLimit || memoryCache.count > configuration.maxItemCount {
            await evictFromMemory()
        }
    }
    
    private func enforceDiskConstraints() async {
        // Implementation would check disk usage and evict as needed
    }
    
    private func evictFromMemory() async {
        guard !memoryCache.isEmpty else { return }
        
        let keyToEvict: String
        
        switch configuration.evictionPolicy {
        case .lru:
            keyToEvict = accessOrder.first ?? memoryCache.keys.first!
        case .lfu:
            keyToEvict = accessFrequency.min { $0.value < $1.value }?.key ?? memoryCache.keys.first!
        case .size:
            keyToEvict = memoryCache.max { $0.value.size < $1.value.size }!.key
        case .age:
            keyToEvict = memoryCache.min { $0.value.creationTime < $1.value.creationTime }!.key
        case .smart:
            // Smart eviction considers multiple factors
            keyToEvict = await selectSmartEvictionCandidate()
        }
        
        memoryCache.removeValue(forKey: keyToEvict)
        await removeFromAccessTracking(keyToEvict)
        
        if configuration.enableMetrics {
            await updateEvictionMetrics()
        }
    }
    
    private func selectSmartEvictionCandidate() async -> String {
        // Smart eviction algorithm considering access frequency, size, and age
        let candidates = memoryCache.map { (key, item) in
            let ageScore = Date().timeIntervalSince(item.lastAccessTime) / 3600 // Hours since last access
            let sizeScore = Double(item.size) / (1024 * 1024) // Size in MB
            let frequencyScore = 1.0 / max(Double(item.accessCount), 1.0) // Inverse frequency
            
            let combinedScore = ageScore + sizeScore + frequencyScore
            return (key: key, score: combinedScore)
        }
        
        return candidates.max { $0.score < $1.score }?.key ?? memoryCache.keys.first!
    }
    
    private func setupMemoryWarningHandling() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
    }
    
    private func handleMemoryWarning() async {
        // Clear half of the memory cache during memory warnings
        let itemsToRemove = memoryCache.count / 2
        
        for _ in 0..<itemsToRemove {
            await evictFromMemory()
        }
    }
    
    private func loadCacheIndex() async {
        // Implementation would load cache index from disk
    }
    
    private func saveCacheIndex() async {
        // Implementation would save cache index to disk
    }
    
    private func clearDiskCache() async {
        guard let cacheDirectory = cacheDirectory else { return }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } catch {
            // Handle error
        }
    }
    
    private func diskFileExists(key: String) async -> Bool {
        guard let cacheDirectory = cacheDirectory else { return false }
        
        for format in configuration.supportedFormats {
            let fileURL = cacheDirectory.appendingPathComponent("\(key).\(format.rawValue)")
            if fileManager.fileExists(atPath: fileURL.path) {
                return true
            }
        }
        
        return false
    }
    
    private func getDiskKeys() async -> [String]? {
        guard let cacheDirectory = cacheDirectory else { return nil }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            let keys = contents.compactMap { url in
                let filename = url.lastPathComponent
                return String(filename.split(separator: ".").first ?? "")
            }
            return Array(Set(keys))
        } catch {
            return nil
        }
    }
    
    private func getDiskCacheSize() async -> UInt64 {
        guard let cacheDirectory = cacheDirectory else { return 0 }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = contents.reduce(0) { total, url in
                do {
                    let attributes = try url.resourceValues(forKeys: [.fileSizeKey])
                    return total + UInt64(attributes.fileSize ?? 0)
                } catch {
                    return total
                }
            }
            return totalSize
        } catch {
            return 0
        }
    }
    
    private func getDiskImageCount() async -> Int {
        guard let diskKeys = await getDiskKeys() else { return 0 }
        return diskKeys.count
    }
    
    private func updateStoreMetrics(item: CachedImageItem, processingTime: TimeInterval) async {
        // Update metrics for store operations
        // Implementation would update the metrics struct
    }
    
    private func updateRetrieveMetrics(hit: Bool, fromMemory: Bool = false, loadTime: TimeInterval) async {
        // Update metrics for retrieve operations
        // Implementation would update the metrics struct
    }
    
    private func updateThumbnailMetrics(hit: Bool, loadTime: TimeInterval) async {
        // Update metrics for thumbnail operations
        // Implementation would update the metrics struct
    }
    
    private func updateEvictionMetrics() async {
        // Update metrics for eviction operations
        // Implementation would update the metrics struct
    }
}

// MARK: - Image Cache Capability Implementation

/// Image cache capability providing high-performance image caching with thumbnails
public actor ImageCacheCapability: DomainCapability {
    public typealias ConfigurationType = ImageCacheCapabilityConfiguration
    public typealias ResourceType = ImageCacheCapabilityResource
    
    private var _configuration: ImageCacheCapabilityConfiguration
    private var _resources: ImageCacheCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "image-cache-capability" }
    
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
    
    public var configuration: ImageCacheCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ImageCacheCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ImageCacheCapabilityConfiguration = ImageCacheCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ImageCacheCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ImageCacheCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid image cache configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Image cache is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Image cache doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Image Cache Operations
    
    /// Store image in cache
    public func storeImage(_ image: UIImage, forKey key: String, format: ImageCacheCapabilityConfiguration.ImageFormat? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        try await _resources.storeImage(image, forKey: key, format: format)
    }
    
    /// Store image data in cache
    public func storeImageData(_ data: Data, forKey key: String, format: ImageCacheCapabilityConfiguration.ImageFormat) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        try await _resources.storeImageData(data, forKey: key, format: format)
    }
    
    /// Retrieve image from cache
    public func retrieveImage(forKey key: String) async throws -> UIImage? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.retrieveImage(forKey: key)
    }
    
    /// Retrieve thumbnail from cache
    public func retrieveThumbnail(forKey key: String, size: ImageCacheCapabilityConfiguration.ThumbnailSize) async throws -> UIImage? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.retrieveThumbnail(forKey: key, size: size)
    }
    
    /// Remove image from cache
    public func removeImage(forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        await _resources.removeImage(forKey: key)
    }
    
    /// Clear all images from cache
    public func removeAllImages() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        await _resources.removeAllImages()
    }
    
    /// Check if image exists in cache
    public func exists(forKey key: String) async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.exists(forKey: key)
    }
    
    /// Get all cache keys
    public func getAllKeys() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.getAllKeys()
    }
    
    /// Get cache performance metrics
    public func getMetrics() async throws -> ImageCacheMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Get cache size information
    public func getCacheSize() async throws -> (memory: UInt64, disk: UInt64, total: UInt64) {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.getCacheSize()
    }
    
    /// Get image count information
    public func getImageCount() async throws -> (memory: Int, disk: Int, total: Int) {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Image cache capability not available")
        }
        
        return await _resources.getImageCount()
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
    /// Image cache specific errors
    public static func imageCacheError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Image Cache: \(message)")
    }
    
    public static func imageCacheItemNotFound(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Image cache item not found: \(key)")
    }
    
    public static func imageCacheCorrupted(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Image cache item corrupted: \(key)")
    }
    
    public static func imageCacheFormatUnsupported(_ format: String) -> AxiomCapabilityError {
        .operationFailed("Image cache format not supported: \(format)")
    }
}