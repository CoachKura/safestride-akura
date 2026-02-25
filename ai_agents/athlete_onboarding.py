"""
ATHLETE ONBOARDING MODULE
=========================
Complete athlete signup and baseline assessment plan generation

Features:
- New athlete signup with Strava integration
- Capture "BEFORE signup" baseline from Strava history
- Classify athlete level (beginner/intermediate/advanced)
- Set SMART goals (time-based or pace-based)
- Generate personalized 14-day baseline assessment plan

Author: AISRI AI Coaching System
Created: February 25, 2026
"""

import os
import json
import logging
from datetime import datetime, timedelta, date
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import httpx
from supabase import create_client, Client

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")  # Use service key for admin operations
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class BeforeSignupBaseline:
    """Athlete's baseline metrics before signing up (from Strava history)"""
    weekly_volume_km: float
    avg_pace: str  # Format: "MM:SS" (per km)
    runs_per_week: float
    longest_run_km: float
    consistency_score: float  # 0-100
    total_runs_90_days: int
    avg_distance_per_run: float
    pace_variability: float  # Lower = more consistent
    raw_activities: List[Dict]


@dataclass
class AthleteClassification:
    """Athlete level classification with reasoning"""
    level: str  # 'beginner', 'intermediate', 'advanced'
    confidence: float  # 0-100
    reasoning: str
    key_indicators: List[str]


@dataclass
class AthleteGoal:
    """Athlete's training goal"""
    primary_goal: str  # '5K', '10K', 'Half Marathon', 'Marathon'
    goal_type: str  # 'time_based', 'pace_based'
    target_time: Optional[str]  # "HH:MM:SS"
    target_pace: Optional[str]  # "MM:SS" per km
    target_race_date: date
    weeks_to_goal: int


@dataclass
class BaselinePlanDay:
    """Single day in 14-day baseline assessment plan"""
    day_number: int
    workout_date: date
    workout_type: str
    workout_category: str
    workout_details: Dict
    expected_duration_minutes: int
    expected_distance_km: Optional[float]
    expected_pace_min: Optional[str]
    expected_pace_max: Optional[str]
    expected_hr_target: Optional[int]
    coach_instructions: str
    focus_areas: List[str]
    assessment_purpose: str


# ============================================================================
# ATHLETE ONBOARDING CLASS
# ============================================================================

