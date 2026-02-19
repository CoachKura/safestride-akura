-- =====================================================
-- AISRI COMPLETE SYSTEM - DATABASE SCHEMA
-- Version: 1.0
-- Created: 2026-02-17
-- Purpose: Add comprehensive AISRI tracking to SafeStride
-- =====================================================

-- =====================================================
-- TABLE 1: AISRI Scores (5 Pillars)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.aisri_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assessment_date TIMESTAMPTZ DEFAULT NOW(),
  
  -- Total AISRI Score (0-100)
  total_score INTEGER NOT NULL CHECK (total_score >= 0 AND total_score <= 100),
  risk_category TEXT CHECK (risk_category IN ('Low Risk', 'Medium Risk', 'High Risk', 'Critical Risk')),
  
  -- 5 Pillar Scores (0-100 each)
  running_performance_score INTEGER CHECK (running_performance_score >= 0 AND running_performance_score <= 100),
  strength_score INTEGER CHECK (strength_score >= 0 AND strength_score <= 100),
  rom_score INTEGER CHECK (rom_score >= 0 AND rom_score <= 100), -- Range of Motion
  balance_score INTEGER CHECK (balance_score >= 0 AND balance_score <= 100),
  mobility_score INTEGER CHECK (mobility_score >= 0 AND mobility_score <= 100),
  
  -- Pillar Weights (Formula: Running × 40% + Strength × 20% + ROM × 15% + Balance × 15% + Mobility × 10%)
  running_weight DECIMAL(3,2) DEFAULT 0.40,
  strength_weight DECIMAL(3,2) DEFAULT 0.20,
  rom_weight DECIMAL(3,2) DEFAULT 0.15,
  balance_weight DECIMAL(3,2) DEFAULT 0.15,
  mobility_weight DECIMAL(3,2) DEFAULT 0.10,
  
  -- Training Zone Permissions
  allowed_zones TEXT[] DEFAULT ARRAY['AR', 'F'], -- Active Recovery, Foundation
  current_phase TEXT, -- 'Base Building', 'Aerobic Development', etc.
  
  -- Safety Gates Status
  safety_gates_passed BOOLEAN DEFAULT false,
  zone_p_unlocked BOOLEAN DEFAULT false, -- Power zone (87-95% max HR)
  zone_sp_unlocked BOOLEAN DEFAULT false, -- Speed zone (95-100% max HR)
  
  -- Performance Index (0-100)
  performance_index INTEGER CHECK (performance_index >= 0 AND performance_index <= 100),
  
  -- Execution Quality
  execution_quality_percent INTEGER CHECK (execution_quality_percent >= 0 AND execution_quality_percent <= 100),
  weeks_foundation_completed INTEGER DEFAULT 0,
  weeks_injury_free INTEGER DEFAULT 0,
  
  -- Metadata
  assessment_notes TEXT,
  assessor_name TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(athlete_id, assessment_date)
);

CREATE INDEX idx_aisri_scores_athlete ON public.aisri_scores(athlete_id);
CREATE INDEX idx_aisri_scores_date ON public.aisri_scores(assessment_date DESC);
CREATE INDEX idx_aisri_scores_risk ON public.aisri_scores(risk_category);

COMMENT ON TABLE public.aisri_scores IS 'AISRI (Akura Injury & Safety Risk Index) complete assessment scores with 5 pillars';

-- =====================================================
-- TABLE 2: Training Zones Definitions
-- =====================================================

CREATE TABLE IF NOT EXISTS public.training_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_code TEXT UNIQUE NOT NULL, -- AR, F, EN, TH, P, SP
  zone_name TEXT NOT NULL,
  zone_description TEXT,
  
  -- Heart Rate Ranges (percentage of max HR)
  hr_min_percent INTEGER NOT NULL,
  hr_max_percent INTEGER NOT NULL,
  
  -- Zone Purpose
  purpose TEXT,
  benefits TEXT[],
  
  -- Unlock Requirements
  min_aisri_score INTEGER,
  min_weeks_foundation INTEGER DEFAULT 0,
  prerequisites TEXT[],
  
  -- Display
  color_hex TEXT,
  sort_order INTEGER,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert standard AISRI training zones
INSERT INTO public.training_zones (zone_code, zone_name, zone_description, hr_min_percent, hr_max_percent, purpose, benefits, min_aisri_score, color_hex, sort_order) VALUES
('AR', 'Active Recovery', 'Recovery, warm-up, cool-down', 50, 60, 'Recovery, warm-up, cool-down', 
  ARRAY['Recovery', 'Warm-up', 'Improved circulation', 'Injury prevention'], 
  0, '#ADD8E6', 1),
  
