-- 🔍 DATABASE SCHEMA VERIFICATION SCRIPT
-- Run this in Supabase SQL Editor to check your schema

-- ========================================
-- 1. CHECK IF TABLES EXIST
-- ========================================

SELECT 
  table_name,
  CASE 
    WHEN table_name IN (
      'athlete_profiles',
      'coach_profiles', 
      'exercises',
      'protocols',
      'athlete_protocols',
      'workouts',
      'athlete_calendar',
      'notifications',
      'user_roles',
      'protocol_exercises'
    ) THEN '✅ EXISTS'
    ELSE '⚠️ UNEXPECTED TABLE'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ========================================
-- 2. CHECK ATHLETE_PROFILES TABLE
-- ========================================

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'athlete_profiles'
ORDER BY ordinal_position;

-- Expected columns:
-- id, user_id, date_of_birth, gender, height_cm, weight_kg, 
-- running_experience_years, injury_history, training_goal,
-- latest_aisri_score, mobility_score, strength_score, balance_score,
-- flexibility_score, endurance_score, power_score,
-- last_assessment_date, created_at, updated_at

-- ========================================
-- 3. CHECK WORKOUTS TABLE
-- ========================================

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'workouts'
ORDER BY ordinal_position;

-- Expected columns:
-- id, athlete_protocol_id, workout_name, workout_type,
-- exercises (JSONB), estimated_duration_minutes, difficulty,
-- equipment_needed, created_at

-- ========================================
-- 4. CHECK EXERCISES TABLE
-- ========================================

SELECT COUNT(*) as exercise_count FROM exercises;
-- Expected: 15 or more

SELECT 
  id,
  exercise_name,
  category
FROM exercises
ORDER BY category, exercise_name;

-- ========================================
-- 5. CHECK YOUR USER
-- ========================================

-- Replace 'YOUR_USER_ID' with your actual user ID
-- You can find it in the app logs (e1f2abfc-a1bb-4a85-b616-fec751de5dc3)

SELECT * FROM athlete_profiles 
WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3';

-- If empty, you need to create one:
-- INSERT INTO athlete_profiles (user_id) 
-- VALUES ('e1f2abfc-a1bb-4a85-b616-fec751de5dc3');

-- ========================================
-- 6. CHECK MISSING COLUMNS
-- ========================================

-- Check if profiles table exists (it should NOT - use athlete_profiles instead)
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'profiles' 
  AND table_schema = 'public';

-- If profiles exists, check what columns it has:
SELECT column_name 
FROM information_schema.columns
WHERE table_name = 'profiles';
