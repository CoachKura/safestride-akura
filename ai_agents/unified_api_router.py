"""
Unified API Router
Single API gateway for both Flutter App and HTML Training Plan Builder.

Features:
- CORS enabled for web browsers
- Consistent response format
- Shared authentication
- Consolidated endpoints

Endpoints serve BOTH:
- Flutter Mobile App (iOS/Android/Web)
- HTML Training Plan Builder (localhost:55854)
"""

from fastapi import APIRouter, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
import os

# Import existing routers
from aisri_auto_calculator import router as aisri_router
from activity_integration import router as activity_router
from api_endpoints import router as api_router

# Create main unified router
unified_router = APIRouter(prefix="/api/v2", tags=["Unified API"])


# ═══════════════════════════════════════════════════════════════════════
# CORS Configuration (Allow HTML Builder + Flutter Web)
# ═══════════════════════════════════════════════════════════════════════

def configure_cors(app):
    """Enable CORS for cross-origin requests"""
    
    origins = [
        "http://localhost:55854",  # HTML Training Plan Builder
        "http://localhost:3000",   # Flutter web dev server
        "https://www.akura.in",    # Production Flutter web
        "https://app.akura.in",    # Production HTML builder
    ]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# ═══════════════════════════════════════════════════════════════════════
# Authentication Helper
# ═══════════════════════════════════════════════════════════════════════

async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """
    Extract and validate user from Authorization header.
    
    Supports:
    - Flutter: Uses Supabase session token
    - HTML: Uses localStorage token
    
    Header format: "Bearer <token>"
    """
    
    if not authorization:
        raise HTTPException(401, "Missing authorization header")
    
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "Invalid authorization format")
    
    token = authorization.replace("Bearer ", "")
    
    # Validate token with Supabase (pseudo-code - implement actual validation)
    # user = await supabase.auth.get_user(token)
    # if not user:
    #     raise HTTPException(401, "Invalid or expired token")
    
    # For now, extract user_id from token (implement proper JWT validation)
    user_id = "extracted_user_id"  # TODO: Implement JWT decoding
    
    return user_id


# ═══════════════════════════════════════════════════════════════════════
# Unified Endpoints (Serve Both Flutter + HTML)
# ═══════════════════════════════════════════════════════════════════════

@unified_router.get("/health")
async def health_check():
    """
    Health check endpoint.
    
    Usage:
    - Flutter: Check API availability
    - HTML: Verify backend is running
    """
    return {
        "status": "healthy",
        "version": "2.0",
        "services": {
            "aisri_calculator": "online",
            "activity_sync": "online",
            "training_plans": "online"
        }
    }


@unified_router.get("/athlete/profile")
async def get_athlete_profile(user_id: str = Depends(get_current_user)):
    """
    Get athlete profile with all data.
    
    Returns:
    - Basic profile
    - Strava connection status
    - Latest AISRI score
    - Activity summary
    
    Used by:
    - Flutter: Profile screen, dashboard
    - HTML: Header, overview cards
    """
    # Implementation here
    return {
        "user_id": user_id,
        "strava_connected": True,
        "latest_aisri_score": {
            "score": 75,
            "risk_level": "Low",
            "confidence": 85,
            "calculated_at": "2026-02-27T10:00:00Z"
        },
        "activity_summary": {
            "total_runs": 45,
            "total_distance_km": 380.5,
            "total_time_hours": 32.5,
            "avg_pace_min_per_km": 5.2
        }
    }


@unified_router.get("/athlete/aisri")
async def get_aisri_scores(
    user_id: str = Depends(get_current_user),
    include_history: bool = True
):
    """
    Get AISRI scores (current + optional history).
    
    Query params:
    - include_history: If true, returns past 10 scores
    
    Used by:
    - Flutter: AISRI dashboard, trend charts
    - HTML: Score display, comparison graphs
    """
    # Implementation here
    return {
        "current": {
            "aisri_score": 75,
            "risk_level": "Low",
            "confidence": 85,
            "pillars": {
                "adaptability": 78,
                "injury_risk": 70,
                "fatigue": 72,
                "recovery": 80,
                "intensity": 75,
                "consistency": 75
            },
            "calculated_at": "2026-02-27T10:00:00Z",
            "calculation_method": "strava_auto"
        },
        "history": [
            # ... past scores
        ] if include_history else None
    }


@unified_router.post("/athlete/aisri/calculate")
async def trigger_aisri_calculation(user_id: str = Depends(get_current_user)):
    """
    Manually trigger AISRI recalculation.
    
    Used by:
    - Flutter: "Refresh AISRI" button
    - HTML: "Recalculate" button
    """
    # Call aisri_auto_calculator
    return {
        "success": True,
        "message": "AISRI calculation started",
        "estimated_completion": "30 seconds"
    }


