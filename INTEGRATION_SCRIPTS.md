# 🔧 AKURA SafeStride - Integration Scripts
## Immediate Deployment Commands

---

## 🚀 STEP 1: Merge AISRI System (Run in Terminal)

```bash
# Navigate to project root
cd /home/user/webapp

# Create backup
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz frontend/ backend/ public/

# Copy AISRI JavaScript modules to frontend
cp public/aisri-ml-analyzer.js frontend/js/
cp public/aisri-engine-v2.js frontend/js/
cp public/ai-training-generator.js frontend/js/
cp public/device-aifri-connector.js frontend/js/

# Copy AISRI HTML pages to frontend
cp public/training-plan-builder.html frontend/
cp public/thursday-workout-generator.html frontend/
cp public/athlete-assessment-csv-upload.html frontend/
cp public/aisri-dashboard.html frontend/

# Create AISRI integration in main dashboard
echo "✅ AISRI files copied to frontend!"
```

---

## 🔐 STEP 2: Set Up Environment Variables

**Create `backend/.env` file:**
```bash
cat > backend/.env << 'EOF'
# Supabase Configuration
SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_KEY=YOUR_SUPABASE_SERVICE_KEY

# JWT Secret (generate with: openssl rand -hex 32)
JWT_SECRET=YOUR_JWT_SECRET_HERE

# Strava API (Already configured)
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=6554eb9bb83f222a585e312c17420221313f85c1
STRAVA_CALLBACK_URL=https://akura.in/auth/strava/callback

# Server Configuration
PORT=3000
NODE_ENV=production
FRONTEND_URL=https://akura.in

# Email Configuration (optional - for password reset)
SENDGRID_API_KEY=YOUR_SENDGRID_KEY
SENDGRID_FROM_EMAIL=noreply@akura.in
EOF
```

**Create `frontend/.env` file:**
```bash
cat > frontend/.env << 'EOF'
# Backend API URL
VITE_API_BASE_URL=https://your-backend-url.onrender.com/api

# Supabase (for direct client queries if needed)
VITE_SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

# Strava OAuth
VITE_STRAVA_CLIENT_ID=162971
EOF
```

---

## 💾 STEP 3: Database Setup

**Option A: Using Supabase SQL Editor**
```sql
-- 1. Go to https://supabase.com/dashboard/project/[YOUR_PROJECT_ID]/sql/new
-- 2. Copy and paste the entire schema from /home/user/webapp/database/schema.sql
-- 3. Click "Run"
-- 4. Import sample data from /home/user/webapp/public/sql/03_import_aisri_scores.sql
```

**Option B: Using psql Command Line**
```bash
# Set Supabase credentials
export SUPABASE_HOST="db.[YOUR_PROJECT_ID].supabase.co"
export SUPABASE_PASSWORD="[YOUR_DATABASE_PASSWORD]"

# Run schema
psql -h $SUPABASE_HOST -U postgres -d postgres -f database/schema.sql

# Import sample data
psql -h $SUPABASE_HOST -U postgres -d postgres -f public/sql/03_import_aisri_scores.sql

echo "✅ Database schema created!"
```

---

## 🔨 STEP 4: Backend Deployment to Render

**Option A: Using Render Dashboard (Recommended)**
```
1. Go to https://dashboard.render.com/
2. Click "New +" → "Web Service"
3. Connect GitHub repo: CoachKura/safestride-akura
4. Settings:
   - Name: akura-safestride-backend
   - Root Directory: backend
   - Build Command: npm install
   - Start Command: node server.js
5. Add Environment Variables (from backend/.env above)
6. Click "Create Web Service"
7. Wait ~5 minutes for deployment
8. Copy deployment URL: https://akura-safestride-backend.onrender.com
```

**Option B: Using Render CLI**
```bash
# Install Render CLI
npm install -g @render/cli

# Login to Render
render login

# Navigate to backend
cd /home/user/webapp/backend

# Deploy
render deploy

# Follow prompts, then copy deployment URL
```

