-- SafeStride seed data
-- Minimal seed set: 7 test athletes for AISRI and device testing

INSERT INTO public.profiles (id, email, full_name)
VALUES
  (gen_random_uuid(), 'runner1@example.com', 'Runner One'),
  (gen_random_uuid(), 'runner2@example.com', 'Runner Two'),
  (gen_random_uuid(), 'runner3@example.com', 'Runner Three'),
  (gen_random_uuid(), 'runner4@example.com', 'Runner Four'),
  (gen_random_uuid(), 'runner5@example.com', 'Runner Five'),
  (gen_random_uuid(), 'runner6@example.com', 'Runner Six'),
  (gen_random_uuid(), 'runner7@example.com', 'Runner Seven');

-- NOTE:
-- Supabase will normally keep auth.users and profiles in sync using triggers.
-- In a brand new project, you should still create corresponding auth users
-- (via the Supabase dashboard or API) using the same emails so that login
-- works and the profile ids reference real auth.users(id) rows.
