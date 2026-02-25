"""
Fitness Analyzer Module
Comprehensive fitness assessment across ALL dimensions: running, strength, mobility, ROM, balance, mental.

This holistic approach evaluates:
- Running fitness (VO2max, endurance, pace progression)
- Strength capacity (estimated from running mechanics)
- Mobility/ROM (stride metrics, cadence analysis)
- Balance/stability (injury risk indicators)
- Mental readiness (pacing discipline, race anxiety)
- Recovery capacity

Used to calculate REALISTIC timelines and identify training focus areas.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from enum import Enum
import statistics


class DimensionLevel(Enum):
    """Assessment levels for each fitness dimension"""
    EXCELLENT = "excellent"
    GOOD = "good"
    FAIR = "fair"
    POOR = "poor"
    UNKNOWN = "unknown"


@dataclass
class RunningFitnessMetrics:
    """Running-specific fitness metrics """
    vo2max_estimate: Optional[float] = None  # ml/kg/min
    endurance_score: float = 0.0  # 0-100
    speed_score: float = 0.0  # 0-100
    pace_progression: float = 0.0  # % improvement over time
    weekly_volume: float = 0.0  # km/week
    consistency: float = 0.0  # runs per week
    longest_run: float = 0.0  # km


@dataclass
class StrengthMetrics:
    """Strength assessment (estimated from running data)"""
    lower_body_strength: DimensionLevel = DimensionLevel.UNKNOWN
    core_strength: DimensionLevel = DimensionLevel.UNKNOWN
    single_leg_stability: DimensionLevel = DimensionLevel.UNKNOWN
    estimated_weeks_to_target: int = 12  # Weeks needed to build strength


@dataclass
class MobilityROMMetrics:
    """Mobility and Range of Motion assessment"""
    hip_flexor_mobility: DimensionLevel = DimensionLevel.UNKNOWN
    ankle_rom: DimensionLevel = DimensionLevel.UNKNOWN
    overall_flexibility: DimensionLevel = DimensionLevel.UNKNOWN
    stride_efficiency_score: float = 0.0  # 0-100
    estimated_weeks_to_target: int = 8  # Weeks needed to improve


@dataclass
class BalanceMetrics:
    """Balance and proprioception assessment"""
    stability_score: float = 0.0  # 0-100
    injury_risk_score: float = 0.0  # 0-100 (higher = more risk)
    asymmetry_detected: bool = False


@dataclass
class MentalReadinessMetrics:
    """Mental/psychological readiness"""
    pacing_discipline: DimensionLevel = DimensionLevel.UNKNOWN
    race_anxiety_level: str = "unknown"  # low/moderate/high
    mental_toughness: DimensionLevel = DimensionLevel.UNKNOWN
    visualization_practice: bool = False


@dataclass
class RecoveryMetrics:
    """Recovery and lifestyle factors"""
    sleep_quality: DimensionLevel = DimensionLevel.UNKNOWN
    stress_level: str = "unknown"  # low/moderate/high
    nutrition_quality: DimensionLevel = DimensionLevel.UNKNOWN
    recovery_score: float = 0.0  # 0-100


@dataclass
class ComprehensiveFitnessAssessment:
    """Complete holistic fitness assessment"""
    # Individual dimension assessments
    running_fitness: RunningFitnessMetrics
    strength: StrengthMetrics
    mobility_rom: MobilityROMMetrics
    balance: BalanceMetrics
    mental_readiness: MentalReadinessMetrics
    recovery: RecoveryMetrics
    
    # Overall scores
    overall_fitness_score: float  # 0-100 (weighted across all dimensions)
    readiness_for_speed_work: bool
    injury_risk_level: str  # low/moderate/high
    
    # Timeline adjustments
    foundation_phase_needed: bool
    foundation_phase_weeks: int  # Additional weeks needed for foundation
    total_estimated_weeks: int  # Total weeks to goal
    
    # Priority areas
    primary_focus_areas: List[str]
    secondary_focus_areas: List[str]
    
    # Detailed recommendations
    strength_training_frequency: int  # sessions per week
    mobility_frequency: str  # daily/3x per week/etc
    mental_training_needed: bool
    
    # Insights
    key_insights: List[str]
    limiting_factors: List[str]


class FitnessAnalyzer:
    """
    Comprehensive fitness analyzer across ALL dimensions.
    
    Evaluates running fitness, strength, mobility, ROM, balance, mental readiness,
    and recovery to provide holistic assessment and realistic timeline estimates.
    """
    
    def __init__(self):
        """Initialize fitness analyzer"""
        pass
    
    def analyze_comprehensive_fitness(
        self,
        # Running data
        recent_race_pace_seconds: int,
        training_pace_seconds: int,
        weekly_volume: float,
        consistency: float,
        longest_run: float,
        race_distance_km: float,
        
        # Optional race performance data
        race_splits: Optional[List[int]] = None,
        race_hr_data: Optional[Dict] = None,
        
        # Strength indicators (self-reported or from assessment)
        plank_hold_seconds: Optional[int] = None,
        single_leg_squat_reps: Optional[int] = None,
        
        # Mobility indicators
        stride_length_cm: Optional[float] = None,
        cadence: Optional[int] = None,
        
        # Lifestyle/recovery
        avg_sleep_hours: Optional[float] = None,
        stress_level: Optional[str] = None,
        
        # Mental
        pacing_variance: Optional[float] = None,
        
        # Goals
        goal_pace_seconds: Optional[int] = None,
        goal_distance_km: Optional[float] = None
        
    ) -> ComprehensiveFitnessAssessment:
        """
        Perform comprehensive fitness assessment.
        
        Args:
            All the various fitness indicators across dimensions
            
        Returns:
            ComprehensiveFitnessAssessment with complete analysis
        """
        # Analyze each dimension
        running_fitness = self._assess_running_fitness(
            recent_race_pace_seconds,
            training_pace_seconds,
            weekly_volume,
            consistency,
            longest_run,
            race_distance_km,
            goal_pace_seconds
        )
        
        strength = self._assess_strength(
            plank_hold_seconds,
            single_leg_squat_reps,
            race_hr_data
        )
        
        mobility_rom = self._assess_mobility_rom(
            stride_length_cm,
            cadence,
            recent_race_pace_seconds,
            training_pace_seconds
        )
        
        balance = self._assess_balance(
            single_leg_squat_reps,
            race_splits
        )
        
        mental_readiness = self._assess_mental_readiness(
            pacing_variance,
            race_splits,
            race_hr_data
        )
        
        recovery = self._assess_recovery(
            avg_sleep_hours,
            stress_level,
            consistency
        )
        
        # Calculate overall fitness score (weighted)
        overall_score = self._calculate_overall_score(
            running_fitness,
            strength,
            mobility_rom,
            balance,
            mental_readiness,
            recovery
        )
        
        # Determine readiness for speed work
        ready_for_speed = self._check_speed_work_readiness(
            strength,
            mobility_rom,
            balance,
            recovery
        )
        
        # Calculate injury risk
        injury_risk = self._calculate_injury_risk(
            strength,
            mobility_rom,
            balance,
            recovery,
            weekly_volume,
            consistency
        )
        
        # Determine if foundation phase needed
        foundation_needed, foundation_weeks = self._assess_foundation_needs(
            strength,
            mobility_rom,
            balance,
            mental_readiness
        )
        
        # Calculate total timeline
        total_weeks = self._calculate_total_timeline(
            running_fitness,
            foundation_needed,
            foundation_weeks,
            goal_pace_seconds,
            recent_race_pace_seconds
        )
        
        # Identify focus areas
        primary_focus, secondary_focus = self._identify_focus_areas(
            running_fitness,
            strength,
            mobility_rom,
            balance,
            mental_readiness,
            recovery
        )
        
        # Determine training frequencies
        strength_freq = self._recommend_strength_frequency(strength, foundation_needed)
        mobility_freq = self._recommend_mobility_frequency(mobility_rom, foundation_needed)
        mental_needed = self._check_mental_training_need(mental_readiness)
        
        # Generate insights and limiting factors
        insights = self._generate_comprehensive_insights(
            running_fitness,
            strength,
            mobility_rom,
            balance,
            mental_readiness,
            recovery,
            foundation_needed,
            ready_for_speed
        )
        
        limiting_factors = self._identify_limiting_factors(
            running_fitness,
            strength,
            mobility_rom,
            balance,
            mental_readiness,
            recovery
        )
        
        return ComprehensiveFitnessAssessment(
            running_fitness=running_fitness,
            strength=strength,
            mobility_rom=mobility_rom,
            balance=balance,
            mental_readiness=mental_readiness,
            recovery=recovery,
            overall_fitness_score=overall_score,
            readiness_for_speed_work=ready_for_speed,
            injury_risk_level=injury_risk,
            foundation_phase_needed=foundation_needed,
            foundation_phase_weeks=foundation_weeks,
            total_estimated_weeks=total_weeks,
            primary_focus_areas=primary_focus,
            secondary_focus_areas=secondary_focus,
            strength_training_frequency=strength_freq,
            mobility_frequency=mobility_freq,
            mental_training_needed=mental_needed,
            key_insights=insights,
            limiting_factors=limiting_factors
        )
    
    def _assess_running_fitness(
        self,
        race_pace_seconds: int,
        training_pace_seconds: int,
        weekly_volume: float,
        consistency: float,
        longest_run: float,
        race_distance: float,
        goal_pace_seconds: Optional[int]
    ) -> RunningFitnessMetrics:
        """Assess running-specific fitness"""
        
        # Estimate VO2max from race pace (simplified calculation)
        # Based on Daniels' Running Formula approximations
        pace_per_mile = race_pace_seconds * 1.60934
        vo2max = max(20, min(80, 80 - (pace_per_mile - 300) / 20))
        
        # Endurance score based on long run and volume
        endurance_score = 0.0
        if longest_run >= race_distance * 0.9:
            endurance_score += 40
        elif longest_run >= race_distance * 0.75:
            endurance_score += 30
        elif longest_run >= race_distance * 0.6:
            endurance_score += 20
        else:
            endurance_score += 10
        
        if weekly_volume >= race_distance * 3:
            endurance_score += 40
        elif weekly_volume >= race_distance * 2:
            endurance_score += 25
        else:
            endurance_score += 10
        
        if consistency >= 4.0:
            endurance_score += 20
        elif consistency >= 3.0:
            endurance_score += 10
        
        endurance_score = min(100, endurance_score)
        
        # Speed score based on pace differential
        pace_diff_pct = ((training_pace_seconds - race_pace_seconds) / training_pace_seconds) * 100
        if pace_diff_pct <= 5:
            speed_score = 90
        elif pace_diff_pct <= 10:
            speed_score = 70
        elif pace_diff_pct <= 15:
            speed_score = 50
        else:
            speed_score = 30
        
        # Pace progression (would need historical data - using placeholder)
        pace_progression = 0.0  # Would calculate from historical data
        
        return RunningFitnessMetrics(
            vo2max_estimate=vo2max,
            endurance_score=endurance_score,
            speed_score=speed_score,
            pace_progression=pace_progression,
            weekly_volume=weekly_volume,
            consistency=consistency,
            longest_run=longest_run
        )
    
    def _assess_strength(
        self,
        plank_seconds: Optional[int],
        single_leg_reps: Optional[int],
        race_hr_data: Optional[Dict]
    ) -> StrengthMetrics:
        """Assess strength capacity"""
        
        # Core strength from plank
        if plank_seconds:
            if plank_seconds >= 90:
                core = DimensionLevel.EXCELLENT
                core_weeks = 0
            elif plank_seconds >= 60:
                core = DimensionLevel.GOOD
                core_weeks = 4
            elif plank_seconds >= 45:
                core = DimensionLevel.FAIR
                core_weeks = 8
            else:
                core = DimensionLevel.POOR
                core_weeks = 12
        else:
            core = DimensionLevel.UNKNOWN
            core_weeks = 8
        
        # Lower body/single leg strength
        if single_leg_reps:
            if single_leg_reps >= 15:
                lower = DimensionLevel.EXCELLENT
                single_leg = DimensionLevel.EXCELLENT
                leg_weeks = 0
            elif single_leg_reps >= 12:
                lower = DimensionLevel.GOOD
                single_leg = DimensionLevel.GOOD
                leg_weeks = 4
            elif single_leg_reps >= 8:
                lower = DimensionLevel.FAIR
                single_leg = DimensionLevel.FAIR
                leg_weeks = 8
            else:
                lower = DimensionLevel.POOR
                single_leg = DimensionLevel.POOR
                leg_weeks = 12
        else:
            lower = DimensionLevel.UNKNOWN
            single_leg = DimensionLevel.UNKNOWN
            leg_weeks = 12
        
        # Estimate weeks needed (take max of all deficits)
        total_weeks = max(core_weeks, leg_weeks)
        
        return StrengthMetrics(
            lower_body_strength=lower,
            core_strength=core,
            single_leg_stability=single_leg,
            estimated_weeks_to_target=total_weeks
        )
    
    def _assess_mobility_rom(
        self,
        stride_length: Optional[float],
        cadence: Optional[int],
        race_pace: int,
        training_pace: int
    ) -> MobilityROMMetrics:
        """Assess mobility and ROM"""
        
        # Optimal cadence is around 170-180 spm
        if cadence:
            if cadence >= 175:
                overall_flex = DimensionLevel.GOOD
                mobility_weeks = 4
            elif cadence >= 165:
                overall_flex = DimensionLevel.FAIR
                mobility_weeks = 8
            else:
                overall_flex = DimensionLevel.POOR
                mobility_weeks = 12
        else:
            overall_flex = DimensionLevel.UNKNOWN
            mobility_weeks = 8
        
        # Estimate hip flexor and ankle from cadence and pace
        # Lower cadence often indicates mobility restrictions
        if cadence and cadence < 165:
            hip_flexor = DimensionLevel.POOR
            ankle = DimensionLevel.POOR
        elif cadence and cadence < 175:
            hip_flexor = DimensionLevel.FAIR
            ankle = DimensionLevel.FAIR
        else:
            hip_flexor = DimensionLevel.GOOD
            ankle = DimensionLevel.GOOD
        
        # Stride efficiency score
        if cadence and stride_length:
            # Optimal stride length is roughly (height * 0.65) but we'll use pace as proxy
            expected_stride = race_pace / 60 * 1000 / (cadence / 60)  # meters
            if stride_length >= expected_stride * 0.95:
                stride_score = 90
            elif stride_length >= expected_stride * 0.9:
                stride_score = 75
            else:
                stride_score = 60
        else:
            stride_score = 70.0  # Unknown, assume fair
        
        return MobilityROMMetrics(
            hip_flexor_mobility=hip_flexor,
            ankle_rom=ankle,
            overall_flexibility=overall_flex,
            stride_efficiency_score=stride_score,
            estimated_weeks_to_target=mobility_weeks
        )
    
    def _assess_balance(
        self,
        single_leg_reps: Optional[int],
        race_splits: Optional[List[int]]
    ) -> BalanceMetrics:
        """Assess balance and stability"""
        
        # Single leg balance correlates with single leg squat ability
        if single_leg_reps:
            if single_leg_reps >= 12:
                stability = 85
                injury_risk = 20
            elif single_leg_reps >= 8:
                stability = 70
                injury_risk = 35
            else:
                stability = 50
                injury_risk = 55
        else:
            stability = 65
            injury_risk = 40
        
        # Check asymmetry from splits (if significant variation, might indicate asymmetry)
        asymmetry = False
        if race_splits and len(race_splits) >= 4:
            # Check if pace variation is high (might indicate one leg weaker)
            variance = statistics.variance(race_splits[:4])  # First 4 splits
            if variance > 100:  # High variance
                asymmetry = True
                injury_risk += 15
        
        return BalanceMetrics(
            stability_score=stability,
            injury_risk_score=min(100, injury_risk),
            asymmetry_detected=asymmetry
        )
    
    def _assess_mental_readiness(
        self,
        pacing_variance: Optional[float],
        race_splits: Optional[List[int]],
        race_hr_data: Optional[Dict]
    ) -> MentalReadinessMetrics:
        """Assess mental/psychological readiness"""
        
        # Pacing discipline from splits
        if race_splits and len(race_splits) >= 3:
            # Calculate variance
            avg_pace = sum(race_splits) / len(race_splits)
            variance = sum((p - avg_pace) ** 2 for p in race_splits) / len(race_splits)
            std_dev = variance ** 0.5
            
            if std_dev <= 10:
                pacing = DimensionLevel.EXCELLENT
            elif std_dev <= 20:
                pacing = DimensionLevel.GOOD
            elif std_dev <= 30:
                pacing = DimensionLevel.FAIR
            else:
                pacing = DimensionLevel.POOR
            
            # Check if first split much faster (indicates starting too fast = anxiety)
            if race_splits[0] < avg_pace - 20:
                anxiety = "high"
            elif race_splits[0] < avg_pace - 10:
                anxiety = "moderate"
            else:
                anxiety = "low"
        else:
            pacing = DimensionLevel.UNKNOWN
            anxiety = "unknown"
        
        # Mental toughness - did they finish strong or fade?
        if race_splits and len(race_splits) >= 3:
            if race_splits[-1] <= race_splits[0]:
                toughness = DimensionLevel.EXCELLENT  # Negative split!
            elif race_splits[-1] <= race_splits[0] + 20:
                toughness = DimensionLevel.GOOD
            else:
                toughness = DimensionLevel.FAIR
        else:
            toughness = DimensionLevel.UNKNOWN
        
        return MentalReadinessMetrics(
            pacing_discipline=pacing,
            race_anxiety_level=anxiety,
            mental_toughness=toughness,
            visualization_practice=False  # Would need to ask athlete
        )
    
    def _assess_recovery(
        self,
        sleep_hours: Optional[float],
        stress: Optional[str],
        consistency: float
    ) -> RecoveryMetrics:
        """Assess recovery capacity"""
        
        # Sleep quality
        if sleep_hours:
            if sleep_hours >= 8.0:
                sleep_qual = DimensionLevel.EXCELLENT
                sleep_score = 95
            elif sleep_hours >= 7.5:
                sleep_qual = DimensionLevel.GOOD
                sleep_score = 80
            elif sleep_hours >= 6.5:
                sleep_qual = DimensionLevel.FAIR
                sleep_score = 60
            else:
                sleep_qual = DimensionLevel.POOR
                sleep_score = 40
        else:
            sleep_qual = DimensionLevel.UNKNOWN
            sleep_score = 70
        
        # Stress
        stress_score = 0
        if stress == "low":
            stress_score = 90
        elif stress == "moderate":
            stress_score = 70
        elif stress == "high":
            stress_score = 40
        else:
            stress_score = 70
        
        # Consistency indicates recovery ability
        if consistency >= 4.5:
            consistency_score = 90
        elif consistency >= 3.5:
            consistency_score = 75
        else:
            consistency_score = 55
        
        # Overall recovery score
        recovery_score = (sleep_score + stress_score + consistency_score) / 3
        
        return RecoveryMetrics(
            sleep_quality=sleep_qual,
            stress_level=stress if stress else "unknown",
            nutrition_quality=DimensionLevel.UNKNOWN,  # Would need dietary data
            recovery_score=recovery_score
        )
    
    def _calculate_overall_score(
        self,
        running: RunningFitnessMetrics,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        mental: MentalReadinessMetrics,
        recovery: RecoveryMetrics
    ) -> float:
        """Calculate weighted overall fitness score"""
        
        # Weights for each dimension
        weights = {
            "running": 0.30,
            "strength": 0.20,
            "mobility": 0.20,
            "balance": 0.10,
            "mental": 0.10,
            "recovery": 0.10
        }
        
        running_score = (running.endurance_score + running.speed_score) / 2
        
        # Convert dimension levels to scores
        level_scores = {
            DimensionLevel.EXCELLENT: 95,
            DimensionLevel.GOOD: 80,
            DimensionLevel.FAIR: 60,
            DimensionLevel.POOR: 35,
            DimensionLevel.UNKNOWN: 65
        }
        
        strength_score = (
            level_scores[strength.core_strength] +
            level_scores[strength.lower_body_strength] +
            level_scores[strength.single_leg_stability]
        ) / 3
        
        mobility_score = (
            level_scores[mobility.hip_flexor_mobility] +
            level_scores[mobility.ankle_rom] +
            mobility.stride_efficiency_score
        ) / 3
        
        balance_score = balance.stability_score
        
        mental_score = (
            level_scores[mental.pacing_discipline] +
            level_scores[mental.mental_toughness]
        ) / 2
        
        recovery_score = recovery.recovery_score
        
        # Weighted average
        overall = (
            weights["running"] * running_score +
            weights["strength"] * strength_score +
            weights["mobility"] * mobility_score +
            weights["balance"] * balance_score +
            weights["mental"] * mental_score +
            weights["recovery"] * recovery_score
        )
        
        return round(overall, 1)
    
    def _check_speed_work_readiness(
        self,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        recovery: RecoveryMetrics
    ) -> bool:
        """Check if athlete is ready for speed work"""
        
        # Need at least FAIR in all critical areas
        strength_ok = (
            strength.core_strength != DimensionLevel.POOR and
            strength.lower_body_strength != DimensionLevel.POOR
        )
        
        mobility_ok = (
            mobility.overall_flexibility != DimensionLevel.POOR and
            mobility.stride_efficiency_score >= 60
        )
        
        balance_ok = balance.stability_score >= 60
        
        recovery_ok = recovery.recovery_score >= 60
        
        return strength_ok and mobility_ok and balance_ok and recovery_ok
    
    def _calculate_injury_risk(
        self,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        recovery: RecoveryMetrics,
        weekly_volume: float,
        consistency: float
    ) -> str:
        """Calculate overall injury risk level"""
        
        risk_score = 0
        
        # Strength deficits increase risk
        if strength.core_strength == DimensionLevel.POOR:
            risk_score += 20
        if strength.lower_body_strength == DimensionLevel.POOR:
            risk_score += 25
        if strength.single_leg_stability == DimensionLevel.POOR:
            risk_score += 20
        
        # Mobility deficits increase risk
        if mobility.hip_flexor_mobility == DimensionLevel.POOR:
            risk_score += 20
        if mobility.ankle_rom == DimensionLevel.POOR:
            risk_score += 15
        
        # Balance issues increase risk
        if balance.stability_score < 60:
            risk_score += 20
        if balance.asymmetry_detected:
            risk_score += 15
        
        # Poor recovery increases risk
        if recovery.recovery_score < 60:
            risk_score += 15
        
        # High volume with poor consistency increases risk
        if weekly_volume > 50 and consistency < 3.5:
            risk_score += 20
        
        if risk_score >= 60:
            return "high"
        elif risk_score >= 35:
            return "moderate"
        else:
            return "low"
    
    def _assess_foundation_needs(
        self,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        mental: MentalReadinessMetrics
    ) -> Tuple[bool, int]:
        """Determine if foundation phase needed and duration"""
        
        needs_foundation = False
        max_weeks = 0
        
        # Check each dimension
        if strength.estimated_weeks_to_target > 0:
            needs_foundation = True
            max_weeks = max(max_weeks, strength.estimated_weeks_to_target)
        
        if mobility.estimated_weeks_to_target > 0:
            needs_foundation = True
            max_weeks = max(max_weeks, mobility.estimated_weeks_to_target)
        
        if balance.stability_score < 70:
            needs_foundation = True
            max_weeks = max(max_weeks, 8)
        
        if mental.pacing_discipline in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            needs_foundation = True
            max_weeks = max(max_weeks, 8)
        
        return needs_foundation, max_weeks
    
    def _calculate_total_timeline(
        self,
        running: RunningFitnessMetrics,
        foundation_needed: bool,
        foundation_weeks: int,
        goal_pace: Optional[int],
        current_pace: int
    ) -> int:
        """Calculate total weeks to goal"""
        
        base_weeks = 16  # Base training phase
        
        # Add foundation if needed
        if foundation_needed:
            base_weeks += foundation_weeks
        
        # Add time based on pace gap
        if goal_pace:
            pace_gap_pct = ((current_pace - goal_pace) / current_pace) * 100
            if pace_gap_pct > 10:
                base_weeks += 12
            elif pace_gap_pct > 7:
                base_weeks += 8
            elif pace_gap_pct > 5:
                base_weeks += 4
        
        # Add time based on endurance deficit
        if running.endurance_score < 70:
            base_weeks += 4
        
        return base_weeks
    
    def _identify_focus_areas(
        self,
        running: RunningFitnessMetrics,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        mental: MentalReadinessMetrics,
        recovery: RecoveryMetrics
    ) -> Tuple[List[str], List[str]]:
        """Identify primary and secondary focus areas"""
        
        primary = []
        secondary = []
        
        # Check each dimension
        if strength.core_strength in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            primary.append("Core strength building")
        if strength.lower_body_strength in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            primary.append("Lower body strength development")
        
        if mobility.hip_flexor_mobility in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            primary.append("Hip flexor mobility (DAILY work required)")
        if mobility.ankle_rom in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            primary.append("Ankle dorsiflexion improvement")
        
        if balance.stability_score < 70:
            secondary.append("Balance and proprioception training")
        
        if mental.pacing_discipline in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            primary.append("Pacing discipline practice")
        
        if running.endurance_score < 70:
            secondary.append("Aerobic base building")
        
        if recovery.recovery_score < 70:
            secondary.append("Sleep and recovery optimization")
        
        if not primary:
            primary.append("Continue balanced training")
        if not secondary:
            secondary.append("Maintain current training structure")
        
        return primary, secondary
    
    def _recommend_strength_frequency(
        self,
        strength: StrengthMetrics,
        foundation_needed: bool
    ) -> int:
        """Recommend strength training frequency"""
        
        if strength.estimated_weeks_to_target >= 12:
            return 3  # 3x per week for major deficits
        elif strength.estimated_weeks_to_target >= 8:
            return 3  # Still 3x for faster improvement
        elif strength.estimated_weeks_to_target > 0:
            return 2  # 2x for minor deficits
        else:
            return 2  # 2x for maintenance
    
    def _recommend_mobility_frequency(
        self,
        mobility: MobilityROMMetrics,
        foundation_needed: bool
    ) -> str:
        """Recommend mobility training frequency"""
        
        if mobility.estimated_weeks_to_target >= 12:
            return "DAILY (30-45 min) - Non-negotiable"
        elif mobility.estimated_weeks_to_target >= 8:
            return "DAILY (30 min minimum)"
        elif mobility.estimated_weeks_to_target > 0:
            return "Daily (20-30 min)"
        else:
            return "3-4x per week (maintenance)"
    
    def _check_mental_training_need(
        self,
        mental: MentalReadinessMetrics
    ) -> bool:
        """Check if mental training is needed"""
        
        return (
            mental.pacing_discipline in [DimensionLevel.POOR, DimensionLevel.FAIR] or
            mental.race_anxiety_level == "high" or
            mental.mental_toughness in [DimensionLevel.POOR, DimensionLevel.FAIR]
        )
    
    def _generate_comprehensive_insights(
        self,
        running: RunningFitnessMetrics,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        mental: MentalReadinessMetrics,
        recovery: RecoveryMetrics,
        foundation_needed: bool,
        ready_for_speed: bool
    ) -> List[str]:
        """Generate comprehensive insights"""
        
        insights = []
        
        # Overall assessment
        if foundation_needed:
            insights.append(
                f"🏗️ Foundation Phase Required: {strength.estimated_weeks_to_target}-"
                f"{mobility.estimated_weeks_to_target} weeks needed to build strength/mobility "
                f"base before adding significant speed work."
            )
        
        if not ready_for_speed:
            insights.append(
                "⚠️ NOT READY for speed work yet. Must address strength, mobility, and "
                "balance deficits first to prevent injury."
            )
        else:
            insights.append(
                "✅ Ready for progressive speed work! Foundation is solid enough to safely "
                "add intervals and tempo runs."
            )
        
        # Strength insights
        if strength.estimated_weeks_to_target >= 12:
            insights.append(
                f"💪 Significant strength deficits detected. Need {strength.estimated_weeks_to_target} "
                f"weeks of 3x/week strength training to build glutes, core, and single-leg "
                f"stability. This is CRITICAL for injury prevention."
            )
        
        # Mobility insights
        if mobility.estimated_weeks_to_target >= 8:
            insights.append(
                f"🧘 Mobility limitations detected. DAILY mobility work required for "
                f"{mobility.estimated_weeks_to_target} weeks minimum. Hip flexor tightness "
                f"and limited ankle ROM reduce stride efficiency and increase injury risk."
            )
        
        # Balance insights
        if balance.injury_risk_score > 50:
            insights.append(
                f"⚖️ Balance/stability needs improvement (risk score: {balance.injury_risk_score:.0f}/100). "
                f"Add 2x/week dedicated balance work to reduce injury risk."
            )
        
        # Mental insights
        if mental.pacing_discipline in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            insights.append(
                "🧠 Pacing discipline is a limiting factor. Practice even-paced runs, check "
                "pace every 3 km, and do visualization work. This takes 8-12 weeks to develop."
            )
        
        # Recovery insights
        if recovery.recovery_score < 70:
            insights.append(
                f"😴 Recovery capacity is suboptimal ({recovery.recovery_score:.0f}/100). "
                f"Prioritize 7.5-8 hrs sleep and stress management. Poor recovery limits "
                f"training adaptation."
            )
        
        return insights
    
    def _identify_limiting_factors(
        self,
        running: RunningFitnessMetrics,
        strength: StrengthMetrics,
        mobility: MobilityROMMetrics,
        balance: BalanceMetrics,
        mental: MentalReadinessMetrics,
        recovery: RecoveryMetrics
    ) -> List[str]:
        """Identify what's limiting improvement"""
        
        limiting = []
        
        if strength.estimated_weeks_to_target >= 12:
            limiting.append(
                "Weak glutes/core preventing safe progression to speed work"
            )
        
        if mobility.hip_flexor_mobility in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            limiting.append(
                "Hip flexor tightness reducing stride length and efficiency"
            )
        
        if mobility.ankle_rom in [DimensionLevel.POOR, DimensionLevel.FAIR]:
            limiting.append(
                "Limited ankle ROM reducing power transfer and increasing calf strain"
            )
        
        if balance.injury_risk_score > 60:
            limiting.append(
                "Poor balance/stability creating high injury risk"
            )
        
        if mental.pacing_discipline == DimensionLevel.POOR:
            limiting.append(
                "Poor pacing discipline causing severe fade in races"
            )
        
        if recovery.recovery_score < 60:
            limiting.append(
                "Insufficient recovery limiting training adaptation"
            )
        
        if not limiting:
            limiting.append("No major limiting factors - ready for progressive training")
        
        return limiting


