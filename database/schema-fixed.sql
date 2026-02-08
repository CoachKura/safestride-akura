-- =====================================================
-- AKURA SAFESTRIDE DATABASE SCHEMA
-- Run these commands in Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. PROFILES TABLE
-- Stores extended user information beyond Supabase auth
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('athlete', 'coach')),
  email TEXT NOT NULL UNIQUE,
  avatar_url TEXT,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  bio TEXT,
  location TEXT,
  timezone TEXT DEFAULT 'UTC',
  
  -- Athlete-specific fields
  current_aifri_score INTEGER,
  fitness_level TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced', 'elite')),
  running_goals TEXT[],
  preferred_distances TEXT[], -- ['5K', '10K', 'Half Marathon', 'Marathon']
  
  -- Coach-specific fields
  certification TEXT,
  specializations TEXT[], -- ['Marathon Training', 'Speed Work', 'Injury Prevention']
  years_experience INTEGER,
  max_athletes INTEGER DEFAULT 10,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  email_verified BOOLEAN DEFAULT FALSE
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);

-- =====================================================
-- 2. ATHLETE_COACH_RELATIONSHIPS TABLE
-- Manages connections between athletes and coaches
-- =====================================================
CREATE TABLE IF NOT EXISTS public.athlete_coach_relationships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  coach_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive', 'rejected')),
  invitation_code TEXT UNIQUE,
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  ended_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure athlete and coach are different users
  CONSTRAINT different_users CHECK (athlete_id != coach_id),
  -- Prevent duplicate relationships
  CONSTRAINT unique_athlete_coach UNIQUE (athlete_id, coach_id)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_relationships_athlete ON public.athlete_coach_relationships(athlete_id);
CREATE INDEX IF NOT EXISTS idx_relationships_coach ON public.athlete_coach_relationships(coach_id);
CREATE INDEX IF NOT EXISTS idx_relationships_status ON public.athlete_coach_relationships(status);
CREATE INDEX IF NOT EXISTS idx_relationships_invitation_code ON public.athlete_coach_relationships(invitation_code);

-- =====================================================
-- 3. AIFRI ASSESSMENTS TABLE
-- Stores AIFRI (AI-Fitness Risk Index) assessment results
-- =====================================================
CREATE TABLE IF NOT EXISTS public.aifri_assessments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Assessment scores (0-100 scale)
  total_score INTEGER NOT NULL CHECK (total_score >= 0 AND total_score <= 1000),
  mobility_score INTEGER CHECK (mobility_score >= 0 AND mobility_score <= 100),
  strength_score INTEGER CHECK (strength_score >= 0 AND strength_score <= 100),
  endurance_score INTEGER CHECK (endurance_score >= 0 AND endurance_score <= 100),
  flexibility_score INTEGER CHECK (flexibility_score >= 0 AND flexibility_score <= 100),
  balance_score INTEGER CHECK (balance_score >= 0 AND balance_score <= 100),
  
  -- Assessment details
  assessment_type TEXT DEFAULT 'full' CHECK (assessment_type IN ('full', 'quick', 'follow_up')),
  assessment_data JSONB, -- Store detailed responses
  recommendations TEXT[],
  risk_factors TEXT[],
  
  -- Metadata
  assessed_by UUID REFERENCES public.profiles(id), -- Coach who conducted assessment
  assessment_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_aifri_athlete ON public.aifri_assessments(athlete_id);
CREATE INDEX IF NOT EXISTS idx_aifri_date ON public.aifri_assessments(assessment_date DESC);
CREATE INDEX IF NOT EXISTS idx_aifri_score ON public.aifri_assessments(total_score DESC);

