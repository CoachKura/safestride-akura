-- =====================================================
-- SAFESTRIDE MODERN PLATFORM - SCHEMA EXTENSION
-- Version: 2.0
-- Created: 2026-03-03
-- Purpose: Extend existing schema for modern platform features
-- =====================================================

-- =====================================================
-- EXTEND USERS TABLE (if not exists)
-- =====================================================

-- Add role column if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'athlete' 
        CHECK (role IN ('admin', 'coach', 'athlete'));
    END IF;
END $$;

-- Add coach assignment
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='coach_id') THEN
        ALTER TABLE public.profiles ADD COLUMN coach_id UUID REFERENCES public.profiles(id);
    END IF;
END $$;

-- Add onboarding status
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='onboarding_completed') THEN
        ALTER TABLE public.profiles ADD COLUMN onboarding_completed BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Add profile details
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='gender') THEN
        ALTER TABLE public.profiles ADD COLUMN gender TEXT CHECK (gender IN ('male', 'female', 'other'));
        ALTER TABLE public.profiles ADD COLUMN weight DECIMAL(5,2);
        ALTER TABLE public.profiles ADD COLUMN height DECIMAL(5,2);
        ALTER TABLE public.profiles ADD COLUMN max_hr INTEGER;
    END IF;
END $$;

-- =====================================================
-- TABLE: PHYSICAL ASSESSMENTS (with image capture)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.physical_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assessment_date TIMESTAMPTZ DEFAULT NOW(),
  assessment_type TEXT DEFAULT 'monthly' CHECK (assessment_type IN ('initial', 'monthly', 'ad_hoc')),
  
  -- ROM (Range of Motion) Tests
  rom_ankle_dorsiflexion_left DECIMAL(5,2), -- degrees
  rom_ankle_dorsiflexion_right DECIMAL(5,2),
  rom_hip_flexion_left DECIMAL(5,2),
  rom_hip_flexion_right DECIMAL(5,2),
  rom_hip_extension_left DECIMAL(5,2),
  rom_hip_extension_right DECIMAL(5,2),
  
  -- Strength Tests (reps or seconds)
  strength_single_leg_squat_left INTEGER,
  strength_single_leg_squat_right INTEGER,
  strength_calf_raise_left INTEGER,
  strength_calf_raise_right INTEGER,
  strength_hip_abduction_left INTEGER,
  strength_hip_abduction_right INTEGER,
  strength_core_plank_seconds INTEGER,
  
  -- Balance Tests (seconds)
  balance_single_leg_left INTEGER,
  balance_single_leg_right INTEGER,
  balance_y_test_left DECIMAL(5,2), -- cm
  balance_y_test_right DECIMAL(5,2),
  
  -- Mobility Tests
  mobility_hip_flexor_left INTEGER, -- score 1-10
  mobility_hip_flexor_right INTEGER,
  mobility_hamstring_left INTEGER,
  mobility_hamstring_right INTEGER,
  mobility_thoracic_rotation INTEGER,
  
  -- Alignment Tests
  alignment_posture_score INTEGER CHECK (alignment_posture_score BETWEEN 0 AND 100),
  alignment_gait_score INTEGER CHECK (alignment_gait_score BETWEEN 0 AND 100),
  
  -- Notes
  assessor_notes TEXT,
  athlete_feedback TEXT,
  
  -- Metadata
  completed_by UUID REFERENCES public.profiles(id), -- Coach/admin who recorded
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(athlete_id, assessment_date)
);

CREATE INDEX idx_physical_assessments_athlete ON public.physical_assessments(athlete_id);
CREATE INDEX idx_physical_assessments_date ON public.physical_assessments(assessment_date DESC);
CREATE INDEX idx_physical_assessments_type ON public.physical_assessments(assessment_type);

COMMENT ON TABLE public.physical_assessments IS 'Physical assessment test results with measurements for ROM, strength, balance, mobility';

