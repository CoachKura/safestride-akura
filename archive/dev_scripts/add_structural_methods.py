# Add structural state methods after get_safety_summary
import sys
sys.path.insert(0, '.')

with open('aisri_safety_gate.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the get_safety_summary method and add after it
insert_line = None
for i, line in enumerate(lines):
    if 'async def get_safety_summary' in line:
        # Find the end of this method (next method or end of file)
        for j in range(i+1, len(lines)):
            # Look for next method or end of class
            if j == len(lines) - 1 or (lines[j].strip() and not lines[j].startswith('    ') and not lines[j].startswith('#')):
                insert_line = j
                break
            # Or detect return statement that ends the method
            if lines[j].strip().startswith('return {') or lines[j].strip().startswith('return result'):
                # Find the closing brace/end of return
                for k in range(j, min(j+20, len(lines))):
                    if '}' in lines[k]:
                        insert_line = k + 1
                        break
                if insert_line:
                    break

if not insert_line:
    print('❌ Could not find insertion point')
    sys.exit(1)

print(f'Found insertion point at line {insert_line}')

methods_code = '''
    async def get_structural_score(self, athlete_id: str) -> int:
        \"\"\"
        Get structural score for athlete.
        
        For now, uses combination of strength + mobility from latest AISRI assessment.
        Future: Can be enhanced with specific structural tests.
        
        Returns:
            Structural score (0-100)
        \"\"\"
        try:
            # Fetch latest AISRI assessment with pillar breakdowns
            result = self.db.supabase.table(\"aisri_scores\").select(\"*\").eq(
                \"athlete_id\", athlete_id
            ).order(\"assessment_date\", desc=True).limit(1).execute()
            
            if not result.data:
                return 50  # Default neutral score
            
            latest = result.data[0]
            
            # Calculate structural score as average of strength + mobility
            # (these are the core structural components)
            strength = latest.get('strength_score', 50)
            mobility = latest.get('mobility_score', 50)
            
            # Could also factor in ROM if available
            rom = latest.get('rom_score', None)
            
            if rom is not None:
                structural_score = int((strength + mobility + rom) / 3)
            else:
                structural_score = int((strength + mobility) / 2)
            
            return structural_score
            
        except Exception as e:
            print(f\"Warning: Could not fetch structural score: {e}\")
            return 50  # Default on error
    
    async def get_structural_state(self, athlete_id: str) -> StructuralState:
        \"\"\"
        Determine structural state for athlete.
        
        Returns:
            StructuralState enum (RED/YELLOW/GREEN)
        \"\"\"
        structural_score = await self.get_structural_score(athlete_id)
        return StructuralState.from_score(structural_score)
    
    async def check_structural_clearance(
        self, 
        athlete_id: str, 
        workout_type: str,
        intensity: str
    ) -> Dict:
        \"\"\"
        Check if workout is structurally appropriate.
        
        Args:
            athlete_id: Athlete ID
            workout_type: 'easy', 'threshold', 'interval', 'vo2max', 'race'
            intensity: 'low', 'moderate', 'high', 'very_high'
        
        Returns:
            {
                'passed': bool,
                'state': str,  # 'red', 'yellow', 'green'
                'structural_score': int,
                'speed_permission': bool,
                'reason': str (if blocked)
            }
        \"\"\"
        structural_score = await self.get_structural_score(athlete_id)
        state = StructuralState.from_score(structural_score)
        
        # RED: Only mobility + activation + zone 1-2
        if state == StructuralState.RED:
            allowed_types = ['mobility', 'activation', 'easy', 'recovery']
            speed_permission = False
            
            if workout_type.lower() not in allowed_types:
                return {
                    'passed': False,
                    'state': 'red',
                    'structural_score': structural_score,
                    'speed_permission': False,
                    'reason': f'Structural state RED (score: {structural_score}). Only mobility, activation, and easy runs (zone 1-2) allowed.'
                }
            
            # If allowed type, still check intensity
            if intensity in ['high', 'very_high']:
                return {
                    'passed': False,
                    'state': 'red',
                    'structural_score': structural_score,
                    'speed_permission': False,
                    'reason': f'Structural state RED (score: {structural_score}). High intensity not allowed.'
                }
        
        # YELLOW: No threshold or VO2
        elif state == StructuralState.YELLOW:
            blocked_types = ['threshold', 'vo2max', 'interval', 'race']
            speed_permission = False
            
            if workout_type.lower() in blocked_types:
                return {
                    'passed': False,
                    'state': 'yellow',
                    'structural_score': structural_score,
                    'speed_permission': False,
                    'reason': f'Structural state YELLOW (score: {structural_score}). Threshold and VO2max workouts not allowed.'
                }
        
        # GREEN: Full access
        else:
            speed_permission = True
        
        return {
            'passed': True,
            'state': state.value,
            'structural_score': structural_score,
            'speed_permission': speed_permission
        }
'''

# Insert at the found position
lines.insert(insert_line, methods_code + '\n')

with open('aisri_safety_gate.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('✅ Step 2 complete: Structural state methods added')
print('   - get_structural_score()')
print('   - get_structural_state()')
print('   - check_structural_clearance()')
