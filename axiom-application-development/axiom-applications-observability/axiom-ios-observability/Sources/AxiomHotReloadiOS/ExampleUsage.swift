import SwiftUI

// MARK: - Example Usage Patterns

#if DEBUG
/// Example demonstrations of how to integrate AxiomHotReload into SwiftUI applications.
/// These examples show the various ways developers can use the hot reload functionality.
public struct ExampleUsage {
    
    // MARK: - Basic Usage (3-line integration)
    
    /// The simplest possible integration - just wrap your content view
    static func basicExample() -> some View {
        AxiomHotReload {
            MyContentView()
        }
    }
    
    // MARK: - Custom Host/Port
    
    /// Connect to a specific host and port
    static func customHostExample() -> some View {
        AxiomHotReload(host: "192.168.1.100", port: 8080) {
            MyContentView()
        }
    }
    
    // MARK: - Development Configuration
    
    /// Development setup with debugging enabled
    static func developmentExample() -> some View {
        AxiomHotReload.development(host: "localhost") {
            MyContentView()
        }
    }
    
    // MARK: - Production Configuration
    
    /// Production setup with hot reload disabled
    static func productionExample() -> some View {
        AxiomHotReload.production {
            MyContentView()
        }
    }
    
    // MARK: - Advanced Configuration
    
    /// Custom configuration with specific settings
    static func advancedExample() -> some View {
        let config = AxiomHotReloadConfiguration.builder()
            .host("localhost")
            .port(8080)
            .autoConnect(true)
            .enableDebugMode(true)
            .showStatusIndicator(true)
            .statusIndicatorColors(.subtle())
            .build()
        
        return AxiomHotReload(configuration: config) {
            MyContentView()
        }
    }
    
    // MARK: - Environment-based Configuration
    
    /// Configuration from environment variables
    static func environmentExample() -> some View {
        AxiomHotReload(configuration: .fromEnvironment()) {
            MyContentView()
        }
    }
    
    // MARK: - Conditional Hot Reload
    
    /// Only enable hot reload in debug builds
    static func conditionalExample() -> some View {
        #if DEBUG
        AxiomHotReload.development() {
            MyContentView()
        }
        #else
        MyContentView()
        #endif
    }
    
    // MARK: - With NavigationView
    
    /// Integration with NavigationView
    static func navigationExample() -> some View {
        NavigationView {
            AxiomHotReload {
                MyContentView()
                    .navigationTitle("Hot Reload Demo")
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }
    
    // MARK: - With TabView
    
    /// Integration with TabView
    static func tabViewExample() -> some View {
        TabView {
            AxiomHotReload {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            
            AxiomHotReload {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
    
    // MARK: - With App-level Integration
    
    /// Integration at the App level (in @main App struct)
    static func appLevelExample() -> some View {
        WindowGroup {
            AxiomHotReload {
                ContentView()
            }
        }
    }
    
    // MARK: - Multiple Configurations
    
    /// Different configurations for different views
    static func multipleConfigurationsExample() -> some View {
        VStack {
            // Main content with hot reload
            AxiomHotReload.development() {
                MainContentView()
            }
            
            Divider()
            
            // Settings panel without hot reload (production config)
            AxiomHotReload.production() {
                SettingsPanel()
            }
        }
    }
    
    // MARK: - Programmatic Control
    
    /// Programmatic control over hot reload connection
    struct ProgrammaticControlExample: View {
        @State private var hotReload = AxiomHotReload.development {
            MyContentView()
        }
        
        var body: some View {
            VStack {
                hotReload
                
                HStack {
                    Button("Connect") {
                        hotReload.connect()
                    }
                    
                    Button("Disconnect") {
                        hotReload.disconnect()
                    }
                    
                    Button("Reset") {
                        hotReload.reset()
                    }
                    
                    Button("Toggle Debug") {
                        hotReload.toggleDebugInfo()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Sample Content Views

/// Sample content view for examples
private struct MyContentView: View {
    @State private var counter = 0
    @State private var text = "Hello, Hot Reload!"
    @State private var isToggled = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Counter: \(counter)")
                .font(.headline)
            
            Button("Increment") {
                counter += 1
            }
            .buttonStyle(.borderedProminent)
            
            Toggle("Toggle Me", isOn: $isToggled)
                .padding(.horizontal)
            
            TextField("Enter text", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
        }
        .padding()
    }
}

private struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home View")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "house.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings View")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "gear")
                .font(.system(size: 50))
                .foregroundColor(.gray)
        }
    }
}

private struct ContentView: View {
    var body: some View {
        Text("Main App Content")
            .font(.title)
    }
}

private struct MainContentView: View {
    var body: some View {
        Text("Main Content with Hot Reload")
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

private struct SettingsPanel: View {
    var body: some View {
        Text("Settings Panel (No Hot Reload)")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

#endif

// MARK: - Documentation Examples

/// Documentation code examples that can be used in README and guides
public struct DocumentationExamples {
    
    /// Basic integration example for README
    public static let basicIntegration = """
    import SwiftUI
    import AxiomHotReloadiOS
    
    struct ContentView: View {
        var body: some View {
            AxiomHotReload {
                VStack {
                    Text("Hello, Hot Reload!")
                        .font(.title)
                    
                    Button("Press Me") {
                        print("Button pressed!")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
    """
    
    /// App-level integration example
    public static let appIntegration = """
    import SwiftUI
    import AxiomHotReloadiOS
    
    @main
    struct MyApp: App {
        var body: some Scene {
            WindowGroup {
                AxiomHotReload {
                    ContentView()
                }
            }
        }
    }
    """
    
    /// Custom configuration example
    public static let customConfiguration = """
    import SwiftUI
    import AxiomHotReloadiOS
    
    struct ContentView: View {
        var body: some View {
            AxiomHotReload.development(host: "192.168.1.100", port: 8080) {
                MyView()
            }
        }
    }
    """
    
    /// Production configuration example
    public static let productionConfiguration = """
    struct ContentView: View {
        var body: some View {
            #if DEBUG
            AxiomHotReload.development() {
                MyView()
            }
            #else
            MyView()
            #endif
        }
    }
    """
}