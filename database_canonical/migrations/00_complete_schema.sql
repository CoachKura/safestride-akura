-- =====================================================
-- SAFESTRIDE - COMPLETE DATABASE SCHEMA
-- =====================================================
-- Version: 3.0 (Emergency Rebuild for 14 Athletes)
-- Date: 2026-02-16
-- Purpose: Single source of truth for database structure
-- =====================================================

-- Enable required extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- TABLE 1: PROFILES (User Accounts)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'athlete' CHECK (role IN ('athlete', 'coach', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

COMMENT ON TABLE public.profiles IS 'User profiles linked to Supabase Auth';

-- =====================================================
-- TABLE 2: ATHLETE-COACH RELATIONSHIPS
-- =====================================================
CREATE TABLE IF NOT EXISTS public.athlete_coach_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(athlete_id, coach_id)
);

ALTER TABLE public.athlete_coach_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Athletes view their coaches" ON public.athlete_coach_relationships
  FOR SELECT USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches view their athletes" ON public.athlete_coach_relationships
  FOR SELECT USING (auth.uid() = coach_id);

CREATE POLICY "Coaches manage relationships" ON public.athlete_coach_relationships
  FOR ALL USING (auth.uid() = coach_id);

CREATE INDEX IF NOT EXISTS idx_relationships_athlete ON public.athlete_coach_relationships(athlete_id);
CREATE INDEX IF NOT EXISTS idx_relationships_coach ON public.athlete_coach_relationships(coach_id);
CREATE INDEX IF NOT EXISTS idx_relationships_status ON public.athlete_coach_relationships(status);

COMMENT ON TABLE public.athlete_coach_relationships IS 'Links coaches to their athletes';

CREATE INDEX IF NOT EXISTS idx_relationships_athlete
  ON public.athlete_coach_relationships(athlete_id);

CREATE INDEX IF NOT EXISTS idx_relationships_coach
  ON public.athlete_coach_relationships(coach_id);

COMMENT ON TABLE public.athlete_coach_relationships IS 'Links coaches to athletes they manage';

-- =====================================================
-- 3. DEVICE CONNECTIONS (Strava, Garmin, etc.)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.device_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('strava', 'garmin', 'polar', 'coros', 'suunto')),
  athlete_id TEXT,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  last_sync_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, platform)
);

ALTER TABLE public.device_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own connections" ON public.device_connections
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users manage own connections" ON public.device_connections
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_device_connections_user ON public.device_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_device_connections_platform ON public.device_connections(platform);
CREATE INDEX IF NOT EXISTS idx_device_connections_active ON public.device_connections(is_active) WHERE is_active = TRUE;

CREATE OR REPLACE FUNCTION update_device_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER device_connections_updated_at_trigger
  BEFORE UPDATE ON public.device_connections
  FOR EACH ROW EXECUTE FUNCTION update_device_connections_updated_at();

COMMENT ON TABLE public.device_connections IS 'OAuth connections to fitness platforms';