('F', 'Foundation (Zone F)', 'Aerobic base, fat burning, stamina', 60, 70, 'Aerobic Base, Fat Burning, Stamina', 
  ARRAY['Builds aerobic base', 'Fat burning', 'Stamina development', 'Cardiovascular fitness'], 
  0, '#87CEEB', 2),
  
('EN', 'Endurance (Zone EN)', 'Aerobic fitness, improved oxygen efficiency', 70, 80, 'Aerobic Fitness, Improved Oxygen Efficiency', 
  ARRAY['Aerobic fitness', 'Oxygen efficiency', 'Endurance building', 'Lactate clearance'], 
  40, '#40E0D0', 3),
  
('TH', 'Threshold (Zone TH)', 'Lactate threshold, anaerobic capacity, speed endurance', 80, 87, 'Lactate Threshold, Anaerobic Capacity, Speed Endurance', 
  ARRAY['Lactate threshold', 'Anaerobic capacity', 'Speed endurance', 'Race pace training'], 
  55, '#FFA500', 4),
  
('P', 'Peak/Power (Zone P)', 'Max oxygen uptake (VO2 Max), peak performance', 87, 95, 'Max Oxygen Uptake (VO2 Max), Peak Performance', 
  ARRAY['VO2 max improvement', 'Peak performance', 'Race pace', 'High-intensity intervals'], 
  70, '#FF6B6B', 5),
  
('SP', 'Speed (Zone SP)', 'Anaerobic power, sprinting, short bursts', 95, 100, 'Anaerobic Power, Sprinting, Short Bursts', 
  ARRAY['Anaerobic power', 'Sprint speed', 'Explosive power', 'Neuromuscular development'], 
  85, '#8B0000', 6)
ON CONFLICT (zone_code) DO NOTHING;

CREATE INDEX idx_training_zones_score ON public.training_zones(min_aisri_score);

COMMENT ON TABLE public.training_zones IS 'AISRI training zones (AR, F, EN, TH, P, SP) with heart rate ranges and unlock requirements';

-- =====================================================
-- TABLE 3: Biomechanical Assessments
-- =====================================================

CREATE TABLE IF NOT EXISTS public.biomechanical_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assessment_date TIMESTAMPTZ DEFAULT NOW(),
  
  -- Running Metrics
  cadence_spm INTEGER, -- steps per minute (optimal: 170-180)
  stride_length_meters DECIMAL(4,2), -- meters (optimal varies by height)
  vertical_oscillation_cm DECIMAL(4,2), -- cm (optimal: <8cm)
  ground_contact_time_ms INTEGER, -- milliseconds (optimal: <250ms)
  
  -- Gait Analysis
  foot_strike_type TEXT CHECK (foot_strike_type IN ('Forefoot', 'Midfoot', 'Heel Strike')),
  pronation_type TEXT CHECK (pronation_type IN ('Neutral', 'Overpronation', 'Supination', 'Excessive Pronation')),
  
  -- Biomechanical Issues (from documentation)
  bow_legs BOOLEAN DEFAULT false,
  knock_knees BOOLEAN DEFAULT false,
  excessive_pronation BOOLEAN DEFAULT false,
  
  -- Mobility Tests (in degrees or cm)
  ankle_dorsiflexion_left INTEGER, -- degrees (optimal: ≥40°)
  ankle_dorsiflexion_right INTEGER,
  hip_flexion_left INTEGER, -- degrees (optimal: ≥120°)
  hip_flexion_right INTEGER,
  hamstring_flexibility_cm INTEGER, -- cm from floor (optimal: 0cm = touch floor)
  
  -- Strength Tests (from documentation)
  plank_hold_seconds INTEGER, -- optimal: ≥60s
  single_leg_deadlift_reps_left INTEGER, -- optimal: ≥10 reps
  single_leg_deadlift_reps_right INTEGER,
  wall_sit_hold_seconds INTEGER, -- optimal: ≥60s
  single_leg_balance_eyes_open_seconds INTEGER, -- optimal: ≥30s
  single_leg_balance_eyes_closed_seconds INTEGER, -- optimal: ≥15s
  
  -- Notes
  assessment_notes TEXT,
  assessor_name TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_biomech_athlete ON public.biomechanical_assessments(athlete_id);
CREATE INDEX idx_biomech_date ON public.biomechanical_assessments(assessment_date DESC);

