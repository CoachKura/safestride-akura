"""
AISRi Safety Gate System
Enforces safety checks before workout generation and execution.

Safety Gates:
1. AISRi Score Threshold - Minimum score for high-intensity workouts
2. Injury Risk Level - Block workouts if injury risk is high
3. Recovery Status - Ensure adequate recovery before hard sessions
4. Volume Progression - Prevent dangerous volume spikes
5. Consecutive Hard Days - Limit back-to-back hard sessions

Usage:
    safety_gate = AISRISafetyGate(database)
    result = await safety_gate.check_workout_safety(athlete_id, workout_type, intensity)
    
    if not result['safe']:
        # Block workout and provide reasoning
        return result['recommendation']
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta
from database_integration import DatabaseIntegration
from workout_templates import get_template_for_state, STRUCTURAL_WORKOUT_TEMPLATES



from enum import Enum

class StructuralState(Enum):
    """
    Structural readiness state based on structural score.
    
    States:
    - RED: < 55 - Only mobility + activation + zone 1-2 allowed
    - YELLOW: 55-70 - No threshold or VO2 allowed
    - GREEN: > 70 - Full training access
    """
    RED = 'red'
    YELLOW = 'yellow'
    GREEN = 'green'
    
    @staticmethod
    def from_score(structural_score: int) -> 'StructuralState':
        """Determine state from structural score"""
        if structural_score < 55:
            return StructuralState.RED
        elif structural_score <= 70:
            return StructuralState.YELLOW
        else:
            return StructuralState.GREEN


class AISRISafetyGate:
    """Enforces safety checks before workout generation"""
    
    # Safety thresholds
    MIN_AISRI_FOR_HARD_WORKOUT = 65
    MIN_AISRI_FOR_INTERVAL = 70
    MAX_INJURY_RISK = 75  # Out of 100
    MIN_RECOVERY_SCORE = 60
    MAX_CONSECUTIVE_HARD_DAYS = 3
    MAX_WEEKLY_VOLUME_INCREASE = 10  # Percent
    
    def __init__(self, database: DatabaseIntegration):
        """Initialize safety gate system"""
        self.db = database
    
    async def check_workout_safety(
        self,
        athlete_id: str,
        workout_type: str,
        intensity: str,
        duration_minutes: Optional[int] = None
    ) -> Dict:
        """
        Comprehensive safety check for workout generation.
        
        Args:
            athlete_id: SafeStride athlete ID
            workout_type: Type of workout (e.g., 'run', 'interval', 'long_run')
            intensity: Intensity level ('easy', 'moderate', 'hard', 'interval')
            duration_minutes: Planned workout duration
        
        Returns:
            {
                'safe': bool,
                'reason': str,
                'recommendation': str,
                'gates_passed': [str],
                'gates_failed': [str],
                'aisri_score': int,
                'injury_risk': int
            }
        """
        
        gates_passed = []
        gates_failed = []
        
        # Get athlete data
        athlete = self.db.get_athlete_profile(athlete_id)
        if not athlete:
            return self._create_result(False, "Athlete profile not found", "", [], ["missing_profile"])
        
        # Gate 1: AISRi Score Check
        aisri_check = await self._check_aisri_score(athlete_id, intensity)
        if aisri_check['passed']:
            gates_passed.append('aisri_score')
        else:
            gates_failed.append('aisri_score')
        
        # Gate 2: Injury Risk Check
        injury_check = await self._check_injury_risk(athlete_id, intensity)
        if injury_check['passed']:
            gates_passed.append('injury_risk')
        else:
            gates_failed.append('injury_risk')
        
        # Gate 3: Recovery Status Check
        recovery_check = await self._check_recovery_status(athlete_id, intensity)
        if recovery_check['passed']:
            gates_passed.append('recovery')
        else:
            gates_failed.append('recovery')
        
        # Gate 4: Consecutive Hard Days Check
        consecutive_check = await self._check_consecutive_hard_days(athlete_id, intensity)
        if consecutive_check['passed']:
            gates_passed.append('consecutive_days')
        else:
            gates_failed.append('consecutive_days')
        
        # Gate 5: Volume Progression Check (if duration provided)
        if duration_minutes:
            volume_check = await self._check_volume_progression(athlete_id, duration_minutes)
            if volume_check['passed']:
                gates_passed.append('volume_progression')
            else:
                gates_failed.append('volume_progression')
        
        # Determine overall safety
        safe = len(gates_failed) == 0
        
        # Build response
        if safe:
            return self._create_result(
                safe=True,
                reason="All safety gates passed",
                recommendation=f"Safe to proceed with {intensity} {workout_type}",
                gates_passed=gates_passed,
                gates_failed=gates_failed,
                aisri_score=aisri_check.get('score', 0),
                injury_risk=injury_check.get('risk', 0)
            )
        else:
            # Compile failure reasons
            reasons = []
            if 'aisri_score' in gates_failed:
                reasons.append(aisri_check['reason'])
            if 'injury_risk' in gates_failed:
                reasons.append(injury_check['reason'])
            if 'recovery' in gates_failed:
                reasons.append(recovery_check['reason'])
            if 'consecutive_days' in gates_failed:
                reasons.append(consecutive_check['reason'])
            if 'volume_progression' in gates_failed:
                reasons.append(volume_check['reason'])
            
            # Build recommendation
            recommendation = self._build_recommendation(gates_failed, intensity)
            
            return self._create_result(
                safe=False,
                reason="; ".join(reasons),
                recommendation=recommendation,
                gates_passed=gates_passed,
                gates_failed=gates_failed,
                aisri_score=aisri_check.get('score', 0),
                injury_risk=injury_check.get('risk', 0)
            )
    
    async def _check_aisri_score(self, athlete_id: str, intensity: str) -> Dict:
        """Check if AISRi score meets threshold for workout intensity"""
        
        try:
            # Get latest AISRi score
            result = self.db.supabase.table("aisri_scores").select("*").eq(
                "athlete_id", athlete_id
            ).order("created_at", desc=True).limit(1).execute()
            
            if not result.data or len(result.data) == 0:
                return {'passed': False, 'reason': 'No AISRi assessment found', 'score': 0}
            
            latest_score = result.data[0]
            aisri_value = latest_score.get('aisri_score', 0)
            
            # Check against intensity-specific thresholds
            if intensity in ['hard', 'tempo', 'threshold']:
                if aisri_value < self.MIN_AISRI_FOR_HARD_WORKOUT:
                    return {
                        'passed': False,
                        'reason': f'AISRi score ({aisri_value}) below threshold for hard workouts ({self.MIN_AISRI_FOR_HARD_WORKOUT})',
                        'score': aisri_value
                    }
            
            elif intensity in ['interval', 'speed', 'vo2max']:
                if aisri_value < self.MIN_AISRI_FOR_INTERVAL:
                    return {
                        'passed': False,
                        'reason': f'AISRi score ({aisri_value}) below threshold for interval workouts ({self.MIN_AISRI_FOR_INTERVAL})',
                        'score': aisri_value
                    }
            
            return {'passed': True, 'score': aisri_value}
        
        except Exception as e:
            return {'passed': False, 'reason': f'Error checking AISRi: {str(e)}', 'score': 0}
    
    async def _check_injury_risk(self, athlete_id: str, intensity: str) -> Dict:
        """Check injury risk level"""
        
        try:
            # Get latest injury prediction
            result = self.db.supabase.table("injury_risk_predictions").select("*").eq(
                "athlete_id", athlete_id
            ).order("created_at", desc=True).limit(1).execute()
            
            if not result.data or len(result.data) == 0:
                # No prediction = use neutral risk
                return {'passed': True, 'risk': 50}
            
            prediction = result.data[0]
            risk_score = prediction.get('risk_score', 50)
            
            # Block high-intensity workouts if injury risk is high
            if risk_score > self.MAX_INJURY_RISK and intensity in ['hard', 'interval', 'speed', 'tempo']:
                return {
                    'passed': False,
                    'reason': f'Injury risk ({risk_score}) too high for {intensity} workout',
                    'risk': risk_score
                }
            
            return {'passed': True, 'risk': risk_score}
        
        except Exception as e:
            return {'passed': True, 'risk': 50}  # Neutral on error
    
    async def _check_recovery_status(self, athlete_id: str, intensity: str) -> Dict:
        """Check recovery adequacy"""
        
        try:
            # Get latest AISRi score for recovery pillar
            result = self.db.supabase.table("aisri_scores").select("*").eq(
                "athlete_id", athlete_id
            ).order("created_at", desc=True).limit(1).execute()
            
            if not result.data or len(result.data) == 0:
                return {'passed': True}  # No data = allow
            
            latest_score = result.data[0]
            recovery_score = latest_score.get('pillar_recovery', 70)
            
            # Check recovery for hard workouts
            if intensity in ['hard', 'interval', 'speed', 'tempo', 'long']:
                if recovery_score < self.MIN_RECOVERY_SCORE:
                    return {
                        'passed': False,
                        'reason': f'Recovery score ({recovery_score}) too low for {intensity} workout'
                    }
            
            return {'passed': True}
        
        except Exception as e:
            return {'passed': True}  # Allow on error
    
    async def _check_consecutive_hard_days(self, athlete_id: str, intensity: str) -> Dict:
        """Check for too many consecutive hard workout days"""
        
        if intensity not in ['hard', 'interval', 'speed', 'tempo']:
            return {'passed': True}  # Only check hard workouts
        
        try:
            # Get recent workouts (last 7 days)
            seven_days_ago = (datetime.now() - timedelta(days=7)).isoformat()
            
            result = self.db.supabase.table("strava_activities").select("*").eq(
                "athlete_id", athlete_id
            ).gte("start_date", seven_days_ago).order("start_date", desc=True).execute()
            
            if not result.data:
                return {'passed': True}
            
            # Count consecutive hard days
            consecutive_hard = 0
            for activity in result.data:
                # Check if hard workout (high heart rate or interval type)
                avg_hr = activity.get('average_heartrate', 0)
                workout_type = activity.get('workout_type', '')
                
                is_hard = (
                    avg_hr > 160 or
                    workout_type in ['3', '4', '9']  # Strava workout types: interval, tempo, race
                )
                
                if is_hard:
                    consecutive_hard += 1
                else:
                    break  # Streak broken
            
            if consecutive_hard >= self.MAX_CONSECUTIVE_HARD_DAYS:
                return {
                    'passed': False,
                    'reason': f'Too many consecutive hard days ({consecutive_hard}). Recovery day recommended.'
                }
            
            return {'passed': True}
        
        except Exception as e:
            return {'passed': True}  # Allow on error
    
    async def _check_volume_progression(self, athlete_id: str, planned_duration: int) -> Dict:
        """Check for safe volume progression"""
        
        try:
            # Get last 2 weeks of activity volume
            two_weeks_ago = (datetime.now() - timedelta(days=14)).isoformat()
            one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            
            # Week 1 volume (2 weeks ago to 1 week ago)
            result_week1 = self.db.supabase.table("strava_activities").select("moving_time").eq(
                "athlete_id", athlete_id
            ).gte("start_date", two_weeks_ago).lt("start_date", one_week_ago).execute()
            
            # Week 2 volume (last 7 days)
            result_week2 = self.db.supabase.table("strava_activities").select("moving_time").eq(
                "athlete_id", athlete_id
            ).gte("start_date", one_week_ago).execute()
            
            week1_minutes = sum([a.get('moving_time', 0) / 60 for a in result_week1.data]) if result_week1.data else 0
            week2_minutes = sum([a.get('moving_time', 0) / 60 for a in result_week2.data]) if result_week2.data else 0
            
            # Calculate proposed volume increase
            if week1_minutes > 0:
                proposed_week2 = week2_minutes + planned_duration
                increase_percent = ((proposed_week2 - week1_minutes) / week1_minutes) * 100
                
                if increase_percent > self.MAX_WEEKLY_VOLUME_INCREASE:
                    return {
                        'passed': False,
                        'reason': f'Weekly volume increase ({increase_percent:.1f}%) exceeds safe limit ({self.MAX_WEEKLY_VOLUME_INCREASE}%)'
                    }
            
            return {'passed': True}
        
        except Exception as e:
            return {'passed': True}  # Allow on error
    
    def _create_result(
        self,
        safe: bool,
        reason: str,
        recommendation: str,
        gates_passed: List[str],
        gates_failed: List[str],
        aisri_score: int = 0,
        injury_risk: int = 0
    ) -> Dict:
        """Create standardized result dictionary"""
        return {
            'safe': safe,
            'reason': reason,
            'recommendation': recommendation,
            'gates_passed': gates_passed,
            'gates_failed': gates_failed,
            'aisri_score': aisri_score,
            'injury_risk': injury_risk,
            'checked_at': datetime.now().isoformat()
        }
    
    def _build_recommendation(self, gates_failed: List[str], intensity: str) -> str:
        """Build safety recommendation based on failed gates"""
        
        if 'aisri_score' in gates_failed:
            return f"AISRi score too low. Recommend easy recovery run instead of {intensity} workout."
        
        if 'injury_risk' in gates_failed:
            return "Injury risk elevated. Focus on recovery and mobility work instead."
        
        if 'recovery' in gates_failed:
            return "Inadequate recovery. Schedule rest day or very easy aerobic session."
        
        if 'consecutive_days' in gates_failed:
            return "Too many hard days in a row. Take a recovery day before next hard session."
        
        if 'volume_progression' in gates_failed:
            return "Volume increasing too quickly. Reduce workout duration or intensity."
        
        return "Safety concerns detected. Consult coach before proceeding with workout."
    
    async def get_safety_summary(self, athlete_id: str) -> Dict:
        """Get overall safety status summary for athlete"""
        
        try:
            # Get latest scores
            aisri_result = self.db.supabase.table("aisri_scores").select("*").eq(
                "athlete_id", athlete_id
            ).order("created_at", desc=True).limit(1).execute()
            
            injury_result = self.db.supabase.table("injury_risk_predictions").select("*").eq(
                "athlete_id", athlete_id
            ).order("created_at", desc=True).limit(1).execute()
            
            aisri_score = aisri_result.data[0].get('aisri_score', 0) if aisri_result.data else 0
            injury_risk = injury_result.data[0].get('risk_score', 50) if injury_result.data else 50
            recovery = aisri_result.data[0].get('pillar_recovery', 70) if aisri_result.data else 70
            
            # Determine overall status
            if aisri_score >= 75 and injury_risk < 50:
                status = "EXCELLENT"
                message = "All systems go! Ready for high-intensity training."
            elif aisri_score >= 65 and injury_risk < 65:
                status = "GOOD"
                message = "Safe for moderate to hard training."
            elif aisri_score >= 50 and injury_risk < 75:
                status = "CAUTION"
                message = "Proceed with easy to moderate training only."
            else:
                status = "WARNING"
                message = "Focus on recovery. Avoid hard training."
            
            return {
                'status': status,
                'message': message,
                'aisri_score': aisri_score,
                'injury_risk': injury_risk,
                'recovery_score': recovery,
                'updated_at': datetime.now().isoformat()
            }

        except Exception as e:
            return {
                'status': 'ERROR',
                'message': f'Error fetching safety summary: {str(e)}',
                'aisri_score': 0,
                'injury_risk': 50,
                'recovery_score': 50,
                'updated_at': datetime.now().isoformat()
            }

    async def get_structural_score(self, athlete_id: str) -> int:
        """
        Get structural score for athlete.
        
        For now, uses combination of strength + mobility from latest AISRI assessment.
        Future: Can be enhanced with specific structural tests.
        
        Returns:
            Structural score (0-100)
        """
        try:
            # Fetch latest AISRI assessment with pillar breakdowns
            result = self.db.supabase.table("aisri_scores").select("*").eq(
                "athlete_id", athlete_id
            ).order("assessment_date", desc=True).limit(1).execute()
            
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
            print(f"Warning: Could not fetch structural score: {e}")
            return 50  # Default on error
    
    async def get_structural_state(self, athlete_id: str) -> StructuralState:
        """
        Determine structural state for athlete.
        
        Returns:
            StructuralState enum (RED/YELLOW/GREEN)
        """
        structural_score = await self.get_structural_score(athlete_id)
        return StructuralState.from_score(structural_score)
    
    async def check_structural_clearance(
        self, 
        athlete_id: str, 
        workout_type: str,
        intensity: str
    ) -> Dict:
        """
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
        """
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



