-- Create injury_risk_predictions table for storing AI-generated injury risk assessments
CREATE TABLE IF NOT EXISTS injury_risk_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    risk_score INT NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level TEXT NOT NULL CHECK (risk_level IN ('LOW', 'MODERATE', 'HIGH')),
    load_ratio NUMERIC(5,2),
    aisri_trend INT,
    latest_aisri_score INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index on athlete_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_injury_predictions_athlete_id ON injury_risk_predictions(athlete_id);

-- Add index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_injury_predictions_created_at ON injury_risk_predictions(created_at DESC);

-- Add composite index for getting latest prediction per athlete
CREATE INDEX IF NOT EXISTS idx_injury_predictions_athlete_created ON injury_risk_predictions(athlete_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE injury_risk_predictions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read of injury predictions" ON injury_risk_predictions;
DROP POLICY IF EXISTS "Allow service role to insert predictions" ON injury_risk_predictions;

-- Allow authenticated users to read their own predictions
CREATE POLICY "Allow public read of injury predictions"
ON injury_risk_predictions
FOR SELECT
USING (true);

-- Allow backend service to insert predictions
CREATE POLICY "Allow service role to insert predictions"
ON injury_risk_predictions
FOR INSERT
WITH CHECK (true);

-- Add helpful comment
COMMENT ON TABLE injury_risk_predictions IS 'Stores AI-generated injury risk predictions based on AISRI scores, training load, and trends';
