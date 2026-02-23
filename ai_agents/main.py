import os
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Load environment variables (prefer ai_agents/.env, then fall back to workspace root .env)
_HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(dotenv_path=os.path.join(_HERE, ".env"), override=False)
load_dotenv(dotenv_path=os.path.join(_HERE, "..", ".env"), override=False)

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


@app.get("/env-check")`ndef env_check():`n    import os`n    return {`n        "SUPABASE_URL": bool(os.getenv("SUPABASE_URL")),`n        "SUPABASE_SERVICE_KEY": bool(os.getenv("SUPABASE_SERVICE_KEY")),`n        "SUPABASE_ANON_KEY": bool(os.getenv("SUPABASE_ANON_KEY")),`n        "OPENAI_API_KEY": bool(os.getenv("OPENAI_API_KEY"))`n    }`n`n
@app.get("/env-check")
def env_check():
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
def generate_workout(request: WorkoutRequest):
    from ai_engine_agent.workout_generator_agent import AISRiWorkoutGeneratorAgent

    agent = AISRiWorkoutGeneratorAgent()

    result = agent.generate_workout(request.athlete_id)

    return result


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
    
    # ✅ Production detection
    if os.getenv("PORT"):
        reload = False

    uvicorn.run("main:app", host=host, port=port, reload=reload)


if __name__ == "__main__":
    main()


