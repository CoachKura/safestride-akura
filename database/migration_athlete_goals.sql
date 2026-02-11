-- Athlete Goals and Training Preferences
-- Captures athlete's goals from evaluation form

-- Drop table if exists to avoid column conflicts
DROP TABLE IF EXISTS athlete_goals CASCADE;

CREATE TABLE athlete_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Goal Information
    primary_goal VARCHAR(100) NOT NULL, -- weight_loss, 5k, 10k, half_marathon, marathon, fitness, speed
    target_event VARCHAR(255), -- Event name (e.g., "Boston Marathon 2026")
    target_date DATE, -- Event date
    current_experience VARCHAR(50), -- beginner, intermediate, advanced
    
    -- Training Preferences
    days_per_week INT CHECK (days_per_week BETWEEN 1 AND 7),
    preferred_time VARCHAR(20), -- morning, afternoon, evening
    max_session_minutes INT, -- Maximum time per workout
    
    -- Personal Records
    current_5k_time VARCHAR(10), -- Format: "25:30"
    current_10k_time VARCHAR(10),
    current_half_marathon_time VARCHAR(10),
    current_marathon_time VARCHAR(10),
    
    -- Target Records
    target_5k_time VARCHAR(10),
    target_10k_time VARCHAR(10),
    target_half_marathon_time VARCHAR(10),
    target_marathon_time VARCHAR(10),
    
    -- Additional Context
    injury_history TEXT,
    training_obstacles TEXT, -- Time constraints, weather, etc.
    motivation_level INT CHECK (motivation_level BETWEEN 1 AND 10),
    notes TEXT,
    
    -- Metadata
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_athlete_goals_user_id ON athlete_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_athlete_goals_target_date ON athlete_goals(target_date);

-- Enable RLS
ALTER TABLE athlete_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage their own goals"
    ON athlete_goals FOR ALL
    USING (auth.uid() = user_id);

-- Update timestamp trigger
DROP TRIGGER IF EXISTS trigger_update_athlete_goals_timestamp ON athlete_goals;
CREATE TRIGGER trigger_update_athlete_goals_timestamp
    BEFORE UPDATE ON athlete_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_workout_plan_timestamp();

-- Sample data insert function
CREATE OR REPLACE FUNCTION insert_sample_athlete_goals(
    p_user_id UUID,
    p_primary_goal VARCHAR DEFAULT '10k',
    p_experience VARCHAR DEFAULT 'intermediate'
)
RETURNS UUID AS $$
DECLARE
    v_goal_id UUID;
BEGIN
    INSERT INTO athlete_goals (
        user_id,
        primary_goal,
        target_event,
        target_date,
        current_experience,
        days_per_week,
        preferred_time,
        max_session_minutes,
        current_10k_time,
        target_10k_time,
        motivation_level
    ) VALUES (
        p_user_id,
        p_primary_goal,
        'City Marathon 2026',
        CURRENT_DATE + INTERVAL '12 weeks',
        p_experience,
        4,
        'morning',
        60,
        '52:30',
        '48:00',
        8
    )
    RETURNING id INTO v_goal_id;
    
    RETURN v_goal_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE athlete_goals IS 'Athlete goals and training preferences from evaluation form';
COMMENT ON COLUMN athlete_goals.primary_goal IS 'Main training objective';
COMMENT ON COLUMN athlete_goals.target_date IS 'Date of target event or goal deadline';
