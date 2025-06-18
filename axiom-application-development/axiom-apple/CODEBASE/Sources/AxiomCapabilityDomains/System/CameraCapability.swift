import Foundation
import AVFoundation
import UIKit
import Photos
import AxiomCore
import AxiomCapabilities

// MARK: - Camera Capability Configuration

/// Configuration for Camera capability
public struct CameraCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let defaultCameraPosition: CameraPosition
    public let defaultVideoQuality: VideoQuality
    public let defaultPhotoQuality: PhotoQuality
    public let enableFaceDetection: Bool
    public let enableStabilization: Bool
    public let enableHDR: Bool
    public let enableFlash: Bool
    public let enableZoom: Bool
    public let maxZoomFactor: CGFloat
    public let enableFocus: Bool
    public let enableExposure: Bool
    public let videoFormat: VideoFormat
    public let photoFormat: PhotoFormat
    public let enableLivePhoto: Bool
    public let enablePortraitMode: Bool
    public let enableSlowMotion: Bool
    public let enableTimelapseMode: Bool
    public let maxRecordingDuration: TimeInterval
    public let enableGeotagging: Bool
    public let enableMetadata: Bool
    public let enableThumbnailGeneration: Bool
    public let thumbnailSize: CGSize
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let storageLocation: StorageLocation
    public let autoSaveToPhotoLibrary: Bool
    
    public enum CameraPosition: String, Codable, CaseIterable, Sendable {
        case front = "front"
        case back = "back"
        case unspecified = "unspecified"
    }
    
    public enum VideoQuality: String, Codable, CaseIterable, Sendable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case photo = "photo"
        case vga640x480 = "640x480"
        case hd1280x720 = "1280x720"
        case hd1920x1080 = "1920x1080"
        case uhd3840x2160 = "3840x2160"
    }
    
    public enum PhotoQuality: String, Codable, CaseIterable, Sendable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case maximum = "maximum"
    }
    
    public enum VideoFormat: String, Codable, CaseIterable, Sendable {
        case mp4 = "mp4"
        case mov = "mov"
        case m4v = "m4v"
    }
    
    public enum PhotoFormat: String, Codable, CaseIterable, Sendable {
        case jpeg = "jpeg"
        case heif = "heif"
        case raw = "raw"
    }
    
    public enum StorageLocation: String, Codable, CaseIterable, Sendable {
        case documents = "documents"
        case temporary = "temporary"
        case caches = "caches"
        case photoLibrary = "photoLibrary"
    }
    
    public init(
        defaultCameraPosition: CameraPosition = .back,
        defaultVideoQuality: VideoQuality = .high,
        defaultPhotoQuality: PhotoQuality = .high,
        enableFaceDetection: Bool = false,
        enableStabilization: Bool = true,
        enableHDR: Bool = true,
        enableFlash: Bool = true,
        enableZoom: Bool = true,
        maxZoomFactor: CGFloat = 10.0,
        enableFocus: Bool = true,
        enableExposure: Bool = true,
        videoFormat: VideoFormat = .mp4,
        photoFormat: PhotoFormat = .jpeg,
        enableLivePhoto: Bool = false,
        enablePortraitMode: Bool = false,
        enableSlowMotion: Bool = false,
        enableTimelapseMode: Bool = false,
        maxRecordingDuration: TimeInterval = 600.0, // 10 minutes
        enableGeotagging: Bool = false,
        enableMetadata: Bool = true,
        enableThumbnailGeneration: Bool = true,
        thumbnailSize: CGSize = CGSize(width: 150, height: 150),
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        storageLocation: StorageLocation = .documents,
        autoSaveToPhotoLibrary: Bool = false
    ) {
        self.defaultCameraPosition = defaultCameraPosition
        self.defaultVideoQuality = defaultVideoQuality
        self.defaultPhotoQuality = defaultPhotoQuality
        self.enableFaceDetection = enableFaceDetection
        self.enableStabilization = enableStabilization
        self.enableHDR = enableHDR
        self.enableFlash = enableFlash
        self.enableZoom = enableZoom
        self.maxZoomFactor = maxZoomFactor
        self.enableFocus = enableFocus
        self.enableExposure = enableExposure
        self.videoFormat = videoFormat
        self.photoFormat = photoFormat
        self.enableLivePhoto = enableLivePhoto
        self.enablePortraitMode = enablePortraitMode
        self.enableSlowMotion = enableSlowMotion
        self.enableTimelapseMode = enableTimelapseMode
        self.maxRecordingDuration = maxRecordingDuration
        self.enableGeotagging = enableGeotagging
        self.enableMetadata = enableMetadata
        self.enableThumbnailGeneration = enableThumbnailGeneration
        self.thumbnailSize = thumbnailSize
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.storageLocation = storageLocation
        self.autoSaveToPhotoLibrary = autoSaveToPhotoLibrary
    }
    
    public var isValid: Bool {
        maxZoomFactor > 0 &&
        maxRecordingDuration > 0 &&
        thumbnailSize.width > 0 &&
        thumbnailSize.height > 0
    }
    
    public func merged(with other: CameraCapabilityConfiguration) -> CameraCapabilityConfiguration {
        CameraCapabilityConfiguration(
            defaultCameraPosition: other.defaultCameraPosition,
            defaultVideoQuality: other.defaultVideoQuality,
            defaultPhotoQuality: other.defaultPhotoQuality,
            enableFaceDetection: other.enableFaceDetection,
            enableStabilization: other.enableStabilization,
            enableHDR: other.enableHDR,
            enableFlash: other.enableFlash,
            enableZoom: other.enableZoom,
            maxZoomFactor: other.maxZoomFactor,
            enableFocus: other.enableFocus,
            enableExposure: other.enableExposure,
            videoFormat: other.videoFormat,
            photoFormat: other.photoFormat,
            enableLivePhoto: other.enableLivePhoto,
            enablePortraitMode: other.enablePortraitMode,
            enableSlowMotion: other.enableSlowMotion,
            enableTimelapseMode: other.enableTimelapseMode,
            maxRecordingDuration: other.maxRecordingDuration,
            enableGeotagging: other.enableGeotagging,
            enableMetadata: other.enableMetadata,
            enableThumbnailGeneration: other.enableThumbnailGeneration,
            thumbnailSize: other.thumbnailSize,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            storageLocation: other.storageLocation,
            autoSaveToPhotoLibrary: other.autoSaveToPhotoLibrary
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CameraCapabilityConfiguration {
        var adjustedVideoQuality = defaultVideoQuality
        var adjustedPhotoQuality = defaultPhotoQuality
        var adjustedLogging = enableLogging
        var adjustedStabilization = enableStabilization
        var adjustedDuration = maxRecordingDuration
        
        if environment.isLowPowerMode {
            adjustedVideoQuality = .medium
            adjustedPhotoQuality = .medium
            adjustedStabilization = false
            adjustedDuration = min(maxRecordingDuration, 300.0) // 5 minutes max
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return CameraCapabilityConfiguration(
            defaultCameraPosition: defaultCameraPosition,
            defaultVideoQuality: adjustedVideoQuality,
            defaultPhotoQuality: adjustedPhotoQuality,
            enableFaceDetection: enableFaceDetection,
            enableStabilization: adjustedStabilization,
            enableHDR: enableHDR,
            enableFlash: enableFlash,
            enableZoom: enableZoom,
            maxZoomFactor: maxZoomFactor,
            enableFocus: enableFocus,
            enableExposure: enableExposure,
            videoFormat: videoFormat,
            photoFormat: photoFormat,
            enableLivePhoto: enableLivePhoto,
            enablePortraitMode: enablePortraitMode,
            enableSlowMotion: enableSlowMotion,
            enableTimelapseMode: enableTimelapseMode,
            maxRecordingDuration: adjustedDuration,
            enableGeotagging: enableGeotagging,
            enableMetadata: enableMetadata,
            enableThumbnailGeneration: enableThumbnailGeneration,
            thumbnailSize: thumbnailSize,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            storageLocation: storageLocation,
            autoSaveToPhotoLibrary: autoSaveToPhotoLibrary
        )
    }
}

// MARK: - Camera Types

/// Camera session state
public enum CameraSessionState: String, Codable, CaseIterable, Sendable {
    case notRunning = "notRunning"
    case running = "running"
    case interrupted = "interrupted"
}

/// Camera authorization status
public enum CameraAuthorizationStatus: String, Codable, CaseIterable, Sendable {
    case notDetermined = "notDetermined"
    case restricted = "restricted"
    case denied = "denied"
    case authorized = "authorized"
}

/// Photo capture result
public struct PhotoCaptureResult: Sendable {
    public let imageData: Data
    public let metadata: [String: Any]?
    public let thumbnail: Data?
    public let livePhotoMovieURL: URL?
    public let captureDate: Date
    public let location: CLLocation?
    public let flashFired: Bool
    public let originalURL: URL?
    
    public init(
        imageData: Data,
        metadata: [String: Any]? = nil,
        thumbnail: Data? = nil,
        livePhotoMovieURL: URL? = nil,
        captureDate: Date = Date(),
        location: CLLocation? = nil,
        flashFired: Bool = false,
        originalURL: URL? = nil
    ) {
        self.imageData = imageData
        self.metadata = metadata
        self.thumbnail = thumbnail
        self.livePhotoMovieURL = livePhotoMovieURL
        self.captureDate = captureDate
        self.location = location
        self.flashFired = flashFired
        self.originalURL = originalURL
    }
}

/// Video recording result
public struct VideoRecordingResult: Sendable {
    public let videoURL: URL
    public let duration: TimeInterval
    public let size: CGSize
    public let metadata: [String: Any]?
    public let thumbnail: Data?
    public let recordingDate: Date
    public let location: CLLocation?
    public let fileSize: Int64
    
    public init(
        videoURL: URL,
        duration: TimeInterval,
        size: CGSize,
        metadata: [String: Any]? = nil,
        thumbnail: Data? = nil,
        recordingDate: Date = Date(),
        location: CLLocation? = nil,
        fileSize: Int64 = 0
    ) {
        self.videoURL = videoURL
        self.duration = duration
        self.size = size
        self.metadata = metadata
        self.thumbnail = thumbnail
        self.recordingDate = recordingDate
        self.location = location
        self.fileSize = fileSize
    }
}

/// Camera settings
public struct CameraSettings: Sendable {
    public let position: CameraCapabilityConfiguration.CameraPosition
    public let videoQuality: CameraCapabilityConfiguration.VideoQuality
    public let photoQuality: CameraCapabilityConfiguration.PhotoQuality
    public let flashMode: FlashMode
    public let focusMode: FocusMode
    public let exposureMode: ExposureMode
    public let zoomFactor: CGFloat
    public let stabilizationEnabled: Bool
    public let hdrEnabled: Bool
    
    public enum FlashMode: String, Codable, CaseIterable, Sendable {
        case off = "off"
        case on = "on"
        case auto = "auto"
    }
    
    public enum FocusMode: String, Codable, CaseIterable, Sendable {
        case locked = "locked"
        case autoFocus = "autoFocus"
        case continuousAutoFocus = "continuousAutoFocus"
    }
    
    public enum ExposureMode: String, Codable, CaseIterable, Sendable {
        case locked = "locked"
        case autoExpose = "autoExpose"
        case continuousAutoExposure = "continuousAutoExposure"
        case custom = "custom"
    }
    
    public init(
        position: CameraCapabilityConfiguration.CameraPosition = .back,
        videoQuality: CameraCapabilityConfiguration.VideoQuality = .high,
        photoQuality: CameraCapabilityConfiguration.PhotoQuality = .high,
        flashMode: FlashMode = .auto,
        focusMode: FocusMode = .continuousAutoFocus,
        exposureMode: ExposureMode = .continuousAutoExposure,
        zoomFactor: CGFloat = 1.0,
        stabilizationEnabled: Bool = true,
        hdrEnabled: Bool = true
    ) {
        self.position = position
        self.videoQuality = videoQuality
        self.photoQuality = photoQuality
        self.flashMode = flashMode
        self.focusMode = focusMode
        self.exposureMode = exposureMode
        self.zoomFactor = zoomFactor
        self.stabilizationEnabled = stabilizationEnabled
        self.hdrEnabled = hdrEnabled
    }
}

/// Camera metrics
public struct CameraMetrics: Sendable {
    public let photosCaptured: Int
    public let videosRecorded: Int
    public let totalRecordingTime: TimeInterval
    public let averagePhotoSize: Int64
    public let averageVideoSize: Int64
    public let flashUsageCount: Int
    public let sessionCount: Int
    public let errorCount: Int
    public let averageFocusTime: TimeInterval
    public let batteryImpact: Double
    
    public init(
        photosCaptured: Int = 0,
        videosRecorded: Int = 0,
        totalRecordingTime: TimeInterval = 0,
        averagePhotoSize: Int64 = 0,
        averageVideoSize: Int64 = 0,
        flashUsageCount: Int = 0,
        sessionCount: Int = 0,
        errorCount: Int = 0,
        averageFocusTime: TimeInterval = 0,
        batteryImpact: Double = 0
    ) {
        self.photosCaptured = photosCaptured
        self.videosRecorded = videosRecorded
        self.totalRecordingTime = totalRecordingTime
        self.averagePhotoSize = averagePhotoSize
        self.averageVideoSize = averageVideoSize
        self.flashUsageCount = flashUsageCount
        self.sessionCount = sessionCount
        self.errorCount = errorCount
        self.averageFocusTime = averageFocusTime
        self.batteryImpact = batteryImpact
    }
}

// MARK: - Camera Resource

/// Camera resource management
public actor CameraCapabilityResource: AxiomCapabilityResource {
    private let configuration: CameraCapabilityConfiguration
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var deviceInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    private var isRecording = false
    private var recordingStartTime: Date?
    private var sessionQueue: DispatchQueue
    private var metrics: CameraMetrics = CameraMetrics()
    private var photoSizes: [Int64] = []
    private var videoSizes: [Int64] = []
    private var focusTimes: [TimeInterval] = []
    
    public init(configuration: CameraCapabilityConfiguration) {
        self.configuration = configuration
        self.sessionQueue = DispatchQueue(label: "com.axiom.camera.session", qos: .userInitiated)
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 100_000_000, // 100MB for camera buffers
            cpu: 25.0, // 25% CPU for camera processing
            bandwidth: 0, // No network bandwidth
            storage: 1_000_000_000 // 1GB for photo/video storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let isActive = captureSession?.isRunning ?? false
            let memoryUsage = isActive ? 50_000_000 : 5_000_000
            let cpuUsage = isActive ? (isRecording ? 20.0 : 10.0) : 1.0
            
            return ResourceUsage(
                memory: memoryUsage,
                cpu: cpuUsage,
                bandwidth: 0,
                storage: 0 // Dynamic based on capture
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        await getAuthorizationStatus() == .authorized && captureSession != nil
    }
    
    public func release() async {
        await stopSession()
        captureSession = nil
        photoOutput = nil
        movieOutput = nil
        deviceInput = nil
        previewLayer = nil
        currentDevice = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        try await setupCaptureSession()
    }
    
    internal func updateConfiguration(_ configuration: CameraCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Authorization
    
    public func getAuthorizationStatus() async -> CameraAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    public func requestPermission() async throws -> CameraAuthorizationStatus {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        return granted ? .authorized : .denied
    }
    
    // MARK: - Session Management
    
    public func startSession() async throws {
        guard let session = captureSession else {
            throw CameraError.sessionNotConfigured
        }
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                if !session.isRunning {
                    session.startRunning()
                }
                continuation.resume()
            }
        }
    }
    
    public func stopSession() async {
        guard let session = captureSession else { return }
        
        return await withCheckedContinuation { continuation in
            sessionQueue.async {
                if session.isRunning {
                    session.stopRunning()
                }
                continuation.resume()
            }
        }
    }
    
    public func getSessionState() -> CameraSessionState {
        guard let session = captureSession else { return .notRunning }
        
        if session.isRunning {
            return .running
        } else if session.isInterrupted {
            return .interrupted
        } else {
            return .notRunning
        }
    }
    
    // MARK: - Camera Controls
    
    public func switchCamera() async throws {
        guard let session = captureSession,
              let currentInput = deviceInput else {
            throw CameraError.sessionNotConfigured
        }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newDevice = getCamera(for: newPosition) else {
            throw CameraError.cameraNotAvailable
        }
        
        let newInput = try AVCaptureDeviceInput(device: newDevice)
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                session.beginConfiguration()
                session.removeInput(currentInput)
                
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                    self.deviceInput = newInput
                    self.currentDevice = newDevice
                    session.commitConfiguration()
                    continuation.resume()
                } else {
                    session.addInput(currentInput) // Restore original input
                    session.commitConfiguration()
                    continuation.resume(throwing: CameraError.cameraNotAvailable)
                }
            }
        }
    }
    
    public func setZoomFactor(_ factor: CGFloat) async throws {
        guard let device = currentDevice else {
            throw CameraError.cameraNotAvailable
        }
        
        let clampedFactor = max(device.minAvailableVideoZoomFactor, 
                              min(factor, min(device.maxAvailableVideoZoomFactor, configuration.maxZoomFactor)))
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = clampedFactor
                    device.unlockForConfiguration()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func setFlashMode(_ mode: CameraSettings.FlashMode) async throws {
        guard let device = currentDevice else {
            throw CameraError.cameraNotAvailable
        }
        
        let avFlashMode: AVCaptureDevice.FlashMode
        switch mode {
        case .off: avFlashMode = .off
        case .on: avFlashMode = .on
        case .auto: avFlashMode = .auto
        }
        
        guard device.isFlashModeSupported(avFlashMode) else {
            throw CameraError.featureNotSupported("Flash mode not supported")
        }
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    try device.lockForConfiguration()
                    device.flashMode = avFlashMode
                    device.unlockForConfiguration()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func focusAt(point: CGPoint) async throws {
        guard let device = currentDevice else {
            throw CameraError.cameraNotAvailable
        }
        
        guard device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported else {
            throw CameraError.featureNotSupported("Focus at point not supported")
        }
        
        let startTime = Date()
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                    device.unlockForConfiguration()
                    
                    let focusTime = Date().timeIntervalSince(startTime)
                    Task {
                        await self.updateFocusMetrics(time: focusTime)
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Photo Capture
    
    public func capturePhoto() async throws -> PhotoCaptureResult {
        guard let photoOutput = photoOutput else {
            throw CameraError.photoOutputNotConfigured
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        if configuration.enableHDR {
            settings.isAutoStillImageStabilizationEnabled = true
        }
        
        return await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate { result in
                Task {
                    await self.updatePhotoMetrics(size: Int64(result.imageData.count))
                }
                continuation.resume(returning: result)
            } onError: { error in
                Task {
                    await self.updateErrorMetrics()
                }
                continuation.resume(throwing: error)
            }
            
            sessionQueue.async {
                photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }
    
    // MARK: - Video Recording
    
    public func startVideoRecording() async throws -> URL {
        guard let movieOutput = movieOutput else {
            throw CameraError.movieOutputNotConfigured
        }
        
        guard !isRecording else {
            throw CameraError.recordingInProgress
        }
        
        let outputURL = try generateVideoOutputURL()
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                movieOutput.startRecording(to: outputURL, recordingDelegate: VideoRecordingDelegate { result in
                    Task {
                        await self.updateVideoMetrics(result: result)
                        self.isRecording = false
                        self.recordingStartTime = nil
                    }
                    continuation.resume(returning: result.videoURL)
                } onError: { error in
                    Task {
                        await self.updateErrorMetrics()
                        self.isRecording = false
                        self.recordingStartTime = nil
                    }
                    continuation.resume(throwing: error)
                })
                
                self.isRecording = true
                self.recordingStartTime = Date()
            }
        }
    }
    
    public func stopVideoRecording() async throws -> VideoRecordingResult {
        guard let movieOutput = movieOutput else {
            throw CameraError.movieOutputNotConfigured
        }
        
        guard isRecording else {
            throw CameraError.notRecording
        }
        
        return await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                movieOutput.stopRecording()
                // Result will be delivered via delegate
            }
        }
    }
    
    public func getRecordingDuration() -> TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    public func isCurrentlyRecording() -> Bool {
        isRecording
    }
    
    // MARK: - Preview
    
    public func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        previewLayer
    }
    
    // MARK: - Device Information
    
    public func getAvailableCameras() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
    }
    
    public func getCameraCapabilities() -> [String: Any] {
        guard let device = currentDevice else { return [:] }
        
        return [
            "hasFlash": device.hasFlash,
            "hasTorch": device.hasTorch,
            "minZoom": device.minAvailableVideoZoomFactor,
            "maxZoom": device.maxAvailableVideoZoomFactor,
            "supportedFormats": device.formats.count,
            "position": device.position.rawValue
        ]
    }
    
    public func getMetrics() -> CameraMetrics {
        metrics
    }
    
    // MARK: - Private Implementation
    
    private func setupCaptureSession() async throws {
        let session = AVCaptureSession()
        
        await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    session.beginConfiguration()
                    
                    // Configure session preset
                    let sessionPreset = self.mapVideoQualityToSessionPreset(self.configuration.defaultVideoQuality)
                    if session.canSetSessionPreset(sessionPreset) {
                        session.sessionPreset = sessionPreset
                    }
                    
                    // Setup camera input
                    let position = self.mapCameraPosition(self.configuration.defaultCameraPosition)
                    guard let camera = self.getCamera(for: position) else {
                        throw CameraError.cameraNotAvailable
                    }
                    
                    let input = try AVCaptureDeviceInput(device: camera)
                    if session.canAddInput(input) {
                        session.addInput(input)
                        self.deviceInput = input
                        self.currentDevice = camera
                    } else {
                        throw CameraError.inputNotSupported
                    }
                    
                    // Setup photo output
                    let photoOutput = AVCapturePhotoOutput()
                    if session.canAddOutput(photoOutput) {
                        session.addOutput(photoOutput)
                        self.photoOutput = photoOutput
                    }
                    
                    // Setup movie output for video recording
                    let movieOutput = AVCaptureMovieFileOutput()
                    if session.canAddOutput(movieOutput) {
                        session.addOutput(movieOutput)
                        self.movieOutput = movieOutput
                        
                        // Configure movie output
                        if let connection = movieOutput.connection(with: .video) {
                            if connection.isVideoStabilizationSupported && self.configuration.enableStabilization {
                                connection.preferredVideoStabilizationMode = .auto
                            }
                        }
                    }
                    
                    // Setup preview layer
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.videoGravity = .resizeAspectFill
                    self.previewLayer = previewLayer
                    
                    session.commitConfiguration()
                    self.captureSession = session
                    
                    Task {
                        await self.updateSessionMetrics()
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices.first
    }
    
    private func mapCameraPosition(_ position: CameraCapabilityConfiguration.CameraPosition) -> AVCaptureDevice.Position {
        switch position {
        case .front: return .front
        case .back: return .back
        case .unspecified: return .unspecified
        }
    }
    
    private func mapVideoQualityToSessionPreset(_ quality: CameraCapabilityConfiguration.VideoQuality) -> AVCaptureSession.Preset {
        switch quality {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .photo: return .photo
        case .vga640x480: return .vga640x480
        case .hd1280x720: return .hd1280x720
        case .hd1920x1080: return .hd1920x1080
        case .uhd3840x2160: return .hd4K3840x2160
        }
    }
    
    private func generateVideoOutputURL() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "video_\(Date().timeIntervalSince1970).\(configuration.videoFormat.rawValue)"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func updatePhotoMetrics(size: Int64) async {
        photoSizes.append(size)
        let averageSize = photoSizes.reduce(0, +) / Int64(photoSizes.count)
        
        metrics = CameraMetrics(
            photosCaptured: metrics.photosCaptured + 1,
            videosRecorded: metrics.videosRecorded,
            totalRecordingTime: metrics.totalRecordingTime,
            averagePhotoSize: averageSize,
            averageVideoSize: metrics.averageVideoSize,
            flashUsageCount: metrics.flashUsageCount,
            sessionCount: metrics.sessionCount,
            errorCount: metrics.errorCount,
            averageFocusTime: metrics.averageFocusTime,
            batteryImpact: metrics.batteryImpact
        )
    }
    
    private func updateVideoMetrics(result: VideoRecordingResult) async {
        videoSizes.append(result.fileSize)
        let averageSize = videoSizes.reduce(0, +) / Int64(videoSizes.count)
        
        metrics = CameraMetrics(
            photosCaptured: metrics.photosCaptured,
            videosRecorded: metrics.videosRecorded + 1,
            totalRecordingTime: metrics.totalRecordingTime + result.duration,
            averagePhotoSize: metrics.averagePhotoSize,
            averageVideoSize: averageSize,
            flashUsageCount: metrics.flashUsageCount,
            sessionCount: metrics.sessionCount,
            errorCount: metrics.errorCount,
            averageFocusTime: metrics.averageFocusTime,
            batteryImpact: metrics.batteryImpact
        )
    }
    
    private func updateFocusMetrics(time: TimeInterval) async {
        focusTimes.append(time)
        let averageTime = focusTimes.reduce(0, +) / Double(focusTimes.count)
        
        metrics = CameraMetrics(
            photosCaptured: metrics.photosCaptured,
            videosRecorded: metrics.videosRecorded,
            totalRecordingTime: metrics.totalRecordingTime,
            averagePhotoSize: metrics.averagePhotoSize,
            averageVideoSize: metrics.averageVideoSize,
            flashUsageCount: metrics.flashUsageCount,
            sessionCount: metrics.sessionCount,
            errorCount: metrics.errorCount,
            averageFocusTime: averageTime,
            batteryImpact: metrics.batteryImpact
        )
    }
    
    private func updateSessionMetrics() async {
        metrics = CameraMetrics(
            photosCaptured: metrics.photosCaptured,
            videosRecorded: metrics.videosRecorded,
            totalRecordingTime: metrics.totalRecordingTime,
            averagePhotoSize: metrics.averagePhotoSize,
            averageVideoSize: metrics.averageVideoSize,
            flashUsageCount: metrics.flashUsageCount,
            sessionCount: metrics.sessionCount + 1,
            errorCount: metrics.errorCount,
            averageFocusTime: metrics.averageFocusTime,
            batteryImpact: metrics.batteryImpact
        )
    }
    
    private func updateErrorMetrics() async {
        metrics = CameraMetrics(
            photosCaptured: metrics.photosCaptured,
            videosRecorded: metrics.videosRecorded,
            totalRecordingTime: metrics.totalRecordingTime,
            averagePhotoSize: metrics.averagePhotoSize,
            averageVideoSize: metrics.averageVideoSize,
            flashUsageCount: metrics.flashUsageCount,
            sessionCount: metrics.sessionCount,
            errorCount: metrics.errorCount + 1,
            averageFocusTime: metrics.averageFocusTime,
            batteryImpact: metrics.batteryImpact
        )
    }
}

