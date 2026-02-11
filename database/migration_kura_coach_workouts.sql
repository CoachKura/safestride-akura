-- Kura Coach AI Workout System
-- Enhanced workout plans with AISRI methodology and Garmin compatibility

-- Enhanced ai_workout_plans table with training phases
CREATE TABLE IF NOT EXISTS ai_workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    training_phase VARCHAR(50) NOT NULL, -- Foundation, Endurance, Threshold, Quality, Peak
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_weeks INT NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- active, completed, paused
    AISRI_score_at_creation DECIMAL(5,2),
    metadata JSONB, -- weekly_schedule, safety_gates, allowed_zones
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced ai_workouts table with Garmin compatibility
CREATE TABLE IF NOT EXISTS ai_workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES ai_workout_plans(id) ON DELETE CASCADE,
    workout_date DATE NOT NULL,
    workout_name VARCHAR(255) NOT NULL,
    workout_type VARCHAR(50) NOT NULL, -- steady, intervals, tempo, long_run, recovery
    zone VARCHAR(10) NOT NULL, -- AR, F, EN, TH, P, SP
    duration_minutes INT NOT NULL,
    target_hr_min INT,
    target_hr_max INT,
    target_pace_min VARCHAR(10), -- Format: "5:30" (min:sec per km)
    target_pace_max VARCHAR(10),
    estimated_distance DECIMAL(6,2), -- in kilometers
    workout_structure JSONB NOT NULL, -- Array of workout steps (Garmin format)
    intervals JSONB, -- Interval configuration if applicable
    status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, in_progress, completed, skipped
    actual_duration_minutes INT,
    actual_distance DECIMAL(6,2),
    actual_avg_hr INT,
    actual_avg_pace VARCHAR(10),
    completed_at TIMESTAMP WITH TIME ZONE,
    garmin_compatible BOOLEAN DEFAULT TRUE,
    garmin_workout_id VARCHAR(255), -- ID if synced to Garmin Connect IQ
    synced_to_garmin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout performance tracking
CREATE TABLE IF NOT EXISTS workout_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES ai_workouts(id) ON DELETE CASCADE,
    completed_date TIMESTAMP WITH TIME ZONE NOT NULL,
    perception_rating INT CHECK (perception_rating BETWEEN 1 AND 10), -- RPE 1-10
    enjoyment_rating INT CHECK (enjoyment_rating BETWEEN 1 AND 5),
    difficulty_rating INT CHECK (difficulty_rating BETWEEN 1 AND 5),
    notes TEXT,
    zones_hit JSONB, -- Actual time spent in each zone
    interval_splits JSONB, -- Individual interval performances
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AISRI training history for adaptive progression
CREATE TABLE IF NOT EXISTS AISRI_training_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    AISRI_score_start DECIMAL(5,2),
    AISRI_score_end DECIMAL(5,2),
    workouts_completed INT DEFAULT 0,
    workouts_scheduled INT DEFAULT 0,
    total_time_minutes INT DEFAULT 0,
    total_distance DECIMAL(8,2) DEFAULT 0,
    zones_trained JSONB, -- Time in each zone
    safety_gates_passed JSONB,
    progression_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ai_workout_plans_user_id ON ai_workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_workout_plans_status ON ai_workout_plans(status);
CREATE INDEX IF NOT EXISTS idx_ai_workout_plans_dates ON ai_workout_plans(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_ai_workouts_user_id ON ai_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_workouts_plan_id ON ai_workouts(plan_id);
CREATE INDEX IF NOT EXISTS idx_ai_workouts_date ON ai_workouts(workout_date);
CREATE INDEX IF NOT EXISTS idx_ai_workouts_status ON ai_workouts(status);
CREATE INDEX IF NOT EXISTS idx_ai_workouts_zone ON ai_workouts(zone);

CREATE INDEX IF NOT EXISTS idx_workout_performance_user_id ON workout_performance(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_performance_workout_id ON workout_performance(workout_id);

CREATE INDEX IF NOT EXISTS idx_AISRI_training_history_user_id ON AISRI_training_history(user_id);
CREATE INDEX IF NOT EXISTS idx_AISRI_training_history_dates ON AISRI_training_history(week_start_date, week_end_date);

-- Enable RLS
ALTER TABLE ai_workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE AISRI_training_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies (drop if exists to avoid errors)
DROP POLICY IF EXISTS "Users can manage their own workout plans" ON ai_workout_plans;
CREATE POLICY "Users can manage their own workout plans"
    ON ai_workout_plans FOR ALL
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own workouts" ON ai_workouts;
CREATE POLICY "Users can manage their own workouts"
    ON ai_workouts FOR ALL
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own workout performance" ON workout_performance;
CREATE POLICY "Users can manage their own workout performance"
    ON workout_performance FOR ALL
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own training history" ON AISRI_training_history;
CREATE POLICY "Users can view their own training history"
    ON AISRI_training_history FOR ALL
    USING (auth.uid() = user_id);

-- Update timestamp triggers
CREATE OR REPLACE FUNCTION update_ai_workout_plan_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_ai_workout_plan_timestamp ON ai_workout_plans;
CREATE TRIGGER trigger_update_ai_workout_plan_timestamp
    BEFORE UPDATE ON ai_workout_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_workout_plan_timestamp();

DROP TRIGGER IF EXISTS trigger_update_ai_workout_timestamp ON ai_workouts;
CREATE TRIGGER trigger_update_ai_workout_timestamp
    BEFORE UPDATE ON ai_workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_workout_plan_timestamp();

-- Comments
COMMENT ON TABLE ai_workout_plans IS 'Kura Coach AI-generated training plans based on AISRI methodology';
COMMENT ON TABLE ai_workouts IS 'Individual structured workouts with Garmin-compatible format';
COMMENT ON TABLE workout_performance IS 'User feedback and performance data for completed workouts';
COMMENT ON TABLE AISRI_training_history IS 'Weekly training load and progression tracking';

COMMENT ON COLUMN ai_workouts.workout_structure IS 'Garmin-compatible workout steps (warmup, intervals, cooldown)';
COMMENT ON COLUMN ai_workouts.zone IS 'AISRI training zone: AR, F, EN, TH, P, SP';
COMMENT ON COLUMN ai_workouts.garmin_workout_id IS 'Reference ID if synced to Garmin Connect IQ app';
