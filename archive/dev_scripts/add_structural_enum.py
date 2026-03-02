# Create Structural State Enum and Logic
import sys
sys.path.insert(0, '.')

# Read current safety gate file
with open('aisri_safety_gate.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Add enum after imports
enum_code = '''
from enum import Enum

class StructuralState(Enum):
    \"\"\"
    Structural readiness state based on structural score.
    
    States:
    - RED: < 55 - Only mobility + activation + zone 1-2 allowed
    - YELLOW: 55-70 - No threshold or VO2 allowed
    - GREEN: > 70 - Full training access
    \"\"\"
    RED = 'red'
    YELLOW = 'yellow'
    GREEN = 'green'
    
    @staticmethod
    def from_score(structural_score: int) -> 'StructuralState':
        \"\"\"Determine state from structural score\"\"\"
        if structural_score < 55:
            return StructuralState.RED
        elif structural_score <= 70:
            return StructuralState.YELLOW
        else:
            return StructuralState.GREEN
'''

# Find where to insert (after imports, before class def)
import_end = content.find('class AISRISafetyGate:')
if import_end == -1:
    print('❌ Could not find class definition')
    sys.exit(1)

# Insert enum code
content = content[:import_end] + enum_code + '\n\n' + content[import_end:]

print('✅ Added StructuralState enum')

# Save
with open('aisri_safety_gate.py', 'w', encoding='utf-8') as f:
    f.write(content)

print('✅ Step 1 complete: Enum added')
