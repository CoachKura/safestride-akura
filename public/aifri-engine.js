/**
 * AIFRI Performance Index Engine (Marketing Brand)
 * Backend uses AISRI (Akura Injury & Safety Risk Index)
 * 
 * Formula: AIFRI = (Running × 40%) + (Strength × 20%) + (ROM × 15%) + (Balance × 15%) + (Mobility × 10%)
 * 
 * Integration with Strava/Garmin for auto-calculating Running pillar
 */

class AIFRIEngine {
    constructor() {
        // Pillar weights (must sum to 1.0)
        this.weights = {
            running: 0.40,
            strength: 0.20,
            rom: 0.15,      // Range of Motion
            balance: 0.15,
            mobility: 0.10
        };

        // Training zones with HR ranges and unlock requirements
        this.trainingZones = {
            'AR': {
                name: 'Active Recovery',
                code: 'AR',
                hrMinPercent: 50,
                hrMaxPercent: 60,
                purpose: 'Recovery, warm-up, cool-down',
                minAIFRI: 0,
                color: '#93C5FD',
                sortOrder: 1
            },
            'F': {
                name: 'Foundation',
                code: 'F',
                hrMinPercent: 60,
                hrMaxPercent: 70,
                purpose: 'Aerobic Base, Fat Burning, Stamina',
                minAIFRI: 0,
                color: '#60A5FA',
                sortOrder: 2
            },
            'EN': {
                name: 'Endurance',
                code: 'EN',
                hrMinPercent: 70,
                hrMaxPercent: 80,
                purpose: 'Aerobic Fitness, Improved Oxygen Efficiency',
                minAIFRI: 40,
                color: '#34D399',
                sortOrder: 3
            },
            'TH': {
                name: 'Threshold',
                code: 'TH',
                hrMinPercent: 80,
                hrMaxPercent: 87,
                purpose: 'Lactate Threshold, Anaerobic Capacity, Speed Endurance',
                minAIFRI: 55,
                color: '#FBBF24',
                sortOrder: 4
            },
            'P': {
                name: 'Power',
                code: 'P',
                hrMinPercent: 87,
                hrMaxPercent: 95,
                purpose: 'Max Oxygen Uptake (VO2 Max), Peak Performance',
                minAIFRI: 70,
                requiresSafetyGate: true,
                color: '#FB923C',
                sortOrder: 5
            },
            'SP': {
                name: 'Speed',
                code: 'SP',
                hrMinPercent: 95,
                hrMaxPercent: 100,
                purpose: 'Anaerobic Power, Sprinting, Short Bursts',
                minAIFRI: 85,
                requiresSafetyGate: true,
                color: '#EF4444',
                sortOrder: 6
            }
        };

        // Risk categories based on AIFRI score
        this.riskCategories = {
            critical: { min: 0, max: 39, label: 'Critical Risk', color: '#DC2626' },
            high: { min: 40, max: 54, label: 'High Risk', color: '#F59E0B' },
            medium: { min: 55, max: 69, label: 'Medium Risk', color: '#EAB308' },
            low: { min: 70, max: 100, label: 'Low Risk', color: '#10B981' }
        };
    }

    /**
     * Calculate complete AIFRI score from 5 pillars
     * @param {Object} pillars - { running, strength, rom, balance, mobility }
     * @returns {number} AIFRI score (0-100)
     */
    calculateAIFRI(pillars) {
        const score = (
            (pillars.running || 0) * this.weights.running +
            (pillars.strength || 0) * this.weights.strength +
            (pillars.rom || 0) * this.weights.rom +
            (pillars.balance || 0) * this.weights.balance +
            (pillars.mobility || 0) * this.weights.mobility
        );

        return Math.round(Math.max(0, Math.min(100, score)));
    }

    /**
     * Calculate Running pillar score from Strava/Garmin data
     * Uses weighted HRV, Recovery Status, Load History, Sleep, Subjective Feel
     * 
     * Formula from flowchart:
     * Running Score = (Weighted HRV × 0.3) + (Recovery Status × 0.3) + 
     *                 (Load History × 0.2) + (Sleep Quality × 0.1) + (Subjective Feel × 0.1)
     */
    calculateRunningPillarFromDeviceData(deviceData) {
        const {
            hrv = 50,                    // Heart Rate Variability (normalized 0-100)
            recoveryStatus = 50,         // Recovery status from device (0-100)
            loadHistory = 50,            // Training load balance (0-100)
            sleepQuality = 50,          // Sleep quality score (0-100)
            subjectiveFeel = 50,        // Self-reported feeling (0-100)
            recentPaces = [],           // Array of recent pace data
            weeklyDistance = 0,         // Weekly mileage
            consistencyWeeks = 0        // Weeks of consistent training
        } = deviceData;

        // Calculate weighted running score
        let runningScore = (
            hrv * 0.30 +
            recoveryStatus * 0.30 +
            loadHistory * 0.20 +
            sleepQuality * 0.10 +
            subjectiveFeel * 0.10
        );

        // Bonus for pace improvement
        if (recentPaces.length >= 5) {
            const paceImprovement = this.calculatePaceImprovement(recentPaces);
            runningScore += paceImprovement;
        }

        // Bonus for weekly distance (capped at +10 points)
        const distanceBonus = Math.min(10, weeklyDistance / 5);
        runningScore += distanceBonus;

        // Bonus for consistency (capped at +10 points)
        const consistencyBonus = Math.min(10, consistencyWeeks * 0.5);
        runningScore += consistencyBonus;

        return Math.round(Math.max(0, Math.min(100, runningScore)));
    }

