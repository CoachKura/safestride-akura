/**
 * AKURA Performance Index (API) Calculator
 * Proprietary scoring system: 0-100 scale
 * Replaces VDOT O2 scoring with Chennai-specific adaptations
 */

class AkuraAPI {
    constructor() {
        // Constants for Chennai climate
        this.CHENNAI_HEAT_FACTOR = 1.15; // 15% adjustment for tropical heat
        this.CHENNAI_HUMIDITY_FACTOR = 1.10; // 10% adjustment for humidity
    }

    /**
     * Calculate complete AKURA Performance Index
     * @param {Object} athlete - Athlete data
     * @returns {number} API Score (0-100)
     */
    calculateAkuraAPI(athlete) {
        const hrEfficiency = this.calculateHREfficiency(
            athlete.restingHR,
            athlete.maxHR,
            athlete.recentWorkouts || []
        );
        
        const paceProgression = this.calculatePaceProgression(
            athlete.workoutHistory || []
        );
        
        const consistencyScore = this.calculateConsistency(
            athlete.trainingFrequency || 0
        );
        
        const injuryResistance = this.calculateInjuryResistance(
            athlete.injuryHistory || 'none'
        );
        
        const chennaiAdaptation = this.calculateHeatAdaptation(
            athlete.location || 'chennai',
            athlete.yearsRunning || 0
        );
        
        // Weighted calculation
        const akuraAPI = (
            hrEfficiency * 0.30 +        // 30% weight - HR efficiency is crucial
            paceProgression * 0.25 +     // 25% weight - pace improvement matters
            consistencyScore * 0.20 +    // 20% weight - consistency is key
            injuryResistance * 0.15 +    // 15% weight - staying healthy
            chennaiAdaptation * 0.10     // 10% weight - local climate adaptation
        );
        
        return Math.round(Math.min(100, Math.max(0, akuraAPI)));
    }

    /**
     * Calculate HR Efficiency Score
     * Based on resting HR, max HR, and recent workout HR data
     */
    calculateHREfficiency(restingHR, maxHR, recentWorkouts) {
        // Lower resting HR = better fitness
        // Optimal resting HR: 40-50 for elite runners
        const restingScore = Math.max(0, 100 - (restingHR - 40) * 2);
        
        // HR Reserve (max - resting)
        const hrReserve = maxHR - restingHR;
        const hrReserveScore = Math.min(100, (hrReserve / 150) * 100);
        
        // Average HR efficiency from recent workouts
        let workoutEfficiency = 75; // Default
        if (recentWorkouts.length > 0) {
            const avgHRPercentages = recentWorkouts.map(w => {
                const hrPercent = ((w.avgHR - restingHR) / hrReserve) * 100;
                const paceScore = this.paceToScore(w.pace);
                return (paceScore / hrPercent) * 100; // Efficiency: pace per HR%
            });
            workoutEfficiency = avgHRPercentages.reduce((a, b) => a + b, 0) / avgHRPercentages.length;
        }
        
        return (restingScore * 0.4 + hrReserveScore * 0.3 + workoutEfficiency * 0.3);
    }

    /**
     * Calculate Pace Progression Score
     * Tracks improvement over time
     */
    calculatePaceProgression(workoutHistory) {
        if (!workoutHistory || workoutHistory.length < 5) {
            return 50; // Default for insufficient data
        }
        
        // Get last 90 days of tempo/threshold runs (Zone 3)
        const recentTempoRuns = workoutHistory
            .filter(w => w.type === 'tempo' || w.type === 'threshold')
            .slice(-12); // Last 12 tempo runs
        
        if (recentTempoRuns.length < 3) return 50;
        
        // Calculate trend (are paces getting faster?)
        const oldPaces = recentTempoRuns.slice(0, Math.floor(recentTempoRuns.length / 2));
        const newPaces = recentTempoRuns.slice(Math.floor(recentTempoRuns.length / 2));
        
        const oldAvg = this.averagePace(oldPaces);
        const newAvg = this.averagePace(newPaces);
        
        // Improvement in seconds per km
        const improvement = oldAvg - newAvg;
        
        // Base score on current pace
        const currentPaceScore = this.paceToScore(newAvg);
        
        // Improvement bonus: +1 point per second improved
        const improvementBonus = Math.min(20, improvement * 2);
        
        return Math.min(100, currentPaceScore + improvementBonus);
    }

