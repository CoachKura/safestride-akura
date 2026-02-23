"""
AISRi Communication Agent - Supabase Handler
Manages athlete profiles and database operations
"""
import os
import logging
from typing import Optional, Dict, Any
from datetime import datetime
from supabase import create_client, Client

logger = logging.getLogger(__name__)


class SupabaseHandler:
    def __init__(self):
        self.url = os.getenv("SUPABASE_URL")
        self.key = os.getenv("SUPABASE_SERVICE_KEY")
        
        if not self.url or not self.key:
            raise ValueError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
        
        self.client: Client = create_client(self.url, self.key)
        logger.info("✅ Supabase client initialized")

    async def get_athlete_by_telegram(self, telegram_id: str) -> Optional[Dict[str, Any]]:
        """Find athlete by Telegram ID"""
        try:
            response = self.client.table("profiles").select("*").eq("telegram_id", telegram_id).execute()
            
            if response.data and len(response.data) > 0:
                logger.info(f"✅ Found athlete for Telegram ID: {telegram_id}")
                return response.data[0]
            
            logger.info(f"⚠️ No athlete found for Telegram ID: {telegram_id}")
            return None
        except Exception as e:
            logger.error(f"❌ Error fetching athlete by Telegram ID: {e}")
            return None

    async def get_athlete_by_whatsapp(self, whatsapp_number: str) -> Optional[Dict[str, Any]]:
        """Find athlete by WhatsApp number"""
        try:
            response = self.client.table("profiles").select("*").eq("whatsapp_number", whatsapp_number).execute()
            
            if response.data and len(response.data) > 0:
                logger.info(f"✅ Found athlete for WhatsApp: {whatsapp_number}")
                return response.data[0]
            
            logger.info(f"⚠️ No athlete found for WhatsApp: {whatsapp_number}")
            return None
        except Exception as e:
            logger.error(f"❌ Error fetching athlete by WhatsApp: {e}")
            return None

    async def create_athlete(
        self,
        telegram_id: Optional[str] = None,
        whatsapp_number: Optional[str] = None,
        first_name: Optional[str] = None,
        username: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Create new athlete profile"""
        try:
            athlete_data = {
                "created_at": datetime.utcnow().isoformat(),
                "telegram_id": telegram_id,
                "whatsapp_number": whatsapp_number,
                "first_name": first_name,
                "username": username,
                "aisri_score": 50,
                "injury_risk": "UNKNOWN",
                "training_status": "ACTIVE"
            }
            
            response = self.client.table("profiles").insert(athlete_data).execute()
            
            if response.data and len(response.data) > 0:
                logger.info(f"✅ Created new athlete: {response.data[0].get('id')}")
                return response.data[0]
            
            logger.error("❌ Failed to create athlete")
            return None
        except Exception as e:
            logger.error(f"❌ Error creating athlete: {e}")
            return None

    async def update_athlete_metrics(
        self,
        athlete_id: str,
        aisri_score: Optional[float] = None,
        injury_risk: Optional[str] = None,
        training_status: Optional[str] = None
    ) -> bool:
        """Update athlete metrics from AI analysis"""
        try:
            update_data = {"updated_at": datetime.utcnow().isoformat()}
            
            if aisri_score is not None:
                update_data["aisri_score"] = aisri_score
            if injury_risk:
                update_data["injury_risk"] = injury_risk
            if training_status:
                update_data["training_status"] = training_status
            
            response = self.client.table("profiles").update(update_data).eq("id", athlete_id).execute()
            
            if response.data:
                logger.info(f"✅ Updated athlete {athlete_id} metrics")
                return True
            
            return False
        except Exception as e:
            logger.error(f"❌ Error updating athlete metrics: {e}")
            return False

    async def get_all_telegram_athletes(self) -> list:
        """Get all athletes with Telegram IDs for daily messaging"""
        try:
            response = self.client.table("profiles").select("*").not_.is_("telegram_id", "null").execute()
            
            logger.info(f"✅ Retrieved {len(response.data)} Telegram athletes")
            return response.data
        except Exception as e:
            logger.error(f"❌ Error fetching Telegram athletes: {e}")
            return []

    async def get_all_whatsapp_athletes(self) -> list:
        """Get all athletes with WhatsApp numbers for daily messaging"""
        try:
            response = self.client.table("profiles").select("*").not_.is_("whatsapp_number", "null").execute()
            
            logger.info(f"✅ Retrieved {len(response.data)} WhatsApp athletes")
            return response.data
        except Exception as e:
            logger.error(f"❌ Error fetching WhatsApp athletes: {e}")
            return []

    async def log_interaction(
        self,
        athlete_id: str,
        platform: str,
        message_type: str,
        query: str,
        response: str
    ) -> bool:
        """Log communication interactions for analytics"""
        try:
            log_data = {
                "athlete_id": athlete_id,
                "platform": platform,
                "message_type": message_type,
                "query": query,
                "response": response,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            # Create interactions table if needed
            self.client.table("communication_logs").insert(log_data).execute()
            return True
        except Exception as e:
            logger.warning(f"⚠️ Failed to log interaction: {e}")
            return False
