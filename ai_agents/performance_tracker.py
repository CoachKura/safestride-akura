"""
Performance Tracker Module
Daily workout tracking system with GIVEN|EXPECTED|RESULT analysis.

Tracks athlete performance against prescribed workouts:
- GIVEN: Assigned workout (distance, pace, HR targets, intervals)
- EXPECTED: Performance ranges (acceptable deviations)
- RESULT: Actual from Strava/Garmin sync
- LABEL: Performance classification (BEST/GREAT/GOOD/FAIR/POOR)

Updates ability_progression table and provides feedback.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from enum import Enum
import statistics


class WorkoutType(Enum):
    """Types of workouts"""
    EASY_RUN = "easy"
    LONG_RUN = "long"
    INTERVAL = "interval"
    TEMPO = "tempo"
    THRESHOLD = "threshold"
    RECOVERY = "recovery"
    RACE = "race"
    STRENGTH = "strength"
    MOBILITY = "mobility"


class PerformanceLabel(Enum):
    """Performance classification labels"""
    BEST = "BEST"  # Exceeded expectations significantly
    GREAT = "GREAT"  # Slightly exceeded expectations
    GOOD = "GOOD"  # Met expectations
    FAIR = "FAIR"  # Slightly below expectations
    POOR = "POOR"  # Significantly below expectations
    INCOMPLETE = "INCOMPLETE"  # Workout not completed


@dataclass
class WorkoutTarget:
    """Target/prescribed workout parameters"""
    workout_type: WorkoutType
    distance_km: float
    target_pace_seconds: Optional[int] = None  # Per km
    pace_range_seconds: Tuple[int, int] = (0, 0)  # (min, max) per km
    target_hr: Optional[int] = None
    hr_range: Tuple[int, int] = (0, 0)  # (min, max)
    intervals: Optional[int] = None  # Number of intervals
    interval_distance_m: Optional[int] = None  # Distance per interval
    interval_pace_seconds: Optional[int] = None  # Target pace per km
    rest_time_seconds: Optional[int] = None  # Rest between intervals
    notes: str = ""


@dataclass
class WorkoutResult:
    """Actual workout results from Strava/Garmin"""
    workout_id: str
    completed_date: datetime
    distance_km: float
    total_time_seconds: int
    avg_pace_seconds: int  # Per km
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    elevation_gain_m: Optional[int] = None
    splits: Optional[List[int]] = None  # Pace per km
    hr_zones: Optional[Dict[int, int]] = None  # Zone: seconds
    completed_full: bool = True
    stopped_at_km: Optional[float] = None


@dataclass
class ExpectedPerformance:
    """Expected performance ranges"""
    distance_tolerance_km: float = 0.5  # ±0.5 km acceptable
    pace_tolerance_seconds: int = 10  # ±10 sec/km acceptable
    hr_tolerance_bpm: int = 5  # ±5 bpm acceptable
    completion_required: bool = True
    
    # For intervals
    interval_consistency_tolerance: float = 0.10  # 10% variance acceptable


@dataclass
class PerformanceComparison:
    """Comparison of target vs actual"""
    distance_variance_km: float
    distance_variance_pct: float
    pace_variance_seconds: int
    pace_variance_pct: float
    hr_variance_bpm: Optional[int] = None
    hr_variance_pct: Optional[float] = None
    
    # Interval-specific
    interval_consistency_variance: Optional[float] = None
    
    # Overall
    distance_met: bool = False
    pace_met: bool = False
    hr_met: bool = False
    workout_completed: bool = True


@dataclass
class PerformanceAssessment:
    """Complete performance assessment"""
    workout_date: datetime
    workout_type: WorkoutType
    performance_label: PerformanceLabel
    
    # What was given/expected/result
    given: WorkoutTarget
    expected: ExpectedPerformance
    result: WorkoutResult
    comparison: PerformanceComparison
    
    # Scores (0-100)
    distance_score: float
    pace_score: float
    hr_score: float
    overall_score: float
    
    # Feedback
    strengths: List[str]
    weaknesses: List[str]
    key_feedback: List[str]
    coach_notes: str
    
    # Progress tracking
    ability_change: float  # Change in ability score
    readiness_for_progression: bool  # Ready to increase load?
    fatigue_level: str  # low/moderate/high
    injury_risk_indicators: List[str]


class PerformanceTracker:
    """
    Track athlete performance against prescribed workouts.
    
    Analyzes GIVEN vs EXPECTED vs RESULT to classify performance
    and provide actionable feedback.
    """
    
    def __init__(self):
        """Initialize performance tracker"""
        pass
    
    def assess_workout_performance(
        self,
        given: WorkoutTarget,
        result: WorkoutResult,
        expected: Optional[ExpectedPerformance] = None
    ) -> PerformanceAssessment:
        """
        Assess workout performance.
        
        Args:
            given: Prescribed workout
            result: Actual workout result
            expected: Expected performance ranges (uses defaults if None)
            
        Returns:
            Complete performance assessment with label and feedback
        """
        if expected is None:
            expected = ExpectedPerformance()
        
        # Compare given vs result
        comparison = self._compare_performance(given, result, expected)
        
        # Calculate scores
        distance_score = self._score_distance(comparison, expected)
        pace_score = self._score_pace(comparison, expected, given.workout_type)
        hr_score = self._score_hr(comparison, expected)
        overall_score = self._calculate_overall_score(
            distance_score, pace_score, hr_score, comparison
        )
        
        # Determine performance label
        label = self._classify_performance(
            overall_score, comparison, given.workout_type
        )
        
        # Analyze strengths and weaknesses
        strengths = self._identify_strengths(comparison, given.workout_type, result)
        weaknesses = self._identify_weaknesses(comparison, given.workout_type, result)
        
        # Generate feedback
        feedback = self._generate_feedback(comparison, label, given.workout_type, result)
        coach_notes = self._generate_coach_notes(
            label, comparison, given.workout_type, strengths, weaknesses
        )
        
        # Assess readiness for progression
        readiness = self._assess_progression_readiness(label, comparison, given.workout_type)
        
        # Calculate ability change
        ability_change = self._calculate_ability_change(label, given.workout_type)
        
        # Assess fatigue and injury risk
        fatigue = self._assess_fatigue_level(result, given.workout_type)
        injury_risks = self._identify_injury_risks(comparison, result, given.workout_type)
        
        return PerformanceAssessment(
            workout_date=result.completed_date,
            workout_type=given.workout_type,
            performance_label=label,
            given=given,
            expected=expected,
            result=result,
            comparison=comparison,
            distance_score=distance_score,
            pace_score=pace_score,
            hr_score=hr_score,
            overall_score=overall_score,
            strengths=strengths,
            weaknesses=weaknesses,
            key_feedback=feedback,
            coach_notes=coach_notes,
            ability_change=ability_change,
            readiness_for_progression=readiness,
            fatigue_level=fatigue,
            injury_risk_indicators=injury_risks
        )
    
    def _compare_performance(
        self,
        given: WorkoutTarget,
        result: WorkoutResult,
        expected: ExpectedPerformance
    ) -> PerformanceComparison:
        """Compare given targets vs actual results"""
        
        # Distance variance
        distance_var_km = result.distance_km - given.distance_km
        distance_var_pct = (distance_var_km / given.distance_km) * 100
        distance_met = abs(distance_var_km) <= expected.distance_tolerance_km
        
        # Pace variance
        if given.target_pace_seconds:
            pace_var_sec = result.avg_pace_seconds - given.target_pace_seconds
            pace_var_pct = (pace_var_sec / given.target_pace_seconds) * 100
            
            # Check if within range
            if given.pace_range_seconds != (0, 0):
                pace_met = (
                    given.pace_range_seconds[0] <= result.avg_pace_seconds <= 
                    given.pace_range_seconds[1]
                )
            else:
                pace_met = abs(pace_var_sec) <= expected.pace_tolerance_seconds
        else:
            pace_var_sec = 0
            pace_var_pct = 0.0
            pace_met = True
        
        # HR variance
        if given.target_hr and result.avg_hr:
            hr_var_bpm = result.avg_hr - given.target_hr
            hr_var_pct = (hr_var_bpm / given.target_hr) * 100
            
            # Check if within range
            if given.hr_range != (0, 0):
                hr_met = (
                    given.hr_range[0] <= result.avg_hr <= given.hr_range[1]
                )
            else:
                hr_met = abs(hr_var_bpm) <= expected.hr_tolerance_bpm
        else:
            hr_var_bpm = None
            hr_var_pct = None
            hr_met = True  # Unknown, assume met
        
        # Interval consistency (if applicable)
        interval_variance = None
        if given.intervals and result.splits and len(result.splits) >= given.intervals:
            # Check first N splits for consistency
            interval_splits = result.splits[:given.intervals]
            avg_interval_pace = sum(interval_splits) / len(interval_splits)
            std_dev = statistics.stdev(interval_splits)
            interval_variance = std_dev / avg_interval_pace
        
        # Workout completion
        workout_completed = result.completed_full
        
        return PerformanceComparison(
            distance_variance_km=distance_var_km,
            distance_variance_pct=distance_var_pct,
            pace_variance_seconds=pace_var_sec,
            pace_variance_pct=pace_var_pct,
            hr_variance_bpm=hr_var_bpm,
            hr_variance_pct=hr_var_pct,
            interval_consistency_variance=interval_variance,
            distance_met=distance_met,
            pace_met=pace_met,
            hr_met=hr_met,
            workout_completed=workout_completed
        )
    
    def _score_distance(
        self,
        comparison: PerformanceComparison,
        expected: ExpectedPerformance
    ) -> float:
        """Score distance completion (0-100)"""
        
        if not comparison.workout_completed:
            return 30.0  # Partial credit for incomplete
        
        variance_pct = abs(comparison.distance_variance_pct)
        
        if variance_pct <= 1.0:
            return 100.0
        elif variance_pct <= 2.0:
            return 95.0
        elif variance_pct <= 5.0:
            return 85.0
        elif variance_pct <= 10.0:
            return 70.0
        else:
            return 50.0
    
    def _score_pace(
        self,
        comparison: PerformanceComparison,
        expected: ExpectedPerformance,
        workout_type: WorkoutType
    ) -> float:
        """Score pace execution (0-100)"""
        
        variance_sec = abs(comparison.pace_variance_seconds)
        
        # Different tolerances for different workout types
        if workout_type in [WorkoutType.EASY_RUN, WorkoutType.RECOVERY]:
            # More lenient for easy runs
            if variance_sec <= 10:
                return 100.0
            elif variance_sec <= 20:
                return 90.0
            elif variance_sec <= 30:
                return 75.0
            else:
                return 60.0
        
        elif workout_type in [WorkoutType.INTERVAL, WorkoutType.TEMPO, WorkoutType.THRESHOLD]:
            # Stricter for quality workouts
            if variance_sec <= 5:
                return 100.0
            elif variance_sec <= 10:
                return 90.0
            elif variance_sec <= 15:
                return 75.0
            elif variance_sec <= 20:
                return 60.0
            else:
                return 40.0
        
        else:  # Long run
            if variance_sec <= 10:
                return 100.0
            elif variance_sec <= 15:
                return 90.0
            elif variance_sec <= 20:
                return 80.0
            else:
                return 65.0
    
    def _score_hr(
        self,
        comparison: PerformanceComparison,
        expected: ExpectedPerformance
    ) -> float:
        """Score HR execution (0-100)"""
        
        if comparison.hr_variance_bpm is None:
            return 75.0  # Unknown, assume fair
        
        variance_bpm = abs(comparison.hr_variance_bpm)
        
        if variance_bpm <= 3:
            return 100.0
        elif variance_bpm <= 5:
            return 95.0
        elif variance_bpm <= 8:
            return 85.0
        elif variance_bpm <= 10:
            return 75.0
        else:
            return 60.0
    
    def _calculate_overall_score(
        self,
        distance_score: float,
        pace_score: float,
        hr_score: float,
        comparison: PerformanceComparison
    ) -> float:
        """Calculate weighted overall score"""
        
        if not comparison.workout_completed:
            return min(50.0, (distance_score + pace_score + hr_score) / 3)
        
        # Weights
        weights = {
            "distance": 0.25,
            "pace": 0.50,
            "hr": 0.25
        }
        
        overall = (
            weights["distance"] * distance_score +
            weights["pace"] * pace_score +
            weights["hr"] * hr_score
        )
        
        return round(overall, 1)
    
    def _classify_performance(
        self,
        overall_score: float,
        comparison: PerformanceComparison,
        workout_type: WorkoutType
    ) -> PerformanceLabel:
        """Classify performance into label"""
        
        if not comparison.workout_completed:
            return PerformanceLabel.INCOMPLETE
        
        # For quality workouts (intervals, tempo, threshold)
        if workout_type in [WorkoutType.INTERVAL, WorkoutType.TEMPO, WorkoutType.THRESHOLD]:
            if overall_score >= 95:
                return PerformanceLabel.BEST
            elif overall_score >= 85:
                return PerformanceLabel.GREAT
            elif overall_score >= 75:
                return PerformanceLabel.GOOD
            elif overall_score >= 60:
                return PerformanceLabel.FAIR
            else:
                return PerformanceLabel.POOR
        
        # For easy/recovery runs
        else:
            if overall_score >= 95:
                return PerformanceLabel.BEST
            elif overall_score >= 85:
                return PerformanceLabel.GREAT
            elif overall_score >= 70:
                return PerformanceLabel.GOOD
            elif overall_score >= 55:
                return PerformanceLabel.FAIR
            else:
                return PerformanceLabel.POOR
    
    def _identify_strengths(
        self,
        comparison: PerformanceComparison,
        workout_type: WorkoutType,
        result: WorkoutResult
    ) -> List[str]:
        """Identify what went well"""
        
        strengths = []
        
        if comparison.distance_met:
            strengths.append("Completed full distance as prescribed")
        
        if comparison.pace_met:
            if comparison.pace_variance_seconds < -5:
                strengths.append(f"Exceeded pace target by {abs(comparison.pace_variance_seconds)} sec/km")
            else:
                strengths.append("Hit pace target perfectly")
        
        if comparison.hr_met and comparison.hr_variance_bpm is not None:
            strengths.append(f"Maintained target HR zone")
        
        # Check for even splits
        if result.splits and len(result.splits) >= 3:
            variance = statistics.variance(result.splits)
            if variance < 50:  # Low variance
                strengths.append("Excellent pacing consistency - even splits")
        
        # Check for negative split
        if result.splits and len(result.splits) >= 4:
            first_half = sum(result.splits[:len(result.splits)//2]) / (len(result.splits)//2)
            second_half = sum(result.splits[len(result.splits)//2:]) / (len(result.splits) - len(result.splits)//2)
            if second_half < first_half:
                strengths.append("🎯 NEGATIVE SPLIT - great execution!")
        
        if not strengths:
            strengths.append("Completed the workout")
        
        return strengths
    
    def _identify_weaknesses(
        self,
        comparison: PerformanceComparison,
        workout_type: WorkoutType,
        result: WorkoutResult
    ) -> List[str]:
        """Identify areas for improvement"""
        
        weaknesses = []
        
        if not comparison.workout_completed:
            weaknesses.append(f"⚠️ Workout incomplete - stopped at {result.stopped_at_km:.1f} km")
        
        if not comparison.distance_met and comparison.distance_variance_km < -0.5:
            weaknesses.append(f"Did not complete full distance (short by {abs(comparison.distance_variance_km):.1f} km)")
        
        if not comparison.pace_met:
            if comparison.pace_variance_seconds > 15:
                weaknesses.append(f"Pace significantly slower than target (+{comparison.pace_variance_seconds} sec/km)")
            elif comparison.pace_variance_seconds < -15:
                weaknesses.append(f"Pace too fast - risk of burnout (started {abs(comparison.pace_variance_seconds)} sec/km faster)")
        
        if comparison.hr_variance_bpm and comparison.hr_variance_bpm > 10:
            weaknesses.append(f"HR too high - running above target zone (+{comparison.hr_variance_bpm} bpm)")
        
        # Check for fade
        if result.splits and len(result.splits) >= 4:
            first_quarter = result.splits[0]
            last_quarter = result.splits[-1]
            if last_quarter > first_quarter + 30:
                fade_pct = ((last_quarter - first_quarter) / first_quarter) * 100
                weaknesses.append(f"Significant fade detected ({fade_pct:.0f}% slower in final quarter)")
        
        # Check for starting too fast
        if result.splits and len(result.splits) >= 3:
            if result.splits[0] < result.splits[1] - 20:
                weaknesses.append("Started too fast - need better pacing discipline")
        
        return weaknesses
    
    def _generate_feedback(
        self,
        comparison: PerformanceComparison,
        label: PerformanceLabel,
        workout_type: WorkoutType,
        result: WorkoutResult
    ) -> List[str]:
        """Generate actionable feedback"""
        
        feedback = []
        
        # Label-specific feedback
        if label == PerformanceLabel.BEST:
            feedback.append("🏆 Outstanding execution! You're ready for progression.")
        elif label == PerformanceLabel.GREAT:
            feedback.append("💪 Excellent work! Very close to target performance.")
        elif label == PerformanceLabel.GOOD:
            feedback.append("✅ Good job! Hit all key targets.")
        elif label == PerformanceLabel.FAIR:
            feedback.append("⚠️ Fair effort, but fell short of targets. Review pacing strategy.")
        elif label == PerformanceLabel.POOR:
            feedback.append("❌ Struggled with this workout. May need to adjust targets or build more base.")
        else:
            feedback.append("⚠️ Incomplete workout. Check if fatigue or injury concerns.")
        
        # Pace-specific feedback
        if comparison.pace_variance_seconds > 20:
            feedback.append(
                f"🎯 Work on pacing: Try to run within ±15 sec/km of target. "
                f"Use GPS watch to check pace every 2-3 km."
            )
        elif comparison.pace_variance_seconds < -20:
            feedback.append(
                f"⚠️ Pace too aggressive: Slow down! Starting too fast leads to fade. "
                f"Check pace at 2 km and adjust."
            )
        
        # HR-specific feedback
        if comparison.hr_variance_bpm and comparison.hr_variance_bpm > 15:
            feedback.append(
                f"❤️ HR too high: Try to keep HR at {comparison.hr_variance_bpm - 15}-"
                f"{comparison.hr_variance_bpm} bpm. Slow down if HR spikes."
            )
        
        # Workout type-specific
        if workout_type == WorkoutType.INTERVAL:
            if comparison.interval_consistency_variance and comparison.interval_consistency_variance > 0.10:
                feedback.append(
                    f"🔄 Interval consistency needs work: Try to keep all intervals within "
                    f"5 sec/km of each other."
                )
        
        return feedback
    
    def _generate_coach_notes(
        self,
        label: PerformanceLabel,
        comparison: PerformanceComparison,
        workout_type: WorkoutType,
        strengths: List[str],
        weaknesses: List[str]
    ) -> str:
        """Generate coach notes for review"""
        
        notes = []
        
        # Performance summary
        notes.append(f"Performance: {label.value}")
        
        if comparison.workout_completed:
            notes.append("✅ Completed full workout")
        else:
            notes.append("⚠️ Incomplete - needs follow-up")
        
        # Key metrics
        if comparison.distance_met and comparison.pace_met and comparison.hr_met:
            notes.append("All targets met 🎯")
        else:
            missed = []
            if not comparison.distance_met:
                missed.append("distance")
            if not comparison.pace_met:
                missed.append("pace")
            if not comparison.hr_met:
                missed.append("HR")
            notes.append(f"Missed targets: {', '.join(missed)}")
        
        # Strengths summary
        if len(strengths) >= 3:
            notes.append("Strong execution")
        
        # Concerns
        if len(weaknesses) >= 3:
            notes.append("⚠️ Multiple concerns - review with athlete")
        
        return " | ".join(notes)
    
    def _assess_progression_readiness(
        self,
        label: PerformanceLabel,
        comparison: PerformanceComparison,
        workout_type: WorkoutType
    ) -> bool:
        """Assess if athlete is ready for progression"""
        
        # Need GREAT or BEST for progression
        if label not in [PerformanceLabel.BEST, PerformanceLabel.GREAT]:
            return False
        
        # Must have completed workout
        if not comparison.workout_completed:
            return False
        
        # For quality workouts, check pace and HR
        if workout_type in [WorkoutType.INTERVAL, WorkoutType.TEMPO, WorkoutType.THRESHOLD]:
            if not comparison.pace_met:
                return False
            if comparison.hr_variance_bpm and comparison.hr_variance_bpm > 10:
                return False
        
        return True
    
    def _calculate_ability_change(
        self,
        label: PerformanceLabel,
        workout_type: WorkoutType
    ) -> float:
        """Calculate change in ability score"""
        
        # Different impacts based on workout type
        multiplier = 1.0
        if workout_type in [WorkoutType.INTERVAL, WorkoutType.TEMPO, WorkoutType.THRESHOLD]:
            multiplier = 1.5  # Quality workouts have bigger impact
        
        if label == PerformanceLabel.BEST:
            return 2.0 * multiplier
        elif label == PerformanceLabel.GREAT:
            return 1.0 * multiplier
        elif label == PerformanceLabel.GOOD:
            return 0.5 * multiplier
        elif label == PerformanceLabel.FAIR:
            return 0.0
        elif label == PerformanceLabel.POOR:
            return -0.5 * multiplier
        else:  # INCOMPLETE
            return -1.0 * multiplier
    
    def _assess_fatigue_level(
        self,
        result: WorkoutResult,
        workout_type: WorkoutType
    ) -> str:
        """Assess fatigue level from workout"""
        
        # Check for fade pattern
        if result.splits and len(result.splits) >= 4:
            first_half_avg = sum(result.splits[:len(result.splits)//2]) / (len(result.splits)//2)
            second_half_avg = sum(result.splits[len(result.splits)//2:]) / (len(result.splits) - len(result.splits)//2)
            
            fade_pct = ((second_half_avg - first_half_avg) / first_half_avg) * 100
            
            if fade_pct > 15:
                return "high"
            elif fade_pct > 8:
                return "moderate"
            else:
                return "low"
        
        # Check HR (if max HR very high, indicates high fatigue)
        if result.max_hr and result.avg_hr:
            if result.max_hr > result.avg_hr + 30:
                return "moderate"
        
        return "low"
    
    def _identify_injury_risks(
        self,
        comparison: PerformanceComparison,
        result: WorkoutResult,
        workout_type: WorkoutType
    ) -> List[str]:
        """Identify injury risk indicators"""
        
        risks = []
        
        # Incomplete workout = potential injury
        if not comparison.workout_completed:
            risks.append("Incomplete workout - check for pain/discomfort")
        
        # HR too high consistently
        if comparison.hr_variance_bpm and comparison.hr_variance_bpm > 20:
            risks.append("HR significantly elevated - possible overtraining")
        
        # Severe pace fade
        if result.splits and len(result.splits) >= 4:
            first = result.splits[0]
            last = result.splits[-1]
            if last > first + 40:
                risks.append("Severe fade - potential fatigue accumulation")
        
        # Too aggressive pace
        if comparison.pace_variance_seconds < -30:
            risks.append("Started way too fast - injury risk from overexertion")
        
        return risks


def seconds_to_pace_str(seconds: int) -> str:
    """Convert seconds to pace string (M:SS)"""
    minutes = seconds // 60
    secs = seconds % 60
    return f"{minutes}:{secs:02d}"


def print_performance_assessment(assessment: PerformanceAssessment):
    """Pretty print performance assessment"""
    
    print("\n" + "="*80)
    print("WORKOUT PERFORMANCE ASSESSMENT")
    print("="*80)
    
    print(f"\n📅 Date: {assessment.workout_date.strftime('%Y-%m-%d')}")
    print(f"🏃 Workout Type: {assessment.workout_type.value.upper()}")
    print(f"🏆 PERFORMANCE: {assessment.performance_label.value} (Score: {assessment.overall_score:.0f}/100)")
    
    print(f"\n📋 GIVEN (Prescribed Workout):")
    g = assessment.given
    print(f"   Distance: {g.distance_km:.1f} km")
    if g.target_pace_seconds:
        print(f"   Target Pace: {seconds_to_pace_str(g.target_pace_seconds)}/km")
    if g.pace_range_seconds != (0, 0):
        print(f"   Pace Range: {seconds_to_pace_str(g.pace_range_seconds[0])}-"
              f"{seconds_to_pace_str(g.pace_range_seconds[1])}/km")
    if g.target_hr:
        print(f"   Target HR: {g.target_hr} bpm")
    if g.hr_range != (0, 0):
        print(f"   HR Range: {g.hr_range[0]}-{g.hr_range[1]} bpm")
    if g.intervals:
        print(f"   Intervals: {g.intervals} × {g.interval_distance_m}m @ "
              f"{seconds_to_pace_str(g.interval_pace_seconds)}/km")
    
    print(f"\n✅ RESULT (Actual Performance):")
    r = assessment.result
    print(f"   Distance: {r.distance_km:.2f} km")
    print(f"   Avg Pace: {seconds_to_pace_str(r.avg_pace_seconds)}/km")
    if r.avg_hr:
        print(f"   Avg HR: {r.avg_hr} bpm (Max: {r.max_hr} bpm)")
    print(f"   Total Time: {r.total_time_seconds // 60}:{r.total_time_seconds % 60:02d}")
    print(f"   Completed: {'✅ YES' if r.completed_full else f'❌ NO (stopped at {r.stopped_at_km}km)'}")
    
    print(f"\n📊 COMPARISON:")
    c = assessment.comparison
    print(f"   Distance: {'✅ MET' if c.distance_met else '❌ MISSED'} "
          f"({c.distance_variance_km:+.2f} km, {c.distance_variance_pct:+.1f}%)")
    print(f"   Pace: {'✅ MET' if c.pace_met else '❌ MISSED'} "
          f"({c.pace_variance_seconds:+d} sec/km, {c.pace_variance_pct:+.1f}%)")
    if c.hr_variance_bpm is not None:
        print(f"   HR: {'✅ MET' if c.hr_met else '❌ MISSED'} "
              f"({c.hr_variance_bpm:+d} bpm, {c.hr_variance_pct:+.1f}%)")
    
    print(f"\n📈 SCORES:")
    print(f"   Distance: {assessment.distance_score:.0f}/100")
    print(f"   Pace: {assessment.pace_score:.0f}/100")
    print(f"   HR: {assessment.hr_score:.0f}/100")
    print(f"   OVERALL: {assessment.overall_score:.0f}/100")
    
    if assessment.strengths:
        print(f"\n💪 STRENGTHS:")
        for strength in assessment.strengths:
            print(f"   ✅ {strength}")
    
    if assessment.weaknesses:
        print(f"\n⚠️ AREAS FOR IMPROVEMENT:")
        for weakness in assessment.weaknesses:
            print(f"   ❌ {weakness}")
    
    if assessment.key_feedback:
        print(f"\n💬 KEY FEEDBACK:")
        for feedback in assessment.key_feedback:
            print(f"   {feedback}")
    
    print(f"\n📝 COACH NOTES: {assessment.coach_notes}")
    
    print(f"\n📊 PROGRESS TRACKING:")
    print(f"   Ability Change: {assessment.ability_change:+.1f}")
    print(f"   Ready for Progression: {'✅ YES' if assessment.readiness_for_progression else '❌ NO'}")
    print(f"   Fatigue Level: {assessment.fatigue_level.upper()}")
    
    if assessment.injury_risk_indicators:
        print(f"\n⚠️ INJURY RISK INDICATORS:")
        for risk in assessment.injury_risk_indicators:
            print(f"   🚨 {risk}")
    
    print("\n" + "="*80 + "\n")


# Example usage
if __name__ == "__main__":
    # Example: Tempo run assessment
    tracker = PerformanceTracker()
    
    # GIVEN: Prescribed tempo run
    given_workout = WorkoutTarget(
        workout_type=WorkoutType.TEMPO,
        distance_km=10.0,
        target_pace_seconds=360,  # 6:00/km
        pace_range_seconds=(350, 370),  # 5:50-6:10/km acceptable
        target_hr=160,
        hr_range=(155, 165),
        notes="Steady tempo effort, should feel comfortably hard"
    )
    
    # RESULT: Actual workout (example: good execution)
    actual_result = WorkoutResult(
        workout_id="STR123456",
        completed_date=datetime.now(),
        distance_km=10.1,
        total_time_seconds=3630,  # 60:30
        avg_pace_seconds=359,  # 5:59/km - on target!
        avg_hr=162,
        max_hr=172,
        splits=[360, 358, 357, 360, 362, 358, 361, 359, 357, 360],  # Consistent!
        completed_full=True
    )
    
    assessment = tracker.assess_workout_performance(
        given=given_workout,
        result=actual_result
    )
    
    print_performance_assessment(assessment)
    
    print("\n" + "="*80)
    print("EXAMPLE 2: Poor Execution (Started too fast, faded badly)")
    print("="*80)
    
    # Example 2: Poor execution
    poor_result = WorkoutResult(
        workout_id="STR123457",
        completed_date=datetime.now(),
        distance_km=9.5,  # Didn't complete full distance
        total_time_seconds=3450,
        avg_pace_seconds=363,  # Averaged 6:03/km but with big fade
        avg_hr=168,  # HR too high
        max_hr=180,
        splits=[340, 345, 355, 365, 375, 380, 385, 390, 395],  # Started too fast, faded badly
        completed_full=False,
        stopped_at_km=9.5
    )
    
    poor_assessment = tracker.assess_workout_performance(
        given=given_workout,
        result=poor_result
    )
    
    print("\n")
    print_performance_assessment(poor_assessment)
