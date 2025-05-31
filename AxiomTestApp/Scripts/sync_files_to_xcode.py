#!/usr/bin/env python3
"""
Comprehensive script to sync all Swift files with Xcode project.
This script ensures Xcode sees and includes all Swift files in the project.
"""

import os
import uuid
import re
from pathlib import Path

def generate_uuid():
    """Generate a unique identifier for Xcode project entries"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def find_all_swift_files(base_path):
    """Find all Swift files recursively in the ExampleApp directory"""
    swift_files = []
    excluded_dirs = {'.build', 'DerivedData', '.git', 'xcuserdata'}
    
    for root, dirs, files in os.walk(base_path):
        # Skip excluded directories
        dirs[:] = [d for d in dirs if d not in excluded_dirs]
        
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, base_path)
                
                # Get the directory structure for proper grouping
                dir_parts = os.path.dirname(rel_path).split(os.sep) if os.path.dirname(rel_path) else []
                
                swift_files.append({
                    'name': file,
                    'path': rel_path,
                    'full_path': full_path,
                    'directory_parts': dir_parts,
                    'parent_dir': os.path.basename(os.path.dirname(full_path)) if os.path.dirname(rel_path) else 'ExampleApp'
                })
    
    return swift_files

def extract_existing_files(content):
    """Extract existing file references from project.pbxproj"""
    existing_files = {}
    
    # Extract existing file references
    file_ref_pattern = r'(\w+) /\* (.+\.swift) \*/ = \{isa = PBXFileReference;[^}]+\};'
    for match in re.finditer(file_ref_pattern, content):
        uuid_val, filename = match.groups()
        existing_files[filename] = uuid_val
    
    return existing_files

def update_project_file():
    """Update the project.pbxproj file to include all Swift files"""
    project_path = '/Users/tojkuv/Documents/GitHub/Axiom/AxiomTestApp/ExampleApp.xcodeproj/project.pbxproj'
    base_path = '/Users/tojkuv/Documents/GitHub/Axiom/AxiomTestApp/ExampleApp'
    
    print("🔍 Scanning for Swift files...")
    swift_files = find_all_swift_files(base_path)
    print(f"Found {len(swift_files)} Swift files")
    
    # Read the current project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    existing_files = extract_existing_files(content)
    print(f"Project already includes {len(existing_files)} Swift files")
    
    # Find missing files
    missing_files = []
    for file_info in swift_files:
        if file_info['name'] not in existing_files:
            missing_files.append(file_info)
    
    if not missing_files:
        print("✅ All Swift files are already included in the project")
        return
    
    print(f"📝 Adding {len(missing_files)} missing files to project:")
    for file_info in missing_files:
        print(f"  + {file_info['path']}")
    
    # Generate new entries for missing files
    new_build_files = []
    new_file_refs = []
    new_sources = []
    file_uuid_map = {}
    
    for file_info in missing_files:
        file_uuid = generate_uuid()
        build_uuid = generate_uuid()
        file_uuid_map[file_info['name']] = file_uuid
        
        # Create file reference
        new_file_refs.append(
            f'\t\t{file_uuid} /* {file_info["name"]} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
            f'path = "{file_info["name"]}"; sourceTree = "<group>"; }};'
        )
        
        # Create build file
        new_build_files.append(
            f'\t\t{build_uuid} /* {file_info["name"]} in Sources */ = '
            f'{{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_info["name"]} */; }};'
        )
        
        # Add to sources
        new_sources.append(f'\t\t\t\t{build_uuid} /* {file_info["name"]} in Sources */,')
    
    # Insert new build files after existing ones
    build_section_pattern = r'(/\* End PBXBuildFile section \*/)'
    if re.search(build_section_pattern, content):
        content = re.sub(
            build_section_pattern,
            '\n'.join(new_build_files) + '\n\\1',
            content
        )
    
    # Insert new file references after existing ones
    file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
    if re.search(file_ref_pattern, content):
        content = re.sub(
            file_ref_pattern,
            '\n'.join(new_file_refs) + '\n\\1',
            content
        )
    
    # Insert new sources in the Sources build phase
    sources_pattern = r'(1A12344E1234567890ABCDEF /\* Sources \*/ = \{[^}]+files = \([^)]+)(\);)'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    if sources_match:
        before_closing = sources_match.group(1)
        closing = sources_match.group(2)
        new_sources_content = before_closing + '\n' + '\n'.join(new_sources) + '\n\t\t\t' + closing
        content = content.replace(sources_match.group(0), new_sources_content)
    
    # Create group structure for better organization
    # This would require more complex parsing, but for now we'll add files to existing groups
    
    # Write back the updated project file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Successfully added {len(missing_files)} files to Xcode project")
    print("🔄 Xcode should now detect all Swift files automatically")

def main():
    """Main function to sync files"""
    print("🚀 Syncing Swift files with Xcode project...")
    try:
        update_project_file()
        print("\n✅ File sync completed successfully!")
        print("\n💡 Tips:")
        print("   - Open Xcode and check that all files appear in the navigator")
        print("   - If files still don't appear, try: Product → Clean Build Folder")
        print("   - For future files, add them through Xcode to avoid this issue")
    except Exception as e:
        print(f"❌ Error during file sync: {e}")
        print("Please check the file paths and try again")

if __name__ == "__main__":
    main()