-- =====================================================
-- =====================================================
-- TABLE 4: AISRI INTAKE RAW (Assessment Forms)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.aisri_intake_raw (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  submitted_at TIMESTAMPTZ NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  
  -- Demographics
  age INTEGER CHECK (age >= 18 AND age <= 100),
  gender TEXT,
  running_experience_years INTEGER,
  weekly_mileage_km NUMERIC(10,2),
  
  -- Quick Assessment (3 key questions for fast entry)
  q1 TEXT, -- Current injuries
  q2 TEXT, -- Pain level (0-10)
  q3 TEXT, -- Medical conditions
  
  -- Full 50-question assessment (optional, for detailed analysis)
  q4 TEXT, q5 TEXT, q6 TEXT, q7 TEXT, q8 TEXT, q9 TEXT, q10 TEXT,
  q11 TEXT, q12 TEXT, q13 TEXT, q14 TEXT, q15 TEXT, q16 TEXT, q17 TEXT, q18 TEXT, q19 TEXT, q20 TEXT,
  q21 TEXT, q22 TEXT, q23 TEXT, q24 TEXT, q25 TEXT, q26 TEXT, q27 TEXT, q28 TEXT, q29 TEXT, q30 TEXT,
  q31 TEXT, q32 TEXT, q33 TEXT, q34 TEXT, q35 TEXT, q36 TEXT, q37 TEXT, q38 TEXT, q39 TEXT, q40 TEXT,
  q41 TEXT, q42 TEXT, q43 TEXT, q44 TEXT, q45 TEXT, q46 TEXT, q47 TEXT, q48 TEXT, q49 TEXT, q50 TEXT,
  
  -- Additional Info
  training_goals TEXT,
  previous_injuries TEXT,
  medical_history TEXT,
  
  -- Processing Status
  processed BOOLEAN DEFAULT FALSE,
  assessment_type TEXT DEFAULT 'quick' CHECK (assessment_type IN ('quick', 'full')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.aisri_intake_raw ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Athletes view own intake" ON public.aisri_intake_raw
  FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Coaches view athlete intake" ON public.aisri_intake_raw
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships acr
      WHERE acr.coach_id = auth.uid()
        AND acr.athlete_id = aisri_intake_raw.profile_id
        AND acr.status = 'active'
    )
  );

CREATE POLICY "Coaches insert athlete intake" ON public.aisri_intake_raw
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships acr
      WHERE acr.coach_id = auth.uid()
        AND acr.athlete_id = aisri_intake_raw.profile_id
        AND acr.status = 'active'
    )
  );

CREATE INDEX IF NOT EXISTS idx_aisri_intake_profile ON public.aisri_intake_raw(profile_id);
CREATE INDEX IF NOT EXISTS idx_aisri_intake_email ON public.aisri_intake_raw(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_aisri_intake_processed ON public.aisri_intake_raw(processed) WHERE processed = FALSE;

COMMENT ON TABLE public.aisri_intake_raw IS 'Raw AISRI assessment data from forms';

-- =====================================================
-- TABLE 5: AISRI ASSESSMENTS (Calculated Scores)
-- =====================================================
CREATE TABLE IF NOT EXISTS public."AISRI_assessments" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  intake_id UUID REFERENCES public.aisri_intake_raw(id) ON DELETE SET NULL,
  
  -- Overall Score (0-1000 scale)
  total_score INTEGER NOT NULL CHECK (total_score BETWEEN 0 AND 1000),
  risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'moderate', 'high', 'critical')),
  
  -- Sub-domain Scores (0-200 each)
  mobility_score INTEGER CHECK (mobility_score BETWEEN 0 AND 200),
  strength_score INTEGER CHECK (strength_score BETWEEN 0 AND 200),
  endurance_score INTEGER CHECK (endurance_score BETWEEN 0 AND 200),
  flexibility_score INTEGER CHECK (flexibility_score BETWEEN 0 AND 200),
  balance_score INTEGER CHECK (balance_score BETWEEN 0 AND 200),
  
  -- Risk Factors
  key_risk_factors JSONB DEFAULT '[]'::JSONB,
  recommendations JSONB DEFAULT '[]'::JSONB,
  
  -- Metadata
  age INTEGER,
  gender TEXT,
  running_experience INTEGER,
  weekly_mileage NUMERIC(10,2),
  assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  assessment_type TEXT DEFAULT 'quick' CHECK (assessment_type IN ('quick', 'full')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(profile_id, assessment_date)
);

ALTER TABLE public."AISRI_assessments" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Athletes view own assessments" ON public."AISRI_assessments"
  FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY IF NOT EXISTS "Coaches can view athlete assessments"
  ON public."AISRI_assessments" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships acr
      WHERE acr.coach_id = auth.uid()
        AND acr.athlete_id = "AISRI_assessments".profile_id
        AND acr.status = 'active'
    )
  );

