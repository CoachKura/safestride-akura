-- Create AI decisions table for autonomous coaching decisions

CREATE TABLE IF NOT EXISTS ai_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    decision TEXT,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_ai_decisions_athlete ON ai_decisions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_ai_decisions_created ON ai_decisions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_decisions_athlete_created ON ai_decisions(athlete_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE ai_decisions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read decisions" ON ai_decisions;
DROP POLICY IF EXISTS "Allow service role insert decisions" ON ai_decisions;

-- Create RLS policies
CREATE POLICY "Allow public read decisions"
ON ai_decisions
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert decisions"
ON ai_decisions
FOR INSERT
WITH CHECK (true);

-- Add helpful comment
COMMENT ON TABLE ai_decisions IS 'Stores daily autonomous coaching decisions for athletes';
