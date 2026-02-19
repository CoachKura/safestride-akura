/**
 * AI Training Programme Generator
 * Based on AKURA Workout Prescription Algorithm
 * 
 * Steps:
 * 1. Calculate AIFRI Score (0-100)
 * 2. Determine Zone Permissions
 * 3. Select Training Phase
 * 4. Generate Weekly Schedule
 * 5. Safety Gates Check (modify intensity if needed)
 */

class AITrainingProgramGenerator {
    constructor(aifriEngine) {
        this.aifri = aifriEngine;
        
        // 7-Protocol Framework from AKURA Weekly Structure
        this.protocols = {
            START: {
                name: 'START Protocol',
                description: 'Foundation running mechanics',
                focus: ['Posture', 'Cadence', 'Foot strike', 'Breathing']
            },
            ENGINE: {
                name: 'ENGINE Protocol',
                description: 'Aerobic engine development',
                focus: ['Conversational pace', 'Zone 2 work', 'Fat adaptation']
            },
            OXYGEN: {
                name: 'OXYGEN Protocol',
                description: 'VO2 max improvement',
                focus: ['Higher intensity', 'Oxygen uptake', 'Lactate clearance']
            },
            POWER: {
                name: 'POWER Protocol',
                description: 'Muscular power & speed',
                focus: ['Hill repeats', 'Short intervals', 'Explosive strength']
            },
            ZONES: {
                name: 'ZONES Protocol',
                description: 'HR zone discipline',
                focus: ['Zone-specific training', 'Pacing control', 'Threshold work']
            },
            STRENGTH: {
                name: 'STRENGTH Protocol',
                description: 'Runner-specific strength',
                focus: ['Core stability', 'Glute activation', 'Single-leg work', 'Plyometrics']
            },
            MOBILITY: {
                name: 'MOBILITY Protocol',
                description: 'Dynamic flexibility',
                focus: ['Dynamic stretching', 'Foam rolling', 'Yoga', 'Recovery']
            },
            ENDURANCE: {
                name: 'ENDURANCE Protocol',
                description: 'Long-duration aerobic work',
                focus: ['Long runs', 'Progressive distance', 'Fatigue resistance']
            },
            RECOVERY: {
                name: 'RECOVERY & ADAPTATION Protocol',
                description: 'Active recovery and regeneration',
                focus: ['Light activity', 'Nutrition', 'Sleep', 'Mental rest']
            }
        };
    }

    /**
     * Generate complete 12-week training program
     * @param {Object} athleteData - Complete athlete profile with AIFRI scores
     * @returns {Object} 12-week program with daily workouts
     */
    generateProgram(athleteData) {
        const {
            aifrScore,
            pillars,
            age,
            restingHR,
            totalDistance = 0,
            weeksInjuryFree = 0,
            weeksFoundation = 0,
            safetyGatesPassed = false
        } = athleteData;

        // Step 1: Get risk category
        const riskCategory = this.aifri.getRiskCategory(aifrScore);

        // Step 2: Determine allowed zones
        const allowedZones = this.aifri.getAllowedZones(aifrScore, safetyGatesPassed);

        // Step 3: Select training phase
        const phase = this.aifri.determineTrainingPhase(totalDistance, aifrScore);

        // Step 4: Calculate HR zones
        const hrZones = this.aifri.calculateHRZones(age, restingHR);

        // Step 5: Check safety gates
        const powerGate = this.aifri.checkPowerZoneSafetyGate({
            aifrScore,
            romScore: pillars.rom,
            weeksInjuryFree,
            weeksFoundation
        });

        const speedGate = this.aifri.checkSpeedZoneSafetyGate({
            aifrScore,
            runningScore: pillars.running,
            strengthScore: pillars.strength,
            romScore: pillars.rom,
            balanceScore: pillars.balance,
            mobilityScore: pillars.mobility,
            perfectForm: pillars.running >= 85,
            weeksPowerTraining: weeksFoundation
        });

        // Step 6: Generate 12-week program
        const weeks = [];
        for (let weekNum = 1; weekNum <= 12; weekNum++) {
            const weekPlan = this.generateWeekPlan(
                weekNum,
                aifrScore,
                phase,
                allowedZones,
                hrZones,
                powerGate.passed,
                speedGate.passed
            );
            weeks.push(weekPlan);
        }

        return {
            athleteInfo: {
                aifrScore,
                riskCategory,
                phase: phase.name,
                allowedZones,
                powerGateStatus: powerGate,
                speedGateStatus: speedGate
            },
            hrZones,
            weeks,
            safetyNotes: this.generateSafetyNotes(riskCategory, powerGate, speedGate)
        };
    }

