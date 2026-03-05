-- =====================================================
-- Migration: 006_power_cells.sql
-- Purpose: Power Cell system for protocol-based workout tracking
-- =====================================================

CREATE TABLE IF NOT EXISTS public.power_cell_protocols (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  protocol_code TEXT NOT NULL UNIQUE CHECK (protocol_code IN ('START','ENGINE','OXYGEN','POWER','ZONES','STRENGTH','LONG_RUN')),
  display_name TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.power_cell_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  protocol_id UUID NOT NULL REFERENCES public.power_cell_protocols(id) ON DELETE RESTRICT,
  zone_requirement INTEGER CHECK (zone_requirement BETWEEN 1 AND 5),
  aisri_minimum INTEGER NOT NULL CHECK (aisri_minimum BETWEEN 0 AND 100),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  intensity TEXT NOT NULL CHECK (intensity IN ('easy','moderate','hard','very_hard')),
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(name, protocol_id)
);

CREATE TABLE IF NOT EXISTS public.user_power_cells (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  power_cell_type_id UUID NOT NULL REFERENCES public.power_cell_types(id) ON DELETE RESTRICT,

  scheduled_for DATE NOT NULL,
  completed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','completed','skipped','missed')),

  -- Link to existing Strava activity rows when matched
  strava_activity_id BIGINT,

  prescribed_duration_minutes INTEGER CHECK (prescribed_duration_minutes > 0),
  actual_duration_minutes INTEGER CHECK (actual_duration_minutes >= 0),
  prescribed_intensity TEXT CHECK (prescribed_intensity IN ('easy','moderate','hard','very_hard')),
  actual_intensity TEXT CHECK (actual_intensity IN ('easy','moderate','hard','very_hard')),

  compliance_score NUMERIC(5,2) CHECK (compliance_score BETWEEN 0 AND 100),
  compliance_notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_user_power_cells_strava_activity
    FOREIGN KEY (strava_activity_id)
    REFERENCES public.strava_activities(strava_activity_id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_power_cell_types_protocol_id ON public.power_cell_types(protocol_id);
CREATE INDEX IF NOT EXISTS idx_power_cell_types_aisri_minimum ON public.power_cell_types(aisri_minimum);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_user_id ON public.user_power_cells(user_id);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_profile_id ON public.user_power_cells(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_scheduled_for ON public.user_power_cells(scheduled_for DESC);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_status ON public.user_power_cells(status);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_strava_activity_id ON public.user_power_cells(strava_activity_id);

-- RLS
ALTER TABLE public.power_cell_protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.power_cell_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_power_cells ENABLE ROW LEVEL SECURITY;

-- Protocols and types are readable by authenticated users
DROP POLICY IF EXISTS "power_cell_protocols_read" ON public.power_cell_protocols;
CREATE POLICY "power_cell_protocols_read"
  ON public.power_cell_protocols FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "power_cell_types_read" ON public.power_cell_types;
CREATE POLICY "power_cell_types_read"
  ON public.power_cell_types FOR SELECT
  USING (auth.role() = 'authenticated');

-- User Power Cells: users can access only their own rows
DROP POLICY IF EXISTS "user_power_cells_select_own" ON public.user_power_cells;
CREATE POLICY "user_power_cells_select_own"
  ON public.user_power_cells FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_power_cells_insert_own" ON public.user_power_cells;
CREATE POLICY "user_power_cells_insert_own"
  ON public.user_power_cells FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_power_cells_update_own" ON public.user_power_cells;
CREATE POLICY "user_power_cells_update_own"
  ON public.user_power_cells FOR UPDATE
  USING (auth.uid() = user_id);

-- Seed protocol definitions
INSERT INTO public.power_cell_protocols (protocol_code, display_name, color_hex, icon_name, description)
VALUES
  ('START', 'Start', '#22c55e', 'seedling', 'Base onboarding and movement quality'),
  ('ENGINE', 'Engine', '#3b82f6', 'gauge-high', 'Aerobic engine development'),
  ('OXYGEN', 'Oxygen', '#06b6d4', 'lungs', 'Oxygen uptake and threshold work'),
  ('POWER', 'Power', '#f59e0b', 'bolt', 'Speed and neuromuscular power'),
  ('ZONES', 'Zones', '#8b5cf6', 'wave-square', 'Zone-guided effort control'),
  ('STRENGTH', 'Strength', '#ef4444', 'dumbbell', 'Strength and durability'),
  ('LONG_RUN', 'Long Run', '#9333ea', 'road', 'Long endurance sessions')
ON CONFLICT (protocol_code) DO NOTHING;

COMMENT ON TABLE public.power_cell_protocols IS 'Master table for 7 SafeStride protocols';
COMMENT ON TABLE public.power_cell_types IS 'Definitions of schedulable power cell workout units';
COMMENT ON TABLE public.user_power_cells IS 'Per-user scheduled/completed power cells with Strava linkage and compliance';
