use crate::error::{Error, Result};
use crate::generators::registry::GenerationContext;
use crate::generators::swift::naming::SwiftNaming;
use crate::proto::types::*;
use crate::utils::file_manager::FileManager;
use std::collections::HashMap;

/// Generate comprehensive documentation for Swift client code
pub struct SwiftDocumentationGenerator {
    naming: SwiftNaming,
}

impl SwiftDocumentationGenerator {
    pub fn new() -> Self {
        Self {
            naming: SwiftNaming::new(),
        }
    }

    /// Generate complete documentation suite for generated Swift code
    pub async fn generate_documentation(
        &self,
        context: &GenerationContext,
        _generated_files: &[String],
    ) -> Result<Vec<String>> {
        let mut doc_files = Vec::new();
        
        // Create documentation directory
        let docs_dir = context.config.output_dir.join("swift/Documentation");
        std::fs::create_dir_all(&docs_dir)?;

        // Generate overview documentation
        let overview_file = self.generate_overview_doc(context, &docs_dir).await?;
        doc_files.push(overview_file);

        // Generate API reference
        let api_ref_file = self.generate_api_reference(context, &docs_dir).await?;
        doc_files.push(api_ref_file);

        // Generate integration guide
        let integration_file = self.generate_integration_guide(context, &docs_dir).await?;
        doc_files.push(integration_file);

        // Generate usage examples
        let examples_file = self.generate_usage_examples(context, &docs_dir).await?;
        doc_files.push(examples_file);

        // Generate troubleshooting guide
        let troubleshooting_file = self.generate_troubleshooting_guide(context, &docs_dir).await?;
        doc_files.push(troubleshooting_file);

        Ok(doc_files)
    }

    /// Generate project overview documentation
    async fn generate_overview_doc(
        &self,
        context: &GenerationContext,
        docs_dir: &std::path::Path,
    ) -> Result<String> {
        let file_path = docs_dir.join("README.md");
        
        let mut content = String::new();
        content.push_str("# Generated Swift Clients - Axiom Framework Integration\n\n");
        content.push_str("This directory contains automatically generated Swift clients that integrate with the Axiom Apple framework.\n\n");
        
        // Project overview
        content.push_str("## Overview\n\n");
        content.push_str("Generated using Axiom Swift Client Generator\n");
        content.push_str(&format!("Generation time: {}\n", chrono::Utc::now().format("%Y-%m-%d %H:%M:%S UTC")));
        content.push_str(&format!("Services: {}\n\n", context.schema.services.len()));

        // Architecture section
        content.push_str("## Architecture\n\n");
        content.push_str("The generated code follows the Axiom framework patterns:\n\n");
        content.push_str("- **Actor-based Clients**: Thread-safe actors conforming to `AxiomClient`\n");
        content.push_str("- **Immutable State**: State structs following `AxiomState` protocol\n");
        content.push_str("- **Type-safe Actions**: Action enums with validation and metadata\n");
        content.push_str("- **Reactive Streams**: AsyncStream-based state observation\n");
        content.push_str("- **Error Handling**: Comprehensive error types with recovery strategies\n\n");

        // Generated files section
        content.push_str("## Generated Files\n\n");
        content.push_str("### Client Files\n");
        for service in &context.schema.services {
            let client_name = self.naming.client_name(&service.name);
            let state_name = self.naming.state_name(&service.name);
            let action_name = self.naming.action_name(&service.name);
            
            content.push_str(&format!("- `{}.swift` - Main client actor\n", client_name));
            content.push_str(&format!("- `{}.swift` - Immutable state container\n", state_name));
            content.push_str(&format!("- `{}.swift` - Action enum with validation\n", action_name));
        }
        
        content.push_str("\n### Support Files\n");
        content.push_str("- `AxiomErrors.swift` - Error types and handling\n");
        content.push_str("- Contract files for proto message types\n\n");

        // Quick start section
        content.push_str("## Quick Start\n\n");
        content.push_str("1. Add the generated files to your Xcode project\n");
        content.push_str("2. Import required dependencies:\n");
        content.push_str("   ```swift\n");
        content.push_str("   import AxiomCore\n");
        content.push_str("   import AxiomArchitecture\n");
        content.push_str("   ```\n");
        content.push_str("3. Initialize and use the client:\n");
        
        if let Some(service) = context.schema.services.first() {
            let client_name = self.naming.client_name(&service.name);
            content.push_str("   ```swift\n");
            content.push_str(&format!("   let client = {}(apiClient: yourApiClient)\n", client_name));
            content.push_str("   ```\n\n");
        }

        content.push_str("## Documentation\n\n");
        content.push_str("- [API Reference](./APIReference.md) - Detailed API documentation\n");
        content.push_str("- [Integration Guide](./IntegrationGuide.md) - Step-by-step integration\n");
        content.push_str("- [Usage Examples](./UsageExamples.md) - Code examples and patterns\n");
        content.push_str("- [Troubleshooting](./Troubleshooting.md) - Common issues and solutions\n\n");

        content.push_str("---\n");
        content.push_str("*Generated by Axiom Swift Client Generator*\n");

        FileManager::write_file(&file_path, &content, true).await?;
        Ok(file_path.to_string_lossy().to_string())
    }

