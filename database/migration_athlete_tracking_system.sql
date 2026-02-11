-- ═══════════════════════════════════════════════════════
-- ATHLETE TRACKING & PROGRESS SYSTEM - DATABASE SCHEMA
-- ═══════════════════════════════════════════════════════
-- 
-- Purpose: Comprehensive tracking of athlete progress, injuries,
--          goals, gait analysis, and AI-powered insights
--          
-- Features:
-- - Body measurements timeline tracking
-- - Injury history and recovery monitoring
-- - Gait pathology analysis storage
-- - Recovery roadmap progress tracking
-- - Goals and milestones management
-- - Coach-athlete messaging system
-- - Workout AI analysis results storage
-- ═══════════════════════════════════════════════════════

-- ┌─────────────────────────────────────────────────────┐
-- │ 1. BODY MEASUREMENTS TABLE                          │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.body_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Core Measurements
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg >= 30 AND weight_kg <= 200),
    height_cm INTEGER NOT NULL CHECK (height_cm >= 100 AND height_cm <= 250),
    
    -- Calculated Metrics
    bmi NUMERIC(4,2) GENERATED ALWAYS AS (weight_kg / POWER(height_cm / 100.0, 2)) STORED,
    bmi_category TEXT GENERATED ALWAYS AS (
        CASE 
            WHEN weight_kg / POWER(height_cm / 100.0, 2) < 18.5 THEN 'underweight'
            WHEN weight_kg / POWER(height_cm / 100.0, 2) < 25 THEN 'normal'
            WHEN weight_kg / POWER(height_cm / 100.0, 2) < 30 THEN 'overweight'
            ELSE 'obese'
        END
    ) STORED,
    
    -- Optional Body Composition
    body_fat_percentage NUMERIC(4,2) CHECK (body_fat_percentage >= 3 AND body_fat_percentage <= 60),
    muscle_mass_kg NUMERIC(5,2) CHECK (muscle_mass_kg >= 10 AND muscle_mass_kg <= 100),
    bone_mass_kg NUMERIC(4,2) CHECK (bone_mass_kg >= 1 AND bone_mass_kg <= 10),
    water_percentage NUMERIC(4,2) CHECK (water_percentage >= 30 AND water_percentage <= 80),
    visceral_fat_rating INTEGER CHECK (visceral_fat_rating >= 1 AND visceral_fat_rating <= 59),
    
    -- Body Measurements
    chest_cm NUMERIC(5,2) CHECK (chest_cm >= 50 AND chest_cm <= 200),
    waist_cm NUMERIC(5,2) CHECK (waist_cm >= 40 AND waist_cm <= 200),
    hips_cm NUMERIC(5,2) CHECK (hips_cm >= 50 AND hips_cm <= 200),
    thigh_cm NUMERIC(5,2) CHECK (thigh_cm >= 30 AND thigh_cm <= 100),
    calf_cm NUMERIC(5,2) CHECK (calf_cm >= 20 AND calf_cm <= 60),
    
    -- Measurement Context
    measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    measurement_time TIME,
    measurement_conditions TEXT CHECK (measurement_conditions IN ('fasted_morning', 'pre_workout', 'post_workout', 'evening', 'random')),
    
    -- Device/Method
    measured_by TEXT CHECK (measured_by IN ('manual', 'smart_scale', 'dexa_scan', 'bioimpedance', 'coach')),
    device_model TEXT,
    
    -- Notes
    notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_body_measurements_user_id ON public.body_measurements(user_id);
CREATE INDEX idx_body_measurements_date ON public.body_measurements(measurement_date DESC);
CREATE INDEX idx_body_measurements_user_date ON public.body_measurements(user_id, measurement_date DESC);

