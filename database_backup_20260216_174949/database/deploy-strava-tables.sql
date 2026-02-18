-- =====================================================
-- SAFESTRIDE - STRAVA INTEGRATION DATABASE TABLES
-- =====================================================
-- Run this script in Supabase SQL Editor
-- Project: xzxnnswggwqtctcgpocr
-- Date: February 15, 2026
-- =====================================================

-- Strava Weekly Stats Table
-- Stores aggregated weekly training statistics
CREATE TABLE IF NOT EXISTS strava_weekly_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  total_distance DOUBLE PRECISION NOT NULL DEFAULT 0, -- in meters
  total_time INTEGER NOT NULL DEFAULT 0, -- in seconds
  total_elevation_gain DOUBLE PRECISION NOT NULL DEFAULT 0, -- in meters
  activity_count INTEGER NOT NULL DEFAULT 0,
  average_pace DOUBLE PRECISION, -- min/km
  average_heartrate DOUBLE PRECISION, -- bpm
  training_load DOUBLE PRECISION, -- TRIMP score
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(athlete_id, week_start_date)
);

-- Add comment to table
COMMENT ON TABLE strava_weekly_stats IS 'Weekly aggregated training statistics from Strava activities';

-- RLS Policies for Weekly Stats
ALTER TABLE strava_weekly_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own weekly stats" ON strava_weekly_stats;
CREATE POLICY "Users can view own weekly stats"
  ON strava_weekly_stats FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can insert own weekly stats" ON strava_weekly_stats;
CREATE POLICY "Users can insert own weekly stats"
  ON strava_weekly_stats FOR INSERT
  WITH CHECK (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can update own weekly stats" ON strava_weekly_stats;
CREATE POLICY "Users can update own weekly stats"
  ON strava_weekly_stats FOR UPDATE
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can delete own weekly stats" ON strava_weekly_stats;
CREATE POLICY "Users can delete own weekly stats"
  ON strava_weekly_stats FOR DELETE
  USING (auth.uid() = athlete_id);

-- =====================================================

-- Strava Personal Bests Table
-- Stores personal best times for standard race distances
CREATE TABLE IF NOT EXISTS strava_personal_bests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  distance_type TEXT NOT NULL CHECK (distance_type IN ('5k', '10k', 'half_marathon', 'marathon')),
  distance_meters INTEGER NOT NULL,
  time_seconds INTEGER NOT NULL,
  pace_per_km DOUBLE PRECISION NOT NULL, -- min/km
  achieved_at TIMESTAMPTZ NOT NULL,
  activity_name TEXT,
  strava_activity_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(athlete_id, distance_type)
);

-- Add comment to table
COMMENT ON TABLE strava_personal_bests IS 'Personal best race times from Strava activities';

-- RLS Policies for Personal Bests
ALTER TABLE strava_personal_bests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own personal bests" ON strava_personal_bests;
CREATE POLICY "Users can view own personal bests"
  ON strava_personal_bests FOR SELECT
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can insert own personal bests" ON strava_personal_bests;
CREATE POLICY "Users can insert own personal bests"
  ON strava_personal_bests FOR INSERT
  WITH CHECK (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can update own personal bests" ON strava_personal_bests;
CREATE POLICY "Users can update own personal bests"
  ON strava_personal_bests FOR UPDATE
  USING (auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can delete own personal bests" ON strava_personal_bests;
CREATE POLICY "Users can delete own personal bests"
  ON strava_personal_bests FOR DELETE
  USING (auth.uid() = athlete_id);

-- =====================================================

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_weekly_stats_athlete_week 
  ON strava_weekly_stats(athlete_id, week_start_date DESC);

CREATE INDEX IF NOT EXISTS idx_weekly_stats_week_date 
  ON strava_weekly_stats(week_start_date DESC);

CREATE INDEX IF NOT EXISTS idx_personal_bests_athlete 
  ON strava_personal_bests(athlete_id);

CREATE INDEX IF NOT EXISTS idx_personal_bests_distance 
  ON strava_personal_bests(distance_type);

-- =====================================================

-- Verify existing strava_connections table
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strava_connections') THEN
    RAISE NOTICE '✅ strava_connections table exists';
  ELSE
    RAISE EXCEPTION '❌ strava_connections table NOT FOUND - please create it first!';
  END IF;
END $$;

-- Verify existing strava_activities table
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strava_activities') THEN
    RAISE NOTICE '✅ strava_activities table exists';
  ELSE
    RAISE EXCEPTION '❌ strava_activities table NOT FOUND - please create it first!';
  END IF;
END $$;

-- =====================================================

-- Success message
SELECT 
  '✅ Strava integration tables created successfully!' AS status,
  COUNT(*) FILTER (WHERE table_name = 'strava_weekly_stats') AS weekly_stats_created,
  COUNT(*) FILTER (WHERE table_name = 'strava_personal_bests') AS personal_bests_created
FROM information_schema.tables 
WHERE table_name IN ('strava_weekly_stats', 'strava_personal_bests');

-- =====================================================

-- Sample query to test tables (optional)
-- SELECT * FROM strava_weekly_stats LIMIT 1;
-- SELECT * FROM strava_personal_bests LIMIT 1;
