# Database Migration Instructions

## Overview
This document explains how to apply the `003_modern_safestride_schema.sql` migration to add modern platform features.

## What This Migration Adds

### New Tables:
1. **physical_assessments** - Store ROM, strength, balance, mobility test results
2. **assessment_media** - Store images/videos captured during assessments
3. **training_plans** - 12-week training programs linked to AISRI scores
4. **daily_workouts** - Individual daily workouts from training plans
5. **workout_completions** - Completed workouts with athlete feedback
6. **evaluation_schedule** - Monthly re-evaluation reminders
7. **aisri_score_history** - Historical AISRI score tracking
8. **training_load** - ACR (Acute:Chronic Ratio) calculations

### New Views:
- `v_latest_aisri_scores` - Latest score per athlete
- `v_upcoming_evaluations` - Scheduled evaluations
- `v_coach_athletes` - Coach's athlete summary

### New Functions:
- `create_next_evaluation()` - Schedule next monthly evaluation
- `calculate_aisri_from_assessment()` - Calculate AISRI from physical tests

## How to Apply Migration

### Method 1: Supabase Dashboard (RECOMMENDED)

1. Go to Supabase SQL Editor:
   ```
   https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/sql/new
   ```

2. Open the migration file:
   ```bash
   cat /home/user/webapp/migrations/003_modern_safestride_schema.sql
   ```

3. Copy the entire SQL content

4. Paste into SQL Editor

5. Click "Run" button

6. Verify success - should see "Success. No rows returned"

### Method 2: Supabase CLI

```bash
# Install Supabase CLI (if not installed)
npm install -g supabase

# Link to project
supabase link --project-ref bdisppaxbvygsspcuymb

# Apply migration
supabase db push

# Or run specific migration
supabase db execute --file migrations/003_modern_safestride_schema.sql
```

### Method 3: PostgreSQL Client (psql)

```bash
# Requires PostgreSQL client installed
psql "postgresql://postgres:YOUR_PASSWORD@db.bdisppaxbvygsspcuymb.supabase.co:5432/postgres" \
  -f migrations/003_modern_safestride_schema.sql
```

## Verification

After applying migration, verify tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'physical_assessments',
    'assessment_media',
    'training_plans',
    'daily_workouts',
    'workout_completions',
    'evaluation_schedule',
    'aisri_score_history',
    'training_load'
  )
ORDER BY table_name;
```

Expected result: 8 tables listed.

## Post-Migration Steps

1. **Test new tables**:
   ```sql
   -- Check profiles table extensions
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'profiles' 
     AND column_name IN ('role', 'coach_id', 'onboarding_completed', 'gender', 'weight', 'height');
   ```

2. **Verify RLS policies**:
   ```sql
   SELECT tablename, policyname 
   FROM pg_policies 
   WHERE schemaname = 'public' 
     AND tablename LIKE '%assessment%' OR tablename LIKE '%training%';
   ```

3. **Test functions**:
   ```sql
   -- Test evaluation scheduling
   SELECT create_next_evaluation('athlete_uuid_here');
   ```

## Rollback (if needed)

To remove migration changes:

```sql
-- Drop new tables (in reverse order due to foreign keys)
DROP TABLE IF EXISTS public.assessment_media CASCADE;
DROP TABLE IF EXISTS public.physical_assessments CASCADE;
DROP TABLE IF EXISTS public.workout_completions CASCADE;
DROP TABLE IF EXISTS public.daily_workouts CASCADE;
DROP TABLE IF EXISTS public.training_plans CASCADE;
DROP TABLE IF EXISTS public.evaluation_schedule CASCADE;
DROP TABLE IF EXISTS public.aisri_score_history CASCADE;
DROP TABLE IF EXISTS public.training_load CASCADE;

-- Drop views
DROP VIEW IF EXISTS public.v_latest_aisri_scores CASCADE;
DROP VIEW IF EXISTS public.v_upcoming_evaluations CASCADE;
DROP VIEW IF EXISTS public.v_coach_athletes CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS public.create_next_evaluation(UUID);
DROP FUNCTION IF EXISTS public.calculate_aisri_from_assessment(UUID);

-- Remove added columns from profiles (if needed)
ALTER TABLE public.profiles DROP COLUMN IF EXISTS role;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS coach_id;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS onboarding_completed;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS gender;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS weight;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS height;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS max_hr;
```

## Notes

- Migration uses `IF NOT EXISTS` checks to be idempotent (safe to run multiple times)
- All new tables have Row Level Security (RLS) enabled
- Policies ensure athletes only see their own data
- Coaches can see data for their assigned athletes
- Service role key required for some operations

## Support

If you encounter errors:
1. Check Supabase dashboard logs
2. Verify database connection
3. Ensure you have proper permissions (service_role or postgres)
4. Review error messages for specific table/column conflicts

## Next Steps After Migration

Once migration is complete, you can:
1. ✅ Access new athlete onboarding flow
2. ✅ Use evaluation forms with image capture
3. ✅ View modern athlete/coach dashboards
4. ✅ Track training plans and workouts
5. ✅ Monitor AISRI scores over time
6. ✅ Schedule monthly re-evaluations
