-- AISRI end-to-end pipeline runner
--
-- How to use this script:
-- 1) Open Supabase SQL Editor for your production project.
-- 2) Paste your INSERT statements (from import_aisri_data.sql) where indicated
--    below, replacing the placeholder section.
-- 3) Run the whole script once. It will:
--      - Insert AISRI intake rows
--      - Link them to profiles
--      - Generate AISRI_assessments
--      - Show basic verification stats and a few sample rows.

BEGIN;

-- ==========================================================
-- STEP 1: IMPORT AISRI INTAKE DATA
-- ==========================================================

-- Paste the contents of /home/user/import_aisri_data.sql here,
-- i.e., the series of:
--   INSERT INTO public.aisri_intake_raw (...)
--   VALUES (...);
--
-- Example placeholder:
-- INSERT INTO public.aisri_intake_raw (...columns...)
-- VALUES (...values...);

-- >>>>> PASTE IMPORT STATEMENTS BELOW THIS LINE <<<<<

-- <<<<< END OF IMPORT STATEMENTS >>>>>

-- ==========================================================
-- STEP 2: LINK INTAKES TO PROFILES
-- ==========================================================

-- Ensure linking function exists (defined in sql/aisri/link_aisri_profiles.sql)
-- Then link all intakes by email → profiles.email
SELECT * FROM public.link_all_intake_to_profiles();

-- ==========================================================
-- STEP 3: GENERATE AISRI ASSESSMENTS
-- ==========================================================

-- Process all unprocessed intakes that have a profile_id
SELECT * FROM public.process_all_unprocessed_aisri_intakes();

-- ==========================================================
-- STEP 4: VERIFICATION QUERIES
-- ==========================================================

-- 4A: total intakes
SELECT COUNT(*) AS total_intakes
FROM public.aisri_intake_raw;

-- 4B: total assessments
SELECT COUNT(*) AS total_assessments
FROM public."AISRI_assessments";

-- 4C: processed / unprocessed / linked / unlinked
SELECT 
  COUNT(*) FILTER (WHERE processed = TRUE)  AS processed,
  COUNT(*) FILTER (WHERE processed = FALSE) AS unprocessed,
  COUNT(*) FILTER (WHERE profile_id IS NOT NULL) AS linked,
  COUNT(*) FILTER (WHERE profile_id IS NULL)     AS unlinked
FROM public.aisri_intake_raw;

-- 4D: sample assessments
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
LIMIT 10;

COMMIT;
