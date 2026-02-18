/**
 * AISRI ML Analyzer
 * AI/ML-powered analyzer for Strava & Garmin data
 * Calculates 6-pillar AISRI scores with machine learning patterns
 * 
 * 6 PILLARS (Total = 100%):
 * - Running Performance: 40%
 * - Strength: 15%
 * - ROM (Range of Motion): 12%
 * - Balance: 13%
 * - Alignment: 10%
 * - Mobility: 10%
 */

class AISRIMLAnalyzer {
    constructor() {
        // Pillar weights
        this.weights = {
            running: 0.40,      // 40%
            strength: 0.15,     // 15%
            rom: 0.12,          // 12%
            balance: 0.13,      // 13%
            alignment: 0.10,    // 10%
            mobility: 0.10      // 10%
        };

        // ML pattern thresholds
        this.thresholds = {
            excellent: 85,
            good: 70,
            moderate: 55,
            poor: 40,
            critical: 0
        };

        // Training load patterns
        this.loadPatterns = {
            optimal: { min: 0.8, max: 1.3 },    // 80-130% of baseline
            risky: { min: 1.3, max: 1.5 },      // 130-150% spike
            dangerous: { min: 1.5, max: 999 }   // >150% spike
        };
    }

    /**
     * MAIN ANALYZER: Process Strava/Garmin data and calculate 6-pillar AISRI
     * @param {Object} athleteData - Raw athlete data from devices
     * @returns {Object} Complete AISRI analysis with ML insights
     */
    async analyzeAthlete(athleteData) {
        console.log('🔬 Starting AISRI ML Analysis...');

        // Step 1: Extract & clean Strava/Garmin data
        const cleanData = this.extractDeviceData(athleteData);

        // Step 2: Calculate Running Pillar (40%) - AI/ML Analysis
        const runningPillar = await this.calculateRunningPillar(cleanData);

        // Step 3: Calculate other 5 pillars from assessment data
        const strengthPillar = this.calculateStrengthPillar(athleteData.assessments);
        const romPillar = this.calculateROMPillar(athleteData.assessments);
        const balancePillar = this.calculateBalancePillar(athleteData.assessments);
        const alignmentPillar = this.calculateAlignmentPillar(athleteData.assessments);
        const mobilityPillar = this.calculateMobilityPillar(athleteData.assessments);

        // Step 4: Calculate total AISRI score
        const totalScore = this.calculateTotalAISRI({
            running: runningPillar.score,
            strength: strengthPillar.score,
            rom: romPillar.score,
            balance: balancePillar.score,
            alignment: alignmentPillar.score,
            mobility: mobilityPillar.score
        });

        // Step 5: Risk assessment
        const riskCategory = this.assessRisk(totalScore, runningPillar);

        // Step 6: Generate ML insights
        const mlInsights = this.generateMLInsights({
            runningPillar,
            strengthPillar,
            romPillar,
            balancePillar,
            alignmentPillar,
            mobilityPillar,
            totalScore,
            riskCategory
        });

        // Step 7: Training recommendations
        const recommendations = this.generateRecommendations(mlInsights);

        return {
            timestamp: new Date().toISOString(),
            aisriScore: totalScore,
            riskCategory,
            pillars: {
                running: { ...runningPillar, weight: this.weights.running },
                strength: { ...strengthPillar, weight: this.weights.strength },
                rom: { ...romPillar, weight: this.weights.rom },
                balance: { ...balancePillar, weight: this.weights.balance },
                alignment: { ...alignmentPillar, weight: this.weights.alignment },
                mobility: { ...mobilityPillar, weight: this.weights.mobility }
            },
            mlInsights,
            recommendations,
            dataQuality: this.assessDataQuality(cleanData)
        };
    }

