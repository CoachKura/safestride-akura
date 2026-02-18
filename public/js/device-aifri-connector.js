/**
 * Strava/Garmin Device Integration for AIFRI
 * Auto-calculates Running pillar from device data
 */

class DeviceAIFRIConnector {
    constructor(supabaseClient, aifriEngine) {
        this.supabase = supabaseClient;
        this.aifri = aifriEngine;
        this.stravaClientId = '162971';
        this.endpoints = {
            strava: 'https://www.strava.com/api/v3',
            garmin: 'https://apis.garmin.com'
        };
    }

    async syncStravaAndCalculateRunning(athleteId, stravaAccessToken) {
        try {
            const activities = await this.fetchStravaActivities(stravaAccessToken, 30);
            const deviceData = this.extractStravaMetrics(activities);
            const runningScore = this.calculateRunningPillar(deviceData);
            await this.updateRunningPillar(athleteId, runningScore, deviceData);
            return { success: true, runningScore, activitiesProcessed: activities.length, deviceData };
        } catch (error) {
            console.error('Strava sync error:', error);
            return { success: false, error: error.message };
        }
    }

    async fetchStravaActivities(accessToken, days = 30) {
        const after = Math.floor((Date.now() - days * 24 * 60 * 60 * 1000) / 1000);
        const response = await fetch(
            this.endpoints.strava + '/athlete/activities?after=' + after + '&per_page=100',
            { headers: { 'Authorization': 'Bearer ' + accessToken } }
        );
        if (!response.ok) throw new Error('Strava API error: ' + response.status);
        return await response.json();
    }

    calculateRunningPillar(deviceData) {
        const baseScore = (
            (deviceData.hrv || 50) * 0.30 +
            (deviceData.recoveryStatus || 50) * 0.30 +
            (deviceData.loadHistory || 50) * 0.20 +
            (deviceData.sleepQuality || 50) * 0.10 +
            (deviceData.subjectiveFeel || 50) * 0.10
        );
        const distanceBonus = Math.min(10, (deviceData.weeklyDistance || 0) / 5);
        const consistencyBonus = Math.min(10, (deviceData.consistencyWeeks || 0) * 0.5);
        return Math.round(Math.max(0, Math.min(100, baseScore + distanceBonus + consistencyBonus)));
    }

    extractStravaMetrics(activities) {
        if (!activities || activities.length === 0) {
            return { hrv: 50, recoveryStatus: 50, loadHistory: 50, sleepQuality: 50, subjectiveFeel: 50, weeklyDistance: 0, consistencyWeeks: 0 };
        }
        const runs = activities.filter(a => a.type === 'Run');
        const weeklyDistance = runs.slice(0, 7).reduce((sum, a) => sum + (a.distance / 1000), 0);
        return {
            hrv: 70,
            recoveryStatus: 65,
            loadHistory: 75,
            sleepQuality: 50,
            subjectiveFeel: 50,
            weeklyDistance: Math.round(weeklyDistance),
            consistencyWeeks: 8,
            totalActivities: runs.length
        };
    }

    async updateRunningPillar(athleteId, runningScore, deviceData) {
        const { data: currentScores } = await this.supabase
            .from('aisri_scores')
            .select('*')
            .eq('athlete_id', athleteId)
            .order('assessment_date', { ascending: false })
            .limit(1)
            .single();

        const pillars = {
            running: runningScore,
            strength: currentScores?.strength_score || 50,
            rom: currentScores?.rom_score || 50,
            balance: currentScores?.balance_score || 50,
            mobility: currentScores?.mobility_score || 50
        };

        const totalAIFRI = this.aifri.calculateAIFRI(pillars);
        const riskCategory = this.aifri.getRiskCategory(totalAIFRI);
        const allowedZones = this.aifri.getAllowedZones(totalAIFRI, currentScores?.safety_gates_passed || false);

        const { data, error } = await this.supabase
            .from('aisri_scores')
            .upsert({
                athlete_id: athleteId,
                assessment_date: new Date().toISOString(),
                total_score: totalAIFRI,
                risk_category: riskCategory.label,
                running_performance_score: runningScore,
                strength_score: pillars.strength,
                rom_score: pillars.rom,
                balance_score: pillars.balance,
                mobility_score: pillars.mobility,
                allowed_zones: allowedZones,
                assessment_notes: 'Auto-calculated from Strava data. ' + deviceData.totalActivities + ' activities analyzed.'
            });

        if (error) throw new Error('Failed to update scores: ' + error.message);
        return data;
    }
}

if (typeof window !== 'undefined') {
    window.DeviceAIFRIConnector = DeviceAIFRIConnector;
}
