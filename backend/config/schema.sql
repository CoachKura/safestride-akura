-- ============================================================================
-- AKURA SAFESTRIDE DATABASE SCHEMA
-- Version: 1.0
-- Database: PostgreSQL (Supabase)
-- Purpose: Store athlete assessments, training protocols, and workout feedback
-- ============================================================================

-- Enable UUID extension (required for UUID generation)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE 1: PROFILES (extends Supabase auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT CHECK (role IN ('athlete', 'coach', 'admin')) DEFAULT 'athlete',
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  height_cm NUMERIC(5,2),
  weight_kg NUMERIC(5,2),
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TABLE 2: ASSESSMENTS (stores AIFRI assessments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- AIFRI Scores
  aifri_score NUMERIC(5,2) CHECK (aifri_score >= 0 AND aifri_score <= 100),
  risk_level TEXT CHECK (risk_level IN ('Low', 'Moderate', 'High', 'Very High')),
  
  -- Pillar Scores (0-100 each)
  pillar_scores JSONB DEFAULT '{
    "running": 0,
    "strength": 0,
    "rom": 0,
    "balance": 0,
    "mobility": 0,
    "alignment": 0
  }'::jsonb,
  
  -- Raw Assessment Data
  assessment_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- Personal Info
  personal_info JSONB DEFAULT '{
    "age": null,
    "height": null,
    "weight": null,
    "gender": null,
    "activityLevel": null
  }'::jsonb,
  
  -- Medical History
  medical_history JSONB DEFAULT '{
    "injuries": [],
    "conditions": [],
    "medications": [],
    "surgeries": []
  }'::jsonb,
  
  -- Alignment Metrics
  alignment_metrics JSONB DEFAULT '{
    "qAngle": null,
    "footPronation": null,
    "pelvicTilt": null,
    "forwardHead": null,
    "shoulderSymmetry": null,
    "spinalCurves": null
  }'::jsonb,
  
  -- ROM (Range of Motion)
  rom_metrics JSONB DEFAULT '{
    "ankleFlexion": null,
    "hipFlexion": null,
    "kneeExtension": null,
    "shoulderFlexion": null
  }'::jsonb,
  
  -- FMS (Functional Movement Screen)
  fms_metrics JSONB DEFAULT '{
    "deepSquat": null,
    "hurdleStep": null,
    "inlineLunge": null,
    "shoulderMobility": null,
    "legRaise": null,
    "pushUp": null,
    "rotaryStability": null,
    "totalScore": null
  }'::jsonb,
  
  -- Strength Metrics
  strength_metrics JSONB DEFAULT '{
    "gripStrength": null,
    "legPress": null,
    "plankTime": null,
    "pushUpCount": null
  }'::jsonb,
  
  -- Balance Metrics
  balance_metrics JSONB DEFAULT '{
    "singleLegLeft": null,
    "singleLegRight": null,
    "closedEyes": null,
    "yBalance": null
  }'::jsonb,
  
  -- Mobility Metrics
  mobility_metrics JSONB DEFAULT '{
    "sitAndReach": null,
    "shoulderReach": null,
    "hipRotation": null
  }'::jsonb,
  
  -- Running History
  running_history JSONB DEFAULT '{
    "weeklyMileage": null,
    "longestRun": null,
    "paceAverage": null,
    "injuries": []
  }'::jsonb,
  
  -- Goals
  goals JSONB DEFAULT '{
    "primary": null,
    "targetRace": null,
    "targetDate": null,
    "notes": null
  }'::jsonb,
  
  -- Linked Protocol
  protocol_id UUID,
  
  -- Status
  status TEXT CHECK (status IN ('pending', 'completed', 'archived')) DEFAULT 'completed',
  
  -- Timestamps
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TABLE 3: PROTOCOLS (90-day adaptive training plans)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  assessment_id UUID REFERENCES public.assessments(id) ON DELETE SET NULL,
  
  -- Protocol Metadata
  name TEXT NOT NULL,
  description TEXT,
  
  -- Duration
  duration_days INTEGER DEFAULT 90,
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  
  -- Protocol Data (12 weeks, 90 daily workouts)
  protocol_data JSONB NOT NULL DEFAULT '{
    "weeks": [],
    "milestones": [],
    "progressionRules": {}
  }'::jsonb,
  
  -- AIFRI Context (snapshot at protocol creation)
  aifri_score NUMERIC(5,2),
  risk_level TEXT,
  pillar_scores JSONB,
  
  -- Adaptive Rules
  adaptation_rules JSONB DEFAULT '{
    "injuryThreshold": 7,
    "fatigueThreshold": 8,
    "recoveryDays": 2,
    "progressionRate": 0.1
  }'::jsonb,
  
  -- Status
  status TEXT CHECK (status IN ('active', 'paused', 'completed', 'cancelled')) DEFAULT 'active',
  completion_percentage NUMERIC(5,2) DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TABLE 4: WORKOUTS (individual daily workouts)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  protocol_id UUID REFERENCES public.protocols(id) ON DELETE CASCADE NOT NULL,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Workout Identity
  week_number INTEGER NOT NULL CHECK (week_number >= 1 AND week_number <= 12),
  day_number INTEGER NOT NULL CHECK (day_number >= 1 AND day_number <= 90),
  day_of_week TEXT CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
  
  -- Workout Data
  workout_data JSONB NOT NULL DEFAULT '{
    "type": "rest",
    "exercises": [],
    "duration": 0,
    "intensity": "low"
  }'::jsonb,
  
  -- Scheduling
  scheduled_date DATE,
  completed_date DATE,
  
  -- Status
  completed BOOLEAN DEFAULT FALSE,
  skipped BOOLEAN DEFAULT FALSE,
  skip_reason TEXT,
  
  -- Performance Metrics (filled after completion)
  actual_duration INTEGER, -- minutes
  actual_distance NUMERIC(6,2), -- km
  actual_pace TEXT, -- e.g., "5:30/km"
  calories_burned INTEGER,
  
  -- Notes
  coach_notes TEXT,
  athlete_notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TABLE 5: FEEDBACK (daily athlete feedback)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID REFERENCES public.workouts(id) ON DELETE CASCADE NOT NULL,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Subjective Metrics
  rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10), -- Rate of Perceived Exertion
  pain_level TEXT CHECK (pain_level IN ('none', 'mild', 'moderate', 'severe')),
  pain_location TEXT[],
  fatigue_level INTEGER CHECK (fatigue_level >= 1 AND fatigue_level <= 10),
  
  -- Recovery Metrics
  sleep_hours NUMERIC(3,1) CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
  sleep_quality TEXT CHECK (sleep_quality IN ('poor', 'fair', 'good', 'excellent')),
  soreness_level INTEGER CHECK (soreness_level >= 0 AND soreness_level <= 10),
  
  -- Lifestyle Factors
  nutrition_quality TEXT CHECK (nutrition_quality IN ('poor', 'fair', 'good', 'excellent')),
  hydration_level TEXT CHECK (hydration_level IN ('poor', 'adequate', 'good', 'excellent')),
  stress_level TEXT CHECK (stress_level IN ('low', 'moderate', 'high', 'very high')),
  
  -- Completion Status
  completed BOOLEAN DEFAULT FALSE,
  completion_percentage INTEGER CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  
  -- Free Text
  notes TEXT,
  
  -- AI Analysis Response
  ai_analysis JSONB DEFAULT '{
    "recommendations": [],
    "adjustments": [],
    "concerns": []
  }'::jsonb,
  
  -- Plan Adjustments Made
  plan_adjusted BOOLEAN DEFAULT FALSE,
  adjustment_details JSONB,
  
  -- Timestamps
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TABLE 6: COACH_ATHLETE_RELATIONSHIPS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.coach_athlete_relationships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coach_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Status
  status TEXT CHECK (status IN ('pending', 'active', 'inactive')) DEFAULT 'pending',
  
  -- Permissions
  permissions JSONB DEFAULT '{
    "canViewAssessments": true,
    "canEditProtocols": true,
    "canViewFeedback": true,
    "canMessage": true
  }'::jsonb,
  
  -- Timestamps
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure unique coach-athlete pairs
  UNIQUE(coach_id, athlete_id)
);

