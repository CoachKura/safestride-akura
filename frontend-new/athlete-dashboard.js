/**
 * Athlete Dashboard JavaScript
 * Displays personalized athlete data, AKURA API score, and workouts
 */

const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com',
    endpoints: {
        athlete: '/api/athlete',
        workouts: '/api/workouts',
        health: '/api/health'
    }
};

const akuraCalculator = new AkuraAPI();
let currentAthlete = null;
let authToken = null;

// Demo athlete data (used if API is offline)
const demoAthleteData = {
    name: "Priya Sharma",
    age: 25,
    email: "priya@example.com",
    currentPace: "4:45/km",
    goal: "Sub-1:35 HM",
    restingHR: 52,
    maxHR: 191,
    injuryHistory: "minor knee",
    yearsRunning: 4,
    location: "Chennai",
    trainingFrequency: 5,
    recentWorkouts: [
        { type: 'tempo', pace: '4:40', avgHR: 165, date: '2026-01-23' },
        { type: 'easy', pace: '5:20', avgHR: 145, date: '2026-01-22' },
        { type: 'interval', pace: '4:15', avgHR: 178, date: '2026-01-21' }
    ],
    workoutHistory: [
        { type: 'tempo', pace: '4:50', avgHR: 162, distance: 8, date: '2026-01-15' },
        { type: 'tempo', pace: '4:45', avgHR: 164, distance: 10, date: '2026-01-08' },
        { type: 'tempo', pace: '4:40', avgHR: 165, distance: 10, date: '2026-01-01' }
    ],
    weekStats: {
        distance: 42,
        runs: 5,
        avgHR: 158
    }
};

/**
 * Initialize dashboard
 */
document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    authToken = localStorage.getItem('safestride_token');
    const userStr = localStorage.getItem('safestride_user');
    
    if (!authToken || !userStr) {
        window.location.href = 'index.html';
        return;
    }
    
    try {
        const user = JSON.parse(userStr);
        document.getElementById('athlete-name').textContent = user.name || user.email;
        document.getElementById('welcome-name').textContent = user.name ? user.name.split(' ')[0] : 'Athlete';
        
        // Load athlete data
        await loadAthleteData();
    } catch (error) {
        console.error('Error loading user data:', error);
        // Use demo data
        loadDemoData();
    }
});

/**
 * Load athlete data from API
 */
