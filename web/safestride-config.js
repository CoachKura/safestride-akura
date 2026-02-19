/**
 * SafeStride Strava Integration Configuration
 *
 * This file contains all configuration needed for the Strava auto-fill system
 * Update these values with your actual credentials
 */

const SAFESTRIDE_CONFIG = {
  // Supabase Configuration
  supabase: {
    url: "https://bdisppaxbvygsspcuymb.supabase.co",
    anonKey:
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY4MjM4OTEsImV4cCI6MjA1MjM5OTg5MX0.4vYk5u3AijkkNMB0JxFy0t2dNUPPGS8BnpWCym_hl_w",
    functionsUrl: "https://bdisppaxbvygsspcuymb.supabase.co/functions/v1",
  },

  // Strava OAuth Configuration
  strava: {
    clientId: "162971",
    clientSecret: "6554eb9bb83f222a585e312c17420221313f85c1", // Only used in edge functions
    redirectUri: window.location.origin + "/strava-callback.html",
    authorizeUrl: "https://www.strava.com/oauth/authorize",
    tokenUrl: "https://www.strava.com/oauth/token",
    apiUrl: "https://www.strava.com/api/v3",
    scope: "read,activity:read_all,profile:read_all",
  },

  // Feature Flags
  features: {
    autoFillEnabled: true,
    mlAnalysisEnabled: true,
    realTimeSync: true,
    activityImport: true,
    personalBests: true,
  },

  // AISRI Configuration
  aisri: {
    // Pillar weights (must sum to 1.0)
    weights: {
      running: 0.4,
      strength: 0.15,
      rom: 0.12,
      balance: 0.13,
      alignment: 0.1,
      mobility: 0.1,
    },

    // Risk thresholds
    riskThresholds: {
      low: 75, // >= 75: Low risk
      medium: 55, // >= 55: Medium risk
      high: 35, // >= 35: High risk
      critical: 0, // < 35: Critical risk
    },

    // Training zone unlocks
    zoneUnlocks: {
      AR: 0, // Active Recovery: Always available
      F: 0, // Foundation: Always available
      EN: 40, // Endurance: AISRI >= 40
      TH: 55, // Threshold: AISRI >= 55
      P: 70, // Power: AISRI >= 70
      SP: 85, // Speed: AISRI >= 85
    },
  },

  // Session Configuration
  session: {
    tokenKey: "safestride_session",
    expiryHours: 24,
    rememberMeDays: 30,
  },

  // API Configuration
  api: {
    timeout: 30000, // 30 seconds
    retryAttempts: 3,
    retryDelay: 1000, // 1 second
  },

  // UI Configuration
  ui: {
    animationDuration: 300,
    toastDuration: 3000,
    pageLoadTimeout: 10000,
  },
};

// Export for use in other modules
if (typeof module !== "undefined" && module.exports) {
  module.exports = SAFESTRIDE_CONFIG;
}

// Make available globally
if (typeof window !== "undefined") {
  window.SAFESTRIDE_CONFIG = SAFESTRIDE_CONFIG;
}
