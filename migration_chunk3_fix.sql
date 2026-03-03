-- =====================================================
-- CHUNK 3 FIX: Corrected View with Proper INTERVAL Syntax
-- =====================================================

-- Drop and recreate the view with fixed syntax
DROP VIEW IF EXISTS public.v_upcoming_evaluations;

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
