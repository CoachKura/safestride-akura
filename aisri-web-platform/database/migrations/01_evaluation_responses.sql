-- =====================================================
-- AISRI WEB PLATFORM DATABASE ADDITIONS
-- =====================================================
-- Add this to your existing Supabase database
-- Date: 2026-02-28
-- =====================================================

-- =====================================================
-- TABLE: evaluation_responses
-- Purpose: Store athlete onboarding evaluation data
-- =====================================================

CREATE TABLE IF NOT EXISTS public.evaluation_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Personal Data
  age INTEGER,
  gender TEXT,
  height_cm NUMERIC(5,2),
  weight_kg NUMERIC(5,2),
  primary_sport TEXT DEFAULT 'running',
  years_training INTEGER,
  
  -- Performance Data
  weekly_volume_km NUMERIC(6,2),
  longest_session_km NUMERIC(6,2),
  vo2_max NUMERIC(5,2),
  recent_race_time INTERVAL,
  recent_race_distance TEXT, -- '5K', '10K', 'Half', 'Marathon'
  
  -- Injury History
  past_injuries JSONB DEFAULT '[]'::JSONB, -- ["knee pain", "shin splints"]
  current_pain_areas JSONB DEFAULT '[]'::JSONB, -- ["left knee", "right achilles"]
  surgery_history TEXT,
  
  -- Recovery Metrics
  avg_sleep_hours NUMERIC(3,1),
  hrv NUMERIC(5,1),
  resting_hr INTEGER,
  
  -- Goals
  has_upcoming_race BOOLEAN DEFAULT FALSE,
  race_date DATE,
  race_distance TEXT,
  target_time INTERVAL,
  priority TEXT CHECK (priority IN ('performance', 'injury_prevention', 'balanced')),
  
  -- Status
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(athlete_id)
);

-- Enable Row Level Security
ALTER TABLE public.evaluation_responses ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Athletes view own evaluations" ON public.evaluation_responses
  FOR SELECT USING (auth.uid() = athlete_id);

CREATE POLICY "Athletes create own evaluations" ON public.evaluation_responses
  FOR INSERT WITH CHECK (auth.uid() = athlete_id);

CREATE POLICY "Athletes update own evaluations" ON public.evaluation_responses
  FOR UPDATE USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches view athlete evaluations" ON public.evaluation_responses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships acr
      WHERE acr.coach_id = auth.uid()
        AND acr.athlete_id = evaluation_responses.athlete_id
        AND acr.status = 'active'
    )
  );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_evaluations_athlete ON public.evaluation_responses(athlete_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_completed ON public.evaluation_responses(completed);

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_evaluation_responses_updated_at
  BEFORE UPDATE ON public.evaluation_responses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE public.evaluation_responses IS 'Athlete onboarding evaluation responses for AISRi web platform';
COMMENT ON COLUMN public.evaluation_responses.past_injuries IS 'JSON array of past injury descriptions';
COMMENT ON COLUMN public.evaluation_responses.current_pain_areas IS 'JSON array of current pain/discomfort areas';
COMMENT ON COLUMN public.evaluation_responses.priority IS 'Athlete primary goal: performance, injury_prevention, or balanced';