-- ┌─────────────────────────────────────────────────────┐
-- │ 2. INJURY HISTORY & TRACKING TABLE                  │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.injuries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Injury Details
    injury_name TEXT NOT NULL, -- e.g., 'Plantar Fasciitis', 'Shin Splints', 'Runner's Knee'
    injury_type TEXT NOT NULL CHECK (injury_type IN ('acute', 'chronic', 'overuse', 'traumatic')),
    affected_area TEXT NOT NULL CHECK (affected_area IN (
        'left_ankle', 'right_ankle', 'left_knee', 'right_knee',
        'left_hip', 'right_hip', 'left_shin', 'right_shin',
        'left_foot', 'right_foot', 'left_calf', 'right_calf',
        'lower_back', 'upper_back', 'left_shoulder', 'right_shoulder',
        'left_achilles', 'right_achilles', 'left_hamstring', 'right_hamstring',
        'left_quad', 'right_quad', 'it_band', 'groin', 'other'
    )),
    
    -- Severity & Status
    severity INTEGER NOT NULL CHECK (severity >= 1 AND severity <= 10),
    current_pain_level INTEGER CHECK (current_pain_level >= 0 AND current_pain_level <= 10),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'recovering', 'healed', 'chronic')),
    
    -- Timeline
    injury_date DATE NOT NULL,
    diagnosed_date DATE,
    expected_recovery_date DATE,
    actual_recovery_date DATE,
    -- days_since_injury calculated in view (uses CURRENT_DATE which is not immutable)
    
    -- Cause & Context
    caused_by TEXT, -- 'Increased mileage too quickly', 'Hard trail run', 'New shoes'
    related_workout_id UUID REFERENCES public.workouts(id) ON DELETE SET NULL,
    contributing_factors TEXT[], -- ['poor_form', 'inadequate_warmup', 'worn_shoes', 'overtraining']
    
    -- Treatment
    treatment_plan TEXT,
    medications TEXT[],
    physical_therapy BOOLEAN DEFAULT FALSE,
    rest_days INTEGER,
    cross_training_allowed BOOLEAN DEFAULT FALSE,
    
    -- Medical
    diagnosed_by TEXT, -- 'Self', 'Physical Therapist', 'Sports Doctor', 'Orthopedist'
    diagnosis_notes TEXT,
    medical_imaging TEXT CHECK (medical_imaging IN ('none', 'x_ray', 'mri', 'ultrasound', 'ct_scan')),
    imaging_results TEXT,
    
    -- Recovery Progress
    recovery_percentage INTEGER DEFAULT 0 CHECK (recovery_percentage >= 0 AND recovery_percentage <= 100),
    recovery_notes TEXT,
    
    -- Prevention
    prevention_recommendations TEXT[],
    corrective_exercises TEXT[],
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_injuries_user_id ON public.injuries(user_id);
CREATE INDEX idx_injuries_status ON public.injuries(status);
CREATE INDEX idx_injuries_affected_area ON public.injuries(affected_area);
CREATE INDEX idx_injuries_date ON public.injuries(injury_date DESC);
CREATE INDEX idx_injuries_user_status ON public.injuries(user_id, status);

-- ┌─────────────────────────────────────────────────────┐
-- │ 3. GAIT ANALYSIS HISTORY TABLE                      │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.gait_analysis_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    assessment_id UUID, -- Link to AISRI assessment
    
    -- Analysis Metadata
    analysis_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    analysis_version TEXT DEFAULT '1.0', -- Version of gait analysis algorithm
    
    -- Pathology Detection (Confidence Scores 0-100)
    bow_legs_confidence INTEGER CHECK (bow_legs_confidence >= 0 AND bow_legs_confidence <= 100),
    knock_knees_confidence INTEGER CHECK (knock_knees_confidence >= 0 AND knock_knees_confidence <= 100),
    overpronation_confidence INTEGER CHECK (overpronation_confidence >= 0 AND overpronation_confidence <= 100),
    underpronation_confidence INTEGER CHECK (underpronation_confidence >= 0 AND underpronation_confidence <= 100),
    
    -- Detected Pathologies (threshold >= 50)
    detected_pathologies TEXT[] DEFAULT ARRAY[]::TEXT[],
    primary_pathology TEXT CHECK (primary_pathology IN ('bow_legs', 'knock_knees', 'overpronation', 'underpronation', 'none')),
    
    -- Biomechanical Analysis
    force_vector_analysis JSONB, -- Detailed force distribution data
    muscle_activation_patterns JSONB, -- Overactive/underactive muscle groups
    energy_cost_percentage NUMERIC(4,2), -- Efficiency loss (e.g., 12.5%)
    
    -- Injury Risk Assessment
    injury_risk_level TEXT CHECK (injury_risk_level IN ('low', 'moderate', 'high', 'critical')),
    injury_risk_score INTEGER CHECK (injury_risk_score >= 0 AND injury_risk_score <= 100),
    specific_injury_risks TEXT[], -- ['PFPS', 'IT_band_syndrome', 'shin_splints']
    risk_percentages JSONB, -- {"PFPS": 70, "IT_band": 45}
    
    -- Corrective Recommendations
    corrective_exercises JSONB, -- Detailed exercise protocols with progressions
    footwear_recommendations TEXT[],
    terrain_modifications TEXT[],
    training_adjustments TEXT[],
    
    -- Progress Tracking
    previous_analysis_id UUID REFERENCES public.gait_analysis_history(id) ON DELETE SET NULL,
    improvement_notes TEXT,
    
    -- Raw Assessment Data (for algorithm improvement)
    ankle_mobility_left NUMERIC(5,2),
    ankle_mobility_right NUMERIC(5,2),
    hip_abduction_reps INTEGER,
    single_leg_balance_seconds NUMERIC(5,2),
    knee_valgus_angle NUMERIC(5,2),
    q_angle NUMERIC(5,2),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_gait_analysis_user_id ON public.gait_analysis_history(user_id);
