# 🚀 Render Deployment Guide - AISRi AI Engine

**Complete step-by-step guide to deploy the AISRi AI Engine on Render**

---

## 📋 Prerequisites

Before starting, have these ready:

- GitHub repository: https://github.com/CoachKura/safestride-akura
- Supabase project: https://bdisppaxbvygsspcuymb.supabase.co
- OpenAI API key: `sk-proj-tqj2...`

---

## 🔧 Step 1: Create New Render Service

### 1.1 Connect to GitHub

1. Go to: https://dashboard.render.com
2. Click **"New +"** button → **"Web Service"**
3. Click **"Connect account"** if GitHub not connected
4. Select your repository: `CoachKura/safestride-akura`
5. Click **"Connect"**

### 1.2 Configure Service Settings

Fill in these EXACT values:

| Setting            | Value                                          |
| ------------------ | ---------------------------------------------- |
| **Name**           | `aisri-ai-engine`                              |
| **Region**         | _Choose closest to you_                        |
| **Branch**         | `main`                                         |
| **Root Directory** | `ai_agents`                                    |
| **Runtime**        | `Python 3.11.9`                                |
| **Build Command**  | `pip install -r requirements.txt`              |
| **Start Command**  | `uvicorn main:app --host 0.0.0.0 --port 10000` |

### 1.3 Select Plan

- **Free Plan** (for testing) or
- **Starter Plan** ($7/month - recommended for production)

---

## 🔐 Step 2: Set Environment Variables

**⚠️ CRITICAL: Do this BEFORE first deployment**

### 2.1 Navigate to Environment Tab

1. After creating service, you'll be on the service dashboard
2. Click **"Environment"** in the left sidebar
3. Click **"Edit"** button (top right)

### 2.2 Add These 3 Variables

**Variable 1: SUPABASE_URL**

```
Key:   SUPABASE_URL
Value: https://bdisppaxbvygsspcuymb.supabase.co
```

**Variable 2: SUPABASE_SERVICE_KEY**

```
Key:   SUPABASE_SERVICE_KEY
Value: eyJ[YOUR_SUPABASE_SERVICE_ROLE_KEY_FROM_DASHBOARD]
```

_(Get from Supabase Dashboard → Settings → API → service_role key)_  
_(This is the service_role key, NOT the anon key)_

**Variable 3: OPENAI_API_KEY**

```
Key:   OPENAI_API_KEY
Value: sk-proj-[YOUR_OPENAI_API_KEY_HERE]
```

