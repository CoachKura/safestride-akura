# 🚀 SafeStride AI - Deployment Action Plan

**Date**: February 25, 2026  
**Status**: Ready to Execute All Options (1, 2, 3)

---

## 📋 Executive Summary

You've chosen to execute all three deployment options simultaneously:

- ✅ **Option 1**: Deploy Backend Now (30 min)
- ✅ **Option 2**: Full Platform Deployment (1-2 days)
- ✅ **Option 3**: Comprehensive Review & Planning

This action plan provides step-by-step instructions to execute all three in parallel.

---

## 🎯 Phase 1: Backend Deployment to Render (IMMEDIATE - 30 min)

### Step 1.1: Get Supabase Credentials (5 min)

1. **Login to Supabase**:

   ```
   URL: https://app.supabase.com/project/bdisppaxbvygsspcuymb
   ```

2. **Get your Service Key**:
   - Go to Settings → API
   - Copy the `service_role` key (starts with `eyJ...`)
   - ⚠️ **Keep this secret!** Never commit to Git

3. **Verify Database Connection**:
   - Settings → Database → Connection string
   - Should be: `https://bdisppaxbvygsspcuymb.supabase.co`

### Step 1.2: Get Strava API Credentials (10 min)

1. **Login to Strava**:

   ```
   URL: https://www.strava.com/settings/api
   ```

2. **Get your credentials** (or create app if needed):
   - Client ID (numeric)
   - Client Secret (40 characters)
   - Create a verify token: `safestride_webhook_verify_2026`

3. **Note your Application ID** for later webhook registration

### Step 1.3: Deploy to Render (15 min)

**🔗 FOLLOW THESE EXACT STEPS**:

1. **Connect GitHub to Render**:

   ```
   1. Go to: https://dashboard.render.com/
   2. Click "New" → "Blueprint"
   3. Connect GitHub account
   4. Select repository: safestride
   5. Render will detect render.yaml
   6. Review 3 services:
      - safestride-api
      - safestride-webhooks
      - safestride-oauth
   7. Click "Apply"
   ```

2. **Wait for Initial Build** (3-5 min per service):
   - Watch the logs in Render dashboard
   - Services will initially fail (missing env vars - expected!)

3. **Configure Environment Variables**:

   **For safestride-api**:

   ```
   Go to service → Environment → Add Environment Variable:

   SUPABASE_URL = https://bdisppaxbvygsspcuymb.supabase.co
   SUPABASE_SERVICE_KEY = [PASTE YOUR SERVICE KEY]
   ```

   Click "Save Changes" → Service will auto-redeploy

   **For safestride-webhooks**:

   ```
   SUPABASE_URL = https://bdisppaxbvygsspcuymb.supabase.co
   SUPABASE_SERVICE_KEY = [PASTE YOUR SERVICE KEY]
   STRAVA_CLIENT_ID = [PASTE YOUR CLIENT ID]
   STRAVA_CLIENT_SECRET = [PASTE YOUR CLIENT SECRET]
   STRAVA_VERIFY_TOKEN = safestride_webhook_verify_2026
   ```

   Click "Save Changes" → Service will auto-redeploy

   **For safestride-oauth**:

   ```
   SUPABASE_URL = https://bdisppaxbvygsspcuymb.supabase.co
   SUPABASE_SERVICE_KEY = [PASTE YOUR SERVICE KEY]
   STRAVA_CLIENT_ID = [PASTE YOUR CLIENT ID]
   STRAVA_CLIENT_SECRET = [PASTE YOUR CLIENT SECRET]
   STRAVA_REDIRECT_URI = https://safestride-oauth.onrender.com/strava/callback
   ```

   ⚠️ **IMPORTANT**: After deployment, update STRAVA_REDIRECT_URI with the actual Render URL!

4. **Get Your Service URLs**:

   ```
   From Render dashboard, copy the URLs for each service:

   safestride-api: https://safestride-api-XXXX.onrender.com
   safestride-webhooks: https://safestride-webhooks-XXXX.onrender.com
   safestride-oauth: https://safestride-oauth-XXXX.onrender.com
   ```

5. **Update STRAVA_REDIRECT_URI**:
   ```
   Go back to safestride-oauth → Environment
   Update STRAVA_REDIRECT_URI with your actual URL
   Save → Service redeploys
   ```

### Step 1.4: Verify Deployment (5 min)

Test each service:

```powershell
# Test Main API
curl https://safestride-api-XXXX.onrender.com/health

# Test Webhooks
curl https://safestride-webhooks-XXXX.onrender.com/health

# Test OAuth
curl https://safestride-oauth-XXXX.onrender.com/health
```

