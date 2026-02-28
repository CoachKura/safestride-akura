# 🚀 SafeStride AI - Complete Deployment Guide

## 📋 Overview

This guide walks through deploying the complete SafeStride AI system across all platforms:

- **Backend API**: Render.com (3 Python FastAPI services)
- **Database**: Supabase PostgreSQL (already deployed ✅)
- **Frontend**: GitHub Pages or Netlify (coming soon)
- **Mobile App**: Flutter (iOS + Android)

---

## 🎯 Pre-Deployment Checklist

### 1. Prerequisites

- [ ] GitHub account with repository access
- [ ] Render.com account (free tier available)
- [ ] Supabase project (already configured)
- [ ] Strava Developer account & app
- [ ] Garmin Developer account (optional)
- [ ] Apple Developer account (for iOS)
- [ ] Google Play Developer account (for Android)

### 2. Environment Variables Ready

Collect these values before starting:

```bash
# Supabase
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<your_service_role_key>

# Strava
STRAVA_CLIENT_ID=<your_client_id>
STRAVA_CLIENT_SECRET=<your_client_secret>
STRAVA_VERIFY_TOKEN=<random_string_for_webhook>

# Garmin (optional)
GARMIN_CONSUMER_KEY=<your_consumer_key>
GARMIN_CONSUMER_SECRET=<your_consumer_secret>
```

---

## 🔧 Part 1: Backend Deployment (Render)

### Step 1: Connect GitHub Repository

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New"** → **"Blueprint"**
3. Connect your GitHub account
4. Select `safestride` repository
5. Grant Render access

### Step 2: Deploy from render.yaml

1. Render will detect `render.yaml` automatically
2. Review the 3 services:
   - `safestride-api` (Main API - port 8000)
   - `safestride-webhooks` (Activity Integration - port 8001)
   - `safestride-oauth` (OAuth Flow - port 8002)
3. Click **"Apply"** to create all services

### Step 3: Configure Environment Variables

For **safestride-api**:

```bash
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<paste_from_supabase>
```

For **safestride-webhooks**:

```bash
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<paste_from_supabase>
STRAVA_CLIENT_ID=<paste_from_strava>
STRAVA_CLIENT_SECRET=<paste_from_strava>
STRAVA_VERIFY_TOKEN=mysecretverifytoken123
GARMIN_CONSUMER_KEY=<paste_from_garmin>
GARMIN_CONSUMER_SECRET=<paste_from_garmin>
```

For **safestride-oauth**:

```bash
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<paste_from_supabase>
STRAVA_CLIENT_ID=<paste_from_strava>
STRAVA_CLIENT_SECRET=<paste_from_strava>
STRAVA_REDIRECT_URI=https://safestride-oauth.onrender.com/strava/callback
```

**Important**: Update `STRAVA_REDIRECT_URI` with your actual Render URL after deployment!

### Step 4: Verify Deployment

Wait 3-5 minutes for build and deployment. Then test:

```bash
# Test Main API
curl https://safestride-api.onrender.com/health

# Test Webhooks Service
curl https://safestride-webhooks.onrender.com/health

# Test OAuth Service
curl https://safestride-oauth.onrender.com/health
```

Expected response:

```json
{ "status": "healthy", "timestamp": "2025-01-28T..." }
```

### Step 5: Update Strava Configuration

