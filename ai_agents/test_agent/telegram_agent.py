"""
AISRi AI Coach Telegram Bot - Production Ready
Provides intelligent coaching via Telegram with Supabase integration
"""

import requests
import os
import time
import logging
from dotenv import load_dotenv
from typing import Optional, Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Configuration
TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
AISRI_API_URL = os.getenv("AISRI_API_URL", "https://api.akura.in")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not TELEGRAM_TOKEN:
    raise ValueError("TELEGRAM_TOKEN environment variable is required")

BASE_URL = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"

# Supabase client initialization
supabase_client = None
if SUPABASE_URL and SUPABASE_SERVICE_KEY:
    try:
        from supabase import create_client
        supabase_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        logger.info("✅ Supabase client initialized")
    except Exception as e:
        logger.warning(f"⚠️ Supabase initialization failed: {e}")


def get_athlete_id(telegram_user_id: int) -> Optional[str]:
    """Get athlete_id from Supabase using telegram_user_id"""
    if not supabase_client:
        logger.warning("Supabase not available, using telegram_id as athlete_id")
        return str(telegram_user_id)
    
    try:
        # Try to find athlete by telegram_id (if column exists)
        response = supabase_client.table("profiles").select("id").eq("telegram_id", telegram_user_id).execute()
        if response.data and len(response.data) > 0:
            athlete_id = response.data[0]["id"]
            logger.info(f"✅ Found athlete_id: {athlete_id} for telegram_id: {telegram_user_id}")
            return athlete_id
        else:
            logger.warning(f"No athlete found for telegram_id: {telegram_user_id}, using telegram_id as fallback")
            return str(telegram_user_id)
    except Exception as e:
        # Graceful fallback if column doesn't exist or other error
        logger.warning(f"⚠️ Supabase lookup failed (using telegram_id as fallback): {e}")
        return str(telegram_user_id)


def send_message(chat_id: int, text: str, parse_mode: str = "Markdown") -> bool:
    """Send message to Telegram chat"""
    try:
        url = f"{BASE_URL}/sendMessage"
        payload = {
            "chat_id": chat_id,
            "text": text,
            "parse_mode": parse_mode
        }
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"❌ Error sending message: {e}")
        return False


def get_updates(offset: Optional[int] = None) -> Dict[str, Any]:
    """Get updates from Telegram"""
    try:
        url = f"{BASE_URL}/getUpdates"
        params = {"timeout": 30}
        if offset:
            params["offset"] = offset
        response = requests.get(url, params=params, timeout=35)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"❌ Error getting updates: {e}")
        return {"ok": False, "result": []}


def handle_start(chat_id: int, user_name: str) -> None:
    """Handle /start command"""
    message = f"""
🏃 *Welcome to AISRi AI Coach, {user_name}!*

I'm your intelligent running coach powered by AI. I analyze your training data, monitor your health, and provide personalized coaching decisions.

*What I can do:*
✅ Daily training recommendations
✅ Weekly training plans
✅ Performance predictions
✅ Injury risk assessment
✅ Personalized coaching advice

*Available Commands:*
/today - Get today's training recommendation
/week - View your weekly training plan
/stats - Check your performance predictions
/help - Show this help message

*Or just ask me anything!*
"Coach, how is my training today?"
"Should I rest or train?"
"What's my injury risk?"

Let's achieve your running goals together! 🎯
"""
    send_message(chat_id, message)


def handle_help(chat_id: int) -> None:
    """Handle /help command"""
    message = """
📚 *AISRi Coach Commands*

/start - Welcome message
/today - Today's training recommendation
/week - Weekly training plan
/stats - Performance predictions
/help - Show this help

*How to use:*
Simply send a command or ask me questions in natural language!

Examples:
• "How should I train today?"
• "Am I at risk of injury?"
• "What's my predicted 5K time?"

I'm here to help you train smarter! 💪
"""
    send_message(chat_id, message)