CREATE INDEX IF NOT EXISTS idx_assessments_profile
  ON public."AISRI_assessments"(profile_id);

CREATE INDEX IF NOT EXISTS idx_assessments_date
  ON public."AISRI_assessments"(assessment_date DESC);

CREATE INDEX IF NOT EXISTS idx_assessments_risk
  ON public."AISRI_assessments"(risk_level);

COMMENT ON TABLE public."AISRI_assessments" IS 'Processed AISRI assessment scores and risk levels';

-- =====================================================
-- 6. HELPER FUNCTIONS
-- =====================================================

-- Link intake data to profiles by email
CREATE OR REPLACE FUNCTION public.link_all_intake_to_profiles()
RETURNS TABLE(total_linked BIGINT, total_unmatched BIGINT) AS $$
DECLARE
  v_linked BIGINT;
  v_unmatched BIGINT;
BEGIN
  UPDATE public.aisri_intake_raw air
  SET profile_id = p.id,
      updated_at = NOW()
  FROM public.profiles p
  WHERE LOWER(TRIM(air.email)) = LOWER(TRIM(p.email))
    AND air.profile_id IS NULL;

  SELECT COUNT(*) INTO v_linked
  FROM public.aisri_intake_raw
  WHERE profile_id IS NOT NULL;

  SELECT COUNT(*) INTO v_unmatched
  FROM public.aisri_intake_raw
  WHERE profile_id IS NULL;

  RETURN QUERY SELECT v_linked, v_unmatched;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.link_all_intake_to_profiles() IS 'Links intake records to profiles by matching email addresses';

-- Function: Quick scoring algorithm for fast processing
CREATE OR REPLACE FUNCTION public.calculate_quick_aisri_score(
  p_injuries TEXT,
  p_pain_level TEXT,
  p_medical_conditions TEXT,
  p_age INTEGER,
  p_weekly_mileage NUMERIC
)
RETURNS INTEGER AS $$
DECLARE
  v_score INTEGER := 500; -- Start at medium risk
  v_pain INTEGER;
BEGIN
  -- Parse pain level
  v_pain := COALESCE(p_pain_level::INTEGER, 0);
  
  -- Adjust for pain (high pain = lower score = higher risk)
  v_score := v_score - (v_pain * 50);
  
  -- Adjust for injuries
  IF p_injuries IS NOT NULL AND LOWER(p_injuries) NOT IN ('no', 'none', 'nil') THEN
    v_score := v_score - 100;
  END IF;
  
  -- Adjust for medical conditions
  IF p_medical_conditions IS NOT NULL AND LOWER(p_medical_conditions) NOT IN ('no', 'none', 'nil') THEN
    v_score := v_score - 75;
  END IF;
  
  -- Adjust for age (older = slightly higher risk)
  IF p_age > 50 THEN
    v_score := v_score - 25;
  END IF;
  
  -- Adjust for training load
  IF p_weekly_mileage > 60 THEN
    v_score := v_score - 50; -- High mileage = higher risk
  ELSIF p_weekly_mileage < 20 THEN
    v_score := v_score + 25; -- Low mileage = lower risk
  END IF;
  
  -- Clamp to 0-1000 range
  v_score := GREATEST(0, LEAST(1000, v_score));
  
  RETURN v_score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Process unprocessed intakes
CREATE OR REPLACE FUNCTION public.process_all_unprocessed_aisri_intakes()
RETURNS TABLE(processed_count INT, skipped_count INT, total_count INT) AS $$
DECLARE
  v_processed INT := 0;
  v_skipped INT := 0;
  v_total INT;
  v_record RECORD;
  v_total_score INT;
  v_risk_level TEXT;
