-- Workout Completions Table
-- Track completed workouts and link to training plans

CREATE TABLE IF NOT EXISTS workout_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    run_session_id UUID REFERENCES run_sessions(id) ON DELETE SET NULL,
    
    -- Workout details
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    workout_name TEXT NOT NULL,
    workout_type TEXT, -- easy, tempo, interval, long
    
    -- Planned vs actual
    planned_distance_km DOUBLE PRECISION NOT NULL,
    actual_distance_km DOUBLE PRECISION NOT NULL,
    planned_duration_sec INTEGER NOT NULL,
    actual_duration_sec INTEGER NOT NULL,
    planned_pace_guide TEXT,
    actual_pace_min_per_km DOUBLE PRECISION,
    
    -- Training plan context
    week_number INTEGER,
    training_plan_goal TEXT, -- 5K, 10K, HM, Marathon
    is_on_plan BOOLEAN NOT NULL DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_completions_user_id ON workout_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_completions_completed_at ON workout_completions(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_completions_training_plan ON workout_completions(user_id, training_plan_goal, week_number);
CREATE INDEX IF NOT EXISTS idx_workout_completions_run_session ON workout_completions(run_session_id);

-- Row Level Security (RLS)
ALTER TABLE workout_completions ENABLE ROW LEVEL SECURITY;

-- Users can view their own completions
DROP POLICY IF EXISTS "Users can view own workout completions" ON workout_completions;
CREATE POLICY "Users can view own workout completions"
    ON workout_completions FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own completions
DROP POLICY IF EXISTS "Users can insert own workout completions" ON workout_completions;
CREATE POLICY "Users can insert own workout completions"
    ON workout_completions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own completions
DROP POLICY IF EXISTS "Users can update own workout completions" ON workout_completions;
CREATE POLICY "Users can update own workout completions"
    ON workout_completions FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own completions
DROP POLICY IF EXISTS "Users can delete own workout completions" ON workout_completions;
CREATE POLICY "Users can delete own workout completions"
    ON workout_completions FOR DELETE
    USING (auth.uid() = user_id);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_workout_completions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_workout_completions_updated_at ON workout_completions;
CREATE TRIGGER trigger_workout_completions_updated_at
    BEFORE UPDATE ON workout_completions
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_completions_updated_at();