CREATE INDEX idx_gait_analysis_date ON public.gait_analysis_history(analysis_date DESC);
CREATE INDEX idx_gait_analysis_assessment ON public.gait_analysis_history(assessment_id);
CREATE INDEX idx_gait_analysis_user_date ON public.gait_analysis_history(user_id, analysis_date DESC);

-- ┌─────────────────────────────────────────────────────┐
-- │ 4. RECOVERY ROADMAP PROGRESS TABLE                  │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.recovery_roadmap_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    assessment_id UUID, -- Link to initial AISRI assessment
    gait_analysis_id UUID REFERENCES public.gait_analysis_history(id) ON DELETE SET NULL,
    
    -- Roadmap Metadata
    roadmap_name TEXT NOT NULL,
    total_duration_weeks INTEGER NOT NULL DEFAULT 16,
    start_date DATE NOT NULL,
    expected_end_date DATE NOT NULL,
    actual_end_date DATE,
    
    -- Current Status
    current_phase INTEGER NOT NULL DEFAULT 1 CHECK (current_phase >= 1 AND current_phase <= 4),
    current_week INTEGER NOT NULL DEFAULT 1,
    overall_progress_percentage INTEGER DEFAULT 0 CHECK (overall_progress_percentage >= 0 AND overall_progress_percentage <= 100),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'abandoned')),
    
    -- Phase 1: Foundation & Acute Correction (Weeks 1-4)
    phase1_start_date DATE,
    phase1_end_date DATE,
    phase1_status TEXT CHECK (phase1_status IN ('not_started', 'in_progress', 'completed')),
    phase1_rom_improvement_percentage INTEGER,
    phase1_pain_reduction_percentage INTEGER,
    phase1_goals_achieved TEXT[],
    phase1_notes TEXT,
    
    -- Phase 2: Functional Strengthening (Weeks 5-8)
    phase2_start_date DATE,
    phase2_end_date DATE,
    phase2_status TEXT CHECK (phase2_status IN ('not_started', 'in_progress', 'completed')),
    phase2_strength_gains_percentage INTEGER,
    phase2_training_volume_percentage INTEGER, -- e.g., 75% of original volume
    phase2_goals_achieved TEXT[],
    phase2_notes TEXT,
    
    -- Phase 3: Integration & Performance (Weeks 9-12)
    phase3_start_date DATE,
    phase3_end_date DATE,
    phase3_status TEXT CHECK (phase3_status IN ('not_started', 'in_progress', 'completed')),
    phase3_training_volume_percentage INTEGER,
    phase3_speed_work_introduced BOOLEAN DEFAULT FALSE,
    phase3_goals_achieved TEXT[],
    phase3_notes TEXT,
    
    -- Phase 4: Maintenance & Optimization (Weeks 13-16)
    phase4_start_date DATE,
    phase4_end_date DATE,
    phase4_status TEXT CHECK (phase4_status IN ('not_started', 'in_progress', 'completed')),
    phase4_full_capacity_achieved BOOLEAN DEFAULT FALSE,
    phase4_habits_established TEXT[],
    phase4_goals_achieved TEXT[],
    phase4_notes TEXT,
    
    -- Milestone Checkpoints
    week2_checkpoint JSONB, -- {"pain_reduction": "30%", "rom_improvement": "+1cm", "notes": "Feeling better"}
    week4_checkpoint JSONB,
    week6_checkpoint JSONB,
    week8_checkpoint JSONB, -- Mid-program re-assessment
    week12_checkpoint JSONB,
    week16_checkpoint JSONB, -- Final assessment
    
    -- Progress Metrics
    initial_aisri_score INTEGER,
    week8_aisri_score INTEGER,
    final_aisri_score INTEGER,
    aisri_improvement INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN initial_aisri_score IS NOT NULL AND final_aisri_score IS NOT NULL
            THEN final_aisri_score - initial_aisri_score
            ELSE NULL
        END
    ) STORED,
    
    -- Adherence Tracking
    workouts_prescribed INTEGER DEFAULT 0,
    workouts_completed INTEGER DEFAULT 0,
    adherence_percentage INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN workouts_prescribed > 0 
            THEN ROUND((workouts_completed::NUMERIC / workouts_prescribed) * 100)
            ELSE 0
        END
    ) STORED,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_recovery_roadmap_user_id ON public.recovery_roadmap_progress(user_id);
