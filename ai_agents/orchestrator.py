"""
AISRi System Orchestrator
Centralized coordination of all AISRi services and workflows.

Components:
- Strava OAuth & Token Management
- AISRi Score Calculation
- Safety Gate Enforcement
- Workout Generation
- Injury Prediction
- Performance Tracking

Usage:
    orchestrator = AISRiOrchestrator()
    
    # Connect athlete to Strava
    auth_url = orchestrator.initiate_strava_connection(athlete_id)
    
    # Generate safe workout
    workout = await orchestrator.generate_safe_workout(athlete_id, 'interval', 60)
"""

from typing import Dict, Optional, List
from datetime import datetime

from database_integration import DatabaseIntegration
from strava_oauth_service import StravaOAuthService
from aisri_safety_gate import AISRISafetyGate
from aisri_auto_calculator import AISRIAutoCalculator


class AISRiOrchestrator:
    """Centralized orchestration of AISRi system services"""
    
    def __init__(self):
        """Initialize orchestrator with all service dependencies"""
        
        # Initialize database
        self.db = DatabaseIntegration()
        
        # Initialize services
        self.strava_oauth = StravaOAuthService(self.db)
        self.safety_gate = AISRISafetyGate(self.db)
        self.aisri_calculator = AISRIAutoCalculator(self.db)
        
        print("✅ AISRi Orchestrator initialized")
    
    # =====================================================
    # STRAVA INTEGRATION WORKFLOWS
    # =====================================================
    
    def initiate_strava_connection(self, athlete_id: str) -> str:
        """
        Start Strava OAuth flow for athlete.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            Strava authorization URL
        """
        return self.strava_oauth.get_authorization_url(athlete_id)
    
    async def complete_strava_connection(
        self,
        code: str,
        state: str,
        scope: Optional[str] = None
    ) -> Dict:
        """
        Complete Strava OAuth flow.
        
        Args:
            code: Authorization code from Strava
            state: Athlete ID
            scope: Granted scopes
        
        Returns:
            Connection result with athlete info
        """
        return await self.strava_oauth.handle_callback(code, state, scope)
    
    async def disconnect_strava(self, athlete_id: str) -> Dict:
        """Disconnect Strava from athlete account"""
        return await self.strava_oauth.disconnect(athlete_id)
    
    async def get_strava_status(self, athlete_id: str) -> Dict:
        """Get Strava connection status"""
        return await self.strava_oauth.get_connection_status(athlete_id)
    
    async def get_valid_strava_token(self, athlete_id: str) -> str:
        """
        Get valid Strava token (auto-refresh if needed).
        
        This is the primary method for getting tokens for API calls.
        """
        return await self.strava_oauth.get_valid_token(athlete_id)
    
    # =====================================================
    # AISRI SCORE WORKFLOWS
    # =====================================================
    
    async def calculate_aisri_from_strava(self, athlete_id: str) -> Dict:
        """
        Calculate AISRi score from Strava activities.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            AISRi score result with all pillars
        """
        
        # Get valid token (auto-refresh)
        try:
            token = await self.get_valid_strava_token(athlete_id)
        except Exception as e:
            return {
                'status': 'error',
                'message': f'Strava not connected: {str(e)}'
            }
        
        # Calculate AISRi
        result = await self.aisri_calculator.calculate_from_strava(
            athlete_id=athlete_id,
            access_token=token,
            days_back=28  # Last 4 weeks
        )
        
        return result
    
    async def get_latest_aisri(self, athlete_id: str) -> Dict:
        """Get latest AISRi score from database"""
        
        try:
            result = self.db.supabase.table("aisri_scores").select("*").eq(
                "athlete_id", athlete_id
            ).order("created_at", desc=True).limit(1).execute()
            
            if not result.data or len(result.data) == 0:
                return {'status': 'not_found', 'message': 'No AISRi assessment yet'}
            
            return {
                'status': 'success',
                'data': result.data[0]
            }
        
        except Exception as e:
            return {'status': 'error', 'message': str(e)}
    
    # =====================================================
    # SAFETY GATE WORKFLOWS
    # =====================================================
    
    async def check_workout_safety(
        self,
        athlete_id: str,
        workout_type: str,
        intensity: str,
        duration_minutes: Optional[int] = None
    ) -> Dict:
        """
        Check if workout passes all safety gates.
        
        Args:
            athlete_id: SafeStride athlete ID
            workout_type: Workout type (run, interval, long_run)
            intensity: Intensity level (easy, moderate, hard, interval)
            duration_minutes: Planned duration
        
        Returns:
            Safety check result with gates status
        """
        
        return await self.safety_gate.check_workout_safety(
            athlete_id=athlete_id,
            workout_type=workout_type,
            intensity=intensity,
            duration_minutes=duration_minutes
        )
    
    async def get_safety_status(self, athlete_id: str) -> Dict:
        """Get overall safety status for athlete"""
        return await self.safety_gate.get_safety_summary(athlete_id)
    
    # =====================================================
    # WORKOUT GENERATION WORKFLOWS
    # =====================================================
    
    async def generate_safe_workout(
        self,
        athlete_id: str,
        workout_type: str,
        duration_minutes: int,
        intensity: Optional[str] = None
    ) -> Dict:
        """
        Generate workout with safety gate enforcement.
        
        This is the primary workout generation method that ensures safety.
        
        Args:
            athlete_id: SafeStride athlete ID
            workout_type: Desired workout type
            duration_minutes: Planned duration
            intensity: Desired intensity (if None, auto-determined)
        
        Returns:
            Workout plan or safety override recommendation
        """
        
        # Auto-determine intensity if not provided
        if not intensity:
            intensity = self._determine_safe_intensity(workout_type)
        
        # Check safety gates
        safety_result = await self.check_workout_safety(
            athlete_id=athlete_id,
            workout_type=workout_type,
            intensity=intensity,
            duration_minutes=duration_minutes
        )
        

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

        # If not safe, return recommendation
        if not safety_result['safe']:
            return {
                'status': 'blocked_by_safety_gate',
                'reason': safety_result['reason'],
                'recommendation': safety_result['recommendation'],
                'gates_failed': safety_result['gates_failed'],
                'aisri_score': safety_result['aisri_score'],
                'injury_risk': safety_result['injury_risk'],
                'speed_permission': structural_result.get('speed_permission', False)
            }
        
        # Safety gates passed - generate workout
        # (Integrate with existing workout generator here)
        workout_plan = await self._generate_workout_plan(
            athlete_id=athlete_id,
            workout_type=workout_type,
            intensity=intensity,
            duration_minutes=duration_minutes,
            safety_data=safety_result
        )
        
        return {
            'status': 'success',
            'workout': workout_plan,
            'safety_check': safety_result,
            'structural_state': structural_result['state'],
            'structural_score': structural_result['structural_score'],
            'speed_permission': structural_result['speed_permission']
        }
    
    def _determine_safe_intensity(self, workout_type: str) -> str:
        """Determine safe default intensity for workout type"""
        
        intensity_map = {
            'recovery': 'easy',
            'easy': 'easy',
            'base': 'moderate',
            'tempo': 'hard',
            'threshold': 'hard',
            'interval': 'interval',
            'speed': 'interval',
            'long_run': 'moderate',
            'long': 'moderate'
        }
        
        return intensity_map.get(workout_type.lower(), 'moderate')
    
    async def _generate_workout_plan(
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
        
        return workout


    def _generate_warmup(self, total_duration: int) -> Dict:
        """Generate warm-up phase"""
        warmup_duration = min(15, int(total_duration * 0.15))
        return {
            'duration_minutes': warmup_duration,
            'description': 'Easy jogging, dynamic stretches',
            'intensity': 'easy'
        }
    
    def _generate_main_set(self, workout_type: str, intensity: str, total_duration: int) -> Dict:
        """Generate main workout set"""
        
        warmup_cooldown = int(total_duration * 0.3)
        main_duration = total_duration - warmup_cooldown
        
        if workout_type == 'interval':
            return {
                'duration_minutes': main_duration,
                'description': '8 x 3min @ 5K pace, 90sec recovery',
                'intervals': 8,
                'work_duration': '3:00',
                'rest_duration': '1:30',
                'intensity': intensity
            }
        else:
            return {
                'duration_minutes': main_duration,
                'description': f'{main_duration} minutes @ {intensity} pace',
                'intensity': intensity
            }
    
    def _generate_cooldown(self, total_duration: int) -> Dict:
        """Generate cool-down phase"""
        cooldown_duration = min(10, int(total_duration * 0.15))
        return {
            'duration_minutes': cooldown_duration,
            'description': 'Easy jogging, static stretches',
            'intensity': 'easy'
        }
    
    def _generate_safety_notes(self, safety_data: Dict) -> List[str]:
        """Generate safety notes based on assessment"""
        
        notes = []
        aisri = safety_data['aisri_score']
        
        if aisri < 70:
            notes.append('Monitor fatigue levels closely during this workout')
        
        if safety_data['injury_risk'] > 60:
            notes.append('Pay attention to any pain or discomfort - stop if needed')
        
        notes.append('Hydrate well before and during workout')
        notes.append('Follow warm-up and cool-down protocols')
        
        return notes
    
    # =====================================================
    # DAILY WORKFLOWS
    # =====================================================
    
    async def run_daily_athlete_update(self, athlete_id: str) -> Dict:
        """
        Run daily update workflow for athlete.
        
        1. Refresh Strava data
        2. Calculate AISRi
        3. Update injury risk
        4. Generate daily recommendation
        """
        
        result = {
            'athlete_id': athlete_id,
            'timestamp': datetime.now().isoformat(),
            'steps': {}
        }
        
        # Step 1: Sync Strava activities
        try:
            aisri_result = await self.calculate_aisri_from_strava(athlete_id)
            result['steps']['aisri_calculation'] = aisri_result['status']
        except Exception as e:
            result['steps']['aisri_calculation'] = f'error: {str(e)}'
        
        # Step 2: Check safety status
        try:
            safety_status = await self.get_safety_status(athlete_id)
            result['steps']['safety_check'] = safety_status['status']
        except Exception as e:
            result['steps']['safety_check'] = f'error: {str(e)}'
        
        return result
    
    # =====================================================
    # HEALTH & DIAGNOSTICS
    # =====================================================
    
    async def health_check(self) -> Dict:
        """System health check"""
        
        health = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'services': {}
        }
        
        # Check database
        try:
            self.db.supabase.table("athlete_profiles").select("id").limit(1).execute()
            health['services']['database'] = 'connected'
        except Exception as e:
            health['services']['database'] = f'error: {str(e)}'
            health['status'] = 'unhealthy'
        
        # Check Strava OAuth
        try:
            # Just check if service is initialized
            if self.strava_oauth.client_id:
                health['services']['strava_oauth'] = 'configured'
            else:
                health['services']['strava_oauth'] = 'missing_config'
        except Exception as e:
            health['services']['strava_oauth'] = f'error: {str(e)}'
        
        return health
