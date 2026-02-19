-- =====================================================
-- AKURA SAFESTRIDE - COMPLETE AUTHENTICATION SYSTEM
-- Version: 1.0
-- Created: 2026-02-19
-- Purpose: Add authentication with admin/coach/athlete roles
-- =====================================================

-- =====================================================
-- TABLE 1: User Roles and Permissions
-- =====================================================

CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_name TEXT UNIQUE NOT NULL CHECK (role_name IN ('admin', 'coach', 'athlete')),
  role_description TEXT,
  permissions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default roles
INSERT INTO public.user_roles (role_name, role_description, permissions) VALUES
('admin', 'System administrator with full access', '{
  "can_create_coaches": true,
  "can_create_athletes": true,
  "can_view_all_data": true,
  "can_modify_system": true,
  "can_delete_users": true
}'::jsonb),
('coach', 'Coach who manages athletes', '{
  "can_create_athletes": true,
  "can_view_own_athletes": true,
  "can_assign_protocols": true,
  "can_view_reports": true,
  "can_modify_own_athletes": true
}'::jsonb),
('athlete', 'Athlete with personal dashboard', '{
  "can_view_own_data": true,
  "can_update_own_profile": true,
  "can_log_workouts": true,
  "can_connect_devices": true,
  "can_change_password": true
}'::jsonb)
ON CONFLICT (role_name) DO NOTHING;

-- =====================================================
-- TABLE 2: Users (Authentication)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL, -- Hashed with bcrypt
  full_name TEXT NOT NULL,
  role_id UUID NOT NULL REFERENCES public.user_roles(id),
  
  -- Account Status
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  must_change_password BOOLEAN DEFAULT false, -- For first-time login
  
  -- Profile
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  
  -- Coach Assignment (for athletes only)
  coach_id UUID REFERENCES public.users(id),
  
  -- Login Tracking
  last_login_at TIMESTAMPTZ,
  last_login_ip TEXT,
  login_count INTEGER DEFAULT 0,
  
  -- Password Reset
  reset_token TEXT,
  reset_token_expires_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id)
);

-- Create indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role_id);
CREATE INDEX idx_users_coach ON public.users(coach_id);
CREATE INDEX idx_users_active ON public.users(is_active);

COMMENT ON TABLE public.users IS 'User authentication and profile data with role-based access';

-- =====================================================
-- TABLE 3: Profiles (Extended athlete information)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- Athlete-specific data
  athlete_uid TEXT UNIQUE, -- Unique athlete identifier (e.g., ATH001)
  height_cm DECIMAL(5,2),
  weight_kg DECIMAL(5,2),
  
  -- Running Profile
  max_heart_rate_bpm INTEGER,
  resting_heart_rate_bpm INTEGER,
  vo2_max DECIMAL(5,2),
  
  -- Goals
  primary_goal TEXT,
  target_race_distance TEXT,
  target_race_date DATE,
  
  -- Injury History
  injury_history JSONB DEFAULT '[]',
  current_injuries JSONB DEFAULT '[]',
  
  -- Medical
  medical_conditions TEXT[],
  medications TEXT[],
  allergies TEXT[],
  
  -- Emergency Contact
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  
  -- Device Connections
  strava_connected BOOLEAN DEFAULT false,
  strava_athlete_id TEXT,
  garmin_connected BOOLEAN DEFAULT false,
  garmin_user_id TEXT,
  
  -- Notes
  coach_notes TEXT,
  athlete_notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_user ON public.profiles(user_id);
CREATE INDEX idx_profiles_athlete_uid ON public.profiles(athlete_uid);
CREATE INDEX idx_profiles_strava ON public.profiles(strava_connected);

COMMENT ON TABLE public.profiles IS 'Extended profile information for athletes including goals, medical data, and device connections';

-- =====================================================
-- TABLE 4: Audit Log
-- =====================================================

CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON public.audit_log(user_id);
CREATE INDEX idx_audit_created ON public.audit_log(created_at DESC);
CREATE INDEX idx_audit_action ON public.audit_log(action);

