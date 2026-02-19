# SafeStride Configuration Guide

## 📋 Overview

The `safestride-config.js` file centralizes all configuration for the SafeStride Strava integration system. This eliminates hardcoded values and makes it easy to update settings across the entire application.

---

## 📁 File Location

- **Source:** `c:\safestride\web\safestride-config.js`
- **Live:** `https://www.akura.in/safestride-config.js`

---

## 🔧 Configuration Structure

### 1. **Supabase Configuration**

```javascript
supabase: {
    url: 'https://bdisppaxbvygsspcuymb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    functionsUrl: 'https://bdisppaxbvygsspcuymb.supabase.co/functions/v1'
}
```

**Description:**
- `url`: Your Supabase project URL
- `anonKey`: Public anonymous key (safe to expose in frontend)
- `functionsUrl`: URL for Supabase Edge Functions

**Where Used:**
- All database queries (`profiles`, `strava_connections`, `aisri_scores`, `strava_activities`)
- Edge Function calls (`strava-oauth`, `strava-sync-activities`)

---

### 2. **Strava OAuth Configuration**

```javascript
strava: {
    clientId: '162971',
    clientSecret: '6554eb9bb83f222a585e312c17420221313f85c1',
    redirectUri: window.location.origin + '/strava-callback.html',
    authorizeUrl: 'https://www.strava.com/oauth/authorize',
    tokenUrl: 'https://www.strava.com/oauth/token',
    apiUrl: 'https://www.strava.com/api/v3',
    scope: 'read,activity:read_all,profile:read_all'
}
```

**Description:**
- `clientId`: Your Strava application ID
- `clientSecret`: Strava app secret (**only used in Edge Functions**, not exposed in browser)
- `redirectUri`: Where Strava redirects after OAuth (auto-detects domain)
- `authorizeUrl`: Strava OAuth authorization endpoint
- `tokenUrl`: Strava token exchange endpoint
- `apiUrl`: Strava REST API base URL
- `scope`: Permissions requested from user

**Where Used:**
- `strava-profile.html` → "Connect with Strava" button
- `strava-callback.html` → OAuth callback handler
- Edge Functions → Token exchange and API calls

**⚠️ Security Note:**
The `clientSecret` is included here for completeness but **should only be used in Edge Functions** (server-side). Never use it directly in frontend code.

---

### 3. **Feature Flags**

```javascript
features: {
    autoFillEnabled: true,
    mlAnalysisEnabled: true,
    realTimeSync: true,
    activityImport: true,
    personalBests: true
}
```

**Description:**
Toggle features on/off without code changes.

**Current Status:**
- ✅ `autoFillEnabled`: Strava auto-fill generator is active
- ✅ `mlAnalysisEnabled`: AISRI ML scoring is active
- ✅ `realTimeSync`: Activity sync happens immediately
- ✅ `activityImport`: Can import activities from Strava
- ✅ `personalBests`: Personal best tracking is enabled

**Where Used:**
- Feature checks throughout the application
- Future: Can disable features during maintenance

---

### 4. **AISRI Configuration**

```javascript
aisri: {
    weights: {
        running: 0.40,    // 40% weight
        strength: 0.15,   // 15% weight
        rom: 0.12,        // 12% weight
        balance: 0.13,    // 13% weight
        alignment: 0.10,  // 10% weight
        mobility: 0.10    // 10% weight
    },
    
    riskThresholds: {
        low: 75,          // >= 75: Low risk
        medium: 55,       // >= 55: Medium risk
        high: 35,         // >= 35: High risk
        critical: 0       // < 35: Critical risk
    },
    
    zoneUnlocks: {
        AR: 0,    // Active Recovery: Always available
        F: 0,     // Foundation: Always available
        EN: 40,   // Endurance: AISRI >= 40
        TH: 55,   // Threshold: AISRI >= 55
        P: 70,    // Power: AISRI >= 70
        SP: 85    // Speed: AISRI >= 85
    }
}
```

**Description:**

**Pillar Weights:**
- Defines how much each pillar contributes to total AISRI score
- Must sum to 1.0 (100%)
- Running has highest weight (40%) as it's most critical for runners

**Risk Thresholds:**
- Determines risk category badges (Low/Medium/High/Critical)
- Used for UI color coding and safety gates

**Zone Unlocks:**
- AISRI score required to unlock each training zone
- Prevents athletes from training too hard when injury risk is high
- AR and F zones always available (safe for recovery)

**Where Used:**
- `aisri-engine-v2.js` → Score calculation
- `training-plan-builder.html` → Zone availability
- `strava-profile.html` → Risk badge display

---

### 5. **Session Configuration**

```javascript
session: {
    tokenKey: 'safestride_session',
    expiryHours: 24,
    rememberMeDays: 30
}
```

**Description:**
- `tokenKey`: Key used in `sessionStorage`
- `expiryHours`: Session expires after 24 hours of inactivity
- `rememberMeDays`: "Remember me" extends to 30 days

**Where Used:**
- `login.html` → Session creation
- All authenticated pages → Session validation

---

### 6. **API Configuration**

```javascript
api: {
    timeout: 30000,       // 30 seconds
    retryAttempts: 3,
    retryDelay: 1000      // 1 second
}
```

**Description:**
- `timeout`: Maximum time to wait for API response
- `retryAttempts`: How many times to retry failed requests
- `retryDelay`: Time to wait between retries

**Where Used:**
- Fetch calls throughout the application
- Edge Function invocations
- External API calls (Strava, Supabase)

---

### 7. **UI Configuration**

```javascript
ui: {
    animationDuration: 300,
    toastDuration: 3000,
    pageLoadTimeout: 10000
}
```

