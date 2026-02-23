-- =====================================================
-- COMPLETE DATABASE DEPLOYMENT FOR AI AGENTS
-- Run this in Supabase SQL Editor to create all tables
-- =====================================================

-- =====================================================
-- STEP 1: CREATE/UPDATE AISRI AND TRAINING LOAD TABLES
-- =====================================================

-- Drop existing AISRI_assessments if it has wrong schema, then recreate
DROP TABLE IF EXISTS "AISRI_assessments" CASCADE;

-- Create AISRI_assessments table with simple schema for AI agents
CREATE TABLE "AISRI_assessments" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    aisri_score INT NOT NULL CHECK (aisri_score >= 0 AND aisri_score <= 1000),
    pillars JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_aisri_assessments_athlete_id ON "AISRI_assessments"(athlete_id);
CREATE INDEX idx_aisri_assessments_created_at ON "AISRI_assessments"(created_at DESC);

ALTER TABLE "AISRI_assessments" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read AISRI"
ON "AISRI_assessments"
FOR SELECT
USING (true);

CREATE POLICY "Allow insert AISRI"
ON "AISRI_assessments"
FOR INSERT
WITH CHECK (true);

CREATE TABLE IF NOT EXISTS training_load_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    load_score NUMERIC(10,2) NOT NULL,
    activity_type TEXT,
    duration_minutes INT,
    distance_km NUMERIC(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_training_load_athlete_id ON training_load_metrics(athlete_id);
CREATE INDEX IF NOT EXISTS idx_training_load_created_at ON training_load_metrics(created_at DESC);

ALTER TABLE training_load_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read training load" ON training_load_metrics;
DROP POLICY IF EXISTS "Allow insert training load" ON training_load_metrics;

CREATE POLICY "Allow public read training load"
ON training_load_metrics
FOR SELECT
USING (true);

CREATE POLICY "Allow insert training load"
ON training_load_metrics
FOR INSERT
WITH CHECK (true);

-- =====================================================
-- STEP 2: CREATE INJURY RISK PREDICTIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS injury_risk_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    risk_score INT NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level TEXT NOT NULL CHECK (risk_level IN ('LOW', 'MODERATE', 'HIGH')),
    load_ratio NUMERIC(5,2),
    aisri_trend INT,
    latest_aisri_score INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_injury_predictions_athlete_id ON injury_risk_predictions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_injury_predictions_created_at ON injury_risk_predictions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_injury_predictions_athlete_created ON injury_risk_predictions(athlete_id, created_at DESC);

ALTER TABLE injury_risk_predictions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read of injury predictions" ON injury_risk_predictions;
DROP POLICY IF EXISTS "Allow service role to insert predictions" ON injury_risk_predictions;

CREATE POLICY "Allow public read of injury predictions"
ON injury_risk_predictions
FOR SELECT
USING (true);

CREATE POLICY "Allow service role to insert predictions"
ON injury_risk_predictions
FOR INSERT
WITH CHECK (true);

-- =====================================================
-- STEP 3: CREATE WORKOUTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    workout_type TEXT,
    distance NUMERIC(10,2),
    duration_minutes INT,
    average_pace NUMERIC(10,2),
    average_heart_rate INT,
    calories INT,
    elevation_gain NUMERIC(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workouts_athlete ON workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workouts_created ON workouts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_athlete_created ON workouts(athlete_id, created_at DESC);

ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read workouts" ON workouts;
DROP POLICY IF EXISTS "Allow service role insert workouts" ON workouts;
DROP POLICY IF EXISTS "Allow athletes update own workouts" ON workouts;

CREATE POLICY "Allow public read workouts"
ON workouts
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert workouts"
ON workouts
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow athletes update own workouts"
ON workouts
FOR UPDATE
USING (true)
WITH CHECK (true);

-- =====================================================
-- STEP 4: CREATE RACE PREDICTIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS race_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    vo2max NUMERIC(5,1) NOT NULL,
    predicted_5k TEXT NOT NULL,
    predicted_10k TEXT NOT NULL,
    predicted_half_marathon TEXT NOT NULL,
    predicted_marathon TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_race_predictions_athlete ON race_predictions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_race_predictions_created ON race_predictions(created_at DESC);

ALTER TABLE race_predictions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read race predictions" ON race_predictions;
DROP POLICY IF EXISTS "Allow service role insert race predictions" ON race_predictions;

CREATE POLICY "Allow public read race predictions"
ON race_predictions
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert race predictions"
ON race_predictions
FOR INSERT
WITH CHECK (true);

-- =====================================================
-- STEP 5: CREATE AI DECISIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    decision TEXT,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_decisions_athlete ON ai_decisions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_ai_decisions_created ON ai_decisions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_decisions_athlete_created ON ai_decisions(athlete_id, created_at DESC);

ALTER TABLE ai_decisions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read decisions" ON ai_decisions;
DROP POLICY IF EXISTS "Allow service role insert decisions" ON ai_decisions;

CREATE POLICY "Allow public read decisions"
ON ai_decisions
FOR SELECT
USING (true);

CREATE POLICY "Allow service role insert decisions"
ON ai_decisions
FOR INSERT
WITH CHECK (true);

-- =====================================================
-- STEP 6: INSERT SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert AISRI assessments for first test athlete (UUID from profiles table)
INSERT INTO "AISRI_assessments" (athlete_id, aisri_score, pillars, created_at)
VALUES 
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 65, '{"running": 70, "strength": 60, "rom": 65, "balance": 65, "alignment": 60, "mobility": 70}'::jsonb, NOW() - INTERVAL '1 day'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 68, '{"running": 75, "strength": 62, "rom": 68, "balance": 68, "alignment": 62, "mobility": 72}'::jsonb, NOW())
ON CONFLICT DO NOTHING;

-- Insert AISRI for second test athlete
INSERT INTO "AISRI_assessments" (athlete_id, aisri_score, pillars, created_at)
VALUES 
    ('cf77e535-a46b-4a25-b035-4e7c2a458e7a', 52, '{"running": 50, "strength": 50, "rom": 50, "balance": 50, "alignment": 50, "mobility": 60}'::jsonb, NOW())
ON CONFLICT DO NOTHING;

-- Insert training load metrics (last 7 days for first athlete)
INSERT INTO training_load_metrics (athlete_id, load_score, activity_type, duration_minutes, distance_km, created_at)
SELECT 
    '33308fc1-3545-431d-a5e7-648b52e1866c',
    (random() * 30 + 50)::numeric(10,2),
    'run',
    (random() * 30 + 30)::int,
    (random() * 5 + 5)::numeric(10,2),
    NOW() - (interval '1 day' * gs)
FROM generate_series(0, 6) gs
ON CONFLICT DO NOTHING;

-- Insert training load for second athlete
INSERT INTO training_load_metrics (athlete_id, load_score, activity_type, duration_minutes, distance_km, created_at)
SELECT 
    'cf77e535-a46b-4a25-b035-4e7c2a458e7a',
    (random() * 30 + 40)::numeric(10,2),
    'run',
    (random() * 30 + 25)::int,
    (random() * 4 + 4)::numeric(10,2),
    NOW() - (interval '1 day' * gs)
FROM generate_series(0, 6) gs
ON CONFLICT DO NOTHING;

-- Insert workout data with pace (last 20 workouts for first athlete)
INSERT INTO workouts (athlete_id, workout_type, distance, duration_minutes, average_pace, average_heart_rate, created_at)
VALUES 
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 5.0, 30, 360, 145, NOW() - INTERVAL '1 day'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 8.0, 48, 360, 150, NOW() - INTERVAL '2 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 10.0, 58, 348, 152, NOW() - INTERVAL '3 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 5.0, 29, 348, 148, NOW() - INTERVAL '4 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 12.0, 72, 360, 155, NOW() - INTERVAL '5 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 6.0, 36, 360, 145, NOW() - INTERVAL '6 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 8.0, 46, 345, 150, NOW() - INTERVAL '7 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 10.0, 57, 342, 152, NOW() - INTERVAL '8 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 5.0, 28, 336, 148, NOW() - INTERVAL '9 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 15.0, 90, 360, 160, NOW() - INTERVAL '10 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 5.0, 30, 360, 145, NOW() - INTERVAL '11 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 8.0, 48, 360, 150, NOW() - INTERVAL '12 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 10.0, 58, 348, 152, NOW() - INTERVAL '13 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 6.0, 35, 350, 148, NOW() - INTERVAL '14 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 12.0, 70, 350, 155, NOW() - INTERVAL '15 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 5.0, 30, 360, 145, NOW() - INTERVAL '16 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 8.0, 48, 360, 150, NOW() - INTERVAL '17 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 10.0, 57, 342, 152, NOW() - INTERVAL '18 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 5.0, 29, 348, 148, NOW() - INTERVAL '19 days'),
    ('33308fc1-3545-431d-a5e7-648b52e1866c', 'run', 15.0, 88, 352, 160, NOW() - INTERVAL '20 days')
ON CONFLICT DO NOTHING;

-- Insert workouts for second athlete
INSERT INTO workouts (athlete_id, workout_type, distance, duration_minutes, average_pace, average_heart_rate, created_at)
VALUES 
    ('cf77e535-a46b-4a25-b035-4e7c2a458e7a', 'run', 5.0, 32, 384, 140, NOW() - INTERVAL '1 day'),
    ('cf77e535-a46b-4a25-b035-4e7c2a458e7a', 'run', 7.0, 46, 394, 145, NOW() - INTERVAL '2 days'),
    ('cf77e535-a46b-4a25-b035-4e7c2a458e7a', 'run', 8.0, 54, 405, 148, NOW() - INTERVAL '3 days'),
    ('cf77e535-a46b-4a25-b035-4e7c2a458e7a', 'run', 5.0, 33, 396, 142, NOW() - INTERVAL '4 days')
ON CONFLICT DO NOTHING;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check table row counts
SELECT 'AISRI_assessments' as table_name, COUNT(*) as row_count FROM "AISRI_assessments"
UNION ALL
SELECT 'training_load_metrics', COUNT(*) FROM training_load_metrics
UNION ALL
SELECT 'injury_risk_predictions', COUNT(*) FROM injury_risk_predictions
UNION ALL
SELECT 'workouts', COUNT(*) FROM workouts
UNION ALL
SELECT 'race_predictions', COUNT(*) FROM race_predictions
UNION ALL
SELECT 'ai_decisions', COUNT(*) FROM ai_decisions;
