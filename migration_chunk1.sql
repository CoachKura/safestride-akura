-- =====================================================
-- CHUNK 1: Extend profiles table only
-- =====================================================

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'athlete' 
        CHECK (role IN ('admin', 'coach', 'athlete'));
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='coach_id') THEN
        ALTER TABLE public.profiles ADD COLUMN coach_id UUID REFERENCES public.profiles(id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='onboarding_completed') THEN
        ALTER TABLE public.profiles ADD COLUMN onboarding_completed BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='profiles' AND column_name='gender') THEN
        ALTER TABLE public.profiles ADD COLUMN gender TEXT CHECK (gender IN ('male', 'female', 'other'));
        ALTER TABLE public.profiles ADD COLUMN weight DECIMAL(5,2);
        ALTER TABLE public.profiles ADD COLUMN height DECIMAL(5,2);
        ALTER TABLE public.profiles ADD COLUMN max_hr INTEGER;
    END IF;
END $$;
