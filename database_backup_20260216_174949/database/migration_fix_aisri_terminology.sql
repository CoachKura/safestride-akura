-- Migration: Correct AIFRI to AISRI terminology
-- Date: 2026-02-10
-- Description: Rename tables, columns, and update JSONB content to use correct AISRI terminology

-- ============================================
-- BACKUP REMINDER
-- ============================================
-- Before running this migration, ensure you have a database backup!

BEGIN;

-- ============================================
-- 1. RENAME TABLES
-- ============================================

-- Rename assessments table
ALTER TABLE IF EXISTS aifri_assessments 
    RENAME TO aisri_assessments;

COMMENT ON TABLE aisri_assessments IS 'AISRI (AI-powered Sports Running Intelligence) assessment results and history';

-- ============================================
-- 2. RENAME COLUMNS IN athlete_goals
-- ============================================

DO $$ 
BEGIN
    -- aifri_score → aisri_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' AND column_name = 'aifri_score'
    ) THEN
        ALTER TABLE athlete_goals 
            RENAME COLUMN aifri_score TO aisri_score;
        
        COMMENT ON COLUMN athlete_goals.aisri_score IS 'AISRI (AI-powered Sports Running Intelligence) assessment score (0-100)';
    END IF;
END $$;

-- ============================================
-- 3. RENAME COLUMNS IN aisri_assessments
-- ============================================

DO $$ 
BEGIN
    -- aifri_score → aisri_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'aisri_assessments' AND column_name = 'aifri_score'
    ) THEN
        ALTER TABLE aisri_assessments
            RENAME COLUMN aifri_score TO aisri_score;
    END IF;
END $$;

-- ============================================
-- 4. RENAME COLUMNS IN athlete_calendar
-- ============================================

DO $$ 
BEGIN
    -- aifri_zone → aisri_zone
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_calendar' AND column_name = 'aifri_zone'
    ) THEN
        ALTER TABLE athlete_calendar
            RENAME COLUMN aifri_zone TO aisri_zone;
        
        COMMENT ON COLUMN athlete_calendar.aisri_zone IS 'AISRI training zone (AR, F, EN, TH, P, SP)';
    END IF;
END $$;

-- ============================================
-- 5. UPDATE JSONB CONTENT IN structured_workouts
-- ============================================

-- Update steps JSONB to replace aifriZone with aisriZone
UPDATE structured_workouts
SET steps = (
    SELECT jsonb_agg(
        CASE 
            WHEN step ? 'aifriZone' THEN
                (step - 'aifriZone') || jsonb_build_object('aisriZone', step->>'aifriZone')
            ELSE
                step
        END
    )
    FROM jsonb_array_elements(steps) AS step
)
WHERE steps::text LIKE '%aifriZone%';

-- ============================================
-- 6. UPDATE INDEXES
-- ============================================

-- Drop old indexes
DROP INDEX IF EXISTS idx_athlete_goals_aifri_score;
DROP INDEX IF EXISTS idx_assessments_aifri_score;
DROP INDEX IF EXISTS idx_athlete_calendar_aifri_zone;

-- Create new indexes (only if columns exist)
DO $$ 
BEGIN
    -- Index for athlete_goals.aisri_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_goals' AND column_name = 'aisri_score'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_athlete_goals_aisri_score 
            ON athlete_goals(aisri_score) 
            WHERE aisri_score IS NOT NULL;
    END IF;

    -- Index for aisri_assessments.aisri_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'aisri_assessments' AND column_name = 'aisri_score'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_assessments_aisri_score 
            ON aisri_assessments(aisri_score) 
            WHERE aisri_score IS NOT NULL;
    END IF;

    -- Index for athlete_calendar.aisri_zone (only if column exists)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_calendar' AND column_name = 'aisri_zone'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_athlete_calendar_aisri_zone 
            ON athlete_calendar(aisri_zone) 
            WHERE aisri_zone IS NOT NULL;
    END IF;
END $$;

-- ============================================
-- 7. UPDATE CONSTRAINTS (if any exist)
-- ============================================

-- Note: This will depend on your specific constraints
-- Add any constraint updates here if needed

-- ============================================
-- 8. UPDATE RLS POLICIES (if they reference the old names)
-- ============================================

-- Recreate relevant RLS policies for aisri_assessments if needed
-- This assumes the policies are already correctly set up

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check renamed tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
    AND table_name LIKE '%aisri%'
ORDER BY table_name;

-- Check renamed columns
SELECT 
    table_name, 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public'
    AND column_name LIKE '%aisri%'
ORDER BY table_name, column_name;

-- Check indexes
SELECT 
    indexname,
    tablename
FROM pg_indexes 
WHERE schemaname = 'public'
    AND indexname LIKE '%aisri%'
ORDER BY tablename, indexname;

-- Verify JSONB updates (sample)
SELECT 
    id,
    workout_name,
    steps
FROM structured_workouts
WHERE steps::text LIKE '%aisriZone%'
LIMIT 5;

-- Expected results:
-- ✓ Table: aisri_assessments exists
-- ✓ Columns: aisri_score, aisri_zone exist
-- ✓ Indexes: idx_*_aisri_* exist
-- ✓ JSONB contains 'aisriZone' not 'aifriZone'

-- ============================================
-- ROLLBACK SCRIPT (if needed)
-- ============================================
-- 
-- If you need to rollback this migration:
-- 
-- BEGIN;
-- ALTER TABLE aisri_assessments RENAME TO aifri_assessments;
-- ALTER TABLE athlete_goals RENAME COLUMN aisri_score TO aifri_score;
-- ALTER TABLE aisri_assessments RENAME COLUMN aisri_score TO aifri_score;
-- ALTER TABLE athlete_calendar RENAME COLUMN aisri_zone TO aifri_zone;
-- -- (Update JSONB back)
-- -- (Recreate old indexes)
-- COMMIT;