-- =====================================================
-- 4. WORKOUTS TABLE
-- Enhanced workout tracking with coach assignment
-- =====================================================
CREATE TABLE IF NOT EXISTS public.workouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  coach_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- Workout details
  workout_type TEXT NOT NULL CHECK (workout_type IN ('run', 'walk', 'cycle', 'strength', 'yoga', 'other')),
  title TEXT,
  description TEXT,
  
  -- Performance metrics
  distance_km DECIMAL(10, 2),
  duration_minutes INTEGER,
  avg_pace_min_per_km DECIMAL(5, 2),
  avg_heart_rate INTEGER,
  max_heart_rate INTEGER,
  calories_burned INTEGER,
  elevation_gain_m INTEGER,
  
  -- RPE and subjective data
  rpe_score INTEGER CHECK (rpe_score >= 1 AND rpe_score <= 10),
  perceived_effort TEXT,
  mood TEXT CHECK (mood IN ('great', 'good', 'okay', 'tired', 'exhausted')),
  
  -- GPS data
  route_data JSONB, -- Store GPS coordinates
  weather_conditions TEXT,
  temperature_celsius DECIMAL(4, 1),
  
  -- Metadata
  workout_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_planned BOOLEAN DEFAULT FALSE, -- True if coach-assigned
  is_completed BOOLEAN DEFAULT TRUE,
  
  -- Device sync
  synced_from TEXT, -- 'manual', 'garmin', 'strava', 'fitbit'
  external_id TEXT,
  sync_timestamp TIMESTAMP WITH TIME ZONE
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_workouts_athlete ON public.workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workouts_coach ON public.workouts(coach_id);
CREATE INDEX IF NOT EXISTS idx_workouts_date ON public.workouts(workout_date DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_type ON public.workouts(workout_type);
CREATE INDEX IF NOT EXISTS idx_workouts_synced ON public.workouts(synced_from);

-- =====================================================
-- 5. TRAINING PLANS TABLE
-- Coach-created training plans for athletes
-- =====================================================
CREATE TABLE IF NOT EXISTS public.training_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  coach_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  title TEXT NOT NULL,
  description TEXT,
  goal TEXT, -- 'Complete 5K', 'Sub-4 Marathon', etc.
  
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  plan_data JSONB, -- Weekly workout structure
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_training_plans_athlete ON public.training_plans(athlete_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_coach ON public.training_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_status ON public.training_plans(status);

-- =====================================================
-- 6. DEVICES TABLE
-- Track connected wearables and devices
-- =====================================================
CREATE TABLE IF NOT EXISTS public.devices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  device_type TEXT NOT NULL CHECK (device_type IN ('garmin', 'strava', 'fitbit', 'apple_watch', 'other')),
  device_name TEXT,
  device_model TEXT,
  
  -- OAuth/API tokens (encrypted in production!)
  access_token TEXT,
  refresh_token TEXT,
  token_expiry TIMESTAMP WITH TIME ZONE,
  
  is_active BOOLEAN DEFAULT TRUE,
  last_sync_at TIMESTAMP WITH TIME ZONE,
  sync_frequency_hours INTEGER DEFAULT 24,
  
  connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_devices_athlete ON public.devices(athlete_id);
CREATE INDEX IF NOT EXISTS idx_devices_type ON public.devices(device_type);
CREATE INDEX IF NOT EXISTS idx_devices_active ON public.devices(is_active);

-- =====================================================
-- 7. NOTIFICATIONS TABLE
-- In-app notifications system
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  type TEXT NOT NULL CHECK (type IN ('workout_assigned', 'coach_message', 'aifri_reminder', 'achievement', 'system')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  action_url TEXT,
  
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.athlete_coach_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aifri_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES POLICIES
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (for signup)
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Coaches can view their athletes' profiles
CREATE POLICY "Coaches can view athletes profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = public.profiles.id
      AND status = 'active'
    )
  );

-- Athletes can view their coaches' profiles
CREATE POLICY "Athletes can view coaches profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships
      WHERE athlete_id = auth.uid()
      AND coach_id = public.profiles.id
      AND status = 'active'
    )
  );

-- =====================================================
-- ATHLETE_COACH_RELATIONSHIPS POLICIES
-- =====================================================

-- Athletes can view their own relationships
CREATE POLICY "Athletes view own relationships" ON public.athlete_coach_relationships
  FOR SELECT USING (athlete_id = auth.uid());

