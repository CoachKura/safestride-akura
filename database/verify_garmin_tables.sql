-- Quick verification query - run this in Supabase SQL Editor after migration

SELECT 
  table_name,
  '✅ EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND table_name IN (
    'garmin_devices',
    'garmin_connections', 
    'garmin_activities',
    'garmin_pushed_workouts'
  )
ORDER BY table_name;

-- Check row counts
SELECT 
  'garmin_devices' as table_name,
  COUNT(*) as row_count
FROM garmin_devices
UNION ALL
SELECT 
  'garmin_connections',
  COUNT(*)
FROM garmin_connections
UNION ALL
SELECT 
  'garmin_activities',
  COUNT(*)
FROM garmin_activities
UNION ALL
SELECT 
  'garmin_pushed_workouts',
  COUNT(*)
FROM garmin_pushed_workouts;
