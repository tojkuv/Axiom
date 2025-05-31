#!/usr/bin/env python3
"""
Fix file paths in the Xcode project to use correct relative paths
"""

import re

def fix_project_file():
    """Fix the project.pbxproj file to use correct relative paths"""
    project_path = '/Users/tojkuv/Documents/GitHub/Axiom/AxiomTestApp/ExampleApp.xcodeproj/project.pbxproj'
    
    # Read the current project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Define path mappings for files that need proper relative paths
    path_fixes = {
        'Phase2APIValidationTests.swift': 'Phase2APIValidationTests.swift',
        'ContentView_Backup.swift': 'ContentView_Backup.swift', 
        'SophisticatedValidationPlaceholderView.swift': 'SophisticatedValidationPlaceholderView.swift',
        'ContentView_Old.swift': 'ContentView_Old.swift',
        'Phase2APITestView.swift': 'Phase2APITestView.swift',
        'UserClient.swift': 'Domains/User/UserClient.swift',
        'UserView.swift': 'Domains/User/UserView.swift',
        'UserContext.swift': 'Domains/User/UserContext.swift',
        'UserState.swift': 'Domains/User/UserState.swift',
        'DataClient.swift': 'Domains/Data/DataClient.swift',
        'DataState.swift': 'Domains/Data/DataState.swift',
        'DataContext.swift': 'Domains/Data/DataContext.swift',
        'IntegrationSupportingViews.swift': 'Integration/IntegrationSupportingViews.swift',
        'CrossDomainOrchestration.swift': 'Integration/CrossDomainOrchestration.swift',
        'AIIntelligenceValidationView.swift': 'Integration/AIIntelligenceValidationView.swift',
        'AdvancedStressTestingSupport.swift': 'Integration/AdvancedStressTestingSupport.swift',
        'AdvancedStressTestingView.swift': 'Integration/AdvancedStressTestingView.swift',
        'FrameworkReportView.swift': 'Integration/FrameworkReportView.swift',
        'EnterpriseTestExtensions.swift': 'Integration/EnterpriseTestExtensions.swift',
        'PerformanceTestExtensions.swift': 'Integration/PerformanceTestExtensions.swift',
        'AdvancedStressTestingViews.swift': 'Integration/AdvancedStressTestingViews.swift',
        'ComprehensiveValidationSupport.swift': 'Integration/ComprehensiveValidationSupport.swift',
        'OptimizationMonitor.swift': 'Integration/OptimizationMonitor.swift',
        'PerformanceMetricsDetailView.swift': 'Integration/PerformanceMetricsDetailView.swift',
        'AIIntelligenceMonitor.swift': 'Integration/AIIntelligenceMonitor.swift',
        'IntegrationDemoView.swift': 'Integration/IntegrationDemoView.swift',
        'EnterpriseGradeValidationView.swift': 'Integration/EnterpriseGradeValidationView.swift',
        'EnterpriseMonitoring.swift': 'Integration/EnterpriseMonitoring.swift',
        'ComprehensiveArchitecturalValidationView.swift': 'Integration/ComprehensiveArchitecturalValidationView.swift',
        'SelfOptimizingPerformanceView.swift': 'Integration/SelfOptimizingPerformanceView.swift',
        'MultiDomainApplicationCoordinator.swift': 'Utils/MultiDomainApplicationCoordinator.swift',
        'MacroValidationContext.swift': 'Examples/Phase2APIValidation/MacroValidationContext.swift',
        'MacroValidationView.swift': 'Examples/Phase2APIValidation/MacroValidationView.swift',
        'Phase2ValidationView.swift': 'Examples/Phase2APIValidation/Phase2ValidationView.swift'
    }
    
    # Fix file references - add path information
    for filename, relative_path in path_fixes.items():
        # Fix the file reference entries - add path information
        pattern = rf'(\w+) /\* {re.escape(filename)} \*/ = \{{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = "{re.escape(filename)}"; sourceTree = "<group>"; \}};'
        replacement = rf'\1 /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{relative_path}"; sourceTree = "<group>"; }};'
        content = re.sub(pattern, replacement, content)
    
    # Write back the updated project file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed file paths in Xcode project")

if __name__ == "__main__":
    fix_project_file()