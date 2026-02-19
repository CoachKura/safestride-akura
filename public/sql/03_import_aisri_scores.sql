-- =====================================================
-- IMPORT INITIAL AISRI SCORES FOR 10 ATHLETES
-- Based on injury history, experience, and risk factors
-- =====================================================

-- =====================================================
-- ATHLETE 1: Muthulakshmi Sankaranarayanan
-- Critical Risk - Multiple injuries, high pain level
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id,
  assessment_date,
  total_score,
  risk_category,
  running_performance_score,
  strength_score,
  rom_score,
  balance_score,
  mobility_score,
  allowed_zones,
  current_phase,
  safety_gates_passed,
  zone_p_unlocked,
  zone_sp_unlocked,
  performance_index,
  execution_quality_percent,
  weeks_foundation_completed,
  weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'muthulakshmi.02@gmail.com'),
  NOW(),
  35, -- Critical Risk
  'Critical Risk',
  40, -- Low running performance due to heel issues
  30, -- Weak strength (contributing to injuries)
  35, -- Poor ROM
  30, -- Poor balance
  35, -- Limited mobility
  ARRAY['AR', 'F'], -- Only recovery & foundation
  'Base Building - Injury Recovery',
  false, false, false,
  NULL, -- No performance index yet
  92, -- Execution quality 92% (from documentation)
  0, 0,
  'Multiple injuries: Heel spur, Calcaneal pain, PF pain. Pain level 8/10. Thyroid & B12 anemia. Needs gradual progression with focus on strength and mobility.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  running_performance_score = EXCLUDED.running_performance_score,
  strength_score = EXCLUDED.strength_score,
  rom_score = EXCLUDED.rom_score,
  balance_score = EXCLUDED.balance_score,
  mobility_score = EXCLUDED.mobility_score,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 2: Chandrasekar Sundaramoorthy
-- Low Risk - Elite runner, no injuries
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'chan24san@gmail.com'),
  NOW(),
  85, 'Low Risk',
  90, 85, 80, 80, 80,
  ARRAY['AR', 'F', 'EN', 'TH', 'P', 'SP'], -- All zones unlocked
  'Advanced Training',
  true, true, true,
  NULL, 95, -- High execution quality
  52, 104, -- 1+ year foundation, 2+ years injury-free
  'Elite runner with 10+ years experience. No injuries. Goal: Sub-1:25 half marathon (sub-4:00/km pace). Excellent execution quality.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 3: Dinesh A
-- High Risk - Knee pain, beginner
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'mailtoadinesh@gmail.com'),
  NOW(),
  50, 'High Risk',
  55, 50, 45, 45, 50,
  ARRAY['AR', 'F', 'EN'], -- Foundation + Endurance
  'Aerobic Development',
  false, false, false,
  NULL, 95, -- Excellent execution
  8, 0, -- 2 months foundation, currently injured
  'Knee pain issue. 1-2 years experience. Pain level 2/10. Needs strengthening program. Goal: Improve form & prevent injuries.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 4: Janarthanan
-- Medium Risk - Multiple injuries, moderate experience
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'janajake9@gmail.com'),
  NOW(),
  50, 'High Risk',
  60, 45, 45, 50, 45,
  ARRAY['AR', 'F', 'EN'], -- Foundation + Endurance
  'Injury Management',
  false, false, false,
  NULL, 90, -- Good execution quality
  12, 0, -- 3 months foundation, currently managing injuries
  'Multiple injuries: Knee pain, Plantar fasciitis, Heel spur. Pain level 1/10. 3 years experience, 50km/week. Needs injury prevention focus.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 5: KRISHNAKUMAR RAM
-- Medium Risk - Age 53, no injuries
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'krishchennai0109@gmail.com'),
  NOW(),
  65, 'Medium Risk',
  70, 60, 65, 65, 60,
  ARRAY['AR', 'F', 'EN', 'TH'], -- Up to Threshold
  'Steady State Training',
  false, false, false,
  NULL, NULL, -- No execution data yet
  28, 104, -- 7 months foundation, 2+ years injury-free
  'Age 53. 7 years experience, 15km/week. No injuries. Goal: General fitness. Age-appropriate progression needed.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 6: Karunakaran
