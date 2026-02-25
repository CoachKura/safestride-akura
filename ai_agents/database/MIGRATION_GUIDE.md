# 🗄️ DATABASE SCHEMA MIGRATION GUIDE

## 📋 Overview

This guide will help you apply the **Athlete Lifecycle Management System** database schema to your Supabase instance.

**Total New Tables:** 6  
**Total Views:** 3  
**Total Functions:** 2  
**Total Triggers:** 6

---

## 🚀 Quick Migration (Recommended)

### **Option 1: Via Supabase Dashboard (Easiest)**

1. **Open Supabase SQL Editor:**
   - Go to: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql
   - Or: Dashboard → SQL Editor → New query

2. **Copy & Paste Schema:**
   - Open `athlete_lifecycle_schema.sql`
   - Copy entire file content
   - Paste into SQL Editor

3. **Execute:**
   - Click **RUN** button
   - Wait for execution (should take ~5-10 seconds)
   - Check for success message: ✅ "Success. No rows returned"

4. **Verify:**
   - Go to: Dashboard → Table Editor
   - You should see 6 new tables:
     - `athlete_detailed_profile`
     - `baseline_assessment_plan`
     - `daily_performance_tracking`
     - `adaptive_workout_generation`
     - `athlete_ability_progression`
     - `existing_athlete_import`

---

### **Option 2: Via Supabase CLI**

```powershell
# Navigate to project directory
cd C:\safestride

# Login to Supabase (if not already logged in)
npx supabase login

# Link to your project
npx supabase link --project-ref xzxnnswggwqtctcgpocr

# Apply migration
npx supabase db push

# Or create a new migration file
npx supabase migration new athlete_lifecycle_system
# Then copy contents of athlete_lifecycle_schema.sql into the generated migration file
# Then run: npx supabase db push
```

---

### **Option 3: Via PowerShell Script**

```powershell
# Run from project root
cd C:\safestride\ai_agents\database

# Execute schema directly
$env:SUPABASE_DB_URL = "your-database-url-here"
psql $env:SUPABASE_DB_URL -f athlete_lifecycle_schema.sql
```

---

## 📊 Schema Structure Overview

### **1. athlete_detailed_profile**

**Purpose:** Complete athlete information beyond basic profile  
**Key Fields:**

- `current_level`: beginner | intermediate | advanced
- `primary_goal`: 5K, 10K, Half Marathon, etc.
- `goal_type`: time_based | pace_based
- `before_signup_*`: Baseline metrics from Strava history
- `baseline_assessment_status`: Tracks 14-day assessment progress

**Relationships:**

- References: `athlete_profiles.athlete_id` (UNIQUE)

---

### **2. baseline_assessment_plan**

**Purpose:** 14-day structured assessment plan  
**Key Fields:**

- `day_number`: 1-14
- `workout_type`: easy_run | tempo_run | interval | strength | rom | rest
- `expected_*`: Target performance metrics
- `completion_status`: scheduled | completed | skipped

**Relationships:**

- References: `athlete_profiles.athlete_id`
- Links to: `daily_performance_tracking` (after completion)

---

### **3. daily_performance_tracking**

**Purpose:** Track GIVEN | EXPECTED | RESULT  
**Key Fields:**

- `given_*`: What was assigned
- `expected_*`: What should be achieved
- `actual_*`: What actually happened
- `performance_label`: BEST | GREAT | GOOD | AVERAGE | POOR | NEEDS_ATTENTION
- `performance_score`: 0-100
- `ability_deduction`: Daily ability assessment

**Relationships:**

- References: `athlete_profiles.athlete_id`
- References: `baseline_assessment_plan.id` (assigned_workout_id)
- Links to: Strava activity via `strava_activity_id`

---

### **4. adaptive_workout_generation**

**Purpose:** Smart workout generation based on performance  
**Key Fields:**

- `workout_plan`: Complete workout structure (JSONB)
- `based_on_performance_ids`: Array of previous performance IDs
- `adaptation_reason`: Why this workout was chosen
- `progressive_overload_percent`: Safe progression rate
- `target_hr_zone`: Always focuses on 80% HR
- `injury_risk_score`: Safety check
- `goal_progress_percent`: Progress toward race goal

