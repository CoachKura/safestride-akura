-- Create AISRI_assessments table for tracking AISRI score history
CREATE TABLE IF NOT EXISTS "AISRI_assessments" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    aisri_score INT NOT NULL CHECK (aisri_score >= 0 AND aisri_score <= 1000),
    pillars JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create training_load_metrics table for tracking training load
CREATE TABLE IF NOT EXISTS training_load_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    load_score NUMERIC(10,2) NOT NULL,
    activity_type TEXT,
    duration_minutes INT,
    distance_km NUMERIC(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_aisri_assessments_athlete_id ON "AISRI_assessments"(athlete_id);
CREATE INDEX IF NOT EXISTS idx_aisri_assessments_created_at ON "AISRI_assessments"(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_training_load_athlete_id ON training_load_metrics(athlete_id);
CREATE INDEX IF NOT EXISTS idx_training_load_created_at ON training_load_metrics(created_at DESC);

-- Enable RLS
ALTER TABLE "AISRI_assessments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_load_metrics ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public read AISRI" ON "AISRI_assessments";
DROP POLICY IF EXISTS "Allow insert AISRI" ON "AISRI_assessments";
DROP POLICY IF EXISTS "Allow public read training load" ON training_load_metrics;
DROP POLICY IF EXISTS "Allow insert training load" ON training_load_metrics;

-- Create policies
CREATE POLICY "Allow public read AISRI"
ON "AISRI_assessments"
FOR SELECT
USING (true);

CREATE POLICY "Allow insert AISRI"
ON "AISRI_assessments"
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow public read training load"
ON training_load_metrics
FOR SELECT
USING (true);

CREATE POLICY "Allow insert training load"
ON training_load_metrics
FOR INSERT
WITH CHECK (true);

-- Add comments
COMMENT ON TABLE "AISRI_assessments" IS 'Historical AISRI scores for injury risk tracking';
COMMENT ON TABLE training_load_metrics IS 'Training load metrics for acute/chronic workload ratio calculation';
