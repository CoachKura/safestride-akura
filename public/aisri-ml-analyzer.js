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
     * PILLAR 2: Strength (15% of total AISRI)
     */
    calculateStrengthPillar(assessments) {
        if (!assessments || !assessments.strength) {
            return { score: 50, status: 'no_data', message: 'No strength assessment data' };
        }

        const data = assessments.strength;
        
        // Core strength metrics
        const plankTime = this.scoreMetric(data.plankSeconds, [30, 45, 60, 90, 120]);
        const singleLegSquat = this.scoreMetric(data.singleLegSquatReps, [5, 8, 12, 15, 20]);
        const calfRaise = this.scoreMetric(data.calfRaiseReps, [15, 20, 25, 30, 40]);
        const gluteBridge = this.scoreMetric(data.gluteBridgeReps, [10, 15, 20, 25, 30]);

        const avgScore = (plankTime + singleLegSquat + calfRaise + gluteBridge) / 4;

        return {
            score: Math.round(avgScore),
            status: this.getScoreStatus(avgScore),
            message: this.getStrengthMessage(avgScore),
            breakdown: {
                plankTime: { score: plankTime, value: data.plankSeconds + 's' },
                singleLegSquat: { score: singleLegSquat, value: data.singleLegSquatReps + ' reps' },
                calfRaise: { score: calfRaise, value: data.calfRaiseReps + ' reps' },
                gluteBridge: { score: gluteBridge, value: data.gluteBridgeReps + ' reps' }
            }
        };
    }

    /**
     * PILLAR 3: ROM - Range of Motion (12% of total AISRI)
     */
    calculateROMPillar(assessments) {
        if (!assessments || !assessments.rom) {
            return { score: 50, status: 'no_data', message: 'No ROM assessment data' };
        }

        const data = assessments.rom;

        // ROM metrics (degrees)
        const ankleDF = this.scoreMetric(data.ankleDorsiflexion, [10, 15, 20, 25, 30]);
        const hipFlexion = this.scoreMetric(data.hipFlexion, [90, 100, 110, 120, 130]);
        const hamstring = this.scoreMetric(data.hamstringFlexibility, [60, 70, 80, 90, 100]);
        const hipRotation = this.scoreMetric(data.hipRotation, [30, 35, 40, 45, 50]);

        const avgScore = (ankleDF + hipFlexion + hamstring + hipRotation) / 4;

        return {
            score: Math.round(avgScore),
            status: this.getScoreStatus(avgScore),
            message: this.getROMMessage(avgScore),
            breakdown: {
                ankleDorsiflexion: { score: ankleDF, value: data.ankleDorsiflexion + '°' },
                hipFlexion: { score: hipFlexion, value: data.hipFlexion + '°' },
                hamstringFlexibility: { score: hamstring, value: data.hamstringFlexibility + '°' },
                hipRotation: { score: hipRotation, value: data.hipRotation + '°' }
            }
        };
    }

    /**
     * PILLAR 4: Balance (13% of total AISRI)
     */
    calculateBalancePillar(assessments) {
        if (!assessments || !assessments.balance) {
            return { score: 50, status: 'no_data', message: 'No balance assessment data' };
        }

        const data = assessments.balance;

        // Balance metrics (seconds)
        const singleLegStand = this.scoreMetric(data.singleLegStandSeconds, [15, 30, 45, 60, 90]);
        const eyesClosed = this.scoreMetric(data.eyesClosedSeconds, [10, 20, 30, 45, 60]);
        const Y_Balance = this.scoreMetric(data.yBalanceScore, [70, 80, 90, 95, 100]);

        const avgScore = (singleLegStand + eyesClosed + Y_Balance) / 3;

        return {
            score: Math.round(avgScore),
            status: this.getScoreStatus(avgScore),
            message: this.getBalanceMessage(avgScore),
            breakdown: {
                singleLegStand: { score: singleLegStand, value: data.singleLegStandSeconds + 's' },
                eyesClosed: { score: eyesClosed, value: data.eyesClosedSeconds + 's' },
                yBalance: { score: Y_Balance, value: data.yBalanceScore + '%' }
            }
        };
    }

    /**
     * PILLAR 5: Alignment (10% of total AISRI) - NEW PILLAR
     */
    calculateAlignmentPillar(assessments) {
        if (!assessments || !assessments.alignment) {
            return { score: 50, status: 'no_data', message: 'No alignment assessment data' };
        }

        const data = assessments.alignment;

        // Alignment metrics
        const postureScore = this.scoreMetric(data.postureScore, [50, 65, 75, 85, 95]);
        const gaitSymmetry = this.scoreMetric(data.gaitSymmetry, [70, 80, 90, 95, 100]);
        const pelvisAlignment = this.scoreMetric(data.pelvisAlignment, [60, 70, 80, 90, 100]);
        const footStrike = this.scoreMetric(data.footStrikeScore, [60, 70, 80, 90, 100]);

        const avgScore = (postureScore + gaitSymmetry + pelvisAlignment + footStrike) / 4;

        return {
            score: Math.round(avgScore),
            status: this.getScoreStatus(avgScore),
            message: this.getAlignmentMessage(avgScore),
            breakdown: {
                posture: { score: postureScore, value: data.postureScore + '%' },
                gaitSymmetry: { score: gaitSymmetry, value: data.gaitSymmetry + '%' },
                pelvisAlignment: { score: pelvisAlignment, value: data.pelvisAlignment + '%' },
                footStrike: { score: footStrike, value: data.footStrikeScore + '%' }
            }
        };
    }

    /**
     * PILLAR 6: Mobility (10% of total AISRI)
     */
    calculateMobilityPillar(assessments) {
        if (!assessments || !assessments.mobility) {
            return { score: 50, status: 'no_data', message: 'No mobility assessment data' };
        }

        const data = assessments.mobility;

        // Mobility metrics
        const hipMobility = this.scoreMetric(data.hipMobility, [60, 70, 80, 90, 100]);
        const ankleMobility = this.scoreMetric(data.ankleMobility, [60, 70, 80, 90, 100]);
        const thoracicRotation = this.scoreMetric(data.thoracicRotation, [40, 50, 60, 70, 80]);
        const shoulderMobility = this.scoreMetric(data.shoulderMobility, [60, 70, 80, 90, 100]);

        const avgScore = (hipMobility + ankleMobility + thoracicRotation + shoulderMobility) / 4;

        return {
            score: Math.round(avgScore),
            status: this.getScoreStatus(avgScore),
            message: this.getMobilityMessage(avgScore),
            breakdown: {
                hipMobility: { score: hipMobility, value: data.hipMobility + '%' },
                ankleMobility: { score: ankleMobility, value: data.ankleMobility + '%' },
                thoracicRotation: { score: thoracicRotation, value: data.thoracicRotation + '°' },
                shoulderMobility: { score: shoulderMobility, value: data.shoulderMobility + '%' }
            }
        };
    }

    /**
     * Calculate Total AISRI Score (0-100)
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
            category = 'low';
            label = 'Low Risk';
            color = '#10b981'; // green
            zones = ['AR', 'F', 'EN', 'TH', 'P', 'SP'];
        } else if (totalScore >= 70) {
            category = 'low';
            label = 'Low Risk';
            color = '#10b981';
            zones = ['AR', 'F', 'EN', 'TH', 'P'];
        } else if (totalScore >= 55) {
            category = 'medium';
            label = 'Medium Risk';
            color = '#f59e0b'; // yellow
            zones = ['AR', 'F', 'EN', 'TH'];
        } else if (totalScore >= 40) {
            category = 'high';
            label = 'High Risk';
            color = '#f97316'; // orange
            zones = ['AR', 'F', 'EN'];
        } else {
            category = 'critical';
            label = 'Critical Risk';
            color = '#ef4444'; // red
            zones = ['AR', 'F'];
        }

        // Check for training load risk override
        if (runningPillar.breakdown.trainingLoad.risk === 'high') {
            label += ' (Training Load Alert!)';
            color = '#dc2626'; // darker red
        }

        return { category, label, color, zones, score: totalScore };
    }

    /**
     * Generate ML Insights
     */
    generateMLInsights(data) {
        const insights = [];

        // Pattern 1: Training Load vs Recovery
        if (data.runningPillar.breakdown.trainingLoad.ratio > 1.3 && 
            data.runningPillar.breakdown.recovery.score < 60) {
            insights.push({
                type: 'warning',
                title: 'High Load + Poor Recovery',
                message: 'Training load spike detected while recovery is suboptimal. High injury risk.',
                action: 'Reduce intensity by 20-30% this week. Focus on sleep and nutrition.',
                priority: 'high'
            });
        }

        // Pattern 2: Weak Pillar Detection
        const weakPillars = [];
        Object.entries(data).forEach(([key, pillar]) => {
            if (key.includes('Pillar') && pillar.score < 55) {
                weakPillars.push({ name: key.replace('Pillar', ''), score: pillar.score });
            }
        });

        if (weakPillars.length > 0) {
            insights.push({
                type: 'alert',
                title: 'Weak Pillars Detected',
                message: `Focus areas: ${weakPillars.map(p => p.name).join(', ')}`,
                action: 'Add targeted strength/mobility work 2-3x per week',
                priority: 'medium',
                details: weakPillars
            });
        }

        // Pattern 3: Positive Momentum
        if (data.runningPillar.breakdown.paceBonus.bonus >= 7 &&
            data.runningPillar.breakdown.consistencyBonus.bonus >= 8) {
            insights.push({
                type: 'success',
                title: 'Excellent Progress',
                message: 'Strong pace improvement with consistent training!',
                action: 'Maintain current approach. Consider adding one hard session.',
                priority: 'low'
            });
        }

        // Pattern 4: Sleep Deficit
        if (data.runningPillar.breakdown.sleep.score < 50) {
            insights.push({
                type: 'warning',
                title: 'Sleep Deficit Detected',
                message: 'Poor sleep is limiting recovery and performance.',
                action: 'Prioritize 7-9 hours sleep. Consider reducing training volume by 15%.',
                priority: 'high'
            });
        }

        // Pattern 5: HRV Trend
        const hrvTrend = data.runningPillar.breakdown.hrv.trend;
        if (hrvTrend === 'declining') {
            insights.push({
                type: 'alert',
                title: 'Declining HRV Trend',
                message: 'HRV trending down - possible overtraining or illness.',
                action: 'Monitor closely. Add 1-2 easy days this week.',
                priority: 'medium'
            });
        }

        return insights;
    }

    /**
     * Generate Training Recommendations
     */
    generateRecommendations(mlInsights) {
        const recommendations = {
            immediate: [],
            shortTerm: [],
            longTerm: []
        };

        mlInsights.forEach(insight => {
            if (insight.priority === 'high') {
                recommendations.immediate.push(insight.action);
            } else if (insight.priority === 'medium') {
                recommendations.shortTerm.push(insight.action);
            } else {
                recommendations.longTerm.push(insight.action);
            }
        });

        return recommendations;
    }

    // ============== HELPER FUNCTIONS ==============

    extractDeviceData(athleteData) {
        // Extract and clean Strava/Garmin data
        return {
            hrv: athleteData.hrv || { values: [], baseline: 50 },
            recovery: athleteData.recovery || { score: 60 },
            load: athleteData.trainingLoad || { acute: 500, chronic: 500 },
            sleep: athleteData.sleep || { avgHours: 7, quality: 70 },
            feel: athleteData.feel || { ratings: [7, 7, 7] },
            activities: athleteData.activities || []
        };
    }

    scoreMetric(value, thresholds) {
        // Convert metric value to 0-100 score based on thresholds
        if (!value) return 50;
        
        if (value >= thresholds[4]) return 95;
        if (value >= thresholds[3]) return 85;
        if (value >= thresholds[2]) return 70;
        if (value >= thresholds[1]) return 55;
        if (value >= thresholds[0]) return 40;
        return 25;
    }

    getScoreStatus(score) {
        if (score >= 85) return 'excellent';
        if (score >= 70) return 'good';
        if (score >= 55) return 'moderate';
        if (score >= 40) return 'poor';
        return 'critical';
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
        // ML pattern recognition (simplified)
        const patterns = [];
        
        // Check for overtraining
        if (data.load && data.load.acute / data.load.chronic > 1.4 &&
            data.recovery && data.recovery.score < 60) {
            patterns.push({ type: 'overtraining', confidence: 0.85 });
        }
        
        // Check for positive adaptation
        if (data.activities && data.activities.length >= 12) {
            const recentPaces = data.activities.slice(-6).map(a => a.averagePace);
            const olderPaces = data.activities.slice(-12, -6).map(a => a.averagePace);
            
            const recentAvg = recentPaces.reduce((a, b) => a + b, 0) / recentPaces.length;
            const olderAvg = olderPaces.reduce((a, b) => a + b, 0) / olderPaces.length;
            
            if (recentAvg < olderAvg) {
                patterns.push({ type: 'positive_adaptation', confidence: 0.75 });
            }
        }
        
        return patterns;
    }

    generateRunningInsights(metrics, finalScore) {
        const insights = [];
        
        if (finalScore >= 80) {
            insights.push('Strong running performance - ready for challenging workouts');
        } else if (finalScore >= 65) {
            insights.push('Good running form - maintain consistency');
        } else if (finalScore >= 50) {
            insights.push('Moderate performance - focus on recovery');
        } else {
            insights.push('Performance concerns - prioritize rest and base building');
        }
        
        return insights;
    }

    getStrengthMessage(score) {
        if (score >= 85) return 'Excellent strength - injury risk minimized';
        if (score >= 70) return 'Good strength foundation';
        if (score >= 55) return 'Adequate strength - room for improvement';
        if (score >= 40) return 'Weak strength - high injury risk';
        return 'Critical strength deficit - urgent improvement needed';
    }

    getROMMessage(score) {
        if (score >= 85) return 'Excellent range of motion';
        if (score >= 70) return 'Good flexibility';
        if (score >= 55) return 'Moderate ROM - focus on stretching';
        if (score >= 40) return 'Limited ROM - injury risk elevated';
        return 'Severely restricted ROM - urgent mobility work needed';
    }

    getBalanceMessage(score) {
        if (score >= 85) return 'Excellent balance and stability';
        if (score >= 70) return 'Good balance control';
        if (score >= 55) return 'Moderate balance - add single-leg work';
        if (score >= 40) return 'Poor balance - injury risk present';
        return 'Critical balance deficit - urgent stability training needed';
    }

    getAlignmentMessage(score) {
        if (score >= 85) return 'Excellent biomechanical alignment';
        if (score >= 70) return 'Good posture and gait symmetry';
        if (score >= 55) return 'Moderate alignment - some compensations present';
        if (score >= 40) return 'Poor alignment - biomechanical stress evident';
        return 'Critical alignment issues - urgent correction needed';
    }

    getMobilityMessage(score) {
        if (score >= 85) return 'Excellent mobility across all joints';
        if (score >= 70) return 'Good overall mobility';
        if (score >= 55) return 'Moderate mobility - regular stretching advised';
        if (score >= 40) return 'Limited mobility - injury risk present';
        return 'Severely restricted mobility - urgent work needed';
    }

    assessDataQuality(data) {
        let score = 0;
        let maxScore = 0;
        
        const fields = ['hrv', 'recovery', 'load', 'sleep', 'feel', 'activities'];
        fields.forEach(field => {
            maxScore += 20;
            if (data[field]) {
                if (Array.isArray(data[field]) && data[field].length > 0) score += 20;
                else if (typeof data[field] === 'object' && Object.keys(data[field]).length > 0) score += 20;
            }
        });
        
        const percentage = (score / maxScore) * 100;
        let quality, message;
        
        if (percentage >= 80) {
            quality = 'excellent';
            message = 'Comprehensive data available for accurate analysis';
        } else if (percentage >= 60) {
            quality = 'good';
            message = 'Good data coverage - minor gaps present';
        } else if (percentage >= 40) {
            quality = 'moderate';
            message = 'Moderate data - some metrics missing';
        } else {
            quality = 'poor';
            message = 'Limited data - analysis may be less accurate';
        }
        
        return { quality, percentage: Math.round(percentage), message };
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AISRIMLAnalyzer;
}
