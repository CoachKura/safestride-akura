"""
Race Analyzer Module
Analyzes existing race records from Strava/Garmin to assess current fitness and recommend goals.

This module evaluates:
- Race performance (pace, HR, splits)
- Racing patterns (pacing discipline, fade analysis)
- Historical performance trends
- Goal feasibility based on current state
- Realistic timeline estimation
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from enum import Enum


class RaceType(Enum):
    """Supported race distances"""
    FIVE_K = "5K"
    TEN_K = "10K"
    HALF_MARATHON = "Half Marathon"
    MARATHON = "Marathon"


class FitnessLevel(Enum):
    """Athlete fitness classification"""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    ELITE = "elite"


class GoalAggression(Enum):
    """Goal timeline aggression levels"""
    CONSERVATIVE = "conservative"
    REALISTIC = "realistic"
    AGGRESSIVE = "aggressive"


@dataclass
class RaceSplit:
    """Individual race split data"""
    km: int
    pace: str  # Format: "6:15/km"
    pace_seconds: int  # Pace in seconds per km
    hr: Optional[int] = None


@dataclass
class RaceRecord:
    """Complete race record"""
    race_type: RaceType
    date: datetime
    finish_time: str  # Format: "02:12:00" (HH:MM:SS)
    finish_time_seconds: int
    avg_pace: str  # Format: "6:15/km"
    avg_pace_seconds: int
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    splits: List[RaceSplit] = None
    elevation_gain: Optional[int] = None
    weather_temp: Optional[int] = None
    
    @property
    def distance_km(self) -> float:
        """Get race distance in kilometers"""
        distances = {
            RaceType.FIVE_K: 5.0,
            RaceType.TEN_K: 10.0,
            RaceType.HALF_MARATHON: 21.1,
            RaceType.MARATHON: 42.2
        }
        return distances[self.race_type]


@dataclass
class TrainingHistory:
    """90-day training history from Strava/Garmin"""
    total_runs: int
    total_distance: float
    avg_weekly_volume: float
    longest_run: float
    avg_pace: str
    avg_pace_seconds: int
    consistency: float  # Runs per week
    easy_run_percentage: float  # % of runs at easy pace
    
    
@dataclass
class RaceAnalysisResult:
    """Complete race analysis output"""
    # Current State
    fitness_level: FitnessLevel
    fitness_confidence: float  # 0-100%
    
    # Race Performance Analysis
    pacing_discipline: str  # "poor", "fair", "good", "excellent"
    pacing_score: float  # 0-100
    hr_efficiency: str  # "poor", "fair", "good", "excellent"
    hr_efficiency_score: float  # 0-100
    fade_analysis: Dict[str, any]
    
    # Strengths & Weaknesses
    strengths: List[str]
    weaknesses: List[str]
    
    # Goal Recommendations
    recommended_goals: Dict[str, Dict]  # conservative/realistic/aggressive
    
    # Timeline Assessment
    timeline_estimate: Dict[str, int]  # min_days, optimal_days, max_days
    
    # Detailed Insights
    insights: List[str]
    warnings: List[str]


class RaceAnalyzer:
    """
    Analyzes race records to assess fitness and recommend improvement goals.
    
    Uses race splits, HR data, and training history to provide comprehensive
    assessment of current fitness level and realistic improvement potential.
    """
    
    def __init__(self):
        """Initialize race analyzer"""
        self.race_distance_factors = {
            RaceType.FIVE_K: 1.0,
            RaceType.TEN_K: 1.05,
            RaceType.HALF_MARATHON: 1.12,
            RaceType.MARATHON: 1.20
        }
    
    def analyze_race(
        self,
        race: RaceRecord,
        training_history: Optional[TrainingHistory] = None,
        athlete_max_hr: Optional[int] = None,
        athlete_age: Optional[int] = None
    ) -> RaceAnalysisResult:
        """
        Comprehensive race analysis.
        
        Args:
            race: Race record to analyze
            training_history: Optional 90-day training history
            athlete_max_hr: Optional athlete max HR
            athlete_age: Optional athlete age for HR calculations
            
        Returns:
            RaceAnalysisResult with complete analysis
        """
        # Calculate max HR if not provided
        if not athlete_max_hr and athlete_age:
            athlete_max_hr = 220 - athlete_age
        
        # Analyze race performance
        fitness_level, fitness_confidence = self._assess_fitness_level(race, training_history)
        pacing_discipline, pacing_score = self._analyze_pacing(race)
        hr_efficiency, hr_efficiency_score = self._analyze_hr_efficiency(race, athlete_max_hr)
        fade_analysis = self._analyze_fade(race)
        
        # Identify strengths and weaknesses
        strengths, weaknesses = self._identify_strengths_weaknesses(
            race, training_history, pacing_score, hr_efficiency_score, fade_analysis
        )
        
        # Generate goal recommendations
        recommended_goals = self._recommend_goals(race, fitness_level, training_history)
        
        # Estimate timeline
        timeline_estimate = self._estimate_timeline(
            race, fitness_level, training_history, weaknesses
        )
        
        # Generate insights and warnings
        insights = self._generate_insights(
            race, fitness_level, pacing_discipline, hr_efficiency, fade_analysis
        )
        warnings = self._generate_warnings(
            race, hr_efficiency_score, fade_analysis, weaknesses
        )
        
        return RaceAnalysisResult(
            fitness_level=fitness_level,
            fitness_confidence=fitness_confidence,
            pacing_discipline=pacing_discipline,
            pacing_score=pacing_score,
            hr_efficiency=hr_efficiency,
            hr_efficiency_score=hr_efficiency_score,
            fade_analysis=fade_analysis,
            strengths=strengths,
            weaknesses=weaknesses,
            recommended_goals=recommended_goals,
            timeline_estimate=timeline_estimate,
            insights=insights,
            warnings=warnings
        )
    
    def _assess_fitness_level(
        self,
        race: RaceRecord,
        training_history: Optional[TrainingHistory]
    ) -> Tuple[FitnessLevel, float]:
        """
        Assess athlete fitness level based on race performance and training.
        
        Returns:
            Tuple of (FitnessLevel, confidence_score)
        """
        pace_seconds = race.avg_pace_seconds
        distance = race.distance_km
        
        # Fitness benchmarks (pace in seconds per km)
        # These are approximate benchmarks for different fitness levels
        benchmarks = {
            RaceType.FIVE_K: {
                FitnessLevel.BEGINNER: 420,      # 7:00/km
                FitnessLevel.INTERMEDIATE: 330,  # 5:30/km
                FitnessLevel.ADVANCED: 270,      # 4:30/km
                FitnessLevel.ELITE: 210          # 3:30/km
            },
            RaceType.TEN_K: {
                FitnessLevel.BEGINNER: 450,      # 7:30/km
                FitnessLevel.INTERMEDIATE: 360,  # 6:00/km
                FitnessLevel.ADVANCED: 300,      # 5:00/km
                FitnessLevel.ELITE: 240          # 4:00/km
            },
            RaceType.HALF_MARATHON: {
                FitnessLevel.BEGINNER: 480,      # 8:00/km
                FitnessLevel.INTERMEDIATE: 375,  # 6:15/km
                FitnessLevel.ADVANCED: 315,      # 5:15/km
                FitnessLevel.ELITE: 255          # 4:15/km
            },
            RaceType.MARATHON: {
                FitnessLevel.BEGINNER: 510,      # 8:30/km
                FitnessLevel.INTERMEDIATE: 405,  # 6:45/km
                FitnessLevel.ADVANCED: 330,      # 5:30/km
                FitnessLevel.ELITE: 270          # 4:30/km
            }
        }
        
        race_benchmarks = benchmarks[race.race_type]
        
        # Determine fitness level based on pace
        if pace_seconds >= race_benchmarks[FitnessLevel.BEGINNER]:
            fitness_level = FitnessLevel.BEGINNER
        elif pace_seconds >= race_benchmarks[FitnessLevel.INTERMEDIATE]:
            fitness_level = FitnessLevel.INTERMEDIATE
        elif pace_seconds >= race_benchmarks[FitnessLevel.ADVANCED]:
            fitness_level = FitnessLevel.ADVANCED
        else:
            fitness_level = FitnessLevel.ELITE
        
        # Calculate confidence based on training history
        confidence = 70.0  # Base confidence
        
        if training_history:
            # Higher consistency = higher confidence
            if training_history.consistency >= 4.5:
                confidence += 15
            elif training_history.consistency >= 3.5:
                confidence += 10
            elif training_history.consistency < 2.5:
                confidence -= 10
            
            # Appropriate weekly volume = higher confidence
            expected_volume = distance * 2.5  # Rough guideline
            if training_history.avg_weekly_volume >= expected_volume:
                confidence += 10
            elif training_history.avg_weekly_volume < expected_volume * 0.7:
                confidence -= 15
            
            # Training pace alignment
            if abs(training_history.avg_pace_seconds - pace_seconds) <= 30:
                confidence += 5
        
        confidence = max(50.0, min(100.0, confidence))
        
        return fitness_level, confidence
    
    def _analyze_pacing(self, race: RaceRecord) -> Tuple[str, float]:
        """
        Analyze pacing discipline from race splits.
        
        Returns:
            Tuple of (discipline_description, pacing_score)
        """
        if not race.splits or len(race.splits) < 3:
            return "unknown", 50.0
        
        # Calculate pace variance
        pace_values = [split.pace_seconds for split in race.splits]
        avg_pace = sum(pace_values) / len(pace_values)
        variance = sum((p - avg_pace) ** 2 for p in pace_values) / len(pace_values)
        std_dev = variance ** 0.5
        
        # Calculate first half vs second half
        mid_point = len(race.splits) // 2
        first_half_avg = sum(pace_values[:mid_point]) / mid_point
        second_half_avg = sum(pace_values[mid_point:]) / (len(pace_values) - mid_point)
        fade = second_half_avg - first_half_avg
        
        # Scoring
        score = 100.0
        
        # Penalize high variance (inconsistent pacing)
        if std_dev > 30:
            score -= 30
        elif std_dev > 20:
            score -= 20
        elif std_dev > 10:
            score -= 10
        else:
            score -= std_dev * 0.5
        
        # Penalize fade (second half slower)
        if fade > 30:  # More than 30 sec/km slower
            score -= 30
        elif fade > 20:
            score -= 20
        elif fade > 10:
            score -= 10
        # Reward negative split
        elif fade < -10:
            score += 10
        
        score = max(0.0, min(100.0, score))
        
        # Categorize discipline
        if score >= 85:
            discipline = "excellent"
        elif score >= 70:
            discipline = "good"
        elif score >= 50:
            discipline = "fair"
        else:
            discipline = "poor"
        
        return discipline, score
    
    def _analyze_hr_efficiency(
        self,
        race: RaceRecord,
        athlete_max_hr: Optional[int]
    ) -> Tuple[str, float]:
        """
        Analyze heart rate efficiency during race.
        
        Returns:
            Tuple of (efficiency_description, efficiency_score)
        """
        if not race.avg_hr or not athlete_max_hr:
            return "unknown", 50.0
        
        # Calculate HR percentage
        hr_percentage = (race.avg_hr / athlete_max_hr) * 100
        
        # Optimal race HR is typically 80-85% for sustainable efforts
        optimal_range = (80, 87)
        
        score = 100.0
        
        if hr_percentage < optimal_range[0]:
            # Too low - not pushing hard enough
            deficit = optimal_range[0] - hr_percentage
            score -= deficit * 2
            efficiency = "suboptimal"
        elif hr_percentage > optimal_range[1]:
            # Too high - unsustainable effort
            excess = hr_percentage - optimal_range[1]
            if excess > 7:
                score -= 40
                efficiency = "poor"
            elif excess > 5:
                score -= 25
                efficiency = "fair"
            else:
                score -= excess * 3
                efficiency = "fair"
        else:
            # In optimal range
            efficiency = "excellent" if hr_percentage <= 85 else "good"
            score = 95.0
        
        score = max(0.0, min(100.0, score))
        
        return efficiency, score
    
    def _analyze_fade(self, race: RaceRecord) -> Dict[str, any]:
        """
        Analyze pace fade throughout race.
        
        Returns:
            Dictionary with fade analysis details
        """
        if not race.splits or len(race.splits) < 4:
            return {
                "has_data": False,
                "fade_type": "unknown",
                "fade_amount": 0,
                "fade_percentage": 0.0
            }
        
        pace_values = [split.pace_seconds for split in race.splits]
        
        # Calculate quartile averages
        q_size = len(pace_values) // 4
        q1_avg = sum(pace_values[:q_size]) / q_size
        q4_avg = sum(pace_values[-q_size:]) / q_size
        
        fade_amount = q4_avg - q1_avg
        fade_percentage = (fade_amount / q1_avg) * 100
        
        # Classify fade
        if fade_amount < -5:
            fade_type = "negative_split"  # Getting faster!
        elif fade_amount <= 5:
            fade_type = "even_pace"
        elif fade_amount <= 15:
            fade_type = "mild_fade"
        elif fade_amount <= 30:
            fade_type = "moderate_fade"
        else:
            fade_type = "severe_fade"
        
        return {
            "has_data": True,
            "fade_type": fade_type,
            "fade_amount": fade_amount,
            "fade_percentage": fade_percentage,
            "first_quartile_pace": q1_avg,
            "last_quartile_pace": q4_avg
        }
    
    def _identify_strengths_weaknesses(
        self,
        race: RaceRecord,
        training_history: Optional[TrainingHistory],
        pacing_score: float,
        hr_efficiency_score: float,
        fade_analysis: Dict
    ) -> Tuple[List[str], List[str]]:
        """Identify athlete strengths and weaknesses"""
        strengths = []
        weaknesses = []
        
        # Pacing analysis
        if pacing_score >= 85:
            strengths.append("Excellent pacing discipline")
        elif pacing_score < 50:
            weaknesses.append("Poor pacing discipline - starts too fast")
        
        # HR efficiency
        if hr_efficiency_score >= 85:
            strengths.append("Good heart rate control")
        elif hr_efficiency_score < 50:
            if race.avg_hr and race.max_hr:
                hr_pct = (race.avg_hr / race.max_hr) * 100
                if hr_pct > 90:
                    weaknesses.append("Racing too hard (unsustainable HR)")
                else:
                    weaknesses.append("Suboptimal race effort (HR too low)")
        
        # Fade analysis
        if fade_analysis.get("has_data"):
            fade_type = fade_analysis["fade_type"]
            if fade_type == "negative_split":
                strengths.append("Excellent endurance - negative split")
            elif fade_type in ["moderate_fade", "severe_fade"]:
                weaknesses.append("Significant pace fade in later stages")
        
        # Training history
        if training_history:
            if training_history.consistency >= 4.5:
                strengths.append("Highly consistent training")
            elif training_history.consistency < 2.5:
                weaknesses.append("Inconsistent training frequency")
            
            if training_history.longest_run >= race.distance_km * 0.8:
                strengths.append("Good base endurance")
            elif training_history.longest_run < race.distance_km * 0.6:
                weaknesses.append("Insufficient long run distance")
            
            # Pace variety
            if training_history.easy_run_percentage < 60:
                weaknesses.append("Not enough easy pace training")
        
        # Ensure we have at least some content
        if not strengths:
            strengths.append("Completed race distance")
        
        if not weaknesses:
            weaknesses.append("No specific issues identified")
        
        return strengths, weaknesses
    
    def _recommend_goals(
        self,
        race: RaceRecord,
        fitness_level: FitnessLevel,
        training_history: Optional[TrainingHistory]
    ) -> Dict[str, Dict]:
        """
        Recommend improvement goals at different aggression levels.
        
        Returns:
            Dictionary with conservative/realistic/aggressive goals
        """
        current_time_seconds = race.finish_time_seconds
        
        # Improvement percentages based on fitness level
        improvement_factors = {
            FitnessLevel.BEGINNER: {
                GoalAggression.CONSERVATIVE: 0.05,  # 5% faster
                GoalAggression.REALISTIC: 0.10,     # 10% faster
                GoalAggression.AGGRESSIVE: 0.15     # 15% faster
            },
            FitnessLevel.INTERMEDIATE: {
                GoalAggression.CONSERVATIVE: 0.03,  # 3% faster
                GoalAggression.REALISTIC: 0.07,     # 7% faster
                GoalAggression.AGGRESSIVE: 0.12     # 12% faster
            },
            FitnessLevel.ADVANCED: {
                GoalAggression.CONSERVATIVE: 0.02,  # 2% faster
                GoalAggression.REALISTIC: 0.05,     # 5% faster
                GoalAggression.AGGRESSIVE: 0.08     # 8% faster
            },
            FitnessLevel.ELITE: {
                GoalAggression.CONSERVATIVE: 0.01,  # 1% faster
                GoalAggression.REALISTIC: 0.03,     # 3% faster
                GoalAggression.AGGRESSIVE: 0.05     # 5% faster
            }
        }
        
        factors = improvement_factors[fitness_level]
        goals = {}
        
        for aggression, factor in factors.items():
            improvement_seconds = int(current_time_seconds * factor)
            goal_time_seconds = current_time_seconds - improvement_seconds
            
            # Convert to time format
            goal_time_str = self._seconds_to_time_str(goal_time_seconds)
            
            # Calculate goal pace
            goal_pace_seconds = goal_time_seconds / race.distance_km
            goal_pace_str = self._seconds_to_pace_str(int(goal_pace_seconds))
            
            # Estimate timeline
            timeline_multiplier = {
                GoalAggression.CONSERVATIVE: 1.0,
                GoalAggression.REALISTIC: 1.3,
                GoalAggression.AGGRESSIVE: 1.6
            }
            
            base_weeks = int(factor * 400)  # Rough estimate
            timeline_weeks = int(base_weeks * timeline_multiplier[aggression])
            
            goals[aggression.value] = {
                "goal_time": goal_time_str,
                "goal_pace": goal_pace_str,
                "improvement_seconds": improvement_seconds,
                "improvement_percentage": factor * 100,
                "timeline_weeks": timeline_weeks,
                "timeline_days": timeline_weeks * 7
            }
        
        return goals
    
    def _estimate_timeline(
        self,
        race: RaceRecord,
        fitness_level: FitnessLevel,
        training_history: Optional[TrainingHistory],
        weaknesses: List[str]
    ) -> Dict[str, int]:
        """
        Estimate realistic timeline for improvement.
        
        Factors in:
        - Current fitness level
        - Training consistency
        - Number of weaknesses to address
        - Base building requirements
        """
        # Base timeline by fitness level (days)
        base_timelines = {
            FitnessLevel.BEGINNER: 180,
            FitnessLevel.INTERMEDIATE: 150,
            FitnessLevel.ADVANCED: 120,
            FitnessLevel.ELITE: 90
        }
        
        base_days = base_timelines[fitness_level]
        
        # Adjust for weaknesses
        weakness_keywords = {
            "strength": 60,
            "mobility": 45,
            "ROM": 45,
            "pacing": 30,
            "HR": 30,
            "inconsistent": 45,
            "fade": 30,
            "insufficient": 45
        }
        
        additional_days = 0
        for weakness in weaknesses:
            for keyword, days in weakness_keywords.items():
                if keyword.lower() in weakness.lower():
                    additional_days += days
                    break
        
        # Cap additional days
        additional_days = min(additional_days, 120)
        
        # Adjust for training history
        if training_history:
            if training_history.consistency < 3.0:
                additional_days += 30  # Need consistency building
            if training_history.avg_weekly_volume < race.distance_km * 2:
                additional_days += 45  # Need volume building
        
        optimal_days = base_days + additional_days
        min_days = int(optimal_days * 0.8)
        max_days = int(optimal_days * 1.4)
        
        return {
            "min_days": min_days,
            "optimal_days": optimal_days,
            "max_days": max_days,
            "min_weeks": min_days // 7,
            "optimal_weeks": optimal_days // 7,
            "max_weeks": max_days // 7
        }
    
    def _generate_insights(
        self,
        race: RaceRecord,
        fitness_level: FitnessLevel,
        pacing_discipline: str,
        hr_efficiency: str,
        fade_analysis: Dict
    ) -> List[str]:
        """Generate actionable insights"""
        insights = []
        
        # Fitness level insight
        insights.append(
            f"Current fitness level: {fitness_level.value.title()} - "
            f"This determines your improvement potential and timeline."
        )
        
        # Pacing insights
        if pacing_discipline == "poor":
            insights.append(
                "Your pacing discipline needs work. Starting too fast is the #1 reason "
                "for poor race performance. Practice even pacing in training."
            )
        elif pacing_discipline == "excellent":
            insights.append(
                "Excellent pacing discipline! You maintained consistent effort "
                "throughout the race. This is a key strength."
            )
        
        # HR insights
        if hr_efficiency == "poor" and race.avg_hr:
            if race.max_hr:
                hr_pct = (race.avg_hr / race.max_hr) * 100
                if hr_pct > 90:
                    insights.append(
                        f"You raced at {hr_pct:.0f}% HR - too high for sustainable effort. "
                        f"Target 80-85% HR for optimal performance. Training at lower HR "
                        f"will build aerobic efficiency."
                    )
        
        # Fade insights
        if fade_analysis.get("has_data"):
            fade_type = fade_analysis["fade_type"]
            if fade_type == "severe_fade":
                fade_pct = fade_analysis["fade_percentage"]
                insights.append(
                    f"You faded {fade_pct:.1f}% in the final quarter. This suggests either "
                    f"starting too fast or insufficient endurance. Focus on negative split "
                    f"training and zone 2 base building."
                )
            elif fade_type == "negative_split":
                insights.append(
                    "Impressive negative split! You held back early and finished strong. "
                    "This shows good race strategy and solid endurance."
                )
        
        return insights
    
    def _generate_warnings(
        self,
        race: RaceRecord,
        hr_efficiency_score: float,
        fade_analysis: Dict,
        weaknesses: List[str]
    ) -> List[str]:
        """Generate important warnings"""
        warnings = []
        
        # HR warning
        if hr_efficiency_score < 50:
            warnings.append(
                "⚠️ Your heart rate during the race suggests unsustainable effort. "
                "This increases injury risk and limits performance. Prioritize HR zone training."
            )
        
        # Severe fade warning
        if fade_analysis.get("fade_type") == "severe_fade":
            warnings.append(
                "⚠️ Severe pace fade detected. This pattern significantly limits improvement "
                "potential. Must address pacing discipline and endurance base before pursuing "
                "faster times."
            )
        
        # Multiple weaknesses warning
        critical_weaknesses = [w for w in weaknesses if any(
            keyword in w.lower() for keyword in ["strength", "mobility", "inconsistent", "insufficient"]
        )]
        
        if len(critical_weaknesses) >= 3:
            warnings.append(
                "⚠️ Multiple foundational weaknesses identified. Recommend 12-16 week "
                "foundation phase (strength, mobility, consistency) before pursuing "
                "aggressive time goals."
            )
        
        return warnings
    
    @staticmethod
    def _seconds_to_time_str(total_seconds: int) -> str:
        """Convert seconds to HH:MM:SS format"""
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    
    @staticmethod
    def _seconds_to_pace_str(seconds_per_km: int) -> str:
        """Convert seconds per km to MM:SS/km format"""
        minutes = seconds_per_km // 60
        seconds = seconds_per_km % 60
        return f"{minutes}:{seconds:02d}/km"
    
    @staticmethod
    def time_str_to_seconds(time_str: str) -> int:
        """Convert HH:MM:SS to total seconds"""
        parts = time_str.split(":")
        if len(parts) == 3:
            hours, minutes, seconds = map(int, parts)
            return hours * 3600 + minutes * 60 + seconds
        elif len(parts) == 2:
            minutes, seconds = map(int, parts)
            return minutes * 60 + seconds
        else:
            raise ValueError(f"Invalid time format: {time_str}")
    
    @staticmethod
    def pace_str_to_seconds(pace_str: str) -> int:
        """Convert MM:SS/km to seconds per km"""
        pace_str = pace_str.replace("/km", "").strip()
        parts = pace_str.split(":")
        minutes, seconds = map(int, parts)
        return minutes * 60 + seconds


def print_race_analysis(result: RaceAnalysisResult):
    """Pretty print race analysis results"""
    print("\n" + "="*70)
    print("RACE ANALYSIS REPORT")
    print("="*70)
    
    print(f"\n📊 FITNESS ASSESSMENT")
    print(f"   Level: {result.fitness_level.value.title()}")
    print(f"   Confidence: {result.fitness_confidence:.0f}%")
    
    print(f"\n🎯 RACE PERFORMANCE")
    print(f"   Pacing Discipline: {result.pacing_discipline.title()} ({result.pacing_score:.0f}/100)")
    print(f"   HR Efficiency: {result.hr_efficiency.title()} ({result.hr_efficiency_score:.0f}/100)")
    
    if result.fade_analysis.get("has_data"):
        fade = result.fade_analysis
        print(f"   Fade Analysis: {fade['fade_type'].replace('_', ' ').title()}")
        print(f"   Fade Amount: {fade['fade_amount']:.0f} seconds/km ({fade['fade_percentage']:.1f}%)")
    
    print(f"\n💪 STRENGTHS:")
    for strength in result.strengths:
        print(f"   ✓ {strength}")
    
    print(f"\n⚠️  WEAKNESSES:")
    for weakness in result.weaknesses:
        print(f"   ✗ {weakness}")
    
    print(f"\n🎯 RECOMMENDED GOALS:")
    for level, goal in result.recommended_goals.items():
        print(f"\n   {level.upper()}:")
        print(f"      Goal Time: {goal['goal_time']} ({goal['goal_pace']})")
        print(f"      Improvement: {goal['improvement_seconds']}s ({goal['improvement_percentage']:.1f}%)")
        print(f"      Timeline: {goal['timeline_weeks']} weeks ({goal['timeline_days']} days)")
    
    print(f"\n⏱️  TIMELINE ESTIMATE:")
    timeline = result.timeline_estimate
    print(f"   Minimum: {timeline['min_weeks']} weeks ({timeline['min_days']} days)")
    print(f"   Optimal: {timeline['optimal_weeks']} weeks ({timeline['optimal_days']} days)")
    print(f"   Maximum: {timeline['max_weeks']} weeks ({timeline['max_days']} days)")
    
    if result.insights:
        print(f"\n💡 KEY INSIGHTS:")
        for insight in result.insights:
            print(f"   • {insight}")
    
    if result.warnings:
        print(f"\n⚠️  IMPORTANT WARNINGS:")
        for warning in result.warnings:
            print(f"   {warning}")
    
    print("\n" + "="*70 + "\n")


# Example usage
if __name__ == "__main__":
    # Example: Rajesh's HM race (as described in roadmap)
    race = RaceRecord(
        race_type=RaceType.HALF_MARATHON,
        date=datetime(2025, 11, 15),
        finish_time="02:12:00",
        finish_time_seconds=RaceAnalyzer.time_str_to_seconds("02:12:00"),
        avg_pace="6:15/km",
        avg_pace_seconds=RaceAnalyzer.pace_str_to_seconds("6:15/km"),
        avg_hr=175,
        max_hr=190,
        splits=[
            RaceSplit(1, "5:50/km", RaceAnalyzer.pace_str_to_seconds("5:50/km"), 165),
            RaceSplit(5, "6:10/km", RaceAnalyzer.pace_str_to_seconds("6:10/km"), 172),
            RaceSplit(10, "6:20/km", RaceAnalyzer.pace_str_to_seconds("6:20/km"), 178),
            RaceSplit(15, "6:40/km", RaceAnalyzer.pace_str_to_seconds("6:40/km"), 182),
            RaceSplit(21, "7:00/km", RaceAnalyzer.pace_str_to_seconds("7:00/km"), 185),
        ]
    )
    
    training_history = TrainingHistory(
        total_runs=38,
        total_distance=360.0,
        avg_weekly_volume=40.0,
        longest_run=18.0,
        avg_pace="6:45/km",
        avg_pace_seconds=RaceAnalyzer.pace_str_to_seconds("6:45/km"),
        consistency=4.2,
        easy_run_percentage=75.0
    )
    
    # Run analysis
    analyzer = RaceAnalyzer()
    result = analyzer.analyze_race(
        race=race,
        training_history=training_history,
        athlete_max_hr=190,
        athlete_age=32
    )
    
    # Print results
    print_race_analysis(result)
