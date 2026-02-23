# 🏃 AISRi Communication Agent

Production-ready multi-platform communication system integrating **Telegram** and **WhatsApp** with **AISRi AI Engine** and **Supabase** backend.

## 🎯 Overview

AISRi Communication Agent acts as an intelligent AI coach across multiple messaging platforms, providing:

- ✅ **Autonomous training decisions**
- 🩺 **Injury risk prediction**
- 📊 **Performance forecasting**
- 📅 **Training plan generation**
- 🌅 **Automated daily messages at 5 AM**
- 💬 **Natural language processing**
- 🔄 **Athlete profile management**

## 🏗️ Architecture

`
ai_agents/communication_agent/
├── communication_agent.py      # Main FastAPI server
├── telegram_handler.py         # Telegram bot logic
├── whatsapp_handler.py         # WhatsApp Cloud API
├── supabase_handler.py         # Database operations
├── aisri_api_handler.py        # AI Engine API client
├── requirements.txt            # Dependencies
├── .env.example                # Environment template
└── README.md                   # This file
`

## 🚀 Quick Start

### 1. Install Dependencies

`ash
cd ai_agents/communication_agent
pip install -r requirements.txt
`

### 2. Configure Environment

Copy .env.example to .env:

`ash
cp .env.example .env
`

Fill in your credentials:

`env
# Telegram
TELEGRAM_TOKEN=your_telegram_bot_token

# WhatsApp
WHATSAPP_VERIFY_TOKEN=your_verify_token
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id

# AISRi AI Engine
AISRI_API_URL=https://api.akura.in

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_key

# Server
PORT=8000
`

### 3. Run the Server

`ash
python communication_agent.py
`

Or with uvicorn:

`ash
uvicorn communication_agent:app --host 0.0.0.0 --port 8000
`

## 📱 Telegram Setup

### Create Bot

1. Message **@BotFather** on Telegram
2. Send /newbot
3. Follow prompts to create bot
4. Copy the token to TELEGRAM_TOKEN in .env

### Available Commands

- /start - Start conversation and register
- /help - Show help message
- /today - Get today's workout recommendation
- /week - Get weekly training plan
- /stats - View current athlete stats

### Natural Language Examples

`
User: "I have knee pain"
Bot: [Calls injury risk agent]

User: "What should I train today?"
Bot: [Calls autonomous decision agent]

User: "Can I run a marathon under 4 hours?"
Bot: [Calls performance prediction agent]
`

## 📲 WhatsApp Setup

### Prerequisites

1. **Meta Developer Account**: https://developers.facebook.com/
2. **WhatsApp Business Account**
3. **Phone Number registered with WhatsApp**

### Configuration Steps

1. Go to Meta Developer Console
2. Create a new app → WhatsApp
3. Get:
   - Access Token
   - Phone Number ID
4. Set a custom verify token (any random string)
5. Add webhook URL: https://your-domain.com/whatsapp/webhook

### Webhook Verification

WhatsApp will send a GET request to verify:

`
GET /whatsapp/webhook?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=CHALLENGE
`

## 🗄️ Supabase Database Schema

### Required Table: profiles

`sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Identifiers
  telegram_id TEXT UNIQUE,
  whatsapp_number TEXT UNIQUE,
  first_name TEXT,
  username TEXT,
  
  -- Metrics
  aisri_score NUMERIC DEFAULT 50,
  injury_risk TEXT DEFAULT 'UNKNOWN',
  training_status TEXT DEFAULT 'ACTIVE'
);
`

### Optional Table: communication_logs

`sql
CREATE TABLE communication_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  platform TEXT,
  message_type TEXT,
  query TEXT,
  response TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
`

## 🤖 AISRi AI Engine Integration

### API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| /agent/autonomous-decision | Daily training recommendations |
| /agent/predict-injury-risk | Injury risk assessment |
| /agent/generate-training-plan | Weekly training plans |
| /agent/predict-performance | Performance predictions |

### API Request Format

`json
{
  "id": "athlete-uuid",
  "aisri_score": 74,
  "injury_risk": "LOW",
  "training_status": "ACTIVE"
}
`

### API Response Format

`json
{
  "aisri_score": 76,
  "injury_risk": "LOW",
  "training_status": "LIGHT TRAIN",
  "recommendation": "Easy aerobic training today. Keep intensity below 75% HR max."
}
`

## 📅 Daily Scheduling

The system automatically sends daily workout recommendations at **5:00 AM UTC**.

### How It Works