COMMENT ON TABLE public.biomechanical_assessments IS 'Detailed biomechanical assessments including gait analysis, mobility tests, and strength tests';

-- =====================================================
-- TABLE 4: Training Sessions/Workouts
-- =====================================================

CREATE TABLE IF NOT EXISTS public.training_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_date TIMESTAMPTZ NOT NULL,
  
  -- Session Type
  session_type TEXT NOT NULL CHECK (session_type IN ('Running', 'Strength', 'Mobility', 'Recovery', 'Cross-Training')),
  zone_code TEXT REFERENCES public.training_zones(zone_code),
  
  -- Planned vs Actual
  planned_duration_minutes INTEGER,
  actual_duration_minutes INTEGER,
  planned_distance_km DECIMAL(6,2),
  actual_distance_km DECIMAL(6,2),
  
  -- Heart Rate Data
  avg_heart_rate_bpm INTEGER,
  max_heart_rate_bpm INTEGER,
  hr_zone_compliance_percent INTEGER CHECK (hr_zone_compliance_percent >= 0 AND hr_zone_compliance_percent <= 100),
  
  -- Performance Metrics
  avg_pace_min_per_km DECIMAL(5,2),
  avg_cadence_spm INTEGER,
  avg_stride_length_m DECIMAL(4,2),
  vertical_oscillation_cm DECIMAL(4,2),
  ground_contact_time_ms INTEGER,
  
  -- Subjective Ratings
  rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10), -- Rate of Perceived Exertion
  execution_quality_percent INTEGER CHECK (execution_quality_percent >= 0 AND execution_quality_percent <= 100),
  energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
  sleep_quality INTEGER CHECK (sleep_quality >= 1 AND sleep_quality <= 10),
  
  -- Session Status
  completed BOOLEAN DEFAULT true,
  skipped BOOLEAN DEFAULT false,
  skip_reason TEXT,
  
  -- Notes
  session_notes TEXT,
  coach_feedback TEXT,
  
  -- Strava/Device Integration
  strava_activity_id TEXT,
  garmin_activity_id TEXT,
  device_data JSONB,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_training_sessions_athlete ON public.training_sessions(athlete_id);
CREATE INDEX idx_training_sessions_date ON public.training_sessions(session_date DESC);
CREATE INDEX idx_training_sessions_type ON public.training_sessions(session_type);
CREATE INDEX idx_training_sessions_zone ON public.training_sessions(zone_code);

COMMENT ON TABLE public.training_sessions IS 'Training session tracking with execution quality, heart rate data, and performance metrics';

-- =====================================================
-- TABLE 5: Safety Gates Tracking
-- =====================================================

CREATE TABLE IF NOT EXISTS public.safety_gates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  gate_type TEXT NOT NULL CHECK (gate_type IN ('Zone P', 'Zone SP')),
  
  -- Requirements
  min_aisri_score INTEGER NOT NULL, -- 70 for P, 85 for SP
  min_rom_score INTEGER, -- 80 for P, 85 for SP
  min_weeks_foundation INTEGER, -- 12 for P, 16 for SP
  no_injuries_weeks INTEGER, -- 12 for P, 24 for SP
  
  -- Status
  is_passed BOOLEAN DEFAULT false,
  passed_date TIMESTAMPTZ,
  
  -- Current Status
  current_aisri_score INTEGER,
  current_rom_score INTEGER,
  weeks_foundation_completed INTEGER DEFAULT 0,
  weeks_injury_free INTEGER DEFAULT 0,
  
  -- Requirements Met
  aisri_requirement_met BOOLEAN DEFAULT false,
  rom_requirement_met BOOLEAN DEFAULT false,
  foundation_requirement_met BOOLEAN DEFAULT false,
  injury_requirement_met BOOLEAN DEFAULT false,
  
  -- Notes
  coach_notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(athlete_id, gate_type)
);

CREATE INDEX idx_safety_gates_athlete ON public.safety_gates(athlete_id);
CREATE INDEX idx_safety_gates_passed ON public.safety_gates(is_passed);

COMMENT ON TABLE public.safety_gates IS 'Safety gate requirements and status for unlocking Zone P (Power) and Zone SP (Speed)';

-- =====================================================
-- FUNCTION 1: Calculate AISRI Score
-- =====================================================

CREATE OR REPLACE FUNCTION public.calculate_aisri_score(
  p_running INTEGER,
  p_strength INTEGER,
  p_rom INTEGER,
  p_balance INTEGER,
  p_mobility INTEGER
)
RETURNS INTEGER AS $$
DECLARE
  v_score DECIMAL(10,2);
