-- Add missing snake_case assessment columns used by the frontend
BEGIN;

-- Running Profile (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS running_experience text;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS weekly_mileage numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS training_history text;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS recent_races text;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS current_training text;

-- Range of Motion (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS ankle_flexibility_left numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS ankle_flexibility_right numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS hip_flexibility_left numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS hip_flexibility_right numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS shoulder_mobility_left numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS shoulder_mobility_right numeric;

-- FMS Tests (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_deep_squat integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_hurdle_step_left integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_hurdle_step_right integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_inline_lunge_left integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_inline_lunge_right integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_shoulder_mobility_left integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_shoulder_mobility_right integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_shoulder_clearing_test boolean;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_active_straight_leg_raise_left integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_active_straight_leg_raise_right integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_trunk_stability integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_press_up_clearing_test boolean;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_rotary_stability_left integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_rotary_stability_right integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_flexion_clearing_test boolean;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS fms_extension_clearing_test boolean;

-- Strength Tests (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS squat_reps integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS lunge_reps integer;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS plank_time numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS side_plank_time_left numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS side_plank_time_right numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS calf_raises integer;

-- Running Form (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS stride_length numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS ground_contact_time numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS vertical_oscillation numeric;

-- Running Baseline (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS baseline_distance numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS baseline_time numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS baseline_pace numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS baseline_heart_rate numeric;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS baseline_rpe integer;

-- Personal Info (snake_case variants)
ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS first_name text;

ALTER TABLE public.assessments 
ADD COLUMN IF NOT EXISTS last_name text;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verification query (run separately if desired):
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' 
--   AND table_name = 'assessments'
--   AND column_name IN ('assessment_data', 'raw_form_data', 'metadata');
