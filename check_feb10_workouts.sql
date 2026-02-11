-- Check for workouts on February 10, 2026
-- Run this in Supabase SQL Editor

-- CORRECT QUERY with actual column names:

-- 1. Check all workouts from Feb 8-10
SELECT 
    created_at,
    workout_name,
    title,
    workout_type,
    synced_from,
    external_id,
    strava_activity_id
FROM workouts
WHERE created_at >= '2026-02-08'
  AND created_at < '2026-02-11'
ORDER BY created_at DESC;

-- 2. Count workouts by date
SELECT 
    DATE(created_at) as date,
    COUNT(*) as workout_count,
    STRING_AGG(workout_name, ', ') as workouts
FROM workouts
WHERE created_at >= '2026-02-08'
  AND created_at < '2026-02-11'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- 3. Check ONLY Feb 10 from Strava
SELECT 
    created_at,
    workout_name,
    title,
    synced_from,
    strava_activity_id
FROM workouts
WHERE created_at >= '2026-02-10'
  AND created_at < '2026-02-11'
  AND synced_from = 'strava'
ORDER BY created_at DESC;
