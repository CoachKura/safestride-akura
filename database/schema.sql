-- SafeStride by AKURA - Database Schema
-- VDOT O2-style Coach Platform + AI Assessment System
-- PostgreSQL (Supabase)
-- Last Updated: 2026-01-27

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- ASSESSMENTS TABLE (New - AI-powered injury risk assessment)
-- ================================================
CREATE TABLE assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id TEXT NOT NULL, -- Email or UUID reference
  assessment_data JSONB NOT NULL,
  aifri_score NUMERIC(5,2) CHECK (aifri_score >= 0 AND aifri_score <= 100),
  scores JSONB, -- Individual pillar scores (running, strength, rom, balance, mobility, alignment)
  risk_level TEXT CHECK (risk_level IN ('Low', 'Moderate', 'High')),
  protocol_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_assessments_athlete ON assessments(athlete_id);
CREATE INDEX idx_assessments_created ON assessments(created_at DESC);
CREATE INDEX idx_assessments_risk ON assessments(risk_level);

-- ================================================
-- PROTOCOLS TABLE (New - Personalized training protocols)
-- ================================================
CREATE TABLE protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assessment_id UUID REFERENCES assessments(id),
  athlete_id TEXT NOT NULL,
  protocol_data JSONB NOT NULL,
  start_date DATE,
  end_date DATE,
  status TEXT CHECK (status IN ('active', 'completed', 'paused')) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_protocols_athlete ON protocols(athlete_id);
CREATE INDEX idx_protocols_status ON protocols(status);

-- ================================================
-- WORKOUTS TABLE (New - Daily workout assignments)
-- ================================================
CREATE TABLE workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  protocol_id UUID REFERENCES protocols(id) NOT NULL,
  athlete_id TEXT NOT NULL,
  day_number INTEGER NOT NULL,
  workout_data JSONB NOT NULL,
  scheduled_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workouts_protocol ON workouts(protocol_id);
CREATE INDEX idx_workouts_athlete ON workouts(athlete_id);
CREATE INDEX idx_workouts_scheduled ON workouts(scheduled_date);

-- ================================================
-- FEEDBACK TABLE (New - Athlete workout feedback)
-- ================================================
CREATE TABLE feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID REFERENCES workouts(id) NOT NULL,
  athlete_id TEXT NOT NULL,
  rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10),
  pain_level TEXT CHECK (pain_level IN ('none', 'mild', 'moderate', 'severe')),
  sleep_hours NUMERIC(3,1),
  nutrition_quality TEXT CHECK (nutrition_quality IN ('poor', 'fair', 'good', 'excellent')),
  stress_level TEXT CHECK (stress_level IN ('low', 'moderate', 'high')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_feedback_workout ON feedback(workout_id);
CREATE INDEX idx_feedback_athlete ON feedback(athlete_id);

-- ================================================
-- COACHES TABLE
-- ================================================
CREATE TABLE coaches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ================================================
-- ATHLETES TABLE
-- ================================================
CREATE TABLE athletes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coach_id UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  age INTEGER,
  weight DECIMAL(5,2),  -- kg
  height DECIMAL(5,2),  -- cm
  max_hr INTEGER,        -- Calculated: 208 - (0.7 × age)
  current_hm_time TEXT,  -- Format: "1:42:00"
  current_10k_time TEXT, -- Format: "40:00"
  injuries TEXT[],       -- Array of injury descriptions
  status TEXT DEFAULT 'invited' CHECK (status IN ('invited', 'active', 'inactive')),
  invite_token TEXT UNIQUE,
  invite_sent_at TIMESTAMP,
  signed_up_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ================================================
-- HR ZONES TABLE
-- ================================================
CREATE TABLE hr_zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID UNIQUE NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
  max_hr INTEGER NOT NULL,
  zone_1_min INTEGER NOT NULL,  -- 60% max_hr
  zone_1_max INTEGER NOT NULL,  -- 70% max_hr
  zone_2_min INTEGER NOT NULL,  -- 70% max_hr
  zone_2_max INTEGER NOT NULL,  -- 80% max_hr
  zone_3_min INTEGER NOT NULL,  -- 80% max_hr
  zone_3_max INTEGER NOT NULL,  -- 87% max_hr
  zone_4_min INTEGER NOT NULL,  -- 87% max_hr
  zone_4_max INTEGER NOT NULL,  -- 93% max_hr
  zone_5_min INTEGER NOT NULL,  -- 93% max_hr
  zone_5_max INTEGER NOT NULL,  -- 100% max_hr
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ================================================
-- DEVICE CONNECTIONS TABLE
-- ================================================
CREATE TABLE device_connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('garmin', 'strava', 'coros', 'apple_health', 'polar', 'suunto', 'fitbit', 'wahoo')),
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMP,
  external_user_id TEXT,
  connected_at TIMESTAMP DEFAULT NOW(),
  last_sync_at TIMESTAMP,
  sync_enabled BOOLEAN DEFAULT true,
  UNIQUE(athlete_id, provider)
);