**Relationships:**

- References: `athlete_profiles.athlete_id`
- Links to: `daily_performance_tracking` (multiple, for analysis)
- Links to: `daily_performance_tracking.id` (completed_performance_id, after execution)

---

### **5. athlete_ability_progression**

**Purpose:** Daily ability deduction and progression tracking  
**Key Fields:**

- `overall_ability_score`: 0-100 (main metric)
- Component scores: endurance, speed, strength, form, consistency
- `current_sustainable_pace`: Pace at 80% HR
- `goal_pace_gap`: Distance from goal
- `goal_readiness_percent`: 0-100 race readiness
- `injury_risk_level`: low | moderate | high | very_high
- `acute_chronic_workload_ratio`: ACWR (injury prevention)

**Relationships:**

- References: `athlete_profiles.athlete_id`
- UNIQUE constraint on: `(athlete_id, assessment_date)`

---

### **6. existing_athlete_import**

**Purpose:** Import existing athletes from Google Forms CSV  
**Key Fields:**

- `import_batch_id`: Groups imports from same file
- `raw_data`: Original form/CSV data (JSONB)
- `parsed_profile`: Structured athlete data
- `import_status`: pending | athlete_created | invitation_sent | completed
- `strava_connected`: Track Strava connection status
- `signin_completed`: Track app/web signin

**Relationships:**

- References: `athlete_profiles.athlete_id` (created_athlete_id)

---

## 🔍 Views Created

### **1. athlete_current_status**

Quick overview of all athletes with current ability, goals, and progress.

```sql
SELECT * FROM athlete_current_status
WHERE baseline_assessment_status = 'in_progress';
```

---

### **2. recent_performance_summary**

Last 7 days performance summary per athlete.

```sql
SELECT * FROM recent_performance_summary
WHERE avg_performance_score > 80;
```

---

### **3. upcoming_workouts**

All scheduled future workouts for all athletes.

```sql
SELECT * FROM upcoming_workouts
WHERE athlete_id = 'your-athlete-id';
```

---

## 🔧 Functions Created

### **1. calculate_performance_label()**

Automatically calculates performance label from metrics.

```sql
SELECT calculate_performance_label(
    105.5,  -- actual_vs_expected: 105.5%
    100.0,  -- completion_percent: 100%
    85.0    -- hr_adherence: 85%
);
-- Returns: 'GREAT'
```

---

### **2. update_updated_at_column()**

Automatically updates `updated_at` timestamp on row updates (applied via triggers).

---

## ✅ Verification Checklist

After applying the schema, verify:

### **1. Tables Created:**

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'athlete_detailed_profile',
    'baseline_assessment_plan',
    'daily_performance_tracking',
    'adaptive_workout_generation',
    'athlete_ability_progression',
    'existing_athlete_import'
);
```

**Expected:** 6 rows

---

### **2. Views Created:**

```sql
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public';
```

**Expected:** At least 3 views (athlete_current_status, recent_performance_summary, upcoming_workouts)

---

### **3. Triggers Active:**

```sql
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE '%updated_at%';
```

**Expected:** 6 triggers (one per table)

---

### **4. Indexes Created:**

```sql
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename LIKE '%athlete%';
```

**Expected:** Multiple indexes for performance optimization

---

## 🧪 Test Data Insertion

### **Test 1: Create Detailed Profile**

```sql
-- First, ensure you have a test athlete in athlete_profiles
-- Then insert detailed profile:

