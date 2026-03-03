-- =====================================================
-- CHUNK 2: Create 8 Main Tables for Platform Modernization
-- =====================================================

-- 1. Physical Assessments Table
CREATE TABLE IF NOT EXISTS public.physical_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    assessment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assessment_type TEXT NOT NULL CHECK (assessment_type IN ('initial', 'monthly', 'injury', 'return-to-sport')),
    
    -- ROM (Range of Motion) Tests
    ankle_dorsiflexion_left INTEGER,
    ankle_dorsiflexion_right INTEGER,
    hip_flexion_left INTEGER,
    hip_flexion_right INTEGER,
    hip_extension_left INTEGER,
    hip_extension_right INTEGER,
    
    -- Strength Tests
    single_leg_calf_raise_left INTEGER,
    single_leg_calf_raise_right INTEGER,
    glute_bridge_hold_time INTEGER,
    plank_hold_time INTEGER,
    
    -- Balance Tests
    single_leg_stand_left INTEGER,
    single_leg_stand_right INTEGER,
    y_balance_anterior_left DECIMAL(5,2),
    y_balance_anterior_right DECIMAL(5,2),
    
    -- Mobility Tests
    overhead_squat_score INTEGER CHECK (overhead_squat_score BETWEEN 0 AND 3),
    hurdle_step_left INTEGER CHECK (hurdle_step_left BETWEEN 0 AND 3),
    hurdle_step_right INTEGER CHECK (hurdle_step_right BETWEEN 0 AND 3),
    
    -- Calculated Scores
    rom_score INTEGER CHECK (rom_score BETWEEN 0 AND 100),
    strength_score INTEGER CHECK (strength_score BETWEEN 0 AND 100),
    balance_score INTEGER CHECK (balance_score BETWEEN 0 AND 100),
    mobility_score INTEGER CHECK (mobility_score BETWEEN 0 AND 100),
    
    -- Notes
    assessor_notes TEXT,
    athlete_feedback TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_physical_assessments_athlete ON public.physical_assessments(athlete_id);
CREATE INDEX IF NOT EXISTS idx_physical_assessments_date ON public.physical_assessments(assessment_date DESC);

-- 2. Assessment Media Table
CREATE TABLE IF NOT EXISTS public.assessment_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES public.physical_assessments(id) ON DELETE CASCADE,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    test_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size_bytes INTEGER,
    mime_type TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_assessment_media_assessment ON public.assessment_media(assessment_id);

-- 3. Training Plans Table
CREATE TABLE IF NOT EXISTS public.training_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_weeks INTEGER NOT NULL DEFAULT 12,
    aisri_score_at_creation INTEGER,
    risk_level_at_creation TEXT CHECK (risk_level_at_creation IN ('low', 'medium', 'high', 'critical')),
    goal_race_distance TEXT,
    goal_race_date DATE,
    target_weekly_volume_km DECIMAL(5,2),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'abandoned')),
    generated_by TEXT,
    generation_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_training_plans_athlete ON public.training_plans(athlete_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_status ON public.training_plans(status);

-- 4. Daily Workouts Table
CREATE TABLE IF NOT EXISTS public.daily_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    training_plan_id UUID NOT NULL REFERENCES public.training_plans(id) ON DELETE CASCADE,
    workout_date DATE NOT NULL,
    week_number INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 12),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    workout_type TEXT NOT NULL CHECK (workout_type IN ('easy_run', 'tempo', 'intervals', 'long_run', 'recovery', 'rest', 'cross_training', 'strength')),
    planned_distance_km DECIMAL(5,2),
    planned_duration_minutes INTEGER,
    target_zone TEXT,
    target_pace_min_per_km TEXT,
    warmup_minutes INTEGER,
    cooldown_minutes INTEGER,
    intervals_json JSONB,
    workout_title TEXT NOT NULL,
    workout_description TEXT,
    coaching_notes TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_workouts_plan ON public.daily_workouts(training_plan_id);
