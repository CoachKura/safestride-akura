-- Create workouts table for storing training data

CREATE TABLE IF NOT EXISTS workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    workout_type TEXT,
    distance NUMERIC(10,2),
    duration_minutes INT,
    average_pace NUMERIC(10,2),
    average_heart_rate INT,
    calories INT,
    elevation_gain NUMERIC(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_workouts_athlete ON workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workouts_created ON workouts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_athlete_created ON workouts(athlete_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read workouts" ON workouts;
DROP POLICY IF EXISTS "Allow service role insert workouts" ON workouts;
DROP POLICY IF EXISTS "Allow athletes update own workouts" ON workouts;

-- Create RLS policies
CREATE POLICY "Allow public read workouts"
ON workouts
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert workouts"
ON workouts
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow athletes update own workouts"
ON workouts
FOR UPDATE
USING (true)
WITH CHECK (true);

-- Add helpful comment
COMMENT ON TABLE workouts IS 'Stores workout data including pace, distance, and heart rate metrics';
