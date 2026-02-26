"""
SafeStride Strava Signup & Activity Sync API

Handles Strava OAuth signup, profile creation in Supabase, and full
activity sync with PB calculation — using direct httpx REST calls to
avoid supabase-py / gotrue compatibility issues on Python 3.13+.
"""

# Python 3.13+ removed the 'cgi' module; use legacy-cgi as a drop-in replacement
import sys
try:
    import cgi
except ImportError:
    import legacy_cgi as cgi
    sys.modules['cgi'] = cgi

from fastapi import FastAPI, HTTPException, BackgroundTasks, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import httpx
import os
import math
import asyncio
from dotenv import load_dotenv
import uvicorn
from datetime import datetime

load_dotenv()

app = FastAPI(title="SafeStride Strava API")

# Router for including in other FastAPI apps (e.g. main.py / api.akura.in)
strava_router = APIRouter()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Configuration ───────────────────────────────────────────────────────────
STRAVA_CLIENT_ID     = os.getenv('STRAVA_CLIENT_ID', '162971')
STRAVA_CLIENT_SECRET = os.getenv('STRAVA_CLIENT_SECRET', '')
SUPABASE_URL         = os.getenv('SUPABASE_URL', '')
SUPABASE_SERVICE_KEY = (
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    or os.getenv('SUPABASE_SERVICE_KEY')
    or ''
)
PORT                 = int(os.getenv('PORT', '8002'))  # Render sets PORT automatically

STRAVA_TOKEN_URL      = 'https://www.strava.com/oauth/token'
STRAVA_ACTIVITIES_URL = 'https://www.strava.com/api/v3/athlete/activities'

# ── Models ──────────────────────────────────────────────────────────────────
class StravaSignupRequest(BaseModel):
    code: str

class SyncActivitiesRequest(BaseModel):
    strava_athlete_id: str
    access_token: str

class StravaSignupResponse(BaseModel):
    user_id: str
    strava_athlete_id: str
    access_token: str
    refresh_token: str
    athlete: dict
    message: str
    is_new_user: bool = True
    activities_synced: Optional[int] = None

# ── Helpers ──────────────────────────────────────────────────────────────────
def _supabase_headers(prefer: str = "") -> dict:
    h = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json',
    }
    if prefer:
        h['Prefer'] = prefer
    return h

def _best_time_at_distance(runs: list, target_m: float, min_m: float, max_m: float) -> Optional[int]:
    """
    Best proportional time (in seconds) at target_m based on runs
    within [min_m, max_m] distance. Returns None if no qualifying runs.
    Uses a Riegel-style scaling: best_time = actual_time * (target / actual)^1.06
    """
    candidates = [
        r for r in runs
        if min_m <= r.get('distance', 0) <= max_m and r.get('moving_time', 0) > 0
    ]
    if not candidates:
        return None
    times = [
        int(r['moving_time'] * math.pow(target_m / r['distance'], 1.06))
        for r in candidates
    ]
    return min(times)

async def fetch_all_strava_activities(access_token: str) -> list:
    """Page through Strava activities API, returning all Run-type activities."""
    runs = []
    page = 1
    async with httpx.AsyncClient(timeout=30) as client:
        while True:
            resp = await client.get(
                STRAVA_ACTIVITIES_URL,
                headers={'Authorization': f'Bearer {access_token}'},
                params={'per_page': 100, 'page': page}
            )
            if resp.status_code != 200:
                break
            activities = resp.json()
            if not activities:
                break
            runs.extend([a for a in activities if a.get('type') == 'Run'])
            if len(activities) < 100:
                break  # last page
            page += 1
            await asyncio.sleep(0.2)  # be polite to Strava rate limits
    return runs

