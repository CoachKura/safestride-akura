/**
 * AISRI Engine V2 - 6 Pillar System
 * Akura Injury & Safety Risk Index
 * 
 * 6 PILLARS (Total = 100%):
 * - Running Performance: 40%
 * - Strength: 15%
 * - ROM (Range of Motion): 12%
 * - Balance: 13%
 * - Alignment: 10%
 * - Mobility: 10%
 */

class AISRIEngine {
    constructor() {
        // 6 Pillar Weights
        this.weights = {
            running: 0.40,      // 40%
            strength: 0.15,     // 15%
            rom: 0.12,          // 12%
            balance: 0.13,      // 13%
            alignment: 0.10,    // 10%
            mobility: 0.10      // 10%
        };

        // Training Zones (HR-based)
        this.zones = {
            AR: {
                code: 'AR',
                name: 'Active Recovery',
                hrPercent: { min: 50, max: 60 },
                purpose: 'Recovery and regeneration',
                color: '#93c5fd',
                minAISRI: 0,
                prerequisites: []
            },
            F: {
                code: 'F',
                name: 'Foundation',
                hrPercent: { min: 60, max: 70 },
                purpose: 'Build aerobic base',
                color: '#86efac',
                minAISRI: 0,
                prerequisites: []
            },
            EN: {
                code: 'EN',
                name: 'Endurance',
                hrPercent: { min: 70, max: 80 },
                purpose: 'Aerobic endurance development',
                color: '#fde047',
                minAISRI: 40,
                prerequisites: []
            },
            TH: {
                code: 'TH',
                name: 'Threshold',
                hrPercent: { min: 80, max: 87 },
                purpose: 'Lactate threshold training',
                color: '#fdba74',
                minAISRI: 55,
                prerequisites: []
            },
            P: {
                code: 'P',
                name: 'Power',
                hrPercent: { min: 87, max: 95 },
                purpose: 'Muscular power & speed endurance',
                color: '#f97316',
                minAISRI: 70,
                prerequisites: ['safetyGate_power']
            },
            SP: {
                code: 'SP',
                name: 'Speed',
                hrPercent: { min: 95, max: 100 },
                purpose: 'Maximum speed & neuromuscular power',
                color: '#dc2626',
                minAISRI: 85,
                prerequisites: ['safetyGate_speed']
            }
        };

        // Risk Categories
        this.riskCategories = {
            critical: { min: 0, max: 39, label: 'Critical Risk', color: '#ef4444', zones: ['AR', 'F'] },
            high: { min: 40, max: 54, label: 'High Risk', color: '#f97316', zones: ['AR', 'F', 'EN'] },
            medium: { min: 55, max: 69, label: 'Medium Risk', color: '#f59e0b', zones: ['AR', 'F', 'EN', 'TH'] },
            low: { min: 70, max: 84, label: 'Low Risk', color: '#10b981', zones: ['AR', 'F', 'EN', 'TH', 'P'] },
            veryLow: { min: 85, max: 100, label: 'Very Low Risk', color: '#059669', zones: ['AR', 'F', 'EN', 'TH', 'P', 'SP'] }
        };

        // Training Phases (0-5000 km roadmap)
        this.trainingPhases = [
            { phase: 1, name: 'Foundation (0-500 km)', minKm: 0, maxKm: 500, minAISRI: 0 },
            { phase: 2, name: 'Base Building (500-1000 km)', minKm: 500, maxKm: 1000, minAISRI: 40 },
            { phase: 3, name: 'Development (1000-2000 km)', minKm: 1000, maxKm: 2000, minAISRI: 55 },
            { phase: 4, name: 'Performance (2000-3500 km)', minKm: 2000, maxKm: 3500, minAISRI: 70 },
            { phase: 5, name: 'Peak Performance (3500-5000 km)', minKm: 3500, maxKm: 5000, minAISRI: 85 },
            { phase: 6, name: 'Elite (5000+ km)', minKm: 5000, maxKm: 999999, minAISRI: 90 }
        ];
    }

    /**
     * Calculate total AISRI score from 6 pillars
     * @param {Object} pillars - { running, strength, rom, balance, alignment, mobility }
     * @returns {Number} Total AISRI score (0-100)
     */
    calculateAISRI(pillars) {
        const {
            running = 50,
            strength = 50,
            rom = 50,
            balance = 50,
            alignment = 50,
            mobility = 50
        } = pillars;

        const total = 
            running * this.weights.running +
            strength * this.weights.strength +
            rom * this.weights.rom +
            balance * this.weights.balance +
            alignment * this.weights.alignment +
            mobility * this.weights.mobility;

        return Math.round(total);
    }

