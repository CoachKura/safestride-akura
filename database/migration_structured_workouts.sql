-- Structured Workouts System (Garmin-style workout builder)
-- Allows coaches to create detailed, step-by-step workouts with intensity targets

-- Create structured_workouts table
CREATE TABLE IF NOT EXISTS structured_workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  description TEXT,
  activity_type TEXT NOT NULL DEFAULT 'Running',
  steps JSONB NOT NULL DEFAULT '[]'::jsonb,
  estimated_duration INTEGER, -- seconds
  estimated_distance NUMERIC(10, 2), -- km
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Create index for faster queries
CREATE INDEX idx_structured_workouts_coach_id ON structured_workouts(coach_id);
CREATE INDEX idx_structured_workouts_activity_type ON structured_workouts(activity_type);
CREATE INDEX idx_structured_workouts_created_at ON structured_workouts(created_at DESC);

-- Enable RLS
ALTER TABLE structured_workouts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Coaches can view their own structured workouts"
  ON structured_workouts FOR SELECT
  USING (auth.uid() = coach_id);

CREATE POLICY "Coaches can create structured workouts"
  ON structured_workouts FOR INSERT
  WITH CHECK (auth.uid() = coach_id);

CREATE POLICY "Coaches can update their own structured workouts"
  ON structured_workouts FOR UPDATE
  USING (auth.uid() = coach_id);

CREATE POLICY "Coaches can delete their own structured workouts"
  ON structured_workouts FOR DELETE
  USING (auth.uid() = coach_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_structured_workout_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_structured_workout_timestamp ON structured_workouts;
CREATE TRIGGER trigger_update_structured_workout_timestamp
  BEFORE UPDATE ON structured_workouts
  FOR EACH ROW
  EXECUTE FUNCTION update_structured_workout_timestamp();

-- Create workout_assignments table (link workouts to athletes with dates)
CREATE TABLE IF NOT EXISTS workout_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  structured_workout_id UUID NOT NULL REFERENCES structured_workouts(id) ON DELETE CASCADE,
  athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'skipped')),
  completed_at TIMESTAMPTZ,
  gps_activity_id UUID REFERENCES gps_activities(id), -- Link to actual tracked workout
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Create indexes
CREATE INDEX idx_workout_assignments_workout_id ON workout_assignments(structured_workout_id);
CREATE INDEX idx_workout_assignments_athlete_id ON workout_assignments(athlete_id);
CREATE INDEX idx_workout_assignments_coach_id ON workout_assignments(coach_id);
CREATE INDEX idx_workout_assignments_scheduled_date ON workout_assignments(scheduled_date);
CREATE INDEX idx_workout_assignments_status ON workout_assignments(status);

-- Enable RLS
ALTER TABLE workout_assignments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workout_assignments
CREATE POLICY "Athletes can view their own assignments"
  ON workout_assignments FOR SELECT
  USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches can view assignments they created"
  ON workout_assignments FOR SELECT
  USING (auth.uid() = coach_id);

CREATE POLICY "Coaches can create assignments"
  ON workout_assignments FOR INSERT
  WITH CHECK (auth.uid() = coach_id);

CREATE POLICY "Coaches can update their assignments"
  ON workout_assignments FOR UPDATE
  USING (auth.uid() = coach_id);

CREATE POLICY "Athletes can update their assignment status"
  ON workout_assignments FOR UPDATE
  USING (auth.uid() = athlete_id);

CREATE POLICY "Coaches can delete their assignments"
  ON workout_assignments FOR DELETE
  USING (auth.uid() = coach_id);

-- Create trigger for workout_assignments
DROP TRIGGER IF EXISTS trigger_update_workout_assignment_timestamp ON workout_assignments;
CREATE TRIGGER trigger_update_workout_assignment_timestamp
  BEFORE UPDATE ON workout_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_structured_workout_timestamp();

-- Add comments
COMMENT ON TABLE structured_workouts IS 'Garmin-style structured workouts with steps, durations, and intensity targets';
COMMENT ON COLUMN structured_workouts.steps IS 'JSONB array of workout steps with type, duration, and intensity targets';
COMMENT ON TABLE workout_assignments IS 'Assigns structured workouts to athletes with scheduled dates';
COMMENT ON COLUMN workout_assignments.gps_activity_id IS 'Links to actual tracked workout when athlete completes it';

-- Sample workout (commented out - for reference)
/*
INSERT INTO structured_workouts (coach_id, workout_name, description, activity_type, steps, estimated_duration, estimated_distance)
VALUES (
  'your-coach-uuid-here',
  'Run Workout (2)',
  '1km run with warm up and cool down',
  'Running',
  '[
    {
      "id": "step-1",
      "step_type": "warmUp",
      "name": "Warm up",
      "order": 0,
      "duration_type": "lapPress",
      "duration_display": "Lap Button Press",
      "intensity_type": "noTarget",
      "target_display": "No Target"
    },
    {
      "id": "step-2",
      "step_type": "run",
      "name": "Run",
      "order": 1,
      "duration_type": "distance",
      "duration_value": 1.0,
      "duration_display": "1.00 km",
      "intensity_type": "heartRateZone",
      "heart_rate_zone": 2,
      "target_min": 106,
      "target_max": 124,
      "target_display": "Heart Rate Zone 2 (106-124 bpm)"
    },
    {
      "id": "step-3",
      "step_type": "coolDown",
      "name": "Cool down",
      "order": 2,
      "duration_type": "lapPress",
      "duration_display": "Lap Button Press",
      "intensity_type": "noTarget",
      "target_display": "No Target"
    }
  ]'::jsonb,
  580, -- 9:40 = 580 seconds
  1.0  -- 1 km
);
*/
