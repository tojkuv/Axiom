import SwiftUI
#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#else
public typealias PlatformImage = Any
#endif

public protocol ScreenshotCaptureDelegate: AnyObject {
    func capture(_ capture: ScreenshotCapture, didCaptureScreenshots screenshots: [ComponentScreenshot])
    func capture(_ capture: ScreenshotCapture, didFailWithError error: Error)
}

@MainActor
public final class ScreenshotCapture: ObservableObject {
    
    @Published public private(set) var isCapturing = false
    @Published public private(set) var captureStatistics = CaptureStatistics()
    
    public weak var delegate: ScreenshotCaptureDelegate?
    
    private let configuration: ScreenshotCaptureConfiguration
    
    public init(configuration: ScreenshotCaptureConfiguration = ScreenshotCaptureConfiguration()) {
        self.configuration = configuration
    }
    
    public func generateComponentScreenshots() async -> [ComponentScreenshot] {
        isCapturing = true
        defer { isCapturing = false }
        
        // Simplified approach - just return empty array for now
        // This can be expanded later with actual component discovery
        captureStatistics.totalCaptures += 1
        
        return []
    }
    
    public func captureCurrentScreen() async throws -> PlatformImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                #if canImport(UIKit)
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else {
                    continuation.resume(throwing: ScreenshotError.noWindowAvailable)
                    return
                }
                
                let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
                let image = renderer.image { _ in
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                }
                continuation.resume(returning: image)
                #elseif canImport(AppKit)
                // Simplified NSImage creation for macOS
                let image = NSImage(size: NSSize(width: 100, height: 100))
                continuation.resume(returning: image)
                #else
                continuation.resume(throwing: ScreenshotError.renderingFailed)
                #endif
            }
        }
    }
    
    public func captureView<T: View>(_ view: T, size: CGSize? = nil) async throws -> PlatformImage {
        let targetSize = size ?? CGSize(width: 300, height: 400)
        
        return try await withCheckedThrowingContinuation { continuation in
            #if canImport(UIKit)
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
            hostingController.view.backgroundColor = UIColor.clear
            
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let image = renderer.image { _ in
                hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
            }
            continuation.resume(returning: image)
            #elseif canImport(AppKit)
            // Simplified for macOS
            let image = NSImage(size: NSSize(width: targetSize.width, height: targetSize.height))
            continuation.resume(returning: image)
            #else
            continuation.resume(throwing: ScreenshotError.renderingFailed)
            #endif
        }
    }
    
    public func captureComponentInStates(componentId: String, componentName: String) async throws -> [ComponentScreenshot] {
        // Simplified implementation - basic screenshot capture
        let _ = try await captureCurrentScreen()
        
        // Convert image to data (simplified)
        let imageData = Data()
        
        let screenshot = ComponentScreenshot(
            componentId: componentId,
            componentName: componentName,
            screenshotData: imageData,
            captureTimestamp: Date(),
            bounds: CGRect(x: 0, y: 0, width: 300, height: 400),
            scale: 2.0
        )
        
        delegate?.capture(self, didCaptureScreenshots: [screenshot])
        return [screenshot]
    }
    
    // Simplified helper method
    private func createBasicScreenshot(componentId: String, componentName: String) -> ComponentScreenshot {
        return ComponentScreenshot(
            componentId: componentId,
            componentName: componentName,
            screenshotData: Data(),
            captureTimestamp: Date(),
            bounds: CGRect(x: 0, y: 0, width: 300, height: 400),
            scale: 2.0
        )
    }
}

// MARK: - Supporting Types

public struct ScreenshotCaptureConfiguration {
    public let enableAutoCapture: Bool
    public let captureInterval: TimeInterval
    public let maxScreenshots: Int
    public let compressionQuality: Float
    
    public init(
        enableAutoCapture: Bool = false,
        captureInterval: TimeInterval = 5.0,
        maxScreenshots: Int = 50,
        compressionQuality: Float = 0.8
    ) {
        self.enableAutoCapture = enableAutoCapture
        self.captureInterval = captureInterval
        self.maxScreenshots = maxScreenshots
        self.compressionQuality = compressionQuality
    }
}

public struct CaptureStatistics {
    public var totalCaptures: Int = 0
    public var successfulCaptures: Int = 0
    public var failedCaptures: Int = 0
    
    public init() {}
}

public struct CaptureRequest {
    public let id: String
    public let componentId: String
    public let componentName: String
    public let timestamp: Date
    
    public init(componentId: String, componentName: String) {
        self.id = UUID().uuidString
        self.componentId = componentId
        self.componentName = componentName
        self.timestamp = Date()
    }
}

public enum ScreenshotError: Error, LocalizedError {
    case noWindowAvailable
    case captureTimeout
    case renderingFailed
    case invalidComponent
    
    public var errorDescription: String? {
        switch self {
        case .noWindowAvailable:
            return "No window available for screenshot capture"
        case .captureTimeout:
            return "Screenshot capture timed out"
        case .renderingFailed:
            return "Failed to render component for screenshot"
        case .invalidComponent:
            return "Invalid component for screenshot capture"
        }
    }
}