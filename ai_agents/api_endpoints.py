"""
API Endpoints for Athlete Lifecycle Management
FastAPI REST API exposing all database operations.

Endpoints:
- /athletes/* - Athlete profile management
- /races/* - Race analysis
- /fitness/* - Fitness assessments
- /workouts/* - Workout assignments and results
- /ability/* - Ability progression tracking
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum

from database_integration import DatabaseIntegration

# Initialize FastAPI app
app = FastAPI(
    title="SafeStride AI Athlete API",
    description="Complete athlete lifecycle management API",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database integration
db = DatabaseIntegration()


# ============================================================================
# PYDANTIC MODELS (Request/Response Schemas)
# ============================================================================

class AthleteSignupRequest(BaseModel):
    """Athlete signup request"""
    athlete_id: str
    current_level: str = Field(..., pattern="^(beginner|intermediate|advanced)$")
    primary_goal: str
    goal_type: str = Field(..., pattern="^(time_based|pace_based|completion|distance)$")
    goal_target_time: Optional[str] = None  # ISO 8601 duration
    goal_target_pace: Optional[str] = None  # ISO 8601 duration
    target_race_date: Optional[date] = None
    current_weekly_volume_km: float = 30.0
    current_avg_pace: int = 405  # seconds per km
    current_max_hr: int = 185
    current_resting_hr: int = 60
    training_frequency_per_week: int = 4
    preferred_training_days: List[str] = []
    years_of_running: int = 0
    has_active_injury: bool = False
    injury_history: List[Dict] = []
    recent_races: Optional[List[Dict]] = None


class AthleteProfileResponse(BaseModel):
    """Athlete profile response"""
    id: str
    athlete_id: str
    current_level: str
    primary_goal: str
    target_race_date: Optional[date]
    weeks_to_goal: Optional[int]
    overall_fitness_score: Optional[float]
    foundation_phase_needed: Optional[bool]
    estimated_weeks_to_goal: Optional[int]
    created_at: datetime
    is_active: bool


class RaceAnalysisRequest(BaseModel):
    """Race analysis request"""
    athlete_id: str
    race_date: datetime
    race_type: str = Field(..., pattern="^(5K|10K|HM|Marathon)$")
    distance_km: float
    finish_time_seconds: int
    avg_pace_seconds: int
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    splits: Optional[List[int]] = None
    weather: Optional[str] = None
    temperature: Optional[float] = None
    surface: Optional[str] = None


class WorkoutAssignmentResponse(BaseModel):
    """Workout assignment response"""
    id: str
    athlete_id: str
    scheduled_date: datetime
    workout_type: str
    workout_status: str
    distance_km: float
    target_pace_seconds: Optional[int]
    pace_range: Optional[Dict[str, int]]
    target_hr: Optional[int]
    hr_range: Optional[Dict[str, int]]
    workout_notes: str
    coaching_cues: List[str]
    generation_rationale: str


class WorkoutCompletionRequest(BaseModel):
    """Workout completion request"""
    assignment_id: str
    athlete_id: str
    completed_date: datetime
    external_id: str  # Strava/Garmin ID
    data_source: str = Field(..., pattern="^(strava|garmin)$")
    distance_km: float
    duration_seconds: int
    avg_pace_seconds: int
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    elevation_gain_m: Optional[int] = None
    splits: Optional[List[int]] = None
    hr_zones: Optional[Dict[int, int]] = None
    completed_full: bool = True
    stopped_at_km: Optional[float] = None


class WorkoutResultResponse(BaseModel):
    """Workout result response"""
    id: str
    assignment_id: str
    athlete_id: str
    performance_label: str
    overall_score: float
    distance_score: float
    pace_score: float
    hr_score: float
    strengths: List[str]
    weaknesses: List[str]
    key_feedback: List[str]
    coach_notes: str
    ability_change: float
    readiness_for_progression: bool
    fatigue_level: str
    next_workout_id: Optional[str] = None


class AbilityProgressionResponse(BaseModel):
    """Ability progression response"""
    recorded_date: datetime
    ability_score_change: float
    current_pace_easy: int
    current_pace_tempo: int
    current_pace_interval: int
    current_weekly_volume: float
    fitness_score: float


# ============================================================================
# ATHLETE ENDPOINTS
# ============================================================================

@app.post("/athletes/signup", response_model=Dict[str, Any])
async def athlete_signup(request: AthleteSignupRequest, background_tasks: BackgroundTasks):
    """
    Complete athlete signup workflow.
    
    Creates profile, analyzes races, generates fitness assessment,
    and creates initial 14-day workout plan.
    """
    try:
        # Prepare signup data
        signup_data = {
            "athlete_id": request.athlete_id,
            "signup_date": datetime.now().isoformat(),
            "current_level": request.current_level,
            "primary_goal": request.primary_goal,
            "goal_type": request.goal_type,
            "goal_target_time": request.goal_target_time,
            "goal_target_pace": request.goal_target_pace,
            "target_race_date": request.target_race_date.isoformat() if request.target_race_date else None,
            "current_weekly_volume_km": request.current_weekly_volume_km,
            "current_avg_pace": request.current_avg_pace,
            "current_max_hr": request.current_max_hr,
            "current_resting_hr": request.current_resting_hr,
            "training_frequency_per_week": request.training_frequency_per_week,
            "preferred_training_days": request.preferred_training_days,
            "years_of_running": request.years_of_running,
            "has_active_injury": request.has_active_injury,
            "injury_history": request.injury_history,
            "baseline_assessment_status": "not_started"
        }
        
        # Process signup
        result = db.process_athlete_signup(
            athlete_id=request.athlete_id,
            signup_data=signup_data,
            recent_races=request.recent_races
        )
        
        return {
            "success": True,
            "athlete_id": request.athlete_id,
            "message": "Athlete signup completed successfully",
            "data": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/athletes/{athlete_id}")
async def get_athlete_profile(athlete_id: str):
    """Get athlete profile"""
    try:
        profile = db.get_athlete_profile(athlete_id)
        if not profile:
            raise HTTPException(status_code=404, detail="Athlete not found")
        return profile
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.patch("/athletes/{athlete_id}")
async def update_athlete_profile(athlete_id: str, updates: Dict[str, Any]):
    """Update athlete profile"""
    try:
        profile = db.update_athlete_profile(athlete_id, updates)
        return {
            "success": True,
            "athlete_id": athlete_id,
            "data": profile
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# RACE ANALYSIS ENDPOINTS
# ============================================================================

@app.post("/races/analyze")
async def analyze_race(request: RaceAnalysisRequest):
    """Analyze race performance"""
    try:
        from race_analyzer import RaceRecord, RaceType, RaceSplit
        
        # Convert request to RaceRecord
        race_record = RaceRecord(
            race_date=request.race_date,
            race_type=RaceType(request.race_type),
            distance_km=request.distance_km,
            finish_time_seconds=request.finish_time_seconds,
            avg_pace_seconds=request.avg_pace_seconds,
            avg_hr=request.avg_hr,
            max_hr=request.max_hr,
            splits=[RaceSplit(km=i+1, pace_seconds=p, hr=None) 
                   for i, p in enumerate(request.splits)] if request.splits else None,
            weather=request.weather,
            temperature=request.temperature,
            surface=request.surface
        )
        
        # Analyze race
        analysis = db.race_analyzer.analyze_race(race_record)
        
        # Store analysis
        stored = db.store_race_analysis(request.athlete_id, analysis)
        
        return {
            "success": True,
            "race_id": stored["id"],
            "analysis": {
                "fitness_level": analysis.fitness_level.value,
                "pacing_score": analysis.pacing_score,
                "hr_efficiency_score": analysis.hr_efficiency_score,
                "fade_percentage": analysis.fade_percentage,
                "strengths": analysis.strengths,
                "weaknesses": analysis.weaknesses,
                "goal_recommendations": analysis.recommended_goals,
                "estimated_timeline_weeks": analysis.estimated_timeline_weeks,
                "key_insights": analysis.key_insights,
                "warnings": analysis.warnings
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/races/{athlete_id}")
async def get_athlete_races(athlete_id: str):
    """Get athlete's race history"""
    try:
        races = db.get_athlete_race_history(athlete_id)
        return {
            "athlete_id": athlete_id,
            "total_races": len(races),
            "races": races
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# FITNESS ASSESSMENT ENDPOINTS
# ============================================================================

@app.get("/fitness/{athlete_id}")
async def get_fitness_assessment(athlete_id: str):
    """Get latest fitness assessment"""
    try:
        profile = db.get_athlete_profile(athlete_id)
        if not profile:
            raise HTTPException(status_code=404, detail="Athlete not found")
        
        assessment_data = profile.get("baseline_assessment_data")
        if not assessment_data:
            raise HTTPException(status_code=404, detail="No fitness assessment found")
        
        return {
            "athlete_id": athlete_id,
            "assessment": assessment_data
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# WORKOUT ENDPOINTS
# ============================================================================

@app.get("/workouts/{athlete_id}")
async def get_athlete_workouts(
    athlete_id: str,
    status: Optional[str] = None,
    limit: int = 10
):
    """Get athlete's workout assignments"""
    try:
        workouts = db.get_athlete_workouts(athlete_id, status, limit)
        return {
            "athlete_id": athlete_id,
            "total_workouts": len(workouts),
            "workouts": workouts
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/workouts/assignment/{assignment_id}")
async def get_workout_assignment(assignment_id: str):
    """Get specific workout assignment"""
    try:
        workout = db.get_workout_assignment(assignment_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout assignment not found")
        return workout
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/workouts/complete", response_model=WorkoutResultResponse)
async def complete_workout(request: WorkoutCompletionRequest):
    """
    Process workout completion.
    
    Analyzes performance, stores result, updates ability,
    and generates next workout.
    """
    try:
        # Convert request to dict for processing
        workout_data = {
            "external_id": request.external_id,
            "completed_date": request.completed_date.isoformat(),
            "distance_km": request.distance_km,
            "duration_seconds": request.duration_seconds,
            "avg_pace_seconds": request.avg_pace_seconds,
            "avg_hr": request.avg_hr,
            "max_hr": request.max_hr,
            "elevation_gain_m": request.elevation_gain_m,
            "splits": request.splits,
            "hr_zones": request.hr_zones,
            "completed_full": request.completed_full,
            "stopped_at_km": request.stopped_at_km
        }
        
        # Process workout completion
        result = db.process_workout_completion(
            assignment_id=request.assignment_id,
            athlete_id=request.athlete_id,
            workout_data=workout_data
        )
        
        # Get stored workout result details
        workout_result = db.get_workout_result(result.get("result_id"))
        
        return WorkoutResultResponse(
            id=workout_result["id"],
            assignment_id=request.assignment_id,
            athlete_id=request.athlete_id,
            performance_label=result["performance_label"],
            overall_score=workout_result["overall_score"],
            distance_score=workout_result["distance_score"],
            pace_score=workout_result["pace_score"],
            hr_score=workout_result["hr_score"],
            strengths=workout_result["strengths"],
            weaknesses=workout_result["weaknesses"],
            key_feedback=result["feedback"],
            coach_notes=workout_result["coach_notes"],
            ability_change=result["ability_change"],
            readiness_for_progression=workout_result["readiness_for_progression"],
            fatigue_level=workout_result["fatigue_level"],
            next_workout_id=result.get("next_workout_id")
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/workouts/results/{athlete_id}")
async def get_workout_results(athlete_id: str, days: int = 30):
    """Get athlete's workout results"""
    try:
        results = db.get_athlete_workout_results(athlete_id, days)
        return {
            "athlete_id": athlete_id,
            "days": days,
            "total_results": len(results),
            "results": results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# ABILITY PROGRESSION ENDPOINTS
# ============================================================================

@app.get("/ability/{athlete_id}")
async def get_ability_progression(athlete_id: str, days: int = 90):
    """Get athlete's ability progression history"""
    try:
        progression = db.get_ability_progression_history(athlete_id, days)
        
        # Calculate summary stats
        if progression:
            total_change = sum(p["ability_score_change"] for p in progression)
            avg_fitness = sum(p["fitness_score"] for p in progression) / len(progression)
            latest = progression[-1]
        else:
            total_change = 0
            avg_fitness = 0
            latest = None
        
        return {
            "athlete_id": athlete_id,
            "days": days,
            "total_change": total_change,
            "avg_fitness_score": avg_fitness,
            "latest_ability": latest,
            "progression_history": progression
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# SYSTEM HEALTH ENDPOINTS
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "SafeStride AI Athlete API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "SafeStride AI Athlete API",
        "version": "1.0.0",
        "documentation": "/docs",
        "health": "/health"
    }


# ============================================================================
# RUN SERVER
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    print("="*80)
    print("SafeStride AI Athlete API")
    print("="*80)
    print("\nStarting FastAPI server...")
    print("API Documentation: http://localhost:8000/docs")
    print("Interactive API: http://localhost:8000/redoc")
    print("="*80 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
