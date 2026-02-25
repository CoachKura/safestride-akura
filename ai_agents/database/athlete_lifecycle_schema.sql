-- ============================================================================
-- ATHLETE LIFECYCLE MANAGEMENT SYSTEM - DATABASE SCHEMA
-- ============================================================================
-- Complete athlete journey: Signup → Baseline → Daily Tracking → Goal Achievement
-- Created: February 25, 2026
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE 1: ATHLETE DETAILED PROFILE
-- ============================================================================
-- Comprehensive athlete information beyond basic profile
-- Captures "BEFORE signup" baseline and goals

CREATE TABLE IF NOT EXISTS athlete_detailed_profile (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(athlete_id) UNIQUE NOT NULL,
  
  -- Signup Information (BEFORE state)
  signup_date TIMESTAMP DEFAULT NOW(),
  current_level VARCHAR(20) CHECK (current_level IN ('beginner', 'intermediate', 'advanced')),
  
  -- Goal Setting
  primary_goal VARCHAR(50), -- '5K', '10K', 'Half Marathon', 'Marathon', 'Ultra'
  goal_type VARCHAR(20) CHECK (goal_type IN ('time_based', 'pace_based', 'completion', 'distance')),
  goal_target_time INTERVAL, -- for time-based goals (e.g., '00:50:00' for 50 min 10K)
  goal_target_pace INTERVAL, -- for pace-based goals (e.g., '00:05:00' for 5:00/km)
  target_race_date DATE,
  weeks_to_goal INTEGER GENERATED ALWAYS AS (
    EXTRACT(DAYS FROM (target_race_date - signup_date)) / 7
  ) STORED,
  
  -- Baseline Metrics (BEFORE signup - from Strava history)
  before_signup_weekly_volume_km FLOAT,
  before_signup_avg_pace INTERVAL,
  before_signup_runs_per_week FLOAT,
  before_signup_longest_run_km FLOAT,
  before_signup_consistency_score FLOAT, -- 0-100
  before_signup_json JSONB, -- Full baseline data
  
  -- Current Physical Status
  current_weekly_volume_km FLOAT,
  current_avg_pace INTERVAL,
  current_max_hr INTEGER,
  current_resting_hr INTEGER,
  target_hr_zone_percent INTEGER DEFAULT 80,
  calculated_target_hr INTEGER GENERATED ALWAYS AS (
    CASE 
      WHEN current_max_hr IS NOT NULL AND target_hr_zone_percent IS NOT NULL 
      THEN CAST((current_max_hr * target_hr_zone_percent / 100.0) AS INTEGER)
      ELSE NULL
    END
  ) STORED,
  
  -- Injury History & Status
  injury_history JSONB DEFAULT '[]'::jsonb, -- [{type, date, severity, recovery_days, notes}]
  current_injuries JSONB DEFAULT '[]'::jsonb, -- [{area, severity, status, date_reported}]
  injury_prone_areas TEXT[] DEFAULT ARRAY[]::TEXT[],
  has_active_injury BOOLEAN DEFAULT FALSE,
  
  -- Training Background
  years_of_running INTEGER,
  previous_races JSONB DEFAULT '[]'::jsonb, -- [{race_type, distance, date, time, pace, place}]
  training_frequency_per_week INTEGER,
  longest_race_completed VARCHAR(30), -- '5K', '10K', 'Half', 'Marathon'
  
  -- Preferences & Availability
  preferred_training_days TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['Monday', 'Wednesday', 'Friday']
  available_training_time_minutes INTEGER DEFAULT 60,
  preferred_training_time VARCHAR(20), -- 'morning', 'afternoon', 'evening'
  equipment_available JSONB DEFAULT '{}'::jsonb, -- {gym: true, treadmill: false, hr_monitor: true}
  
  -- Assessment Status
  baseline_assessment_status VARCHAR(20) DEFAULT 'not_started' 
    CHECK (baseline_assessment_status IN ('not_started', 'in_progress', 'completed', 'skipped')),
  baseline_start_date DATE,
  baseline_completion_date DATE,
  baseline_completion_percent INTEGER DEFAULT 0 CHECK (baseline_completion_percent BETWEEN 0 AND 100),
  
  -- Coach Assignment & Communication
  assigned_coach_id UUID, -- For future human coach integration
  communication_preferences JSONB DEFAULT '{}'::jsonb, -- {telegram: true, email: true, sms: false}
  timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

-- Indexes for athlete_detailed_profile
CREATE INDEX idx_athlete_detailed_profile_athlete_id ON athlete_detailed_profile(athlete_id);
CREATE INDEX idx_athlete_detailed_profile_level ON athlete_detailed_profile(current_level);
CREATE INDEX idx_athlete_detailed_profile_baseline_status ON athlete_detailed_profile(baseline_assessment_status);
CREATE INDEX idx_athlete_detailed_profile_active ON athlete_detailed_profile(is_active);

-- ============================================================================
-- TABLE 2: BASELINE ASSESSMENT PLAN
-- ============================================================================
-- 14-day structured assessment plan to learn athlete's true capability
-- Includes running, strength, and ROM protocols

CREATE TABLE IF NOT EXISTS baseline_assessment_plan (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(athlete_id) NOT NULL,
  
  -- 14-Day Plan Structure
  day_number INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 14),
  workout_date DATE NOT NULL,
  
  -- Workout Components
  workout_type VARCHAR(30) NOT NULL 
    CHECK (workout_type IN (
      'easy_run', 'tempo_run', 'interval', 'long_run', 'recovery_run',
      'rest', 'strength', 'rom', 'cross_training', 'combined'
    )),
  workout_category VARCHAR(20) CHECK (workout_category IN ('running', 'strength', 'mobility', 'rest')),
  
  -- Workout Details (Structured)
  workout_details JSONB NOT NULL, -- {distance, pace_range, intervals, exercises, etc.}
  
  -- Expected Performance (Running workouts)
  expected_duration_minutes INTEGER,
  expected_distance_km FLOAT,
  expected_pace_min INTERVAL, -- Minimum acceptable pace
  expected_pace_max INTERVAL, -- Maximum acceptable pace
  expected_avg_hr INTEGER,
  expected_hr_zone JSONB, -- {min: 140, max: 160, target_percent: 80}
  expected_effort_level INTEGER CHECK (expected_effort_level BETWEEN 1 AND 10), -- RPE scale
  
  -- Strength & ROM Details (if applicable)
  strength_exercises JSONB DEFAULT '[]'::jsonb, -- [{name, sets, reps, notes}]
  rom_protocols JSONB DEFAULT '[]'::jsonb, -- [{stretch, duration_seconds, reps, notes}]
  
  -- Instructions & Guidance
  coach_instructions TEXT,
  focus_areas TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['cadence', 'form', 'breathing', 'heart_rate']
  form_cues TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['lean forward', 'quick feet', 'relaxed shoulders']
  safety_notes TEXT,
  
  -- Assessment Goals (What we're learning)
  assessment_purpose TEXT, -- 'baseline_fitness', 'lactate_threshold', 'speed_capability', etc.
  metrics_to_capture TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['avg_pace', 'avg_hr', 'cadence', 'consistency']
  
  -- Completion Status
  completion_status VARCHAR(20) DEFAULT 'scheduled' 
    CHECK (completion_status IN ('scheduled', 'sent', 'in_progress', 'completed', 'skipped', 'modified', 'failed')),
  completed_at TIMESTAMP,
  skipped_reason TEXT,
  
  -- Linked Performance Data
  performance_tracking_id UUID, -- Links to daily_performance_tracking after completion
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(athlete_id, day_number)
);

-- Indexes for baseline_assessment_plan
CREATE INDEX idx_baseline_plan_athlete_id ON baseline_assessment_plan(athlete_id);
CREATE INDEX idx_baseline_plan_date ON baseline_assessment_plan(workout_date);
CREATE INDEX idx_baseline_plan_day ON baseline_assessment_plan(day_number);
CREATE INDEX idx_baseline_plan_status ON baseline_assessment_plan(completion_status);
CREATE INDEX idx_baseline_plan_type ON baseline_assessment_plan(workout_type);

-- ============================================================================
-- TABLE 3: DAILY PERFORMANCE TRACKING
-- ============================================================================
-- Track GIVEN (assigned) vs EXPECTED (target) vs RESULT (actual)
-- Performance labels: BEST, GREAT, GOOD, AVERAGE, POOR

CREATE TABLE IF NOT EXISTS daily_performance_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(athlete_id) NOT NULL,
  workout_date DATE NOT NULL,
  
  -- Workout Assignment
  assigned_workout_id UUID REFERENCES baseline_assessment_plan(id),
  workout_type VARCHAR(30) NOT NULL,
  workout_category VARCHAR(20),
  
  -- ========== GIVEN (What was assigned) ==========
  given_workout JSONB NOT NULL, -- Complete assignment details
  given_duration_minutes INTEGER,
  given_distance_km FLOAT,
  given_pace_target INTERVAL,
  given_pace_range JSONB, -- {min, max}
  given_hr_target INTEGER,
  given_hr_zone JSONB, -- {min, max}
  given_effort_level INTEGER,
  
  -- ========== EXPECTED (What athlete should achieve) ==========
  expected_performance JSONB NOT NULL, -- Performance targets
  expected_completion_percent INTEGER DEFAULT 100,
  
  -- ========== RESULT (What actually happened) ==========
  actual_duration_minutes INTEGER,
  actual_distance_km FLOAT,
  actual_avg_pace INTERVAL,
  actual_max_hr INTEGER,
  actual_avg_hr INTEGER,
  actual_cadence INTEGER,
  actual_elevation_gain_m FLOAT,
  actual_effort_perceived INTEGER, -- 1-10 (RPE - Rate of Perceived Exertion)
  
  -- Activity Data Sources
  strava_activity_id BIGINT,
  garmin_activity_id VARCHAR(100),
  activity_data JSONB, -- Full activity details from Strava/Garmin
  activity_synced_at TIMESTAMP,
  
  -- ========== PERFORMANCE ANALYSIS ==========
  -- Quantitative Metrics
  performance_vs_expected_percent FLOAT, -- (actual / expected) * 100
  pace_variance_percent FLOAT, -- Deviation from expected pace
  hr_zone_adherence_percent FLOAT, -- % of time in target HR zone
  consistency_score FLOAT CHECK (consistency_score BETWEEN 0 AND 100), -- Pace consistency
  completion_percent FLOAT, -- % of workout completed
  
  -- Performance Label (Main Classification)
  performance_label VARCHAR(30) CHECK (performance_label IN (
    'BEST',           -- Exceeded expectations significantly (>110%)
    'GREAT',          -- Above expectations (105-110%)
    'GOOD',           -- Met expectations (95-105%)
    'AVERAGE',        -- Slightly below expectations (85-95%)
    'POOR',           -- Significantly below expectations (70-85%)
    'NEEDS_ATTENTION',-- Very poor or injured (<70%)
    'INCOMPLETE',     -- Workout not completed
    'SKIPPED'         -- Workout skipped
  )),
  performance_score FLOAT CHECK (performance_score BETWEEN 0 AND 100), -- Overall score 0-100
  performance_notes TEXT,
  
  -- Detailed Performance Breakdown
  pacing_quality VARCHAR(20), -- 'excellent', 'good', 'inconsistent', 'poor'
  heart_rate_control VARCHAR(20), -- 'excellent', 'good', 'high', 'too_low'
  effort_management VARCHAR(20), -- 'well_paced', 'started_fast', 'negative_split'
  
  -- ========== ATHLETE FEEDBACK ==========
  athlete_comments TEXT,
  how_felt VARCHAR(30), -- 'amazing', 'strong', 'normal', 'tired', 'exhausted', 'painful'
  pain_or_discomfort JSONB DEFAULT '[]'::jsonb, -- [{area, severity_1_10, description}]
  weather_conditions JSONB, -- {temp, humidity, wind, conditions}
  sleep_quality INTEGER CHECK (sleep_quality BETWEEN 1 AND 10), -- Previous night
  nutrition_quality INTEGER CHECK (nutrition_quality BETWEEN 1 AND 10), -- Pre-workout
  stress_level INTEGER CHECK (stress_level BETWEEN 1 AND 10), -- Overall stress
  
  -- ========== AI ANALYSIS ==========
  ai_analysis JSONB, -- {strengths: [], improvements: [], injury_risk: {}, recommendations: []}
  ai_insights TEXT, -- Natural language summary
  ability_deduction FLOAT CHECK (ability_deduction BETWEEN 0 AND 100), -- Current ability score
  
  -- Injury Risk Assessment
  injury_risk_score FLOAT CHECK (injury_risk_score BETWEEN 0 AND 100),
  injury_risk_level VARCHAR(20) CHECK (injury_risk_level IN ('low', 'moderate', 'high', 'very_high')),
  injury_risk_factors JSONB DEFAULT '[]'::jsonb, -- [{factor, severity, recommendation}]
  
  -- ========== NEXT WORKOUT ADJUSTMENT ==========
  adjustment_needed BOOLEAN DEFAULT FALSE,
  adjustment_type VARCHAR(30), -- 'increase', 'maintain', 'decrease', 'rest', 'recovery'
  adjustment_reason TEXT,
  recommended_next_workout JSONB, -- Adaptive recommendation
  
  -- Coach Review
  coach_reviewed BOOLEAN DEFAULT FALSE,
  coach_notes TEXT,
  coach_reviewed_at TIMESTAMP,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for daily_performance_tracking
CREATE INDEX idx_performance_athlete_id ON daily_performance_tracking(athlete_id);
CREATE INDEX idx_performance_date ON daily_performance_tracking(workout_date);
CREATE INDEX idx_performance_label ON daily_performance_tracking(performance_label);
CREATE INDEX idx_performance_strava_id ON daily_performance_tracking(strava_activity_id);
CREATE INDEX idx_performance_date_athlete ON daily_performance_tracking(workout_date, athlete_id);

-- ============================================================================
-- TABLE 4: ADAPTIVE WORKOUT GENERATION
-- ============================================================================
-- Smart workout generation based on previous performance
-- Progressive overload with injury prevention

CREATE TABLE IF NOT EXISTS adaptive_workout_generation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(athlete_id) NOT NULL,
  
  -- Workout Schedule
  scheduled_date DATE NOT NULL,
  week_number INTEGER, -- Week in training plan
  workout_type VARCHAR(30) NOT NULL,
  workout_category VARCHAR(20),
  
  -- Generated Workout (Based on Previous Performance)
  workout_plan JSONB NOT NULL, -- Complete workout structure
  workout_title VARCHAR(200),
  workout_description TEXT,
  
  -- ========== ADAPTATION LOGIC ==========
  based_on_performance_ids UUID[] DEFAULT ARRAY[]::UUID[], -- References to daily_performance_tracking
  adaptation_factors JSONB, -- {prev_performance, recovery, injury_risk, weather, etc.}
  adaptation_reason TEXT, -- Why this workout was generated
  progressive_overload_percent FLOAT, -- % increase from previous similar workout
  
  -- Previous Workout Comparison
  previous_similar_workout_id UUID,
  change_from_previous JSONB, -- {distance_change, pace_change, volume_change}
  
  -- ========== WORKOUT DETAILS ==========
  target_duration_minutes INTEGER,
  target_distance_km FLOAT,
  target_pace_min INTERVAL,
  target_pace_max INTERVAL,
  target_pace_avg INTERVAL,
  
  -- Heart Rate Targets (80% focus)
  target_hr_zone JSONB NOT NULL, -- {min_hr, max_hr, target_percent: 80}
  target_avg_hr INTEGER,
  hr_zone_guidance TEXT, -- Instructions for staying in zone
  
  -- Specifics for Different Workout Types
  intervals JSONB DEFAULT '[]'::jsonb, -- [{distance, pace, recovery_time, reps}]
  tempo_segments JSONB DEFAULT '[]'::jsonb, -- [{distance, pace, hr_target}]
  strength_exercises JSONB DEFAULT '[]'::jsonb, -- [{exercise, sets, reps, weight, rest}]
  rom_protocols JSONB DEFAULT '[]'::jsonb, -- [{stretch, duration, reps, focus}]
  
  -- ========== SAFETY & INJURY PREVENTION ==========
  injury_risk_score FLOAT CHECK (injury_risk_score BETWEEN 0 AND 100),
  fatigue_level VARCHAR(20) CHECK (fatigue_level IN ('low', 'moderate', 'high', 'very_high')),
  recovery_recommendation TEXT,
  
  -- Training Load Management
  estimated_training_stress_score FLOAT, -- TSS estimate
  acute_chronic_workload_ratio FLOAT, -- ACWR (should be < 1.5)
  cumulative_fatigue_index FLOAT,
  
  -- Safety Checks
  safety_flags JSONB DEFAULT '[]'::jsonb, -- [{flag, severity, recommendation}]
  requires_coach_approval BOOLEAN DEFAULT FALSE,
  
  -- ========== GOAL ALIGNMENT ==========
  contributes_to_goal VARCHAR(100), -- How this workout helps achieve goal
  goal_progress_percent FLOAT CHECK (goal_progress_percent BETWEEN 0 AND 100), -- % toward race goal
  milestone_target TEXT, -- Specific milestone this workout works toward
  
  -- Race Preparation (if applicable)
  days_until_race INTEGER,
  is_race_week BOOLEAN DEFAULT FALSE,
  taper_phase VARCHAR(20), -- 'none', 'early_taper', 'peak_taper', 'race_week'
  
  -- ========== COACH GUIDANCE ==========
  ai_coach_notes TEXT,
  focus_for_this_workout TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['pacing', 'form', 'mental_toughness']
  form_cues TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['maintain cadence', 'controlled breathing']
  motivation_message TEXT,
  
  -- Pre-Workout Preparation
  warmup_routine JSONB, -- Structured warmup
  cooldown_routine JSONB, -- Structured cooldown
  nutrition_guidance TEXT,
  hydration_guidance TEXT,
  
  -- ========== STATUS & DELIVERY ==========
  generation_status VARCHAR(20) DEFAULT 'generated'
    CHECK (generation_status IN ('generated', 'reviewed', 'approved', 'sent', 'rejected')),
  sent_to_athlete_at TIMESTAMP,
  athlete_acknowledged BOOLEAN DEFAULT FALSE,
  athlete_acknowledged_at TIMESTAMP,
  
  -- Actual Execution Status
  execution_status VARCHAR(20) DEFAULT 'scheduled'
    CHECK (execution_status IN ('scheduled', 'in_progress', 'completed', 'skipped', 'modified', 'failed')),
  completed_performance_id UUID REFERENCES daily_performance_tracking(id),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for adaptive_workout_generation
CREATE INDEX idx_adaptive_workout_athlete_id ON adaptive_workout_generation(athlete_id);
CREATE INDEX idx_adaptive_workout_date ON adaptive_workout_generation(scheduled_date);
CREATE INDEX idx_adaptive_workout_status ON adaptive_workout_generation(execution_status);
CREATE INDEX idx_adaptive_workout_type ON adaptive_workout_generation(workout_type);

-- ============================================================================
-- TABLE 5: ATHLETE ABILITY PROGRESSION
-- ============================================================================
-- Daily ability deduction and progression tracking
-- Tracks improvement from baseline to current state

CREATE TABLE IF NOT EXISTS athlete_ability_progression (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES athlete_profiles(athlete_id) NOT NULL,
  assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- ========== ABILITY METRICS (Daily Deduction) ==========
  overall_ability_score FLOAT CHECK (overall_ability_score BETWEEN 0 AND 100),
  
  -- Component Scores
  endurance_score FLOAT CHECK (endurance_score BETWEEN 0 AND 100),
  speed_score FLOAT CHECK (speed_score BETWEEN 0 AND 100),
  strength_score FLOAT CHECK (strength_score BETWEEN 0 AND 100),
  form_score FLOAT CHECK (form_score BETWEEN 0 AND 100),
  consistency_score FLOAT CHECK (consistency_score BETWEEN 0 AND 100),
  mental_toughness_score FLOAT CHECK (mental_toughness_score BETWEEN 0 AND 100),
  
  -- Calculated from Recent Performances
  last_7_days_avg_performance FLOAT,
  last_14_days_avg_performance FLOAT,
  last_30_days_avg_performance FLOAT,
  performance_trend VARCHAR(20), -- 'improving', 'stable', 'declining'
  
  -- ========== PERFORMANCE INDICATORS ==========
  current_aerobic_threshold_pace INTERVAL, -- Pace at aerobic threshold
  current_vo2max_estimate FLOAT, -- Estimated VO2 max
  current_lactate_threshold_hr INTEGER, -- HR at lactate threshold
  current_sustainable_pace INTERVAL, -- Pace athlete can sustain at 80% HR
  current_5k_pace_estimate INTERVAL,
  current_10k_pace_estimate INTERVAL,
  current_hm_pace_estimate INTERVAL,
  current_marathon_pace_estimate INTERVAL,
  
  -- Training Zones (Calculated)
  easy_pace_range JSONB, -- {min, max} for easy runs
  tempo_pace_range JSONB, -- {min, max} for tempo runs
  interval_pace_range JSONB, -- {min, max} for intervals
  long_run_pace_range JSONB, -- {min, max} for long runs
  
  -- ========== GOAL PROGRESS ==========
  goal_pace_gap INTERVAL, -- Difference between current pace and goal pace
  goal_readiness_percent FLOAT CHECK (goal_readiness_percent BETWEEN 0 AND 100), -- 0-100: How ready for race goal
  estimated_finish_time INTERVAL, -- Current predicted race time at goal distance
  days_of_training INTEGER, -- Total days since baseline completion
  
  -- Progress Indicators
  pace_improvement_percent FLOAT, -- % improvement from baseline
  volume_increase_percent FLOAT, -- % increase in weekly volume
  consistency_improvement FLOAT, -- Change in consistency score
  
  -- ========== INJURY RISK ==========
  injury_risk_level VARCHAR(20) CHECK (injury_risk_level IN ('low', 'moderate', 'high', 'very_high')),
  injury_risk_factors JSONB DEFAULT '[]'::jsonb, -- [{factor, weight_0_1, description}]
  
  -- Training Load (Injury Prevention)
  acute_chronic_workload_ratio FLOAT, -- ACWR (should be 0.8-1.3)
  training_stress_score FLOAT, -- Current TSS
  training_stress_balance FLOAT, -- TSB (fitness - fatigue)
  fatigue_level FLOAT CHECK (fatigue_level BETWEEN 0 AND 100),
  freshness_level FLOAT CHECK (freshness_level BETWEEN 0 AND 100),
  
  -- Recovery Status
  recovery_quality VARCHAR(20), -- 'excellent', 'good', 'fair', 'poor'
  suggested_rest_days INTEGER, -- Recommended rest days
  
  -- ========== AI INSIGHTS ==========
  strengths TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['consistent', 'good_pacing', 'strong_endurance']
  areas_for_improvement TEXT[] DEFAULT ARRAY[]::TEXT[], -- ['speed_work', 'cadence']
  next_milestone TEXT, -- 'First sub-60min 10K'
  days_to_goal_readiness INTEGER, -- Estimated days until race-ready
  
  ai_recommendations TEXT[] DEFAULT ARRAY[]::TEXT[], -- Actionable recommendations
  coach_insights TEXT, -- Natural language insights
  
  -- ========== COMPARATIVE ANALYSIS ==========
  compared_to_baseline JSONB, -- {pace_change, volume_change, improvements: []}
  compared_to_last_week JSONB, -- Week-over-week changes
  compared_to_last_month JSONB, -- Month-over-month changes
  
  -- Peer Comparison (Optional)
  percentile_in_age_group FLOAT, -- Where athlete ranks in age group
  percentile_in_experience_group FLOAT, -- Compared to similar experience level
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(athlete_id, assessment_date)
);

-- Indexes for athlete_ability_progression
CREATE INDEX idx_ability_athlete_id ON athlete_ability_progression(athlete_id);
CREATE INDEX idx_ability_date ON athlete_ability_progression(assessment_date);
CREATE INDEX idx_ability_score ON athlete_ability_progression(overall_ability_score);
CREATE INDEX idx_ability_risk ON athlete_ability_progression(injury_risk_level);

-- ============================================================================
-- TABLE 6: EXISTING ATHLETE IMPORT
-- ============================================================================
-- Track import of existing athletes from Google Forms CSV
-- Manage onboarding flow for imported athletes

CREATE TABLE IF NOT EXISTS existing_athlete_import (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Import Metadata
  import_batch_id UUID NOT NULL, -- Group imports from same CSV
  import_date TIMESTAMP DEFAULT NOW(),
  import_source VARCHAR(50) CHECK (import_source IN ('google_form', 'csv_upload', 'manual', 'api')),
  import_filename VARCHAR(255),
  import_row_number INTEGER, -- Row in CSV
  
  -- Raw Data (As received)
  raw_data JSONB NOT NULL, -- Original form/CSV data
  
  -- Mapped Athlete Data
  athlete_email VARCHAR(255),
  athlete_name VARCHAR(100),
  phone_number VARCHAR(20),
  whatsapp_number VARCHAR(20),
  telegram_username VARCHAR(100),
  
  -- Parsed Profile
  parsed_profile JSONB NOT NULL, -- Structured athlete data mapped from form
  
  -- Validation
  validation_status VARCHAR(30) DEFAULT 'pending'
    CHECK (validation_status IN ('pending', 'valid', 'invalid', 'duplicate', 'needs_review')),
  validation_errors JSONB DEFAULT '[]'::jsonb, -- [{field, error, suggestion}]
  
  -- Import Status
  import_status VARCHAR(30) DEFAULT 'pending'
    CHECK (import_status IN (
      'pending', 'processing', 'athlete_created', 'invitation_sent', 
      'completed', 'error', 'skipped', 'duplicate'
    )),
  error_message TEXT,
  processing_notes TEXT,
  
  -- Linked Athlete
  created_athlete_id UUID REFERENCES athlete_profiles(athlete_id),
  athlete_created_at TIMESTAMP,
  
  -- Onboarding Progress
  invitation_sent BOOLEAN DEFAULT FALSE,
  invitation_sent_at TIMESTAMP,
  invitation_method VARCHAR(20), -- 'email', 'sms', 'telegram', 'whatsapp'
  
  -- Strava Connection Status
  strava_connected BOOLEAN DEFAULT FALSE,
  strava_connection_date TIMESTAMP,
  strava_athlete_id BIGINT,
  
  -- App/Web Signin Status
  signin_completed BOOLEAN DEFAULT FALSE,
  signin_date TIMESTAMP,
  initial_profile_completed BOOLEAN DEFAULT FALSE,
  
  -- Baseline Assessment Status
  baseline_started BOOLEAN DEFAULT FALSE,
  baseline_start_date DATE,
  
  -- Follow-up & Reminders
  reminder_count INTEGER DEFAULT 0,
  last_reminder_sent_at TIMESTAMP,
  next_followup_date DATE,
  
  -- Manual Review
  requires_manual_review BOOLEAN DEFAULT FALSE,
  review_reason TEXT,
  reviewed_by VARCHAR(100),
  reviewed_at TIMESTAMP,
  review_notes TEXT,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for existing_athlete_import
CREATE INDEX idx_import_batch ON existing_athlete_import(import_batch_id);
CREATE INDEX idx_import_email ON existing_athlete_import(athlete_email);
CREATE INDEX idx_import_status ON existing_athlete_import(import_status);
CREATE INDEX idx_import_athlete_id ON existing_athlete_import(created_athlete_id);
CREATE INDEX idx_import_validation ON existing_athlete_import(validation_status);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
CREATE TRIGGER update_athlete_detailed_profile_updated_at
    BEFORE UPDATE ON athlete_detailed_profile
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_baseline_assessment_plan_updated_at
    BEFORE UPDATE ON baseline_assessment_plan
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_performance_tracking_updated_at
    BEFORE UPDATE ON daily_performance_tracking
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_adaptive_workout_generation_updated_at
    BEFORE UPDATE ON adaptive_workout_generation
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_athlete_ability_progression_updated_at
    BEFORE UPDATE ON athlete_ability_progression
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_existing_athlete_import_updated_at
    BEFORE UPDATE ON existing_athlete_import
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Current athlete status with all key metrics
CREATE OR REPLACE VIEW athlete_current_status AS
SELECT 
    ap.athlete_id,
    ap.name,
    ap.email,
    adp.current_level,
    adp.primary_goal,
    adp.goal_target_time,
    adp.target_race_date,
    adp.baseline_assessment_status,
    adp.baseline_completion_percent,
    aap.overall_ability_score,
    aap.goal_readiness_percent,
    aap.injury_risk_level,
    aap.current_sustainable_pace,
    aap.goal_pace_gap
FROM athlete_profiles ap
LEFT JOIN athlete_detailed_profile adp ON ap.athlete_id = adp.athlete_id
LEFT JOIN LATERAL (
    SELECT * FROM athlete_ability_progression
    WHERE athlete_id = ap.athlete_id
    ORDER BY assessment_date DESC
    LIMIT 1
) aap ON true
WHERE adp.is_active = TRUE;

-- View: Recent performance summary (last 7 days)
CREATE OR REPLACE VIEW recent_performance_summary AS
SELECT 
    athlete_id,
    COUNT(*) as workouts_completed,
    AVG(performance_score) as avg_performance_score,
    SUM(actual_distance_km) as total_distance_km,
    AVG(actual_avg_hr) as avg_heart_rate,
    MODE() WITHIN GROUP (ORDER BY performance_label) as most_common_label
FROM daily_performance_tracking
WHERE workout_date >= CURRENT_DATE - INTERVAL '7 days'
    AND completion_percent >= 80
GROUP BY athlete_id;

-- View: Upcoming workouts
CREATE OR REPLACE VIEW upcoming_workouts AS
SELECT 
    awg.athlete_id,
    awg.scheduled_date,
    awg.workout_type,
    awg.workout_title,
    awg.target_distance_km,
    awg.target_pace_avg,
    awg.target_hr_zone,
    awg.execution_status,
    awg.ai_coach_notes
FROM adaptive_workout_generation awg
WHERE awg.scheduled_date >= CURRENT_DATE
    AND awg.execution_status IN ('scheduled', 'sent')
ORDER BY awg.athlete_id, awg.scheduled_date;

-- ============================================================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- ============================================================================

-- Function: Calculate performance label from metrics
CREATE OR REPLACE FUNCTION calculate_performance_label(
    actual_vs_expected FLOAT,
    completion_pct FLOAT,
    hr_adherence FLOAT
) RETURNS VARCHAR(30) AS $$
BEGIN
    -- If workout incomplete or very poor adherence
    IF completion_pct < 70 OR hr_adherence < 50 THEN
        RETURN 'NEEDS_ATTENTION';
    END IF;
    
    IF completion_pct < 85 THEN
        RETURN 'INCOMPLETE';
    END IF;
    
    -- Based on performance vs expected
    IF actual_vs_expected >= 110 THEN
        RETURN 'BEST';
    ELSIF actual_vs_expected >= 105 THEN
        RETURN 'GREAT';
    ELSIF actual_vs_expected >= 95 THEN
        RETURN 'GOOD';
    ELSIF actual_vs_expected >= 85 THEN
        RETURN 'AVERAGE';
    ELSIF actual_vs_expected >= 70 THEN
        RETURN 'POOR';
    ELSE
        RETURN 'NEEDS_ATTENTION';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE DATA INSERTION (FOR TESTING)
-- ============================================================================
-- Uncomment below to insert sample data

/*
-- Sample athlete with complete profile
INSERT INTO athlete_detailed_profile (
    athlete_id,
    current_level,
    primary_goal,
    goal_type,
    goal_target_time,
    target_race_date,
    before_signup_weekly_volume_km,
    before_signup_avg_pace,
    current_max_hr,
    current_resting_hr,
    training_frequency_per_week
) VALUES (
    'sample-athlete-uuid-here',
    'beginner',
    '10K',
    'time_based',
    '00:60:00'::interval,
    CURRENT_DATE + INTERVAL '16 weeks',
    10.0,
    '00:07:30'::interval,
    190,
    60,
    3
);
*/

-- ============================================================================
-- PERMISSIONS (Adjust based on your Supabase setup)
-- ============================================================================
-- Grant permissions to authenticated users

-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- COMPLETION
-- ============================================================================
-- Schema creation complete!
-- Total tables: 6
-- Total views: 3
-- Total functions: 2
-- Total triggers: 6