    /// Generate detailed API reference documentation
    async fn generate_api_reference(
        &self,
        context: &GenerationContext,
        docs_dir: &std::path::Path,
    ) -> Result<String> {
        let file_path = docs_dir.join("APIReference.md");
        
        let mut content = String::new();
        content.push_str("# API Reference\n\n");
        content.push_str("Complete reference for all generated types and methods.\n\n");

        // Generate documentation for each service
        for service in &context.schema.services {
            content.push_str(&self.generate_service_documentation(service)?);
        }

        FileManager::write_file(&file_path, &content, true).await?;
        Ok(file_path.to_string_lossy().to_string())
    }

    /// Generate documentation for a specific service
    fn generate_service_documentation(&self, service: &Service) -> Result<String> {
        let mut content = String::new();
        
        let client_name = self.naming.client_name(&service.name);
        let state_name = self.naming.state_name(&service.name);
        let action_name = self.naming.action_name(&service.name);

        content.push_str(&format!("## {} Service\n\n", service.name));
        
        if let Some(doc) = &service.documentation {
            content.push_str(&format!("{}\n\n", doc));
        }

        // Client Actor Documentation
        content.push_str(&format!("### {}\n\n", client_name));
        content.push_str(&format!("Actor-based client for {} operations.\n\n", service.name));
        
        content.push_str("#### Properties\n\n");
        content.push_str(&format!("- `stateStream: AsyncStream<{}>`\n", &state_name));
        content.push_str("  - Reactive stream of state updates\n");
        content.push_str("  - Automatically emits new state when changes occur\n\n");

        content.push_str("#### Methods\n\n");
        content.push_str(&format!("- `func process(_ action: {}) async throws`\n", action_name));
        content.push_str("  - Process an action and update state\n");
        content.push_str("  - Validates action before processing\n");
        content.push_str("  - Notifies observers of state changes\n\n");

        content.push_str(&format!("- `func getCurrentState() async -> {}`\n", state_name));
        content.push_str("  - Get current state synchronously\n");
        content.push_str("  - Thread-safe access to state\n\n");

        content.push_str(&format!("- `func rollbackToState(_ state: {}) async`\n", state_name));
        content.push_str("  - Rollback to a previous state\n");
        content.push_str("  - Useful for error recovery\n\n");

        // State Documentation
        content.push_str(&format!("### {}\n\n", state_name));
        content.push_str("Immutable state container following Axiom patterns.\n\n");
        
        content.push_str("#### Properties\n\n");
        content.push_str("- `isLoading: Bool` - Loading state indicator\n");
        content.push_str("- `error: Error?` - Last error that occurred\n");
        content.push_str("- `lastUpdated: Date` - Timestamp of last update\n\n");

        content.push_str("#### Update Methods\n\n");
        content.push_str("All state updates return new instances (immutable):\n\n");
        content.push_str("- `withLoading(_:)` - Update loading state\n");
        content.push_str("- `withError(_:)` - Update error state\n");
        content.push_str("- Collection-specific update methods\n\n");

        // Action Documentation
        content.push_str(&format!("### {}\n\n", action_name));
        content.push_str("Type-safe action enum for all service operations.\n\n");
        
        content.push_str("#### Cases\n\n");
        for method in &service.methods {
            let method_name = self.naming.method_name(&method.name);
            content.push_str(&format!("- `.{}` - {}\n", method_name, 
                method.documentation.as_deref().unwrap_or(&format!("{} operation", method.name))));
        }

        content.push_str("\n#### Validation\n\n");
        content.push_str("- `var isValid: Bool` - Check if action is valid\n");
        content.push_str("- `var validationErrors: [String]` - Get validation errors\n\n");

        content.push_str("#### Metadata\n\n");
        content.push_str("- `var requiresNetworkAccess: Bool` - Network requirement\n");
        content.push_str("- `var modifiesState: Bool` - State modification flag\n");
        content.push_str("- `var actionName: String` - Action identifier\n\n");

        content.push_str("---\n\n");
        
        Ok(content)
    }

