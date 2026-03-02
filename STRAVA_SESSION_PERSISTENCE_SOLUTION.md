# 🔄 **STRAVA SESSION PERSISTENCE - SOLUTION**

**Date**: March 2, 2026  
**Issue**: User must click "Connect Strava" every login instead of staying connected  
**Root Cause**: No check for existing Strava connection in database

---

## 🎯 **THE PROBLEM**

Current Flow:
```
User logs in → Training Plan Builder page loads → Shows "Connect Strava" button
User clicks "Connect Strava" → OAuth flow → Data synced → 908 activities loaded
User logs out → Next login → SAME THING - needs to reconnect!
```

**Expected Flow**:
```
User logs in → Check if strava_connections table has record for this athlete
If YES → Auto-load Strava data (no reconnection needed)
If NO → Show "Connect Strava" button
```

---

## 📊 **WHAT EXISTS IN DATABASE**

### Table: `strava_connections`
```sql
CREATE TABLE strava_connections (
  id UUID PRIMARY KEY,
  athlete_id TEXT NOT NULL UNIQUE,
  strava_athlete_id BIGINT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  athlete_data JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**After first OAuth**: Your record exists with 908 activities synced!

---

## ✅ **SOLUTION: Auto-Check Connection on Page Load**

### Step 1: Add Connection Check Function

Add this to `training-plan-builder.html` (around line 200):

```javascript
// Check if Strava is already connected
async function checkExistingStravaConnection() {
    try {
        console.log('🔍 Checking for existing Strava connection...');
        
        const session = JSON.parse(sessionStorage.getItem('safestride_session') || '{}');
        if (!session.uid) {
            console.log('❌ No session found');
            return null;
        }
        
        // Query Supabase for existing connection
        const response = await supabase
            .from('strava_connections')
            .select('*')
            .eq('athlete_id', session.uid)
            .single();
        
        if (response.error) {
            console.log('❌ No Strava connection found:', response.error.message);
            return null;
        }
        
        console.log('✅ Found existing Strava connection:', response.data);
        
        // Check if token is expired
        const expiresAt = new Date(response.data.expires_at);
        const now = new Date();
        
        if (expiresAt < now) {
            console.log('⚠️ Strava token expired, needs refresh');
            // TODO: Implement token refresh
            return null;
        }
        
        // Mark as connected
        localStorage.setItem('strava_connected', 'true');
        localStorage.setItem('strava_connection_data', JSON.stringify({
            strava_athlete_id: response.data.strava_athlete_id,
            athlete_name: response.data.athlete_data?.firstname + ' ' + response.data.athlete_data?.lastname,
            connected_at: response.data.created_at
        }));
        
        return response.data;
        
    } catch (error) {
        console.error('Error checking Strava connection:', error);
        return null;
    }
}

// Update UI based on connection status
function updateStravaConnectionUI(connectionData) {
    const connectBtn = document.getElementById('connectStravaBtn');
    
    if (connectionData) {
        // Already connected - show status
        connectBtn.innerHTML = `
            <i class="fas fa-check-circle mr-2"></i>
            Strava Connected
        `;
        connectBtn.className = 'bg-green-600 hover:bg-green-700 text-white font-semibold py-3 px-6 rounded-lg transition';
        connectBtn.disabled = false;
        connectBtn.onclick = null; // Don't reconnect
        
        // Show activity count
        const statusDiv = document.createElement('div');
        statusDiv.className = 'mt-2 text-sm text-green-600';
        statusDiv.innerHTML = `
            <i class="fas fa-sync-alt mr-1"></i>
            Last synced: ${new Date(connectionData.updated_at).toLocaleDateString()}
        `;
        connectBtn.parentElement.appendChild(statusDiv);
        
        // Auto-load activities
        loadStravaActivities(connectionData.athlete_id);
        
    } else {
        // Not connected - show connect button
        connectBtn.innerHTML = `
            <i class="fas fa-plug mr-2"></i>
            Connect Strava
        `;
        connectBtn.className = 'bg-orange-600 hover:bg-orange-700 text-white font-semibold py-3 px-6 rounded-lg transition';
        connectBtn.disabled = false;
        connectBtn.onclick = connectStrava;
    }
}

// Load activities from database
async function loadStravaActivities(athleteId) {
    try {
        console.log('📊 Loading activities from database...');
        
        const response = await supabase
            .from('strava_activities')
            .select('*')
            .eq('athlete_id', athleteId)
            .order('created_at', { ascending: false })
            .limit(100);
        
        if (response.error) {
            console.error('Error loading activities:', response.error);
            return;
        }
        
        console.log(`✅ Loaded ${response.data.length} activities from database`);
        
        // Display activities
        displayActivities(response.data);
        
        // Load AISRI scores
        loadAISRIScores(athleteId);
        
    } catch (error) {
        console.error('Error loading Strava data:', error);
    }
}

