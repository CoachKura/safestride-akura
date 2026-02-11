-- Custom Workouts Table Migration
-- This table stores user-created workouts for running, strengthening, and rehab

CREATE TABLE IF NOT EXISTS public.custom_workouts (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_name TEXT NOT NULL,
    workout_type TEXT NOT NULL, -- e.g., 'Easy Run', 'Tempo Run', 'Lower Body Strength', 'Ankle Mobility'
    category TEXT NOT NULL, -- 'Running', 'Strengthening', 'Rehab'
    description TEXT,
    duration_minutes INTEGER,
    distance_km NUMERIC(10,2),
    sets INTEGER,
    reps INTEGER,
    rest_seconds INTEGER,
    standards JSONB, -- Stores standards like intensity, frequency, structure
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_custom_workouts_user_id ON public.custom_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_category ON public.custom_workouts(category);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_workout_type ON public.custom_workouts(workout_type);
CREATE INDEX IF NOT EXISTS idx_custom_workouts_created_at ON public.custom_workouts(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.custom_workouts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own custom workouts"
    ON public.custom_workouts
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own custom workouts"
    ON public.custom_workouts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own custom workouts"
    ON public.custom_workouts
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own custom workouts"
    ON public.custom_workouts
    FOR DELETE
    USING (auth.uid() = user_id);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_custom_workouts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER custom_workouts_updated_at
    BEFORE UPDATE ON public.custom_workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_custom_workouts_updated_at();

-- Comments for documentation
COMMENT ON TABLE public.custom_workouts IS 'User-created custom workouts for running, strength training, and rehabilitation';
COMMENT ON COLUMN public.custom_workouts.standards IS 'JSON object containing workout standards like intensity, frequency, duration, structure based on category';
COMMENT ON COLUMN public.custom_workouts.category IS 'Workout category: Running, Strengthening, or Rehab';
