# SafeStride - AI-Powered Running Coach 🏃‍♂️

## 🎯 Overview

SafeStride is an AI-powered running coaching platform that integrates with Strava to provide personalized training plans, performance analytics, and real-time coaching feedback.

**Production URL:** `https://api.akura.in`  
**GitHub:** `https://github.com/CoachKura/safestride-akura`  
**Database:** Supabase (`bdisppaxbvygsspcuymb`)

---

## ✅ Current Features (Production)

### 🏁 Strava Integration (LIVE)

- **OAuth Signup** - Connect Strava account in one tap
- **Activity Sync** - Automatic sync of all running activities
- **Personal Bests** - Auto-calculate PBs for 5K, 10K, Half Marathon, Marathon
- **Returning User Detection** - Smart login/signup flow
- **Persistent Sessions** - Stay logged in with SharedPreferences

### 📊 Dashboard & Analytics

- **Home Dashboard** - Live stats, PBs, quick actions
- **Stats Display** - Total runs, distance, time, pace, longest run
- **Athlete Profile** - Photo, name, location from Strava

### 🎯 Training Plans (AI-Generated)

- **Goal Selection** - 5K, 10K, Half Marathon, Marathon
- **Riegel Projection** - 3% PB improvement targets
- **Pace Guidance** - Easy, Tempo, Interval zones from 5K PB
- **Duration Options** - 8, 12, or 16-week plans
- **Progressive Phases** - Base → Build → Peak → Taper
- **Color-Coded Workouts** - Visual workout type identification

### 🔐 Authentication

- Email/password signup and login
- Strava OAuth integration
- Secure token management

---

## 📁 Project Structure

### **Backend (Python/FastAPI)**

```
ai_agents/
├── main.py                          # Main FastAPI app (aisri-ai-engine)
├── communication_agent_v2.py        # AI chat/telegram bot
├── strava_signup_api_simple.py      # Strava OAuth & sync ⭐
├── api_endpoints.py                 # Core API routes
├── activity_integration.py          # Webhook handlers
├── supabase_handler_v2.py          # Database client
├── telegram_handler_v2.py          # Telegram integration
├── aisri_api_handler_v2.py         # API utilities
├── database_integration.py         # DB operations
├── race_analyzer.py                # Race analysis
├── performance_tracker.py          # Workout tracking
├── fitness_analyzer.py             # Fitness metrics
├── ai_engine_agent/                # AI coaching engine
│   ├── technical_knowledge_base.py
│   ├── self_learning_integration.py
│   └── autonomous_decision_agent.py
└── tests_archive/                  # Old test files (archived)
```

### **Frontend (Flutter/Dart)**

```
lib/
├── main.dart                        # App entry point with auto-login
├── screens/                         # UI screens (15 active)
│   ├── login_screen.dart           # Email + Strava login
│   ├── register_screen.dart        # Email signup
│   ├── dashboard_screen.dart       # Main app dashboard
│   ├── strava_oauth_screen.dart    # Strava OAuth WebView ⭐
│   ├── strava_home_dashboard.dart  # Strava home screen ⭐
│   ├── strava_stats_screen.dart    # Post-OAuth stats ⭐
│   ├── strava_training_plan_screen.dart # Training plan gen ⭐
│   ├── tracker_screen.dart         # GPS run tracking
│   ├── start_run_screen.dart       # Run initialization
│   ├── history_screen.dart         # Activity history
│   ├── profile_screen.dart         # User settings
│   └── archived/                   # Old screens (33 archived)
├── services/                        # Business logic (40+ services)
│   ├── strava_session_service.dart # Persistent login ⭐
│   ├── auth_service.dart           # Authentication
│   └── strava_service.dart         # Strava API client
├── models/                          # Data models
├── widgets/                         # Reusable components
└── config/                          # App configuration
```

### **Database (Supabase)**

```
supabase/
├── migrations/                      # SQL migrations
└── functions/                       # Edge functions
```

### **Configuration**

```
.env                                 # Environment variables
render.yaml                          # Production deployment config
requirements.txt                     # Python dependencies
pubspec.yaml                         # Flutter dependencies
```

### **Scripts & Documentation**

```
scripts/                             # Essential utilities
├── backup-database.ps1
├── restore-database.ps1
├── connect-db.ps1
└── archive/                        # Old scripts (19 archived)

docs/
├── archive/                        # Old development docs (58 files)
└── garmin/                         # Garmin integration docs (6 files)
```

---

## 🚀 Production Services (Render)

### **1. aisri-ai-engine** → `api.akura.in`

- **Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **File:** `ai_agents/main.py`
- **Includes:** Strava OAuth routes from `strava_signup_api_simple.py`

### **2. aisri-communication-v2**

- **Command:** `uvicorn communication_agent_v2:app --host 0.0.0.0 --port $PORT`
- **File:** `ai_agents/communication_agent_v2.py`
- **Purpose:** Telegram bot + AI chat

### **3. safestride-api**

- **Command:** `python api_endpoints.py`
- **File:** `ai_agents/api_endpoints.py`
- **Port:** 8000

### **4. safestride-webhooks**