**Expected Response**:

```json
{ "status": "healthy", "timestamp": "2026-02-25T..." }
```

### Step 1.5: Register Strava Webhook (5 min)

```powershell
# Replace with your actual values
curl -X POST https://www.strava.com/api/v3/push_subscriptions `
  -F client_id=YOUR_CLIENT_ID `
  -F client_secret=YOUR_CLIENT_SECRET `
  -F callback_url=https://safestride-webhooks-XXXX.onrender.com/webhooks/strava `
  -F verify_token=safestride_webhook_verify_2026
```

**Save the subscription ID** returned in the response!

### ✅ Phase 1 Complete Checklist

- [ ] Supabase service key obtained
- [ ] Strava API credentials obtained
- [ ] Render account connected to GitHub
- [ ] 3 services deployed from render.yaml
- [ ] All environment variables configured
- [ ] All services show "Live" status
- [ ] Health endpoints return 200 OK
- [ ] Strava webhook registered
- [ ] Webhook subscription ID saved

---

## 📱 Phase 2: Mobile App Deployment (1-2 hours setup)

### Step 2.1: Update Flutter API Configuration (10 min)

**Create API config file**:

```powershell
# Save your Render URLs
$API_URL = "https://safestride-api-XXXX.onrender.com"
$WEBHOOKS_URL = "https://safestride-webhooks-XXXX.onrender.com"
$OAUTH_URL = "https://safestride-oauth-XXXX.onrender.com"
```

Now create the Flutter config file:

```dart
// File: lib/config/api_config.dart

class ApiConfig {
  // Production API URLs (from Render)
  static const String baseUrl = 'https://safestride-api-XXXX.onrender.com';
  static const String webhooksUrl = 'https://safestride-webhooks-XXXX.onrender.com';
  static const String oauthUrl = 'https://safestride-oauth-XXXX.onrender.com';

  // API Endpoints
  static const String signupEndpoint = '/athletes/signup';
  static const String profileEndpoint = '/athletes';
  static const String raceAnalysisEndpoint = '/races/analyze';
  static const String fitnessEndpoint = '/fitness';
  static const String workoutsEndpoint = '/workouts';
  static const String workoutCompleteEndpoint = '/workouts/complete';
  static const String resultsEndpoint = '/workouts/results';
  static const String abilityEndpoint = '/ability';
  static const String stravaConnectEndpoint = '/strava/connect';
  static const String stravaStatusEndpoint = '/strava/status';
  static const String stravaDisconnectEndpoint = '/strava/disconnect';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Environment
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  // Full endpoint URLs
  static String get signupUrl => '$baseUrl$signupEndpoint';
  static String get healthUrl => '$baseUrl/health';

  static String profileUrl(String athleteId) => '$baseUrl$profileEndpoint/$athleteId';
  static String fitnessUrl(String athleteId) => '$baseUrl$fitnessEndpoint/$athleteId';
  static String workoutsUrl(String athleteId) => '$baseUrl$workoutsEndpoint/$athleteId';
  static String resultsUrl(String athleteId) => '$baseUrl$resultsEndpoint/$athleteId';
  static String abilityUrl(String athleteId) => '$baseUrl$abilityEndpoint/$athleteId';
  static String stravaStatusUrl(String athleteId) => '$oauthUrl$stravaStatusEndpoint/$athleteId';