-- ================================================
-- WORKOUT TEMPLATES (7 Protocols)
-- ================================================
CREATE TABLE workout_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  protocol TEXT NOT NULL CHECK (protocol IN ('START', 'ENGINE', 'OXYGEN', 'POWER', 'ZONES', 'STRENGTH', 'LONG_RUN')),
  name TEXT NOT NULL,
  description TEXT,
  hr_zones INTEGER[] NOT NULL,  -- e.g., [1,2] for Zones 1-2
  duration_minutes INTEGER,
  workout_structure JSONB NOT NULL,
  day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Monday, 6=Sunday
  created_at TIMESTAMP DEFAULT NOW()
);

-- ================================================
-- SCHEDULED WORKOUTS
-- ================================================
CREATE TABLE scheduled_workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  personalized_paces JSONB,  -- Per-athlete pace targets
  personalized_hr_zones JSONB,  -- Athlete-specific HR zones
  notes TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'skipped', 'missed')),
  synced_to_garmin BOOLEAN DEFAULT false,
  synced_to_strava BOOLEAN DEFAULT false,
  garmin_workout_id TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(athlete_id, scheduled_date)
);

-- ================================================
-- COMPLETED ACTIVITIES
-- ================================================
CREATE TABLE completed_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
  scheduled_workout_id UUID REFERENCES scheduled_workouts(id) ON DELETE SET NULL,
  activity_date TIMESTAMP NOT NULL,
  distance_km DECIMAL(6,2),
  duration_minutes INTEGER,
  duration_seconds INTEGER,
  avg_pace TEXT,  -- Format: "5:30/km"
  avg_hr INTEGER,
  max_hr INTEGER,
  elevation_gain DECIMAL(6,2),
  source TEXT NOT NULL CHECK (source IN ('garmin', 'strava', 'coros', 'manual')),
  external_id TEXT,  -- Strava activity ID or Garmin activity ID
  external_url TEXT,
  raw_data JSONB,  -- Full API response
  auto_matched BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(athlete_id, external_id, source)
);

-- ================================================
-- INVITATIONS LOG
-- ================================================
CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coach_id UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  athlete_id UUID REFERENCES athletes(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  token TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
  sent_at TIMESTAMP DEFAULT NOW(),
  accepted_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '7 days'
);

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
CREATE INDEX idx_athletes_coach_id ON athletes(coach_id);
CREATE INDEX idx_athletes_status ON athletes(status);
CREATE INDEX idx_scheduled_workouts_athlete_date ON scheduled_workouts(athlete_id, scheduled_date);
CREATE INDEX idx_scheduled_workouts_status ON scheduled_workouts(status);
CREATE INDEX idx_completed_activities_athlete_date ON completed_activities(athlete_id, activity_date);
CREATE INDEX idx_completed_activities_scheduled ON completed_activities(scheduled_workout_id);
CREATE INDEX idx_device_connections_athlete ON device_connections(athlete_id);
CREATE INDEX idx_invitations_token ON invitations(token);

