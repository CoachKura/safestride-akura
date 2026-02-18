-- AISRI Assessments helpers: scoring + upsert + batch processor
--
-- This script is designed to work with the schema in
-- database/schema-fixed.sql, where public.AISRI_assessments has:
--   profile_id   UUID REFERENCES auth.users(id)
--   intake_id    UUID REFERENCES aisri_intake_raw(id)
--   total_score  DECIMAL(5,2)
--   mobility_score, strength_score, endurance_score,
--   flexibility_score, balance_score (all 0–100 ints)
-- plus assessment_type, assessment_data, recommendations, risk_factors, etc.

-- Safety: drop old versions first so we can change OUT parameters
DROP FUNCTION IF EXISTS public.calculate_aisri_score_from_intake(UUID);
DROP FUNCTION IF EXISTS public.upsert_aisri_assessment_from_intake(UUID);
DROP FUNCTION IF EXISTS public.process_all_unprocessed_aisri_intakes();

---------------------------------------------------------------
-- 1) Score a single AISRI intake row
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.calculate_aisri_score_from_intake(
  p_intake_id UUID
)
RETURNS TABLE (
  total_score NUMERIC,
  mobility_score INTEGER,
  strength_score INTEGER,
  endurance_score INTEGER,
  flexibility_score INTEGER,
  balance_score INTEGER,
  assessment_type TEXT
) AS $$
DECLARE
  v_intake RECORD;
  v_raw_numeric INTEGER[];
  v_sum INTEGER := 0;
  v_count INTEGER := 0;
  v_mobility INTEGER := 0;
  v_strength INTEGER := 0;
  v_endurance INTEGER := 0;
  v_flexibility INTEGER := 0;
  v_balance INTEGER := 0;
  i INTEGER;
BEGIN
  SELECT * INTO v_intake
  FROM public.aisri_intake_raw
  WHERE id = p_intake_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'AISRI intake row % not found', p_intake_id;
  END IF;

  -- Treat q1..q50 as 1–5 Likert scores stored as TEXT.
  v_raw_numeric := ARRAY[
    NULLIF(v_intake.q1,  '')::INTEGER,
    NULLIF(v_intake.q2,  '')::INTEGER,
    NULLIF(v_intake.q3,  '')::INTEGER,
    NULLIF(v_intake.q4,  '')::INTEGER,
    NULLIF(v_intake.q5,  '')::INTEGER,
    NULLIF(v_intake.q6,  '')::INTEGER,
    NULLIF(v_intake.q7,  '')::INTEGER,
    NULLIF(v_intake.q8,  '')::INTEGER,
    NULLIF(v_intake.q9,  '')::INTEGER,
    NULLIF(v_intake.q10, '')::INTEGER,
    NULLIF(v_intake.q11, '')::INTEGER,
    NULLIF(v_intake.q12, '')::INTEGER,
    NULLIF(v_intake.q13, '')::INTEGER,
    NULLIF(v_intake.q14, '')::INTEGER,
    NULLIF(v_intake.q15, '')::INTEGER,
    NULLIF(v_intake.q16, '')::INTEGER,
    NULLIF(v_intake.q17, '')::INTEGER,
    NULLIF(v_intake.q18, '')::INTEGER,
    NULLIF(v_intake.q19, '')::INTEGER,
    NULLIF(v_intake.q20, '')::INTEGER,
    NULLIF(v_intake.q21, '')::INTEGER,
    NULLIF(v_intake.q22, '')::INTEGER,
    NULLIF(v_intake.q23, '')::INTEGER,
    NULLIF(v_intake.q24, '')::INTEGER,
    NULLIF(v_intake.q25, '')::INTEGER,
    NULLIF(v_intake.q26, '')::INTEGER,
    NULLIF(v_intake.q27, '')::INTEGER,
    NULLIF(v_intake.q28, '')::INTEGER,
    NULLIF(v_intake.q29, '')::INTEGER,
    NULLIF(v_intake.q30, '')::INTEGER,
    NULLIF(v_intake.q31, '')::INTEGER,
    NULLIF(v_intake.q32, '')::INTEGER,
    NULLIF(v_intake.q33, '')::INTEGER,
    NULLIF(v_intake.q34, '')::INTEGER,
    NULLIF(v_intake.q35, '')::INTEGER,
    NULLIF(v_intake.q36, '')::INTEGER,
    NULLIF(v_intake.q37, '')::INTEGER,
    NULLIF(v_intake.q38, '')::INTEGER,
    NULLIF(v_intake.q39, '')::INTEGER,
    NULLIF(v_intake.q40, '')::INTEGER,
    NULLIF(v_intake.q41, '')::INTEGER,
    NULLIF(v_intake.q42, '')::INTEGER,
    NULLIF(v_intake.q43, '')::INTEGER,
    NULLIF(v_intake.q44, '')::INTEGER,
    NULLIF(v_intake.q45, '')::INTEGER,
    NULLIF(v_intake.q46, '')::INTEGER,
    NULLIF(v_intake.q47, '')::INTEGER,
    NULLIF(v_intake.q48, '')::INTEGER,
    NULLIF(v_intake.q49, '')::INTEGER,
    NULLIF(v_intake.q50, '')::INTEGER
  ];

  FOR i IN array_lower(v_raw_numeric, 1)..array_upper(v_raw_numeric, 1) LOOP
    IF v_raw_numeric[i] IS NOT NULL THEN
      v_sum := v_sum + v_raw_numeric[i];
      v_count := v_count + 1;

      IF i BETWEEN 1 AND 10 THEN
        v_mobility := v_mobility + v_raw_numeric[i];
      ELSIF i BETWEEN 11 AND 20 THEN
        v_strength := v_strength + v_raw_numeric[i];
      ELSIF i BETWEEN 21 AND 30 THEN
        v_endurance := v_endurance + v_raw_numeric[i];
      ELSIF i BETWEEN 31 AND 40 THEN
        v_flexibility := v_flexibility + v_raw_numeric[i];
      ELSIF i BETWEEN 41 AND 50 THEN
        v_balance := v_balance + v_raw_numeric[i];
      END IF;
    END IF;
  END LOOP;

  IF v_count = 0 THEN
    RAISE EXCEPTION 'AISRI intake row % has no numeric responses', p_intake_id;
  END IF;

  -- Scale to 0–1000 (stored in DECIMAL(5,2)); simple linear scaling
  total_score := ROUND(
    LEAST(1000, GREATEST(0, (v_sum::NUMERIC / (v_count * 5)::NUMERIC) * 1000
  )), 2);

  mobility_score := v_mobility;
  strength_score := v_strength;
  endurance_score := v_endurance;
  flexibility_score := v_flexibility;
  balance_score := v_balance;
  assessment_type := 'full';

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;


