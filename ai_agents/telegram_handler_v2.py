"""
Telegram Handler V2
Async Telegram Bot API interface
"""

import os
import httpx

TELEGRAM_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")

class TelegramHandler:
    """Handle Telegram Bot API operations"""

    @staticmethod
    async def send(chat_id, text):
        """
        Send message to Telegram chat
        
        Args:
            chat_id: Telegram chat ID
            text: Message text to send
        """
        if not TELEGRAM_TOKEN:
            print("⚠️ TELEGRAM_BOT_TOKEN not set")
            return
            
        url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                await client.post(url, json={
                    "chat_id": chat_id,
                    "text": text
                })
        except Exception as e:
            print(f"Error sending Telegram message: {e}")

    @staticmethod
    def extract(update):
        """
        Extract message data from Telegram update
        
        Args:
            update: Telegram webhook update dict
            
        Returns:
            dict: Extracted message data or None
        """
        try:
            msg = update["message"]
            return {
                "chat_id": msg["chat"]["id"],
                "telegram_id": msg["from"]["id"],
                "text": msg["text"],
                "username": msg["from"].get("username", "unknown")
            }
        except Exception as e:
            print(f"Error extracting Telegram message: {e}")
            return None
