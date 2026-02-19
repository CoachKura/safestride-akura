-- ============================================================================
-- AISRI Strava ML/AI Integration - Database Schema
-- Creates dedicated tables for Strava OAuth tokens, activities, and AI scores
-- Deploy to: Supabase Dashboard → SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. STRAVA CONNECTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS strava_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id TEXT NOT NULL UNIQUE,
  strava_athlete_id BIGINT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  athlete_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 2. STRAVA ACTIVITIES TABLE (with ML analysis)
-- ============================================================================
CREATE TABLE IF NOT EXISTS strava_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id TEXT NOT NULL,
  strava_activity_id BIGINT NOT NULL UNIQUE,
  activity_data JSONB NOT NULL,
  aisri_score NUMERIC(5,2),
  ml_insights JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 3. AISRI SCORES TABLE (AI-calculated 6-pillar scores)
-- ============================================================================
CREATE TABLE IF NOT EXISTS aisri_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id TEXT NOT NULL,
  assessment_date DATE DEFAULT CURRENT_DATE,
  total_score NUMERIC(5,2) NOT NULL,
  risk_category TEXT NOT NULL,
  pillar_scores JSONB,
  ml_insights JSONB,
  strava_data_included BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if table already exists
ALTER TABLE aisri_scores ADD COLUMN IF NOT EXISTS pillar_scores JSONB;
ALTER TABLE aisri_scores ADD COLUMN IF NOT EXISTS ml_insights JSONB;
ALTER TABLE aisri_scores ADD COLUMN IF NOT EXISTS strava_data_included BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- 4. INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_strava_connections_athlete ON strava_connections(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_athlete ON strava_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_date ON strava_activities((activity_data->>'start_date'));
CREATE INDEX IF NOT EXISTS idx_aisri_scores_athlete ON aisri_scores(athlete_id);
CREATE INDEX IF NOT EXISTS idx_aisri_scores_date ON aisri_scores(assessment_date DESC);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================================================
ALTER TABLE strava_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE strava_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE aisri_scores ENABLE ROW LEVEL SECURITY;

-- Allow public access (adjust based on your security needs)
CREATE POLICY "Allow all operations on strava_connections" ON strava_connections FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on strava_activities" ON strava_activities FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on aisri_scores" ON aisri_scores FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- 6. COMMENTS
-- ============================================================================
COMMENT ON TABLE strava_connections IS 'Stores Strava OAuth tokens and athlete information';
COMMENT ON TABLE strava_activities IS 'Stores Strava activities with ML/AI analysis results';
COMMENT ON TABLE aisri_scores IS 'Stores calculated 6-pillar AISRI scores from ML analysis';

COMMENT ON COLUMN strava_connections.athlete_id IS 'Unique athlete identifier (e.g., strava_12345)';
COMMENT ON COLUMN strava_connections.expires_at IS 'Access token expiration timestamp (auto-refresh before this)';
COMMENT ON COLUMN strava_activities.ml_insights IS 'ML calculations: training load, recovery score, performance index, fatigue level';
COMMENT ON COLUMN aisri_scores.pillar_scores IS 'JSON with 6 pillar scores: running, strength, rom, balance, alignment, mobility';
COMMENT ON COLUMN aisri_scores.ml_insights IS 'AI-generated insights and recommendations based on activity patterns';

-- ============================================================================
-- 7. TEST QUERIES
-- ============================================================================
-- View all Strava connections:
-- SELECT athlete_id, strava_athlete_id, expires_at FROM strava_connections;

-- View activities with ML scores:
-- SELECT 
--   athlete_id,
--   (activity_data->>'name') as activity_name,
--   aisri_score,
--   ml_insights
-- FROM strava_activities
-- ORDER BY created_at DESC
-- LIMIT 10;

-- View AISRI scores:
-- SELECT 
--   athlete_id,
--   total_score,
--   risk_category,
--   pillar_scores,
--   assessment_date
-- FROM aisri_scores
-- ORDER BY created_at DESC;