CREATE INDEX idx_recovery_roadmap_assessment ON public.recovery_roadmap_progress(assessment_id);
CREATE INDEX idx_recovery_roadmap_status ON public.recovery_roadmap_progress(status);
CREATE INDEX idx_recovery_roadmap_phase ON public.recovery_roadmap_progress(current_phase);

-- ┌─────────────────────────────────────────────────────┐
-- │ 5. ATHLETE GOALS TABLE                              │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.athlete_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Goal Details
    goal_type TEXT NOT NULL CHECK (goal_type IN (
        'complete_distance', 'time_target', 'consistency', 'injury_prevention',
        'weight_loss', 'strength_gain', 'flexibility', 'aisri_score', 'custom'
    )),
    goal_title TEXT NOT NULL, -- e.g., 'Complete First 5K', 'Sub-4 Hour Marathon'
    goal_description TEXT,
    
    -- Target Specifications
    target_distance_km NUMERIC(6,2), -- For distance goals
    target_time_minutes INTEGER, -- For time-based goals
    target_pace_min_per_km NUMERIC(5,2), -- For pace goals
    target_weight_kg NUMERIC(5,2), -- For weight goals
    target_aisri_score INTEGER, -- For AISRI improvement goals
    target_workouts_per_week INTEGER, -- For consistency goals
    custom_metric_name TEXT, -- For custom goals
    custom_metric_target NUMERIC(10,2), -- For custom goals
    
    -- Timeline
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    target_date DATE NOT NULL,
    actual_completion_date DATE,
    -- days_to_target calculated in view (uses CURRENT_DATE which is not immutable)
    
    -- Progress
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed', 'paused', 'abandoned')),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    current_value NUMERIC(10,2), -- Current metric value
    
    -- Milestones (25%, 50%, 75%, 100%)
    milestone_25_achieved BOOLEAN DEFAULT FALSE,
    milestone_25_date DATE,
    milestone_50_achieved BOOLEAN DEFAULT FALSE,
    milestone_50_date DATE,
    milestone_75_achieved BOOLEAN DEFAULT FALSE,
    milestone_75_date DATE,
    milestone_100_achieved BOOLEAN DEFAULT FALSE,
    milestone_100_date DATE,
    
    -- Motivation & Tracking
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    motivation_reason TEXT,
    reward TEXT, -- Self-reward when goal achieved
    
    -- Related Items
    related_training_protocol_id UUID, -- Link to training protocol
    related_race_event TEXT, -- Name of race/event
    race_date DATE,
    
    -- Social Sharing
    is_public BOOLEAN DEFAULT FALSE,
    shared_with_coach BOOLEAN DEFAULT TRUE,
    
    -- Notes & Reflection
    notes TEXT,
    completion_reflection TEXT, -- Reflection when goal completed
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_athlete_goals_user_id ON public.athlete_goals(user_id);
CREATE INDEX idx_athlete_goals_status ON public.athlete_goals(status);
CREATE INDEX idx_athlete_goals_target_date ON public.athlete_goals(target_date);
CREATE INDEX idx_athlete_goals_type ON public.athlete_goals(goal_type);
CREATE INDEX idx_athlete_goals_user_status ON public.athlete_goals(user_id, status);

-- ┌─────────────────────────────────────────────────────┐
-- │ 6. COACH-ATHLETE MESSAGES TABLE                     │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Thread Organization
    thread_id UUID, -- Group related messages
    parent_message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE, -- For replies
    
    -- Message Content
    subject TEXT, -- Optional for first message in thread
    message_body TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'workout_feedback', 'assessment_review', 'goal_update', 'system')),
    
    -- Attachments
    attachment_urls TEXT[], -- Array of URLs for images/files
    attachment_types TEXT[], -- ['image', 'pdf', 'screenshot']
    
    -- Related Items
    related_workout_id UUID REFERENCES public.workouts(id) ON DELETE SET NULL,
    related_assessment_id UUID,
    related_goal_id UUID REFERENCES public.athlete_goals(id) ON DELETE SET NULL,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    is_starred BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    
    -- Priority
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    requires_response BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Validation
    CONSTRAINT different_users CHECK (sender_id != receiver_id)
);