    /// Generate integration guide
    async fn generate_integration_guide(
        &self,
        context: &GenerationContext,
        docs_dir: &std::path::Path,
    ) -> Result<String> {
        let file_path = docs_dir.join("IntegrationGuide.md");
        
        let mut content = String::new();
        content.push_str("# Integration Guide\n\n");
        content.push_str("Step-by-step guide to integrating generated Swift clients with your application.\n\n");

        // Prerequisites
        content.push_str("## Prerequisites\n\n");
        content.push_str("- Xcode 15.0 or later\n");
        content.push_str("- iOS 15.0+ / macOS 12.0+\n");
        content.push_str("- Swift 5.9+\n");
        content.push_str("- Axiom framework dependencies\n\n");

        // Installation
        content.push_str("## Installation\n\n");
        content.push_str("### 1. Add Framework Dependencies\n\n");
        content.push_str("Add to your `Package.swift`:\n\n");
        content.push_str("```swift\n");
        content.push_str("dependencies: [\n");
        content.push_str("    .package(url: \"https://github.com/axiom/axiom-core\", from: \"1.0.0\"),\n");
        content.push_str("    .package(url: \"https://github.com/axiom/axiom-architecture\", from: \"1.0.0\")\n");
        content.push_str("]\n");
        content.push_str("```\n\n");

        content.push_str("### 2. Add Generated Files\n\n");
        content.push_str("1. Copy all generated `.swift` files to your project\n");
        content.push_str("2. Add them to your target in Xcode\n");
        content.push_str("3. Ensure proper module organization\n\n");

        // Basic Usage
        content.push_str("## Basic Usage\n\n");
        content.push_str("### 1. Initialize Client\n\n");
        
        if let Some(service) = context.schema.services.first() {
            let client_name = self.naming.client_name(&service.name);
            let state_name = self.naming.state_name(&service.name);
            
            content.push_str("```swift\n");
            content.push_str("import AxiomCore\n");
            content.push_str("import AxiomArchitecture\n");
            content.push_str("import YourGeneratedModule\n\n");
            content.push_str("class MyViewController: UIViewController {\n");
            content.push_str(&format!("    private let client = {}()\n", client_name));
            content.push_str("    private var stateObserver: Task<Void, Never>?\n\n");
            content.push_str("    override func viewDidLoad() {\n");
            content.push_str("        super.viewDidLoad()\n");
            content.push_str("        observeState()\n");
            content.push_str("    }\n");
            content.push_str("}\n");
            content.push_str("```\n\n");

            content.push_str("### 2. Observe State Changes\n\n");
            content.push_str("```swift\n");
            content.push_str("private func observeState() {\n");
            content.push_str("    stateObserver = Task {\n");
            content.push_str("        for await state in client.stateStream {\n");
            content.push_str("            await updateUI(with: state)\n");
            content.push_str("        }\n");
            content.push_str("    }\n");
            content.push_str("}\n\n");
            content.push_str(&format!("@MainActor\nprivate func updateUI(with state: {}) {{\n", state_name));
            content.push_str("    // Update your UI based on state\n");
            content.push_str("    loadingIndicator.isHidden = !state.isLoading\n");
            content.push_str("    errorLabel.text = state.error?.localizedDescription\n");
            content.push_str("}\n");
            content.push_str("```\n\n");
        }

        // Error Handling
        content.push_str("## Error Handling\n\n");
        content.push_str("### Built-in Error Types\n\n");
        content.push_str("```swift\n");
        content.push_str("do {\n");
        content.push_str("    try await client.process(.someAction(request))\n");
        content.push_str("} catch let error as AxiomError {\n");
        content.push_str("    switch error {\n");
        content.push_str("    case .networkError(let message):\n");
        content.push_str("        // Handle network errors\n");
        content.push_str("        showNetworkErrorAlert(message)\n");
        content.push_str("    case .validationError(let message):\n");
        content.push_str("        // Handle validation errors\n");
        content.push_str("        showValidationError(message)\n");
        content.push_str("    default:\n");
        content.push_str("        // Handle other errors\n");
        content.push_str("        showGenericError(error)\n");
        content.push_str("    }\n");
        content.push_str("}\n");
        content.push_str("```\n\n");

        // Best Practices
        content.push_str("## Best Practices\n\n");
        content.push_str("### 1. State Management\n\n");
        content.push_str("- Always observe state changes through `stateStream`\n");
        content.push_str("- Use `getCurrentState()` for synchronous access when needed\n");
        content.push_str("- Implement proper cleanup in `deinit`\n\n");

        content.push_str("### 2. Action Validation\n\n");
        content.push_str("```swift\n");
        content.push_str("let action = SomeAction.create(request)\n");
        content.push_str("guard action.isValid else {\n");
        content.push_str("    let errors = action.validationErrors\n");
        content.push_str("    showValidationErrors(errors)\n");
        content.push_str("    return\n");
        content.push_str("}\n\n");
        content.push_str("try await client.process(action)\n");
        content.push_str("```\n\n");

        content.push_str("### 3. Memory Management\n\n");
        content.push_str("```swift\n");
        content.push_str("deinit {\n");
        content.push_str("    stateObserver?.cancel()\n");
        content.push_str("}\n");
        content.push_str("```\n\n");

        FileManager::write_file(&file_path, &content, true).await?;
        Ok(file_path.to_string_lossy().to_string())
    }

