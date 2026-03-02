# Add template loader import and method to aisri_safety_gate.py
import sys
sys.path.insert(0, '.')

with open('aisri_safety_gate.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import at top after other imports
import_line = 'from database_integration import DatabaseIntegration'
new_import = 'from database_integration import DatabaseIntegration\nfrom workout_templates import get_template_for_state, STRUCTURAL_WORKOUT_TEMPLATES'

if import_line in content:
    content = content.replace(import_line, new_import)
    print('✅ Added workout_templates import')
else:
    print('⚠️  Could not find import line')
    sys.exit(1)

# Add method after check_structural_clearance
method_code = '''
    def load_template_for_state(
        self,
        structural_state: str,
        workout_type: str
    ) -> Dict:
        """
        Load appropriate workout template based on structural state.
        
        Args:
            structural_state: 'red', 'yellow', 'green'
            workout_type: Desired workout type
        
        Returns:
            Template dictionary with structure and AI constraints
        """
        from workout_templates import get_template_for_state
        
        template = get_template_for_state(structural_state, workout_type)
        
        if not template:
            # Fallback to safest option
            if structural_state == 'red':
                template = STRUCTURAL_WORKOUT_TEMPLATES['red']['easy']
            elif structural_state == 'yellow':
                template = STRUCTURAL_WORKOUT_TEMPLATES['yellow']['easy']
            else:
                template = STRUCTURAL_WORKOUT_TEMPLATES['green']['threshold']
        
        return template
'''

# Find insertion point after check_structural_clearance
insertion_marker = "        return {\n            'passed': True,\n            'state': state.value,\n            'structural_score': structural_score,\n            'speed_permission': speed_permission\n        }"

if insertion_marker in content:
    # Insert after this return statement
    parts = content.split(insertion_marker)
    content = parts[0] + insertion_marker + '\n' + method_code + parts[1]
    print('✅ Added load_template_for_state() method')
else:
    print('⚠️  Could not find insertion point')

with open('aisri_safety_gate.py', 'w', encoding='utf-8') as f:
    f.write(content)

print('✅ Template loader integrated into safety gate')