async def sync_activities_background(strava_athlete_id: str, access_token: str):
    """
    Background task: fetch all runs, calculate PBs, upsert strava_activities,
    and update profile statistics.
    """
    try:
        runs = await fetch_all_strava_activities(access_token)
        if not runs:
            return

        # ── Calculate PBs (stored in seconds) ──────────────────────────────
        pb_5k         = _best_time_at_distance(runs, 5000,  4000,  7000)
        pb_10k        = _best_time_at_distance(runs, 10000, 8000,  13000)
        pb_half       = _best_time_at_distance(runs, 21097, 18000, 24000)
        pb_marathon   = _best_time_at_distance(runs, 42195, 38000, 46000)

        # ── Aggregate stats ─────────────────────────────────────────────────
        total_runs     = len(runs)
        total_dist_m   = sum(r.get('distance', 0) for r in runs)
        total_dist_km  = round(total_dist_m / 1000, 2)
        total_time_s   = sum(r.get('moving_time', 0) for r in runs)
        total_time_h   = round(total_time_s / 3600, 2)
        avg_pace       = round((total_time_s / 60) / (total_dist_km), 2) if total_dist_km > 0 else None
        longest_run_km = round(max((r.get('distance', 0) for r in runs), default=0) / 1000, 2)

        async with httpx.AsyncClient(timeout=30) as client:
            # ── Update profile PBs & stats ──────────────────────────────────
            patch_data = {
                'total_runs':         total_runs,
                'total_distance_km':  total_dist_km,
                'total_time_hours':   total_time_h,
                'avg_pace_min_per_km': avg_pace,
                'longest_run_km':     longest_run_km,
                'last_strava_sync':   datetime.utcnow().isoformat(),
            }
            if pb_5k:       patch_data['pb_5k']            = pb_5k
            if pb_10k:      patch_data['pb_10k']           = pb_10k
            if pb_half:     patch_data['pb_half_marathon'] = pb_half
            if pb_marathon: patch_data['pb_marathon']      = pb_marathon

            await client.patch(
                f'{SUPABASE_URL}/rest/v1/profiles',
                headers=_supabase_headers('return=minimal'),
                params={'strava_athlete_id': f'eq.{strava_athlete_id}'},
                json=patch_data
            )

            # ── Upsert individual activities ────────────────────────────────
            # Fetch profile id for this athlete to use as user_id FK
            prof_resp = await client.get(
                f'{SUPABASE_URL}/rest/v1/profiles',
                headers=_supabase_headers(),
                params={'strava_athlete_id': f'eq.{strava_athlete_id}', 'select': 'id'}
            )
            if prof_resp.status_code != 200 or not prof_resp.json():
                return
            profile_id = prof_resp.json()[0]['id']

            rows = []
            for r in runs:
                rows.append({
                    'strava_activity_id':    r['id'],
                    'user_id':               profile_id,
                    'name':                  r.get('name'),
                    'distance_meters':       r.get('distance'),
                    'moving_time_seconds':   r.get('moving_time'),
                    'elapsed_time_seconds':  r.get('elapsed_time'),
                    'total_elevation_gain':  r.get('total_elevation_gain'),
                    'activity_type':         r.get('type'),
                    'start_date':            r.get('start_date'),
                    'average_speed':         r.get('average_speed'),
                    'max_speed':             r.get('max_speed'),
                    'average_heartrate':     r.get('average_heartrate'),
                    'max_heartrate':         r.get('max_heartrate'),
                    'average_cadence':       r.get('average_cadence'),
                })

            # Batch upsert in chunks of 50
            for i in range(0, len(rows), 50):
                chunk = rows[i:i+50]
                await client.post(
                    f'{SUPABASE_URL}/rest/v1/strava_activities',
                    headers=_supabase_headers('resolution=merge-duplicates,return=minimal'),
                    params={'on_conflict': 'strava_activity_id'},
                    json=chunk
                )
                await asyncio.sleep(0.1)

    except Exception as e:
        import traceback
        print(f"[sync_activities] ERROR for athlete {strava_athlete_id}: {e}")
        print(traceback.format_exc())

# ── Routes ───────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "service": "SafeStride Strava API",
        "status": "running",
        "endpoints": {
            "POST /api/strava-signup":           "OAuth signup + auto activity sync",
            "POST /api/strava-sync-activities":  "Manual activity sync",
            "GET  /health":                      "Health check",
        }
    }

@app.get("/health")
def health():
    return {"status": "healthy", "timestamp": str(datetime.utcnow())}

