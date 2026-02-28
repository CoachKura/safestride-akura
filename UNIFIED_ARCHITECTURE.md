# SafeStride Complete Architecture & Data Flow

**Unified System Integration Guide**

## 📊 System Overview

SafeStride now has **THREE INTERCONNECTED COMPONENTS**:

1. **Flutter Mobile App** - Native iOS/Android/Web application
2. **Python AI Backend** - API services, AI agents, data processing
3. **HTML Training Plan Builder** - Web-based training plan creator (localhost:55854)

### 🎯 **THE SOLUTION**: All three components now share the same backend and database!

---

## 🔗 Integration Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER EXPERIENCE                             │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌────────────────────┐  │
│  │   Flutter    │    │   HTML Web   │    │   Mobile Apps      │  │
│  │   Web App    │    │   Builder    │    │   (iOS/Android)    │  │
│  │ (Chrome/Edge)│    │ (localhost)  │    │                    │  │
│  └──────┬───────┘    └──────┬───────┘    └────────┬───────────┘  │
│         │                    │                      │              │
└─────────┼────────────────────┼──────────────────────┼──────────────┘
          │                    │                      │
          └────────────────────┴──────────────────────┘
                               │
                    ┌──────────▼───────────┐
                    │   UNIFIED BACKEND    │
                    │  Python FastAPI      │
                    │  (api.akura.in)      │
                    │                      │
                    │  • Strava OAuth      │
                    │  • AISRI Calculator  │
                    │  • Activity Sync     │
                    │  • Training Plans    │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │   SUPABASE DATABASE  │
                    │                      │
                    │  • athletes          │
                    │  • aisri_scores      │
                    │  • run_sessions      │
                    │  • training_plans    │
                    └──────────────────────┘
```

---

## 🚀 Complete User Journey

### **Scenario 1: New User (First Time)**

```
1. User opens Flutter app
   ↓
2. Clicks "Connect with Strava"
   ↓
3. OAuth flow (Strava authorization)
   ↓
4. Returns to app with athlete data
   ↓
5. **NEW**: Auto-fills AISRI assessment form
   - Age: from Strava profile
   - Gender: from Strava profile
   - Weight: from Strava profile
   ↓
6. User completes remaining assessment questions
   ↓
7. AISRI score calculated & saved to database
   ↓
8. User navigates to Strava Home Dashboard
   ↓
9. Can now use training plan builder (shares same backend!)
```

### **Scenario 2: Returning User (Has Strava Connected)**

```
1. User opens Flutter app
   ↓
2. Auto-login with saved session
   ↓
3. Goes directly to Strava Home Dashboard
   ↓
4. **NEW**: Auto-calculated AISRI score visible (updated weekly)
   ↓
5. Can access training plan through Flutter OR HTML builder
   - Both use SAME database
   - Both see SAME activities
   - Both see SAME AISRI scores
```

---

## 📂 Data Flow Diagram

### **Strava Connection Flow**

```
┌────────────┐
│   User     │
│  Clicks    │
│  "Connect  │
│   Strava"  │
└─────┬──────┘
      │
      ▼
┌──────────────────────────────────────────┐
│  StravaOAuthScreen (Flutter)             │
│  - Opens Strava OAuth in WebView         │
│  - Redirects to: api.akura.in/callback   │
└─────┬────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────┐
│  Backend: /strava-oauth-callback         │
│  - Exchanges code for tokens             │
│  - Fetches athlete profile               │
│  - Saves to Supabase `strava_athletes`   │
│  - Returns StravaAuthResult              │
└─────┬────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────┐
│  StravaStatsScreen (Flutter)             │
│  - Shows: Total runs, distance, PBs      │
│  - "Let's Run!" button                   │
└─────┬────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────┐
│  EvaluationFormScreen (Flutter)          │
│  **NEW**: Receives athleteData           │
│  - Auto-fills: Age, Gender, Weight       │
│  - User completes remaining fields       │
│  - Calculates AISRI score                │
│  - Saves to `aisri_assessments` table    │
└─────┬────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────┐
│  StravaHomeDashboard (Flutter)           │
│  - Quick actions: Training Plan, History │
│  - Shows recent activities               │
│  - Displays AISRI score                  │
└──────────────────────────────────────────┘
```

---

## 🔄 Auto-AISRI Calculation Flow

### **Weekly Automatic Update**

```
┌─────────────────────────┐
│  Scheduled Job          │
│  (Every Sunday 2:00 AM) │
└──────────┬──────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  aisri_scheduled_updater.py          │
│                                      │
│  FOR EACH connected athlete:         │
│    1. Check for new activities       │
│    2. Fetch activities from Strava   │
│    3. Calculate AISRI pillars:       │
│       ✓ Adaptability (training age)  │
│       ✓ Consistency (frequency)      │
│       ✓ Intensity (pace variety)     │
│       ✓ Recovery (rest days)         │
│       ✓ Fatigue (training load)      │
│       ⚠️ Injury Risk (estimated)      │
│    4. Save to `aisri_scores` table   │
│    5. Notify if score changed >10    │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Database: athlete_aisri_scores      │
│                                      │
│  {                                   │
│    user_id: "uuid",                  │
│    aisri_score: 75,                  │
│    risk_level: "Low",                │
│    confidence: 85,                   │
│    calculation_method: "strava_auto",│
│    data_source: "Strava",            │
│    calculated_at: "2026-02-27"       │
│  }                                   │
└──────────────────────────────────────┘
```

---

## 🛠️ Backend API Endpoints

### **For Flutter App & HTML Builder**

```http
# Strava OAuth
POST /strava-oauth-callback
  - Completes Strava OAuth flow
  - Saves athlete data to database
  - Returns: tokens + athlete profile