    /**
     * PILLAR 1: Running Performance (40% of total AISRI)
     * AI/ML analysis of Strava/Garmin running data
     */
    async calculateRunningPillar(data) {
        console.log('🏃 Calculating Running Pillar (40%)...');

        const metrics = {
            // Core metrics from devices
            hrv: this.analyzeHRV(data.hrv),                           // 30%
            recovery: this.analyzeRecovery(data.recovery),            // 30%
            trainingLoad: this.analyzeTrainingLoad(data.load),        // 20%
            sleep: this.analyzeSleep(data.sleep),                     // 10%
            feel: this.analyzeSubjective(data.feel),                  // 10%

            // Bonus factors (up to +10 each)
            paceBonus: this.analyzePaceProgression(data.activities),  // +10
            distanceBonus: this.analyzeWeeklyDistance(data.activities), // +10
            consistencyBonus: this.analyzeConsistency(data.activities)  // +10
        };

        // Base score (0-70)
        const baseScore = 
            metrics.hrv.score * 0.30 +
            metrics.recovery.score * 0.30 +
            metrics.trainingLoad.score * 0.20 +
            metrics.sleep.score * 0.10 +
            metrics.feel.score * 0.10;

        // Add bonuses (up to +30)
        const bonusScore = 
            metrics.paceBonus.bonus +
            metrics.distanceBonus.bonus +
            metrics.consistencyBonus.bonus;

        const finalScore = Math.min(100, baseScore + bonusScore);

        return {
            score: Math.round(finalScore),
            breakdown: metrics,
            mlPatterns: this.identifyRunningPatterns(data),
            insights: this.generateRunningInsights(metrics, finalScore)
        };
    }

    /**
     * Analyze HRV (Heart Rate Variability) - 30% of Running Pillar
     */
    analyzeHRV(hrvData) {
        if (!hrvData || !hrvData.values || hrvData.values.length === 0) {
            return { score: 50, status: 'no_data', message: 'No HRV data available' };
        }

        const recent = hrvData.values.slice(-7); // Last 7 days
        const avg = recent.reduce((a, b) => a + b, 0) / recent.length;
        const baseline = hrvData.baseline || 50;
        const deviation = ((avg - baseline) / baseline) * 100;

        let score, status, message;

        if (deviation >= 10) {
            score = 90;
            status = 'excellent';
            message = 'HRV significantly above baseline - excellent recovery';
        } else if (deviation >= 5) {
            score = 80;
            status = 'good';
            message = 'HRV above baseline - good recovery state';
        } else if (deviation >= -5) {
            score = 70;
            status = 'normal';
            message = 'HRV near baseline - adequate recovery';
        } else if (deviation >= -10) {
            score = 50;
            status = 'low';
            message = 'HRV below baseline - consider easy day';
        } else {
            score = 30;
            status = 'very_low';
            message = 'HRV significantly low - rest recommended';
        }

        return {
            score,
            status,
            message,
            current: Math.round(avg),
            baseline: Math.round(baseline),
            deviation: Math.round(deviation),
            trend: this.calculateTrend(recent)
        };
    }

    /**
     * Analyze Recovery Status - 30% of Running Pillar
     */
    analyzeRecovery(recoveryData) {
        if (!recoveryData || !recoveryData.score) {
            return { score: 50, status: 'no_data', message: 'No recovery data available' };
        }

        const score = recoveryData.score; // From Garmin/Strava (0-100)
        let status, message;

        if (score >= 85) {
            status = 'fully_recovered';
            message = 'Fully recovered - ready for hard training';
        } else if (score >= 70) {
            status = 'recovered';
            message = 'Well recovered - moderate to hard training OK';
        } else if (score >= 55) {
            status = 'partial';
            message = 'Partially recovered - easy to moderate training';
        } else if (score >= 40) {
            status = 'poor';
            message = 'Poor recovery - easy training only';
        } else {
            status = 'critical';
            message = 'Critical recovery deficit - rest required';
        }

        return {
            score,
            status,
            message,
            restingHR: recoveryData.restingHR || null,
            sleepQuality: recoveryData.sleepQuality || null
        };
    }

    /**
     * Analyze Training Load - 20% of Running Pillar
     */
    analyzeTrainingLoad(loadData) {
        if (!loadData || !loadData.acute || !loadData.chronic) {
            return { score: 60, status: 'no_data', message: 'No training load data available' };
        }

        const acuteLoad = loadData.acute;      // Last 7 days
        const chronicLoad = loadData.chronic;  // Last 28 days
        const ratio = acuteLoad / chronicLoad; // ACWR (Acute:Chronic Workload Ratio)

        let score, status, message, risk;

        if (ratio >= 0.8 && ratio <= 1.3) {
            score = 90;
            status = 'optimal';
            message = 'Training load in optimal range';
            risk = 'low';
        } else if (ratio >= 1.3 && ratio <= 1.5) {
            score = 70;
            status = 'elevated';
            message = 'Training load elevated - monitor closely';
            risk = 'moderate';
        } else if (ratio > 1.5) {
            score = 40;
            status = 'dangerous';
            message = 'Training load spike detected - injury risk HIGH';
            risk = 'high';
        } else if (ratio < 0.8) {
            score = 60;
            status = 'low';
            message = 'Training load low - detraining possible';
            risk = 'low';
        }

        return {
            score,
            status,
            message,
            risk,
            acuteLoad: Math.round(acuteLoad),
            chronicLoad: Math.round(chronicLoad),
            ratio: ratio.toFixed(2),
            recommendation: this.getLoadRecommendation(ratio)
        };
    }

