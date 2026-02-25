"""
Self-Learning Integration for AISRi
Integrates ML-powered self-learning with existing communication and coaching systems

This module:
1. Automatically triggers analysis when athlete syncs data
2. Uses learned insights in bot responses
3. Schedules daily learning cycles
4. Provides athlete journey insights in conversations
"""

import logging
from typing import Dict, Optional
from ai_engine_agent.self_learning_engine import (
    SelfLearningEngine,
    AthleteJourneyAnalyzer
)
from supabase import create_client
from dotenv import load_dotenv
import os
import json

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
logger = logging.getLogger("AISRi.SelfLearningIntegration")


class AthleteDataSyncHandler:
    """
    Handles athlete data sync events
    Automatically triggers self-learning analysis
    """
    
    @staticmethod
    def on_strava_sync(athlete_id: str, sync_data: Dict):
        """
        Triggered when athlete syncs Strava data
        
        Args:
            athlete_id: Athlete's unique ID
            sync_data: Strava sync response data
        """
        logger.info(f"[DATA-SYNC] Strava sync detected for athlete {athlete_id}")
        
        try:
            # Trigger self-learning analysis
            journey_analysis = SelfLearningEngine.on_athlete_signup(athlete_id)
            
            # Generate personalized insights message
            insights_message = AthleteDataSyncHandler._format_journey_insights(journey_analysis)
            
            # Save insights for bot to use in future conversations
            supabase.table("athlete_insights").upsert({
                "athlete_id": athlete_id,
                "insights": json.dumps(journey_analysis),
                "summary_message": insights_message,
                "last_analyzed": journey_analysis.get("analyzed_at")
            }).execute()
            
            logger.info(f"[DATA-SYNC] Journey analysis complete for {athlete_id}")
            
            return {
                "status": "success",
                "message": insights_message,
                "analysis": journey_analysis
            }
            
        except Exception as e:
            logger.error(f"[DATA-SYNC] Error analyzing athlete {athlete_id}: {str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }
    
    @staticmethod
    def on_garmin_sync(athlete_id: str, sync_data: Dict):
        """Triggered when athlete syncs Garmin data"""
        return AthleteDataSyncHandler.on_strava_sync(athlete_id, sync_data)
    
    @staticmethod
    def on_manual_workout_log(athlete_id: str, workout_data: Dict):
        """Triggered when athlete manually logs a workout"""
        logger.info(f"[DATA-SYNC] Manual workout logged for athlete {athlete_id}")
        
        # Check if this is a milestone workout (e.g., 10th, 50th, 100th)
        workout_count = supabase.table("workouts") \
            .select("id", count="exact") \
            .eq("athlete_id", athlete_id) \
            .execute()
        
        count = workout_count.count if hasattr(workout_count, 'count') else len(workout_count.data)
        
        if count in [10, 25, 50, 100, 200, 500]:
            # Trigger full journey analysis on milestones
            return SelfLearningEngine.on_athlete_signup(athlete_id)
        
        return {"status": "acknowledged"}
    
    @staticmethod
    def _format_journey_insights(journey_analysis: Dict) -> str:
        """
        Format journey analysis into bot message
        """
        if journey_analysis.get("status") == "no_data":
            return ""
        
        insights = journey_analysis.get("insights", [])
        if not insights:
            return ""
        
        # Create personalized message based on insights
        message_parts = ["🎯 *Your Running Journey Analysis*\n"]
        
        for insight in insights[:3]:  # Top 3 insights
            emoji_map = {
                "IMPROVEMENT": "📈",
                "ACHIEVEMENT": "🏆",
                "STRENGTH": "💪",
                "CELEBRATION": "🎉",
                "WARNING": "⚠️"
            }
            emoji = emoji_map.get(insight["type"], "💡")
            message_parts.append(f"{emoji} {insight['message']}")
        
        # Add progression summary
        progression = journey_analysis.get("progression", {})
        improvement = progression.get("improvement_percent", {})
        
        if improvement.get("average_pace", 0) > 0:
            message_parts.append(f"\n📊 *Pace Improvement:* {improvement['average_pace']:.1f}%")
        
        if improvement.get("average_cadence", 0) > 0:
            message_parts.append(f"🦶 *Cadence Improvement:* {improvement['average_cadence']:.1f}%")
        
        # Add milestones
        milestones = journey_analysis.get("milestones", [])
        if milestones:
            message_parts.append(f"\n🏅 *Milestones Achieved:* {len(milestones)}")
        
        message_parts.append("\nKeep up the amazing work! 🚀")
        
        return "\n".join(message_parts)


class IntelligentResponseGenerator:
    """
    Uses learned insights to generate more personalized responses
    Integrates ML-powered knowledge into bot conversations
    """
    
    @staticmethod
    def get_personalized_context(athlete_id: str) -> Optional[Dict]:
        """
        Get athlete's learned insights for personalization
        
        Returns athlete journey analysis, patterns, and insights
        """
        try:
            insights = supabase.table("athlete_insights") \
                .select("*") \
                .eq("athlete_id", athlete_id) \
                .execute()
            
            if insights.data:
                return json.loads(insights.data[0]["insights"])
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching insights for {athlete_id}: {str(e)}")
            return None
    
    @staticmethod
    def enhance_performance_response(athlete_id: str, base_response: Dict) -> str:
        """
        Enhance performance prediction with learned insights
        """
        insights = IntelligentResponseGenerator.get_personalized_context(athlete_id)
        
        if not insights or base_response.get("status") != "success":
            # Return base response without enhancement
            predictions = base_response.get("predictions", {})
            vo2max = base_response.get("vo2max", "N/A")
            
            return f"""📈 *Performance Predictions*

*Current Fitness:*
• VO2max: {vo2max}

*Race Time Predictions:*
🏃 5K: {predictions.get('5K', 'N/A')}
🏃 10K: {predictions.get('10K', 'N/A')}
🏃 Half Marathon: {predictions.get('Half Marathon', 'N/A')}
🏃 Marathon: {predictions.get('Marathon', 'N/A')}

Keep training to improve these times! 🎯"""
        
        # Enhanced response with journey insights
        predictions = base_response.get("predictions", {})
        vo2max = base_response.get("vo2max", "N/A")
        
        progression = insights.get("progression", {})
        improvement = progression.get("improvement_percent", {})
        patterns = insights.get("patterns", {})
        
        response_parts = [
            "📈 *Your Personalized Performance Analysis*\n",
            "*Current Fitness:*",
            f"• VO2max: {vo2max}",
            f"• Training Style: {patterns.get('training_style', 'Balanced').replace('_', ' ').title()}",
            f"• Consistency: {patterns.get('consistency', 'Moderate').replace('_', ' ').title()}\n",
            "*Race Time Predictions:*",
            f"🏃 5K: {predictions.get('5K', 'N/A')}",
            f"🏃 10K: {predictions.get('10K', 'N/A')}",
            f"🏃 Half Marathon: {predictions.get('Half Marathon', 'N/A')}",
            f"🏃 Marathon: {predictions.get('Marathon', 'N/A')}\n"
        ]
        
        # Add personalized insights
        if improvement.get("average_pace", 0) > 5:
            response_parts.append(f"💪 *Your pace has improved {improvement['average_pace']:.1f}% since you started!*")
        
        if patterns.get("consistency") in ["VERY_HIGH", "HIGH"]:
            response_parts.append("🔥 *Your consistent training is paying off!*")
        
        response_parts.append("\nYour dedication is showing real results! Keep it up! 🎯")
        
        return "\n".join(response_parts)
    
    @staticmethod
    def enhance_training_plan_response(athlete_id: str, base_response: Dict) -> str:
        """
        Enhance training plan with athlete's journey context
        """
        insights = IntelligentResponseGenerator.get_personalized_context(athlete_id)
        
        if not insights:
            return base_response.get("plan", "Training plan generated!")
        
        patterns = insights.get("patterns", {})
        progression = insights.get("progression", {})
        
        # Customize plan based on athlete's history
        enhancement = f"""
💡 *Personalized for Your Journey*

Based on your training patterns:
• Your consistency level: {patterns.get('consistency', 'Moderate').replace('_', ' ').title()}
• Your style: {patterns.get('training_style', 'Balanced').replace('_', ' ').title()}
• Total workouts: {patterns.get('total_workouts', 0)}

This plan is optimized for your current fitness level and training history!
"""
        
        return base_response.get("plan", "") + "\n" + enhancement


class DailyLearningScheduler:
    """
    Schedules and manages daily self-learning cycles
    """
    
    @staticmethod
    def schedule_daily_learning():
        """
        Schedule daily learning cycle (to be called by APScheduler)
        """
        logger.info("[SCHEDULER] Starting daily self-learning cycle")
        
        try:
            result = SelfLearningEngine.daily_learning_cycle()
            
            logger.info(f"[SCHEDULER] Daily learning complete: {result}")
            
            return {
                "status": "success",
                "timestamp": result
            }
            
        except Exception as e:
            logger.error(f"[SCHEDULER] Daily learning failed: {str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }


# Export main handlers
__all__ = [
    "AthleteDataSyncHandler",
    "IntelligentResponseGenerator",
    "DailyLearningScheduler"
]