async function loadAthleteData() {
    try {
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.athlete}`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            currentAthlete = await response.json();
            displayAthleteData(currentAthlete);
        } else {
            console.warn('Failed to load athlete data, using demo');
            loadDemoData();
        }
    } catch (error) {
        console.error('API error:', error);
        loadDemoData();
    }
}

/**
 * Load demo data when API is unavailable
 */
function loadDemoData() {
    console.log('📊 Loading demo athlete data...');
    currentAthlete = demoAthleteData;
    displayAthleteData(currentAthlete);
}

/**
 * Display athlete data on dashboard
 */
function displayAthleteData(athlete) {
    // Calculate AKURA API Score
    const apiScore = akuraCalculator.calculateAkuraAPI(athlete);
    const apiCategory = akuraCalculator.getAPICategory(apiScore);
    const referencePaces = akuraCalculator.getReferencePaces(apiScore);
    const hrZones = akuraCalculator.calculateHRZones(athlete.age, athlete.restingHR);
    
    // Display API Score
    document.getElementById('api-score').textContent = apiScore;
    document.getElementById('api-category').textContent = `${apiCategory.label} - ${apiCategory.description}`;
    document.getElementById('api-category').style.color = apiCategory.color;
    
    // Display week stats
    document.getElementById('week-distance').textContent = `${athlete.weekStats.distance} km`;
    document.getElementById('week-runs').textContent = `${athlete.weekStats.runs} runs completed`;
    document.getElementById('avg-hr').textContent = `${athlete.weekStats.avgHR} bpm`;
    
    // Calculate which zone the avg HR falls into
    const avgZone = getHRZone(athlete.weekStats.avgHR, hrZones);
    document.getElementById('avg-zone').textContent = avgZone;
    
    // Display goal progress (calculate based on current pace vs goal pace)
    const goalProgress = calculateGoalProgress(athlete.currentPace, athlete.goal);
    document.getElementById('goal-progress').textContent = `${goalProgress}%`;
    document.getElementById('goal-label').textContent = athlete.goal;
    
    // Display today's workout
    displayTodayWorkout(apiScore, referencePaces, hrZones);
    
    // Display HR Zones
    displayHRZones(hrZones);
    
    // Display progress chart
    displayProgressChart(athlete.workoutHistory);
}

/**
 * Display today's workout recommendation
 */
function displayTodayWorkout(apiScore, paces, hrZones) {
    const todayContainer = document.getElementById('today-workout');
    
    // Determine today's workout (simplified logic - can be expanded)
    const dayOfWeek = new Date().getDay();
    let workout = {};
    
    if (dayOfWeek === 0) { // Sunday - Long Run
        workout = {
            type: 'Long Run',
            icon: 'fa-route',
            color: 'blue',
            distance: '16-20 km',
            pace: paces.easy,
            hrZone: 'Zone 2',
            hrRange: `${hrZones.zone2.min}-${hrZones.zone2.max} bpm`,
            description: 'Easy conversational pace. Build endurance.'
        };
    } else if (dayOfWeek === 3) { // Wednesday - Tempo
        workout = {
            type: 'Tempo Run',
            icon: 'fa-fire',
            color: 'orange',
            distance: '8-10 km',
            pace: paces.tempo,
            hrZone: 'Zone 3',
            hrRange: `${hrZones.zone3.min}-${hrZones.zone3.max} bpm`,
            description: 'Comfortably hard pace. Threshold training.'
        };
    } else if (dayOfWeek === 2 || dayOfWeek === 5) { // Tuesday/Friday - Intervals
        workout = {
            type: 'Interval Training',
            icon: 'fa-bolt',
            color: 'red',
            distance: '6x800m @ ' + paces.interval,
            pace: paces.interval,
            hrZone: 'Zone 4',
            hrRange: `${hrZones.zone4.min}-${hrZones.zone4.max} bpm`,
            description: '400m recovery jog between intervals.'
        };
    } else { // Easy day
        workout = {
            type: 'Easy Run',
            icon: 'fa-smile',
            color: 'green',
            distance: '8-12 km',
            pace: paces.easy,
            hrZone: 'Zone 2',
            hrRange: `${hrZones.zone2.min}-${hrZones.zone2.max} bpm`,
            description: 'Recovery run. Keep it comfortable.'
        };
    }
    
    todayContainer.innerHTML = `
        <div class="flex items-start space-x-4 p-4 bg-${workout.color}-50 rounded-lg">
            <div class="flex-shrink-0">
                <div class="w-12 h-12 bg-${workout.color}-500 rounded-full flex items-center justify-center">
                    <i class="fas ${workout.icon} text-white text-xl"></i>
                </div>
            </div>
            <div class="flex-1">
                <h3 class="text-xl font-bold text-gray-900 mb-1">${workout.type}</h3>
                <div class="grid grid-cols-2 gap-4 mt-3">
                    <div>
                        <p class="text-sm text-gray-600">Distance</p>
                        <p class="font-semibold text-gray-900">${workout.distance}</p>
                    </div>
                    <div>
                        <p class="text-sm text-gray-600">Pace</p>
                        <p class="font-semibold text-gray-900">${workout.pace}/km</p>
                    </div>
                    <div>
                        <p class="text-sm text-gray-600">HR Target</p>
                        <p class="font-semibold text-gray-900">${workout.hrZone}</p>
                    </div>
                    <div>
                        <p class="text-sm text-gray-600">HR Range</p>
                        <p class="font-semibold text-gray-900">${workout.hrRange}</p>
                    </div>
                </div>
                <p class="text-sm text-gray-600 mt-3">${workout.description}</p>
                <button class="mt-4 bg-${workout.color}-500 text-white px-6 py-2 rounded-lg font-semibold hover:bg-${workout.color}-600 transition-colors">
                    <i class="fas fa-play mr-2"></i>Start Workout
                </button>
            </div>
        </div>
    `;
}

/**
 * Display HR Zones
 */
function displayHRZones(zones) {
    const container = document.getElementById('hr-zones-display');
    
    const zoneColors = {
        zone1: 'gray',
        zone2: 'blue',
        zone3: 'yellow',
        zone4: 'orange',
        zone5: 'red'
    };
    
    let html = '';
    
    ['zone1', 'zone2', 'zone3', 'zone4', 'zone5'].forEach((zoneKey, index) => {
        const zone = zones[zoneKey];
        const color = zoneColors[zoneKey];
        const isPrimary = zone.primary ? ' ⭐ PRIMARY FOCUS' : '';
        
        html += `
            <div class="flex items-center justify-between p-4 bg-${color}-50 rounded-lg border-2 ${zone.primary ? 'border-yellow-400' : 'border-transparent'}">
                <div class="flex items-center space-x-4">
                    <div class="w-12 h-12 bg-${color}-500 rounded-full flex items-center justify-center">
                        <span class="text-white font-bold text-lg">${index + 1}</span>
                    </div>
                    <div>
                        <h4 class="font-bold text-gray-900">${zone.name}${isPrimary}</h4>
                        <p class="text-sm text-gray-600">${zone.percentage} of Max HR</p>
                    </div>
                </div>
                <div class="text-right">
                    <p class="text-2xl font-bold text-gray-900">${zone.min}-${zone.max}</p>
                    <p class="text-sm text-gray-600">bpm</p>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

/**
 * Display progress chart
 */
function displayProgressChart(workoutHistory) {
    const ctx = document.getElementById('progress-chart');
    
    // Prepare data for last 30 days
    const dates = workoutHistory.map(w => w.date).reverse();
    const paces = workoutHistory.map(w => {
        const [min, sec] = w.pace.split(':').map(Number);
        return min * 60 + sec;
    }).reverse();
    
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: dates,
            datasets: [{
                label: 'Pace (seconds/km)',
                data: paces,
                borderColor: '#667eea',
                backgroundColor: 'rgba(102, 126, 234, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            const seconds = context.parsed.y;
                            const min = Math.floor(seconds / 60);
                            const sec = Math.round(seconds % 60);
                            return `Pace: ${min}:${sec.toString().padStart(2, '0')}/km`;
                        }
                    }
                }
            },
            scales: {
                y: {
                    reverse: true, // Lower pace is better
                    ticks: {
                        callback: function(value) {
                            const min = Math.floor(value / 60);
                            const sec = Math.round(value % 60);
                            return `${min}:${sec.toString().padStart(2, '0')}`;
                        }
                    }
                }
            }
        }
    });
}

