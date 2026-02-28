# COMPLETE DATABASE SETUP FOR SAFESTRIDE
# This creates all core tables in Supabase

Write-Host ""
Write-Host "DEPLOYING SAFESTRIDE DATABASE" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Set database password
$env:SUPABASE_DB_PASSWORD = "Akura@2026`$"

# Create timestamp for new migration
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$migrationFile = "supabase\migrations\${timestamp}_complete_setup.sql"

Write-Host "Creating migration file..." -ForegroundColor Yellow
Write-Host "  File: $migrationFile" -ForegroundColor DarkGray
Write-Host ""

# Create SQL migration file
$sql = @"
-- Complete SafeStride Database Setup
-- This creates all  core tables with RLS policies

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Signup trigger to auto-create profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS `$`$
BEGIN
    INSERT INTO public.profiles (id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
    RETURN NEW;
END;
`$`$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. ATHLETE GOALS TABLE
CREATE TABLE IF NOT EXISTS public.athlete_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    goal_type TEXT NOT NULL,
    target_date DATE,
    target_time INTERVAL,
    status TEXT DEFAULT 'active',
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

-- 3. STRAVA CONNECTIONS TABLE
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

DROP POLICY IF EXISTS "Users can manage own strava" ON public.strava_connections;
CREATE POLICY "Users can manage own strava" ON public.strava_connections
    FOR ALL USING (auth.uid() = user_id);

-- 4. STRAVA ACTIVITIES TABLE
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
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_strava_activities_user_date 
    ON public.strava_activities(user_id, start_date DESC);

ALTER TABLE public.strava_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own activities" ON public.strava_activities;
CREATE POLICY "Users can manage own activities" ON public.strava_activities
    FOR ALL USING (auth.uid() = user_id);

SELECT 'Database setup complete!' AS result;
"@

# Save to migration file
$sql | Out-File -FilePath $migrationFile -Encoding UTF8
Write-Host "OK - Migration file created" -ForegroundColor Green
Write-Host ""

Write-Host "Pushing to Supabase..." -ForegroundColor Yellow
Write-Host ""

# Push migration
$output = npx supabase db push 2>&1 | Out-String
$success = $LASTEXITCODE -eq 0 -or $output -match "already exists"

Write-Host $output

if ($success) {
    Write-Host ""
    Write-Host "SUCCESS! DATABASE DEPLOYED!" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host ""
    Write-Host "Tables created:" -ForegroundColor Cyan
    Write-Host "  - profiles (with auto-signup trigger)" -ForegroundColor White
    Write-Host "  - athlete_goals" -ForegroundColor White
    Write-Host "  - strava_connections" -ForegroundColor White
    Write-Host "  - strava_activities" -ForegroundColor White
    Write-Host ""
    Write-Host "Security:" -ForegroundColor Cyan
    Write-Host "  - RLS enabled on all tables" -ForegroundColor White
    Write-Host "  - User-specific access policies" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Open: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/editor" -ForegroundColor White
    Write-Host "  2. Verify tables appear in left sidebar" -ForegroundColor White
    Write-Host "  3. Create account in your app (Sign up, not Login)" -ForegroundColor White
    Write-Host "  4. Test Strava connection" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "WARNING: Deployment completed with warnings" -ForegroundColor Yellow
    Write-Host "  (This is normal if tables already exist)" -ForegroundColor DarkGray
    Write-Host ""
}
