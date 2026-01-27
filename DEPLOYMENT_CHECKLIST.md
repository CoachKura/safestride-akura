# 🚀 AKURA SafeStride - Production Deployment Checklist
**Target Launch:** January 27, 2026  
**Status:** Ready for deployment

---

## ✅ PRE-DEPLOYMENT CHECKLIST

### 1. Code Readiness
- [x] Frontend validation fixes (alignment.qAngle 0-45 range)
- [x] Environment variable configuration (.env setup)
- [x] Assessment form navigation (Next button visible)
- [x] Backend security hardening (helmet, rate limiting)
- [x] Supabase integration with graceful fallback
- [x] AIFRI calculation logic (6-pillar system)
- [x] Structured error responses with requestId
- [ ] Git commit all changes
- [ ] Push to GitHub main branch

### 2. Database Setup (Supabase)
- [ ] Create Supabase project at https://supabase.com
  - Name: `akura-safestride`
  - Region: `ap-south-1` (India) or closest to users
  - Tier: Free
- [ ] Run schema from `database/schema.sql` in SQL Editor
- [ ] Copy credentials from Project Settings → API:
  - `SUPABASE_URL`: https://xxxxx.supabase.co
  - `SUPABASE_ANON_KEY`: eyJhbGciOiJI...
  - `SUPABASE_SERVICE_KEY`: eyJhbGciOiJI...

### 3. Backend Deployment (Render)
- [ ] Go to https://dashboard.render.com
- [ ] Create Web Service:
  - Name: `akura-backend`
  - Repo: `CoachKura/safestride-akura`
  - Root Directory: `backend`
  - Environment: Node
  - Build Command: `npm install`
  - Start Command: `npm start`
  - Instance Type: Free
- [ ] Add environment variables:
  ```
  SUPABASE_URL=https://xxxxx.supabase.co
  SUPABASE_ANON_KEY=eyJhbGciOiJI...
  SUPABASE_SERVICE_KEY=eyJhbGciOiJI...
  JWT_SECRET=your-super-secret-key-min-32-characters-long
  FRONTEND_URL=https://akura.in
  NODE_ENV=production
  ```
- [ ] Enable Auto-Deploy (Settings → Build & Deploy → Yes)
- [ ] Wait for first deployment (3-5 minutes)
- [ ] Test health check: `curl https://akura-backend.onrender.com/api/healthz`
  - Expected: `{"status":"ok","service":"akura-backend","version":"1.0.0"}`

### 4. Frontend Deployment (Netlify) - **RECOMMENDED FASTEST**
- [ ] Go to https://app.netlify.com
- [ ] Add new site → Import from Git
  - Connect GitHub: `CoachKura/safestride-akura`
  - Branch: `main`
  - Publish directory: `frontend`
  - Build command: (leave empty)
- [ ] Deploy site (takes 2-3 minutes)
- [ ] Configure environment variables (Site settings → Environment variables):
  ```
  VITE_API_BASE_URL=/api
  VITE_ENABLE_OFFLINE_MODE=false
  VITE_LOG_LEVEL=info
  ```
- [ ] Test deployment:
  ```bash
  curl https://[your-site].netlify.app/api/healthz
  # Should return backend health check via proxy
  ```

### 5. Custom Domain Setup (Netlify)
- [ ] Add custom domain (Site settings → Domain management):
  - Add domain: `akura.in`
  - Add domain: `www.akura.in`
- [ ] Configure DNS with your registrar:
  ```
  Type: A
  Name: @
  Value: 75.2.60.5  (Netlify load balancer)
  
  Type: CNAME
  Name: www
  Value: [your-site].netlify.app
  ```
