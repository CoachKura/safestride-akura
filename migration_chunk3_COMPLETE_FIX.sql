-- =====================================================
-- CHUNK 3 COMPLETE FIX: All Syntax Errors Corrected
-- =====================================================

-- Drop existing views to recreate them
DROP VIEW IF EXISTS public.v_coach_athletes CASCADE;
DROP VIEW IF EXISTS public.v_upcoming_evaluations CASCADE;
DROP VIEW IF EXISTS public.v_latest_aisri_scores CASCADE;

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS public.calculate_aisri_from_assessment(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.create_next_evaluation(UUID) CASCADE;

-- View: Latest AISRI Score per Athlete
CREATE OR REPLACE VIEW public.v_latest_aisri_scores AS
SELECT DISTINCT ON (athlete_id)
    athlete_id,
    total_aisri_score,
    risk_level,
    running_score,
    strength_score,
    rom_score,
    balance_score,
    alignment_score,
    mobility_score,
    calculated_at,
    score_change
FROM public.aisri_score_history
ORDER BY athlete_id, calculated_at DESC;

COMMENT ON VIEW public.v_latest_aisri_scores IS 'Latest AISRI score for each athlete';

-- View: Upcoming Evaluations with Urgency (FIXED INTERVAL SYNTAX)
CREATE OR REPLACE VIEW public.v_upcoming_evaluations AS
SELECT 
    es.id,
    es.athlete_id,
    p.full_name as athlete_name,
    p.email as athlete_email,
    es.scheduled_date,
    es.evaluation_type,
    es.status,
    CASE 
        WHEN es.scheduled_date < CURRENT_DATE THEN 'overdue'
        WHEN es.scheduled_date = CURRENT_DATE THEN 'today'
        WHEN es.scheduled_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'this_week'
        ELSE 'upcoming'
    END as urgency,
    es.reminder_sent,
    es.created_at
FROM public.evaluation_schedule es
JOIN public.profiles p ON es.athlete_id = p.id
WHERE es.status IN ('pending', 'rescheduled')
ORDER BY es.scheduled_date ASC;

COMMENT ON VIEW public.v_upcoming_evaluations IS 'Upcoming evaluations with urgency indicators';

-- View: Coach Athletes Summary (FIXED ALL QUOTES)
CREATE OR REPLACE VIEW public.v_coach_athletes AS
SELECT 
    p.id as athlete_id,
    p.full_name as athlete_name,
    p.email as athlete_email,
    p.coach_id,
    coach.full_name as coach_name,
    p.onboarding_completed,
    p.gender,
    p.weight,
    p.height,
    aisri.total_aisri_score,
    aisri.risk_level,
    aisri.calculated_at as last_aisri_update,
    sc.connected as strava_connected,
    sc.strava_athlete_id,
    (SELECT COUNT(*) FROM public.physical_assessments pa WHERE pa.athlete_id = p.id) as total_assessments,
    (SELECT MAX(assessment_date) FROM public.physical_assessments pa WHERE pa.athlete_id = p.id) as last_assessment_date,
    (SELECT COUNT(*) FROM public.training_plans tp WHERE tp.athlete_id = p.id AND tp.status = 'active') as active_plans
FROM public.profiles p
LEFT JOIN public.profiles coach ON p.coach_id = coach.id
LEFT JOIN public.v_latest_aisri_scores aisri ON p.id = aisri.athlete_id
LEFT JOIN public.strava_connections sc ON p.id = sc.athlete_id
WHERE p.role = 'athlete';

COMMENT ON VIEW public.v_coach_athletes IS 'Comprehensive athlete summary for coaches';

-- Function: Create Next Monthly Evaluation (FIXED INTERVAL)
CREATE OR REPLACE FUNCTION public.create_next_evaluation(p_athlete_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_date DATE;
    v_eval_id UUID;
BEGIN
    SELECT COALESCE(MAX(assessment_date), CURRENT_DATE) + INTERVAL '30 days'
    INTO v_next_date
    FROM public.physical_assessments
    WHERE athlete_id = p_athlete_id;
    
    INSERT INTO public.evaluation_schedule (
        athlete_id,
        scheduled_date,
        evaluation_type,
        status
    ) VALUES (
        p_athlete_id,
        v_next_date,
        'monthly',
        'pending'
    )
    RETURNING id INTO v_eval_id;
    
    RETURN v_eval_id;
END;
$$;

COMMENT ON FUNCTION public.create_next_evaluation(UUID) IS 'Schedule next monthly evaluation 30 days from last assessment';

-- Function: Calculate AISRI from Physical Assessment (FIXED ALL QUOTES)
CREATE OR REPLACE FUNCTION public.calculate_aisri_from_assessment(p_assessment_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_athlete_id UUID;
    v_rom_score INTEGER;
    v_strength_score INTEGER;
    v_balance_score INTEGER;
    v_mobility_score INTEGER;
    v_running_score INTEGER := 75;
    v_alignment_score INTEGER := 70;
    v_total_score INTEGER;
    v_risk_level TEXT;
    v_previous_score INTEGER;
BEGIN
    SELECT 
        athlete_id,
        rom_score,
        strength_score,
        balance_score,
        mobility_score
    INTO
        v_athlete_id,
        v_rom_score,
        v_strength_score,
        v_balance_score,
        v_mobility_score
    FROM public.physical_assessments
    WHERE id = p_assessment_id;
    
    SELECT total_aisri_score INTO v_previous_score
    FROM public.aisri_score_history
    WHERE athlete_id = v_athlete_id
    ORDER BY calculated_at DESC
    LIMIT 1;
    
    v_total_score := (
        (COALESCE(v_running_score, 0) * 0.40) +
        (COALESCE(v_strength_score, 0) * 0.15) +
        (COALESCE(v_rom_score, 0) * 0.12) +
        (COALESCE(v_balance_score, 0) * 0.13) +
        (COALESCE(v_alignment_score, 0) * 0.10) +
        (COALESCE(v_mobility_score, 0) * 0.10)
    )::INTEGER;
    
    v_risk_level := CASE
        WHEN v_total_score < 40 THEN 'low'
        WHEN v_total_score < 55 THEN 'medium'
        WHEN v_total_score < 75 THEN 'high'
        ELSE 'critical'
    END;
    
    INSERT INTO public.aisri_score_history (
        athlete_id,
        total_aisri_score,
        risk_level,
        running_score,
        strength_score,
        rom_score,
        balance_score,
        alignment_score,
        mobility_score,
        running_weighted,
        strength_weighted,
        rom_weighted,
        balance_weighted,
        alignment_weighted,
        mobility_weighted,
        calculation_source,
        source_assessment_id,
        previous_score,
        score_change
    ) VALUES (
        v_athlete_id,
        v_total_score,
        v_risk_level,
        v_running_score,
        v_strength_score,
        v_rom_score,
        v_balance_score,
        v_alignment_score,
        v_mobility_score,
        (v_running_score * 0.40),
        (v_strength_score * 0.15),
        (v_rom_score * 0.12),
        (v_balance_score * 0.13),
        (v_alignment_score * 0.10),
        (v_mobility_score * 0.10),
        'physical_assessment',
        p_assessment_id,
        v_previous_score,
        v_total_score - COALESCE(v_previous_score, v_total_score)
    );
    
    RETURN v_total_score;
END;
$$;

COMMENT ON FUNCTION public.calculate_aisri_from_assessment(UUID) IS 'Calculate AISRI score from physical assessment with 6-pillar weighting';

-- Enable RLS on all new tables
ALTER TABLE public.physical_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluation_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aisri_score_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_load ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid "already exists" errors)
DROP POLICY IF EXISTS physical_assessments_select ON public.physical_assessments;
DROP POLICY IF EXISTS physical_assessments_insert ON public.physical_assessments;
DROP POLICY IF EXISTS assessment_media_select ON public.assessment_media;
DROP POLICY IF EXISTS training_plans_select ON public.training_plans;
DROP POLICY IF EXISTS training_plans_insert ON public.training_plans;
DROP POLICY IF EXISTS daily_workouts_select ON public.daily_workouts;
DROP POLICY IF EXISTS workout_completions_select ON public.workout_completions;
DROP POLICY IF EXISTS workout_completions_insert ON public.workout_completions;
DROP POLICY IF EXISTS evaluation_schedule_select ON public.evaluation_schedule;
DROP POLICY IF EXISTS aisri_score_history_select ON public.aisri_score_history;
DROP POLICY IF EXISTS training_load_select ON public.training_load;

-- Policy: physical_assessments (FIXED QUOTES)
CREATE POLICY physical_assessments_select ON public.physical_assessments
    FOR SELECT
    USING (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('coach', 'admin')
            AND (role = 'admin' OR id = (SELECT coach_id FROM public.profiles WHERE id = physical_assessments.athlete_id))
        )
    );

CREATE POLICY physical_assessments_insert ON public.physical_assessments
    FOR INSERT
    WITH CHECK (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

-- Policy: assessment_media (FIXED QUOTES)
CREATE POLICY assessment_media_select ON public.assessment_media
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.physical_assessments pa
            WHERE pa.id = assessment_media.assessment_id
            AND (
                pa.athlete_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.profiles p
                    WHERE p.id = auth.uid()
                    AND p.role IN ('coach', 'admin')
                )
            )
        )
    );

