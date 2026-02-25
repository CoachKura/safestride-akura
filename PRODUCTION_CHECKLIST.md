# ✅ SafeStride AI - Production Deployment Checklist

## 📋 Pre-Deployment Preparation

### Environment Setup
- [ ] **Supabase Database** configured and accessible
  - URL: `https://bdisppaxbvygsspcuymb.supabase.co`
  - Service key obtained from Supabase dashboard
  - All 6 tables created successfully:
    - athlete_detailed_profile
    - baseline_assessment_plan
    - workout_assignments
    - workout_results
    - ability_progression
    - race_history

- [ ] **Strava Developer App** created
  - Client ID & Secret obtained
  - Authorization callback domain set
  - Webhook verify token generated

- [ ] **Garmin Developer App** created (optional)
  - Consumer key & secret obtained

- [ ] **Developer Accounts** active
  - Render.com account (free tier OK for start)
  - Apple Developer ($99/year for iOS)
  - Google Play Developer ($25 one-time for Android)
  - GitHub account with repository access

### Code Review
- [ ] All 11 production modules tested locally
  - race_analyzer.py ✅
  - fitness_analyzer.py ✅
  - performance_tracker.py ✅
  - adaptive_workout_generator.py ✅
  - database_integration.py ✅
  - api_endpoints.py ✅
  - activity_integration.py ✅
  - strava_oauth.py ✅
  - integration_test.py ✅
  - test_database_integration.py ✅
  - test_api_endpoints.py ✅

- [ ] All tests passing locally
  - Integration test: 6/6 stages ✅
  - Database integration test: 5/5 operations ✅
  - API test suite ready

- [ ] All code committed to Git
  - Latest commit: 887f142
  - All changes pushed to GitHub
  - No uncommitted changes

### Documentation Review
- [ ] Read DEPLOYMENT_GUIDE.md
- [ ] Read FLUTTER_DEPLOYMENT_GUIDE.md
- [ ] Read STRAVA_GARMIN_INTEGRATION_GUIDE.md
- [ ] Read IMPLEMENTATION_SUMMARY.md

---

## 🚀 Phase 1: Backend Deployment (Render)

