import SwiftUI
import Foundation
import Darwin

struct SwiftUIFile: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let fullPath: String
    let relativePath: String
    let content: String
    
    static func == (lhs: SwiftUIFile, rhs: SwiftUIFile) -> Bool {
        lhs.fullPath == rhs.fullPath
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fullPath)
    }
}

@MainActor
class SwiftUIFileManager: ObservableObject {
    @Published var swiftUIFiles: [SwiftUIFile] = []
    @Published var selectediPhoneFile: SwiftUIFile?
    @Published var selectediPadFile: SwiftUIFile?
    
    private let watchedDirectory: URL
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    
    init() {
        let baseDirectory = "/Users/tojkuv/Documents/GitHub/axiom-full-stack/workspace-meta-workspace/axiom-ide/SwiftUIViews"
        self.watchedDirectory = URL(fileURLWithPath: baseDirectory)
        print("📁 Watching directory: \(watchedDirectory.path)")
    }
    
    func startWatching() {
        scanForFiles()
        startFileSystemMonitoring()
    }
    
    private func scanForFiles() {
        let fileManager = Foundation.FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: watchedDirectory,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey]
        ) else {
            print("Failed to create file enumerator for: \(watchedDirectory.path)")
            return
        }
        
        var files: [SwiftUIFile] = []
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    if content.contains("View") && (content.contains("var body:") || content.contains("var body :")) {
                        let relativePath = fileURL.path.replacingOccurrences(
                            of: watchedDirectory.path + "/",
                            with: ""
                        )
                        
                        let file = SwiftUIFile(
                            name: fileURL.lastPathComponent,
                            fullPath: fileURL.path,
                            relativePath: relativePath,
                            content: content
                        )
                        files.append(file)
                    }
                } catch {
                    print("Failed to read file \(fileURL.path): \(error)")
                }
            }
        }
        
        swiftUIFiles = files.sorted { $0.name < $1.name }
        print("📁 Found \(files.count) SwiftUI files: \(files.map { $0.name }.joined(separator: ", "))")
    }
    
    private func startFileSystemMonitoring() {
        stopFileSystemMonitoring()
        
        fileDescriptor = open(watchedDirectory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("Failed to open directory for monitoring: \(watchedDirectory.path)")
            return
        }
        
        fileSystemSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: DispatchQueue.global(qos: .background)
        )
        
        fileSystemSource?.setEventHandler { [weak self] in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second debounce
                self?.scanForFiles()
            }
        }
        
        fileSystemSource?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }
        
        fileSystemSource?.resume()
        print("Started monitoring directory: \(watchedDirectory.path)")
    }
    
    private func stopFileSystemMonitoring() {
        fileSystemSource?.cancel()
        fileSystemSource = nil
    }
    
    deinit {
        let source = fileSystemSource
        source?.cancel()
        let fd = fileDescriptor
        if fd >= 0 {
            close(fd)
        }
    }
}