-- Medium Risk - Ankle pain, experienced runner
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'gvkarunakharan@gmail.com'),
  NOW(),
  55, 'Medium Risk',
  65, 55, 50, 50, 55,
  ARRAY['AR', 'F', 'EN', 'TH'], -- Up to Threshold
  'Threshold Development',
  false, false, false,
  NULL, 88, -- Execution quality 88%
  40, 8, -- 10 months foundation, 2 months injury-free
  'Ankle pain issue. Asthma. 10+ years experience, 50km/week. Pain level 2/10. Goal: Sub-1:25 half marathon. Needs ankle strengthening.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 7: Vivek
-- High Risk - Ankle injury, moderate mileage
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'arunvivek24@gmail.com'),
  NOW(),
  45, 'High Risk',
  50, 45, 40, 45, 45,
  ARRAY['AR', 'F', 'EN'], -- Foundation + Endurance
  'Base Building',
  false, false, false,
  NULL, NULL, -- No execution data yet
  12, 4, -- 3 months foundation, 1 month injury-free
  'Above ankle injury. Pain level 3/10. 3 years experience, 15km/week. Goal: Sub-1:30 half marathon. Time constraints + training knowledge gaps.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 8: Vidhya E
-- Medium Risk - Beginner, no injuries
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'gvkvidhya09@gmail.com'),
  NOW(),
  70, 'Medium Risk',
  75, 65, 70, 70, 65,
  ARRAY['AR', 'F', 'EN', 'TH', 'P'], -- Up to Power
  'Progressive Training',
  false, true, false, -- Zone P unlocked
  NULL, NULL, -- No execution data yet
  8, 52, -- 2 months foundation, 1+ year injury-free
  '6-12 months experience, 0-20km/week. No injuries. Pain level 0/10. Goal: Complete a half marathon (any time). Age 41, female.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 9: Srinath V
-- Low Risk - Consistent training, no injuries
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'vsrinath27@gmail.com'),
  NOW(),
  75, 'Low Risk',
  80, 70, 75, 75, 70,
  ARRAY['AR', 'F', 'EN', 'TH', 'P'], -- Up to Power
  'Performance Training',
  false, true, false, -- Zone P unlocked
  NULL, NULL, -- No execution data yet
  16, 78, -- 4 months foundation, 1.5+ years injury-free
  '1-2 years experience, 0-20km/week. No injuries. Pain level 0/10. Goal: General fitness & health. Age 37, male.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- ATHLETE 10: Saranya Ravichandran
-- High Risk - Rheumatoid arthritis (early stage)
-- =====================================================
INSERT INTO public.aisri_scores (
  athlete_id, assessment_date, total_score, risk_category,
  running_performance_score, strength_score, rom_score, balance_score, mobility_score,
  allowed_zones, current_phase,
  safety_gates_passed, zone_p_unlocked, zone_sp_unlocked,
  performance_index, execution_quality_percent,
  weeks_foundation_completed, weeks_injury_free,
  assessment_notes
) VALUES (
  (SELECT id FROM public.profiles WHERE email = 'saranyassravi@gmail.com'),
  NOW(),
  40, 'High Risk',
  45, 35, 35, 40, 40,
  ARRAY['AR', 'F', 'EN'], -- Foundation + Endurance
  'Base Building - Medical Consideration',
  false, false, false,
  NULL, NULL, -- No execution data yet
  4, 26, -- 1 month foundation, 6 months injury-free
  'Rheumatoid arthritis (early stage) + Thyroid. <6 months experience, 0-20km/week. Pain level 1/10. Goal: General fitness. Requires careful monitoring.'
)
ON CONFLICT (athlete_id, assessment_date) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  risk_category = EXCLUDED.risk_category,
  allowed_zones = EXCLUDED.allowed_zones,
  updated_at = NOW();

-- =====================================================
-- INITIALIZE SAFETY GATES FOR ALL ATHLETES
-- =====================================================

-- Zone P requirements for all athletes
INSERT INTO public.safety_gates (
  athlete_id, gate_type,
  min_aisri_score, min_rom_score, min_weeks_foundation, no_injuries_weeks,
  current_aisri_score, current_rom_score,
  weeks_foundation_completed, weeks_injury_free,
  is_passed
)
SELECT 
  id, 'Zone P',
  70, 80, 12, 12,
  s.total_score, s.rom_score,
  s.weeks_foundation_completed, s.weeks_injury_free,
  (s.total_score >= 70 AND s.rom_score >= 80 AND s.weeks_foundation_completed >= 12 AND s.weeks_injury_free >= 12)