_(Get your API key from: https://platform.openai.com/api-keys)_

### 2.3 Save Changes

1. Click **"Save Changes"** button
2. Render will automatically trigger a deployment
3. Wait 3-5 minutes for deployment to complete

---

## ✅ Step 3: Verify Deployment

### 3.1 Check Deployment Status

1. Go to **"Logs"** tab in your Render service
2. Wait for these messages:
   ```
   ==> Building...
   ==> Installing dependencies
   ==> Running 'uvicorn main:app --host 0.0.0.0 --port 10000'
   INFO:     Started server process
   INFO:     Application startup complete.
   INFO:     Uvicorn running on http://0.0.0.0:10000
   ```

### 3.2 Get Your Service URL

1. Look at the top of your service dashboard
2. You'll see a URL like: `https://aisri-ai-engine.onrender.com`
3. Copy this URL

### 3.3 Test Endpoints

**Test 1: Health Check**

```powershell
Invoke-RestMethod -Uri "https://YOUR-SERVICE.onrender.com/" | ConvertTo-Json
```

Expected output:

```json
{
  "status": "AISRi AI Engine Running",
  "service": "AISRi AI Engine",
  "version": "1.0",
  "api": "https://api.akura.in",
  "docs": "https://api.akura.in/docs"
}
```

**Test 2: Environment Variables**

```powershell
Invoke-RestMethod -Uri "https://YOUR-SERVICE.onrender.com/env-check" | ConvertTo-Json
```

Expected output:

```json
{
  "SUPABASE_URL_set": true,
  "SUPABASE_SERVICE_KEY_set": true,
  "OPENAI_API_KEY_set": true,
  "supabase_client_initialized": true
}
```

**Test 3: Autonomous Decision**

```powershell
$body = '{"athlete_id":"test_athlete_001","query":"How am I doing?"}'
Invoke-RestMethod -Uri "https://YOUR-SERVICE.onrender.com/agent/autonomous-decision" -Method Post -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 3
```

Expected output:

```json
{
  "recommendation": "...",
  "athlete_id": "test_athlete_001",
  "confidence": 0.85
}
```

---

## 🔗 Step 4: Set Up Custom Domain (Optional)

### 4.1 Add Custom Domain in Render

1. In your service dashboard, click **"Settings"** tab
2. Scroll to **"Custom Domain"** section
3. Click **"Add Custom Domain"**
4. Enter: `api.akura.in`
5. Render will give you a CNAME record

### 4.2 Configure DNS

1. Go to your DNS provider (e.g., Cloudflare, GoDaddy)
2. Add CNAME record:
   ```
   Name:  api.akura.in
   Type:  CNAME
   Value: [value provided by Render]
   TTL:   Auto
   ```
3. Wait 5-15 minutes for DNS propagation

### 4.3 Verify Custom Domain

```powershell
Invoke-RestMethod -Uri "https://api.akura.in/" | ConvertTo-Json
```

---

## 🔄 Step 5: Deploy Updates (After Changes)

### When You Push Code Changes to GitHub:

**Automatic Deployment:**

1. Commit changes locally:
   ```powershell
   git add .
   git commit -m "your message"
   git push origin main
   ```
2. Render automatically detects the push
3. Starts new deployment (2-3 minutes)

**Manual Deployment:**

1. Go to Render service dashboard
2. Click **"Manual Deploy"** button (top right)
3. Select **"Deploy latest commit"**
4. Or select **"Clear build cache & deploy"** (if having issues)

---

## 🐛 Troubleshooting

### Issue 1: Environment Variables Not Loading

**Symptoms:**

```json
{
  "SUPABASE_URL_set": false,
  "SUPABASE_SERVICE_KEY_set": false,
  "OPENAI_API_KEY_set": false
}
```

**Solutions:**

**A. Verify variables are set:**

1. Go to **Environment** tab
2. You should see all 3 variables listed
3. If missing, add them using Step 2

**B. Force fresh deployment:**

1. Click **"Manual Deploy"**
2. Select **"Clear build cache & deploy"**
3. Wait 3-4 minutes

**C. Check for typos:**

- Variable names are CASE-SENSITIVE
- Must be EXACTLY:
  - `SUPABASE_URL` (not `supabase_url` or `SUPABASE-URL`)
  - `SUPABASE_SERVICE_KEY` (not `SUPABASE_SERVICE_ROLE_KEY`)
  - `OPENAI_API_KEY` (not `OPENAI-API-KEY`)

**D. Verify correct service:**

- Make sure you're setting variables on the RIGHT service
- Check the service URL matches where your API is deployed

---

### Issue 2: Build Fails

**Check Logs:**

1. Go to **"Logs"** tab
2. Look for error messages in red

**Common errors:**

**"Module not found"**

```
Solution: Check requirements.txt includes all dependencies
Fix: Update requirements.txt, commit, push
```

**"Python version mismatch"**

```
Solution: Check runtime.txt or Render settings
Fix: Set Python version to 3.11.9 in Render settings
```

**"Port binding error"**

```
Solution: Make sure start command uses port 10000
Fix: Start Command should be:
     uvicorn main:app --host 0.0.0.0 --port 10000
```

---

### Issue 3: 500 Internal Server Error

**Check application logs:**

1. Go to **"Logs"** tab
2. Scroll to see Python error traceback

**Common causes:**

- Missing environment variables
- Supabase connection failed
- Code error in application

**Debug steps:**

1. Test `/env-check` endpoint to verify variables
2. Check Supabase dashboard is accessible
3. Review error traceback in logs

---

### Issue 4: Custom Domain Not Working

**DNS not propagated yet:**

```
Wait 15-30 minutes after setting DNS record
Test: nslookup api.akura.in
```

**CNAME record incorrect:**

```
Verify CNAME points to Render-provided domain
Should end with .onrender.com
```

**SSL certificate pending:**

```
Render auto-provisions SSL (takes 1-2 minutes)
Check "Settings" → "Custom Domain" for status
```

---

## 📊 Monitoring & Maintenance

### Daily Checks

```powershell
# Quick health check
Invoke-RestMethod -Uri "https://api.akura.in/"

# Environment check
Invoke-RestMethod -Uri "https://api.akura.in/env-check"
```

### View Logs

1. Go to Render dashboard
2. Click your service
3. Click **"Logs"** tab
4. See real-time application logs

### Restart Service

1. Go to **"Settings"** tab
2. Scroll to **"Service Details"**
3. Click **"Suspend Service"** then **"Resume Service"**

### Update Environment Variables

1. Go to **"Environment"** tab
2. Click **"Edit"**
3. Modify values
4. Click **"Save Changes"** (triggers auto-deploy)

---

## ✅ Deployment Checklist

Before going to production, verify:

- [ ] Environment variables set correctly (all 3)
- [ ] `/env-check` returns all `true`
- [ ] `/agent/autonomous-decision` returns valid JSON
- [ ] Custom domain configured (if using)
- [ ] SSL certificate active (green lock in browser)
- [ ] Logs show no errors
- [ ] Service is on paid plan (for production loads)
- [ ] Backup plan for database (Supabase)

---

## 🚨 Emergency Rollback

If deployment breaks production:

1. Go to **"Events"** tab
2. Find the last working deployment
3. Click **"Rollback to this deploy"**
4. Service reverts to previous working version

---

## 📞 Support

**Render Issues:**

- Docs: https://render.com/docs
- Support: https://render.com/support

**Application Issues:**

- Check logs: Render Dashboard → Your Service → Logs
- Test locally: `python -m uvicorn main:app --reload`

---

## 🎯 Production Recommendations

1. **Enable Auto-Deploy:** Automatically deploy on push to main
2. **Set up Health Checks:** Render auto-restarts if endpoint fails
3. **Use Paid Plan:** Free tier sleeps after 15min inactivity
4. **Monitor Logs:** Check daily for errors
5. **Backup Environment Variables:** Keep copy in secure location
6. **Set up Alerts:** Get notified of deployment failures

---

**Last Updated:** February 24, 2026  
**Service:** AISRi AI Engine  
**Repository:** github.com/CoachKura/safestride-akura  
**Branch:** main