-- Indexes
CREATE INDEX idx_messages_sender ON public.messages(sender_id);
CREATE INDEX idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX idx_messages_thread ON public.messages(thread_id);
CREATE INDEX idx_messages_sent_at ON public.messages(sent_at DESC);
CREATE INDEX idx_messages_receiver_read ON public.messages(receiver_id, is_read);
CREATE INDEX idx_messages_receiver_thread ON public.messages(receiver_id, thread_id);

-- ┌─────────────────────────────────────────────────────┐
-- │ 7. WORKOUT AI ANALYSIS RESULTS TABLE                │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.workout_ai_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Analysis Metadata
    analysis_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    analysis_version TEXT DEFAULT '1.0',
    data_source TEXT CHECK (data_source IN ('strava', 'garmin', 'manual', 'gps_watch', 'multiple')),
    
    -- Analysis Period
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    total_workouts_analyzed INTEGER NOT NULL,
    total_distance_km NUMERIC(10,2),
    total_duration_hours NUMERIC(10,2),
    
    -- Overall Injury Prevention Score (0-100)
    injury_prevention_score INTEGER NOT NULL CHECK (injury_prevention_score >= 0 AND injury_prevention_score <= 100),
    risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'moderate', 'high', 'critical')),
    risk_category_color TEXT GENERATED ALWAYS AS (
        CASE 
            WHEN injury_prevention_score >= 80 THEN 'green'
            WHEN injury_prevention_score >= 60 THEN 'orange'
            ELSE 'red'
        END
    ) STORED,
    
    -- Issue Counts
    critical_issues_count INTEGER DEFAULT 0,
    warning_issues_count INTEGER DEFAULT 0,
    info_issues_count INTEGER DEFAULT 0,
    strengths_count INTEGER DEFAULT 0,
    
    -- Detailed Issues (JSONB Arrays)
    critical_issues JSONB DEFAULT '[]'::JSONB, -- [{"issue": "Low Cadence", "current": 155, "target": "170-180", ...}]
    warning_issues JSONB DEFAULT '[]'::JSONB,
    info_issues JSONB DEFAULT '[]'::JSONB,
    strengths JSONB DEFAULT '[]'::JSONB,
    
    -- Key Metrics Analysis
    avg_cadence_spm INTEGER,
    target_cadence_spm TEXT DEFAULT '170-180',
    cadence_status TEXT CHECK (cadence_status IN ('optimal', 'low', 'high', 'needs_improvement')),
    
    avg_vertical_oscillation_cm NUMERIC(4,2),
    target_vertical_oscillation_cm TEXT DEFAULT '6-8',
    vertical_oscillation_status TEXT CHECK (vertical_oscillation_status IN ('optimal', 'low', 'high', 'excessive')),
    
    avg_ground_contact_time_ms INTEGER,
    target_ground_contact_time_ms TEXT DEFAULT '200-250',
    ground_contact_time_status TEXT CHECK (ground_contact_time_status IN ('optimal', 'low', 'high', 'excessive')),
    
    avg_heart_rate_bpm INTEGER,
    max_heart_rate_bpm INTEGER,
    hr_zone_distribution JSONB, -- {"zone1": 20, "zone2": 40, "zone3": 30, "zone4": 8, "zone5": 2}
    
    weekly_distance_km NUMERIC(10,2),
    weekly_distance_change_percentage NUMERIC(5,2), -- e.g., +15% from previous week
    distance_change_status TEXT CHECK (distance_change_status IN ('safe', 'caution', 'excessive')),
    
    -- Training Load
    training_load_score INTEGER,
    training_stress_balance INTEGER,
    acute_chronic_workload_ratio NUMERIC(4,2), -- ACWR
    acwr_status TEXT CHECK (acwr_status IN ('optimal', 'undertraining', 'high_risk', 'injury_risk')),
    
    -- Recovery Analysis
    rest_days_in_period INTEGER,
    recovery_adequacy TEXT CHECK (recovery_adequacy IN ('sufficient', 'borderline', 'insufficient')),
    fatigue_indicators TEXT[],
    
    -- AI Recommendations
    top_recommendations TEXT[], -- Top 5 action items
    protocol_focus_areas TEXT[], -- ['Cadence Drills', 'Plyometric Exercises', 'Recovery']
    
    -- Generated Protocol
    generated_protocol_id UUID, -- Link to training_protocols table
    protocol_generated BOOLEAN DEFAULT FALSE,
    protocol_generation_date TIMESTAMP WITH TIME ZONE,
    
    -- Comparison with Previous Analysis
    previous_analysis_id UUID REFERENCES public.workout_ai_analysis(id) ON DELETE SET NULL,
    score_change INTEGER, -- Change from previous analysis
    improvements_noted TEXT[],
    regressions_noted TEXT[],
    
    -- Raw Data Reference (for re-analysis)
    workout_ids UUID[], -- Array of workout IDs analyzed
    
    -- User Feedback
    user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
    user_feedback TEXT,
    recommendations_followed TEXT[],
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_workout_ai_analysis_user_id ON public.workout_ai_analysis(user_id);
CREATE INDEX idx_workout_ai_analysis_date ON public.workout_ai_analysis(analysis_date DESC);
CREATE INDEX idx_workout_ai_analysis_score ON public.workout_ai_analysis(injury_prevention_score);
CREATE INDEX idx_workout_ai_analysis_user_date ON public.workout_ai_analysis(user_id, analysis_date DESC);
CREATE INDEX idx_workout_ai_analysis_period ON public.workout_ai_analysis(period_start_date, period_end_date);

