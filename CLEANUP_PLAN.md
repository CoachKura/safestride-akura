# SafeStride Project Cleanup & Reorganization Plan

## 📊 Current State Analysis

### ✅ **ACTIVE PRODUCTION FILES**

#### Backend (Deployed on Render)

- `ai_agents/main.py` → aisri-ai-engine (api.akura.in)
- `ai_agents/communication_agent_v2.py` → aisri-communication-v2
- `ai_agents/strava_signup_api_simple.py` → Strava OAuth & sync (included in main.py)
- `ai_agents/supabase_handler_v2.py` → Database client
- `ai_agents/telegram_handler_v2.py` → Telegram bot
- `ai_agents/aisri_api_handler_v2.py` → API utilities

#### Flutter App (Active Screens)

**Wired in main.dart routes:**

- login_screen.dart
- register_screen.dart
- dashboard_screen.dart
- strava_home_dashboard.dart ⭐ **NEW**
- strava_oauth_screen.dart ⭐ **NEW**
- strava_stats_screen.dart ⭐ **NEW**
- strava_training_plan_screen.dart ⭐ **NEW**
- evaluation_form_screen.dart
- devices_screen.dart
- tracker_screen.dart
- start_run_screen.dart
- logger_screen.dart
- workout_creator_screen.dart
- history_screen.dart
- profile_screen.dart

**Active Services:**

- strava_session_service.dart ⭐ **NEW**
- auth_service.dart
- strava_service.dart
- All services in lib/services/ (40 files)

#### Configuration Files (KEEP)

- `.env`, `.env.example`
- `pubspec.yaml`, `pubspec.lock`
- `render.yaml`
- `requirements.txt`, `runtime.txt`
- `.gitignore`, `.metadata`
- `analysis_options.yaml`, `devtools_options.yaml`

---

## 🗑️ **FILES TO REMOVE/ARCHIVE**

### Root Directory - Documentation Overload (65 markdown files)

**Category 1: Old Deployment Guides (Archive to /docs/archive/)**

- DEPLOYMENT_GUIDE.md
- DEPLOYMENT_ACTION_PLAN.md
- DEPLOYMENT_COMPLETE.md
- LIVE_DEPLOYMENT_GUIDE.md
- START_HERE_DEPLOY.md
- FLUTTER_DEPLOYMENT_GUIDE.md
- RAILWAY_DEPLOYMENT.md
- RENDER_DEPLOYMENT_GUIDE.md
- BUILD_COMPLETE.md
- READY_FOR_PRODUCTION.md
- PRODUCTION_CHECKLIST.md

**Category 2: Strava Development Docs (Archive)**

- STRAVA_SIGNUP_ARCHITECTURE.md
- STRAVA_SIGNUP_COMPLETE_GUIDE.md
- STRAVA_SIGNUP_QUICK_REFERENCE.md
- STRAVA_OAUTH_FIX.md
- STRAVA_OAUTH_TEST_GUIDE.md
- STRAVA_CONNECTION_FIX.md
- STRAVA_PROFILE_FEATURE.md
- STRAVA_DASHBOARD_INTEGRATION_GUIDE.md
- STRAVA_GARMIN_INTEGRATION_GUIDE.md
- SIGNUP_AND_DATA_SYNC_GUIDE.md

**Category 3: Garmin Docs (Move to /docs/garmin/)**

- GARMIN_DATA_FORMAT_GUIDE.md
- GARMIN_INTEGRATION_COMPLETE_GUIDE.md
- GARMIN_INTEGRATION_DECISION_GUIDE.md
- GARMIN_INTEGRATION_STATUS.md
- GARMIN_QUICK_INTEGRATION.md
- AI_WORKOUT_TO_GARMIN_CALENDAR.md

**Category 4: General Dev Docs (Archive or consolidate)**

- COMPLETE_EVALUATION_SYSTEM_GUIDE.md
- COMPREHENSIVE_IMPROVEMENT_PLAN.md
- IMPROVED_ONBOARDING_FLOW.md
- IMPLEMENTATION_SUMMARY.md
- CURRENT_APP_STRUCTURE.md
- PROJECT_STRUCTURE.md
- SAFESTRIDE_AI_ML_IMPLEMENTATION.md
- WORKOUT_ANALYSIS_SYSTEM.md
- TRAINING_PLAN_BUILDER_SETUP.md
- BIOMECHANICS_INTEGRATION.md

**Category 5: Old Testing/Setup Docs (Delete)**

