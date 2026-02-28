-- Create progression_plans table
-- Stores personalized adaptive pace progression plans for athletes

CREATE TABLE IF NOT EXISTS progression_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Timeline details
    total_weeks INTEGER NOT NULL,
    current_week INTEGER DEFAULT 1,
    
    -- Pace progression
    start_pace DECIMAL(4,2) NOT NULL, -- e.g., 11.00 (11:00/km)
    goal_pace DECIMAL(4,2) NOT NULL DEFAULT 3.50, -- Always 3:30/km
    
    -- Mileage progression
    start_mileage DECIMAL(5,2) NOT NULL, -- Weekly km
    goal_mileage DECIMAL(5,2) NOT NULL,
    
    -- AISRI progression
    start_aisri INTEGER NOT NULL,
    goal_aisri INTEGER NOT NULL DEFAULT 75,
    
    -- Training phases
    phases TEXT[] NOT NULL, -- ['foundation', 'baseBuilding', 'speedDevelopment', ...]
    
    -- Weekly plans (JSONB for detailed workout data)
    weekly_plans JSONB NOT NULL,
    
    -- Summary and status
    summary TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'completed', 'paused'
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_pace CHECK (start_pace > goal_pace),
    CONSTRAINT valid_mileage CHECK (goal_mileage >= start_mileage),
    CONSTRAINT valid_week CHECK (current_week > 0 AND current_week <= total_weeks),
    CONSTRAINT valid_status CHECK (status IN ('active', 'completed', 'paused'))
);

-- Index for quick athlete lookups
CREATE INDEX idx_progression_plans_athlete ON progression_plans(athlete_id);
CREATE INDEX idx_progression_plans_status ON progression_plans(status);
CREATE INDEX idx_progression_plans_athlete_status ON progression_plans(athlete_id, status);

-- Add RLS policies
ALTER TABLE progression_plans ENABLE ROW LEVEL SECURITY;

-- Athletes can view their own plans
CREATE POLICY "Athletes can view own progression plans"
    ON progression_plans FOR SELECT
    USING (auth.uid() = athlete_id);

-- Athletes can insert their own plans
CREATE POLICY "Athletes can create own progression plans"
    ON progression_plans FOR INSERT
    WITH CHECK (auth.uid() = athlete_id);

-- Athletes can update their own plans
CREATE POLICY "Athletes can update own progression plans"
    ON progression_plans FOR UPDATE
    USING (auth.uid() = athlete_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_progression_plan_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update timestamp
CREATE TRIGGER update_progression_plans_timestamp
    BEFORE UPDATE ON progression_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_progression_plan_timestamp();

-- Add comments for documentation
COMMENT ON TABLE progression_plans IS 'Stores personalized adaptive pace progression plans to 3:30/km goal';
COMMENT ON COLUMN progression_plans.start_pace IS 'Starting pace in minutes per km (e.g., 11.00 = 11:00/km)';
COMMENT ON COLUMN progression_plans.goal_pace IS 'Goal pace in minutes per km (always 3:30/km = 3.50)';
COMMENT ON COLUMN progression_plans.weekly_plans IS 'Detailed week-by-week training plans with workouts';
COMMENT ON COLUMN progression_plans.phases IS 'Training phases: foundation, baseBuilding, speedDevelopment, thresholdWork, powerWork, goalAchievement';