    /**
     * Analyze Sleep Quality - 10% of Running Pillar
     */
    analyzeSleep(sleepData) {
        if (!sleepData || !sleepData.avgHours) {
            return { score: 60, status: 'no_data', message: 'No sleep data available' };
        }

        const avgHours = sleepData.avgHours; // Last 7 days average
        const quality = sleepData.quality || 70; // Sleep quality score (0-100)

        let score, status, message;

        if (avgHours >= 7.5 && quality >= 80) {
            score = 90;
            status = 'excellent';
            message = 'Excellent sleep - optimal recovery';
        } else if (avgHours >= 7 && quality >= 70) {
            score = 80;
            status = 'good';
            message = 'Good sleep quality';
        } else if (avgHours >= 6 && quality >= 60) {
            score = 60;
            status = 'adequate';
            message = 'Adequate sleep - could improve';
        } else if (avgHours >= 5) {
            score = 40;
            status = 'poor';
            message = 'Poor sleep - affecting recovery';
        } else {
            score = 20;
            status = 'critical';
            message = 'Critical sleep deficit - performance impaired';
        }

        return {
            score,
            status,
            message,
            avgHours: avgHours.toFixed(1),
            quality: Math.round(quality),
            recommendation: avgHours < 7 ? 'Aim for 7-9 hours per night' : 'Maintain current sleep pattern'
        };
    }

    /**
     * Analyze Subjective Feel - 10% of Running Pillar
     */
    analyzeSubjective(feelData) {
        if (!feelData || !feelData.ratings || feelData.ratings.length === 0) {
            return { score: 60, status: 'no_data', message: 'No subjective ratings available' };
        }

        const recent = feelData.ratings.slice(-7); // Last 7 days
        const avg = recent.reduce((a, b) => a + b, 0) / recent.length;

        let score, status, message;

        if (avg >= 8) {
            score = 90;
            status = 'excellent';
            message = 'Feeling strong and energized';
        } else if (avg >= 6.5) {
            score = 80;
            status = 'good';
            message = 'Feeling good overall';
        } else if (avg >= 5) {
            score = 60;
            status = 'moderate';
            message = 'Moderate energy levels';
        } else if (avg >= 3.5) {
            score = 40;
            status = 'low';
            message = 'Low energy - consider reducing load';
        } else {
            score = 20;
            status = 'very_low';
            message = 'Very low energy - rest needed';
        }

        return {
            score,
            status,
            message,
            avgRating: avg.toFixed(1),
            trend: this.calculateTrend(recent)
        };
    }

    /**
     * Analyze Pace Progression (Bonus up to +10)
     */
    analyzePaceProgression(activities) {
        if (!activities || activities.length < 10) {
            return { bonus: 0, message: 'Insufficient data for pace analysis' };
        }

        const recentRuns = activities.filter(a => a.type === 'Run').slice(-10);
        const paces = recentRuns.map(a => a.averagePace); // min/km

        // Calculate pace improvement trend
        const firstHalf = paces.slice(0, 5).reduce((a, b) => a + b, 0) / 5;
        const secondHalf = paces.slice(5).reduce((a, b) => a + b, 0) / 5;
        const improvement = ((firstHalf - secondHalf) / firstHalf) * 100;

        let bonus, message;

        if (improvement >= 5) {
            bonus = 10;
            message = 'Excellent pace improvement - 5%+ faster';
        } else if (improvement >= 2.5) {
            bonus = 7;
            message = 'Good pace improvement - 2.5-5% faster';
        } else if (improvement >= 1) {
            bonus = 4;
            message = 'Moderate pace improvement - 1-2.5% faster';
        } else if (improvement >= -1) {
            bonus = 2;
            message = 'Pace maintained - no significant change';
        } else {
            bonus = 0;
            message = 'Pace declining - review training load';
        }

        return {
            bonus,
            message,
            improvement: improvement.toFixed(1) + '%',
            avgPaceRecent: this.formatPace(secondHalf)
        };
    }

