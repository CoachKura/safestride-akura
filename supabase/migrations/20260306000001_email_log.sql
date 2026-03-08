-- File: supabase/migrations/20260306000001_email_log.sql
-- Purpose: Add athlete email delivery log table with RLS policies.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.athlete_email_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email_type TEXT NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT CHECK (status IN ('sent', 'delivered', 'opened', 'clicked', 'failed')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backfill expected columns for partially existing table variants.
ALTER TABLE IF EXISTS public.athlete_email_log
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS email_type TEXT,
  ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS status TEXT,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Indexes for fast lookups.
CREATE INDEX IF NOT EXISTS idx_athlete_email_log_user_id
  ON public.athlete_email_log(user_id);
CREATE INDEX IF NOT EXISTS idx_athlete_email_log_email_type
  ON public.athlete_email_log(email_type);
CREATE INDEX IF NOT EXISTS idx_athlete_email_log_sent_at
  ON public.athlete_email_log(sent_at DESC);

-- RLS
ALTER TABLE public.athlete_email_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own email log" ON public.athlete_email_log;
CREATE POLICY "Users can view own email log"
  ON public.athlete_email_log FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage email log" ON public.athlete_email_log;
CREATE POLICY "Service role can manage email log"
  ON public.athlete_email_log FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');