    /**
     * Get risk category based on AISRI score
     * @param {Number} score - AISRI score (0-100)
     * @returns {Object} Risk category details
     */
    getRiskCategory(score) {
        for (const [key, category] of Object.entries(this.riskCategories)) {
            if (score >= category.min && score <= category.max) {
                return { ...category, key };
            }
        }
        return this.riskCategories.critical;
    }

    /**
     * Get allowed training zones based on AISRI score and safety gates
     * @param {Number} aisriScore - AISRI score
     * @param {Boolean} powerGatePassed - Has athlete passed Power zone safety gate?
     * @param {Boolean} speedGatePassed - Has athlete passed Speed zone safety gate?
     * @returns {Array} Array of allowed zone codes
     */
    getAllowedZones(aisriScore, powerGatePassed = false, speedGatePassed = false) {
        const riskCategory = this.getRiskCategory(aisriScore);
        let zones = [...riskCategory.zones];

        // Remove P if safety gate not passed
        if (zones.includes('P') && !powerGatePassed) {
            zones = zones.filter(z => z !== 'P');
        }

        // Remove SP if safety gate not passed
        if (zones.includes('SP') && !speedGatePassed) {
            zones = zones.filter(z => z !== 'SP');
        }

        return zones;
    }

    /**
     * Check Power Zone Safety Gate
     * Requirements:
     * - AISRI Score >= 70
     * - ROM Score >= 75
     * - 8+ weeks injury-free
     * - 6+ weeks foundation training
     */
    checkPowerZoneSafetyGate(data) {
        const {
            aisriScore,
            romScore,
            weeksInjuryFree,
            weeksFoundation
        } = data;

        const requirements = {
            aisriScore: { required: 70, current: aisriScore, met: aisriScore >= 70 },
            romScore: { required: 75, current: romScore, met: romScore >= 75 },
            weeksInjuryFree: { required: 8, current: weeksInjuryFree, met: weeksInjuryFree >= 8 },
            weeksFoundation: { required: 6, current: weeksFoundation, met: weeksFoundation >= 6 }
        };

        const passed = Object.values(requirements).every(req => req.met);

        return {
            passed,
            requirements,
            message: passed 
                ? '✅ Power Zone (P) UNLOCKED' 
                : '🔒 Power Zone (P) LOCKED - Complete requirements to unlock'
        };
    }

    /**
     * Check Speed Zone Safety Gate
     * Requirements:
     * - AISRI Score >= 85
     * - Running Pillar >= 80
     * - All other pillars >= 75
     * - Perfect running form
     * - 12+ weeks of Power zone training
     */
    checkSpeedZoneSafetyGate(data) {
        const {
            aisriScore,
            runningScore,
            strengthScore,
            romScore,
            balanceScore,
            alignmentScore,
            mobilityScore,
            perfectForm = false,
            weeksPowerTraining
        } = data;

        const requirements = {
            aisriScore: { required: 85, current: aisriScore, met: aisriScore >= 85 },
            runningScore: { required: 80, current: runningScore, met: runningScore >= 80 },
            strengthScore: { required: 75, current: strengthScore, met: strengthScore >= 75 },
            romScore: { required: 75, current: romScore, met: romScore >= 75 },
            balanceScore: { required: 75, current: balanceScore, met: balanceScore >= 75 },
            alignmentScore: { required: 75, current: alignmentScore, met: alignmentScore >= 75 },
            mobilityScore: { required: 75, current: mobilityScore, met: mobilityScore >= 75 },
            perfectForm: { required: true, current: perfectForm, met: perfectForm },
            weeksPowerTraining: { required: 12, current: weeksPowerTraining, met: weeksPowerTraining >= 12 }
        };

        const passed = Object.values(requirements).every(req => req.met);

        return {
            passed,
            requirements,
            message: passed 
                ? '✅ Speed Zone (SP) UNLOCKED' 
                : '🔒 Speed Zone (SP) LOCKED - Complete requirements to unlock'
        };
    }

    /**
     * Calculate HR zones based on age and resting HR
     * @param {Number} age - Athlete age
     * @param {Number} restingHR - Resting heart rate
     * @returns {Object} HR zones with min/max bpm for each zone
     */
    calculateHRZones(age, restingHR = 60) {
        const maxHR = 220 - age;
        const hrReserve = maxHR - restingHR;

        const zones = {};
        Object.entries(this.zones).forEach(([key, zone]) => {
            const minHR = Math.round(restingHR + (hrReserve * zone.hrPercent.min / 100));
            const maxHR_zone = Math.round(restingHR + (hrReserve * zone.hrPercent.max / 100));

            zones[key] = {
                ...zone,
                min: minHR,
                max: maxHR_zone,
                range: `${minHR}-${maxHR_zone} bpm`
            };
        });

        return {
            maxHR,
            restingHR,
            hrReserve,
            zones
        };
    }