    /// Generate usage examples
    async fn generate_usage_examples(
        &self,
        context: &GenerationContext,
        docs_dir: &std::path::Path,
    ) -> Result<String> {
        let file_path = docs_dir.join("UsageExamples.md");
        
        let mut content = String::new();
        content.push_str("# Usage Examples\n\n");
        content.push_str("Real-world examples showing how to use the generated Swift clients.\n\n");

        // Generate examples for each service
        for (index, service) in context.schema.services.iter().enumerate() {
            content.push_str(&self.generate_service_examples(service, index + 1)?);
        }

        FileManager::write_file(&file_path, &content, true).await?;
        Ok(file_path.to_string_lossy().to_string())
    }

    /// Generate examples for a specific service
    fn generate_service_examples(&self, service: &Service, example_num: usize) -> Result<String> {
        let mut content = String::new();
        
        let client_name = self.naming.client_name(&service.name);
        let action_name = self.naming.action_name(&service.name);
        
        content.push_str(&format!("## Example {}: {} Service\n\n", example_num, service.name));

        // Basic CRUD example
        content.push_str("### Basic Operations\n\n");
        content.push_str("```swift\n");
        content.push_str("import Foundation\n");
        content.push_str("import AxiomCore\n");
        content.push_str("import AxiomArchitecture\n\n");
        
        content.push_str("class ServiceManager {\n");
        content.push_str(&format!("    private let client = {}()\n", client_name));
        content.push_str("    private var observations: Set<Task<Void, Never>> = []\n\n");
        
        content.push_str("    func start() {\n");
        content.push_str("        observeStateChanges()\n");
        content.push_str("        loadInitialData()\n");
        content.push_str("    }\n\n");

        // State observation example
        content.push_str("    private func observeStateChanges() {\n");
        content.push_str("        let task = Task {\n");
        content.push_str("            for await state in client.stateStream {\n");
        content.push_str("                await handleStateChange(state)\n");
        content.push_str("            }\n");
        content.push_str("        }\n");
        content.push_str("        observations.insert(task)\n");
        content.push_str("    }\n\n");

        // Method examples
        for method in service.methods.iter().take(3) {
            let method_name = self.naming.method_name(&method.name);
            content.push_str(&format!("    func {}() async throws {{\n", method_name));
            content.push_str(&format!("        let action = {}.{}(/* parameters */)\n", action_name, method_name));
            content.push_str("        try await client.process(action)\n");
            content.push_str("    }\n\n");
        }

        content.push_str("    deinit {\n");
        content.push_str("        observations.forEach { $0.cancel() }\n");
        content.push_str("    }\n");
        content.push_str("}\n");
        content.push_str("```\n\n");

        // SwiftUI example
        content.push_str("### SwiftUI Integration\n\n");
        content.push_str("```swift\n");
        content.push_str("import SwiftUI\n");
        content.push_str("import AxiomCore\n\n");
        
        content.push_str(&format!("struct {}View: View {{\n", service.name));
        content.push_str(&format!("    @StateObject private var viewModel = {}ViewModel()\n", service.name));
        content.push_str("    \n");
        content.push_str("    var body: some View {\n");
        content.push_str("        NavigationView {\n");
        content.push_str("            VStack {\n");
        content.push_str("                if viewModel.isLoading {\n");
        content.push_str("                    ProgressView(\"Loading...\")\n");
        content.push_str("                } else {\n");
        content.push_str("                    // Your content here\n");
        content.push_str("                }\n");
        content.push_str("            }\n");
        content.push_str(&format!("            .navigationTitle(\"{}\")\n", &service.name));
        content.push_str("        }\n");
        content.push_str("        .onAppear {\n");
        content.push_str("            viewModel.loadData()\n");
        content.push_str("        }\n");
        content.push_str("    }\n");
        content.push_str("}\n\n");

        content.push_str(&format!("@MainActor\nclass {}ViewModel: ObservableObject {{\n", service.name));
        content.push_str(&format!("    private let client = {}()\n", client_name));
        content.push_str("    @Published var isLoading = false\n");
        content.push_str("    @Published var error: String?\n");
        content.push_str("    private var stateTask: Task<Void, Never>?\n\n");
        
        content.push_str("    init() {\n");
        content.push_str("        observeState()\n");
        content.push_str("    }\n\n");
        
        content.push_str("    func loadData() {\n");
        content.push_str("        Task {\n");
        content.push_str("            // Implement your data loading\n");
        content.push_str("        }\n");
        content.push_str("    }\n");
        content.push_str("}\n");
        content.push_str("```\n\n");

        content.push_str("---\n\n");
        Ok(content)
    }

