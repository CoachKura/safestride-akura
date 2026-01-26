/**
 * Coach Dashboard JavaScript
 * Manages coach view, athlete roster, and team analytics
 */

const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com',
    endpoints: {
        coach: '/api/coach',
        athletes: '/api/athlete',
        workouts: '/api/workouts'
    }
};

const akuraCalculator = new AkuraAPI();
let athletes = [];
let authToken = null;

/**
 * Initialize coach dashboard
 */
document.addEventListener('DOMContentLoaded', async () => {
    authToken = localStorage.getItem('safestride_token');
    const userStr = localStorage.getItem('safestride_user');
    
    if (!authToken || !userStr) {
        window.location.href = 'index.html';
        return;
    }
    
    try {
        const user = JSON.parse(userStr);
        
        // Check if user is a coach
        if (user.role !== 'coach') {
            window.location.href = 'athlete-dashboard.html';
            return;
        }
        
        document.getElementById('coach-name').textContent = user.name || user.email;
        
        // Load athletes data
        await loadAthletes();
    } catch (error) {
        console.error('Error loading coach data:', error);
        // Use demo data
        loadDemoData();
    }
});

/**
 * Load athletes from API
 */
async function loadAthletes() {
    try {
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.coach}/athletes`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            athletes = await response.json();
            displayAthletes();
            displayTeamStats();
            displayTodaySchedule();
        } else {
            console.warn('Failed to load athletes, using demo data');
            loadDemoData();
        }
    } catch (error) {
        console.error('API error:', error);
        loadDemoData();
    }
}

/**
 * Load demo data from chennai-athletes.js
 */
function loadDemoData() {
    console.log('📊 Loading demo Chennai athletes data...');
    
    // Load from chennai-athletes.js if available
    if (typeof CHENNAI_ATHLETES !== 'undefined') {
        athletes = CHENNAI_ATHLETES;
    } else {
        // Fallback minimal data
        athletes = [
            {
                id: 1,
                name: "Arjun Kumar",
                age: 28,
                currentPace: "4:15/km",
                goal: "Sub-3:00 Marathon",
                restingHR: 48,
                maxHR: 188,
                injuryHistory: "none",
                yearsRunning: 6,
                location: "Chennai",
                trainingFrequency: 6,
                recentWorkouts: [
                    { type: 'tempo', pace: '4:10', avgHR: 168, distance: 10, date: '2026-01-23' }
                ],
                workoutHistory: [
                    { type: 'tempo', pace: '4:15', avgHR: 167, distance: 10, date: '2026-01-15' }
                ],
                weekStats: { distance: 68, runs: 6, avgHR: 162 }
            }
        ];
    }
    
    displayAthletes();
    displayTeamStats();
    displayTodaySchedule();
}

/**
 * Display athletes grid
 */
function displayAthletes() {
    const grid = document.getElementById('athletes-grid');
    
    // Update athlete count
    document.getElementById('athlete-count').textContent = athletes.length;
    
    // Calculate AKURA API for each athlete
    const athletesWithAPI = athletes.map(athlete => {
        const apiScore = akuraCalculator.calculateAkuraAPI(athlete);
        const category = akuraCalculator.getAPICategory(apiScore);
        return { ...athlete, apiScore, category };
    });
    
    // Sort by API score (default)
    athletesWithAPI.sort((a, b) => b.apiScore - a.apiScore);
    
    let html = '';
    
    athletesWithAPI.forEach(athlete => {
        html += `
            <div class="athlete-card bg-white rounded-xl shadow-md p-6" onclick="viewAthleteDetails(${athlete.id})">
                <div class="flex items-start justify-between mb-4">
                    <div>
                        <h3 class="text-lg font-bold text-gray-900">${athlete.name}</h3>
                        <p class="text-sm text-gray-600">${athlete.age} years • ${athlete.yearsRunning} years running</p>
                    </div>
                    <div class="text-right">
                        <div class="text-3xl font-bold" style="color: ${athlete.category.color}">${athlete.apiScore}</div>
                        <p class="text-xs text-gray-600">AKURA API</p>
                    </div>
                </div>
                
                <div class="space-y-2 mb-4">
                    <div class="flex justify-between text-sm">
                        <span class="text-gray-600">Current Pace:</span>
                        <span class="font-semibold text-gray-900">${athlete.currentPace}</span>
                    </div>
                    <div class="flex justify-between text-sm">
                        <span class="text-gray-600">Goal:</span>
                        <span class="font-semibold text-gray-900">${athlete.goal}</span>
                    </div>
                    <div class="flex justify-between text-sm">
                        <span class="text-gray-600">This Week:</span>
                        <span class="font-semibold text-gray-900">${athlete.weekStats.distance} km (${athlete.weekStats.runs} runs)</span>
                    </div>
                </div>
                
                <div class="pt-4 border-t border-gray-200">
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium" 
                          style="background-color: ${athlete.category.color}20; color: ${athlete.category.color}">
                        <i class="fas fa-circle text-xs mr-2"></i>${athlete.category.label}
                    </span>
                    ${athlete.injuryHistory !== 'none' ? 
                        `<span class="ml-2 inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700">
                            <i class="fas fa-exclamation-triangle text-xs mr-2"></i>Injury History
                        </span>` : ''}
                </div>
            </div>
        `;
    });
    
    grid.innerHTML = html;
}

/**
 * Display team statistics
 */
function displayTeamStats() {
    // Calculate team average API
    const apiScores = athletes.map(a => akuraCalculator.calculateAkuraAPI(a));
    const avgAPI = Math.round(apiScores.reduce((sum, score) => sum + score, 0) / apiScores.length);
    
    // Calculate team totals
    const totalWorkouts = athletes.reduce((sum, a) => sum + (a.weekStats?.runs || 0), 0);
    const totalDistance = athletes.reduce((sum, a) => sum + (a.weekStats?.distance || 0), 0);
    
    document.getElementById('team-avg-api').textContent = avgAPI;
    document.getElementById('team-workouts').textContent = totalWorkouts;
    document.getElementById('team-distance').textContent = totalDistance;
}

/**
 * Display today's workout schedule
 */
function displayTodaySchedule() {
    const container = document.getElementById('today-schedule');
    const today = new Date().toISOString().split('T')[0];
    
    // Get today's workouts for all athletes
    let todayWorkouts = [];
    
    athletes.forEach(athlete => {
        // Simplified: assign workouts based on day of week
        const dayOfWeek = new Date().getDay();
        let workoutType = 'Easy Run';
        
        if (dayOfWeek === 0) workoutType = 'Long Run';
        else if (dayOfWeek === 3) workoutType = 'Tempo Run';
        else if (dayOfWeek === 2 || dayOfWeek === 5) workoutType = 'Intervals';
        
        todayWorkouts.push({
            athlete: athlete.name,
            type: workoutType,
            scheduled: true
        });
    });
    
    if (todayWorkouts.length === 0) {
        container.innerHTML = '<p class="text-gray-600">No workouts scheduled for today</p>';
        return;
    }
    
    // Group by workout type
    const grouped = todayWorkouts.reduce((acc, w) => {
        if (!acc[w.type]) acc[w.type] = [];
        acc[w.type].push(w.athlete);
        return acc;
    }, {});
    
    let html = '';
    
    Object.keys(grouped).forEach(type => {
        const athleteList = grouped[type];
        const icon = type === 'Long Run' ? 'fa-route' : 
                    type === 'Tempo Run' ? 'fa-fire' :
                    type === 'Intervals' ? 'fa-bolt' : 'fa-running';
        
        html += `
            <div class="flex items-start p-4 bg-gray-50 rounded-lg">
                <div class="flex-shrink-0 w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center mr-4">
                    <i class="fas ${icon} text-purple-600"></i>
                </div>
                <div class="flex-1">
                    <h3 class="font-bold text-gray-900">${type}</h3>
                    <p class="text-sm text-gray-600 mt-1">${athleteList.length} athlete${athleteList.length > 1 ? 's' : ''}: ${athleteList.join(', ')}</p>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

/**
 * Sort athletes
 */
function sortAthletes(method) {
    const athletesWithAPI = athletes.map(athlete => ({
        ...athlete,
        apiScore: akuraCalculator.calculateAkuraAPI(athlete)
    }));
    
    if (method === 'api') {
        athletesWithAPI.sort((a, b) => b.apiScore - a.apiScore);
    } else if (method === 'name') {
        athletesWithAPI.sort((a, b) => a.name.localeCompare(b.name));
    }
    
    athletes = athletesWithAPI;
    displayAthletes();
}

/**
 * View athlete details
 */
function viewAthleteDetails(athleteId) {
    const athlete = athletes.find(a => a.id === athleteId);
    if (!athlete) return;
    
    // Store athlete ID and navigate to details page
    localStorage.setItem('viewing_athlete_id', athleteId);
    window.location.href = `coach-athlete-detail.html?id=${athleteId}`;
}

/**
 * View reports
 */
function viewReports() {
    showNotification('Team analytics dashboard coming soon!', 'info');
}

/**
 * Broadcast message
 */
function broadcastMessage() {
    const message = prompt('Enter message to send to all athletes:');
    if (message && message.trim()) {
        showNotification(`Broadcasting: "${message}" to ${athletes.length} athletes`, 'success');
        // In production, this would call API endpoint
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
window.sortAthletes = sortAthletes;
window.viewAthleteDetails = viewAthleteDetails;
window.viewReports = viewReports;
window.broadcastMessage = broadcastMessage;
window.logout = logout;