INSERT INTO athlete_detailed_profile (
    athlete_id,
    current_level,
    primary_goal,
    goal_type,
    goal_target_time,
    target_race_date,
    before_signup_weekly_volume_km,
    before_signup_avg_pace,
    current_max_hr,
    current_resting_hr,
    training_frequency_per_week
) VALUES (
    'your-test-athlete-id-here'::UUID,
    'beginner',
    '10K',
    'time_based',
    '00:60:00'::interval,
    CURRENT_DATE + INTERVAL '16 weeks',
    10.0,
    '00:07:30'::interval,
    190,
    60,
    3
);
```

---

### **Test 2: Create 14-Day Baseline Plan**

```sql
INSERT INTO baseline_assessment_plan (
    athlete_id,
    day_number,
    workout_date,
    workout_type,
    workout_category,
    workout_details,
    expected_duration_minutes,
    expected_distance_km,
    expected_pace_min,
    expected_pace_max,
    coach_instructions
) VALUES (
    'your-test-athlete-id-here'::UUID,
    1,
    CURRENT_DATE,
    'easy_run',
    'running',
    '{"type": "easy_run", "distance": 3, "pace_target": "7:30/km"}'::jsonb,
    23,
    3.0,
    '00:07:00'::interval,
    '00:08:00'::interval,
    'Welcome run! Keep it comfortable and easy. You should be able to chat.'
);
```

---

### **Test 3: Query Views**

```sql
-- Check athlete status
SELECT * FROM athlete_current_status LIMIT 5;

-- Check recent performance
SELECT * FROM recent_performance_summary LIMIT 5;

-- Check upcoming workouts
SELECT * FROM upcoming_workouts LIMIT 5;
```

---

## 🔒 Row Level Security (RLS)

**Important:** After schema creation, configure RLS policies in Supabase:

### **Enable RLS on all tables:**

```sql
ALTER TABLE athlete_detailed_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE baseline_assessment_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_performance_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE adaptive_workout_generation ENABLE ROW LEVEL SECURITY;
ALTER TABLE athlete_ability_progression ENABLE ROW LEVEL SECURITY;
ALTER TABLE existing_athlete_import ENABLE ROW LEVEL SECURITY;
```

### **Example Policy: Athletes can only see their own data**

```sql
-- Detailed Profile
CREATE POLICY "Athletes can view own profile"
ON athlete_detailed_profile FOR SELECT
USING (auth.uid()::text = athlete_id::text);

CREATE POLICY "Athletes can update own profile"
ON athlete_detailed_profile FOR UPDATE
USING (auth.uid()::text = athlete_id::text);

-- Repeat similar policies for other tables
-- Or use service role key in backend for admin access
```

---

## 🚨 Common Issues & Solutions

### **Issue 1: "relation athlete_profiles does not exist"**

**Solution:** Ensure base `athlete_profiles` table exists first. This schema references it.

---

### **Issue 2: "uuid-ossp extension not found"**

**Solution:** Run manually:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

---

### **Issue 3: "permission denied for schema public"**

**Solution:** Check database user permissions or use Supabase Dashboard SQL Editor.

---

### **Issue 4: RLS blocking inserts**

**Solution:**

- Use service role key in backend (bypasses RLS)
- Or configure appropriate RLS policies
- Or temporarily disable RLS for testing

---

## 📊 Database Size Estimation

**Per Athlete (Estimated):**

- `athlete_detailed_profile`: ~2 KB
- `baseline_assessment_plan`: ~14 rows × 1 KB = 14 KB
- `daily_performance_tracking`: ~365 rows/year × 2 KB = 730 KB/year
- `adaptive_workout_generation`: ~365 rows/year × 2 KB = 730 KB/year
- `athlete_ability_progression`: ~365 rows/year × 1 KB = 365 KB/year

**Total per athlete per year:** ~1.8 MB

**For 1000 athletes:** ~1.8 GB/year (very manageable)

---

## 🎯 Next Steps

After successful migration:

1. ✅ **Verify all tables created**
2. ✅ **Configure RLS policies** (if using auth)
3. ✅ **Insert test data**
4. ✅ **Test queries and views**
5. ✅ **Build Python modules** to interact with schema
6. ✅ **Update API endpoints** to use new tables

---

## 📞 Need Help?

If you encounter issues:

1. Check Supabase logs: Dashboard → Logs
2. Verify SQL syntax in SQL Editor
3. Check user permissions
4. Review error messages carefully

---

**🎉 Schema ready to power the complete athlete lifecycle system!**
