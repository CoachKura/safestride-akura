-- SafeStride Athlete Calendar System
-- Schema for workout scheduling and tracking

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Athlete Profiles Table
-- Links auth.users to athlete-specific data
CREATE TABLE IF NOT EXISTS athlete_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workouts Template Table
-- Stores reusable workout templates
CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL CHECK (workout_type IN ('rehab', 'strength', 'mobility', 'cardio', 'balance', 'recovery', 'rest')),
  exercises JSONB NOT NULL,
  estimated_duration_minutes INT NOT NULL CHECK (estimated_duration_minutes > 0),
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'moderate', 'hard')),
  equipment_needed TEXT[] DEFAULT ARRAY[]::TEXT[],
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Athlete Calendar Table
-- Schedules workouts for specific athletes
CREATE TABLE IF NOT EXISTS athlete_calendar (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(id) ON DELETE CASCADE NOT NULL,
  workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE NOT NULL,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped', 'rescheduled')),
  completed_at TIMESTAMP WITH TIME ZONE,
  actual_duration_minutes INT CHECK (actual_duration_minutes > 0),
  difficulty_rating INT CHECK (difficulty_rating BETWEEN 1 AND 5),
  pain_level INT CHECK (pain_level BETWEEN 0 AND 10),
  athlete_notes TEXT,
  reminder_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_user_id ON athlete_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_id ON athlete_calendar(athlete_id);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_scheduled_date ON athlete_calendar(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_athlete_date ON athlete_calendar(athlete_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_athlete_calendar_status ON athlete_calendar(status);
CREATE INDEX IF NOT EXISTS idx_workouts_type ON workouts(workout_type);

-- Row Level Security (RLS) Policies

-- Enable RLS
ALTER TABLE athlete_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE athlete_calendar ENABLE ROW LEVEL SECURITY;

-- Athlete Profiles Policies
CREATE POLICY "Users can view their own profile"
  ON athlete_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
  ON athlete_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
  ON athlete_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Workouts Policies (Read-only for now, can be expanded later)
CREATE POLICY "Everyone can view workouts"
  ON workouts FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert workouts"
  ON workouts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Athlete Calendar Policies
CREATE POLICY "Users can view their own calendar"
  ON athlete_calendar FOR SELECT
  USING (
    athlete_id IN (
      SELECT id FROM athlete_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own calendar entries"
  ON athlete_calendar FOR INSERT
  WITH CHECK (
    athlete_id IN (
      SELECT id FROM athlete_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own calendar entries"
  ON athlete_calendar FOR UPDATE
  USING (
    athlete_id IN (
      SELECT id FROM athlete_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own calendar entries"
  ON athlete_calendar FOR DELETE
  USING (
    athlete_id IN (
      SELECT id FROM athlete_profiles WHERE user_id = auth.uid()
    )
  );

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_athlete_profiles_updated_at
  BEFORE UPDATE ON athlete_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at
  BEFORE UPDATE ON workouts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_athlete_calendar_updated_at
  BEFORE UPDATE ON athlete_calendar
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Sample Comments
COMMENT ON TABLE athlete_profiles IS 'Links auth users to athlete-specific data and settings';
COMMENT ON TABLE workouts IS 'Reusable workout templates with exercises stored as JSONB';
COMMENT ON TABLE athlete_calendar IS 'Scheduled workouts for athletes with completion tracking';
COMMENT ON COLUMN athlete_calendar.status IS 'Workflow status: pending, completed, skipped, rescheduled';
COMMENT ON COLUMN athlete_calendar.pain_level IS 'Self-reported pain level: 0 (no pain) to 10 (severe pain)';
COMMENT ON COLUMN athlete_calendar.difficulty_rating IS 'Athlete-reported difficulty: 1 (very easy) to 5 (very hard)';
