/**
 * Athlete Devices JavaScript
 * Handles device connections (Strava, Garmin, COROS)
 */

const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com',
    stravaClientId: '162971',
    endpoints: {
        stravaAuth: '/api/strava/auth',
        garminAuth: '/api/garmin/auth',
        workouts: '/api/workouts'
    }
};

// Strava OAuth constants
const STRAVA_CLIENT_ID = API_CONFIG.stravaClientId;
// Use the production frontend URL for the redirect target
const STRAVA_REDIRECT_URI = 'https://safestride-frontend.onrender.com/athlete-devices.html';

let authToken = null;

/**
 * Initialize devices page
 */
document.addEventListener('DOMContentLoaded', () => {
    authToken = localStorage.getItem('safestride_token');
    const userStr = localStorage.getItem('safestride_user');
    
    if (!authToken || !userStr) {
        window.location.href = 'index.html';
        return;
    }
    
    try {
        const user = JSON.parse(userStr);
        document.getElementById('athlete-name').textContent = user.name || user.email;
        
        // Check device connection status
        checkDeviceStatus();
        
        // Set today's date for manual upload
        document.getElementById('workout-date').valueAsDate = new Date();
    } catch (error) {
        console.error('Error loading user data:', error);
    }
});

/**
 * Check which devices are connected
 */
async function checkDeviceStatus() {
    // Check localStorage for device connections
    const stravaConnected = localStorage.getItem('strava_connected') === 'true';
    const garminConnected = localStorage.getItem('garmin_connected') === 'true';
    
    if (stravaConnected) {
        updateDeviceStatus('strava', true);
    }
    
    if (garminConnected) {
        updateDeviceStatus('garmin', true);
    }
    
    // Check URL for OAuth callback
    const urlParams = new URLSearchParams(window.location.search);
    const code = urlParams.get('code');
    const state = urlParams.get('state');
    
    if (code) {
        if (state === 'strava') {
            await handleStravaCallback(code);
        } else if (state === 'garmin') {
            await handleGarminCallback(code);
        }
    }
}

/**
 * Update device connection status UI
 */
function updateDeviceStatus(device, connected) {
    const statusElement = document.getElementById(`${device}-status`);
    
    if (connected) {
        statusElement.innerHTML = `
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-700">
                <i class="fas fa-check-circle text-green-500 mr-2 text-xs"></i>Connected
            </span>
        `;
        
        // Update button
        const button = statusElement.parentElement.querySelector('button');
        button.innerHTML = `<i class="fas fa-times mr-2"></i>Disconnect`;
        button.onclick = () => disconnectDevice(device);
        button.className = 'w-full bg-red-500 text-white px-4 py-2 rounded-lg font-semibold hover:bg-red-600 transition-colors';
    }
}

/**
 * Connect to Strava
 */
function connectStrava() {
    const redirectUri = encodeURIComponent(STRAVA_REDIRECT_URI);
    const scope = 'activity:read_all';
    const state = 'strava';
    const approval = 'force';
    const authUrl = `https://www.strava.com/oauth/authorize?client_id=${STRAVA_CLIENT_ID}&response_type=code&redirect_uri=${redirectUri}&approval_prompt=${approval}&scope=${scope}&state=${state}`;
    window.location.href = authUrl;
}

/**
 * Handle Strava OAuth callback
 */
async function handleStravaCallback(code) {
    try {
        showNotification('Connecting to Strava...', 'info');
        
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.stravaAuth}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify({ code })
        });
        
        if (response.ok) {
            const data = await response.json();
            localStorage.setItem('strava_connected', 'true');
            localStorage.setItem('strava_athlete_id', data.athlete.id);
            
            updateDeviceStatus('strava', true);
            showNotification('Strava connected successfully!', 'success');
            
            // Clean URL
            window.history.replaceState({}, document.title, window.location.pathname);
        } else {
            throw new Error('Strava connection failed');
        }
    } catch (error) {
        console.error('Strava callback error:', error);
        showNotification('Failed to connect Strava. Please try again.', 'error');
    }
}

/**
 * Connect to Garmin
 */
