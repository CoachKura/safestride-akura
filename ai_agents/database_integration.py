"""
Database Integration Layer
Connects all analysis modules to Supabase athlete_lifecycle tables.

Provides CRUD operations for:
- Athlete profiles and detailed information
- Race analysis results
- Fitness assessments
- Workout assignments and results
- Performance tracking
- Ability progression
"""

import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from supabase import create_client, Client
import json
from dotenv import load_dotenv

# Import our analysis modules
from race_analyzer import RaceAnalyzer, RaceRecord, RaceAnalysisResult, RaceType
from fitness_analyzer import FitnessAnalyzer, ComprehensiveFitnessAssessment, DimensionLevel
from performance_tracker import PerformanceTracker, WorkoutTarget, WorkoutResult, PerformanceAssessment, WorkoutType, PerformanceLabel
from adaptive_workout_generator import AdaptiveWorkoutGenerator, AthleteAbility, PerformanceHistory, TrainingPhase, GeneratedWorkout

# Load environment variables
load_dotenv()


class DatabaseIntegration:
    """
    Database integration layer for athlete lifecycle management.
    
    Connects all analysis modules to Supabase tables:
    - athlete_detailed_profile
    - baseline_assessment_plan
    - workout_assignments
    - workout_results
    - ability_progression
    - race_history
    """
    
    def __init__(self):
        """Initialize Supabase client"""
        supabase_url = os.getenv("SUPABASE_URL")
        # Support multiple key environment variable names
        supabase_key = (
            os.getenv("SUPABASE_KEY") or 
            os.getenv("SUPABASE_SERVICE_KEY") or 
            os.getenv("SUPABASE_ANON_KEY")
        )
        
        if not supabase_url or not supabase_key:
            raise ValueError(
                "SUPABASE_URL and SUPABASE_KEY (or SUPABASE_SERVICE_KEY/SUPABASE_ANON_KEY) "
                "must be set in environment"
            )
        
        self.supabase: Client = create_client(supabase_url, supabase_key)
        
        # Initialize analysis modules
        self.race_analyzer = RaceAnalyzer()
        self.fitness_analyzer = FitnessAnalyzer()
        self.performance_tracker = PerformanceTracker()
        self.workout_generator = AdaptiveWorkoutGenerator()
    
    # =========================================================================
    # ATHLETE PROFILE OPERATIONS
    # =========================================================================
    
    def get_athlete_profile(self, athlete_id: str) -> Optional[Dict]:
        """Get athlete detailed profile"""
        try:
            response = self.supabase.table("athlete_detailed_profile")\
                .select("*")\
                .eq("athlete_id", athlete_id)\
                .single()\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error fetching athlete profile: {e}")
            return None
    
    def create_athlete_profile(self, athlete_data: Dict) -> Dict:
        """Create new athlete profile"""
        try:
            response = self.supabase.table("athlete_detailed_profile")\
                .insert(athlete_data)\
                .execute()
            return response.data[0]
        except Exception as e:
            print(f"Error creating athlete profile: {e}")
            raise
    
    def update_athlete_profile(self, athlete_id: str, updates: Dict) -> Dict:
        """Update athlete profile"""
        updates["updated_at"] = datetime.now().isoformat()
        
        try:
            response = self.supabase.table("athlete_detailed_profile")\
                .update(updates)\
                .eq("athlete_id", athlete_id)\
                .execute()
            return response.data[0]
        except Exception as e:
            print(f"Error updating athlete profile: {e}")
            raise
    
    # =========================================================================
    # RACE ANALYSIS OPERATIONS
    # =========================================================================
    
    def store_race_analysis(
        self,
        athlete_id: str,
        race_analysis: RaceAnalysisResult
    ) -> Dict:
        """Store race analysis results in race_history table"""
        
        race_data = {
            "athlete_id": athlete_id,
            "race_date": race_analysis.race_date.isoformat() if race_analysis.race_date else None,
            "race_type": race_analysis.race_type.value,
            "distance_km": race_analysis.distance_km,
            "finish_time_seconds": race_analysis.finish_time_seconds,
            "avg_pace_seconds": race_analysis.avg_pace_seconds,
            "avg_hr": race_analysis.avg_hr,
            "max_hr": race_analysis.max_hr,
            "race_conditions": json.dumps({
                "weather": race_analysis.weather,
                "temperature": race_analysis.temperature,
                "surface": race_analysis.surface
            }),
            "splits_data": json.dumps(race_analysis.splits if race_analysis.splits else []),
            "analysis_results": json.dumps({
                "fitness_level": race_analysis.fitness_level.value,
                "fitness_confidence": race_analysis.fitness_confidence,
                "pacing_score": race_analysis.pacing_score,
                "hr_efficiency_score": race_analysis.hr_efficiency_score,
                "fade_percentage": race_analysis.fade_percentage,
                "fade_seconds_per_km": race_analysis.fade_seconds_per_km,
                "strengths": race_analysis.strengths,
                "weaknesses": race_analysis.weaknesses,
                "improvement_areas": race_analysis.improvement_areas,
                "goal_recommendations": {
                    "conservative": {
                        "time_seconds": race_analysis.recommended_goals["conservative"]["time_seconds"],
                        "improvement_pct": race_analysis.recommended_goals["conservative"]["improvement_pct"],
                        "timeline_weeks": race_analysis.recommended_goals["conservative"]["timeline_weeks"]
                    },
                    "realistic": {
                        "time_seconds": race_analysis.recommended_goals["realistic"]["time_seconds"],
                        "improvement_pct": race_analysis.recommended_goals["realistic"]["improvement_pct"],
                        "timeline_weeks": race_analysis.recommended_goals["realistic"]["timeline_weeks"]
                    },
                    "aggressive": {
                        "time_seconds": race_analysis.recommended_goals["aggressive"]["time_seconds"],
                        "improvement_pct": race_analysis.recommended_goals["aggressive"]["improvement_pct"],
                        "timeline_weeks": race_analysis.recommended_goals["aggressive"]["timeline_weeks"]
                    }
                },
                "estimated_timeline_weeks": race_analysis.estimated_timeline_weeks,
                "key_insights": race_analysis.key_insights,
                "warnings": race_analysis.warnings
            })
        }
        
        try:
            response = self.supabase.table("race_history")\
                .insert(race_data)\
                .execute()
            return response.data[0]
        except Exception as e:
            print(f"Error storing race analysis: {e}")
            raise
    
    def get_athlete_race_history(self, athlete_id: str) -> List[Dict]:
        """Get athlete's race history"""
        try:
            response = self.supabase.table("race_history")\
                .select("*")\
                .eq("athlete_id", athlete_id)\
                .order("race_date", desc=True)\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error fetching race history: {e}")
            return []
    
    # =========================================================================
    # FITNESS ASSESSMENT OPERATIONS
    # =========================================================================
    
    def store_fitness_assessment(
        self,
        athlete_id: str,
        assessment: ComprehensiveFitnessAssessment
    ) -> Dict:
        """Store comprehensive fitness assessment"""
        
        # Store in athlete_detailed_profile as additional data
        assessment_data = {
            "assessment_date": datetime.now().isoformat(),
            "overall_fitness_score": assessment.overall_fitness_score,
            "running_fitness": {
                "vo2max_estimate": assessment.running_fitness.vo2max_estimate,
                "endurance_score": assessment.running_fitness.endurance_score,
                "speed_score": assessment.running_fitness.speed_score,
                "weekly_volume": assessment.running_fitness.weekly_volume,
                "consistency": assessment.running_fitness.consistency
            },
            "strength": {
                "core": assessment.strength.core_strength.value,
                "lower_body": assessment.strength.lower_body_strength.value,
                "single_leg": assessment.strength.single_leg_stability.value,
                "weeks_to_target": assessment.strength.estimated_weeks_to_target
            },
            "mobility_rom": {
                "hip_flexors": assessment.mobility_rom.hip_flexor_mobility.value,
                "ankle_rom": assessment.mobility_rom.ankle_rom.value,
                "overall": assessment.mobility_rom.overall_flexibility.value,
                "stride_efficiency": assessment.mobility_rom.stride_efficiency_score,
                "weeks_to_target": assessment.mobility_rom.estimated_weeks_to_target
            },
            "balance": {
                "stability_score": assessment.balance.stability_score,
                "injury_risk_score": assessment.balance.injury_risk_score,
                "asymmetry_detected": assessment.balance.asymmetry_detected
            },
            "mental_readiness": {
                "pacing_discipline": assessment.mental_readiness.pacing_discipline.value,
                "race_anxiety": assessment.mental_readiness.race_anxiety_level,
                "mental_toughness": assessment.mental_readiness.mental_toughness.value
            },
            "recovery": {
                "sleep_quality": assessment.recovery.sleep_quality.value,
                "stress_level": assessment.recovery.stress_level,
                "recovery_score": assessment.recovery.recovery_score
            },
            "readiness_for_speed_work": assessment.readiness_for_speed_work,
            "injury_risk_level": assessment.injury_risk_level,
            "foundation_phase_needed": assessment.foundation_phase_needed,
            "foundation_phase_weeks": assessment.foundation_phase_weeks,
            "total_estimated_weeks": assessment.total_estimated_weeks,
            "primary_focus_areas": assessment.primary_focus_areas,
            "secondary_focus_areas": assessment.secondary_focus_areas,
            "strength_training_frequency": assessment.strength_training_frequency,
            "mobility_frequency": assessment.mobility_frequency,
            "mental_training_needed": assessment.mental_training_needed,
            "key_insights": assessment.key_insights,
            "limiting_factors": assessment.limiting_factors
        }
        
        # Update athlete profile with latest assessment
        try:
            response = self.update_athlete_profile(
                athlete_id,
                {"baseline_assessment_data": json.dumps(assessment_data)}
            )
            return response
        except Exception as e:
            print(f"Error storing fitness assessment: {e}")
            raise
    
    # =========================================================================
    # WORKOUT ASSIGNMENT OPERATIONS
    # =========================================================================
    
    def create_workout_assignment(
        self,
        athlete_id: str,
        workout: GeneratedWorkout
    ) -> Dict:
        """Create new workout assignment"""
        
        workout_data = {
            "athlete_id": athlete_id,
            "assigned_date": datetime.now().isoformat(),
            "scheduled_date": workout.workout_date.isoformat(),
            "workout_type": workout.workout_type,
            "workout_status": "assigned",
            "distance_km": workout.distance_km,
            "target_pace_seconds": workout.target_pace_seconds,
            "pace_range_min": workout.pace_range_seconds[0] if workout.pace_range_seconds else None,
            "pace_range_max": workout.pace_range_seconds[1] if workout.pace_range_seconds else None,
            "target_hr": workout.target_hr,
            "hr_range_min": workout.hr_range[0] if workout.hr_range else None,
            "hr_range_max": workout.hr_range[1] if workout.hr_range else None,
            "interval_count": workout.intervals,
            "interval_distance_m": workout.interval_distance_m,
            "interval_pace_seconds": workout.interval_pace_seconds,
            "rest_time_seconds": workout.rest_time_seconds,
            "workout_notes": workout.workout_notes,
            "coaching_cues": json.dumps(workout.coaching_cues if workout.coaching_cues else []),
            "expected_load": workout.expected_load,
            "progressive_increase_pct": workout.progressive_increase_pct,
            "acwr_projected": workout.acwr_after_workout,
            "generation_rationale": workout.generation_rationale
        }
        
        try:
            response = self.supabase.table("workout_assignments")\
                .insert(workout_data)\
                .execute()
            return response.data[0]
        except Exception as e:
            print(f"Error creating workout assignment: {e}")
            raise
    
    def get_workout_assignment(self, assignment_id: str) -> Optional[Dict]:
        """Get workout assignment by ID"""
        try:
            response = self.supabase.table("workout_assignments")\
                .select("*")\
                .eq("id", assignment_id)\
                .single()\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error fetching workout assignment: {e}")
            return None
    
    def get_athlete_workouts(
        self,
        athlete_id: str,
        status: Optional[str] = None,
        limit: int = 10
    ) -> List[Dict]:
        """Get athlete's workout assignments"""
        try:
            query = self.supabase.table("workout_assignments")\
                .select("*")\
                .eq("athlete_id", athlete_id)\
                .order("scheduled_date", desc=True)\
                .limit(limit)
            
            if status:
                query = query.eq("workout_status", status)
            
            response = query.execute()
            return response.data
        except Exception as e:
            print(f"Error fetching athlete workouts: {e}")
            return []
    
    def update_workout_status(
        self,
        assignment_id: str,
        status: str,
        notes: Optional[str] = None
    ) -> Dict:
        """Update workout status"""
        updates = {
            "workout_status": status,
            "updated_at": datetime.now().isoformat()
        }
        
        if notes:
            updates["completion_notes"] = notes
        
        if status == "completed":
            updates["completed_date"] = datetime.now().isoformat()
        
        try:
            response = self.supabase.table("workout_assignments")\
                .update(updates)\
                .eq("id", assignment_id)\
                .execute()
            return response.data[0]
        except Exception as e:
            print(f"Error updating workout status: {e}")
            raise
    
    # =========================================================================
    # WORKOUT RESULT OPERATIONS
    # =========================================================================
    
    def store_workout_result(
        self,
        assignment_id: str,
        athlete_id: str,
        result: WorkoutResult,
        assessment: PerformanceAssessment
    ) -> Dict:
        """Store workout result and performance assessment"""
        
        result_data = {
            "assignment_id": assignment_id,
            "athlete_id": athlete_id,
            "workout_date": result.completed_date.isoformat(),
            "external_id": result.workout_id,  # Strava/Garmin ID
            "data_source": "strava",  # or "garmin"
            "distance_km": result.distance_km,
            "duration_seconds": result.total_time_seconds,
            "avg_pace_seconds": result.avg_pace_seconds,
            "avg_hr": result.avg_hr,
            "max_hr": result.max_hr,
            "elevation_gain_m": result.elevation_gain_m,
            "splits_data": json.dumps(result.splits if result.splits else []),
            "hr_zones": json.dumps(result.hr_zones if result.hr_zones else {}),
            "completed_full": result.completed_full,
            "stopped_at_km": result.stopped_at_km,
            "performance_label": assessment.performance_label.value,
            "distance_score": assessment.distance_score,
            "pace_score": assessment.pace_score,
            "hr_score": assessment.hr_score,
            "overall_score": assessment.overall_score,
            "strengths": json.dumps(assessment.strengths),
            "weaknesses": json.dumps(assessment.weaknesses),
            "key_feedback": json.dumps(assessment.key_feedback),
            "coach_notes": assessment.coach_notes,
            "ability_change": assessment.ability_change,
            "readiness_for_progression": assessment.readiness_for_progression,
            "fatigue_level": assessment.fatigue_level,
            "injury_risk_indicators": json.dumps(assessment.injury_risk_indicators)
        }
        
        try:
            response = self.supabase.table("workout_results")\
                .insert(result_data)\
                .execute()
            
            # Update workout assignment status
            self.update_workout_status(assignment_id, "completed")
            
            return response.data[0]
        except Exception as e:
            print(f"Error storing workout result: {e}")
            raise
    
    def get_workout_result(self, result_id: str) -> Optional[Dict]:
        """Get workout result by ID"""
        try:
            response = self.supabase.table("workout_results")\
                .select("*")\
                .eq("id", result_id)\
                .single()\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error fetching workout result: {e}")
            return None
    
    def get_athlete_workout_results(
        self,
        athlete_id: str,
        days: int = 30
    ) -> List[Dict]:
        """Get athlete's workout results from last N days"""
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        try:
            response = self.supabase.table("workout_results")\
                .select("*")\
                .eq("athlete_id", athlete_id)\
                .gte("workout_date", cutoff_date)\
                .order("workout_date", desc=True)\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error fetching athlete workout results: {e}")
            return []
    
    # =========================================================================
    # ABILITY PROGRESSION OPERATIONS
    # =========================================================================
    
    def update_ability_progression(
        self,
        athlete_id: str,
        ability_change: float,
        workout_result_id: str,
        current_ability: AthleteAbility
    ) -> Dict:
        """Update athlete ability progression"""
        
        progression_data = {
            "athlete_id": athlete_id,
            "recorded_date": datetime.now().isoformat(),
            "workout_result_id": workout_result_id,
            "ability_score_change": ability_change,
            "current_pace_easy": current_ability.current_pace_easy,
            "current_pace_tempo": current_ability.current_pace_tempo,
            "current_pace_interval": current_ability.current_pace_interval,
            "current_weekly_volume": current_ability.weekly_volume_km,
            "current_longest_run": current_ability.longest_run_km,
            "fitness_score": current_ability.fitness_score,
            "max_hr": current_ability.max_hr,
            "threshold_hr": current_ability.threshold_hr,
            "aerobic_hr": current_ability.aerobic_hr
        }
        
        try:
            response = self.supabase.table("ability_progression")\
                .insert(progression_data)\
                .execute()
            return response.data[0]
        except Exception as e:
            print(f"Error updating ability progression: {e}")
            raise
    
    def get_ability_progression_history(
        self,
        athlete_id: str,
        days: int = 90
    ) -> List[Dict]:
        """Get athlete's ability progression history"""
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        try:
            response = self.supabase.table("ability_progression")\
                .select("*")\
                .eq("athlete_id", athlete_id)\
                .gte("recorded_date", cutoff_date)\
                .order("recorded_date", desc=False)\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error fetching ability progression: {e}")
            return []
    
    # =========================================================================
    # INTEGRATED WORKFLOWS
    # =========================================================================
    
    def process_athlete_signup(
        self,
        athlete_id: str,
        signup_data: Dict,
        recent_races: Optional[List[Dict]] = None
    ) -> Dict:
        """
        Process complete athlete signup workflow.
        
        Steps:
        1. Create athlete profile
        2. Analyze recent races (if provided)
        3. Generate comprehensive fitness assessment
        4. Store baseline data
        5. Generate initial 14-day workout plan
        
        Returns:
            Complete signup result with recommendations
        """
        results = {
            "athlete_id": athlete_id,
            "signup_date": datetime.now().isoformat(),
            "profile_created": False,
            "races_analyzed": 0,
            "fitness_assessment": None,
            "initial_workouts": []
        }
        
        try:
            # Step 1: Create athlete profile
            profile = self.create_athlete_profile(signup_data)
            results["profile_created"] = True
            
            # Step 2: Analyze recent races
            if recent_races:
                for race_data in recent_races:
                    race_record = self._dict_to_race_record(race_data)
                    analysis = self.race_analyzer.analyze_race(race_record)
                    self.store_race_analysis(athlete_id, analysis)
                    results["races_analyzed"] += 1
            
            # Step 3: Generate comprehensive fitness assessment
            fitness_assessment = self._generate_initial_fitness_assessment(
                athlete_id, signup_data, recent_races
            )
            self.store_fitness_assessment(athlete_id, fitness_assessment)
            results["fitness_assessment"] = {
                "overall_score": fitness_assessment.overall_fitness_score,
                "foundation_needed": fitness_assessment.foundation_phase_needed,
                "estimated_weeks": fitness_assessment.total_estimated_weeks,
                "primary_focus": fitness_assessment.primary_focus_areas
            }
            
            # Step 4: Generate initial 14-day workout plan
            athlete_ability = self._create_athlete_ability_from_assessment(
                fitness_assessment, signup_data
            )
            
            for day in range(1, 15):
                workout = self.workout_generator.generate_next_workout(
                    athlete_ability=athlete_ability,
                    performance_history=PerformanceHistory(
                        last_7_days=[],
                        last_4_weeks_volume=[signup_data.get("current_weekly_volume_km", 30.0)],
                        last_3_workouts=[],
                        consecutive_good_performances=0,
                        fatigue_indicators=[],
                        injury_risk_score=0.0
                    ),
                    training_phase=(
                        TrainingPhase.FOUNDATION if fitness_assessment.foundation_phase_needed
                        else TrainingPhase.BASE_BUILD
                    ),
                    week_number=1 if day <= 7 else 2,
                    day_of_week=((day - 1) % 7) + 1
                )
                
                workout.workout_date = datetime.now() + timedelta(days=day)
                assignment = self.create_workout_assignment(athlete_id, workout)
                results["initial_workouts"].append(assignment["id"])
            
            return results
            
        except Exception as e:
            print(f"Error processing athlete signup: {e}")
            raise
    
    def process_workout_completion(
        self,
        assignment_id: str,
        athlete_id: str,
        workout_data: Dict
    ) -> Dict:
        """
        Process workout completion workflow.
        
        Steps:
        1. Get workout assignment (GIVEN)
        2. Parse workout result (RESULT)
        3. Analyze performance (GIVEN vs RESULT)
        4. Store workout result and assessment
        5. Update ability progression
        6. Generate next workout
        
        Returns:
            Complete workout processing result
        """
        results = {
            "assignment_id": assignment_id,
            "performance_label": None,
            "ability_change": 0.0,
            "next_workout_id": None,
            "feedback": []
        }
        
        try:
            # Step 1: Get workout assignment
            assignment = self.get_workout_assignment(assignment_id)
            if not assignment:
                raise ValueError(f"Workout assignment {assignment_id} not found")
            
            # Step 2: Parse workout result
            workout_result = self._dict_to_workout_result(workout_data)
            
            # Step 3: Create workout target from assignment
            workout_target = self._assignment_to_workout_target(assignment)
            
            # Step 4: Analyze performance
            assessment = self.performance_tracker.assess_workout_performance(
                given=workout_target,
                result=workout_result
            )
            
            results["performance_label"] = assessment.performance_label.value
            results["ability_change"] = assessment.ability_change
            results["feedback"] = assessment.key_feedback
            
            # Step 5: Store result and assessment
            stored_result = self.store_workout_result(
                assignment_id, athlete_id, workout_result, assessment
            )
            
            # Step 6: Update ability progression
            athlete_profile = self.get_athlete_profile(athlete_id)
            current_ability = self._profile_to_athlete_ability(athlete_profile)
            
            self.update_ability_progression(
                athlete_id,
                assessment.ability_change,
                stored_result["id"],
                current_ability
            )
            
            # Step 7: Generate next workout
            recent_results = self.get_athlete_workout_results(athlete_id, days=7)
            performance_history = self._create_performance_history(recent_results)
            
            next_workout = self.workout_generator.generate_next_workout(
                athlete_ability=current_ability,
                performance_history=performance_history,
                training_phase=TrainingPhase.SPEED_BUILD,  # Would come from training plan
                week_number=self._calculate_week_number(athlete_id),
                day_of_week=((datetime.now().weekday() + 2) % 7) + 1
            )
            
            next_assignment = self.create_workout_assignment(athlete_id, next_workout)
            results["next_workout_id"] = next_assignment["id"]
            
            return results
            
        except Exception as e:
            print(f"Error processing workout completion: {e}")
            raise
    
    # =========================================================================
    # HELPER METHODS
    # =========================================================================
    
    def _dict_to_race_record(self, data: Dict) -> RaceRecord:
        """Convert dict to RaceRecord"""
        # Implementation would parse dict to RaceRecord
        pass
    
    def _dict_to_workout_result(self, data: Dict) -> WorkoutResult:
        """Convert dict to WorkoutResult"""
        return WorkoutResult(
            workout_id=data.get("external_id", ""),
            completed_date=datetime.fromisoformat(data["completed_date"]),
            distance_km=data["distance_km"],
            total_time_seconds=data["duration_seconds"],
            avg_pace_seconds=data["avg_pace_seconds"],
            avg_hr=data.get("avg_hr"),
            max_hr=data.get("max_hr"),
            elevation_gain_m=data.get("elevation_gain_m"),
            splits=data.get("splits", []),
            hr_zones=data.get("hr_zones"),
            completed_full=data.get("completed_full", True),
            stopped_at_km=data.get("stopped_at_km")
        )
    
    def _assignment_to_workout_target(self, assignment: Dict) -> WorkoutTarget:
        """Convert assignment dict to WorkoutTarget"""
        return WorkoutTarget(
            workout_type=WorkoutType(assignment["workout_type"]),
            distance_km=assignment["distance_km"],
            target_pace_seconds=assignment.get("target_pace_seconds"),
            pace_range_seconds=(
                assignment.get("pace_range_min", 0),
                assignment.get("pace_range_max", 0)
            ),
            target_hr=assignment.get("target_hr"),
            hr_range=(
                assignment.get("hr_range_min", 0),
                assignment.get("hr_range_max", 0)
            ),
            intervals=assignment.get("interval_count"),
            interval_distance_m=assignment.get("interval_distance_m"),
            interval_pace_seconds=assignment.get("interval_pace_seconds"),
            rest_time_seconds=assignment.get("rest_time_seconds"),
            notes=assignment.get("workout_notes", "")
        )
    
    def _profile_to_athlete_ability(self, profile: Dict) -> AthleteAbility:
        """Convert profile dict to AthleteAbility"""
        # Would extract ability metrics from profile
        return AthleteAbility(
            current_pace_easy=int(profile.get("current_avg_pace_easy", 405)),
            current_pace_tempo=int(profile.get("current_avg_pace_tempo", 360)),
            current_pace_interval=int(profile.get("current_avg_pace_interval", 340)),
            max_hr=profile.get("current_max_hr", 185),
            threshold_hr=int(profile.get("current_max_hr", 185) * 0.90),
            aerobic_hr=int(profile.get("current_max_hr", 185) * 0.80),
            weekly_volume_km=profile.get("current_weekly_volume_km", 40.0),
            longest_run_km=profile.get("before_signup_longest_run_km", 16.0),
            fitness_score=65.0
        )
    
    def _create_performance_history(self, recent_results: List[Dict]) -> PerformanceHistory:
        """Create PerformanceHistory from recent workout results"""
        last_7_labels = [r["performance_label"] for r in recent_results[:7]]
        
        # Calculate weekly volumes
        weekly_volumes = []
        # Would aggregate results by week
        
        return PerformanceHistory(
            last_7_days=last_7_labels,
            last_4_weeks_volume=weekly_volumes or [40.0],
            last_3_workouts=recent_results[:3],
            consecutive_good_performances=len([l for l in last_7_labels if l in ["GREAT", "BEST"]]),
            fatigue_indicators=[],
            injury_risk_score=0.0
        )
    
    def _generate_initial_fitness_assessment(
        self,
        athlete_id: str,
        signup_data: Dict,
        recent_races: Optional[List[Dict]]
    ) -> ComprehensiveFitnessAssessment:
        """Generate initial comprehensive fitness assessment"""
        # Would use fitness_analyzer with signup data
        return self.fitness_analyzer.analyze_comprehensive_fitness(
            recent_race_pace_seconds=signup_data.get("recent_race_pace", 375),
            training_pace_seconds=signup_data.get("current_avg_pace", 405),
            weekly_volume=signup_data.get("current_weekly_volume_km", 40.0),
            consistency=signup_data.get("training_frequency_per_week", 4.0),
            longest_run=signup_data.get("before_signup_longest_run_km", 16.0),
            race_distance_km=21.1,  # Would come from goal
            goal_pace_seconds=signup_data.get("goal_target_pace", 340)
        )
    
    def _create_athlete_ability_from_assessment(
        self,
        assessment: ComprehensiveFitnessAssessment,
        signup_data: Dict
    ) -> AthleteAbility:
        """Create AthleteAbility from fitness assessment"""
        return AthleteAbility(
            current_pace_easy=signup_data.get("current_avg_pace", 405),
            current_pace_tempo=signup_data.get("current_avg_pace", 405) - 30,
            current_pace_interval=signup_data.get("current_avg_pace", 405) - 50,
            max_hr=signup_data.get("current_max_hr", 185),
            threshold_hr=int(signup_data.get("current_max_hr", 185) * 0.90),
            aerobic_hr=int(signup_data.get("current_max_hr", 185) * 0.80),
            weekly_volume_km=assessment.running_fitness.weekly_volume,
            longest_run_km=assessment.running_fitness.longest_run,
            fitness_score=assessment.overall_fitness_score
        )
    
    def _calculate_week_number(self, athlete_id: str) -> int:
        """Calculate current week number in training plan"""
        profile = self.get_athlete_profile(athlete_id)
        if not profile:
            return 1
        
        signup_date = datetime.fromisoformat(profile["signup_date"])
        days_since_signup = (datetime.now() - signup_date).days
        return (days_since_signup // 7) + 1


# Example usage
if __name__ == "__main__":
    print("Database Integration Layer")
    print("="*80)
    print("\nThis module connects all analysis modules to Supabase.")
    print("\nKey Operations:")
    print("  - Athlete signup workflow")
    print("  - Race analysis storage")
    print("  - Fitness assessment tracking")
    print("  - Workout assignment and completion")
    print("  - Performance tracking")
    print("  - Ability progression updates")
    print("\nReady for API integration!")
    print("="*80)