    /**
     * Generate single week training plan
     */
    generateWeekPlan(weekNum, aifrScore, phase, allowedZones, hrZones, powerUnlocked, speedUnlocked) {
        const weekPlan = {
            weekNumber: weekNum,
            theme: this.getWeekTheme(weekNum, phase),
            days: {}
        };

        // Monday: REST or Active Recovery
        weekPlan.days.monday = {
            type: 'REST or Active Recovery',
            zone: 'AR',
            protocol: this.protocols.RECOVERY,
            workout: {
                duration: '20-30 min optional',
                hrRange: `${hrZones.zones.AR.min}-${hrZones.zones.AR.max} bpm`,
                description: 'Complete rest or light walk/swim. Focus on nutrition and mental recovery.',
                alternatives: ['Complete rest', 'Easy walk', 'Light swim', 'Gentle yoga']
            }
        };

        // Tuesday: Foundation/Endurance
        const tuesdayZone = allowedZones.includes('EN') ? 'EN' : 'F';
        weekPlan.days.tuesday = {
            type: 'Foundation/Endurance Run',
            zone: tuesdayZone,
            protocol: allowedZones.includes('EN') ? this.protocols.OXYGEN : this.protocols.ENGINE,
            workout: {
                duration: '40-60 min',
                hrRange: `${hrZones.zones[tuesdayZone].min}-${hrZones.zones[tuesdayZone].max} bpm`,
                description: tuesdayZone === 'EN' 
                    ? 'Steady aerobic run. Should feel "comfortably hard".'
                    : 'Easy conversational pace. Build aerobic base.',
                structure: {
                    warmup: '10 min easy',
                    main: tuesdayZone === 'EN' ? '30-40 min steady' : '30-40 min easy',
                    cooldown: '10 min easy + stretching'
                }
            }
        };

        // Wednesday: Strength Training
        weekPlan.days.wednesday = {
            type: 'Strength Training',
            zone: null,
            protocol: phase.phase >= 3 && powerUnlocked ? this.protocols.POWER : this.protocols.STRENGTH,
            workout: {
                duration: '45-60 min',
                description: 'Runner-specific strength training focusing on injury prevention.',
                exercises: this.generateStrengthWorkout(phase.phase, aifrScore),
                structure: {
                    warmup: '5-10 min dynamic stretching',
                    main: '35-45 min strength circuit',
                    cooldown: '5-10 min foam rolling'
                }
            }
        };

        // Thursday: Intervals/Tempo
        const thursdayZone = this.selectIntensityZone(allowedZones, speedUnlocked, powerUnlocked);
        weekPlan.days.thursday = {
            type: thursdayZone === 'TH' ? 'Tempo Run' : thursdayZone === 'P' ? 'Power Intervals' : 'Speed Work',
            zone: thursdayZone,
            protocol: thursdayZone === 'TH' ? this.protocols.ZONES : this.protocols.POWER,
            workout: this.generateIntervalWorkout(thursdayZone, hrZones, weekNum, phase)
        };

        // Friday: Mobility & Flexibility
        weekPlan.days.friday = {
            type: 'Mobility & Flexibility',
            zone: null,
            protocol: this.protocols.MOBILITY,
            workout: {
                duration: '30-45 min',
                description: 'Dynamic stretching, foam rolling, and flexibility work.',
                focus: ['Hip mobility', 'Ankle mobility', 'Thoracic rotation', 'Hamstring flexibility'],
                structure: {
                    foam_rolling: '10-15 min (IT band, calves, glutes, quads)',
                    dynamic_stretching: '15-20 min',
                    yoga_poses: '10-15 min (Pigeon, Lizard, Downward Dog)'
                }
            }
        };

        // Saturday: Long Run
        const saturdayZone = allowedZones.includes('EN') ? 'EN' : 'F';
        const longRunDuration = this.calculateLongRunDuration(weekNum, phase, aifrScore);
        weekPlan.days.saturday = {
            type: 'Long Run',
            zone: saturdayZone,
            protocol: this.protocols.ENDURANCE,
            workout: {
                duration: longRunDuration,
                hrRange: `${hrZones.zones[saturdayZone].min}-${hrZones.zones[saturdayZone].max} bpm`,
                description: 'Build endurance. Pace should feel comfortable for conversation.',
                structure: {
                    warmup: '10 min easy jog',
                    main: `${longRunDuration.split('-')[0]} steady aerobic`,
                    cooldown: '5-10 min walk + stretching'
                },
                nutrition: 'Carry water/gels if run > 90 min',
                terrain: 'Prefer soft surfaces (trail, grass) to reduce impact'
            }
        };

        // Sunday: Active Recovery & Wellness
        weekPlan.days.sunday = {
            type: 'Active Recovery & Wellness',
            zone: 'AR',
            protocol: this.protocols.RECOVERY,
            workout: {
                duration: '20-40 min',
                hrRange: `${hrZones.zones.AR.min}-${hrZones.zones.AR.max} bpm`,
                description: 'Light activity, focus on recovery and preparation for next week.',
                options: [
                    'Easy walk or hike',
                    'Light swim',
                    'Recovery bike ride',
                    'Gentle yoga class',
                    'Complete rest if needed'
                ],
                wellness_checklist: [
                    'Review weekly training load',
                    'Assess energy levels',
                    'Check for any pain/discomfort',
                    'Plan meals for upcoming week',
                    'Ensure adequate sleep (7-9 hours)'
                ]
            }
        };

        // Calculate weekly totals
        weekPlan.weeklyTotals = this.calculateWeeklyTotals(weekPlan.days);

        return weekPlan;
    }

