-- Migration: Add AISRI Assessments Table and Update Profiles
-- Description: Creates table for athlete evaluation form data and adds current_AISRI_score to profiles
-- Date: February 3, 2026

-- ============================================
-- 1. Create AISRI_assessments table
-- ============================================
CREATE TABLE IF NOT EXISTS public.AISRI_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Step 1: Personal Information
    age INTEGER NOT NULL CHECK (age >= 13 AND age <= 100),
    gender VARCHAR(50) NOT NULL,
    weight DECIMAL(5, 2) NOT NULL CHECK (weight >= 30 AND weight <= 200),
    height DECIMAL(5, 2) NOT NULL CHECK (height >= 120 AND height <= 250),
    
    -- Step 2: Training Background
    years_running DECIMAL(4, 2) NOT NULL CHECK (years_running >= 0 AND years_running <= 50),
    weekly_mileage DECIMAL(6, 2) NOT NULL CHECK (weekly_mileage >= 0),
    training_frequency VARCHAR(50) NOT NULL,
    training_intensity INTEGER NOT NULL CHECK (training_intensity >= 1 AND training_intensity <= 10),
    
    -- Step 3: Injury History
    injury_history TEXT,
    current_pain INTEGER NOT NULL CHECK (current_pain >= 0 AND current_pain <= 10),
    months_injury_free INTEGER NOT NULL CHECK (months_injury_free >= 0 AND months_injury_free <= 120),
    
    -- Step 4: Recovery Metrics
    sleep_hours DECIMAL(3, 1) NOT NULL CHECK (sleep_hours >= 4 AND sleep_hours <= 12),
    sleep_quality INTEGER NOT NULL CHECK (sleep_quality >= 1 AND sleep_quality <= 10),
    stress_level INTEGER NOT NULL CHECK (stress_level >= 1 AND stress_level <= 10),
    
    -- Step 5: Performance Data
    recent_5k_time VARCHAR(20) NOT NULL,
    recent_10k_time VARCHAR(20),
    recent_half_time VARCHAR(20),
    fitness_level VARCHAR(50) NOT NULL,
    
    -- Step 6: Goals
    target_race_distance VARCHAR(50) NOT NULL,
    target_race_date TIMESTAMP NOT NULL,
    primary_goal VARCHAR(100) NOT NULL,
    
    -- AISRI 6-Pillar Scores (0-100 each)
    mobility DECIMAL(5, 2) DEFAULT 75.0,
    strength DECIMAL(5, 2) DEFAULT 75.0,
    endurance DECIMAL(5, 2) DEFAULT 75.0,
    flexibility DECIMAL(5, 2) DEFAULT 75.0,
    balance DECIMAL(5, 2) DEFAULT 75.0,
    total_score DECIMAL(5, 2) NOT NULL DEFAULT 75.0 CHECK (total_score >= 0 AND total_score <= 100),
    
    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Ensure one assessment per user (or allow multiple with unique constraint on created_at)
    UNIQUE(user_id, created_at)
);

-- Add index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_AISRI_assessments_user_id ON public.AISRI_assessments(user_id);

-- Add index for filtering by creation date
CREATE INDEX IF NOT EXISTS idx_AISRI_assessments_created_at ON public.AISRI_assessments(created_at DESC);

-- ============================================
-- 2. Update profiles table to add current_AISRI_score
-- ============================================
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS current_AISRI_score DECIMAL(5, 2) DEFAULT NULL CHECK (current_AISRI_score IS NULL OR (current_AISRI_score >= 0 AND current_AISRI_score <= 100));

-- ============================================
-- 3. Enable Row Level Security (RLS)
-- ============================================
ALTER TABLE public.AISRI_assessments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own assessments
CREATE POLICY "Users can view own assessments" ON public.AISRI_assessments
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own assessments
CREATE POLICY "Users can insert own assessments" ON public.AISRI_assessments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own assessments
CREATE POLICY "Users can update own assessments" ON public.AISRI_assessments
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Coaches can view assessments of their athletes (optional - for future coach feature)
-- CREATE POLICY "Coaches can view athlete assessments" ON public.AISRI_assessments
--     FOR SELECT USING (
--         EXISTS (
--             SELECT 1 FROM public.coach_athlete_relationships
--             WHERE coach_id = auth.uid() AND athlete_id = AISRI_assessments.user_id
--         )
--     );

-- ============================================
-- 4. Create function to auto-update updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS update_AISRI_assessments_updated_at ON public.AISRI_assessments;
CREATE TRIGGER update_AISRI_assessments_updated_at
    BEFORE UPDATE ON public.AISRI_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. Grant permissions
-- ============================================
GRANT SELECT, INSERT, UPDATE ON public.AISRI_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================
-- 6. Sample query to verify table structure
-- ============================================
-- SELECT * FROM public.AISRI_assessments WHERE user_id = auth.uid();
