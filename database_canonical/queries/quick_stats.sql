-- =====================================================
-- SAFESTRIDE - QUICK STATS
-- =====================================================
-- Run anytime to get instant overview
-- =====================================================

-- Overall counts
SELECT 
  (SELECT COUNT(*) FROM public.aisri_intake_raw) as total_intake_forms,
  (SELECT COUNT(*) FROM public."AISRI_assessments") as total_assessments,
  (SELECT COUNT(*) FROM public.aisri_intake_raw WHERE processed = false) as unprocessed_forms;

-- Risk distribution
SELECT 
  risk_level,
  COUNT(*) as count,
  ROUND(AVG(total_score), 0) as avg_score,
  MIN(total_score) as min_score,
  MAX(total_score) as max_score
FROM public."AISRI_assessments"
GROUP BY risk_level
ORDER BY 
  CASE risk_level 
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'moderate' THEN 3
    WHEN 'low' THEN 4
  END;

-- Athletes needing immediate attention
SELECT 
  athlete_name,
  athlete_email,
  risk_status,
  current_injuries,
  pain_level,
  medical_conditions
FROM public.athlete_intake_dashboard
WHERE risk_level IN ('critical', 'high')
ORDER BY total_score ASC;

-- Recent assessments (last 7 days)
SELECT 
  athlete_name,
  assessment_date,
  risk_status,
  total_score,
  days_since_assessment
FROM public.athlete_intake_dashboard
WHERE days_since_assessment <= 7
ORDER BY assessment_date DESC;
