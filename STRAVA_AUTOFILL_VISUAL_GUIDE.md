# 🎨 Strava Auto-Fill System - Visual Guide

## 📱 User Interface Preview

```
┌─────────────────────────────────────────────────────────────┐
│  SafeStride - Strava Profile                    [Admin]     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────┐  John Smith                                       │
│  │ 👤   │  ATH0001                                          │
│  └──────┘                                                    │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AISRI Score                               85       │   │
│  │                                         Risk: Low    │   │
│  │                                                       │   │
│  │  Running   ███████████████░░░  85                   │   │
│  │  Strength  ████████████░░░░░░  70                   │   │
│  │  ROM       ███████████████████  90                   │   │
│  │  Balance   ████████████████░░  80                   │   │
│  │  Alignment ███████████████░░░  75                   │   │
│  │  Mobility  ████████████████░░  82                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐         │
│  │   42    │ │ 312.5   │ │  5:12   │ │  Good   │         │
│  │Activities│ │  km     │ │  /km    │ │  Form   │         │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘         │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🏃 Strava Connection                               │   │
│  │                                                       │   │
│  │  ┌──────┐  john_smith_runner                        │   │
│  │  │ 👤   │  View on Strava →                         │   │
│  │  └──────┘  Last synced: 2 hours ago                 │   │
│  │                                                       │   │
│  │  [Sync Activities]  [Disconnect]                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Auto-Fill Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    USER OPENS PAGE                           │
│               /public/strava-profile.html                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              CHECK AUTHENTICATION                            │
│                                                               │
│  sessionStorage.getItem('safestride_session')               │
│  ├─ uid: "ATH0001"                                          │
│  ├─ role: "athlete"                                         │
│  └─ token: "eyJ..."                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│         INITIALIZE AUTO-FILL GENERATOR                       │
│                                                               │
│  const generator = new StravaAutoFillGenerator()            │
│                                                               │
│  generator.generatePage(                                     │
│    { uid: "ATH0001" },                                      │
│    { pageType: "profile", role: "athlete", autoFill: true }│
│  )                                                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                FETCH DATA (PARALLEL)                         │
│                                                               │
│  ┌─────────────────┬─────────────────┬─────────────────┐   │
│  │                 │                 │                 │   │
│  ↓                 ↓                 ↓                 ↓   │
│  Athlete Data   Strava Conn.    AISRI Scores   Activities  │
│                                                               │
│  GET /rest/v1/athletes?uid=eq.ATH0001                       │
│  → { full_name, email, phone, avatar }                      │
│                                                               │
│  GET /rest/v1/strava_connections?athlete_id=eq.ATH0001      │
│  → { strava_athlete_id, access_token, athlete_data }        │
│                                                               │
│  GET /rest/v1/aisri_scores?athlete_id=eq.ATH0001&limit=1    │
│  → { total_score, risk_category, pillar_scores }            │
│                                                               │
│  GET /rest/v1/strava_activities?athlete_id=eq.ATH0001       │
│  → [ { distance, time, aisri_score }, ... ]                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│             COMPUTE DERIVED FIELDS                           │
│                                                               │
│  totalActivities = activities.length                         │
│  totalDistance = sum(activities.map(a => a.distance))        │
│  totalTime = sum(activities.map(a => a.time))                │
│  averagePace = totalTime / totalDistance                     │
│  recentForm = calculateForm(aisri.total_score)               │
│                                                               │
│  ├─ total_score >= 75 → "Excellent"                         │
│  ├─ total_score >= 55 → "Good"                              │
│  ├─ total_score >= 35 → "Fair"                              │
│  └─ total_score < 35  → "Poor"                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              RENDER TEMPLATE WITH DATA                       │
│                                                               │
│  html = template                                             │
│    .replace('{{athlete.name}}', 'John Smith')               │
│    .replace('{{athlete.uid}}', 'ATH0001')                   │
│    .replace('{{athlete.email}}', 'john@example.com')        │
│    .replace('{{aisri.total}}', '85')                        │
│    .replace('{{aisri.risk}}', 'Low')                        │
│    .replace('{{aisri.running}}', '85')                      │
│    .replace('{{aisri.strength}}', '70')                     │
│    .replace('{{computed.totalActivities}}', '42')           │
│    .replace('{{computed.totalDistance}}', '312.5')          │
│    ... etc                                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              UPDATE PAGE ELEMENTS                            │
│                                                               │
│  document.getElementById('athleteName').textContent = '...'  │
│  document.getElementById('aisriTotal').textContent = '85'    │
│  document.getElementById('runningBar').style.width = '85%'   │
│  ... animate score bars, update stats, etc                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                 PAGE FULLY LOADED                            │
│                ALL FIELDS AUTO-FILLED                        │
│                                                               │
│                    ✅ Complete!                              │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Role-Based Access Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     USER LOGIN                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
       ↓               ↓               ↓
   ┌───────┐      ┌────────┐     ┌─────────┐
   │ ADMIN │      │ COACH  │     │ ATHLETE │
   └───┬───┘      └───┬────┘     └────┬────┘
       │              │               │
       ↓              ↓               ↓
┌──────────────────────────────────────────────────────────┐
│                                                           │
│  ADMIN ACCESS                                            │
│  ├─ View all athletes                                    │
│  ├─ View all Strava connections                          │
│  ├─ Manage system settings                               │
│  ├─ Configure AISRI weights                              │
│  └─ Red badge: 👑 Admin                                  │
│                                                           │
└──────────────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│                                                           │
│  COACH ACCESS                                            │
│  ├─ View assigned athletes                               │
│  ├─ View Strava connections                              │
│  ├─ Monitor AISRI scores                                 │
│  ├─ Generate training plans                              │
│  └─ Blue badge: 👔 Coach                                 │
│                                                           │
└──────────────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│                                                           │
│  ATHLETE ACCESS                                          │
│  ├─ View own data only                                   │
│  ├─ Connect/disconnect Strava                            │
│  ├─ Sync activities                                      │
│  ├─ View AISRI scores                                    │
│  └─ Green badge: 🏃 Athlete                              │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## 🔗 Strava OAuth Integration Flow

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: User clicks "Connect with Strava"                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Redirect to Strava Authorization                   │
│                                                               │
│  https://www.strava.com/oauth/authorize?                    │
│    client_id={STRAVA_CLIENT_ID}                             │
│    &redirect_uri=https://www.akura.in/strava-callback.html  │
│    &response_type=code                                       │
│    &scope=read,activity:read_all,profile:read_all           │
│    &state={athlete_uid}                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: User authorizes SafeStride on Strava               │
│                                                               │
│  ┌────────────────────────────────────────────────┐         │
│  │  Strava Authorization                          │         │
│  │                                                 │         │
│  │  SafeStride wants to:                          │         │
│  │  ✓ View your profile                           │         │
│  │  ✓ View your activities                        │         │
│  │  ✓ View your activity details                  │         │
│  │                                                 │         │
│  │  [Authorize]  [Cancel]                         │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Strava redirects with authorization code           │
│                                                               │
│  https://www.akura.in/strava-callback.html?                 │
│    code={AUTHORIZATION_CODE}                                 │
│    &state={athlete_uid}                                      │
│    &scope=read,activity:read_all,profile:read_all           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Exchange code for tokens (Edge Function)           │
│                                                               │
│  POST /functions/v1/strava-oauth                            │
│  Body: { code, athlete_id }                                  │
│                                                               │
│  Strava API responds with:                                   │
│  {                                                            │
│    access_token: "abc123...",                                │
│    refresh_token: "xyz789...",                               │
│    expires_at: 1234567890,                                   │
│    athlete: { id, username, firstname, lastname, ... }      │
│  }                                                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Store connection in database                       │
│                                                               │
│  INSERT INTO strava_connections (                            │
│    athlete_id,                                               │
│    strava_athlete_id,                                        │
│    access_token,                                             │
│    refresh_token,                                            │
│    expires_at,                                               │
│    athlete_data                                              │
│  )                                                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 7: Sync activities (Edge Function)                    │
│                                                               │
│  POST /functions/v1/strava-sync-activities                  │
│  Body: { athlete_id }                                        │
│                                                               │
│  ├─ Fetch activities from Strava API                        │
│  ├─ Calculate AISRI scores                                  │
│  ├─ Store in strava_activities table                        │
│  └─ Update aisri_scores table                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 8: Redirect to profile (auto-filled)                  │
│                                                               │
│  window.location.href = '/public/strava-profile.html'       │
│                                                               │
│  ✅ All data loaded and displayed!                          │
└─────────────────────────────────────────────────────────────┘
```

