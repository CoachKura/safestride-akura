-- Supabase Edge Function: Weekly Tracking Cron Job
-- Run every Sunday at 11:59 PM to track weekly performance
-- and trigger adaptations after week 4

CREATE OR REPLACE FUNCTION kura_coach_weekly_tracking()
RETURNS void AS $$
DECLARE
    active_plan RECORD;
    week_number INT;
    current_aisri DECIMAL;
BEGIN
    -- Loop through all active workout plans
    FOR active_plan IN 
        SELECT DISTINCT
            awp.id as plan_id,
            awp.user_id,
            awp.start_date,
            awp.training_phase,
            awp.aisri_score_at_creation
        FROM ai_workout_plans awp
        WHERE awp.status = 'active'
    LOOP
        -- Calculate which week number this is (1-4)
        week_number := CEIL((CURRENT_DATE - active_plan.start_date)::NUMERIC / 7.0);
        
        -- Only track weeks 1-4
        IF week_number BETWEEN 1 AND 4 THEN
            -- Track weekly performance
            -- (This would call the tracking logic)
            RAISE NOTICE 'Tracking week % for user %', week_number, active_plan.user_id;
            
            -- After week 4, trigger adaptation
            IF week_number = 4 THEN
                RAISE NOTICE 'Week 4 complete for user %, triggering adaptation', active_plan.user_id;
                -- Mark plan as completed
                UPDATE ai_workout_plans
                SET status = 'completed'
                WHERE id = active_plan.plan_id;
                
                -- Adaptation logic would be triggered here
                -- (Called from Flutter app via notification or scheduled task)
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create pg_cron job (if pg_cron extension is available)
-- Run every Sunday at 23:59
-- SELECT cron.schedule('kura-coach-weekly-tracking', '59 23 * * 0', 'SELECT kura_coach_weekly_tracking();');

-- Alternative: Create a view to identify athletes needing adaptation
CREATE OR REPLACE VIEW athletes_needing_adaptation AS
SELECT 
    awp.id as plan_id,
    awp.user_id,
    COALESCE(ap.name, au.email) as athlete_name,
    awp.training_phase as current_phase,
    awp.start_date,
    CEIL((CURRENT_DATE - awp.start_date)::NUMERIC / 7.0) as weeks_completed,
    COUNT(CASE WHEN aw.status = 'completed' THEN 1 END) as workouts_completed,
    COUNT(*) as workouts_total,
    ROUND(
        COUNT(CASE WHEN aw.status = 'completed' THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 
        0
    ) as completion_percentage
FROM ai_workout_plans awp
LEFT JOIN athlete_profiles ap ON ap.user_id = awp.user_id
JOIN auth.users au ON au.id = awp.user_id
LEFT JOIN ai_workouts aw ON aw.plan_id = awp.id
WHERE awp.status = 'active'
    AND awp.start_date <= CURRENT_DATE - INTERVAL '4 weeks'
GROUP BY awp.id, awp.user_id, ap.name, au.email, awp.training_phase, awp.start_date
HAVING CEIL((CURRENT_DATE - awp.start_date)::NUMERIC / 7.0) >= 4;

COMMENT ON VIEW athletes_needing_adaptation IS 'Athletes who have completed 4+ weeks and need new training plan';

-- Function to get athletes ready for adaptation
CREATE OR REPLACE FUNCTION get_athletes_ready_for_adaptation()
RETURNS TABLE (
    user_id UUID,
    athlete_name TEXT,
    plan_id UUID,
    current_phase TEXT,
    completion_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.user_id,
        a.athlete_name,
        a.plan_id,
        a.current_phase,
        a.completion_percentage
    FROM athletes_needing_adaptation a
    ORDER BY a.weeks_completed DESC;
END;
$$ LANGUAGE plpgsql;
