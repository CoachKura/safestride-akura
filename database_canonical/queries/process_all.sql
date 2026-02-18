-- =====================================================
-- SAFESTRIDE - PROCESS ALL AISRI ASSESSMENTS
-- =====================================================
-- Run this after adding new athletes
-- This will:
-- 1. Link intake forms to user profiles (if they exist)
-- 2. Calculate AISRI risk scores
-- 3. Create assessment records
-- =====================================================

BEGIN;

-- Step 1: Link new intake forms to existing profiles
SELECT 
  total_linked,
  total_unmatched,
  'Profiles linked' as status
FROM public.link_all_intake_to_profiles();

-- Step 2: Process all unprocessed assessments
SELECT 
  processed_count,
  skipped_count,
  total_count,
  'Assessments processed' as status
FROM public.process_all_unprocessed_aisri_intakes();

-- Step 3: View the results
SELECT 
  athlete_name,
  athlete_email,
  risk_status,
  total_score,
  current_injuries,
  pain_level,
  days_since_assessment
FROM public.athlete_intake_dashboard
ORDER BY total_score ASC;

-- Step 4: Summary statistics
SELECT 
  COUNT(*) as total_athletes,
  COUNT(*) FILTER (WHERE risk_level = 'critical') as critical_risk,
  COUNT(*) FILTER (WHERE risk_level = 'high') as high_risk,
  COUNT(*) FILTER (WHERE risk_level = 'moderate') as moderate_risk,
  COUNT(*) FILTER (WHERE risk_level = 'low') as low_risk,
  ROUND(AVG(total_score), 0) as avg_score
FROM public."AISRI_assessments";

COMMIT;

SELECT '✅ All assessments processed successfully!' as status;
