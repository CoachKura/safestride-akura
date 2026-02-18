-- ================================================
-- DEPLOY MISSING SAFESTRIDE TABLES
-- ================================================

-- TABLE 2: athlete_goals
CREATE TABLE IF NOT EXISTS public.athlete_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    goal_type TEXT NOT NULL CHECK (goal_type IN ('5K', '10K', 'Half Marathon', 'Marathon', 'Ultra', 'Other')),
    target_date DATE,
    target_time INTERVAL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.athlete_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own goals" ON public.athlete_goals;
CREATE POLICY "Users can view own goals" ON public.athlete_goals
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own goals" ON public.athlete_goals;
CREATE POLICY "Users can insert own goals" ON public.athlete_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own goals" ON public.athlete_goals;
CREATE POLICY "Users can update own goals" ON public.athlete_goals
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own goals" ON public.athlete_goals;
CREATE POLICY "Users can delete own goals" ON public.athlete_goals
    FOR DELETE USING (auth.uid() = user_id);

-- TABLE 3: structured_workouts
CREATE TABLE IF NOT EXISTS public.structured_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    workout_name TEXT NOT NULL,
    workout_type TEXT NOT NULL,
    aisri_zone INTEGER CHECK (aisri_zone >= 1 AND aisri_zone <= 5),
    duration_minutes INTEGER,
    distance_km DECIMAL(10, 2),
    intensity_level TEXT CHECK (intensity_level IN ('easy', 'moderate', 'hard', 'very_hard')),
    description TEXT,
    is_template BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.structured_workouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view workouts" ON public.structured_workouts;
CREATE POLICY "Users can view workouts" ON public.structured_workouts
    FOR SELECT USING (auth.uid() = user_id OR is_template = true);

DROP POLICY IF EXISTS "Users can insert own workouts" ON public.structured_workouts;
CREATE POLICY "Users can insert own workouts" ON public.structured_workouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own workouts" ON public.structured_workouts;
CREATE POLICY "Users can update own workouts" ON public.structured_workouts
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own workouts" ON public.structured_workouts;
CREATE POLICY "Users can delete own workouts" ON public.structured_workouts
    FOR DELETE USING (auth.uid() = user_id);

-- TABLE 4: strava_connections
CREATE TABLE IF NOT EXISTS public.strava_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    athlete_id BIGINT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.strava_connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own strava connection" ON public.strava_connections;
CREATE POLICY "Users can view own strava connection" ON public.strava_connections
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own strava connection" ON public.strava_connections;
CREATE POLICY "Users can insert own strava connection" ON public.strava_connections
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own strava connection" ON public.strava_connections;
CREATE POLICY "Users can update own strava connection" ON public.strava_connections
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own strava connection" ON public.strava_connections;
CREATE POLICY "Users can delete own strava connection" ON public.strava_connections
    FOR DELETE USING (auth.uid() = user_id);

-- TABLE 5: strava_activities
CREATE TABLE IF NOT EXISTS public.strava_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    strava_activity_id BIGINT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    distance_meters DECIMAL(10, 2),
    moving_time_seconds INTEGER,
    elapsed_time_seconds INTEGER,
    total_elevation_gain DECIMAL(10, 2),
    average_heartrate DECIMAL(5, 1),
    max_heartrate INTEGER,
    average_speed DECIMAL(5, 2),
    max_speed DECIMAL(5, 2),
    calories DECIMAL(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_strava_activities_user_date 
    ON public.strava_activities(user_id, start_date DESC);

ALTER TABLE public.strava_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own strava activities" ON public.strava_activities;
CREATE POLICY "Users can view own strava activities" ON public.strava_activities
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own strava activities" ON public.strava_activities;
CREATE POLICY "Users can insert own strava activities" ON public.strava_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own strava activities" ON public.strava_activities;
CREATE POLICY "Users can update own strava activities" ON public.strava_activities
    FOR UPDATE USING (auth.uid() = user_id);

-- Verification
SELECT 'DEPLOYMENT COMPLETE!' as status;
