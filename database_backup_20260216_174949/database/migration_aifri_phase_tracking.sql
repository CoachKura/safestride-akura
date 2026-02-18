-- Migration: Add AISRI Training Phase Tracking
-- Date: 2026-02-09
-- Purpose: Add columns to track training phases, lifetime km, and AISRI zone history

-- ============================================
-- 1. Add Training Phase Tracking to Profiles
-- ============================================

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS lifetime_km_total DECIMAL(10, 2) DEFAULT 0.0 CHECK (lifetime_km_total >= 0);

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS current_training_phase INTEGER DEFAULT 1 CHECK (current_training_phase BETWEEN 1 AND 6);

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS phase_start_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS last_zone_unlock_date TIMESTAMP WITH TIME ZONE;

-- ============================================
-- 2. Create AISRI Zone History Table
-- ============================================

CREATE TABLE IF NOT EXISTS public.AISRI_zone_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    zone_code VARCHAR(3) NOT NULL CHECK (zone_code IN ('AR', 'F', 'EN', 'TH', 'P', 'SP')),
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    AISRI_score_at_unlock INTEGER CHECK (AISRI_score_at_unlock BETWEEN 0 AND 100),
    requirements_met JSONB, -- Store which requirements were met
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for user lookups
CREATE INDEX IF NOT EXISTS idx_zone_history_user_id ON public.AISRI_zone_history(user_id);

-- Add index for zone lookups
CREATE INDEX IF NOT EXISTS idx_zone_history_zone_code ON public.AISRI_zone_history(zone_code);

-- ============================================
-- 3. Create AISRI Training Log Table
-- ============================================

CREATE TABLE IF NOT EXISTS public.AISRI_training_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    zone_completed VARCHAR(3) CHECK (zone_completed IN ('AR', 'F', 'EN', 'TH', 'P', 'SP')),
    distance DECIMAL(10, 2) CHECK (distance >= 0),
    duration_minutes INTEGER CHECK (duration_minutes >= 0),
    avg_heart_rate INTEGER CHECK (avg_heart_rate BETWEEN 40 AND 220),
    AISRI_score INTEGER CHECK (AISRI_score BETWEEN 0 AND 100),
    load_ratio DECIMAL(5, 2), -- Acute:Chronic ratio
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for user and date lookups
CREATE INDEX IF NOT EXISTS idx_training_log_user_date ON public.AISRI_training_log(user_id, log_date DESC);

-- ============================================
-- 4. Create Phase Transition History Table
-- ============================================

CREATE TABLE IF NOT EXISTS public.phase_transitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    from_phase INTEGER CHECK (from_phase BETWEEN 1 AND 6),
    to_phase INTEGER CHECK (to_phase BETWEEN 1 AND 6),
    transition_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_km_at_transition DECIMAL(10, 2),
    AISRI_score_at_transition INTEGER CHECK (AISRI_score_at_transition BETWEEN 0 AND 100),
    weeks_in_previous_phase INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for user lookups
CREATE INDEX IF NOT EXISTS idx_phase_transitions_user_id ON public.phase_transitions(user_id);

-- ============================================
-- 5. Enable Row Level Security (RLS)
-- ============================================

ALTER TABLE public.AISRI_zone_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.AISRI_training_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phase_transitions ENABLE ROW LEVEL SECURITY;

-- Zone History Policies
CREATE POLICY "Users can view their own zone history"
    ON public.AISRI_zone_history
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own zone history"
    ON public.AISRI_zone_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Training Log Policies
CREATE POLICY "Users can view their own training log"
    ON public.AISRI_training_log
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own training log"
    ON public.AISRI_training_log
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own training log"
    ON public.AISRI_training_log
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Phase Transitions Policies
CREATE POLICY "Users can view their own phase transitions"
    ON public.phase_transitions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own phase transitions"
    ON public.phase_transitions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 6. Create Function to Update Lifetime KM
-- ============================================

CREATE OR REPLACE FUNCTION update_lifetime_km()
RETURNS TRIGGER AS $$
DECLARE
    dist_value DECIMAL(10, 2);
    profile_user_id UUID;
BEGIN
    -- Get distance from whichever column exists
    dist_value := COALESCE(NEW.distance, NEW.distance_km, 0);
    
    -- Get user_id from whichever column exists
    profile_user_id := COALESCE(NEW.user_id, NEW.athlete_id);
    
    -- Update lifetime_km_total in profiles when a workout is added
    IF profile_user_id IS NOT NULL THEN
        UPDATE public.profiles
        SET lifetime_km_total = COALESCE(lifetime_km_total, 0) + dist_value
        WHERE id = profile_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on workouts table
DROP TRIGGER IF EXISTS trigger_update_lifetime_km ON public.workouts;
CREATE TRIGGER trigger_update_lifetime_km
    AFTER INSERT ON public.workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_lifetime_km();

-- ============================================
-- 7. Create Function to Check Phase Transition
-- ============================================

CREATE OR REPLACE FUNCTION check_phase_transition()
RETURNS TRIGGER AS $$
DECLARE
    current_phase INTEGER;
    new_phase INTEGER;
    total_km DECIMAL(10, 2);
    profile_user_id UUID;