@unified_router.get("/athlete/activities")
async def get_athlete_activities(
    user_id: str = Depends(get_current_user),
    limit: int = 30,
    offset: int = 0
):
    """
    Get athlete's recent activities.
    
    Query params:
    - limit: Number of activities (default 30)
    - offset: Pagination offset
    
    Used by:
    - Flutter: Activity history screen
    - HTML: Activity list, calendar view
    """
    # Implementation here
    return {
        "activities": [
            {
                "id": "12345",
                "name": "Morning Run",
                "date": "2026-02-27T07:30:00Z",
                "distance_km": 8.5,
                "duration_minutes": 45,
                "pace_min_per_km": 5.2,
                "avg_heartrate": 155,
                "type": "Run"
            },
            # ... more activities
        ],
        "total_count": 150,
        "has_more": True
    }


@unified_router.get("/athlete/training-plans")
async def get_training_plans(user_id: str = Depends(get_current_user)):
    """
    Get all training plans for athlete.
    
    Used by:
    - Flutter: Training plan screen
    - HTML: Plan selector dropdown
    """
    return {
        "plans": [
            {
                "id": "plan_123",
                "name": "10K Race Training",
                "target_race_distance": "10K",
                "target_race_date": "2026-04-15",
                "weeks_remaining": 6,
                "status": "active",
                "completion_percentage": 45
            },
            # ... more plans
        ]
    }


@unified_router.post("/athlete/training-plans/generate")
async def generate_training_plan(
    plan_request: dict,
    user_id: str = Depends(get_current_user)
):
    """
    Generate new AI-powered training plan.
    
    Request body:
    {
        "target_race_distance": "10K",
        "target_race_date": "2026-04-15",
        "primary_goal": "PR time",
        "aisri_score": 75 (optional, will fetch if not provided)
    }
    
    Used by:
    - Flutter: Training plan builder screen
    - HTML: Plan generation form
    """
    # Implementation here
    return {
        "success": True,
        "plan_id": "plan_456",
        "message": "Training plan generated successfully",
        "plan": {
            "weeks": [
                {
                    "week": 1,
                    "workouts": [
                        {
                            "day": "Monday",
                            "type": "Easy Run",
                            "distance_km": 5,
                            "pace_guidance": "Easy pace (6:00/km)"
                        },
                        # ... more workouts
                    ]
                },
                # ... more weeks
            ]
        }
    }


@unified_router.get("/athlete/stats")
async def get_athlete_stats(user_id: str = Depends(get_current_user)):
    """
    Get comprehensive athlete statistics.
    
    Used by:
    - Flutter: Dashboard cards
    - HTML: Overview section
    """
    return {
        "totals": {
            "runs": 150,
            "distance_km": 1250.5,
            "time_hours": 105.2,
            "elevation_gain_m": 15480
        },
        "averages": {
            "pace_min_per_km": 5.1,
            "distance_per_run_km": 8.3,
            "runs_per_week": 4.2
        },
        "personal_bests": {
            "5k": "21:35",
            "10k": "45:20",
            "half_marathon": "1:42:15",
            "marathon": "3:35:42"
        },
        "recent_form": {
            "last_7_days": {
                "runs": 4,
                "distance_km": 32.5
            },
            "last_30_days": {
                "runs": 18,
                "distance_km": 145.2
            }
        }
    }


# ═══════════════════════════════════════════════════════════════════════
# Include Existing Routers
# ═══════════════════════════════════════════════════════════════════════

# Include AISRI calculator endpoints
unified_router.include_router(aisri_router, tags=["AISRI"])

# Include activity integration endpoints
unified_router.include_router(activity_router, tags=["Activities"])

# Include other API endpoints
unified_router.include_router(api_router, tags=["Legacy API"])


# ═══════════════════════════════════════════════════════════════════════
# API Documentation
# ═══════════════════════════════════════════════════════════════════════

"""
API Usage Examples:

## Flutter (Dart)
```dart
// Get AISRI scores
final response = await http.get(
  Uri.parse('https://api.akura.in/api/v2/athlete/aisri'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
final data = jsonDecode(response.body);
print('AISRI Score: ${data['current']['aisri_score']}');
```

## HTML (JavaScript)
```javascript
// Get athlete profile
fetch('https://api.akura.in/api/v2/athlete/profile', {
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('token')}`
  }
})
.then(res => res.json())
.then(data => {
  console.log('AISRI Score:', data.latest_aisri_score.score);
});
```

## cURL (Testing)
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.akura.in/api/v2/athlete/aisri
```
"""
