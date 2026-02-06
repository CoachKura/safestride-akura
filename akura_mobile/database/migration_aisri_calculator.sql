-- Migration: Add AISRI Score Calculation Columns
-- Date: 2026-02-03
-- Purpose: Add columns to store calculated AISRI score, risk level, and pillar scores

-- Add aifri_score column (0-100 integer)
ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS aifri_score INTEGER DEFAULT 0 CHECK (aifri_score >= 0 AND aifri_score <= 100);

-- Add calculated risk level (Low, Moderate, High)
ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT 'Unknown' CHECK (risk_level IN ('Low', 'Moderate', 'High', 'Unknown'));

-- Add timestamp for when score was calculated
ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS score_calculated_at TIMESTAMP WITH TIME ZONE;

-- Add individual pillar scores (each 0-100)
ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS pillar_adaptability INTEGER DEFAULT 0 CHECK (pillar_adaptability >= 0 AND pillar_adaptability <= 100);

ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS pillar_injury_risk INTEGER DEFAULT 0 CHECK (pillar_injury_risk >= 0 AND pillar_injury_risk <= 100);

ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS pillar_fatigue INTEGER DEFAULT 0 CHECK (pillar_fatigue >= 0 AND pillar_fatigue <= 100);

ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS pillar_recovery INTEGER DEFAULT 0 CHECK (pillar_recovery >= 0 AND pillar_recovery <= 100);

ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS pillar_intensity INTEGER DEFAULT 0 CHECK (pillar_intensity >= 0 AND pillar_intensity <= 100);

ALTER TABLE aifri_assessments 
ADD COLUMN IF NOT EXISTS pillar_consistency INTEGER DEFAULT 0 CHECK (pillar_consistency >= 0 AND pillar_consistency <= 100);

-- Create index on aifri_score for faster queries
CREATE INDEX IF NOT EXISTS idx_aifri_assessments_score ON aifri_assessments(aifri_score DESC);

-- Create index on risk_level for filtering
CREATE INDEX IF NOT EXISTS idx_aifri_assessments_risk_level ON aifri_assessments(risk_level);

-- Comments
COMMENT ON COLUMN aifri_assessments.aifri_score IS 'Overall AISRI score calculated from 6 pillars (0-100)';
COMMENT ON COLUMN aifri_assessments.risk_level IS 'Risk level: Low (80+), Moderate (60-79), High (<60)';
COMMENT ON COLUMN aifri_assessments.score_calculated_at IS 'Timestamp when AISRI score was calculated';
COMMENT ON COLUMN aifri_assessments.pillar_adaptability IS 'Adaptability pillar score based on years_running and training_frequency';
COMMENT ON COLUMN aifri_assessments.pillar_injury_risk IS 'Injury risk pillar score based on injury_history and current_pain';
COMMENT ON COLUMN aifri_assessments.pillar_fatigue IS 'Fatigue pillar score based on training_intensity and weekly_mileage';
COMMENT ON COLUMN aifri_assessments.pillar_recovery IS 'Recovery pillar score based on sleep and stress metrics';
COMMENT ON COLUMN aifri_assessments.pillar_intensity IS 'Intensity pillar score based on training_intensity and fitness_level';
COMMENT ON COLUMN aifri_assessments.pillar_consistency IS 'Consistency pillar score based on training_frequency';