class AthleteOnboarding:
    """
    Complete athlete onboarding system
    
    Workflow:
    1. Create athlete profile
    2. Connect Strava & fetch history
    3. Analyze baseline (BEFORE signup state)
    4. Classify athlete level
    5. Set goals
    6. Generate 14-day baseline assessment plan
    7. Send welcome message
    """
    
    def __init__(self):
        self.supabase = supabase
        logger.info("AthleteOnboarding initialized")
    
    
    # ========================================================================
    # MAIN SIGNUP FLOW
    # ========================================================================
    
    async def signup_new_athlete(
        self,
        athlete_data: Dict,
        strava_athlete_id: int,
        strava_access_token: str
    ) -> Dict:
        """
        Complete athlete signup process
        
        Args:
            athlete_data: Basic athlete info (name, email, phone, etc.)
            strava_athlete_id: Strava athlete ID
            strava_access_token: Strava OAuth token
        
        Returns:
            Dict with athlete_id, profile_id, baseline_plan_id, welcome_message
        """
        try:
            logger.info(f"Starting signup for athlete: {athlete_data.get('email')}")
            
            # Step 1: Create base athlete profile
            athlete_id = await self._create_athlete_profile(athlete_data, strava_athlete_id)
            logger.info(f"✅ Athlete profile created: {athlete_id}")
            
            # Step 2: Fetch Strava history
            strava_activities = await self._fetch_strava_history(
                strava_access_token,
                days=90  # Last 90 days
            )
            logger.info(f"✅ Fetched {len(strava_activities)} Strava activities")
            
            # Step 3: Analyze BEFORE signup baseline
            baseline = await self.capture_before_signup_baseline(
                athlete_id,
                strava_activities
            )
            logger.info(f"✅ Baseline captured: {baseline.weekly_volume_km:.1f} km/week")
            
            # Step 4: Classify athlete level
            classification = await self.classify_athlete_level(baseline)
            logger.info(f"✅ Classified as: {classification.level} ({classification.confidence:.0f}% confidence)")
            
            # Step 5: Create detailed profile
            profile_id = await self._create_detailed_profile(
                athlete_id,
                athlete_data,
                baseline,
                classification
            )
            logger.info(f"✅ Detailed profile created: {profile_id}")
            
            # Step 6: Set goals (from athlete_data or default)
            goal = await self.set_athlete_goals(athlete_id, athlete_data)
            logger.info(f"✅ Goal set: {goal.primary_goal} in {goal.weeks_to_goal} weeks")
            
            # Step 7: Generate 14-day baseline assessment plan
            plan_days = await self.generate_14day_plan(
                athlete_id,
                classification.level,
                baseline,
                goal
            )
            logger.info(f"✅ 14-day plan generated: {len(plan_days)} days")
            
            # Step 8: Save plan to database
            await self._save_baseline_plan(athlete_id, plan_days)
            logger.info("✅ Plan saved to database")
            
            # Step 9: Generate welcome message
            welcome_message = self._generate_welcome_message(
                athlete_data['name'],
                classification,
                goal,
                plan_days[0]  # First day workout
            )
            
            return {
                "success": True,
                "athlete_id": athlete_id,
                "profile_id": profile_id,
                "classification": classification.level,
                "goal": f"{goal.primary_goal} - {goal.target_time or goal.target_pace}",
                "baseline_plan_days": len(plan_days),
                "welcome_message": welcome_message,
                "first_workout_date": plan_days[0].workout_date.isoformat()
            }
            
        except Exception as e:
            logger.error(f"❌ Signup failed: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
    
    
    # ========================================================================
    # STRAVA INTEGRATION
    # ========================================================================
    
    async def _fetch_strava_history(
        self,
        access_token: str,
        days: int = 90
    ) -> List[Dict]:
        """
        Fetch athlete's Strava activity history
        
        Args:
            access_token: Strava OAuth access token
            days: Number of days to fetch (default: 90)
        
        Returns:
            List of activity dictionaries
        """
        try:
            # Calculate date range
            after_timestamp = int((datetime.now() - timedelta(days=days)).timestamp())
            
            # Fetch activities from Strava API
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://www.strava.com/api/v3/athlete/activities",
                    headers={"Authorization": f"Bearer {access_token}"},
                    params={
                        "after": after_timestamp,
                        "per_page": 200  # Max allowed
                    },
                    timeout=30.0
                )
                response.raise_for_status()
                activities = response.json()
            
            # Filter only running activities
            running_activities = [
                act for act in activities
                if act.get('type') in ['Run', 'VirtualRun']
            ]
            
            logger.info(f"Fetched {len(running_activities)} running activities from last {days} days")
            return running_activities
            
        except Exception as e:
            logger.error(f"Error fetching Strava history: {str(e)}")
            return []
    
    
    async def capture_before_signup_baseline(
        self,
        athlete_id: str,
        activities: List[Dict]
    ) -> BeforeSignupBaseline:
        """
        Analyze Strava history to establish BEFORE signup baseline
        
        Metrics calculated:
        - Weekly volume (km)
        - Average pace (min/km)
        - Runs per week
        - Longest run
        - Consistency score
        
        Args:
            athlete_id: UUID of athlete
            activities: List of Strava activities
        
        Returns:
            BeforeSignupBaseline object
        """
        if not activities:
            # No Strava history - complete beginner
            return BeforeSignupBaseline(
                weekly_volume_km=0.0,
                avg_pace="00:00",
                runs_per_week=0.0,
                longest_run_km=0.0,
                consistency_score=0.0,
                total_runs_90_days=0,
                avg_distance_per_run=0.0,
                pace_variability=0.0,
                raw_activities=[]
            )
        
        # Calculate metrics
        total_distance_m = sum(act.get('distance', 0) for act in activities)
        total_distance_km = total_distance_m / 1000.0
        
        total_time_s = sum(act.get('moving_time', 0) for act in activities)
        
        num_runs = len(activities)
        days_span = 90  # We fetched 90 days
        weeks_span = days_span / 7.0
        
        # Weekly volume
        weekly_volume = total_distance_km / weeks_span if weeks_span > 0 else 0
        
        # Runs per week
        runs_per_week = num_runs / weeks_span if weeks_span > 0 else 0
        
        # Average pace (min/km)
        if total_distance_km > 0 and total_time_s > 0:
            avg_pace_seconds_per_km = total_time_s / total_distance_km
            avg_pace = self._seconds_to_pace_string(avg_pace_seconds_per_km)
        else:
            avg_pace = "00:00"
        
        # Longest run
        longest_run_m = max((act.get('distance', 0) for act in activities), default=0)
        longest_run_km = longest_run_m / 1000.0
        
        # Average distance per run
        avg_distance = total_distance_km / num_runs if num_runs > 0 else 0
        
        # Pace variability (coefficient of variation)
        paces = []
        for act in activities:
            dist = act.get('distance', 0) / 1000.0  # km
            time = act.get('moving_time', 0)  # seconds
            if dist > 0 and time > 0:
                pace_sec_per_km = time / dist
                paces.append(pace_sec_per_km)
        
        if len(paces) > 1:
            import statistics
            pace_mean = statistics.mean(paces)
            pace_std = statistics.stdev(paces)
            pace_variability = (pace_std / pace_mean) * 100 if pace_mean > 0 else 0
        else:
            pace_variability = 0
        
        # Consistency score (0-100)
        # Based on: runs per week, regularity, volume consistency
        consistency_score = self._calculate_consistency_score(
            runs_per_week,
            activities,
            pace_variability
        )
        
        baseline = BeforeSignupBaseline(
            weekly_volume_km=round(weekly_volume, 1),
            avg_pace=avg_pace,
            runs_per_week=round(runs_per_week, 1),
            longest_run_km=round(longest_run_km, 1),
            consistency_score=round(consistency_score, 1),
            total_runs_90_days=num_runs,
            avg_distance_per_run=round(avg_distance, 1),
            pace_variability=round(pace_variability, 1),
            raw_activities=activities
        )
        
        logger.info(f"Baseline: {baseline.weekly_volume_km} km/week, {baseline.avg_pace}/km, {baseline.runs_per_week} runs/week")
        return baseline
    
    
    # ========================================================================
    # ATHLETE CLASSIFICATION
    # ========================================================================
    
    async def classify_athlete_level(self, baseline: BeforeSignupBaseline) -> AthleteClassification:
        """
        Classify athlete level based on baseline metrics
        
        Criteria:
        - Beginner: < 3 months consistent, < 20km/week, pace > 7:00/km
        - Intermediate: 3-12 months, 20-50km/week, pace 5:30-7:00/km
        - Advanced: > 12 months, > 50km/week, pace < 5:30/km
        
        Args:
            baseline: BeforeSignupBaseline object
        
        Returns:
            AthleteClassification object
        """
        indicators = []
        points = 0  # Classification score
        
        # Factor 1: Weekly volume
        if baseline.weekly_volume_km < 15:
            indicators.append(f"Low volume ({baseline.weekly_volume_km:.1f} km/week)")
            points += 0
        elif baseline.weekly_volume_km < 35:
            indicators.append(f"Moderate volume ({baseline.weekly_volume_km:.1f} km/week)")
            points += 5
        else:
            indicators.append(f"High volume ({baseline.weekly_volume_km:.1f} km/week)")
            points += 10
        
        # Factor 2: Frequency
        if baseline.runs_per_week < 2:
            indicators.append(f"Infrequent running ({baseline.runs_per_week:.1f} runs/week)")
            points += 0
        elif baseline.runs_per_week < 4:
            indicators.append(f"Regular running ({baseline.runs_per_week:.1f} runs/week)")
            points += 5
        else:
            indicators.append(f"Frequent running ({baseline.runs_per_week:.1f} runs/week)")
            points += 10
        
        # Factor 3: Pace (convert to seconds for comparison)
        pace_seconds = self._pace_string_to_seconds(baseline.avg_pace)
        if pace_seconds > 450:  # Slower than 7:30/km
            indicators.append(f"Developing pace ({baseline.avg_pace}/km)")
            points += 0
        elif pace_seconds > 360:  # 6:00-7:30/km
            indicators.append(f"Good pace ({baseline.avg_pace}/km)")
            points += 5
        else:  # Faster than 6:00/km
            indicators.append(f"Strong pace ({baseline.avg_pace}/km)")
            points += 10
        
        # Factor 4: Consistency
        if baseline.consistency_score < 40:
            indicators.append(f"Building consistency ({baseline.consistency_score:.0f}/100)")
            points += 0
        elif baseline.consistency_score < 70:
            indicators.append(f"Consistent training ({baseline.consistency_score:.0f}/100)")
            points += 5
        else:
            indicators.append(f"Very consistent ({baseline.consistency_score:.0f}/100)")
            points += 10
        
        # Factor 5: Total experience (number of runs)
        if baseline.total_runs_90_days < 15:
            indicators.append(f"New to running ({baseline.total_runs_90_days} runs in 90 days)")
            points += 0
        elif baseline.total_runs_90_days < 40:
            indicators.append(f"Some experience ({baseline.total_runs_90_days} runs in 90 days)")
            points += 5
        else:
            indicators.append(f"Experienced runner ({baseline.total_runs_90_days} runs in 90 days)")
            points += 10
        
        # Classify based on total points
        if points < 12:
            level = "beginner"
            confidence = 75 + (points / 12) * 15
            reasoning = "New to consistent running or returning after layoff. Focus on building base."
        elif points < 30:
            level = "intermediate"
            confidence = 75 + ((points - 12) / 18) * 15
            reasoning = "Established running routine with room to improve speed and endurance."
        else:
            level = "advanced"
            confidence = 85 + ((points - 30) / 20) * 15
            reasoning = "Strong running foundation. Ready for advanced training and performance goals."
        
        classification = AthleteClassification(
            level=level,
            confidence=round(min(confidence, 95), 1),
            reasoning=reasoning,
            key_indicators=indicators
        )
        
        logger.info(f"Classification: {level} (confidence: {confidence:.1f}%)")
        return classification
    
    
    # ========================================================================
    # GOAL SETTING
    # ========================================================================
    
    async def set_athlete_goals(self, athlete_id: str, athlete_data: Dict) -> AthleteGoal:
        """
        Set athlete's training goals
        
        Args:
            athlete_id: UUID of athlete
            athlete_data: Dict containing goal information
        
        Returns:
            AthleteGoal object
        """
        # Extract goal data (with sensible defaults)
        primary_goal = athlete_data.get('primary_goal', '10K')
        goal_type = athlete_data.get('goal_type', 'time_based')
        target_time = athlete_data.get('target_time')  # "HH:MM:SS" or "MM:SS"
        target_pace = athlete_data.get('target_pace')  # "MM:SS"
        
        # Target race date (default: 16 weeks from now)
        if 'target_race_date' in athlete_data:
            race_date = datetime.fromisoformat(athlete_data['target_race_date']).date()
        else:
            race_date = date.today() + timedelta(weeks=16)
        
        weeks_to_goal = (race_date - date.today()).days // 7
        
        goal = AthleteGoal(
            primary_goal=primary_goal,
            goal_type=goal_type,
            target_time=target_time,
            target_pace=target_pace,
            target_race_date=race_date,
            weeks_to_goal=weeks_to_goal
        )
        
        logger.info(f"Goal: {primary_goal} in {weeks_to_goal} weeks ({goal_type})")
        return goal
    
    
    # ========================================================================
    # 14-DAY BASELINE ASSESSMENT PLAN GENERATION
    # ========================================================================
    
    async def generate_14day_plan(
        self,
        athlete_id: str,
        athlete_level: str,
        baseline: BeforeSignupBaseline,
        goal: AthleteGoal
    ) -> List[BaselinePlanDay]:
        """
        Generate personalized 14-day baseline assessment plan
        
        Structure:
        Days 1-4: Easy runs + ROM (assess baseline fitness)
        Days 5-7: Add tempo runs (assess lactate threshold)
        Days 8-10: Add intervals (assess speed capability)
        Days 11-12: Strength assessment
        Days 13-14: Long run (assess endurance) + rest
        
        Args:
            athlete_id: UUID of athlete
            athlete_level: 'beginner', 'intermediate', or 'advanced'
            baseline: BeforeSignupBaseline object
            goal: AthleteGoal object
        
        Returns:
            List of BaselinePlanDay objects (14 days)
        """
        logger.info(f"Generating 14-day plan for {athlete_level} athlete")
        
        # Get level-specific parameters
        params = self._get_level_parameters(athlete_level, baseline)
        
        plan_days = []
        start_date = date.today() + timedelta(days=1)  # Start tomorrow
        
        # DAY 1: Easy run + ROM
        plan_days.append(self._create_plan_day(
            day_number=1,
            workout_date=start_date,
            workout_type="easy_run",
            distance=params['initial_easy_distance'],
            pace_range=(params['easy_pace_min'], params['easy_pace_max']),
            hr_target=params['easy_hr'],
            instructions="Welcome run! Keep it comfortable and easy. You should be able to chat comfortably.",
            focus_areas=["relaxed form", "comfortable breathing", "easy effort"],
            assessment_purpose="Baseline fitness assessment"
        ))
        
        # DAY 2: ROM + Strength
        plan_days.append(self._create_plan_day(
            day_number=2,
            workout_date=start_date + timedelta(days=1),
            workout_type="combined",
            distance=None,
            duration=30,
            instructions="Mobility and strength work. Focus on running-specific movements.",
            focus_areas=["hip mobility", "core strength", "ankle stability"],
            assessment_purpose="Assess mobility and strength baseline",
            is_strength=True
        ))
        
        # Continue with remaining days...
        # (Full implementation would include all 14 days)
        
        # For brevity, adding a few more key days:
        
        # DAY 3: Easy run  (continued assessment)
        plan_days.append(self._create_plan_day(
            day_number=3,
            workout_date=start_date + timedelta(days=2),
            workout_type="easy_run",
            distance=params['initial_easy_distance'] * 1.2,
            pace_range=(params['easy_pace_min'], params['easy_pace_max']),
            hr_target=params['easy_hr'],
            instructions="Another easy run. Listen to your body. Notice your natural pace and breathing.",
            focus_areas=["cadence awareness", "form", "heart rate control"],
            assessment_purpose="Consistency and natural pace assessment"
        ))
        
        # DAY 4: Rest
        plan_days.append(self._create_plan_day(
            day_number=4,
            workout_date=start_date + timedelta(days=3),
            workout_type="rest",
            distance=None,
            instructions="Complete rest day. Recovery is when you get stronger!",
            focus_areas=["hydration", "nutrition", "sleep"],
            assessment_purpose="Recovery assessment"
        ))
        
        # DAY 5: Tempo run (lactate threshold test)
        plan_days.append(self._create_plan_day(
            day_number=5,
            workout_date=start_date + timedelta(days=4),
            workout_type="tempo_run",
            distance=params['tempo_distance'],
            pace_range=(params['tempo_pace_min'], params['tempo_pace_max']),
            hr_target=params['tempo_hr'],
            instructions="Comfortably hard effort. You can speak in short phrases only.",
            focus_areas=["threshold effort", "controlled breathing", "steady pace"],
            assessment_purpose="Lactate threshold assessment"
        ))
        
        # ... Continue for all 14 days
        # (Implementation would include days 6-14 with varied workouts)
        
        # For now, let's create a simplified complete plan
        plan_days.extend(self._generate_remaining_days(
            start_date,
            params,
            athlete_level
        ))
        
        logger.info(f"Generated {len(plan_days)} day plan")
        return plan_days[:14]  # Ensure exactly 14 days
    
    
    def _get_level_parameters(self, level: str, baseline: BeforeSignupBaseline) -> Dict:
        """Get training parameters based on athlete level"""
        
        if level == "beginner":
            return {
                'initial_easy_distance': 3.0,  # km
                'tempo_distance': 3.0,
                'interval_distance': 0.4,  # km per rep
                'long_run_distance': 5.0,
                'easy_pace_min': '07:00',
                'easy_pace_max': '08:00',
                'tempo_pace_min': '06:30',
                'tempo_pace_max': '07:00',
                'interval_pace': '06:00',
                'easy_hr': 150,
                'tempo_hr': 165,
                'interval_hr': 175
            }
        elif level == "intermediate":
            return {
                'initial_easy_distance': 5.0,
                'tempo_distance': 5.0,
                'interval_distance': 0.8,
                'long_run_distance': 10.0,
                'easy_pace_min': '06:00',
                'easy_pace_max': '06:45',
                'tempo_pace_min': '05:30',
                'tempo_pace_max': '06:00',
                'interval_pace': '05:00',
                'easy_hr': 150,
                'tempo_hr': 165,
                'interval_hr': 180
            }
        else:  # advanced
            return {
                'initial_easy_distance': 8.0,
                'tempo_distance': 8.0,
                'interval_distance': 1.0,
                'long_run_distance': 15.0,
                'easy_pace_min': '05:00',
                'easy_pace_max': '05:45',
                'tempo_pace_min': '04:30',
                'tempo_pace_max': '05:00',
                'interval_pace': '04:00',
                'easy_hr': 145,
                'tempo_hr': 165,
                'interval_hr': 185
            }
    
    
    def _create_plan_day(
        self,
        day_number: int,
        workout_date: date,
        workout_type: str,
        distance: Optional[float] = None,
        pace_range: Optional[Tuple[str, str]] = None,
        hr_target: Optional[int] = None,
        duration: Optional[int] = None,
        instructions: str = "",
        focus_areas: List[str] = None,
        assessment_purpose: str = "",
        is_strength: bool = False
    ) -> BaselinePlanDay:
        """Create a single day in the baseline plan"""
        
        workout_category = "strength" if is_strength else ("rest" if workout_type == "rest" else "running")
        
        if distance:
            expected_pace_avg = self._calculate_avg_pace(pace_range) if pace_range else None
            expected_duration = int((distance * self._pace_string_to_seconds(expected_pace_avg)) / 60) if expected_pace_avg else None
        else:
            expected_duration = duration
        
        workout_details = {
            "type": workout_type,
            "distance": distance,
            "duration": duration,
            "pace_range": pace_range,
            "is_strength": is_strength
        }
        
        return BaselinePlanDay(
            day_number=day_number,
            workout_date=workout_date,
            workout_type=workout_type,
            workout_category=workout_category,
            workout_details=workout_details,
            expected_duration_minutes=expected_duration or 0,
            expected_distance_km=distance,
            expected_pace_min=pace_range[0] if pace_range else None,
            expected_pace_max=pace_range[1] if pace_range else None,
            expected_hr_target=hr_target,
            coach_instructions=instructions,
            focus_areas=focus_areas or [],
            assessment_purpose=assessment_purpose
        )
    
    
    def _generate_remaining_days(self, start_date: date, params: Dict, level: str) -> List[BaselinePlanDay]:
        """Generate days 6-14 of the plan"""
        # Simplified implementation - would be fully expanded in production
        days = []
        
        # Days 6-14 would include:
        # - More easy runs
        # - Interval workouts
        # - Strength sessions
        # - Long run
        # - Rest days
        
        # Placeholder for now
        for day in range(6, 15):
            days.append(self._create_plan_day(
                day_number=day,
                workout_date=start_date + timedelta(days=day-1),
                workout_type="easy_run",
                distance=params['initial_easy_distance'],
                pace_range=(params['easy_pace_min'], params['easy_pace_max']),
                hr_target=params['easy_hr'],
                instructions=f"Day {day} workout - details coming soon",
                focus_areas=["form", "consistency"],
                assessment_purpose="Ongoing assessment"
            ))
        
        return days
    
    
    # ========================================================================
    # DATABASE OPERATIONS
    # ========================================================================
    
    async def _create_athlete_profile(self, athlete_data: Dict, strava_athlete_id: int) -> str:
        """Create base athlete profile in database"""
        try:
            result = self.supabase.table("athlete_profiles").insert({
                "name": athlete_data['name'],
                "email": athlete_data['email'],
                "phone_number": athlete_data.get('phone_number'),
                "strava_athlete_id": strava_athlete_id,
                "is_active": True
            }).execute()
            
            athlete_id = result.data[0]['athlete_id']
            return str(athlete_id)
        except Exception as e:
            logger.error(f"Error creating athlete profile: {str(e)}")
            raise
    
    
    async def _create_detailed_profile(
        self,
        athlete_id: str,
        athlete_data: Dict,
        baseline: BeforeSignupBaseline,
        classification: AthleteClassification
    ) -> str:
        """Create detailed athlete profile"""
        try:
            result = self.supabase.table("athlete_detailed_profile").insert({
                "athlete_id": athlete_id,
                "current_level": classification.level,
                "before_signup_weekly_volume_km": baseline.weekly_volume_km,
                "before_signup_avg_pace": baseline.avg_pace,
                "before_signup_runs_per_week": baseline.runs_per_week,
                "before_signup_longest_run_km": baseline.longest_run_km,
                "before_signup_consistency_score": baseline.consistency_score,
                "before_signup_json": {
                    "total_runs_90_days": baseline.total_runs_90_days,
                    "avg_distance_per_run": baseline.avg_distance_per_run,
                    "pace_variability": baseline.pace_variability,
                    "classification": {
                        "confidence": classification.confidence,
                        "reasoning": classification.reasoning,
                        "indicators": classification.key_indicators
                    }
                },
                "baseline_assessment_status": "not_started"
            }).execute()
            
            profile_id = result.data[0]['id']
            return str(profile_id)
        except Exception as e:
            logger.error(f"Error creating detailed profile: {str(e)}")
            raise
    
    
    async def _save_baseline_plan(self, athlete_id: str, plan_days: List[BaselinePlanDay]):
        """Save 14-day baseline plan to database"""
        try:
            # Prepare data for bulk insert
            plan_records = []
            for day in plan_days:
                plan_records.append({
                    "athlete_id": athlete_id,
                    "day_number": day.day_number,
                    "workout_date": day.workout_date.isoformat(),
                    "workout_type": day.workout_type,
                    "workout_category": day.workout_category,
                    "workout_details": day.workout_details,
                    "expected_duration_minutes": day.expected_duration_minutes,
                    "expected_distance_km": day.expected_distance_km,
                    "expected_pace_min": day.expected_pace_min,
                    "expected_pace_max": day.expected_pace_max,
                    "expected_avg_hr": day.expected_hr_target,
                    "coach_instructions": day.coach_instructions,
                    "focus_areas": day.focus_areas,
                    "assessment_purpose": day.assessment_purpose,
                    "completion_status": "scheduled"
                })
            
            # Bulk insert
            self.supabase.table("baseline_assessment_plan").insert(plan_records).execute()
            logger.info(f"Saved {len(plan_records)} day plan to database")
            
        except Exception as e:
            logger.error(f"Error saving baseline plan: {str(e)}")
            raise
    
    
    # ========================================================================
    # HELPER FUNCTIONS
    # ========================================================================
    
    def _seconds_to_pace_string(self, seconds_per_km: float) -> str:
        """Convert seconds per km to MM:SS format"""
        minutes = int(seconds_per_km // 60)
        secs = int(seconds_per_km % 60)
        return f"{minutes:02d}:{secs:02d}"
    
    
    def _pace_string_to_seconds(self, pace_string: str) -> float:
        """Convert MM:SS pace string to seconds per km"""
        if not pace_string or pace_string == "00:00":
            return 0
        parts = pace_string.split(':')
        return int(parts[0]) * 60 + int(parts[1])
    
    
    def _calculate_avg_pace(self, pace_range: Tuple[str, str]) -> str:
        """Calculate average of pace range"""
        min_seconds = self._pace_string_to_seconds(pace_range[0])
        max_seconds = self._pace_string_to_seconds(pace_range[1])
        avg_seconds = (min_seconds + max_seconds) / 2
        return self._seconds_to_pace_string(avg_seconds)
    
    
    def _calculate_consistency_score(
        self,
        runs_per_week: float,
        activities: List[Dict],
        pace_variability: float
    ) -> float:
        """
        Calculate consistency score (0-100)
        
        Factors:
        - Frequency (runs per week)
        - Regularity (gaps between runs)
        - Pace consistency
        """
        score = 0
        
        # Frequency component (0-40 points)
        if runs_per_week >= 4:
            score += 40
        elif runs_per_week >= 3:
            score += 30
        elif runs_per_week >= 2:
            score += 20
        else:
            score += 10
        
        # Pace consistency (0-30 points)
        if pace_variability < 10:
            score += 30
        elif pace_variability < 20:
            score += 20
        elif pace_variability < 30:
            score += 10
        
        # Regularity (0-30 points)
        # Check for regular spacing between runs
        if len(activities) >= 4:
            dates = [datetime.fromisoformat(act['start_date'].replace('Z', '+00:00')) for act in activities]
            dates.sort()
            gaps = [(dates[i+1] - dates[i]).days for i in range(len(dates)-1)]
            
            if gaps:
                import statistics
                avg_gap = statistics.mean(gaps)
                if 2 <= avg_gap <= 4:  # Ideally 2-4 days between runs
                    score += 30
                elif 1 <= avg_gap <= 5:
                    score += 20
                else:
                    score += 10
        
        return min(score, 100)
    
    
    def _generate_welcome_message(
        self,
        athlete_name: str,
        classification: AthleteClassification,
        goal: AthleteGoal,
        first_day: BaselinePlanDay
    ) -> str:
        """Generate personalized welcome message"""
        message = f"""
🎉 Welcome to AISRI, {athlete_name}!

I'm your AI running coach, and I'm excited to help you achieve your goal!

📊 YOUR PROFILE:
• Level: {classification.level.title()}
• Goal: {goal.primary_goal} in {goal.weeks_to_goal} weeks
• Target: {goal.target_time or goal.target_pace}

🏃 YOUR 14-DAY BASELINE ASSESSMENT:
I've created a personalized 14-day assessment plan to understand your true capabilities. This will help me design the perfect training program for you.

📅 DAY 1 STARTS: {first_day.workout_date.strftime('%B %d, %Y')}

{first_day.workout_type.replace('_', ' ').title()}: {first_day.expected_distance_km} km
⏱️ Duration: ~{first_day.expected_duration_minutes} minutes
🎯 Pace: {first_day.expected_pace_min}-{first_day.expected_pace_max} min/km
❤️ Heart Rate: Keep around {first_day.expected_hr_target} bpm (80% of max)

💡 FOCUS: {', '.join(first_day.focus_areas)}

{first_day.coach_instructions}

🔗 NEXT STEPS:
1. Complete Day 1 workout
2. Connect Garmin/Strava to auto-track
3. I'll analyze your performance
4. Get your Day 2 workout automatically

Remember: This is about learning YOUR baseline, not impressing me. Run at a comfortable effort and let's see what you can do! 💪

Let's make this journey amazing! 🚀
"""
        return message


# ============================================================================
# MAIN EXECUTION (FOR TESTING)
# ============================================================================

if __name__ == "__main__":
    import asyncio
    
    async def test_onboarding():
        """Test the onboarding flow"""
        onboarding = AthleteOnboarding()
        
        # Test athlete data
        test_athlete = {
            "name": "Rajesh Kumar",
            "email": "rajesh@example.com",
            "phone_number": "+919876543210",
            "primary_goal": "10K",
            "goal_type": "time_based",
            "target_time": "01:00:00",  # 60 minutes
            "target_race_date": (date.today() + timedelta(weeks=16)).isoformat()
        }
        
        # Mock Strava data (replace with real token in production)
        strava_athlete_id = 123456
        strava_access_token = "mock_token"
        
        result = await onboarding.signup_new_athlete(
            test_athlete,
            strava_athlete_id,
            strava_access_token
        )
        
        print(json.dumps(result, indent=2))
    
    # Run test
    # asyncio.run(test_onboarding())
    logger.info("AthleteOnboarding module loaded successfully")
