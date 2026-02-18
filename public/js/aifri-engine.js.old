/**
 * AIFRI Performance Index Engine (Marketing Brand)
 * Backend uses AISRI (Akura Injury & Safety Risk Index)
 * 
 * Formula: AIFRI = (Running  40%) + (Strength  20%) + (ROM  15%) + (Balance  15%) + (Mobility  10%)
 */

class AIFRIEngine {
    constructor() {
        // Pillar weights (must sum to 1.0)
        this.weights = {
            running: 0.40,
            strength: 0.20,
            rom: 0.15,
            balance: 0.15,
            mobility: 0.10
        };

        // Training zones with HR ranges
        this.trainingZones = {
            'AR': { name: 'Active Recovery', hrMinPercent: 50, hrMaxPercent: 60, minAIFRI: 0, color: '#93C5FD', sortOrder: 1 },
            'F': { name: 'Foundation', hrMinPercent: 60, hrMaxPercent: 70, minAIFRI: 0, color: '#60A5FA', sortOrder: 2 },
            'EN': { name: 'Endurance', hrMinPercent: 70, hrMaxPercent: 80, minAIFRI: 40, color: '#34D399', sortOrder: 3 },
            'TH': { name: 'Threshold', hrMinPercent: 80, hrMaxPercent: 87, minAIFRI: 55, color: '#FBBF24', sortOrder: 4 },
            'P': { name: 'Power', hrMinPercent: 87, hrMaxPercent: 95, minAIFRI: 70, requiresSafetyGate: true, color: '#FB923C', sortOrder: 5 },
            'SP': { name: 'Speed', hrMinPercent: 95, hrMaxPercent: 100, minAIFRI: 85, requiresSafetyGate: true, color: '#EF4444', sortOrder: 6 }
        };

        this.riskCategories = {
            critical: { min: 0, max: 39, label: 'Critical Risk', color: '#DC2626' },
            high: { min: 40, max: 54, label: 'High Risk', color: '#F59E0B' },
            medium: { min: 55, max: 69, label: 'Medium Risk', color: '#EAB308' },
            low: { min: 70, max: 100, label: 'Low Risk', color: '#10B981' }
        };
    }

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

    getRiskCategory(aifrScore) {
        for (const [key, category] of Object.entries(this.riskCategories)) {
            if (aifrScore >= category.min && aifrScore <= category.max) {
                return category;
            }
        }
        return this.riskCategories.critical;
    }

    getAllowedZones(aifrScore, safetyGatesPassed = false) {
        const zones = [];
        if (aifrScore < 40) {
            zones.push('AR', 'F');
        } else if (aifrScore < 55) {
            zones.push('AR', 'F', 'EN');
        } else if (aifrScore < 70) {
            zones.push('AR', 'F', 'EN', 'TH');
        } else if (aifrScore < 85) {
            zones.push('AR', 'F', 'EN', 'TH');
            if (safetyGatesPassed) zones.push('P');
        } else {
            zones.push('AR', 'F', 'EN', 'TH');
            if (safetyGatesPassed) zones.push('P', 'SP');
        }
        return zones;
    }

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
}

// Export for browser
if (typeof window !== 'undefined') {
    window.AIFRIEngine = AIFRIEngine;
}
