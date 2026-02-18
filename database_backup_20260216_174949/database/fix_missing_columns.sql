-- =====================================================
-- FIX MISSING COLUMNS - Run this in Supabase SQL Editor
-- This adds any missing columns to existing tables
-- =====================================================

-- Fix profiles table
DO $$ 
BEGIN
  -- Add is_active column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='profiles' AND column_name='is_active') THEN
    ALTER TABLE public.profiles ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    RAISE NOTICE 'Added is_active column to profiles';
  END IF;
  
  -- Add email_verified column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='profiles' AND column_name='email_verified') THEN
    ALTER TABLE public.profiles ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
    RAISE NOTICE 'Added email_verified column to profiles';
  END IF;
  
  -- Add last_login_at column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='profiles' AND column_name='last_login_at') THEN
    ALTER TABLE public.profiles ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE 'Added last_login_at column to profiles';
  END IF;
END $$;

-- Fix workouts table
DO $$ 
BEGIN
  -- Add external_id column (for Strava/GPS sync)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='external_id') THEN
    ALTER TABLE public.workouts ADD COLUMN external_id TEXT;
    RAISE NOTICE 'Added external_id column to workouts';
  END IF;
  
  -- Add synced_from column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='synced_from') THEN
    ALTER TABLE public.workouts ADD COLUMN synced_from TEXT;
    RAISE NOTICE 'Added synced_from column to workouts';
  END IF;
  
  -- Add sync_timestamp column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='sync_timestamp') THEN
    ALTER TABLE public.workouts ADD COLUMN sync_timestamp TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE 'Added sync_timestamp column to workouts';
  END IF;
  
  -- Add route_data column (for GPS track/map)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='route_data') THEN
    ALTER TABLE public.workouts ADD COLUMN route_data JSONB;
    RAISE NOTICE 'Added route_data column to workouts';
  END IF;
  
  -- Add title column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='title') THEN
    ALTER TABLE public.workouts ADD COLUMN title TEXT;
    RAISE NOTICE 'Added title column to workouts';
  END IF;
  
  -- Add description column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='description') THEN
    ALTER TABLE public.workouts ADD COLUMN description TEXT;
    RAISE NOTICE 'Added description column to workouts';
  END IF;
  
  -- Add avg_pace_min_per_km column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='avg_pace_min_per_km') THEN
    ALTER TABLE public.workouts ADD COLUMN avg_pace_min_per_km DECIMAL(5, 2);
    RAISE NOTICE 'Added avg_pace_min_per_km column to workouts';
  END IF;
  
  -- Add avg_heart_rate column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='avg_heart_rate') THEN
    ALTER TABLE public.workouts ADD COLUMN avg_heart_rate INTEGER;
    RAISE NOTICE 'Added avg_heart_rate column to workouts';
  END IF;
  
  -- Add max_heart_rate column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='max_heart_rate') THEN
    ALTER TABLE public.workouts ADD COLUMN max_heart_rate INTEGER;
    RAISE NOTICE 'Added max_heart_rate column to workouts';
  END IF;
  
  -- Add calories_burned column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='calories_burned') THEN
    ALTER TABLE public.workouts ADD COLUMN calories_burned INTEGER;
    RAISE NOTICE 'Added calories_burned column to workouts';
  END IF;
  
  -- Add elevation_gain_m column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='elevation_gain_m') THEN
    ALTER TABLE public.workouts ADD COLUMN elevation_gain_m INTEGER;
    RAISE NOTICE 'Added elevation_gain_m column to workouts';
  END IF;
  
  -- Add is_completed column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='public' AND table_name='workouts' AND column_name='is_completed') THEN
    ALTER TABLE public.workouts ADD COLUMN is_completed BOOLEAN DEFAULT TRUE;
    RAISE NOTICE 'Added is_completed column to workouts';
  END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_workouts_external_id ON public.workouts(external_id);
CREATE INDEX IF NOT EXISTS idx_workouts_synced ON public.workouts(synced_from);

-- Create unique index for Strava activities to prevent duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_workouts_strava_unique 
  ON public.workouts(external_id, synced_from) 
  WHERE synced_from = 'strava' AND external_id IS NOT NULL;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ All missing columns have been added successfully!';
  RAISE NOTICE 'You can now sync workouts from Strava.';
END $$;
