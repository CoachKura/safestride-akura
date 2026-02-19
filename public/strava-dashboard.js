/**
 * SafeStride Strava Dashboard
 * Integrates Strava data with AISRI scoring and role-based access
 */

class SafeStrideDashboard {
    constructor() {
        this.config = window.SAFESTRIDE_CONFIG;
        this.athleteData = null;
        this.stravaData = null;
        this.aisriData = null;
        this.role = null;
        this.uid = null;
        
        this.init();
    }

    async init() {
        console.log('🚀 SafeStride Dashboard initializing...');
        
        // Get session info
        const session = this.getSession();
        if (!session) {
            console.warn('⚠️ No session found, redirecting to login...');
            window.location.href = '/login.html';
            return;
        }

        this.uid = session.uid;
        this.role = session.role;
        
        // Update role badge
        this.updateRoleBadge();
        
        // Load all data
        await this.loadDashboard();
        
        // Setup event listeners
        this.setupEventListeners();
        
        console.log('✅ Dashboard initialized');
    }

    getSession() {
        const sessionToken = sessionStorage.getItem(this.config.session.tokenKey);
        if (!sessionToken) return null;
        
        try {
            const payload = JSON.parse(atob(sessionToken.split('.')[1]));
            return payload;
        } catch (error) {
            console.error('❌ Invalid session token:', error);
            return null;
        }
    }

    updateRoleBadge() {
        const badge = document.getElementById('roleBadge');
        const roleText = document.getElementById('roleText');
        
        const roleConfig = {
            admin: { text: 'Admin', class: 'role-admin', icon: 'fa-user-shield' },
            coach: { text: 'Coach', class: 'role-coach', icon: 'fa-user-tie' },
            athlete: { text: 'Athlete', class: 'role-athlete', icon: 'fa-running' }
        };
        
        const config = roleConfig[this.role] || roleConfig.athlete;
        
        badge.className = `role-badge ${config.class}`;
        roleText.innerHTML = `<i class="fas ${config.icon}"></i> ${config.text}`;
        badge.style.display = 'block';
    }

    async loadDashboard() {
        try {
            // Show loading state
            document.getElementById('loadingState').style.display = 'block';
            document.getElementById('dashboardContent').style.display = 'none';
            
            // Load data in parallel
            const [athleteData, stravaData, aisriData] = await Promise.all([
                this.loadAthleteData(),
                this.loadStravaData(),
                this.loadAISRIData()
            ]);
            
            this.athleteData = athleteData;
            this.stravaData = stravaData;
            this.aisriData = aisriData;
            
            // Render all sections
            this.renderAthleteInfo();
            this.renderStravaStatus();
            this.renderQuickStats();
            this.renderAISRIScore();
            this.renderRecentActivities();
            this.renderTrainingZones();
            this.renderAIInsights();
            
            // Hide loading, show content
            document.getElementById('loadingState').style.display = 'none';
            document.getElementById('dashboardContent').style.display = 'block';
            
            console.log('✅ Dashboard loaded successfully');
        } catch (error) {
            console.error('❌ Error loading dashboard:', error);
            this.showError('Failed to load dashboard. Please refresh the page.');
        }
    }

    async loadAthleteData() {
        try {
            const response = await fetch(
                `${this.config.supabase.url}/rest/v1/athletes?uid=eq.${this.uid}&select=*`,
                {
                    headers: {
                        'apikey': this.config.supabase.anonKey,
                        'Authorization': `Bearer ${sessionStorage.getItem(this.config.session.tokenKey)}`
                    }
                }
            );

            if (!response.ok) {
                throw new Error(`Failed to load athlete data: ${response.statusText}`);
            }

            const data = await response.json();
            return data[0] || null;
        } catch (error) {
            console.error('❌ Error loading athlete data:', error);
            return null;
        }
    }

