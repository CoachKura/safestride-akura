"""
AISRi Communication Agent - Main Server
Production-ready FastAPI server integrating Telegram & WhatsApp
with AISRi AI Engine and Supabase backend
"""
import os
import logging
import asyncio
from datetime import datetime, time
from contextlib import asynccontextmanager
from typing import Dict, Any

from fastapi import FastAPI, Request, HTTPException, Query
from fastapi.responses import PlainTextResponse, JSONResponse
from dotenv import load_dotenv
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from supabase_handler import SupabaseHandler
from aisri_api_handler import AISRiAPIHandler
from telegram_handler import TelegramHandler
from whatsapp_handler import WhatsAppHandler

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global handlers
supabase_handler = None
api_handler = None
telegram_handler = None
whatsapp_handler = None
scheduler = None


async def send_daily_recommendations():
    """Send daily workout recommendations to all athletes"""
    logger.info("🌅 Starting daily recommendation cycle...")
    
    try:
        # Get all Telegram athletes
        telegram_athletes = await supabase_handler.get_all_telegram_athletes()
        logger.info(f"📱 Found {len(telegram_athletes)} Telegram athletes")
        
        for athlete in telegram_athletes:
            try:
                # Get daily recommendation
                response = await api_handler.call_autonomous_decision(athlete)
                
                if response:
                    # Update metrics
                    await supabase_handler.update_athlete_metrics(
                        athlete["id"],
                        aisri_score=response.get("aisri_score"),
                        injury_risk=response.get("injury_risk"),
                        training_status=response.get("training_status")
                    )
                    
                    # Format and send message
                    message = f"""🌅 **Good Morning from AISRi Coach!**

Here's your daily training recommendation:

{api_handler.format_response(response, athlete)}

Have a great workout! 💪
"""
                    await telegram_handler.send_daily_message(
                        athlete["telegram_id"],
                        message
                    )
                    
                    logger.info(f"✅ Sent daily message to Telegram athlete {athlete['id']}")
                    
            except Exception as e:
                logger.error(f"❌ Error sending to Telegram athlete {athlete.get('id')}: {e}")
            
            # Rate limiting
            await asyncio.sleep(1)
        
        # Get all WhatsApp athletes
        whatsapp_athletes = await supabase_handler.get_all_whatsapp_athletes()
        logger.info(f"📱 Found {len(whatsapp_athletes)} WhatsApp athletes")
        
        for athlete in whatsapp_athletes:
            try:
                # Get daily recommendation
                response = await api_handler.call_autonomous_decision(athlete)
                
                if response:
                    # Update metrics
                    await supabase_handler.update_athlete_metrics(
                        athlete["id"],
                        aisri_score=response.get("aisri_score"),
                        injury_risk=response.get("injury_risk"),
                        training_status=response.get("training_status")
                    )
                    
                    # Format and send message
                    message = f"""🌅 Good Morning from AISRi Coach!

Here's your daily training recommendation:

{api_handler.format_response(response, athlete)}

Have a great workout! 💪
"""
                    await whatsapp_handler.send_daily_message(
                        athlete["whatsapp_number"],
                        message
                    )
                    
                    logger.info(f"✅ Sent daily message to WhatsApp athlete {athlete['id']}")
                    
            except Exception as e:
                logger.error(f"❌ Error sending to WhatsApp athlete {athlete.get('id')}: {e}")
            
            # Rate limiting
            await asyncio.sleep(1)
        
        logger.info("✅ Daily recommendation cycle completed")
        
    except Exception as e:
        logger.error(f"❌ Error in daily recommendation cycle: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI lifespan manager for startup and shutdown"""
    global supabase_handler, api_handler, telegram_handler, whatsapp_handler, scheduler
    
    logger.info("🚀 Starting AISRi Communication Agent...")
    
    # Initialize handlers
    try:
        supabase_handler = SupabaseHandler()
        api_handler = AISRiAPIHandler()
        telegram_handler = TelegramHandler(supabase_handler, api_handler)
        whatsapp_handler = WhatsAppHandler(supabase_handler, api_handler)
        
        logger.info("✅ All handlers initialized")
        
        # Setup Telegram handlers
        telegram_handler.setup_handlers()
        
        # Start Telegram polling in background
        asyncio.create_task(telegram_handler.start_polling())
        
        # Setup scheduler for daily messages
        scheduler = AsyncIOScheduler()
        
        # Schedule daily messages at 5:00 AM
        scheduler.add_job(
            send_daily_recommendations,
            CronTrigger(hour=5, minute=0),
            id="daily_recommendations",
            name="Send daily workout recommendations",
            replace_existing=True
        )
        
        scheduler.start()
        logger.info("✅ Scheduler started - Daily messages at 5:00 AM")
        
        logger.info("🎉 AISRi Communication Agent is ready!")
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize: {e}")
        raise
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down...")
    
    if telegram_handler:
        await telegram_handler.stop_polling()
    
    if scheduler:
        scheduler.shutdown()
    
    logger.info("✅ Shutdown complete")


# Create FastAPI app
app = FastAPI(
    title="AISRi Communication Agent",
    description="Production-ready Telegram & WhatsApp integration with AISRi AI Engine",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "✅ AISRi Communication Agent is running",
        "version": "1.0.0",
        "platforms": ["Telegram", "WhatsApp"],
        "features": [
            "Autonomous training decisions",
            "Injury risk prediction",
            "Performance prediction",
            "Training plan generation",
            "Daily automated messages"
        ]
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "handlers": {
            "supabase": supabase_handler is not None,
            "api": api_handler is not None,
            "telegram": telegram_handler is not None,
            "whatsapp": whatsapp_handler is not None
        },
        "scheduler": scheduler.running if scheduler else False
    }


@app.post("/telegram/webhook")
async def telegram_webhook(request: Request):
    """Telegram webhook endpoint (alternative to polling)"""
    try:
        data = await request.json()
        logger.info("📨 Received Telegram webhook")
        
        # Process through Telegram handler
        # Note: This requires webhook setup with Telegram
        return JSONResponse({"status": "received"})
        
    except Exception as e:
        logger.error(f"❌ Telegram webhook error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/whatsapp/webhook")
async def whatsapp_webhook_verify(
    mode: str = Query(None, alias="hub.mode"),
    token: str = Query(None, alias="hub.verify_token"),
    challenge: str = Query(None, alias="hub.challenge")
):
    """WhatsApp webhook verification"""
    logger.info("🔐 WhatsApp webhook verification request")
    
    result = whatsapp_handler.verify_webhook(mode, token, challenge)
    
    if result:
        return PlainTextResponse(result)
    else:
        raise HTTPException(status_code=403, detail="Verification failed")


@app.post("/whatsapp/webhook")
async def whatsapp_webhook(request: Request):
    """WhatsApp webhook endpoint for incoming messages"""
    try:
        data = await request.json()
        logger.info("📨 Received WhatsApp webhook")
        
        # Process webhook
        success = await whatsapp_handler.process_webhook(data)
        
        if success:
            return JSONResponse({"status": "success"})
        else:
            return JSONResponse({"status": "no_message"})
            
    except Exception as e:
        logger.error(f"❌ WhatsApp webhook error: {e}")
        # Always return 200 to WhatsApp to prevent retries
        return JSONResponse({"status": "error", "message": str(e)})


@app.post("/admin/send-daily")
async def trigger_daily_messages():
    """Admin endpoint to manually trigger daily messages"""
    try:
        asyncio.create_task(send_daily_recommendations())
        return {"status": "✅ Daily message cycle started"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/admin/stats")
async def get_stats():
    """Admin endpoint to get system statistics"""
    try:
        telegram_athletes = await supabase_handler.get_all_telegram_athletes()
        whatsapp_athletes = await supabase_handler.get_all_whatsapp_athletes()
        
        return {
            "total_athletes": {
                "telegram": len(telegram_athletes),
                "whatsapp": len(whatsapp_athletes)
            },
            "next_daily_message": "05:00 UTC",
            "scheduler_running": scheduler.running if scheduler else False
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    
    uvicorn.run(
        "communication_agent:app",
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