BEGIN
    -- Get user_id from whichever column exists
    profile_user_id := COALESCE(NEW.user_id, NEW.athlete_id);
    
    IF profile_user_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Get current phase and total km
    SELECT current_training_phase, lifetime_km_total
    INTO current_phase, total_km
    FROM public.profiles
    WHERE id = profile_user_id;
    
    -- Determine new phase based on total km
    IF total_km < 800 THEN
        new_phase := 1;
    ELSIF total_km < 1600 THEN
        new_phase := 2;
    ELSIF total_km < 2400 THEN
        new_phase := 3;
    ELSIF total_km < 3200 THEN
        new_phase := 4;
    ELSIF total_km < 4000 THEN
        new_phase := 5;
    ELSE
        new_phase := 6;
    END IF;
    
    -- If phase changed, update profile and log transition
    IF new_phase != current_phase THEN
        -- Update profile
        UPDATE public.profiles
        SET current_training_phase = new_phase,
            phase_start_date = NOW()
        WHERE id = profile_user_id;
        
        -- Log transition
        INSERT INTO public.phase_transitions (
            user_id,
            from_phase,
            to_phase,
            total_km_at_transition,
            AISRI_score_at_transition
        )
        VALUES (
            profile_user_id,
            current_phase,
            new_phase,
            total_km,
            (SELECT current_AISRI_score FROM public.profiles WHERE id = profile_user_id)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on workouts table
DROP TRIGGER IF EXISTS trigger_check_phase_transition ON public.workouts;
CREATE TRIGGER trigger_check_phase_transition
    AFTER INSERT ON public.workouts
    FOR EACH ROW
    EXECUTE FUNCTION check_phase_transition();

-- ============================================
-- 8. Add Comments
-- ============================================

COMMENT ON COLUMN profiles.lifetime_km_total IS 'Total kilometers run across all time (for phase tracking)';
COMMENT ON COLUMN profiles.current_training_phase IS 'Current training phase (1-6): 1=Base Building, 2=Aerobic Development, 3=Threshold Focus, 4=Interval Training, 5=Peak Performance, 6=Taper & Recovery';
COMMENT ON COLUMN profiles.phase_start_date IS 'Date when current phase started';
COMMENT ON COLUMN profiles.last_zone_unlock_date IS 'Date when last HR zone was unlocked';

COMMENT ON TABLE AISRI_zone_history IS 'History of zone unlocks for each user';
COMMENT ON TABLE AISRI_training_log IS 'Daily training log with AISRI metrics';
COMMENT ON TABLE phase_transitions IS 'History of phase transitions in the 0-5000km journey';

-- ============================================
-- 9. Initialize Existing Users (Optional)
-- ============================================

-- First, ensure workouts table has a distance tracking column
-- This handles different schema versions (distance vs distance_km vs athlete_id vs user_id)

-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add distance column if missing (used by logger_screen)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'workouts' 
        AND column_name = 'distance'
    ) THEN
        ALTER TABLE public.workouts ADD COLUMN distance DECIMAL(10, 2);
    END IF;
    
    -- Add distance_km column if missing (used by strava_service)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'workouts' 
        AND column_name = 'distance_km'
    ) THEN
        ALTER TABLE public.workouts ADD COLUMN distance_km DECIMAL(10, 2);
    END IF;
    
    -- Add user_id column if missing (used by logger_screen)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'workouts' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.workouts ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add athlete_id column if missing (used by strava_service)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'workouts' 
        AND column_name = 'athlete_id'
    ) THEN
        ALTER TABLE public.workouts ADD COLUMN athlete_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Sync data between duplicate columns (if both exist)
UPDATE public.workouts 
SET distance_km = distance 
WHERE distance_km IS NULL AND distance IS NOT NULL;

UPDATE public.workouts 
SET distance = distance_km 
WHERE distance IS NULL AND distance_km IS NOT NULL;

UPDATE public.workouts 
SET user_id = athlete_id 
WHERE user_id IS NULL AND athlete_id IS NOT NULL;

UPDATE public.workouts 
SET athlete_id = user_id 
WHERE athlete_id IS NULL AND user_id IS NOT NULL;

-- Calculate lifetime km for existing users
-- Use COALESCE to handle both distance and distance_km columns
UPDATE public.profiles p
SET lifetime_km_total = COALESCE((
    SELECT SUM(COALESCE(distance, distance_km, 0))
    FROM public.workouts w
    WHERE w.user_id = p.id OR w.athlete_id = p.id
), 0)
WHERE p.lifetime_km_total IS NULL OR p.lifetime_km_total = 0;

-- Set initial phase based on lifetime km
UPDATE public.profiles
SET current_training_phase = CASE
    WHEN lifetime_km_total < 800 THEN 1
    WHEN lifetime_km_total < 1600 THEN 2
    WHEN lifetime_km_total < 2400 THEN 3
    WHEN lifetime_km_total < 3200 THEN 4
    WHEN lifetime_km_total < 4000 THEN 5
    ELSE 6
END,
phase_start_date = NOW()
WHERE phase_start_date IS NULL;