// MARK: - Capture Delegates

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let onSuccess: (PhotoCaptureResult) -> Void
    private let onError: (Error) -> Void
    
    init(onSuccess: @escaping (PhotoCaptureResult) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            onError(error)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            onError(CameraError.imageDataNotAvailable)
            return
        }
        
        let result = PhotoCaptureResult(
            imageData: imageData,
            metadata: photo.metadata,
            captureDate: Date(),
            flashFired: photo.isFlashFired
        )
        
        onSuccess(result)
    }
}

private class VideoRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let onSuccess: (VideoRecordingResult) -> Void
    private let onError: (Error) -> Void
    
    init(onSuccess: @escaping (VideoRecordingResult) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            onError(error)
            return
        }
        
        // Get video properties
        let asset = AVAsset(url: outputFileURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        // Get file size
        let fileSize = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path)[.size] as? Int64 ?? 0
        
        // Get video dimensions
        let videoTrack = asset.tracks(withMediaType: .video).first
        let size = videoTrack?.naturalSize ?? .zero
        
        let result = VideoRecordingResult(
            videoURL: outputFileURL,
            duration: duration,
            size: size,
            recordingDate: Date(),
            fileSize: fileSize ?? 0
        )
        
        onSuccess(result)
    }
}

// MARK: - Camera Capability Implementation