## 📊 AISRI Calculation Flow

```
┌─────────────────────────────────────────────────────────────┐
│              ACTIVITY DATA FROM STRAVA                       │
│                                                               │
│  {                                                            │
│    distance: 5000 (meters)                                   │
│    moving_time: 1500 (seconds)                               │
│    average_heartrate: 155 (bpm)                              │
│    average_cadence: 85 (spm)                                 │
│    total_elevation_gain: 50 (meters)                         │
│    suffer_score: 42                                          │
│  }                                                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│           ML/AI ANALYSIS (per activity)                      │
│                                                               │
│  Training Load = f(distance, time, elevation, HR)            │
│  Recovery Index = f(HR_variance, suffer_score, time)         │
│  Performance = f(pace, cadence, consistency)                 │
│  Fatigue = f(cumulative_load, recovery_time)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│        AGGREGATE TO 6-PILLAR AISRI SCORE                     │
│                                                               │
│  Running   (40%) = activities_analysis + biomechanics        │
│  Strength  (15%) = power_metrics + strength_tests            │
│  ROM       (12%) = flexibility_tests + mobility_data         │
│  Balance   (13%) = balance_tests + stability_metrics         │
│  Alignment (10%) = posture_analysis + gait_data              │
│  Mobility  (10%) = range_of_motion + functional_tests        │
│                                                               │
│  Total AISRI = weighted_sum(all_pillars)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              RISK CATEGORIZATION                             │
│                                                               │
│  IF total_score >= 75:  risk = "Low"                        │
│  IF total_score >= 55:  risk = "Medium"                     │
│  IF total_score >= 35:  risk = "High"                       │
│  ELSE:                  risk = "Critical"                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│               STORE IN DATABASE                              │
│                                                               │
│  INSERT INTO aisri_scores (                                  │
│    athlete_id,                                               │
│    total_score: 85,                                          │
│    risk_category: "Low",                                     │
│    pillar_scores: {                                          │
│      running: 85,                                            │
│      strength: 70,                                           │
│      rom: 90,                                                │
│      balance: 80,                                            │
│      alignment: 75,                                          │
│      mobility: 82                                            │
│    }                                                          │
│  )                                                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│            AUTO-FILL ON PROFILE PAGE                         │
│                                                               │
│  ✅ AISRI Score: 85                                          │
│  ✅ Risk: Low                                                │
│  ✅ 6 Pillar Scores displayed                                │
│  ✅ Training zones unlocked                                  │
└─────────────────────────────────────────────────────────────┘
```