1. Go to [Strava Settings](https://www.strava.com/settings/api)
2. Update **Authorization Callback Domain**:

   ```
   safestride-oauth.onrender.com
   ```

3. Register webhook subscription:

   ```bash
   curl -X POST https://www.strava.com/api/v3/push_subscriptions \
     -F client_id=YOUR_CLIENT_ID \
     -F client_secret=YOUR_CLIENT_SECRET \
     -F callback_url=https://safestride-webhooks.onrender.com/webhooks/strava \
     -F verify_token=mysecretverifytoken123
   ```

4. Save the subscription ID returned

### Step 6: Test Complete Flow

```bash
# 1. Create test athlete
curl -X POST https://safestride-api.onrender.com/athletes/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "age": 30,
    "gender": "M",
    "weight_kg": 70,
    "height_cm": 175,
    "email": "test@example.com"
  }'

# 2. Get athlete ID from response, then connect Strava
# Visit in browser:
https://safestride-oauth.onrender.com/strava/connect?athlete_id=<athlete_id>

# 3. Complete OAuth flow
# 4. Run a workout on Strava
# 5. Check webhook received:
curl https://safestride-api.onrender.com/workouts/results/<athlete_id>
```

---

## 📱 Part 2: Flutter Mobile App Deployment

### Step 1: Update API URLs in Flutter

1. Open `lib/config/api_config.dart`
2. Update base URLs:
   ```dart
   class ApiConfig {
     static const String baseUrl = 'https://safestride-api.onrender.com';
     static const String webhooksUrl = 'https://safestride-webhooks.onrender.com';
     static const String oauthUrl = 'https://safestride-oauth.onrender.com';
   }
   ```

### Step 2: iOS Build & Deployment

#### Prerequisites

- Xcode 15+ installed
- Apple Developer account ($99/year)
- Valid provisioning profiles

#### Build Steps

1. **Configure iOS signing**:

   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **In Xcode**:
   - Select Runner target
   - Update Bundle Identifier: `com.safestride.app`
   - Select your Team
   - Enable "Automatically manage signing"

3. **Build for App Store**:

   ```bash
   cd ..
   flutter build ipa --release
   ```

4. **Upload to App Store Connect**:

   ```bash
   # Option 1: Via Xcode
   open build/ios/archive/Runner.xcarchive

   # Option 2: Via Transporter app
   # Download from Mac App Store
   # Upload build/ios/ipa/safestride.ipa
   ```

5. **Submit for Review**:
   - Go to [App Store Connect](https://appstoreconnect.apple.com/)
   - Create new app: SafeStride AI
   - Fill app information, screenshots, description
   - Submit for review (7-14 days)

### Step 3: Android Build & Deployment

#### Prerequisites

- Android Studio installed
- Google Play Developer account ($25 one-time)
- Signing key generated

#### Build Steps

1. **Generate signing key**:

   ```bash
   keytool -genkey -v -keystore ~/safestride-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias safestride
   ```

2. **Configure signing** in `android/key.properties`:

   ```properties
   storePassword=<your_password>
   keyPassword=<your_password>
   keyAlias=safestride
   storeFile=C:/Users/<you>/safestride-release-key.jks
   ```

3. **Update `android/app/build.gradle`**:

   ```gradle
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
           storePassword keystoreProperties['storePassword']
       }
   }

   buildTypes {
       release {
           signingConfig signingConfigs.release
       }
   }
   ```

4. **Build App Bundle**:

   ```bash
   flutter build appbundle --release
   ```

5. **Upload to Google Play Console**:
   - Go to [Google Play Console](https://play.google.com/console/)
   - Create new app: SafeStride AI
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Fill app information, screenshots, description
   - Submit for review (1-7 days)

### Step 4: Beta Testing (Recommended First)

#### iOS TestFlight

1. In App Store Connect, go to TestFlight
2. Add internal testers (up to 100)
3. Distribute build
4. Collect feedback for 2-4 weeks

#### Android Internal Testing

1. In Google Play Console, go to Internal Testing
2. Add tester emails (up to 100)
3. Distribute release
4. Collect feedback for 2-4 weeks

---

## 🌐 Part 3: Frontend Web App (Optional)

### Option A: GitHub Pages (Static Site)

1. Create `docs/` folder in repository
2. Build static site:

   ```bash
   flutter build web --release
   cp -r build/web/* docs/
   ```

3. Enable GitHub Pages:
   - Go to repository Settings
   - Pages → Source: `main` branch, `/docs` folder
   - Save

4. Access at: `https://<username>.github.io/safestride/`

### Option B: Netlify (Recommended)

1. Sign up at [Netlify](https://www.netlify.com/)
2. Connect GitHub repository
3. Build settings:
   - Build command: `flutter build web --release`
   - Publish directory: `build/web`
4. Deploy
5. Custom domain (optional): `app.safestride.ai`

---

## 📊 Part 4: Monitoring & Analytics

### 1. Render Monitoring

- View logs in Render dashboard
- Set up alerting for service failures
- Monitor response times

### 2. Supabase Monitoring

- Database performance metrics
- Query analysis
- Connection pooling

### 3. Application Monitoring (Optional)

Install Sentry for error tracking:

```bash
# Add to requirements.txt
sentry-sdk[fastapi]==1.40.0

# In each service:
import sentry_sdk
sentry_sdk.init(
    dsn=os.getenv("SENTRY_DSN"),
    traces_sample_rate=0.1
)
```

### 4. Analytics (Optional)

- Google Analytics for web/mobile
- Mixpanel for user behavior
- PostHog for product analytics

---

## 🔐 Security Checklist

- [ ] All API keys stored as environment variables (not in code)
- [ ] HTTPS enabled for all services
- [ ] CORS configured correctly
- [ ] Rate limiting enabled (consider Cloudflare)
- [ ] Input validation on all endpoints
- [ ] Database RLS (Row Level Security) enabled in Supabase
- [ ] OAuth tokens encrypted in database
- [ ] Regular security audits

---

## 💰 Cost Breakdown

### Free Tier (0-50 users)

- **Render**: $0 (3 services × free tier)
- **Supabase**: $0 (free tier: 500 MB, 50k API requests/month)
- **Domain**: $12/year (optional)
- **Total**: ~$1/month

### Paid Tier (50-500 users)

- **Render**: $21/month (3 services × $7)
- **Supabase**: $25/month (Pro plan)
- **Domain**: $12/year
- **Total**: ~$47/month

### Scale Tier (500+ users)

- **Render**: ~$100/month (standard plans + scaling)
- **Supabase**: $25-100/month (based on usage)
- **CDN**: $20/month (Cloudflare Pro)
- **Monitoring**: $29/month (Sentry)
- **Total**: ~$175-250/month

---

## 🚨 Troubleshooting

### API Service Won't Start

```bash
# Check Render logs
# Common issues:
1. Missing environment variables
2. Invalid Supabase key
3. Build failed (check requirements.txt)
4. Port already in use
```

### Strava Webhook Not Receiving Events

```bash
# Verify webhook subscription:
curl https://www.strava.com/api/v3/push_subscriptions \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Check callback URL matches:
https://safestride-webhooks.onrender.com/webhooks/strava
```

### Mobile App Build Fails

```bash
# Clear build cache:
flutter clean
flutter pub get
flutter build <ios|appbundle> --release

# Check native logs:
# iOS: Xcode → Product → Build
# Android: Build → Flutter → View Flutter Console
```

### Database Connection Timeout

```bash
# Check Supabase status
# Verify SUPABASE_URL and SUPABASE_SERVICE_KEY
# Check connection pooling settings
# Consider upgrading Supabase plan
```

---

## 📈 Post-Deployment Tasks

### Week 1

- [ ] Monitor service health daily
- [ ] Test complete user journey (signup → connect Strava → sync activities)
- [ ] Verify webhook delivery
- [ ] Check database performance

### Week 2

- [ ] Onboard 5-10 beta users
- [ ] Collect feedback
- [ ] Monitor error rates
- [ ] Optimize slow queries

### Week 3-4

- [ ] Scale to 15 pilot users
- [ ] Implement user feedback
- [ ] Add monitoring dashboards
- [ ] Document common issues

### Month 2+

- [ ] Public beta launch
- [ ] Marketing & growth
- [ ] Feature iterations
- [ ] Scale infrastructure

---

## 📞 Support & Resources

- **Documentation**: See `IMPLEMENTATION_SUMMARY.md`
- **Strava Integration**: See `STRAVA_GARMIN_INTEGRATION_GUIDE.md`
- **API Reference**: See `api_endpoints.py` docstrings
- **Database Schema**: See `database_canonical/` folder

---

## 🎉 Success Criteria

Your deployment is successful when:

✅ All 3 Render services show "healthy" status
✅ API health endpoint returns 200 OK
✅ Strava OAuth flow completes successfully
✅ Webhook receives and processes activities
✅ Mobile app connects to API
✅ Database operations complete successfully
✅ Users can complete full signup → workout → analysis flow

---

## 🚀 Next Steps

After successful deployment:

1. **15-Athlete Pilot Program**
   - Recruit diverse runners (beginner to advanced)
   - Onboard with Strava connections
   - Monitor for 4-8 weeks
   - Collect detailed feedback

2. **Feature Enhancements**
   - Real-time coaching notifications
   - Social features (challenges, leaderboards)
   - Advanced analytics dashboards
   - Injury prevention alerts

3. **Scale & Optimize**
   - Implement caching (Redis)
   - Optimize database queries
   - Add CDN for static assets
   - Set up auto-scaling

---

**🏃 Ready to deploy? Let's go!**

Start with Part 1 (Backend Deployment) and work through each section systematically. Good luck! 🚀
