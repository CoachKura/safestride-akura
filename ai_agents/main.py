import os
from typing import Any, Optional

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Phase 0 Stabilization - Production Services  
try:
    from orchestrator import AISRiOrchestrator
    from env_validator import validate_environment
    from aisri_safety_gate import AISRISafetyGate
    from strava_oauth_service import StravaOAuthService
    _PHASE0_OK = True
except Exception as e:
    _PHASE0_OK = False
    print(f'Phase 0 services unavailable: {e}')


# Strava OAuth signup & activity sync routes
try:
    from strava_signup_api_simple import strava_router
    _STRAVA_ROUTER_OK = True
except Exception as _e:
    strava_router = None
    _STRAVA_ROUTER_OK = False

# Load environment variables only if .env files exist (for local development)
# On production (Render), environment variables are injected directly
_HERE = os.path.dirname(os.path.abspath(__file__))
_LOCAL_ENV = os.path.join(_HERE, ".env")
_ROOT_ENV = os.path.join(_HERE, "..", ".env")

if os.path.exists(_LOCAL_ENV):
    load_dotenv(dotenv_path=_LOCAL_ENV, override=False)
if os.path.exists(_ROOT_ENV):
    load_dotenv(dotenv_path=_ROOT_ENV, override=False)

SUPABASE_URL = os.getenv("SUPABASE_URL")

# Prefer service-role key for server-side use; fall back to anon key for dev.
SUPABASE_SERVICE_KEY = (
    os.getenv("SUPABASE_SERVICE_KEY")
    or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    or os.getenv("SUPABASE_ANON_KEY")
)

supabase = None
if SUPABASE_URL and SUPABASE_SERVICE_KEY:
    try:
        from supabase import create_client  # type: ignore

        supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    except Exception as exc:
        # Keep the app importable even if supabase client fails to init.
        supabase = None
        _SUPABASE_INIT_ERROR = str(exc)
else:
    _SUPABASE_INIT_ERROR = "Missing SUPABASE_URL or SUPABASE_SERVICE_KEY/SUPABASE_ANON_KEY"


app = FastAPI(title="AISRi AI Engine", version="1.0")

# Add CORS middleware to allow Flutter app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (restrict in production if needed)
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Mount Strava OAuth & activity sync routes onto this app
if strava_router:
    app.include_router(strava_router)

# Global orchestrator
orchestrator = None

@app.on_event('startup')
async def startup_event():
    global orchestrator
    print('='*70)
    print('AISRI ENGINE STARTUP')
    print('='*70)
    if _PHASE0_OK:
        try:
            is_valid, missing = validate_environment(verbose=True)
            if not is_valid:
                print(f'WARNING: Missing {len(missing)} variables')
        except: pass
        try:
            orchestrator = AISRiOrchestrator()
            print('Orchestrator initialized')
        except Exception as e:
            print(f'Orchestrator init failed: {e}')
    print('AISRI ENGINE READY')
    print('='*70)



class CommanderRequest(BaseModel):
    goal: str = Field(..., min_length=1)
    athlete_id: str | None = None


class WorkoutRequest(BaseModel):
    athlete_id: str


class InjuryPredictionRequest(BaseModel):
    athlete_id: str


class TrainingPlanRequest(BaseModel):
    athlete_id: str


class PerformancePredictionRequest(BaseModel):
    athlete_id: str


class AutonomousDecisionRequest(BaseModel):
    athlete_id: str


@app.get("/")
def root():
    return {
        "status": "AISRi AI Engine Running",
        "service": "AISRi AI Engine",
        "version": "1.0",
        "api": "https://api.akura.in",
        "docs": "https://api.akura.in/docs"
    }


@app.get("/env-check")
def env_check():
    """Diagnostic endpoint to check if environment variables are loaded"""
    import os
    return {
        "SUPABASE_URL_set": bool(os.getenv("SUPABASE_URL")),
        "SUPABASE_SERVICE_KEY_set": bool(os.getenv("SUPABASE_SERVICE_KEY")),
        "SUPABASE_ANON_KEY_set": bool(os.getenv("SUPABASE_ANON_KEY")),
        "OPENAI_API_KEY_set": bool(os.getenv("OPENAI_API_KEY")),
        "supabase_client_initialized": supabase is not None
    }