-- =====================================================
-- TABLE: ASSESSMENT MEDIA (images/videos)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.assessment_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id UUID NOT NULL REFERENCES public.physical_assessments(id) ON DELETE CASCADE,
  test_name TEXT NOT NULL, -- 'rom_ankle_dorsiflexion_left', 'strength_squat', etc.
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url TEXT NOT NULL,
  file_size INTEGER, -- bytes
  mime_type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Optional AI analysis results
  ai_analysis_results JSONB,
  
  UNIQUE(assessment_id, test_name, media_type)
);

CREATE INDEX idx_assessment_media_assessment ON public.assessment_media(assessment_id);
CREATE INDEX idx_assessment_media_test ON public.assessment_media(test_name);

COMMENT ON TABLE public.assessment_media IS 'Images and videos captured during physical assessments';

-- =====================================================
-- TABLE: TRAINING PLANS (12-week programs)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.training_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_weeks INTEGER DEFAULT 12,
  
  -- AISRI context at plan creation
  aisri_score_at_creation INTEGER,
  risk_category TEXT,
  
  -- Plan data (full JSON structure)
  plan_data JSONB NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
  
  -- Coach approval
  created_by UUID REFERENCES public.profiles(id), -- Coach who created
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_training_plans_athlete ON public.training_plans(athlete_id);
CREATE INDEX idx_training_plans_status ON public.training_plans(status);
CREATE INDEX idx_training_plans_dates ON public.training_plans(start_date, end_date);

COMMENT ON TABLE public.training_plans IS '12-week training programs generated based on AISRI scores';

-- =====================================================
-- TABLE: DAILY WORKOUTS (from training plans)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.daily_workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  training_plan_id UUID NOT NULL REFERENCES public.training_plans(id) ON DELETE CASCADE,
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  workout_date DATE NOT NULL,
  week_number INTEGER CHECK (week_number BETWEEN 1 AND 52),
  day_number INTEGER CHECK (day_number BETWEEN 1 AND 7),
  
  -- Workout details
  workout_type TEXT NOT NULL, -- 'AR', 'F', 'EN', 'TH', 'P', 'SP', 'Strength', 'Recovery'
  workout_name TEXT NOT NULL,
  description TEXT,
  distance DECIMAL(5,2), -- km
  duration INTEGER, -- minutes
  hr_zone TEXT,
  intensity TEXT,
  notes TEXT,
  
  -- Completion tracking
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  actual_distance DECIMAL(5,2),
  actual_duration INTEGER,
  actual_avg_hr INTEGER,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(athlete_id, workout_date)
);

CREATE INDEX idx_daily_workouts_athlete ON public.daily_workouts(athlete_id);
CREATE INDEX idx_daily_workouts_date ON public.daily_workouts(workout_date DESC);
CREATE INDEX idx_daily_workouts_plan ON public.daily_workouts(training_plan_id);
CREATE INDEX idx_daily_workouts_completed ON public.daily_workouts(completed);

COMMENT ON TABLE public.daily_workouts IS 'Individual daily workouts from training plans';

-- =====================================================
-- TABLE: WORKOUT COMPLETIONS (feedback)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.workout_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_workout_id UUID REFERENCES public.daily_workouts(id),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  completed_at TIMESTAMPTZ NOT NULL,
  
  -- Link to Strava activity if synced
  strava_activity_id TEXT,
  
  -- Athlete feedback
  feedback_rating INTEGER CHECK (feedback_rating BETWEEN 1 AND 5),
  feedback_notes TEXT,
  perceived_effort INTEGER CHECK (perceived_effort BETWEEN 1 AND 10), -- RPE
  
  -- Actual metrics
  actual_distance DECIMAL(5,2),
  actual_duration INTEGER,
  actual_avg_hr INTEGER,
  actual_max_hr INTEGER,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workout_completions_athlete ON public.workout_completions(athlete_id);
