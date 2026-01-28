/**
 * AKURA SafeStride Authentication Guard
 * 
 * Include this script on pages that require authentication:
 * <script src="js/auth.js"></script>
 * <script src="js/auth-guard.js"></script>
 * 
 * The guard will:
 * 1. Check if user is authenticated
 * 2. Verify session validity
 * 3. Redirect to login if not authenticated
 * 4. Allow access if authenticated
 */

(function() {
    'use strict';

    // Configuration
    const AUTH_CHECK_DELAY = 100; // ms to wait for Supabase init
    const SESSION_CHECK_INTERVAL = 60000; // Check session every 60 seconds

    // Pages that don't require authentication
    const PUBLIC_PAGES = [
        '/login.html',
        '/register.html',
        '/forgot-password.html',
        '/reset-password.html',
        '/index.html',
        '/'
    ];

    // Pages that require specific roles
    const ROLE_RESTRICTED_PAGES = {
        '/coach-dashboard.html': 'coach',
        '/athlete-dashboard.html': 'athlete'
    };

    /**
     * Check if current page requires authentication
     */
    function requiresAuth() {
        const path = window.location.pathname;
        return !PUBLIC_PAGES.some(page => path.endsWith(page));
    }

    /**
     * Check if current page has role restrictions
     */
    function getRequiredRole() {
        const path = window.location.pathname;
        
        for (const [page, role] of Object.entries(ROLE_RESTRICTED_PAGES)) {
            if (path.endsWith(page)) {
                return role;
            }
        }
        
        return null;
    }

    /**
     * Perform authentication check
     */
    async function performAuthCheck() {
        // Skip check for public pages
        if (!requiresAuth()) {
            return;
        }

        // Check if user has a session in localStorage
        if (!isAuthenticated()) {
            console.warn('No authentication session found. Redirecting to login...');
            redirectToLogin();
            return;
        }

        // Verify session with Supabase
        try {
            const { session } = await getSession();
            
            if (!session) {
                console.warn('Session expired or invalid. Redirecting to login...');
                localStorage.removeItem('akura_session');
                localStorage.removeItem('akura_user_role');
                localStorage.removeItem('akura_user_name');
                redirectToLogin();
                return;
            }

            // Check role-based access
            const requiredRole = getRequiredRole();
            if (requiredRole) {
                const userRole = getUserRole();
                
                if (userRole !== requiredRole) {
                    console.warn(`Access denied. Required role: ${requiredRole}, User role: ${userRole}`);
                    
                    // Redirect to appropriate dashboard
                    if (userRole === 'coach') {
                        window.location.href = 'coach-dashboard.html';
                    } else if (userRole === 'athlete') {
                        window.location.href = 'athlete-dashboard.html';
                    } else {
                        redirectToLogin();
                    }
                    return;
                }
            }

            // User is authenticated and authorized
            console.log('✓ Authentication check passed');
            
            // Show protected content
            showProtectedContent();
            
        } catch (error) {
            console.error('Auth check error:', error);
            // On error, redirect to login to be safe
            redirectToLogin();
        }
    }

    /**
     * Show protected content (remove loading overlay if present)
     */
    function showProtectedContent() {
        // Remove auth-loading class from body if present
        document.body.classList.remove('auth-loading');
        
        // Hide loading overlay if present
        const loadingOverlay = document.getElementById('auth-loading-overlay');
        if (loadingOverlay) {
            loadingOverlay.style.display = 'none';
        }
        
        // Show main content
        const mainContent = document.getElementById('main-content');
        if (mainContent) {
            mainContent.style.display = 'block';
        }
    }

    /**
     * Periodic session validation
     */
    function startSessionMonitoring() {
        setInterval(async () => {
            if (!requiresAuth()) {
                return;
            }

            const { session } = await getSession();
            
            if (!session) {
                console.warn('Session expired during use. Redirecting to login...');
                localStorage.clear();
                
                // Show alert before redirect
                if (typeof showAlert === 'function') {
                    showAlert('error', 'Your session has expired. Please log in again.');
                }
                
                setTimeout(() => {
                    redirectToLogin();
                }, 2000);
            }
        }, SESSION_CHECK_INTERVAL);
    }

    /**
     * Initialize auth guard
     */
    function initAuthGuard() {
        // Add loading class to body while checking auth
        if (requiresAuth()) {
            document.body.classList.add('auth-loading');
        }

        // Perform auth check after a short delay to allow Supabase to initialize
        setTimeout(async () => {
            await performAuthCheck();
            
            // Start session monitoring for authenticated pages
            if (requiresAuth()) {
                startSessionMonitoring();
            }
        }, AUTH_CHECK_DELAY);
    }

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAuthGuard);
    } else {
        initAuthGuard();
    }

    // Add loading styles if not already present
    if (!document.getElementById('auth-guard-styles')) {
        const style = document.createElement('style');
        style.id = 'auth-guard-styles';
        style.textContent = `
            body.auth-loading {
                overflow: hidden;
            }
            
            body.auth-loading::before {
                content: '';
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(255, 255, 255, 0.9);
                z-index: 9999;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            body.auth-loading::after {
                content: 'Verifying authentication...';
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                z-index: 10000;
                font-size: 1rem;
                color: #6B7280;
                font-family: 'Inter', sans-serif;
            }
        `;
        document.head.appendChild(style);
    }

})();

/**
 * Utility function to add logout functionality to buttons
 * Usage: Add onclick="handleLogout()" to your logout buttons
 */
async function handleLogout() {
    if (confirm('Are you sure you want to log out?')) {
        const result = await logout();
        
        if (result.success) {
            window.location.href = 'login.html';
        } else {
            alert('Logout failed: ' + (result.error || 'Unknown error'));
        }
    }
}

/**
 * Utility function to display user info
 * Usage: Call displayUserInfo() in your dashboard pages
 */
async function displayUserInfo() {
    const userName = getUserName();
    const userRole = getUserRole();
    
    // Update DOM elements with user info
    const userNameElements = document.querySelectorAll('[data-user-name]');
    userNameElements.forEach(el => {
        el.textContent = userName || 'User';
    });
    
    const userRoleElements = document.querySelectorAll('[data-user-role]');
    userRoleElements.forEach(el => {
        el.textContent = userRole ? (userRole.charAt(0).toUpperCase() + userRole.slice(1)) : '';
    });
    
    // Get full user data from Supabase
    const { user } = await getCurrentUser();
    
    if (user) {
        // Update email
        const userEmailElements = document.querySelectorAll('[data-user-email]');
        userEmailElements.forEach(el => {
            el.textContent = user.email || '';
        });
        
        // Update avatar (if you have user avatars)
        const userAvatarElements = document.querySelectorAll('[data-user-avatar]');
        userAvatarElements.forEach(el => {
            if (user.user_metadata?.avatar_url) {
                el.src = user.user_metadata.avatar_url;
            }
        });
    }
}
