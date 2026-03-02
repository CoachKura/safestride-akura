-- Complete database fix for web_calendar
-- Create missing tables and fix schema

BEGIN;

-- 1. Create gps_activities table (currently missing)
CREATE TABLE IF NOT EXISTS public.gps_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  athlete_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Platform info
  platform TEXT NOT NULL,
  platform_activity_id TEXT,
  
  -- Activity details
  activity_type TEXT NOT NULL DEFAULT 'Run',
  activity_name TEXT,
  
  -- Timing
  start_time TIMESTAMPTZ NOT NULL,
  duration_seconds INTEGER NOT NULL,
  moving_time_seconds INTEGER,
  elapsed_time_seconds INTEGER,
  
  -- Distance and pace
  distance_meters NUMERIC(10,2) NOT NULL,
  avg_pace NUMERIC(6,2),
  avg_speed NUMERIC(6,2),
  max_speed NUMERIC(6,2),
  
  -- Heart rate
  avg_heart_rate NUMERIC(5,1),
  max_heart_rate INTEGER,
  
  -- Running metrics
  avg_cadence NUMERIC(5,1),
  avg_stride_length NUMERIC(5,2),
  avg_ground_contact_time NUMERIC(6,2),
  avg_vertical_oscillation NUMERIC(5,2),
  
  -- Elevation
  elevation_gain NUMERIC(10,2),
  elevation_loss NUMERIC(10,2),
  max_elevation NUMERIC(10,2),
  min_elevation NUMERIC(10,2),
  
  -- Training metrics
  calories INTEGER,
  training_load NUMERIC(6,2),
  aerobic_training_effect NUMERIC(3,1),
  anaerobic_training_effect NUMERIC(3,1),
  
  -- HR Zones
  hr_zone_1_seconds INTEGER,
  hr_zone_2_seconds INTEGER,
  hr_zone_3_seconds INTEGER,
  hr_zone_4_seconds INTEGER,
  hr_zone_5_seconds INTEGER,
  
  -- GPS data
  track_points JSONB,
  raw_data JSONB,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, platform, platform_activity_id)
);

CREATE INDEX IF NOT EXISTS idx_gps_activities_user_id ON public.gps_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_gps_activities_athlete_id ON public.gps_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_gps_activities_start_time ON public.gps_activities(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_gps_activities_user_time ON public.gps_activities(user_id, start_time DESC);

ALTER TABLE public.gps_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own activities" ON public.gps_activities;
CREATE POLICY "Users can view own activities" ON public.gps_activities FOR SELECT USING (auth.uid() = user_id OR auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can insert own activities" ON public.gps_activities;
CREATE POLICY "Users can insert own activities" ON public.gps_activities FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can update own activities" ON public.gps_activities;
CREATE POLICY "Users can update own activities" ON public.gps_activities FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = athlete_id);

DROP POLICY IF EXISTS "Users can delete own activities" ON public.gps_activities;
CREATE POLICY "Users can delete own activities" ON public.gps_activities FOR DELETE USING (auth.uid() = user_id OR auth.uid() = athlete_id);

-- 2. Create athlete_calendar table
CREATE TABLE IF NOT EXISTS public.athlete_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL,
  description TEXT,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  duration_minutes INTEGER,
  distance_km NUMERIC(6,2),
  target_pace TEXT,
  intensity TEXT,
  intervals JSONB,
  exercises JSONB,
  status TEXT DEFAULT 'scheduled',
  completed_at TIMESTAMPTZ,
  completed_distance_km NUMERIC(6,2),
  completed_duration_minutes INTEGER,
  gps_activity_id UUID REFERENCES public.gps_activities(id),
  coach_notes TEXT,
  athlete_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  UNIQUE(athlete_id, scheduled_date, workout_type)
);

CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_id ON public.athlete_calendar(athlete_id);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_scheduled_date ON public.athlete_calendar(scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_date ON public.athlete_calendar(athlete_id, scheduled_date);

ALTER TABLE public.athlete_calendar ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can view own workouts" ON public.athlete_calendar FOR SELECT USING (auth.uid() = athlete_id OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can insert own workouts" ON public.athlete_calendar FOR INSERT WITH CHECK (auth.uid() = athlete_id OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can update own workouts" ON public.athlete_calendar FOR UPDATE USING (auth.uid() = athlete_id OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can delete own workouts" ON public.athlete_calendar FOR DELETE USING (auth.uid() = athlete_id OR auth.uid() = user_id);

COMMIT;

NOTIFY pgrst, 'reload schema';