COMMENT ON TABLE public.audit_log IS 'Audit trail for all user actions and data modifications';

-- =====================================================
-- TABLE 5: Session Management
-- =====================================================

CREATE TABLE IF NOT EXISTS public.user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  session_token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON public.user_sessions(user_id);
CREATE INDEX idx_sessions_token ON public.user_sessions(session_token);
CREATE INDEX idx_sessions_expires ON public.user_sessions(expires_at);

COMMENT ON TABLE public.user_sessions IS 'Active user sessions for authentication';

-- =====================================================
-- FUNCTION 1: Create Athlete Account (by Coach/Admin)
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_athlete_account(
  p_email TEXT,
  p_full_name TEXT,
  p_temporary_password TEXT,
  p_coach_id UUID,
  p_athlete_uid TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_date_of_birth DATE DEFAULT NULL,
  p_gender TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
  v_profile_id UUID;
  v_athlete_role_id UUID;
  v_generated_uid TEXT;
BEGIN
  -- Get athlete role ID
  SELECT id INTO v_athlete_role_id FROM public.user_roles WHERE role_name = 'athlete';
  
  -- Generate athlete UID if not provided
  IF p_athlete_uid IS NULL THEN
    v_generated_uid := 'ATH' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  ELSE
    v_generated_uid := p_athlete_uid;
  END IF;
  
  -- Create user account
  INSERT INTO public.users (
    email, 
    password_hash, 
    full_name, 
    role_id, 
    coach_id,
    phone,
    date_of_birth,
    gender,
    must_change_password,
    created_by
  ) VALUES (
    p_email,
    crypt(p_temporary_password, gen_salt('bf')), -- bcrypt hash
    p_full_name,
    v_athlete_role_id,
    p_coach_id,
    p_phone,
    p_date_of_birth,
    p_gender,
    true, -- Must change password on first login
    p_coach_id
  )
  RETURNING id INTO v_user_id;
  
  -- Create profile
  INSERT INTO public.profiles (
    user_id,
    athlete_uid
  ) VALUES (
    v_user_id,
    v_generated_uid
  )
  RETURNING id INTO v_profile_id;
  
  -- Log action
  INSERT INTO public.audit_log (user_id, action, entity_type, entity_id, new_data)
  VALUES (
    p_coach_id,
    'CREATE_ATHLETE',
    'users',
    v_user_id,
    jsonb_build_object('email', p_email, 'full_name', p_full_name, 'athlete_uid', v_generated_uid)
  );
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_athlete_account IS 'Create a new athlete account with temporary password (coach/admin only)';

-- =====================================================
-- FUNCTION 2: Authenticate User
-- =====================================================

CREATE OR REPLACE FUNCTION public.authenticate_user(
  p_email TEXT,
  p_password TEXT,
  p_ip_address TEXT DEFAULT NULL
)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  role_name TEXT,
  must_change_password BOOLEAN,
  coach_id UUID,
  athlete_uid TEXT,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_user RECORD;
  v_password_match BOOLEAN;
BEGIN
  -- Get user with role
  SELECT 
    u.id,
    u.email,
    u.full_name,
    u.password_hash,
    u.is_active,
    u.must_change_password,
    u.coach_id,
    ur.role_name,
    p.athlete_uid
  INTO v_user
  FROM public.users u
  JOIN public.user_roles ur ON u.role_id = ur.id
  LEFT JOIN public.profiles p ON p.user_id = u.id
  WHERE u.email = p_email;
  
  -- Check if user exists
  IF v_user.id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::UUID,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::BOOLEAN,
      NULL::UUID,
      NULL::TEXT,
      false,
      'Invalid email or password';
    RETURN;
  END IF;
  
  -- Check if account is active
  IF NOT v_user.is_active THEN
    RETURN QUERY SELECT 
      NULL::UUID,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::BOOLEAN,
      NULL::UUID,
      NULL::TEXT,
      false,
      'Account is deactivated';
    RETURN;
  END IF;
  
  -- Verify password
  v_password_match := (v_user.password_hash = crypt(p_password, v_user.password_hash));
  
  IF NOT v_password_match THEN
    RETURN QUERY SELECT 
      NULL::UUID,
      NULL::TEXT,
      NULL::TEXT,
      NULL::TEXT,
      NULL::BOOLEAN,
      NULL::UUID,
      NULL::TEXT,
      false,
      'Invalid email or password';
    RETURN;
  END IF;
  
  -- Update login tracking
  UPDATE public.users
  SET 
    last_login_at = NOW(),
    last_login_ip = p_ip_address,
    login_count = login_count + 1,
    updated_at = NOW()
  WHERE id = v_user.id;
  
  -- Log successful login
  INSERT INTO public.audit_log (user_id, action, ip_address)
  VALUES (v_user.id, 'LOGIN_SUCCESS', p_ip_address);
  
  -- Return user info
  RETURN QUERY SELECT 
    v_user.id,
    v_user.email,
    v_user.full_name,
    v_user.role_name,
    v_user.must_change_password,
    v_user.coach_id,
    v_user.athlete_uid,
    true,
    'Login successful';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.authenticate_user IS 'Authenticate user with email and password, returns user info and role';

-- =====================================================
-- FUNCTION 3: Change Password
-- =====================================================

CREATE OR REPLACE FUNCTION public.change_password(
  p_user_id UUID,
  p_old_password TEXT,
  p_new_password TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_current_hash TEXT;
  v_password_match BOOLEAN;
BEGIN
  -- Get current password hash
  SELECT password_hash INTO v_current_hash
  FROM public.users
  WHERE id = p_user_id;
  
  -- Verify old password
  v_password_match := (v_current_hash = crypt(p_old_password, v_current_hash));
  
  IF NOT v_password_match THEN
    RETURN QUERY SELECT false, 'Current password is incorrect';
    RETURN;
  END IF;
  
  -- Validate new password (min 8 characters)
  IF LENGTH(p_new_password) < 8 THEN
    RETURN QUERY SELECT false, 'New password must be at least 8 characters';
    RETURN;
  END IF;
  
  -- Update password
  UPDATE public.users
  SET 
    password_hash = crypt(p_new_password, gen_salt('bf')),
    must_change_password = false,
    updated_at = NOW()
  WHERE id = p_user_id;
  
  -- Log password change
  INSERT INTO public.audit_log (user_id, action)
  VALUES (p_user_id, 'PASSWORD_CHANGED');
  
  RETURN QUERY SELECT true, 'Password changed successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.change_password IS 'Change user password with old password verification';

-- =====================================================
-- FUNCTION 4: Get Coach Athletes
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_coach_athletes(p_coach_id UUID)
RETURNS TABLE (
  athlete_id UUID,
  athlete_uid TEXT,
  email TEXT,
  full_name TEXT,
  phone TEXT,
  strava_connected BOOLEAN,
  last_login_at TIMESTAMPTZ,
  aisri_score INTEGER,
  risk_category TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    p.athlete_uid,
    u.email,
    u.full_name,
    u.phone,
    p.strava_connected,
    u.last_login_at,
    a.total_score,
    a.risk_category,
    u.created_at
  FROM public.users u
  JOIN public.profiles p ON p.user_id = u.id
  LEFT JOIN LATERAL (
    SELECT * FROM public.aisri_scores
    WHERE athlete_id = p.athlete_uid
    ORDER BY assessment_date DESC
    LIMIT 1
  ) a ON true
  WHERE u.coach_id = p_coach_id
    AND u.is_active = true
  ORDER BY u.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_coach_athletes IS 'Get all athletes assigned to a specific coach with their latest AISRI scores';

-- =====================================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Coaches can view their athletes"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users coach
      WHERE coach.id = auth.uid()
        AND users.coach_id = coach.id
    )
  );

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- RLS Policies for profiles table
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Coaches can view athlete profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = user_id
        AND users.coach_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (user_id = auth.uid());

-- =====================================================
-- CREATE DEFAULT ADMIN ACCOUNT
-- =====================================================

DO $$
DECLARE
  v_admin_role_id UUID;
  v_admin_user_id UUID;
BEGIN
  -- Get admin role
  SELECT id INTO v_admin_role_id FROM public.user_roles WHERE role_name = 'admin';
  
  -- Create default admin (password: Admin@123)
  INSERT INTO public.users (
    email,
    password_hash,
    full_name,
    role_id,
    is_active,
    email_verified
  ) VALUES (
    'admin@akura.in',
    crypt('Admin@123', gen_salt('bf')),
    'System Administrator',
    v_admin_role_id,
    true,
    true
  )
  ON CONFLICT (email) DO NOTHING
  RETURNING id INTO v_admin_user_id;
  
  IF v_admin_user_id IS NOT NULL THEN
    RAISE NOTICE 'Default admin created: admin@akura.in / Admin@123';
  END IF;
END $$;

-- =====================================================
-- CREATE DEFAULT COACH ACCOUNT (Kura B Sathyamoorthy)
-- =====================================================

DO $$
DECLARE
  v_coach_role_id UUID;
  v_coach_user_id UUID;
  v_coach_profile_id UUID;
BEGIN
  -- Get coach role
  SELECT id INTO v_coach_role_id FROM public.user_roles WHERE role_name = 'coach';
  
  -- Create coach account
  INSERT INTO public.users (
    email,
    password_hash,
    full_name,
    role_id,
    phone,
    is_active,
    email_verified
  ) VALUES (
    'coach@akura.in',
    crypt('Coach@123', gen_salt('bf')),
    'Kura B Sathyamoorthy',
    v_coach_role_id,
    '+91 9876543210',
    true,
    true
  )
  ON CONFLICT (email) DO NOTHING
  RETURNING id INTO v_coach_user_id;
  
  IF v_coach_user_id IS NOT NULL THEN
    -- Create coach profile
    INSERT INTO public.profiles (user_id)
    VALUES (v_coach_user_id)
    RETURNING id INTO v_coach_profile_id;
    
    RAISE NOTICE 'Default coach created: coach@akura.in / Coach@123';
  END IF;
END $$;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT SELECT ON public.user_roles TO anon, authenticated;
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT ON public.audit_log TO authenticated;
GRANT INSERT, DELETE ON public.user_sessions TO authenticated;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ AUTHENTICATION SYSTEM CREATED!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Tables Created:';
  RAISE NOTICE '  1. user_roles - Admin, Coach, Athlete roles';
  RAISE NOTICE '  2. users - User authentication';
  RAISE NOTICE '  3. profiles - Extended athlete profiles';
  RAISE NOTICE '  4. audit_log - Security audit trail';
  RAISE NOTICE '  5. user_sessions - Session management';
  RAISE NOTICE '';
  RAISE NOTICE 'Functions Created:';
  RAISE NOTICE '  1. create_athlete_account() - Coach creates athletes';
  RAISE NOTICE '  2. authenticate_user() - Login function';
  RAISE NOTICE '  3. change_password() - Password change';
  RAISE NOTICE '  4. get_coach_athletes() - List coach athletes';
  RAISE NOTICE '';
  RAISE NOTICE 'Default Accounts:';
  RAISE NOTICE '  Admin: admin@akura.in / Admin@123';
  RAISE NOTICE '  Coach: coach@akura.in / Coach@123';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  IMPORTANT: Change default passwords immediately!';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Step: Deploy to Supabase';
END $$;

-- Verification
SELECT 
  'Roles' AS type, COUNT(*) AS count FROM public.user_roles
UNION ALL
SELECT 'Users' AS type, COUNT(*) AS count FROM public.users
UNION ALL
SELECT 'Profiles' AS type, COUNT(*) AS count FROM public.profiles;

SELECT role_name, role_description 
FROM public.user_roles 
ORDER BY 
  CASE role_name 
    WHEN 'admin' THEN 1 
    WHEN 'coach' THEN 2 
    WHEN 'athlete' THEN 3 
  END;
