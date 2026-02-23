"""
AISRi Communication Agent - API Handler
Handles all API calls to AISRi AI Engine
"""
import os
import logging
import httpx
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)


class AISRiAPIHandler:
    def __init__(self):
        self.base_url = os.getenv("AISRI_API_URL", "https://api.akura.in")
        self.timeout = 30.0
        logger.info(f"✅ AISRi API Handler initialized: {self.base_url}")

    async def call_autonomous_decision(self, athlete_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Call autonomous decision agent for training recommendations"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/agent/autonomous-decision",
                    json=athlete_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.info("✅ Autonomous decision agent responded")
                    return result
                else:
                    logger.error(f"❌ Autonomous decision failed: {response.status_code}")
                    return None
        except Exception as e:
            logger.error(f"❌ Error calling autonomous decision agent: {e}")
            return None

    async def predict_injury_risk(self, athlete_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Call injury risk prediction agent"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/agent/predict-injury-risk",
                    json=athlete_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.info("✅ Injury risk agent responded")
                    return result
                else:
                    logger.error(f"❌ Injury risk prediction failed: {response.status_code}")
                    return None
        except Exception as e:
            logger.error(f"❌ Error calling injury risk agent: {e}")
            return None

    async def generate_training_plan(self, athlete_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Call training plan generation agent"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/agent/generate-training-plan",
                    json=athlete_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.info("✅ Training plan agent responded")
                    return result
                else:
                    logger.error(f"❌ Training plan generation failed: {response.status_code}")
                    return None
        except Exception as e:
            logger.error(f"❌ Error calling training plan agent: {e}")
            return None

    async def predict_performance(self, athlete_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Call performance prediction agent"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/agent/predict-performance",
                    json=athlete_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.info("✅ Performance prediction agent responded")
                    return result
                else:
                    logger.error(f"❌ Performance prediction failed: {response.status_code}")
                    return None
        except Exception as e:
            logger.error(f"❌ Error calling performance prediction agent: {e}")
            return None

    async def route_query(self, query: str, athlete_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Intelligently route query to appropriate agent based on keywords"""
        query_lower = query.lower()
        
        # Injury-related keywords
        if any(keyword in query_lower for keyword in ["pain", "injury", "hurt", "sore", "ache", "strain"]):
            logger.info("🩺 Routing to injury risk agent")
            return await self.predict_injury_risk(athlete_data)
        
        # Performance-related keywords
        elif any(keyword in query_lower for keyword in ["performance", "predict", "race", "pace", "time", "pr", "pb"]):
            logger.info("📊 Routing to performance prediction agent")
            return await self.predict_performance(athlete_data)
        
        # Training plan keywords
        elif any(keyword in query_lower for keyword in ["plan", "schedule", "week", "training", "workout"]):
            logger.info("📅 Routing to training plan agent")
            return await self.generate_training_plan(athlete_data)
        
        # Default: autonomous decision
        else:
            logger.info("🤖 Routing to autonomous decision agent")
            return await self.call_autonomous_decision(athlete_data)

    def format_response(self, agent_response: Dict[str, Any], athlete_data: Dict[str, Any]) -> str:
        """Format agent response into user-friendly message"""
        try:
            aisri_score = agent_response.get("aisri_score", athlete_data.get("aisri_score", 50))
            injury_risk = agent_response.get("injury_risk", "UNKNOWN")
            training_status = agent_response.get("training_status", "UNKNOWN")
            recommendation = agent_response.get("recommendation", "Continue training as planned")
            
            message = f"""🏃 **AISRi Coach**

👤 Athlete Status: **{training_status}**

📊 AISRi Score: **{aisri_score}**
🩺 Injury Risk: **{injury_risk}**

💡 **Recommendation:**
{recommendation}

---
_Powered by AISRi AI Engine_
"""
            return message
        except Exception as e:
            logger.error(f"❌ Error formatting response: {e}")
            return "Sorry, I encountered an error processing your request. Please try again."
