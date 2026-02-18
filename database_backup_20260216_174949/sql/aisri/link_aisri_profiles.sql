-- =====================================================
-- SAFESTRIDE - LINK AISRI INTAKE TO PROFILES (FIXED)
-- Schema-Compatible Version
-- =====================================================
-- Project: xzxnnswggwqtctcgpocr (PRODUCTION)
-- Date: February 16, 2026
-- Purpose: Link aisri_intake_raw records to profiles via email
-- FIXED: Uses public.profiles correctly
-- =====================================================

-- =====================================================
-- STEP 1: Link Profiles by Email (Case-Insensitive)
-- =====================================================

UPDATE public.aisri_intake_raw r
SET 
  profile_id = p.id,
  updated_at = NOW()
FROM public.profiles p
WHERE 
  LOWER(r.email) = LOWER(p.email)
  AND r.profile_id IS NULL;

-- Display results
DO $$
DECLARE
  matched_count INTEGER;
  unmatched_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO matched_count
  FROM public.aisri_intake_raw
  WHERE profile_id IS NOT NULL;
  
  SELECT COUNT(*) INTO unmatched_count
  FROM public.aisri_intake_raw
  WHERE profile_id IS NULL;
  
  RAISE NOTICE '✅ Profile Linking Complete:';
  RAISE NOTICE '   - Matched: % records', matched_count;
  RAISE NOTICE '   - Unmatched: % records', unmatched_count;
  
  IF unmatched_count > 0 THEN
    RAISE NOTICE '⚠️ Unmatched records need athlete signup';
  END IF;
END $$;

-- =====================================================
-- STEP 2: View Unmatched Records
-- =====================================================

SELECT 
  email,
  full_name,
  submitted_at,
  'Athlete needs to sign up' as status
FROM public.aisri_intake_raw
WHERE profile_id IS NULL
ORDER BY submitted_at DESC;

-- =====================================================
-- STEP 3: Helper Function for Future Linking
-- =====================================================

CREATE OR REPLACE FUNCTION public.link_intake_to_profile(intake_email TEXT)
RETURNS TABLE(
  status TEXT,
  intake_id UUID,
  profile_id UUID,
  athlete_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  UPDATE public.aisri_intake_raw r
  SET 
    profile_id = p.id,
    updated_at = NOW()
  FROM public.profiles p
  WHERE 
    LOWER(r.email) = LOWER(intake_email)
    AND LOWER(p.email) = LOWER(intake_email)
    AND r.profile_id IS NULL
  RETURNING 
    'Linked successfully'::TEXT as status,
    r.id as intake_id,
    r.profile_id,
    r.full_name as athlete_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 4: Batch Link All Unlinked Records
-- =====================================================

CREATE OR REPLACE FUNCTION public.link_all_intake_to_profiles()
RETURNS TABLE(
  total_linked INTEGER,
  total_unmatched INTEGER
) AS $$
DECLARE
  linked_count INTEGER;
  unmatched_count INTEGER;
BEGIN
  UPDATE public.aisri_intake_raw r
  SET 
    profile_id = p.id,
    updated_at = NOW()
  FROM public.profiles p
  WHERE 
    LOWER(r.email) = LOWER(p.email)
    AND r.profile_id IS NULL;
  
  GET DIAGNOSTICS linked_count = ROW_COUNT;
  
  SELECT COUNT(*) INTO unmatched_count
  FROM public.aisri_intake_raw
  WHERE profile_id IS NULL;
  
  RETURN QUERY SELECT linked_count, unmatched_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 
  '✅ Profile linking functions created' as status,
  COUNT(*) FILTER (WHERE profile_id IS NOT NULL) as linked,
  COUNT(*) FILTER (WHERE profile_id IS NULL) as unlinked
FROM public.aisri_intake_raw;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

/*
1. Link all after CSV import:
   SELECT * FROM link_all_intake_to_profiles();

2. Link specific athlete:
   SELECT * FROM link_intake_to_profile('athlete@example.com');

3. Check status:
   SELECT 
     COUNT(*) FILTER (WHERE profile_id IS NOT NULL) as linked,
     COUNT(*) FILTER (WHERE profile_id IS NULL) as unlinked
   FROM aisri_intake_raw;

4. View unmatched:
   SELECT email, full_name FROM aisri_intake_raw WHERE profile_id IS NULL;
*/

-- =====================================================
-- END OF SCRIPT
-- =====================================================
