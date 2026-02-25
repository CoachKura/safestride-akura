"""
Strava & Garmin Activity Integration
Real-time activity sync with workout analysis pipeline.

Features:
- Strava webhook listener (activity.create events)
- Garmin webhook listener (activity push)
- Activity data parser (TCX, GPX, FIT formats)
- Automatic workout analysis on completion
- Performance tracking & ability updates

Integration Flow:
1. Webhook receives activity data
2. Parse activity → workout result
3. Match to assignment (if exists)
4. Analyze performance (GIVEN vs RESULT)
5. Update ability progression
6. Generate next workout
"""

import os
import hmac
import hashlib
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

from fastapi import FastAPI, Request, HTTPException, BackgroundTasks, Header
from fastapi.responses import JSONResponse
import httpx

# Import our modules
from database_integration import DatabaseIntegration
from performance_tracker import WorkoutType


@dataclass
class StravaActivity:
    """Strava activity data"""
    id: int
    athlete_id: int
    name: str
    type: str  # Run, Ride, Swim, etc.
    start_date: datetime
    distance_meters: float
    moving_time_seconds: int
    elapsed_time_seconds: int
    total_elevation_gain: float
    avg_speed: float
    max_speed: float
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    avg_cadence: Optional[float] = None
    suffer_score: Optional[int] = None
    splits_km: Optional[List[Dict]] = None


@dataclass
class GarminActivity:
    """Garmin activity data"""
    activity_id: str
    athlete_id: str
    activity_name: str
    activity_type: str
    start_time: datetime
    duration_seconds: int
    distance_meters: float
    calories: int
    avg_hr: Optional[int] = None
    max_hr: Optional[int] = None
    avg_pace: Optional[float] = None
    elevation_gain: Optional[float] = None
    laps: Optional[List[Dict]] = None


