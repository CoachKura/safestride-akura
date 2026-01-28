/**
 * AKURA SafeStride Authentication System
 * Supabase Integration
 * 
 * IMPORTANT: Replace SUPABASE_URL and SUPABASE_ANON_KEY with your actual credentials
 * Find them in: Supabase Dashboard > Settings > API
 */

// ===================================
// SUPABASE CONFIGURATION
// ===================================
const SUPABASE_URL = 'YOUR_SUPABASE_URL'; // e.g., 'https://xxxxx.supabase.co'
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY'; // Your anon/public key

// Import Supabase client from CDN
let supabase = null;

// Initialize Supabase client
(function initSupabase() {
    if (typeof window !== 'undefined') {
        // Load Supabase from CDN if not already loaded
        if (!window.supabase) {
            const script = document.createElement('script');
            script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
            script.onload = () => {
                supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
                console.log('✓ Supabase initialized');
            };
            document.head.appendChild(script);
        } else {
            supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
            console.log('✓ Supabase initialized');
        }
    }
})();

// ===================================
// AUTHENTICATION FUNCTIONS
// ===================================

/**
 * Register new user with email and password
 * @param {string} email - User email
 * @param {string} password - User password
 * @param {string} fullName - User full name
 * @param {string} role - User role (athlete or coach)
 * @returns {Promise<{success: boolean, error?: string, user?: object}>}
 */
async function register(email, password, fullName, role) {
    try {
        if (!supabase) {
            return { success: false, error: 'Authentication system is initializing. Please wait a moment and try again.' };
        }

        const { data, error } = await supabase.auth.signUp({
            email: email,
            password: password,
            options: {
                data: {
                    full_name: fullName,
                    role: role,
                    display_name: fullName
                },
                emailRedirectTo: `${window.location.origin}/profile-setup.html`
            }
        });

        if (error) {
            console.error('Registration error:', error);
            return { success: false, error: error.message };
        }

        // Store user info in localStorage for profile setup
        if (data.user) {
            localStorage.setItem('akura_user_role', role);
            localStorage.setItem('akura_user_name', fullName);
        }

        return { success: true, user: data.user };
    } catch (error) {
        console.error('Registration exception:', error);
        return { success: false, error: 'An unexpected error occurred. Please try again.' };
    }
}

/**
 * Login user with email and password
 * @param {string} email - User email
 * @param {string} password - User password
 * @returns {Promise<{success: boolean, error?: string, session?: object}>}
 */
async function login(email, password) {
    try {
        if (!supabase) {
            return { success: false, error: 'Authentication system is initializing. Please wait a moment and try again.' };
        }

        const { data, error } = await supabase.auth.signInWithPassword({
            email: email,
            password: password
        });

        if (error) {
            console.error('Login error:', error);
            
            // Provide user-friendly error messages
            if (error.message.includes('Invalid login credentials')) {
                return { success: false, error: 'Invalid email or password. Please try again.' };
            } else if (error.message.includes('Email not confirmed')) {
                return { success: false, error: 'Please check your email to confirm your account before signing in.' };
            }
            
            return { success: false, error: error.message };
        }

        // Store session info
        if (data.session) {
            localStorage.setItem('akura_session', JSON.stringify(data.session));
            
            // Store user role if available
            if (data.user?.user_metadata?.role) {
                localStorage.setItem('akura_user_role', data.user.user_metadata.role);
            }
            
            // Store user name if available
            if (data.user?.user_metadata?.full_name) {
                localStorage.setItem('akura_user_name', data.user.user_metadata.full_name);
            }
        }

        return { success: true, session: data.session, user: data.user };
    } catch (error) {
        console.error('Login exception:', error);
        return { success: false, error: 'An unexpected error occurred. Please try again.' };
    }
}

/**
 * Logout current user
 * @returns {Promise<{success: boolean, error?: string}>}
 */
async function logout() {
    try {
        if (!supabase) {
            return { success: false, error: 'Authentication system is initializing.' };
        }

        const { error } = await supabase.auth.signOut();

        if (error) {
            console.error('Logout error:', error);
            return { success: false, error: error.message };
        }

        // Clear local storage
        localStorage.removeItem('akura_session');
        localStorage.removeItem('akura_user_role');
        localStorage.removeItem('akura_user_name');

        return { success: true };
    } catch (error) {
        console.error('Logout exception:', error);
        return { success: false, error: 'An unexpected error occurred.' };
    }
}

/**
 * Send password reset email
 * @param {string} email - User email
 * @returns {Promise<{success: boolean, error?: string}>}
 */
async function resetPassword(email) {
    try {
        if (!supabase) {
            return { success: false, error: 'Authentication system is initializing. Please wait a moment and try again.' };
        }

        const { error } = await supabase.auth.resetPasswordForEmail(email, {
            redirectTo: `${window.location.origin}/reset-password.html`
        });

        if (error) {
            console.error('Password reset error:', error);
            return { success: false, error: error.message };
        }

        return { success: true };
    } catch (error) {
        console.error('Password reset exception:', error);
        return { success: false, error: 'An unexpected error occurred. Please try again.' };
    }
}