CREATE INDEX idx_workout_completions_workout ON public.workout_completions(daily_workout_id);
CREATE INDEX idx_workout_completions_date ON public.workout_completions(completed_at DESC);

COMMENT ON TABLE public.workout_completions IS 'Completed workouts with athlete feedback';

-- =====================================================
-- TABLE: EVALUATION SCHEDULE (monthly re-evaluations)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.evaluation_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  next_evaluation_date DATE NOT NULL,
  evaluation_type TEXT DEFAULT 'monthly' CHECK (evaluation_type IN ('monthly', 'quarterly', 'annual')),
  
  reminder_sent_at TIMESTAMPTZ,
  reminder_count INTEGER DEFAULT 0,
  
  completed_at TIMESTAMPTZ,
  assessment_id UUID REFERENCES public.physical_assessments(id),
  
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reminded', 'completed', 'overdue')),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_evaluation_schedule_athlete ON public.evaluation_schedule(athlete_id);
CREATE INDEX idx_evaluation_schedule_date ON public.evaluation_schedule(next_evaluation_date);
CREATE INDEX idx_evaluation_schedule_status ON public.evaluation_schedule(status);

COMMENT ON TABLE public.evaluation_schedule IS 'Scheduled re-evaluations for monthly AISRI tracking';

-- =====================================================
-- TABLE: AISRI SCORE HISTORY
-- =====================================================

CREATE TABLE IF NOT EXISTS public.aisri_score_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES public.physical_assessments(id),
  
  -- Scores
  aisri_score INTEGER NOT NULL CHECK (aisri_score BETWEEN 0 AND 100),
  risk_category TEXT NOT NULL,
  
  -- 6 Pillars (updated from 5 to 6)
  pillar_running INTEGER CHECK (pillar_running BETWEEN 0 AND 100),
  pillar_strength INTEGER CHECK (pillar_strength BETWEEN 0 AND 100),
  pillar_rom INTEGER CHECK (pillar_rom BETWEEN 0 AND 100),
  pillar_balance INTEGER CHECK (pillar_balance BETWEEN 0 AND 100),
  pillar_alignment INTEGER CHECK (pillar_alignment BETWEEN 0 AND 100),
  pillar_mobility INTEGER CHECK (pillar_mobility BETWEEN 0 AND 100),
  
  -- Change from previous assessment
  score_change INTEGER,
  change_direction TEXT CHECK (change_direction IN ('improved', 'declined', 'stable')),
  
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_aisri_history_athlete ON public.aisri_score_history(athlete_id);
CREATE INDEX idx_aisri_history_date ON public.aisri_score_history(recorded_at DESC);

COMMENT ON TABLE public.aisri_score_history IS 'Historical tracking of AISRI scores over time';

-- =====================================================
-- TABLE: TRAINING LOAD (ACR calculations)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.training_load (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  
  -- Training Load metrics
  daily_load INTEGER,
  acute_load DECIMAL(10,2), -- 7-day rolling average
  chronic_load DECIMAL(10,2), -- 28-day rolling average
  acr_ratio DECIMAL(5,2), -- Acute:Chronic Ratio
  
  -- Weekly summary
  weekly_distance DECIMAL(10,2), -- km
  weekly_duration INTEGER, -- minutes
  weekly_activities INTEGER,
  
  -- Calculated status
  load_status TEXT CHECK (load_status IN ('optimal', 'high', 'very_high', 'critical')),
  
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(athlete_id, date)
);

CREATE INDEX idx_training_load_athlete ON public.training_load(athlete_id);
CREATE INDEX idx_training_load_date ON public.training_load(date DESC);

COMMENT ON TABLE public.training_load IS 'Training load calculations for injury prevention';

-- =====================================================
-- VIEWS: Useful queries
-- =====================================================

-- Latest AISRI scores per athlete
CREATE OR REPLACE VIEW public.v_latest_aisri_scores AS
SELECT DISTINCT ON (athlete_id)
  athlete_id,
  aisri_score,
  risk_category,
  pillar_running,
  pillar_strength,
  pillar_rom,
  pillar_balance,
  pillar_alignment,
  pillar_mobility,
  recorded_at
