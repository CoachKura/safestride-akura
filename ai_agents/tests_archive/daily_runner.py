"""
Daily Runner for SafeStride AI Coaching System

This script runs daily (scheduled via Windows Task Scheduler or cron)
and makes autonomous coaching decisions for all athletes.

Simpler alternative to n8n workflow - just pure Python!
"""

import os
import sys
from datetime import datetime
from typing import Any

import requests
from dotenv import load_dotenv

# Load environment variables
_HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(dotenv_path=os.path.join(_HERE, ".env"), override=False)
load_dotenv(dotenv_path=os.path.join(_HERE, "..", ".env"), override=False)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = (
    os.getenv("SUPABASE_SERVICE_KEY")
    or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    or os.getenv("SUPABASE_ANON_KEY")
)

# FastAPI server URL (should be running)
API_BASE_URL = "http://127.0.0.1:8001"


def log(message: str):
    """Print timestamped log message."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


def get_all_athletes() -> list[dict[str, Any]]:
    """Fetch all athletes from the commander endpoint."""
    log("Fetching all athletes...")
    
    response = requests.post(
        f"{API_BASE_URL}/agent/commander",
        json={"goal": "list_athletes"},
        timeout=10
    )
    response.raise_for_status()
    
    data = response.json()
    athletes = data.get("result", [])
    log(f"Found {len(athletes)} athletes")
    
    return athletes


def get_decision_for_athlete(athlete_id: str) -> dict[str, Any]:
    """Get autonomous coaching decision for one athlete."""
    log(f"Getting decision for athlete {athlete_id}...")
    
    response = requests.post(
        f"{API_BASE_URL}/agent/autonomous-decision",
        json={"athlete_id": athlete_id},
        timeout=30
    )
    response.raise_for_status()
    
    return response.json()


def get_injury_prediction_for_athlete(athlete_id: str) -> dict[str, Any]:
    """Get injury risk prediction for one athlete."""
    log(f"Getting injury prediction for athlete {athlete_id}...")
    
    response = requests.post(
        f"{API_BASE_URL}/agent/predict-injury-risk",
        json={"athlete_id": athlete_id},
        timeout=30
    )
    response.raise_for_status()
    
    return response.json()


def generate_workout_for_athlete(athlete_id: str) -> dict[str, Any]:
    """Generate personalized workout for one athlete."""
    log(f"Generating workout for athlete {athlete_id}...")
    
    response = requests.post(
        f"{API_BASE_URL}/agent/generate-workout",
        json={"athlete_id": athlete_id},
        timeout=30
    )
    response.raise_for_status()
    
    return response.json()


def save_decision_to_database(athlete_id: str, decision_data: dict[str, Any]):
    """Save the decision to Supabase ai_decisions table."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        log("⚠️  WARNING: Supabase not configured, skipping database save")
        return
    
    log(f"Saving decision to database for athlete {athlete_id}...")
    
    from supabase import create_client
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    # Prepare data for insertion
    insert_data = {
        "athlete_id": athlete_id,
        "decision": decision_data.get("decision"),
        "reason": decision_data.get("reason"),
        "aisri_score": decision_data.get("aisri_score"),
        "injury_risk": decision_data.get("injury_risk"),
        "training_load": decision_data.get("training_load"),
    }
    
    response = supabase.table("ai_decisions").insert(insert_data).execute()
    log(f"✅ Decision saved to database")


def save_injury_prediction_to_database(athlete_id: str, prediction_data: dict[str, Any]):
    """Save injury risk prediction to Supabase injury_risk_predictions table."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        log("⚠️  WARNING: Supabase not configured, skipping database save")
        return
    
    log(f"Saving injury prediction to database for athlete {athlete_id}...")
    
    from supabase import create_client
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    # Prepare data for insertion
    insert_data = {
        "athlete_id": athlete_id,
        "risk_level": prediction_data.get("risk_level"),
        "risk_score": prediction_data.get("risk_score"),
        "factors": prediction_data.get("factors"),
        "recommendations": prediction_data.get("recommendations"),
    }
    
    response = supabase.table("injury_risk_predictions").insert(insert_data).execute()
    log(f"✅ Injury prediction saved to database")


def save_workout_to_database(athlete_id: str, workout_data: dict[str, Any]):
    """Save generated workout to Supabase workouts table."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        log("⚠️  WARNING: Supabase not configured, skipping database save")
        return
    
    log(f"Saving workout to database for athlete {athlete_id}...")
    
    from supabase import create_client
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    # Prepare data for insertion
    insert_data = {
        "athlete_id": athlete_id,
        "workout_type": workout_data.get("workout_type"),
        "duration_minutes": workout_data.get("duration_minutes"),
        "intensity": workout_data.get("intensity"),
        "description": workout_data.get("description"),
        "exercises": workout_data.get("exercises"),
    }
    
    response = supabase.table("workouts").insert(insert_data).execute()
    log(f"✅ Workout saved to database")


