#!/usr/bin/env python3
"""
Script to add all missing Swift files to the Xcode project automatically.
This updates the project.pbxproj file to include all Swift files in the ExampleApp directory.
"""

import os
import uuid
import re
from pathlib import Path

def generate_uuid():
    """Generate a unique identifier for Xcode project entries"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def find_swift_files(base_path):
    """Find all Swift files in the ExampleApp directory"""
    swift_files = []
    for root, dirs, files in os.walk(base_path):
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, base_path)
                swift_files.append({
                    'name': file,
                    'path': rel_path,
                    'full_path': full_path,
                    'directory': os.path.dirname(rel_path) if os.path.dirname(rel_path) else '.'
                })
    return swift_files

def update_project_file():
    """Update the project.pbxproj file to include all Swift files"""
    project_path = '/Users/tojkuv/Documents/GitHub/Axiom/AxiomTestApp/ExampleApp.xcodeproj/project.pbxproj'
    base_path = '/Users/tojkuv/Documents/GitHub/Axiom/AxiomTestApp/ExampleApp'
    
    # Find all Swift files
    swift_files = find_swift_files(base_path)
    print(f"Found {len(swift_files)} Swift files")
    
    # Read the current project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Extract existing file references to avoid duplicates
    existing_files = set()
    for match in re.finditer(r'/\* (.+\.swift) \*/', content):
        existing_files.add(match.group(1))
    
    # Generate new entries for missing files
    new_build_files = []
    new_file_refs = []
    new_sources = []
    
    for file_info in swift_files:
        if file_info['name'] not in existing_files:
            file_uuid = generate_uuid()
            build_uuid = generate_uuid()
            
            # Create file reference
            new_file_refs.append(f'\t\t{file_uuid} /* {file_info["name"]} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_info["name"]}"; sourceTree = "<group>"; }};')
            
            # Create build file
            new_build_files.append(f'\t\t{build_uuid} /* {file_info["name"]} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_info["name"]} */; }};')
            
            # Add to sources
            new_sources.append(f'\t\t\t\t{build_uuid} /* {file_info["name"]} in Sources */,')
    
    if not new_build_files:
        print("No new files to add")
        return
    
    # Insert new build files
    build_section_end = content.find('/* End PBXBuildFile section */')
    if build_section_end != -1:
        content = content[:build_section_end] + '\n'.join(new_build_files) + '\n' + content[build_section_end:]
    
    # Insert new file references
    file_ref_end = content.find('/* End PBXFileReference section */')
    if file_ref_end != -1:
        content = content[:file_ref_end] + '\n'.join(new_file_refs) + '\n' + content[file_ref_end:]
    
    # Insert new sources
    sources_pattern = r'(1A12344E1234567890ABCDEF /\* Sources \*/ = \{[^}]+files = \([^)]+)'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    if sources_match:
        sources_content = sources_match.group(1)
        new_sources_content = sources_content + '\n' + '\n'.join(new_sources)
        content = content.replace(sources_content, new_sources_content)
    
    # Write back the updated project file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"Added {len(new_build_files)} files to Xcode project")

if __name__ == "__main__":
    update_project_file()