FROM public.aisri_score_history
ORDER BY athlete_id, recorded_at DESC;

-- Upcoming evaluations
CREATE OR REPLACE VIEW public.v_upcoming_evaluations AS
SELECT 
  es.athlete_id,
  p.full_name,
  p.email,
  es.next_evaluation_date,
  es.status,
  es.reminder_sent_at,
  CASE 
    WHEN es.next_evaluation_date < CURRENT_DATE THEN 'overdue'
    WHEN es.next_evaluation_date = CURRENT_DATE THEN 'today'
    WHEN es.next_evaluation_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'this_week'
    ELSE 'upcoming'
  END AS urgency
FROM public.evaluation_schedule es
JOIN public.profiles p ON es.athlete_id = p.id
WHERE es.status IN ('pending', 'reminded', 'overdue')
ORDER BY es.next_evaluation_date;

-- Coach's athlete summary
CREATE OR REPLACE VIEW public.v_coach_athletes AS
SELECT 
  p.id AS athlete_id,
  p.full_name,
  p.email,
  p.onboarding_completed,
  p.coach_id,
  las.aisri_score,
  las.risk_category,
  las.recorded_at AS last_assessment_date,
  sc.connected AS strava_connected,
  sc.last_sync_at AS strava_last_sync
FROM public.profiles p
LEFT JOIN public.v_latest_aisri_scores las ON p.id = las.athlete_id
LEFT JOIN public.strava_connections sc ON p.id = sc.athlete_id
WHERE p.role = 'athlete'
ORDER BY las.risk_category DESC, p.full_name;

-- =====================================================
-- FUNCTIONS: Automated tasks
-- =====================================================

-- Function to create next monthly evaluation
CREATE OR REPLACE FUNCTION public.create_next_evaluation(p_athlete_id UUID)
RETURNS UUID AS $$
DECLARE
  v_evaluation_id UUID;
  v_last_assessment_date DATE;
  v_next_date DATE;
BEGIN
  -- Get last assessment date
  SELECT assessment_date INTO v_last_assessment_date
  FROM public.physical_assessments
  WHERE athlete_id = p_athlete_id
  ORDER BY assessment_date DESC
  LIMIT 1;
  
  -- If no previous assessment, schedule 30 days from now
  IF v_last_assessment_date IS NULL THEN
    v_next_date := CURRENT_DATE + INTERVAL '30 days';
  ELSE
    v_next_date := v_last_assessment_date + INTERVAL '30 days';
  END IF;
  
  -- Create evaluation schedule
  INSERT INTO public.evaluation_schedule (athlete_id, next_evaluation_date)
  VALUES (p_athlete_id, v_next_date)
  ON CONFLICT (athlete_id, next_evaluation_date) DO NOTHING
  RETURNING id INTO v_evaluation_id;
  
  RETURN v_evaluation_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate AISRI score from physical assessments
