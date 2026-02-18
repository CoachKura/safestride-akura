-- SafeStride base schema
-- Clean, self-contained schema for new Supabase project

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

------------------------------------------------------------
-- Utility: generic updated_at trigger
------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------
-- 1) PROFILES
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email      TEXT UNIQUE NOT NULL,
  full_name  TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can view and update only their own profile
CREATE POLICY IF NOT EXISTS "Profiles: select own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Profiles: update own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

------------------------------------------------------------
-- 2) ATHLETE_COACH_RELATIONSHIPS
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.athlete_coach_relationships (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT different_users CHECK (coach_id <> athlete_id),
  CONSTRAINT unique_coach_athlete UNIQUE (coach_id, athlete_id)
);

CREATE INDEX IF NOT EXISTS idx_relationships_coach
  ON public.athlete_coach_relationships(coach_id);
CREATE INDEX IF NOT EXISTS idx_relationships_athlete
  ON public.athlete_coach_relationships(athlete_id);

CREATE TRIGGER set_relationships_updated_at
BEFORE UPDATE ON public.athlete_coach_relationships
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.athlete_coach_relationships ENABLE ROW LEVEL SECURITY;

-- Coaches and athletes can see their own relationships
CREATE POLICY IF NOT EXISTS "Relationships: select own" ON public.athlete_coach_relationships
  FOR SELECT USING (auth.uid() IN (coach_id, athlete_id));

-- Coaches can create relationships
CREATE POLICY IF NOT EXISTS "Relationships: coach insert" ON public.athlete_coach_relationships
  FOR INSERT WITH CHECK (auth.uid() = coach_id);

-- Either side can update status
CREATE POLICY IF NOT EXISTS "Relationships: update own" ON public.athlete_coach_relationships
  FOR UPDATE USING (auth.uid() IN (coach_id, athlete_id));

------------------------------------------------------------
-- 3) DEVICE_CONNECTIONS
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.device_connections (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  platform         TEXT NOT NULL CHECK (platform IN ('strava','garmin','coros','polar','suunto')),
  access_token     TEXT,
  refresh_token    TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active        BOOLEAN DEFAULT TRUE,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_platform UNIQUE (user_id, platform)
);

CREATE INDEX IF NOT EXISTS idx_device_connections_user
  ON public.device_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_device_connections_platform
  ON public.device_connections(platform);

CREATE TRIGGER set_device_connections_updated_at
BEFORE UPDATE ON public.device_connections
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.device_connections ENABLE ROW LEVEL SECURITY;

-- Users manage only their own device connections
CREATE POLICY IF NOT EXISTS "Devices: select own" ON public.device_connections
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Devices: insert own" ON public.device_connections
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Devices: update own" ON public.device_connections
  FOR UPDATE USING (auth.uid() = user_id);

------------------------------------------------------------
-- 4) AISRI_INTAKE_RAW
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.aisri_intake_raw (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id                UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  submitted_at              TIMESTAMPTZ NOT NULL,
  email                     TEXT NOT NULL,
  full_name                 TEXT NOT NULL,
  age                       INTEGER,
  gender                    TEXT,
  running_experience_years  INTEGER,
  weekly_mileage_km         DECIMAL(10,2),
  q1  TEXT, q2  TEXT, q3  TEXT, q4  TEXT, q5  TEXT,
  q6  TEXT, q7  TEXT, q8  TEXT, q9  TEXT, q10 TEXT,
  q11 TEXT, q12 TEXT, q13 TEXT, q14 TEXT, q15 TEXT,
  q16 TEXT, q17 TEXT, q18 TEXT, q19 TEXT, q20 TEXT,
  q21 TEXT, q22 TEXT, q23 TEXT, q24 TEXT, q25 TEXT,
  q26 TEXT, q27 TEXT, q28 TEXT, q29 TEXT, q30 TEXT,
  q31 TEXT, q32 TEXT, q33 TEXT, q34 TEXT, q35 TEXT,
  q36 TEXT, q37 TEXT, q38 TEXT, q39 TEXT, q40 TEXT,
  q41 TEXT, q42 TEXT, q43 TEXT, q44 TEXT, q45 TEXT,
  q46 TEXT, q47 TEXT, q48 TEXT, q49 TEXT, q50 TEXT,
  training_goals            TEXT,
  previous_injuries         TEXT,
  medical_history           TEXT,
  processed                 BOOLEAN DEFAULT FALSE,
  processed_at              TIMESTAMPTZ,
  created_at                TIMESTAMPTZ DEFAULT NOW(),
  updated_at                TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_aisri_intake_email
  ON public.aisri_intake_raw (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_aisri_intake_profile
  ON public.aisri_intake_raw (profile_id);
CREATE INDEX IF NOT EXISTS idx_aisri_intake_processed
  ON public.aisri_intake_raw (processed);

CREATE TRIGGER set_aisri_intake_updated_at
BEFORE UPDATE ON public.aisri_intake_raw
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.aisri_intake_raw ENABLE ROW LEVEL SECURITY;

-- Athletes see their own intake rows
CREATE POLICY IF NOT EXISTS "AISRI intake: athlete select" ON public.aisri_intake_raw
  FOR SELECT USING (auth.uid() = profile_id);

-- Coaches see their athletes' intake rows
CREATE POLICY IF NOT EXISTS "AISRI intake: coach select" ON public.aisri_intake_raw
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships r
      WHERE r.athlete_id = aisri_intake_raw.profile_id
        AND r.coach_id = auth.uid()
        AND r.status = 'active'
    )
  );

