-- Fix web_calendar database tables
-- Create missing athlete_calendar table

BEGIN;

-- Create athlete_calendar table for scheduled workouts
CREATE TABLE IF NOT EXISTS public.athlete_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Workout details
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL,
  description TEXT,
  
  -- Scheduling
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  
  -- Workout parameters
  duration_minutes INTEGER,
  distance_km NUMERIC(6,2),
  target_pace TEXT,
  intensity TEXT,
  
  -- Structure details
  intervals JSONB,
  exercises JSONB,
  
  -- Status tracking
  status TEXT DEFAULT 'scheduled',
  completed_at TIMESTAMPTZ,
  completed_distance_km NUMERIC(6,2),
  completed_duration_minutes INTEGER,
  
  -- Linked GPS activity
  gps_activity_id UUID,
  
  -- Notes
  coach_notes TEXT,
  athlete_notes TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  
  -- Prevent duplicate workouts
  UNIQUE(athlete_id, scheduled_date, workout_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_id 
  ON public.athlete_calendar(athlete_id);
  
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_scheduled_date 
  ON public.athlete_calendar(scheduled_date DESC);
  
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_date 
  ON public.athlete_calendar(athlete_id, scheduled_date);

-- Enable Row Level Security
ALTER TABLE public.athlete_calendar ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can view own workouts" ON public.athlete_calendar
  FOR SELECT USING (auth.uid() = athlete_id OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can insert own workouts" ON public.athlete_calendar
  FOR INSERT WITH CHECK (auth.uid() = athlete_id OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can update own workouts" ON public.athlete_calendar
  FOR UPDATE USING (auth.uid() = athlete_id OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own workouts" ON public.athlete_calendar;
CREATE POLICY "Users can delete own workouts" ON public.athlete_calendar
  FOR DELETE USING (auth.uid() = athlete_id OR auth.uid() = user_id);

COMMIT;