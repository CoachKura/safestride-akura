/**
 * Strava Session Persistence Functions
 * Auto-checks for existing Strava connection on page load
 * Implements token refresh for expired tokens
 */

// Load Supabase client from config
const SUPABASE_URL = SAFESTRIDE_CONFIG?.supabase?.url || 'https://bdisppaxbvygsspcuymb.supabase.co';
const SUPABASE_ANON_KEY = SAFESTRIDE_CONFIG?.supabase?.anonKey;
const SUPABASE_FUNCTIONS_URL = SAFESTRIDE_CONFIG?.supabase?.functionsUrl;

// Initialize Supabase client
let supabaseClient = null;
if (typeof supabase !== 'undefined' && SUPABASE_URL && SUPABASE_ANON_KEY) {
    supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

/**
 * Check if user has an existing Strava connection in database
 * @returns {Object|null} Connection data if exists, null otherwise
 */
async function checkExistingStravaConnection() {
    try {
        console.log('🔍 Checking for existing Strava connection...');
        
        // Get current session
        const session = JSON.parse(sessionStorage.getItem('safestride_session') || '{}');
        const athleteId = session.uid || localStorage.getItem('athleteId');
        
        if (!athleteId) {
            console.log('❌ No athlete ID found in session');
            return null;
        }
        
        if (!supabaseClient) {
            console.error('❌ Supabase client not initialized');
            return null;
        }
        
        // Query database for existing connection
        const { data, error } = await supabaseClient
            .from('strava_connections')
            .select('*')
            .eq('athlete_id', athleteId)
            .single();
        
        if (error) {
            if (error.code === 'PGRST116') {
                // No rows returned - connection doesn't exist
                console.log('ℹ️ No Strava connection found for athlete:', athleteId);
            } else {
                console.error('❌ Database query error:', error);
            }
            return null;
        }
        
        console.log('✅ Found existing Strava connection:', {
            athlete_id: data.athlete_id,
            strava_athlete_id: data.strava_athlete_id,
            connected_at: data.created_at,
            expires_at: data.expires_at
        });
        
        // Check if token is expired
        const expiresAt = new Date(data.expires_at);
        const now = new Date();
        const isExpired = expiresAt < now;
        
        if (isExpired) {
            console.log('⚠️ Strava token expired, attempting refresh...');
            const refreshed = await refreshStravaToken(athleteId, data.refresh_token);
            
            if (refreshed) {
                // Reload connection data after refresh
                return await checkExistingStravaConnection();
            } else {
                console.error('❌ Token refresh failed, user needs to reconnect');
                return null;
            }
        }
        
        // Mark as connected in localStorage
        localStorage.setItem('strava_connected', 'true');
        localStorage.setItem('strava_athlete_id', data.strava_athlete_id);
        localStorage.setItem('strava_connected_at', data.created_at);
        
        return data;
        
    } catch (error) {
        console.error('❌ Error checking Strava connection:', error);
        return null;
    }
}

/**
 * Refresh expired Strava access token
 * @param {string} athleteId - Athlete ID
 * @param {string} refreshToken - Refresh token from database
 * @returns {boolean} True if refresh succeeded, false otherwise
 */
async function refreshStravaToken(athleteId, refreshToken) {
    try {
        console.log('🔄 Refreshing Strava token for athlete:', athleteId);
        
        const session = JSON.parse(sessionStorage.getItem('safestride_session') || '{}');
        
        const response = await fetch(`${SUPABASE_FUNCTIONS_URL}/strava-refresh-token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.token}`
            },
            body: JSON.stringify({
                athleteId: athleteId,
                refreshToken: refreshToken
            })
        });
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('❌ Token refresh failed:', errorText);
            return false;
        }
        
        const data = await response.json();
        
        if (!data.success) {
            console.error('❌ Token refresh unsuccessful:', data.error);
            return false;
        }
        
        console.log('✅ Token refreshed successfully, expires:', data.expires_at);
        return true;
        
    } catch (error) {
        console.error('❌ Error refreshing token:', error);
        return false;
    }
}

