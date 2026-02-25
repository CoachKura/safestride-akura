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
    version="2.0.1"
)

scheduler = AsyncIOScheduler()

# Configure logging (production-safe)
handlers = [logging.StreamHandler()]
log_dir = "logs"
if os.path.exists(log_dir) or os.makedirs(log_dir, exist_ok=True) is None:
    try:
        handlers.append(logging.FileHandler(f"{log_dir}/aisri_communication.log"))
    except:
        pass  # Fall back to console-only logging in production

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=handlers
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
        str: Endpoint type (faq/injury/performance/training/autonomous)
    """
    text = text.lower()

    # FAQ/General questions - handle these with custom responses
    if any(k in text for k in ["what is aisri", "aisri mean", "abbreviation", "acronym", "stand for", 
                                 "what does aisri", "explain aisri", "tell me about", "help", 
                                "how do i", "getting started", "get started"]):
        return "faq"

    # Injury/pain keywords
    if any(k in text for k in ["pain", "sore", "injury", "hurt", "ache", "strain"]):
        return "injury"

    # Performance/race keywords
    if any(k in text for k in ["race", "pace", "performance", "pr", "personal best", "time", "predict", "10k", "5k", "marathon", "half marathon"]):
        return "performance"

    # Training plan keywords
    if any(k in text for k in ["plan", "workout", "schedule", "training", "program"]):
        return "training"

    # Default to autonomous
    return "autonomous"


def handle_faq(text: str):
    """
    Handle frequently asked questions with coach-like responses
    
    Args:
        text: User message text
        
    Returns:
        str: Formatted response with helpful information
    """
    text = text.lower()

    # AISRI explanation
    if any(k in text for k in ["what is aisri", "aisri mean", "abbreviation", "acronym", "stand for", "what does aisri", "explain aisri"]):
        return """🤖 *Welcome to AISRi!*

*AISRi* stands for *Artificial Intelligence System for Running Intelligence* - your personal AI running coach!

*What I do:*
📊 Analyze your running biomechanics
🏃 Predict race times and performance
🩺 Monitor injury risk
📅 Create personalized training plans
💬 Provide daily coaching guidance

Think of me as your 24/7 running coach who uses AI to understand your body, track your progress, and help you achieve your goals safely!

*Ready to get started?* Try asking:
• "What pace for my 10K race?"
• "Am I at risk for injury?"
• "Create me a training plan"
• "Should I train today?"