    /**
     * Convert pace (min/km) to score
     */
    paceToScore(paceSeconds) {
        // Elite: 3:30/km = 210s = 100 points
        // Good: 4:30/km = 270s = 75 points
        // Average: 5:30/km = 330s = 50 points
        // Beginner: 6:30/km = 390s = 25 points
        
        if (paceSeconds <= 210) return 100;
        if (paceSeconds >= 390) return 25;
        
        // Linear interpolation
        return 100 - ((paceSeconds - 210) / 180) * 75;
    }

    /**
     * Calculate average pace from workouts
     */
    averagePace(workouts) {
        const totalSeconds = workouts.reduce((sum, w) => {
            const [min, sec] = w.pace.split(':').map(Number);
            return sum + (min * 60 + sec);
        }, 0);
        return totalSeconds / workouts.length;
    }

    /**
     * Calculate Consistency Score
     * Based on training frequency
     */
    calculateConsistency(trainingFrequency) {
        // trainingFrequency: avg runs per week
        // Elite runners: 6-7 runs/week = 100 points
        // Good runners: 4-5 runs/week = 75 points
        // Average runners: 3 runs/week = 50 points
        
        if (trainingFrequency >= 6) return 100;
        if (trainingFrequency >= 5) return 85;
        if (trainingFrequency >= 4) return 70;
        if (trainingFrequency >= 3) return 55;
        return 30;
    }

    /**
     * Calculate Injury Resistance Score
     */
    calculateInjuryResistance(injuryHistory) {
        const injuryMap = {
            'none': 100,
            'minor': 85,
            'minor knee': 80,
            'minor calf': 80,
            'IT band': 70,
            'shin splints': 65,
            'plantar fasciitis': 60,
            'stress fracture': 40,
            'major': 30
        };
        
        const normalizedHistory = injuryHistory.toLowerCase();
        
        for (const [key, score] of Object.entries(injuryMap)) {
            if (normalizedHistory.includes(key)) {
                return score;
            }
        }
        
        return 75; // Default for unknown
    }

    /**
     * Calculate Chennai Heat Adaptation Score
     */
    calculateHeatAdaptation(location, yearsRunning) {
        const isChennai = location.toLowerCase().includes('chennai');
        
        // Heat adaptation improves over years
        // Year 1: 60%, Year 2: 75%, Year 3+: 90-100%
        let adaptationScore = 60 + (yearsRunning * 10);
        adaptationScore = Math.min(100, adaptationScore);
        
        if (!isChennai) {
            // Non-Chennai runners get baseline score
            return 75;
        }
        
        return adaptationScore;
    }

    /**
     * Get reference paces based on AKURA API Score
     * Similar to VDOT pace charts
     */
    getReferencePaces(apiScore) {
        // Pace calculations based on API score (0-100)
        // Returns paces in seconds per km
        
        const easyPace = this.calculateEasyPace(apiScore);
        const tempoPace = this.calculateTempoPace(apiScore);
        const intervalPace = this.calculateIntervalPace(apiScore);
        const racePaceHM = this.calculateRacePace(apiScore, 'halfMarathon');
        const racePaceMarathon = this.calculateRacePace(apiScore, 'marathon');
        
        return {
            easy: this.secondsToMinSec(easyPace),
            tempo: this.secondsToMinSec(tempoPace),
            interval: this.secondsToMinSec(intervalPace),
            halfMarathon: this.secondsToMinSec(racePaceHM),
            marathon: this.secondsToMinSec(racePaceMarathon),
            apiScore: apiScore
        };
    }

    calculateEasyPace(api) {
        // API 50 = 6:30/km (390s), API 70 = 5:30/km (330s), API 90 = 4:30/km (270s)
        return 510 - (api * 2.4);
    }

    calculateTempoPace(api) {
        // API 50 = 5:45/km (345s), API 70 = 4:45/km (285s), API 90 = 3:50/km (230s)
        return 465 - (api * 2.35);
    }