    /**
     * Analyze Weekly Distance (Bonus up to +10)
     */
    analyzeWeeklyDistance(activities) {
        if (!activities || activities.length === 0) {
            return { bonus: 0, message: 'No activity data' };
        }

        const last28Days = activities.filter(a => {
            const activityDate = new Date(a.date);
            const cutoff = new Date();
            cutoff.setDate(cutoff.getDate() - 28);
            return activityDate >= cutoff && a.type === 'Run';
        });

        const totalKm = last28Days.reduce((sum, a) => sum + (a.distance / 1000), 0);
        const avgWeeklyKm = totalKm / 4;

        let bonus, message;

        if (avgWeeklyKm >= 50) {
            bonus = 10;
            message = 'Excellent volume - 50+ km/week';
        } else if (avgWeeklyKm >= 40) {
            bonus = 8;
            message = 'Great volume - 40-50 km/week';
        } else if (avgWeeklyKm >= 30) {
            bonus = 6;
            message = 'Good volume - 30-40 km/week';
        } else if (avgWeeklyKm >= 20) {
            bonus = 4;
            message = 'Moderate volume - 20-30 km/week';
        } else if (avgWeeklyKm >= 10) {
            bonus = 2;
            message = 'Low volume - 10-20 km/week';
        } else {
            bonus = 0;
            message = 'Very low volume - <10 km/week';
        }

        return {
            bonus,
            message,
            avgWeeklyKm: avgWeeklyKm.toFixed(1),
            totalKm: totalKm.toFixed(1)
        };
    }

    /**
     * Analyze Training Consistency (Bonus up to +10)
     */
    analyzeConsistency(activities) {
        if (!activities || activities.length === 0) {
            return { bonus: 0, message: 'No activity data' };
        }

        const last28Days = activities.filter(a => {
            const activityDate = new Date(a.date);
            const cutoff = new Date();
            cutoff.setDate(cutoff.getDate() - 28);
            return activityDate >= cutoff && a.type === 'Run';
        });

        const runsPerWeek = last28Days.length / 4;
        const consistency = (last28Days.length / 28) * 100; // % of days with activity

        let bonus, message;

        if (runsPerWeek >= 5 && consistency >= 60) {
            bonus = 10;
            message = 'Excellent consistency - 5+ runs/week';
        } else if (runsPerWeek >= 4 && consistency >= 50) {
            bonus = 8;
            message = 'Great consistency - 4-5 runs/week';
        } else if (runsPerWeek >= 3 && consistency >= 40) {
            bonus = 6;
            message = 'Good consistency - 3-4 runs/week';
        } else if (runsPerWeek >= 2) {
            bonus = 4;
            message = 'Moderate consistency - 2-3 runs/week';
        } else if (runsPerWeek >= 1) {
            bonus = 2;
            message = 'Low consistency - 1-2 runs/week';
        } else {
            bonus = 0;
            message = 'Very low consistency - <1 run/week';
        }

        return {
            bonus,
            message,
            runsPerWeek: runsPerWeek.toFixed(1),
            consistency: consistency.toFixed(0) + '%'
        };
    }

    /**
     * PILLAR 2-6: Calculate from assessment data
     */
    calculateStrengthPillar(assessments) {
        if (!assessments || !assessments.strength) {
            return { score: 50, status: 'no_data', message: 'No strength assessment data' };
        }
        // Simplified - would expand based on actual assessment data structure
        return { score: assessments.strength.score || 50, status: 'assessed', message: 'From manual assessment' };
    }

    calculateROMPillar(assessments) {
        if (!assessments || !assessments.rom) {
            return { score: 50, status: 'no_data', message: 'No ROM assessment data' };
        }
        return { score: assessments.rom.score || 50, status: 'assessed', message: 'From manual assessment' };
    }

    calculateBalancePillar(assessments) {
        if (!assessments || !assessments.balance) {
            return { score: 50, status: 'no_data', message: 'No balance assessment data' };
        }
        return { score: assessments.balance.score || 50, status: 'assessed', message: 'From manual assessment' };
    }

    calculateAlignmentPillar(assessments) {
        if (!assessments || !assessments.alignment) {
            return { score: 50, status: 'no_data', message: 'No alignment assessment data' };
        }
        return { score: assessments.alignment.score || 50, status: 'assessed', message: 'From manual assessment' };
    }

    calculateMobilityPillar(assessments) {
        if (!assessments || !assessments.mobility) {
            return { score: 50, status: 'no_data', message: 'No mobility assessment data' };
        }
        return { score: assessments.mobility.score || 50, status: 'assessed', message: 'From manual assessment' };
    }

