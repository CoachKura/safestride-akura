"""
AISRi Communication Agent - Minimal Test Server
For testing the server structure without external dependencies
"""
from fastapi import FastAPI
from datetime import datetime

app = FastAPI(
    title="AISRi Communication Agent - Test Mode",
    description="Minimal test server without external dependencies",
    version="1.0.0-test"
)

@app.get("/")
async def root():
    return {
        "status": "✅ AISRi Communication Agent is running (TEST MODE)",
        "version": "1.0.0-test",
        "note": "Configure .env with real credentials for full functionality",
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
    return {
        "status": "healthy",
        "mode": "test",
        "timestamp": datetime.utcnow().isoformat(),
        "message": "Test server running. Configure .env for full functionality."
    }

if __name__ == "__main__":
    import uvicorn
    import os
    
    port = int(os.getenv("PORT", 8000))
    
    print("\n🧪 AISRi Communication Agent - TEST MODE")
    print("=" * 50)
    print("✅ Server starting without external dependencies")
    print(f"🌐 Access at: http://localhost:{port}")
    print(f"💚 Health check: http://localhost:{port}/health")
    print("\n⚠️  To enable full functionality:")
    print("   1. Get Telegram token from @BotFather")
    print("   2. Get Supabase credentials from your project")
    print("   3. Update .env file")
    print("   4. Run: python communication_agent.py")
    print("=" * 50 + "\n")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