def run_daily_coaching():
    """
    Main function to run daily AISRi cycle for all athletes.
    
    This function:
    1. Gets all athletes
    2. For each athlete, runs ALL 3 AI agents:
       - Autonomous Decision (training recommendation)
       - Injury Risk Prediction
       - Workout Generation
    3. Saves all results to the database
    4. Prints a summary
    """
    log("=" * 60)
    log("🚀 Starting Daily AISRi Cycle (3 AI Agents)")
    log("=" * 60)
    
    try:
        # Get all athletes
        athletes = get_all_athletes()
        
        if not athletes:
            log("⚠️  No athletes found!")
            return
        
        # Process each athlete
        results = []
        for athlete in athletes:
            athlete_id = athlete.get("id")
            athlete_name = athlete.get("full_name", "Unknown")
            
            log("")
            log(f"👤 Processing: {athlete_name} ({athlete_id})")
            log("-" * 60)
            
            try:
                # 1. Get autonomous decision
                log("  🤖 Agent 1: Getting training decision...")
                decision_data = get_decision_for_athlete(athlete_id)
                decision = decision_data.get("decision", "UNKNOWN")
                aisri = decision_data.get("aisri_score", "N/A")
                log(f"     ✅ Decision: {decision} (AISRI: {aisri})")
                save_decision_to_database(athlete_id, decision_data)
                
                # 2. Get injury risk prediction
                log("  🏥 Agent 2: Predicting injury risk...")
                injury_data = get_injury_prediction_for_athlete(athlete_id)
                risk_level = injury_data.get("risk_level", "UNKNOWN")
                log(f"     ✅ Risk Level: {risk_level}")
                save_injury_prediction_to_database(athlete_id, injury_data)
                
                # 3. Generate workout
                log("  💪 Agent 3: Generating workout...")
                workout_data = generate_workout_for_athlete(athlete_id)
                workout_type = workout_data.get("workout_type", "UNKNOWN")
                duration = workout_data.get("duration_minutes", 0)
                log(f"     ✅ Workout: {workout_type} ({duration} min)")
                save_workout_to_database(athlete_id, workout_data)
                
                results.append({
                    "athlete": athlete_name,
                    "decision": decision,
                    "risk_level": risk_level,
                    "workout_type": workout_type,
                    "status": "success"
                })
                
            except Exception as e:
                log(f"❌ ERROR processing {athlete_name}: {str(e)}")
                results.append({
                    "athlete": athlete_name,
                    "decision": "ERROR",
                    "status": "failed",
                    "error": str(e)
                })
        
        # Print summary
        log("")
        log("=" * 60)
        log("📊 SUMMARY")
        log("=" * 60)
        
        successful = sum(1 for r in results if r["status"] == "success")
        failed = sum(1 for r in results if r["status"] == "failed")
        
        log(f"Total Athletes: {len(results)}")
        log(f"Successful: {successful}")
        log(f"Failed: {failed}")
        
        log("")
        log("Decisions by type:")
        decision_counts = {}
        risk_counts = {}
        workout_counts = {}
        
        for r in results:
            if r["status"] == "success":
                decision = r["decision"]
                decision_counts[decision] = decision_counts.get(decision, 0) + 1
                
                risk_level = r.get("risk_level", "UNKNOWN")
                risk_counts[risk_level] = risk_counts.get(risk_level, 0) + 1
                
                workout_type = r.get("workout_type", "UNKNOWN")
                workout_counts[workout_type] = workout_counts.get(workout_type, 0) + 1
        
        for decision, count in sorted(decision_counts.items()):
            log(f"  {decision}: {count}")
        
        log("")
        log("Injury Risk Levels:")
        for risk_level, count in sorted(risk_counts.items()):
            log(f"  {risk_level}: {count}")
        
        log("")
        log("Workout Types:")
        for workout_type, count in sorted(workout_counts.items()):
            log(f"  {workout_type}: {count}")
        
        log("")
        log("=" * 60)
        log("✅ AISRi daily cycle complete!")
        log("=" * 60)
        
    except Exception as e:
        log(f"❌ FATAL ERROR: {str(e)}")
        sys.exit(1)


def test_connection():
    """Test if the FastAPI server is accessible."""
    log("Testing connection to FastAPI server...")
    
    try:
        response = requests.get(f"{API_BASE_URL}/", timeout=5)
        response.raise_for_status()
        log("✅ FastAPI server is accessible")
        return True
    except Exception as e:
        log(f"❌ Cannot connect to FastAPI server: {str(e)}")
        log(f"   Make sure server is running at {API_BASE_URL}")
        return False


if __name__ == "__main__":
    # Test connection first
    if not test_connection():
        log("")
        log("💡 To start the FastAPI server, run:")
        log("   cd C:\\safestride\\ai_agents")
        log("   python main.py")
        sys.exit(1)
    
    # Run the daily coaching
    run_daily_coaching()
