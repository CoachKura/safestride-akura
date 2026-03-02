# Update orchestrator to use template-based workflow
import sys
sys.path.insert(0, '.')

with open('orchestrator.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace _generate_workout_plan method
old_method_start = '    async def _generate_workout_plan('
old_method_end = '            return workout'

# New template-based implementation
new_method = '''    async def _generate_workout_plan(
        self,
        athlete_id: str,
        workout_type: str,
        intensity: str,
        duration_minutes: int,
        safety_data: Dict
    ) -> Dict:
        """
        Generate workout plan using template-based workflow.
        
        Workflow:
        1. Get structural state
        2. Load appropriate template
        3. Apply AI adjustments within constraints
        4. Return final structured workout
        """
        
        # Get structural state (already calculated earlier)
        structural_score = await self.safety_gate.get_structural_score(athlete_id)
        structural_state = await self.safety_gate.get_structural_state(athlete_id)
        
        # Load template for this state
        template = self.safety_gate.load_template_for_state(
            structural_state.value,
            workout_type
        )
        
        # Apply AI adjustments based on:
        # - Athlete profile
        # - Safety constraints
        # - Template constraints
        adjusted_workout = await self._apply_ai_adjustments(
            template=template,
            athlete_id=athlete_id,
            duration_minutes=duration_minutes,
            safety_data=safety_data,
            structural_state=structural_state.value
        )
        
        return adjusted_workout
    
    async def _apply_ai_adjustments(
        self,
        template: Dict,
        athlete_id: str,
        duration_minutes: int,
        safety_data: Dict,
        structural_state: str
    ) -> Dict:
        """
        Apply AI adjustments to template within constraints.
        
        Args:
            template: Base template from structural state
            athlete_id: Athlete ID
            duration_minutes: Requested duration
            safety_data: Safety gate results
            structural_state: red/yellow/green
        
        Returns:
            Adjusted workout dictionary
        """
        # Get AI constraints from template
        ai_constraints = template.get('ai_constraints', {})
        
        # Adjust duration if needed (respect min/max from template)
        actual_duration = min(
            duration_minutes,
            template.get('duration_minutes', duration_minutes)
        )
        
        # Build final workout structure
        workout = {
            'name': template['name'],
            'type': template['type'],
            'duration_minutes': actual_duration,
            'intensity': template['intensity'],
            'structural_state': structural_state,
            'zones_allowed': template.get('zones_allowed', [1, 2]),
            
            # Structure from template
            'warmup': template['structure']['warmup'],
            'main': template['structure']['main'],
            'cooldown': template['structure']['cooldown'],
            
            # AI constraints applied
            'constraints': {
                'max_heart_rate_percent': ai_constraints.get('max_heart_rate_percent', 75),
                'max_perceived_exertion': ai_constraints.get('max_perceived_exertion', 6),
                'speed_permission': structural_state == 'green',
                'focus': ai_constraints.get('focus', 'aerobic_base')
            },
            
            # Safety metadata
            'safety_notes': self._generate_safety_notes(safety_data),
            'aisri_score': safety_data.get('aisri_score', 0),
            'structural_score': await self.safety_gate.get_structural_score(athlete_id),
            
            # Metadata
            'created_at': datetime.now().isoformat(),
            'generated_by': 'orchestrator_v2_template_based'
        }
        
        # Add specific guidance based on structural state
        if structural_state == 'red':
            workout['athlete_guidance'] = (
                'Focus on structural strengthening. No speed work yet. '
                'Prioritize form, mobility, and aerobic base building.'
            )
        elif structural_state == 'yellow':
            workout['athlete_guidance'] = (
                'Building structural capacity. Moderate intensity OK. '
                'Avoid VO2max and race-pace work until structural score improves.'
            )
        else:
            workout['athlete_guidance'] = (
                'Structural readiness excellent. Full training access. '
                'Maintain structural work alongside performance training.'
            )
        
        return workout'''

# Replace the method
import re

# Find the start of the method
method_start_idx = content.find(old_method_start)
if method_start_idx == -1:
    print('Could not find method start')
    sys.exit(1)

# Find the end (next method or end of class)
# Look for next async def or def at same indentation level
search_from = method_start_idx + len(old_method_start)
next_method = re.search(r'\n    (async )?def ', content[search_from:])

if next_method:
    method_end_idx = search_from + next_method.start()
else:
    # End of class
    method_end_idx = len(content)

# Replace
content = content[:method_start_idx] + new_method + '\n\n' + content[method_end_idx:]

print(f'✅ Replaced _generate_workout_plan with template-based version')

# Remove old helper methods that are no longer needed
for old_helper in ['_generate_warmup', '_generate_main_set', '_generate_cooldown']:
    helper_pattern = f'    def {old_helper}\\('
    if helper_pattern in content:
        print(f'   Note: Old helper {old_helper}() still present (can be removed later)')

with open('orchestrator.py', 'w', encoding='utf-8') as f:
    f.write(content)

print('✅ Orchestrator updated with template-based workflow')
