-- ═══════════════════════════════════════════════════════
-- TRAINING PROTOCOL SYSTEM - DATABASE SCHEMA
-- ═══════════════════════════════════════════════════════
-- 
-- Purpose: Generate personalized training protocols based on
--          athlete evaluation forms (AISRI assessment)
--          
-- Features:
-- - Protocol generation from evaluation scores
-- - Self-learning workout images with AI
-- - Progress tracking and protocol adjustment
-- - Exercise library with image/video guidance
-- ═══════════════════════════════════════════════════════

-- ┌─────────────────────────────────────────────────────┐
-- │ 1. TRAINING PROTOCOLS TABLE                         │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.training_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    assessment_id UUID REFERENCES public.aisri_assessments(id) ON DELETE SET NULL,
    
    -- Protocol Metadata
    protocol_name TEXT NOT NULL,
    protocol_type TEXT NOT NULL CHECK (protocol_type IN ('injury_prevention', 'strength_building', 'endurance', 'recovery', 'custom')),
    duration_weeks INTEGER NOT NULL DEFAULT 12,
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    
    -- Generated Based On
    based_on_scores JSONB NOT NULL, -- Stores evaluation scores used for generation
    focus_areas TEXT[] NOT NULL, -- e.g., ['ankle_mobility', 'core_stability']
    
    -- Protocol Status
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'archived')),
    start_date DATE,
    end_date DATE,
    current_week INTEGER DEFAULT 1,
    
    -- AI Learning
    ai_generated BOOLEAN DEFAULT true,
    ai_model_version TEXT,
    ai_confidence_score NUMERIC(3,2), -- 0.00 to 1.00
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    notes TEXT
);

-- Indexes
CREATE INDEX idx_training_protocols_user_id ON public.training_protocols(user_id);
CREATE INDEX idx_training_protocols_assessment_id ON public.training_protocols(assessment_id);
CREATE INDEX idx_training_protocols_status ON public.training_protocols(status);
CREATE INDEX idx_training_protocols_start_date ON public.training_protocols(start_date);

-- ┌─────────────────────────────────────────────────────┐
-- │ 2. EXERCISE LIBRARY TABLE                           │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.exercise_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Exercise Details
    exercise_name TEXT NOT NULL UNIQUE,
    exercise_category TEXT NOT NULL CHECK (exercise_category IN ('mobility', 'strength', 'stability', 'balance', 'plyometric', 'cardio', 'recovery')),
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    
    -- Description
    description TEXT NOT NULL,
    instructions TEXT[] NOT NULL, -- Step-by-step instructions
    common_mistakes TEXT[], -- What to avoid
    
    -- Media Assets
    image_url TEXT, -- Primary demonstration image
    video_url TEXT, -- Video tutorial URL
    thumbnail_url TEXT, -- Thumbnail for list views
    
    -- Self-Learning AI Images
    ai_generated_images JSONB, -- URLs of AI-generated variations
    ai_learning_enabled BOOLEAN DEFAULT false,
    
    -- Targeting
    muscle_groups TEXT[] NOT NULL, -- e.g., ['glutes', 'core', 'ankles']
    equipment_needed TEXT[], -- e.g., ['resistance_band', 'mat']
    
    -- AISRI Scoring Impact
    targets_ankle_mobility BOOLEAN DEFAULT false,
    targets_hip_flexibility BOOLEAN DEFAULT false,
    targets_core_stability BOOLEAN DEFAULT false,
    targets_leg_balance BOOLEAN DEFAULT false,
    
    -- Exercise Parameters
    default_sets INTEGER DEFAULT 3,
    default_reps INTEGER, -- Can be null for time-based exercises
    default_duration_seconds INTEGER, -- Can be null for rep-based exercises
    default_rest_seconds INTEGER DEFAULT 60,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true
);

