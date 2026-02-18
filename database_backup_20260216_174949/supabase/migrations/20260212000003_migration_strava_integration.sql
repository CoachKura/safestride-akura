-- Migration: Add Strava Integration Columns
-- Description: Adds columns to profiles table for storing Strava OAuth tokens
-- Date: February 3, 2026

-- ============================================
-- 1. Add Strava columns to profiles table
-- ============================================
ALTER TABLE "public"."profiles" 
ADD COLUMN strava_access_token TEXT;
ALTER TABLE "public"."profiles" 
ADD COLUMN strava_refresh_token TEXT;
ALTER TABLE "public"."profiles" 
ADD COLUMN strava_athlete_id BIGINT;
ALTER TABLE "public"."profiles" 
ADD COLUMN strava_connected_at TIMESTAMP;
ALTER TABLE "public"."profiles" 
ADD COLUMN strava_expires_at TIMESTAMP;

-- ============================================
-- 2. Add strava_activity_id to workouts table
-- ============================================
ALTER TABLE "public"."workouts"
ADD COLUMN strava_activity_id BIGINT UNIQUE;

-- Create index for faster Strava activity lookups
CREATE INDEX IF NOT EXISTS idx_workouts_strava_activity_id ON "public"."workouts"(strava_activity_id);

-- ============================================
-- 3. Comments for documentation
-- ============================================
COMMENT ON COLUMN "public"."profiles".strava_access_token IS 'Strava OAuth access token for API calls';
COMMENT ON COLUMN "public"."profiles".strava_refresh_token IS 'Strava OAuth refresh token for renewing access';
COMMENT ON COLUMN "public"."profiles".strava_athlete_id IS 'Strava athlete ID';
COMMENT ON COLUMN "public"."profiles".strava_connected_at IS 'Timestamp when Strava was first connected';
COMMENT ON COLUMN "public"."profiles".strava_expires_at IS 'Access token expiration timestamp';
COMMENT ON COLUMN "public"."workouts".strava_activity_id IS 'Strava activity ID for synced workouts';

-- ============================================
-- 4. Sample queries for testing
-- ============================================
-- Check if user has Strava connected:
-- SELECT strava_access_token IS NOT NULL as is_connected FROM profiles WHERE id = auth.uid();

-- Get all Strava-synced workouts:
-- SELECT * FROM workouts WHERE user_id = auth.uid() AND strava_activity_id IS NOT NULL;