BEGIN
  -- AISRI Formula: (Running × 0.40) + (Strength × 0.20) + (ROM × 0.15) + (Balance × 0.15) + (Mobility × 0.10)
  v_score := (p_running * 0.40) + (p_strength * 0.20) + (p_rom * 0.15) + (p_balance * 0.15) + (p_mobility * 0.10);
  
  RETURN ROUND(v_score)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.calculate_aisri_score IS 'Calculate AISRI score using weighted formula: Running (40%), Strength (20%), ROM (15%), Balance (15%), Mobility (10%)';

-- Test function
SELECT calculate_aisri_score(80, 75, 70, 65, 60) as test_aisri_score; -- Should return 74

-- =====================================================
-- FUNCTION 2: Determine Allowed Training Zones
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_allowed_zones(p_aisri_score INTEGER)
RETURNS TEXT[] AS $$
BEGIN
  IF p_aisri_score >= 85 THEN
    RETURN ARRAY['AR', 'F', 'EN', 'TH', 'P', 'SP']; -- All zones
  ELSIF p_aisri_score >= 70 THEN
    RETURN ARRAY['AR', 'F', 'EN', 'TH', 'P']; -- +Power
  ELSIF p_aisri_score >= 55 THEN
    RETURN ARRAY['AR', 'F', 'EN', 'TH']; -- +Threshold
  ELSIF p_aisri_score >= 40 THEN
    RETURN ARRAY['AR', 'F', 'EN']; -- +Endurance
  ELSE
    RETURN ARRAY['AR', 'F']; -- Foundation only
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.get_allowed_zones IS 'Returns allowed training zones based on AISRI score';

-- Test function
SELECT get_allowed_zones(74) as test_zones; -- Should return {AR,F,EN,TH,P}

-- =====================================================
-- FUNCTION 3: Determine Risk Category
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_risk_category(p_aisri_score INTEGER)
RETURNS TEXT AS $$
BEGIN
  IF p_aisri_score >= 75 THEN
    RETURN 'Low Risk';
  ELSIF p_aisri_score >= 55 THEN
    RETURN 'Medium Risk';
  ELSIF p_aisri_score >= 35 THEN
    RETURN 'High Risk';
  ELSE
    RETURN 'Critical Risk';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.get_risk_category IS 'Returns risk category based on AISRI score: Low (≥75), Medium (≥55), High (≥35), Critical (<35)';

-- Test function
SELECT get_risk_category(74) as test_risk_category; -- Should return 'Medium Risk'

-- =====================================================
-- VIEW: Comprehensive AISRI Athlete Dashboard
-- =====================================================

CREATE OR REPLACE VIEW public.aisri_athlete_dashboard AS
SELECT 
  p.id as athlete_id,
  p.email,
  p.full_name as athlete_name,
  
  -- Latest AISRI Score
  s.total_score as aisri_score,
  s.risk_category,
  s.running_performance_score,
  s.strength_score,
  s.rom_score,
  s.balance_score,
  s.mobility_score,
  s.allowed_zones,
  s.current_phase,
  s.safety_gates_passed,
  s.zone_p_unlocked,
  s.zone_sp_unlocked,
  s.performance_index,
  s.execution_quality_percent,
  s.weeks_foundation_completed,
  s.weeks_injury_free,
  s.assessment_date as last_aisri_assessment,
  
  -- Latest Injury Risk Assessment (from existing system)
  a.total_score as injury_risk_score,
  a.age,
  a.gender,
  
  -- Recent Training
  (SELECT COUNT(*) 
   FROM public.training_sessions ts 
   WHERE ts.athlete_id = p.id 
     AND ts.session_date >= NOW() - INTERVAL '7 days'
     AND ts.completed = true
  ) as sessions_last_7_days,
  
  (SELECT COUNT(*) 
   FROM public.training_sessions ts 
   WHERE ts.athlete_id = p.id 
     AND ts.session_date >= NOW() - INTERVAL '30 days'
     AND ts.completed = true
  ) as sessions_last_30_days,
  
  (SELECT AVG(execution_quality_percent)::INTEGER 
   FROM public.training_sessions ts 
   WHERE ts.athlete_id = p.id 
     AND ts.session_date >= NOW() - INTERVAL '30 days'
     AND ts.execution_quality_percent IS NOT NULL
  ) as avg_execution_30_days,
  
  -- Latest Biomechanics
  b.cadence_spm,
  b.stride_length_meters,
  b.vertical_oscillation_cm,
  b.ground_contact_time_ms,
  b.foot_strike_type,
  b.pronation_type,
  b.assessment_date as last_biomech_assessment,
  
  -- Safety Gates
  (SELECT is_passed FROM public.safety_gates sg WHERE sg.athlete_id = p.id AND sg.gate_type = 'Zone P') as zone_p_gate_passed,
  (SELECT is_passed FROM public.safety_gates sg WHERE sg.athlete_id = p.id AND sg.gate_type = 'Zone SP') as zone_sp_gate_passed
  