-- Coaches can view their own relationships
CREATE POLICY "Coaches view own relationships" ON public.athlete_coach_relationships
  FOR SELECT USING (coach_id = auth.uid());

-- Coaches can create relationships (invitations)
CREATE POLICY "Coaches create relationships" ON public.athlete_coach_relationships
  FOR INSERT WITH CHECK (coach_id = auth.uid());

-- Athletes can accept/reject invitations (update status)
CREATE POLICY "Athletes update relationships" ON public.athlete_coach_relationships
  FOR UPDATE USING (athlete_id = auth.uid());

-- =====================================================
-- WORKOUTS POLICIES
-- =====================================================

-- Athletes can view their own workouts
CREATE POLICY "Athletes view own workouts" ON public.workouts
  FOR SELECT USING (athlete_id = auth.uid());

-- Coaches can view their athletes' workouts
CREATE POLICY "Coaches view athletes workouts" ON public.workouts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = public.workouts.athlete_id
      AND status = 'active'
    )
  );

-- Athletes can insert their own workouts
CREATE POLICY "Athletes insert own workouts" ON public.workouts
  FOR INSERT WITH CHECK (athlete_id = auth.uid());

-- Athletes can update their own workouts
CREATE POLICY "Athletes update own workouts" ON public.workouts
  FOR UPDATE USING (athlete_id = auth.uid());

-- Coaches can insert workouts for their athletes
CREATE POLICY "Coaches insert athletes workouts" ON public.workouts
  FOR INSERT WITH CHECK (
    coach_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = public.workouts.athlete_id
      AND status = 'active'
    )
  );

-- =====================================================
-- AIFRI ASSESSMENTS POLICIES
-- =====================================================

-- Athletes can view their own assessments
CREATE POLICY "Athletes view own assessments" ON public.aifri_assessments
  FOR SELECT USING (athlete_id = auth.uid());

-- Coaches can view their athletes' assessments
CREATE POLICY "Coaches view athletes assessments" ON public.aifri_assessments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = public.aifri_assessments.athlete_id
      AND status = 'active'
    )
  );

-- Coaches can insert assessments for their athletes
CREATE POLICY "Coaches insert assessments" ON public.aifri_assessments
  FOR INSERT WITH CHECK (
    assessed_by = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.athlete_coach_relationships
      WHERE coach_id = auth.uid()
      AND athlete_id = public.aifri_assessments.athlete_id
      AND status = 'active'
    )
  );

-- =====================================================
-- DEVICES POLICIES
-- =====================================================

-- Athletes can manage their own devices
CREATE POLICY "Athletes manage own devices" ON public.devices
  FOR ALL USING (athlete_id = auth.uid());

-- =====================================================
-- NOTIFICATIONS POLICIES
-- =====================================================

-- Users can view and update their own notifications
CREATE POLICY "Users manage own notifications" ON public.notifications
  FOR ALL USING (user_id = auth.uid());

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_relationships_updated_at BEFORE UPDATE ON public.athlete_coach_relationships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON public.workouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_training_plans_updated_at BEFORE UPDATE ON public.training_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON public.devices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'athlete'),
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile when user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Generate random invitation code for coaches
CREATE OR REPLACE FUNCTION generate_invitation_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
BEGIN
  code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
  RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Calculate AIFRI score from components
CREATE OR REPLACE FUNCTION calculate_aifri_total(
  mobility INT,
  strength INT,
  endurance INT,
  flexibility INT,
  balance INT
)
RETURNS INT AS $$
BEGIN
  RETURN (mobility * 2) + (strength * 2) + (endurance * 3) + (flexibility * 2) + balance;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SAMPLE DATA (for testing)
-- =====================================================

-- Uncomment to insert test data:
-- INSERT INTO public.profiles (id, email, full_name, role, current_aifri_score, fitness_level)
-- VALUES (
--   gen_random_uuid(),
--   'test.athlete@example.com',
--   'Test Athlete',
--   'athlete',
--   335,
--   'intermediate'
-- );

-- =====================================================
-- END OF SCHEMA
-- =====================================================
