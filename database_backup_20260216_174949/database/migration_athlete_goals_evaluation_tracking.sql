-- Add evaluation tracking columns to athlete_goals table
-- This migration supports training protocol generation from AISRI evaluations
-- Created: 2026-02-10

-- Check if columns exist before adding
DO $$ 
BEGIN
    -- Add generated_from_evaluation column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'generated_from_evaluation'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN generated_from_evaluation BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add evaluation_date column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'evaluation_date'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN evaluation_date TIMESTAMPTZ;
    END IF;

    -- Add AISRI_score column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'AISRI_score'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN AISRI_score DECIMAL(5,2);
    END IF;

    -- Add fitness_level column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'fitness_level'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN fitness_level TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced'));
    END IF;

    -- Add injury_risk column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'injury_risk'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN injury_risk TEXT CHECK (injury_risk IN ('low', 'moderate', 'high'));
    END IF;

    -- Add recommended_weekly_frequency column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'recommended_weekly_frequency'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN recommended_weekly_frequency INTEGER CHECK (recommended_weekly_frequency BETWEEN 3 AND 6);
    END IF;

    -- Add recommended_weekly_volume column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'recommended_weekly_volume'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN recommended_weekly_volume DECIMAL(6,2);
    END IF;

    -- Add focus_areas column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'focus_areas'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN focus_areas TEXT[];
    END IF;

    -- Add protocol_duration_weeks column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' 
        AND column_name = 'protocol_duration_weeks'
    ) THEN
        ALTER TABLE athlete_goals 
        ADD COLUMN protocol_duration_weeks INTEGER CHECK (protocol_duration_weeks BETWEEN 8 AND 20);
    END IF;
END $$;

-- Create index for querying evaluation-generated goals
CREATE INDEX IF NOT EXISTS idx_athlete_goals_evaluation 
ON athlete_goals(user_id, generated_from_evaluation) 
WHERE generated_from_evaluation = TRUE;

-- Add comments for documentation
COMMENT ON COLUMN athlete_goals.generated_from_evaluation IS 'TRUE if this goal was automatically generated from AISRI evaluation';
COMMENT ON COLUMN athlete_goals.evaluation_date IS 'Date when the AISRI evaluation was completed';
COMMENT ON COLUMN athlete_goals.AISRI_score IS 'AISRI score (0-100) from the evaluation';
COMMENT ON COLUMN athlete_goals.fitness_level IS 'Classified fitness level: beginner, intermediate, or advanced';
COMMENT ON COLUMN athlete_goals.injury_risk IS 'Assessed injury risk level: low, moderate, or high';
COMMENT ON COLUMN athlete_goals.recommended_weekly_frequency IS 'Recommended training days per week (3-6)';
COMMENT ON COLUMN athlete_goals.recommended_weekly_volume IS 'Recommended weekly running volume in kilometers';
COMMENT ON COLUMN athlete_goals.focus_areas IS 'Weak areas identified from AISRI pillar scores that need focus';
COMMENT ON COLUMN athlete_goals.protocol_duration_weeks IS 'Duration of the training protocol in weeks (8-20)';
