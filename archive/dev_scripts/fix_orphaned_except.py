# Remove the orphaned except block
import sys
sys.path.insert(0, '.')

with open('aisri_safety_gate.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and remove the orphaned except block around line 575
to_remove = []
for i, line in enumerate(lines):
    # Find line 574-583 range with the orphaned except
    if i >= 573 and i < 590:
        if 'except Exception as e:' in line:
            # Check if there's a return statement soon after and remove the whole block
            for j in range(i, min(i+15, len(lines))):
                if "'updated_at': datetime.now().isoformat()" in lines[j] and j > i:
                    # Mark for removal from i to j+2 (including closing brace)
                    to_remove = list(range(i, j+2))
                    break
            if to_remove:
                break

if to_remove:
    # Remove in reverse order
    for i in reversed(to_remove):
        del lines[i]
    print(f'Removed orphaned except block: lines {to_remove[0]} to {to_remove[-1]}')
else:
    print('Could not find orphaned except block')

with open('aisri_safety_gate.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Fixed orphaned except block')
