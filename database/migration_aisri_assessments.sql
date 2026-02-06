-- AISRI Assessments Table Migration
-- Stores injury risk assessment data for athletes

CREATE TABLE IF NOT EXISTS public.aisri_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assessment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Physical assessment scores (0-100)
    mobility_score INTEGER NOT NULL CHECK (mobility_score >= 0 AND mobility_score <= 100),
    strength_score INTEGER NOT NULL CHECK (strength_score >= 0 AND strength_score <= 100),
    balance_score INTEGER NOT NULL CHECK (balance_score >= 0 AND balance_score <= 100),
    flexibility_score INTEGER NOT NULL CHECK (flexibility_score >= 0 AND flexibility_score <= 100),
    endurance_score INTEGER NOT NULL CHECK (endurance_score >= 0 AND endurance_score <= 100),
    power_score INTEGER NOT NULL CHECK (power_score >= 0 AND power_score <= 100),
    
    -- Training data
    weekly_distance DECIMAL(10, 2) NOT NULL CHECK (weekly_distance >= 0),
    avg_cadence INTEGER NOT NULL CHECK (avg_cadence > 0),
    avg_pace DECIMAL(10, 2) NOT NULL CHECK (avg_pace > 0),
    
    -- Injury history
    past_injuries TEXT[] DEFAULT '{}',
    
    -- Biomechanics data (optional)
    ground_contact_time DECIMAL(10, 2) CHECK (ground_contact_time > 0),
    vertical_oscillation DECIMAL(10, 2) CHECK (vertical_oscillation > 0),
    stride_length DECIMAL(10, 2) CHECK (stride_length > 0),
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_assessment_date CHECK (assessment_date <= NOW())
);

-- Create indexes for performance
CREATE INDEX idx_aisri_assessments_user_id ON public.aisri_assessments(user_id);
CREATE INDEX idx_aisri_assessments_assessment_date ON public.aisri_assessments(assessment_date DESC);
CREATE INDEX idx_aisri_assessments_user_date ON public.aisri_assessments(user_id, assessment_date DESC);

-- Enable Row Level Security
ALTER TABLE public.aisri_assessments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own assessments
CREATE POLICY "Users can view their own AISRI assessments"
    ON public.aisri_assessments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own assessments
CREATE POLICY "Users can insert their own AISRI assessments"
    ON public.aisri_assessments
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own assessments
CREATE POLICY "Users can update their own AISRI assessments"
    ON public.aisri_assessments
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own assessments
CREATE POLICY "Users can delete their own AISRI assessments"
    ON public.aisri_assessments
    FOR DELETE
    USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_aisri_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
CREATE TRIGGER set_aisri_assessments_updated_at
    BEFORE UPDATE ON public.aisri_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_aisri_assessments_updated_at();

-- Comments for documentation
COMMENT ON TABLE public.aisri_assessments IS 'Stores AISRI (AI-powered Sports Running Injury) risk assessment data for athletes';
COMMENT ON COLUMN public.aisri_assessments.mobility_score IS 'Mobility assessment score (0-100)';
COMMENT ON COLUMN public.aisri_assessments.strength_score IS 'Strength assessment score (0-100)';
COMMENT ON COLUMN public.aisri_assessments.balance_score IS 'Balance assessment score (0-100)';
COMMENT ON COLUMN public.aisri_assessments.flexibility_score IS 'Flexibility assessment score (0-100)';
COMMENT ON COLUMN public.aisri_assessments.endurance_score IS 'Endurance assessment score (0-100)';
COMMENT ON COLUMN public.aisri_assessments.power_score IS 'Power assessment score (0-100)';
COMMENT ON COLUMN public.aisri_assessments.weekly_distance IS 'Average weekly running distance in kilometers';
COMMENT ON COLUMN public.aisri_assessments.avg_cadence IS 'Average running cadence in steps per minute';
COMMENT ON COLUMN public.aisri_assessments.avg_pace IS 'Average running pace in minutes per kilometer';
COMMENT ON COLUMN public.aisri_assessments.past_injuries IS 'Array of past injury descriptions';
COMMENT ON COLUMN public.aisri_assessments.ground_contact_time IS 'Ground contact time in milliseconds (from GPS watch)';
COMMENT ON COLUMN public.aisri_assessments.vertical_oscillation IS 'Vertical oscillation in centimeters (from GPS watch)';
COMMENT ON COLUMN public.aisri_assessments.stride_length IS 'Average stride length in meters (from GPS watch)';