---

## 🌐 STEP 5: Frontend Deployment to Vercel

**Option A: Using Vercel Dashboard (Recommended)**
```
1. Go to https://vercel.com/new
2. Import Git Repository: CoachKura/safestride-akura
3. Settings:
   - Framework Preset: Other
   - Root Directory: frontend
   - Build Command: (leave empty)
   - Output Directory: . (current directory)
4. Environment Variables:
   - VITE_API_BASE_URL = https://akura-safestride-backend.onrender.com/api
   - VITE_SUPABASE_URL = [YOUR_SUPABASE_URL]
   - VITE_SUPABASE_ANON_KEY = [YOUR_ANON_KEY]
   - VITE_STRAVA_CLIENT_ID = 162971
5. Click "Deploy"
6. Wait ~2 minutes
7. Copy deployment URL: https://your-project.vercel.app
```

**Option B: Using Vercel CLI**
```bash
# Install Vercel CLI
npm install -g vercel

# Navigate to frontend
cd /home/user/webapp/frontend

# Update API endpoint first
sed -i "s|const API_BASE_URL = .*|const API_BASE_URL = 'https://akura-safestride-backend.onrender.com/api';|" js/akuraAPI.js

# Deploy
vercel --prod

# Follow prompts
# Copy deployment URL when done
```

---

## 🌍 STEP 6: Configure Custom Domain (akura.in)

**Step 6.1: Add Domain to Vercel**
```
1. Go to Vercel project settings
2. Click "Domains"
3. Add "akura.in" and "www.akura.in"
4. Vercel will provide DNS records
```

**Step 6.2: Update DNS Records**
```
Type: CNAME
Name: akura.in (or @)
Value: cname.vercel-dns.com
TTL: Automatic

Type: CNAME
Name: www
Value: cname.vercel-dns.com
TTL: Automatic
```

**Step 6.3: Update Strava Callback URL**
```
1. Go to https://www.strava.com/settings/api
2. Update "Authorization Callback Domain" to: akura.in
3. Save changes
```

**Step 6.4: Update Backend CORS**
```bash
# Edit backend/server.js
# Change CORS origin to:
app.use(cors({
  origin: ['https://akura.in', 'https://www.akura.in'],
  credentials: true
}));

# Redeploy backend
cd /home/user/webapp/backend
git add .
git commit -m "Update CORS for production domain"
git push
```

---

## 🧪 STEP 7: Test Deployment

**Run these tests after deployment:**

```bash
# Test 1: Backend Health Check
curl https://akura-safestride-backend.onrender.com/api/health

# Test 2: Strava OAuth Endpoint
curl https://akura-safestride-backend.onrender.com/api/strava/connect

# Test 3: Frontend Loading
curl -I https://akura.in

# Test 4: AISRI Calculator
curl -I https://akura.in/training-plan-builder.html

# Test 5: API CORS
curl -H "Origin: https://akura.in" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS \
  https://akura-safestride-backend.onrender.com/api/auth/login

# All tests should return 200 OK or appropriate redirects
echo "✅ All tests passed!"
```

---

## 🔐 STEP 8: Create Admin Account

**Create first admin/coach account:**

```bash
# Using curl
curl -X POST https://akura-safestride-backend.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "coach@akura.in",
    "password": "TEMPORARY_PASSWORD_HERE",
    "name": "Coach Kura",
    "role": "coach"
  }'

# Save the returned JWT token
# Login at: https://akura.in/login.html
```

---

## 📱 STEP 9: Connect Strava (Kura B Sathyamoorthy)

**After logging in:**
```
1. Go to https://akura.in/athlete-dashboard.html
2. Click "Connect Strava" button
3. Authorize with Strava
4. System will automatically sync activities
5. AISRI scores will be calculated from HRV and activity data
```

---

## 📊 STEP 10: Test Complete Workflow