/**
 * Update UI based on Strava connection status
 * @param {Object|null} connectionData - Connection data from database
 */
function updateStravaConnectionUI(connectionData) {
    const connectBtn = document.getElementById('stravaConnect');
    const statusDiv = document.getElementById('stravaStatus');
    
    if (!connectBtn) {
        console.warn('⚠️ Connect Strava button not found in DOM');
        return;
    }
    
    if (connectionData) {
        // Already connected - show green checkmark
        connectBtn.innerHTML = `
            <i class="fas fa-check-circle mr-2"></i>
            Strava Connected
        `;
        connectBtn.className = 'px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 w-full transition duration-200';
        connectBtn.disabled = false;
        connectBtn.onclick = () => {
            alert(`Connected to Strava since ${new Date(connectionData.created_at).toLocaleDateString()}\n\nActivities are automatically synced.\n\nTo reconnect, please contact support.`);
        };
        
        // Update status message
        if (statusDiv) {
            const lastSync = new Date(connectionData.updated_at);
            const timeSince = Math.floor((new Date() - lastSync) / (1000 * 60)); // minutes
            
            let timeDisplay = '';
            if (timeSince < 60) {
                timeDisplay = `${timeSince} minute${timeSince !== 1 ? 's' : ''} ago`;
            } else if (timeSince < 1440) {
                const hours = Math.floor(timeSince / 60);
                timeDisplay = `${hours} hour${hours !== 1 ? 's' : ''} ago`;
            } else {
                const days = Math.floor(timeSince / 1440);
                timeDisplay = `${days} day${days !== 1 ? 's' : ''} ago`;
            }
            
            statusDiv.innerHTML = `
                <span class="text-green-600">
                    <i class="fas fa-sync-alt mr-2"></i>
                    Last synced: ${timeDisplay}
                </span>
            `;
        }
        
        console.log('✅ UI updated - showing connected state');
        
        // Auto-load Strava data
        loadStravaActivities(connectionData.athlete_id);
        
    } else {
        // Not connected - show orange connect button
        connectBtn.innerHTML = `
            <i class="fas fa-plug mr-2"></i>
            Connect Strava
        `;
        connectBtn.className = 'px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 w-full transition duration-200';
        connectBtn.disabled = false;
        connectBtn.onclick = connectStrava;
        
        // Update status message
        if (statusDiv) {
            statusDiv.innerHTML = `
                <span class="text-gray-600">
                    <i class="fas fa-info-circle mr-2"></i>
                    Not connected
                </span>
            `;
        }
        
        console.log('ℹ️ UI updated - showing disconnected state');
    }
}

/**
 * Load Strava activities from database
 * @param {string} athleteId - Athlete ID
 */
async function loadStravaActivities(athleteId) {
    try {
        console.log('📊 Loading Strava activities from database...');
        
        if (!supabaseClient) {
            console.error('❌ Supabase client not initialized');
            return;
        }
        
        const { data, error } = await supabaseClient
            .from('strava_activities')
            .select('*')
            .eq('athlete_id', athleteId)
            .order('created_at', { ascending: false })
            .limit(100);
        
        if (error) {
            console.error('❌ Error loading activities:', error);
            return;
        }
        
        console.log(`✅ Loaded ${data.length} activities from database`);
        
        if (data.length > 0) {
            // Calculate stats from activities
            const stats = calculateStravaStats(data);
            console.log('📈 Calculated stats:', stats);
            
            // Update UI with stats
            updateStatsDisplay(stats);
            
            // Load AISRI scores
            await loadAISRIScores(athleteId);
        }
        
    } catch (error) {
        console.error('❌ Error loading Strava activities:', error);
    }
}