def print_comprehensive_assessment(assessment: ComprehensiveFitnessAssessment):
    """Pretty print comprehensive fitness assessment"""
    
    print("\n" + "="*80)
    print("COMPREHENSIVE FITNESS ASSESSMENT (HOLISTIC)")
    print("="*80)
    
    print(f"\n🎯 OVERALL FITNESS SCORE: {assessment.overall_fitness_score:.1f}/100")
    print(f"   Speed Work Ready: {'✅ YES' if assessment.readiness_for_speed_work else '❌ NO'}")
    print(f"   Injury Risk: {assessment.injury_risk_level.upper()}")
    
    print(f"\n🏃 RUNNING FITNESS:")
    rf = assessment.running_fitness
    print(f"   VO2max Estimate: {rf.vo2max_estimate:.1f} ml/kg/min")
    print(f"   Endurance Score: {rf.endurance_score:.0f}/100")
    print(f"   Speed Score: {rf.speed_score:.0f}/100")
    print(f"   Weekly Volume: {rf.weekly_volume:.1f} km")
    print(f"   Consistency: {rf.consistency:.1f} runs/week")
    
    print(f"\n💪 STRENGTH:")
    s = assessment.strength
    print(f"   Core Strength: {s.core_strength.value.title()}")
    print(f"   Lower Body: {s.lower_body_strength.value.title()}")
    print(f"   Single-Leg Stability: {s.single_leg_stability.value.title()}")
    print(f"   Weeks to Target: {s.estimated_weeks_to_target}")
    
    print(f"\n🧘 MOBILITY/ROM:")
    m = assessment.mobility_rom
    print(f"   Hip Flexors: {m.hip_flexor_mobility.value.title()}")
    print(f"   Ankle ROM: {m.ankle_rom.value.title()}")
    print(f"   Overall Flexibility: {m.overall_flexibility.value.title()}")
    print(f"   Stride Efficiency: {m.stride_efficiency_score:.0f}/100")
    print(f"   Weeks to Target: {m.estimated_weeks_to_target}")
    
    print(f"\n⚖️ BALANCE/STABILITY:")
    b = assessment.balance
    print(f"   Stability Score: {b.stability_score:.0f}/100")
    print(f"   Injury Risk Score: {b.injury_risk_score:.0f}/100")
    print(f"   Asymmetry Detected: {'⚠️ YES' if b.asymmetry_detected else '✅ NO'}")
    
    print(f"\n🧠 MENTAL READINESS:")
    mn = assessment.mental_readiness
    print(f"   Pacing Discipline: {mn.pacing_discipline.value.title()}")
    print(f"   Race Anxiety: {mn.race_anxiety_level.title()}")
    print(f"   Mental Toughness: {mn.mental_toughness.value.title()}")
    
    print(f"\n💤 RECOVERY:")
    r = assessment.recovery
    print(f"   Sleep Quality: {r.sleep_quality.value.title()}")
    print(f"   Stress Level: {r.stress_level.title()}")
    print(f"   Recovery Score: {r.recovery_score:.0f}/100")
    
    print(f"\n⏱️ TIMELINE ASSESSMENT:")
    if assessment.foundation_phase_needed:
        print(f"   ⚠️ Foundation Phase REQUIRED: {assessment.foundation_phase_weeks} weeks")
    else:
        print(f"   ✅ No foundation phase needed")
    print(f"   Total Estimated Weeks to Goal: {assessment.total_estimated_weeks} weeks "
          f"({assessment.total_estimated_weeks // 4} months)")
    
    print(f"\n🎯 PRIMARY FOCUS AREAS:")
    for area in assessment.primary_focus_areas:
        print(f"   🔴 {area}")
    
    print(f"\n📋 SECONDARY FOCUS AREAS:")
    for area in assessment.secondary_focus_areas:
        print(f"   🟡 {area}")
    
    print(f"\n📅 TRAINING RECOMMENDATIONS:")
    print(f"   Strength Training: {assessment.strength_training_frequency}x per week")
    print(f"   Mobility Work: {assessment.mobility_frequency}")
    print(f"   Mental Training: {'✅ YES - needed' if assessment.mental_training_needed else '➖ Optional'}")
    
    if assessment.key_insights:
        print(f"\n💡 KEY INSIGHTS:")
        for insight in assessment.key_insights:
            print(f"   {insight}")
    
    if assessment.limiting_factors:
        print(f"\n🚧 LIMITING FACTORS:")
        for factor in assessment.limiting_factors:
            print(f"   ⚠️ {factor}")
    
    print("\n" + "="*80 + "\n")


# Example usage
if __name__ == "__main__":
    # Example: Rajesh's assessment
    analyzer = FitnessAnalyzer()
    
    assessment = analyzer.analyze_comprehensive_fitness(
        # Running data
        recent_race_pace_seconds=375,  # 6:15/km
        training_pace_seconds=405,  # 6:45/km
        weekly_volume=40.0,
        consistency=4.2,
        longest_run=18.0,
        race_distance_km=21.1,
        
        # Strength indicators (estimated from roadmap)
        plank_hold_seconds=45,  # Weak core
        single_leg_squat_reps=5,  # Weak glutes
        
        # Mobility indicators
        stride_length_cm=None,
        cadence=165,  # Low cadence = mobility issues
        
        # Lifestyle
        avg_sleep_hours=6.5,  # Needs improvement
        stress_level="moderate",
        
        # Mental (from race splits showing severe fade)
        pacing_variance=70.0,  # High variance
        
        # Goal
        goal_pace_seconds=340,  # 5:40/km
        goal_distance_km=21.1
    )
    
    print_comprehensive_assessment(assessment)
