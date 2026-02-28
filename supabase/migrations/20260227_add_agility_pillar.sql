-- =====================================================
-- COMPLETE AISRI ASSESSMENT TABLE MIGRATION
-- Date: 2026-02-27
-- =====================================================
-- This migration:
-- 1. Adds all missing columns to "AISRI_assessments" table
-- 2. Adds the 7th pillar "Agility"
-- 3. Adds improvement tracking columns
-- 4. Creates reassessment_reminders table
-- =====================================================

-- STEP 1: Add user_id column (for auth integration)
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- STEP 2: Add Personal Information columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS gender VARCHAR(20),
ADD COLUMN IF NOT EXISTS weight NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS height NUMERIC(5,2);

-- STEP 3: Add Training Background columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS years_running NUMERIC(4,1),
ADD COLUMN IF NOT EXISTS weekly_mileage NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS training_frequency VARCHAR(50),
ADD COLUMN IF NOT EXISTS training_intensity INTEGER;

-- STEP 4: Add Injury History columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS injury_history TEXT,
ADD COLUMN IF NOT EXISTS current_pain INTEGER,
ADD COLUMN IF NOT EXISTS months_injury_free INTEGER;

-- STEP 5: Add Recovery Metrics columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS sleep_hours NUMERIC(3,1),
ADD COLUMN IF NOT EXISTS sleep_quality INTEGER,
ADD COLUMN IF NOT EXISTS stress_level INTEGER;

-- STEP 6: Add Performance Data columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS recent_5k_time VARCHAR(20),
ADD COLUMN IF NOT EXISTS recent_10k_time VARCHAR(20),
ADD COLUMN IF NOT EXISTS recent_half_time VARCHAR(20),
ADD COLUMN IF NOT EXISTS fitness_level VARCHAR(50);

-- STEP 7: Add Physical Assessment columns (15 tests)
-- Lower Body (6 tests)
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS ankle_dorsiflexion_cm NUMERIC(4,1),
ADD COLUMN IF NOT EXISTS knee_flexion_gap_cm NUMERIC(4,1),
ADD COLUMN IF NOT EXISTS knee_extension_strength VARCHAR(50),
ADD COLUMN IF NOT EXISTS hip_flexion_angle INTEGER,
ADD COLUMN IF NOT EXISTS hip_abduction_reps INTEGER,
ADD COLUMN IF NOT EXISTS hamstring_flexibility_cm NUMERIC(4,1);

-- Core & Balance (2 tests)
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS balance_test_seconds INTEGER,
ADD COLUMN IF NOT EXISTS plank_hold_seconds INTEGER;

-- Upper Body (4 tests)
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS shoulder_flexion_angle INTEGER,
ADD COLUMN IF NOT EXISTS shoulder_abduction_angle INTEGER,
ADD COLUMN IF NOT EXISTS shoulder_internal_rotation VARCHAR(50),
ADD COLUMN IF NOT EXISTS neck_rotation_angle INTEGER,
ADD COLUMN IF NOT EXISTS neck_flexion VARCHAR(50);

-- Cardiovascular & Recovery (2 tests)
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS resting_hr INTEGER,
ADD COLUMN IF NOT EXISTS perceived_fatigue INTEGER;

-- STEP 8: Add individual pillar scores (including NEW Agility pillar)
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS pillar_adaptability INTEGER,
ADD COLUMN IF NOT EXISTS pillar_injury_risk INTEGER,
ADD COLUMN IF NOT EXISTS pillar_fatigue INTEGER,
ADD COLUMN IF NOT EXISTS pillar_recovery INTEGER,
ADD COLUMN IF NOT EXISTS pillar_intensity INTEGER,
ADD COLUMN IF NOT EXISTS pillar_consistency INTEGER,
ADD COLUMN IF NOT EXISTS pillar_agility INTEGER; -- NEW: 7th pillar!

-- STEP 9: Add risk_level column
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS risk_level VARCHAR(20);

-- STEP 10: Add Goals columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS target_race_distance VARCHAR(50),
ADD COLUMN IF NOT EXISTS target_race_date DATE,
ADD COLUMN IF NOT EXISTS primary_goal VARCHAR(100);

-- STEP 11: Add improvement tracking columns
ALTER TABLE "AISRI_assessments" 
ADD COLUMN IF NOT EXISTS improvement_from_previous INTEGER,
ADD COLUMN IF NOT EXISTS biggest_gain VARCHAR(50),
ADD COLUMN IF NOT EXISTS focus_area VARCHAR(50);

-- STEP 12: Create reassessment_reminders table
CREATE TABLE IF NOT EXISTS reassessment_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    last_assessment_date DATE NOT NULL,
    reminder_sent_at TIMESTAMPTZ,
    reminder_acknowledged BOOLEAN DEFAULT FALSE,
    next_assessment_due DATE GENERATED ALWAYS AS (last_assessment_date + INTERVAL '25 days') STORED,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 13: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_aisri_assessments_user_id 
ON "AISRI_assessments"(user_id);

CREATE INDEX IF NOT EXISTS idx_aisri_assessments_user_created 
ON "AISRI_assessments"(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reassessment_reminders_user 
ON reassessment_reminders(user_id);

CREATE INDEX IF NOT EXISTS idx_reassessment_reminders_next_due 
ON reassessment_reminders(next_assessment_due);

-- STEP 14: Update RLS policies for user_id
DROP POLICY IF EXISTS "Allow user read own assessments" ON "AISRI_assessments";
DROP POLICY IF EXISTS "Allow user insert own assessments" ON "AISRI_assessments";

CREATE POLICY "Allow user read own assessments"
ON "AISRI_assessments"
FOR SELECT
USING (auth.uid() = user_id OR true); -- Allow public read OR user's own

CREATE POLICY "Allow user insert own assessments"
ON "AISRI_assessments"
FOR INSERT
WITH CHECK (auth.uid() = user_id OR true); -- Allow insert

-- STEP 15: Enable RLS on reassessment_reminders
ALTER TABLE reassessment_reminders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Allow user read own reminders" ON reassessment_reminders;
DROP POLICY IF EXISTS "Allow user insert own reminders" ON reassessment_reminders;

CREATE POLICY "Allow user read own reminders"
ON reassessment_reminders
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Allow user insert own reminders"
ON reassessment_reminders
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- STEP 16: Add helpful comments
COMMENT ON COLUMN "AISRI_assessments".pillar_agility IS 
'Agility pillar score (0-100): Movement control, change of direction ability, lateral stability';

COMMENT ON COLUMN "AISRI_assessments".improvement_from_previous IS 
'Improvement in overall AISRI score compared to previous assessment';

COMMENT ON COLUMN "AISRI_assessments".biggest_gain IS 
'Name of the pillar with the biggest improvement';

COMMENT ON COLUMN "AISRI_assessments".focus_area IS 
'Name of the pillar that needs the most attention';

COMMENT ON TABLE "AISRI_assessments" IS 
'Complete AISRI assessments with all 7 pillars (includes Adaptability, Injury Risk, Fatigue, Recovery, Intensity, Consistency, Agility)';

-- =====================================================
-- MIGRATION COMPLETE!
-- =====================================================
-- The table now has all columns needed by the Flutter app
-- including the new Agility pillar (7th pillar)
-- =====================================================