class ActivityIntegration:
    """
    Handles Strava & Garmin activity webhooks and processing.
    
    Workflow:
    1. Webhook callback receives activity
    2. Parse activity data
    3. Convert to workout result
    4. Process through performance tracker
    5. Update athlete ability
    6. Generate next workout
    """
    
    def __init__(self, database: DatabaseIntegration):
        """Initialize activity integration"""
        self.db = database
        
        # Strava configuration
        self.strava_client_id = os.getenv("STRAVA_CLIENT_ID")
        self.strava_client_secret = os.getenv("STRAVA_CLIENT_SECRET")
        self.strava_verify_token = os.getenv("STRAVA_VERIFY_TOKEN", "SAFESTRIDE_VERIFY")
        
        # Garmin configuration
        self.garmin_consumer_key = os.getenv("GARMIN_CONSUMER_KEY")
        self.garmin_consumer_secret = os.getenv("GARMIN_CONSUMER_SECRET")
        
        # HTTP client for API calls
        self.http_client = httpx.AsyncClient()
    
    async def handle_strava_webhook(
        self,
        request: Request,
        background_tasks: BackgroundTasks
    ) -> Dict:
        """
        Handle Strava webhook callback.
        
        Webhook Events:
        - create: New activity uploaded
        - update: Activity edited
        - delete: Activity deleted
        """
        
        # Parse webhook payload
        body = await request.json()
        
        # Subscription verification (initial setup)
        if request.method == "GET":
            return await self._verify_strava_subscription(request)
        
        # Activity webhook callback
        aspect_type = body.get("aspect_type")  # create, update, delete
        object_type = body.get("object_type")  # activity, athlete
        object_id = body.get("object_id")  # Activity ID
        owner_id = body.get("owner_id")  # Athlete ID
        
        if object_type == "activity" and aspect_type == "create":
            # Process new activity in background
            background_tasks.add_task(
                self._process_strava_activity,
                activity_id=object_id,
                athlete_id=owner_id
            )
            
            return {
                "status": "processing",
                "activity_id": object_id,
                "athlete_id": owner_id
            }
        
        return {"status": "ignored", "reason": f"Event type {aspect_type} not handled"}
    
    async def _verify_strava_subscription(self, request: Request) -> Dict:
        """Verify Strava webhook subscription (GET request)"""
        
        # Extract verification params
        params = dict(request.query_params)
        hub_mode = params.get("hub.mode")
        hub_verify_token = params.get("hub.verify_token")
        hub_challenge = params.get("hub.challenge")
        
        # Verify token matches
        if hub_mode == "subscribe" and hub_verify_token == self.strava_verify_token:
            return {"hub.challenge": hub_challenge}
        
        raise HTTPException(status_code=403, detail="Invalid verify token")
    
    async def _process_strava_activity(
        self,
        activity_id: int,
        athlete_id: int
    ):
        """
        Process Strava activity (background task).
        
        Steps:
        1. Fetch full activity data from Strava API
        2. Parse into workout result
        3. Find matching assignment (if exists)
        4. Analyze performance
        5. Update ability
        6. Generate next workout
        """
        
        try:
            # Step 1: Fetch activity from Strava API
            activity_data = await self._fetch_strava_activity(activity_id, athlete_id)
            
            if not activity_data:
                print(f"⚠️ Failed to fetch Strava activity {activity_id}")
                return
            
            # Step 2: Convert to our format
            activity = self._parse_strava_activity(activity_data)
            
            # Only process running activities
            if activity.type.lower() not in ["run", "virtualrun"]:
                print(f"ℹ️ Skipping non-running activity: {activity.type}")
                return
            
            # Step 3: Convert to workout result
            workout_result = self._activity_to_workout_result(activity, athlete_id)
            
            # Step 4: Find matching assignment (look for today's workouts)
            assignment = self._find_matching_assignment(
                athlete_id=str(athlete_id),
                activity_date=activity.start_date,
                distance_km=workout_result["distance_km"]
            )
            
            if assignment:
                # Step 5: Process workout completion with GIVEN vs RESULT
                result = self.db.process_workout_completion(
                    assignment_id=assignment['id'],
                    athlete_id=str(athlete_id),
                    workout_data=workout_result
                )
                
                print(f"✅ Processed Strava activity {activity_id}")
                print(f"   Performance: {result.get('performance_label')}")
                print(f"   Ability Change: {result.get('ability_change'):+.1f}")
                print(f"   Next Workout: {result.get('next_workout_id')}")
            else:
                # No matching assignment - log as ad-hoc workout
                print(f"ℹ️ No assignment found for activity {activity_id}")
                print(f"   Logging as ad-hoc workout")
                
                # Store as workout result without assignment
                self.db.store_workout_result(
                    assignment_id=None,
                    athlete_id=str(athlete_id),
                    result=workout_result,
                    assessment=None
                )
        
        except Exception as e:
            print(f"❌ Error processing Strava activity {activity_id}: {e}")
            import traceback
            traceback.print_exc()
    
    async def _fetch_strava_activity(
        self,
        activity_id: int,
        athlete_id: int
    ) -> Optional[Dict]:
        """
        Fetch detailed activity from Strava API.
        
        Requires athlete's access token (stored in database).
        """
        
        # Get athlete's Strava access token from database
        athlete = self.db.get_athlete_profile(str(athlete_id))
        if not athlete:
            print(f"❌ Athlete {athlete_id} not found")
            return None
        
        strava_token = athlete.get('strava_access_token')
        if not strava_token:
            print(f"❌ No Strava token for athlete {athlete_id}")
            return None
        
        # Fetch activity from Strava API
        try:
            response = await self.http_client.get(
                f"https://www.strava.com/api/v3/activities/{activity_id}",
                headers={"Authorization": f"Bearer {strava_token}"}
            )
            response.raise_for_status()
            return response.json()
        
        except httpx.HTTPStatusError as e:
            print(f"❌ Strava API error: {e.response.status_code}")
            return None
    
    def _parse_strava_activity(self, data: Dict) -> StravaActivity:
        """Parse Strava API response into our format"""
        
        return StravaActivity(
            id=data['id'],
            athlete_id=data['athlete']['id'],
            name=data['name'],
            type=data['type'],
            start_date=datetime.fromisoformat(data['start_date'].replace('Z', '+00:00')),
            distance_meters=data['distance'],
            moving_time_seconds=data['moving_time'],
            elapsed_time_seconds=data['elapsed_time'],
            total_elevation_gain=data.get('total_elevation_gain', 0),
            avg_speed=data.get('average_speed', 0),
            max_speed=data.get('max_speed', 0),
            avg_hr=data.get('average_heartrate'),
            max_hr=data.get('max_heartrate'),
            avg_cadence=data.get('average_cadence'),
            suffer_score=data.get('suffer_score'),
            splits_km=data.get('splits_metric', [])
        )
    
    def _activity_to_workout_result(
        self,
        activity: StravaActivity,
        athlete_id: int
    ) -> Dict:
        """Convert activity to workout result format"""
        
        # Calculate pace (seconds per km)
        distance_km = activity.distance_meters / 1000
        avg_pace_seconds = int(activity.moving_time_seconds / distance_km) if distance_km > 0 else 0
        
        # Determine workout type from activity name and data
        workout_type = self._infer_workout_type(
            name=activity.name,
            distance_km=distance_km,
            avg_pace_seconds=avg_pace_seconds,
            splits=activity.splits_km
        )
        
        return {
            "workout_id": f"STRAVA_{activity.id}",
            "completed_date": activity.start_date.isoformat(),
            "distance_km": distance_km,
            "total_time_seconds": activity.moving_time_seconds,
            "avg_pace_seconds": avg_pace_seconds,
            "avg_hr": activity.avg_hr,
            "max_hr": activity.max_hr,
            "completed_full": True,
            "elevation_gain": activity.total_elevation_gain,
            "notes": f"Strava: {activity.name}"
        }
    
    def _infer_workout_type(
        self,
        name: str,
        distance_km: float,
        avg_pace_seconds: int,
        splits: Optional[List[Dict]]
    ) -> str:
        """
        Infer workout type from activity data.
        
        Rules:
        - "easy", "recovery" in name → easy
        - "tempo", "threshold" in name → tempo
        - "interval", "repeat", "speed" in name → intervals
        - "long", "LSD" in name → long
        - distance > 16km → long
        - High pace variance in splits → intervals
        - Default → easy
        """
        
        name_lower = name.lower()
        
        # Check name keywords
        if any(keyword in name_lower for keyword in ["easy", "recovery", "shake"]):
            return "easy"
        if any(keyword in name_lower for keyword in ["tempo", "threshold", "marathon pace"]):
            return "tempo"
        if any(keyword in name_lower for keyword in ["interval", "repeat", "speed", "track", "fartlek"]):
            return "intervals"
        if any(keyword in name_lower for keyword in ["long", "lsd", "endurance"]):
            return "long"
        
        # Check distance
        if distance_km > 16:
            return "long"
        
        # Check pace variance in splits (indicates intervals)
        if splits and len(splits) > 5:
            paces = [split.get('average_speed', 0) for split in splits]
            if paces:
                avg = sum(paces) / len(paces)
                variance = sum(abs(p - avg) for p in paces) / len(paces)
                if variance / avg > 0.15:  # 15% variance
                    return "intervals"
        
        # Default to easy
        return "easy"
    
    def _find_matching_assignment(
        self,
        athlete_id: str,
        activity_date: datetime,
        distance_km: float
    ) -> Optional[Dict]:
        """
        Find matching workout assignment for activity.
        
        Matching criteria:
        - Same day (within 24 hours)
        - Status: assigned or in_progress
        - Distance within 15% tolerance
        """
        
        # Get athlete's recent assignments
        assignments = self.db.get_athlete_workouts(
            athlete_id=athlete_id,
            status="assigned",
            limit=10
        )
        
        # Find best match
        for assignment in assignments:
            # Check date (within 24 hours)
            scheduled_date = datetime.fromisoformat(assignment['scheduled_date'])
            time_diff = abs((activity_date - scheduled_date).total_seconds())
            
            if time_diff > 86400:  # 24 hours
                continue
            
            # Check distance (within 15% tolerance)
            assignment_distance = assignment.get('distance_km', 0)
            if assignment_distance == 0:
                continue
            
            distance_diff_pct = abs(distance_km - assignment_distance) / assignment_distance
            
            if distance_diff_pct <= 0.15:  # 15% tolerance
                return assignment
        
        return None
    
    async def handle_garmin_webhook(
        self,
        request: Request,
        background_tasks: BackgroundTasks
    ) -> Dict:
        """
        Handle Garmin webhook callback.
        
        Garmin sends activity summaries via POST.
        """
        
        # Verify Garmin signature
        if not await self._verify_garmin_signature(request):
            raise HTTPException(status_code=403, detail="Invalid signature")
        
        # Parse webhook payload
        body = await request.json()
        
        # Process activities
        activities = body.get("activitySummaries", [])
        
        for activity_data in activities:
            background_tasks.add_task(
                self._process_garmin_activity,
                activity_data=activity_data
            )
        
        return {
            "status": "processing",
            "activities_count": len(activities)
        }
    
    async def _verify_garmin_signature(self, request: Request) -> bool:
        """Verify Garmin webhook signature (OAuth 1.0)"""
        
        # Get OAuth signature from header
        auth_header = request.headers.get("Authorization", "")
        
        # TODO: Implement OAuth 1.0 signature verification
        # For now, return True (implement when Garmin integration is live)
        return True
    
    async def _process_garmin_activity(self, activity_data: Dict):
        """Process Garmin activity (background task)"""
        
        try:
            # Parse Garmin activity
            activity = self._parse_garmin_activity(activity_data)
            
            # Only process running activities
            if activity.activity_type.lower() != "running":
                print(f"ℹ️ Skipping non-running activity: {activity.activity_type}")
                return
            
            # Convert to workout result
            workout_result = self._garmin_activity_to_workout_result(activity)
            
            # Find matching assignment
            assignment = self._find_matching_assignment(
                athlete_id=activity.athlete_id,
                activity_date=activity.start_time,
                distance_km=workout_result["distance_km"]
            )
            
            if assignment:
                # Process workout completion
                result = self.db.process_workout_completion(
                    assignment_id=assignment['id'],
                    athlete_id=activity.athlete_id,
                    workout_data=workout_result
                )
                
                print(f"✅ Processed Garmin activity {activity.activity_id}")
                print(f"   Performance: {result.get('performance_label')}")
            else:
                print(f"ℹ️ No assignment found for Garmin activity {activity.activity_id}")
                
                # Store as ad-hoc workout
                self.db.store_workout_result(
                    assignment_id=None,
                    athlete_id=activity.athlete_id,
                    result=workout_result,
                    assessment=None
                )
        
        except Exception as e:
            print(f"❌ Error processing Garmin activity: {e}")
            import traceback
            traceback.print_exc()
    
    def _parse_garmin_activity(self, data: Dict) -> GarminActivity:
        """Parse Garmin webhook data"""
        
        return GarminActivity(
            activity_id=str(data['activityId']),
            athlete_id=str(data['userId']),
            activity_name=data.get('activityName', 'Running'),
            activity_type=data.get('activityType', 'running'),
            start_time=datetime.fromisoformat(data['startTimeGMT']),
            duration_seconds=int(data['duration']),
            distance_meters=float(data['distance']),
            calories=int(data.get('calories', 0)),
            avg_hr=data.get('averageHR'),
            max_hr=data.get('maxHR'),
            avg_pace=data.get('averagePace'),
            elevation_gain=data.get('elevationGain'),
            laps=data.get('laps', [])
        )
    
    def _garmin_activity_to_workout_result(
        self,
        activity: GarminActivity
    ) -> Dict:
        """Convert Garmin activity to workout result"""
        
        distance_km = activity.distance_meters / 1000
        avg_pace_seconds = int(activity.duration_seconds / distance_km) if distance_km > 0 else 0
        
        return {
            "workout_id": f"GARMIN_{activity.activity_id}",
            "completed_date": activity.start_time.isoformat(),
            "distance_km": distance_km,
            "total_time_seconds": activity.duration_seconds,
            "avg_pace_seconds": avg_pace_seconds,
            "avg_hr": activity.avg_hr,
            "max_hr": activity.max_hr,
            "completed_full": True,
            "notes": f"Garmin: {activity.activity_name}"
        }


# FastAPI application with webhook endpoints
app = FastAPI(title="SafeStride Activity Integration")

# Initialize integration
db = DatabaseIntegration()
activity_integration = ActivityIntegration(database=db)


@app.post("/webhooks/strava")
async def strava_webhook(
    request: Request,
    background_tasks: BackgroundTasks
):
    """Strava webhook endpoint"""
    return await activity_integration.handle_strava_webhook(request, background_tasks)


@app.get("/webhooks/strava")
async def strava_webhook_verify(request: Request):
    """Strava subscription verification"""
    return await activity_integration.handle_strava_webhook(request, BackgroundTasks())


@app.post("/webhooks/garmin")
async def garmin_webhook(
    request: Request,
    background_tasks: BackgroundTasks
):
    """Garmin webhook endpoint"""
    return await activity_integration.handle_garmin_webhook(request, background_tasks)


@app.get("/health")
async def health_check():
    """Health check"""
    return {
        "status": "healthy",
        "service": "SafeStride Activity Integration",
        "timestamp": datetime.now().isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        reload=True
    )