    calculateIntervalPace(api) {
        // API 50 = 5:15/km (315s), API 70 = 4:15/km (255s), API 90 = 3:30/km (210s)
        return 435 - (api * 2.25);
    }

    calculateRacePace(api, distance) {
        if (distance === 'halfMarathon') {
            // API 50 = 5:00/km (300s), API 70 = 4:00/km (240s), API 90 = 3:15/km (195s)
            return 405 - (api * 2.1);
        } else if (distance === 'marathon') {
            // Marathon pace ~15-20s slower than HM pace
            const hmPace = this.calculateRacePace(api, 'halfMarathon');
            return hmPace + 18;
        }
        return 300; // Default 5:00/km
    }

    secondsToMinSec(seconds) {
        const min = Math.floor(seconds / 60);
        const sec = Math.round(seconds % 60);
        return `${min}:${sec.toString().padStart(2, '0')}`;
    }

    /**
     * Calculate HR Zones based on age and resting HR
     * Formula: Max HR = 208 - (0.7 × Age)
     */
    calculateHRZones(age, restingHR) {
        const maxHR = Math.round(208 - (0.7 * age));
        const hrReserve = maxHR - restingHR;
        
        return {
            maxHR: maxHR,
            restingHR: restingHR,
            zone1: {
                name: 'Recovery',
                min: Math.round(restingHR + hrReserve * 0.50),
                max: Math.round(restingHR + hrReserve * 0.60),
                percentage: '50-60%'
            },
            zone2: {
                name: 'Easy/Base',
                min: Math.round(restingHR + hrReserve * 0.60),
                max: Math.round(restingHR + hrReserve * 0.70),
                percentage: '60-70%'
            },
            zone3: {
                name: 'Tempo/Threshold',
                min: Math.round(restingHR + hrReserve * 0.70),
                max: Math.round(restingHR + hrReserve * 0.80),
                percentage: '70-80%',
                primary: true // PRIMARY FOCUS for SafeStride
            },
            zone4: {
                name: 'VO2 Max',
                min: Math.round(restingHR + hrReserve * 0.80),
                max: Math.round(restingHR + hrReserve * 0.90),
                percentage: '80-90%'
            },
            zone5: {
                name: 'Anaerobic',
                min: Math.round(restingHR + hrReserve * 0.90),
                max: maxHR,
                percentage: '90-100%'
            }
        };
    }

    /**
     * Get API Category label
     */
    getAPICategory(apiScore) {
        if (apiScore >= 90) return { label: 'Elite', color: '#10b981', description: 'World-class performance level' };
        if (apiScore >= 80) return { label: 'Advanced', color: '#3b82f6', description: 'Competitive runner' };
        if (apiScore >= 70) return { label: 'Intermediate', color: '#8b5cf6', description: 'Experienced runner' };
        if (apiScore >= 60) return { label: 'Developing', color: '#f59e0b', description: 'Progressing well' };
        if (apiScore >= 50) return { label: 'Beginner', color: '#ef4444', description: 'Building foundation' };
        return { label: 'Novice', color: '#6b7280', description: 'Starting journey' };
    }

    /**
     * Calculate 90-day improvement projection
     */
    calculate90DayProjection(currentAPI, trainingConsistency) {
        // Average improvement: 5-15 points over 90 days
        // Depends on consistency and current level
        
        let baseImprovement = 8; // Average
        
        // Higher consistency = more improvement
        if (trainingConsistency >= 6) baseImprovement = 12;
        else if (trainingConsistency >= 5) baseImprovement = 10;
        else if (trainingConsistency >= 4) baseImprovement = 8;
        else if (trainingConsistency >= 3) baseImprovement = 6;
        else baseImprovement = 4;
        
        // Diminishing returns at higher levels
        if (currentAPI >= 85) baseImprovement *= 0.5;
        else if (currentAPI >= 75) baseImprovement *= 0.7;
        
        const projectedAPI = Math.min(100, currentAPI + baseImprovement);
        
        return {
            current: currentAPI,
            projected: Math.round(projectedAPI),
            improvement: Math.round(projectedAPI - currentAPI),
            timeline: '90 days'
        };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AkuraAPI;
}