- **Command:** `python activity_integration.py`
- **File:** `ai_agents/activity_integration.py`
- **Port:** 8001

---

## 🔧 Development Setup

### **Prerequisites**

- Python 3.14+ with `legacy-cgi` package
- Flutter 3.5.4+
- Supabase account
- Strava API credentials

### **Backend Setup**

```bash
cd ai_agents
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pip install legacy-cgi  # Python 3.14 compatibility
```

Create `.env` file:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_service_key
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=your_secret
```

Run locally:

```bash
uvicorn main:app --reload --port 8002
```

### **Frontend Setup**

```bash
flutter pub get
flutter run
```

---

## 📊 Database Schema

### **profiles table**

```sql
- id (uuid, PK)
- email
- strava_athlete_id (bigint)
- strava_access_token (text)
- strava_refresh_token (text)
- strava_token_expires_at (timestamp)
- last_strava_sync (timestamp)
- profile_photo_url (text)
- gender, weight, height
- city, state, country
- pb_5k, pb_10k, pb_half_marathon, pb_marathon (seconds)
- total_runs, total_distance_km, total_time_hours
- avg_pace_min_per_km, longest_run_km
```

### **strava_activities table**

```sql
- id (uuid, PK)
- user_id (uuid, FK → profiles.id)
- strava_activity_id (bigint, unique)
- name, distance_meters, moving_time_seconds
- elapsed_time_seconds, total_elevation_gain
- activity_type, sport_type
- start_date, start_date_local
- average_speed, max_speed
- average_heartrate, max_heartrate
- average_cadence, average_watts, max_watts
- kudos_count, achievement_count, comment_count
- raw_data (jsonb)
```

---

## 🔐 Environment Variables

### **Backend (Render)**

```env
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=*****
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=*****
TELEGRAM_BOT_TOKEN=*****
AISRI_API_URL=http://aisri-api:8000
```

### **Flutter (Hardcoded)**

```dart
// lib/config/api_config.dart
const String apiBaseUrl = 'https://api.akura.in';
const String supabaseUrl = 'https://bdisppaxbvygsspcuymb.supabase.co';
const String supabaseAnonKey = '*****';
```

---

## 🧪 Testing

### **Backend API Tests**

```bash
# Test Strava OAuth endpoint
curl https://api.akura.in/api/strava-signup

# Test athlete stats
curl https://api.akura.in/api/athlete-stats/122864016
```

### **Flutter Tests**

```bash
flutter test
flutter analyze
```

---

## 📈 Key Metrics

### **Production Data (Verified)**

- **Athlete ID 122864016:**
  - 479 running activities synced
  - 2,601.3 km total distance
  - PBs calculated correctly
  - All stats accurate

### **Performance**

- Strava OAuth flow: ~2-3 seconds
- Activity sync (479 runs): ~15 seconds background job
- PB calculation: Real-time (Riegel formula)

---

## 🎯 Next Development Phases

### **Phase 2: Activity Tracking**

- [ ] Real-time GPS run tracking
- [ ] Live pace, distance, time display
- [ ] Route mapping
- [ ] Save runs to Supabase + sync to Strava

### **Phase 3: Workout Analysis**

- [ ] Post-run insights (pace zones, HR analysis)
- [ ] Compare actual vs training plan
- [ ] AI recommendations for next workout

### **Phase 4: Training Plan Execution**

- [ ] Link workouts from plan to tracker
- [ ] Check off completed workouts
- [ ] Progress tracking & adaptive adjustments

### **Phase 5: Social & Gamification**

- [ ] Challenges & community engagement
- [ ] Achievements & milestone tracking
- [ ] Leaderboards

### **Phase 6: Advanced AI**

- [ ] Injury prevention (biomechanics analysis)
- [ ] Performance prediction (race time projections)
- [ ] AI coach chat

---

## 📝 Git Workflow

### **Branches**

- `main` - Production (auto-deploys to Render)
- `develop` - Development branch
- `feature/*` - Feature branches

### **Commits**

Recent production commits:

- `b7d2fd1` - Added persistent login, home dashboard, training plans (Options 5,6,7)
- `c428b9e` - Returning user detection + Flutter stats screen (Options 3,4)
- `bf8fabe` - Merged Strava routes into aisri-ai-engine
- `838b36a` - Initial Strava OAuth implementation

---

## 🐛 Known Issues & Solutions

### **Python 3.14 `cgi` Module Removed**

**Solution:** Install `legacy-cgi` package

```bash
pip install legacy-cgi
```

### **Strava OAuth Redirect Issues**

**Solution:** Ensure redirect URIs match exactly:

- Production: `https://api.akura.in/api/strava-callback`
- Local: `http://localhost:8002/api/strava-callback`

### **Flutter Hot Reload Issues**

**Solution:** Full restart after adding new screens:

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📞 Support & Contact

**Project Owner:** Coach Kura  
**GitHub:** https://github.com/CoachKura/safestride-akura  
**Production API:** https://api.akura.in

---

## 📄 License

Proprietary - All rights reserved

---

## 📅 Last Updated

**Date:** February 27, 2026  
**Version:** 1.2.0 (Strava MVP Complete + Training Plans)  
**Status:** ✅ Production Live