    /**
     * Select appropriate intensity zone for interval day
     */
    selectIntensityZone(allowedZones, speedUnlocked, powerUnlocked) {
        if (speedUnlocked && allowedZones.includes('SP')) return 'SP';
        if (powerUnlocked && allowedZones.includes('P')) return 'P';
        if (allowedZones.includes('TH')) return 'TH';
        if (allowedZones.includes('EN')) return 'EN';
        return 'F';
    }

    /**
     * Generate interval workout based on zone and week
     */
    generateIntervalWorkout(zone, hrZones, weekNum, phase) {
        const intervals = {
            'SP': {
                duration: '40-50 min total',
                hrRange: `${hrZones.zones.SP.min}-${hrZones.zones.SP.max} bpm`,
                description: 'Speed intervals - short, intense efforts.',
                warmup: '15 min easy + 4x100m strides',
                main: weekNum % 3 === 0 
                    ? '8x200m @ 95-100% max HR, 200m jog recovery'
                    : '6x400m @ 95-100% max HR, 400m jog recovery',
                cooldown: '10 min easy + stretching',
                notes: 'Focus on form. Stop if form breaks down.'
            },
            'P': {
                duration: '40-50 min total',
                hrRange: `${hrZones.zones.P.min}-${hrZones.zones.P.max} bpm`,
                description: 'Power intervals - sustained hard efforts.',
                warmup: '10 min easy + 3x100m strides',
                main: weekNum % 2 === 0
                    ? '5x1km @ 87-95% max HR, 2 min jog recovery'
                    : '4x1200m @ 87-95% max HR, 2.5 min jog recovery',
                cooldown: '10 min easy + stretching',
                notes: 'Hard but controlled. Maintain even effort across intervals.'
            },
            'TH': {
                duration: '45-55 min total',
                hrRange: `${hrZones.zones.TH.min}-${hrZones.zones.TH.max} bpm`,
                description: 'Tempo run - comfortably hard pace.',
                warmup: '10 min easy',
                main: phase.phase <= 2 
                    ? '20 min @ threshold pace (80-87% max HR)'
                    : '30 min @ threshold pace (80-87% max HR)',
                cooldown: '10 min easy + stretching',
                notes: 'Should feel "comfortably hard" - can speak a few words but not hold conversation.'
            },
            'EN': {
                duration: '45-55 min total',
                hrRange: `${hrZones.zones.EN.min}-${hrZones.zones.EN.max} bpm`,
                description: 'Endurance intervals - build aerobic capacity.',
                warmup: '10 min easy',
                main: '4x8 min @ 70-80% max HR, 2 min easy jog recovery',
                cooldown: '10 min easy + stretching',
                notes: 'Steady effort. Focus on maintaining consistent pace.'
            },
            'F': {
                duration: '40-50 min total',
                hrRange: `${hrZones.zones.F.min}-${hrZones.zones.F.max} bpm`,
                description: 'Foundation run with short pick-ups.',
                warmup: '10 min easy',
                main: '30 min easy run with 6x30sec pick-ups (60-70% max HR), 90sec easy between',
                cooldown: '5-10 min easy + stretching',
                notes: 'Keep overall effort easy. Pick-ups should feel controlled.'
            }
        };

        return { ...intervals[zone], zone };
    }

