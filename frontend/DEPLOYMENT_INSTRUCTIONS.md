# SafeStride Frontend - Deployment Guide

## Quick Deploy to Render.com

### Option 1: Render Dashboard (Recommended)
1. Go to https://dashboard.render.com
2. Click "New +" → "Static Site"
3. Connect GitHub repo: `CoachKura/safestride-akura`
4. Configure:
   - **Name**: `safestride-frontend`
   - **Branch**: `main`
   - **Root Directory**: `frontend`
   - **Build Command**: (leave empty)
   - **Publish Directory**: `.` (current directory)
5. Click "Create Static Site"
6. Wait 2-3 minutes for deployment
7. Access your site at: `https://safestride-frontend.onrender.com`

### Option 2: Render CLI
```bash
# Install Render CLI (if not installed)
npm install -g render-cli

# Login
render login

# Deploy from frontend directory
cd "E:\Akura Safe Stride\safestride\frontend"
render deploy
```

### Option 3: Alternative - Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd "E:\Akura Safe Stride\safestride\frontend"
vercel --name safestride_frontend --prod
```

## Post-Deployment Checklist

### 1. Verify Deployment
- [ ] Visit the deployed URL
- [ ] Check all pages load:
  - [ ] Homepage (index.html)
  - [ ] Athlete Dashboard (athlete-dashboard.html)
  - [ ] Coach Dashboard (coach-dashboard.html)
  - [ ] Devices Page (athlete-devices.html)

### 2. Test API Integration
- [ ] Open browser console (F12)
- [ ] Check for backend health check success
- [ ] Test login with credentials
- [ ] Verify Strava OAuth redirect

### 3. Mobile Testing
- [ ] Test on iOS Safari
- [ ] Test on Android Chrome
- [ ] Verify responsive design
- [ ] Check touch interactions

### 4. Performance Check
- [ ] Run Lighthouse audit (target: 90+ score)
- [ ] Check page load time (<3 seconds)
- [ ] Verify all assets load correctly

## Environment Configuration

### Backend URL (Already Set)
```javascript
// In main.js, coach-dashboard.js, athlete-dashboard.js, athlete-devices.js
const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com',
    // ...
};
```

### Strava OAuth
- Client ID: 162971
- Redirect URL: Update in Strava settings to match deployed frontend URL
- Example: `https://safestride-frontend.onrender.com/athlete-devices.html`

## Troubleshooting

### Issue: CORS Error
**Solution**: Verify backend CORS settings allow frontend domain
```bash
# Check backend .env has:
FRONTEND_URL=https://safestride-frontend.onrender.com
```

### Issue: 404 on Page Refresh
**Solution**: Already handled by render.yaml rewrite rules

### Issue: Assets Not Loading
**Solution**: Check file paths are relative (no leading slash)

### Issue: Strava OAuth Fails
**Solution**: Update Strava app redirect URI to match deployed URL

## Custom Domain Setup (Optional)

1. In Render dashboard, go to your static site
2. Click "Settings" → "Custom Domain"
3. Add your domain (e.g., app.akura.in)
4. Follow DNS configuration instructions
5. Wait for SSL certificate provisioning (5-10 minutes)

## Monitoring

### Check Frontend Status
```bash
curl https://safestride-frontend.onrender.com
```

### Check Backend Status
```bash
curl https://safestride-backend-cave.onrender.com/api/health
```

### View Logs
- Render Dashboard → Your Service → Logs
- Browser DevTools → Console

## Next Steps After Deployment

1. ✅ Update Strava OAuth redirect URL
2. ✅ Test complete user flow (signup → login → dashboard)
3. ✅ Send invite links to 10 Chennai athletes
4. ✅ Monitor for first 24 hours
5. ✅ Collect feedback and iterate

---

**Deployment Time**: ~5 minutes
**Status**: Ready to deploy ✅
