import SwiftUI
import Axiom

// MARK: - Interactive Validation Views

/// INTERACTIVE validation implementations demonstrating real framework functionality
/// Each view provides live user interaction with actual framework capabilities

// AI Intelligence and Self-Optimizing Performance views are defined in InteractiveValidationViews.swift
// All other interactive validation views are defined in AdditionalInteractiveViews.swift

// Note: The interactive implementations from AdditionalInteractiveViews.swift are automatically available
// since they're part of the same target. ContentView.swift references these by name directly.

// MARK: - Enterprise Supporting Views

struct EnterpriseLoadingView: View {
    let progress: Double
    let currentStep: String
    let status: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(progress * 360))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: progress)
            
            Text("Enterprise Framework")
                .font(.title)
                .fontWeight(.bold)
            
            Text(status)
                .font(.headline)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(width: 200)
            
            Text(String(format: "%.0f%%", progress * 100))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(currentStep)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EnterpriseErrorView: View {
    let error: any AxiomError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text("Initialization Failed")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error.userMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry Initialization") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}