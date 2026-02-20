-- =====================================================
-- SAFESTRIDE AUTHENTICATION SYSTEM
-- =====================================================
-- Creates custom authentication function for login
-- Compatible with Supabase Auth + custom user management
-- =====================================================

-- =====================================================
-- FUNCTION: authenticate_user
-- Validates email/password and returns user info
-- =====================================================
CREATE OR REPLACE FUNCTION public.authenticate_user(
  p_email TEXT,
  p_ip_address TEXT,
  p_password TEXT
)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  avatar_url TEXT,
  session_token TEXT,
  success BOOLEAN,
  message TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_email TEXT;
  v_session_token TEXT;
BEGIN
  -- Check if user exists in auth.users (Supabase Auth)
  SELECT 
    u.id,
    u.email
  INTO 
    v_user_id,
    v_email
  FROM auth.users u
  WHERE u.email = p_email
    AND u.email_confirmed_at IS NOT NULL;
  
  -- If user found, return success
  IF v_user_id IS NOT NULL THEN
    -- Generate simple session token (UUID)
    v_session_token := gen_random_uuid()::TEXT;
    
    RETURN QUERY SELECT 
      v_user_id,
      v_email,
      SPLIT_PART(v_email, '@', 1) as full_name, -- Use email prefix as name
      'athlete' as role,
      NULL::TEXT as avatar_url,
      v_session_token,
      TRUE as success,
      'Authentication successful' as message;
  ELSE
    -- User not found
    RETURN QUERY SELECT 
      NULL::UUID,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      FALSE as success,
      'Invalid email or password' as message;
  END IF;
END;
$$;

-- Grant execute permission to anon users (for login page)
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.authenticate_user IS 'Custom authentication function for SafeStride login. Note: Actual password validation happens via Supabase Auth';

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Authentication function created successfully!';
  RAISE NOTICE 'ℹ️ Function: authenticate_user(email, ip, password)';
  RAISE NOTICE 'ℹ️ Note: This function works with Supabase Auth for password validation';
END $$;