/**
 * Calculate statistics from Strava activities
 * @param {Array} activities - Array of activity objects
 * @returns {Object} Calculated statistics
 */
function calculateStravaStats(activities) {
    const stats = {
        totalActivities: activities.length,
        totalDistance: 0,
        totalTime: 0,
        avgPace: 0,
        runningPillarScore: 0
    };
    
    let runCount = 0;
    
    activities.forEach(activity => {
        const activityData = activity.activity_data;
        if (!activityData) return;
        
        // Only count running activities
        if (activityData.type === 'Run') {
            runCount++;
            stats.totalDistance += activityData.distance || 0;
            stats.totalTime += activityData.moving_time || 0;
        }
    });
    
    // Convert distance from meters to km
    stats.totalDistance = Math.round(stats.totalDistance / 1000);
    
    // Calculate average pace (min/km)
    if (stats.totalDistance > 0) {
        const totalMinutes = stats.totalTime / 60;
        stats.avgPace = totalMinutes / stats.totalDistance;
    }
    
    // Calculate running pillar score (simplified)
    // Based on weekly distance, consistency, etc.
    if (runCount > 0) {
        const consistency = Math.min(runCount / 30, 1) * 100; // 30 runs in 90 days = 100
        stats.runningPillarScore = Math.round(consistency * 0.75); // Max 75
    }
    
    return stats;
}

/**
 * Update stats display in UI
 * @param {Object} stats - Statistics object
 */
function updateStatsDisplay(stats) {
    // Update running pillar if exists
    const runningPillarEl = document.getElementById('runningPillarScore');
    if (runningPillarEl) {
        runningPillarEl.textContent = stats.runningPillarScore;
    }
    
    // Update total distance if exists
    const totalDistanceEl = document.getElementById('totalDistance');
    if (totalDistanceEl) {
        totalDistanceEl.textContent = `${stats.totalDistance} km`;
    }
    
    console.log('✅ Stats display updated');
}

/**
 * Load AISRI scores from database
 * @param {string} athleteId - Athlete ID
 */
async function loadAISRIScores(athleteId) {
    try {
        console.log('📊 Loading AISRI scores from database...');
        
        if (!supabaseClient) {
            console.error('❌ Supabase client not initialized');
            return;
        }
        
        const { data, error } = await supabaseClient
            .from('aisri_scores')
            .select('*')
            .eq('athlete_id', athleteId)
            .order('assessment_date', { ascending: false })
            .limit(1);
        
        if (error) {
            console.error('❌ Error loading AISRI scores:', error);
            return;
        }
        
        if (data.length > 0) {
            const latestScore = data[0];
            console.log('✅ Loaded latest AISRI score:', latestScore.total_score);
            
            // Update UI with score
            displayAISRIScore(latestScore);
        } else {
            console.log('ℹ️ No AISRI scores found for athlete');
        }
        
    } catch (error) {
        console.error('❌ Error loading AISRI scores:', error);
    }
}

/**
 * Display AISRI score in UI
 * @param {Object} scoreData - Score data object
 */
function displayAISRIScore(scoreData) {
    // Update total score if element exists
    const totalScoreEl = document.getElementById('aisriTotalScore');
    if (totalScoreEl) {
        totalScoreEl.textContent = Math.round(scoreData.total_score);
    }
    
    // Update risk category
    const riskCategoryEl = document.getElementById('riskCategory');
    if (riskCategoryEl) {
        riskCategoryEl.textContent = scoreData.risk_category;
        
        // Update color based on risk
        const colorMap = {
            'Low': 'text-green-600',
            'Medium': 'text-yellow-600',
            'High': 'text-orange-600',
            'Critical': 'text-red-600'
        };
        riskCategoryEl.className = colorMap[scoreData.risk_category] || 'text-gray-600';
    }
    
    console.log('✅ AISRI score displayed');
}

console.log('✅ Strava session persistence functions loaded');
