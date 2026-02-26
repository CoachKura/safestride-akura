-- Migration: Add Strava Signup and Stats Fields
-- Description: Adds columns for complete Strava profile sync including PBs, total mileage, and activity stats

-- Add Strava authentication fields
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS strava_athlete_id BIGINT UNIQUE,
ADD COLUMN IF NOT EXISTS strava_access_token TEXT,
ADD COLUMN IF NOT EXISTS strava_refresh_token TEXT,
ADD COLUMN IF NOT EXISTS strava_token_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS last_strava_sync TIMESTAMP WITH TIME ZONE;

-- Add profile fields from Strava
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
ADD COLUMN IF NOT EXISTS weight DECIMAL(5,2), -- in kg
ADD COLUMN IF NOT EXISTS height DECIMAL(5,2), -- in cm
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS country TEXT;

-- Add Personal Best (PB) fields - stored in seconds
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS pb_5k INTEGER, -- 5K PB in seconds (e.g., 1290 = 21:30)
ADD COLUMN IF NOT EXISTS pb_10k INTEGER, -- 10K PB in seconds
ADD COLUMN IF NOT EXISTS pb_half_marathon INTEGER, -- Half Marathon PB in seconds
ADD COLUMN IF NOT EXISTS pb_marathon INTEGER; -- Marathon PB in seconds

-- Add activity statistics
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS total_runs INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_distance_km DECIMAL(10,2) DEFAULT 0, -- Total distance in km
ADD COLUMN IF NOT EXISTS total_time_hours DECIMAL(10,2) DEFAULT 0, -- Total time in hours
ADD COLUMN IF NOT EXISTS avg_pace_min_per_km DECIMAL(5,2), -- Average pace in min/km
ADD COLUMN IF NOT EXISTS longest_run_km DECIMAL(6,2); -- Longest run in km

-- Create index on strava_athlete_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_profiles_strava_athlete_id 
ON profiles(strava_athlete_id);

-- Drop existing strava_activities table if it exists (for clean migration)
DROP TABLE IF EXISTS strava_activities CASCADE;

-- Create table for storing individual Strava activities
CREATE TABLE strava_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    strava_activity_id BIGINT UNIQUE NOT NULL,
    name TEXT,
    distance_meters DECIMAL(10,2),
    moving_time_seconds INTEGER,
    elapsed_time_seconds INTEGER,
    total_elevation_gain DECIMAL(8,2),
    activity_type VARCHAR(50),
    start_date TIMESTAMP WITH TIME ZONE,
    average_speed DECIMAL(5,2),
    max_speed DECIMAL(5,2),
    average_heartrate INTEGER,
    max_heartrate INTEGER,
    average_cadence DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for strava_activities
CREATE INDEX IF NOT EXISTS idx_strava_activities_user_id 
ON strava_activities(user_id);

CREATE INDEX IF NOT EXISTS idx_strava_activities_start_date 
ON strava_activities(start_date DESC);

CREATE INDEX IF NOT EXISTS idx_strava_activities_distance 
ON strava_activities(distance_meters);

-- Enable Row Level Security
ALTER TABLE strava_activities ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own activities" ON strava_activities;
DROP POLICY IF EXISTS "System can insert activities" ON strava_activities;
DROP POLICY IF EXISTS "Users can update their own activities" ON strava_activities;
DROP POLICY IF EXISTS "Users can delete their own activities" ON strava_activities;

-- RLS Policy: Users can only see their own activities
CREATE POLICY "Users can view their own activities"
ON strava_activities FOR SELECT
USING (user_id = auth.uid());

-- RLS Policy: System can insert activities (for background sync)
CREATE POLICY "System can insert activities"
ON strava_activities FOR INSERT
WITH CHECK (user_id = auth.uid());

-- RLS Policy: Users can update their own activities
CREATE POLICY "Users can update their own activities"
ON strava_activities FOR UPDATE
USING (user_id = auth.uid());

-- RLS Policy: Users can delete their own activities
CREATE POLICY "Users can delete their own activities"
ON strava_activities FOR DELETE
USING (user_id = auth.uid());

-- Add comment
COMMENT ON TABLE strava_activities IS 'Stores individual Strava activities for detailed analysis and historical tracking';
COMMENT ON COLUMN profiles.pb_5k IS 'Personal Best for 5K distance in seconds';
COMMENT ON COLUMN profiles.total_distance_km IS 'Total running distance across all activities in kilometers';
COMMENT ON COLUMN profiles.strava_athlete_id IS 'Unique Strava athlete ID for linking to Strava account';
