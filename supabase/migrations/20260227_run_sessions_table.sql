-- Migration: Create run_sessions table for GPS-tracked runs
-- Date: 2026-02-27
-- Description: Stores GPS-tracked running sessions with real-time metrics and route data

CREATE TABLE IF NOT EXISTS run_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Timing
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  
  -- Workout context (from training plan)
  workout_name TEXT,
  workout_type TEXT, -- 'easy', 'tempo', 'interval', 'long_run', 'rest'
  planned_distance_km NUMERIC(6, 2),
  planned_pace_target TEXT, -- e.g., 'Easy: 6:15/km'
  workout_context JSONB, -- Full workout context: week_number, training_plan_goal, etc.
  
  -- GPS route (stored as JSONB for flexibility)
  route JSONB NOT NULL DEFAULT '[]'::jsonb,
  
  -- Metrics
  distance_meters NUMERIC(10, 2) NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0, -- Active time (excludes pauses)
  total_seconds INTEGER NOT NULL DEFAULT 0, -- Total elapsed time (includes pauses)
  pause_intervals INTEGER[] DEFAULT '{}', -- Array of pause durations in seconds
  
  -- Performance
  avg_pace_min_per_km NUMERIC(6, 2),
  max_speed_kmh NUMERIC(6, 2),
  avg_heart_rate NUMERIC(5, 1),
  max_heart_rate INTEGER,
  calories INTEGER,
  
  -- Splits (stored as JSONB)
  splits JSONB DEFAULT '[]'::jsonb,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active', -- 'active', 'paused', 'completed', 'uploaded'
  is_uploaded BOOLEAN NOT NULL DEFAULT FALSE,
  strava_activity_id TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_run_sessions_user_id ON run_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_run_sessions_start_time ON run_sessions(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_run_sessions_status ON run_sessions(status);
CREATE INDEX IF NOT EXISTS idx_run_sessions_user_start ON run_sessions(user_id, start_time DESC);

-- Row Level Security (RLS)
ALTER TABLE run_sessions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own run sessions
DROP POLICY IF EXISTS "Users can view own run sessions" ON run_sessions;
CREATE POLICY "Users can view own run sessions"
  ON run_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own run sessions
DROP POLICY IF EXISTS "Users can insert own run sessions" ON run_sessions;
CREATE POLICY "Users can insert own run sessions"
  ON run_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own run sessions
DROP POLICY IF EXISTS "Users can update own run sessions" ON run_sessions;
CREATE POLICY "Users can update own run sessions"
  ON run_sessions
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own run sessions
DROP POLICY IF EXISTS "Users can delete own run sessions" ON run_sessions;
CREATE POLICY "Users can delete own run sessions"
  ON run_sessions
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_run_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on every update
DROP TRIGGER IF EXISTS trigger_update_run_sessions_updated_at ON run_sessions;
CREATE TRIGGER trigger_update_run_sessions_updated_at
  BEFORE UPDATE ON run_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_run_sessions_updated_at();

-- Comments for documentation
COMMENT ON TABLE run_sessions IS 'GPS-tracked running sessions with real-time metrics and route data';
COMMENT ON COLUMN run_sessions.route IS 'JSONB array of route points with lat, lng, timestamp, altitude, speed, etc.';
COMMENT ON COLUMN run_sessions.splits IS 'JSONB array of split data (per kilometer) with duration and pace';
COMMENT ON COLUMN run_sessions.duration_seconds IS 'Active running time in seconds (excludes pauses)';
COMMENT ON COLUMN run_sessions.total_seconds IS 'Total elapsed time in seconds (includes pauses)';