    /// Generate troubleshooting guide
    async fn generate_troubleshooting_guide(
        &self,
        _context: &GenerationContext,
        docs_dir: &std::path::Path,
    ) -> Result<String> {
        let file_path = docs_dir.join("Troubleshooting.md");
        
        let mut content = String::new();
        content.push_str("# Troubleshooting Guide\n\n");
        content.push_str("Common issues and solutions when working with generated Swift clients.\n\n");

        // Compilation Issues
        content.push_str("## Compilation Issues\n\n");
        content.push_str("### Missing Framework Dependencies\n\n");
        content.push_str("**Error**: `Cannot find 'AxiomClient' in scope`\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("1. Ensure you've added the required dependencies:\n");
        content.push_str("   ```swift\n");
        content.push_str("   import AxiomCore\n");
        content.push_str("   import AxiomArchitecture\n");
        content.push_str("   ```\n");
        content.push_str("2. Verify the frameworks are properly linked in your project\n\n");

        content.push_str("### Actor Isolation Errors\n\n");
        content.push_str("**Error**: `Expression is 'async' but is not marked with 'await'`\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("Always use `await` when calling actor methods:\n");
        content.push_str("```swift\n");
        content.push_str("let state = await client.getCurrentState()\n");
        content.push_str("try await client.process(action)\n");
        content.push_str("```\n\n");

        // Runtime Issues
        content.push_str("## Runtime Issues\n\n");
        content.push_str("### State Not Updating\n\n");
        content.push_str("**Issue**: UI not reflecting state changes\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("1. Ensure you're observing the state stream:\n");
        content.push_str("   ```swift\n");
        content.push_str("   for await state in client.stateStream {\n");
        content.push_str("       await updateUI(with: state)\n");
        content.push_str("   }\n");
        content.push_str("   ```\n");
        content.push_str("2. Make sure UI updates happen on the main thread\n\n");

        content.push_str("### Action Validation Failures\n\n");
        content.push_str("**Issue**: Actions being rejected due to validation\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("Always validate actions before processing:\n");
        content.push_str("```swift\n");
        content.push_str("let action = MyAction.create(request)\n");
        content.push_str("if !action.isValid {\n");
        content.push_str("    print(\"Validation errors: \\(action.validationErrors)\")\n");
        content.push_str("    return\n");
        content.push_str("}\n");
        content.push_str("try await client.process(action)\n");
        content.push_str("```\n\n");

        // Memory Issues
        content.push_str("## Memory Issues\n\n");
        content.push_str("### Memory Leaks in State Observation\n\n");
        content.push_str("**Issue**: App memory usage growing over time\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("Properly cancel observation tasks:\n");
        content.push_str("```swift\n");
        content.push_str("class MyViewController: UIViewController {\n");
        content.push_str("    private var stateObserver: Task<Void, Never>?\n\n");
        content.push_str("    deinit {\n");
        content.push_str("        stateObserver?.cancel()\n");
        content.push_str("    }\n");
        content.push_str("}\n");
        content.push_str("```\n\n");

        // Performance Issues
        content.push_str("## Performance Issues\n\n");
        content.push_str("### Slow State Updates\n\n");
        content.push_str("**Issue**: State changes taking too long\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("1. Avoid heavy processing in state update handlers\n");
        content.push_str("2. Use background queues for heavy work:\n");
        content.push_str("   ```swift\n");
        content.push_str("   Task.detached {\n");
        content.push_str("       // Heavy processing\n");
        content.push_str("       await MainActor.run {\n");
        content.push_str("           // UI updates\n");
        content.push_str("       }\n");
        content.push_str("   }\n");
        content.push_str("   ```\n\n");

        // Integration Issues
        content.push_str("## Integration Issues\n\n");
        content.push_str("### Framework Version Conflicts\n\n");
        content.push_str("**Issue**: Compatibility issues with Axiom framework versions\n\n");
        content.push_str("**Solution**:\n");
        content.push_str("1. Check the generated code comments for required framework version\n");
        content.push_str("2. Update your framework dependencies to match\n");
        content.push_str("3. Regenerate clients if framework patterns have changed\n\n");

        // Getting Help
        content.push_str("## Getting Help\n\n");
        content.push_str("If you encounter issues not covered here:\n\n");
        content.push_str("1. **Check Generated Code**: Review the generated files for any obvious issues\n");
        content.push_str("2. **Validate Generation**: Run the generator with `--validate` flag\n");
        content.push_str("3. **System Diagnostics**: Run `axiom-client-generator doctor`\n");
        content.push_str("4. **Enable Logging**: Use `--verbose` for detailed generation logs\n");
        content.push_str("5. **Regenerate**: Try regenerating the clients with latest generator version\n\n");

        content.push_str("### Debug Information\n\n");
        content.push_str("When reporting issues, include:\n");
        content.push_str("- Generator version\n");
        content.push_str("- Proto file content (if possible)\n");
        content.push_str("- Generation command used\n");
        content.push_str("- Error messages and stack traces\n");
        content.push_str("- Swift/Xcode version\n\n");

        FileManager::write_file(&file_path, &content, true).await?;
        Ok(file_path.to_string_lossy().to_string())
    }
}