- QUICK_TEST_GUIDE.md
- TESTING_GUIDE.md
- TESTING_CHECKLIST.md
- TESTING_CHECKLIST_UPDATED.md
- ANDROID_TESTING_GUIDE.md
- TEST_MOBILE_NOW.md
- RUN_DATABASE_MIGRATION.md
- FIX_SUPABASE_AUTH_ERROR.md
- DATABASE_DEPLOYMENT_GUIDE.md
- CONFIGURATION_GUIDE.md
- DATA_PROTECTION_GUIDE.md

**Category 6: Quick Start Guides (Keep 1, archive rest)**
**KEEP:** README.md (update it)
**ARCHIVE:**

- START_HERE.md
- QUICK_START.md
- QUICK_START_AI_ML.md
- QUICK_START_GARMIN.md

**Category 7: N8N/Workflow Docs (Archive - not using n8n)**

- N8N_WORKFLOW_GUIDE.md
- N8N_FIX_GET_DECISION_NODE.md
- n8n-ai-coaching-workflow.json

**Category 8: AISRI Guides (Archive - internal reference)**

- AISRI_BIOMECHANICS_AI_GUIDE.md
- AISRI_CORRECTION_GUIDE.md
- AISRI_QUICK_REFERENCE.md
- ADAPTIVE_TIMELINE_CALCULATOR.md

### PowerShell Scripts (23 files) - Many are one-time setup/test

**Keep Essential (4):**

- `backup-database.ps1`
- `restore-database.ps1`
- `connect-db.ps1`
- `supabase-cli-reference.ps1`

**Archive to /scripts/archive/ (19):**

- All test-\*.ps1
- All setup-\*.ps1
- All verify-\*.ps1
- diagnose-strava-oauth.ps1
- start-strava-signup-api.ps1
- start-all-services.ps1
- deploy-start.ps1
- apply-\*.ps1
- run-migration.ps1
- fix-dns-windows.ps1
- get-api-keys.ps1

### Python Files - Old/Test versions

**ai_agents/ - Remove:**

- `strava_oauth.py` (old, use strava_signup_api_simple.py)
- `strava_signup_api.py` (old, use strava_signup_api_simple.py)
- `activity_integration.py` (?)
- `api_endpoints.py` (?)
- All test\_\*.py (16 files)
- `simple_test.py`, `integration_test.py`
- `check_status.py`, `run_cycle.py`, `simple_daily_cycle.py`
- `communication_agent_simple.py` (root - use v2)

**ai_agents/ - Old Agent Directories (DELETE):**

- `ai_engine_agent/` (not used)
- `backend_agent/` (not used)
- `commander/` (not used)
- `communication_agent/` (old, use communication_agent_v2.py)
- `database_agent/` (not used)
- `devops_agent/` (not used)
- `mobile_agent/` (not used)
- `test_agent/` (not used)

### Flutter - Unused Screens (DELETE)

**Screens NOT in main.dart routes:**

- admin_batch_generation_screen.dart
- analysis_report_screen.dart
- assessment_results_screen.dart
- assessment_screen.dart
- athlete_dashboard.dart
- athlete_goals_screen.dart
- body_measurements_screen.dart
- calendar_screen.dart
- fitness_dashboard_screen.dart
- garmin_connect_screen.dart
- garmin_device_screen.dart
- garmin_workout_builder_screen.dart
- goals_screen.dart
- goal_based_workout_creator_screen.dart
- gps_connection_screen.dart
- gps_tracker_screen.dart
- injuries_screen.dart
- injury_detail_screen.dart
- kura_coach_calendar_screen.dart
- kura_coach_workout_detail_screen.dart
- pace_progression_screen.dart
- phase_details_screen.dart
- report_viewer_screen.dart
- safety_gates_screen.dart
- step_editor_screen.dart
- strava_connect_screen.dart (old)
- strava_signup_screen.dart (old - use strava_oauth_screen)
- structured_workout_detail_screen.dart
- structured_workout_list_screen.dart
- training_plan_screen.dart (old - use strava_training_plan_screen)
- workout_builder_screen.dart
- workout_detail_screen.dart
- workout_history_screen.dart

### Other Directories

**DELETE:**

- `garmin_connectiq/` (2.65 MB - ConnectIQ app not being used)
- `database_canonical/` (0.03 MB - old schema reference)
- `test/` (empty)
- `docs/` (0.52 MB - move useful docs to root /docs/, delete duplicates)

---

## 📁 **PROPOSED CLEAN STRUCTURE**

