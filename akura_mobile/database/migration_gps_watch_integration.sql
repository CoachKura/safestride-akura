-- =====================================================
-- GPS Watch Integration Migration
-- Created: 2026-02-05
-- Description: Adds tables for GPS watch connections (Garmin, Coros, Strava)
--              and activity storage for comprehensive workout tracking
-- =====================================================

-- =====================================================
-- TABLE: gps_connections
-- Purpose: Store OAuth tokens for GPS watch platforms
-- =====================================================
CREATE TABLE IF NOT EXISTS gps_connections (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('garmin', 'coros', 'strava')),
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_type TEXT DEFAULT 'Bearer',
  expires_at TIMESTAMPTZ,
  scope TEXT,
  connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_synced_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (user_id, platform)
);

-- Indexes for gps_connections
CREATE INDEX IF NOT EXISTS idx_gps_connections_user_id ON gps_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_gps_connections_platform ON gps_connections(platform);
CREATE INDEX IF NOT EXISTS idx_gps_connections_active ON gps_connections(user_id, is_active);

-- RLS Policies for gps_connections
ALTER TABLE gps_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own connections"
  ON gps_connections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own connections"
  ON gps_connections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own connections"
  ON gps_connections FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own connections"
  ON gps_connections FOR DELETE
  USING (auth.uid() = user_id);

COMMENT ON TABLE gps_connections IS 'OAuth connection tokens for GPS watch platforms (Garmin, Coros, Strava)';

-- =====================================================
-- TABLE: gps_activities
-- Purpose: Store synced activities from GPS watch platforms
-- =====================================================
CREATE TABLE IF NOT EXISTS gps_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  athlete_id TEXT NOT NULL,
  
  -- Platform info
  platform TEXT NOT NULL CHECK (platform IN ('garmin', 'coros', 'strava')),
  platform_activity_id TEXT NOT NULL,
  
  -- Activity details
  activity_type TEXT NOT NULL DEFAULT 'run',
  activity_name TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  timezone TEXT,
  
  -- Duration and distance
  duration_seconds INTEGER NOT NULL,
  moving_time_seconds INTEGER,
  elapsed_time_seconds INTEGER,
  distance_meters NUMERIC(10, 2) NOT NULL,
  
  -- Performance metrics
  avg_pace NUMERIC(6, 2), -- min/km
  avg_speed NUMERIC(6, 2), -- km/h
  max_speed NUMERIC(6, 2), -- km/h
  avg_cadence NUMERIC(6, 2), -- steps per minute
  max_cadence NUMERIC(6, 2),
  avg_heart_rate NUMERIC(6, 2), -- bpm
  max_heart_rate NUMERIC(6, 2),
  
  -- Elevation
  elevation_gain NUMERIC(8, 2), -- meters
  elevation_loss NUMERIC(8, 2), -- meters
  max_elevation NUMERIC(8, 2),
  min_elevation NUMERIC(8, 2),
  
  -- Advanced biomechanics (from premium GPS watches)
  avg_ground_contact_time NUMERIC(6, 2), -- milliseconds
  avg_vertical_oscillation NUMERIC(6, 2), -- centimeters
  avg_stride_length NUMERIC(6, 2), -- meters
  avg_vertical_ratio NUMERIC(6, 2), -- percentage
  training_load NUMERIC(6, 2),
  aerobic_training_effect NUMERIC(4, 2),
  anaerobic_training_effect NUMERIC(4, 2),
  
  -- Calories and zones
  calories INTEGER,
  hr_zone_1_seconds INTEGER, -- Recovery (50-60% max HR)
  hr_zone_2_seconds INTEGER, -- Aerobic (60-70% max HR)
  hr_zone_3_seconds INTEGER, -- Tempo (70-80% max HR)
  hr_zone_4_seconds INTEGER, -- Threshold (80-90% max HR)
  hr_zone_5_seconds INTEGER, -- Anaerobic (90-100% max HR)
  
  -- Rating and notes
  perceived_effort INTEGER CHECK (perceived_effort BETWEEN 1 AND 10),
  athlete_notes TEXT,
  
  -- Gear
  gear_id TEXT,
  gear_name TEXT,
  
  -- Weather conditions
  temperature NUMERIC(5, 2), -- Celsius
  humidity INTEGER, -- percentage
  wind_speed NUMERIC(5, 2), -- km/h
  weather_condition TEXT,
  
  -- Raw data from platform (JSONB for flexibility)
  raw_data JSONB,
  
  -- Sync metadata
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint: one activity per platform
  UNIQUE (user_id, platform, platform_activity_id)
);