function connectGarmin() {
    showNotification('Garmin Connect integration coming soon!', 'info');
    
    // Placeholder for Garmin OAuth
    // In production, this would follow similar OAuth flow
    /*
    const redirectUri = encodeURIComponent(window.location.href.split('?')[0]);
    const state = 'garmin';
    
    const authUrl = `https://connect.garmin.com/oauthConfirm?oauth_callback=${redirectUri}&state=${state}`;
    window.location.href = authUrl;
    */
}

/**
 * Handle Garmin OAuth callback
 */
async function handleGarminCallback(code) {
    try {
        showNotification('Connecting to Garmin...', 'info');
        
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.garminAuth}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify({ code })
        });
        
        if (response.ok) {
            localStorage.setItem('garmin_connected', 'true');
            updateDeviceStatus('garmin', true);
            showNotification('Garmin connected successfully!', 'success');
            
            window.history.replaceState({}, document.title, window.location.pathname);
        } else {
            throw new Error('Garmin connection failed');
        }
    } catch (error) {
        console.error('Garmin callback error:', error);
        showNotification('Failed to connect Garmin. Please try again.', 'error');
    }
}

/**
 * Disconnect device
 */
function disconnectDevice(device) {
    if (confirm(`Are you sure you want to disconnect ${device}?`)) {
        localStorage.removeItem(`${device}_connected`);
        localStorage.removeItem(`${device}_athlete_id`);
        
        // Reload page to reset UI
        location.reload();
    }
}

/**
 * Show manual upload modal
 */
function showManualUploadModal() {
    document.getElementById('manual-upload-modal').classList.remove('hidden');
    document.getElementById('manual-upload-modal').classList.add('flex');
}

/**
 * Close manual upload modal
 */
function closeManualUploadModal() {
    document.getElementById('manual-upload-modal').classList.add('hidden');
    document.getElementById('manual-upload-modal').classList.remove('flex');
}

/**
 * Submit manual workout
 */
async function submitManualWorkout(event) {
    event.preventDefault();
    
    const workoutData = {
        type: document.getElementById('workout-type').value,
        distance: parseFloat(document.getElementById('workout-distance').value),
        duration: parseInt(document.getElementById('workout-duration').value),
        avgHR: parseInt(document.getElementById('workout-hr').value) || null,
        date: document.getElementById('workout-date').value,
        notes: document.getElementById('workout-notes').value,
        source: 'manual'
    };
    
    // Calculate pace
    const paceSeconds = (workoutData.duration * 60) / workoutData.distance;
    const paceMin = Math.floor(paceSeconds / 60);
    const paceSec = Math.round(paceSeconds % 60);
    workoutData.pace = `${paceMin}:${paceSec.toString().padStart(2, '0')}`;
    
    try {
        showNotification('Saving workout...', 'info');
        
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.workouts}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify(workoutData)
        });
        
        if (response.ok) {
            showNotification('Workout saved successfully!', 'success');
            closeManualUploadModal();
            
            // Reset form
            event.target.reset();
            document.getElementById('workout-date').valueAsDate = new Date();
        } else {
            throw new Error('Failed to save workout');
        }
    } catch (error) {
        console.error('Manual workout error:', error);
        showNotification('Failed to save workout. Please try again.', 'error');
    }
}

/**
 * Show notification
 */
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg max-w-md ${
        type === 'success' ? 'bg-green-500' :
        type === 'error' ? 'bg-red-500' :
        type === 'warning' ? 'bg-yellow-500' :
        'bg-blue-500'
    } text-white`;
    
    notification.innerHTML = `
        <div class="flex items-center">
            <i class="fas ${
                type === 'success' ? 'fa-check-circle' :
                type === 'error' ? 'fa-exclamation-circle' :
                type === 'warning' ? 'fa-exclamation-triangle' :
                'fa-info-circle'
            } text-xl mr-3"></i>
            <span>${message}</span>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 3000);
}

/**
 * Logout function
 */
function logout() {
    localStorage.removeItem('safestride_token');
    localStorage.removeItem('safestride_user');
    window.location.href = 'index.html';
}

// Make functions globally available
window.connectStrava = connectStrava;
window.connectGarmin = connectGarmin;
window.disconnectDevice = disconnectDevice;
window.showManualUploadModal = showManualUploadModal;
window.closeManualUploadModal = closeManualUploadModal;
window.submitManualWorkout = submitManualWorkout;
window.logout = logout;
