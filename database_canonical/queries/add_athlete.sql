-- =====================================================
-- SAFESTRIDE - ADD NEW ATHLETE TEMPLATE
-- =====================================================
-- INSTRUCTIONS:
-- 1. Copy this entire INSERT block
-- 2. Modify the values (email, name, age, etc.)
-- 3. Execute the query
-- 4. Run process_all.sql to calculate scores
-- =====================================================

INSERT INTO public.aisri_intake_raw (
  submitted_at, 
  email, 
  full_name, 
  age, 
  gender,
  running_experience_years, 
  weekly_mileage_km,
  q1,    -- Current injuries
  q2,    -- Pain level (0-10)
  q3,    -- Medical conditions
  training_goals,
  assessment_type
) VALUES (
  NOW(),
  'NEW_EMAIL@gmail.com',          -- ⚠️ CHANGE THIS - Real Gmail
  'NEW ATHLETE NAME',             -- ⚠️ CHANGE THIS - Full name
  30,                             -- ⚠️ CHANGE THIS - Age (18-100)
  'Male',                         -- ⚠️ CHANGE THIS - Male/Female
  2,                              -- Years running experience
  20,                             -- Weekly mileage in km
  'None',                         -- Current injuries (or specific description)
  '0',                            -- Pain level as string '0'-'10'
  'None',                         -- Medical conditions (or specific)
  'Improve fitness',              -- Training goals
  'quick'                         -- Assessment type (always 'quick')
);

-- =====================================================
-- AFTER INSERTING, RUN THIS TO VERIFY:
-- =====================================================
SELECT * FROM public.aisri_intake_raw 
WHERE email = 'NEW_EMAIL@gmail.com'  -- Use the email you just added
ORDER BY submitted_at DESC 
LIMIT 1;

-- =====================================================
-- TEMPLATE FOR BULK INSERT (14 ATHLETES)
-- =====================================================
-- Copy this block 14 times, modify each, then execute all at once:

/*
INSERT INTO public.aisri_intake_raw (
  submitted_at, email, full_name, age, gender,
  running_experience_years, weekly_mileage_km,
  q1, q2, q3, training_goals, assessment_type
) VALUES 
  (NOW(), 'athlete1@gmail.com', 'Athlete One', 25, 'Male', 1, 15, 'None', '0', 'None', 'Build endurance', 'quick'),
  (NOW(), 'athlete2@gmail.com', 'Athlete Two', 28, 'Female', 2, 20, 'Knee pain', '3', 'None', 'Half marathon', 'quick'),
  (NOW(), 'athlete3@gmail.com', 'Athlete Three', 35, 'Male', 5, 40, 'None', '1', 'Asthma', 'Improve speed', 'quick');
  -- Add 11 more rows...
*/
