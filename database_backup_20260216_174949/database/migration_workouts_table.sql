-- Migration: Create Workouts Table
-- Description: Stores all logged and tracked workouts for athletes
-- Date: February 3, 2026

-- ============================================
-- 1. Create workouts table
-- ============================================
CREATE TABLE IF NOT EXISTS public.workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Workout Details
    activity_type VARCHAR(100) NOT NULL,
    distance DECIMAL(10, 2) DEFAULT 0.0 CHECK (distance >= 0),
    duration INTEGER DEFAULT 0 CHECK (duration >= 0), -- in minutes
    
    -- RPE and Pain Tracking
    rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10),
    pain_level INTEGER DEFAULT 0 CHECK (pain_level >= 0 AND pain_level <= 10),
    
    -- Additional Data
    notes TEXT,
    route_data JSONB, -- GPS coordinates for tracked workouts
    
    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Indexes for performance
    CONSTRAINT workouts_user_id_created_at_key UNIQUE (user_id, created_at)
);

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_created_at ON public.workouts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_user_created ON public.workouts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_activity_type ON public.workouts(activity_type);

-- ============================================
-- 2. Enable Row Level Security (RLS)
-- ============================================
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own workouts
CREATE POLICY "Users can view own workouts" ON public.workouts
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own workouts
CREATE POLICY "Users can insert own workouts" ON public.workouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own workouts
CREATE POLICY "Users can update own workouts" ON public.workouts
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own workouts
CREATE POLICY "Users can delete own workouts" ON public.workouts
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. Create trigger for auto-updating updated_at
-- ============================================
DROP TRIGGER IF EXISTS update_workouts_updated_at ON public.workouts;
CREATE TRIGGER update_workouts_updated_at
    BEFORE UPDATE ON public.workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 4. Add weekly_goal_distance to profiles table (if not exists)
-- ============================================
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS weekly_goal_distance DECIMAL(10, 2) DEFAULT 50.0 CHECK (weekly_goal_distance >= 0);

-- ============================================
-- 5. Grant permissions
-- ============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workouts TO authenticated;

-- ============================================
-- 6. Sample queries for testing
-- ============================================
-- SELECT * FROM public.workouts WHERE user_id = auth.uid() ORDER BY created_at DESC;
-- SELECT COUNT(*) as total_workouts, SUM(distance) as total_km FROM public.workouts WHERE user_id = auth.uid();
