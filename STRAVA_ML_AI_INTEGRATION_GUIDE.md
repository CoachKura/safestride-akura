# 🚀 Strava ML/AI Integration - Complete Guide

## 📊 WHAT WE'VE BUILT

### **3 New Components:**

1. **Supabase Database Schema** (`supabase/migrations/001_strava_integration.sql`)
   - `strava_connections` - Stores OAuth tokens
   - `strava_activities` - Stores activities with ML analysis
   - `aisri_scores` - Stores calculated AISRI scores

2. **Supabase Edge Function: strava-oauth** (`supabase/functions/strava-oauth/index.ts`)
   - Handles OAuth token exchange
   - Saves connection to database
   - Returns athlete info

3. **Supabase Edge Function: strava-sync-activities** (`supabase/functions/strava-sync-activities/index.ts`)
   - Fetches last 30 days of activities
   - Calculates ML/AI metrics for each:
     * Training Load (based on distance, duration, HR)
     * Recovery Score (HRV, pace analysis)
     * Performance Index (pace, elevation, HR efficiency)
     * Fatigue Level (duration, HR intensity)
   - Aggregates into 6-pillar AISRI score
   - Saves to database

---

## 🔧 DEPLOYMENT STEPS

### **Step 1: Run Database Migration**

1. Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/sql/new

2. Copy contents of `supabase/migrations/001_strava_integration.sql`

3. Paste and click **"Run"**

4. Verify tables created:
   ```sql
   SELECT * FROM strava_connections LIMIT 1;
   SELECT * FROM strava_activities LIMIT 1;
   SELECT * FROM aisri_scores LIMIT 1;
   ```

---

### **Step 2: Deploy Edge Functions**

#### **Option A: Using Supabase CLI (Recommended)**

```powershell
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref bdisppaxbvygsspcuymb

# Deploy functions
cd C:\safestride-web\supabase\functions
supabase functions deploy strava-oauth
supabase functions deploy strava-sync-activities

# Set secrets (Strava credentials)
supabase secrets set STRAVA_CLIENT_ID=162971
supabase secrets set STRAVA_CLIENT_SECRET=6554eb9bb83f222a585e312c17420221313f85c1
```

#### **Option B: Using Supabase Dashboard**

1. Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

2. Click **"Create Function"**

3. **For strava-oauth:**
   - Name: `strava-oauth`
   - Copy code from `supabase/functions/strava-oauth/index.ts`
   - Paste and deploy

4. **For strava-sync-activities:**
   - Name: `strava-sync-activities`
   - Copy code from `supabase/functions/strava-sync-activities/index.ts`
   - Paste and deploy

5. **Set Environment Variables:**
   - Go to: Settings → Edge Functions → Secrets
   - Add:
     ```
     STRAVA_CLIENT_ID = 162971
     STRAVA_CLIENT_SECRET = 6554eb9bb83f222a585e312c17420221313f85c1
     ```

---

### **Step 3: Update Strava Callback URL**

1. Go to: https://www.strava.com/settings/api

2. Under "Authorization Callback Domain":
   - Change to: `www.akura.in`
   - Save

---

### **Step 4: Update Frontend Code**

The frontend code in `training-plan-builder.html` needs to be updated to call the Edge Functions. Here's the updated JavaScript:

```javascript
// Add after line 629 in training-plan-builder.html

async function handleStravaCallback(code) {
  console.log('🔄 Handling Strava OAuth callback...');
  
  try {
    // Show loading
    showNotification('Connecting to Strava...', 'info');
    
    // Step 1: Exchange code for tokens via Edge Function
    const { data: oauthData, error: oauthError } = await supabase.functions.invoke(
      'strava-oauth',
      {
        body: {
          code,
          athleteId: `athlete_${Date.now()}`, // Generate unique ID
        },
      }
    );
    
    if (oauthError) throw oauthError;
    if (!oauthData.success) throw new Error(oauthData.error);
    
    console.log('✅ Strava connected:', oauthData.athlete);
    
    // Step 2: Sync activities and calculate ML/AI scores
    showNotification('Fetching activities and calculating AI scores...', 'info');
    
    const { data: syncData, error: syncError } = await supabase.functions.invoke(
      'strava-sync-activities',
      {
        body: {
          athleteId: oauthData.athlete.id.toString(),
          daysBack: 30, // Last 30 days
        },
      }
    );
    
    if (syncError) throw syncError;
    if (!syncData.success) throw new Error(syncData.error);
    
    console.log('✅ Activities synced:', syncData);
    
    // Step 3: Display AISRI score
    athleteData = {
      stravaConnected: true,
      stravaAthlete: oauthData.athlete,
      activities: syncData.activities,
      aisriScore: syncData.aisriScore,
    };
    
    // Step 4: Update UI
    displayStravaData(athleteData);
    showNotification(`✅ Connected! Analyzed ${syncData.activitiesProcessed} activities. AISRI Score: ${syncData.aisriScore.totalScore}/100`, 'success');
    
    // Step 5: Move to next step
    goToStep(2);
    
    // Clean URL (remove code parameter)
    window.history.replaceState({}, document.title, window.location.pathname);
    
  } catch (error) {
    console.error('❌ Strava connection error:', error);
    showNotification(`Error: ${error.message}`, 'error');
  }
}

function displayStravaData(data) {
  const container = document.getElementById('strava-data-container');
  if (!container) return;
  
  const { aisriScore, activities } = data;
  
  container.innerHTML = `
    <div class="card">
      <h3>🎯 Your AISRI Score from Strava Data</h3>
      <div class="aisri-score-display">
        <div class="score-circle">
          <span class="score-value">${aisriScore.totalScore}</span>
          <span class="score-label">/100</span>
        </div>
        <div class="risk-badge ${aisriScore.riskCategory.toLowerCase().replace(' ', '-')}">
          ${aisriScore.riskCategory}
        </div>
      </div>
      
      <h4>📊 Pillar Breakdown:</h4>
      <div class="pillar-scores">
        <div class="pillar">
          <span class="pillar-name">🏃 Running</span>
          <span class="pillar-score">${aisriScore.pillars.running}/100</span>
          <div class="pillar-bar">
            <div class="pillar-fill" style="width: ${aisriScore.pillars.running}%"></div>
          </div>
        </div>
        <div class="pillar">
          <span class="pillar-name">💪 Strength</span>
          <span class="pillar-score">${aisriScore.pillars.strength}/100</span>
          <div class="pillar-bar">
            <div class="pillar-fill" style="width: ${aisriScore.pillars.strength}%"></div>
          </div>
        </div>
        <div class="pillar">
          <span class="pillar-name">🤸 ROM</span>
          <span class="pillar-score">${aisriScore.pillars.rom}/100</span>
          <div class="pillar-bar">
            <div class="pillar-fill" style="width: ${aisriScore.pillars.rom}%"></div>
          </div>
        </div>
        <div class="pillar">
          <span class="pillar-name">⚖️ Balance</span>
          <span class="pillar-score">${aisriScore.pillars.balance}/100</span>
          <div class="pillar-bar">
            <div class="pillar-fill" style="width: ${aisriScore.pillars.balance}%"></div>
          </div>
        </div>
        <div class="pillar">
          <span class="pillar-name">📐 Alignment</span>
          <span class="pillar-score">${aisriScore.pillars.alignment}/100</span>
          <div class="pillar-bar">
            <div class="pillar-fill" style="width: ${aisriScore.pillars.alignment}%"></div>
          </div>
        </div>
        <div class="pillar">
          <span class="pillar-name">🧘 Mobility</span>
          <span class="pillar-score">${aisriScore.pillars.mobility}/100</span>
          <div class="pillar-bar">
            <div class="pillar-fill" style="width: ${aisriScore.pillars.mobility}%"></div>
          </div>
        </div>
      </div>
      
      <h4>📈 Recent Activities (Last 30 days):</h4>
      <div class="activities-list">
        ${activities.slice(0, 5).map(act => {
          const actData = act.activity_data;
          const insights = act.ml_insights;
          return `
            <div class="activity-card">
              <div class="activity-header">
                <span class="activity-name">${actData.name}</span>
                <span class="activity-date">${new Date(actData.start_date).toLocaleDateString()}</span>
              </div>
              <div class="activity-stats">
                <span>📏 ${(actData.distance / 1000).toFixed(2)} km</span>
                <span>⏱️ ${Math.round(actData.moving_time / 60)} min</span>
                <span>💓 ${actData.average_heartrate || 'N/A'} avg HR</span>
              </div>
              <div class="activity-insights">
                <span>Training Load: ${insights.trainingLoad}/100</span>
                <span>Recovery: ${insights.recoveryScore}/100</span>
                <span>Performance: ${insights.performanceIndex}/100</span>
              </div>
            </div>
          `;
        }).join('')}
      </div>
      
      <p class="insights-summary">${aisriScore.insights}</p>
    </div>
  `;
}

function showNotification(message, type = 'info') {
  // Create notification element
  const notification = document.createElement('div');
  notification.className = `notification ${type}`;
  notification.textContent = message;
  document.body.appendChild(notification);
  
  // Auto-remove after 3 seconds
  setTimeout(() => {
    notification.remove();
  }, 3000);
}
```

