-- =====================================================
-- SAFESTRIDE - AISRI INTAKE RAW TABLE (FIXED)
-- Schema-Compatible Version - No role column dependency
-- =====================================================
-- Project: xzxnnswggwqtctcgpocr (PRODUCTION)
-- Date: February 16, 2026
-- Purpose: Store raw AISRI intake assessment responses from Google Forms
-- FIXED: Uses athlete_coach_relationships instead of profiles.role
-- FIXED: References public.profiles(id) not auth.users(id)
-- =====================================================

-- Drop existing table if needed (CAUTION: removes all data)
-- DROP TABLE IF EXISTS public.aisri_intake_raw CASCADE;

-- Create AISRI Intake Raw Table
CREATE TABLE IF NOT EXISTS public.aisri_intake_raw (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Link to user profile (nullable until linked)
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- Google Forms metadata
  submitted_at TIMESTAMPTZ NOT NULL,
  
  -- Athlete information
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  age INTEGER CHECK (age >= 18 AND age <= 100),
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Non-binary', 'Prefer not to say', 'Other')),
  
  -- Running background
  running_experience_years INTEGER CHECK (running_experience_years >= 0 AND running_experience_years <= 50),
  weekly_mileage_km DECIMAL(10,2) CHECK (weekly_mileage_km >= 0 AND weekly_mileage_km <= 500),
  
  -- AISRI Questions (50 questions, stored as TEXT for flexibility)
  q1 TEXT,   q2 TEXT,   q3 TEXT,   q4 TEXT,   q5 TEXT,
  q6 TEXT,   q7 TEXT,   q8 TEXT,   q9 TEXT,   q10 TEXT,
  q11 TEXT,  q12 TEXT,  q13 TEXT,  q14 TEXT,  q15 TEXT,
  q16 TEXT,  q17 TEXT,  q18 TEXT,  q19 TEXT,  q20 TEXT,
  q21 TEXT,  q22 TEXT,  q23 TEXT,  q24 TEXT,  q25 TEXT,
  q26 TEXT,  q27 TEXT,  q28 TEXT,  q29 TEXT,  q30 TEXT,
  q31 TEXT,  q32 TEXT,  q33 TEXT,  q34 TEXT,  q35 TEXT,
  q36 TEXT,  q37 TEXT,  q38 TEXT,  q39 TEXT,  q40 TEXT,
  q41 TEXT,  q42 TEXT,  q43 TEXT,  q44 TEXT,  q45 TEXT,
  q46 TEXT,  q47 TEXT,  q48 TEXT,  q49 TEXT,  q50 TEXT,
  
  -- Additional athlete input
  training_goals TEXT,
  previous_injuries TEXT,
  medical_history TEXT,
  
  -- Processing status
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMPTZ,
  
  -- Audit fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE public.aisri_intake_raw IS 'Raw AISRI intake assessment responses from Google Forms';

-- =====================================================
-- ROW LEVEL SECURITY (FIXED - No role column)
-- =====================================================

ALTER TABLE public.aisri_intake_raw ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Coaches can view all intake responses" ON public.aisri_intake_raw;
DROP POLICY IF EXISTS "Athletes can view own intake responses" ON public.aisri_intake_raw;
DROP POLICY IF EXISTS "Coaches can insert intake responses" ON public.aisri_intake_raw;
DROP POLICY IF EXISTS "Athletes can insert own intake responses" ON public.aisri_intake_raw;
DROP POLICY IF EXISTS "System can update for processing" ON public.aisri_intake_raw;

-- Coaches can view intakes of their athletes (via athlete_coach_relationships)
CREATE POLICY "Coaches can view intake responses"
  ON public.aisri_intake_raw FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.athlete_coach_relationships r
      WHERE r.coach_id = auth.uid()
        AND r.athlete_id = aisri_intake_raw.profile_id
        AND r.status = 'active'
    )
  );

-- Athletes can view only their own
CREATE POLICY "Athletes can view own intake responses"
  ON public.aisri_intake_raw FOR SELECT
  USING (auth.uid() = profile_id);

-- Coaches can insert for their athletes
CREATE POLICY "Coaches can insert intake responses"
  ON public.aisri_intake_raw FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.athlete_coach_relationships r
      WHERE r.coach_id = auth.uid()
        AND r.status = 'active'
    )
  );

-- Athletes can insert their own
CREATE POLICY "Athletes can insert own intake responses"
  ON public.aisri_intake_raw FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Allow updates for processing (coaches and athletes)
CREATE POLICY "System can update for processing"
  ON public.aisri_intake_raw FOR UPDATE
  USING (
    auth.uid() = profile_id OR
    EXISTS (
      SELECT 1
      FROM public.athlete_coach_relationships r
      WHERE r.coach_id = auth.uid()
        AND r.athlete_id = aisri_intake_raw.profile_id
        AND r.status = 'active'
    )
  );

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_aisri_intake_email 
  ON public.aisri_intake_raw(LOWER(email));

CREATE INDEX IF NOT EXISTS idx_aisri_intake_profile 
  ON public.aisri_intake_raw(profile_id);

CREATE INDEX IF NOT EXISTS idx_aisri_intake_submitted 
  ON public.aisri_intake_raw(submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_aisri_intake_processed 
  ON public.aisri_intake_raw(processed) 
  WHERE processed = false;

-- =====================================================
-- TRIGGER FOR updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_aisri_intake_raw_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_aisri_intake_raw_updated_at ON public.aisri_intake_raw;
CREATE TRIGGER trigger_aisri_intake_raw_updated_at
  BEFORE UPDATE ON public.aisri_intake_raw
  FOR EACH ROW
  EXECUTE FUNCTION public.update_aisri_intake_raw_updated_at();

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT '✅ aisri_intake_raw table created (schema-compatible version)' AS status;

SELECT 
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'aisri_intake_raw'
ORDER BY ordinal_position;

-- =====================================================
-- CSV IMPORT INSTRUCTIONS
-- =====================================================

/*
CSV HEADER MAPPING:

Timestamp → submitted_at
Email Address → email
Full Name → full_name
Age → age
Gender → gender
Running Experience (years) → running_experience_years
Weekly Mileage (km) → weekly_mileage_km
Question 1 → q1
Question 2 → q2
... (q3-q50) ...
Training Goals → training_goals
Previous Injuries → previous_injuries
Medical History → medical_history

IMPORT STEPS:
1. Export Google Forms to CSV
2. Supabase → Database → aisri_intake_raw → Insert → Import CSV
3. Map columns → Import
4. Run: SELECT * FROM link_all_intake_to_profiles();
5. Run: SELECT upsert_aisri_assessment_from_intake(id) FROM aisri_intake_raw WHERE processed = false;
*/

-- =====================================================
-- END OF SCRIPT
-- =====================================================
