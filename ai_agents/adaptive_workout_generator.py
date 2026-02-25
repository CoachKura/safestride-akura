"""
Adaptive Workout Generator
Intelligently generates next workout based on recent performance and ability progression.

Key Features:
- Progressive overload (safe 5-10% increases)
- HR zone optimization (target 80% max HR for aerobic training)
- Injury prevention checks (ACWR, load management)
- Adaptation based on performance labels (BEST/GREAT/GOOD/FAIR/POOR)
- Training phase awareness (foundation, base, build, peak)
- Workout type rotation (easy, intervals, tempo, long run)
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from enum import Enum
import statistics


class TrainingPhase(Enum):
    """Training phases"""
    FOUNDATION = "foundation"  # Weeks 1-12: Strength/mobility focus
    BASE_BUILD = "base_build"  # Weeks 13-20: Aerobic base
    SPEED_BUILD = "speed_build"  # Weeks 21-32: Add speed work
    RACE_PREP = "race_prep"  # Weeks 33-38: Race-specific
    TAPER = "taper"  # Final 2 weeks before race
    RECOVERY = "recovery"  # Post-race recovery


class LoadTrend(Enum):
    """Load management trends"""
    INCREASING = "increasing"
    STABLE = "stable"
    DECREASING = "decreasing"
    RECOVERY_WEEK = "recovery_week"


@dataclass
class AthleteAbility:
    """Current athlete ability/fitness level"""
    current_pace_easy: int  # sec/km for easy runs
    current_pace_tempo: int  # sec/km for tempo runs
    current_pace_interval: int  # sec/km for intervals
    max_hr: int  # Maximum heart rate
    threshold_hr: int  # Lactate threshold HR (typically 85-90% max)
    aerobic_hr: int  # Aerobic zone HR (typically 75-82% max)
    weekly_volume_km: float  # Current weekly volume
    longest_run_km: float  # Current longest run capability
    fitness_score: float  # 0-100 overall fitness


@dataclass
class PerformanceHistory:
    """Recent performance history"""
    last_7_days: List[str]  # Performance labels: BEST/GREAT/GOOD/FAIR/POOR
    last_4_weeks_volume: List[float]  # Weekly volume in km
    last_3_workouts: List[Dict]  # Recent workout details
    consecutive_good_performances: int  # Streak of GREAT/BEST
    fatigue_indicators: List[str]  # Recent fatigue signals
    injury_risk_score: float  # 0-100 (higher = more risk)


@dataclass
class InjuryPreventionMetrics:
    """Injury prevention calculations"""
    acute_load: float  # Last 7 days load
    chronic_load: float  # Last 28 days load (avg)
    acwr: float  # Acute:Chronic Workload Ratio
    load_status: str  # "safe", "caution", "high_risk"
    recommended_max_increase_pct: float  # Max safe increase %
    recovery_week_needed: bool


@dataclass
class GeneratedWorkout:
    """Generated workout prescription"""
    workout_date: datetime
    workout_type: str  # easy/long/interval/tempo/threshold/recovery/strength/mobility
    distance_km: float
    target_pace_seconds: Optional[int] = None
    pace_range_seconds: Tuple[int, int] = (0, 0)
    target_hr: Optional[int] = None
    hr_range: Tuple[int, int] = (0, 0)
    
    # Interval details
    intervals: Optional[int] = None
    interval_distance_m: Optional[int] = None
    interval_pace_seconds: Optional[int] = None
    rest_time_seconds: Optional[int] = None
    
    # Workout notes
    workout_notes: str = ""
    coaching_cues: List[str] = None
    
    # Load management
    expected_load: float = 0.0
    progressive_increase_pct: float = 0.0
    acwr_after_workout: float = 0.0
    
    # Rationale
    generation_rationale: str = ""


class AdaptiveWorkoutGenerator:
    """
    Generates intelligent, adaptive workouts based on athlete ability and recent performance.
    
    Implements:
    - Progressive overload (5-10% safe increases)
    - ACWR monitoring (keep between 0.8-1.3)
    - Performance-based adaptation
    - Training phase progression
    - Injury prevention
    """
    
    def __init__(self):
        """Initialize workout generator"""
        # Safe ACWR ranges
        self.acwr_safe_min = 0.8
        self.acwr_safe_max = 1.3
        self.acwr_optimal = 1.0
        
        # Progressive overload limits
        self.max_increase_pct = 10.0  # Never increase more than 10%
        self.default_increase_pct = 5.0  # Default safe increase
        
        # Recovery week frequency
        self.recovery_week_frequency = 3  # Every 3-4 weeks
    
    def generate_next_workout(
        self,
        athlete_ability: AthleteAbility,
        performance_history: PerformanceHistory,
        training_phase: TrainingPhase,
        week_number: int,
        day_of_week: int,  # 1=Monday, 7=Sunday
        weekly_plan_structure: Optional[Dict] = None
    ) -> GeneratedWorkout:
        """
        Generate next workout based on athlete state and training context.
        
        Args:
            athlete_ability: Current fitness/ability levels
            performance_history: Recent performance data
            training_phase: Current training phase
            week_number: Week number in training plan
            day_of_week: Day of week (1=Mon, 7=Sun)
            weekly_plan_structure: Optional weekly structure override
            
        Returns:
            Generated workout with all parameters
        """
        # Check injury prevention metrics
        injury_metrics = self._calculate_injury_prevention_metrics(
            performance_history, athlete_ability.weekly_volume_km
        )
        
        # Determine if recovery week needed
        is_recovery_week = self._check_recovery_week_needed(
            week_number, injury_metrics, performance_history
        )
        
        # Get base workout type for this day
        workout_type = self._determine_workout_type(
            day_of_week, training_phase, is_recovery_week, weekly_plan_structure
        )
        
        # Determine progressive increase based on recent performance
        increase_pct = self._calculate_progressive_increase(
            performance_history, injury_metrics, is_recovery_week
        )
        
        # Generate workout based on type
        if workout_type == "easy":
            workout = self._generate_easy_run(
                athlete_ability, increase_pct, injury_metrics
            )
        elif workout_type == "long":
            workout = self._generate_long_run(
                athlete_ability, increase_pct, injury_metrics, training_phase
            )
        elif workout_type == "interval":
            workout = self._generate_interval_workout(
                athlete_ability, training_phase, injury_metrics
            )
        elif workout_type == "tempo":
            workout = self._generate_tempo_run(
                athlete_ability, training_phase, injury_metrics
            )
        elif workout_type == "threshold":
            workout = self._generate_threshold_run(
                athlete_ability, training_phase, injury_metrics
            )
        elif workout_type == "recovery":
            workout = self._generate_recovery_run(
                athlete_ability, injury_metrics
            )
        elif workout_type == "strength":
            workout = self._generate_strength_session(
                training_phase, week_number
            )
        elif workout_type == "mobility":
            workout = self._generate_mobility_session(
                training_phase, week_number
            )
        else:
            # Default to easy run
            workout = self._generate_easy_run(
                athlete_ability, increase_pct, injury_metrics
            )
        
        # Set workout date and load calculations
        workout.workout_date = datetime.now() + timedelta(days=1)
        workout.expected_load = self._calculate_workout_load(workout)
        workout.progressive_increase_pct = increase_pct
        workout.acwr_after_workout = self._project_acwr_after_workout(
            injury_metrics, workout.expected_load
        )
        
        # Generate rationale
        workout.generation_rationale = self._generate_rationale(
            workout_type, increase_pct, performance_history, injury_metrics, training_phase
        )
        
        return workout
    
    def _calculate_injury_prevention_metrics(
        self,
        history: PerformanceHistory,
        current_volume: float
    ) -> InjuryPreventionMetrics:
        """Calculate ACWR and injury prevention metrics"""
        
        # Acute load (last 7 days)
        if len(history.last_4_weeks_volume) >= 1:
            acute_load = history.last_4_weeks_volume[-1]  # Last week
        else:
            acute_load = current_volume
        
        # Chronic load (average of last 4 weeks)
        if len(history.last_4_weeks_volume) >= 4:
            chronic_load = sum(history.last_4_weeks_volume) / len(history.last_4_weeks_volume)
        elif len(history.last_4_weeks_volume) > 0:
            chronic_load = sum(history.last_4_weeks_volume) / len(history.last_4_weeks_volume)
        else:
            chronic_load = current_volume
        
        # ACWR calculation
        if chronic_load > 0:
            acwr = acute_load / chronic_load
        else:
            acwr = 1.0
        
        # Determine load status
        if acwr < self.acwr_safe_min:
            load_status = "caution"  # Undertraining
            recommended_increase = 10.0
        elif acwr <= self.acwr_safe_max:
            load_status = "safe"
            recommended_increase = 8.0
        else:
            load_status = "high_risk"  # Overtraining
            recommended_increase = 0.0  # No increase
        
        # Check if recovery week needed
        recovery_needed = (
            acwr > 1.2 or
            history.injury_risk_score > 60 or
            len([p for p in history.last_7_days if p in ["POOR", "INCOMPLETE"]]) >= 2
        )
        
        return InjuryPreventionMetrics(
            acute_load=acute_load,
            chronic_load=chronic_load,
            acwr=acwr,
            load_status=load_status,
            recommended_max_increase_pct=recommended_increase,
            recovery_week_needed=recovery_needed
        )
    
    def _check_recovery_week_needed(
        self,
        week_number: int,
        injury_metrics: InjuryPreventionMetrics,
        history: PerformanceHistory
    ) -> bool:
        """Check if this should be a recovery week"""
        
        # Every 3-4 weeks, schedule recovery
        if week_number % 4 == 0:
            return True
        
        # Force recovery if injury prevention metrics indicate
        if injury_metrics.recovery_week_needed:
            return True
        
        # Check fatigue indicators
        if len(history.fatigue_indicators) >= 3:
            return True
        
        return False
    
    def _determine_workout_type(
        self,
        day_of_week: int,
        training_phase: TrainingPhase,
        is_recovery_week: bool,
        weekly_structure: Optional[Dict]
    ) -> str:
        """Determine workout type for this day"""
        
        # Use custom weekly structure if provided
        if weekly_structure and day_of_week in weekly_structure:
            return weekly_structure[day_of_week]
        
        # Default structure based on training phase
        if is_recovery_week:
            # Recovery week: all easy runs + strength/mobility
            structure = {
                1: "rest",  # Monday: Rest
                2: "easy",  # Tuesday: Easy
                3: "mobility",  # Wednesday: Mobility
                4: "easy",  # Thursday: Easy
                5: "strength",  # Friday: Strength
                6: "easy",  # Saturday: Easy
                7: "long"  # Sunday: Long run (reduced volume)
            }
        elif training_phase == TrainingPhase.FOUNDATION:
            # Foundation: Focus on volume, strength, mobility
            structure = {
                1: "strength",  # Monday: Strength
                2: "easy",  # Tuesday: Easy
                3: "mobility",  # Wednesday: Mobility
                4: "easy",  # Thursday: Easy
                5: "strength",  # Friday: Strength
                6: "strength",  # Saturday: Strength (alternating long run)
                7: "long"  # Sunday: Long run
            }
        elif training_phase == TrainingPhase.BASE_BUILD:
            # Base building: Aerobic focus
            structure = {
                1: "easy",  # Monday: Easy + Strength
                2: "easy",  # Tuesday: Easy
                3: "mobility",  # Wednesday: Mobility + easy
                4: "tempo",  # Thursday: Tempo
                5: "strength",  # Friday: Strength
                6: "easy",  # Saturday: Easy (alternating long run)
                7: "long"  # Sunday: Long run
            }
        elif training_phase == TrainingPhase.SPEED_BUILD:
            # Speed building: Add intervals
            structure = {
                1: "easy",  # Monday: Easy + Strength
                2: "interval",  # Tuesday: Intervals
                3: "mobility",  # Wednesday: Mobility
                4: "tempo",  # Thursday: Tempo/Threshold
                5: "strength",  # Friday: Strength
                6: "strength",  # Saturday: Strength (alternating long)
                7: "long"  # Sunday: Long run
            }
        elif training_phase == TrainingPhase.RACE_PREP:
            # Race prep: Race-specific workouts
            structure = {
                1: "easy",  # Monday: Easy
                2: "interval",  # Tuesday: Race pace intervals
                3: "mobility",  # Wednesday: Mobility
                4: "threshold",  # Thursday: Threshold
                5: "strength",  # Friday: Strength
                6: "easy",  # Saturday: Easy
                7: "long"  # Sunday: Long run at marathon pace
            }
        elif training_phase == TrainingPhase.TAPER:
            # Taper: Reduce volume, maintain intensity
            structure = {
                1: "rest",  # Monday: Rest
                2: "easy",  # Tuesday: Easy with strides
                3: "rest",  # Wednesday: Rest
                4: "easy",  # Thursday: Easy
                5: "rest",  # Friday: Rest
                6: "easy",  # Saturday: Easy shakeout
                7: "race"  # Sunday: RACE DAY!
            }
        else:
            # Default structure
            structure = {
                1: "easy",
                2: "easy",
                3: "mobility",
                4: "easy",
                5: "strength",
                6: "easy",
                7: "long"
            }
        
        return structure.get(day_of_week, "easy")
    
    def _calculate_progressive_increase(
        self,
        history: PerformanceHistory,
        injury_metrics: InjuryPreventionMetrics,
        is_recovery_week: bool
    ) -> float:
        """Calculate safe progressive increase percentage"""
        
        # Recovery week: reduce volume by 20-30%
        if is_recovery_week:
            return -25.0
        
        # High injury risk: no increase
        if injury_metrics.load_status == "high_risk":
            return 0.0
        
        # Count recent good performances
        recent_great = len([p for p in history.last_7_days if p in ["BEST", "GREAT"]])
        recent_poor = len([p for p in history.last_7_days if p in ["POOR", "INCOMPLETE"]])
        
        # Adjust increase based on performance
        if recent_poor >= 2:
            # Multiple poor performances: no increase
            return 0.0
        elif recent_poor == 1:
            # One poor performance: small increase
            return 3.0
        elif recent_great >= 5:
            # Consistently great: larger increase
            return min(10.0, injury_metrics.recommended_max_increase_pct)
        elif recent_great >= 3:
            # Good trend: normal increase
            return min(7.0, injury_metrics.recommended_max_increase_pct)
        else:
            # Mixed performance: conservative increase
            return min(5.0, injury_metrics.recommended_max_increase_pct)
    
    def _generate_easy_run(
        self,
        ability: AthleteAbility,
        increase_pct: float,
        injury_metrics: InjuryPreventionMetrics
    ) -> GeneratedWorkout:
        """Generate easy run workout"""
        
        # Base distance (40% of weekly volume as avg easy run)
        base_distance = ability.weekly_volume_km * 0.12  # ~3 easy runs per week
        
        # Apply progressive increase
        distance = base_distance * (1 + increase_pct / 100)
        distance = round(distance * 2) / 2  # Round to 0.5 km
        distance = max(5.0, min(15.0, distance))  # Clamp 5-15 km
        
        # Pace: Easy pace (aerobic zone)
        target_pace = ability.current_pace_easy
        pace_range = (target_pace - 10, target_pace + 15)  # Allow slower
        
        # HR: Aerobic zone (75-82% max HR)
        target_hr = ability.aerobic_hr
        hr_range = (int(ability.max_hr * 0.75), int(ability.max_hr * 0.82))
        
        coaching_cues = [
            "Keep it conversational - should be able to talk in full sentences",
            "Focus on time on feet, not pace",
            f"Check HR at 3 km - should be around {target_hr} bpm",
            "If HR creeps above 82%, slow down"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="easy",
            distance_km=distance,
            target_pace_seconds=target_pace,
            pace_range_seconds=pace_range,
            target_hr=target_hr,
            hr_range=hr_range,
            workout_notes=f"Easy aerobic run. Focus on building base endurance.",
            coaching_cues=coaching_cues
        )
    
    def _generate_long_run(
        self,
        ability: AthleteAbility,
        increase_pct: float,
        injury_metrics: InjuryPreventionMetrics,
        training_phase: TrainingPhase
    ) -> GeneratedWorkout:
        """Generate long run workout"""
        
        # Long run: 30-35% of weekly volume
        base_distance = ability.longest_run_km
        
        # Apply progressive increase (but cap at 10% for long runs)
        if increase_pct > 10:
            increase_pct = 10.0
        
        distance = base_distance * (1 + increase_pct / 100)
        distance = round(distance)  # Round to whole km
        
        # Cap at safe limits based on phase
        if training_phase == TrainingPhase.FOUNDATION:
            distance = min(distance, 18.0)
        elif training_phase == TrainingPhase.BASE_BUILD:
            distance = min(distance, 22.0)
        else:
            distance = min(distance, 32.0)
        
        # Pace: Slightly slower than easy pace
        target_pace = ability.current_pace_easy + 15
        pace_range = (target_pace - 10, target_pace + 20)
        
        # HR: Low aerobic zone
        target_hr = int(ability.max_hr * 0.75)
        hr_range = (int(ability.max_hr * 0.70), int(ability.max_hr * 0.80))
        
        coaching_cues = [
            "Start SLOW - first 3 km should feel too easy",
            f"Target HR: {target_hr} bpm (70-80% max)",
            "Focus on mental toughness in final 5 km",
            "Take water/fuel if run > 90 minutes"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="long",
            distance_km=distance,
            target_pace_seconds=target_pace,
            pace_range_seconds=pace_range,
            target_hr=target_hr,
            hr_range=hr_range,
            workout_notes=f"Long run for endurance. Primary focus: time on feet.",
            coaching_cues=coaching_cues
        )
    
    def _generate_interval_workout(
        self,
        ability: AthleteAbility,
        training_phase: TrainingPhase,
        injury_metrics: InjuryPreventionMetrics
    ) -> GeneratedWorkout:
        """Generate interval workout"""
        
        # Warm-up + intervals + cooldown
        warmup = 2.0
        cooldown = 2.0
        
        # Interval structure based on phase
        if training_phase == TrainingPhase.SPEED_BUILD:
            # Early speed work: shorter intervals
            intervals = 8
            interval_distance = 400
            rest_time = 90
        else:  # RACE_PREP
            # Race prep: longer intervals
            intervals = 6
            interval_distance = 800
            rest_time = 120
        
        # Total interval distance in km
        interval_km = (intervals * interval_distance) / 1000
        total_distance = warmup + interval_km + cooldown
        
        # Interval pace: 90-95% of 5K pace (roughly)
        interval_pace = ability.current_pace_interval
        
        # HR: Should hit 85-92% max during intervals
        target_hr = int(ability.max_hr * 0.88)
        hr_range = (int(ability.max_hr * 0.85), int(ability.max_hr * 0.92))
        
        coaching_cues = [
            f"2 km easy warm-up, then {intervals} × {interval_distance}m",
            f"Target pace for intervals: {self._seconds_to_pace_str(interval_pace)}/km",
            f"Rest {rest_time} seconds between intervals (walk/jog)",
            "First interval should feel controlled, not all-out",
            "Maintain consistent pace across all intervals",
            "2 km easy cooldown"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="interval",
            distance_km=total_distance,
            target_pace_seconds=interval_pace,
            pace_range_seconds=(interval_pace - 5, interval_pace + 5),
            target_hr=target_hr,
            hr_range=hr_range,
            intervals=intervals,
            interval_distance_m=interval_distance,
            interval_pace_seconds=interval_pace,
            rest_time_seconds=rest_time,
            workout_notes=f"Interval session for speed development.",
            coaching_cues=coaching_cues
        )
    
    def _generate_tempo_run(
        self,
        ability: AthleteAbility,
        training_phase: TrainingPhase,
        injury_metrics: InjuryPreventionMetrics
    ) -> GeneratedWorkout:
        """Generate tempo run workout"""
        
        # Tempo: "comfortably hard" pace (roughly marathon pace + 10-15 sec/km)
        tempo_pace = ability.current_pace_tempo
        
        # Tempo distance based on phase
        if training_phase == TrainingPhase.BASE_BUILD:
            tempo_km = 6.0
        elif training_phase == TrainingPhase.SPEED_BUILD:
            tempo_km = 8.0
        else:  # RACE_PREP
            tempo_km = 10.0
        
        # Warm-up + tempo + cooldown
        warmup = 2.0
        cooldown = 2.0
        total_distance = warmup + tempo_km + cooldown
        
        # HR: Threshold zone (85-90% max)
        target_hr = ability.threshold_hr
        hr_range = (int(ability.max_hr * 0.85), int(ability.max_hr * 0.90))
        
        coaching_cues = [
            "2 km easy warm-up",
            f"{tempo_km} km at tempo pace: {self._seconds_to_pace_str(tempo_pace)}/km",
            "Tempo should feel 'comfortably hard' - can speak a few words",
            f"Target HR: {target_hr} bpm (85-90% max)",
            "Maintain steady effort, don't start too fast",
            "2 km easy cooldown"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="tempo",
            distance_km=total_distance,
            target_pace_seconds=tempo_pace,
            pace_range_seconds=(tempo_pace - 5, tempo_pace + 10),
            target_hr=target_hr,
            hr_range=hr_range,
            workout_notes=f"Tempo run for lactate threshold development.",
            coaching_cues=coaching_cues
        )
    
    def _generate_threshold_run(
        self,
        ability: AthleteAbility,
        training_phase: TrainingPhase,
        injury_metrics: InjuryPreventionMetrics
    ) -> GeneratedWorkout:
        """Generate threshold run workout"""
        
        # Threshold pace: Slightly faster than tempo (roughly half marathon pace)
        threshold_pace = ability.current_pace_tempo - 10
        
        # Threshold distance
        threshold_km = 8.0
        
        # Warm-up + threshold + cooldown
        warmup = 2.0
        cooldown = 2.0
        total_distance = warmup + threshold_km + cooldown
        
        # HR: High threshold (88-92% max)
        target_hr = int(ability.max_hr * 0.90)
        hr_range = (int(ability.max_hr * 0.88), int(ability.max_hr * 0.92))
        
        coaching_cues = [
            "2 km easy warm-up",
            f"{threshold_km} km at threshold pace: {self._seconds_to_pace_str(threshold_pace)}/km",
            "This should feel HARD - 'comfortably uncomfortable'",
            f"Target HR: {target_hr} bpm (88-92% max)",
            "Can only speak 1-2 words at this effort",
            "2 km easy cooldown"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="threshold",
            distance_km=total_distance,
            target_pace_seconds=threshold_pace,
            pace_range_seconds=(threshold_pace - 5, threshold_pace + 5),
            target_hr=target_hr,
            hr_range=hr_range,
            workout_notes=f"Threshold run for race pace development.",
            coaching_cues=coaching_cues
        )
    
    def _generate_recovery_run(
        self,
        ability: AthleteAbility,
        injury_metrics: InjuryPreventionMetrics
    ) -> GeneratedWorkout:
        """Generate recovery run workout"""
        
        # Very short, very easy
        distance = 5.0
        
        # Pace: Very easy (20-30 sec/km slower than easy)
        recovery_pace = ability.current_pace_easy + 25
        pace_range = (recovery_pace - 10, recovery_pace + 30)
        
        # HR: Very low (65-75% max)
        target_hr = int(ability.max_hr * 0.70)
        hr_range = (int(ability.max_hr * 0.65), int(ability.max_hr * 0.75))
        
        coaching_cues = [
            "This should feel TOO EASY",
            "If in doubt, go slower",
            "HR should stay below 75% max",
            "Focus: active recovery, not training stress"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="recovery",
            distance_km=distance,
            target_pace_seconds=recovery_pace,
            pace_range_seconds=pace_range,
            target_hr=target_hr,
            hr_range=hr_range,
            workout_notes="Recovery run - extremely easy pace.",
            coaching_cues=coaching_cues
        )
    
    def _generate_strength_session(
        self,
        training_phase: TrainingPhase,
        week_number: int
    ) -> GeneratedWorkout:
        """Generate strength training session"""
        
        if training_phase == TrainingPhase.FOUNDATION:
            focus = "Foundation strength: squats, deadlifts, planks, single-leg work"
            duration = 60
        else:
            focus = "Maintenance strength: focus on glutes, core, stability"
            duration = 45
        
        coaching_cues = [
            "Warm-up: 10 min dynamic stretches",
            "Focus areas: glutes, core, single-leg stability",
            "3 sets × 12 reps for main lifts",
            "Include: squats, lunges, planks, bridges",
            "Cool-down: 10 min stretching"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="strength",
            distance_km=0.0,
            workout_notes=f"{focus} ({duration} min session)",
            coaching_cues=coaching_cues
        )
    
    def _generate_mobility_session(
        self,
        training_phase: TrainingPhase,
        week_number: int
    ) -> GeneratedWorkout:
        """Generate mobility session"""
        
        if training_phase == TrainingPhase.FOUNDATION:
            focus = "Hip flexors, ankles, hamstrings, thoracic spine"
            duration = 40
        else:
            focus = "Maintenance mobility: hip flexors, ankles"
            duration = 30
        
        coaching_cues = [
            "Focus: hip flexor stretches (hold 2 min each side)",
            "Ankle dorsiflexion work",
            "Hamstring stretching",
            "Thoracic spine rotation",
            "Foam rolling: quads, IT band, calves"
        ]
        
        return GeneratedWorkout(
            workout_date=datetime.now(),
            workout_type="mobility",
            distance_km=0.0,
            workout_notes=f"Mobility session: {focus} ({duration} min)",
            coaching_cues=coaching_cues
        )
    
    def _calculate_workout_load(self, workout: GeneratedWorkout) -> float:
        """Calculate training load for a workout"""
        
        # Simple load calculation: distance × intensity factor
        if workout.workout_type in ["easy", "recovery"]:
            intensity = 1.0
        elif workout.workout_type == "long":
            intensity = 1.2
        elif workout.workout_type in ["tempo", "threshold"]:
            intensity = 1.8
        elif workout.workout_type == "interval":
            intensity = 2.0
        elif workout.workout_type in ["strength", "mobility"]:
            intensity = 0.8  # Lower running load
        else:
            intensity = 1.0
        
        load = workout.distance_km * intensity
        return round(load, 1)
    
    def _project_acwr_after_workout(
        self,
        injury_metrics: InjuryPreventionMetrics,
        new_workout_load: float
    ) -> float:
        """Project ACWR after this workout"""
        
        # New acute load (add this workout to last 7 days)
        new_acute = injury_metrics.acute_load + new_workout_load
        
        # Chronic stays same (4-week average)
        chronic = injury_metrics.chronic_load
        
        if chronic > 0:
            projected_acwr = new_acute / chronic
        else:
            projected_acwr = 1.0
        
        return round(projected_acwr, 2)
    
    def _generate_rationale(
        self,
        workout_type: str,
        increase_pct: float,
        history: PerformanceHistory,
        injury_metrics: InjuryPreventionMetrics,
        training_phase: TrainingPhase
    ) -> str:
        """Generate explanation for workout generation"""
        
        rationale_parts = []
        
        # Phase context
        rationale_parts.append(f"Training phase: {training_phase.value}")
        
        # Progressive increase rationale
        if increase_pct > 0:
            rationale_parts.append(
                f"Progressive increase: +{increase_pct:.1f}% (based on {history.consecutive_good_performances} "
                f"recent good performances)"
            )
        elif increase_pct < 0:
            rationale_parts.append(
                f"Recovery week: {increase_pct:.1f}% reduction for adaptation"
            )
        else:
            rationale_parts.append("Maintaining current load (recent mixed performance or high ACWR)")
        
        # ACWR status
        rationale_parts.append(
            f"ACWR: {injury_metrics.acwr:.2f} ({injury_metrics.load_status})"
        )
        
        # Workout type rationale
        if workout_type == "interval":
            rationale_parts.append("Interval work for speed development")
        elif workout_type == "tempo":
            rationale_parts.append("Tempo run for lactate threshold improvement")
        elif workout_type == "long":
            rationale_parts.append("Long run for aerobic endurance")
        elif workout_type == "easy":
            rationale_parts.append("Easy run for base building and recovery")
        
        return " | ".join(rationale_parts)
    
    def _seconds_to_pace_str(self, seconds: int) -> str:
        """Convert seconds to pace string"""
        minutes = seconds // 60
        secs = seconds % 60
        return f"{minutes}:{secs:02d}"


def print_generated_workout(workout: GeneratedWorkout):
    """Pretty print generated workout"""
    
    print("\n" + "="*80)
    print("GENERATED WORKOUT")
    print("="*80)
    
    print(f"\n📅 Date: {workout.workout_date.strftime('%Y-%m-%d')}")
    print(f"🏃 Type: {workout.workout_type.upper()}")
    
    if workout.distance_km > 0:
        print(f"📏 Distance: {workout.distance_km:.1f} km")
    
    if workout.target_pace_seconds:
        pace_str = f"{workout.target_pace_seconds // 60}:{workout.target_pace_seconds % 60:02d}"
        print(f"⏱️ Target Pace: {pace_str}/km")
        if workout.pace_range_seconds != (0, 0):
            min_pace = f"{workout.pace_range_seconds[0] // 60}:{workout.pace_range_seconds[0] % 60:02d}"
            max_pace = f"{workout.pace_range_seconds[1] // 60}:{workout.pace_range_seconds[1] % 60:02d}"
            print(f"   Acceptable Range: {min_pace}-{max_pace}/km")
    
    if workout.target_hr:
        print(f"❤️ Target HR: {workout.target_hr} bpm")
        if workout.hr_range != (0, 0):
            print(f"   Acceptable Range: {workout.hr_range[0]}-{workout.hr_range[1]} bpm")
    
    if workout.intervals:
        print(f"\n🔄 Intervals:")
        print(f"   {workout.intervals} × {workout.interval_distance_m}m")
        interval_pace_str = f"{workout.interval_pace_seconds // 60}:{workout.interval_pace_seconds % 60:02d}"
        print(f"   Target Pace: {interval_pace_str}/km")
        print(f"   Rest: {workout.rest_time_seconds} seconds")
    
    print(f"\n📝 Workout Notes:")
    print(f"   {workout.workout_notes}")
    
    if workout.coaching_cues:
        print(f"\n💬 Coaching Cues:")
        for cue in workout.coaching_cues:
            print(f"   • {cue}")
    
    print(f"\n📊 Load Management:")
    print(f"   Expected Load: {workout.expected_load:.1f}")
    print(f"   Progressive Increase: {workout.progressive_increase_pct:+.1f}%")
    print(f"   Projected ACWR: {workout.acwr_after_workout:.2f}")
    
    print(f"\n🧠 Generation Rationale:")
    print(f"   {workout.generation_rationale}")
    
    print("\n" + "="*80 + "\n")


# Example usage
if __name__ == "__main__":
    # Example: Generate workout for intermediate runner
    generator = AdaptiveWorkoutGenerator()
    
    # Define athlete ability
    athlete = AthleteAbility(
        current_pace_easy=405,  # 6:45/km
        current_pace_tempo=360,  # 6:00/km
        current_pace_interval=340,  # 5:40/km
        max_hr=185,
        threshold_hr=167,  # 90% max
        aerobic_hr=148,  # 80% max
        weekly_volume_km=40.0,
        longest_run_km=16.0,
        fitness_score=65.0
    )
    
    # Recent performance history (good trend)
    history = PerformanceHistory(
        last_7_days=["GREAT", "GOOD", "BEST", "GREAT", "GOOD", "GREAT", "BEST"],
        last_4_weeks_volume=[35.0, 38.0, 40.0, 40.0],
        last_3_workouts=[],
        consecutive_good_performances=6,
        fatigue_indicators=[],
        injury_risk_score=25.0
    )
    
    print("="*80)
    print("EXAMPLE 1: Interval Workout (Speed Build Phase, Tuesday)")
    print("="*80)
    
    # Generate Tuesday interval workout
    workout1 = generator.generate_next_workout(
        athlete_ability=athlete,
        performance_history=history,
        training_phase=TrainingPhase.SPEED_BUILD,
        week_number=24,
        day_of_week=2  # Tuesday
    )
    
    print_generated_workout(workout1)
    
    print("\n" + "="*80)
    print("EXAMPLE 2: Long Run (Sunday)")
    print("="*80)
    
    # Generate Sunday long run
    workout2 = generator.generate_next_workout(
        athlete_ability=athlete,
        performance_history=history,
        training_phase=TrainingPhase.SPEED_BUILD,
        week_number=24,
        day_of_week=7  # Sunday
    )
    
    print_generated_workout(workout2)
    
    print("\n" + "="*80)
    print("EXAMPLE 3: Recovery Week (Poor recent performance)")
    print("="*80)
    
    # Poor performance history
    poor_history = PerformanceHistory(
        last_7_days=["FAIR", "POOR", "FAIR", "INCOMPLETE", "FAIR", "POOR", "FAIR"],
        last_4_weeks_volume=[40.0, 45.0, 48.0, 52.0],  # Rapidly increasing
        last_3_workouts=[],
        consecutive_good_performances=0,
        fatigue_indicators=["Elevated resting HR", "Poor sleep", "Muscle soreness"],
        injury_risk_score=75.0
    )
    
    # Generate easy run for recovery week
    workout3 = generator.generate_next_workout(
        athlete_ability=athlete,
        performance_history=poor_history,
        training_phase=TrainingPhase.SPEED_BUILD,
        week_number=28,  # Recovery week
        day_of_week=2
    )
    
    print_generated_workout(workout3)