    async loadStravaData() {
        try {
            // Check Strava connection
            const connResponse = await fetch(
                `${this.config.supabase.url}/rest/v1/strava_connections?athlete_id=eq.${this.uid}&select=*`,
                {
                    headers: {
                        'apikey': this.config.supabase.anonKey,
                        'Authorization': `Bearer ${sessionStorage.getItem(this.config.session.tokenKey)}`
                    }
                }
            );

            if (!connResponse.ok) {
                console.warn('⚠️ No Strava connection found');
                return { connected: false, activities: [] };
            }

            const connections = await connResponse.json();
            if (!connections || connections.length === 0) {
                return { connected: false, activities: [] };
            }

            // Load activities
            const actResponse = await fetch(
                `${this.config.supabase.url}/rest/v1/strava_activities?athlete_id=eq.${this.uid}&select=*&order=start_date.desc&limit=10`,
                {
                    headers: {
                        'apikey': this.config.supabase.anonKey,
                        'Authorization': `Bearer ${sessionStorage.getItem(this.config.session.tokenKey)}`
                    }
                }
            );

            const activities = actResponse.ok ? await actResponse.json() : [];
            
            return {
                connected: true,
                connection: connections[0],
                activities: activities
            };
        } catch (error) {
            console.error('❌ Error loading Strava data:', error);
            return { connected: false, activities: [] };
        }
    }

    async loadAISRIData() {
        try {
            const response = await fetch(
                `${this.config.supabase.url}/rest/v1/aisri_scores?athlete_id=eq.${this.uid}&select=*&order=calculated_at.desc&limit=1`,
                {
                    headers: {
                        'apikey': this.config.supabase.anonKey,
                        'Authorization': `Bearer ${sessionStorage.getItem(this.config.session.tokenKey)}`
                    }
                }
            );

            if (!response.ok) {
                console.warn('⚠️ No AISRI scores found');
                return null;
            }

            const scores = await response.json();
            return scores[0] || null;
        } catch (error) {
            console.error('❌ Error loading AISRI data:', error);
            return null;
        }
    }

    renderAthleteInfo() {
        if (this.athleteData) {
            document.getElementById('athleteName').textContent = 
                this.athleteData.name || 'Unknown Athlete';
            document.getElementById('athleteEmail').textContent = 
                this.athleteData.email || this.uid;
        }
    }

    renderStravaStatus() {
        const statusEl = document.getElementById('stravaStatus');
        
        if (this.stravaData && this.stravaData.connected) {
            statusEl.innerHTML = `
                <span class="stat-highlight" style="background: #d4edda; color: #155724;">
                    <i class="fas fa-check-circle"></i> Connected
                </span>
            `;
        } else {
            statusEl.innerHTML = `
                <button id="connectStravaBtn" class="stat-highlight" style="background: #fc4c02; color: white; cursor: pointer; border: none;">
                    <i class="fab fa-strava"></i> Connect Strava
                </button>
            `;
            
            // Add click handler
            setTimeout(() => {
                const btn = document.getElementById('connectStravaBtn');
                if (btn) {
                    btn.addEventListener('click', () => this.connectStrava());
                }
            }, 100);
        }
    }

    renderQuickStats() {
        if (!this.stravaData || !this.stravaData.activities || this.stravaData.activities.length === 0) {
            document.getElementById('totalActivities').textContent = '0';
            document.getElementById('totalDistance').textContent = '0 km';
            document.getElementById('totalTime').textContent = '0h 0m';
            document.getElementById('avgPace').textContent = '0:00';
            return;
        }

        const activities = this.stravaData.activities;
        
        // Total activities
        document.getElementById('totalActivities').textContent = activities.length;
        
        // Total distance (in km)
        const totalDistance = activities.reduce((sum, act) => {
            return sum + (parseFloat(act.distance_km) || 0);
        }, 0);
        document.getElementById('totalDistance').textContent = totalDistance.toFixed(1);
        
        // Total time
        const totalSeconds = activities.reduce((sum, act) => {
            return sum + (parseInt(act.duration_seconds) || 0);
        }, 0);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        document.getElementById('totalTime').textContent = `${hours}h ${minutes}m`;
        
        // Average pace (min/km)
        if (totalDistance > 0 && totalSeconds > 0) {
            const avgPaceSeconds = totalSeconds / totalDistance / 60; // min/km
            const paceMin = Math.floor(avgPaceSeconds);
            const paceSec = Math.floor((avgPaceSeconds - paceMin) * 60);
            document.getElementById('avgPace').textContent = 
                `${paceMin}:${paceSec.toString().padStart(2, '0')}`;
        }
    }