-- ═══════════════════════════════════════════════════════
-- VIEWS & FUNCTIONS
-- ═══════════════════════════════════════════════════════

-- View: Active Injuries with Days Since Injury
CREATE OR REPLACE VIEW public.active_injuries_summary AS
SELECT 
    i.id,
    i.user_id,
    i.injury_name,
    i.affected_area,
    i.severity,
    i.current_pain_level,
    i.status,
    i.injury_date,
    CASE 
        WHEN i.status IN ('healed') AND i.actual_recovery_date IS NOT NULL 
        THEN (i.actual_recovery_date - i.injury_date)
        ELSE (CURRENT_DATE - i.injury_date)
    END as days_since_injury,
    i.recovery_percentage,
    CASE 
        WHEN i.expected_recovery_date IS NOT NULL 
        THEN (i.expected_recovery_date - CURRENT_DATE)
        ELSE NULL
    END as days_until_recovery
FROM public.injuries i
WHERE i.status IN ('active', 'recovering')
ORDER BY i.severity DESC, i.injury_date DESC;

-- View: Body Measurements Progress
CREATE OR REPLACE VIEW public.body_measurements_progress AS
SELECT 
    user_id,
    COUNT(*) as total_measurements,
    MIN(measurement_date) as first_measurement_date,
    MAX(measurement_date) as latest_measurement_date,
    -- Latest measurements
    (SELECT weight_kg FROM public.body_measurements 
     WHERE user_id = bm.user_id 
     ORDER BY measurement_date DESC LIMIT 1) as current_weight_kg,
    (SELECT bmi FROM public.body_measurements 
     WHERE user_id = bm.user_id 
     ORDER BY measurement_date DESC LIMIT 1) as current_bmi,
    -- First measurements (for comparison)
    (SELECT weight_kg FROM public.body_measurements 
     WHERE user_id = bm.user_id 
     ORDER BY measurement_date ASC LIMIT 1) as starting_weight_kg,
    -- Changes
    (SELECT weight_kg FROM public.body_measurements 
     WHERE user_id = bm.user_id 
     ORDER BY measurement_date DESC LIMIT 1) -
    (SELECT weight_kg FROM public.body_measurements 
     WHERE user_id = bm.user_id 
     ORDER BY measurement_date ASC LIMIT 1) as weight_change_kg
FROM public.body_measurements bm
GROUP BY user_id;

-- View: Goals Progress Dashboard
CREATE OR REPLACE VIEW public.goals_dashboard AS
SELECT 
    user_id,
    COUNT(*) as total_goals,
    COUNT(*) FILTER (WHERE status = 'active') as active_goals,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_goals,
    COUNT(*) FILTER (WHERE status = 'paused') as paused_goals,
    AVG(progress_percentage) FILTER (WHERE status = 'active') as avg_progress,
    COUNT(*) FILTER (WHERE target_date < CURRENT_DATE AND status = 'active') as overdue_goals
