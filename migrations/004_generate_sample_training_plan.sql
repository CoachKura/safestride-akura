-- =====================================================
-- SAFESTRIDE: GENERATE SAMPLE TRAINING PLAN & WORKOUTS
-- Purpose: Create realistic 12-week training plan with 84 daily workouts
-- Usage: Run this after creating an athlete account
-- =====================================================

-- STEP 1: Create a training plan
-- Replace 'ATHLETE_UUID_HERE' with actual athlete UUID from profiles table

DO $$
DECLARE
    v_athlete_id UUID := 'ATHLETE_UUID_HERE'; -- ⚠️ REPLACE THIS
    v_plan_id UUID;
    v_start_date DATE := CURRENT_DATE;
    v_current_date DATE;
    v_week_number INTEGER;
    v_day_number INTEGER;
    v_workout_type TEXT;
    v_workout_name TEXT;
    v_distance DECIMAL(5,2);
    v_duration INTEGER;
    v_hr_zone TEXT;
    v_intensity TEXT;
    v_notes TEXT;
BEGIN
    -- Create training plan
    INSERT INTO training_plans (
        athlete_id,
        plan_name,
        start_date,
        end_date,
        total_weeks,
        aisri_score_at_creation,
        risk_category,
        plan_data,
        status,
        created_by
    ) VALUES (
        v_athlete_id,
        '12-Week Foundation Building Program',
        v_start_date,
        v_start_date + INTERVAL '84 days',
        12,
        65, -- Medium Risk AISRI score
        'Medium Risk',
        jsonb_build_object(
            'goal', '10K Race Preparation',
            'focus', 'Build aerobic base and injury prevention',
            'zones_unlocked', array['AR', 'F', 'EN']
        ),
        'active',
        v_athlete_id
    ) RETURNING id INTO v_plan_id;

    RAISE NOTICE 'Created training plan: %', v_plan_id;

    -- Generate 84 daily workouts (12 weeks × 7 days)
    FOR v_week_number IN 1..12 LOOP
        FOR v_day_number IN 1..7 LOOP
            v_current_date := v_start_date + ((v_week_number - 1) * 7 + (v_day_number - 1));
            
            -- Weekly pattern: Mon-Easy, Tue-Tempo, Wed-Easy, Thu-Rest, Fri-Easy, Sat-Long, Sun-Rest
            CASE v_day_number
                WHEN 1 THEN -- Monday: Easy Run
                    v_workout_type := 'F';
                    v_workout_name := 'Easy Foundation Run';
                    v_distance := 5.0 + (v_week_number * 0.3);
                    v_duration := 35 + (v_week_number * 2);
                    v_hr_zone := 'Zone 2';
                    v_intensity := 'Easy';
                    v_notes := 'Comfortable pace. Focus on maintaining good form and breathing rhythm.';
                    
                WHEN 2 THEN -- Tuesday: Tempo or Intervals (progressive)
                    IF v_week_number <= 4 THEN
                        v_workout_type := 'F';
                        v_workout_name := 'Foundation Pace Run';
                        v_distance := 4.0 + (v_week_number * 0.2);
                        v_duration := 30 + v_week_number;
                        v_hr_zone := 'Zone 2-3';
                        v_intensity := 'Moderate';
                        v_notes := 'Steady pace. Should feel controlled and sustainable.';
                    ELSIF v_week_number <= 8 THEN
                        v_workout_type := 'EN';
                        v_workout_name := 'Endurance Run';
                        v_distance := 6.0 + (v_week_number * 0.2);
                        v_duration := 40 + (v_week_number * 2);
                        v_hr_zone := 'Zone 3';
                        v_intensity := 'Moderate';
                        v_notes := 'Build endurance. Maintain consistent pace throughout.';
                    ELSE
                        v_workout_type := 'TH';
                        v_workout_name := 'Threshold Intervals';
                        v_distance := 7.0;
                        v_duration := 50;
                        v_hr_zone := 'Zone 4';
                        v_intensity := 'Hard';
                        v_notes := '3x10min @ threshold pace with 3min recovery. Comfortably hard effort.';
                    END IF;
                    
                WHEN 3 THEN -- Wednesday: Easy Recovery
                    v_workout_type := 'AR';
                    v_workout_name := 'Active Recovery Run';
                    v_distance := 4.0;
                    v_duration := 25 + v_week_number;
                    v_hr_zone := 'Zone 1-2';
                    v_intensity := 'Very Easy';
                    v_notes := 'Very easy pace. Should be able to hold full conversation.';
                    
                WHEN 4 THEN -- Thursday: Rest or Cross-Training
                    v_workout_type := 'Rest';
                    v_workout_name := 'Rest Day';
                    v_distance := 0;
                    v_duration := 0;
                    v_hr_zone := 'N/A';
                    v_intensity := 'Rest';
                    v_notes := 'Complete rest. Focus on recovery, hydration, and mobility work.';
                    
                WHEN 5 THEN -- Friday: Easy Run
                    v_workout_type := 'F';
                    v_workout_name := 'Easy Foundation Run';
                    v_distance := 5.0 + (v_week_number * 0.2);
                    v_duration := 35 + v_week_number;
                    v_hr_zone := 'Zone 2';
                    v_intensity := 'Easy';
                    v_notes := 'Relaxed pace. Save energy for weekend long run.';
                    
                WHEN 6 THEN -- Saturday: Long Run (progressive build)
                    v_workout_type := 'EN';
                    v_workout_name := 'Long Endurance Run';
                    v_distance := 8.0 + (v_week_number * 0.5);
                    v_duration := 60 + (v_week_number * 4);
                    v_hr_zone := 'Zone 2-3';
                    v_intensity := 'Moderate';
                    v_notes := 'Long steady run. Start easy and maintain consistent pace. Fuel properly.';
                    
                WHEN 7 THEN -- Sunday: Rest or Easy
                    IF v_week_number % 3 = 0 THEN -- Every 3rd week: active recovery
                        v_workout_type := 'AR';
                        v_workout_name := 'Easy Shakeout Run';
                        v_distance := 3.0;
                        v_duration := 20;
                        v_hr_zone := 'Zone 1';
                        v_intensity := 'Very Easy';
                        v_notes := 'Light recovery run to flush out legs from long run.';
                    ELSE -- Rest day
                        v_workout_type := 'Rest';
                        v_workout_name := 'Rest Day';
                        v_distance := 0;
                        v_duration := 0;
                        v_hr_zone := 'N/A';
                        v_intensity := 'Rest';
                        v_notes := 'Complete rest. Focus on recovery and preparation for next week.';
                    END IF;
            END CASE;
            
            -- Insert workout
            INSERT INTO daily_workouts (
                training_plan_id,
                athlete_id,
                workout_date,
                week_number,
                day_number,
                workout_type,
                workout_name,
                description,
                distance,
                duration,
                hr_zone,
                intensity,
                notes,
                completed
            ) VALUES (
                v_plan_id,
                v_athlete_id,
                v_current_date,
                v_week_number,
                v_day_number,
                v_workout_type,
                v_workout_name,
                v_workout_name || ' - Week ' || v_week_number || ', Day ' || v_day_number,
                v_distance,
                v_duration,
                v_hr_zone,
                v_intensity,
                v_notes,
                FALSE
            );
            
        END LOOP;
        
        RAISE NOTICE 'Generated workouts for Week %', v_week_number;
    END LOOP;

    RAISE NOTICE '✅ Successfully generated 84 workouts for training plan: %', v_plan_id;
    RAISE NOTICE 'Start Date: %', v_start_date;
    RAISE NOTICE 'End Date: %', v_start_date + INTERVAL '84 days';
    