/// Camera capability providing camera access with video/photo capture
public actor CameraCapability: LocalCapability {
    public typealias ConfigurationType = CameraCapabilityConfiguration
    public typealias ResourceType = CameraCapabilityResource
    
    private var _configuration: CameraCapabilityConfiguration
    private var _resources: CameraCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "camera-capability" }
    
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
    
    public var configuration: CameraCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CameraCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CameraCapabilityConfiguration = CameraCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CameraCapabilityResource(configuration: self._configuration)
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
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: CameraCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Camera configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        !await _resources.getAvailableCameras().isEmpty
    }
    
    public func requestPermission() async throws {
        let status = try await _resources.requestPermission()
        guard status == .authorized else {
            throw CameraError.permissionDenied
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Camera Operations
    
    /// Start camera session
    public func startSession() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        try await _resources.startSession()
    }
    
    /// Stop camera session
    public func stopSession() async {
        await _resources.stopSession()
    }
    
    /// Get current session state
    public func getSessionState() async -> CameraSessionState {
        await _resources.getSessionState()
    }
    
    /// Capture photo
    public func capturePhoto() async throws -> PhotoCaptureResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        return try await _resources.capturePhoto()
    }
    
    /// Start video recording
    public func startVideoRecording() async throws -> URL {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        return try await _resources.startVideoRecording()
    }
    
    /// Stop video recording
    public func stopVideoRecording() async throws -> VideoRecordingResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        return try await _resources.stopVideoRecording()
    }
    
    /// Switch between front and back camera
    public func switchCamera() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        try await _resources.switchCamera()
    }
    
    /// Set zoom factor
    public func setZoomFactor(_ factor: CGFloat) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        try await _resources.setZoomFactor(factor)
    }
    
    /// Set flash mode
    public func setFlashMode(_ mode: CameraSettings.FlashMode) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        try await _resources.setFlashMode(mode)
    }
    
    /// Focus at specific point
    public func focusAt(point: CGPoint) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Camera capability not available")
        }
        
        try await _resources.focusAt(point: point)
    }
    
    /// Get preview layer for UI integration
    public func getPreviewLayer() async -> AVCaptureVideoPreviewLayer? {
        await _resources.getPreviewLayer()
    }
    
    /// Get available cameras
    public func getAvailableCameras() async -> [AVCaptureDevice] {
        await _resources.getAvailableCameras()
    }
    
    /// Get camera capabilities
    public func getCameraCapabilities() async -> [String: Any] {
        await _resources.getCameraCapabilities()
    }
    
    /// Get recording duration (if currently recording)
    public func getRecordingDuration() async -> TimeInterval {
        await _resources.getRecordingDuration()
    }
    
    /// Check if currently recording
    public func isCurrentlyRecording() async -> Bool {
        await _resources.isCurrentlyRecording()
    }
    
    /// Get camera metrics
    public func getMetrics() async -> CameraMetrics {
        await _resources.getMetrics()
    }
    
    /// Get authorization status
    public func getAuthorizationStatus() async -> CameraAuthorizationStatus {
        await _resources.getAuthorizationStatus()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Camera specific errors
public enum CameraError: Error, LocalizedError {
    case permissionDenied
    case cameraNotAvailable
    case sessionNotConfigured
    case inputNotSupported
    case photoOutputNotConfigured
    case movieOutputNotConfigured
    case recordingInProgress
    case notRecording
    case imageDataNotAvailable
    case featureNotSupported(String)
    case configurationFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied"
        case .cameraNotAvailable:
            return "Camera not available"
        case .sessionNotConfigured:
            return "Camera session not configured"
        case .inputNotSupported:
            return "Camera input not supported"
        case .photoOutputNotConfigured:
            return "Photo output not configured"
        case .movieOutputNotConfigured:
            return "Movie output not configured"
        case .recordingInProgress:
            return "Recording already in progress"
        case .notRecording:
            return "Not currently recording"
        case .imageDataNotAvailable:
            return "Image data not available"
        case .featureNotSupported(let feature):
            return "Feature not supported: \(feature)"
        case .configurationFailed(let error):
            return "Camera configuration failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

import CoreLocation

extension PhotoCaptureResult {
    public var image: UIImage? {
        UIImage(data: imageData)
    }
    
    public var thumbnailImage: UIImage? {
        guard let thumbnail = thumbnail else { return nil }
        return UIImage(data: thumbnail)
    }
}