-- ============================================================================
-- INDEXES (for performance optimization)
-- ============================================================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Assessments indexes
CREATE INDEX IF NOT EXISTS idx_assessments_athlete ON public.assessments(athlete_id);
CREATE INDEX IF NOT EXISTS idx_assessments_created ON public.assessments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_assessments_risk ON public.assessments(risk_level);
CREATE INDEX IF NOT EXISTS idx_assessments_score ON public.assessments(aifri_score);

-- Protocols indexes
CREATE INDEX IF NOT EXISTS idx_protocols_athlete ON public.protocols(athlete_id);
CREATE INDEX IF NOT EXISTS idx_protocols_assessment ON public.protocols(assessment_id);
CREATE INDEX IF NOT EXISTS idx_protocols_status ON public.protocols(status);
CREATE INDEX IF NOT EXISTS idx_protocols_dates ON public.protocols(start_date, end_date);

-- Workouts indexes
CREATE INDEX IF NOT EXISTS idx_workouts_protocol ON public.workouts(protocol_id);
CREATE INDEX IF NOT EXISTS idx_workouts_athlete ON public.workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workouts_date ON public.workouts(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_workouts_completed ON public.workouts(completed);
CREATE INDEX IF NOT EXISTS idx_workouts_week_day ON public.workouts(week_number, day_number);

-- Feedback indexes
CREATE INDEX IF NOT EXISTS idx_feedback_workout ON public.feedback(workout_id);
CREATE INDEX IF NOT EXISTS idx_feedback_athlete ON public.feedback(athlete_id);
CREATE INDEX IF NOT EXISTS idx_feedback_submitted ON public.feedback(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_pain ON public.feedback(pain_level);
CREATE INDEX IF NOT EXISTS idx_feedback_rpe ON public.feedback(rpe);

-- Coach-Athlete indexes
CREATE INDEX IF NOT EXISTS idx_coach_athlete_coach ON public.coach_athlete_relationships(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_athlete_athlete ON public.coach_athlete_relationships(athlete_id);
CREATE INDEX IF NOT EXISTS idx_coach_athlete_status ON public.coach_athlete_relationships(status);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_athlete_relationships ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own profile on signup
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Coaches can view their athletes' profiles
CREATE POLICY "Coaches can view athlete profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.coach_athlete_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = profiles.id
      AND status = 'active'
    )
  );

-- ============================================================================
-- ASSESSMENTS POLICIES
-- ============================================================================

-- Athletes can view their own assessments
CREATE POLICY "Athletes can view own assessments"
  ON public.assessments FOR SELECT
  USING (auth.uid() = athlete_id);

-- Athletes can create their own assessments
CREATE POLICY "Athletes can create own assessments"
  ON public.assessments FOR INSERT
  WITH CHECK (auth.uid() = athlete_id);

-- Coaches can view their athletes' assessments
CREATE POLICY "Coaches can view athlete assessments"
  ON public.assessments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.coach_athlete_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = assessments.athlete_id
      AND status = 'active'
    )
  );