END $$;

-- =====================================================
-- STEP 2: Verify workout generation
-- =====================================================

-- Count total workouts
SELECT 
    COUNT(*) as total_workouts,
    COUNT(CASE WHEN completed THEN 1 END) as completed_workouts,
    COUNT(CASE WHEN workout_type = 'Rest' THEN 1 END) as rest_days,
    COUNT(CASE WHEN workout_type != 'Rest' THEN 1 END) as training_days
FROM daily_workouts
WHERE athlete_id = 'ATHLETE_UUID_HERE'; -- ⚠️ REPLACE THIS

-- View workouts by week
SELECT 
    week_number,
    COUNT(*) as workouts,
    SUM(distance) as total_km,
    SUM(duration) as total_minutes
FROM daily_workouts
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS
GROUP BY week_number
ORDER BY week_number;

-- View next 7 days
SELECT 
    workout_date,
    workout_type,
    workout_name,
    distance,
    duration,
    hr_zone,
    intensity
FROM daily_workouts
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS
  AND workout_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY workout_date;

-- =====================================================
-- STEP 3: Optional - Mark some past workouts as completed (for demo)
-- =====================================================

-- Mark last week's workouts as completed with sample data
UPDATE daily_workouts
SET 
    completed = TRUE,
    completed_at = workout_date + TIME '18:30:00',
    actual_distance = distance * (0.95 + random() * 0.1), -- Slightly varied from planned
    actual_duration = duration + (random() * 10 - 5)::INTEGER, -- ±5 minutes
    actual_avg_hr = CASE 
        WHEN workout_type = 'AR' THEN 120 + (random() * 10)::INTEGER
        WHEN workout_type = 'F' THEN 135 + (random() * 10)::INTEGER
        WHEN workout_type = 'EN' THEN 145 + (random() * 10)::INTEGER
        WHEN workout_type = 'TH' THEN 160 + (random() * 10)::INTEGER
        ELSE NULL
    END
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS
  AND workout_date BETWEEN CURRENT_DATE - INTERVAL '7 days' AND CURRENT_DATE - INTERVAL '1 day'
  AND workout_type != 'Rest';