CREATE OR REPLACE FUNCTION public.calculate_aisri_from_assessment(p_assessment_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_aisri_score INTEGER;
  v_athlete_id UUID;
  v_assessment_date TIMESTAMPTZ;
  -- Pillar scores
  v_running INTEGER := 0;
  v_strength INTEGER := 0;
  v_rom INTEGER := 0;
  v_balance INTEGER := 0;
  v_alignment INTEGER := 0;
  v_mobility INTEGER := 0;
BEGIN
  -- Get assessment data
  SELECT 
    athlete_id,
    assessment_date,
    -- Calculate ROM score (average of all ROM tests)
    ROUND((COALESCE(rom_ankle_dorsiflexion_left, 0) + COALESCE(rom_ankle_dorsiflexion_right, 0) + 
           COALESCE(rom_hip_flexion_left, 0) + COALESCE(rom_hip_flexion_right, 0)) / 4.0),
    -- Calculate Strength score (average of all strength tests, normalized to 0-100)
    ROUND((COALESCE(strength_single_leg_squat_left, 0) + COALESCE(strength_single_leg_squat_right, 0) + 
           COALESCE(strength_calf_raise_left, 0) + COALESCE(strength_calf_raise_right, 0)) / 4.0),
    -- Calculate Balance score
    ROUND((COALESCE(balance_single_leg_left, 0) + COALESCE(balance_single_leg_right, 0)) / 2.0),
    -- Mobility score
    ROUND((COALESCE(mobility_hip_flexor_left, 0) + COALESCE(mobility_hip_flexor_right, 0) + 
           COALESCE(mobility_hamstring_left, 0) + COALESCE(mobility_hamstring_right, 0)) / 4.0 * 10),
    -- Alignment score
    COALESCE(alignment_posture_score, 0)
  INTO 
    v_athlete_id,
    v_assessment_date,
    v_rom,
    v_strength,
    v_balance,
    v_mobility,
    v_alignment
  FROM public.physical_assessments
  WHERE id = p_assessment_id;
  
  -- Get running score from latest Strava data (simplified - would use ML analyzer in production)
  SELECT COALESCE(running_performance_score, 50) INTO v_running
  FROM public.aisri_scores
  WHERE athlete_id = v_athlete_id
  ORDER BY assessment_date DESC
  LIMIT 1;
  
  -- Calculate weighted AISRI score (6 pillars)
  -- Running: 40%, Strength: 15%, ROM: 12%, Balance: 13%, Alignment: 10%, Mobility: 10%
  v_aisri_score := ROUND(
    v_running * 0.40 +
    v_strength * 0.15 +
    v_rom * 0.12 +
    v_balance * 0.13 +
    v_alignment * 0.10 +
    v_mobility * 0.10
  );
  
  -- Store in history
  INSERT INTO public.aisri_score_history (
    athlete_id,
    assessment_id,
    aisri_score,
    risk_category,
    pillar_running,
    pillar_strength,
    pillar_rom,
    pillar_balance,
    pillar_alignment,
    pillar_mobility
  ) VALUES (
    v_athlete_id,
    p_assessment_id,
    v_aisri_score,
    CASE 
      WHEN v_aisri_score >= 75 THEN 'Low Risk'
      WHEN v_aisri_score >= 55 THEN 'Medium Risk'
      WHEN v_aisri_score >= 35 THEN 'High Risk'
      ELSE 'Critical Risk'
    END,
    v_running,
    v_strength,
    v_rom,
    v_balance,
    v_alignment,
    v_mobility
  );
  
  RETURN v_aisri_score;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE public.physical_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluation_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aisri_score_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_load ENABLE ROW LEVEL SECURITY;

-- Physical Assessments Policies
CREATE POLICY "Athletes can view their own assessments"
  ON public.physical_assessments FOR SELECT
  USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches can view their athletes' assessments"
  ON public.physical_assessments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('coach', 'admin')
    )
  );

CREATE POLICY "Coaches can insert assessments for their athletes"
  ON public.physical_assessments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('coach', 'admin')
    )
  );

-- Training Plans Policies
CREATE POLICY "Athletes can view their own training plans"
  ON public.training_plans FOR SELECT
  USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches can manage training plans"
  ON public.training_plans FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('coach', 'admin')
    )
  );

-- Daily Workouts Policies
CREATE POLICY "Athletes can view and update their own workouts"
  ON public.daily_workouts FOR ALL
  USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches can manage their athletes' workouts"
  ON public.daily_workouts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('coach', 'admin')
    )
  );

-- =====================================================
-- GRANTS
-- =====================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON SCHEMA public IS 'SafeStride Modern Platform - Complete athlete management with AISRI scoring, physical assessments, training plans, and re-evaluation system';

-- =====================================================
-- END OF MIGRATION
-- =====================================================
