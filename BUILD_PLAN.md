# 🚀 Akura SafeStride - Complete Build Plan

**Project**: Akura SafeStride Web Application  
**Started**: January 31, 2026  
**Production URL**: https://www.akura.in  
**GitHub**: https://github.com/CoachKura/safestride-akura  

---

## ✅ Current Status

### What's Working:
- ✅ User Authentication (Supabase Auth)
- ✅ Assessment Intake (AIFRI calculation)
- ✅ Database Schema (7 tables)
- ✅ Basic Dashboard Layout
- ✅ Weekly Mileage Card (with real-time data)
- ✅ Monthly Distance Card (with real-time data)
- ✅ Track Workout Page
- ✅ Responsive Design
- ✅ VS Code Development Environment

### What's Partially Working:
- 🟡 Athlete Dashboard (layout done, some data missing)
- 🟡 Today's Workout Card (placeholder data)
- 🟡 6-Pillar Progress Chart (UI done, no real data)
- 🟡 Injury Status (basic query only)
- 🟡 Next Assessment (placeholder)

### What's Missing:
- ❌ Strava Integration (OAuth + Sync)
- ❌ Workout Detail Pages
- ❌ Coach Dashboard Features
- ❌ Advanced Analytics
- ❌ Social Features

---

## 📋 PHASE 1: COMPLETE ATHLETE DASHBOARD

**Goal**: Make every card on athlete-dashboard-pro.html fully functional with real data.

### Task 1.1: Today's Workout Card ⭐ **START HERE**

**Current State**: Shows placeholder data  
**Target**: Query `workouts` table for today's scheduled workout

**Implementation Steps**:
1. Create `loadTodaysWorkout(userId)` function
2. Query Supabase: `workouts` table where `athlete_id = userId` AND `scheduled_date = today` AND `status = 'scheduled'`
3. Display workout_type, duration_minutes, target_rpe, location
4. If no workout today, show "Rest Day" message
5. "Start Workout" button → redirect to `/track-workout.html`
6. Handle case where no workouts exist (show onboarding)

**Database Query**:
```javascript
const today = new Date().toISOString().split('T')[0];
const { data, error } = await supabase
  .from('workouts')
  .select('*')
  .eq('athlete_id', userId)
  .eq('scheduled_date', today)
  .eq('status', 'scheduled')
  .single();
```

**Expected Result**: Card shows real workout data or "Rest Day" message

---

### Task 1.2: 6-Pillar Progress Chart

**Current State**: Chart UI exists, shows sample data  
**Target**: Load real pillar scores from `pillar_progress` table

**Implementation Steps**:
1. Query `pillar_progress` table for latest week
2. Get scores: mobility_score, stability_score, strength_score, endurance_score, technique_score, recovery_score
3. Update Chart.js radar chart with real data
4. If no pillar data exists, show "Complete your first assessment" message
5. Add trend indicators (up/down arrows vs last week)
6. Make chart clickable → show detailed pillar history

**Database Query**:
```javascript
const { data, error } = await supabase
  .from('pillar_progress')
  .select('*')
  .eq('athlete_id', userId)
  .order('week_number', { ascending: false })
  .limit(1)
  .single();
```

**Expected Result**: Chart displays real pillar scores with visual progress indicators

---

### Task 1.3: Next Assessment Card

**Current State**: Shows placeholder "90 days"  
**Target**: Calculate actual next assessment date based on last assessment

**Implementation Steps**:
1. Query `assessments` table for most recent assessment
2. Calculate next assessment date (last_assessment + 90 days)
3. Show days remaining until next assessment
4. Add progress bar (0-90 days)
5. Button: "Take Assessment Now" or "Schedule Assessment"
6. If overdue, show warning badge

**Database Query**:
```javascript
const { data, error } = await supabase
  .from('assessments')
  .select('created_at')
  .eq('athlete_id', userId)
  .order('created_at', { ascending: false })
  .limit(1)
  .single();

// Calculate next date
const lastAssessment = new Date(data.created_at);
const nextAssessment = new Date(lastAssessment);
nextAssessment.setDate(nextAssessment.getDate() + 90);
const daysRemaining = Math.ceil((nextAssessment - new Date()) / (1000 * 60 * 60 * 24));
```

**Expected Result**: Shows accurate days remaining with visual progress

---

### Task 1.4: Verify All Existing Cards

**Cards to Test**:
- ✅ Weekly Mileage Goal (already working)
- ✅ Monthly Distance (already working)
- 🔍 This Week Progress (verify calculation)
- 🔍 Last 7 Days RPE (verify query)
- 🔍 Injury Status (verify active injuries count)
- 🔍 AIFRI Score (verify latest score)
- 🔍 Streak (verify consecutive days logic)

**Testing Checklist**:
- [ ] All cards load without errors
- [ ] All cards show real data (not placeholders)
- [ ] Loading states work correctly
- [ ] Error states show helpful messages
- [ ] Empty states guide user to take action
- [ ] Click handlers work (Coming Soon toasts)
- [ ] Mobile responsive on all cards

---

## 📋 PHASE 2: STRAVA INTEGRATION

**Goal**: Connect Strava accounts and auto-sync workouts to activity_logs

### Task 2.1: Strava OAuth Setup

**What's Needed**:
1. Create Strava App at https://www.strava.com/settings/api
2. Get Client ID and Client Secret
3. Set Redirect URI: `https://www.akura.in/strava/callback`
4. Store credentials as Cloudflare secrets (or .dev.vars for local)

