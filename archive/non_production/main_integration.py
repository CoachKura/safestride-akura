# Add these imports at the top of ai_agents/main.py after existing imports

# Phase 0 Stabilization - New Services
from orchestrator import AISRiOrchestrator
from env_validator import validate_environment, print_environment_report
from aisri_safety_gate import AISRISafetyGate
from strava_oauth_service import StravaOAuthService

# Initialize orchestrator on startup
orchestrator = None

@app.on_event('startup')
async def startup_event():
    '''Startup validation and initialization'''
    global orchestrator
    
    print('\n' + '='*70)
    print('🚀 AISRI AI ENGINE STARTUP')
    print('='*70 + '\n')
    
    # Validate environment
    is_valid, missing = validate_environment(verbose=True)
    
    if not is_valid:
        print(f'\n⚠️  WARNING: Missing {len(missing)} required environment variables')
        print('System will start but some features may not work.\n')
    
    # Initialize orchestrator
    try:
        orchestrator = AISRiOrchestrator()
        print('✅ Orchestrator initialized\n')
    except Exception as e:
        print(f'❌ Failed to initialize orchestrator: {e}\n')
    
    print('='*70)
    print('✅ AISRI AI ENGINE READY')
    print('='*70 + '\n')

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
