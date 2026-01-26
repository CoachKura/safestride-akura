/**
 * SafeStride by AKURA - Main JavaScript
 * Homepage functionality and API integration
 */

// API Configuration
const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com',
    endpoints: {
        health: '/api/health',
        login: '/api/auth/login',
        signup: '/api/auth/signup',
        athlete: '/api/athlete',
        coach: '/api/coach',
        workouts: '/api/workouts',
        stravaAuth: '/api/strava/auth',
        garminAuth: '/api/garmin/auth'
    }
};

// Initialize AKURA API Calculator
const akuraCalculator = new AkuraAPI();

// Global state
let currentUser = null;
let authToken = null;

/**
 * Initialize application
 */
document.addEventListener('DOMContentLoaded', () => {
    // Check for existing auth token
    checkAuthStatus();
    
    // Check backend health
    checkBackendHealth();
    
    // Setup smooth scrolling
    setupSmoothScroll();
    
    // Load demo data visualization
    initializeDemoCharts();
});

/**
 * Check authentication status
 */
function checkAuthStatus() {
    authToken = localStorage.getItem('safestride_token');
    const userStr = localStorage.getItem('safestride_user');
    
    if (authToken && userStr) {
        try {
            currentUser = JSON.parse(userStr);
            
            // Redirect to appropriate dashboard
            if (currentUser.role === 'coach') {
                window.location.href = 'coach-dashboard.html';
            } else if (currentUser.role === 'athlete') {
                window.location.href = 'athlete-dashboard.html';
            }
        } catch (e) {
            console.error('Error parsing user data:', e);
            localStorage.removeItem('safestride_token');
            localStorage.removeItem('safestride_user');
        }
    }
}

/**
 * Check backend health status
 */
