/**
 * SafeStride Strava Integration Configuration
 * 
 * This file contains all configuration needed for the Strava auto-fill system
 * Update these values with your actual credentials
 */

const isLocalhost =
    window.location.hostname === 'localhost' ||
    window.location.hostname === '127.0.0.1';

const useLocalSupabase =
    isLocalhost &&
    (window.location.port === '8080' || window.location.port === '');

const supabaseConfig = useLocalSupabase
    ? {
        // Local Supabase (Docker)
        url: 'http://127.0.0.1:54321',
        anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
        functionsUrl: 'http://127.0.0.1:54321/functions/v1'
    }
    : {
        // Production Supabase (Cloud)
        url: 'https://bdisppaxbvygsspcuymb.supabase.co',
        anonKey: 'sb_publishable_BBjk8yeyQ2jgh5iFiQINUQ_mwU2FMnk',
        functionsUrl: 'https://bdisppaxbvygsspcuymb.supabase.co/functions/v1'
    };

const SAFESTRIDE_CONFIG = {
    // Supabase Configuration
    supabase: supabaseConfig,
    
    // Strava OAuth Configuration
    strava: {
        clientId: '162971',
        // Keep secrets out of frontend code. Use Supabase Edge Function env vars instead.
        clientSecret: '',
        redirectUri: isLocalhost
            ? 'http://localhost:8080/strava-callback.html'
            : window.location.origin + '/public/strava-callback.html',
        authorizeUrl: 'https://www.strava.com/oauth/authorize',
        tokenUrl: 'https://www.strava.com/oauth/token',
        apiUrl: 'https://www.strava.com/api/v3',
        scope: 'read,activity:read_all,profile:read_all',
        // Real Strava Dashboard Assets (updated from actual dashboard)
        assets: {
            css: [
                'https://d3nn82uaxijpm6.cloudfront.net/assets/strava-app-icons-61713d2ac89d70bdf7e4204f1ae8854a00b8c7a16f0de25b14610202104b5275.css',
                'https://d3nn82uaxijpm6.cloudfront.net/assets/strava-orion-040b2969ab017ba28840da8b0e661b38da3379ee9d91f970ca24c73839677a1d.css',
                'https://d3nn82uaxijpm6.cloudfront.net/assets/dashboard/show-3b0a095c10e536e0812031f0422e4e219079f3df9034b020540f0b8cba965d42.css'
            ],
            js: [
                'https://d3nn82uaxijpm6.cloudfront.net/packs/js/runtime-d5723e3ff5db5c0f8ca4.js',
                'https://d3nn82uaxijpm6.cloudfront.net/packs/js/vendor-d5723e3ff5db5c0f8ca4.js',
                'https://d3nn82uaxijpm6.cloudfront.net/packs/js/strava_with_framework-33e9ac57a03761457da7.js'
            ]
        }
    },
    
    // Feature Flags
    features: {
        autoFillEnabled: true,
        mlAnalysisEnabled: true,
        realTimeSync: true,
        activityImport: true,
        personalBests: true
    },
    
    // AISRI Configuration
    aisri: {
        // Pillar weights (must sum to 1.0)
        weights: {
            running: 0.40,
            strength: 0.15,
            rom: 0.12,
            balance: 0.13,
            alignment: 0.10,
            mobility: 0.10
        },
        
        // Risk thresholds
        riskThresholds: {
            low: 75,        // >= 75: Low risk
            medium: 55,     // >= 55: Medium risk
            high: 35,       // >= 35: High risk
            critical: 0     // < 35: Critical risk
        },
        
        // Training zone unlocks
        zoneUnlocks: {
            AR: 0,    // Active Recovery: Always available
            F: 0,     // Foundation: Always available
            EN: 40,   // Endurance: AISRI >= 40
            TH: 55,   // Threshold: AISRI >= 55
            P: 70,    // Power: AISRI >= 70
            SP: 85    // Speed: AISRI >= 85
        }
    },
    
    // Session Configuration
    session: {
        tokenKey: 'safestride_session',
        expiryHours: 24,
        rememberMeDays: 30
    },

    // Auth alias for compatibility with newer modules
    auth: {
        sessionKey: 'safestride_session',
        tokenExpiry: 3600000
    },
    
    // API Configuration
    api: {
        timeout: 30000, // 30 seconds
        retryAttempts: 3,
        retryDelay: 1000, // 1 second
        baseUrl: supabaseConfig.url,
        functionsUrl: supabaseConfig.functionsUrl
    },
    
    // UI Configuration
    ui: {
        animationDuration: 300,
        toastDuration: 3000,
        pageLoadTimeout: 10000
    },

    environment: isLocalhost ? 'development' : 'production',
    isLocal: useLocalSupabase
};

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SAFESTRIDE_CONFIG;
}

// Make available globally
if (typeof window !== 'undefined') {
    window.SAFESTRIDE_CONFIG = SAFESTRIDE_CONFIG;

    if (isLocalhost) {
        console.log('SafeStride config loaded:', {
            environment: SAFESTRIDE_CONFIG.environment,
            supabaseUrl: SAFESTRIDE_CONFIG.supabase.url,
            functionsUrl: SAFESTRIDE_CONFIG.supabase.functionsUrl
        });
    }
}
