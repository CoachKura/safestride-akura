-- 🔧 QUICK FIX: Create Athlete Profile for Current User
-- Run this ONLY if verify_schema.sql shows you're missing athlete_profiles record

-- Step 1: Check if athlete_profiles table exists
-- If it doesn't exist, you need to run COMPLETE_DATABASE_MIGRATION.sql first!

-- Step 2: Create athlete profile for your user
-- Replace the user_id with YOUR actual user ID from the app logs
-- Your ID is: e1f2abfc-a1bb-4a85-b616-fec751de5dc3

INSERT INTO athlete_profiles (
  user_id,
  latest_aisri_score,
  mobility_score,
  strength_score,
  balance_score,
  flexibility_score,
  endurance_score,
  power_score,
  created_at,
  updated_at
) VALUES (
  'e1f2abfc-a1bb-4a85-b616-fec751de5dc3', -- Your user ID
  60,  -- Default AISRI score
  60,  -- Default mobility
  60,  -- Default strength
  60,  -- Default balance
  60,  -- Default flexibility
  60,  -- Default endurance
  60,  -- Default power
  NOW(),
  NOW()
)
ON CONFLICT (user_id) DO NOTHING;

-- Step 3: Verify it was created
SELECT 
  id,
  user_id,
  latest_aisri_score,
  created_at
FROM athlete_profiles
WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3';

-- Expected: 1 row showing your athlete profile

-- Step 4: If you've completed the AISRI assessment, update the scores
-- Run this AFTER doing the assessment in the app:

-- UPDATE athlete_profiles
-- SET 
--   latest_aisri_score = [your actual score],
--   mobility_score = [your mobility score],
--   strength_score = [your strength score],
--   balance_score = [your balance score],
--   flexibility_score = [your flexibility score],
--   endurance_score = [your endurance score],
--   power_score = [your power score],
--   last_assessment_date = NOW(),
--   updated_at = NOW()
-- WHERE user_id = 'e1f2abfc-a1bb-4a85-b616-fec751de5dc3';
