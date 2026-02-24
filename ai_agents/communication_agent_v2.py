"""
AISRi Communication Agent V2
Production-grade AI coaching communication infrastructure

Features:
- Async HTTP with retry logic
- Intelligent keyword routing
- Conversation memory (last 5 messages)
- Structured logging
- APScheduler automation
- Health + metrics endpoints
- Scale Target: B (1,000-5,000 athletes)
"""

import os
import logging
from datetime import datetime
from fastapi import FastAPI, Request
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from aisri_api_handler_v2 import AISRiAPI
from supabase_handler_v2 import SupabaseHandler
from telegram_handler_v2 import TelegramHandler

# ===============================
# APP INITIALIZATION
# ===============================

app = FastAPI(
    title="AISRi Communication Agent V2",
    description="Production-grade AI coaching communication infrastructure",
    version="2.0.0"
)

scheduler = AsyncIOScheduler()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("logs/aisri_communication.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("AISRi.CommunicationAgent")

# ===============================
# INTELLIGENT MESSAGE ROUTER
# ===============================

def classify_message(text: str):
    """
    Classify incoming message to route to appropriate endpoint
    
    Args:
        text: User message text
        
    Returns:
        str: Endpoint type (injury/performance/training/autonomous)
    """
    text = text.lower()

    # Injury/pain keywords
    if any(k in text for k in ["pain", "sore", "injury", "hurt", "ache", "strain"]):
        return "injury"

    # Performance/race keywords
    if any(k in text for k in ["race", "pace", "performance", "pr", "personal best", "time"]):
        return "performance"

    # Training plan keywords
    if any(k in text for k in ["plan", "workout", "schedule", "training", "program"]):
        return "training"

    # Default to autonomous
    return "autonomous"

# ===============================
# TELEGRAM WEBHOOK
# ===============================

@app.post("/telegram/webhook")
async def telegram_webhook(request: Request):
    """
    Handle incoming Telegram messages
    
    Process:
    1. Extract message data
    2. Validate athlete registration
    3. Classify message intent
    4. Route to appropriate AI endpoint
    5. Save conversation for memory
    6. Send response
    """
    
    try:
        update = await request.json()
        message = TelegramHandler.extract(update)

        if not message:
            logger.warning("Invalid Telegram update received")
            return {"status": "ignored"}

        logger.info(f"Message from Telegram ID {message['telegram_id']}: {message['text'][:50]}...")

        # Validate athlete registration
        athlete = SupabaseHandler.get_athlete_by_telegram(message["telegram_id"])

        if not athlete:
            await TelegramHandler.send(
                message["chat_id"],
                "⚠️ You are not registered in AISRi. Please register first at https://akura.in"
            )
            logger.warning(f"Unregistered Telegram user: {message['telegram_id']}")
            return {"status": "not_registered"}

        # Classify message and route to appropriate endpoint
        route = classify_message(message["text"])
        logger.info(f"Athlete {athlete['id']} → Route: {route}")

        # Prepare payload with conversation context
        payload = {
            "athlete_id": athlete["id"],
            "query": message["text"],
            "context": SupabaseHandler.get_last_messages(athlete["id"])
        }

        # Route to appropriate endpoint
        if route == "injury":
            ai_response = await AISRiAPI.injury(payload)
        elif route == "performance":
            ai_response = await AISRiAPI.performance(payload)
        elif route == "training":
            ai_response = await AISRiAPI.training(payload)
        else:
            ai_response = await AISRiAPI.autonomous(payload)

        # Extract response text
        response_text = ai_response.get("recommendation") or \
                       ai_response.get("response") or \
                       ai_response.get("plan") or \
                       "⚠️ Error processing your request. Please try again."

        if "error" in ai_response:
            response_text = "⚠️ AISRi engine is temporarily unavailable. Please try again in a moment."
            logger.error(f"API error for athlete {athlete['id']}: {ai_response['error']}")

        # Save conversation for memory
        SupabaseHandler.save_conversation(
            athlete["id"],
            message["text"],
            response_text
        )

        # Send response
        await TelegramHandler.send(message["chat_id"], response_text)

        logger.info(f"Response sent to athlete {athlete['id']} via {route} endpoint")

        return {"status": "ok", "route": route}

    except Exception as e:
        logger.error(f"Webhook error: {str(e)}", exc_info=True)
        return {"status": "error", "message": str(e)}

# ===============================
# HEALTH & METRICS
# ===============================

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "AISRi Communication Agent V2",
        "version": "2.0.0",
        "status": "running",
        "scale_target": "B (1,000-5,000 athletes)"
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "AISRi Communication Agent V2",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/metrics")
async def metrics():
    """Metrics endpoint for monitoring"""
    return {
        "system": "AISRi Communication V2",
        "scale_target": "B",
        "capacity": "1000-5000 athletes",
        "features": [
            "async_http",
            "intelligent_routing",
            "conversation_memory",
            "retry_logic",
            "structured_logging"
        ]
    }

# ===============================
# DAILY AUTOMATION
# ===============================

async def daily_workout_automation():
    """
    Daily automation job - sends workout recommendations
    Runs at 6 AM UTC
    """
    logger.info("Daily workout automation triggered")
    # TODO: Implement athlete notification logic
    # - Query active athletes
    # - Generate personalized workouts
    # - Send via Telegram

async def daily_recovery_check():
    """
    Daily recovery check - analyzes recovery metrics
    Runs at 8 PM UTC
    """
    logger.info("Daily recovery check triggered")
    # TODO: Implement recovery analysis
    # - Check athlete recovery scores
    # - Send alerts for overtraining

# Schedule jobs
scheduler.add_job(daily_workout_automation, "cron", hour=6, minute=0)
scheduler.add_job(daily_recovery_check, "cron", hour=20, minute=0)

# ===============================
# STARTUP / SHUTDOWN
# ===============================

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    scheduler.start()
    logger.info("🚀 AISRi Communication Agent V2 started")
    logger.info("✅ APScheduler initialized")
    logger.info("✅ Telegram webhook ready at /telegram/webhook")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    scheduler.shutdown()
    logger.info("👋 AISRi Communication Agent V2 stopped")