    /**
     * Generate strength workout based on phase and AIFRI score
     */
    generateStrengthWorkout(phaseNum, aifrScore) {
        const baseExercises = [
            { name: 'Plank Hold', sets: '3x30-60sec', focus: 'Core stability' },
            { name: 'Single-Leg Deadlift', sets: '3x10 each leg', focus: 'Glute strength, balance' },
            { name: 'Wall Sit', sets: '3x30-45sec', focus: 'Quad endurance' },
            { name: 'Calf Raises', sets: '3x15-20', focus: 'Ankle strength' },
            { name: 'Glute Bridge', sets: '3x15', focus: 'Glute activation, hip extension' }
        ];

        const advancedExercises = [
            { name: 'Single-Leg Box Step-Up', sets: '3x10 each leg', focus: 'Power, stability' },
            { name: 'Bulgarian Split Squat', sets: '3x8 each leg', focus: 'Leg strength, balance' },
            { name: 'Jump Squats', sets: '3x8-10', focus: 'Explosive power' },
            { name: 'Lateral Band Walks', sets: '3x15 steps each direction', focus: 'Hip stability' },
            { name: 'Dead Bug', sets: '3x10 each side', focus: 'Core anti-rotation' }
        ];

        if (aifrScore < 55 || phaseNum <= 2) {
            return {
                level: 'Foundation',
                circuit: baseExercises,
                rounds: 3,
                rest: '60-90sec between exercises',
                notes: 'Focus on form. Do NOT rush. Quality > quantity.'
            };
        } else {
            return {
                level: 'Advanced',
                circuit: [...baseExercises.slice(0, 3), ...advancedExercises],
                rounds: 3,
                rest: '45-60sec between exercises',
                notes: 'Maintain perfect form. Add light weight if bodyweight feels easy.'
            };
        }
    }

    /**
     * Calculate long run duration based on week and phase
     */
    calculateLongRunDuration(weekNum, phase, aifrScore) {
        const baseMinutes = aifrScore < 40 ? 40 : aifrScore < 55 ? 60 : 75;
        const weekMultiplier = 1 + (weekNum - 1) * 0.05; // Progressive increase
        const phaseMultiplier = 1 + (phase.phase - 1) * 0.1;

        const minDuration = Math.round(baseMinutes * weekMultiplier * phaseMultiplier);
        const maxDuration = Math.round(minDuration * 1.2);

        return `${minDuration}-${maxDuration} min`;
    }

    /**
     * Get week theme based on phase
     */
    getWeekTheme(weekNum, phase) {
        if (weekNum % 4 === 0) return 'Recovery Week';
        if (weekNum === 1) return 'Foundation Building';
        if (phase.phase === 1) return 'Aerobic Base Development';
        if (phase.phase === 2) return 'Endurance Building';
        if (phase.phase === 3) return 'Threshold Training';
        if (phase.phase === 4) return 'Speed Development';
        if (phase.phase === 5) return 'Peak Performance';
        return 'Progressive Load';
    }

