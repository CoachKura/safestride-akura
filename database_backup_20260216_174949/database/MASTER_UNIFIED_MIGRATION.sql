-- ========================================
-- 🎯 MASTER UNIFIED MIGRATION
-- ========================================
-- This migration creates a schema compatible with BOTH old and new app code
-- Run this in Supabase SQL Editor
-- 
-- What it does:
-- ✅ Creates/updates profiles table (for old app code)
-- ✅ Creates athlete_profiles table (for new Strava services)
-- ✅ Creates all calendar/workout tables
-- ✅ Loads 15 exercises
-- ✅ Sets up your user profile
-- ========================================

-- ========================================
-- STEP 1: PROFILES TABLE (OLD APP CODE)
-- ========================================

-- Drop and recreate profiles table with ALL needed columns
DROP TABLE IF EXISTS profiles CASCADE;

CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  name TEXT,
  email TEXT,
  date_of_birth DATE,
  gender TEXT,
  height_cm INTEGER,
  weight_kg NUMERIC(5,2),
  
  -- AISRI Assessment fields
  aisri_score INTEGER,
  mobility_score INTEGER,
  strength_score INTEGER,
  balance_score INTEGER,
  flexibility_score INTEGER,
  endurance_score INTEGER,
  power_score INTEGER,
  last_assessment_date TIMESTAMP WITH TIME ZONE,
  
  -- Strava fields
  strava_connected BOOLEAN DEFAULT false,
  strava_athlete_id TEXT,
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at TIMESTAMP WITH TIME ZONE,
  strava_activities JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- STEP 2: ATHLETE_PROFILES TABLE (NEW SERVICES)
-- ========================================

DROP TABLE IF EXISTS athlete_profiles CASCADE;

CREATE TABLE athlete_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  date_of_birth DATE,
  gender TEXT,
  height_cm INTEGER,
  weight_kg NUMERIC(5,2),
  running_experience_years INTEGER,
  injury_history TEXT,
  training_goal TEXT,
  
  -- AISRI Assessment scores
  latest_aisri_score INTEGER DEFAULT 60,
  mobility_score INTEGER DEFAULT 60,
  strength_score INTEGER DEFAULT 60,
  balance_score INTEGER DEFAULT 60,
  flexibility_score INTEGER DEFAULT 60,
  endurance_score INTEGER DEFAULT 60,
  power_score INTEGER DEFAULT 60,
  last_assessment_date TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE athlete_profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Athletes can view own profile"
  ON athlete_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Athletes can update own profile"
  ON athlete_profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Athletes can insert own profile"
  ON athlete_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- STEP 3: COACH_PROFILES TABLE
-- ========================================

DROP TABLE IF EXISTS coach_profiles CASCADE;

CREATE TABLE coach_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  coach_name TEXT NOT NULL,
  specialization TEXT,
  certification TEXT,
  years_experience INTEGER,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE coach_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view coaches"
  ON coach_profiles FOR SELECT
  USING (true);

-- ========================================
-- STEP 4: EXERCISES TABLE
-- ========================================

DROP TABLE IF EXISTS exercises CASCADE;

CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exercise_name TEXT NOT NULL,
  category TEXT NOT NULL,
  default_sets INTEGER DEFAULT 3,
  default_reps INTEGER,
  default_duration_seconds INTEGER,
  equipment_needed TEXT,
  description TEXT,
  video_url TEXT,
  image_url TEXT,
  difficulty_level TEXT DEFAULT 'beginner',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view exercises"
  ON exercises FOR SELECT
  USING (true);

-- ========================================
-- STEP 5: PROTOCOLS TABLE
-- ========================================

DROP TABLE IF EXISTS protocols CASCADE;

CREATE TABLE protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  protocol_name TEXT NOT NULL,
  protocol_type TEXT,
  description TEXT,
  duration_weeks INTEGER DEFAULT 2,
  frequency_per_week INTEGER DEFAULT 3,
  target_injury TEXT,
  target_deficit TEXT,
  expected_outcomes TEXT,
  created_by UUID REFERENCES coach_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE protocols ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view protocols"
  ON protocols FOR SELECT
  USING (true);

-- ========================================
-- STEP 6: ATHLETE_PROTOCOLS TABLE
-- ========================================