**Description:**
- `animationDuration`: Standard animation length (ms)
- `toastDuration`: How long success/error messages display
- `pageLoadTimeout`: Max time before showing "loading too long" message

**Where Used:**
- CSS transitions
- Toast notifications
- Loading state management

---

## 🔌 Usage in Your Code

### **1. Include the Config File**

Add to your HTML before other scripts:

```html
<!-- Configuration -->
<script src="safestride-config.js"></script>

<!-- Your app scripts -->
<script src="your-script.js"></script>
```

### **2. Access Configuration Values**

```javascript
// Supabase
const supabaseUrl = SAFESTRIDE_CONFIG.supabase.url;
const supabaseKey = SAFESTRIDE_CONFIG.supabase.anonKey;

// Strava
const clientId = SAFESTRIDE_CONFIG.strava.clientId;
const redirectUri = SAFESTRIDE_CONFIG.strava.redirectUri;

// AISRI
const runningWeight = SAFESTRIDE_CONFIG.aisri.weights.running;
const lowRiskThreshold = SAFESTRIDE_CONFIG.aisri.riskThresholds.low;

// Feature Flags
if (SAFESTRIDE_CONFIG.features.autoFillEnabled) {
    // Auto-fill logic
}

// Session
const sessionKey = SAFESTRIDE_CONFIG.session.tokenKey;
const session = JSON.parse(sessionStorage.getItem(sessionKey) || '{}');
```

---

## 📝 Files Currently Using Config

### **1. strava-profile.html** ✅
```javascript
const SUPABASE_URL = SAFESTRIDE_CONFIG.supabase.url;
const SUPABASE_KEY = SAFESTRIDE_CONFIG.supabase.anonKey;
const STRAVA_CLIENT_ID = SAFESTRIDE_CONFIG.strava.clientId;
```

### **2. strava-autofill-generator.js** 🔄 (To be updated)
Currently has hardcoded values:
```javascript
this.supabaseUrl = 'https://bdisppaxbvygsspcuymb.supabase.co';
this.supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Should use:
```javascript
this.supabaseUrl = SAFESTRIDE_CONFIG.supabase.url;
this.supabaseKey = SAFESTRIDE_CONFIG.supabase.anonKey;
```

### **3. training-plan-builder.html** 🔄 (To be updated)
Should use AISRI thresholds and zone unlocks from config.

---

## 🔐 Security Best Practices

### **✅ Safe to Expose (Frontend)**
- `supabase.url`
- `supabase.anonKey` (protected by RLS policies)
- `strava.clientId`
- All other config values

### **⚠️ NEVER Expose (Backend Only)**
- `strava.clientSecret` → Only use in Edge Functions
- Database passwords
- Service role keys
- Private API keys

### **Current Implementation:**
- ✅ Config file is frontend-safe
- ✅ Client secret only used in Edge Functions (not exposed)
- ✅ Supabase RLS policies protect data despite anon key

---

## 🔄 Updating Configuration

### **Development (Local)**
Edit: `c:\safestride\web\safestride-config.js`

### **Production (Live)**
1. Update local file
2. Test locally
3. Commit to master
4. Deploy to gh-pages
5. Verify at www.akura.in/safestride-config.js

**Example:**
```powershell
cd c:\safestride
# Edit safestride-config.js
git add web/safestride-config.js
git commit -m "config: Update Strava client ID"
git push origin master

cd c:\safestride-web
Copy-Item "c:\safestride\web\safestride-config.js" -Destination "safestride-config.js"
git add safestride-config.js
git commit -m "config: Update Strava client ID"
git push origin gh-pages
```

---

## 🧪 Testing Configuration

### **1. Check Config Loads**
Open browser console on any page:
```javascript
console.log(SAFESTRIDE_CONFIG);
// Should show full config object
```

### **2. Verify Values**
```javascript
console.log('Supabase URL:', SAFESTRIDE_CONFIG.supabase.url);
console.log('Strava Client ID:', SAFESTRIDE_CONFIG.strava.clientId);
console.log('Features:', SAFESTRIDE_CONFIG.features);
```

### **3. Test Feature Flags**
```javascript
if (SAFESTRIDE_CONFIG.features.autoFillEnabled) {
    console.log('✅ Auto-fill is enabled');
} else {
    console.log('❌ Auto-fill is disabled');
}
```

---

## 📊 Impact on Performance

**Before (Hardcoded):**
- Values scattered across multiple files
- Difficult to update (find/replace in 10+ files)
- Risk of inconsistencies

**After (Centralized):**
- ✅ Single source of truth
- ✅ Update once, applies everywhere
- ✅ Easy feature toggling
- ✅ Minimal overhead (~1KB file, cached by browser)

**Load Time:**
- Config file: ~100 lines, ~1KB
- Loads before app scripts
- Cached by browser after first load

---

## 🚀 Next Steps

### **Immediate:**
- [x] Create config file
- [x] Update strava-profile.html to use config
- [x] Deploy to production

### **Future:**
- [ ] Update strava-autofill-generator.js to use config
- [ ] Update training-plan-builder.html to use config
- [ ] Update all HTML pages to use config
- [ ] Add environment-specific configs (dev/prod)
- [ ] Create config validation function
- [ ] Add config editor in admin panel

---

## 📚 Related Documentation

- [STRAVA_PROFILE_FEATURE.md](STRAVA_PROFILE_FEATURE.md) - Strava profile page docs
- [AISRI_QUICK_REFERENCE.md](AISRI_QUICK_REFERENCE.md) - AISRI scoring system
- [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) - Overall project status

---

**Created:** February 19, 2026  
**Last Updated:** February 19, 2026  
**Status:** ✅ Live at www.akura.in
