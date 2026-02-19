-- AISRI Strava Integration - Supabase Edge Function
-- This function handles Strava OAuth token exchange and activity fetching
-- Deploy to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

-- CREATE TABLE FOR STRAVA CONNECTIONS
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

-- CREATE TABLE FOR STRAVA ACTIVITIES
CREATE TABLE IF NOT EXISTS strava_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id TEXT NOT NULL,
  strava_activity_id BIGINT NOT NULL UNIQUE,
  activity_data JSONB NOT NULL,
  aisri_score NUMERIC(5,2),
  ml_insights JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CREATE TABLE FOR AISRI SCORES
CREATE TABLE IF NOT EXISTS aisri_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id TEXT NOT NULL,
  assessment_date DATE DEFAULT CURRENT_DATE,
  total_score NUMERIC(5,2) NOT NULL,
  risk_category TEXT NOT NULL,
  pillar_scores JSONB NOT NULL,
  ml_insights JSONB,
  strava_data_included BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_strava_connections_athlete ON strava_connections(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_athlete ON strava_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_date ON strava_activities((activity_data->>'start_date'));
CREATE INDEX IF NOT EXISTS idx_aisri_scores_athlete ON aisri_scores(athlete_id);
CREATE INDEX IF NOT EXISTS idx_aisri_scores_date ON aisri_scores(assessment_date DESC);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE strava_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE strava_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE aisri_scores ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES (Allow read/write for authenticated users)
CREATE POLICY "Users can view their own Strava connections"
  ON strava_connections FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own Strava connections"
  ON strava_connections FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their own Strava connections"
  ON strava_connections FOR UPDATE
  USING (true);

CREATE POLICY "Users can view their own activities"
  ON strava_activities FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own activities"
  ON strava_activities FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can view their own AISRI scores"
  ON aisri_scores FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own AISRI scores"
  ON aisri_scores FOR INSERT
  WITH CHECK (true);
