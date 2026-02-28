-- Create training_plans table for storing generated 12-week training programs
-- This table stores AI-generated training plans from the web interface

CREATE TABLE IF NOT EXISTS training_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    athlete_id TEXT,
    athlete_name TEXT NOT NULL,
    aisri_score NUMERIC NOT NULL,
    risk_category TEXT NOT NULL,
    training_phase TEXT NOT NULL,
    allowed_zones TEXT[] NOT NULL,
    pillar_scores JSONB NOT NULL,
    training_plan JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_training_plans_user_id ON training_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_athlete_id ON training_plans(athlete_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_created_at ON training_plans(created_at DESC);

-- Enable Row Level Security
ALTER TABLE training_plans ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own training plans
DROP POLICY IF EXISTS "Users can view their own training plans" ON training_plans;
CREATE POLICY "Users can view their own training plans"
    ON training_plans FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

-- Create policy to allow users to insert their own training plans
DROP POLICY IF EXISTS "Users can create training plans" ON training_plans;
CREATE POLICY "Users can create training plans"
    ON training_plans FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Create policy to allow users to update their own training plans
DROP POLICY IF EXISTS "Users can update their own training plans" ON training_plans;
CREATE POLICY "Users can update their own training plans"
    ON training_plans FOR UPDATE
    USING (auth.uid() = user_id OR user_id IS NULL);

-- Create policy to allow users to delete their own training plans
DROP POLICY IF EXISTS "Users can delete their own training plans" ON training_plans;
CREATE POLICY "Users can delete their own training plans"
    ON training_plans FOR DELETE
    USING (auth.uid() = user_id OR user_id IS NULL);

-- Add comment
COMMENT ON TABLE training_plans IS 'Stores AI-generated 12-week training programs from the web interface';
