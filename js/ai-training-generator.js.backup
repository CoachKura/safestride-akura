/**
 * AI Training Programme Generator
 * Generates 12-week personalized training programs
 */

class AITrainingProgramGenerator {
    constructor(aifriEngine) {
        this.aifri = aifriEngine;
    }

    generateProgram(athleteData) {
        const { aifrScore, pillars, age, restingHR, totalDistance = 0 } = athleteData;
        const riskCategory = this.aifri.getRiskCategory(aifrScore);
        const allowedZones = this.aifri.getAllowedZones(aifrScore, athleteData.safetyGatesPassed || false);
        const hrZones = this.aifri.calculateHRZones(age, restingHR);
        
        const weeks = [];
        for (let weekNum = 1; weekNum <= 12; weekNum++) {
            weeks.push(this.generateWeekPlan(weekNum, aifrScore, allowedZones, hrZones));
        }

        return {
            athleteInfo: { aifrScore, riskCategory, allowedZones },
            hrZones,
            weeks,
            safetyNotes: this.generateSafetyNotes(riskCategory)
        };
    }

    generateWeekPlan(weekNum, aifrScore, allowedZones, hrZones) {
        const weekPlan = { weekNumber: weekNum, theme: this.getWeekTheme(weekNum), days: {} };

        weekPlan.days.monday = {
            type: 'REST or Active Recovery',
            zone: 'AR',
            workout: { duration: '20-30 min optional', description: 'Complete rest or light activity' }
        };

        const tuesdayZone = allowedZones.includes('EN') ? 'EN' : 'F';
        weekPlan.days.tuesday = {
            type: 'Foundation Run',
            zone: tuesdayZone,
            workout: {
                duration: '40-60 min',
                hrRange: hrZones.zones[tuesdayZone].min + '-' + hrZones.zones[tuesdayZone].max + ' bpm',
                description: 'Easy conversational pace'
            }
        };

        weekPlan.days.wednesday = {
            type: 'Strength Training',
            zone: null,
            workout: { duration: '45-60 min', description: 'Runner-specific strength work' }
        };

        const thursdayZone = allowedZones.includes('TH') ? 'TH' : 'EN';
        weekPlan.days.thursday = {
            type: 'Tempo Run',
            zone: thursdayZone,
            workout: {
                duration: '40-50 min',
                hrRange: hrZones.zones[thursdayZone].min + '-' + hrZones.zones[thursdayZone].max + ' bpm',
                description: 'Comfortably hard pace'
            }
        };

        weekPlan.days.friday = {
            type: 'Mobility & Flexibility',
            zone: null,
            workout: { duration: '30-45 min', description: 'Stretching and foam rolling' }
        };

        weekPlan.days.saturday = {
            type: 'Long Run',
            zone: allowedZones.includes('EN') ? 'EN' : 'F',
            workout: { duration: '60-90 min', description: 'Build endurance at easy pace' }
        };

        weekPlan.days.sunday = {
            type: 'Active Recovery',
            zone: 'AR',
            workout: { duration: '20-40 min', description: 'Light activity or complete rest' }
        };

        return weekPlan;
    }

    getWeekTheme(weekNum) {
        if (weekNum % 4 === 0) return 'Recovery Week';
        if (weekNum === 1) return 'Foundation Building';
        return 'Progressive Load Week ' + weekNum;
    }

    generateSafetyNotes(riskCategory) {
        const notes = [];
        if (riskCategory.label === 'Critical Risk') {
            notes.push(' CRITICAL: Focus on injury recovery and base building');
            notes.push(' Stay in Foundation (F) and Active Recovery (AR) zones only');
        }
        notes.push(' Listen to your body. Skip workouts if injured or overly fatigued');
        notes.push(' Prioritize sleep (7-9 hours), hydration, and nutrition');
        return notes;
    }
}

if (typeof window !== 'undefined') {
    window.AITrainingProgramGenerator = AITrainingProgramGenerator;
}
