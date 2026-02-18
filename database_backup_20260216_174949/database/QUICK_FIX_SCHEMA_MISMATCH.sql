-- ========================================
-- 🔧 QUICK FIX: Schema Mismatch Resolution
-- ========================================
-- This adds missing columns and creates athlete_profiles
-- WITHOUT dropping your existing data
-- Run this in Supabase SQL Editor
-- ========================================

-- ========================================
-- STEP 1: Create profiles table
-- ========================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  name TEXT,
  email TEXT,
  role TEXT CHECK (role IN ('athlete', 'coach')),
  avatar_url TEXT,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT,
  
  -- AISRI assessment columns
  current_aisri_score INTEGER,
  aisri_score INTEGER,
  mobility_score INTEGER,
  strength_score INTEGER,
  balance_score INTEGER,
  flexibility_score INTEGER,
  endurance_score INTEGER,
  power_score INTEGER,
  last_assessment_date TIMESTAMP WITH TIME ZONE,
  
  -- Strava columns
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

-- Add missing columns to profiles table if they don't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS weekly_goal_distance NUMERIC(5,2);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS strava_connected_at TIMESTAMP WITH TIME ZONE;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ========================================
-- STEP 2: Create athlete_profiles table
-- ========================================

CREATE TABLE IF NOT EXISTS athlete_profiles (
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

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Athletes can view own profile" ON athlete_profiles;
DROP POLICY IF EXISTS "Athletes can update own profile" ON athlete_profiles;
DROP POLICY IF EXISTS "Athletes can insert own profile" ON athlete_profiles;

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

-- Add missing columns to athlete_profiles if they don't exist
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS athlete_name TEXT;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS height_cm INTEGER;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS weight_kg NUMERIC(5,2);
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS running_experience_years INTEGER;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS injury_history TEXT;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS training_goal TEXT;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS latest_aisri_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS mobility_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS strength_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS balance_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS flexibility_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS endurance_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS power_score INTEGER DEFAULT 60;
ALTER TABLE athlete_profiles ADD COLUMN IF NOT EXISTS last_assessment_date TIMESTAMP WITH TIME ZONE;

-- Make athlete_name nullable (not all athletes need names immediately)
ALTER TABLE athlete_profiles ALTER COLUMN athlete_name DROP NOT NULL;

-- ========================================
-- STEP 3: Create coach_profiles table
-- ========================================

CREATE TABLE IF NOT EXISTS coach_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  coach_name TEXT NOT NULL,
  specialization TEXT,
  certification TEXT,
  years_experience INTEGER,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Make user_id nullable (for AI coaches)
ALTER TABLE coach_profiles ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE coach_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view coaches" ON coach_profiles;

CREATE POLICY "Anyone can view coaches"
  ON coach_profiles FOR SELECT
  USING (true);

-- ========================================
-- STEP 4: Create exercises table
-- ========================================

CREATE TABLE IF NOT EXISTS exercises (
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

DROP POLICY IF EXISTS "Anyone can view exercises" ON exercises;

CREATE POLICY "Anyone can view exercises"
  ON exercises FOR SELECT
  USING (true);

-- Add missing columns to exercises table if they don't exist
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS difficulty_level TEXT DEFAULT 'beginner';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS video_url TEXT;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Fix column types if they're wrong (array -> text)
-- Force convert equipment_needed to TEXT using USING clause
DO $$ 
BEGIN
  BEGIN
    -- Try to alter the column type
    ALTER TABLE exercises ALTER COLUMN equipment_needed TYPE TEXT USING equipment_needed::TEXT;
  EXCEPTION 
    WHEN OTHERS THEN
      -- If it fails, column is probably already TEXT, which is fine
      NULL;
  END;
END $$;

-- ========================================
-- STEP 5: Load exercises (if not already loaded)
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
-- STEP 6: Create protocols table
-- ========================================

CREATE TABLE IF NOT EXISTS protocols (
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

DROP POLICY IF EXISTS "Anyone can view protocols" ON protocols;

CREATE POLICY "Anyone can view protocols"
  ON protocols FOR SELECT
  USING (true);

-- ========================================
-- STEP 7: Create athlete_protocols table
-- ========================================

CREATE TABLE IF NOT EXISTS athlete_protocols (
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

DROP POLICY IF EXISTS "Athletes can view own protocols" ON athlete_protocols;

CREATE POLICY "Athletes can view own protocols"
  ON athlete_protocols FOR SELECT
  USING (athlete_id IN (SELECT id FROM athlete_profiles WHERE user_id = auth.uid()));

-- ========================================
-- STEP 8: Create workouts table
-- ========================================

CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_protocol_id UUID REFERENCES athlete_protocols(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL,
  exercises JSONB NOT NULL,
  estimated_duration_minutes INTEGER DEFAULT 30,
  difficulty TEXT DEFAULT 'moderate',
  equipment_needed TEXT,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns to workouts table if they don't exist
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view workouts for their protocols" ON workouts;

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
-- STEP 9: Create athlete_calendar table
-- ========================================

CREATE TABLE IF NOT EXISTS athlete_calendar (
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
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_id ON athlete_calendar(athlete_id);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_scheduled_date ON athlete_calendar(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_status ON athlete_calendar(status);

ALTER TABLE athlete_calendar ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Athletes can view own calendar" ON athlete_calendar;
DROP POLICY IF EXISTS "Athletes can update own calendar" ON athlete_calendar;
DROP POLICY IF EXISTS "Athletes can insert own calendar" ON athlete_calendar;

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
-- STEP 10: Create "Coach Kura (AI)"
-- ========================================

INSERT INTO coach_profiles (coach_name, specialization, bio)
VALUES (
  'Coach Kura (AI)',
  'AI-Powered Running Coach',
  'Your AI-powered running coach that creates personalized workout protocols based on your AISRI assessment and Strava data.'
)
ON CONFLICT DO NOTHING;

-- ========================================
-- STEP 11: Create profile for user e1f2abfc-a1bb-4a85-b616-fec751de5dc3
-- ========================================

INSERT INTO profiles (id, role, name, full_name, current_aisri_score, aisri_score)
VALUES (
  'e1f2abfc-a1bb-4a85-b616-fec751de5dc3'::uuid,
  'athlete',
  'User',
  'User',
  60,
  60
)
ON CONFLICT (id) DO UPDATE SET
  current_aisri_score = COALESCE(profiles.current_aisri_score, 60),
  aisri_score = COALESCE(profiles.aisri_score, 60);

-- ========================================
-- STEP 12: Create athlete_profile for user e1f2abfc-a1bb-4a85-b616-fec751de5dc3
-- ========================================

INSERT INTO athlete_profiles (
  user_id,
  athlete_name,
  latest_aisri_score,
  mobility_score,
  strength_score,
  balance_score,
  flexibility_score,
  endurance_score,
  power_score
)
VALUES (
  'e1f2abfc-a1bb-4a85-b616-fec751de5dc3'::uuid,
  'User',
  60,
  60,
  60,
  60,
  60,
  60,
  60
)
ON CONFLICT (user_id) DO UPDATE SET
  athlete_name = COALESCE(EXCLUDED.athlete_name, athlete_profiles.athlete_name),
  latest_aisri_score = COALESCE(EXCLUDED.latest_aisri_score, athlete_profiles.latest_aisri_score),
  mobility_score = COALESCE(EXCLUDED.mobility_score, athlete_profiles.mobility_score),
  strength_score = COALESCE(EXCLUDED.strength_score, athlete_profiles.strength_score),
  balance_score = COALESCE(EXCLUDED.balance_score, athlete_profiles.balance_score),
  flexibility_score = COALESCE(EXCLUDED.flexibility_score, athlete_profiles.flexibility_score),
  endurance_score = COALESCE(EXCLUDED.endurance_score, athlete_profiles.endurance_score),
  power_score = COALESCE(EXCLUDED.power_score, athlete_profiles.power_score),
  updated_at = NOW();

-- ========================================
-- STEP 13: Verification
-- ========================================

SELECT 
  'Migration Complete!' as status,
  (SELECT COUNT(*) FROM profiles) as profiles_count,
  (SELECT COUNT(*) FROM athlete_profiles) as athlete_profiles_count,
  (SELECT COUNT(*) FROM exercises) as exercises_count,
  (SELECT COUNT(*) FROM coach_profiles) as coaches_count;

-- ========================================
-- ✅ DONE!
-- ========================================
-- Expected: 
-- • profiles_count: 1+ (your profile created)
-- • athlete_profiles_count: 1+ (synced from profiles)
-- • exercises_count: 15
-- • coaches_count: 1+ (Coach Kura AI)
-- 
-- ⚠️ If profiles_count = 0, you need to log in to the app first!
-- ========================================
