# SafeStride Deployment Guide

## 🚀 Quick Deployment to Production

### **Prerequisites**
- GitHub account (repo: CoachKura/safestride-akura)
- Render account (for backend)
- Domain registrar access (for akura.in)
- Supabase project (existing)
- Strava API credentials (Client ID: 162971)

---

## 📦 Step 1: Upload Frontend Files to GitHub

If you haven't already pushed these files:

```bash
cd safestride-frontend
git init
git add .
git commit -m "SafeStride frontend complete with AKURA API"
git remote add origin https://github.com/CoachKura/safestride-akura.git
git push -u origin main
```

---

## 🌐 Step 2: Deploy Frontend to Render (Static Site)

1. Go to https://render.com/
2. Click **New +** → **Static Site**
3. Connect repository: `CoachKura/safestride-akura`
4. Configure:
   - **Name**: `safestride-frontend`
   - **Branch**: `main`
   - **Root Directory**: Leave empty (or `./` if files are in subfolder)
   - **Build Command**: Leave empty (static HTML)
   - **Publish Directory**: `.` (root directory)

5. Click **Create Static Site**
6. Wait 2-3 minutes for deployment
7. Your site will be live at: `https://safestride-frontend.onrender.com`

---

## 🔧 Step 3: Update API Configuration

Once frontend is deployed, update the backend URL in your JavaScript files:

**In `js/main.js`, `js/athlete-dashboard.js`, `js/athlete-devices.js`, `js/coach-dashboard.js`:**

```javascript
const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com', // ✅ Already set
    stravaClientId: '162971' // ✅ Already set
};
```

✅ **No changes needed** - already configured!

---

## 🔐 Step 4: Configure Strava OAuth Callback

1. Go to https://www.strava.com/settings/api
2. Update **Authorization Callback Domain**:
   ```
   Remove: localhost
   Add: safestride-frontend.onrender.com
   Add: akura.in
   ```
3. Click **Update**

---

## 🌍 Step 5: Configure Custom Domain (akura.in)

### **Option A: Render Custom Domain**

1. In Render dashboard, go to `safestride-frontend` → **Settings** → **Custom Domains**
2. Click **Add Custom Domain**
3. Enter: `akura.in`
4. Enter: `www.akura.in`
5. Render will show DNS records:
   ```
   Type: A
   Host: @
   Value: 216.24.57.1
   TTL: 3600

   Type: A
   Host: www
   Value: 216.24.57.1
   TTL: 3600
   ```

### **Option B: Cloudflare (if using)**

1. Add akura.in to Cloudflare
2. Add DNS records:
   ```
   Type: CNAME
   Name: @
   Target: safestride-frontend.onrender.com
   Proxy: Enabled (orange cloud)

   Type: CNAME
   Name: www
   Target: safestride-frontend.onrender.com
   Proxy: Enabled
   ```

3. Update DNS at registrar:
   - Nameserver 1: `ns1.cloudflare.com`
   - Nameserver 2: `ns2.cloudflare.com`

---

## 🔒 Step 6: Update Backend CORS

Update backend environment variable on Render:

```env
CORS_ORIGIN=https://akura.in,https://www.akura.in,https://safestride-frontend.onrender.com
```

Then **Redeploy** backend.

---

## ✅ Step 7: Verify Deployment

### **Test Checklist**

1. **Homepage loads**: https://akura.in (or https://safestride-frontend.onrender.com)
   - [x] Hero section displays
   - [x] Features section displays
   - [x] Sign In/Join Now buttons work

2. **Backend connection**:
   - [x] Check browser console: `✅ Backend Status: ok`
   - [x] Test: https://safestride-backend-cave.onrender.com/api/health
   - [x] Expected: `{"status":"ok","service":"SafeStride by AKURA Backend"}`

3. **Authentication flow**:
   - [x] Click "Sign In"
   - [x] Enter email/password
   - [x] Submit → Should redirect to dashboard

4. **Athlete Dashboard**:
   - [x] AKURA API score displays
   - [x] Today's workout shows
   - [x] HR zones display correctly
   - [x] Progress chart renders

5. **Device Sync**:
   - [x] Navigate to Devices page
   - [x] Click "Connect Strava"
   - [x] Should redirect to Strava OAuth
   - [x] After authorization, return to devices page