Let's crush those running goals together! 💪🏃‍♂️"""

    # Getting started / help
    elif any(k in text for k in ["help", "getting started", "get started", "how do i"]):
        return """👋 *Let's Get You Started!*

Here's your quick start guide:

*1️⃣ Connect Your Data:*
• Link Strava or Garmin account
• Sync your running watch
• Or manually log workouts

*2️⃣ Complete AISRi Assessment (~5 min):*
• Measure your flexibility & ROM
• Assess current fitness level
• Identify injury risk factors

*3️⃣ Start Training:*
• Get race predictions
• Receive personalized training plans
• Track injury risk daily
• Get coaching advice anytime

*What I Can Help With:*
🏃 Race time predictions
📅 Training plans
🩺 Injury risk monitoring
💬 Daily coaching questions
📊 Performance analysis

*Try asking me:*
• "What is my 10K pace?"
• "Create a training plan for me"
• "Should I run today?"
• "Am I at risk for injury?"

Ready to start? Just ask me anything! 🎯"""

    # Default general response for other questions
    else:
        return """👋 *Hey there!*

I'm your AISRi running coach, and I'm here to help you train smarter and run safer!

*I can help you with:*
🏃 Race predictions & pace guidance
📅 Personalized training plans
🩺 Injury risk assessment
💬 Daily training decisions
📊 Performance analysis

*Popular questions:*
• "What pace for my 10K race?"
• "Create me a training plan"
• "Should I train today?"
• "Am I at risk for injury?"
• "What is AISRi?" (learn more about me!)

What would you like to know? 😊"""

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

        # Handle FAQ questions directly without API call
        if route == "faq":
            response_text = handle_faq(message["text"])
            ai_response = {}  # Empty response since we're not calling API

        else:
            # Prepare payload (AI Engine expects only athlete_id as string)
            payload = {
                "athlete_id": str(athlete["id"])
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

        # Check for API errors first (skip for FAQ since we handled it already)
        if route == "faq":
            # response_text already set by handle_faq()
            pass
        elif "error" in ai_response:
            response_text = "⚠️ AISRi engine is temporarily unavailable. Please try again in a moment."
            logger.error(f"API error for athlete {athlete['id']}: {ai_response['error']}")

        # Extract and format response based on route type
        elif route == "performance":
            # Format performance prediction response
            if ai_response.get("status") == "success":
                predictions = ai_response.get("predictions", {})
                vo2max = ai_response.get("vo2max", "N/A")
                aisri_score = ai_response.get("aisri_score", "N/A")
                
                response_text = f"""📈 *Performance Predictions*

*Current Fitness:*
• VO2max: {vo2max}
• AISRi Score: {aisri_score}

*Race Time Predictions:*
🏃 5K: {predictions.get('5K', 'N/A')}
🏃 10K: {predictions.get('10K', 'N/A')}
🏃 Half Marathon: {predictions.get('Half Marathon', 'N/A')}
🏃 Marathon: {predictions.get('Marathon', 'N/A')}

Keep training to improve these times! 🎯"""
            else:
                # Coach-like response for missing data
                error_msg = ai_response.get("message", "")
                if "workout" in error_msg.lower() or "pace" in error_msg.lower():
                    response_text = """🏃‍♂️ *Hey there!*

I don't see any workout data yet. To give you accurate race predictions, I need to see some of your runs first!

*Here's how to get started:*
📱 Connect your Strava or Garmin account
⌚ Sync your running watch
📝 Or manually log a workout

Once you have at least a few runs recorded, I'll be able to predict your race times accurately!

Need help connecting your devices? Just ask! 💪"""
                else:
                    response_text = f"""⚠️ *Hmm, something's not quite right*

I'm having trouble analyzing your performance right now. This usually means:
• You might not have enough workout data yet
• Your account might need to be set up

Try connecting your Strava or Garmin account, or ask me "how do I get started?" for help!"""

        elif route == "injury":
            # Format injury risk response
            risk_level = ai_response.get("risk_level", "UNKNOWN")
            risk_score = ai_response.get("risk_score", 0)
            recommendation = ai_response.get("recommendation", "Continue training carefully")
            
            response_text = f"""🏥 *Injury Risk Analysis*

*Risk Level:* {risk_level}
*Risk Score:* {risk_score}/100

*Recommendation:*
{recommendation}

Listen to your body and train smart! 🩺"""

        elif route == "training":
            # Format training plan response
            if ai_response.get("status") == "success":
                response_text = ai_response.get("plan") or ai_response.get("response") or \
                       "Your training plan is ready! Check your schedule."
            else:
                # Coach-like response for missing AISRi score
                error_msg = ai_response.get("message", "")
                if "aisri" in error_msg.lower() or "score" in error_msg.lower():
                    response_text = """💪 *Let's Build Your Training Plan!*

To create a personalized training plan, I first need to assess your current fitness and injury risk. 

*Quick Start:*
1️⃣ Complete your AISRi assessment (takes ~5 minutes)
2️⃣ Log a few workouts so I can understand your baseline
3️⃣ Then I'll create a custom plan just for you!

Want me to guide you through the assessment? Just say "start assessment" or ask me any questions about getting started!

Remember: Good training starts with good data! 📊"""
                else:
                    response_text = """🏃‍♂️ *Training Plan Builder*

I'd love to help you create a training plan! To build something perfect for you, I need:

✅ Your current fitness level (from workouts or assessment)
✅ Any injury concerns or limitations
✅ Your training goals

Have you completed your AISRi assessment yet? That's the best way to get started!

Type "help" if you need guidance on getting set up! 🎯"""

        else:  # autonomous
            # Format autonomous decision response
            decision_data = ai_response.get("decision", {})
            decision = decision_data.get("decision", "TRAIN")
            reason = decision_data.get("reason", "Training analysis completed")
            recommendation = decision_data.get("recommendation", "Follow your training plan")
            aisri_score = ai_response.get("aisri_score", "N/A")
            injury_risk = ai_response.get("injury_risk", "UNKNOWN")
            
            response_text = f"""🤖 *AISRi Coach*

*Status:* {decision}
*AISRi Score:* {aisri_score}
*Injury Risk:* {injury_risk}

*Reason:*
{reason}

*Recommendation:*
{recommendation}

Train smart, stay healthy! 🏃‍♂️"""

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
    logger.info("[STARTUP] AISRi Communication Agent V2 started")
    logger.info("[STARTUP] APScheduler initialized")
    logger.info("[STARTUP] Telegram webhook ready at /telegram/webhook")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    scheduler.shutdown()
    logger.info("[SHUTDOWN] AISRi Communication Agent V2 stopped")

# ===============================
# PRODUCTION DIRECT RUN
# ===============================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "communication_agent_v2:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 10000)),
        reload=False
    )
