-- Fix: Add 'manual' to platform constraint for GPS tracker
-- This allows the app's GPS tracker to save workouts

-- Drop the existing constraint
ALTER TABLE gps_activities 
DROP CONSTRAINT IF EXISTS gps_activities_platform_check;

-- Add new constraint with 'manual' included
ALTER TABLE gps_activities 
ADD CONSTRAINT gps_activities_platform_check 
CHECK (platform IN ('garmin', 'coros', 'strava', 'manual'));

-- Verify the fix
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_name = 'gps_activities_platform_check';

-- Test comment
COMMENT ON CONSTRAINT gps_activities_platform_check ON gps_activities 
IS 'Allowed platforms: garmin, coros, strava (external watches), manual (app GPS tracker)';
