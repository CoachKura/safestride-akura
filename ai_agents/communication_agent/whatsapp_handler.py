"""
AISRi Communication Agent - WhatsApp Handler
Handles WhatsApp Cloud API webhook and message processing
"""
import os
import logging
import httpx
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)


class WhatsAppHandler:
    def __init__(self, supabase_handler, api_handler):
        self.verify_token = os.getenv("WHATSAPP_VERIFY_TOKEN")
        self.access_token = os.getenv("WHATSAPP_ACCESS_TOKEN")
        self.phone_number_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID")
        
        if not all([self.verify_token, self.access_token, self.phone_number_id]):
            logger.warning("⚠️ WhatsApp credentials not fully configured")
        
        self.supabase = supabase_handler
        self.api_handler = api_handler
        self.api_url = f"https://graph.facebook.com/v17.0/{self.phone_number_id}/messages"
        
        logger.info("✅ WhatsApp Handler initialized")

    def verify_webhook(self, mode: str, token: str, challenge: str) -> Optional[str]:
        """Verify WhatsApp webhook during setup"""
        if mode == "subscribe" and token == self.verify_token:
            logger.info("✅ WhatsApp webhook verified")
            return challenge
        else:
            logger.error("❌ WhatsApp webhook verification failed")
            return None

    async def process_webhook(self, payload: Dict[str, Any]) -> bool:
        """Process incoming WhatsApp webhook"""
        try:
            # Extract message from webhook payload
            entry = payload.get("entry", [])
            if not entry:
                return False
            
            changes = entry[0].get("changes", [])
            if not changes:
                return False
            
            value = changes[0].get("value", {})
            messages = value.get("messages", [])
            
            if not messages:
                return False
            
            # Process first message
            message = messages[0]
            from_number = message.get("from")
            message_type = message.get("type")
            
            if message_type == "text":
                text = message.get("text", {}).get("body", "")
                await self.handle_text_message(from_number, text)
            
            logger.info(f"✅ Processed WhatsApp message from {from_number}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error processing WhatsApp webhook: {e}")
            return False

    async def handle_text_message(self, from_number: str, text: str):
        """Handle incoming text message"""
        try:
            # Get or create athlete
            athlete = await self.supabase.get_athlete_by_whatsapp(from_number)
            
            if not athlete:
                athlete = await self.supabase.create_athlete(
                    whatsapp_number=from_number
                )
                
                # Send welcome message
                welcome = f"""👋 Welcome to AISRi Coach!

I'm your AI-powered running coach. I can help you with:

🏃 Training recommendations
🩺 Injury risk assessment
📊 Performance predictions
📅 Weekly training plans

Just message me naturally about your training, pain, or performance!
"""
                await self.send_message(from_number, welcome)
            
            # Route query to appropriate agent
            response = await self.api_handler.route_query(text, athlete)
            
            if response:
                # Update athlete metrics
                await self.supabase.update_athlete_metrics(
                    athlete["id"],
                    aisri_score=response.get("aisri_score"),
                    injury_risk=response.get("injury_risk"),
                    training_status=response.get("training_status")
                )
                
                # Format and send response
                formatted_message = self.api_handler.format_response(response, athlete)
                await self.send_message(from_number, formatted_message)
                
                # Log interaction
                await self.supabase.log_interaction(
                    athlete["id"],
                    "whatsapp",
                    "text",
                    text,
                    formatted_message
                )
            else:
                await self.send_message(
                    from_number,
                    "Sorry, I couldn't process your request. Please try again."
                )
            
        except Exception as e:
            logger.error(f"❌ Error handling WhatsApp message: {e}")

    async def send_message(self, to_number: str, message: str) -> bool:
        """Send message via WhatsApp Cloud API"""
        try:
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "messaging_product": "whatsapp",
                "to": to_number,
                "type": "text",
                "text": {"body": message}
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self.api_url,
                    headers=headers,
                    json=payload
                )
                
                if response.status_code == 200:
                    logger.info(f"✅ Sent WhatsApp message to {to_number}")
                    return True
                else:
                    logger.error(f"❌ Failed to send WhatsApp message: {response.status_code}")
                    return False
                    
        except Exception as e:
            logger.error(f"❌ Error sending WhatsApp message: {e}")
            return False

    async def send_daily_message(self, whatsapp_number: str, message: str) -> bool:
        """Send daily automated message to athlete"""
        return await self.send_message(whatsapp_number, message)

    async def send_template_message(self, to_number: str, template_name: str, language: str = "en") -> bool:
        """Send WhatsApp template message (for bulk/scheduled messages)"""
        try:
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "messaging_product": "whatsapp",
                "to": to_number,
                "type": "template",
                "template": {
                    "name": template_name,
                    "language": {"code": language}
                }
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self.api_url,
                    headers=headers,
                    json=payload
                )
                
                if response.status_code == 200:
                    logger.info(f"✅ Sent WhatsApp template to {to_number}")
                    return True
                else:
                    logger.error(f"❌ Failed to send template: {response.status_code}")
                    return False
                    
        except Exception as e:
            logger.error(f"❌ Error sending WhatsApp template: {e}")
            return False