# AISRI Calculation
POST /api/athlete/{user_id}/calculate-aisri-auto
  - Auto-calculates AISRI from activities
  - Returns: score + pillars + confidence

GET /api/athlete/{user_id}/aisri-scores
  - Fetches current + historical AISRI scores
  - Returns: [{aisri_score, risk_level, calculated_at}]

POST /api/athlete/{user_id}/refresh-aisri
  - Manually trigger AISRI recalculation
  - Returns: updated scores

# Activity Sync
GET /api/athlete/{strava_id}/recent-activities
  - Fetches activities from past 8 weeks
  - Returns: [{id, distance, pace, date, ...}]

GET /api/athlete/{strava_id}/athlete-stats
  - Fetches aggregated stats
  - Returns: {total_runs, total_distance, PBs}

# Training Plans
POST /api/training-plan/generate
  - Generates AI-powered training plan
  - Input: aisri_score, target_race, goal
  - Returns: {weeks, workouts, progressions}

GET /api/athlete/{user_id}/training-plans
  - Fetches all training plans
  - Returns: [{plan_id, name, weeks, status}]
```

---

## 📊 Database Schema

### **Key Tables**

```sql
-- Strava athlete connections
CREATE TABLE strava_athletes (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    strava_athlete_id VARCHAR UNIQUE,
    access_token VARCHAR,
    refresh_token VARCHAR,
    athlete_data JSONB,
    created_at TIMESTAMPTZ,
    last_sync_at TIMESTAMPTZ
);

-- AISRI scores (auto-calculated + manual)
CREATE TABLE athlete_aisri_scores (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    aisri_score INTEGER,
    risk_level VARCHAR,
    confidence INTEGER,

    -- Pillars
    pillar_adaptability INTEGER,
    pillar_injury_risk INTEGER,
    pillar_fatigue INTEGER,
    pillar_recovery INTEGER,
    pillar_intensity INTEGER,
    pillar_consistency INTEGER,

    -- Metadata
    calculation_method VARCHAR, -- 'manual', 'strava_auto'
    data_source VARCHAR, -- 'Strava', 'Garmin', 'Manual'
    notes TEXT,
    calculated_at TIMESTAMPTZ
);

-- Activity storage
CREATE TABLE strava_activities (
    id UUID PRIMARY KEY,
    strava_activity_id VARCHAR UNIQUE,
    athlete_id VARCHAR,
    name VARCHAR,
    distance FLOAT,
    moving_time INTEGER,
    average_speed FLOAT,
    average_heartrate INTEGER,
    start_date TIMESTAMPTZ,
    activity_data JSONB, -- Full Strava response
    synced_at TIMESTAMPTZ
);

-- Training plans
CREATE TABLE training_plans (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    plan_name VARCHAR,
    target_race_distance VARCHAR,
    target_race_date DATE,
    weeks_data JSONB, -- [{week: 1, workouts: [...]}]
    created_at TIMESTAMPTZ,
    status VARCHAR -- 'active', 'completed', 'paused'
);
```

---

## 🎨 Frontend Components

### **Flutter App Structure**

```
lib/
├── main.dart (✅ Updated - handles /aisri route with arguments)
├── screens/
│   ├── login_screen.dart (✅ Updated - routes new users to evaluation form)
│   ├── strava_oauth_screen.dart (✅ Returns athleteData)
│   ├── strava_stats_screen.dart (✅ Shows stats before evaluation)
│   ├── evaluation_form_screen.dart (✅ Auto-fills from Strava)
│   ├── strava_home_dashboard.dart (Main dashboard)
│   ├── strava_training_plan_screen.dart (Training plan UI)
│   └── ...
├── services/
│   ├── aisri_calculator.dart (Manual assessment calculator)
│   ├── strava_aisri_auto_calculator.dart (✅ NEW - Auto from Strava)
│   ├── strava_session_service.dart (Session persistence)
│   └── ...
```

### **HTML Training Plan Builder**

```
training-plan-builder/
├── index.html
│   - Strava OAuth button
│   - Activity display
│   - AISRI score visualization
│   - Training plan generator
├── js/
│   ├── strava-auth.js
│   │   - OAuth flow handler
│   │   - Uses SAME backend: api.akura.in
│   ├── aisri-display.js
│   │   - Fetches: GET /api/athlete/{user_id}/aisri-scores
│   │   - Shows: Score + pillars + trends
│   └── plan-builder.js
│       - Generates training plans
│       - POST /api/training-plan/generate
```

---

## 🔐 Authentication Flow

### **Shared Session Management**

```
1. User authenticates via Strava (either app)
   ↓