-- ================================================
-- FUNCTIONS
-- ================================================

-- Function to calculate HR zones from max HR
CREATE OR REPLACE FUNCTION calculate_hr_zones(max_hr_value INTEGER)
RETURNS TABLE(
  zone_1_min INTEGER,
  zone_1_max INTEGER,
  zone_2_min INTEGER,
  zone_2_max INTEGER,
  zone_3_min INTEGER,
  zone_3_max INTEGER,
  zone_4_min INTEGER,
  zone_4_max INTEGER,
  zone_5_min INTEGER,
  zone_5_max INTEGER
) AS $$
BEGIN
  RETURN QUERY SELECT
    ROUND(max_hr_value * 0.60)::INTEGER,  -- Zone 1 min (60%)
    ROUND(max_hr_value * 0.70)::INTEGER,  -- Zone 1 max (70%)
    ROUND(max_hr_value * 0.70)::INTEGER,  -- Zone 2 min (70%)
    ROUND(max_hr_value * 0.80)::INTEGER,  -- Zone 2 max (80%)
    ROUND(max_hr_value * 0.80)::INTEGER,  -- Zone 3 min (80%)
    ROUND(max_hr_value * 0.87)::INTEGER,  -- Zone 3 max (87%)
    ROUND(max_hr_value * 0.87)::INTEGER,  -- Zone 4 min (87%)
    ROUND(max_hr_value * 0.93)::INTEGER,  -- Zone 4 max (93%)
    ROUND(max_hr_value * 0.93)::INTEGER,  -- Zone 5 min (93%)
    ROUND(max_hr_value * 1.00)::INTEGER;  -- Zone 5 max (100%)
END;
$$ LANGUAGE plpgsql;

-- Function to calculate Max HR from age
CREATE OR REPLACE FUNCTION calculate_max_hr(age_value INTEGER)
RETURNS INTEGER AS $$
BEGIN
  RETURN 208 - ROUND(0.7 * age_value)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-calculate Max HR when athlete age is set
CREATE OR REPLACE FUNCTION trigger_calculate_max_hr()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.age IS NOT NULL AND (NEW.max_hr IS NULL OR OLD.age IS DISTINCT FROM NEW.age) THEN
    NEW.max_hr := calculate_max_hr(NEW.age);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_athlete_max_hr
BEFORE INSERT OR UPDATE ON athletes
FOR EACH ROW
EXECUTE FUNCTION trigger_calculate_max_hr();

-- Trigger to auto-create HR zones when athlete is created
CREATE OR REPLACE FUNCTION trigger_create_hr_zones()
RETURNS TRIGGER AS $$
DECLARE
  zones RECORD;
BEGIN
  IF NEW.max_hr IS NOT NULL THEN
    SELECT * INTO zones FROM calculate_hr_zones(NEW.max_hr);
    
    INSERT INTO hr_zones (
      athlete_id, max_hr,
      zone_1_min, zone_1_max,
      zone_2_min, zone_2_max,
      zone_3_min, zone_3_max,
      zone_4_min, zone_4_max,
      zone_5_min, zone_5_max
    ) VALUES (
      NEW.id, NEW.max_hr,
      zones.zone_1_min, zones.zone_1_max,
      zones.zone_2_min, zones.zone_2_max,
      zones.zone_3_min, zones.zone_3_max,
      zones.zone_4_min, zones.zone_4_max,
      zones.zone_5_min, zones.zone_5_max
    )
    ON CONFLICT (athlete_id) DO UPDATE SET
      max_hr = EXCLUDED.max_hr,
      zone_1_min = EXCLUDED.zone_1_min,
      zone_1_max = EXCLUDED.zone_1_max,
      zone_2_min = EXCLUDED.zone_2_min,
      zone_2_max = EXCLUDED.zone_2_max,
      zone_3_min = EXCLUDED.zone_3_min,
      zone_3_max = EXCLUDED.zone_3_max,
      zone_4_min = EXCLUDED.zone_4_min,
      zone_4_max = EXCLUDED.zone_4_max,
      zone_5_min = EXCLUDED.zone_5_min,
      zone_5_max = EXCLUDED.zone_5_max;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_athlete_hr_zones