```
safestride/
├── .github/                    # Keep (CI/CD)
├── ai_agents/
│   ├── main.py                ✅ PROD
│   ├── communication_agent_v2.py ✅ PROD
│   ├── strava_signup_api_simple.py ✅ PROD
│   ├── supabase_handler_v2.py ✅ PROD
│   ├── telegram_handler_v2.py ✅ PROD
│   ├── aisri_api_handler_v2.py ✅ PROD
│   ├── database/              # Keep if used
│   ├── logs/                  # Keep
│   ├── requirements.txt       ✅
│   └── .env                   ✅
├── android/                   ✅ Flutter native
├── ios/                       ✅ Flutter native
├── linux/                     ✅ Flutter native
├── macos/                     ✅ Flutter native
├── windows/                   ✅ Flutter native
├── assets/                    ✅ Images, fonts
├── lib/
│   ├── main.dart             ✅ ENTRY
│   ├── config/               ✅
│   ├── models/               ✅
│   ├── screens/              ✅ 15 active screens only
│   ├── services/             ✅ 40+ services
│   ├── theme/                ✅
│   └── widgets/              ✅
├── supabase/                  ✅ DB migrations
├── web/                       ✅ Flutter web + Strava test pages
├── build/                     # Git ignored
├── scripts/                   📂 NEW - Move essential scripts here
│   ├── backup-database.ps1
│   ├── restore-database.ps1
│   ├── connect-db.ps1
│   └── archive/              # Old scripts
├── docs/                      📂 REORGANIZED
│   ├── README.md             # Project overview
│   ├── QUICK_START.md        # Getting started
│   ├── API.md                # API reference
│   ├── DEPLOYMENT.md         # Production deployment
│   ├── garmin/               # Garmin integration docs
│   └── archive/              # Old development docs
├── .env                       ✅
├── .env.example              ✅
├── .gitignore                ✅
├── pubspec.yaml              ✅
├── render.yaml               ✅ PROD config
├── requirements.txt          ✅ Python deps
└── README.md                 ✅ Main project readme
```

---

## 🎯 **NEXT STEPS FOR DEVELOPMENT**

### Immediate (Strava MVP Done ✅)

- [✅] Strava OAuth signup & profile sync
- [✅] Returning user detection
- [✅] Stats screen after OAuth
- [✅] Persistent login (SharedPreferences)
- [✅] Home dashboard with PBs & stats
- [✅] Training plan generator (5K/10K/HM/Marathon)

### Phase 2 - Activity Tracking (Next Sprint)

1. **GPS Run Tracking** - Use existing tracker_screen.dart
   - Real-time pace, distance, time
   - Route mapping
   - Save to Supabase
   - Sync to Strava

2. **Workout Analysis** - After-run insights
   - Pace zones
   - Heart rate analysis (if available)
   - Compare to training plan
   - AI recommendations

3. **Training Plan Execution**
   - Link workouts from plan to tracker
   - Check off completed workouts
   - Progress tracking
   - Adaptive adjustments

### Phase 3 - Social & Gamification

1. **Challenges** - Community engagement
2. **Achievements** - Milestone tracking
3. **Leaderboards** - Friendly competition

### Phase 4 - Advanced AI

1. **Injury Prevention** - Biomechanics analysis
2. **Performance Prediction** - Race time projections
3. **Coach Chat** - AI running advisor

---

## 📋 **CLEANUP EXECUTION CHECKLIST**

- [ ] Create `/scripts/` and `/scripts/archive/`
- [ ] Move 4 essential .ps1 to `/scripts/`
- [ ] Move 19 old .ps1 to `/scripts/archive/`
- [ ] Create `/docs/archive/` and `/docs/garmin/`
- [ ] Move 50+ old .md to `/docs/archive/`
- [ ] Move Garmin docs to `/docs/garmin/`
- [ ] Update root README.md with current state
- [ ] Delete unused Flutter screens (30+ files)
- [ ] Delete test Python files (16+ files)
- [ ] Delete old agent directories (8 folders)
- [ ] Delete `/garmin_connectiq/`
- [ ] Delete `/database_canonical/`
- [ ] Delete `/test/` (empty)
- [ ] Clean up `/docs/` duplicates
- [ ] Update `.gitignore` to exclude `/docs/archive/`
- [ ] Commit cleanup

---

## 📝 **ESTIMATED CLEANUP IMPACT**

**Files to remove/archive:** ~150 files
**Disk space freed:** ~5-10 MB (docs + garmin_connectiq)
**Clarity gained:** MASSIVE ⭐

**Before:** 65 markdown docs, 23 scripts, 8 agent dirs, 30+ unused screens
**After:** 5 essential docs, 4 scripts, clean structure
