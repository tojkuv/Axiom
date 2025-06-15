import SwiftUI
import Foundation

enum DeviceType: String, CaseIterable, Sendable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    
    var displayName: String {
        rawValue
    }
}

enum SimulatorState: String, Sendable {
    case shutdown = "Shutdown"
    case booted = "Booted"
    case booting = "Booting"
    case shuttingDown = "Shutting Down"
    case unknown = "Unknown"
    
    var displayName: String {
        switch self {
        case .shutdown: return "Shutdown"
        case .booted: return "Booted"
        case .booting: return "Booting"
        case .shuttingDown: return "Shutting Down"
        case .unknown: return "Unknown"
        }
    }
}

struct Simulator: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let deviceType: DeviceType
    let runtime: String
    let state: SimulatorState
    
    var displayName: String {
        "\(name) (\(runtime))"
    }
    
    static func == (lhs: Simulator, rhs: Simulator) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
class SimulatorManager: ObservableObject {
    @Published var simulators: [Simulator] = []
    @Published var iPhoneSimulator: Simulator?
    @Published var iPadSimulator: Simulator?
    @Published var isLoading = false
    
    var iPhoneSimulators: [Simulator] {
        simulators.filter { simulator in
            let isIOS26 = simulator.runtime.contains("iOS 26") || simulator.runtime.contains("iOS26")
            let isiPhone = simulator.name.contains("iPhone 16 Pro") && !simulator.name.contains("Max")
            return isIOS26 && isiPhone
        }
    }
    
    var iPadSimulators: [Simulator] {
        simulators.filter { simulator in
            let isIOS26 = simulator.runtime.contains("iOS 26") || simulator.runtime.contains("iOS26")
            let isiPad = simulator.name.contains("iPad Pro (13-inch)")
            return isIOS26 && isiPad
        }
    }
    
    func loadSimulators() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let output = try await runXcodeCommand(["simctl", "list", "devices", "--json"])
            let simulatorData = try parseSimulatorData(output)
            simulators = simulatorData
            
            // Auto-assign first available simulator for each type
            iPhoneSimulator = iPhoneSimulators.first { $0.state == .booted } ?? iPhoneSimulators.first
            iPadSimulator = iPadSimulators.first { $0.state == .booted } ?? iPadSimulators.first
            
            if let iPhone = iPhoneSimulator {
                print("📱 Detected iPhone: \(iPhone.name) (\(iPhone.state.displayName))")
            }
            if let iPad = iPadSimulator {
                print("📱 Detected iPad: \(iPad.name) (\(iPad.state.displayName))")
            }
            