    /**
     * Calculate pace improvement from recent workouts
     */
    calculatePaceImprovement(paces) {
        if (paces.length < 5) return 0;

        const oldAvg = paces.slice(0, Math.floor(paces.length / 2)).reduce((a, b) => a + b, 0) / Math.floor(paces.length / 2);
        const newAvg = paces.slice(Math.floor(paces.length / 2)).reduce((a, b) => a + b, 0) / Math.ceil(paces.length / 2);

        // Faster pace = improvement (lower seconds per km is better)
        const improvement = oldAvg - newAvg;
        return Math.min(10, improvement * 2); // Max +10 points
    }

    /**
     * Get risk category from AIFRI score
     */
    getRiskCategory(aifrScore) {
        for (const [key, category] of Object.entries(this.riskCategories)) {
            if (aifrScore >= category.min && aifrScore <= category.max) {
                return category;
            }
        }
        return this.riskCategories.critical;
    }

    /**
     * Determine allowed training zones based on AIFRI score
     * Per Step 2 of Workout Prescription Algorithm
     */
    getAllowedZones(aifrScore, safetyGatesPassed = false) {
        const zones = [];

        // Score 0-39: AR, F only
        if (aifrScore < 40) {
            zones.push('AR', 'F');
        }
        // Score 40-54: +EN
        else if (aifrScore < 55) {
            zones.push('AR', 'F', 'EN');
        }
        // Score 55-69: +TH
        else if (aifrScore < 70) {
            zones.push('AR', 'F', 'EN', 'TH');
        }
        // Score 70-84: +P (if safety gates passed)
        else if (aifrScore < 85) {
            zones.push('AR', 'F', 'EN', 'TH');
            if (safetyGatesPassed) {
                zones.push('P');
            }
        }
        // Score 85-100: All zones (if safety gates passed)
        else {
            zones.push('AR', 'F', 'EN', 'TH');
            if (safetyGatesPassed) {
                zones.push('P', 'SP');
            }
        }

        return zones;
    }

    /**
     * Check if Zone P (Power) safety gate requirements are met
     * Requirements:
     * - AIFRI Score ≥ 70
     * - ROM Score ≥ 75
     * - No injuries past 4 weeks
     * - 8+ weeks lower zone training
     */
    checkPowerZoneSafetyGate(data) {
        return {
            passed: data.aifrScore >= 70 &&
                    data.romScore >= 75 &&
                    data.weeksInjuryFree >= 4 &&
                    data.weeksFoundation >= 8,
            requirements: {
                aifrScore: { required: 70, current: data.aifrScore, met: data.aifrScore >= 70 },
                romScore: { required: 75, current: data.romScore, met: data.romScore >= 75 },
                weeksInjuryFree: { required: 4, current: data.weeksInjuryFree, met: data.weeksInjuryFree >= 4 },
                weeksFoundation: { required: 8, current: data.weeksFoundation, met: data.weeksFoundation >= 8 }
            }
        };
    }

    /**
     * Check if Zone SP (Speed) safety gate requirements are met
     * Requirements:
     * - AIFRI Score ≥ 75
     * - All 5 Pillars ≥ 75
     * - Perfect running form
     * - 12+ weeks including Power work
     */
    checkSpeedZoneSafetyGate(data) {
        const allPillars75 = data.runningScore >= 75 &&
                             data.strengthScore >= 75 &&
                             data.romScore >= 75 &&
                             data.balanceScore >= 75 &&
                             data.mobilityScore >= 75;

        return {
            passed: data.aifrScore >= 75 &&
                    allPillars75 &&
                    data.perfectForm === true &&
                    data.weeksPowerTraining >= 12,
            requirements: {
                aifrScore: { required: 75, current: data.aifrScore, met: data.aifrScore >= 75 },
                allPillars75: { required: true, current: allPillars75, met: allPillars75 },
                perfectForm: { required: true, current: data.perfectForm, met: data.perfectForm === true },
                weeksPowerTraining: { required: 12, current: data.weeksPowerTraining, met: data.weeksPowerTraining >= 12 }
            }
        };
    }

