# Add structural gating to orchestrator
import sys
sys.path.insert(0, '.')

with open('orchestrator.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the line with safety check
insert_idx = None
for i, line in enumerate(lines):
    if '# If not safe, return recommendation' in line:
        insert_idx = i
        break

if not insert_idx:
    print('Failed to find insertion point')
    sys.exit(1)

# Insert structural check before the safety result check
structural_check_code = """
        # Check structural clearance (NEW: Structural State Gating)
        structural_result = await self.safety_gate.check_structural_clearance(
            athlete_id=athlete_id,
            workout_type=workout_type,
            intensity=intensity
        )

        # If structural clearance fails, return recommendation
        if not structural_result['passed']:
            return {
                'status': 'blocked_by_structural_state',
                'reason': structural_result['reason'],
                'structural_state': structural_result['state'],
                'structural_score': structural_result['structural_score'],
                'speed_permission': structural_result['speed_permission'],
                'recommendation': 'Focus on mobility and foundational movements to improve structural readiness.'
            }

"""

lines.insert(insert_idx, structural_check_code)
print(f'Inserted structural check at line {insert_idx}')

# Update blocked return
search = "'injury_risk': safety_result['injury_risk']"
for i, line in enumerate(lines):
    if search in line:
        indent = len(line) - len(line.lstrip())
        lines[i] = line.rstrip() + ',\n' + ' ' * indent + "'speed_permission': structural_result.get('speed_permission', False)\n"
        print(f'Added speed_permission to blocked at line {i}')
        break

# Update success return
search2 = "'safety_check': safety_result"
for i, line in enumerate(lines):
    if search2 in line and i > insert_idx:
        indent = len(line) - len(line.lstrip())
        lines[i] = line.rstrip() + ',\n' + ' ' * indent + "'structural_state': structural_result['state'],\n" + ' ' * indent + "'structural_score': structural_result['structural_score'],\n" + ' ' * indent + "'speed_permission': structural_result['speed_permission']\n"
        print(f'Added structural info to success at line {i}')
        break

with open('orchestrator.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Step 3 complete: Orchestrator updated')
