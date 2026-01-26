/**
 * SafeStride by AKURA - Main JavaScript
 * Core API integration and authentication functions
 */

// API Configuration
const API_URL = 'https://safestride-backend-cave.onrender.com';

const API_ENDPOINTS = {
    health: '/api/health',
    login: '/api/auth/login',
    signup: '/api/auth/signup',
    athlete: '/api/athlete',
    coach: '/api/coach',
    workouts: '/api/workouts',
    stravaAuth: '/api/strava/auth',
    garminAuth: '/api/garmin/auth'
};

/**
 * Login user with email and password
 */
async function loginUser(email, password) {
    try {
        const response = await fetch(`${API_URL}${API_ENDPOINTS.login}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Login failed');
        }

        const data = await response.json();
        
        // Store token and user info
        localStorage.setItem('safestride_token', data.token);
        localStorage.setItem('safestride_user', JSON.stringify(data.user));
        
        // Redirect based on user role
        if (data.user.role === 'coach') {
            window.location.href = '/coach-dashboard.html';
        } else if (data.user.role === 'athlete') {
            window.location.href = '/athlete-dashboard.html';
        }
        
        return true;
    } catch (error) {
        console.error('Login error:', error);
        throw error;
    }
}

/**
 * Sign up new user
 */
async function signupUser(name, email, password, role) {
    try {
        const response = await fetch(`${API_URL}${API_ENDPOINTS.signup}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name,
                email,
                password,
                role
            })
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Signup failed');
        }

        const data = await response.json();
        
        // Store token and user info
        localStorage.setItem('safestride_token', data.token);
        localStorage.setItem('safestride_user', JSON.stringify(data.user));
        
        // Redirect to appropriate dashboard
        if (data.user.role === 'coach') {
            window.location.href = '/coach-dashboard.html';
        } else if (data.user.role === 'athlete') {
            window.location.href = '/athlete-dashboard.html';
        } else {
            window.location.href = '/index.html';
        }
        
        return true;
    } catch (error) {
        console.error('Signup error:', error);
        throw error;
    }
}

/**
 * Logout user
 */
function logoutUser() {
    localStorage.removeItem('safestride_token');
    localStorage.removeItem('safestride_user');
    window.location.href = '/index.html';
}

/**
 * Check if user is authenticated
 */
function isAuthenticated() {
    return !!localStorage.getItem('safestride_token');
}

/**
 * Get current user from localStorage
 */
function getCurrentUser() {
    const userStr = localStorage.getItem('safestride_user');
    return userStr ? JSON.parse(userStr) : null;
}

/**
 * Get auth token
 */
function getAuthToken() {
    return localStorage.getItem('safestride_token');
}

/**
 * Make authenticated API call
 */
async function apiCall(endpoint, options = {}) {
    const token = getAuthToken();
    
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers
    };
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers
    });
    
    if (!response.ok) {
        if (response.status === 401) {
            // Token expired or invalid
            logoutUser();
            throw new Error('Session expired');
        }
        throw new Error(`API error: ${response.status}`);
    }
    
    return response.json();
}

/**
 * Check JWT token validity and expiration
 */
function checkAuth() {
    const token = getAuthToken();
    
    if (!token) {
        window.location.href = '/index.html';
        return false;
    }
    
    try {
        // Decode JWT payload (format: header.payload.signature)
        const payload = JSON.parse(atob(token.split('.')[1]));
        
        // Check if token is expired (exp is in seconds, multiply by 1000 for milliseconds)
        if (payload.exp && payload.exp * 1000 < Date.now()) {
            // Token expired
            logoutUser();
            return false;
        }
        
        return true;
    } catch (error) {
        console.error('Token validation error:', error);
        logoutUser();
        return false;
    }
}

/**
 * Check backend health
 */
async function checkBackendHealth() {
    try {
        const response = await fetch(`${API_URL}${API_ENDPOINTS.health}`);
        const data = await response.json();
        return data.status === 'ok';
    } catch (error) {
        console.warn('Backend health check failed:', error);
        return false;
    }
}

// Make functions globally available
window.loginUser = loginUser;
window.signupUser = signupUser;
window.logoutUser = logoutUser;
window.isAuthenticated = isAuthenticated;
window.getCurrentUser = getCurrentUser;
window.getAuthToken = getAuthToken;
window.checkAuth = checkAuth;
window.apiCall = apiCall;
window.checkBackendHealth = checkBackendHealth;
