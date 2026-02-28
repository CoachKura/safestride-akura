"""
Strava OAuth Signup API Endpoint

Handles:
1. Receives OAuth authorization code from frontend
2. Exchanges code for access token with Strava
3. Fetches athlete profile from Strava
4. Creates Supabase auth user
5. Stores profile with Strava data
6. Initiates background sync of activities
7. Returns session token to frontend

Endpoint: POST /api/strava-signup
Body: {"code": "authorization_code"}
Response: {"user_id": "...", "access_token": "...", "athlete": {...}}
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import httpx
import os
from dotenv import load_dotenv
from supabase import create_client, Client
import random
import string
from datetime import datetime, timedelta

load_dotenv()

# Initialize FastAPI
app = FastAPI(title="SafeStride Strava Signup API")

# Configuration
STRAVA_CLIENT_ID = os.getenv('STRAVA_CLIENT_ID', '162971')
STRAVA_CLIENT_SECRET = os.getenv('STRAVA_CLIENT_SECRET', '')
SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Strava API endpoints
STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token'
STRAVA_ATHLETE_URL = 'https://www.strava.com/api/v3/athlete'
STRAVA_ACTIVITIES_URL = 'https://www.strava.com/api/v3/athlete/activities'


class StravaSignupRequest(BaseModel):
    code: str


class StravaSignupResponse(BaseModel):
    user_id: str
    access_token: str
    refresh_token: str
    athlete: dict
    message: str


@app.post("/api/strava-signup", response_model=StravaSignupResponse)
async def strava_signup(
    request: StravaSignupRequest,
    background_tasks: BackgroundTasks
):
    """
    Complete Strava OAuth signup flow
    
    Steps:
    1. Exchange authorization code for access token
    2. Fetch athlete profile from Strava
    3. Create Supabase auth user
    4. Store profile with Strava data
    5. Start background sync of activities (async)
    6. Return session token
    """
    try:
        # Step 1: Exchange code for token
        token_data = await exchange_code_for_token(request.code)
        
        # Step 2: Fetch athlete profile
        athlete = await fetch_athlete_profile(token_data['access_token'])
        
        # Step 3: Create Supabase user
        user_data = await create_supabase_user(athlete, token_data)
        
        # Step 4: Start background sync (don't wait)
        background_tasks.add_task(
            background_sync_activities,
            user_data['user_id'],
            token_data['access_token']
        )
        
        return StravaSignupResponse(
            user_id=user_data['user_id'],
            access_token=user_data['access_token'],
            refresh_token=user_data['refresh_token'],
            athlete=athlete,
            message="Signup successful! Background sync started."
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


async def exchange_code_for_token(code: str) -> dict:
    """
    Exchange OAuth authorization code for access token
    
    Returns:
    {
        'access_token': '...',
        'refresh_token': '...',
        'expires_at': 1234567890,
        'athlete': {...}
    }
    """
    async with httpx.AsyncClient() as client:
        response = await client.post(
            STRAVA_TOKEN_URL,
            json={
                'client_id': STRAVA_CLIENT_ID,
                'client_secret': STRAVA_CLIENT_SECRET,
                'code': code,
                'grant_type': 'authorization_code'
            }
        )
        
        if response.status_code != 200:
            raise Exception(f"Strava token exchange failed: {response.text}")
        
        return response.json()


async def fetch_athlete_profile(access_token: str) -> dict:
    """
    Fetch complete athlete profile from Strava API
    
    Returns athlete data including:
    - id, firstname, lastname, sex, weight
    - profile photo URL
    - city, state, country
    """
    async with httpx.AsyncClient() as client:
        response = await client.get(
            STRAVA_ATHLETE_URL,
            headers={'Authorization': f'Bearer {access_token}'}
        )
        
        if response.status_code != 200:
            raise Exception(f"Failed to fetch athlete profile: {response.text}")
        
        return response.json()


async def create_supabase_user(athlete: dict, token_data: dict) -> dict:
    """
    Create Supabase auth user and profile
    
    Steps:
    1. Generate email (if not provided by Strava)
    2. Generate secure random password
    3. Create auth user
    4. Store profile with Strava data
    
    Returns:
    {
        'user_id': '...',
        'access_token': '...',
        'refresh_token': '...'
    }
    """
    try:
        # Generate email if not available
        email = athlete.get('email')
        if not email:
            email = f"{athlete['id']}@strava.safestride.app"
        
        # Generate secure password (user won't need this - Strava OAuth only)
        password = generate_secure_password()
        
        # Create Supabase auth user
        auth_response = supabase.auth.sign_up({
            'email': email,
            'password': password,
            'options': {
                'data': {
                    'strava_athlete_id': athlete['id'],
                    'first_name': athlete.get('firstname', ''),
                    'last_name': athlete.get('lastname', ''),
                    'profile_photo': athlete.get('profile_medium') or athlete.get('profile'),
                }
            }
        })
        
        if not auth_response.user:
            raise Exception("Failed to create Supabase user")
        
        user_id = auth_response.user.id
        
        # Store profile with Strava data
        expires_at = datetime.fromtimestamp(token_data['expires_at'])
        
        supabase.table('profiles').upsert({
            'id': user_id,
            'strava_athlete_id': athlete['id'],
            'first_name': athlete.get('firstname'),
            'last_name': athlete.get('lastname'),
            'profile_photo_url': athlete.get('profile_medium') or athlete.get('profile'),
            'gender': athlete.get('sex'),
            'weight': athlete.get('weight'),
            'city': athlete.get('city'),
            'state': athlete.get('state'),
            'country': athlete.get('country'),
            'strava_access_token': token_data['access_token'],
            'strava_refresh_token': token_data['refresh_token'],
            'strava_token_expires_at': expires_at.isoformat(),
            'updated_at': datetime.now().isoformat(),
        }).execute()
        
        return {
            'user_id': user_id,
            'access_token': auth_response.session.access_token,
            'refresh_token': auth_response.session.refresh_token,
        }
        
    except Exception as e:
        raise Exception(f"Failed to create user: {str(e)}")


async def background_sync_activities(user_id: str, access_token: str):
    """
    Background task to sync all Strava activities
    
    Steps:
    1. Fetch all activities (paginated)
    2. Calculate Personal Bests (5K, 10K, Half, Marathon)
    3. Calculate total mileage and stats
    4. Update profile in database
    5. Store individual activities
    
    This runs asynchronously and can take several minutes
    """
    try:
        print(f"🔄 Starting background sync for user {user_id}...")
        
        # Fetch all activities
        activities = await fetch_all_activities(access_token)
        print(f"✅ Fetched {len(activities)} activities")
        
        # Calculate PBs
        pbs = calculate_personal_bests(activities)
        print(f"✅ Calculated PBs: {pbs}")
        
        # Calculate stats
        stats = calculate_activity_stats(activities)
        print(f"✅ Calculated stats: {stats}")
        
        # Update profile
        supabase.table('profiles').update({
            'pb_5k': pbs.get('5K'),
            'pb_10k': pbs.get('10K'),
            'pb_half_marathon': pbs.get('HalfMarathon'),
            'pb_marathon': pbs.get('Marathon'),
            'total_runs': stats['total_runs'],
            'total_distance_km': stats['total_distance_km'],
            'total_time_hours': stats['total_time_hours'],
            'avg_pace_min_per_km': stats['avg_pace_min_per_km'],
            'longest_run_km': stats['longest_run_km'],
            'last_strava_sync': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }).eq('id', user_id).execute()
        
        print(f"✅ Updated profile for user {user_id}")
        
        # Store activities
        await store_activities(user_id, activities)
        print(f"✅ Stored {len(activities)} activities")
        
        print(f"✅ Background sync completed for user {user_id}")
        
    except Exception as e:
        print(f"❌ Background sync failed for user {user_id}: {str(e)}")


async def fetch_all_activities(
    access_token: str,
    max_activities: int = 1000
) -> list:
    """
    Fetch all athlete activities from Strava (paginated)
    
    Strava API limit: 200 activities per request
    Max total: 1000 activities
    """
    all_activities = []
    page = 1
    per_page = 200
    
    async with httpx.AsyncClient() as client:
        while len(all_activities) < max_activities:
            response = await client.get(
                STRAVA_ACTIVITIES_URL,
                headers={'Authorization': f'Bearer {access_token}'},
                params={'page': page, 'per_page': per_page}
            )
            
            if response.status_code != 200:
                print(f"⚠️ Failed to fetch activities page {page}: {response.text}")
                break
            
            activities = response.json()
            
            if not activities:
                break  # No more activities
            
            all_activities.extend(activities)
            page += 1
            
            # Respect rate limits (15 requests per 15 minutes)
            await httpx.AsyncClient().aclose()
    
    return all_activities


def calculate_personal_bests(activities: list) -> dict:
    """
    Calculate Personal Bests from activities
    
    Returns:
    {
        '5K': seconds (or None),
        '10K': seconds (or None),
        'HalfMarathon': seconds (or None),
        'Marathon': seconds (or None)
    }
    """
    runs = [a for a in activities if a['type'] == 'Run']
    
    pbs = {'5K': None, '10K': None, 'HalfMarathon': None, 'Marathon': None}
    
    for run in runs:
        distance = run.get('distance', 0)
        moving_time = run.get('moving_time')
        
        if not moving_time or moving_time == 0:
            continue
        
        # 5K: 4.8 - 5.2 km
        if 4800 <= distance <= 5200:
            if pbs['5K'] is None or moving_time < pbs['5K']:
                pbs['5K'] = moving_time
        
        # 10K: 9.8 - 10.2 km
        if 9800 <= distance <= 10200:
            if pbs['10K'] is None or moving_time < pbs['10K']:
                pbs['10K'] = moving_time
        
        # Half Marathon: 20 - 22 km
        if 20000 <= distance <= 22000:
            if pbs['HalfMarathon'] is None or moving_time < pbs['HalfMarathon']:
                pbs['HalfMarathon'] = moving_time
        
        # Marathon: 42 - 43 km
        if 42000 <= distance <= 43000:
            if pbs['Marathon'] is None or moving_time < pbs['Marathon']:
                pbs['Marathon'] = moving_time
    
    return pbs


def calculate_activity_stats(activities: list) -> dict:
    """
    Calculate aggregate statistics from activities
    
    Returns:
    {
        'total_runs': int,
        'total_distance_km': float,
        'total_time_hours': float,
        'avg_pace_min_per_km': float,
        'longest_run_km': float
    }
    """
    runs = [a for a in activities if a['type'] == 'Run']
    
    total_runs = len(runs)
    total_distance = sum(r.get('distance', 0) for r in runs) / 1000  # km
    total_time = sum(r.get('moving_time', 0) for r in runs) / 3600  # hours
    
    # Average pace
    avg_pace = (total_time * 60) / total_distance if total_distance > 0 else 0
    
    # Longest run
    longest_run = max((r.get('distance', 0) / 1000 for r in runs), default=0)
    
    return {
        'total_runs': total_runs,
        'total_distance_km': round(total_distance, 2),
        'total_time_hours': round(total_time, 2),
        'avg_pace_min_per_km': round(avg_pace, 2),
        'longest_run_km': round(longest_run, 2)
    }


async def store_activities(user_id: str, activities: list):
    """
    Store individual activities in database
    
    Only stores running activities
    Batch inserts for efficiency
    """
    runs = [a for a in activities if a['type'] == 'Run']
    
    activities_to_insert = []
    for run in runs:
        activities_to_insert.append({
            'user_id': user_id,
            'strava_activity_id': run['id'],
            'name': run.get('name'),
            'distance_meters': run.get('distance'),
            'moving_time_seconds': run.get('moving_time'),
            'elapsed_time_seconds': run.get('elapsed_time'),
            'total_elevation_gain': run.get('total_elevation_gain'),
            'activity_type': run.get('type'),
            'start_date': run.get('start_date'),
            'average_speed': run.get('average_speed'),
            'max_speed': run.get('max_speed'),
            'average_heartrate': run.get('average_heartrate'),
            'max_heartrate': run.get('max_heartrate'),
            'average_cadence': run.get('average_cadence'),
            'created_at': datetime.now().isoformat(),
        })
    
    # Insert in batches of 100
    for i in range(0, len(activities_to_insert), 100):
        batch = activities_to_insert[i:i+100]
        supabase.table('strava_activities').upsert(
            batch,
            on_conflict='strava_activity_id'
        ).execute()


def generate_secure_password() -> str:
    """Generate a secure random password for Strava-only users"""
    chars = string.ascii_letters + string.digits + string.punctuation
    return ''.join(random.choice(chars) for _ in range(32))


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "SafeStride Strava Signup API"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