/**
 * Get HR Zone from heart rate value
 */
function getHRZone(hr, zones) {
    if (hr >= zones.zone5.min) return '5 (Anaerobic)';
    if (hr >= zones.zone4.min) return '4 (VO2 Max)';
    if (hr >= zones.zone3.min) return '3 (Tempo)';
    if (hr >= zones.zone2.min) return '2 (Easy)';
    return '1 (Recovery)';
}

/**
 * Calculate goal progress
 */
function calculateGoalProgress(currentPace, goal) {
    // Extract goal pace from goal string (e.g., "Sub-1:35 HM" -> 4:30/km)
    // Simplified calculation
    const currentSeconds = paceToSeconds(currentPace);
    
    // Sub-1:35 HM = 4:30/km pace needed
    // Sub-4:00/km = direct pace goal
    let goalSeconds = 270; // Default 4:30/km
    
    if (goal.includes('Sub-1:35')) goalSeconds = 270; // 4:30/km
    if (goal.includes('Sub-1:40')) goalSeconds = 285; // 4:45/km
    if (goal.includes('Sub-4:00/km')) goalSeconds = 240; // 4:00/km
    
    // Calculate progress (inverse - faster pace = more progress)
    const progress = Math.max(0, Math.min(100, ((360 - currentSeconds) / (360 - goalSeconds)) * 100));
    
    return Math.round(progress);
}

/**
 * Convert pace string to seconds
 */
function paceToSeconds(pace) {
    const parts = pace.replace('/km', '').split(':');
    return parseInt(parts[0]) * 60 + parseInt(parts[1]);
}

/**
 * Logout function
 */
function logout() {
    localStorage.removeItem('safestride_token');
    localStorage.removeItem('safestride_user');
    window.location.href = 'index.html';
}

// Make logout available globally
window.logout = logout;