-- Allow athletes to insert their own intake rows
CREATE POLICY IF NOT EXISTS "AISRI intake: athlete insert" ON public.aisri_intake_raw
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

------------------------------------------------------------
-- 5) AISRI_ASSESSMENTS
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public."AISRI_assessments" (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  intake_id         UUID REFERENCES public.aisri_intake_raw(id) ON DELETE SET NULL,
  total_score       INTEGER CHECK (total_score >= 0 AND total_score <= 1000),
  mobility_score    INTEGER CHECK (mobility_score >= 0 AND mobility_score <= 1000),
  strength_score    INTEGER CHECK (strength_score >= 0 AND strength_score <= 1000),
  endurance_score   INTEGER CHECK (endurance_score >= 0 AND endurance_score <= 1000),
  flexibility_score INTEGER CHECK (flexibility_score >= 0 AND flexibility_score <= 1000),
  balance_score     INTEGER CHECK (balance_score >= 0 AND balance_score <= 1000),
  age               INTEGER,
  gender            TEXT,
  running_experience INTEGER,
  weekly_mileage     DECIMAL(10,2),
  assessment_date   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_aisri_assessments_athlete
  ON public."AISRI_assessments" (athlete_id);
CREATE INDEX IF NOT EXISTS idx_aisri_assessments_score
  ON public."AISRI_assessments" (total_score DESC);

ALTER TABLE public."AISRI_assessments" ENABLE ROW LEVEL SECURITY;

-- Athlete can view own assessments
CREATE POLICY IF NOT EXISTS "AISRI assessments: athlete select" ON public."AISRI_assessments"
  FOR SELECT USING (auth.uid() = athlete_id);

-- Coaches can view assessments of their athletes
CREATE POLICY IF NOT EXISTS "AISRI assessments: coach select" ON public."AISRI_assessments"
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships r
      WHERE r.athlete_id = "AISRI_assessments".athlete_id
        AND r.coach_id = auth.uid()
        AND r.status = 'active'
    )
  );

------------------------------------------------------------
-- 6) HELPER FUNCTIONS
------------------------------------------------------------

-- 6.1 Link all intake rows to profiles by email
CREATE OR REPLACE FUNCTION public.link_all_intake_to_profiles()
RETURNS TABLE (
  total_linked   INTEGER,
  total_unmatched INTEGER
) AS $$
DECLARE
  v_before_linked INTEGER;
  v_after_linked  INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_before_linked
  FROM public.aisri_intake_raw
  WHERE profile_id IS NOT NULL;

  UPDATE public.aisri_intake_raw r
  SET profile_id = p.id
  FROM public.profiles p
  WHERE r.profile_id IS NULL
    AND LOWER(r.email) = LOWER(p.email);

  SELECT COUNT(*) INTO v_after_linked
  FROM public.aisri_intake_raw
  WHERE profile_id IS NOT NULL;

  total_linked := v_after_linked - v_before_linked;
  total_unmatched := (
    SELECT COUNT(*) FROM public.aisri_intake_raw
    WHERE profile_id IS NULL
  );

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6.2 Process all unprocessed AISRI intakes into assessments
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
  r           RECORD;
  v_total_score NUMERIC;
  v_mobility    NUMERIC;
  v_strength    NUMERIC;
  v_endurance   NUMERIC;
  v_flexibility NUMERIC;
  v_balance     NUMERIC;
  v_vals        INTEGER[];
  i             INTEGER;
