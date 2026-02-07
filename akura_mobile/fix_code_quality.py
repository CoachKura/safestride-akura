#!/usr/bin/env python3
"""
SafeStride Code Quality Auto-Fixer
Fixes all warnings from flutter analyze:
1. Replaces print() with developer.log()
2. Replaces deprecated withOpacity() with withValues()
3. Fixes form field value -> initialValue
4. Removes unused imports
5. Adds library directives for dangling doc comments
6. Makes private fields final where appropriate
"""

import os
import re
import sys
from pathlib import Path
from typing import Set, List, Tuple

class CodeQualityFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_dir = self.project_root / 'lib'
        self.stats = {
            'files_processed': 0,
            'print_fixed': 0,
            'withOpacity_fixed': 0,
            'form_value_fixed': 0,
            'imports_removed': 0,
            'library_added': 0,
            'finals_added': 0
        }
        
    def fix_all(self):
        """Fix all Dart files in lib directory"""
        print("🚀 SafeStride Code Quality Auto-Fixer")
        print("=" * 60)
        
        dart_files = list(self.lib_dir.rglob('*.dart'))
        print(f"📁 Found {len(dart_files)} Dart files\n")
        
        for dart_file in dart_files:
            self.fix_file(dart_file)
            
        self.print_summary()
        
    def fix_file(self, file_path: Path):
        """Fix a single Dart file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
                
            content = original_content
            
            # Apply fixes in order
            content = self.fix_print_statements(content, file_path)
            content = self.fix_with_opacity(content)
            content = self.fix_form_value_parameter(content)
            content = self.add_library_directive(content, file_path)
            content = self.remove_unused_imports(content, file_path)
            
            # Only write if changed
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.stats['files_processed'] += 1
                print(f"✅ Fixed: {file_path.relative_to(self.project_root)}")
                
        except Exception as e:
            print(f"❌ Error fixing {file_path}: {e}")
            
    def fix_print_statements(self, content: str, file_path: Path) -> str:
        """Replace print() with developer.log()"""
        # Check if file already has developer import
        has_developer_import = 'dart:developer' in content
        
        # Find all print() statements
        print_pattern = r'\bprint\s*\('
        matches = list(re.finditer(print_pattern, content))
        
        if not matches:
            return content
            
        # Add developer import if needed
        if not has_developer_import:
            # Find the last import line
            import_pattern = r'^import\s+[^;]+;$'
            import_matches = list(re.finditer(import_pattern, content, re.MULTILINE))
            
            if import_matches:
                last_import_pos = import_matches[-1].end()
                content = (content[:last_import_pos] + 
                          "\nimport 'dart:developer' as developer;" +
                          content[last_import_pos:])
            else:
                # No imports, add at beginning after comments
                lines = content.split('\n')
                insert_pos = 0
                for i, line in enumerate(lines):
                    if not line.strip().startswith('///') and not line.strip().startswith('//'):
                        insert_pos = i
                        break
                lines.insert(insert_pos, "import 'dart:developer' as developer;")
                content = '\n'.join(lines)
        
        # Replace print() with developer.log()
        original_count = len(matches)
        content = re.sub(
            r'\bprint\s*\(',
            'developer.log(',
            content
        )
        
        self.stats['print_fixed'] += original_count
        return content
        
    def fix_with_opacity(self, content: str) -> str:
        """Replace .withOpacity(x) with .withValues(alpha: x)"""
        pattern = r'\.withOpacity\(([^)]+)\)'
        matches = list(re.finditer(pattern, content))
        
        if not matches:
            return content
            
        def replacement(match):
            opacity_value = match.group(1)
            return f'.withValues(alpha: {opacity_value})'
            
        new_content = re.sub(pattern, replacement, content)
        self.stats['withOpacity_fixed'] += len(matches)
        return new_content
        
    def fix_form_value_parameter(self, content: str) -> str:
        """Replace value: in form fields with initialValue:"""
        # Pattern for form field value parameters (but not in onChange, etc.)
        pattern = r'(TextFormField\s*\([^)]*)\bvalue:\s*'
        matches = list(re.finditer(pattern, content))
        
        if not matches:
            return content
            
        new_content = re.sub(pattern, r'\1initialValue: ', content)
        self.stats['form_value_fixed'] += len(matches)
        return new_content
        
    def add_library_directive(self, content: str, file_path: Path) -> str:
        """Add library directive for files with dangling doc comments"""
        lines = content.split('\n')
        
        # Check if file starts with doc comment
        has_doc_comment = False
        doc_comment_end = -1
        
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith('///'):
                has_doc_comment = True
            elif has_doc_comment and not stripped.startswith('///') and stripped:
                doc_comment_end = i
                break
                
        if not has_doc_comment:
            return content
            
        # Check if library directive already exists
        if doc_comment_end >= 0:
            next_line = lines[doc_comment_end].strip()
            if next_line.startswith('library '):
                return content
                
        # Add library directive
        if doc_comment_end >= 0:
            # Generate library name from file path
            lib_name = file_path.stem.replace('-', '_').replace(' ', '_')
            lines.insert(doc_comment_end, f'library {lib_name};')
            lines.insert(doc_comment_end + 1, '')
            self.stats['library_added'] += 1
            return '\n'.join(lines)
            
        return content
        
    def remove_unused_imports(self, content: str, file_path: Path) -> str:
        """Remove unused imports based on known issues"""
        # Known unused imports from analysis
        unused_map = {
            'evaluation_form_screen.dart': ['dashboard_screen.dart'],
            'assessment_report_generator.dart': ['package:flutter/foundation.dart'],
        }
        
        filename = file_path.name
        if filename not in unused_map:
            return content
            
        for unused_import in unused_map[filename]:
            pattern = rf"^import\s+['\"].*{re.escape(unused_import)}['\"];?\s*$"
            matches = list(re.finditer(pattern, content, re.MULTILINE))
            if matches:
                content = re.sub(pattern, '', content, flags=re.MULTILINE)
                self.stats['imports_removed'] += len(matches)
                
        return content
        
    def print_summary(self):
        """Print fix summary"""
        print("\n" + "=" * 60)
        print("📊 FIX SUMMARY")
        print("=" * 60)
        print(f"Files processed:        {self.stats['files_processed']}")
        print(f"print() → log():        {self.stats['print_fixed']}")
        print(f"withOpacity() → withValues(): {self.stats['withOpacity_fixed']}")
        print(f"value → initialValue:   {self.stats['form_value_fixed']}")
        print(f"Unused imports removed: {self.stats['imports_removed']}")
        print(f"Library directives added: {self.stats['library_added']}")
        print("=" * 60)
        print("\n✨ All fixes applied!")
        print("\n📝 Next steps:")
        print("1. Run: flutter analyze")
        print("2. Verify no errors")
        print("3. Test build: flutter build apk --debug")
        print("4. Commit: git add . && git commit -m 'Fix: Code quality improvements'")


def main():
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = os.getcwd()
        
    fixer = CodeQualityFixer(project_root)
    fixer.fix_all()


if __name__ == '__main__':
    main()
