import Foundation

final class FileSystemMonitor: @unchecked Sendable {
    private let path: String
    private let onChange: (String) -> Void
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    
    init(path: String, onChange: @escaping (String) -> Void) {
        self.path = path
        self.onChange = onChange
    }
    
    func start() {
        fileDescriptor = open(path, O_EVTONLY)
        
        guard fileDescriptor >= 0 else {
            print("❌ Failed to open directory for monitoring: \(path)")
            return
        }
        
        fileSystemSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: DispatchQueue.global(qos: .background)
        )
        
        fileSystemSource?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        fileSystemSource?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }
        
        fileSystemSource?.resume()
        print("✅ Started monitoring: \(path)")
    }
    
    func stop() {
        fileSystemSource?.cancel()
        fileSystemSource = nil
    }
    
    private func handleFileSystemEvent() {
        // Debounce file changes
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            self?.scanDirectory()
        }
    }
    
    private func scanDirectory() {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                onChange(fileURL.path)
            }
        }
    }
    
    deinit {
        stop()
    }
}