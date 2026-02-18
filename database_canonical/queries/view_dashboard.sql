-- =====================================================
-- SAFESTRIDE - COACH DASHBOARD VIEW
-- =====================================================
-- Quick dashboard view for coaches
-- Run this anytime to see athlete status
-- =====================================================

SELECT 
  athlete_name,
  athlete_email,
  risk_status,
  total_score,
  current_injuries,
  pain_level,
  medical_conditions,
  days_since_assessment,
  training_goals
FROM public.athlete_intake_dashboard
ORDER BY 
  CASE risk_level 
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'moderate' THEN 3
    WHEN 'low' THEN 4
  END,
  total_score ASC
LIMIT 25;

-- Quick stats summary
SELECT 
  COUNT(*) as total_athletes,
  COUNT(*) FILTER (WHERE risk_level = 'critical') as critical,
  COUNT(*) FILTER (WHERE risk_level = 'high') as high,
  COUNT(*) FILTER (WHERE risk_level = 'moderate') as moderate,
  COUNT(*) FILTER (WHERE risk_level = 'low') as low,
  ROUND(AVG(total_score), 0) as avg_score
FROM public."AISRI_assessments";