1. **APScheduler** runs a cron job at 5:00 AM
2. Fetches all athletes with Telegram/WhatsApp
3. Calls AISRi AI Engine for each athlete
4. Sends personalized message via appropriate platform
5. Updates athlete metrics in Supabase

### Manual Trigger

`ash
curl -X POST http://localhost:8000/admin/send-daily
`

## 🔌 API Endpoints

### Health Check

`ash
GET /
GET /health
`

### Telegram Webhook

`ash
POST /telegram/webhook
`

### WhatsApp Webhook

`ash
GET /whatsapp/webhook    # Verification
POST /whatsapp/webhook   # Messages
`

### Admin

`ash
POST /admin/send-daily   # Trigger daily messages
GET /admin/stats         # System statistics
`

## 🧪 Testing

### Test Health

`ash
curl http://localhost:8000/health
`

### Test Telegram Bot

1. Open Telegram
2. Find your bot by username
3. Send /start

### Test WhatsApp

1. Send message to your WhatsApp Business number
2. Check logs for webhook processing

### Test Daily Messages

`ash
curl -X POST http://localhost:8000/admin/send-daily
`

## 🚢 Deployment

### Render

Create ender.yaml:

`yaml
services:
  - type: web
    name: aisri-communication-agent
    runtime: python
    buildCommand: pip install -r requirements.txt
    startCommand: python communication_agent.py
    envVars:
      - key: TELEGRAM_TOKEN
        sync: false
      - key: WHATSAPP_ACCESS_TOKEN
        sync: false
      - key: AISRI_API_URL
        value: https://api.akura.in
      - key: SUPABASE_URL
        sync: false
      - key: SUPABASE_SERVICE_KEY
        sync: false
`

### Railway

`ash
railway login
railway init
railway up
`

### Docker

`dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "communication_agent.py"]
`

## 📊 Monitoring

### Logs

The system uses structured logging:

`
2024-02-23 05:00:00 - INFO - 🌅 Starting daily recommendation cycle...
2024-02-23 05:00:01 - INFO - 📱 Found 142 Telegram athletes
2024-02-23 05:00:02 - INFO - ✅ Sent daily message to Telegram athlete abc-123
`

### Admin Statistics

`ash
curl http://localhost:8000/admin/stats
`

Response:

`json
{
  "total_athletes": {
    "telegram": 142,
    "whatsapp": 87
  },
  "next_daily_message": "05:00 UTC",
  "scheduler_running": true
}
`

## 🔧 Troubleshooting

### Telegram Not Responding

1. Check TELEGRAM_TOKEN is correct
2. Verify bot is not blocked by user
3. Check logs for errors

### WhatsApp Webhook Not Working

1. Verify webhook URL is publicly accessible
2. Check WHATSAPP_VERIFY_TOKEN matches
3. Ensure HTTPS is enabled
4. Check Meta Developer Console logs

### Supabase Connection Errors

1. Verify SUPABASE_URL and SUPABASE_SERVICE_KEY
2. Check network connectivity
3. Verify table schema exists

### AISRi API Errors

1. Check AISRI_API_URL is correct
2. Verify API is running
3. Check API logs for errors

## 🔐 Security

### Environment Variables

- Never commit .env to version control
- Use secrets management in production
- Rotate tokens regularly

### API Keys

- Use service role key for Supabase (server-side only)
- Keep WhatsApp access token secure
- Limit Telegram bot permissions

### Rate Limiting

- 1-second delay between daily messages
- Implement user-level rate limiting if needed

## 📈 Performance

### Optimization Tips

1. **Connection Pooling**: Reuse HTTP clients
2. **Async Operations**: All I/O is non-blocking
3. **Error Handling**: Graceful degradation
4. **Logging**: Structured for analysis

### Scaling

- Horizontal scaling supported
- Stateless design
- Database is single source of truth

## 🤝 Contributing

1. Follow existing code structure
2. Add type hints
3. Include docstrings
4. Test thoroughly
5. Update documentation

## 📄 License

Copyright © 2024 AISRi / Akura Technologies

## 🆘 Support

For issues or questions:

- Check logs first
- Review documentation
- Test with /health endpoint
- Check Supabase connectivity

## 🎉 Success Indicators

✅ Server starts without errors  
✅ /health returns healthy status  
✅ Telegram commands work  
✅ WhatsApp webhook verified  
✅ Daily messages sent at 5 AM  
✅ Athletes created/updated in Supabase  
✅ AISRi AI Engine responses received  

---

**Built with ❤️ for runners by AISRi**