-- Indexes
CREATE INDEX idx_exercise_library_category ON public.exercise_library(exercise_category);
CREATE INDEX idx_exercise_library_difficulty ON public.exercise_library(difficulty_level);
CREATE INDEX idx_exercise_library_active ON public.exercise_library(is_active);
CREATE INDEX idx_exercise_library_name ON public.exercise_library(exercise_name);

-- ┌─────────────────────────────────────────────────────┐
-- │ 3. PROTOCOL EXERCISES (Junction Table)              │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.protocol_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    protocol_id UUID REFERENCES public.training_protocols(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercise_library(id) ON DELETE CASCADE,
    
    -- Week Planning
    week_number INTEGER NOT NULL,
    day_number INTEGER NOT NULL, -- 1-7 (Mon-Sun)
    order_in_workout INTEGER NOT NULL, -- Sequence within the workout
    
    -- Exercise Prescription
    prescribed_sets INTEGER NOT NULL,
    prescribed_reps INTEGER, -- Can be null for time-based
    prescribed_duration_seconds INTEGER, -- Can be null for rep-based
    prescribed_rest_seconds INTEGER NOT NULL,
    
    -- Intensity/Progression
    intensity_level TEXT CHECK (intensity_level IN ('light', 'moderate', 'hard', 'very_hard')),
    progression_notes TEXT, -- How to increase difficulty
    
    -- Coaching
    coach_notes TEXT,
    video_timestamp INTEGER, -- Start point in video (seconds)
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_protocol_exercises_protocol_id ON public.protocol_exercises(protocol_id);
CREATE INDEX idx_protocol_exercises_exercise_id ON public.protocol_exercises(exercise_id);
CREATE INDEX idx_protocol_exercises_week_day ON public.protocol_exercises(protocol_id, week_number, day_number);

-- ┌─────────────────────────────────────────────────────┐
-- │ 4. WORKOUT EXECUTION LOGS                           │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.workout_execution_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    protocol_id UUID REFERENCES public.training_protocols(id) ON DELETE SET NULL,
    protocol_exercise_id UUID REFERENCES public.protocol_exercises(id) ON DELETE SET NULL,
    exercise_id UUID REFERENCES public.exercise_library(id) ON DELETE SET NULL,
    
    -- Execution Details
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed BOOLEAN DEFAULT false,
    
    -- Performance Data
    actual_sets INTEGER,
    actual_reps INTEGER,
    actual_duration_seconds INTEGER,
    perceived_difficulty INTEGER CHECK (perceived_difficulty >= 1 AND perceived_difficulty <= 10),
    
    -- Quality Metrics
    form_quality INTEGER CHECK (form_quality >= 1 AND form_quality <= 5), -- User self-rating
    pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
    
    -- Media Capture (Self-Learning)
    user_video_url TEXT, -- User's execution video for AI analysis
    ai_form_analysis JSONB, -- AI feedback on form
    ai_analyzed BOOLEAN DEFAULT false,
    
    -- Notes
    notes TEXT,
    coach_feedback TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_workout_logs_user_id ON public.workout_execution_logs(user_id);
CREATE INDEX idx_workout_logs_protocol_id ON public.workout_execution_logs(protocol_id);
CREATE INDEX idx_workout_logs_executed_at ON public.workout_execution_logs(executed_at);
CREATE INDEX idx_workout_logs_ai_analyzed ON public.workout_execution_logs(ai_analyzed);

-- ┌─────────────────────────────────────────────────────┐
-- │ 5. AI LEARNING IMAGES TABLE                         │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.ai_workout_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id UUID REFERENCES public.exercise_library(id) ON DELETE CASCADE,
    
    -- Image Details
    image_url TEXT NOT NULL,
    image_type TEXT NOT NULL CHECK (image_type IN ('demonstration', 'variation', 'progression', 'correction', 'angle_view')),
    
    -- AI Generation
    ai_generated BOOLEAN DEFAULT true,
    ai_model TEXT, -- e.g., 'stable-diffusion', 'midjourney', 'dalle-3'
    generation_prompt TEXT,
    generation_params JSONB,
    
    -- Image Metadata
    view_angle TEXT, -- e.g., 'front', 'side', 'back', '45-degree'
    difficulty_shown TEXT CHECK (difficulty_shown IN ('beginner', 'intermediate', 'advanced')),
    highlights_mistake BOOLEAN DEFAULT false, -- Shows common error
    
    -- Quality & Usage
    quality_score NUMERIC(3,2), -- AI or manual quality rating
    usage_count INTEGER DEFAULT 0,
    user_ratings JSONB, -- Array of user ratings
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Indexes
CREATE INDEX idx_ai_images_exercise_id ON public.ai_workout_images(exercise_id);
CREATE INDEX idx_ai_images_type ON public.ai_workout_images(image_type);
CREATE INDEX idx_ai_images_active ON public.ai_workout_images(is_active);

-- ┌─────────────────────────────────────────────────────┐
-- │ 6. PROTOCOL PROGRESS TRACKING                       │
-- └─────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS public.protocol_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    protocol_id UUID REFERENCES public.training_protocols(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Weekly Progress
    week_number INTEGER NOT NULL,
    
    -- Completion Stats
    total_workouts_planned INTEGER NOT NULL,
    workouts_completed INTEGER DEFAULT 0,
    completion_rate NUMERIC(5,2), -- Percentage
    
    -- Performance Trends
    avg_perceived_difficulty NUMERIC(3,1),
    avg_form_quality NUMERIC(3,1),
    avg_pain_level NUMERIC(3,1),
    
    -- Re-assessment Scores (Optional)
    ankle_mobility_score INTEGER,
    hip_flexibility_score INTEGER,
    core_stability_score INTEGER,
    leg_balance_score INTEGER,
    
    -- AI Insights
    ai_recommendations TEXT[],
    suggested_adjustments TEXT,
    
    -- Metadata
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_protocol_progress_protocol_id ON public.protocol_progress(protocol_id);
CREATE INDEX idx_protocol_progress_user_id ON public.protocol_progress(user_id);
CREATE INDEX idx_protocol_progress_week ON public.protocol_progress(protocol_id, week_number);

-- ┌─────────────────────────────────────────────────────┐
-- │ 7. SEED DATA: SAMPLE EXERCISES                      │
-- └─────────────────────────────────────────────────────┘

-- Ankle Mobility Exercises
INSERT INTO public.exercise_library (
    exercise_name, exercise_category, difficulty_level,
    description, instructions, common_mistakes,
    muscle_groups, equipment_needed,
    targets_ankle_mobility,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds
) VALUES
-- 1. Ankle Circles
(
    'Ankle Circles',
    'mobility',
    'beginner',
    'Improve ankle range of motion with controlled circular movements',
    ARRAY[
        'Sit in a chair with one leg extended',
        'Point your toe and trace large circles in the air',
        'Complete circles in both clockwise and counter-clockwise directions',
        'Focus on smooth, controlled movements'
    ],
    ARRAY[
        'Moving too fast without control',
        'Using leg instead of ankle to create circles',
        'Not completing full range of motion'
    ],
    ARRAY['ankles', 'calves'],
    ARRAY['chair'],
    true,
    2, 15, NULL, 30
),

-- 2. Calf Raises
(
    'Calf Raises',
    'strength',
    'beginner',
    'Build strength in calves and ankle stability',
    ARRAY[
        'Stand with feet hip-width apart near a wall for balance',
        'Rise up onto the balls of your feet',
        'Hold for 2 seconds at the top',
        'Lower slowly back down'
    ],
    ARRAY[
        'Rising too quickly',
        'Not reaching full height',
        'Leaning forward excessively'
    ],
    ARRAY['calves', 'ankles'],
    ARRAY['wall_for_balance'],
    true,
    3, 15, NULL, 45
),

-- Core Stability Exercises
-- 3. Plank Hold
(
    'Plank Hold',
    'stability',
    'beginner',
    'Build core endurance and full-body stability',
    ARRAY[
        'Start in push-up position on forearms',
        'Keep body in straight line from head to heels',
        'Engage core and squeeze glutes',
        'Hold position breathing normally'
    ],
    ARRAY[
        'Hips sagging or lifting too high',
        'Holding breath',
        'Looking up instead of down',
        'Letting shoulders roll forward'
    ],
    ARRAY['core', 'abs', 'shoulders'],
    ARRAY['mat'],
    false,
    3, NULL, 30, 60
),

-- 4. Dead Bug
(
    'Dead Bug',
    'stability',
    'beginner',
    'Improve core stability and coordination',
    ARRAY[
        'Lie on back with arms extended toward ceiling',
        'Lift knees to 90-degree angle',
        'Lower opposite arm and leg toward floor',
        'Return to start and alternate sides'
    ],
    ARRAY[
        'Arching lower back off floor',
        'Moving too quickly',
        'Not coordinating arm and leg movements',
        'Holding breath'
    ],
    ARRAY['core', 'abs', 'hip_flexors'],
    ARRAY['mat'],
    false,
    3, 10, NULL, 45
),

-- Hip Flexibility Exercises
-- 5. Hip Flexor Stretch
(
    'Kneeling Hip Flexor Stretch',
    'mobility',
    'beginner',
    'Improve hip flexor flexibility and reduce tightness',
    ARRAY[
        'Kneel on one knee with other foot forward',
        'Keep back straight and engage core',
        'Shift weight forward until stretch in front hip',
        'Hold stretch breathing deeply'
    ],
    ARRAY[
        'Arching back excessively',
        'Leaning too far forward',
        'Not engaging core',
        'Bouncing in stretch'
    ],
    ARRAY['hip_flexors', 'quads', 'core'],
    ARRAY['mat', 'cushion'],
    false,
    2, NULL, 30, 30
),

-- Balance Exercises
-- 6. Single Leg Stand
(
    'Single Leg Balance',
    'balance',
    'beginner',
    'Develop single-leg stability and proprioception',
    ARRAY[
        'Stand on one leg near a wall for safety',
        'Keep standing leg slightly bent',
        'Focus eyes on fixed point ahead',
        'Hold position maintaining balance'
    ],
    ARRAY[
        'Locking knee',
        'Tensing up upper body',
        'Not having support nearby',
        'Holding breath'
    ],
    ARRAY['ankles', 'calves', 'core', 'glutes'],
    ARRAY['wall_for_balance'],
    false,
    3, NULL, 30, 30
)
ON CONFLICT (exercise_name) DO NOTHING;

-- ═══════════════════════════════════════════════════════
-- VIEWS & FUNCTIONS
-- ═══════════════════════════════════════════════════════

-- View: Active Training Protocols with Progress
CREATE OR REPLACE VIEW public.active_protocols_with_progress AS
SELECT 
    tp.id,
    tp.user_id,
    tp.protocol_name,
    tp.protocol_type,
    tp.duration_weeks,
    tp.current_week,
    tp.start_date,
    tp.end_date,
    tp.status,
    tp.focus_areas,
    -- Calculate overall completion
    COALESCE(
        (SELECT AVG(completion_rate) 
         FROM public.protocol_progress 
         WHERE protocol_id = tp.id), 
        0
    ) as overall_completion_rate,
    -- Count total workouts
    (SELECT COUNT(*) 
     FROM public.protocol_exercises 
     WHERE protocol_id = tp.id) as total_workouts,
    -- Count completed workouts
    (SELECT COUNT(*) 
     FROM public.workout_execution_logs 
     WHERE protocol_id = tp.id AND completed = true) as completed_workouts
FROM public.training_protocols tp
WHERE tp.status = 'active';

-- Function: Generate Protocol from Assessment
CREATE OR REPLACE FUNCTION public.generate_protocol_from_assessment(
    p_user_id UUID,
    p_assessment_id UUID,
    p_duration_weeks INTEGER DEFAULT 12
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_protocol_id UUID;
    v_assessment RECORD;
    v_focus_areas TEXT[];
    v_difficulty TEXT;
BEGIN
    -- Get assessment data
    SELECT * INTO v_assessment
    FROM public.aisri_assessments
    WHERE id = p_assessment_id AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found';
    END IF;
    
    -- Determine focus areas based on scores
    v_focus_areas := ARRAY[]::TEXT[];
    
    IF v_assessment.ankle_mobility_score < 7 THEN
        v_focus_areas := array_append(v_focus_areas, 'ankle_mobility');
    END IF;
    
    IF v_assessment.hip_flexibility_score < 7 THEN
        v_focus_areas := array_append(v_focus_areas, 'hip_flexibility');
    END IF;
    
    IF v_assessment.core_stability_score < 7 THEN
        v_focus_areas := array_append(v_focus_areas, 'core_stability');
    END IF;
    
    IF v_assessment.single_leg_balance_score < 7 THEN
        v_focus_areas := array_append(v_focus_areas, 'single_leg_balance');
    END IF;
    
    -- Determine difficulty based on overall score
    IF v_assessment.total_score < 25 THEN
        v_difficulty := 'beginner';
    ELSIF v_assessment.total_score < 35 THEN
        v_difficulty := 'intermediate';
    ELSE
        v_difficulty := 'advanced';
    END IF;
    
    -- Create protocol
    INSERT INTO public.training_protocols (
        user_id,
        assessment_id,
        protocol_name,
        protocol_type,
        duration_weeks,
        difficulty_level,
        based_on_scores,
        focus_areas,
        status,
        ai_generated,
        ai_confidence_score
    ) VALUES (
        p_user_id,
        p_assessment_id,
        'Injury Prevention Protocol - ' || to_char(NOW(), 'YYYY-MM-DD'),
        'injury_prevention',
        p_duration_weeks,
        v_difficulty,
        jsonb_build_object(
            'ankle_mobility', v_assessment.ankle_mobility_score,
            'hip_flexibility', v_assessment.hip_flexibility_score,
            'core_stability', v_assessment.core_stability_score,
            'single_leg_balance', v_assessment.single_leg_balance_score,
            'total_score', v_assessment.total_score
        ),
        v_focus_areas,
        'draft',
        true,
        0.85
    )
    RETURNING id INTO v_protocol_id;
    
    RETURN v_protocol_id;
END;
$$;

-- ═══════════════════════════════════════════════════════
-- PERMISSIONS (RLS Policies)
-- ═══════════════════════════════════════════════════════

-- Enable RLS
ALTER TABLE public.training_protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.protocol_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_execution_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_workout_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.protocol_progress ENABLE ROW LEVEL SECURITY;

-- Training Protocols: Users can only see their own
CREATE POLICY "Users can view own protocols"
    ON public.training_protocols FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own protocols"
    ON public.training_protocols FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own protocols"
    ON public.training_protocols FOR UPDATE
    USING (auth.uid() = user_id);

-- Exercise Library: Everyone can read
CREATE POLICY "Everyone can view exercises"
    ON public.exercise_library FOR SELECT
    USING (is_active = true);

-- Protocol Exercises: Users can see exercises in their protocols
CREATE POLICY "Users can view own protocol exercises"
    ON public.protocol_exercises FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.training_protocols
            WHERE id = protocol_exercises.protocol_id
            AND user_id = auth.uid()
        )
    );

-- Workout Logs: Users can only see their own
CREATE POLICY "Users can view own workout logs"
    ON public.workout_execution_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own workout logs"
    ON public.workout_execution_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- AI Images: Everyone can read active images
CREATE POLICY "Everyone can view AI workout images"
    ON public.ai_workout_images FOR SELECT
    USING (is_active = true);

-- Protocol Progress: Users can see their own progress
CREATE POLICY "Users can view own protocol progress"
    ON public.protocol_progress FOR SELECT
    USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════
-- END OF SCHEMA
-- ═══════════════════════════════════════════════════════