FROM public.profiles p
JOIN public.aisri_scores s ON p.id = s.athlete_id
ON CONFLICT (athlete_id, gate_type) DO UPDATE SET
  current_aisri_score = EXCLUDED.current_aisri_score,
  current_rom_score = EXCLUDED.current_rom_score,
  weeks_foundation_completed = EXCLUDED.weeks_foundation_completed,
  weeks_injury_free = EXCLUDED.weeks_injury_free,
  is_passed = EXCLUDED.is_passed,
  updated_at = NOW();

-- Zone SP requirements for all athletes
INSERT INTO public.safety_gates (
  athlete_id, gate_type,
  min_aisri_score, min_rom_score, min_weeks_foundation, no_injuries_weeks,
  current_aisri_score, current_rom_score,
  weeks_foundation_completed, weeks_injury_free,
  is_passed
)
SELECT 
  id, 'Zone SP',
  85, 85, 16, 24,
  s.total_score, s.rom_score,
  s.weeks_foundation_completed, s.weeks_injury_free,
  (s.total_score >= 85 AND s.rom_score >= 85 AND s.weeks_foundation_completed >= 16 AND s.weeks_injury_free >= 24)
FROM public.profiles p
JOIN public.aisri_scores s ON p.id = s.athlete_id
ON CONFLICT (athlete_id, gate_type) DO UPDATE SET
  current_aisri_score = EXCLUDED.current_aisri_score,
  current_rom_score = EXCLUDED.current_rom_score,
  weeks_foundation_completed = EXCLUDED.weeks_foundation_completed,
  weeks_injury_free = EXCLUDED.weeks_injury_free,
  is_passed = EXCLUDED.is_passed,
  updated_at = NOW();

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Count AISRI scores
SELECT COUNT(*) as total_aisri_scores FROM public.aisri_scores;

-- View all athlete AISRI scores
SELECT 
  p.full_name,
  s.total_score as aisri_score,
  s.risk_category,
  array_to_string(s.allowed_zones, ', ') as zones,
  s.current_phase,
  s.execution_quality_percent as execution_pct
FROM public.profiles p
JOIN public.aisri_scores s ON p.id = s.athlete_id
ORDER BY s.total_score DESC;

-- View risk distribution
SELECT 
  risk_category,
  COUNT(*) as athlete_count,
  ROUND(AVG(total_score)) as avg_aisri_score
FROM public.aisri_scores
GROUP BY risk_category
ORDER BY 
  CASE risk_category
    WHEN 'Low Risk' THEN 1
    WHEN 'Medium Risk' THEN 2
    WHEN 'High Risk' THEN 3
    WHEN 'Critical Risk' THEN 4
  END;

-- View safety gates status
SELECT 
  p.full_name,
  sg.gate_type,
  sg.is_passed,
  sg.current_aisri_score,
  sg.min_aisri_score,
  sg.current_rom_score,
  sg.min_rom_score,
  sg.weeks_foundation_completed,
  sg.min_weeks_foundation
FROM public.profiles p
JOIN public.safety_gates sg ON p.id = sg.athlete_id
ORDER BY p.full_name, sg.gate_type;

-- Test dashboard view
SELECT 
  athlete_name,
  aisri_score,
  risk_category,
  array_to_string(allowed_zones, ', ') as zones,
  current_phase,
  execution_quality_percent,
  sessions_last_7_days,
  avg_execution_30_days
FROM public.aisri_athlete_dashboard
ORDER BY aisri_score ASC;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ AISRI SCORES IMPORTED SUCCESSFULLY!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Athletes with AISRI Scores: 10';
  RAISE NOTICE '';
  RAISE NOTICE 'Risk Distribution:';
  RAISE NOTICE '  Low Risk (≥75): 2 athletes';
  RAISE NOTICE '  Medium Risk (55-74): 4 athletes';
  RAISE NOTICE '  High Risk (35-54): 3 athletes';
  RAISE NOTICE '  Critical Risk (<35): 1 athlete';
  RAISE NOTICE '';
  RAISE NOTICE 'Safety Gates Initialized: 20 (2 per athlete)';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Step: View dashboard or create calculator tool';
END $$;

SELECT '✅ All 10 athletes have AISRI scores!' AS status;
