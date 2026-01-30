// ===================================
// AKURA SafeStride Auth Guard
// Advanced route protection with role-based access
// ===================================

const AuthGuard = {
    /**
     * Initialize auth guard
     */
    async init() {
        console.log('🛡️ Auth Guard initialized');
        
        // Check if user is authenticated
        if (!Auth.isAuthenticated()) {
            console.log('User not authenticated, redirecting to login...');
            this.redirectToLogin();
            return;
        }

        // Check page-specific access requirements
        await this.checkPageAccess();

        // Monitor session status
        this.monitorSession();
    },

    /**
     * Check page access based on requirements
     */
    async checkPageAccess() {
        const currentPage = window.location.pathname.split('/').pop();
        console.log('Checking access for page:', currentPage);

        // Get user data
        const user = await Auth.getCurrentUser();
        if (!user) {
            this.redirectToLogin();
            return;
        }

        const metadata = user.user_metadata || {};
        const role = metadata.role || 'athlete';
        const accessLevel = metadata.access_level || 'demo';
        const assessmentCompleted = metadata.assessment_completed || false;

        // Define page access rules
        const pageRules = {
            // Public pages (no auth required)
            'index.html': { authRequired: false },
            'login.html': { authRequired: false },
            'register.html': { authRequired: false },
            'forgot-password.html': { authRequired: false },
            'reset-password.html': { authRequired: false },

            // Assessment page (auth required, no assessment needed)
            'aifri-assessment.html': {
                authRequired: true,
                assessmentRequired: false,
                minAccessLevel: 'demo'
            },

            // Demo dashboard (auth required, assessment completed)
            'demo-dashboard.html': {
                authRequired: true,
                assessmentRequired: true,
                minAccessLevel: 'demo',
                maxAccessLevel: 'demo' // Only demo users
            },

            // Athlete pages (full access required)
            'athlete-dashboard.html': {
                authRequired: true,
                assessmentRequired: true,
                minAccessLevel: 'full',
                allowedRoles: ['athlete']
            },
            'training-plans.html': {
                authRequired: true,
                assessmentRequired: true,
                minAccessLevel: 'full',
                allowedRoles: ['athlete']
            },
            'workout-tracking.html': {
                authRequired: true,
                assessmentRequired: true,
                minAccessLevel: 'full',
                allowedRoles: ['athlete']
            },
            'progress-charts.html': {
                authRequired: true,
                assessmentRequired: true,
                minAccessLevel: 'full',
                allowedRoles: ['athlete']
            },

            // Coach pages (full access required)
            'coach-dashboard.html': {
                authRequired: true,
                assessmentRequired: false,
                minAccessLevel: 'full',
                allowedRoles: ['coach']
            },
            'athlete-management.html': {
                authRequired: true,
                assessmentRequired: false,
                minAccessLevel: 'full',
                allowedRoles: ['coach']
            },
            'protocol-creation.html': {
                authRequired: true,
                assessmentRequired: false,
                minAccessLevel: 'full',
                allowedRoles: ['coach']
            }
        };

        // Get rules for current page
        const rules = pageRules[currentPage];
        if (!rules) {
            console.log('No access rules defined for:', currentPage);
            return; // Allow access if no rules defined
        }

        // Check authentication
        if (rules.authRequired && !user) {
            console.log('Auth required but user not logged in');
            this.redirectToLogin();
            return;
        }

        // Check assessment completion
        if (rules.assessmentRequired && !assessmentCompleted) {
            console.log('Assessment required but not completed');
            this.showAccessDenied('Please complete your AIFRI assessment first');
            setTimeout(() => {
                window.location.href = 'aifri-assessment.html';
            }, 2000);
            return;
        }

        // Check access level
        if (rules.minAccessLevel) {
            const hasAccess = await Auth.checkAccessLevel(rules.minAccessLevel);
            if (!hasAccess) {
                console.log('Insufficient access level:', accessLevel, 'required:', rules.minAccessLevel);
                this.showAccessDenied('This feature requires full access');
                setTimeout(() => {
                    window.location.href = 'demo-dashboard.html';
                }, 2000);
                return;
            }
        }

        // Check max access level (for demo-only pages)
        if (rules.maxAccessLevel) {
            const accessHierarchy = ['demo', 'full', 'premium'];
            const userLevelIndex = accessHierarchy.indexOf(accessLevel);
            const maxLevelIndex = accessHierarchy.indexOf(rules.maxAccessLevel);
            
            if (userLevelIndex > maxLevelIndex) {
                console.log('Access level too high for demo page, redirecting to full dashboard');
                const redirectPath = await Auth.getRedirectPath();
                window.location.href = redirectPath;
                return;
            }
        }

        // Check role
        if (rules.allowedRoles && !rules.allowedRoles.includes(role)) {
            console.log('Role not allowed:', role, 'allowed:', rules.allowedRoles);
            this.showAccessDenied('You do not have permission to access this page');
            setTimeout(() => {
                const redirectPath = role === 'coach' ? 'coach-dashboard.html' : 'athlete-dashboard.html';
                window.location.href = redirectPath;
            }, 2000);
            return;
        }

        console.log('✅ Access granted for:', currentPage);
    },

    /**
     * Redirect to login page
     */
    redirectToLogin() {
        const currentPage = window.location.pathname;
        const loginUrl = `login.html?redirect=${encodeURIComponent(currentPage)}`;
        window.location.href = loginUrl;
    },

    /**
     * Show access denied message
     * @param {string} message - Error message
     */
    showAccessDenied(message) {
        // Create overlay
        const overlay = document.createElement('div');
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.95);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
        `;

        // Create message box
        const messageBox = document.createElement('div');
        messageBox.style.cssText = `
            background: white;
            padding: 40px;
            border-radius: 12px;
            text-align: center;
            max-width: 400px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        `;

        messageBox.innerHTML = `
            <div style="font-size: 48px; margin-bottom: 20px;">🔒</div>
            <h2 style="margin-bottom: 12px; color: #1E293B;">Access Denied</h2>
            <p style="color: #64748B; margin-bottom: 24px;">${message}</p>
            <div style="display: flex; align-items: center; justify-content: center; gap: 8px; color: #3B82F6;">
                <i class="fas fa-spinner fa-spin"></i>
                <span>Redirecting...</span>
            </div>
        `;

        overlay.appendChild(messageBox);
        document.body.appendChild(overlay);
    },

    /**
     * Monitor session status
     */
    monitorSession() {
        // Check session every 5 minutes
        setInterval(async () => {
            const user = await Auth.getCurrentUser();
            if (!user) {
                console.log('Session expired, redirecting to login...');
                this.redirectToLogin();
            }
        }, 5 * 60 * 1000);
    },

    /**
     * Require demo access
     * @returns {Promise<boolean>} - True if has demo access
     */
    async requireDemoAccess() {
        return await Auth.checkAccessLevel('demo');
    },

    /**
     * Require full access
     * @returns {Promise<boolean>} - True if has full access
     */
    async requireFullAccess() {
        return await Auth.checkAccessLevel('full');
    },

    /**
     * Require premium access
     * @returns {Promise<boolean>} - True if has premium access
     */
    async requirePremiumAccess() {
        return await Auth.checkAccessLevel('premium');
    },

    /**
     * Require specific role
     * @param {string} role - Required role
     * @returns {Promise<boolean>} - True if user has role
     */
    async requireRole(role) {
        const userRole = await Auth.getUserRole();
        return userRole === role;
    },

    /**
     * Require athlete role
     * @returns {Promise<boolean>} - True if user is athlete
     */
    async requireAthlete() {
        return await this.requireRole('athlete');
    },

    /**
     * Require coach role
     * @returns {Promise<boolean>} - True if user is coach
     */
    async requireCoach() {
        return await this.requireRole('coach');
    },

    /**
     * Show upgrade prompt
     * @param {string} feature - Feature name
     */
    showUpgradePrompt(feature) {
        const overlay = document.createElement('div');
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.8);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
        `;

        const promptBox = document.createElement('div');
        promptBox.style.cssText = `
            background: white;
            padding: 40px;
            border-radius: 16px;
            text-align: center;
            max-width: 480px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        `;

        promptBox.innerHTML = `
            <div style="font-size: 64px; margin-bottom: 20px;">🔓</div>
            <h2 style="margin-bottom: 12px; color: #1E293B; font-size: 28px;">Unlock ${feature}</h2>
            <p style="color: #64748B; margin-bottom: 32px; font-size: 16px; line-height: 1.6;">
                Upgrade to full access to unlock all features, personalized training plans, and unlimited progress tracking.
            </p>
            <div style="display: flex; gap: 12px; justify-content: center;">
                <button id="upgradeBtn" style="
                    background: linear-gradient(135deg, #3B82F6, #10B981);
                    color: white;
                    border: none;
                    padding: 14px 32px;
                    border-radius: 8px;
                    font-weight: 600;
                    font-size: 16px;
                    cursor: pointer;
                ">Upgrade Now</button>
                <button id="closeUpgradeBtn" style="
                    background: white;
                    color: #64748B;
                    border: 2px solid #E2E8F0;
                    padding: 14px 32px;
                    border-radius: 8px;
                    font-weight: 600;
                    font-size: 16px;
                    cursor: pointer;
                ">Maybe Later</button>
            </div>
        `;

        overlay.appendChild(promptBox);
        document.body.appendChild(overlay);

        // Event listeners
        document.getElementById('upgradeBtn').addEventListener('click', () => {
            window.location.href = 'upgrade.html'; // Create upgrade page
        });

        document.getElementById('closeUpgradeBtn').addEventListener('click', () => {
            overlay.remove();
        });

        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                overlay.remove();
            }
        });
    }
};

// ===================================
// AUTO-INITIALIZE ON PAGE LOAD
// ===================================

document.addEventListener('DOMContentLoaded', async () => {
    // Ensure the auth library is initialized. Prefer AkuraAuth if available.
    if (typeof AkuraAuth !== 'undefined' && typeof AkuraAuth.isReady === 'function') {
        // Wait for AkuraAuth to be ready (poll briefly)
        let attempts = 0;
        while (!AkuraAuth.isReady() && attempts < 50) {
            await new Promise(resolve => setTimeout(resolve, 100));
            attempts++;
        }
    } else if (typeof Auth !== 'undefined' && typeof Auth.init === 'function') {
        Auth.init();
    }

    await AuthGuard.init();
});

// ===================================
// CONSOLE LOG
// ===================================

console.log('🛡️ AKURA Auth Guard loaded');

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AuthGuard;
}