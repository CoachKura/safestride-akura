# 🏃 Strava Integration Setup Guide

**Complete guide to integrate Strava with SafeStride**

---

## 📝 What You'll Get

### Real Training Data
- ✅ Automatic weekly mileage calculation
- ✅ Actual training frequency (not self-reported)
- ✅ Real pace data from activities
- ✅ Personal bests (5K, 10K, Half, Marathon)
- ✅ Training consistency patterns
- ✅ Recent performance trends
- ✅ Heart rate data (if available)

### Better AISRI Scores
- ✅ **Intensity Pillar** - Real training load from activities
- ✅ **Consistency Pillar** - Actual workout frequency
- ✅ **Fatigue Pillar** - Training load trends
- ✅ **Adaptability Pillar** - Performance progression

---

## 🔑 Step 1: Register Strava API Application

### 1.1 Create Strava Developer Account

1. Go to https://www.strava.com/settings/api
2. Log in with your Strava account
3. Click **"Create & Manage Your App"**

### 1.2 Fill Out Application Form

**Required Information:**

| Field | Value |
|-------|-------|
| **Application Name** | SafeStride |
| **Category** | Training |
| **Club** | Leave blank |
| **Website** | Your app website or `https://safestride.app` |
| **Application Description** | AI-powered running injury prevention app with biomechanics assessment and personalized recovery programs |
| **Authorization Callback Domain** | `supabase.co` |

**CRITICAL:** Authorization Callback Domain must be `supabase.co` for Supabase OAuth to work

### 1.3 Get Your Credentials

After creating the app, you'll receive:

```
Client ID: 123456
Client Secret: abcdef1234567890abcdef1234567890abcdef12
```

**⚠️ IMPORTANT:** Keep Client Secret secure! Never commit to git.

---

## 🗄️ Step 2: Database Migration

### 2.1 Create Strava Tables

Run this migration in Supabase SQL Editor:

```sql
-- Strava Integration Schema
-- Run this in Supabase SQL Editor

BEGIN;

-- Store Strava OAuth tokens
CREATE TABLE IF NOT EXISTS public.strava_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strava_athlete_id BIGINT UNIQUE NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at BIGINT NOT NULL,
  scope TEXT,
  connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_sync_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(athlete_id)
);

-- Store Strava athlete profile
CREATE TABLE IF NOT EXISTS public.strava_athletes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strava_athlete_id BIGINT UNIQUE NOT NULL,
  username TEXT,
  firstname TEXT,
  lastname TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  sex TEXT,
  profile_medium TEXT,
  profile TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(athlete_id)
);

-- Store Strava activities
CREATE TABLE IF NOT EXISTS public.strava_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strava_activity_id BIGINT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  distance NUMERIC(10,2), -- in meters
  moving_time INTEGER, -- in seconds
  elapsed_time INTEGER,
  total_elevation_gain NUMERIC(8,2),
  sport_type TEXT,
  workout_type INTEGER,
  start_date TIMESTAMP WITH TIME ZONE,
  start_date_local TIMESTAMP WITH TIME ZONE,
  timezone TEXT,
  average_speed NUMERIC(6,2), -- in m/s
  max_speed NUMERIC(6,2),
  average_heartrate NUMERIC(6,2),
  max_heartrate INTEGER,
  average_cadence NUMERIC(6,2),
  has_heartrate BOOLEAN DEFAULT FALSE,
  suffer_score NUMERIC(6,2),
  perceived_exertion INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Store Personal Bests
CREATE TABLE IF NOT EXISTS public.strava_personal_bests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  distance_type TEXT NOT NULL, -- '5k', '10k', 'half_marathon', 'marathon'
  distance_meters INTEGER NOT NULL,
  time_seconds INTEGER NOT NULL,
  pace_per_km NUMERIC(6,2), -- in min/km
  activity_id UUID REFERENCES public.strava_activities(id),
  achieved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(athlete_id, distance_type)
);

-- Store weekly training stats
CREATE TABLE IF NOT EXISTS public.strava_weekly_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  total_distance NUMERIC(10,2), -- in meters
  total_time INTEGER, -- in seconds
  total_elevation_gain NUMERIC(10,2),
  activity_count INTEGER DEFAULT 0,
  average_pace NUMERIC(6,2), -- in min/km
  average_heartrate NUMERIC(6,2),
  training_load NUMERIC(8,2), -- calculated metric
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(athlete_id, week_start_date)
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_strava_connections_athlete ON public.strava_connections(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_athlete ON public.strava_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_date ON public.strava_activities(start_date DESC);
CREATE INDEX IF NOT EXISTS idx_strava_pbs_athlete ON public.strava_personal_bests(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_weekly_athlete ON public.strava_weekly_stats(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_weekly_date ON public.strava_weekly_stats(week_start_date DESC);

-- Enable Row Level Security
ALTER TABLE public.strava_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strava_athletes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strava_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strava_personal_bests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strava_weekly_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data
DROP POLICY IF EXISTS "Users can view own Strava connections" ON public.strava_connections;
CREATE POLICY "Users can view own Strava connections"
  ON public.strava_connections FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can manage own Strava connections" ON public.strava_connections;
CREATE POLICY "Users can manage own Strava connections"
  ON public.strava_connections FOR ALL
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can view own Strava profile" ON public.strava_athletes;
CREATE POLICY "Users can view own Strava profile"
  ON public.strava_athletes FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can manage own Strava profile" ON public.strava_athletes;
CREATE POLICY "Users can manage own Strava profile"
  ON public.strava_athletes FOR ALL
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can view own activities" ON public.strava_activities;
CREATE POLICY "Users can view own activities"
  ON public.strava_activities FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can manage own activities" ON public.strava_activities;
CREATE POLICY "Users can manage own activities"
  ON public.strava_activities FOR ALL
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can view own PBs" ON public.strava_personal_bests;
CREATE POLICY "Users can view own PBs"
  ON public.strava_personal_bests FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can manage own PBs" ON public.strava_personal_bests;
CREATE POLICY "Users can manage own PBs"
  ON public.strava_personal_bests FOR ALL
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can view own weekly stats" ON public.strava_weekly_stats;
CREATE POLICY "Users can view own weekly stats"
  ON public.strava_weekly_stats FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can manage own weekly stats" ON public.strava_weekly_stats;
CREATE POLICY "Users can manage own weekly stats"
  ON public.strava_weekly_stats FOR ALL
  USING (auth.uid() = athlete_id);

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;
```

### 2.2 Verify Migration

```sql
-- Check tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'strava%';

-- Expected output:
-- strava_connections
-- strava_athletes
-- strava_activities
-- strava_personal_bests
-- strava_weekly_stats
```

---

## 🔐 Step 3: Configure Supabase OAuth

### 3.1 Add Strava Provider in Supabase Dashboard

1. Go to **Supabase Dashboard** → Your Project
2. Click **Authentication** → **Providers**
3. Find **Strava** in the list
4. Enable Strava provider
5. Enter your credentials:
   - **Client ID:** `123456` (from Step 1)
   - **Client Secret:** `abcdef123...` (from Step 1)
6. Copy the **Redirect URL** shown (e.g., `https://yourproject.supabase.co/auth/v1/callback`)
7. Click **Save**

### 3.2 Update Strava API Settings

1. Go back to https://www.strava.com/settings/api
2. Update **Authorization Callback Domain** to match your Supabase URL
   - Example: `yourproject.supabase.co`
3. Save changes

---

## 📱 Step 4: Flutter Integration

### 4.1 Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  http: ^1.1.0
  intl: ^0.18.0
  fl_chart: ^0.65.0  # For visualizing training data
```

Run:
```bash
flutter pub get
```

### 4.2 Files Already Created

```
lib/
├── services/
│   └── strava_service.dart              ✅ Created
└── screens/
    └── strava_connect_screen.dart       ✅ Created
```

---

## 🎯 Step 5: How It Will Work

### User Flow:

```
1. User opens SafeStride app
   ↓
2. Taps "Connect Strava" button
   ↓
3. Redirected to Strava OAuth page
   ↓
4. User authorizes SafeStride
   ↓
