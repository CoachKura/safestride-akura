-- =====================================================
-- SAFESTRIDE - IMPORT 7 EXISTING ATHLETES
-- =====================================================
-- Version: 3.0 (Ready for 14 more tomorrow)
-- Date: 2026-02-16
-- Assessment Type: Quick (3 questions only)
-- =====================================================

-- Athlete 1: Muthulakshmi Sankaranarayanan
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-13 22:38:36'::timestamptz,
  'muthulakshmi.02@gmail.com',
  'Muthulakshmi Sankaranarayanan',
  42,
  'Female',
  3,
  50,
  'Heel spur, Calcaneal pain, PF pain',
  '8',
  'Thyroid, B12 Anemia',
  'Improve running form & prevent injuries',
  'Frequent injuries',
  'Thyroid, B12 Anemia',
  'quick'
);

-- Athlete 2: Chandrasekar Sundaramoorthy
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-14 04:52:20'::timestamptz,
  'chan24san@gmail.com',
  'Chandrasekar Sundaramoorthy',
  43,
  'Male',
  10,
  50,
  'No',
  '0',
  'None',
  'Run sub-1:25 half marathon (sub-4:00/km pace)',
  'Lack of time',
  'None',
  'quick'
);

-- Athlete 3: Dinesh A
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-14 05:47:15'::timestamptz,
  'mailtoadinesh@gmail.com',
  'Dinesh A',
  38,
  'Male',
  1,
  30,
  'Knee pain',
  '2',
  'None',
  'Improve running form & prevent injuries',
  'Knee issues',
  'None',
  'quick'
);

-- Athlete 4: Janarthanan
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-14 17:27:04'::timestamptz,
  'janajake9@gmail.com',
  'Janarthanan',
  37,
  'Male',
  3,
  50,
  'Knee pain, Plantar Fasciitis, Heel spur',
  '1',
  'None',
  'Improve running form & prevent injuries',
  'Multiple chronic issues',
  'None',
  'quick'
);

-- Athlete 5: KRISHNAKUMAR RAM
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-14 21:50:33'::timestamptz,
  'krishchennai0109@gmail.com',
  'KRISHNAKUMAR RAM',
  53,
  'Male',
  7,
  15,
  'NONE',
  '0',
  'NONE',
  'General fitness & health',
  'None',
  'None',
  'quick'
);

-- Athlete 6: Karunakaran
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-15 18:11:36'::timestamptz,
  'gvkarunakharan@gmail.com',
  'Karunakaran',
  48,
  'Male',
  10,
  50,
  'Ankle pain',
  '2',
  'Asthma',
  'Run sub-1:25 half marathon (sub-4:00/km pace)',
  'Ankle issues',
  'Asthma',
  'quick'
);

-- Athlete 7: Vivek
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, previous_injuries, medical_history,
  assessment_type
) VALUES (
  '2026-02-16 11:01:24'::timestamptz,
  'arunvivek24@gmail.com',
  'Vivek',
  31,
  'Male',
  3,
  15,
  'Above ankle',
  '3',
  'None',
  'Run sub-1:30 half marathon',
  'Ankle area concern',
  'None',
  'quick'
);

-- =====================================================
-- VERIFICATION
-- =====================================================
SELECT COUNT(*) AS total_imported FROM public.aisri_intake_raw;

SELECT 
  email,
  full_name,
  age,
  gender,
  q1 AS injuries,
  q2 AS pain_level,
  q3 AS medical,
  assessment_type
FROM public.aisri_intake_raw
ORDER BY submitted_at DESC;

-- =====================================================
-- NEXT STEPS
-- =====================================================
-- Run these commands after import:

-- Step 1: Link profiles (if accounts exist)
-- SELECT * FROM public.link_all_intake_to_profiles();

-- Step 2: Process assessments
-- SELECT * FROM public.process_all_unprocessed_aisri_intakes();

-- Step 3: View dashboard
-- SELECT * FROM public.athlete_intake_dashboard;

-- =====================================================
-- TEMPLATE FOR TOMORROW'S 14 ATHLETES
-- =====================================================
/*
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3,
  training_goals, assessment_type
) VALUES (
  NOW(),
  'athlete@example.com',
  'Athlete Name',
  30,
  'Male',
  2,
  20,
  'None', -- Current injuries
  '0',    -- Pain level (0-10)
  'None', -- Medical conditions
  'Improve fitness',
  'quick'
);
*/

SELECT '✅ 7 athletes imported! Ready for 14 more tomorrow!' AS status;
