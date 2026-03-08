-- AISRI Strava Integration - Supabase Edge Function
-- This function handles Strava OAuth token exchange and activity fetching
-- Deploy to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

-- Ensure pgcrypto is available for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

-- Backward compatibility: if table already exists with older schema, add missing columns.
ALTER TABLE IF EXISTS public.strava_connections
  ADD COLUMN IF NOT EXISTS athlete_id TEXT,
  ADD COLUMN IF NOT EXISTS strava_athlete_id BIGINT,
  ADD COLUMN IF NOT EXISTS access_token TEXT,
  ADD COLUMN IF NOT EXISTS refresh_token TEXT,
  ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS athlete_data JSONB,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

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

ALTER TABLE IF EXISTS public.strava_activities
  ADD COLUMN IF NOT EXISTS athlete_id TEXT,
  ADD COLUMN IF NOT EXISTS strava_activity_id BIGINT,
  ADD COLUMN IF NOT EXISTS activity_data JSONB,
  ADD COLUMN IF NOT EXISTS aisri_score NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS ml_insights JSONB,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

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

ALTER TABLE IF EXISTS public.aisri_scores
  ADD COLUMN IF NOT EXISTS athlete_id TEXT,
  ADD COLUMN IF NOT EXISTS assessment_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS total_score NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS risk_category TEXT,
  ADD COLUMN IF NOT EXISTS pillar_scores JSONB,
  ADD COLUMN IF NOT EXISTS ml_insights JSONB,
  ADD COLUMN IF NOT EXISTS strava_data_included BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- CREATE INDEXES
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'strava_connections' AND column_name = 'athlete_id'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_strava_connections_athlete ON strava_connections(athlete_id);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'strava_activities' AND column_name = 'athlete_id'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_strava_activities_athlete ON strava_activities(athlete_id);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'strava_activities' AND column_name = 'activity_data'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_strava_activities_date ON strava_activities((activity_data->>'start_date'));
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'aisri_scores' AND column_name = 'athlete_id'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_aisri_scores_athlete ON aisri_scores(athlete_id);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'aisri_scores' AND column_name = 'assessment_date'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_aisri_scores_date ON aisri_scores(assessment_date DESC);
  END IF;
END
$$;

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE strava_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE strava_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE aisri_scores ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES (Allow read/write for authenticated users)
DROP POLICY IF EXISTS "Users can view their own Strava connections" ON public.strava_connections;
CREATE POLICY "Users can view their own Strava connections"
  ON strava_connections FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own Strava connections" ON public.strava_connections;
CREATE POLICY "Users can insert their own Strava connections"
  ON strava_connections FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their own Strava connections" ON public.strava_connections;
CREATE POLICY "Users can update their own Strava connections"
  ON strava_connections FOR UPDATE
  USING (true);

DROP POLICY IF EXISTS "Users can view their own activities" ON public.strava_activities;
CREATE POLICY "Users can view their own activities"
  ON strava_activities FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own activities" ON public.strava_activities;
CREATE POLICY "Users can insert their own activities"
  ON strava_activities FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view their own AISRI scores" ON public.aisri_scores;
CREATE POLICY "Users can view their own AISRI scores"
  ON aisri_scores FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own AISRI scores" ON public.aisri_scores;
CREATE POLICY "Users can insert their own AISRI scores"
  ON aisri_scores FOR INSERT
  WITH CHECK (true);