    renderAISRIScore() {
        if (!this.aisriData) {
            document.getElementById('aisriScore').textContent = '--';
            document.getElementById('aisriRisk').textContent = 'No data yet';
            return;
        }

        const score = this.aisriData.total_score || 0;
        const risk = this.aisriData.risk_category || 'Unknown';
        const pillars = this.aisriData.pillar_scores || {};

        // Main score
        document.getElementById('aisriScore').textContent = Math.round(score);
        
        // Risk category with emoji
        const riskEmoji = {
            'Low Risk': '✅',
            'Medium Risk': '⚠️',
            'High Risk': '🔴',
            'Critical Risk': '🚨'
        };
        document.getElementById('aisriRisk').textContent = 
            `${riskEmoji[risk] || ''} ${risk}`;

        // Pillar scores
        const pillarMap = {
            running: { score: pillars.running || 0, bar: 'runningBar', text: 'runningScore' },
            strength: { score: pillars.strength || 0, bar: 'strengthBar', text: 'strengthScore' },
            rom: { score: pillars.rom || 0, bar: 'romBar', text: 'romScore' },
            balance: { score: pillars.balance || 0, bar: 'balanceBar', text: 'balanceScore' },
            alignment: { score: pillars.alignment || 0, bar: 'alignmentBar', text: 'alignmentScore' },
            mobility: { score: pillars.mobility || 0, bar: 'mobilityBar', text: 'mobilityScore' }
        };

        Object.keys(pillarMap).forEach(key => {
            const pillar = pillarMap[key];
            document.getElementById(pillar.bar).style.width = `${pillar.score}%`;
            document.getElementById(pillar.text).textContent = Math.round(pillar.score);
        });
    }

    renderRecentActivities() {
        const container = document.getElementById('recentActivities');
        
        if (!this.stravaData || !this.stravaData.activities || this.stravaData.activities.length === 0) {
            container.innerHTML = `
                <div class="text-center text-gray-500 py-8">
                    <i class="fas fa-inbox text-3xl mb-3"></i>
                    <p>No activities yet</p>
                    <p class="text-sm mt-1">Connect Strava to sync your activities</p>
                </div>
            `;
            return;
        }

        const activities = this.stravaData.activities.slice(0, 5); // Top 5
        
        container.innerHTML = activities.map(act => {
            const icon = this.getActivityIcon(act.activity_type);
            const date = new Date(act.start_date).toLocaleDateString('en-US', { 
                month: 'short', 
                day: 'numeric' 
            });
            const distance = (parseFloat(act.distance_km) || 0).toFixed(1);
            const duration = this.formatDuration(parseInt(act.duration_seconds) || 0);
            
            return `
                <div class="activity-item">
                    <div class="activity-icon">
                        <i class="${icon}"></i>
                    </div>
                    <div class="activity-details">
                        <div class="activity-name">${act.name || 'Untitled Activity'}</div>
                        <div class="activity-stats">
                            ${date} • ${distance} km • ${duration}
                        </div>
                    </div>
                </div>
            `;
        }).join('');
    }

    renderTrainingZones() {
        if (!this.aisriData) return;
        
        const score = this.aisriData.total_score || 0;
        
        // Update zone status based on AISRI score
        document.getElementById('arZone').textContent = '✅ Unlocked';
        document.getElementById('fZone').textContent = '✅ Unlocked';
        document.getElementById('enZone').textContent = score >= 40 ? '✅ Unlocked' : '🔒 Locked';
        document.getElementById('thZone').textContent = score >= 55 ? '✅ Unlocked' : '🔒 Locked';
        document.getElementById('pZone').textContent = score >= 70 ? '✅ Unlocked' : '🔒 Locked';
        document.getElementById('spZone').textContent = score >= 85 ? '✅ Unlocked' : '🔒 Locked';
    }

