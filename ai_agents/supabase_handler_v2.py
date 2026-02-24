"""
Supabase Handler V2
Memory and database operations for AISRi Communication Agent
"""

import os
from supabase import create_client

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Initialize Supabase client
supabase = None
if SUPABASE_URL and SUPABASE_SERVICE_KEY:
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    except Exception as e:
        print(f"⚠️ Supabase initialization failed: {e}")

class SupabaseHandler:
    """Handle Supabase operations for athlete data and conversation memory"""

    @staticmethod
    def get_athlete_by_telegram(telegram_id):
        """
        Retrieve athlete record by Telegram ID
        
        Args:
            telegram_id: Telegram user ID
            
        Returns:
            dict: Athlete record or None
        """
        if not supabase:
            return None
            
        try:
            res = supabase.table("athletes").select("*") \
                .eq("telegram_id", telegram_id).execute()
            return res.data[0] if res.data else None
        except Exception as e:
            print(f"Error fetching athlete: {e}")
            return None

    @staticmethod
    def save_conversation(athlete_id, message, response):
        """
        Save conversation to database for memory
        
        Args:
            athlete_id: Athlete UUID
            message: User message text
            response: AI response text
        """
        if not supabase:
            return
            
        try:
            supabase.table("conversation_logs").insert({
                "athlete_id": athlete_id,
                "message": message,
                "response": response
            }).execute()
        except Exception as e:
            print(f"Error saving conversation: {e}")

    @staticmethod
    def get_last_messages(athlete_id, limit=5):
        """
        Get recent conversation history for context
        
        Args:
            athlete_id: Athlete UUID
            limit: Number of recent messages (default 5)
            
        Returns:
            list: Recent conversation records
        """
        if not supabase:
            return []
            
        try:
            res = supabase.table("conversation_logs") \
                .select("*") \
                .eq("athlete_id", athlete_id) \
                .order("created_at", desc=True) \
                .limit(limit).execute()
            return res.data if res.data else []
        except Exception as e:
            print(f"Error fetching messages: {e}")
            return []