    /**
     * Determine current training phase based on total distance
     * @param {Number} totalKm - Total lifetime running distance
     * @param {Number} aisriScore - Current AISRI score
     * @returns {Object} Current training phase
     */
    determineTrainingPhase(totalKm, aisriScore) {
        for (const phase of this.trainingPhases) {
            if (totalKm >= phase.minKm && totalKm < phase.maxKm) {
                const eligible = aisriScore >= phase.minAISRI;
                return {
                    ...phase,
                    eligible,
                    progress: ((totalKm - phase.minKm) / (phase.maxKm - phase.minKm) * 100).toFixed(1),
                    kmRemaining: phase.maxKm - totalKm
                };
            }
        }
        return this.trainingPhases[0]; // Default to Phase 1
    }

    /**
     * Get zone details by code
     * @param {String} zoneCode - Zone code (AR, F, EN, TH, P, SP)
     * @returns {Object} Zone details
     */
    getZone(zoneCode) {
        return this.zones[zoneCode] || this.zones.AR;
    }

    /**
     * Validate AISRI data completeness
     * @param {Object} pillars - All 6 pillar scores
     * @returns {Object} Validation result
     */
    validateData(pillars) {
        const required = ['running', 'strength', 'rom', 'balance', 'alignment', 'mobility'];
        const missing = required.filter(p => !(p in pillars) || pillars[p] === null || pillars[p] === undefined);

        if (missing.length > 0) {
            return {
                valid: false,
                missing,
                message: `Missing pillar data: ${missing.join(', ')}`
            };
        }

        // Check if scores are in valid range (0-100)
        const outOfRange = required.filter(p => pillars[p] < 0 || pillars[p] > 100);

        if (outOfRange.length > 0) {
            return {
                valid: false,
                outOfRange,
                message: `Invalid scores (must be 0-100): ${outOfRange.join(', ')}`
            };
        }

        return {
            valid: true,
            message: 'All pillar data complete and valid'
        };
    }

    /**
     * Generate personalized training recommendations
     * @param {Object} data - Complete athlete data
     * @returns {Array} Array of recommendations
     */
    generateRecommendations(data) {
        const { aisriScore, pillars, riskCategory, allowedZones } = data;
        const recommendations = [];

        // Risk-based recommendations
        if (riskCategory.key === 'critical') {
            recommendations.push({
                type: 'urgent',
                title: 'Critical Risk - Focus on Recovery',
                message: 'Stay in AR and F zones only. Prioritize strength and mobility work.',
                priority: 1
            });
        }

        // Weak pillar recommendations
        const weakPillars = Object.entries(pillars)
            .filter(([key, score]) => score < 60)
            .sort((a, b) => a[1] - b[1]);

        if (weakPillars.length > 0) {
            recommendations.push({
                type: 'improvement',
                title: 'Weak Pillars Detected',
                message: `Focus on: ${weakPillars.map(([key]) => key).join(', ')}`,
                priority: 2,
                details: weakPillars.map(([key, score]) => ({ pillar: key, score }))
            });
        }

        // Zone progression recommendations
        if (allowedZones.includes('EN') && !allowedZones.includes('TH')) {
            recommendations.push({
                type: 'progression',
                title: 'Close to Threshold Zone',
                message: `Need ${55 - aisriScore} more AISRI points to unlock TH zone`,
                priority: 3
            });
        }

        return recommendations;
    }

    /**
     * Export AISRI report as JSON
     * @param {Object} data - Complete athlete data
     * @returns {String} JSON report
     */
    exportReport(data) {
        const report = {
            timestamp: new Date().toISOString(),
            athlete: data.athlete || {},
            aisriScore: data.aisriScore,
            riskCategory: data.riskCategory,
            pillars: data.pillars,
            allowedZones: data.allowedZones,
            recommendations: this.generateRecommendations(data),
            trainingPhase: data.trainingPhase || {},
            safetyGates: {
                power: data.powerGate || {},
                speed: data.speedGate || {}
            }
        };

        return JSON.stringify(report, null, 2);
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AISRIEngine;
}

// Export for browser
if (typeof window !== 'undefined') {
    window.AISRIEngine = AISRIEngine;
}
