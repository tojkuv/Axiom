#!/bin/bash

# Axiom Framework - Xcode Project Setup Script
# This script opens the Package.swift in Xcode for the best development experience

echo "🚀 Setting up Axiom Framework in Xcode..."
echo ""
echo "The Axiom framework uses Swift Package Manager."
echo "Opening Package.swift in Xcode for the best experience..."
echo ""

# Check if Xcode is installed
if ! command -v xed &> /dev/null; then
    echo "❌ Xcode command line tools not found"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

# Open the workspace in Xcode
echo "📦 Opening Axiom.xcworkspace in Xcode..."
open Axiom.xcworkspace

echo ""
echo "✅ Xcode should now be opening with the complete Axiom workspace"
echo ""
echo "Quick tips:"
echo "  • Select 'Axiom-Framework' scheme and press Cmd+B to build"
echo "  • Select 'All-Tests' scheme and press Cmd+U to run all tests"
echo "  • Select 'AxiomFoundationExample' scheme and press Cmd+R to run the example"
echo ""
echo "Available schemes:"
echo "  • Axiom-Framework - Build and test the framework"
echo "  • AxiomFoundationExample - Run the complete example app"
echo "  • All-Tests - Run all test suites at once"
echo "  • ExampleApp - Simple iOS app template"
echo ""
echo "For more details, see README.md and STATUS.md"