AFTER INSERT OR UPDATE ON athletes
FOR EACH ROW
EXECUTE FUNCTION trigger_create_hr_zones();

-- ================================================
-- SEED DATA: Coach Kura
-- ================================================
INSERT INTO coaches (email, name, phone, password_hash) VALUES
('coach@akura.in', 'Kura Balendar Sathyamoorthy', '+91-XXXXXXXXXX', '$2a$10$placeholder_hash')
ON CONFLICT (email) DO NOTHING;

-- ================================================
-- SEED DATA: 7 Workout Templates
-- ================================================

-- 1. START Protocol (Monday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'START',
  'Mitochondrial Adaptation Run',
  'Easy conversational pace run to build aerobic base and increase mitochondrial density',
  ARRAY[1, 2],
  50,
  0,  -- Monday
  '{
    "warmup": {"duration": 10, "description": "Easy jog + dynamic stretches"},
    "main": {
      "type": "easy_run",
      "duration": 40,
      "target_hr_zones": [1, 2],
      "description": "Easy conversational pace. You should be able to talk in full sentences."
    },
    "cooldown": {"duration": 5, "description": "Easy jog + static stretches"}
  }'::jsonb
);

-- 2. ENGINE Protocol (Tuesday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'ENGINE',
  'Lactate Threshold Tempo',
  'Sustained tempo run to improve lactate clearance and threshold endurance',
  ARRAY[3],
  60,
  1,  -- Tuesday
  '{
    "warmup": {"duration": 15, "description": "Easy jog progressively building"},
    "main": {
      "type": "tempo",
      "duration": 30,
      "target_hr_zones": [3],
      "description": "Comfortably hard pace. Can speak short sentences but not full conversations."
    },
    "cooldown": {"duration": 15, "description": "Easy jog + stretching"}
  }'::jsonb
);

-- 3. OXYGEN Protocol (Wednesday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'OXYGEN',
  'VO2max Intervals',
  'High-intensity intervals to increase maximum oxygen uptake capacity',
  ARRAY[4, 5],
  65,
  2,  -- Wednesday
  '{
    "warmup": {"duration": 20, "description": "Easy jog + drills + strides"},
    "main": {
      "type": "intervals",
      "sets": 6,
      "work_duration": "4-6 minutes",
      "rest_duration": "2-3 minutes jog",
      "target_hr_zones": [4, 5],
      "description": "6 x 1000m intervals at 90-95% effort with 400m jog recovery"
    },
    "cooldown": {"duration": 15, "description": "Easy jog + stretching"}
  }'::jsonb
);

-- 4. POWER Protocol (Thursday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'POWER',
  'Speed Development Sprints',
  'Short explosive sprints to build neuromuscular power and running economy',
  ARRAY[5],
  55,
  3,  -- Thursday
  '{
    "warmup": {"duration": 15, "description": "Easy jog + dynamic drills + 4 strides"},
    "main": {
      "type": "sprints",
      "sets": 10,
      "work_duration": "200m or 60 seconds",
      "rest_duration": "Full recovery (2-3 min walk/jog)",
      "target_hr_zones": [5],
      "description": "10 x 200m sprints or 60-sec hill sprints at 90-95% max effort"
    },
    "cooldown": {"duration": 12, "description": "Easy jog + stretching"}
  }'::jsonb
);

-- 5. ZONES Protocol (Friday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'ZONES',
  'Mixed HR Fartlek',
  'Varied pace run to build race adaptability and comfort with pace changes',
  ARRAY[1, 2, 3, 4, 5],
  55,
  4,  -- Friday
  '{
    "warmup": {"duration": 10, "description": "Easy jog"},
    "main": {
      "type": "fartlek",
      "duration": 40,
      "surges": "10-15 surges of varying lengths",
      "target_hr_zones": [1, 2, 3, 4, 5],
      "description": "Mix of 30-sec bursts, 90-sec pickups, 3-min tempo efforts, and easy recovery"
    },
    "cooldown": {"duration": 10, "description": "Easy jog + stretching"}
  }'::jsonb
);

