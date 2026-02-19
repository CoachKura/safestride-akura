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

    /**
     * Fetch recent Strava activities and calculate Running pillar
     */
    async syncStravaAndCalculateRunning(athleteId, stravaAccessToken) {
        try {
            // Fetch last 30 days of activities
            const activities = await this.fetchStravaActivities(stravaAccessToken, 30);
            
            // Extract relevant metrics
            const deviceData = this.extractStravaMetrics(activities);
            
            // Calculate Running pillar score
            const runningScore = this.aifri.calculateRunningPillarFromDeviceData(deviceData);
            
            // Update AISRI scores table
            await this.updateRunningPillar(athleteId, runningScore, deviceData);
            
            return {
                success: true,
                runningScore,
                activitiesProcessed: activities.length,
                deviceData
            };
        } catch (error) {
            console.error('Strava sync error:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Fetch Strava activities for last N days
     */
    async fetchStravaActivities(accessToken, days = 30) {
        const after = Math.floor((Date.now() - days * 24 * 60 * 60 * 1000) / 1000);
        
        const response = await fetch(
            `${this.endpoints.strava}/athlete/activities?after=${after}&per_page=100`,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
        );

        if (!response.ok) {
            throw new Error(`Strava API error: ${response.status}`);
        }

        return await response.json();
    }

    /**
     * Extract metrics from Strava activities for AIFRI calculation
     */
    extractStravaMetrics(activities) {
        if (!activities || activities.length === 0) {
            return this.getDefaultMetrics();
        }

        // Filter running activities
        const runs = activities.filter(a => a.type === 'Run');

        // Calculate average HRV from activities with heart rate data
        const activitiesWithHR = runs.filter(a => a.average_heartrate);
        const avgHR = activitiesWithHR.length > 0
            ? activitiesWithHR.reduce((sum, a) => sum + a.average_heartrate, 0) / activitiesWithHR.length
            : 0;

        // Calculate recent paces (min/km) for last 10 runs
        const recentPaces = runs.slice(0, 10).map(a => {
            const paceSeconds = a.moving_time / (a.distance / 1000);
            return paceSeconds;
        });

        // Calculate weekly distance (sum of last 7 days)
        const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
        const weeklyDistance = runs
            .filter(a => new Date(a.start_date).getTime() > weekAgo)
            .reduce((sum, a) => sum + (a.distance / 1000), 0);

        // Calculate consistency (how many weeks with 3+ runs in last 12 weeks)
        const consistencyWeeks = this.calculateConsistencyWeeks(runs);

        // Normalize HRV (inverse relationship: lower HR during runs = better)
        // Assume max HR ~180, resting ~50, so reserve ~130
        const normalizedHRV = avgHR > 0 ? Math.max(0, 100 - ((avgHR - 130) / 130 * 100)) : 50;

        // Recovery status from suffer score / kudos_count (proxy)
        const avgSufferScore = runs.slice(0, 5).reduce((sum, a) => sum + (a.suffer_score || 50), 0) / Math.min(5, runs.length);
        const recoveryStatus = Math.max(0, 100 - avgSufferScore);

        // Load history (training load balance)
        const loadHistory = this.calculateLoadBalance(runs);

        return {
            hrv: Math.round(normalizedHRV),
            recoveryStatus: Math.round(recoveryStatus),
            loadHistory: Math.round(loadHistory),
            sleepQuality: 50, // Strava doesn't provide sleep data
            subjectiveFeel: 50, // Default - would need manual input
            recentPaces,
            weeklyDistance: Math.round(weeklyDistance),
            consistencyWeeks,
            totalActivities: runs.length,
            avgHeartRate: Math.round(avgHR)
        };
    }

    /**
     * Calculate consistency weeks (weeks with 3+ runs in last 12 weeks)
     */
    calculateConsistencyWeeks(runs) {
        const weeks = {};
        const twelveWeeksAgo = Date.now() - 12 * 7 * 24 * 60 * 60 * 1000;

        runs.forEach(run => {
            const runDate = new Date(run.start_date);
            if (runDate.getTime() > twelveWeeksAgo) {
                const weekKey = `${runDate.getFullYear()}-W${Math.ceil(runDate.getDate() / 7)}`;
                weeks[weekKey] = (weeks[weekKey] || 0) + 1;
            }
        });

        return Object.values(weeks).filter(count => count >= 3).length;
    }

    /**
     * Calculate training load balance (recent vs baseline)
     */
    calculateLoadBalance(runs) {
        if (runs.length < 10) return 50;

        const recentLoad = runs.slice(0, 5).reduce((sum, a) => sum + a.distance, 0);
        const baselineLoad = runs.slice(5, 10).reduce((sum, a) => sum + a.distance, 0);

        if (baselineLoad === 0) return 50;

        const ratio = recentLoad / baselineLoad;
        
        // Ideal ratio: 0.9-1.1 (steady state)
        if (ratio >= 0.9 && ratio <= 1.1) return 90;
        if (ratio >= 0.8 && ratio <= 1.2) return 75;
        if (ratio >= 0.7 && ratio <= 1.3) return 60;
        return 50;
    }

    /**
     * Get default metrics when no data available
     */
    getDefaultMetrics() {
        return {
            hrv: 50,
            recoveryStatus: 50,
            loadHistory: 50,
            sleepQuality: 50,
            subjectiveFeel: 50,
            recentPaces: [],
            weeklyDistance: 0,
            consistencyWeeks: 0
        };
    }

    /**
     * Update Running pillar in aisri_scores table
     */
    async updateRunningPillar(athleteId, runningScore, deviceData) {
        // Get current AISRI scores
        const { data: currentScores, error: fetchError } = await this.supabase
            .from('aisri_scores')
            .select('*')
            .eq('athlete_id', athleteId)
            .order('assessment_date', { ascending: false })
            .limit(1)
            .single();

        if (fetchError && fetchError.code !== 'PGRST116') {
            throw new Error(`Failed to fetch current scores: ${fetchError.message}`);
        }

        // Calculate new total AIFRI score
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

        // Insert or update score
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
                assessment_notes: `Auto-calculated from Strava data. ${deviceData.totalActivities} activities analyzed.`
            }, {
                onConflict: 'athlete_id,assessment_date'
            });

        if (error) {
            throw new Error(`Failed to update scores: ${error.message}`);
        }

        return data;
    }

    /**
     * Fetch Garmin activities (similar structure)
     */
    async syncGarminAndCalculateRunning(athleteId, garminAccessToken) {
        try {
            // Similar implementation for Garmin Connect API
            // Garmin provides more detailed HRV, sleep, and recovery data
            
            const activities = await this.fetchGarminActivities(garminAccessToken, 30);
            const deviceData = this.extractGarminMetrics(activities);
            const runningScore = this.aifri.calculateRunningPillarFromDeviceData(deviceData);
            
            await this.updateRunningPillar(athleteId, runningScore, deviceData);
            
            return {
                success: true,
                runningScore,
                activitiesProcessed: activities.length,
                deviceData
            };
        } catch (error) {
            console.error('Garmin sync error:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Fetch Garmin activities
     */
    async fetchGarminActivities(accessToken, days = 30) {
        // Garmin Connect API endpoint
        const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        const endDate = new Date().toISOString().split('T')[0];
        
        const response = await fetch(
            `${this.endpoints.garmin}/wellness-api/rest/activities?uploadStartTimeInGMT=${startDate}&uploadEndTimeInGMT=${endDate}`,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
        );

        if (!response.ok) {
            throw new Error(`Garmin API error: ${response.status}`);
        }

        return await response.json();
    }

    /**
     * Extract metrics from Garmin activities
     * Garmin provides richer data: HRV, sleep, recovery time, training effect
     */
    extractGarminMetrics(activities) {
        if (!activities || activities.length === 0) {
            return this.getDefaultMetrics();
        }

        // Garmin provides actual HRV data
        const avgHRV = activities
            .filter(a => a.hrv)
            .reduce((sum, a) => sum + a.hrv, 0) / activities.filter(a => a.hrv).length || 50;

        // Garmin provides recovery time
        const recoveryStatus = 100 - Math.min(100, (activities[0]?.recoveryTime || 0) / 72 * 100);

        // Garmin provides training load
        const loadHistory = activities[0]?.trainingLoad || 50;

        // Garmin provides sleep data
        const sleepQuality = activities
            .filter(a => a.sleepScore)
            .reduce((sum, a) => sum + a.sleepScore, 0) / activities.filter(a => a.sleepScore).length || 50;

        // Rest similar to Strava
        const runs = activities.filter(a => a.activityType === 'RUNNING');
        const recentPaces = runs.slice(0, 10).map(a => a.duration / (a.distance / 1000));
        const weeklyDistance = runs.slice(0, 7).reduce((sum, a) => sum + (a.distance / 1000), 0);
        const consistencyWeeks = this.calculateConsistencyWeeks(runs);

        return {
            hrv: Math.round(avgHRV),
            recoveryStatus: Math.round(recoveryStatus),
            loadHistory: Math.round(loadHistory),
            sleepQuality: Math.round(sleepQuality),
            subjectiveFeel: 50, // Would need manual input
            recentPaces,
            weeklyDistance: Math.round(weeklyDistance),
            consistencyWeeks,
            totalActivities: runs.length
        };
    }

    /**
     * Auto-sync for athlete (call this daily via cron or manually)
     */
    async autoSyncAllDevices(athleteId) {
        const results = { strava: null, garmin: null };

        // Get athlete's connected devices from profiles table
        const { data: profile, error } = await this.supabase
            .from('profiles')
            .select('strava_access_token, garmin_access_token')
            .eq('id', athleteId)
            .single();

        if (error) {
            throw new Error(`Failed to fetch athlete profile: ${error.message}`);
        }

        // Sync Strava if connected
        if (profile.strava_access_token) {
            results.strava = await this.syncStravaAndCalculateRunning(
                athleteId,
                profile.strava_access_token
            );
        }

        // Sync Garmin if connected
        if (profile.garmin_access_token) {
            results.garmin = await this.syncGarminAndCalculateRunning(
                athleteId,
                profile.garmin_access_token
            );
        }

        return results;
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DeviceAIFRIConnector;
}
