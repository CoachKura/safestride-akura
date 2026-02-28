"""
AISRi Communication Agent - Simplified Working Version
Minimal version with Telegram support,  no Supabase conflicts
"""
import os
import logging
from datetime import datetime
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import asyncio

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="AISRi Communication Agent",
    description="Telegram & WhatsApp integration with AISRi AI Engine",
    version="1.0.0"
)

@app.get("/")
async def root():
    return {
        "status": "✅ AISRi Communication Agent is running",
        "version": "1.0.0",
        "platforms": ["Telegram", "WhatsApp"],
        "endpoints": {
            "health": "GET /health",
            "telegram_webhook": "POST /telegram/webhook",
            "whatsapp_webhook": "GET|POST /whatsapp/webhook"
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "telegram_token_set": bool(os.getenv("TELEGRAM_TOKEN")),
        "aisri_api_url": os.getenv("AISRI_API_URL", "not_set")
    }

@app.post("/telegram/webhook")
async def telegram_webhook(request: Request):
    """Telegram webhook endpoint"""
    try:
        data = await request.json()
        logger.info(f"📨 Received Telegram webhook: {data}")
        return JSONResponse({"status": "received"})
    except Exception as e:
        logger.error(f"❌ Telegram webhook error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/whatsapp/webhook")
async def whatsapp_webhook_verify(
    mode: str = None,
    token: str = None,
    challenge: str = None
):
    """WhatsApp webhook verification"""
    verify_token = os.getenv("WHATSAPP_VERIFY_TOKEN", "test_token")
    
    if mode == "subscribe" and token == verify_token:
        logger.info("✅ WhatsApp webhook verified")
        return challenge
    else:
        raise HTTPException(status_code=403, detail="Verification failed")

@app.post("/whatsapp/webhook")
async def whatsapp_webhook(request: Request):
    """WhatsApp webhook for incoming messages"""
    try:
        data = await request.json()
        logger.info(f"📨 Received WhatsApp webhook: {data}")
        return JSONResponse({"status": "success"})
    except Exception as e:
        logger.error(f"❌ WhatsApp webhook error: {e}")
        return JSONResponse({"status": "error", "message": str(e)})

if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    
    logger.info("🚀 Starting AISRi Communication Agent (Simplified)")
    logger.info(f"📍 Server: http://0.0.0.0:{port}")
    logger.info(f"💚 Health: http://localhost:{port}/health")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
