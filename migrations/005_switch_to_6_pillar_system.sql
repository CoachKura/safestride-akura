-- =====================================================
-- MIGRATION: Switch to NEW 6-Pillar AISRI System
-- Version: 3.0
-- Created: 2026-03-04
-- Purpose: Replace old 5-pillar with comprehensive 6-pillar system
-- =====================================================

-- =====================================================
-- ADD NEW 6-PILLAR COLUMNS TO physical_assessments
-- =====================================================

ALTER TABLE public.physical_assessments
  ADD COLUMN IF NOT EXISTS pillar_mobility_flexibility INTEGER CHECK (pillar_mobility_flexibility BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS pillar_core_strength INTEGER CHECK (pillar_core_strength BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS pillar_mental_resilience INTEGER CHECK (pillar_mental_resilience BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS pillar_recovery INTEGER CHECK (pillar_recovery BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS pillar_injury_prevention INTEGER CHECK (pillar_injury_prevention BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS pillar_performance INTEGER CHECK (pillar_performance BETWEEN 0 AND 100);

-- =====================================================
-- UPDATE AISRI CALCULATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION public.calculate_aisri_v2(
  p_mobility_flexibility INTEGER,
  p_core_strength INTEGER,
  p_mental_resilience INTEGER,
  p_recovery INTEGER,
  p_injury_prevention INTEGER,
  p_performance INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_aisri INTEGER;
BEGIN
  -- NEW 6-Pillar Formula: Equal weight (16.67% each)
  v_aisri := ROUND((
    COALESCE(p_mobility_flexibility, 0) +
    COALESCE(p_core_strength, 0) +
    COALESCE(p_mental_resilience, 0) +
    COALESCE(p_recovery, 0) +
    COALESCE(p_injury_prevention, 0) +
    COALESCE(p_performance, 0)
  ) / 6.0);
  
  RETURN GREATEST(0, LEAST(100, v_aisri));
END;
$$;

-- =====================================================
-- CREATE VIEW: Latest AISRI Scores with 6 Pillars
-- =====================================================

CREATE OR REPLACE VIEW public.athlete_aisri_current_v2 AS
SELECT 
  p.id AS athlete_id,
  p.full_name,
  p.email,
  pa.assessment_date,
  pa.pillar_mobility_flexibility,
  pa.pillar_core_strength,
  pa.pillar_mental_resilience,
  pa.pillar_recovery,
  pa.pillar_injury_prevention,
  pa.pillar_performance,
  calculate_aisri_v2(
    pa.pillar_mobility_flexibility,
    pa.pillar_core_strength,
    pa.pillar_mental_resilience,
    pa.pillar_recovery,
    pa.pillar_injury_prevention,
    pa.pillar_performance
  ) AS aisri_score,
  CASE
    WHEN calculate_aisri_v2(
      pa.pillar_mobility_flexibility,
      pa.pillar_core_strength,
      pa.pillar_mental_resilience,
      pa.pillar_recovery,
      pa.pillar_injury_prevention,
      pa.pillar_performance
    ) >= 75 THEN 'Low Risk'
    WHEN calculate_aisri_v2(
      pa.pillar_mobility_flexibility,
      pa.pillar_core_strength,
      pa.pillar_mental_resilience,
      pa.pillar_recovery,
      pa.pillar_injury_prevention,
      pa.pillar_performance
    ) >= 60 THEN 'Medium Risk'
    WHEN calculate_aisri_v2(
      pa.pillar_mobility_flexibility,
      pa.pillar_core_strength,
      pa.pillar_mental_resilience,
      pa.pillar_recovery,
      pa.pillar_injury_prevention,
      pa.pillar_performance
    ) >= 40 THEN 'High Risk'
    ELSE 'Critical Risk'
  END AS risk_category,
  CASE
    WHEN calculate_aisri_v2(
      pa.pillar_mobility_flexibility,
      pa.pillar_core_strength,
      pa.pillar_mental_resilience,
      pa.pillar_recovery,
      pa.pillar_injury_prevention,
      pa.pillar_performance
    ) >= 75 THEN 'Zones 1-5 (All)'
    WHEN calculate_aisri_v2(
      pa.pillar_mobility_flexibility,
      pa.pillar_core_strength,
      pa.pillar_mental_resilience,
      pa.pillar_recovery,
      pa.pillar_injury_prevention,
      pa.pillar_performance
    ) >= 60 THEN 'Zones 1-3'
    WHEN calculate_aisri_v2(
      pa.pillar_mobility_flexibility,
      pa.pillar_core_strength,
      pa.pillar_mental_resilience,
      pa.pillar_recovery,
      pa.pillar_injury_prevention,
      pa.pillar_performance
    ) >= 40 THEN 'Zones 1-2'
    ELSE 'Zone 1 Only'
  END AS allowed_zones
FROM public.profiles p
LEFT JOIN LATERAL (
  SELECT *
  FROM public.physical_assessments
  WHERE athlete_id = p.id
  ORDER BY assessment_date DESC
  LIMIT 1
) pa ON true
WHERE p.role = 'athlete';

-- =====================================================
-- COMMENT: The 6 Pillars
-- =====================================================

COMMENT ON COLUMN public.physical_assessments.pillar_mobility_flexibility IS 'Pillar 1: Joint range of motion, muscle flexibility (~17%)';
COMMENT ON COLUMN public.physical_assessments.pillar_core_strength IS 'Pillar 2: Core stability, leg strength, balance (~17%)';
COMMENT ON COLUMN public.physical_assessments.pillar_mental_resilience IS 'Pillar 3: Focus, stress management, recovery mindset (~17%)';
COMMENT ON COLUMN public.physical_assessments.pillar_recovery IS 'Pillar 4: Sleep quality, nutrition, rest protocols (~17%)';
COMMENT ON COLUMN public.physical_assessments.pillar_injury_prevention IS 'Pillar 5: Biomechanics, form, injury history (~17%)';
COMMENT ON COLUMN public.physical_assessments.pillar_performance IS 'Pillar 6: VO2 max, lactate threshold, zone training (~17%)';

-- =====================================================
-- SAMPLE DATA: Rajesh's NEW 6-Pillar Scores
-- =====================================================

-- Insert Rajesh's AFTER scores (18 months progress)
INSERT INTO public.physical_assessments (
  athlete_id,
  assessment_date,
  assessment_type,
  pillar_mobility_flexibility,
  pillar_core_strength,
  pillar_mental_resilience,
  pillar_recovery,
  pillar_injury_prevention,
  pillar_performance,
  assessor_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'rajesh@example.com' LIMIT 1),
  NOW(),
  'monthly',
  85,  -- Mobility & Flexibility (improved from 40)
  88,  -- Core Strength & Stability (improved from 35)
  80,  -- Mental Resilience (improved from 50)
  82,  -- Recovery & Regeneration (improved from 38)
  90,  -- Injury Prevention (improved from 42)
  85,  -- Performance Optimization (improved from 45)
  'Rajesh after 18 months: AISRI 82, 5K time 19:45, weight 68kg, diabetes reversed'
) ON CONFLICT DO NOTHING;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT SELECT ON public.athlete_aisri_current_v2 TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_aisri_v2 TO authenticated;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- The 6-pillar AISRI system is now active!
-- Old 5-pillar columns remain for backward compatibility
-- New assessments should use the 6-pillar columns
-- =====================================================
