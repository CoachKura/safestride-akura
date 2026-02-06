-- Add missing Strava columns to athlete_profiles table
-- Run this in Supabase Dashboard > SQL Editor

ALTER TABLE public.athlete_profiles 
ADD COLUMN IF NOT EXISTS strava_athlete_id BIGINT,
ADD COLUMN IF NOT EXISTS strava_username TEXT,
ADD COLUMN IF NOT EXISTS strava_firstname TEXT,
ADD COLUMN IF NOT EXISTS strava_lastname TEXT,
ADD COLUMN IF NOT EXISTS strava_profile_image TEXT,
ADD COLUMN IF NOT EXISTS strava_connected_at TIMESTAMPTZ;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_strava_id 
ON public.athlete_profiles(strava_athlete_id);

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'athlete_profiles' 
AND column_name LIKE 'strava%';