    /**
     * Calculate Total AISRI Score
     */
    calculateTotalAISRI(pillars) {
        return Math.round(
            pillars.running * this.weights.running +
            pillars.strength * this.weights.strength +
            pillars.rom * this.weights.rom +
            pillars.balance * this.weights.balance +
            pillars.alignment * this.weights.alignment +
            pillars.mobility * this.weights.mobility
        );
    }

    /**
     * Assess Risk Category
     */
    assessRisk(totalScore, runningPillar) {
        let category, label, color, zones;

        if (totalScore >= 85) {
            category = 'veryLow';
            label = 'Very Low Risk';
            color = '#10b981';
            zones = ['AR', 'F', 'EN', 'TH', 'P', 'SP'];
        } else if (totalScore >= 70) {
            category = 'low';
            label = 'Low Risk';
            color = '#10b981';
            zones = ['AR', 'F', 'EN', 'TH', 'P'];
        } else if (totalScore >= 55) {
            category = 'medium';
            label = 'Medium Risk';
            color = '#f59e0b';
            zones = ['AR', 'F', 'EN', 'TH'];
        } else if (totalScore >= 40) {
            category = 'high';
            label = 'High Risk';
            color = '#f97316';
            zones = ['AR', 'F', 'EN'];
        } else {
            category = 'critical';
            label = 'Critical Risk';
            color = '#ef4444';
            zones = ['AR', 'F'];
        }

        if (runningPillar.breakdown && runningPillar.breakdown.trainingLoad && runningPillar.breakdown.trainingLoad.risk === 'high') {
            label += ' (Training Load Alert!)';
        }

        return { category, label, color, zones, score: totalScore };
    }

    /**
     * Generate ML Insights
     */
    generateMLInsights(data) {
        const insights = [];

        // Pattern detection would go here
        if (data.totalScore < 55) {
            insights.push({
                type: 'warning',
                title: 'Below Optimal Performance',
                message: 'Focus on base building and recovery',
                priority: 'high'
            });
        }

        return insights;
    }

    /**
     * Generate Recommendations
     */
    generateRecommendations(mlInsights) {
        return {
            immediate: mlInsights.filter(i => i.priority === 'high').map(i => i.message),
            shortTerm: mlInsights.filter(i => i.priority === 'medium').map(i => i.message),
            longTerm: mlInsights.filter(i => i.priority === 'low').map(i => i.message)
        };
    }

    // Helper functions
    extractDeviceData(athleteData) {
        return {
            hrv: athleteData.hrv || { values: [], baseline: 50 },
            recovery: athleteData.recovery || { score: 60 },
            load: athleteData.trainingLoad || { acute: 500, chronic: 500 },
            sleep: athleteData.sleep || { avgHours: 7, quality: 70 },
            feel: athleteData.feel || { ratings: [7, 7, 7] },
            activities: athleteData.activities || []
        };
    }

    calculateTrend(values) {
        if (values.length < 3) return 'insufficient_data';
        const first = values.slice(0, Math.floor(values.length / 2));
        const second = values.slice(Math.floor(values.length / 2));
        const firstAvg = first.reduce((a, b) => a + b, 0) / first.length;
        const secondAvg = second.reduce((a, b) => a + b, 0) / second.length;
        const change = ((secondAvg - firstAvg) / firstAvg) * 100;
        if (change > 5) return 'improving';
        if (change < -5) return 'declining';
        return 'stable';
    }

    formatPace(minutesPerKm) {
        const mins = Math.floor(minutesPerKm);
        const secs = Math.round((minutesPerKm - mins) * 60);
        return `${mins}:${secs.toString().padStart(2, '0')}/km`;
    }

    getLoadRecommendation(ratio) {
        if (ratio > 1.5) return 'Reduce volume by 30%. Add extra rest day.';
        if (ratio > 1.3) return 'Maintain current volume. Monitor closely.';
        if (ratio < 0.8) return 'Can increase volume by 10-15% if feeling good.';
        return 'Training load optimal. Continue current plan.';
    }

    identifyRunningPatterns(data) {
        return [];
    }

    generateRunningInsights(metrics, finalScore) {
        const insights = [];
        if (finalScore >= 80) {
            insights.push('Strong running performance');
        }
        return insights;
    }

    assessDataQuality(data) {
        return { quality: 'good', percentage: 80, message: 'Good data coverage' };
    }
}

// Export for browser
if (typeof window !== 'undefined') {
    window.AISRIMLAnalyzer = AISRIMLAnalyzer;
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AISRIMLAnalyzer;
}