  static String stravaConnectUrl(String athleteId) =>
    '$oauthUrl$stravaConnectEndpoint?athlete_id=$athleteId';
}
```

**Replace XXXX with your actual Render URLs**!

### Step 2.2: iOS Setup (macOS Required)

**Prerequisites**:

- [ ] Xcode 15+ installed
- [ ] Apple Developer account active ($99/year)
- [ ] Valid payment method on file

**Steps**:

1. **Open Xcode Project**:

   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Configure Signing**:
   - Select Runner target (top left)
   - Go to "Signing & Capabilities" tab
   - Team: Select your Apple Developer team
   - ✅ Enable "Automatically manage signing"
   - Bundle Identifier: `com.safestride.app`

3. **Update App Info** (Runner target → General):
   - Display Name: `SafeStride AI`
   - Version: `1.0.0`
   - Build: `1`
   - Minimum Deployments: `iOS 13.0`

4. **Build for Testing**:

   ```bash
   cd ..
   flutter clean
   flutter pub get
   cd ios && pod install --repo-update
   cd ..
   flutter build ios --release --no-codesign
   ```

5. **Archive & Upload** (in Xcode):
   - Product → Archive
   - Wait for archive to complete
   - Window → Organizer
   - Select latest archive
   - Click "Distribute App"
   - Select "App Store Connect"
   - Upload

6. **TestFlight Setup** (App Store Connect):
   - Go to: https://appstoreconnect.apple.com/
   - Apps → Create new app
   - Name: SafeStride AI
   - Bundle ID: com.safestride.app
   - Wait for build to appear in TestFlight (10-20 min)
   - Add internal testers
   - Distribute build

### Step 2.3: Android Setup

**Prerequisites**:

- [ ] Android Studio installed
- [ ] Google Play Developer account ($25 one-time)
- [ ] Valid payment method

**Steps**:

1. **Generate Signing Key** (one-time):

   ```powershell
   keytool -genkey -v -keystore $env:USERPROFILE\safestride-release-key.jks `
     -keyalg RSA -keysize 2048 -validity 10000 `
     -alias safestride

   # Enter password (SAVE THIS!)
   # Enter your details (name, organization, etc.)
   ```

2. **Create Key Properties**:

   ```powershell
   # Create android/key.properties
   @"
   storePassword=YOUR_PASSWORD_HERE
   keyPassword=YOUR_PASSWORD_HERE
   keyAlias=safestride
   storeFile=$env:USERPROFILE\safestride-release-key.jks
   "@ | Out-File -FilePath android\key.properties -Encoding UTF8
   ```

3. **Update build.gradle** (android/app/build.gradle):

   ```gradle
   // Add at top of file (before android block)
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       // ... existing config ...

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
   }
   ```

4. **Build App Bundle**:

   ```powershell
   flutter clean
   flutter pub get
   flutter build appbundle --release

   # Output: build\app\outputs\bundle\release\app-release.aab
   ```

5. **Upload to Play Console**:
   - Go to: https://play.google.com/console/
   - Create new application
   - Name: SafeStride AI
   - Upload AAB file
   - Complete store listing
   - Create Internal Testing track
   - Add testers
   - Publish to Internal Testing

### ✅ Phase 2 Complete Checklist

- [ ] API config created with Render URLs
- [ ] iOS: Xcode configured with signing
- [ ] iOS: TestFlight build uploaded
- [ ] iOS: 5-10 internal testers added
- [ ] Android: Signing key generated & saved
- [ ] Android: key.properties created
- [ ] Android: App bundle built successfully
- [ ] Android: Uploaded to Play Console
- [ ] Android: Internal Testing track created
- [ ] Android: 5-10 testers added

---

## 🔍 Phase 3: Comprehensive Review & Testing

### Step 3.1: End-to-End API Testing (15 min)

**Test the complete user journey**:

```powershell
# Set your API URL
$API_URL = "https://safestride-api-XXXX.onrender.com"

# 1. Create test athlete
$athleteResponse = Invoke-RestMethod -Uri "$API_URL/athletes/signup" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    name = "Test User"
    age = 30
    gender = "M"
    weight_kg = 70
    height_cm = 175
    email = "test@safestride.example"
  } | ConvertTo-Json)

$athleteId = $athleteResponse.athlete_id
Write-Host "✅ Athlete created: $athleteId"

# 2. Test race analysis
$raceResponse = Invoke-RestMethod -Uri "$API_URL/races/analyze" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    athlete_id = $athleteId
    race_type = "HALF_MARATHON"
    finish_time_seconds = 7935
    race_date = "2026-01-01"
  } | ConvertTo-Json)

Write-Host "✅ Race analyzed: $($raceResponse.classification)"

# 3. Test fitness assessment
$fitnessResponse = Invoke-RestMethod -Uri "$API_URL/fitness/$athleteId"
Write-Host "✅ Fitness assessed: $($fitnessResponse.overall_fitness_score)/100"

# 4. Test workout retrieval
$workoutsResponse = Invoke-RestMethod -Uri "$API_URL/workouts/$athleteId"
Write-Host "✅ Workouts retrieved: $($workoutsResponse.Count) workouts"

# 5. Test Strava OAuth initiation
$stravaResponse = Invoke-RestMethod -Uri "$OAUTH_URL/strava/connect?athlete_id=$athleteId"
Write-Host "✅ Strava OAuth URL: $($stravaResponse.authorize_url)"

