/**
 * SafeStride - Generate Sample Training Plan & Workouts
 * 
 * This script creates a realistic 12-week training plan with 84 daily workouts
 * Run this in browser console after logging in as an athlete
 */

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// Supabase configuration
const SUPABASE_URL = 'https://bdisppaxbvygsspcuymb.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxMzk5NjIsImV4cCI6MjA1MTcxNTk2Mn0.abc123def456';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function generateTrainingPlan(athleteId) {
    console.log('🚀 Starting training plan generation...');
    console.log('Athlete ID:', athleteId);

    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 84); // 12 weeks

    try {
        // Step 1: Create training plan
        console.log('\n📋 Creating training plan...');
        const { data: plan, error: planError } = await supabase
            .from('training_plans')
            .insert({
                athlete_id: athleteId,
                plan_name: '12-Week Foundation Building Program',
                start_date: startDate.toISOString().split('T')[0],
                end_date: endDate.toISOString().split('T')[0],
                total_weeks: 12,
                aisri_score_at_creation: 65,
                risk_category: 'Medium Risk',
                plan_data: {
                    goal: '10K Race Preparation',
                    focus: 'Build aerobic base and injury prevention',
                    zones_unlocked: ['AR', 'F', 'EN']
                },
                status: 'active',
                created_by: athleteId
            })
            .select()
            .single();

        if (planError) throw planError;
        console.log('✅ Training plan created:', plan.id);

        // Step 2: Generate 84 daily workouts
        console.log('\n🏃 Generating 84 daily workouts...');
        const workouts = [];

        for (let week = 1; week <= 12; week++) {
            for (let day = 1; day <= 7; day++) {
                const workoutDate = new Date(startDate);
                workoutDate.setDate(workoutDate.getDate() + ((week - 1) * 7 + (day - 1)));

                let workout = {
                    training_plan_id: plan.id,
                    athlete_id: athleteId,
                    workout_date: workoutDate.toISOString().split('T')[0],
                    week_number: week,
                    day_number: day,
                    completed: false
                };

                // Weekly pattern: Mon-Easy, Tue-Tempo, Wed-Easy, Thu-Rest, Fri-Easy, Sat-Long, Sun-Rest
                switch (day) {
                    case 1: // Monday: Easy Run
                        workout = {
                            ...workout,
                            workout_type: 'F',
                            workout_name: 'Easy Foundation Run',
                            distance: 5.0 + (week * 0.3),
                            duration: 35 + (week * 2),
                            hr_zone: 'Zone 2',
                            intensity: 'Easy',
                            notes: 'Comfortable pace. Focus on maintaining good form and breathing rhythm.'
                        };
                        break;

                    case 2: // Tuesday: Progressive
                        if (week <= 4) {
                            workout = {
                                ...workout,
                                workout_type: 'F',
                                workout_name: 'Foundation Pace Run',
                                distance: 4.0 + (week * 0.2),
                                duration: 30 + week,
                                hr_zone: 'Zone 2-3',
                                intensity: 'Moderate',
                                notes: 'Steady pace. Should feel controlled and sustainable.'
                            };
                        } else if (week <= 8) {
                            workout = {
                                ...workout,
                                workout_type: 'EN',
                                workout_name: 'Endurance Run',
                                distance: 6.0 + (week * 0.2),
                                duration: 40 + (week * 2),
                                hr_zone: 'Zone 3',
                                intensity: 'Moderate',
                                notes: 'Build endurance. Maintain consistent pace throughout.'
                            };
                        } else {
                            workout = {
                                ...workout,
                                workout_type: 'TH',
                                workout_name: 'Threshold Intervals',
                                distance: 7.0,
                                duration: 50,
                                hr_zone: 'Zone 4',
                                intensity: 'Hard',
                                notes: '3x10min @ threshold pace with 3min recovery. Comfortably hard effort.'
                            };
                        }
                        break;

                    case 3: // Wednesday: Recovery
                        workout = {
                            ...workout,
                            workout_type: 'AR',
                            workout_name: 'Active Recovery Run',
                            distance: 4.0,
                            duration: 25 + week,
                            hr_zone: 'Zone 1-2',
                            intensity: 'Very Easy',
                            notes: 'Very easy pace. Should be able to hold full conversation.'
                        };
                        break;

                    case 4: // Thursday: Rest
                        workout = {
                            ...workout,
                            workout_type: 'Rest',
                            workout_name: 'Rest Day',
                            distance: 0,
                            duration: 0,
                            hr_zone: 'N/A',
                            intensity: 'Rest',
                            notes: 'Complete rest. Focus on recovery, hydration, and mobility work.'
                        };
                        break;

                    case 5: // Friday: Easy
                        workout = {
                            ...workout,
                            workout_type: 'F',
                            workout_name: 'Easy Foundation Run',
                            distance: 5.0 + (week * 0.2),
                            duration: 35 + week,
                            hr_zone: 'Zone 2',
                            intensity: 'Easy',
                            notes: 'Relaxed pace. Save energy for weekend long run.'
                        };
                        break;

                    case 6: // Saturday: Long Run
                        workout = {
                            ...workout,
                            workout_type: 'EN',
                            workout_name: 'Long Endurance Run',
                            distance: 8.0 + (week * 0.5),
                            duration: 60 + (week * 4),
                            hr_zone: 'Zone 2-3',
                            intensity: 'Moderate',
                            notes: 'Long steady run. Start easy and maintain consistent pace. Fuel properly.'
                        };
                        break;

                    case 7: // Sunday: Rest or Easy
                        if (week % 3 === 0) {
                            workout = {
                                ...workout,
                                workout_type: 'AR',
                                workout_name: 'Easy Shakeout Run',
                                distance: 3.0,
                                duration: 20,
                                hr_zone: 'Zone 1',
                                intensity: 'Very Easy',
                                notes: 'Light recovery run to flush out legs from long run.'
                            };
                        } else {
                            workout = {
                                ...workout,
                                workout_type: 'Rest',
                                workout_name: 'Rest Day',
                                distance: 0,
                                duration: 0,
                                hr_zone: 'N/A',
                                intensity: 'Rest',
                                notes: 'Complete rest. Focus on recovery and preparation for next week.'
                            };
                        }
                        break;
                }

                workouts.push(workout);
            }

            console.log(`  Week ${week}/12 generated (${workouts.length} workouts)`);
        }

        // Insert all workouts in batches (Supabase has 1000 row limit per insert)
        console.log('\n💾 Inserting workouts into database...');
        const { data: insertedWorkouts, error: workoutsError } = await supabase
            .from('daily_workouts')
            .insert(workouts)
            .select();

        if (workoutsError) throw workoutsError;
        console.log(`✅ ${insertedWorkouts.length} workouts inserted`);

        // Step 3: Mark some past workouts as completed (for demo)
        console.log('\n✅ Marking past week workouts as completed (demo data)...');
        const lastWeekDate = new Date();
        lastWeekDate.setDate(lastWeekDate.getDate() - 7);

        const { data: pastWorkouts } = await supabase
            .from('daily_workouts')
            .select('id, distance, duration, workout_type')
            .eq('athlete_id', athleteId)
            .gte('workout_date', lastWeekDate.toISOString().split('T')[0])
            .lt('workout_date', new Date().toISOString().split('T')[0])
            .neq('workout_type', 'Rest');

        if (pastWorkouts && pastWorkouts.length > 0) {
            for (const workout of pastWorkouts) {
                const actualDistance = workout.distance * (0.95 + Math.random() * 0.1);
                const actualDuration = workout.duration + Math.floor(Math.random() * 10 - 5);
                
                let actualHR = 140;
                if (workout.workout_type === 'AR') actualHR = 120 + Math.floor(Math.random() * 10);
                else if (workout.workout_type === 'F') actualHR = 135 + Math.floor(Math.random() * 10);
                else if (workout.workout_type === 'EN') actualHR = 145 + Math.floor(Math.random() * 10);
                else if (workout.workout_type === 'TH') actualHR = 160 + Math.floor(Math.random() * 10);

                // Update workout as completed
                await supabase
                    .from('daily_workouts')
                    .update({
                        completed: true,
                        completed_at: new Date().toISOString(),
                        actual_distance: actualDistance,
                        actual_duration: actualDuration,
                        actual_avg_hr: actualHR
                    })
                    .eq('id', workout.id);

                // Create completion record
                await supabase
                    .from('workout_completions')
                    .insert({
                        daily_workout_id: workout.id,
                        athlete_id: athleteId,
                        completed_at: new Date().toISOString(),
                        feedback_rating: 3 + Math.floor(Math.random() * 2),
                        perceived_effort: 5 + Math.floor(Math.random() * 3),
                        feedback_notes: 'Sample completed workout',
                        actual_distance: actualDistance,
                        actual_duration: actualDuration,
                        actual_avg_hr: actualHR
                    });
            }
            console.log(`✅ ${pastWorkouts.length} past workouts marked complete`);
        }

        // Step 4: Create AISRI score history
        console.log('\n📊 Creating AISRI score history...');
        await supabase.from('aisri_score_history').insert([
            {
                athlete_id: athleteId,
                aisri_score: 65,
                risk_category: 'Medium Risk',
                pillar_running: 68,
                pillar_strength: 62,
                pillar_rom: 60,
                pillar_balance: 70,
                pillar_alignment: 64,
                pillar_mobility: 66,
                recorded_at: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
            },
            {
                athlete_id: athleteId,
                aisri_score: 72,
                risk_category: 'Medium Risk',
                pillar_running: 75,
                pillar_strength: 68,
                pillar_rom: 65,
                pillar_balance: 76,
                pillar_alignment: 70,
                pillar_mobility: 72,
                score_change: 7,
                change_direction: 'improved'
            }
        ]);
        console.log('✅ AISRI scores created');

        // Step 5: Schedule next evaluation
        console.log('\n📅 Scheduling next evaluation...');
        const nextEvalDate = new Date();
        nextEvalDate.setDate(nextEvalDate.getDate() + 7);

        await supabase.from('evaluation_schedule').insert({
            athlete_id: athleteId,
            next_evaluation_date: nextEvalDate.toISOString().split('T')[0],
            evaluation_type: 'monthly',
            status: 'pending'
        });
        console.log('✅ Next evaluation scheduled');

        // Final summary
        console.log('\n' + '='.repeat(50));
        console.log('🎉 TRAINING PLAN GENERATION COMPLETE!');
        console.log('='.repeat(50));
        console.log(`\n📊 Summary:`);
        console.log(`  • Training Plan ID: ${plan.id}`);
        console.log(`  • Total Workouts: 84 (12 weeks × 7 days)`);
        console.log(`  • Start Date: ${startDate.toISOString().split('T')[0]}`);
        console.log(`  • End Date: ${endDate.toISOString().split('T')[0]}`);
        console.log(`  • AISRI Score: 72 (Medium Risk)`);
        console.log(`  • Next Evaluation: ${nextEvalDate.toISOString().split('T')[0]}`);
        console.log(`\n✅ You can now:`);
        console.log(`  1. View training calendar at /public/training-calendar.html`);
        console.log(`  2. Check dashboard at /public/athlete-dashboard.html`);
        console.log(`  3. Complete today's workout`);
        console.log(`\n🚀 Happy training!`);

        return { success: true, planId: plan.id };

    } catch (error) {
        console.error('❌ Error generating training plan:', error);
        return { success: false, error: error.message };
    }
}

// Auto-run if current user is logged in
(async () => {
    const { data: { session } } = await supabase.auth.getSession();
    
    if (session) {
        console.log('👤 Current user:', session.user.email);
        console.log('🆔 Athlete ID:', session.user.id);
        console.log('\n⚠️  This will create a 12-week training plan with 84 workouts');
        console.log('Continue? Run: generateTrainingPlan("' + session.user.id + '")');
        
        // Uncomment below to auto-generate (careful - will create duplicate plans if run multiple times)
        // await generateTrainingPlan(session.user.id);
    } else {
        console.log('⚠️  Not logged in. Please login first.');
        console.log('Then run: generateTrainingPlan("ATHLETE_UUID")');
    }
})();

// Export for manual use
window.generateTrainingPlan = generateTrainingPlan;
console.log('\n💡 Manual usage: generateTrainingPlan("your-athlete-id")');