            print("📱 Loaded \(simulators.count) simulators")
        } catch {
            print("Failed to load simulators: \(error)")
        }
    }
    
    func bootSimulator(_ simulator: Simulator) async {
        do {
            _ = try await runXcodeCommand(["simctl", "boot", simulator.id])
            await loadSimulators() // Refresh status
            print("📱 Booting simulator: \(simulator.name)")
        } catch {
            print("Failed to boot simulator \(simulator.name): \(error)")
        }
    }
    
    func shutdownSimulator(_ simulator: Simulator) async {
        do {
            _ = try await runXcodeCommand(["simctl", "shutdown", simulator.id])
            await loadSimulators() // Refresh status
            print("📱 Shutting down simulator: \(simulator.name)")
        } catch {
            print("Failed to shutdown simulator \(simulator.name): \(error)")
        }
    }
    
    func buildAndInstallPreviewApp(on simulator: Simulator) async throws {
        let bundleId = "com.axiom.HotReloadApp"
        
        // Build the iOS app
        try await buildPreviewApp()
        
        // Install on simulator
        try await installPreviewApp(on: simulator)
        
        // Launch the app
        try await launchApp(bundleId: bundleId, on: simulator)
    }
    
    private func buildPreviewApp() async throws {
        let projectPath = "/Users/tojkuv/Documents/GitHub/axiom-full-stack/workspace-meta-workspace/axiom-ide/HotReloadApp/HotReloadApp.xcodeproj"
        print("🔨 Building iOS app at: \(projectPath)")
        
        let buildProcess = Process()
        buildProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        buildProcess.arguments = [
            "-project", projectPath,
            "-scheme", "HotReloadApp",
            "-sdk", "iphonesimulator",
            "-destination", "platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0",
            "-configuration", "Debug",
            "-derivedDataPath", "/tmp/HotReloadApp-Build",
            "build"
        ]
        
        let pipe = Pipe()
        buildProcess.standardOutput = pipe
        buildProcess.standardError = pipe
        
        try buildProcess.run()
        buildProcess.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if buildProcess.terminationStatus != 0 {
            print("❌ iOS app build failed:")
            print(output)
            throw SimulatorError.buildFailed("iOS app build failed: \(output)")
        }
        
        print("✅ iOS Preview app built successfully")
    }
    
    private func installPreviewApp(on simulator: Simulator) async throws {
        // Find the built app
        let appPath = "/tmp/HotReloadApp-Build/Build/Products/Debug-iphonesimulator/HotReloadApp.app"
        
        let installProcess = Process()
        installProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        installProcess.arguments = ["simctl", "install", simulator.id, appPath]
        
        try installProcess.run()
        installProcess.waitUntilExit()
        
        if installProcess.terminationStatus != 0 {
            throw SimulatorError.installFailed("Failed to install app on simulator")
        }
        
        print("📱 iOS Preview app installed on \(simulator.name)")
    }
    
    func launchApp(bundleId: String, on simulator: Simulator) async throws {
        let launchProcess = Process()
        launchProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        launchProcess.arguments = ["simctl", "launch", simulator.id, bundleId]
        
        try launchProcess.run()
        launchProcess.waitUntilExit()
        
        if launchProcess.terminationStatus != 0 {
            throw SimulatorError.launchFailed("Failed to launch app")
        }
        
        print("🚀 Launched app \(bundleId) on \(simulator.name)")
    }
    
    func isAppInstalled(bundleId: String, on simulator: Simulator) async -> Bool {
        do {
            let output = try await runXcodeCommand(["simctl", "get_app_container", simulator.id, bundleId])
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }
    
    private func runXcodeCommand(_ arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func parseSimulatorData(_ json: String) throws -> [Simulator] {
        let data = json.data(using: .utf8) ?? Data()
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let devices = response["devices"] as? [String: [[String: Any]]] ?? [:]
        
        var simulators: [Simulator] = []
        
        for (runtime, deviceList) in devices {
            for device in deviceList {
                guard let name = device["name"] as? String,
                      let udid = device["udid"] as? String,
                      let stateString = device["state"] as? String else { continue }
                
                let deviceType: DeviceType
                if name.contains("iPad") {
                    deviceType = .iPad
                } else {
                    deviceType = .iPhone
                }
                
                let state = SimulatorState(rawValue: stateString) ?? .unknown
                let cleanRuntime = runtime
                    .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                    .replacingOccurrences(of: "-", with: " ")
                
                let simulator = Simulator(
                    id: udid,
                    name: name,
                    deviceType: deviceType,
                    runtime: cleanRuntime,
                    state: state
                )
                
                simulators.append(simulator)
            }
        }
        
        return simulators.sorted { first, second in
            if first.deviceType != second.deviceType {
                return first.deviceType.rawValue < second.deviceType.rawValue
            }
            if first.state != second.state {
                return first.state == .booted
            }
            return first.name < second.name
        }
    }
}

enum SimulatorError: Error, LocalizedError {
    case buildFailed(String)
    case installFailed(String)
    case launchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .buildFailed(let message): return "Build failed: \(message)"
        case .installFailed(let message): return "Installation failed: \(message)"
        case .launchFailed(let message): return "Launch failed: \(message)"
        }
    }
}