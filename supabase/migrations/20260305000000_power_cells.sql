-- =====================================================
-- Migration: 20260305000000_power_cells.sql
-- Purpose: Power Cell training system schema
-- =====================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'power_cell_protocols'
      AND column_name = 'id'
      AND data_type <> 'bigint'
  ) THEN
    DROP TABLE IF EXISTS public.user_power_cells CASCADE;
    DROP TABLE IF EXISTS public.power_cell_types CASCADE;
    DROP TABLE IF EXISTS public.power_cell_protocols CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'power_cell_intensity'
  ) THEN
    CREATE TYPE public.power_cell_intensity AS ENUM ('easy', 'moderate', 'hard', 'very_hard');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.power_cell_protocols (
  id BIGSERIAL PRIMARY KEY,
  protocol_name TEXT NOT NULL UNIQUE CHECK (protocol_name IN ('START', 'ENGINE', 'OXYGEN', 'POWER', 'ZONES', 'STRENGTH', 'LONG_RUN')),
  display_name TEXT NOT NULL,
  description TEXT,
  color_hex TEXT NOT NULL,
  icon_class TEXT NOT NULL,
  training_focus TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.power_cell_types (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  protocol_id BIGINT NOT NULL REFERENCES public.power_cell_protocols(id) ON DELETE CASCADE,
  zone_requirement INTEGER NOT NULL CHECK (zone_requirement BETWEEN 1 AND 5),
  aisri_minimum INTEGER NOT NULL CHECK (aisri_minimum BETWEEN 0 AND 100),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  intensity public.power_cell_intensity NOT NULL,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_power_cells (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  power_cell_type_id BIGINT NOT NULL REFERENCES public.power_cell_types(id) ON DELETE RESTRICT,
  scheduled_date DATE NOT NULL,
  completed_at TIMESTAMP,
  actual_duration_minutes INTEGER,
  actual_distance_km NUMERIC(6,2),
  actual_pace_min_per_km NUMERIC(5,2),
  compliance_score INTEGER CHECK (compliance_score BETWEEN 0 AND 100),
  strava_activity_id BIGINT,
  coach_notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_power_cell_types_protocol_id ON public.power_cell_types(protocol_id);
CREATE INDEX IF NOT EXISTS idx_power_cell_types_aisri_minimum ON public.power_cell_types(aisri_minimum);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_user_id ON public.user_power_cells(user_id);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_scheduled_date ON public.user_power_cells(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_user_power_cells_strava_activity_id ON public.user_power_cells(strava_activity_id);

DO $$
BEGIN
  IF to_regclass('public.strava_activities') IS NOT NULL THEN
    IF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'strava_activities' AND column_name = 'strava_activity_id'
    ) THEN
      ALTER TABLE public.user_power_cells
        ADD CONSTRAINT fk_user_power_cells_strava_activity
        FOREIGN KEY (strava_activity_id)
        REFERENCES public.strava_activities(strava_activity_id)
        ON DELETE SET NULL;
    ELSIF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'strava_activities' AND column_name = 'id'
    ) THEN
      ALTER TABLE public.user_power_cells
        ADD CONSTRAINT fk_user_power_cells_strava_activity
        FOREIGN KEY (strava_activity_id)
        REFERENCES public.strava_activities(id)
        ON DELETE SET NULL;
    END IF;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

ALTER TABLE public.power_cell_protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.power_cell_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_power_cells ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS power_cell_protocols_read_authenticated ON public.power_cell_protocols;
CREATE POLICY power_cell_protocols_read_authenticated
  ON public.power_cell_protocols
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS power_cell_types_read_authenticated ON public.power_cell_types;
CREATE POLICY power_cell_types_read_authenticated
  ON public.power_cell_types
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS user_power_cells_select_own ON public.user_power_cells;
CREATE POLICY user_power_cells_select_own
  ON public.user_power_cells
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_power_cells_insert_own ON public.user_power_cells;
CREATE POLICY user_power_cells_insert_own
  ON public.user_power_cells
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_power_cells_update_own ON public.user_power_cells;
CREATE POLICY user_power_cells_update_own
  ON public.user_power_cells
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_power_cells_delete_own ON public.user_power_cells;
CREATE POLICY user_power_cells_delete_own
  ON public.user_power_cells
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