## 🎨 Component Hierarchy

```
strava-profile.html
├── Header
│   ├── Avatar (auto-filled)
│   ├── Name (auto-filled)
│   ├── UID (auto-filled)
│   └── Navigation
│       ├── Dashboard link
│       ├── Training link
│       ├── Strava Profile (active)
│       └── Logout button
│
├── Role Badge (top-right)
│   ├── Admin (red)
│   ├── Coach (blue)
│   └── Athlete (green)
│
├── AISRI Score Card
│   ├── Total Score (auto-filled)
│   ├── Risk Badge (auto-filled)
│   └── 6 Pillar Scores
│       ├── Running (auto-filled with animation)
│       ├── Strength (auto-filled with animation)
│       ├── ROM (auto-filled with animation)
│       ├── Balance (auto-filled with animation)
│       ├── Alignment (auto-filled with animation)
│       └── Mobility (auto-filled with animation)
│
├── Activity Stats Grid
│   ├── Total Activities (auto-filled)
│   ├── Total Distance (auto-filled)
│   ├── Average Pace (auto-filled)
│   └── Recent Form (auto-filled)
│
├── Strava Connection Card
│   ├── Connected State
│   │   ├── Avatar (auto-filled)
│   │   ├── Username (auto-filled)
│   │   ├── Profile Link (auto-filled)
│   │   ├── Last Sync (auto-filled)
│   │   ├── Sync Button
│   │   └── Disconnect Button
│   │
│   └── Not Connected State
│       ├── Connect Button
│       └── Benefits Info
│
├── Recent Activities List
│   ├── Activity 1 (auto-filled)
│   ├── Activity 2 (auto-filled)
│   ├── ...
│   └── Load More Button
│
└── Contact Information
    ├── Email (auto-filled)
    └── Phone (auto-filled)
```

## 📦 File Organization

```
/home/user/webapp/
│
├── public/
│   ├── strava-autofill-generator.js  (22 KB)
│   │   ├── StravaAutoFillGenerator class
│   │   ├── Data fetching methods
│   │   ├── Template generation
│   │   ├── Field computation
│   │   └── Rendering logic
│   │
│   ├── strava-profile.html  (36 KB)
│   │   ├── Main profile page
│   │   ├── Auto-fill initialization
│   │   ├── Role-based UI
│   │   └── Event handlers
│   │
│   ├── strava-callback.html  (13 KB)
│   │   ├── OAuth callback handler
│   │   ├── Token exchange
│   │   ├── Activity sync trigger
│   │   └── Status display
│   │
│   ├── config.js  (3 KB)
│   │   ├── Supabase config
│   │   ├── Strava OAuth config
│   │   ├── AISRI settings
│   │   └── Feature flags
│   │
│   └── test-autofill.html  (27 KB)
│       ├── Test suite UI
│       ├── Generator tests
│       ├── Data fetch tests
│       ├── Role-based tests
│       ├── Auto-fill tests
│       └── Integration tests
│
├── STRAVA_AUTOFILL_SETUP_GUIDE.md  (10 KB)
│   ├── Installation instructions
│   ├── Configuration guide
│   ├── Architecture documentation
│   ├── API reference
│   ├── Troubleshooting
│   └── Deployment checklist
│
└── STRAVA_AUTOFILL_IMPLEMENTATION_SUMMARY.md  (12 KB)
    ├── Overview
    ├── Deliverables
    ├── Features
    ├── Configuration
    ├── Testing
    ├── Performance
    ├── Security
    └── Next steps
```

---

**Visual Guide Complete** ✨  
*All diagrams show actual system flow and UI structure*