2. Backend creates:
   - Supabase auth session
   - Strava access/refresh tokens
   ↓
3. Tokens stored in:
   - Flutter: StravaSessionService (SharedPreferences)
   - HTML: localStorage
   - Backend: strava_athletes table
   ↓
4. Both frontends use SAME session
   - Flutter: Pass session in Navigator arguments
   - HTML: Read from localStorage
   ↓
5. Backend validates tokens on every API call
   - Auto-refreshes expired tokens
   - Returns 401 if session invalid
```

---

## ⚙️ Setup & Configuration

### **1. Environment Variables**

Create `.env` file in `ai_agents/`:

```bash
# Supabase
SUPABASE_URL=https://xzxnnswggwqtctcgpocr.supabase.co
SUPABASE_SERVICE_KEY=your_service_key

# Strava
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
STRAVA_REDIRECT_URI=https://www.akura.in/strava-callback

# API
AISRI_API_BASE=https://api.akura.in

# Notifications
ENABLE_TELEGRAM_NOTIFICATIONS=true
ADMIN_TELEGRAM_ID=your_telegram_id

# Scheduler
AISRI_SCHEDULER_NOTIFY=true
```

### **2. Flutter Configuration**

Edit `.env` in root:

```bash
SAFESTRIDE_STRAVA_API_URL=https://api.akura.in
SUPABASE_URL=https://xzxnnswggwqtctcgpocr.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

### **3. HTML Builder Configuration**

Edit `config.js`:

```javascript
const CONFIG = {
  API_BASE: "https://api.akura.in",
  STRAVA_CLIENT_ID: "your_client_id",
  REDIRECT_URI: "http://localhost:55854/callback",
};
```

---

## 🚀 Deployment

### **Backend Deployment (Railway/Render)**

```bash
cd ai_agents
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

### **Scheduled Job Setup**

```bash
# Linux cron (weekly on Sunday 2 AM)
0 2 * * 0 cd /path/to/ai_agents && python aisri_scheduled_updater.py

# Windows Task Scheduler
# Create task: Run weekly on Sunday 2:00 AM
# Action: python C:\safestride\ai_agents\aisri_scheduled_updater.py
```

### **Flutter Build**

```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 📈 Benefits of Unified Architecture

✅ **Single Sign-On**: Connect Strava once, use everywhere  
✅ **Shared Data**: Activities synced to one database  
✅ **Consistent AISRI**: Same scores across all platforms  
✅ **Auto-Updates**: Weekly score recalculation  
✅ **Multi-Platform**: Use Flutter app OR HTML builder  
✅ **Scalable**: Add more frontends easily

---

## 🔧 Troubleshooting

### **"Why do I see different scores in Flutter vs. HTML?"**

- Check calculation timestamps
- Verify both are calling same API endpoint
- Check database for duplicate user records

### **"Auto-AISRI not working"**

- Verify Strava athletes table has data
- Check strava_activities table has recent activities
- Run scheduler manually: `python aisri_scheduled_updater.py`

### **"HTML builder can't connect to Strava"**

- Verify STRAVA_CLIENT_ID in config.js matches backend
- Check redirect URI is registered in Strava app settings
- Clear localStorage and re-authenticate

---

## 📝 Migration Checklist

✅ **Completed:**

- [x] Wire Strava OAuth → Evaluation Form with auto-fill
- [x] Create Flutter auto-AISRI calculator service
- [x] Create Python backend auto-AISRI endpoint
- [x] Build scheduled weekly updater
- [x] Update navigation flow for new users
- [x] Document complete architecture

🔄 **In Progress:**

- [ ] Integrate training plan with auto-calculated scores
- [ ] Update HTML builder to use unified API
- [ ] Add Garmin support to auto-calculator

⏳ **Next Steps:**

- [ ] Test end-to-end with real Strava account
- [ ] Deploy backend with scheduler
- [ ] Update HTML builder JavaScript
- [ ] Add in-app AISRI trend charts
- [ ] Create admin dashboard for monitoring

---

## 📞 Support & Resources

- **Backend API Docs**: https://api.akura.in/docs
- **Strava API**: https://developers.strava.com/
- **Supabase Dashboard**: https://app.supabase.com/project/xzxnnswggwqtctcgpocr

---

**Last Updated**: February 27, 2026  
**Version**: 2.0 (Unified Architecture)