Write-Host "`n🎉 All API tests passed!"
```

### Step 3.2: Mobile App Testing Checklist

**iOS (TestFlight)**:

- [ ] Install TestFlight app on iPhone
- [ ] Accept invitation email
- [ ] Install SafeStride AI beta
- [ ] Complete onboarding flow
- [ ] Create profile
- [ ] Test Strava connection
- [ ] Verify UI/UX flows
- [ ] Check for crashes
- [ ] Test on multiple iOS versions (13, 14, 15, 16, 17)

**Android (Internal Testing)**:

- [ ] Open Play Store link
- [ ] Join testing program
- [ ] Install SafeStride AI
- [ ] Complete onboarding flow
- [ ] Create profile
- [ ] Test Strava connection
- [ ] Verify UI/UX flows
- [ ] Check for crashes
- [ ] Test on multiple Android versions (9, 10, 11, 12, 13, 14)

### Step 3.3: Integration Testing Checklist

**Strava Integration**:

- [ ] User connects Strava account (OAuth flow)
- [ ] Authorization completes successfully
- [ ] Tokens stored in database
- [ ] Upload activity to Strava
- [ ] Webhook receives activity event
- [ ] Activity fetched from Strava API
- [ ] Activity parsed correctly
- [ ] Assignment matched (if exists)
- [ ] Performance analyzed
- [ ] Results stored in database
- [ ] Ability progression updated
- [ ] Next workout generated

**Database Operations**:

- [ ] Athlete profile CRUD works
- [ ] Race history stored correctly
- [ ] Workout assignments created
- [ ] Workout results recorded
- [ ] Ability progression tracked
- [ ] Strava tokens managed properly

### Step 3.4: Performance & Monitoring

**Backend Performance**:

```powershell
# Test response times
Measure-Command {
  Invoke-RestMethod -Uri "$API_URL/health"
} | Select-Object TotalMilliseconds

# Should be < 500ms for health check
# Should be < 2000ms for complex operations
```

**Monitor in Render Dashboard**:

- [ ] View logs for each service
- [ ] Check for errors or warnings
- [ ] Monitor response times
- [ ] Track memory usage
- [ ] Set up email alerts

**Monitor in Supabase Dashboard**:

- [ ] Check database size
- [ ] Monitor query performance
- [ ] Review slow queries
- [ ] Check connection pooling
- [ ] Set up usage alerts

### ✅ Phase 3 Complete Checklist

- [ ] Complete API workflow tested
- [ ] All endpoints responding correctly
- [ ] iOS TestFlight app installed & tested
- [ ] Android Internal Testing app installed & tested
- [ ] Strava integration working end-to-end
- [ ] Database operations verified
- [ ] Performance metrics acceptable
- [ ] Monitoring dashboards configured
- [ ] No critical errors in logs

---

## 🎯 Next: 15-Athlete Pilot Program

Once Phases 1-3 are complete, proceed to pilot program:

### Pilot Program Timeline

**Week 0: Recruitment** (3-5 days)

- [ ] Identify 15 diverse athletes:
  - 3-5 beginners (new to running)
  - 5-7 intermediate (run regularly)
  - 3-5 advanced (race experience)
- [ ] Recruit via running clubs, social media, personal network
- [ ] Get commitment for 4-8 weeks

**Week 1: Onboarding** (intensive)

- [ ] Send welcome email with instructions
- [ ] 1-on-1 onboarding calls
- [ ] Help create profiles
- [ ] Guide Strava connection
- [ ] Explain app features
- [ ] Set expectations

**Weeks 2-4: Active Monitoring**

- [ ] Daily check of activity sync
- [ ] Monitor workout completion rates
- [ ] Respond to questions quickly (< 24h)
- [ ] Collect feedback weekly
- [ ] Log all bugs and issues
- [ ] Track feature requests

**Weeks 5-8: Iteration**

- [ ] Fix critical bugs
- [ ] Implement quick wins
- [ ] Continue monitoring
- [ ] Prepare final survey
- [ ] Collect testimonials

**Week 9: Analysis & Planning**

- [ ] Calculate metrics (retention, completion, satisfaction)
- [ ] Analyze feedback themes
- [ ] Prioritize improvements
- [ ] Plan next version
- [ ] Decide: scale or iterate

### Success Metrics

**Target KPIs**:

- User retention at 2 weeks: ≥ 80%
- Workout completion rate: ≥ 70%
- Activity sync success: ≥ 95%
- User satisfaction (1-10): ≥ 8.0
- Critical bugs: ≤ 2
- App crashes: < 1% of sessions

**Go/No-Go Decision**:

- ✅ **GO**: If 4+ metrics hit targets → Scale to 50 users
- ⚠️ **ITERATE**: If 2-3 metrics hit → Fix issues, run 2-week follow-up
- 🛑 **STOP**: If <2 metrics hit → Major pivot needed

---

## 📊 Cost Tracking

### Current Costs (Free Tier)

```
Render:         $0/month (3 services, free tier)
Supabase:       $0/month (free tier)
GitHub:         $0/month
Strava API:     $0/month
Apple Dev:      $8/month ($99/year amortized)
Google Play:    $2/month ($25 one-time amortized)
──────────────────────────────
TOTAL:          $10/month
```

### Expected Costs (50 Users)

```
Render:         $21/month (3 × $7 Starter)
Supabase:       $25/month (Pro plan)
Apple Dev:      $8/month
Google Play:    $0/month (one-time paid)
Domain:         $1/month
──────────────────────────────
TOTAL:          $55/month
```

---

## 🚨 Troubleshooting Guide

### Issue: Render Service Won't Start

**Check logs**:

```
Render Dashboard → Service → Logs
```

**Common fixes**:

1. Missing environment variable
   - Solution: Add via Environment tab
2. Invalid Supabase key
   - Solution: Copy service_role key from Supabase
3. Port binding issue
   - Solution: Services use PORT env var automatically
4. Build failed
   - Solution: Check requirements.txt, verify Python version

### Issue: Strava Webhook Not Receiving

**Verify subscription**:

```powershell
# Get access token first (from Strava OAuth)
$token = "YOUR_ACCESS_TOKEN"
Invoke-RestMethod -Uri "https://www.strava.com/api/v3/push_subscriptions" `
  -Headers @{Authorization = "Bearer $token"}
```