**Test flow as athlete:**
```
1. Register: https://akura.in/register.html
2. Login: https://akura.in/login.html
3. Complete assessment: https://akura.in/assessment-intake.html
4. View dashboard: https://akura.in/athlete-dashboard.html
5. Connect Strava
6. View AISRI scores
7. Get Thursday workout: https://akura.in/thursday-workout-generator.html
8. Complete workout tracking
9. Submit daily data
```

**Test flow as coach:**
```
1. Login: https://akura.in/login.html
2. View coach dashboard: https://akura.in/coach-dashboard.html
3. See all athletes
4. Upload CSV: https://akura.in/athlete-assessment-csv-upload.html
5. Generate bulk workouts
6. View athlete AISRI scores
7. Assign training protocols
```

---

## 🐛 TROUBLESHOOTING

**Issue 1: Backend deployment failing**
```bash
# Check logs on Render dashboard
# Common issues:
# - Missing environment variables
# - Node version mismatch (use 18.x)
# - Missing dependencies

# Fix: Update package.json engines
{
  "engines": {
    "node": "18.x"
  }
}
```

**Issue 2: CORS errors in browser**
```javascript
// Check backend/server.js CORS config:
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5500',
  credentials: true
}));

// Redeploy after changes
```

**Issue 3: Supabase connection failing**
```bash
# Test connection:
curl -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  https://YOUR_PROJECT_ID.supabase.co/rest/v1/coaches

# If fails, check:
# - Is API enabled in Supabase dashboard?
# - Are RLS policies configured?
# - Is anon key correct?
```

**Issue 4: Strava OAuth not working**
```
1. Check callback URL in Strava settings matches deployment
2. Verify STRAVA_CALLBACK_URL in backend/.env
3. Ensure SSL is enabled (Strava requires HTTPS)
4. Check browser console for errors
```

---

## 🎉 SUCCESS CHECKLIST

After deployment, verify:

- [ ] Backend health endpoint responds: `/api/health`
- [ ] Frontend loads: `https://akura.in`
- [ ] Login works: `https://akura.in/login.html`
- [ ] AISRI calculator works: `https://akura.in/training-plan-builder.html`
- [ ] Thursday workout generator works
- [ ] CSV upload works
- [ ] Strava OAuth redirects properly
- [ ] Database queries work (check coach dashboard)
- [ ] API authentication works (JWT tokens)
- [ ] Mobile responsive works (test on phone)
- [ ] All static assets load (CSS, JS, images)
- [ ] No console errors in browser DevTools
- [ ] No CORS errors
- [ ] SSL certificate active (green padlock)
- [ ] Domain resolves correctly

---

## 📞 SUPPORT

**If you encounter issues:**

1. **Check logs:**
   - Render: Dashboard → Logs
   - Vercel: Dashboard → Deployment → Logs
   - Browser: F12 → Console

2. **Test API directly:**
   ```bash
   curl -v https://your-backend.onrender.com/api/health
   ```

3. **Check environment variables:**
   - Render: Dashboard → Environment
   - Vercel: Dashboard → Settings → Environment Variables

4. **Database connection:**
   - Supabase: Dashboard → Database → Connection Info

---

## 🚀 DEPLOYMENT TIMELINE

**Total estimated time: 2 hours**

- Step 1: Merge AISRI (10 min) ⏱️
- Step 2: Environment variables (10 min) ⏱️
- Step 3: Database setup (15 min) ⏱️
- Step 4: Backend deployment (30 min) ⏱️
- Step 5: Frontend deployment (20 min) ⏱️
- Step 6: Custom domain (15 min) ⏱️
- Step 7: Testing (10 min) ⏱️
- Step 8: Admin account (5 min) ⏱️
- Step 9: Strava connection (5 min) ⏱️
- Step 10: Workflow testing (10 min) ⏱️

**Total: 2 hours 10 minutes** ✅

---

**Ready to deploy? Let's do this! 🚀**

_"From localhost to production in 2 hours. Let's make it happen!"_ 💪