---

## 🎯 HOW IT WORKS

### **Flow:**

1. **User clicks "Connect Strava"**
   - Redirects to Strava OAuth
   - User authorizes
   - Redirects back with `code`

2. **Frontend calls `strava-oauth` Edge Function**
   - Exchanges code for tokens
   - Saves to `strava_connections` table
   - Returns athlete info

3. **Frontend calls `strava-sync-activities` Edge Function**
   - Fetches last 30 days of activities
   - For each activity:
     * Calculates training load
     * Calculates recovery score
     * Calculates performance index
     * Calculates fatigue level
   - Saves to `strava_activities` table
   - Aggregates into 6-pillar AISRI score
   - Saves to `aisri_scores` table

4. **Frontend displays results**
   - Shows AISRI score (0-100)
   - Shows risk category
   - Shows 6-pillar breakdown
   - Shows recent activities with ML insights

---

## 📊 ML/AI CALCULATIONS

### **Training Load Formula:**
```
load = distance × duration × (avgHR / 180)
score = 0-100 based on load thresholds
```

### **Recovery Score Formula:**
```
HRV proxy = ((maxHR - avgHR) / maxHR) × 100
score = HRV × 5 + pace bonuses
```

### **Performance Index Formula:**
```
paceScore = faster pace → higher score
elevationBonus = more elevation → bonus points
hrEfficiency = lower HR at same pace → bonus
```

### **Fatigue Level Formula:**
```
durationFatigue = longer duration → higher fatigue
hrFatigue = higher avg/max HR ratio → higher fatigue
```

### **AISRI Aggregation:**
```
Running Pillar = average of all activity scores
Other Pillars = baseline 70 (from assessment)
Total Score = weighted sum:
  Running: 40%
  Strength: 15%
  ROM: 12%
  Balance: 13%
  Alignment: 10%
  Mobility: 10%
```

---

## 🚀 NEXT STEPS

### **What YOU need to do:**

1. **Deploy database schema** (Step 1)
2. **Deploy Edge Functions** (Step 2)
3. **Update Strava callback** (Step 3)
4. **Test the flow:**
   - Go to: https://www.akura.in/training-plan-builder.html
   - Click "Connect Strava"
   - Authorize
   - See AISRI score calculated from your Strava data! 🎉

---

## 📞 SUPPORT

**Reply with:**
- "Schema deployed" - Great! Now deploy Edge Functions
- "Edge Functions deployed" - Perfect! Now test Strava connection
- "Strava connected!" - Awesome! Check your AISRI score
- "Error: [message]" - I'll help debug

---

**Your ML/AI system is ready to analyze Strava data and calculate personalized AISRI scores!** 🚀

Files created:
- `/home/user/webapp/supabase/migrations/001_strava_integration.sql`
- `/home/user/webapp/supabase/functions/strava-oauth/index.ts`
- `/home/user/webapp/supabase/functions/strava-sync-activities/index.ts`
- This guide

Ready to deploy? 🎯
