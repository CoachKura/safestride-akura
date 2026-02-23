-- Create adaptive training plan database tables

-- Table for storing AI-generated workout plans
CREATE TABLE IF NOT EXISTS ai_workout_plans (
    id UUID PRIMARY KEY,
    athlete_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for storing individual workout templates
CREATE TABLE IF NOT EXISTS ai_workouts (
    id UUID PRIMARY KEY,
    athlete_id TEXT NOT NULL,
    name TEXT NOT NULL,
    duration_minutes INT NOT NULL,
    zone TEXT NOT NULL CHECK (zone IN ('AR', 'F', 'EN', 'TH', 'P', 'REST')),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for assigning workouts to specific dates in a plan
CREATE TABLE IF NOT EXISTS workout_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    workout_id UUID REFERENCES ai_workouts(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES ai_workout_plans(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    completed_date TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL CHECK (status IN ('scheduled', 'completed', 'skipped', 'modified')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_ai_workout_plans_athlete ON ai_workout_plans(athlete_id);
CREATE INDEX IF NOT EXISTS idx_ai_workout_plans_created ON ai_workout_plans(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_workouts_athlete ON ai_workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workout_assignments_athlete ON workout_assignments(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workout_assignments_plan ON workout_assignments(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_assignments_date ON workout_assignments(scheduled_date);

-- Enable Row Level Security
ALTER TABLE ai_workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_assignments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read workout plans" ON ai_workout_plans;
DROP POLICY IF EXISTS "Allow service role insert workout plans" ON ai_workout_plans;
DROP POLICY IF EXISTS "Allow public read workouts" ON ai_workouts;
DROP POLICY IF EXISTS "Allow service role insert workouts" ON ai_workouts;
DROP POLICY IF EXISTS "Allow public read assignments" ON workout_assignments;
DROP POLICY IF EXISTS "Allow service role insert assignments" ON workout_assignments;
DROP POLICY IF EXISTS "Allow athletes update assignments" ON workout_assignments;

-- Create RLS policies for ai_workout_plans
CREATE POLICY "Allow public read workout plans"
ON ai_workout_plans
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert workout plans"
ON ai_workout_plans
FOR INSERT
WITH CHECK (true);

-- Create RLS policies for ai_workouts
CREATE POLICY "Allow public read workouts"
ON ai_workouts
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert workouts"
ON ai_workouts
FOR INSERT
WITH CHECK (true);

-- Create RLS policies for workout_assignments
CREATE POLICY "Allow public read assignments"
ON workout_assignments
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert assignments"
ON workout_assignments
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow athletes update assignments"
ON workout_assignments
FOR UPDATE
USING (true)
WITH CHECK (true);

-- Add helpful comments
COMMENT ON TABLE ai_workout_plans IS 'Stores AI-generated adaptive training plans for athletes';
COMMENT ON TABLE ai_workouts IS 'Individual workout templates with zones and durations';
COMMENT ON TABLE workout_assignments IS 'Assigns workouts to specific dates in training plans';

COMMENT ON COLUMN ai_workouts.zone IS 'Training zone: AR=Active Recovery, F=Foundation, EN=Endurance, TH=Threshold, P=Power, REST=Rest Day';