FROM public.athlete_goals
GROUP BY user_id;

-- View: Recent Gait Analysis Summary
CREATE OR REPLACE VIEW public.recent_gait_analysis AS
SELECT 
    user_id,
    analysis_date,
    detected_pathologies,
    primary_pathology,
    injury_risk_level,
    injury_risk_score,
    specific_injury_risks,
    bow_legs_confidence,
    knock_knees_confidence,
    overpronation_confidence,
    underpronation_confidence
FROM public.gait_analysis_history
WHERE analysis_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY analysis_date DESC;

-- View: Unread Messages Count
CREATE OR REPLACE VIEW public.unread_messages_count AS
SELECT 
    receiver_id as user_id,
    COUNT(*) as unread_count,
    COUNT(*) FILTER (WHERE priority IN ('high', 'urgent')) as urgent_unread_count,
    MAX(sent_at) as latest_message_at
FROM public.messages
WHERE is_read = FALSE AND is_archived = FALSE
GROUP BY receiver_id;

-- Function: Update Injury Recovery Percentage
CREATE OR REPLACE FUNCTION public.update_injury_recovery_percentage(
    p_injury_id UUID,
    p_new_percentage INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.injuries
    SET 
        recovery_percentage = p_new_percentage,
        status = CASE 
            WHEN p_new_percentage >= 100 THEN 'healed'
            WHEN p_new_percentage >= 50 THEN 'recovering'
            ELSE status
        END,
        actual_recovery_date = CASE 
            WHEN p_new_percentage >= 100 THEN CURRENT_DATE
            ELSE actual_recovery_date
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_injury_id;
END;
$$;

-- Function: Update Goal Progress
CREATE OR REPLACE FUNCTION public.update_goal_progress(
    p_goal_id UUID,
    p_current_value NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_goal RECORD;
    v_progress INTEGER;
BEGIN
    SELECT * INTO v_goal
    FROM public.athlete_goals
    WHERE id = p_goal_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Goal not found';
    END IF;
    
    -- Calculate progress percentage based on goal type
    CASE v_goal.goal_type
        WHEN 'complete_distance' THEN
            v_progress := LEAST(100, ROUND((p_current_value / v_goal.target_distance_km) * 100));
        WHEN 'weight_loss' THEN
            v_progress := LEAST(100, ROUND(((v_goal.current_value - p_current_value) / 
                                   (v_goal.current_value - v_goal.target_weight_kg)) * 100));
        WHEN 'aisri_score' THEN
            v_progress := LEAST(100, ROUND((p_current_value / v_goal.target_aisri_score) * 100));
        ELSE
            v_progress := LEAST(100, ROUND((p_current_value / v_goal.custom_metric_target) * 100));
    END CASE;
    
    -- Update goal
    UPDATE public.athlete_goals
    SET 
        current_value = p_current_value,
        progress_percentage = v_progress,
        status = CASE 
            WHEN v_progress >= 100 THEN 'completed'
            ELSE status
        END,
        milestone_25_achieved = CASE WHEN v_progress >= 25 THEN TRUE ELSE milestone_25_achieved END,
        milestone_25_date = CASE WHEN v_progress >= 25 AND milestone_25_date IS NULL THEN CURRENT_DATE ELSE milestone_25_date END,
        milestone_50_achieved = CASE WHEN v_progress >= 50 THEN TRUE ELSE milestone_50_achieved END,
        milestone_50_date = CASE WHEN v_progress >= 50 AND milestone_50_date IS NULL THEN CURRENT_DATE ELSE milestone_50_date END,
        milestone_75_achieved = CASE WHEN v_progress >= 75 THEN TRUE ELSE milestone_75_achieved END,
        milestone_75_date = CASE WHEN v_progress >= 75 AND milestone_75_date IS NULL THEN CURRENT_DATE ELSE milestone_75_date END,
        milestone_100_achieved = CASE WHEN v_progress >= 100 THEN TRUE ELSE milestone_100_achieved END,
        milestone_100_date = CASE WHEN v_progress >= 100 AND milestone_100_date IS NULL THEN CURRENT_DATE ELSE milestone_100_date END,
        actual_completion_date = CASE WHEN v_progress >= 100 THEN CURRENT_DATE ELSE actual_completion_date END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_goal_id;
END;
$$;

-- ═══════════════════════════════════════════════════════
-- PERMISSIONS (RLS Policies)
-- ═══════════════════════════════════════════════════════

-- Enable RLS
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.injuries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gait_analysis_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recovery_roadmap_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.athlete_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_ai_analysis ENABLE ROW LEVEL SECURITY;

-- Body Measurements: Users manage their own
CREATE POLICY "Users manage own body measurements"
    ON public.body_measurements FOR ALL
    USING (auth.uid() = user_id);

-- Coaches can view their athletes' measurements
CREATE POLICY "Coaches view athletes body measurements"
    ON public.body_measurements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.athlete_coach_relationships
            WHERE coach_id = auth.uid()
            AND athlete_id = body_measurements.user_id
            AND status = 'active'
        )
    );

