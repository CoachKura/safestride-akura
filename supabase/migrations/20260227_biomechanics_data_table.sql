-- Biomechanics Data Table
-- Store running form metrics and biomechanical analysis

CREATE TABLE IF NOT EXISTS biomechanics_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    run_session_id UUID REFERENCES run_sessions(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    
    -- Cadence (steps per minute)
    cadence INTEGER,
    left_cadence INTEGER,
    right_cadence INTEGER,
    
    -- Stride metrics (meters)
    stride_length NUMERIC(6, 3),
    left_stride_length NUMERIC(6, 3),
    right_stride_length NUMERIC(6, 3),
    
    -- Ground contact time (milliseconds)
    ground_contact_time INTEGER,
    left_ground_contact_time INTEGER,
    right_ground_contact_time INTEGER,
    
    -- Vertical oscillation (cm)
    vertical_oscillation NUMERIC(5, 2),
    left_vertical_oscillation NUMERIC(5, 2),
    right_vertical_oscillation NUMERIC(5, 2),
    
    -- Ground contact balance (%)
    ground_contact_balance NUMERIC(5, 2),
    
    -- Power and efficiency
    power INTEGER, -- Watts
    vertical_ratio NUMERIC(5, 3), -- Ratio of vertical oscillation to stride length
    
    -- Impact forces (G-force)
    impact_force NUMERIC(5, 2),
    left_impact_force NUMERIC(5, 2),
    right_impact_force NUMERIC(5, 2),
    
    -- Pronation (degrees)
    pronation NUMERIC(6, 2),
    pronation_type TEXT, -- 'neutral', 'overpronation', 'underpronation'
    
    -- Location context (optional)
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    altitude NUMERIC(8, 2),
    speed_kmh NUMERIC(6, 2),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_biomechanics_user_id ON biomechanics_data(user_id);
CREATE INDEX IF NOT EXISTS idx_biomechanics_run_session ON biomechanics_data(run_session_id);
CREATE INDEX IF NOT EXISTS idx_biomechanics_timestamp ON biomechanics_data(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_biomechanics_user_timestamp ON biomechanics_data(user_id, timestamp DESC);

-- Row Level Security (RLS)
ALTER TABLE biomechanics_data ENABLE ROW LEVEL SECURITY;

-- Users can view their own biomechanics data
DROP POLICY IF EXISTS "Users can view own biomechanics data" ON biomechanics_data;
CREATE POLICY "Users can view own biomechanics data"
    ON biomechanics_data FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own biomechanics data
DROP POLICY IF EXISTS "Users can insert own biomechanics data" ON biomechanics_data;
CREATE POLICY "Users can insert own biomechanics data"
    ON biomechanics_data FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own biomechanics data
DROP POLICY IF EXISTS "Users can update own biomechanics data" ON biomechanics_data;
CREATE POLICY "Users can update own biomechanics data"
    ON biomechanics_data FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own biomechanics data
DROP POLICY IF EXISTS "Users can delete own biomechanics data" ON biomechanics_data;
CREATE POLICY "Users can delete own biomechanics data"
    ON biomechanics_data FOR DELETE
    USING (auth.uid() = user_id);