BEGIN
  FOR r IN
    SELECT * FROM public.aisri_intake_raw
    WHERE processed = FALSE
  LOOP
    v_total := v_total + 1;

    IF r.profile_id IS NULL THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    -- Simple scoring: treat q1-q50 numeric responses as 1-5, scale to 0-1000
    v_vals := ARRAY[
      NULLIF(r.q1,'')::INTEGER, NULLIF(r.q2,'')::INTEGER, NULLIF(r.q3,'')::INTEGER,
      NULLIF(r.q4,'')::INTEGER, NULLIF(r.q5,'')::INTEGER, NULLIF(r.q6,'')::INTEGER,
      NULLIF(r.q7,'')::INTEGER, NULLIF(r.q8,'')::INTEGER, NULLIF(r.q9,'')::INTEGER,
      NULLIF(r.q10,'')::INTEGER, NULLIF(r.q11,'')::INTEGER, NULLIF(r.q12,'')::INTEGER,
      NULLIF(r.q13,'')::INTEGER, NULLIF(r.q14,'')::INTEGER, NULLIF(r.q15,'')::INTEGER,
      NULLIF(r.q16,'')::INTEGER, NULLIF(r.q17,'')::INTEGER, NULLIF(r.q18,'')::INTEGER,
      NULLIF(r.q19,'')::INTEGER, NULLIF(r.q20,'')::INTEGER, NULLIF(r.q21,'')::INTEGER,
      NULLIF(r.q22,'')::INTEGER, NULLIF(r.q23,'')::INTEGER, NULLIF(r.q24,'')::INTEGER,
      NULLIF(r.q25,'')::INTEGER, NULLIF(r.q26,'')::INTEGER, NULLIF(r.q27,'')::INTEGER,
      NULLIF(r.q28,'')::INTEGER, NULLIF(r.q29,'')::INTEGER, NULLIF(r.q30,'')::INTEGER,
      NULLIF(r.q31,'')::INTEGER, NULLIF(r.q32,'')::INTEGER, NULLIF(r.q33,'')::INTEGER,
      NULLIF(r.q34,'')::INTEGER, NULLIF(r.q35,'')::INTEGER, NULLIF(r.q36,'')::INTEGER,
      NULLIF(r.q37,'')::INTEGER, NULLIF(r.q38,'')::INTEGER, NULLIF(r.q39,'')::INTEGER,
      NULLIF(r.q40,'')::INTEGER, NULLIF(r.q41,'')::INTEGER, NULLIF(r.q42,'')::INTEGER,
      NULLIF(r.q43,'')::INTEGER, NULLIF(r.q44,'')::INTEGER, NULLIF(r.q45,'')::INTEGER,
      NULLIF(r.q46,'')::INTEGER, NULLIF(r.q47,'')::INTEGER, NULLIF(r.q48,'')::INTEGER,
      NULLIF(r.q49,'')::INTEGER, NULLIF(r.q50,'')::INTEGER
    ];

    v_total_score := 0;
    v_mobility    := 0;
    v_strength    := 0;
    v_endurance   := 0;
    v_flexibility := 0;
    v_balance     := 0;

    FOR i IN array_lower(v_vals,1)..array_upper(v_vals,1) LOOP
      IF v_vals[i] IS NULL THEN
        CONTINUE;
      END IF;

      v_total_score := v_total_score + v_vals[i];

      IF i BETWEEN 1 AND 10 THEN
        v_mobility := v_mobility + v_vals[i];
      ELSIF i BETWEEN 11 AND 20 THEN
        v_strength := v_strength + v_vals[i];
      ELSIF i BETWEEN 21 AND 30 THEN
        v_endurance := v_endurance + v_vals[i];
      ELSIF i BETWEEN 31 AND 40 THEN
        v_flexibility := v_flexibility + v_vals[i];
      ELSE
        v_balance := v_balance + v_vals[i];
      END IF;
    END LOOP;

    IF v_total_score IS NULL OR v_total_score = 0 THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    -- Scale total_score to 0-1000 assuming responses are between 1 and 5
    v_total_score := LEAST(1000, GREATEST(0,
      (v_total_score / (5.0 * GREATEST(1, array_length(v_vals,1)))) * 1000
    ));

    INSERT INTO public."AISRI_assessments" (
      athlete_id,
      intake_id,
      total_score,
      mobility_score,
      strength_score,
      endurance_score,
      flexibility_score,
      balance_score,
      age,
      gender,
      running_experience,
      weekly_mileage,
      assessment_date
    ) VALUES (
      r.profile_id,
      r.id,
      ROUND(v_total_score)::INTEGER,
      ROUND(v_mobility * 20.0 / 50.0)::INTEGER,
      ROUND(v_strength * 20.0 / 50.0)::INTEGER,
      ROUND(v_endurance * 20.0 / 50.0)::INTEGER,
      ROUND(v_flexibility * 20.0 / 50.0)::INTEGER,
      ROUND(v_balance * 20.0 / 50.0)::INTEGER,
      r.age,
      r.gender,
      r.running_experience_years,
      r.weekly_mileage_km,
      NOW()
    );

    UPDATE public.aisri_intake_raw
    SET processed = TRUE,
        processed_at = NOW(),
        updated_at = NOW()
    WHERE id = r.id;

    v_processed := v_processed + 1;
  END LOOP;

  processed_count := v_processed;
  skipped_count   := v_skipped;
  total_count     := v_total;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

------------------------------------------------------------
-- 7) DASHBOARD VIEW
------------------------------------------------------------

CREATE OR REPLACE VIEW public.athlete_intake_dashboard AS
SELECT
  a.id                 AS assessment_id,
  p.id                 AS athlete_profile_id,
  p.full_name,
  p.email,
  a.total_score,
  a.mobility_score,
  a.strength_score,
  a.endurance_score,
  a.flexibility_score,
  a.balance_score,
  a.assessment_date,
  i.submitted_at       AS intake_submitted_at,
  i.running_experience_years,
  i.weekly_mileage_km,
  i.training_goals,
  i.previous_injuries,
  i.medical_history
FROM public."AISRI_assessments" a
JOIN public.profiles p ON p.id = a.athlete_id
LEFT JOIN public.aisri_intake_raw i ON i.id = a.intake_id;