-- Injuries: Users manage their own
CREATE POLICY "Users manage own injuries"
    ON public.injuries FOR ALL
    USING (auth.uid() = user_id);

-- Coaches can view their athletes' injuries
CREATE POLICY "Coaches view athletes injuries"
    ON public.injuries FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.athlete_coach_relationships
            WHERE coach_id = auth.uid()
            AND athlete_id = injuries.user_id
            AND status = 'active'
        )
    );

-- Gait Analysis: Users view their own
CREATE POLICY "Users view own gait analysis"
    ON public.gait_analysis_history FOR SELECT
    USING (auth.uid() = user_id);

-- Coaches view their athletes' gait analysis
CREATE POLICY "Coaches view athletes gait analysis"
    ON public.gait_analysis_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.athlete_coach_relationships
            WHERE coach_id = auth.uid()
            AND athlete_id = gait_analysis_history.user_id
            AND status = 'active'
        )
    );

-- Recovery Roadmap: Users manage their own
CREATE POLICY "Users manage own recovery roadmap"
    ON public.recovery_roadmap_progress FOR ALL
    USING (auth.uid() = user_id);

-- Coaches view/update their athletes' roadmaps
CREATE POLICY "Coaches manage athletes recovery roadmap"
    ON public.recovery_roadmap_progress FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.athlete_coach_relationships
            WHERE coach_id = auth.uid()
            AND athlete_id = recovery_roadmap_progress.user_id
            AND status = 'active'
        )
    );

-- Goals: Users manage their own
CREATE POLICY "Users manage own goals"
    ON public.athlete_goals FOR ALL
    USING (auth.uid() = user_id);

-- Coaches view their athletes' goals
CREATE POLICY "Coaches view athletes goals"
    ON public.athlete_goals FOR SELECT
    USING (
        shared_with_coach = TRUE AND
        EXISTS (
            SELECT 1 FROM public.athlete_coach_relationships
            WHERE coach_id = auth.uid()
            AND athlete_id = athlete_goals.user_id
            AND status = 'active'
        )
    );

-- Messages: Sender and receiver can view
CREATE POLICY "Users view sent messages"
    ON public.messages FOR SELECT
    USING (auth.uid() = sender_id);

CREATE POLICY "Users view received messages"
    ON public.messages FOR SELECT
    USING (auth.uid() = receiver_id);

-- Users can send messages
CREATE POLICY "Users send messages"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- Users can update their received messages (mark as read)
CREATE POLICY "Users update received messages"
    ON public.messages FOR UPDATE
    USING (auth.uid() = receiver_id);

-- Workout AI Analysis: Users view their own
CREATE POLICY "Users view own workout analysis"
    ON public.workout_ai_analysis FOR SELECT
    USING (auth.uid() = user_id);

-- Users create their own analysis
CREATE POLICY "Users create own workout analysis"
    ON public.workout_ai_analysis FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Coaches view their athletes' analysis
CREATE POLICY "Coaches view athletes workout analysis"
    ON public.workout_ai_analysis FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.athlete_coach_relationships
            WHERE coach_id = auth.uid()
            AND athlete_id = workout_ai_analysis.user_id
            AND status = 'active'
        )
    );

-- ═══════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════

-- Updated_at trigger function (if not already exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_body_measurements_updated_at 
    BEFORE UPDATE ON public.body_measurements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_injuries_updated_at 
    BEFORE UPDATE ON public.injuries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gait_analysis_updated_at 
    BEFORE UPDATE ON public.gait_analysis_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recovery_roadmap_updated_at 
    BEFORE UPDATE ON public.recovery_roadmap_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_athlete_goals_updated_at 
    BEFORE UPDATE ON public.athlete_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workout_ai_analysis_updated_at 
    BEFORE UPDATE ON public.workout_ai_analysis
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════
-- END OF SCHEMA
-- ═══════════════════════════════════════════════════════
