-- Create race predictions table for storing performance predictions

CREATE TABLE IF NOT EXISTS race_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    vo2max NUMERIC(5,1) NOT NULL,
    predicted_5k TEXT NOT NULL,
    predicted_10k TEXT NOT NULL,
    predicted_half_marathon TEXT NOT NULL,
    predicted_marathon TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster athlete queries
CREATE INDEX IF NOT EXISTS idx_race_predictions_athlete ON race_predictions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_race_predictions_created ON race_predictions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE race_predictions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read race predictions" ON race_predictions;
DROP POLICY IF EXISTS "Allow service role insert race predictions" ON race_predictions;

-- Create RLS policies
CREATE POLICY "Allow public read race predictions"
ON race_predictions
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert race predictions"
ON race_predictions
FOR INSERT
WITH CHECK (true);

-- Add helpful comment
COMMENT ON TABLE race_predictions IS 'Stores AI-predicted race times based on workout pace and AISRI scores';