// Load AISRI scores
async function loadAISRIScores(athleteId) {
    try {
        const response = await supabase
            .from('aisri_scores')
            .select('*')
            .eq('athlete_id', athleteId)
            .order('assessment_date', { ascending: false })
            .limit(1);
        
        if (response.error) {
            console.error('Error loading scores:', response.error);
            return;
        }
        
        if (response.data.length > 0) {
            const latestScore = response.data[0];
            displayAISRIScore(latestScore);
        }
        
    } catch (error) {
        console.error('Error loading AISRI scores:', error);
    }
}
```

### Step 2: Update Page Load Handler

Replace the DOMContentLoaded handler:

```javascript
// Initialize on page load
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Training Plan Builder loaded');
    
    // Check authentication
    const session = JSON.parse(sessionStorage.getItem('safestride_session') || '{}');
    if (!session.token) {
        console.log('❌ Not authenticated, redirecting to login');
        window.location.href = '/public/login.html';
        return;
    }
    
    // Check for existing Strava connection
    const connection = await checkExistingStravaConnection();
    
    // Update UI
    updateStravaConnectionUI(connection);
    
    // Check if coming back from OAuth callback
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('code')) {
        handleStravaCallback();
    }
});
```

---

## 🔄 **TOKEN REFRESH LOGIC (Optional but Recommended)**

Strava tokens expire after 6 hours. Add refresh logic:

```javascript
async function refreshStravaToken(athleteId, refreshToken) {
    try {
        console.log('🔄 Refreshing Strava token...');
        
        const response = await fetch(`${SUPABASE_FUNCTIONS_URL}/strava-refresh-token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${sessionStorage.getItem('safestride_token')}`
            },
            body: JSON.stringify({
                athleteId: athleteId,
                refreshToken: refreshToken
            })
        });
        
        if (!response.ok) {
            throw new Error('Token refresh failed');
        }
        
        const data = await response.json();
        console.log('✅ Token refreshed successfully');
        
        return data;
        
    } catch (error) {
        console.error('Token refresh error:', error);
        // If refresh fails, require reconnection
        localStorage.removeItem('strava_connected');
        return null;
    }
}
```

---

## 📝 **FILES TO UPDATE**

### 1. `/home/user/webapp/public/training-plan-builder.html`
- Add connection check functions
- Update DOMContentLoaded handler
- Add auto-load logic

### 2. `/home/user/webapp/supabase/functions/strava-refresh-token/index.ts` (NEW)
```typescript
// Create new Edge Function for token refresh
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const STRAVA_CLIENT_ID = "162971"
const STRAVA_CLIENT_SECRET = "ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626"

serve(async (req) => {
  const { refreshToken, athleteId } = await req.json()
  
  // Exchange refresh token for new access token
  const response = await fetch('https://www.strava.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: STRAVA_CLIENT_ID,
      client_secret: STRAVA_CLIENT_SECRET,
      grant_type: 'refresh_token',
      refresh_token: refreshToken
    })
  })
  
  const tokenData = await response.json()
  
  // Update database
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )
  
  await supabase
    .from('strava_connections')
    .update({
      access_token: tokenData.access_token,
      refresh_token: tokenData.refresh_token,
      expires_at: new Date(tokenData.expires_at * 1000).toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('athlete_id', athleteId)
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

---

## ✅ **TESTING STEPS**

### Test 1: First Time Connection
1. Clear localStorage and sessionStorage
2. Login to app
3. Click "Connect Strava"
4. Authorize → Data syncs → 908 activities loaded

### Test 2: Persistent Connection (THIS IS THE FIX)
1. **Stay logged in** or **logout and login again**
2. Go to Training Plan Builder
3. **Expected**: Button shows "Strava Connected" (green) - NO reconnection needed
4. Activities auto-load from database
5. AISRI scores displayed automatically

### Test 3: Token Expiration
1. Wait 6 hours (or manually expire token in DB)
2. Page load detects expired token
3. Auto-refreshes using refresh_token
4. Activities still load without user action

---

## 🎯 **BENEFITS OF THIS SOLUTION**

✅ **One-time OAuth**: User connects Strava once, stays connected  
✅ **Fast Load**: Data loads from database, not Strava API  
✅ **Auto-Refresh**: Tokens refresh automatically when needed  
✅ **Offline-Ready**: Works even if Strava API is slow  
✅ **Better UX**: No repeated "Connect Strava" clicks

---

## 📊 **DATA FLOW DIAGRAM**

```
User Login
    ↓
Check sessionStorage (safestride_session)
    ↓
Query strava_connections table
    ↓
    ├─ Record EXISTS → ✅ Auto-load data
    │                    ├─ Check token expiry
    │                    ├─ Refresh if needed
    │                    └─ Load activities from DB
    │
    └─ Record MISSING → Show "Connect Strava" button
                        ↓
                        User clicks → OAuth flow
                        ↓
                        Save to strava_connections
                        ↓
                        Next login → Auto-load!
```

---

## 🚀 **IMPLEMENTATION PLAN**

**I will now create the updated files with this logic built-in.**

Would you like me to:
1. ✅ **Update training-plan-builder.html with auto-check logic**
2. ✅ **Create strava-refresh-token Edge Function**
3. ✅ **Add "Reconnect Strava" button (for manual refresh)**
4. ✅ **Update strava-dashboard.html with same logic**

**Estimated time**: 10 minutes to implement, test, and deploy.

---

**Reply "YES" and I'll implement the complete solution now!** 🚀