async function checkBackendHealth() {
    try {
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.health}`);
        
        if (response.ok) {
            const data = await response.json();
            console.log('✅ Backend Status:', data);
            showNotification('Backend connected successfully', 'success');
        } else {
            console.warn('⚠️ Backend responded with error:', response.status);
            showNotification('Backend connection issue', 'warning');
        }
    } catch (error) {
        console.error('❌ Backend connection failed:', error);
        showNotification('Backend offline - using demo mode', 'info');
    }
}

/**
 * Setup smooth scrolling for navigation
 */
function setupSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

/**
 * Show authentication modal
 */
function showAuthModal(mode = 'login') {
    const modal = document.getElementById('authModal');
    const content = document.getElementById('authContent');
    
    if (mode === 'login') {
        content.innerHTML = generateLoginForm();
    } else {
        content.innerHTML = generateSignupForm();
    }
    
    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

/**
 * Close authentication modal
 */
function closeAuthModal() {
    const modal = document.getElementById('authModal');
    modal.classList.add('hidden');
    modal.classList.remove('flex');
}

/**
 * Generate login form HTML
 */
function generateLoginForm() {
    return `
        <div class="text-center mb-6">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Welcome Back</h2>
            <p class="text-gray-600">Sign in to your SafeStride account</p>
        </div>
        
        <form onsubmit="handleLogin(event)" class="space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Account Type</label>
                <div class="grid grid-cols-2 gap-2">
                    <button type="button" onclick="selectRole('coach')" id="role-coach" class="px-4 py-2 border-2 rounded-lg hover:border-purple-600 transition-colors">
                        <i class="fas fa-user-tie text-lg mb-1"></i>
                        <div class="text-sm font-medium">Coach</div>
                    </button>
                    <button type="button" onclick="selectRole('athlete')" id="role-athlete" class="px-4 py-2 border-2 rounded-lg hover:border-purple-600 transition-colors border-purple-600">
                        <i class="fas fa-running text-lg mb-1"></i>
                        <div class="text-sm font-medium">Athlete</div>
                    </button>
                </div>
                <input type="hidden" id="login-role" value="athlete" required>
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                <input type="email" id="login-email" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                    placeholder="you@example.com">
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Password</label>
                <input type="password" id="login-password" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                    placeholder="••••••••">
            </div>
            
            <button type="submit" class="w-full btn-primary text-white py-3 rounded-lg font-semibold">
                <i class="fas fa-sign-in-alt mr-2"></i>Sign In
            </button>
        </form>
        
        <div class="mt-4 text-center text-sm text-gray-600">
            Don't have an account? 
            <button onclick="showAuthModal('signup')" class="text-purple-600 font-semibold hover:text-purple-700">Sign up</button>
        </div>
    `;
}

/**
 * Generate signup form HTML
 */
function generateSignupForm() {
    return `
        <div class="text-center mb-6">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Join SafeStride</h2>
            <p class="text-gray-600">Start your elite running journey</p>
        </div>
        
        <form onsubmit="handleSignup(event)" class="space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Full Name</label>
                <input type="text" id="signup-name" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                    placeholder="John Doe">
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                <input type="email" id="signup-email" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                    placeholder="you@example.com">
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Password</label>
                <input type="password" id="signup-password" required minlength="8"
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                    placeholder="Minimum 8 characters">
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Invite Code (Optional)</label>
                <input type="text" id="signup-invitecode"
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                    placeholder="Coach invite code">
            </div>
            
            <button type="submit" class="w-full btn-primary text-white py-3 rounded-lg font-semibold">
                <i class="fas fa-user-plus mr-2"></i>Create Account
            </button>
        </form>
        
        <div class="mt-4 text-center text-sm text-gray-600">
            Already have an account? 
            <button onclick="showAuthModal('login')" class="text-purple-600 font-semibold hover:text-purple-700">Sign in</button>
        </div>
    `;
}

/**
 * Select role in login form
 */
function selectRole(role) {
    document.getElementById('login-role').value = role;
    
    // Update button styles
    const coachBtn = document.getElementById('role-coach');
    const athleteBtn = document.getElementById('role-athlete');
    
    if (role === 'coach') {
        coachBtn.classList.add('border-purple-600');
        athleteBtn.classList.remove('border-purple-600');
    } else {
        athleteBtn.classList.add('border-purple-600');
        coachBtn.classList.remove('border-purple-600');
    }
}

/**
 * Handle login form submission
 */
async function handleLogin(event) {
    event.preventDefault();
    
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    const role = document.getElementById('login-role').value;
    
    try {
        showNotification('Signing in...', 'info');
        
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.login}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password, role })
        });
        
        if (response.ok) {
            const data = await response.json();
            
            // Store auth data
            localStorage.setItem('safestride_token', data.token);
            localStorage.setItem('safestride_user', JSON.stringify(data.user));
            
            showNotification('Login successful!', 'success');
            
            // Redirect based on role
            setTimeout(() => {
                if (role === 'coach') {
                    window.location.href = 'coach-dashboard.html';
                } else {
                    window.location.href = 'athlete-dashboard.html';
                }
            }, 1000);
        } else {
            const error = await response.json();
            showNotification(error.message || 'Login failed', 'error');
        }
    } catch (error) {
        console.error('Login error:', error);
        showNotification('Network error. Please try again.', 'error');
    }
}

/**
 * Handle signup form submission
 */
async function handleSignup(event) {
    event.preventDefault();
    
    const name = document.getElementById('signup-name').value;
    const email = document.getElementById('signup-email').value;
    const password = document.getElementById('signup-password').value;
    const inviteCode = document.getElementById('signup-invitecode').value;
    
    try {
        showNotification('Creating account...', 'info');
        
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.signup}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name, email, password, inviteCode })
        });
        
        if (response.ok) {
            const data = await response.json();
            
            // Store auth data
            localStorage.setItem('safestride_token', data.token);
            localStorage.setItem('safestride_user', JSON.stringify(data.user));
            
            showNotification('Account created successfully!', 'success');
            
            // Redirect to athlete dashboard
            setTimeout(() => {
                window.location.href = 'athlete-dashboard.html';
            }, 1000);
        } else {
            const error = await response.json();
            showNotification(error.message || 'Signup failed', 'error');
        }
    } catch (error) {
        console.error('Signup error:', error);
        showNotification('Network error. Please try again.', 'error');
    }
}

/**
 * Show notification
 */
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg max-w-md animate-fade-in ${
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
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.remove();
    }, 3000);
}

/**
 * Initialize demo charts for homepage
 */
function initializeDemoCharts() {
    // This will be expanded when we add Chart.js visualizations
    console.log('📊 Demo charts ready');
}

// Make functions available globally
window.showAuthModal = showAuthModal;
window.closeAuthModal = closeAuthModal;
window.selectRole = selectRole;
window.handleLogin = handleLogin;
window.handleSignup = handleSignup;
