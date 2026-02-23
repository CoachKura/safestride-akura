-- SafeStride Athlete Profiles Table
-- Stores athlete signup data including AISRI evaluation scores

CREATE TABLE IF NOT EXISTS athlete_profiles (
  id BIGSERIAL PRIMARY KEY,
  athlete_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  age INTEGER NOT NULL,
  resting_hr INTEGER,
  weekly_distance INTEGER,
  
  -- AISRI Pillar Scores (0-100 each)
  pillars JSONB NOT NULL, -- {running, strength, rom, balance, alignment, mobility}
  
  -- Detailed ROM Test Results (optional, for advanced analysis)
  rom_tests JSONB, -- {hip_flexion, hip_extension, ankle_dorsiflexion, knee_flexion, etc.}
  
  -- Calculated Metrics
  aisri_score INTEGER, -- Total score 0-1000
  risk_category TEXT, -- AR, F, EN, TH, P
  
  -- Predicted Running Metrics (calculated from pillars)
  predicted_stride_length NUMERIC(4,2), -- meters
  predicted_cadence INTEGER, -- steps per minute
  predicted_vertical_oscillation NUMERIC(4,2), -- cm
  
  -- Integration Status
  has_strava BOOLEAN DEFAULT FALSE,
  strava_athlete_id TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add new columns if they don't exist (for upgrading existing table)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'rom_tests') THEN
    ALTER TABLE athlete_profiles ADD COLUMN rom_tests JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'aisri_score') THEN
    ALTER TABLE athlete_profiles ADD COLUMN aisri_score INTEGER;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'risk_category') THEN
    ALTER TABLE athlete_profiles ADD COLUMN risk_category TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'predicted_stride_length') THEN
    ALTER TABLE athlete_profiles ADD COLUMN predicted_stride_length NUMERIC(4,2);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'predicted_cadence') THEN
    ALTER TABLE athlete_profiles ADD COLUMN predicted_cadence INTEGER;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'predicted_vertical_oscillation') THEN
    ALTER TABLE athlete_profiles ADD COLUMN predicted_vertical_oscillation NUMERIC(4,2);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'athlete_profiles' AND column_name = 'strava_athlete_id') THEN
    ALTER TABLE athlete_profiles ADD COLUMN strava_athlete_id TEXT;
  END IF;
END $$;

-- Index for fast athlete lookup (safe to re-run)
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_athlete_id ON athlete_profiles(athlete_id);
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_email ON athlete_profiles(email);
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_strava_athlete_id ON athlete_profiles(strava_athlete_id);
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_risk_category ON athlete_profiles(risk_category);
CREATE INDEX IF NOT EXISTS idx_athlete_profiles_aisri_score ON athlete_profiles(aisri_score);

-- Enable Row Level Security
ALTER TABLE athlete_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public insert" ON athlete_profiles;
DROP POLICY IF EXISTS "Allow athlete read own profile" ON athlete_profiles;
DROP POLICY IF EXISTS "Allow athlete update own profile" ON athlete_profiles;

-- Policy: Anyone can insert (signup)
CREATE POLICY "Allow public insert" ON athlete_profiles
  FOR INSERT
  WITH CHECK (true);

-- Policy: Athletes can read their own profile
CREATE POLICY "Allow athlete read own profile" ON athlete_profiles
  FOR SELECT
  USING (true);

-- Policy: Athletes can update their own profile
CREATE POLICY "Allow athlete update own profile" ON athlete_profiles
  FOR UPDATE
  USING (true);

-- Comments
COMMENT ON TABLE athlete_profiles IS 'Stores athlete signup data, AISRI evaluation scores, and predicted running metrics';
COMMENT ON COLUMN athlete_profiles.pillars IS 'JSONB object with keys: running, strength, rom, balance, alignment, mobility (all 0-100)';
COMMENT ON COLUMN athlete_profiles.rom_tests IS 'JSONB object with detailed ROM test measurements: {hip_flexion: degrees, hip_extension: degrees, ankle_dorsiflexion: degrees, etc.}';
COMMENT ON COLUMN athlete_profiles.aisri_score IS 'Calculated total AISRI score (0-1000) based on weighted pillar formula';
COMMENT ON COLUMN athlete_profiles.risk_category IS 'Risk-based training zone: AR (Active Recovery), F (Foundation), EN (Endurance), TH (Threshold), P (Peak)';
COMMENT ON COLUMN athlete_profiles.predicted_stride_length IS 'Predicted stride length in meters based on ROM and strength scores';
COMMENT ON COLUMN athlete_profiles.predicted_cadence IS 'Predicted running cadence in steps per minute based on mobility scores';
COMMENT ON COLUMN athlete_profiles.predicted_vertical_oscillation IS 'Predicted vertical oscillation in cm based on ROM scores';
