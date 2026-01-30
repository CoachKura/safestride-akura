-- Add JSON columns used by frontend to assessments table
BEGIN;

ALTER TABLE public.assessments
ADD COLUMN IF NOT EXISTS assessment_data jsonb DEFAULT '{}'::jsonb;

ALTER TABLE public.assessments
ADD COLUMN IF NOT EXISTS raw_form_data jsonb DEFAULT '{}'::jsonb;

ALTER TABLE public.assessments
ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

COMMIT;
