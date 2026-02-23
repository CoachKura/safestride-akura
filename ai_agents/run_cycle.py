"""
Production-Ready Daily Runner for SafeStride AI

Supports both local and production API endpoints.
Set ENVIRONMENT variable to switch between them.
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

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = (
    os.getenv("SUPABASE_SERVICE_KEY")
    or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    or os.getenv("SUPABASE_ANON_KEY")
)

# API Configuration - supports both local and production
ENVIRONMENT = os.getenv("ENVIRONMENT", "production").lower()  # Default to production
PRODUCTION_API_URL = os.getenv("PRODUCTION_API_URL", "https://aisri-ai-engine-production.up.railway.app")
LOCAL_API_URL = os.getenv("LOCAL_API_URL", "http://127.0.0.1:8001")

# Select API base URL based on environment
if ENVIRONMENT == "production":
    API_BASE_URL = PRODUCTION_API_URL
else:
    API_BASE_URL = LOCAL_API_URL


def log(message: str):
    """Print timestamped log message."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


def test_connection():
    """Test if the API server is accessible."""
    log(f"Testing connection to API server ({ENVIRONMENT})...")
    log(f"URL: {API_BASE_URL}")
    
    try:
        response = requests.get(f"{API_BASE_URL}/", timeout=10)
        response.raise_for_status()
        log("✅ API server is accessible")
        return True
    except Exception as e:
        log(f"❌ Cannot connect to API server: {str(e)}")
        log(f"   Make sure server is running at {API_BASE_URL}")
        return False


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


def run_simple_cycle():
    """
    Simple version - just run all 3 AI agents for each athlete.
    No database saving, just API calls.
    """
    log("=" * 70)
    log(f"🚀 Starting AISRi Daily Cycle ({ENVIRONMENT.upper()} API)")
    log("=" * 70)
    
    try:
        athletes = get_all_athletes()
        
        for i, athlete in enumerate(athletes, 1):
            athlete_id = athlete["id"]
            name = athlete.get("full_name", "Unknown")
            
            log(f"\n{i}. Processing: {name}")
            
            try:
                # Run all 3 agents
                get_decision_for_athlete(athlete_id)
                get_injury_prediction_for_athlete(athlete_id)
                generate_workout_for_athlete(athlete_id)
                log(f"   ✅ All 3 agents completed")
                
            except Exception as e:
                log(f"   ❌ ERROR: {str(e)}")
        
        log("\n" + "=" * 70)
        log("✅ AISRi daily cycle complete!")
        log("=" * 70)
        
    except Exception as e:
        log(f"\n❌ CRITICAL ERROR: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    # Show configuration
    log("")
    log("=" * 70)
    log("CONFIGURATION")
    log("=" * 70)
    log(f"Environment: {ENVIRONMENT.upper()}")
    log(f"API URL: {API_BASE_URL}")
    log(f"Supabase: {'Connected' if SUPABASE_URL else 'Not configured'}")
    log("=" * 70)
    log("")
    
    # Test connection first
    if not test_connection():
        log("")
        if ENVIRONMENT == "local":
            log("💡 To start the local server:")
            log("   cd C:\\safestride\\ai_agents")
            log("   python main.py")
        else:
            log("💡 Check your production server at:")
            log(f"   {PRODUCTION_API_URL}")
        sys.exit(1)
    
    # Run the daily cycle
    run_simple_cycle()