-- Indexes for gps_activities
CREATE INDEX IF NOT EXISTS idx_gps_activities_user_id ON gps_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_gps_activities_athlete_id ON gps_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_gps_activities_platform ON gps_activities(platform);
CREATE INDEX IF NOT EXISTS idx_gps_activities_start_time ON gps_activities(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_gps_activities_activity_type ON gps_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_gps_activities_user_start ON gps_activities(user_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_gps_activities_platform_id ON gps_activities(platform, platform_activity_id);
CREATE INDEX IF NOT EXISTS idx_gps_activities_raw_data ON gps_activities USING GIN(raw_data);

-- RLS Policies for gps_activities
ALTER TABLE gps_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own activities"
  ON gps_activities FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activities"
  ON gps_activities FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activities"
  ON gps_activities FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own activities"
  ON gps_activities FOR DELETE
  USING (auth.uid() = user_id);

COMMENT ON TABLE gps_activities IS 'Synced running activities from GPS watch platforms with comprehensive metrics';

-- =====================================================
-- TABLE: custom_workouts
-- Purpose: Store manually created workouts for calendar
-- =====================================================
CREATE TABLE IF NOT EXISTS custom_workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Workout identification
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL CHECK (workout_type IN (
    'easy_run', 'quality_session', 'race', 'cross_training', 'rest_day', 'note'
  )),
  
  -- Workout definition (JSON from WorkoutDefinition model)
  workout_data JSONB NOT NULL,
  
  -- Computed fields for quick access
  estimated_duration_minutes INTEGER,
  difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard')),
  equipment_needed TEXT[],
  
  -- Categorization
  tags TEXT[],
  is_template BOOLEAN DEFAULT FALSE,
  template_category TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Optional: Link to template if created from one (FK added after workout_templates is created)
  template_id UUID
);

-- Indexes for custom_workouts
CREATE INDEX IF NOT EXISTS idx_custom_workouts_user_id ON custom_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_type ON custom_workouts(workout_type);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_template ON custom_workouts(is_template);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_created ON custom_workouts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_data ON custom_workouts USING GIN(workout_data);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_tags ON custom_workouts USING GIN(tags);

-- RLS Policies for custom_workouts
ALTER TABLE custom_workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own workouts"
  ON custom_workouts FOR SELECT
  USING (auth.uid() = user_id OR is_template = TRUE);

CREATE POLICY "Users can insert their own workouts"
  ON custom_workouts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workouts"
  ON custom_workouts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workouts"
  ON custom_workouts FOR DELETE
  USING (auth.uid() = user_id);

COMMENT ON TABLE custom_workouts IS 'Stores manually created workouts for calendar scheduling';

-- =====================================================
-- TABLE: workout_templates
-- Purpose: Store reusable workout templates
-- =====================================================
CREATE TABLE IF NOT EXISTS workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Template identification
  template_name TEXT NOT NULL,
  template_description TEXT,
  workout_type TEXT NOT NULL CHECK (workout_type IN (
    'easy_run', 'quality_session', 'race', 'cross_training', 'rest_day', 'note'
  )),
  
  -- Template definition (JSON from WorkoutDefinition model)
  workout_data JSONB NOT NULL,
  
  -- Computed fields
  estimated_duration_minutes INTEGER,
  difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard')),
  equipment_needed TEXT[],
  
  -- Categorization
  category TEXT, -- e.g., 'Speed Work', 'Endurance', 'Recovery', 'Strength'
  subcategory TEXT, -- e.g., 'Intervals', 'Tempo', 'Long Run'
  tags TEXT[],
  
  -- Sharing and visibility
  is_public BOOLEAN DEFAULT FALSE,
  is_featured BOOLEAN DEFAULT FALSE,
  
  -- Usage tracking
  use_count INTEGER DEFAULT 0,
  rating NUMERIC(3, 2),
  rating_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- Indexes for workout_templates
CREATE INDEX IF NOT EXISTS idx_workout_templates_creator ON workout_templates(creator_id);
CREATE INDEX IF NOT EXISTS idx_workout_templates_type ON workout_templates(workout_type);
CREATE INDEX IF NOT EXISTS idx_workout_templates_category ON workout_templates(category);
CREATE INDEX IF NOT EXISTS idx_workout_templates_public ON workout_templates(is_public);
CREATE INDEX IF NOT EXISTS idx_workout_templates_featured ON workout_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_workout_templates_rating ON workout_templates(rating DESC);
CREATE INDEX IF NOT EXISTS idx_workout_templates_uses ON workout_templates(use_count DESC);
CREATE INDEX IF NOT EXISTS idx_workout_templates_data ON workout_templates USING GIN(workout_data);
CREATE INDEX IF NOT EXISTS idx_workout_templates_tags ON workout_templates USING GIN(tags);

-- RLS Policies for workout_templates
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public templates"
  ON workout_templates FOR SELECT
  USING (is_public = TRUE OR auth.uid() = creator_id);

CREATE POLICY "Users can insert their own templates"
  ON workout_templates FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update their own templates"
  ON workout_templates FOR UPDATE
  USING (auth.uid() = creator_id);

CREATE POLICY "Users can delete their own templates"
  ON workout_templates FOR DELETE
  USING (auth.uid() = creator_id);

COMMENT ON TABLE workout_templates IS 'Stores reusable workout templates created by users';

-- =====================================================
-- Add foreign key constraint for custom_workouts.template_id
-- (Must be added after workout_templates table exists)
-- =====================================================
ALTER TABLE custom_workouts
  ADD CONSTRAINT fk_custom_workouts_template
  FOREIGN KEY (template_id) 
  REFERENCES workout_templates(id) 
  ON DELETE SET NULL;

-- =====================================================
-- VIEW: weekly_activity_summary
-- Purpose: Aggregated weekly activity metrics
-- =====================================================
CREATE OR REPLACE VIEW weekly_activity_summary AS
SELECT 
  user_id,
  athlete_id,
  DATE_TRUNC('week', start_time) AS week_start,
  
  -- Activity counts
  COUNT(*) AS total_activities,
  COUNT(*) FILTER (WHERE activity_type = 'run') AS run_count,
  COUNT(*) FILTER (WHERE activity_type = 'trail_run') AS trail_run_count,
  
  -- Distance metrics
  ROUND(SUM(distance_meters) / 1000, 2) AS total_distance_km,
  ROUND(AVG(distance_meters) / 1000, 2) AS avg_distance_km,
  ROUND(MAX(distance_meters) / 1000, 2) AS max_distance_km,
  
  -- Time metrics
  ROUND(SUM(duration_seconds) / 3600, 2) AS total_duration_hours,
  ROUND(AVG(duration_seconds) / 60, 2) AS avg_duration_minutes,
  
  -- Pace metrics
  ROUND(AVG(avg_pace), 2) AS avg_pace_min_km,
  ROUND(MIN(avg_pace), 2) AS best_pace_min_km,
  
  -- Cadence metrics
  ROUND(AVG(avg_cadence), 1) AS avg_cadence_spm,
  
  -- Heart rate metrics
  ROUND(AVG(avg_heart_rate), 1) AS avg_heart_rate_bpm,
  ROUND(MAX(max_heart_rate), 0) AS max_heart_rate_bpm,
  
  -- Elevation metrics
  ROUND(SUM(elevation_gain), 0) AS total_elevation_gain_m,
  ROUND(AVG(elevation_gain), 0) AS avg_elevation_gain_m,
  
  -- Biomechanics metrics
  ROUND(AVG(avg_ground_contact_time), 1) AS avg_ground_contact_time_ms,
  ROUND(AVG(avg_vertical_oscillation), 2) AS avg_vertical_oscillation_cm,
  ROUND(AVG(avg_stride_length), 2) AS avg_stride_length_m,
  
  -- Training load
  ROUND(SUM(training_load), 1) AS total_training_load,
  ROUND(AVG(training_load), 1) AS avg_training_load,
  
  -- Calories
  SUM(calories) AS total_calories,
  
  -- Platform breakdown
  COUNT(*) FILTER (WHERE platform = 'garmin') AS garmin_activities,
  COUNT(*) FILTER (WHERE platform = 'coros') AS coros_activities,
  COUNT(*) FILTER (WHERE platform = 'strava') AS strava_activities
  
FROM gps_activities
WHERE start_time >= DATE_TRUNC('week', NOW()) - INTERVAL '12 weeks'
GROUP BY user_id, athlete_id, week_start
ORDER BY week_start DESC;

COMMENT ON VIEW weekly_activity_summary IS 'Weekly aggregated activity metrics for analytics';

-- =====================================================
-- VIEW: monthly_activity_summary
-- Purpose: Aggregated monthly activity metrics
-- =====================================================
CREATE OR REPLACE VIEW monthly_activity_summary AS
SELECT 
  user_id,
  athlete_id,
  DATE_TRUNC('month', start_time) AS month_start,
  TO_CHAR(DATE_TRUNC('month', start_time), 'YYYY-MM') AS month_label,
  
  -- Activity counts
  COUNT(*) AS total_activities,
  COUNT(*) FILTER (WHERE activity_type = 'run') AS run_count,
  
  -- Distance metrics
  ROUND(SUM(distance_meters) / 1000, 2) AS total_distance_km,
  ROUND(AVG(distance_meters) / 1000, 2) AS avg_distance_km,
  ROUND(MAX(distance_meters) / 1000, 2) AS longest_run_km,
  
  -- Time metrics
  ROUND(SUM(duration_seconds) / 3600, 2) AS total_duration_hours,
  ROUND(SUM(moving_time_seconds) / 3600, 2) AS total_moving_hours,
  
  -- Pace metrics
  ROUND(AVG(avg_pace), 2) AS avg_pace_min_km,
  ROUND(MIN(avg_pace), 2) AS best_pace_min_km,
  
  -- Performance metrics
  ROUND(AVG(avg_cadence), 1) AS avg_cadence_spm,
  ROUND(AVG(avg_heart_rate), 1) AS avg_heart_rate_bpm,
  
  -- Elevation
  ROUND(SUM(elevation_gain), 0) AS total_elevation_gain_m,
  
  -- Training load
  ROUND(SUM(training_load), 1) AS total_training_load,
  ROUND(AVG(training_load), 1) AS avg_training_load,
  
  -- Calories
  SUM(calories) AS total_calories,
  
  -- Consistency (days with activity)
  COUNT(DISTINCT DATE(start_time)) AS active_days,
  ROUND(COUNT(DISTINCT DATE(start_time))::NUMERIC / 
        EXTRACT(DAY FROM DATE_TRUNC('month', start_time) + INTERVAL '1 month' - INTERVAL '1 day') * 100, 1) 
    AS consistency_percentage
  
FROM gps_activities
WHERE start_time >= DATE_TRUNC('month', NOW()) - INTERVAL '12 months'
GROUP BY user_id, athlete_id, month_start
ORDER BY month_start DESC;

COMMENT ON VIEW monthly_activity_summary IS 'Monthly aggregated activity metrics for analytics';

-- =====================================================
-- FUNCTION: Update updated_at timestamp
-- Purpose: Automatically update the updated_at column
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_updated_at trigger to all tables
CREATE TRIGGER update_gps_connections_updated_at
  BEFORE UPDATE ON gps_connections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gps_activities_updated_at
  BEFORE UPDATE ON gps_activities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_custom_workouts_updated_at
  BEFORE UPDATE ON custom_workouts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workout_templates_updated_at
  BEFORE UPDATE ON workout_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTION: Increment template use count
-- Purpose: Track template usage
-- =====================================================
CREATE OR REPLACE FUNCTION increment_template_use_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.template_id IS NOT NULL THEN
    UPDATE workout_templates
    SET use_count = use_count + 1
    WHERE id = NEW.template_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_template_usage
  AFTER INSERT ON custom_workouts
  FOR EACH ROW
  WHEN (NEW.template_id IS NOT NULL)
  EXECUTE FUNCTION increment_template_use_count();

-- =====================================================
-- GRANTS: Ensure authenticated users have access
-- =====================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON gps_connections TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON gps_activities TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON custom_workouts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON workout_templates TO authenticated;
GRANT SELECT ON weekly_activity_summary TO authenticated;
GRANT SELECT ON monthly_activity_summary TO authenticated;

-- =====================================================
-- END OF MIGRATION
-- =====================================================
