"""
Auto-AISRI Calculator Service
Automatically calculates AISRI scores from Strava/Garmin activity data.

Features:
- Analyzes activity history (past 4-8 weeks)
- Calculates 6 AISRI pillars from objective data
- Provides confidence score for reliability
- Scheduled weekly updates
- REST API for both Flutter app and HTML builder

Endpoints:
- POST /api/athlete/{user_id}/calculate-aisri-auto
- GET /api/athlete/{user_id}/aisri-scores (latest + history)
- POST /api/athlete/{user_id}/refresh-aisri (manual trigger)
"""

import os
import math
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass

from fastapi import APIRouter, HTTPException, BackgroundTasks
from database_integration import DatabaseIntegration


@dataclass
class AISRIAutoResult:
    """Auto-calculated AISRI result"""
    aisri_score: int
    risk_level: str
    confidence: int
    pillar_adaptability: int
    pillar_injury_risk: int
    pillar_fatigue: int
    pillar_recovery: int
    pillar_intensity: int
    pillar_consistency: int
    calculation_method: str
    activities_analyzed: int
    data_source: str
    notes: str
    calculated_at: datetime


router = APIRouter()
db = DatabaseIntegration()


class AISRIAutoCalculator:
    """
    Automatically calculate AISRI scores from activity data.
    
    Analysis includes:
    1. Training consistency (frequency, regularity)
    2. Volume progression (safe vs. risky ramp-up)
    3. Intensity distribution (hard/easy balance)
    4. Recovery patterns (rest days, consecutive efforts)
    5. Performance trends (fitness progression)
    """

    @staticmethod
    async def calculate_from_strava(
        user_id: str,
        strava_athlete_id: str
    ) -> AISRIAutoResult:
        """
        Calculate AISRI from Strava activities.
        
        Args:
            user_id: SafeStride user ID
            strava_athlete_id: Strava athlete ID
            
        Returns:
            AISRIAutoResult with scores and confidence
        """
        
        # Fetch athlete data
        athlete = await db.get_strava_athlete(strava_athlete_id)
        if not athlete:
            raise HTTPException(404, "Athlete not found")
        
        # Fetch recent activities (past 8 weeks for comprehensive analysis)
        activities = await db.get_athlete_activities(
            strava_athlete_id,
            start_date=datetime.now() - timedelta(weeks=8)
        )
        
        if len(activities) < 3:
            # Insufficient data for reliable auto-calculation
            return AISRIAutoResult(
                aisri_score=60,
                risk_level='Moderate',
                confidence=30,
                pillar_adaptability=60,
                pillar_injury_risk=70,
                pillar_fatigue=60,
                pillar_recovery=60,
                pillar_intensity=60,
                pillar_consistency=50,
                calculation_method='strava_auto_insufficient',
                activities_analyzed=len(activities),
                data_source='Strava',
                notes='Insufficient activity data. Complete full assessment for accurate scores.',
                calculated_at=datetime.now()
            )
        
        # Calculate each pillar
        adaptability = AISRIAutoCalculator._calculate_adaptability(
            athlete, activities
        )
        consistency = AISRIAutoCalculator._calculate_consistency(activities)
        intensity = AISRIAutoCalculator._calculate_intensity(activities)
        recovery = AISRIAutoCalculator._calculate_recovery(activities)
        fatigue = AISRIAutoCalculator._estimate_fatigue(activities)
        
        # Injury risk: neutral estimate (requires manual assessment)
        injury_risk = 70
        
        # Overall AISRI score
        aisri_score = round((
            adaptability +
            injury_risk +
            fatigue +
            recovery +
            intensity +
            consistency
        ) / 6)
        
        # Risk level
        if aisri_score >= 80:
            risk_level = 'Low'
        elif aisri_score >= 60:
            risk_level = 'Moderate'
        else:
            risk_level = 'High'
        
        # Confidence calculation
        confidence = AISRIAutoCalculator._calculate_confidence(
            athlete, activities
        )
        
        return AISRIAutoResult(
            aisri_score=aisri_score,
            risk_level=risk_level,
            confidence=confidence,
            pillar_adaptability=adaptability,
            pillar_injury_risk=injury_risk,
            pillar_fatigue=fatigue,
            pillar_recovery=recovery,
            pillar_intensity=intensity,
            pillar_consistency=consistency,
            calculation_method='strava_auto',
            activities_analyzed=len(activities),
            data_source='Strava',
            notes='Auto-calculated from Strava activities. Complete full assessment for comprehensive analysis.' if confidence >= 70 else 'Limited data. Complete full assessment for more accurate scores.',
            calculated_at=datetime.now()
        )
    
    @staticmethod
    def _calculate_adaptability(
        athlete: Dict,
        activities: List[Dict]
    ) -> int:
        """Calculate adaptability pillar from training history"""
        score = 50
        
        # Training age (years since Strava join)
        if athlete.get('created_at'):
            created = datetime.fromisoformat(athlete['created_at'])
            years_active = (datetime.now() - created).days / 365
            score += min(int(years_active * 3), 20)
        
        # Activity count bonus
        activity_count = len(activities)
        if activity_count >= 30:
            score += 20
        elif activity_count >= 15:
            score += 15
        elif activity_count >= 5:
            score += 10
        else:
            score += 5
        
        # Volume progression (safe ramp-up)
        if len(activities) >= 8:
            recent_weeks = activities[:len(activities)//2]
            older_weeks = activities[len(activities)//2:]
            
            recent_avg = sum(a['distance'] for a in recent_weeks) / len(recent_weeks)
            older_avg = sum(a['distance'] for a in older_weeks) / len(older_weeks)
            
            if recent_avg > older_avg * 1.1:
                score += 10  # Positive progression
        
        return min(max(score, 0), 100)
    
    @staticmethod
    def _calculate_consistency(activities: List[Dict]) -> int:
        """Calculate consistency pillar from training frequency"""
        score = 50
        
        # Count activities per week (past 4 weeks)
        now = datetime.now()
        week_counts = [0, 0, 0, 0]
        
        for activity in activities:
            start = datetime.fromisoformat(activity['start_date_local'])
            days_ago = (now - start).days
            
            if days_ago <= 7:
                week_counts[0] += 1
            elif days_ago <= 14:
                week_counts[1] += 1
            elif days_ago <= 21:
                week_counts[2] += 1
            elif days_ago <= 28:
                week_counts[3] += 1
        
        avg_weekly = sum(week_counts) / len(week_counts)
        
        # Frequency scoring
        if avg_weekly >= 6:
            score += 30
        elif avg_weekly >= 4:
            score += 25
        elif avg_weekly >= 3:
            score += 20
        elif avg_weekly >= 2:
            score += 10
        
        # Regularity bonus (low variance = consistent)
        variance = sum((c - avg_weekly) ** 2 for c in week_counts) / len(week_counts)
        std_dev = math.sqrt(variance)
        
        if std_dev < 1:
            score += 10
        elif std_dev < 2:
            score += 5
        
        return min(max(score, 0), 100)
    
    @staticmethod
    def _calculate_intensity(activities: List[Dict]) -> int:
        """Calculate intensity pillar from pace variability"""
        score = 60
        
        # Extract paces from activities
        paces = []
        for activity in activities:
            if activity.get('average_speed') and activity['average_speed'] > 0:
                if activity.get('distance', 0) > 1000:  # At least 1km
                    speed_mps = activity['average_speed']
                    pace_min_per_km = (1000 / 60) / speed_mps
                    paces.append(pace_min_per_km)
        
        if len(paces) >= 3:
            avg_pace = sum(paces) / len(paces)
            fastest = min(paces)
            slowest = max(paces)
            pace_range = slowest - fastest
            
            # Pace variety scoring
            if pace_range > 2.0:
                score += 20  # Excellent variety
            elif pace_range > 1.0:
                score += 15
            elif pace_range > 0.5:
                score += 10
            
            # Check for easy recovery runs
            if slowest > avg_pace * 1.3:
                score += 10
        
        # Recent quality sessions (suffer score > 100)
        recent_hard = any(
            a.get('suffer_score', 0) > 100
            for a in activities[:7]
        )
        if recent_hard:
            score += 10
        
        return min(max(score, 0), 100)
    
    @staticmethod
    def _calculate_recovery(activities: List[Dict]) -> int:
        """Calculate recovery pillar from rest patterns"""
        score = 60
        
        # Identify training days in past 14 days
        now = datetime.now()
        past_14_days = [False] * 14
        
        for activity in activities:
            start = datetime.fromisoformat(activity['start_date_local'])
            days_ago = (now - start).days
            
            if 0 <= days_ago < 14:
                past_14_days[days_ago] = True
        
        # Count rest days
        rest_days = sum(1 for has_activity in past_14_days if not has_activity)
        
        if rest_days >= 4:
            score += 20
        elif rest_days >= 2:
            score += 15
        elif rest_days >= 1:
            score += 10
        else:
            score -= 10  # No rest = overtraining risk
        
        # Check for excessive consecutive training
        max_consecutive = 0
        current_consecutive = 0
        
        for has_activity in past_14_days:
            if has_activity:
                current_consecutive += 1
                max_consecutive = max(max_consecutive, current_consecutive)
            else:
                current_consecutive = 0
        
        if max_consecutive > 10:
            score -= 20
        elif max_consecutive > 7:
            score -= 10
        elif max_consecutive <= 3:
            score += 10
        
        return min(max(score, 0), 100)
    
    @staticmethod
    def _estimate_fatigue(activities: List[Dict]) -> int:
        """Estimate fatigue from recent training load"""
        score = 70
        
        now = datetime.now()
        
        # Recent week distance
        recent_week_distance = sum(
            activity.get('distance', 0)
            for activity in activities
            if (now - datetime.fromisoformat(activity['start_date_local'])).days <= 7
        )
        
        # Average weekly distance (past 4 weeks)
        if len(activities) > 0:
            total_distance = sum(a.get('distance', 0) for a in activities[:28])
            avg_weekly_distance = total_distance / 4
            
            # Compare recent to average
            if recent_week_distance > avg_weekly_distance * 1.5:
                score -= 20  # Significant overload
            elif recent_week_distance > avg_weekly_distance * 1.2:
                score -= 10  # Moderate overload
            elif recent_week_distance < avg_weekly_distance * 0.7:
                score += 10  # Good taper/recovery
        
        return min(max(score, 0), 100)
    
    @staticmethod
    def _calculate_confidence(
        athlete: Dict,
        activities: List[Dict]
    ) -> int:
        """Calculate confidence in auto-generated score"""
        confidence = 50
        
        # Activity count
        if len(activities) >= 30:
            confidence += 30
        elif len(activities) >= 15:
            confidence += 20
        elif len(activities) >= 5:
            confidence += 10
        
        # Platform tenure
        if athlete.get('created_at'):
            created = datetime.fromisoformat(athlete['created_at'])
            years_active = (datetime.now() - created).days / 365
            
            if years_active >= 2:
                confidence += 10
            elif years_active >= 1:
                confidence += 5
        
        # Heart rate data availability
        has_hr = any(a.get('average_heartrate') for a in activities)
        if has_hr:
            confidence += 10
        
        return min(max(confidence, 0), 100)


# ═══════════════════════════════════════════════════════════════════════
# REST API Endpoints
# ═══════════════════════════════════════════════════════════════════════

@router.post("/api/athlete/{user_id}/calculate-aisri-auto")
async def calculate_aisri_auto(
    user_id: str,
    background_tasks: BackgroundTasks
):
    """
    Calculate AISRI scores automatically from activity data.
    
    This endpoint:
    1. Fetches athlete's Strava/Garmin activities
    2. Analyzes training patterns
    3. Calculates AISRI scores
    4. Saves to database
    5. Returns result
    """
    try:
        # Get athlete's Strava ID
        athlete = await db.get_user_athlete_connection(user_id)
        if not athlete or not athlete.get('strava_athlete_id'):
            raise HTTPException(404, "No Strava connection found")
        
        # Calculate scores
        result = await AISRIAutoCalculator.calculate_from_strava(
            user_id=user_id,
            strava_athlete_id=athlete['strava_athlete_id']
        )
        
        # Save to database
        await db.upsert_aisri_score(
            user_id=user_id,
            aisri_score=result.aisri_score,
            risk_level=result.risk_level,
            pillar_adaptability=result.pillar_adaptability,
            pillar_injury_risk=result.pillar_injury_risk,
            pillar_fatigue=result.pillar_fatigue,
            pillar_recovery=result.pillar_recovery,
            pillar_intensity=result.pillar_intensity,
            pillar_consistency=result.pillar_consistency,
            calculation_method=result.calculation_method,
            confidence=result.confidence,
            data_source=result.data_source,
            notes=result.notes
        )
        
        return {
            "success": True,
            "aisri_score": result.aisri_score,
            "risk_level": result.risk_level,
            "confidence": result.confidence,
            "pillars": {
                "adaptability": result.pillar_adaptability,
                "injury_risk": result.pillar_injury_risk,
                "fatigue": result.pillar_fatigue,
                "recovery": result.pillar_recovery,
                "intensity": result.pillar_intensity,
                "consistency": result.pillar_consistency,
            },
            "metadata": {
                "calculation_method": result.calculation_method,
                "activities_analyzed": result.activities_analyzed,
                "data_source": result.data_source,
                "notes": result.notes,
                "calculated_at": result.calculated_at.isoformat()
            }
        }
        
    except Exception as e:
        raise HTTPException(500, f"Error calculating AISRI: {str(e)}")


@router.get("/api/athlete/{user_id}/aisri-scores")
async def get_aisri_scores(user_id: str):
    """
    Get athlete's AISRI scores (latest + history).
    
    Returns:
    - current_score: Most recent AISRI score
    - history: Past scores for trend analysis
    """
    try:
        scores = await db.get_aisri_scores_history(user_id, limit=10)
        
        if not scores:
            return {
                "current_score": None,
                "history": [],
                "message": "No AISRI scores calculated yet. Connect Strava to auto-calculate."
            }
        
        return {
            "current_score": scores[0],
            "history": scores[1:],
            "total_assessments": len(scores)
        }
        
    except Exception as e:
        raise HTTPException(500, f"Error fetching AISRI scores: {str(e)}")


@router.post("/api/athlete/{user_id}/refresh-aisri")
async def refresh_aisri(user_id: str):
    """
    Manually trigger AISRI recalculation.
    
    Use this:
    - When athlete wants updated scores
    - After significant training changes
    - For on-demand analysis
    """
    return await calculate_aisri_auto(user_id, BackgroundTasks())
