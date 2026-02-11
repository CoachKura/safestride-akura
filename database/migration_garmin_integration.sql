
-- ============================================================================
-- GARMIN INTEGRATION - Complete Migration
-- ============================================================================
-- This migration includes:
-- 1. Local device connections (Bluetooth/WiFi) - garmin_devices
-- 2. OAuth connections (Garmin Connect API) - garmin_connections
-- 3. Activity sync - garmin_activities
-- 4. Workout push - garmin_pushed_workouts
-- ============================================================================

-- ============================================================================
-- 1. GARMIN DEVICES (Local Bluetooth/WiFi connections)
-- ============================================================================
CREATE TABLE IF NOT EXISTS garmin_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL UNIQUE,
    device_name VARCHAR(255) NOT NULL,
    connection_type VARCHAR(20) DEFAULT 'bluetooth' CHECK (connection_type IN ('bluetooth', 'wifi', 'both')),
    ip_address VARCHAR(45),
    device_info JSONB,
    last_connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_sync_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    sync_settings JSONB DEFAULT '{"auto_sync": true, "sync_interval_hours": 24}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add columns to existing table if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='garmin_devices' AND column_name='connection_type') THEN
        ALTER TABLE garmin_devices ADD COLUMN connection_type VARCHAR(20) DEFAULT 'bluetooth' CHECK (connection_type IN ('bluetooth', 'wifi', 'both'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='garmin_devices' AND column_name='ip_address') THEN
        ALTER TABLE garmin_devices ADD COLUMN ip_address VARCHAR(45);
    END IF;
END $$;

-- Add device_source column to gps_activities if table exists
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='gps_activities') THEN
        ALTER TABLE gps_activities ADD COLUMN IF NOT EXISTS device_source VARCHAR(50);
        ALTER TABLE gps_activities ADD COLUMN IF NOT EXISTS device_id VARCHAR(255);
    END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_garmin_devices_user_id ON garmin_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_garmin_devices_device_id ON garmin_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_garmin_devices_active ON garmin_devices(user_id, is_active) WHERE is_active = TRUE;

-- Create index on gps_activities if table exists
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='gps_activities') THEN
        CREATE INDEX IF NOT EXISTS idx_gps_activities_device_source ON gps_activities(device_source);
    END IF;
END $$;

-- ============================================================================
-- 2. GARMIN CONNECTIONS (OAuth API connections to Garmin Connect)
-- ============================================================================
CREATE TABLE IF NOT EXISTS garmin_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    garmin_user_id TEXT NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    token_expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(athlete_id, garmin_user_id)
);

-- ============================================================================
-- 3. GARMIN ACTIVITIES (Synced workouts from Garmin Connect)
-- ============================================================================
CREATE TABLE IF NOT EXISTS garmin_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    garmin_activity_id BIGINT NOT NULL UNIQUE,
    activity_type TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    duration INTEGER NOT NULL,
    distance DECIMAL(10, 2),
    average_heart_rate INTEGER,
    max_heart_rate INTEGER,
    average_pace DECIMAL(5, 2),
    calories INTEGER,
    elevation_gain DECIMAL(10, 2),
    training_effect DECIMAL(3, 1),
    vo2_max DECIMAL(4, 1),
    fit_file_url TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_garmin_activities_athlete ON garmin_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_garmin_activities_date ON garmin_activities(athlete_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_garmin_activities_garmin_id ON garmin_activities(garmin_activity_id);

-- ============================================================================
-- 4. GARMIN PUSHED WORKOUTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS garmin_pushed_workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    safestride_workout_id UUID,
    garmin_workout_id TEXT,
    workout_name TEXT NOT NULL,
    workout_type TEXT NOT NULL,
    scheduled_date DATE,
    push_status TEXT DEFAULT 'pending' CHECK (push_status IN ('pending', 'success', 'failed')),
    pushed_at TIMESTAMPTZ,
    garmin_response JSONB,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_garmin_pushed_athlete ON garmin_pushed_workouts(athlete_id);
CREATE INDEX IF NOT EXISTS idx_garmin_pushed_date ON garmin_pushed_workouts(scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_garmin_pushed_status ON garmin_pushed_workouts(push_status);

-- Enable RLS
ALTER TABLE garmin_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE garmin_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE garmin_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE garmin_pushed_workouts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for garmin_devices
DROP POLICY IF EXISTS "Users can view their own Garmin devices" ON garmin_devices;
DROP POLICY IF EXISTS "Users can insert their own Garmin devices" ON garmin_devices;
DROP POLICY IF EXISTS "Users can update their own Garmin devices" ON garmin_devices;
DROP POLICY IF EXISTS "Users can delete their own Garmin devices" ON garmin_devices;

CREATE POLICY "Users can view their own Garmin devices" ON garmin_devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own Garmin devices" ON garmin_devices FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own Garmin devices" ON garmin_devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own Garmin devices" ON garmin_devices FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for garmin_connections
DROP POLICY IF EXISTS "Users can view own Garmin connections" ON garmin_connections;
DROP POLICY IF EXISTS "Users can insert own Garmin connections" ON garmin_connections;
DROP POLICY IF EXISTS "Users can update own Garmin connections" ON garmin_connections;

CREATE POLICY "Users can view own Garmin connections" ON garmin_connections FOR SELECT USING (auth.uid() = athlete_id);
CREATE POLICY "Users can insert own Garmin connections" ON garmin_connections FOR INSERT WITH CHECK (auth.uid() = athlete_id);
CREATE POLICY "Users can update own Garmin connections" ON garmin_connections FOR UPDATE USING (auth.uid() = athlete_id);

-- RLS Policies for garmin_activities
DROP POLICY IF EXISTS "Users can view own Garmin activities" ON garmin_activities;
DROP POLICY IF EXISTS "Users can insert own Garmin activities" ON garmin_activities;

CREATE POLICY "Users can view own Garmin activities" ON garmin_activities FOR SELECT USING (auth.uid() = athlete_id);
CREATE POLICY "Users can insert own Garmin activities" ON garmin_activities FOR INSERT WITH CHECK (auth.uid() = athlete_id);

-- RLS Policies for garmin_pushed_workouts
DROP POLICY IF EXISTS "Users can view own pushed workouts" ON garmin_pushed_workouts;
DROP POLICY IF EXISTS "Users can insert own pushed workouts" ON garmin_pushed_workouts;
DROP POLICY IF EXISTS "Users can update own pushed workouts" ON garmin_pushed_workouts;

CREATE POLICY "Users can view own pushed workouts" ON garmin_pushed_workouts FOR SELECT USING (auth.uid() = athlete_id);
CREATE POLICY "Users can insert own pushed workouts" ON garmin_pushed_workouts FOR INSERT WITH CHECK (auth.uid() = athlete_id);
CREATE POLICY "Users can update own pushed workouts" ON garmin_pushed_workouts FOR UPDATE USING (auth.uid() = athlete_id);