5. Redirected back to app with access token
   ↓
6. App fetches athlete data & activities
   ↓
7. Calculates weekly mileage, PBs, etc.
   ↓
8. Stores in Supabase database
   ↓
9. AISRI assessment auto-fills training data
   ↓
10. More accurate AISRI scores!
```

### Data Sync:

```
Initial Sync:
- Fetch last 200 activities (Strava API limit)
- Calculate all PBs
- Generate weekly stats for last 12 weeks

Ongoing Sync:
- Check for new activities daily
- Update weekly stats
- Recalculate PBs if new records
```

---

## 📊 What Data We'll Use for AISRI

### Pillar Updates:

| Pillar | Before (Manual) | After (Strava) |
|--------|----------------|----------------|
| **Intensity** | Self-reported mileage | Real weekly distance from activities |
| **Consistency** | Self-reported frequency | Actual workout count per week |
| **Fatigue** | Perceived fatigue only | Training load + suffer score + trends |
| **Adaptability** | Manual input | Performance trends + pace progression |

### Specific Metrics:

1. **Weekly Mileage**
   ```sql
   SELECT SUM(distance) / 1000 as weekly_km
   FROM strava_activities
   WHERE athlete_id = ?
     AND start_date >= NOW() - INTERVAL '7 days'
   ```

2. **Training Frequency**
   ```sql
   SELECT COUNT(*) as activities_per_week
   FROM strava_activities
   WHERE athlete_id = ?
     AND start_date >= NOW() - INTERVAL '7 days'
   ```

3. **Average Pace**
   ```sql
   SELECT AVG(1000 / (average_speed * 60)) as avg_pace_per_km
   FROM strava_activities
   WHERE athlete_id = ?
     AND start_date >= NOW() - INTERVAL '30 days'
   ```

4. **Personal Bests**
   ```sql
   SELECT distance_type, time_seconds, pace_per_km
   FROM strava_personal_bests
   WHERE athlete_id = ?
   ORDER BY distance_meters
   ```

---

## 🔒 Security Considerations

### Token Storage
- ✅ Tokens stored in Supabase (encrypted at rest)
- ✅ Never stored in app local storage
- ✅ Refresh tokens used to get new access tokens
- ✅ Row-level security prevents data leaks

### API Rate Limits
- ✅ Strava API: 100 requests per 15 minutes, 1000 per day
- ✅ Implement exponential backoff
- ✅ Cache data locally
- ✅ Sync in background, not on demand

### User Privacy
- ✅ User controls when to sync
- ✅ Can disconnect Strava anytime
- ✅ Data only visible to user (RLS)
- ✅ No sharing without consent

---

## 📈 Benefits for AISRI

### More Accurate Scores
- **Before:** User says "I run 40km/week" (maybe exaggerated)
- **After:** Real data shows 28km/week average

### Better Insights
- Detect overtraining (high weekly mileage + low recovery)
- Identify inconsistency (sporadic training patterns)
- Spot fatigue (declining pace over weeks)
- Track adaptation (improving PBs)

### Personalized Recommendations
- "Your 4-week average is 32km, but this week you did 55km (+72%). High injury risk!"
- "You ran 6 times last week but only 2 this week. Consistency is key for Pillar 6."
- "Your 10K PB improved by 2 minutes in 8 weeks. Great adaptation!"

---

## 🧪 Testing Checklist

- [ ] Strava API application created
- [ ] Client ID & Secret configured in Supabase
- [ ] Database migration run successfully
- [ ] OAuth flow works (connect → authorize → redirect back)
- [ ] Activities fetched and stored
- [ ] Weekly stats calculated correctly
- [ ] PBs identified accurately
- [ ] AISRI scores use real Strava data
- [ ] Sync runs in background
- [ ] Disconnect Strava works

---

## 🚀 Next Steps

1. **Register Strava API app** (Step 1)
2. **Run database migration** (Step 2)
3. **Configure Supabase OAuth** (Step 3)
4. **Test with real Strava account**
5. **Integrate with evaluation form**

---

**Last Updated:** 2026-02-04  
**Status:** Setup guide complete, ready for implementation
