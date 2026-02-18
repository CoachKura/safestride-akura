-- ========================================
-- 🔧 FIX SIGNUP TRIGGER (UPDATED)
-- ========================================
-- This fixes the "Database error saving new user" issue
-- Run this in Supabase SQL Editor
-- ========================================

-- Drop the old trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop old function
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the correct function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_name TEXT;
BEGIN
  -- Get the role from user metadata (default to 'athlete')
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'athlete');
  user_name := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User');

  -- ALWAYS create a profiles record (required for app)
  -- Using only columns that exist in the table
  BEGIN
    INSERT INTO public.profiles (user_id, name, email)
    VALUES (NEW.id, user_name, NEW.email)
    ON CONFLICT (user_id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
  END;

  -- If user is an athlete, also create athlete_profiles record
  IF user_role = 'athlete' THEN
    BEGIN
      INSERT INTO public.athlete_profiles (user_id)
      VALUES (NEW.id)
      ON CONFLICT (user_id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Error creating athlete_profile for user %: %', NEW.id, SQLERRM;
    END;
  END IF;

  -- If user is a coach, create coach_profiles record
  IF user_role = 'coach' THEN
    BEGIN
      INSERT INTO public.coach_profiles (user_id, coach_name)
      VALUES (NEW.id, user_name)
      ON CONFLICT (user_id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Error creating coach_profile for user %: %', NEW.id, SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- ✅ DONE! Now try signing up again
-- ========================================