    renderAIInsights() {
        if (!this.stravaData || !this.stravaData.activities || this.stravaData.activities.length === 0) {
            document.getElementById('loadInsight').textContent = 'No data to analyze';
            document.getElementById('recoveryInsight').textContent = 'No data to analyze';
            document.getElementById('riskInsight').textContent = 'No data to analyze';
            return;
        }

        const recentActivity = this.stravaData.activities[0];
        const mlInsights = recentActivity.ml_insights || {};

        // Training load insight
        const trainingLoad = mlInsights.training_load || 50;
        let loadText = 'Moderate training load detected';
        if (trainingLoad < 40) loadText = 'Low training load - consider increasing volume';
        else if (trainingLoad > 70) loadText = 'High training load - ensure adequate recovery';
        document.getElementById('loadInsight').textContent = loadText;

        // Recovery insight
        const recoveryScore = mlInsights.recovery_score || 70;
        let recoveryText = 'Good recovery status';
        if (recoveryScore < 50) recoveryText = 'Poor recovery - rest recommended';
        else if (recoveryScore > 80) recoveryText = 'Excellent recovery - ready for hard training';
        document.getElementById('recoveryInsight').textContent = recoveryText;

        // Risk insight
        const riskCategory = this.aisriData?.risk_category || 'Unknown';
        let riskText = 'Continue monitoring your progress';
        if (riskCategory === 'High Risk' || riskCategory === 'Critical Risk') {
            riskText = 'Elevated injury risk detected - consult your coach';
        } else if (riskCategory === 'Low Risk') {
            riskText = 'Low injury risk - maintain current training';
        }
        document.getElementById('riskInsight').textContent = riskText;
    }

    // Helper methods
    getActivityIcon(type) {
        const icons = {
            'Run': 'fas fa-running',
            'Ride': 'fas fa-biking',
            'Swim': 'fas fa-swimmer',
            'Walk': 'fas fa-walking',
            'Hike': 'fas fa-hiking',
            'Workout': 'fas fa-dumbbell',
            'default': 'fas fa-heartbeat'
        };
        return icons[type] || icons.default;
    }

    formatDuration(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        
        if (hours > 0) {
            return `${hours}h ${minutes}m`;
        }
        return `${minutes}m`;
    }

    // Event handlers
    setupEventListeners() {
        // Logout
        document.getElementById('logoutBtn').addEventListener('click', () => {
            sessionStorage.clear();
            window.location.href = '/login.html';
        });

        // Sync Strava
        document.getElementById('syncBtn').addEventListener('click', () => {
            this.syncStravaActivities();
        });
    }

    connectStrava() {
        const state = Math.random().toString(36).substring(7);
        sessionStorage.setItem('strava_oauth_state', state);
        
        const authUrl = new URL(this.config.strava.authorizeUrl);
        authUrl.searchParams.append('client_id', this.config.strava.clientId);
        authUrl.searchParams.append('redirect_uri', this.config.strava.redirectUri);
        authUrl.searchParams.append('response_type', 'code');
        authUrl.searchParams.append('scope', this.config.strava.scope);
        authUrl.searchParams.append('state', state);
        
        window.location.href = authUrl.toString();
    }

    async syncStravaActivities() {
        try {
            const btn = document.getElementById('syncBtn');
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-sync-alt fa-spin"></i> Syncing...';
            
            const response = await fetch(
                `${this.config.supabase.functionsUrl}/strava-sync-activities`,
                {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${sessionStorage.getItem(this.config.session.tokenKey)}`
                    },
                    body: JSON.stringify({
                        athleteId: this.uid,
                        daysBack: 30
                    })
                }
            );

            const result = await response.json();
            
            if (result.success) {
                this.showSuccess(`Synced ${result.count} activities successfully!`);
                // Reload dashboard
                await this.loadDashboard();
            } else {
                throw new Error(result.error || 'Sync failed');
            }
        } catch (error) {
            console.error('❌ Sync error:', error);
            this.showError('Failed to sync activities. Please try again.');
        } finally {
            const btn = document.getElementById('syncBtn');
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-sync-alt"></i> Sync Strava';
        }
    }

    showSuccess(message) {
        // Simple toast notification
        const toast = document.createElement('div');
        toast.className = 'fixed bottom-4 right-4 bg-green-500 text-white px-6 py-3 rounded-lg shadow-lg z-50';
        toast.innerHTML = `<i class="fas fa-check-circle mr-2"></i>${message}`;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            toast.remove();
        }, 3000);
    }

    showError(message) {
        // Simple toast notification
        const toast = document.createElement('div');
        toast.className = 'fixed bottom-4 right-4 bg-red-500 text-white px-6 py-3 rounded-lg shadow-lg z-50';
        toast.innerHTML = `<i class="fas fa-exclamation-circle mr-2"></i>${message}`;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            toast.remove();
        }, 5000);
    }
}

// Initialize dashboard when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        new SafeStrideDashboard();
    });
} else {
    new SafeStrideDashboard();
}