DROP TABLE IF EXISTS athlete_protocols CASCADE;

CREATE TABLE athlete_protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(id) ON DELETE CASCADE,
  protocol_id UUID REFERENCES protocols(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES coach_profiles(id),
  status TEXT DEFAULT 'active',
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  total_workouts_scheduled INTEGER DEFAULT 0,
  total_workouts_completed INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE athlete_protocols ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Athletes can view own protocols"
  ON athlete_protocols FOR SELECT
  USING (athlete_id IN (SELECT id FROM athlete_profiles WHERE user_id = auth.uid()));

-- ========================================
-- STEP 7: WORKOUTS TABLE
-- ========================================

DROP TABLE IF EXISTS workouts CASCADE;

CREATE TABLE workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_protocol_id UUID REFERENCES athlete_protocols(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL,
  exercises JSONB NOT NULL,
  estimated_duration_minutes INTEGER DEFAULT 30,
  difficulty TEXT DEFAULT 'moderate',
  equipment_needed TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view workouts for their protocols"
  ON workouts FOR SELECT
  USING (
    athlete_protocol_id IN (
      SELECT ap.id FROM athlete_protocols ap
      JOIN athlete_profiles a ON ap.athlete_id = a.id
      WHERE a.user_id = auth.uid()
    )
  );

-- ========================================
-- STEP 8: ATHLETE_CALENDAR TABLE
-- ========================================

DROP TABLE IF EXISTS athlete_calendar CASCADE;

CREATE TABLE athlete_calendar (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(id) ON DELETE CASCADE,
  workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME DEFAULT '09:00:00',
  status TEXT DEFAULT 'pending',
  completed_at TIMESTAMP WITH TIME ZONE,
  actual_duration_minutes INTEGER,
  difficulty_rating INTEGER,
  pain_level INTEGER,
  athlete_notes TEXT,
  reminder_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_athlete_calendar_athlete_id ON athlete_calendar(athlete_id);
CREATE INDEX idx_athlete_calendar_scheduled_date ON athlete_calendar(scheduled_date);
CREATE INDEX idx_athlete_calendar_status ON athlete_calendar(status);

ALTER TABLE athlete_calendar ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Athletes can view own calendar"
  ON athlete_calendar FOR SELECT
  USING (athlete_id IN (SELECT id FROM athlete_profiles WHERE user_id = auth.uid()));

CREATE POLICY "Athletes can update own calendar"
  ON athlete_calendar FOR UPDATE
  USING (athlete_id IN (SELECT id FROM athlete_profiles WHERE user_id = auth.uid()));

CREATE POLICY "Athletes can insert own calendar"
  ON athlete_calendar FOR INSERT
  WITH CHECK (athlete_id IN (SELECT id FROM athlete_profiles WHERE user_id = auth.uid()));

-- ========================================
-- STEP 9: LOAD 15 EXERCISES
-- ========================================

INSERT INTO exercises (exercise_name, category, default_sets, default_reps, default_duration_seconds, equipment_needed, description, difficulty_level) VALUES
('Ankle Dorsiflexion', 'Mobility', 3, 15, NULL, 'None', 'Improve ankle mobility for better running form', 'beginner'),
('Calf Raises', 'Strength', 3, 20, NULL, 'None', 'Strengthen calves for push-off power', 'beginner'),
('Hip Abduction', 'Strength', 3, 15, NULL, 'Resistance Band', 'Strengthen hip stabilizers', 'beginner'),
('Clamshells', 'Strength', 3, 15, NULL, 'Resistance Band', 'Target gluteus medius', 'beginner'),
('Single-Leg Balance', 'Balance', 3, NULL, 30, 'None', 'Improve balance and proprioception', 'beginner'),
('Dead Bug', 'Strength', 3, 12, NULL, 'None', 'Core stability exercise', 'beginner'),
('Glute Bridge', 'Strength', 3, 15, NULL, 'None', 'Strengthen glutes and hamstrings', 'beginner'),
('Hip Flexor Stretch', 'Mobility', 3, NULL, 30, 'None', 'Improve hip flexibility', 'beginner'),
('Hamstring Stretch', 'Flexibility', 3, NULL, 30, 'None', 'Improve hamstring flexibility', 'beginner'),
('Quadriceps Stretch', 'Flexibility', 3, NULL, 30, 'None', 'Improve quad flexibility', 'beginner'),
('Plank', 'Strength', 3, NULL, 30, 'None', 'Core strengthening', 'beginner'),
('Side Plank', 'Strength', 3, NULL, 30, 'None', 'Lateral core stability', 'intermediate'),
('Bird Dog', 'Balance', 3, 12, NULL, 'None', 'Balance and core stability', 'beginner'),
('Romanian Deadlift', 'Strength', 3, 12, NULL, 'Dumbbells', 'Posterior chain strength', 'intermediate'),
('Step Ups', 'Strength', 3, 12, NULL, 'Step or Box', 'Single-leg strength', 'beginner')
ON CONFLICT DO NOTHING;

-- ========================================
-- STEP 10: CREATE "COACH KURA (AI)" SYSTEM COACH
-- ========================================

INSERT INTO coach_profiles (coach_name, specialization, bio)
VALUES (
  'Coach Kura (AI)',
  'AI-Powered Running Coach',
  'Your AI-powered running coach that creates personalized workout protocols based on your AISRI assessment and Strava data.'
)
ON CONFLICT DO NOTHING;

-- ========================================
-- STEP 11: CREATE YOUR USER PROFILES
-- ========================================

-- Replace this UUID with YOUR actual user ID
-- You can find it in the app logs: e1f2abfc-a1bb-4a85-b616-fec751de5dc3

DO $$
DECLARE
  v_user_id UUID := 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3';
BEGIN
  -- Create profiles record (for old app code)
  INSERT INTO profiles (user_id, name, aisri_score, mobility_score, strength_score, balance_score, flexibility_score, endurance_score, power_score)
  VALUES (v_user_id, 'User', 60, 60, 60, 60, 60, 60, 60)
  ON CONFLICT (user_id) DO UPDATE SET
    aisri_score = COALESCE(profiles.aisri_score, 60),
    mobility_score = COALESCE(profiles.mobility_score, 60),
    strength_score = COALESCE(profiles.strength_score, 60),
    balance_score = COALESCE(profiles.balance_score, 60),
    flexibility_score = COALESCE(profiles.flexibility_score, 60),
    endurance_score = COALESCE(profiles.endurance_score, 60),
    power_score = COALESCE(profiles.power_score, 60),
    updated_at = NOW();

  -- Create athlete_profiles record (for new Strava services)
  INSERT INTO athlete_profiles (user_id, latest_aisri_score, mobility_score, strength_score, balance_score, flexibility_score, endurance_score, power_score)
  VALUES (v_user_id, 60, 60, 60, 60, 60, 60, 60)
  ON CONFLICT (user_id) DO UPDATE SET
    latest_aisri_score = COALESCE(athlete_profiles.latest_aisri_score, 60),
    mobility_score = COALESCE(athlete_profiles.mobility_score, 60),
    strength_score = COALESCE(athlete_profiles.strength_score, 60),
    balance_score = COALESCE(athlete_profiles.balance_score, 60),
    flexibility_score = COALESCE(athlete_profiles.flexibility_score, 60),
    endurance_score = COALESCE(athlete_profiles.endurance_score, 60),
    power_score = COALESCE(athlete_profiles.power_score, 60),
    updated_at = NOW();
END $$;

-- ========================================
-- STEP 12: VERIFICATION QUERIES
-- ========================================

-- Check tables exist
SELECT 
  'Tables Created' as status,
  COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles',
    'athlete_profiles',
    'coach_profiles',
    'exercises',
    'protocols',
    'athlete_protocols',
    'workouts',
    'athlete_calendar'
  );

-- Check exercises loaded
SELECT 
  'Exercises Loaded' as status,
  COUNT(*) as exercise_count 
FROM exercises;

-- Check your profiles created
SELECT 
  'User Profiles' as status,
  (SELECT COUNT(*) FROM profiles WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3') as profiles_count,
  (SELECT COUNT(*) FROM athlete_profiles WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3') as athlete_profiles_count;

-- ========================================
-- ✅ MIGRATION COMPLETE!
-- ========================================
-- Expected results:
-- • Tables Created: 8
-- • Exercises Loaded: 15
-- • User Profiles: profiles_count=1, athlete_profiles_count=1
--
-- If you see these numbers, you're ready to test the app!
-- ========================================