**Implementation**:
1. Create `/strava/connect` button on dashboard
2. OAuth flow: Redirect to Strava authorization
3. Callback handler: Exchange code for tokens
4. Store tokens in new table: `strava_connections`

**Database Table: strava_connections**:
```sql
CREATE TABLE strava_connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id) NOT NULL,
  strava_athlete_id BIGINT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  scope TEXT,
  connected_at TIMESTAMP DEFAULT NOW(),
  last_sync_at TIMESTAMP,
  sync_enabled BOOLEAN DEFAULT true,
  UNIQUE(athlete_id)
);
```

---

### Task 2.2: Strava Sync Service

**Functionality**:
1. Fetch activities from Strava API
2. Transform Strava activity → activity_logs format
3. Insert new activities (check for duplicates)
4. Handle token refresh (if expired)
5. Sync on demand or scheduled (daily)

**Strava API Endpoints**:
- Get Athlete Activities: `GET /athlete/activities`
- Get Activity Details: `GET /activities/{id}`
- Refresh Token: `POST /oauth/token`

**Mapping**:
```javascript
Strava Activity → activity_logs:
- start_date → activity_date
- distance (meters) → distance_km (convert)
- moving_time (seconds) → duration_minutes
- type → activity_type (Run, TrailRun, etc.)
- average_heartrate → (optional field to add)
- suffer_score → (can map to RPE approximation)
```

**Hono API Endpoints**:
```typescript
POST /api/strava/connect - Initiate OAuth flow
GET /api/strava/callback - OAuth callback handler
POST /api/strava/sync - Manual sync trigger
POST /api/strava/disconnect - Remove connection
GET /api/strava/status - Check connection status
```

---

### Task 2.3: Strava Settings Page

**UI Components**:
1. Connection status card (Connected / Not Connected)
2. Last sync time
3. Sync history (recent imports)
4. Sync settings:
   - Auto-sync enabled/disabled
   - Sync frequency (daily, manual)
   - Activity types to sync (Run, TrailRun, etc.)
5. "Sync Now" button
6. "Disconnect Strava" button

**File**: `frontend/strava-settings.html`

---

## 📋 PHASE 3: ENHANCED FEATURES

### Task 3.1: Workout Detail Page

**Purpose**: View full details of any workout from history

**URL**: `/workout/{id}`

**Content**:
- Activity date, time, location
- Distance, duration, pace
- RPE, pain level, notes
- Route map (if GPS data available from Strava)
- Heart rate chart (if available)
- Split times (if available)
- Edit/Delete buttons

---

### Task 3.2: Coach Dashboard Enhancements

**Current**: Basic layout exists  
**Target**: Full coach functionality

**Features**:
1. List all athletes (profiles where role = 'athlete')
2. Athlete cards showing:
   - Name, email, photo
   - Current AIFRI score with risk level badge
   - Days since last workout
   - Active injuries count
   - Weekly mileage vs goal
   - Last assessment date
3. Click athlete → view full athlete details
4. Filters: Sort by risk level, activity, injuries
5. Search by name

---

### Task 3.3: Advanced Analytics

**Dashboard Additions**:
1. Weekly Summary Card:
   - Total distance
   - Total duration
   - Average pace
   - Total elevation (if Strava)
2. Monthly Trends Chart:
   - Distance over time
   - RPE trends
   - Injury incidents
3. Injury Prevention Insights:
   - Risk factors detected
   - Recommendations
   - Trend analysis

---

## 📋 PHASE 4: TESTING & DEPLOYMENT

### Task 4.1: End-to-End Testing

**Test Scenarios**:
1. New user registration → assessment → dashboard
2. Existing user login → dashboard loads with data
3. Log workout manually → appears in history
4. Connect Strava → sync activities → verify in history
5. Weekly mileage updates in real-time
6. All cards clickable and show correct data
7. Mobile responsive on all pages
8. Logout and re-login preserves state

### Task 4.2: Production Deployment

**Steps**:
1. Commit all changes to git
2. Push to GitHub main branch
3. Vercel auto-deploys from main
4. Test at https://www.akura.in
5. Monitor for errors (Vercel logs)
6. Set up error tracking (Sentry optional)

---

## 🗓️ Estimated Timeline

### Week 1: Dashboard Completion
- Day 1-2: Today's Workout Card + 6-Pillar Chart ✅
- Day 3: Next Assessment Card + Verify All Cards ✅
- Day 4: Testing and bug fixes ✅
- Day 5: Deploy to production ✅

### Week 2: Strava Integration
- Day 1-2: Strava OAuth setup + Database table ✅
- Day 3-4: Strava sync service + API endpoints ✅
- Day 5: Strava settings page + Testing ✅

### Week 3: Enhanced Features
- Day 1-2: Workout detail pages ✅
- Day 3: Coach dashboard enhancements ✅
- Day 4-5: Advanced analytics + Testing ✅

### Week 4: Polish & Deploy
- Day 1-3: End-to-end testing ✅
- Day 4: Bug fixes and refinements ✅
- Day 5: Final production deployment ✅

---

## 🎯 Current Priority

**RIGHT NOW**: Complete Task 1.1 - Today's Workout Card

Let's start implementing this immediately!

---

## 📞 Contact & Support

- Production: https://www.akura.in
- GitHub: https://github.com/CoachKura/safestride-akura
- Supabase: https://yawxlwcniqfspcgefuro.supabase.co

---

**Last Updated**: January 31, 2026  
**Status**: Phase 1 In Progress  
**Next Task**: Fix Today's Workout Card
