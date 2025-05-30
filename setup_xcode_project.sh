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

# Open the package in Xcode
echo "📦 Opening Package.swift in Xcode..."
xed .

echo ""
echo "✅ Xcode should now be opening with the Axiom package"
echo ""
echo "Quick tips:"
echo "  • Press Cmd+B to build the framework"
echo "  • Press Cmd+U to run all tests"
echo "  • Select 'AxiomFoundationExample' scheme to run the example app"
echo ""
echo "For more details, see CREATE_XCODE_PROJECT.md"