@strava_router.post("/api/strava-signup", response_model=StravaSignupResponse)
@app.post("/api/strava-signup", response_model=StravaSignupResponse)
async def strava_signup(request: StravaSignupRequest, background_tasks: BackgroundTasks):
    """Exchange Strava auth code, upsert profile, then sync activities in background."""
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            # ── Step 1: Exchange code → token ───────────────────────────────
            token_resp = await client.post(
                STRAVA_TOKEN_URL,
                data={
                    'client_id':     STRAVA_CLIENT_ID,
                    'client_secret': STRAVA_CLIENT_SECRET,
                    'code':          request.code,
                    'grant_type':    'authorization_code',
                }
            )
            if token_resp.status_code != 200:
                raise HTTPException(status_code=400, detail=f"Strava token exchange failed: {token_resp.text}")

            token_data          = token_resp.json()
            strava_access_token = token_data.get('access_token')
            strava_athlete      = token_data.get('athlete', {})
            athlete_id          = strava_athlete.get('id')
            placeholder_email   = f"strava_{athlete_id}@strava.safestride.app"

            # ── Step 1b: Check if athlete already exists (returning user) ──
            existing_resp = await client.get(
                f'{SUPABASE_URL}/rest/v1/profiles',
                headers=_supabase_headers(),
                params={'strava_athlete_id': f'eq.{athlete_id}', 'select': 'id'}
            )
            is_new_user = not (existing_resp.status_code == 200 and existing_resp.json())

            # ── Step 2: Upsert profile ──────────────────────────────────────
            profile_data = {
                'email':                    placeholder_email,
                'strava_athlete_id':        str(athlete_id),
                'full_name':                f"{strava_athlete.get('firstname','')} {strava_athlete.get('lastname','')}".strip(),
                'profile_photo_url':        strava_athlete.get('profile'),
                'city':                     strava_athlete.get('city'),
                'state':                    strava_athlete.get('state'),
                'country':                  strava_athlete.get('country'),
                'gender':                   strava_athlete.get('sex'),
                'weight':                   strava_athlete.get('weight'),
                'strava_access_token':      strava_access_token,
                'strava_refresh_token':     token_data.get('refresh_token'),
                'strava_token_expires_at':  (
                    datetime.utcfromtimestamp(token_data['expires_at']).isoformat()
                    if token_data.get('expires_at') else None
                ),
                'last_strava_sync':         datetime.utcnow().isoformat(),
                'updated_at':               datetime.utcnow().isoformat(),
            }

            prof_resp = await client.post(
                f'{SUPABASE_URL}/rest/v1/profiles',
                headers=_supabase_headers('resolution=merge-duplicates,return=representation'),
                params={'on_conflict': 'strava_athlete_id'},
                json=profile_data
            )
            if prof_resp.status_code not in [200, 201]:
                raise HTTPException(status_code=500, detail=f"Failed to create profile: {prof_resp.text}")

            prof_obj = prof_resp.json()
            prof_obj = prof_obj[0] if isinstance(prof_obj, list) else prof_obj
            user_id  = prof_obj.get('id', 'unknown') if isinstance(prof_obj, dict) else str(prof_obj)

            # ── Step 3: Kick off activity sync in background ────────────────
            background_tasks.add_task(
                sync_activities_background, str(athlete_id), strava_access_token
            )

            msg = (
                "Welcome to SafeStride! Profile created and Strava connected. Syncing activities…"
                if is_new_user else
                "Welcome back! Tokens refreshed and activities re-syncing…"
            )
            return StravaSignupResponse(
                user_id=str(user_id),
                strava_athlete_id=str(athlete_id),
                access_token=strava_access_token,
                refresh_token=token_data.get('refresh_token', ''),
                athlete=strava_athlete,
                message=msg,
                is_new_user=is_new_user,
            )

    except HTTPException:
        raise
    except httpx.HTTPError as e:
        raise HTTPException(status_code=500, detail=f"HTTP error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@strava_router.post("/api/strava-sync-activities")
@app.post("/api/strava-sync-activities")
async def manual_sync(request: SyncActivitiesRequest):
    """Manually trigger a full activity sync for an athlete."""
    try:
        await sync_activities_background(request.strava_athlete_id, request.access_token)
        return {"status": "ok", "message": "Activities synced successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@strava_router.get("/api/athlete-stats/{strava_athlete_id}")
@app.get("/api/athlete-stats/{strava_athlete_id}")
async def athlete_stats(strava_athlete_id: str):
    """Return profile stats and PBs for display after sync."""
    async with httpx.AsyncClient(timeout=10) as client:
        # Profile stats
        prof_resp = await client.get(
            f'{SUPABASE_URL}/rest/v1/profiles',
            headers=_supabase_headers(),
            params={
                'strava_athlete_id': f'eq.{strava_athlete_id}',
                'select': 'full_name,profile_photo_url,city,country,total_runs,total_distance_km,total_time_hours,avg_pace_min_per_km,longest_run_km,pb_5k,pb_10k,pb_half_marathon,pb_marathon,last_strava_sync'
            }
        )
        if prof_resp.status_code != 200 or not prof_resp.json():
            raise HTTPException(status_code=404, detail="Athlete not found")
        profile = prof_resp.json()[0]
        # Return flat structure so JS can access fields directly
        return {
            "full_name":           profile.get('full_name'),
            "profile_photo_url":   profile.get('profile_photo_url'),
            "city":                profile.get('city'),
            "country":             profile.get('country'),
            "total_runs":          profile.get('total_runs'),
            "total_distance_km":   profile.get('total_distance_km'),
            "total_time_hours":    profile.get('total_time_hours'),
            "avg_pace_min_per_km": profile.get('avg_pace_min_per_km'),
            "longest_run_km":      profile.get('longest_run_km'),
            "pb_5k":               profile.get('pb_5k'),
            "pb_10k":              profile.get('pb_10k'),
            "pb_half_marathon":    profile.get('pb_half_marathon'),
            "pb_marathon":         profile.get('pb_marathon'),
            "last_strava_sync":    profile.get('last_strava_sync'),
        }


@app.get("/api/strava-mobile-callback")
async def mobile_callback(code: str = "", error: str = ""):
    """
    Landing page used as redirect_uri for mobile OAuth.
    Returns a minimal HTML page — the Flutter WebView intercepts
    this URL before it loads and extracts the `code` parameter.
    """
    if error:
        return {"status": "error", "error": error}
    return {"status": "ok", "code": code}


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("SafeStride Strava API")
    print("=" * 60)
    print(f"  Local:   http://localhost:{PORT}")
    print(f"  Docs:    http://localhost:{PORT}/docs")
    print("=" * 60 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=PORT)