-- Add workout completion records for completed workouts
INSERT INTO workout_completions (
    daily_workout_id,
    athlete_id,
    completed_at,
    feedback_rating,
    perceived_effort,
    feedback_notes,
    actual_distance,
    actual_duration,
    actual_avg_hr
)
SELECT 
    id,
    athlete_id,
    completed_at,
    (3 + random() * 2)::INTEGER, -- Rating 3-5
    (5 + random() * 3)::INTEGER, -- RPE 5-8
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'Felt great today! Strong throughout the run.'
        WHEN 1 THEN 'Good workout. Legs a bit tired but pushed through.'
        ELSE 'Tough day but completed as planned.'
    END,
    actual_distance,
    actual_duration,
    actual_avg_hr
FROM daily_workouts
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS
  AND completed = TRUE
  AND workout_type != 'Rest';

RAISE NOTICE '✅ Sample workout completions added for demo';

-- =====================================================
-- STEP 4: Create sample AISRI score history
-- =====================================================

-- Add initial AISRI score
INSERT INTO aisri_score_history (
    athlete_id,
    aisri_score,
    risk_category,
    pillar_running,
    pillar_strength,
    pillar_rom,
    pillar_balance,
    pillar_alignment,
    pillar_mobility,
    recorded_at
) VALUES (
    'ATHLETE_UUID_HERE', -- ⚠️ REPLACE THIS
    65,
    'Medium Risk',
    68,
    62,
    60,
    70,
    64,
    66,
    CURRENT_TIMESTAMP - INTERVAL '30 days'
);

-- Add current AISRI score (showing improvement)
INSERT INTO aisri_score_history (
    athlete_id,
    aisri_score,
    risk_category,
    pillar_running,
    pillar_strength,
    pillar_rom,
    pillar_balance,
    pillar_alignment,
    pillar_mobility,
    score_change,
    change_direction
) VALUES (
    'ATHLETE_UUID_HERE', -- ⚠️ REPLACE THIS
    72,
    'Medium Risk',
    75,
    68,
    65,
    76,
    70,
    72,
    7,
    'improved'
);

-- Schedule next evaluation
INSERT INTO evaluation_schedule (
    athlete_id,
    next_evaluation_date,
    evaluation_type,
    status
) VALUES (
    'ATHLETE_UUID_HERE', -- ⚠️ REPLACE THIS
    CURRENT_DATE + INTERVAL '7 days',
    'monthly',
    'pending'
);

RAISE NOTICE '✅ AISRI scores and evaluation schedule created';

-- =====================================================
-- FINAL VERIFICATION
-- =====================================================

SELECT '✅ SETUP COMPLETE!' as status;

SELECT 
    'Training Plan' as item,
    COUNT(*) as count
FROM training_plans
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS

UNION ALL

SELECT 
    'Daily Workouts',
    COUNT(*)
FROM daily_workouts
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS

UNION ALL

SELECT 
    'Completed Workouts',
    COUNT(*)
FROM daily_workouts
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS
  AND completed = TRUE

UNION ALL

SELECT 
    'AISRI Scores',
    COUNT(*)
FROM aisri_score_history
WHERE athlete_id = 'ATHLETE_UUID_HERE' -- ⚠️ REPLACE THIS

UNION ALL

SELECT 
    'Evaluation Schedule',
    COUNT(*)
FROM evaluation_schedule
WHERE athlete_id = 'ATHLETE_UUID_HERE'; -- ⚠️ REPLACE THIS