### Step 1: Connect GitHub to Render
- [ ] Login to [Render.com](https://dashboard.render.com/)
- [ ] Click "New" → "Blueprint"
- [ ] Connect GitHub account
- [ ] Grant Render access to safestride repository
- [ ] Select repository from list

### Step 2: Deploy from Blueprint
- [ ] Render detects `render.yaml` automatically
- [ ] Review 3 SafeStride services:
  - safestride-api (Main API)
  - safestride-webhooks (Activity Integration)
  - safestride-oauth (OAuth Flow)
- [ ] Click "Apply" to create all services
- [ ] Wait for initial build (3-5 minutes per service)

### Step 3: Configure Environment Variables

For **safestride-api**:
```bash
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<PASTE_YOUR_SERVICE_KEY>
```

For **safestride-webhooks**:
```bash
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<PASTE_YOUR_SERVICE_KEY>
STRAVA_CLIENT_ID=<PASTE_YOUR_CLIENT_ID>
STRAVA_CLIENT_SECRET=<PASTE_YOUR_CLIENT_SECRET>
STRAVA_VERIFY_TOKEN=mysecretverifytoken123
GARMIN_CONSUMER_KEY=<PASTE_IF_AVAILABLE>
GARMIN_CONSUMER_SECRET=<PASTE_IF_AVAILABLE>
```

For **safestride-oauth**:
```bash
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=<PASTE_YOUR_SERVICE_KEY>
STRAVA_CLIENT_ID=<PASTE_YOUR_CLIENT_ID>
STRAVA_CLIENT_SECRET=<PASTE_YOUR_CLIENT_SECRET>
STRAVA_REDIRECT_URI=https://safestride-oauth.onrender.com/strava/callback
```

**Note**: Update STRAVA_REDIRECT_URI after getting actual Render URL!

- [ ] All environment variables set for safestride-api
- [ ] All environment variables set for safestride-webhooks
- [ ] All environment variables set for safestride-oauth
- [ ] Services redeployed after adding env vars

### Step 4: Verify Deployment

Test each service:

```bash
# Main API health check
curl https://safestride-api.onrender.com/health

# Webhooks service health check
curl https://safestride-webhooks.onrender.com/health

# OAuth service health check
curl https://safestride-oauth.onrender.com/health
```

Expected response:
```json
{"status":"healthy","timestamp":"2025-01-28T..."}
```

- [ ] safestride-api health check returns 200 OK
- [ ] safestride-webhooks health check returns 200 OK
- [ ] safestride-oauth health check returns 200 OK
- [ ] All services show "Live" status in Render dashboard

### Step 5: Update Strava Configuration

- [ ] Login to [Strava Settings](https://www.strava.com/settings/api)
- [ ] Update "Authorization Callback Domain":
  ```
  safestride-oauth.onrender.com
  ```
- [ ] Save changes
- [ ] Register webhook subscription:
  ```bash
  curl -X POST https://www.strava.com/api/v3/push_subscriptions \
    -F client_id=YOUR_CLIENT_ID \
    -F client_secret=YOUR_CLIENT_SECRET \
    -F callback_url=https://safestride-webhooks.onrender.com/webhooks/strava \
    -F verify_token=mysecretverifytoken123
  ```
- [ ] Save subscription ID from response
- [ ] Verify subscription active:
  ```bash
  curl https://www.strava.com/api/v3/push_subscriptions \
    -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
  ```

### Step 6: End-to-End API Test

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

# 2. Save athlete_id from response

# 3. Test race analysis
curl -X POST https://safestride-api.onrender.com/races/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": "<ATHLETE_ID>",
    "race_type": "HALF_MARATHON",
    "finish_time_seconds": 7935,
    "race_date": "2025-01-01"
  }'

# 4. Test fitness assessment
curl https://safestride-api.onrender.com/fitness/<ATHLETE_ID>

# 5. Test Strava connection
# Visit in browser:
# https://safestride-oauth.onrender.com/strava/connect?athlete_id=<ATHLETE_ID>
```

- [ ] Athlete signup successful
- [ ] Race analysis returns results
- [ ] Fitness assessment works
- [ ] Strava OAuth flow redirects correctly
- [ ] Full workflow tested end-to-end

---

## 📱 Phase 2: Flutter Mobile Deployment

### iOS Deployment

#### Prerequisites
- [ ] Xcode 15+ installed (macOS required)
- [ ] Apple Developer account active ($99/year)
- [ ] CocoaPods installed

#### Configuration
- [ ] Update API URLs in `lib/config/api_config.dart`
- [ ] Set Bundle ID: `com.safestride.app`
- [ ] Configure app icons (all sizes)
- [ ] Set up launch screen
- [ ] Configure Info.plist permissions

#### Build & Upload
- [ ] Open Xcode workspace: `ios/Runner.xcworkspace`
- [ ] Select Runner target
- [ ] Choose your Team (Apple Developer)
- [ ] Enable "Automatically manage signing"
- [ ] Build IPA: `flutter build ipa --release`
- [ ] Upload to App Store Connect via Transporter
- [ ] TestFlight build appears in App Store Connect

#### App Store Connect Setup
- [ ] Create new app: "SafeStride AI"
- [ ] Fill app information
- [ ] Upload screenshots (6.7", 5.5", 12.9" displays)
- [ ] Add app description & keywords
- [ ] Set privacy policy URL
- [ ] Set support URL
- [ ] Submit for TestFlight (Internal Testing first)
- [ ] Onboard 10-20 beta testers
- [ ] Collect feedback for 2 weeks
- [ ] Submit for App Store review (after beta)

### Android Deployment

#### Prerequisites
- [ ] Android Studio installed
- [ ] Google Play Developer account ($25 one-time)
- [ ] Java JDK installed

#### Configuration
- [ ] Update API URLs in `lib/config/api_config.dart`
- [ ] Generate signing key (save securely!)
- [ ] Create `android/key.properties`
- [ ] Update `android/app/build.gradle` with signing config
- [ ] Set applicationId: `com.safestride.app`
- [ ] Configure app icons (all densities)

#### Build & Upload
- [ ] Build App Bundle: `flutter build appbundle --release`
- [ ] Login to [Google Play Console](https://play.google.com/console/)
- [ ] Create new app: "SafeStride AI"
- [ ] Upload AAB: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Fill store listing
- [ ] Upload screenshots (phone & tablet)
- [ ] Add feature graphic (1024×500px)
- [ ] Set content rating
- [ ] Complete app content questionnaire
- [ ] Create Internal Testing release first
- [ ] Add 10-20 testers
- [ ] Collect feedback for 2 weeks
- [ ] Create Production release (after testing)

---

## 🌐 Phase 3: Frontend Web Deployment (Optional)

### Option A: GitHub Pages

- [ ] Create `docs/` folder in repository
- [ ] Build web app: `flutter build web --release`
- [ ] Copy build output: `cp -r build/web/* docs/`
- [ ] Commit and push to GitHub
- [ ] Enable GitHub Pages in repository settings
- [ ] Set source: `main` branch, `/docs` folder
- [ ] Access at: `https://<username>.github.io/safestride/`

### Option B: Netlify (Recommended)

- [ ] Sign up at [Netlify.com](https://www.netlify.com/)
- [ ] Connect GitHub repository
- [ ] Set build command: `flutter build web --release`
- [ ] Set publish directory: `build/web`
- [ ] Deploy
- [ ] Configure custom domain (optional): `app.safestride.ai`

---

## 🔐 Phase 4: Security & Monitoring

### Security
- [ ] All API keys stored as environment variables (not in code)
- [ ] HTTPS enabled for all services (Render does this automatically)
- [ ] CORS configured correctly in FastAPI
- [ ] Supabase RLS (Row Level Security) policies enabled
- [ ] OAuth tokens encrypted in database
- [ ] Rate limiting considered (Cloudflare or similar)
- [ ] Input validation on all API endpoints

### Monitoring Setup
- [ ] Render dashboard monitoring configured
- [ ] Email alerts for service failures
- [ ] Supabase database metrics reviewed
- [ ] Optional: Sentry for error tracking
- [ ] Optional: Google Analytics for mobile apps
- [ ] Optional: Mixpanel for user behavior

### Logging
- [ ] View logs in Render dashboard for each service
- [ ] Set up log retention policy
- [ ] Configure log alerts for critical errors
- [ ] Monitor API response times
- [ ] Track database query performance

---

## 🧪 Phase 5: Beta Testing & Validation

### Backend Testing
- [ ] Test all 13 API endpoints with real data
- [ ] Complete athlete signup workflow
- [ ] Test race analysis with various race times
- [ ] Verify workout generation
- [ ] Test performance tracking
- [ ] Verify adaptive workout generation
- [ ] Test Strava OAuth flow end-to-end
- [ ] Verify webhook receives activities
- [ ] Test activity processing and analysis
- [ ] Confirm database updates correctly

### Mobile App Testing
- [ ] Install TestFlight build (iOS) or Internal Testing (Android)
- [ ] Test onboarding flow
- [ ] Test profile creation
- [ ] Test Strava connection
- [ ] Test activity sync
- [ ] Test workout viewing
- [ ] Test performance charts
- [ ] Test push notifications (if implemented)
- [ ] Test deep links
- [ ] Test offline functionality

### User Acceptance Testing
- [ ] Recruit 5-10 beta testers
- [ ] Onboard each user with clear instructions
- [ ] Monitor usage for 2 weeks
- [ ] Collect feedback via survey
- [ ] Track error rates and crashes
- [ ] Identify common issues
- [ ] Prioritize bug fixes and improvements

---

## 📈 Phase 6: Launch Preparation

### Documentation
- [ ] User guide created
- [ ] FAQ document prepared
- [ ] Troubleshooting guide available
- [ ] Support email setup: support@safestride.ai
- [ ] Privacy policy published
- [ ] Terms of service published

### Marketing Materials
- [ ] App Store screenshots finalized (5-8 per platform)
- [ ] Feature graphics created
- [ ] App preview videos recorded (optional but recommended)
- [ ] Landing page created (if applicable)
- [ ] Social media assets prepared
- [ ] Press release drafted (optional)

### Support Infrastructure
- [ ] Support email monitored daily
- [ ] Response templates prepared for common questions
- [ ] Bug tracking system setup (GitHub Issues)
- [ ] Feedback collection method established
- [ ] User onboarding email sequence ready

---

## 🚀 Phase 7: Launch Day

### Pre-Launch (Day -1)
- [ ] Final smoke tests on all services
- [ ] All team members briefed
- [ ] Support systems ready
- [ ] Monitoring dashboards open
- [ ] Rollback plan documented

### Launch Day (Day 0)
- [ ] Announce on social media (if applicable)
- [ ] Send launch email to beta testers
- [ ] Monitor error rates closely (every 2 hours)
- [ ] Track user signups
- [ ] Respond to reviews within 24 hours
- [ ] Fix critical bugs immediately

### Post-Launch (Day 1-7)
- [ ] Daily monitoring of all services
- [ ] Track user retention
- [ ] Collect and categorize feedback
- [ ] Prioritize feature requests
- [ ] Release bug fix updates as needed
- [ ] Celebrate the launch! 🎉

---

## 📊 Phase 8: 15-Athlete Pilot Program

### Recruitment
- [ ] Identify diverse runner profiles:
  - 3-5 beginners (never run before)
  - 5-7 intermediate (run regularly)
  - 3-5 advanced (race experience)
- [ ] Recruit via running clubs, social media, or personal network
- [ ] Ensure geographic diversity if possible
- [ ] Get commitment for 4-8 week participation

### Onboarding
- [ ] Send welcome email with instructions
- [ ] Help each athlete create profile
- [ ] Guide through race history upload
- [ ] Assist with Strava connection
- [ ] Explain how to use the app
- [ ] Set expectations for feedback

### Monitoring (Weeks 1-8)
- [ ] Week 1: Daily check-ins
- [ ] Week 2-4: 2x per week check-ins
- [ ] Week 5-8: Weekly check-ins
- [ ] Track activity sync completion rate
- [ ] Monitor workout completion rate
- [ ] Collect qualitative feedback
- [ ] Log all bugs and issues
- [ ] Track feature requests

### Analysis
- [ ] Calculate key metrics:
  - User retention rate
  - Activity sync success rate
  - Workout completion rate
  - Average session duration
  - User satisfaction score (1-10)
- [ ] Identify top 3 pain points
- [ ] Prioritize improvements
- [ ] Plan next iteration

---

## ✅ Success Criteria

Your deployment is successful when:

✅ **Backend**
- All 3 Render services show "Live" status
- Health endpoints return 200 OK
- API endpoints respond correctly
- Strava OAuth flow completes
- Webhooks receive and process activities
- Database operations succeed
- No critical errors in logs

✅ **Mobile Apps**
- iOS TestFlight build installed successfully
- Android Internal Testing build installed successfully
- App launches without crashes
- Users can complete signup
- Strava connection works
- Activities sync automatically
- Workouts display correctly
- Performance charts render

✅ **User Journey**
- Athlete can sign up
- Race analysis provides results
- Fitness assessment generates timeline
- Training plan created (14 days)
- User connects Strava account
- Activities sync automatically
- Performance tracked correctly
- Adaptive workouts generated

✅ **Beta Testing**
- 15 pilot athletes onboarded
- At least 80% retention after 2 weeks
- At least 70% workout completion rate
- Average satisfaction score ≥ 7/10
- Feedback collected from all users
- Critical bugs identified and fixed

---

## 🎯 Post-Launch Roadmap

### Month 1
- [ ] Fix all critical bugs from pilot
- [ ] Implement top 3 feature requests
- [ ] Optimize slow database queries
- [ ] Improve app performance
- [ ] Update documentation based on feedback

### Month 2
- [ ] Scale to 50 users (if pilot successful)
- [ ] Add real-time coaching notifications
- [ ] Improve UI/UX based on feedback
- [ ] Add more detailed analytics
- [ ] Optimize infrastructure costs

### Month 3
- [ ] Public beta launch (100+ users)
- [ ] Marketing campaign
- [ ] Content creation (blog, videos)
- [ ] Community building (Discord, Reddit)
- [ ] Partnership outreach (running clubs)

### Month 4+
- [ ] Production launch (open to all)
- [ ] App Store & Google Play feature requests
- [ ] Scale infrastructure as needed
- [ ] Continuous feature development
- [ ] Build sustainable business model

---

## 🆘 Emergency Contacts & Resources

### Critical Issues
- **Backend Down**: Check Render dashboard → Logs → Restart service
- **Database Issues**: Check Supabase dashboard → Database → Logs
- **Strava API Errors**: Check Strava API status page
- **App Store Rejection**: Review guidelines → Fix issues → Resubmit

### Documentation
- 📖 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete deployment walkthrough
- 📖 [FLUTTER_DEPLOYMENT_GUIDE.md](FLUTTER_DEPLOYMENT_GUIDE.md) - Mobile app details
- 📖 [STRAVA_GARMIN_INTEGRATION_GUIDE.md](STRAVA_GARMIN_INTEGRATION_GUIDE.md) - Integration setup
- 📖 [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - System architecture

### Support Resources
- Render Support: [render.com/docs](https://render.com/docs)
- Supabase Support: [supabase.com/docs](https://supabase.com/docs)
- Strava API: [developers.strava.com/docs](https://developers.strava.com/docs)
- Flutter Docs: [flutter.dev/docs](https://flutter.dev/docs)

---

## 💰 Cost Tracking

### Current Costs (Free Tier)
- Render: $0 (3 services on free tier)
- Supabase: $0 (free tier)
- GitHub: $0
- **Total**: $0/month

### Expected Costs (Paid Tier at 50+ users)
- Render: $21/month (3 × $7 Starter plan)
- Supabase: $25/month (Pro plan)
- Domain: $12/year (~$1/month)
- Apple Developer: $99/year (~$8/month)
- Google Play: $25 one-time
- **Total**: ~$55/month ongoing

### Scale Costs (500+ users)
- Render: ~$100/month (Standard plans)
- Supabase: ~$50/month (Pro with overages)
- Monitoring: $29/month (Sentry)
- CDN: $20/month (Cloudflare Pro)
- **Total**: ~$200/month

---

**🏁 You're ready to launch! Follow this checklist step-by-step and you'll have a production-ready system. Good luck! 🚀**

**Questions?** Review the detailed guides in the `docs/` folder or reach out for help.

**Remember**: Start small (15 pilots), iterate fast, and scale gradually. You've got this! 💪