-- Policy: training_plans (FIXED QUOTES)
CREATE POLICY training_plans_select ON public.training_plans
    FOR SELECT
    USING (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

CREATE POLICY training_plans_insert ON public.training_plans
    FOR INSERT
    WITH CHECK (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

-- Policy: daily_workouts (FIXED QUOTES)
CREATE POLICY daily_workouts_select ON public.daily_workouts
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.training_plans tp
            WHERE tp.id = daily_workouts.training_plan_id
            AND (
                tp.athlete_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.profiles p
                    WHERE p.id = auth.uid() AND p.role IN ('coach', 'admin')
                )
            )
        )
    );

-- Policy: workout_completions (FIXED QUOTES)
CREATE POLICY workout_completions_select ON public.workout_completions
    FOR SELECT
    USING (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

CREATE POLICY workout_completions_insert ON public.workout_completions
    FOR INSERT
    WITH CHECK (athlete_id = auth.uid());

-- Policy: evaluation_schedule (FIXED QUOTES)
CREATE POLICY evaluation_schedule_select ON public.evaluation_schedule
    FOR SELECT
    USING (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

-- Policy: aisri_score_history (FIXED QUOTES)
CREATE POLICY aisri_score_history_select ON public.aisri_score_history
    FOR SELECT
    USING (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

-- Policy: training_load (FIXED QUOTES)
CREATE POLICY training_load_select ON public.training_load
    FOR SELECT
    USING (
        athlete_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('coach', 'admin')
        )
    );

-- Grants
GRANT SELECT ON public.v_latest_aisri_scores TO authenticated;
GRANT SELECT ON public.v_upcoming_evaluations TO authenticated;
GRANT SELECT ON public.v_coach_athletes TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_next_evaluation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_aisri_from_assessment(UUID) TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.physical_assessments TO authenticated;
GRANT SELECT, INSERT ON public.assessment_media TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.training_plans TO authenticated;
GRANT SELECT ON public.daily_workouts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.workout_completions TO authenticated;
GRANT SELECT ON public.evaluation_schedule TO authenticated;
GRANT SELECT ON public.aisri_score_history TO authenticated;
GRANT SELECT ON public.training_load TO authenticated;