CREATE INDEX IF NOT EXISTS idx_daily_workouts_date ON public.daily_workouts(workout_date);

-- 5. Workout Completions Table
CREATE TABLE IF NOT EXISTS public.workout_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_workout_id UUID NOT NULL REFERENCES public.daily_workouts(id) ON DELETE CASCADE,
    athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    actual_distance_km DECIMAL(5,2),
    actual_duration_minutes INTEGER,
    actual_pace_min_per_km TEXT,
    average_hr INTEGER,
    max_hr INTEGER,
    strava_activity_id BIGINT,
    synced_from_strava BOOLEAN DEFAULT FALSE,
    perceived_effort INTEGER CHECK (perceived_effort BETWEEN 1 AND 10),
    fatigue_level INTEGER CHECK (fatigue_level BETWEEN 1 AND 10),
    mood_score INTEGER CHECK (mood_score BETWEEN 1 AND 10),
    sleep_hours DECIMAL(3,1),
    athlete_notes TEXT,
    injury_reported BOOLEAN DEFAULT FALSE,
    injury_description TEXT,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_completions_workout ON public.workout_completions(daily_workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_completions_athlete ON public.workout_completions(athlete_id);

-- 6. Evaluation Schedule Table
CREATE TABLE IF NOT EXISTS public.evaluation_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    evaluation_type TEXT NOT NULL CHECK (evaluation_type IN ('monthly', 'quarterly', 'injury_followup', 'return_to_sport')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'missed', 'rescheduled')),
    completed_assessment_id UUID REFERENCES public.physical_assessments(id),
    completed_at TIMESTAMPTZ,
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evaluation_schedule_athlete ON public.evaluation_schedule(athlete_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_schedule_date ON public.evaluation_schedule(scheduled_date);

-- 7. AISRI Score History Table
CREATE TABLE IF NOT EXISTS public.aisri_score_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_aisri_score INTEGER NOT NULL CHECK (total_aisri_score BETWEEN 0 AND 100),
    risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    running_score INTEGER CHECK (running_score BETWEEN 0 AND 100),
    strength_score INTEGER CHECK (strength_score BETWEEN 0 AND 100),
    rom_score INTEGER CHECK (rom_score BETWEEN 0 AND 100),
    balance_score INTEGER CHECK (balance_score BETWEEN 0 AND 100),
    alignment_score INTEGER CHECK (alignment_score BETWEEN 0 AND 100),
    mobility_score INTEGER CHECK (mobility_score BETWEEN 0 AND 100),
    running_weighted DECIMAL(5,2),
    strength_weighted DECIMAL(5,2),
    rom_weighted DECIMAL(5,2),
    balance_weighted DECIMAL(5,2),
    alignment_weighted DECIMAL(5,2),
    mobility_weighted DECIMAL(5,2),
    calculation_source TEXT,
    source_assessment_id UUID REFERENCES public.physical_assessments(id),
    previous_score INTEGER,
    score_change INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_aisri_history_athlete ON public.aisri_score_history(athlete_id);
CREATE INDEX IF NOT EXISTS idx_aisri_history_date ON public.aisri_score_history(calculated_at DESC);

-- 8. Training Load Table
CREATE TABLE IF NOT EXISTS public.training_load (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    distance_km DECIMAL(5,2),
    duration_minutes INTEGER,
    training_load INTEGER,
    acute_load INTEGER,
    chronic_load INTEGER,
    acr DECIMAL(4,2),
    acr_status TEXT CHECK (acr_status IN ('safe', 'caution', 'danger')),
    injury_risk TEXT CHECK (injury_risk IN ('low', 'moderate', 'high')),
    recommended_adjustment TEXT,
    calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_training_load_athlete ON public.training_load(athlete_id);
CREATE INDEX IF NOT EXISTS idx_training_load_date ON public.training_load(date DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_training_load_athlete_date ON public.training_load(athlete_id, date);