---------------------------------------------------------------
-- 2) Upsert AISRI_assessments row from an intake
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.upsert_aisri_assessment_from_intake(
  p_intake_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_scores RECORD;
  v_intake public.aisri_intake_raw%ROWTYPE;
  v_profile_id UUID;
BEGIN
  SELECT * INTO v_intake
  FROM public.aisri_intake_raw
  WHERE id = p_intake_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'AISRI intake row % not found', p_intake_id;
  END IF;

  -- Prefer linked profile; fall back to current auth user if needed.
  v_profile_id := COALESCE(v_intake.profile_id, auth.uid());

  SELECT * INTO v_scores
  FROM public.calculate_aisri_score_from_intake(p_intake_id);

  -- Remove any previous assessment for this intake/profile to keep
  -- the table idempotent if we re-run processing.
  DELETE FROM public."AISRI_assessments"
  WHERE intake_id = p_intake_id
    AND profile_id = v_profile_id;

  INSERT INTO public."AISRI_assessments" (
    profile_id,
    intake_id,
    total_score,
    mobility_score,
    strength_score,
    endurance_score,
    flexibility_score,
    balance_score,
    assessment_type,
    assessment_data,
    recommendations,
    risk_factors,
    assessed_by,
    assessment_date,
    created_at,
    notes
  ) VALUES (
    v_profile_id,
    p_intake_id,
    v_scores.total_score,
    v_scores.mobility_score,
    v_scores.strength_score,
    v_scores.endurance_score,
    v_scores.flexibility_score,
    v_scores.balance_score,
    v_scores.assessment_type,
    to_jsonb(v_intake),
    NULL, -- recommendations (to be populated by later logic if desired)
    NULL, -- risk_factors
    auth.uid(),
    CURRENT_DATE,
    NOW(),
    'Generated from AISRI intake'
  );

  -- Mark intake as processed
  UPDATE public.aisri_intake_raw
  SET processed   = TRUE,
      processed_at = COALESCE(processed_at, NOW()),
      updated_at  = NOW()
  WHERE id = p_intake_id;

  RETURN p_intake_id;
END;
$$ LANGUAGE plpgsql VOLATILE;


---------------------------------------------------------------
-- 3) Batch process all unprocessed AISRI intakes
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.process_all_unprocessed_aisri_intakes()
RETURNS TABLE (
  processed_count INTEGER,
  skipped_count   INTEGER,
  total_count     INTEGER
) AS $$
DECLARE
  v_processed INTEGER := 0;
  v_skipped   INTEGER := 0;
  v_total     INTEGER := 0;
  r RECORD;
BEGIN
  FOR r IN
    SELECT id, profile_id
    FROM public.aisri_intake_raw
    WHERE processed = FALSE
  LOOP
    v_total := v_total + 1;

    -- Require a linked profile to create an assessment
    IF r.profile_id IS NULL THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    PERFORM public.upsert_aisri_assessment_from_intake(r.id);
    v_processed := v_processed + 1;
  END LOOP;

  processed_count := v_processed;
  skipped_count   := v_skipped;
  total_count     := v_total;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Usage examples (run manually in Supabase SQL editor):
--   SELECT * FROM public.calculate_aisri_score_from_intake('<intake_uuid>');
--   SELECT public.upsert_aisri_assessment_from_intake('<intake_uuid>');
--   SELECT * FROM public.process_all_unprocessed_aisri_intakes();

-- SELECT
--   profile_id,
--   intake_id,
--   total_score,
--   mobility_score,
--   strength_score,
--   endurance_score,
--   flexibility_score,
--   balance_score,
--   assessment_date
-- FROM public."AISRI_assessments"
-- ORDER BY assessment_date DESC
-- LIMIT 20;

-- SELECT
--   COUNT(*) FILTER (WHERE processed = TRUE)  AS processed,
--   COUNT(*) FILTER (WHERE processed = FALSE) AS unprocessed
-- FROM public.aisri_intake_raw;

SELECT 
  COUNT(*) FILTER (WHERE processed = TRUE)  AS processed,
  COUNT(*) FILTER (WHERE processed = FALSE) AS unprocessed
FROM public.aisri_intake_raw;

SELECT 
  profile_id,
  intake_id,
  total_score,
  mobility_score,
  strength_score,
  endurance_score,
  flexibility_score,
  balance_score,
  assessment_date
FROM public."AISRI_assessments"
ORDER BY assessment_date DESC
LIMIT 20;

SELECT * FROM public.process_all_unprocessed_aisri_intakes();
