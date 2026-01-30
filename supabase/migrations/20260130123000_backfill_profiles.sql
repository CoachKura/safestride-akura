-- Backfill missing profiles from auth.users
-- This migration inserts a profile row for any auth user that does not
-- already have a corresponding row in public.profiles.

BEGIN;

INSERT INTO public.profiles (id, full_name, email, role, created_at, updated_at)
SELECT u.id,
       COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'fullName', u.email) AS full_name,
       u.email,
       'athlete',
       NOW(),
       NOW()
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);

COMMIT;