BEGIN
  SELECT COUNT(*) INTO v_total FROM public.aisri_intake_raw WHERE processed = FALSE;
  
  FOR v_record IN 
    SELECT * FROM public.aisri_intake_raw WHERE processed = FALSE
  LOOP
    IF v_record.profile_id IS NULL THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;
    
    -- Calculate quick score
    v_total_score := public.calculate_quick_aisri_score(
      v_record.q1,
      v_record.q2,
      v_record.q3,
      v_record.age,
      v_record.weekly_mileage_km
    );
    
    -- Determine risk level
    IF v_total_score >= 750 THEN v_risk_level := 'low';
    ELSIF v_total_score >= 500 THEN v_risk_level := 'moderate';
    ELSIF v_total_score >= 250 THEN v_risk_level := 'high';
    ELSE v_risk_level := 'critical';
    END IF;
    
    -- Insert assessment
    INSERT INTO public."AISRI_assessments" (
      profile_id, intake_id, total_score, risk_level,
      mobility_score, strength_score, endurance_score,
      age, gender, running_experience, weekly_mileage,
      assessment_date, assessment_type
    ) VALUES (
      v_record.profile_id, v_record.id, v_total_score, v_risk_level,
      FLOOR(v_total_score * 0.2)::INTEGER,
      FLOOR(v_total_score * 0.2)::INTEGER,
      FLOOR(v_total_score * 0.2)::INTEGER,
      v_record.age, v_record.gender,
      v_record.running_experience_years, v_record.weekly_mileage_km,
      v_record.submitted_at::DATE, v_record.assessment_type
    )
    ON CONFLICT (profile_id, assessment_date) DO UPDATE SET
      total_score = EXCLUDED.total_score,
      risk_level = EXCLUDED.risk_level,
      mobility_score = EXCLUDED.mobility_score,
      strength_score = EXCLUDED.strength_score,
      endurance_score = EXCLUDED.endurance_score,
      updated_at = NOW();
    
    UPDATE public.aisri_intake_raw SET processed = TRUE WHERE id = v_record.id;
    v_processed := v_processed + 1;
  END LOOP;
  
  RETURN QUERY SELECT v_processed, v_skipped, v_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DASHBOARD VIEW
-- =====================================================
CREATE OR REPLACE VIEW public.athlete_intake_dashboard AS
SELECT 
  p.id AS athlete_id,
  p.email AS athlete_email,
  p.full_name AS athlete_name,
  p.role,
  a.id AS assessment_id,
  a.assessment_date,
  a.total_score,
  a.risk_level,
  CASE 
    WHEN a.risk_level = 'critical' THEN '🚨 Critical'
    WHEN a.risk_level = 'high' THEN '🔶 High'
    WHEN a.risk_level = 'moderate' THEN '⚠️ Moderate'
    ELSE '✅ Low'
  END AS risk_status,
  a.mobility_score,
  a.strength_score,
  a.endurance_score,
  a.flexibility_score,
  a.balance_score,
  a.age,
  a.gender,
  a.running_experience,
  a.weekly_mileage,
  i.training_goals,
  i.previous_injuries,
  i.q1 AS current_injuries,
  i.q2 AS pain_level,
  i.q3 AS medical_conditions,
  EXTRACT(DAY FROM NOW() - a.assessment_date) AS days_since_assessment
FROM public."AISRI_assessments" a
JOIN public.profiles p ON a.profile_id = p.id
LEFT JOIN public.aisri_intake_raw i ON a.intake_id = i.id
ORDER BY a.total_score ASC, a.assessment_date DESC;

GRANT SELECT ON public.athlete_intake_dashboard TO authenticated;

COMMENT ON VIEW public.athlete_intake_dashboard IS 'Complete athlete dashboard for coaches';

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ SafeStride database schema created successfully!';
  RAISE NOTICE '✅ Tables: 5 (profiles, relationships, connections, intakes, assessments)';
  RAISE NOTICE '✅ Functions: 3 (link, quick_score, process)';
  RAISE NOTICE '✅ Views: 1 (dashboard)';
  RAISE NOTICE '✅ RLS: Enabled on all tables';
END $$;

SELECT '✅ Database ready for 14 athletes!' AS status;
