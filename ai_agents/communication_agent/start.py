#!/usr/bin/env python3
"""
AISRi Communication Agent - Startup Script
Quick start script with environment validation
"""
import os
import sys
from pathlib import Path

def check_env_vars():
    """Check required environment variables"""
    required = [
        "TELEGRAM_TOKEN",
        "AISRI_API_URL",
        "SUPABASE_URL",
        "SUPABASE_SERVICE_KEY"
    ]
    
    optional = [
        "WHATSAPP_VERIFY_TOKEN",
        "WHATSAPP_ACCESS_TOKEN",
        "WHATSAPP_PHONE_NUMBER_ID"
    ]
    
    missing = []
    for var in required:
        if not os.getenv(var):
            missing.append(var)
    
    if missing:
        print("❌ Missing required environment variables:")
        for var in missing:
            print(f"   - {var}")
        print("\n💡 Copy .env.example to .env and fill in your values")
        return False
    
    print("✅ All required environment variables set")
    
    missing_optional = [var for var in optional if not os.getenv(var)]
    if missing_optional:
        print("⚠️  Optional WhatsApp variables not set:")
        for var in missing_optional:
            print(f"   - {var}")
        print("   WhatsApp functionality will be disabled")
    
    return True

def main():
    print("🚀 AISRi Communication Agent - Startup\n")
    
    # Check if .env exists
    env_file = Path(".env")
    if not env_file.exists():
        print("❌ .env file not found")
        print("💡 Copy .env.example to .env and configure:\n")
        print("   cp .env.example .env\n")
        sys.exit(1)
    
    # Load environment
    from dotenv import load_dotenv
    load_dotenv()
    
    # Validate environment
    if not check_env_vars():
        sys.exit(1)
    
    print("\n🎯 Starting server...\n")
    
    # Import and run
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    
    uvicorn.run(
        "communication_agent:app",
        host="0.0.0.0",
        port=port,
        reload=False,
        log_level="info"
    )

if __name__ == "__main__":
    main()
