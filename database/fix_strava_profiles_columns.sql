-- Add missing Strava columns to profiles table
-- Run this in Supabase SQL Editor

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS strava_access_token TEXT,
ADD COLUMN IF NOT EXISTS strava_refresh_token TEXT,
ADD COLUMN IF NOT EXISTS strava_athlete_id BIGINT,
ADD COLUMN IF NOT EXISTS strava_connected_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS strava_expires_at TIMESTAMPTZ;

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name LIKE 'strava%'
ORDER BY column_name;