FROM public.profiles p
LEFT JOIN LATERAL (
  SELECT * FROM public.aisri_scores 
  WHERE athlete_id = p.id 
  ORDER BY assessment_date DESC 
  LIMIT 1
) s ON true
LEFT JOIN LATERAL (
  SELECT * FROM public."AISRI_assessments" 
  WHERE athlete_id = p.id 
  ORDER BY assessment_date DESC 
  LIMIT 1
) a ON true
LEFT JOIN LATERAL (
  SELECT * FROM public.biomechanical_assessments 
  WHERE athlete_id = p.id 
  ORDER BY assessment_date DESC 
  LIMIT 1
) b ON true
ORDER BY s.total_score ASC NULLS LAST, p.full_name;

GRANT SELECT ON public.aisri_athlete_dashboard TO authenticated;
GRANT SELECT ON public.aisri_athlete_dashboard TO anon;

COMMENT ON VIEW public.aisri_athlete_dashboard IS 'Comprehensive AISRI dashboard with scores, training zones, execution quality, and biomechanics';

-- =====================================================
-- DISABLE ROW LEVEL SECURITY (for dashboard access)
-- =====================================================

ALTER TABLE public.aisri_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.biomechanical_assessments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_gates DISABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT ON public.aisri_scores TO anon, authenticated;
GRANT SELECT ON public.training_zones TO anon, authenticated;
GRANT SELECT ON public.biomechanical_assessments TO anon, authenticated;
GRANT SELECT ON public.training_sessions TO anon, authenticated;
GRANT SELECT ON public.safety_gates TO anon, authenticated;

GRANT INSERT, UPDATE ON public.aisri_scores TO authenticated;
GRANT INSERT, UPDATE ON public.biomechanical_assessments TO authenticated;
GRANT INSERT, UPDATE ON public.training_sessions TO authenticated;
GRANT INSERT, UPDATE ON public.safety_gates TO authenticated;

-- =====================================================
-- SUCCESS MESSAGE & VERIFICATION
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ AISRI COMPLETE SCHEMA CREATED!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Tables Created:';
  RAISE NOTICE '  1. aisri_scores - AISRI assessments (5 pillars)';
  RAISE NOTICE '  2. training_zones - 6 zones (AR, F, EN, TH, P, SP)';
  RAISE NOTICE '  3. biomechanical_assessments - Gait & mobility tests';
  RAISE NOTICE '  4. training_sessions - Workout tracking';
  RAISE NOTICE '  5. safety_gates - Zone unlock requirements';
  RAISE NOTICE '';
  RAISE NOTICE 'Functions Created:';
  RAISE NOTICE '  1. calculate_aisri_score() - Weighted formula';
  RAISE NOTICE '  2. get_allowed_zones() - Zone permissions';
  RAISE NOTICE '  3. get_risk_category() - Risk classification';
  RAISE NOTICE '';
  RAISE NOTICE 'Views Created:';
  RAISE NOTICE '  1. aisri_athlete_dashboard - Complete athlete overview';
  RAISE NOTICE '';
  RAISE NOTICE 'Training Zones Loaded: 6 zones';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Step: Run 03_import_aisri_scores.sql';
END $$;

-- Verification queries
SELECT '✅ Schema created successfully!' AS status;

SELECT 'Training Zones' AS type, COUNT(*) AS count FROM public.training_zones
UNION ALL
SELECT 'AISRI Scores' AS type, COUNT(*) AS count FROM public.aisri_scores
UNION ALL
SELECT 'Biomech Assessments' AS type, COUNT(*) AS count FROM public.biomechanical_assessments
UNION ALL
SELECT 'Training Sessions' AS type, COUNT(*) AS count FROM public.training_sessions
UNION ALL
SELECT 'Safety Gates' AS type, COUNT(*) AS count FROM public.safety_gates;

-- List training zones
SELECT zone_code, zone_name, hr_min_percent || '-' || hr_max_percent || '% max HR' as hr_range, min_aisri_score
FROM public.training_zones
ORDER BY sort_order;