- [ ] Wait for DNS propagation (5-30 minutes)
- [ ] Enable HTTPS (automatic via Let's Encrypt)
- [ ] Test: `curl https://akura.in/api/healthz`

---

## 🧪 POST-DEPLOYMENT TESTING

### Backend API Tests
```bash
# 1. Health check
curl https://akura.in/api/healthz
# Expected: {"status":"ok","service":"akura-backend","version":"1.0.0"}

# 2. Submit test assessment
curl -X POST https://akura.in/api/assessments \
  -H "Content-Type: application/json" \
  -d '{
    "personal": {"age": 35, "email": "test@akura.in"},
    "running": {"weeklyMileage": 30},
    "alignment": {"qAngle": 16}
  }'
# Expected: 201 Created with assessmentId and scores

# 3. Test rate limiting (should fail on 101st request)
for i in {1..105}; do curl https://akura.in/api/healthz; done
# Expected: 429 Too Many Requests with RATE_LIMIT_EXCEEDED
```

### Frontend Tests
1. Open https://akura.in
2. Click "Get Started" → Fill assessment form
3. Verify:
   - [ ] All 9 steps load correctly
   - [ ] Next/Previous buttons work
   - [ ] Step counter shows "Step X of 9"
   - [ ] Validation catches invalid qAngle (e.g., typing "abc")
   - [ ] Submit shows loading spinner
   - [ ] Success page displays AIFRI score and risk level
4. Mobile test: Open on phone, verify responsive layout

### Database Tests
1. Go to Supabase Dashboard → Table Editor
2. Check `assessments` table:
   - [ ] New row created with correct athlete_id
   - [ ] `aifri_score` in 0-100 range
   - [ ] `scores` JSONB has all 6 pillars
   - [ ] `risk_level` is "Low", "Moderate", or "High"
   - [ ] `created_at` timestamp is correct

---

## 🔧 TROUBLESHOOTING

### Frontend not loading
```bash
# Check Netlify deploy status
netlify deploy --prod

# Check browser console for errors
# Right-click → Inspect → Console tab
```

### API calls failing (CORS errors)
- Verify `netlify.toml` has correct `[[redirects]]` section
- Check backend `FRONTEND_URL` env var matches actual domain
- Ensure Netlify proxy is working: `curl https://akura.in/api/healthz`

### Database connection errors
```bash
# SSH into Render instance (or check logs)
# Verify env vars are set
echo $SUPABASE_URL
echo $SUPABASE_SERVICE_KEY

# Test Supabase connection
node -e "require('./backend/config/supabase.js')"
# Should log: ✅ Supabase client initialized (service role)
```

### Assessment submission returns 500 error
- Check Render logs: Dashboard → akura-backend → Logs
- Look for `Assessment error [req_...]` messages
- Verify `assessments` table exists in Supabase
- Check if RLS policies are blocking inserts

---

## 📊 MONITORING SETUP

### Render Monitoring
- Dashboard: https://dashboard.render.com/web/akura-backend
- View Logs: Click "Logs" tab
- Metrics: CPU, Memory, Response Time automatically tracked

### Netlify Monitoring
- Dashboard: https://app.netlify.com/sites/[your-site]
- Analytics: Shows page views, bandwidth, build times
- Deploy Previews: Every PR gets preview URL

### Supabase Monitoring
- Dashboard: https://supabase.com/dashboard/project/[your-project]
- Database: Shows table sizes, query performance
- Auth: Track user signups (if using authentication)

---

## 🔄 CONTINUOUS DEPLOYMENT WORKFLOW

```bash
# 1. Make changes locally
cd "E:\Akura Safe Stride\safestride"

# Frontend changes
cd frontend
# Edit files...

# Backend changes
cd ../backend
# Edit files...

# 2. Test locally
cd ../frontend
npx http-server -p 5500 -c-1  # Test frontend

cd ../backend
npm start  # Test backend on localhost:3000

# 3. Commit and push
git add .
git commit -m "feat: add workout feedback endpoint"
git push origin main

# 4. Automatic deployments trigger:
# ✅ Netlify: Detects push → rebuilds frontend → deploys to CDN (2-3 min)
# ✅ Render: Detects push → rebuilds backend → deploys to server (3-5 min)

# 5. Check deployment status
# Netlify: https://app.netlify.com/sites/[your-site]/deploys
# Render: https://dashboard.render.com/web/akura-backend/events
```

---

## 🎯 LAUNCH CHECKLIST

### Day Before Launch (January 26, 2026)
- [ ] Complete all deployments
- [ ] Run full test suite
- [ ] Load test backend (100 requests/15min)
- [ ] Test on 3+ devices (desktop, mobile, tablet)
- [ ] Verify email notifications work
- [ ] Backup database schema
- [ ] Share staging URL with coach for final review

### Launch Day (January 27, 2026)
- [ ] Send invite emails to 10 Chennai athletes
- [ ] Monitor Render logs for errors
- [ ] Check Netlify analytics for traffic
- [ ] Be available for support (Slack/WhatsApp)
- [ ] Document any issues in GitHub Issues

### Week 1 Post-Launch
- [ ] Gather athlete feedback
- [ ] Review error logs daily
- [ ] Monitor AIFRI score distribution
- [ ] Fix critical bugs within 24 hours
- [ ] Plan iteration roadmap based on feedback

---

## 📝 ENVIRONMENT VARIABLES REFERENCE

### Backend (Render)
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
JWT_SECRET=your-super-secret-key-min-32-characters-long
FRONTEND_URL=https://akura.in
NODE_ENV=production
PORT=3000
```

### Frontend (Netlify)
```env
VITE_API_BASE_URL=/api
VITE_ENABLE_OFFLINE_MODE=false
VITE_LOG_LEVEL=info
```

---

## 🆘 SUPPORT CONTACTS

- **Developer:** Copilot AI
- **Coach/Product Owner:** [Your Name]
- **Render Support:** https://render.com/docs
- **Netlify Support:** https://docs.netlify.com
- **Supabase Support:** https://supabase.com/docs

---

**Last Updated:** 2026-01-27  
**Version:** 1.0.0  
**Status:** ✅ Ready for Production
