# 🚀 AISRi Communication Agent - Quick Reference

## ⚡ Quick Commands

### Local Development

`ash
# Setup
cd ai_agents/communication_agent
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your credentials

# Run
python start.py

# Or with PowerShell (Windows)
.\start.ps1
`

### Health Check

`ash
curl http://localhost:8000/health
`

## 📱 Platform Setup

### Telegram

1. **Create bot**: Message @BotFather → /newbot
2. **Get token**: Copy to TELEGRAM_TOKEN
3. **Test**: Find your bot on Telegram → /start

### WhatsApp

1. **Meta Developer**: https://developers.facebook.com/
2. **Create app**: WhatsApp → Business API
3. **Get tokens**: Access Token + Phone Number ID
4. **Set webhook**: https://your-domain.com/whatsapp/webhook

## 🔑 Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| TELEGRAM_TOKEN | ✅ | Bot token from @BotFather |
| AISRI_API_URL | ✅ | https://api.akura.in |
| SUPABASE_URL | ✅ | Your Supabase project URL |
| SUPABASE_SERVICE_KEY | ✅ | Service role key |
| WHATSAPP_VERIFY_TOKEN | ⚠️ | Custom verify token |
| WHATSAPP_ACCESS_TOKEN | ⚠️ | Meta access token |
| WHATSAPP_PHONE_NUMBER_ID | ⚠️ | WhatsApp phone number ID |

## 🗄️ Database Schema

`sql
-- Profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  telegram_id TEXT UNIQUE,
  whatsapp_number TEXT UNIQUE,
  first_name TEXT,
  username TEXT,
  aisri_score NUMERIC DEFAULT 50,
  injury_risk TEXT DEFAULT 'UNKNOWN',
  training_status TEXT DEFAULT 'ACTIVE',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Optional: Communication logs
CREATE TABLE communication_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  platform TEXT,
  message_type TEXT,
  query TEXT,
  response TEXT,
  timestamp TIMESTAMP DEFAULT NOW()
);
`

## 🤖 Telegram Commands

| Command | Description |
|---------|-------------|
| /start | Register and start |
| /help | Show help |
| /today | Today's workout |
| /week | Weekly plan |
| /stats | Your stats |

## 💬 Natural Language

| Input | Routed To |
|-------|-----------|
| "knee pain" | Injury Risk Agent |
| "train today?" | Autonomous Decision |
| "5K under 20 min?" | Performance Prediction |
| "weekly plan" | Training Plan Agent |

## 🌅 Daily Scheduling

**Time**: 5:00 AM UTC  
**Action**: Sends workout recommendations to all athletes

### Manual Trigger

`ash
curl -X POST http://localhost:8000/admin/send-daily
`

## 📊 API Endpoints

`ash
# Health
GET  /
GET  /health

# Webhooks
POST /telegram/webhook
GET  /whatsapp/webhook   # Verify
POST /whatsapp/webhook   # Messages

# Admin
POST /admin/send-daily
GET  /admin/stats
`

## 🚢 Deployment

### Render

`ash
# Push to GitHub
git push

# In Render dashboard:
1. New Web Service
2. Connect repository
3. Set environment variables
4. Deploy
`

### Railway

`ash
railway login
railway init
railway add
railway up
`

### Docker

`ash
docker build -t aisri-comm-agent .
docker run -p 8000:8000 --env-file .env aisri-comm-agent
`

## 🔧 Troubleshooting

### Telegram Not Responding

`ash
# Check token
echo 

# Check logs
tail -f logs/communication_agent.log

# Test bot
curl https://api.telegram.org/bot/getMe
`

### WhatsApp Webhook Failing

`ash
# Test webhook URL (must be HTTPS)
curl https://your-domain.com/health

# Verify token matches
echo 

# Check Meta Developer Console logs
`

### Supabase Connection Error

`ash
# Test connection
curl -H "apikey: " "/rest/v1/profiles?select=*&limit=1"
`

### AISRi API Error

`ash
# Test API
curl https://api.akura.in/

# Check API is running
curl https://api.akura.in/health
`

## 📈 Monitoring

### Check System Status

`ash
curl http://localhost:8000/admin/stats
`

### View Logs

`ash
# Follow logs
tail -f logs/*.log

# Filter errors
grep ERROR logs/*.log
`

## 🎯 Testing Checklist

- [ ] Server starts without errors
- [ ] /health returns 200
- [ ] Telegram /start works
- [ ] Telegram commands respond
- [ ] WhatsApp webhook verified
- [ ] WhatsApp messages received
- [ ] Athletes created in Supabase
- [ ] AISRi API responses work
- [ ] Daily messages scheduled

## 🆘 Common Issues

**Port already in use**
`ash
# Windows
netstat -ano | findstr :8000
taskkill /PID <pid> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
`

**Import errors**
`ash
pip install -r requirements.txt --force-reinstall
`

**Environment not loading**
`ash
# Check .env exists
ls -la .env

# Test load
python -c "from dotenv import load_dotenv; load_dotenv(); import os; print(os.getenv('TELEGRAM_TOKEN'))"
`

## ⚡ Quick Start Checklist

1. ✅ Install Python 3.11+
2. ✅ Clone repository
3. ✅ Install dependencies: pip install -r requirements.txt
4. ✅ Copy .env.example to .env
5. ✅ Get Telegram token from @BotFather
6. ✅ Add Supabase credentials
7. ✅ Run: python start.py
8. ✅ Test: curl http://localhost:8000/health
9. ✅ Message bot on Telegram

## 📚 Resources

- **Telegram Bot API**: https://core.telegram.org/bots/api
- **WhatsApp Cloud API**: https://developers.facebook.com/docs/whatsapp/cloud-api
- **Supabase Docs**: https://supabase.com/docs
- **FastAPI Docs**: https://fastapi.tiangolo.com/

---

**Need help?** Check the [full README](README.md) or server logs.
