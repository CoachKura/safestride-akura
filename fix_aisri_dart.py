import os
import re

def fix_aisri_in_dart_files():
    root_dir = r"C:\safestride\lib"
    count = 0
    
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.dart'):
                filepath = os.path.join(dirpath, filename)
                
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    if 'AIFRI' in content or 'aifri' in content or 'Aifri' in content:
                        # Replace all variations
                        new_content = content.replace('AIFRI', 'AISRI')
                        new_content = new_content.replace('aifri', 'aisri')
                        new_content = new_content.replace('Aifri', 'Aisri')
                        
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        
                        count += 1
                        print(f"[OK] {filename}")
                except Exception as e:
                    print(f"[ERROR] {filename}: {e}")
    
    print(f"\n✓ Fixed {count} Dart files")

if __name__ == "__main__":
    fix_aisri_in_dart_files()