@app.get("/test-supabase")
def test_supabase() -> dict[str, Any]:
    if supabase is None:
        raise HTTPException(status_code=500, detail=f"Supabase not configured: {_SUPABASE_INIT_ERROR}")

    try:
        response = supabase.table("profiles").select("id").limit(5).execute()
        data = response.data or []
        return {"status": "success", "records_found": len(data), "data": data}
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.get("/aisri-score/{athlete_id}")
def get_aisri_score(athlete_id: str) -> dict[str, Any]:
    if supabase is None:
        raise HTTPException(status_code=500, detail=f"Supabase not configured: {_SUPABASE_INIT_ERROR}")

    try:
        # In this repo's canonical schema, AISRI_assessments uses `athlete_id`.
        response = (
            supabase.table('AISRI_assessments')
            .select("*")
            .eq("athlete_id", athlete_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )

        data = response.data or []
        latest = data[0] if data else None
        return {"status": "success", "aisri_score": latest}
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.post("/agent/commander")
def run_commander(request: CommanderRequest) -> dict[str, Any]:
    goal = request.goal.strip().lower()

    if goal == "list_athletes":
        try:
            from commander.commander import AISRiCommander

            commander = AISRiCommander()
            athletes = commander.get_all_athletes()
            return {"status": "success", "result": athletes}
        except RuntimeError as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        except Exception as exc:
            raise HTTPException(status_code=502, detail=str(exc))

    if goal == "get_latest_aisri":
        if not request.athlete_id:
            return {"status": "error", "message": "athlete_id required"}

        try:
            from commander.commander import AISRiCommander

            commander = AISRiCommander()
            score = commander.get_latest_aisri(request.athlete_id)
            return {"status": "success", "result": score}
        except RuntimeError as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        except Exception as exc:
            raise HTTPException(status_code=502, detail=str(exc))

    return {"status": "error", "message": f"Unknown goal: {goal}"}


@app.get("/agent/athletes")
def list_athletes() -> dict[str, Any]:
    try:
        from commander.commander import AISRiCommander

        commander = AISRiCommander()
        athletes = commander.get_all_athletes()
        return {"status": "success", "count": len(athletes or []), "data": athletes or []}
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.get("/agent/latest-aisri/{profile_id}")
def latest_aisri(profile_id: str) -> dict[str, Any]:
    try:
        from commander.commander import AISRiCommander

        commander = AISRiCommander()
        rows = commander.get_latest_aisri(profile_id)
        latest = rows[0] if rows else None
        return {"status": "success", "aisri_score": latest}
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.post("/agent/generate-workout")
async def generate_workout(request: WorkoutRequest):
    # Generate workout - UPDATED to use  Orchestrator with Safety Gates
    # Legacy endpoint maintained for backward compatibility
    if orchestrator is None:
        # Fallback to direct agent call if orchestrator not available
        from ai_engine_agent.workout_generator_agent import AISRiWorkoutGeneratorAgent
        agent = AISRiWorkoutGeneratorAgent()
        return agent.generate_workout(request.athlete_id)
    
    # Route through orchestrator for safety gate enforcement
    try:
        result = await orchestrator.generate_safe_workout(
            athlete_id=request.athlete_id,
            workout_type='run',
            duration_minutes=60,
            intensity=None
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/agent/predict-injury-risk")
def predict_injury(request: InjuryPredictionRequest):
    from ai_engine_agent.injury_prediction_agent import AISRiInjuryPredictionAgent

    agent = AISRiInjuryPredictionAgent()

    result = agent.predict_injury_risk(request.athlete_id)

    return result


@app.post("/agent/generate-training-plan")
def generate_training_plan(request: TrainingPlanRequest):
    """
    Generate adaptive 7-day training plan based on:
    - Latest AISRI score
    - Current injury risk level
    - Athlete's readiness
    
    Returns: Weekly plan with zones (AR, F, EN, TH, P, REST)
    """
    from ai_engine_agent.adaptive_training_plan_agent import AISRiAdaptiveTrainingPlanAgent

    agent = AISRiAdaptiveTrainingPlanAgent()

    result = agent.generate_plan(request.athlete_id)

    return result


@app.post("/agent/predict-performance")
def predict_performance(request: PerformancePredictionRequest):
    """
    Predict comprehensive performance metrics:
    - VO2max estimate
    - Race time predictions (5K, 10K, Half, Marathon)
    - Running biomechanics (stride, cadence, vertical oscillation)
    - Performance score (0-100)
    
    Based on AISRI scores, ROM tests, and training history.
    """
    from ai_engine_agent.performance_prediction_agent import AISRiPerformancePredictionAgent

    agent = AISRiPerformancePredictionAgent()

    result = agent.predict_performance(request.athlete_id)

    return result


@app.post("/agent/autonomous-decision")
def autonomous_decision(request: AutonomousDecisionRequest):
    """
    Make autonomous training decisions based on:
    - Current AISRI score
    - Injury risk level
    - Recent training load (last 7 days)
    
    Returns: Decision (REST, RECOVERY, INTENSIFY, TRAIN, LIGHT_TRAIN) with reason
    """
    from ai_engine_agent.autonomous_decision_agent import AISRiAutonomousDecisionAgent

    agent = AISRiAutonomousDecisionAgent()

    result = agent.run_decision_cycle(request.athlete_id)

    return result


# ===============================
# SELF-LEARNING & ATHLETE JOURNEY ENDPOINTS
# ===============================

class DataSyncRequest(BaseModel):
    athlete_id: str
    sync_source: str = Field(..., description="strava, garmin, or manual")
    sync_data: dict = Field(default={}, description="Optional sync metadata")


class AthleteJourneyRequest(BaseModel):
    athlete_id: str


@app.post("/sync/data")
def trigger_data_sync(request: DataSyncRequest):
    """
    Triggered when athlete syncs data from Strava/Garmin or logs workout manually
    Automatically analyzes athlete journey and updates ML models
    
    Process:
    1. Detect sync source (Strava, Garmin, Manual)
    2. Trigger self-learning analysis
    3. Generate personalized insights
    4. Update athlete's learned profile
    
    Returns: Journey analysis and insights
    """
    from ai_engine_agent.self_learning_integration import AthleteDataSyncHandler
    
    if request.sync_source.lower() == "strava":
        result = AthleteDataSyncHandler.on_strava_sync(request.athlete_id, request.sync_data)
    elif request.sync_source.lower() == "garmin":
        result = AthleteDataSyncHandler.on_garmin_sync(request.athlete_id, request.sync_data)
    elif request.sync_source.lower() == "manual":
        result = AthleteDataSyncHandler.on_manual_workout_log(request.athlete_id, request.sync_data)
    else:
        raise HTTPException(status_code=400, detail="Invalid sync_source. Must be 'strava', 'garmin', or 'manual'")
    
    return result


@app.post("/athlete/journey-analysis")
def get_athlete_journey(request: AthleteJourneyRequest):
    """
    Get comprehensive athlete journey analysis
    Shows progression from start to current state
    
    Returns:
    - Starting metrics vs current metrics
    - Improvement percentages
    - Training patterns
    - Milestones achieved
    - AI-generated insights
    """
    from ai_engine_agent.self_learning_engine import AthleteJourneyAnalyzer
    
    analysis = AthleteJourneyAnalyzer.analyze_athlete_journey(request.athlete_id)
    
    return analysis


@app.post("/system/daily-learning")
def trigger_daily_learning():
    """
    Manually trigger daily ML learning cycle
    (Normally runs automatically at 2 AM via scheduler)
    
    Process:
    1. Collect all athlete data
    2. Train/update ML models
    3. Identify knowledge gaps
    4. Generate system improvements
    
    Returns: Learning cycle results
    """
    from ai_engine_agent.self_learning_engine import SelfLearningEngine
    
    result = SelfLearningEngine.daily_learning_cycle()
    
    return result



# =====================================================
# STRAVA OAUTH ENDPOINTS
# =====================================================

@app.get('/strava/connect')
async def strava_connect(athlete_id: str = Query(..., description='SafeStride athlete ID')):
    '''
    Initiate Strava OAuth connection.
    Returns authorization URL for athlete to visit.
    '''
    try:
        auth_url = orchestrator.initiate_strava_connection(athlete_id)
        return {
            'status': 'success',
            'auth_url': auth_url,
            'message': 'Redirect athlete to this URL to authorize Strava'
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get('/strava/callback')
async def strava_callback(
    code: str = Query(..., description='Authorization code'),
    state: str = Query(..., description='Athlete ID'),
    scope: Optional[str] = Query(None, description='Granted scopes')
):
    '''
    Handle Strava OAuth callback.
    Exchanges code for access token and stores in database.
    '''
    try:
        result = await orchestrator.complete_strava_connection(code, state, scope)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get('/strava/status/{athlete_id}')
async def strava_status(athlete_id: str):
    '''Get Strava connection status for athlete'''
    try:
        status = await orchestrator.get_strava_status(athlete_id)
        return status
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/strava/disconnect')
async def strava_disconnect(athlete_id: str = Query(...)):
    '''Disconnect Strava from athlete account'''
    try:
        result = await orchestrator.disconnect_strava(athlete_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# AISRI WITH SAFETY GATE ENDPOINTS
# =====================================================

@app.post('/aisri/calculate')
async def calculate_aisri(athlete_id: str = Query(...)):
    '''
    Calculate AISRi score from Strava activities.
    Auto-refreshes token if needed.
    '''
    try:
        result = await orchestrator.calculate_aisri_from_strava(athlete_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get('/safety/status/{athlete_id}')
async def safety_status(athlete_id: str):
    '''Get overall safety status for athlete'''
    try:
        status = await orchestrator.get_safety_status(athlete_id)
        return status
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/safety/check-workout')
async def check_workout_safety(
    athlete_id: str = Query(...),
    workout_type: str = Query(..., description='Workout type: run, interval, long_run'),
    intensity: str = Query(..., description='Intensity: easy, moderate, hard, interval'),
    duration_minutes: Optional[int] = Query(None)
):
    '''
    Check if workout passes all safety gates.
    Returns safety status and recommendation.
    '''
    try:
        result = await orchestrator.check_workout_safety(
            athlete_id=athlete_id,
            workout_type=workout_type,
            intensity=intensity,
            duration_minutes=duration_minutes
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/workout/generate-safe')
async def generate_safe_workout(
    athlete_id: str = Query(...),
    workout_type: str = Query(...),
    duration_minutes: int = Query(...),
    intensity: Optional[str] = Query(None, description='Auto-determined if not provided')
):
    '''
    Generate workout with safety gate enforcement.
    Will block unsafe workouts and provide alternatives.
    '''
    try:
        result = await orchestrator.generate_safe_workout(
            athlete_id=athlete_id,
            workout_type=workout_type,
            duration_minutes=duration_minutes,
            intensity=intensity
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# SYSTEM ENDPOINTS
# =====================================================

@app.get('/system/health')
async def system_health():
    '''Comprehensive system health check'''
    try:
        health = await orchestrator.health_check()
        return health
    except Exception as e:
        return {
            'status': 'error',
            'message': str(e)
        }

@app.get('/system/env-status')
async def env_status():
    '''Check environment configuration status'''
    is_valid, missing = validate_environment(verbose=False)
    return {
        'valid': is_valid,
        'missing_vars': missing,
        'message': 'All required variables set' if is_valid else f'Missing {len(missing)} variables'
    }


def main() -> None:
    """
    Start the FastAPI server.
    
    Railway uses PORT environment variable.
    For production, always bind to 0.0.0.0 to accept external connections.
    """
    # ✅ Uses 0.0.0.0
    host = os.getenv("API_HOST") or "0.0.0.0"
    
    # ✅ Uses PORT environment variable
    port = int(os.getenv("PORT") or os.getenv("API_PORT") or "8000")
    
    # ✅ Reload mode - False by default to prevent crashes
    reload_env = os.getenv("API_RELOAD", "false").lower()
    reload = reload_env in ["true", "1", "yes"]
    
    # ✅ Production detection - disable reload in production
    if os.getenv("PORT"):
        reload = False

    uvicorn.run("main:app", host=host, port=port, reload=reload)


if __name__ == "__main__":
    main()