-- 6. STRENGTH Protocol (Saturday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'STRENGTH',
  'Circuit Training',
  'Resistance training for injury prevention and power development',
  ARRAY[],
  65,
  5,  -- Saturday
  '{
    "warmup": {"duration": 10, "description": "Light cardio + dynamic stretches"},
    "main": {
      "type": "circuit",
      "rounds": 4,
      "exercises": [
        "Squats (15 reps)",
        "Lunges (12 each leg)",
        "Single-leg deadlifts (10 each)",
        "Calf raises (20 reps)",
        "Planks (60 sec)",
        "Push-ups (15 reps)",
        "Glute bridges (20 reps)"
      ],
      "rest_between_exercises": "45 seconds",
      "rest_between_rounds": "2 minutes",
      "description": "4 rounds of circuit training focusing on running-specific strength"
    },
    "cooldown": {"duration": 15, "description": "Stretching + foam rolling"}
  }'::jsonb
);

-- 7. LONG RUN Protocol (Sunday)
INSERT INTO workout_templates (protocol, name, description, hr_zones, duration_minutes, day_of_week, workout_structure) VALUES
(
  'LONG_RUN',
  'Endurance Long Run',
  'Extended easy run to build aerobic endurance and mental toughness',
  ARRAY[2],
  90,
  6,  -- Sunday
  '{
    "warmup": {"duration": 5, "description": "Very easy start"},
    "main": {
      "type": "long_run",
      "duration": 80,
      "target_hr_zones": [2],
      "description": "Long continuous run at easy conversational pace. Focus on time on feet, not speed."
    },
    "cooldown": {"duration": 5, "description": "Easy walk + stretching"},
    "notes": "Bring water/fuel if running over 90 minutes. Practice race-day nutrition strategy."
  }'::jsonb
);

-- ================================================
-- SEED DATA: 10 Chennai Athletes
-- ================================================
DO $$
DECLARE
  coach_uuid UUID;
BEGIN
  SELECT id INTO coach_uuid FROM coaches WHERE email = 'coach@akura.in';
  
  -- San (Elite)
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, current_10k_time, status) VALUES
  (coach_uuid, 'san@example.com', 'San', 28, 65.0, 175.0, '1:42:00', '40:00', 'active');
  
  -- Jana Alrey (Sub-elite)
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, status) VALUES
  (coach_uuid, 'jana@example.com', 'Jana Alrey', 26, 60.0, 170.0, '1:47:00', 'active');
  
  -- Karuna (BWO injury)
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, injuries, status) VALUES
  (coach_uuid, 'karuna@example.com', 'Karunakaran GV', 32, 72.0, 178.0, '1:50:00', ARRAY['BWO leg'], 'active');
  
  -- Vivek
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, status) VALUES
  (coach_uuid, 'vivek@example.com', 'Vivek', 30, 68.0, 172.0, '1:59:00', 'active');
  
  -- Dinesh
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, status) VALUES
  (coach_uuid, 'dinesh@example.com', 'Dinesh', 35, 75.0, 180.0, '2:13:00', 'active');
  
  -- Lakshmi (Plantar spur)
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, injuries, status) VALUES
  (coach_uuid, 'lakshmi@example.com', 'Lakshmi', 29, 55.0, 162.0, '2:20:00', ARRAY['Plantar spur'], 'active');
  
  -- Vinoth (New)
  INSERT INTO athletes (coach_id, email, name, age, weight, height, status) VALUES
  (coach_uuid, 'vinoth@example.com', 'Vinoth', 27, 70.0, 176.0, 'active');
  
  -- Natraj
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_10k_time, status) VALUES
  (coach_uuid, 'natraj@example.com', 'Natraj', 31, 73.0, 174.0, '70:00', 'active');
  
  -- Nathan
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_10k_time, status) VALUES
  (coach_uuid, 'nathan@example.com', 'Nathan', 28, 67.0, 173.0, '70:00', 'active');
  
  -- Coach Kura (Sciatica rehab)
  INSERT INTO athletes (coach_id, email, name, age, weight, height, current_hm_time, current_10k_time, injuries, status) VALUES
  (coach_uuid, 'kura@example.com', 'Kura Balendar Sathyamoorthy', 38, 78.0, 182.0, '2:35:00', '73:00', ARRAY['Sciatica S1'], 'active');