6. **Coach Dashboard**:
   - [x] Login as coach
   - [x] 10 athletes display
   - [x] AKURA API scores calculated
   - [x] Team stats show

---

## 🎯 Post-Deployment Tasks

### **1. Test with Real Athletes (Day 1)**

Send invitations to 10 Chennai athletes:

```
Hi [Name],

Welcome to SafeStride by AKURA! 🏃

Your account is ready:
- Website: https://akura.in
- Email: [athlete-email]
- Temporary Password: [generated-password]

Connect your Garmin/Strava watch and start your journey!

Coach Kura
```

### **2. Monitor Backend Health**

Check Render logs:
```
https://dashboard.render.com/web/[your-service-id]/logs
```

Expected logs:
```
✅ Supabase connected successfully
Server running on port 10000
SafeStride Backend v1.0.0
```

### **3. Analytics Setup (Optional)**

Add Google Analytics to `index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

---

## 🐛 Troubleshooting

### **Issue: "Backend connection failed"**

**Solution:**
1. Check backend is running: https://safestride-backend-cave.onrender.com/api/health
2. Check CORS settings in backend env vars
3. Check browser console for CORS errors

### **Issue: "Strava callback fails"**

**Solution:**
1. Verify callback domain in Strava settings
2. Check URL matches exactly: `safestride-frontend.onrender.com`
3. Ensure `state` parameter is `strava`

### **Issue: "DNS not resolving"**

**Solution:**
1. Check DNS propagation: https://dnschecker.org
2. Wait 10-60 minutes for propagation
3. Verify A records point to correct IP: `216.24.57.1`
4. Clear browser cache and DNS cache

### **Issue: "SSL certificate not issued"**

**Solution:**
1. Wait 10-15 minutes after DNS propagation
2. Render auto-issues Let's Encrypt certificates
3. Check Render dashboard for SSL status
4. Force refresh: `https://akura.in` (not `http://`)

---

## 📊 Expected Performance

- **First Load**: < 2 seconds
- **Backend API**: < 500ms response time
- **Strava OAuth**: < 3 seconds redirect
- **AKURA API Calculation**: < 50ms
- **Chart Rendering**: < 200ms

---

## 🎉 Launch Day Checklist

### **January 27, 2026 - Go Live**

- [x] Frontend deployed to Render
- [x] Backend running on Render
- [x] akura.in domain configured
- [x] SSL certificate issued
- [x] Strava OAuth tested
- [ ] 10 athletes invited
- [ ] Coach login tested
- [ ] All pages load correctly
- [ ] Mobile responsive verified
- [ ] Social media announcement ready
- [ ] WhatsApp group created

---

## 📞 Support Contacts

- **Technical Issues**: Check Render logs
- **Domain Issues**: Contact registrar support
- **Strava API**: https://developers.strava.com/docs/
- **Coach Contact**: coach@akura.in

---

## 🚨 Emergency Rollback

If critical issue occurs:

1. **Disable frontend**:
   ```
   Render Dashboard → safestride-frontend → Settings → Suspend
   ```

2. **Show maintenance page**:
   Create `index.html` with:
   ```html
   <h1>SafeStride Maintenance</h1>
   <p>We'll be back shortly. Contact: coach@akura.in</p>
   ```

3. **Fix issue in development**
4. **Test locally**
5. **Redeploy to Render**

---

## 📈 Success Metrics (First 30 Days)

| Metric | Target | How to Track |
|--------|--------|--------------|
| Athlete Signups | 10 | Supabase dashboard |
| Device Connections | 8+ | Check `stravaConnected` field |
| Avg API Score | 70+ | Query athletes table |
| Workout Uploads | 100+ | Count workouts table |
| Coach Logins | Daily | Check coach activity logs |
| Uptime | 99.9% | Render metrics |

---

## 🎯 Next Steps After Launch

1. **Week 1**: Monitor usage, fix bugs, collect feedback
2. **Week 2**: Add Garmin integration
3. **Week 3**: Implement coach calendar (publish/stage workflow)
4. **Week 4**: Add email notifications for workouts
5. **Month 2**: Mobile app (React Native)
6. **Month 3**: AI-powered pace predictions

---

**You're ready to launch! 🚀**

Questions? Contact: coach@akura.in
