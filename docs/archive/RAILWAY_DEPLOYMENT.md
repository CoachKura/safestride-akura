# Railway Deployment Guide - SafeStride AI Engine

## 🚀 Your Production Deployment

**Production URL:** https://aisri-ai-engine-production.up.railway.app

Your FastAPI backend is now deployed and accessible from anywhere! 🎉

## 🔄 Environment Switching

You now have **2 environments**:

### 1. **Production** (Railway)

- URL: `https://aisri-ai-engine-production.up.railway.app`
- Use for: Flutter app, scheduled tasks, production data
- Always available, no local server needed

### 2. **Local** (Development)

- URL: `http://127.0.0.1:8001`
- Use for: Testing, development, offline work
- Requires running local server

## ⚙️ Configuration

### Update Your `.env` File

Add these lines to `ai_agents/.env`:

```env
# API Configuration
PRODUCTION_API_URL=https://aisri-ai-engine-production.up.railway.app
LOCAL_API_URL=http://127.0.0.1:8001

# Set to 'production' or 'local'
ENVIRONMENT=production
```

## 🎯 Using the New Script

### Run Against Production

```bash
cd C:\safestride\ai_agents

# Set environment to production
$env:ENVIRONMENT = "production"

# Run the cycle
python run_cycle.py
```

### Run Against Local

```bash
cd C:\safestride\ai_agents

# Set environment to local
$env:ENVIRONMENT = "local"

# Make sure local server is running first!
# python main.py  (in separate terminal)

# Run the cycle
python run_cycle.py
```

## 📱 Flutter App Configuration

Update your Flutter app to use production URL:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://aisri-ai-engine-production.up.railway.app';

  // For development, comment above and use:
  // static const String baseUrl = 'http://127.0.0.1:8001';
}
```

## ⏰ Scheduled Tasks

### Update Task to Use Production

**For SafeStrideAIDaily:**

```powershell
# Update the scheduled task
$action = New-ScheduledTaskAction `
    -Execute "powershell" `
    -Argument "-Command `"cd C:\safestride\ai_agents; `$env:ENVIRONMENT='production'; python run_cycle.py`""

Set-ScheduledTask -TaskName "SafeStrideAIDaily" -Action $action
```

**For SafeStrideSimple:**

```powershell
# Update to use production
$action = New-ScheduledTaskAction `
    -Execute "powershell" `
    -Argument "-Command `"cd C:\safestride\ai_agents; `$env:ENVIRONMENT='production'; python simple_daily_cycle.py`""

Set-ScheduledTask -TaskName "SafeStrideSimple" -Action $action
```

## 🧪 Testing Both Environments

### Test Production

```powershell
# Test connection
Invoke-RestMethod https://aisri-ai-engine-production.up.railway.app/

# Test commander endpoint
$body = @{goal="list_athletes"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://aisri-ai-engine-production.up.railway.app/agent/commander" `
    -Method POST -Body $body -ContentType "application/json"
```

### Test Local

```powershell
# Test connection
Invoke-RestMethod http://127.0.0.1:8001/

# Test commander endpoint
$body = @{goal="list_athletes"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://127.0.0.1:8001/agent/commander" `
    -Method POST -Body $body -ContentType "application/json"
```

## 📊 Benefits of Railway Deployment

✅ **Always Available** - No need to keep local server running  
✅ **Mobile Access** - Flutter app can access from anywhere  
✅ **Scheduled Tasks** - Run automation from any machine  
✅ **Scalable** - Railway handles traffic automatically  
✅ **SSL/HTTPS** - Secure by default  
✅ **Monitoring** - Railway provides logs and metrics

## 🔧 Railway Configuration

### Environment Variables on Railway

Make sure these are set in your Railway project:

```
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<your-service-key>
PORT=8000  (Railway sets this automatically)
OPENAI_API_KEY=<your-openai-key>
```

### Deployment Command

Railway should auto-detect and use:

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

## 📝 API Documentation

Your production API docs are available at:

- **Swagger UI:** https://aisri-ai-engine-production.up.railway.app/docs
- **ReDoc:** https://aisri-ai-engine-production.up.railway.app/redoc

## 🔐 Security Considerations

### Production

- ✅ HTTPS enabled automatically
- ✅ Environment variables encrypted
- ⚠️ No authentication yet - consider adding API keys
- ⚠️ CORS may need configuration for Flutter

### Add CORS for Flutter

In `main.py`, add:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🚨 Troubleshooting

### "Cannot connect to production API"

1. Check Railway dashboard - is service running?
2. Check Railway logs for errors
3. Verify environment variables are set
4. Test URL directly in browser

### "Local server not responding"

1. Make sure you started local server: `python main.py`
2. Check port 8001 is not in use
3. Verify `.env` file has correct Supabase credentials

### "Scheduled task not working"

1. Check Windows Event Viewer for task errors
2. Verify environment variable is set in task
3. Test script manually first
4. Check task history in Task Scheduler

## 📊 Monitoring

### Railway Dashboard

- View logs: Railway dashboard → Deployments → Logs
- Check metrics: CPU, Memory, Request count
- Set up alerts for errors

### Local Logs

```powershell
# Run with verbose logging
python run_cycle.py 2>&1 | Tee-Object -FilePath "C:\safestride\logs\cycle.log"
```

## 🔄 Switching Environments

### Quick Switch Commands

**Switch to Production:**

```powershell
# In PowerShell
$env:ENVIRONMENT = "production"
python run_cycle.py
```

**Switch to Local:**

```powershell
# In PowerShell
$env:ENVIRONMENT = "local"
python run_cycle.py
```

**Permanent Change:**
Edit `.env` file and change `ENVIRONMENT=production` or `ENVIRONMENT=local`

## 📦 Deployment Workflow

```
Local Development
    ↓ (git push)
Railway (Auto-Deploy)
    ↓ (builds & deploys)
Production Server
    ↓ (accessible at)
https://aisri-ai-engine-production.up.railway.app
```

## 🎯 Best Practices

1. **Development:** Always test locally first
2. **Testing:** Use production for integration tests
3. **Automation:** Point scheduled tasks to production
4. **Mobile App:** Use production URL in release builds
5. **Monitoring:** Check Railway logs regularly
6. **Backups:** Supabase handles database backups

## 🔗 Quick Links

- **Production API:** https://aisri-ai-engine-production.up.railway.app
- **API Docs:** https://aisri-ai-engine-production.up.railway.app/docs
- **Railway Dashboard:** https://railway.app/dashboard
- **Supabase Dashboard:** https://app.supabase.com/project/xzxnnswggwqtctcgpocr

---

**Ready to use!** Your AI engine is now running in the cloud 🚀