def handle_today(chat_id: int, athlete_id: str) -> None:
    """Handle /today command - autonomous decision"""
    try:
        logger.info(f"📊 Calling autonomous-decision for athlete: {athlete_id}")
        response = requests.post(
            f"{AISRI_API_URL}/agent/autonomous-decision",
            json={"athlete_id": athlete_id},
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        
        decision_data = data.get("decision", {})
        decision = decision_data.get("decision", "TRAIN")
        reason = decision_data.get("reason", "Training analysis completed")
        aisri_score = decision_data.get("aisri_score", "N/A")
        injury_risk = decision_data.get("injury_risk", "UNKNOWN")
        recommendation = decision_data.get("recommendation", "Follow your training plan")
        
        message = f"""
🤖 *AISRi Coach*

*Status:* {decision}
*AISRi Score:* {aisri_score}
*Injury Risk:* {injury_risk}

*Reason:*
{reason}

*Recommendation:*
{recommendation}

Train smart, stay healthy! 🏃‍♂️
"""
        send_message(chat_id, message)
        
    except requests.exceptions.Timeout:
        send_message(chat_id, "⏱️ Analysis timed out. Please try again.")
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ API Error: {e}")
        send_message(chat_id, "❌ Unable to reach AISRi API. Please try again later.")
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        send_message(chat_id, "❌ Something went wrong. Please try again.")


def handle_week(chat_id: int, athlete_id: str) -> None:
    """Handle /week command - training plan"""
    try:
        logger.info(f"📅 Calling generate-training-plan for athlete: {athlete_id}")
        response = requests.post(
            f"{AISRI_API_URL}/agent/generate-training-plan",
            json={"athlete_id": athlete_id, "weeks": 1},
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        
        plan = data.get("plan", {})
        summary = plan.get("summary", "No plan available")
        
        message = f"""
📅 *Weekly Training Plan*

{summary}

Stay consistent and trust the process! 💪
"""
        send_message(chat_id, message)
        
    except requests.exceptions.Timeout:
        send_message(chat_id, "⏱️ Planning timed out. Please try again.")
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ API Error: {e}")
        send_message(chat_id, "❌ Unable to generate plan. Please try again later.")
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        send_message(chat_id, "❌ Something went wrong. Please try again.")


def handle_stats(chat_id: int, athlete_id: str) -> None:
    """Handle /stats command - performance predictions"""
    try:
        logger.info(f"📈 Calling predict-performance for athlete: {athlete_id}")
        response = requests.post(
            f"{AISRI_API_URL}/agent/predict-performance",
            json={"athlete_id": athlete_id},
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        
        predictions = data.get("predictions", {})
        vo2max = predictions.get("vo2max", "N/A")
        pred_5k = predictions.get("5k_time", "N/A")
        pred_10k = predictions.get("10k_time", "N/A")
        pred_hm = predictions.get("half_marathon_time", "N/A")
        
        message = f"""
📈 *Performance Predictions*

*Current Fitness:*
VO2max: {vo2max}

*Race Predictions:*
🏃 5K: {pred_5k}
🏃 10K: {pred_10k}
🏃 Half Marathon: {pred_hm}

Keep training to improve these times! 🎯
"""
        send_message(chat_id, message)
        
    except requests.exceptions.Timeout:
        send_message(chat_id, "⏱️ Analysis timed out. Please try again.")
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ API Error: {e}")
        send_message(chat_id, "❌ Unable to predict performance. Please try again later.")
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        send_message(chat_id, "❌ Something went wrong. Please try again.")


def handle_free_text(chat_id: int, athlete_id: str, text: str) -> None:
    """Handle free-text messages with intelligent routing"""
    text_lower = text.lower()
    
    # Detect intent from message
    if any(word in text_lower for word in ["pain", "injury", "hurt", "sore", "ache"]):
        # Route to injury prediction
        try:
            logger.info(f"🏥 Calling injury prediction for athlete: {athlete_id}")
            response = requests.post(
                f"{AISRI_API_URL}/agent/predict-injury",
                json={"athlete_id": athlete_id},
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            risk = data.get("risk", {})
            risk_level = risk.get("level", "UNKNOWN")
            risk_reason = risk.get("reason", "Analysis completed")
            
            message = f"""
🏥 *AISRi Injury Analysis*

*Risk Level:* {risk_level}

*Assessment:*
{risk_reason}

*Recommendation:*
Listen to your body and train smart.

Stay healthy! 🩺
"""
            send_message(chat_id, message)
            
        except Exception as e:
            logger.error(f"❌ Injury prediction error: {e}")
            send_message(chat_id, "❌ Unable to assess injury risk. Please try /today for training guidance.")
    
    elif any(word in text_lower for word in ["performance", "predict", "race", "time", "vo2"]):
        # Route to performance prediction
        handle_stats(chat_id, athlete_id)
    
    else:
        # Default to autonomous decision
        handle_today(chat_id, athlete_id)


def handle_message(chat_id: int, message_text: str, user_id: int, user_name: str) -> None:
    """Main message handler with command routing"""
    try:
        # Get athlete_id from Supabase
        athlete_id = get_athlete_id(user_id)
        
        # Route based on command or free text
        if message_text.startswith("/"):
            command = message_text.split()[0].lower()
            
            if command == "/start":
                handle_start(chat_id, user_name)
            elif command == "/help":
                handle_help(chat_id)
            elif command == "/today":
                handle_today(chat_id, athlete_id)
            elif command == "/week":
                handle_week(chat_id, athlete_id)
            elif command == "/stats":
                handle_stats(chat_id, athlete_id)
            else:
                send_message(chat_id, "Unknown command. Use /help to see available commands.")
        else:
            # Handle free-text with intelligent routing
            handle_free_text(chat_id, athlete_id, message_text)
            
    except Exception as e:
        logger.error(f"❌ Error handling message: {e}")
        send_message(chat_id, "❌ Something went wrong. Please try again or use /help.")


def run_bot() -> None:
    """Main bot loop with production-safe error handling"""
    logger.info("🤖 AISRi Telegram Bot started")
    logger.info(f"📡 API URL: {AISRI_API_URL}")
    
    last_update_id = None
    error_count = 0
    max_errors = 5
    
    while True:
        try:
            # Get updates with timeout
            updates = get_updates(last_update_id)
            
            if not updates.get("ok"):
                logger.warning("⚠️ Failed to get updates")
                time.sleep(5)
                continue
            
            # Reset error count on successful request
            error_count = 0
            
            # Process each update
            for update in updates.get("result", []):
                update_id = update["update_id"]
                
                # Update offset for next request
                last_update_id = update_id + 1
                
                # Extract message
                message = update.get("message")
                if not message:
                    continue
                
                chat_id = message["chat"]["id"]
                text = message.get("text", "")
                user_id = message["from"]["id"]
                user_name = message["from"].get("first_name", "Runner")
                
                logger.info(f"📨 Message from {user_name} ({user_id}): {text}")
                
                # Handle message
                handle_message(chat_id, text, user_id, user_name)
            
            # Small delay between polling cycles
            time.sleep(1)
            
        except KeyboardInterrupt:
            logger.info("🛑 Bot stopped by user")
            break
            
        except Exception as e:
            error_count += 1
            logger.error(f"❌ Bot error ({error_count}/{max_errors}): {e}")
            
            if error_count >= max_errors:
                logger.critical("💥 Too many errors, stopping bot")
                break
            
            # Exponential backoff
            time.sleep(min(2 ** error_count, 60))


if __name__ == "__main__":
    try:
        run_bot()
    except Exception as e:
        logger.critical(f"💥 Fatal error: {e}")
        raise