/**
 * Update user password (after reset)
 * @param {string} newPassword - New password
 * @returns {Promise<{success: boolean, error?: string}>}
 */
async function updatePassword(newPassword) {
    try {
        if (!supabase) {
            return { success: false, error: 'Authentication system is initializing. Please wait a moment and try again.' };
        }

        const { error } = await supabase.auth.updateUser({
            password: newPassword
        });

        if (error) {
            console.error('Password update error:', error);
            return { success: false, error: error.message };
        }

        return { success: true };
    } catch (error) {
        console.error('Password update exception:', error);
        return { success: false, error: 'An unexpected error occurred. Please try again.' };
    }
}

/**
 * Update user profile metadata
 * @param {object} profileData - Profile data (age, gender, fitnessLevel, etc.)
 * @returns {Promise<{success: boolean, error?: string}>}
 */
async function updateUserProfile(profileData) {
    try {
        if (!supabase) {
            return { success: false, error: 'Authentication system is initializing.' };
        }

        const { error } = await supabase.auth.updateUser({
            data: profileData
        });

        if (error) {
            console.error('Profile update error:', error);
            return { success: false, error: error.message };
        }

        return { success: true };
    } catch (error) {
        console.error('Profile update exception:', error);
        return { success: false, error: 'An unexpected error occurred.' };
    }
}

/**
 * Get current user
 * @returns {Promise<{user: object | null}>}
 */
async function getCurrentUser() {
    try {
        if (!supabase) {
            return { user: null };
        }

        const { data: { user }, error } = await supabase.auth.getUser();

        if (error) {
            console.error('Get user error:', error);
            return { user: null };
        }

        return { user };
    } catch (error) {
        console.error('Get user exception:', error);
        return { user: null };
    }
}

/**
 * Get current session
 * @returns {Promise<{session: object | null}>}
 */
async function getSession() {
    try {
        if (!supabase) {
            return { session: null };
        }

        const { data: { session }, error } = await supabase.auth.getSession();

        if (error) {
            console.error('Get session error:', error);
            return { session: null };
        }

        return { session };
    } catch (error) {
        console.error('Get session exception:', error);
        return { session: null };
    }
}

// ===================================
// UTILITY FUNCTIONS
// ===================================

/**
 * Check if user is authenticated
 * @returns {boolean}
 */
function isAuthenticated() {
    const session = localStorage.getItem('akura_session');
    return session !== null;
}

/**
 * Get user role from localStorage
 * @returns {string | null} - 'athlete' or 'coach'
 */
function getUserRole() {
    return localStorage.getItem('akura_user_role');
}

/**
 * Get user name from localStorage
 * @returns {string | null}
 */
function getUserName() {
    return localStorage.getItem('akura_user_name');
}

/**
 * Redirect to appropriate dashboard based on user role
 */
function redirectToDashboard() {
    const role = getUserRole();
    
    if (role === 'coach') {
        window.location.href = 'coach-dashboard.html';
    } else {
        // Default to athlete dashboard
        window.location.href = 'athlete-dashboard.html';
    }
}

/**
 * Redirect to login page
 */
function redirectToLogin() {
    const currentPath = window.location.pathname;
    window.location.href = `login.html?redirect=${encodeURIComponent(currentPath)}`;
}

/**
 * Get redirect URL from query parameter
 * @returns {string | null}
 */
function getRedirectUrl() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('redirect');
}

// ===================================
// SESSION MANAGEMENT
// ===================================

/**
 * Initialize auth state listener
 * Automatically updates localStorage when auth state changes
 */
function initAuthStateListener() {
    if (!supabase) {
        console.warn('Supabase not initialized for auth state listener');
        return;
    }

    supabase.auth.onAuthStateChange((event, session) => {
        console.log('Auth state changed:', event);

        if (event === 'SIGNED_IN' && session) {
            // Update localStorage
            localStorage.setItem('akura_session', JSON.stringify(session));
            
            if (session.user?.user_metadata?.role) {
                localStorage.setItem('akura_user_role', session.user.user_metadata.role);
            }
            
            if (session.user?.user_metadata?.full_name) {
                localStorage.setItem('akura_user_name', session.user.user_metadata.full_name);
            }
        } else if (event === 'SIGNED_OUT') {
            // Clear localStorage
            localStorage.removeItem('akura_session');
            localStorage.removeItem('akura_user_role');
            localStorage.removeItem('akura_user_name');
        } else if (event === 'TOKEN_REFRESHED' && session) {
            // Update session in localStorage
            localStorage.setItem('akura_session', JSON.stringify(session));
        }
    });
}

// Initialize auth state listener when DOM is ready
if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            setTimeout(initAuthStateListener, 500); // Wait for Supabase to load
        });
    } else {
        setTimeout(initAuthStateListener, 500);
    }
}

// ===================================
// EXPORTS (for module systems)
// ===================================
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        register,
        login,
        logout,
        resetPassword,
        updatePassword,
        updateUserProfile,
        getCurrentUser,
        getSession,
        isAuthenticated,
        getUserRole,
        getUserName,
        redirectToDashboard,
        redirectToLogin,
        getRedirectUrl
    };
}