-- ============================================================================
-- PROTOCOLS POLICIES
-- ============================================================================

-- Athletes can view their own protocols
CREATE POLICY "Athletes can view own protocols"
  ON public.protocols FOR SELECT
  USING (auth.uid() = athlete_id);

-- Coaches can view and manage their athletes' protocols
CREATE POLICY "Coaches can manage athlete protocols"
  ON public.protocols FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.coach_athlete_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = protocols.athlete_id
      AND status = 'active'
    )
  );

-- ============================================================================
-- WORKOUTS POLICIES
-- ============================================================================

-- Athletes can view their own workouts
CREATE POLICY "Athletes can view own workouts"
  ON public.workouts FOR SELECT
  USING (auth.uid() = athlete_id);

-- Athletes can update their own workouts (mark complete, add notes)
CREATE POLICY "Athletes can update own workouts"
  ON public.workouts FOR UPDATE
  USING (auth.uid() = athlete_id);

-- Coaches can view and manage their athletes' workouts
CREATE POLICY "Coaches can manage athlete workouts"
  ON public.workouts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.coach_athlete_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = workouts.athlete_id
      AND status = 'active'
    )
  );

-- ============================================================================
-- FEEDBACK POLICIES
-- ============================================================================

-- Athletes can view and create their own feedback
CREATE POLICY "Athletes can manage own feedback"
  ON public.feedback FOR ALL
  USING (auth.uid() = athlete_id);

-- Coaches can view their athletes' feedback
CREATE POLICY "Coaches can view athlete feedback"
  ON public.feedback FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.coach_athlete_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = feedback.athlete_id
      AND status = 'active'
    )
  );

-- ============================================================================
-- COACH-ATHLETE RELATIONSHIPS POLICIES
-- ============================================================================

-- Coaches can view relationships where they are the coach
CREATE POLICY "Coaches can view own relationships"
  ON public.coach_athlete_relationships FOR SELECT
  USING (auth.uid() = coach_id);

-- Athletes can view relationships where they are the athlete
CREATE POLICY "Athletes can view own relationships"
  ON public.coach_athlete_relationships FOR SELECT
  USING (auth.uid() = athlete_id);

-- Coaches can create new relationships (send invites)
CREATE POLICY "Coaches can create relationships"
  ON public.coach_athlete_relationships FOR INSERT
  WITH CHECK (auth.uid() = coach_id);

-- Athletes can update relationships (accept invites)
CREATE POLICY "Athletes can accept invites"
  ON public.coach_athlete_relationships FOR UPDATE
  USING (auth.uid() = athlete_id);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;

$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON public.assessments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_protocols_updated_at BEFORE UPDATE ON public.protocols
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON public.workouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_coach_athlete_updated_at BEFORE UPDATE ON public.coach_athlete_relationships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SEED DATA (optional test data)
-- ============================================================================

-- Uncomment to insert test data
-- INSERT INTO public.profiles (id, email, full_name, role)
-- VALUES (
--   '00000000-0000-0000-0000-000000000001',
--   'test@akura.in',
--   'Test Athlete',
--   'athlete'
-- );

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.schema_version (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.schema_version (version) VALUES ('1.0') ON CONFLICT DO NOTHING;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

-- Verify table creation
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_catalog.pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
