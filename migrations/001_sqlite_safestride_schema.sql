-- SafeStride SQLite Schema for Cloudflare D1
-- Version 1.0 - Compatible with SQLite

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Profiles table (users/athletes)
CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'athlete' CHECK(role IN ('athlete', 'coach', 'admin')),
  coach_id TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  onboarding_completed INTEGER DEFAULT 0,
  gender TEXT CHECK(gender IN ('male', 'female', 'other')),
  age INTEGER,
  weight REAL,
  height REAL,
  resting_hr INTEGER,
  max_hr INTEGER,
  FOREIGN KEY (coach_id) REFERENCES profiles(id)
);

-- Physical assessments
CREATE TABLE IF NOT EXISTS physical_assessments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id TEXT NOT NULL,
  assessment_date TEXT DEFAULT (datetime('now')),
  assessment_type TEXT DEFAULT 'monthly' CHECK(assessment_type IN ('initial', 'monthly', 'quarterly', 'injury')),
  rom_score REAL,
  strength_score REAL,
  balance_score REAL,
  mobility_score REAL,
  alignment_score REAL,
  running_score REAL,
  notes TEXT,
  metadata TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_assessments_athlete ON physical_assessments(athlete_id);
CREATE INDEX IF NOT EXISTS idx_assessments_date ON physical_assessments(assessment_date);

-- Assessment media (images/videos)
CREATE TABLE IF NOT EXISTS assessment_media (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  assessment_id INTEGER NOT NULL,
  media_type TEXT CHECK(media_type IN ('image', 'video')),
  file_url TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  pillar TEXT,
  analysis_data TEXT,
  uploaded_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (assessment_id) REFERENCES physical_assessments(id)
);

-- Training plans
CREATE TABLE IF NOT EXISTS training_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id TEXT NOT NULL,
  plan_name TEXT NOT NULL,
  duration_weeks INTEGER DEFAULT 12,
  plan_data TEXT,
  aisri_score_at_creation REAL,
  status TEXT DEFAULT 'active' CHECK(status IN ('draft', 'active', 'completed', 'cancelled')),
  created_by TEXT,
  approved_by_coach INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id),
  FOREIGN KEY (created_by) REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_plans_athlete ON training_plans(athlete_id);

-- Daily workouts
CREATE TABLE IF NOT EXISTS daily_workouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id TEXT NOT NULL,
  training_plan_id INTEGER,
  workout_date TEXT NOT NULL,
  week_number INTEGER,
  day_number INTEGER,
  workout_type TEXT,
  workout_name TEXT NOT NULL,
  description TEXT,
  target_distance REAL,
  target_duration INTEGER,
  target_hr_zone TEXT,
  intensity_level TEXT,
  completed INTEGER DEFAULT 0,
  completion_date TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id),
  FOREIGN KEY (training_plan_id) REFERENCES training_plans(id),
  UNIQUE(athlete_id, workout_date)
);

CREATE INDEX IF NOT EXISTS idx_workouts_athlete ON daily_workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workouts_date ON daily_workouts(workout_date);

-- Workout completions
CREATE TABLE IF NOT EXISTS workout_completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  workout_id INTEGER NOT NULL,
  athlete_id TEXT NOT NULL,
  completed_at TEXT DEFAULT (datetime('now')),
  actual_distance REAL,
  actual_duration INTEGER,
  average_hr INTEGER,
  max_hr INTEGER,
  perceived_effort INTEGER,
  notes TEXT,
  strava_activity_id TEXT,
  FOREIGN KEY (workout_id) REFERENCES daily_workouts(id),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id)
);

-- Evaluation schedule
CREATE TABLE IF NOT EXISTS evaluation_schedule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id TEXT NOT NULL,
  next_evaluation_date TEXT NOT NULL,
  evaluation_type TEXT DEFAULT 'monthly',
  reminder_sent_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'missed')),
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_eval_athlete ON evaluation_schedule(athlete_id);
CREATE INDEX IF NOT EXISTS idx_eval_date ON evaluation_schedule(next_evaluation_date);

-- AISRI score history
CREATE TABLE IF NOT EXISTS aisri_score_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id TEXT NOT NULL,
  assessment_id INTEGER,
  aisri_score REAL NOT NULL,
  risk_category TEXT,
  rom_score REAL,
  strength_score REAL,
  balance_score REAL,
  mobility_score REAL,
  alignment_score REAL,
  running_score REAL,
  pillar_scores TEXT,
  recorded_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id),
  FOREIGN KEY (assessment_id) REFERENCES physical_assessments(id)
);

CREATE INDEX IF NOT EXISTS idx_aisri_athlete ON aisri_score_history(athlete_id);
CREATE INDEX IF NOT EXISTS idx_aisri_date ON aisri_score_history(recorded_at);

-- Training load
CREATE TABLE IF NOT EXISTS training_load (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id TEXT NOT NULL,
  date TEXT NOT NULL,
  daily_load REAL,
  acute_load REAL,
  chronic_load REAL,
  acr_ratio REAL,
  weekly_distance REAL,
  weekly_duration INTEGER,
  load_status TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (athlete_id) REFERENCES profiles(id),
  UNIQUE(athlete_id, date)
);

CREATE INDEX IF NOT EXISTS idx_load_athlete ON training_load(athlete_id);
CREATE INDEX IF NOT EXISTS idx_load_date ON training_load(date);

-- Insert initial data (optional)
-- You can add sample data here if needed
