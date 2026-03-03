-- =====================================================
-- CHUNK 3 FIXED: Views, Functions, RLS Policies
-- =====================================================
-- This version fixes the UUID vs TEXT type mismatch
-- =====================================================

-- Drop existing views/functions first to avoid conflicts
DROP VIEW IF EXISTS public.v_coach_athletes CASCADE;
DROP VIEW IF EXISTS public.v_upcoming_evaluations CASCADE;
DROP VIEW IF EXISTS public.v_latest_aisri_scores CASCADE;
DROP FUNCTION IF EXISTS public.create_next_evaluation(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.calculate_aisri_from_assessment(UUID) CASCADE;

-- =====================================================
-- VIEW 1: Latest AISRI Scores (one per athlete)
-- =====================================================
CREATE VIEW public.v_latest_aisri_scores AS
SELECT DISTINCT ON (athlete_id)
    athlete_id,
    source_assessment_id as assessment_id,
    total_aisri_score as total_score,
    rom_score,
    strength_score,
    balance_score,
    mobility_score,
    0 as endurance_score,
    0 as recovery_score,
    risk_level,
    calculated_at
FROM public.aisri_score_history
ORDER BY athlete_id, calculated_at DESC;

-- =====================================================
-- VIEW 2: Upcoming Evaluations (with urgency)
-- =====================================================
CREATE VIEW public.v_upcoming_evaluations AS
SELECT 
    es.*,
    p.full_name as athlete_name,
    CASE 
        WHEN es.scheduled_date < CURRENT_DATE THEN 'overdue'
        WHEN es.scheduled_date = CURRENT_DATE THEN 'today'
        WHEN es.scheduled_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'this_week'
        ELSE 'upcoming'
    END as urgency
FROM public.evaluation_schedule es
JOIN public.profiles p ON es.athlete_id = p.id
WHERE es.status = 'pending'
ORDER BY es.scheduled_date ASC;

-- =====================================================
-- VIEW 3: Coach Athletes (comprehensive dashboard view)
-- =====================================================
-- FIXED LINE 81: Cast p.id::text to match strava_connections.athlete_id type
CREATE VIEW public.v_coach_athletes AS
SELECT 
    p.id,
    p.full_name,
    p.email,
    p.created_at as joined_date,
    p.onboarding_completed,
    p.coach_id,
    coach.full_name as coach_name,
    las.total_score as latest_aisri_score,
    las.risk_level,
    las.calculated_at as last_assessment_date,
    sc.access_token IS NOT NULL as strava_connected,
    sc.athlete_id as strava_athlete_id,
    (SELECT COUNT(*) FROM public.physical_assessments WHERE athlete_id = p.id) as assessment_count,
    (SELECT COUNT(*) FROM public.training_plans WHERE athlete_id = p.id AND status = 'active') as active_plan_count
FROM public.profiles p
LEFT JOIN public.profiles coach ON p.coach_id = coach.id
LEFT JOIN public.v_latest_aisri_scores las ON p.id = las.athlete_id
LEFT JOIN public.strava_connections sc ON p.id::text = sc.athlete_id
WHERE p.role = 'athlete';

-- =====================================================
-- FUNCTION 1: Create Next Evaluation (auto-schedule)
-- =====================================================
CREATE OR REPLACE FUNCTION public.create_next_evaluation(p_athlete_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_eval_id UUID;
BEGIN
    INSERT INTO public.evaluation_schedule (
        athlete_id,
        scheduled_date,
        evaluation_type,
        status
    ) VALUES (
        p_athlete_id,
        CURRENT_DATE + INTERVAL '30 days',
        'monthly',
        'pending'
    )
    RETURNING id INTO v_eval_id;
    
    RETURN v_eval_id;
END;
$$;

-- =====================================================
-- FUNCTION 2: Calculate AISRI from Assessment
-- =====================================================
-- This is the core AISRI calculation with 6 pillars
CREATE OR REPLACE FUNCTION public.calculate_aisri_from_assessment(p_assessment_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_athlete_id UUID;
    v_score_id UUID;
    v_rom_score DECIMAL(5,2);
    v_strength_score DECIMAL(5,2);
    v_balance_score DECIMAL(5,2);
    v_mobility_score DECIMAL(5,2);
    v_endurance_score DECIMAL(5,2);
    v_recovery_score DECIMAL(5,2);
    v_total_score DECIMAL(5,2);
    v_risk_level TEXT;
BEGIN
    -- Get athlete_id from assessment
    SELECT athlete_id INTO v_athlete_id
    FROM public.physical_assessments
    WHERE id = p_assessment_id;
    
    -- Calculate ROM Score (40% weight): Average of ankle/hip tests
    SELECT 
        ((COALESCE(ankle_dorsiflexion_left, 0) + 
          COALESCE(ankle_dorsiflexion_right, 0) + 
          COALESCE(hip_flexion_left, 0) + 
          COALESCE(hip_flexion_right, 0)) / 12.0) * 100
    INTO v_rom_score
    FROM public.physical_assessments
    WHERE id = p_assessment_id;
    
    -- Calculate Strength Score (15% weight): Average of strength tests
    SELECT 
        ((COALESCE(single_leg_calf_raise_left, 0) + 
          COALESCE(single_leg_calf_raise_right, 0) + 
          COALESCE(glute_bridge_hold_time, 0) / 60.0 * 3) / 9.0) * 100
    INTO v_strength_score
    FROM public.physical_assessments
    WHERE id = p_assessment_id;
    
    -- Calculate Balance Score (12% weight): Average of balance tests
    SELECT 
        ((COALESCE(single_leg_stand_left, 0) + 
          COALESCE(single_leg_stand_right, 0)) / 60.0) * 100
    INTO v_balance_score
    FROM public.physical_assessments
    WHERE id = p_assessment_id;
    
    -- Calculate Mobility Score (13% weight): Overhead squat and hurdle tests
    SELECT 
        ((COALESCE(overhead_squat_score, 0) + 
          COALESCE(hurdle_step_left, 0) + 
          COALESCE(hurdle_step_right, 0)) / 9.0) * 100
    INTO v_mobility_score
    FROM public.physical_assessments
    WHERE id = p_assessment_id;
    
    -- Endurance Score (10% weight): Placeholder - would come from training data
    v_endurance_score := 70.0;
    
    -- Recovery Score (10% weight): Placeholder - would come from HRV/sleep data
    v_recovery_score := 75.0;
    
    -- Calculate weighted total (out of 100)
    v_total_score := (
        (v_rom_score * 0.40) +
        (v_strength_score * 0.15) +
        (v_balance_score * 0.12) +
        (v_mobility_score * 0.13) +
        (v_endurance_score * 0.10) +
        (v_recovery_score * 0.10)
    );
    
    -- Determine risk level
    v_risk_level := CASE
        WHEN v_total_score >= 80 THEN 'low'
        WHEN v_total_score >= 60 THEN 'medium'
        ELSE 'high'
    END;
    
    -- Insert into history
    INSERT INTO public.aisri_score_history (
        athlete_id,
        source_assessment_id,
        total_aisri_score,
        rom_score,
        strength_score,
        balance_score,
        mobility_score,
        running_score,
        alignment_score,
        risk_level,
        calculation_source
    ) VALUES (
        v_athlete_id,
        p_assessment_id,
        v_total_score::INTEGER,
        v_rom_score::INTEGER,
        v_strength_score::INTEGER,
        v_balance_score::INTEGER,
        v_mobility_score::INTEGER,
        0,
        0,
        v_risk_level,
        'physical_assessment'
    )
    RETURNING id INTO v_score_id;
    
    -- Schedule next evaluation (30 days)
    PERFORM public.create_next_evaluation(v_athlete_id);
    
    RETURN v_score_id;
END;
$$;

-- =====================================================
-- RLS POLICIES: Row-Level Security
-- =====================================================

-- Drop existing policies first to avoid "already exists" errors
DROP POLICY IF EXISTS "Athletes can view their own assessments" ON public.physical_assessments;
DROP POLICY IF EXISTS "Athletes can insert their own assessments" ON public.physical_assessments;
DROP POLICY IF EXISTS "Coaches can view their athletes assessments" ON public.physical_assessments;
DROP POLICY IF EXISTS "Athletes can view their own plans" ON public.training_plans;
DROP POLICY IF EXISTS "Coaches can manage their athletes plans" ON public.training_plans;
DROP POLICY IF EXISTS "Athletes can view their workouts" ON public.daily_workouts;
DROP POLICY IF EXISTS "Athletes can complete workouts" ON public.workout_completions;
DROP POLICY IF EXISTS "Athletes can view their AISRI scores" ON public.aisri_score_history;
DROP POLICY IF EXISTS "Coaches can view their athletes scores" ON public.aisri_score_history;
DROP POLICY IF EXISTS "Athletes can view evaluation schedule" ON public.evaluation_schedule;
DROP POLICY IF EXISTS "Coaches can manage evaluation schedule" ON public.evaluation_schedule;

-- Enable RLS on all tables
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
    USING (athlete_id = auth.uid());

CREATE POLICY "Athletes can insert their own assessments"
    ON public.physical_assessments FOR INSERT
    WITH CHECK (athlete_id = auth.uid());

CREATE POLICY "Coaches can view their athletes assessments"
    ON public.physical_assessments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = athlete_id AND coach_id = auth.uid()
        )
    );

-- Training Plans Policies
CREATE POLICY "Athletes can view their own plans"
    ON public.training_plans FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "Coaches can manage their athletes plans"
    ON public.training_plans FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = athlete_id AND coach_id = auth.uid()
        )
    );

-- Daily Workouts Policy
CREATE POLICY "Athletes can view their workouts"
    ON public.daily_workouts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.training_plans tp
            WHERE tp.id = training_plan_id AND tp.athlete_id = auth.uid()
        )
    );

-- Workout Completions Policy
CREATE POLICY "Athletes can complete workouts"
    ON public.workout_completions FOR ALL
    USING (athlete_id = auth.uid());

-- AISRI Score History Policies
CREATE POLICY "Athletes can view their AISRI scores"
    ON public.aisri_score_history FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "Coaches can view their athletes scores"
    ON public.aisri_score_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = athlete_id AND coach_id = auth.uid()
        )
    );

-- Evaluation Schedule Policies
CREATE POLICY "Athletes can view evaluation schedule"
    ON public.evaluation_schedule FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "Coaches can manage evaluation schedule"
    ON public.evaluation_schedule FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = athlete_id AND coach_id = auth.uid()
        )
    );

-- =====================================================
-- GRANTS: Function permissions
-- =====================================================
GRANT EXECUTE ON FUNCTION public.calculate_aisri_from_assessment(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_next_evaluation(UUID) TO authenticated;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 'Migration Complete! 3 views + 2 functions + 11 RLS policies created' as status;