    /**
     * Calculate HR zones for athlete based on age and resting HR
     */
    calculateHRZones(age, restingHR) {
        const maxHR = Math.round(208 - (0.7 * age));
        const hrReserve = maxHR - restingHR;

        const zones = {};
        for (const [code, zone] of Object.entries(this.trainingZones)) {
            zones[code] = {
                ...zone,
                min: Math.round(restingHR + (hrReserve * zone.hrMinPercent / 100)),
                max: Math.round(restingHR + (hrReserve * zone.hrMaxPercent / 100))
            };
        }

        return { maxHR, restingHR, zones };
    }

    /**
     * Generate weekly training schedule based on AIFRI score and phase
     * Per AKURA Weekly Training Structure from image
     */
    generateWeeklySchedule(aifrScore, phase, allowedZones) {
        const schedule = {
            monday: { type: 'REST or Active Recovery', zone: 'AR', duration: '20-30 min', protocol: 'Recovery between weeks' },
            tuesday: { type: 'Foundation/Endurance', zone: allowedZones.includes('EN') ? 'EN' : 'F', duration: '40-60 min', protocol: 'ENGINE or OXYGEN' },
            wednesday: { type: 'Strength Training', zone: null, duration: '45-60 min', protocol: 'STRENGTH or POWER' },
            thursday: { type: 'Intervals/Tempo', zone: this.selectIntensityZone(allowedZones), duration: '40-50 min', protocol: 'PACE or THRESHOLD' },
            friday: { type: 'Mobility & Flexibility', zone: null, duration: '30-45 min', protocol: 'MOBILITY' },
            saturday: { type: 'Long Run', zone: allowedZones.includes('EN') ? 'EN' : 'F', duration: '60-90+ min', protocol: 'ENDURANCE' },
            sunday: { type: 'Active Recovery & Wellness', zone: 'AR', duration: 'Light activity', protocol: 'RECOVERY & ADAPTATION' }
        };

        return schedule;
    }

    /**
     * Select appropriate intensity zone for interval training
     */
    selectIntensityZone(allowedZones) {
        if (allowedZones.includes('SP')) return 'SP';
        if (allowedZones.includes('P')) return 'P';
        if (allowedZones.includes('TH')) return 'TH';
        if (allowedZones.includes('EN')) return 'EN';
        return 'F';
    }

    /**
     * Determine current training phase based on total distance and AIFRI score
     * Per AKURA 6-Phase Training Distribution (0-5000 km roadmap)
     */
    determineTrainingPhase(totalDistance, aifrScore) {
        if (totalDistance < 800) {
            return {
                phase: 1,
                name: 'Base Building',
                distanceRange: '0-800 km',
                weeks: '1-16',
                zoneDistribution: { AR: 20, F: 75, EN: 5 },
                protocols: ['START', 'ENGINE'],
                weeklyRuns: 3,
                weeklyStrength: 1
            };
        } else if (totalDistance < 1600) {
            return {
                phase: 2,
                name: 'Aerobic Development',
                distanceRange: '800-1600 km',
                weeks: '17-32',
                zoneDistribution: { TH: 10, EN: 25, F: 65 },
                protocols: ['ENGINE', 'OXYGEN', 'ZONES'],
                weeklyRuns: 4,
                weeklyStrength: 3
            };
        } else if (totalDistance < 2400) {
            return {
                phase: 3,
                name: 'Threshold Focus',
                distanceRange: '1600-2400 km',
                weeks: '33-48',
                zoneDistribution: { I: 15, TH: 30, F: 55 },
                protocols: ['POWER', 'ZONES', 'STRENGTH'],
                weeklyRuns: 4,
                weeklyStrength: 4
            };
        } else if (totalDistance < 3200) {
            return {
                phase: 4,
                name: 'Interval Training',
                distanceRange: '2400-3200 km',
                weeks: '49-64',
                zoneDistribution: { I: 35, R: 20, F: 45 },
                protocols: ['POWER', 'ZONES', 'STRENGTH'],
                weeklyRuns: 5,
                weeklyStrength: 4
            };
        } else if (totalDistance < 4000) {
            return {
                phase: 5,
                name: 'Peak Performance',
                distanceRange: '3200-4000 km',
                weeks: '65-80',
                zoneDistribution: { RP: 30, R: 30, F: 40 },
                protocols: ['LONG RUN', 'ZONES', 'STRENGTH'],
                weeklyRuns: 5,
                weeklyStrength: 5
            };
        } else {
            return {
                phase: 6,
                name: 'Taper & Recovery',
                distanceRange: '4000-5000 km',
                weeks: '81-100',
                zoneDistribution: { RP: 10, AR: 40, F: 50 },
                protocols: ['START', 'ENGINE', 'LONG RUN'],
                weeklyRuns: 3,
                weeklyStrength: 2
            };
        }
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AIFRIEngine;
}