END $$;

-- ================================================
-- VIEWS FOR COACH DASHBOARD
-- ================================================

-- View: Athletes with their HR zones
CREATE OR REPLACE VIEW v_athletes_with_zones AS
SELECT 
  a.id,
  a.email,
  a.name,
  a.age,
  a.max_hr,
  a.current_hm_time,
  a.current_10k_time,
  a.injuries,
  a.status,
  hz.zone_1_min, hz.zone_1_max,
  hz.zone_2_min, hz.zone_2_max,
  hz.zone_3_min, hz.zone_3_max,
  hz.zone_4_min, hz.zone_4_max,
  hz.zone_5_min, hz.zone_5_max,
  dc_garmin.connected_at AS garmin_connected,
  dc_strava.connected_at AS strava_connected
FROM athletes a
LEFT JOIN hr_zones hz ON a.id = hz.athlete_id
LEFT JOIN device_connections dc_garmin ON a.id = dc_garmin.athlete_id AND dc_garmin.provider = 'garmin'
LEFT JOIN device_connections dc_strava ON a.id = dc_strava.athlete_id AND dc_strava.provider = 'strava';

-- View: Upcoming workouts for all athletes
CREATE OR REPLACE VIEW v_upcoming_workouts AS
SELECT 
  sw.id,
  sw.athlete_id,
  a.name AS athlete_name,
  sw.scheduled_date,
  wt.protocol,
  wt.name AS workout_name,
  wt.description,
  sw.status,
  sw.synced_to_garmin,
  sw.synced_to_strava
FROM scheduled_workouts sw
JOIN athletes a ON sw.athlete_id = a.id
JOIN workout_templates wt ON sw.template_id = wt.id
WHERE sw.scheduled_date >= CURRENT_DATE
ORDER BY sw.scheduled_date, a.name;

-- View: Completed activities with matching
CREATE OR REPLACE VIEW v_completed_activities_matched AS
SELECT 
  ca.id,
  ca.athlete_id,
  a.name AS athlete_name,
  ca.activity_date,
  ca.distance_km,
  ca.duration_minutes,
  ca.avg_pace,
  ca.avg_hr,
  ca.source,
  sw.scheduled_date,
  wt.protocol AS matched_protocol,
  wt.name AS matched_workout_name,
  ca.auto_matched
FROM completed_activities ca
JOIN athletes a ON ca.athlete_id = a.id
LEFT JOIN scheduled_workouts sw ON ca.scheduled_workout_id = sw.id
LEFT JOIN workout_templates wt ON sw.template_id = wt.id
ORDER BY ca.activity_date DESC;

COMMENT ON TABLE coaches IS 'Coaches managing athlete training programs';
COMMENT ON TABLE athletes IS 'Athletes being coached, with calculated Max HR and zones';
COMMENT ON TABLE hr_zones IS 'Heart rate zones calculated from Max HR (208 - 0.7 × Age)';
COMMENT ON TABLE device_connections IS 'Connected devices (Garmin, Strava, etc.) for auto-sync';
COMMENT ON TABLE workout_templates IS '7 training protocols with HR-based targets';
COMMENT ON TABLE scheduled_workouts IS 'Workouts published to athlete calendars';
COMMENT ON TABLE completed_activities IS 'Completed runs synced from devices or entered manually';
COMMENT ON TABLE invitations IS 'Email invitations sent by coaches to athletes';
