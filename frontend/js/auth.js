// ===================================
// AKURA SafeStride Enhanced Authentication
// With role-based access and redirect logic
// ===================================

// Supabase Configuration
const SUPABASE_URL = "https://yawxlwcniqfspcgefuro.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTcxODksImV4cCI6MjA4NTA3MzE4OX0.eky8ua6lEhzPcvG289wWDMWOjVGwr-bL8LLUnrzO4r4";

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Authentication object
const Auth = {
    // ===================================
    // AUTHENTICATION METHODS
    // ===================================

    /**
     * Register a new user
     * @param {string} email - User's email
     * @param {string} password - User's password
     * @param {string} fullName - User's full name
     * @param {string} role - User's role (athlete/coach)
     * @returns {Promise<Object>} - Result object
     */
    async register(email, password, fullName, role = 'athlete') {
        try {
            // Create user account
            const { data, error } = await supabase.auth.signUp({
                email: email,
                password: password,
                options: {
                    data: {
                        full_name: fullName,
                        role: role,
                        access_level: 'demo', // New users start with demo access
                        assessment_completed: false,
                        first_login: new Date().toISOString()
                    }
                }
            });

            if (error) {
                console.error('Registration error:', error);
                return {
                    success: false,
                    error: error.message || 'Registration failed'
                };
            }

            if (data.user) {
                console.log('User registered successfully:', data.user.id);
                
                // Store user metadata
                await this.updateUserMetadata({
                    full_name: fullName,
                    role: role,
                    access_level: 'demo',
                    assessment_completed: false
                });

                return {
                    success: true,
                    user: data.user
                };
            }

            return {
                success: false,
                error: 'Registration failed - no user data returned'
            };
        } catch (error) {
            console.error('Registration error:', error);
            return {
                success: false,
                error: error.message || 'An unexpected error occurred'
            };
        }
    },

    /**
     * Login user
     * @param {string} email - User's email
     * @param {string} password - User's password
     * @returns {Promise<Object>} - Result object
     */
    async login(email, password) {
        try {
            const { data, error } = await supabase.auth.signInWithPassword({
                email: email,
                password: password
            });

            if (error) {
                console.error('Login error:', error);
                return {
                    success: false,
                    error: error.message || 'Invalid email or password'
                };
            }

            if (data.user) {
                console.log('User logged in successfully:', data.user.id);
                
                // Store session data
                this.storeSession(data.session);
                
                // Get redirect path based on user status
                const redirectPath = await this.getRedirectPath();
                
                // Redirect user
                setTimeout(() => {
                    window.location.href = redirectPath;
                }, 500);

                return {
                    success: true,
                    user: data.user,
                    redirectPath: redirectPath
                };
            }

            return {
                success: false,
                error: 'Login failed - no user data returned'
            };
        } catch (error) {
            console.error('Login error:', error);
            return {
                success: false,
                error: error.message || 'An unexpected error occurred'
            };
        }
    },

    /**
     * Logout user
     * @returns {Promise<Object>} - Result object
     */
    async logout() {
        try {
            const { error } = await supabase.auth.signOut();
            
            if (error) {
                console.error('Logout error:', error);
                return {
                    success: false,
                    error: error.message
                };
            }

            // Clear local storage
            this.clearSession();

            // Redirect to homepage
            window.location.href = 'index.html';

            return { success: true };
        } catch (error) {
            console.error('Logout error:', error);
            return {
                success: false,
                error: error.message || 'Logout failed'
            };
        }
    },

    /**
     * Get current user
     * @returns {Promise<Object|null>} - User object or null
     */
    async getCurrentUser() {
        try {
            const { data: { user }, error } = await supabase.auth.getUser();
            
            if (error) {
                console.error('Get user error:', error);
                return null;
            }

            return user;
        } catch (error) {
            console.error('Get user error:', error);
            return null;
        }
    },

    /**
     * Check if user is authenticated
     * @returns {boolean} - True if authenticated
     */
    isAuthenticated() {
        const session = localStorage.getItem('akura_session');
        return session !== null;
    },

    /**
     * Get user metadata
     * @returns {Promise<Object>} - User metadata
     */
    async getUserMetadata() {
        const user = await this.getCurrentUser();
        if (!user) return null;

        return user.user_metadata || {};
    },

    /**
     * Update user metadata
     * @param {Object} metadata - Metadata to update
     * @returns {Promise<Object>} - Result object
     */
    async updateUserMetadata(metadata) {
        try {
            const { data, error } = await supabase.auth.updateUser({
                data: metadata
            });

            if (error) {
                console.error('Update metadata error:', error);
                return { success: false, error: error.message };
            }

            return { success: true, user: data.user };
        } catch (error) {
            console.error('Update metadata error:', error);
            return { success: false, error: error.message };
        }
    },

    // ===================================
    // ACCESS CONTROL & REDIRECT LOGIC
    // ===================================

    /**
     * Get redirect path based on user status
     * @returns {Promise<string>} - Redirect path
     */
    async getRedirectPath() {
        const user = await this.getCurrentUser();
        if (!user) return 'login.html';

        const metadata = user.user_metadata || {};
        const role = metadata.role || 'athlete';
        const accessLevel = metadata.access_level || 'demo';
        const assessmentCompleted = metadata.assessment_completed || false;

        console.log('User metadata:', metadata);
        console.log('Redirect logic - Role:', role, 'Access:', accessLevel, 'Assessment:', assessmentCompleted);

        // NEW USER FLOW: First time user → AIFRI Assessment
        if (!assessmentCompleted) {
            return 'aifri-assessment.html';
        }

        // DEMO ACCESS FLOW: Assessment completed but demo access → Demo Dashboard
        if (accessLevel === 'demo') {
            return 'demo-dashboard.html';
        }

        // FULL ACCESS FLOW: Role-based redirect
        if (role === 'coach') {
            return 'coach-dashboard.html';
        } else {
            return 'athlete-dashboard.html';
        }
    },

    /**
     * Check user access level
     * @param {string} requiredLevel - Required access level (demo, full, premium)
     * @returns {Promise<boolean>} - True if user has required access
     */
    async checkAccessLevel(requiredLevel) {
        const metadata = await this.getUserMetadata();
        if (!metadata) return false;

        const userAccessLevel = metadata.access_level || 'demo';
        
        const accessHierarchy = ['demo', 'full', 'premium'];
        const userLevel = accessHierarchy.indexOf(userAccessLevel);
        const requiredLevelIndex = accessHierarchy.indexOf(requiredLevel);

        return userLevel >= requiredLevelIndex;
    },

    /**
     * Check if user completed assessment
     * @returns {Promise<boolean>} - True if assessment completed
     */
    async isAssessmentCompleted() {
        const metadata = await this.getUserMetadata();
        return metadata?.assessment_completed || false;
    },

    /**
     * Mark assessment as completed
     * @returns {Promise<Object>} - Result object
     */
    async markAssessmentCompleted() {
        return await this.updateUserMetadata({
            assessment_completed: true
        });
    },

    /**
     * Upgrade user access level
     * @param {string} newLevel - New access level (full, premium)
     * @returns {Promise<Object>} - Result object
     */
    async upgradeAccessLevel(newLevel) {
        return await this.updateUserMetadata({
            access_level: newLevel
        });
    },

    // ===================================
    // SESSION MANAGEMENT
    // ===================================

    /**
     * Store session data
     * @param {Object} session - Session object
     */
    storeSession(session) {
        if (session) {
            localStorage.setItem('akura_session', JSON.stringify(session));
            localStorage.setItem('akura_access_token', session.access_token);
            localStorage.setItem('akura_refresh_token', session.refresh_token);
        }
    },

    /**
     * Clear session data
     */
    clearSession() {
        localStorage.removeItem('akura_session');
        localStorage.removeItem('akura_access_token');
        localStorage.removeItem('akura_refresh_token');
        localStorage.removeItem('akura_remember_me');
    },

    /**
     * Refresh session
     * @returns {Promise<Object>} - Result object
     */
    async refreshSession() {
        try {
            const { data, error } = await supabase.auth.refreshSession();
            
            if (error) {
                console.error('Refresh session error:', error);
                return { success: false, error: error.message };
            }

            if (data.session) {
                this.storeSession(data.session);
                return { success: true, session: data.session };
            }

            return { success: false, error: 'No session data' };
        } catch (error) {
            console.error('Refresh session error:', error);
            return { success: false, error: error.message };
        }
    },

    // ===================================
    // PASSWORD RESET
    // ===================================

    /**
     * Request password reset
     * @param {string} email - User's email
     * @returns {Promise<Object>} - Result object
     */
    async resetPassword(email) {
        try {
            const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/reset-password.html`
            });

            if (error) {
                console.error('Password reset error:', error);
                return { success: false, error: error.message };
            }

            return { success: true };
        } catch (error) {
            console.error('Password reset error:', error);
            return { success: false, error: error.message };
        }
    },

    /**
     * Update password
     * @param {string} newPassword - New password
     * @returns {Promise<Object>} - Result object
     */
    async updatePassword(newPassword) {
        try {
            const { data, error } = await supabase.auth.updateUser({
                password: newPassword
            });

            if (error) {
                console.error('Update password error:', error);
                return { success: false, error: error.message };
            }

            return { success: true };
        } catch (error) {
            console.error('Update password error:', error);
            return { success: false, error: error.message };
        }
    },

    // ===================================
    // UTILITY METHODS
    // ===================================

    /**
     * Get user role
     * @returns {Promise<string>} - User role
     */
    async getUserRole() {
        const metadata = await this.getUserMetadata();
        return metadata?.role || 'athlete';
    },

    /**
     * Get user access level
     * @returns {Promise<string>} - User access level
     */
    async getUserAccessLevel() {
        const metadata = await this.getUserMetadata();
        return metadata?.access_level || 'demo';
    },

    /**
     * Get user display name
     * @returns {Promise<string>} - User's full name
     */
    async getUserDisplayName() {
        const metadata = await this.getUserMetadata();
        return metadata?.full_name || 'User';
    }
};

// ===================================
// AUTO-REFRESH SESSION
// ===================================

// Check and refresh session every 30 minutes
setInterval(async () => {
    if (Auth.isAuthenticated()) {
        await Auth.refreshSession();
    }
}, 30 * 60 * 1000);

// ===================================
// CONSOLE LOG
// ===================================

console.log('🏃 AKURA Auth initialized');

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Auth;
}