    /**
     * Calculate weekly training totals
     */
    calculateWeeklyTotals(days) {
        let runningDays = 0;
        let strengthDays = 0;
        let totalDuration = 0;

        Object.values(days).forEach(day => {
            if (day.zone && day.zone !== 'AR') runningDays++;
            if (day.type.includes('Strength')) strengthDays++;
            
            const duration = day.workout.duration || '';
            const match = duration.match(/(\d+)/);
            if (match) totalDuration += parseInt(match[1]);
        });

        return {
            runningDays,
            strengthDays,
            totalDuration: `${totalDuration} min`,
            totalHours: `${(totalDuration / 60).toFixed(1)} hours`
        };
    }

    /**
     * Generate safety notes based on risk category and gates
     */
    generateSafetyNotes(riskCategory, powerGate, speedGate) {
        const notes = [];

        if (riskCategory.label === 'Critical Risk') {
            notes.push('⚠️ CRITICAL: Focus on injury recovery and base building. Avoid high-intensity work.');
            notes.push('📌 Mandatory strength training 2x/week to address biomechanical issues.');
            notes.push('📌 Stay in Foundation (F) and Active Recovery (AR) zones only.');
        } else if (riskCategory.label === 'High Risk') {
            notes.push('⚠️ HIGH RISK: Gradual progression essential. Avoid sudden increases in volume/intensity.');
            notes.push('📌 Focus on consistency over intensity.');
        }

        if (!powerGate.passed) {
            notes.push('🔒 Power Zone (P) LOCKED. Requirements to unlock:');
            Object.entries(powerGate.requirements).forEach(([key, req]) => {
                if (!req.met) {
                    notes.push(`   • ${key}: Need ${req.required}, Current ${req.current}`);
                }
            });
        }

        if (!speedGate.passed) {
            notes.push('🔒 Speed Zone (SP) LOCKED. Requirements to unlock:');
            Object.entries(speedGate.requirements).forEach(([key, req]) => {
                if (!req.met) {
                    notes.push(`   • ${key}: Need ${req.required}, Current ${req.current}`);
                }
            });
        }

        notes.push('💡 Listen to your body. Skip workouts if injured or overly fatigued.');
        notes.push('💡 Prioritize sleep (7-9 hours), hydration, and nutrition.');

        return notes;
    }

    /**
     * Export program to printable format
     */
    exportToPDF(program) {
        // This would integrate with a PDF generation library
        // For now, return formatted text
        return this.formatProgramText(program);
    }

    /**
     * Format program as readable text
     */
    formatProgramText(program) {
        let text = `\n═══════════════════════════════════════════════════════\n`;
        text += `  AKURA AIFRI TRAINING PROGRAM - 12 WEEKS\n`;
        text += `═══════════════════════════════════════════════════════\n\n`;
        
        text += `ATHLETE PROFILE:\n`;
        text += `  AIFRI Score: ${program.athleteInfo.aifrScore}/100\n`;
        text += `  Risk Category: ${program.athleteInfo.riskCategory.label}\n`;
        text += `  Training Phase: ${program.athleteInfo.phase}\n`;
        text += `  Allowed Zones: ${program.athleteInfo.allowedZones.join(', ')}\n\n`;

        program.weeks.forEach((week, idx) => {
            text += `\n━━━ WEEK ${week.weekNumber}: ${week.theme} ━━━\n`;
            text += `Weekly Totals: ${week.weeklyTotals.runningDays} running days, ${week.weeklyTotals.strengthDays} strength days, ${week.weeklyTotals.totalHours}\n\n`;

            Object.entries(week.days).forEach(([day, workout]) => {
                text += `${day.toUpperCase()}:\n`;
                text += `  ${workout.type} [${workout.zone || 'Non-running'}]\n`;
                text += `  ${workout.workout.description}\n`;
                text += `  Duration: ${workout.workout.duration}\n`;
                if (workout.workout.hrRange) {
                    text += `  HR Range: ${workout.workout.hrRange}\n`;
                }
                text += `\n`;
            });
        });

        text += `\n═══════════════════════════════════════════════════════\n`;
        text += `SAFETY NOTES:\n`;
        program.safetyNotes.forEach(note => {
            text += `${note}\n`;
        });
        text += `═══════════════════════════════════════════════════════\n`;

        return text;
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AITrainingProgramGenerator;
}