**Common fixes**:

1. Callback URL incorrect
   - Solution: Must match exact Render URL
2. Verify token mismatch
   - Solution: Must match token in env vars
3. Subscription not active
   - Solution: Re-register webhook

### Issue: Mobile App Build Fails

**iOS**:

```bash
# Clean everything
flutter clean
rm -rf ios/Pods ios/.symlinks ios/Podfile.lock
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter pub get
```

**Android**:

```powershell
flutter clean
Remove-Item -Recurse -Force build
flutter pub get
flutter build appbundle --release
```

### Issue: Database Connection Errors

**Check Supabase status**:

```
https://status.supabase.com/
```

**Verify credentials**:

1. Go to Supabase Dashboard → Settings → API
2. Copy URL (should be https://bdisppaxbvygsspcuymb.supabase.co)
3. Copy service_role key (starts with eyJ...)
4. Update in Render environment variables

---

## 📞 Support Resources

### Documentation

- 📖 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- 📖 [FLUTTER_DEPLOYMENT_GUIDE.md](FLUTTER_DEPLOYMENT_GUIDE.md)
- 📖 [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)
- 📖 [STRAVA_GARMIN_INTEGRATION_GUIDE.md](STRAVA_GARMIN_INTEGRATION_GUIDE.md)

### External Resources

- **Render**: https://render.com/docs
- **Supabase**: https://supabase.com/docs
- **Strava API**: https://developers.strava.com/docs
- **Flutter**: https://flutter.dev/docs
- **GitHub Actions**: https://docs.github.com/actions

### Community

- **Render Community**: https://community.render.com/
- **Supabase Discord**: https://discord.supabase.com/
- **Flutter Discord**: https://discord.gg/flutter

---

## ✅ Final Checklist

Before considering deployment complete:

**Backend**:

- [ ] All 3 services deployed and live
- [ ] Health checks passing
- [ ] Environment variables configured
- [ ] Strava webhook registered
- [ ] End-to-end API test passed

**Mobile Apps**:

- [ ] iOS TestFlight build available
- [ ] Android Internal Testing available
- [ ] API config updated with production URLs
- [ ] Testers invited and installed
- [ ] Basic flows tested on real devices

**Monitoring**:

- [ ] Render logs reviewed
- [ ] Supabase metrics checked
- [ ] Email alerts configured
- [ ] Error tracking set up (optional)

**Documentation**:

- [ ] Service URLs documented
- [ ] Environment variables saved securely
- [ ] Troubleshooting guide accessible
- [ ] Support process defined

**Pilot Program**:

- [ ] 15 athletes identified
- [ ] Onboarding materials ready
- [ ] Feedback mechanisms set up
- [ ] Success metrics defined

---

## 🎉 You're Ready to Launch!

**Current Status**: All deployment configurations ready ✅  
**Next Action**: Execute Phase 1 (Backend to Render) ⏭️  
**Timeline**: 30 min for Phase 1, then proceed to Phases 2 & 3

**Remember**:

- Start small (15 pilots)
- Iterate based on feedback
- Monitor closely in first week
- Scale gradually

---

**Let's get SafeStride AI into production!** 🚀🏃‍♂️

**Questions or issues?** Review the troubleshooting section or consult the detailed guides.

**Good luck!** 💪
