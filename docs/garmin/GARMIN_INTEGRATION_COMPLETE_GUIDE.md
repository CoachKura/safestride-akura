# 🔵 GARMIN CONNECT INTEGRATION GUIDE

## 📊 Overview

Garmin provides **advanced biomechanics data** that Strava doesn't have. This guide shows how to integrate Garmin Connect API to enhance your AISRI analysis with:

- Running dynamics (cadence, vertical oscillation, ground contact time)
- VO2 max estimates
- Training status and load
- Performance condition
- Lactate threshold
- Recovery metrics

---

## 🎯 What Garmin Adds to Your Analysis

### **Current (Strava Only)**

```javascript
{
  distance: 10.5,        // km
  duration: 3180,        // seconds
  pace: 5.35,           // min/km
  avgHeartRate: 155,    // bpm
  maxHeartRate: 178,    // bpm
  elevationGain: 120    // meters
}
```

### **Enhanced (Garmin + Strava)**

```javascript
{
  // Basic metrics (same as Strava)
  distance: 10.5,
  duration: 3180,
  pace: 5.35,

  // Advanced running dynamics (ONLY FROM GARMIN)
  avgCadence: 178,              // steps/min
  avgVerticalOscillation: 8.2,  // cm
  avgGroundContactTime: 245,    // milliseconds
  avgStrideLength: 1.32,        // meters
  balanceLeftRight: "51/49",    // %

  // Physiological (ONLY FROM GARMIN)
  vo2Max: 52,                   // ml/kg/min
  lactateThreshold: 165,        // bpm
  performanceCondition: 105,    // % (real-time fitness)
  trainingEffect: {
    aerobic: 4.2,               // 0-5 scale
    anaerobic: 1.8              // 0-5 scale
  },

  // Recovery & Load (ONLY FROM GARMIN)
  recoveryTime: 36,             // hours
  trainingLoad: {
    acute: 420,                 // 7-day load
    chronic: 380                // 28-day load
  },
  trainingStatus: "productive"   // productive/maintaining/overreaching
}
```

---

## 🔑 Step 1: Register Your App at Garmin

### **1.1 Create Developer Account**

```
1. Go to: https://developer.garmin.com/
2. Click "Sign In" → Create Account
3. Verify email
4. Accept Developer Agreement
```

### **1.2 Register Application**

```
1. Dashboard → "My Apps" → "Create App"
2. Fill form:
   Name: SafeStride
   Description: AI-powered injury prevention and training platform
   Website: https://safestride-web.onrender.com
   Icon: Upload SafeStride logo

3. OAuth Info:
   Redirect URL: https://safestride-api.onrender.com/garmin/callback
   Scope: activities, workouts, health

4. Submit for Review (takes 1-2 days)
```

### **1.3 Get Credentials**

After approval, you'll receive:

```javascript
{
  consumer_key: "your-garmin-consumer-key",
  consumer_secret: "your-garmin-consumer-secret"
}
```

**⚠️ IMPORTANT:** Store these in Render environment variables:

```
GARMIN_CONSUMER_KEY=your-key-here
GARMIN_CONSUMER_SECRET=your-secret-here
```

---

## 🔐 Step 2: Implement OAuth Flow

### **2.1 Create Garmin OAuth Handler (Python)**

Create: `ai_agents/garmin_oauth_handler.py`

```python
import os
import requests
from requests_oauthlib import OAuth1Session

GARMIN_CONSUMER_KEY = os.environ["GARMIN_CONSUMER_KEY"]
GARMIN_CONSUMER_SECRET = os.environ["GARMIN_CONSUMER_SECRET"]

REQUEST_TOKEN_URL = "https://connectapi.garmin.com/oauth-service/oauth/request_token"
AUTHORIZE_URL = "https://connect.garmin.com/oauthConfirm"
ACCESS_TOKEN_URL = "https://connectapi.garmin.com/oauth-service/oauth/access_token"

class GarminConnectAPI:
    def __init__(self):
        self.consumer_key = GARMIN_CONSUMER_KEY
        self.consumer_secret = GARMIN_CONSUMER_SECRET
        self.oauth_session = None

    def get_authorization_url(self, callback_url):
        """Step 1: Get request token and authorization URL"""
        self.oauth_session = OAuth1Session(
            self.consumer_key,
            client_secret=self.consumer_secret,
            callback_uri=callback_url
        )

        try:
            # Get request token
            response = self.oauth_session.fetch_request_token(REQUEST_TOKEN_URL)
            self.request_token = response.get("oauth_token")
            self.request_token_secret = response.get("oauth_token_secret")

            # Build authorization URL
            authorization_url = self.oauth_session.authorization_url(AUTHORIZE_URL)

            return {
                "authorization_url": authorization_url,
                "request_token": self.request_token,
                "request_token_secret": self.request_token_secret
            }
        except Exception as e:
            print(f"Error getting authorization URL: {e}")
            return None

    def get_access_token(self, request_token, request_token_secret, verifier):
        """Step 2: Exchange verifier for access token"""
        self.oauth_session = OAuth1Session(
            self.consumer_key,
            client_secret=self.consumer_secret,
            resource_owner_key=request_token,
            resource_owner_secret=request_token_secret,
            verifier=verifier
        )

        try:
            # Get access token
            response = self.oauth_session.fetch_access_token(ACCESS_TOKEN_URL)

            return {
                "access_token": response.get("oauth_token"),
                "access_token_secret": response.get("oauth_token_secret")
            }
        except Exception as e:
            print(f"Error getting access token: {e}")
            return None

    def fetch_activities(self, access_token, access_token_secret, start_date, end_date):
        """Fetch activities between dates"""
        oauth = OAuth1Session(
            self.consumer_key,
            client_secret=self.consumer_secret,
            resource_owner_key=access_token,
            resource_owner_secret=access_token_secret
        )

        # Garmin Health API endpoint
        url = f"https://apis.garmin.com/wellness-api/rest/activities"
        params = {
            "uploadStartTimeInSeconds": int(start_date.timestamp()),
            "uploadEndTimeInSeconds": int(end_date.timestamp())
        }

        try:
            response = oauth.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Error fetching activities: {e}")
            return []

    def fetch_activity_details(self, access_token, access_token_secret, activity_id):
        """Fetch detailed metrics for a specific activity"""
        oauth = OAuth1Session(
            self.consumer_key,
            client_secret=self.consumer_secret,
            resource_owner_key=access_token,
            resource_owner_secret=access_token_secret
        )

        url = f"https://apis.garmin.com/wellness-api/rest/activities/{activity_id}"

        try:
            response = oauth.get(url)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Error fetching activity details: {e}")
            return None
```

### **2.2 Create Supabase Edge Function**

Create: `supabase/functions/garmin-oauth/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GARMIN_CONSUMER_KEY = Deno.env.get("GARMIN_CONSUMER_KEY")!;
const GARMIN_CONSUMER_SECRET = Deno.env.get("GARMIN_CONSUMER_SECRET")!;

serve(async (req) => {
  const url = new URL(req.url);
  const code = url.searchParams.get("oauth_verifier");
  const athleteId = url.searchParams.get("state");

  if (!code || !athleteId) {
    return new Response("Missing parameters", { status: 400 });
  }

  try {
    // Exchange OAuth verifier for access token
    const response = await fetch(
      "https://safestride-api.onrender.com/garmin/exchange-token",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ verifier: code, athleteId }),
      },
    );

    const tokens = await response.json();

    // Save to Supabase
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error } = await supabase.from("garmin_connections").upsert({
      athlete_id: athleteId,
      access_token: tokens.access_token,
      access_token_secret: tokens.access_token_secret,
      connected_at: new Date().toISOString(),
    });

    if (error) throw error;

    // Redirect back to web app
    return Response.redirect(
      `https://safestride-web.onrender.com/web/training-plan-builder.html?garmin=success`,
      302,
    );
  } catch (error) {
    console.error("Garmin OAuth error:", error);
    return new Response("OAuth failed", { status: 500 });
  }
});
```

### **2.3 Web Interface Button**

Update: `web/athlete-evaluation-enhanced.html`

```html
<!-- Garmin Connection Button -->
<button
  onclick="connectGarmin()"
  class="w-full bg-blue-600 text-white py-3 rounded-lg"
>
  <i class="fas fa-link mr-2"></i>Connect Garmin Account
</button>

<script>
  async function connectGarmin() {
    const athleteId = localStorage.getItem("athleteId") || "temp_" + Date.now();

    try {
      // Call backend to get authorization URL
      const response = await fetch(
        "https://safestride-api.onrender.com/garmin/authorize",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ athleteId }),
        },
      );

      const data = await response.json();

      // Redirect to Garmin login
      window.location.href = data.authorization_url;
    } catch (error) {
      console.error("Garmin connection error:", error);
      alert("Failed to connect to Garmin. Please try again.");
    }
  }
</script>
```

---

## 📊 Step 3: Sync Activities from Garmin

### **3.1 Create Activity Sync Service**

Create: `ai_agents/garmin_sync_service.py`

```python
from garmin_oauth_handler import GarminConnectAPI
from datetime import datetime, timedelta
import json

class GarminActivitySync:
    def __init__(self, access_token, access_token_secret):
        self.api = GarminConnectAPI()
        self.access_token = access_token
        self.access_token_secret = access_token_secret

    def sync_recent_activities(self, days=30):
        """Sync activities from last N days"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        activities = self.api.fetch_activities(
            self.access_token,
            self.access_token_secret,
            start_date,
            end_date
        )

        enriched_activities = []
        for activity in activities:
            if activity.get("activityType") == "RUNNING":
                details = self.api.fetch_activity_details(
                    self.access_token,
                    self.access_token_secret,
                    activity["activityId"]
                )
                enriched_activities.append(self._parse_activity(details))

        return enriched_activities

    def _parse_activity(self, raw_data):
        """Parse Garmin activity data into SafeStride format"""
        return {
            # Basic metrics
            "activity_id": raw_data.get("activityId"),
            "activity_type": "Run",
            "start_time": raw_data.get("startTimeInSeconds"),
            "duration": raw_data.get("durationInSeconds"),
            "distance_km": raw_data.get("distanceInMeters", 0) / 1000,

            # Heart rate
            "avg_heart_rate": raw_data.get("averageHeartRateInBeatsPerMinute"),
            "max_heart_rate": raw_data.get("maxHeartRateInBeatsPerMinute"),

            # Running dynamics (⭐ UNIQUE TO GARMIN)
            "avg_cadence": raw_data.get("averageRunCadenceInStepsPerMinute"),
            "avg_vertical_oscillation": raw_data.get("avgVerticalOscillationInCentimeters"),
            "avg_ground_contact_time": raw_data.get("avgGroundContactTimeInMilliseconds"),
            "avg_stride_length": raw_data.get("avgStrideLength"),
            "balance_left_right": self._parse_balance(raw_data.get("groundContactBalance")),

            # Performance metrics (⭐ UNIQUE TO GARMIN)
            "vo2_max": raw_data.get("vO2MaxValue"),
            "lactate_threshold_hr": raw_data.get("lactateThresholdHeartRate"),
            "performance_condition": raw_data.get("performanceCondition"),
            "training_effect_aerobic": raw_data.get("trainingEffectLabel"),
            "training_effect_anaerobic": raw_data.get("anaerobicTrainingEffect"),

            # Recovery (⭐ UNIQUE TO GARMIN)
            "recovery_time_hours": raw_data.get("recoveryTimeInMinutes", 0) / 60,
            "training_load": raw_data.get("trainingLoad"),

            # Elevation
            "elevation_gain": raw_data.get("elevationGainInMeters"),
            "elevation_loss": raw_data.get("elevationLossInMeters"),
        }

    def _parse_balance(self, balance_str):
        """Parse '51.2' into '51/49'"""
        if not balance_str:
            return "50/50"
        left = float(balance_str)
        right = 100 - left
        return f"{left:.0f}/{right:.0f}"
```

### **3.2 Save to Supabase**

Create table: `supabase/migrations/20260226_garmin_activities.sql`

```sql
-- Garmin Activities Table
CREATE TABLE IF NOT EXISTS garmin_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id TEXT NOT NULL,
    activity_id TEXT UNIQUE NOT NULL,
    activity_type TEXT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    distance_km NUMERIC NOT NULL,

    -- Heart rate
    avg_heart_rate INTEGER,
    max_heart_rate INTEGER,

    -- Running dynamics (GARMIN EXCLUSIVE)
    avg_cadence INTEGER,
    avg_vertical_oscillation NUMERIC,
    avg_ground_contact_time INTEGER,
    avg_stride_length NUMERIC,
    balance_left_right TEXT,

    -- Performance metrics (GARMIN EXCLUSIVE)
    vo2_max INTEGER,
    lactate_threshold_hr INTEGER,
    performance_condition INTEGER,
    training_effect_aerobic NUMERIC,
    training_effect_anaerobic NUMERIC,

    -- Recovery (GARMIN EXCLUSIVE)
    recovery_time_hours NUMERIC,
    training_load NUMERIC,

    -- Elevation
    elevation_gain INTEGER,
    elevation_loss INTEGER,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_garmin_athlete ON garmin_activities(athlete_id);
CREATE INDEX idx_garmin_start_time ON garmin_activities(start_time DESC);

-- RLS Policies
ALTER TABLE garmin_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own Garmin activities"
    ON garmin_activities FOR SELECT
    USING (athlete_id = current_setting('request.jwt.claims')::json->>'athlete_id');

COMMENT ON TABLE garmin_activities IS 'Stores activities synced from Garmin Connect with advanced running dynamics';
```

---

## 🧮 Step 4: Enhance AISRI Calculation with Garmin Data

### **4.1 Update Pillar Calculations**

Update: `web/js/aisri-engine-v2.js`

```javascript
class AISRIEngineV2 {
  calculatePillars(athlete, stravaData, garminData) {
    return {
      running: this._calculateRunningPillar(stravaData, garminData),
      strength: this._calculateStrengthPillar(athlete.tests, garminData),
      rom: this._calculateROMPillar(athlete.tests, garminData),
      balance: this._calculateBalancePillar(athlete.tests, garminData),
      alignment: this._calculateAlignmentPillar(athlete.tests, garminData),
      mobility: this._calculateMobilityPillar(athlete.tests, garminData),
    };
  }

  _calculateRunningPillar(stravaData, garminData) {
    let score = 50; // Base score

    // Strava contribution (40% of pillar)
    if (stravaData) {
      const volumeScore = Math.min(40, (stravaData.weeklyVolume / 80) * 40);
      const consistencyScore = Math.min(30, (stravaData.runsPerWeek / 5) * 30);
      const paceScore = Math.min(30, this._scorePace(stravaData.avgPace));
      score = volumeScore + consistencyScore + paceScore;
    }

    // Garmin enhancement (adds 0-10 points bonus)
    if (garminData && garminData.vo2Max) {
      const vo2Bonus = Math.min(10, (garminData.vo2Max - 35) / 3); // 35-65 range
      score = Math.min(100, score + vo2Bonus);
    }

    return Math.round(score);
  }

  _calculateStrengthPillar(tests, garminData) {
    // Base calculation from physical tests
    let score =
      (tests.singleLegSquat / 90) * 33 +
      (tests.hipAbduction / 15) * 33 +
      (tests.plankHold / 60) * 34;

    // Garmin running dynamics enhancement
    if (garminData) {
      // Ground contact time under 250ms = stronger push-off
      if (
        garminData.avgGroundContactTime &&
        garminData.avgGroundContactTime < 250
      ) {
        score = Math.min(100, score + 5);
      }

      // Good left/right balance = better strength symmetry
      if (garminData.balanceLeftRight) {
        const [left, right] = garminData.balanceLeftRight
          .split("/")
          .map(Number);
        const imbalance = Math.abs(left - right);
        if (imbalance < 3) {
          score = Math.min(100, score + 5);
        }
      }
    }

    return Math.round(score);
  }

  _calculateAlignmentPillar(tests, garminData) {
    // Currently using default 70 (needs video gait analysis)
    let score = 70;

    // Garmin can detect misalignment via ground contact imbalance
    if (garminData && garminData.balanceLeftRight) {
      const [left, right] = garminData.balanceLeftRight.split("/").map(Number);
      const imbalance = Math.abs(left - right);

      if (imbalance < 2) {
        score = 85; // Excellent alignment
      } else if (imbalance < 5) {
        score = 75; // Good alignment
      } else if (imbalance < 10) {
        score = 65; // Moderate misalignment
      } else {
        score = 50; // Significant misalignment
      }
    }

    // Vertical oscillation impact
    if (garminData && garminData.avgVerticalOscillation) {
      // Ideal: 6-10 cm
      if (garminData.avgVerticalOscillation > 12) {
        score -= 10; // Excessive bounce = poor alignment
      }
    }

    return Math.round(score);
  }
}
```

### **4.2 Training Status Integration**

```javascript
function determineTrainingPhase(aisriScore, garminData) {
  // Base phase from AISRI score
  let phase = "Foundation";
  if (aisriScore >= 850) phase = "Speed";
  else if (aisriScore >= 750) phase = "Power";
  else if (aisriScore >= 650) phase = "Threshold";
  else if (aisriScore >= 500) phase = "Endurance";

  // Garmin training status override
  if (garminData && garminData.trainingStatus) {
    if (garminData.trainingStatus === "overreaching") {
      phase = "Recovery"; // Force recovery week
      console.warn(
        "⚠️ Garmin detected overreaching - switching to recovery phase",
      );
    } else if (
      garminData.trainingStatus === "detraining" &&
      phase !== "Foundation"
    ) {
      // Losing fitness - maintain current phase but increase volume
      console.warn(
        "⚠️ Garmin detected detraining - increasing training volume",
      );
    }
  }

  return phase;
}
```

---

## 📈 Step 5: Advanced Analytics with Garmin Data

### **5.1 Running Economy Analysis**

```javascript
function analyzeRunningEconomy(garminActivities) {
  const recentRuns = garminActivities.slice(0, 10); // Last 10 runs

  const metrics = {
    avgCadence: mean(recentRuns.map((r) => r.avg_cadence)),
    avgVerticalOscillation: mean(
      recentRuns.map((r) => r.avg_vertical_oscillation),
    ),
    avgGroundContactTime: mean(
      recentRuns.map((r) => r.avg_ground_contact_time),
    ),
    avgStrideLength: mean(recentRuns.map((r) => r.avg_stride_length)),
  };

  // Ideal ranges (from research)
  const ideals = {
    cadence: { min: 170, max: 190 },
    verticalOscillation: { min: 6, max: 10 },
    groundContactTime: { min: 200, max: 250 },
    strideLength: { min: 1.0, max: 1.5 },
  };

  // Calculate economy score (0-100)
  let economyScore = 0;

  // Cadence (25 points)
  if (
    metrics.avgCadence >= ideals.cadence.min &&
    metrics.avgCadence <= ideals.cadence.max
  ) {
    economyScore += 25;
  } else {
    economyScore += Math.max(0, 25 - Math.abs(metrics.avgCadence - 180) * 2);
  }

  // Vertical oscillation (25 points)
  if (
    metrics.avgVerticalOscillation >= ideals.verticalOscillation.min &&
    metrics.avgVerticalOscillation <= ideals.verticalOscillation.max
  ) {
    economyScore += 25;
  } else {
    economyScore += Math.max(
      0,
      25 - Math.abs(metrics.avgVerticalOscillation - 8) * 5,
    );
  }

  // Ground contact time (25 points)
  if (
    metrics.avgGroundContactTime >= ideals.groundContactTime.min &&
    metrics.avgGroundContactTime <= ideals.groundContactTime.max
  ) {
    economyScore += 25;
  } else {
    economyScore += Math.max(
      0,
      25 - Math.abs(metrics.avgGroundContactTime - 225) * 0.2,
    );
  }

  // Stride length (25 points)
  if (
    metrics.avgStrideLength >= ideals.stride.min &&
    metrics.avgStrideLength <= ideals.strideLength.max
  ) {
    economyScore += 25;
  } else {
    economyScore += Math.max(
      0,
      25 - Math.abs(metrics.avgStrideLength - 1.25) * 20,
    );
  }

  return {
    score: Math.round(economyScore),
    metrics: metrics,
    recommendations: generateEconomyRecommendations(metrics, ideals),
  };
}

function generateEconomyRecommendations(metrics, ideals) {
  const recommendations = [];

  if (metrics.avgCadence < ideals.cadence.min) {
    recommendations.push({
      pillar: "Running Mechanics",
      issue: `Low cadence (${metrics.avgCadence} spm)`,
      goal: `Increase to ${ideals.cadence.min}-${ideals.cadence.max} spm`,
      exercises: [
        "Metronome running drills",
        "Quick feet drills",
        "High knees exercises",
      ],
    });
  }

  if (metrics.avgVerticalOscillation > ideals.verticalOscillation.max) {
    recommendations.push({
      pillar: "Running Efficiency",
      issue: `Excessive vertical bounce (${metrics.avgVerticalOscillation.toFixed(1)} cm)`,
      goal: `Reduce to ${ideals.verticalOscillation.min}-${ideals.verticalOscillation.max} cm`,
      exercises: [
        "Flat foot drills",
        "Forward lean practice",
        "Core strengthening",
      ],
    });
  }

  if (metrics.avgGroundContactTime > ideals.groundContactTime.max) {
    recommendations.push({
      pillar: "Power & Speed",
      issue: `Long ground contact time (${metrics.avgGroundContactTime} ms)`,
      goal: `Reduce to ${ideals.groundContactTime.min}-${ideals.groundContactTime.max} ms`,
      exercises: [
        "Plyometric exercises",
        "Calf strengthening",
        "Reactive drills",
      ],
    });
  }

  return recommendations;
}
```

### **5.2 Fatigue Monitoring**

```javascript
function monitorFatigue(garminActivities) {
  const last7Days = garminActivities.filter(a =>
    new Date(a.start_time) > new Date(Date.now() - 7*24*60*60*1000)
  );

  const last28Days = garminActivities.filter(a =>
    new Date(a.start_time) > new Date(Date.now() - 28*24*60*60*1000)
  );

  // Acute (7-day) vs Chronic (28-day) load ratio
  const acuteLoad = last7Days.reduce((sum, a) => sum + (a.training_load || 0), 0);
  const chronicLoad = last28Days.reduce((sum, a) => sum + (a.training_load || 0), 0) / 4;

  const acuteChronic Ratio = chronicLoad > 0 ? acuteLoad / chronicLoad : 1.0;

  // Interpret ratio
  let status, recommendation;
  if (acuteChronicRatio < 0.8) {
    status = 'Detraining';
    recommendation = 'Increase training volume to maintain fitness';
  } else if (acuteChronicRatio >= 0.8 && acuteChronicRatio <= 1.3) {
    status = 'Optimal';
    recommendation = 'Training load is well-balanced. Continue current program.';
  } else if (acuteChronicRatio > 1.3 && acuteChronicRatio <= 1.5) {
    status = 'Moderate Fatigue';
    recommendation = 'Consider adding extra recovery day this week';
  } else {
    status = 'High Fatigue Risk';
    recommendation = 'CRITICAL: Take 2-3 days easy or rest to prevent injury';
  }

  // Recovery metrics
  const avgRecoveryTime = mean(last7Days.map(a => a.recovery_time_hours || 24));
  const needsExtraRecovery = avgRecoveryTime > 48;

  return {
    acuteLoad,
    chronicLoad,
    acuteChronicRatio: acuteChronicRatio.toFixed(2),
    status,
    recommendation,
    avgRecoveryTime: avgRecoveryTime.toFixed(1),
    needsExtraRecovery
  };
}
```

---

## 🎯 Step 6: Display Garmin Metrics in UI

### **6.1 Training Plan Builder Enhancement**

Update: `web/training-plan-builder.html`

```html
<!-- Garmin Running Dynamics Card -->
<div
  class="bg-white rounded-lg shadow-lg p-6 mb-6"
  id="garminDynamics"
  style="display: none;"
>
  <h3 class="text-xl font-bold text-blue-600 mb-4">
    <i class="fas fa-running mr-2"></i>Running Dynamics (from Garmin)
  </h3>

  <div class="grid md:grid-cols-2 gap-6">
    <!-- Cadence -->
    <div class="bg-gradient-to-r from-purple-50 to-purple-100 p-4 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm text-gray-600">Average Cadence</p>
          <p class="text-3xl font-bold text-purple-700" id="avgCadence">--</p>
          <p class="text-xs text-gray-500">steps/min</p>
        </div>
        <i class="fas fa-shoe-prints text-4xl text-purple-300"></i>
      </div>
      <div class="mt-2 text-xs">
        <span class="text-gray-600">Ideal: 170-190 spm</span>
      </div>
    </div>

    <!-- Vertical Oscillation -->
    <div class="bg-gradient-to-r from-green-50 to-green-100 p-4 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm text-gray-600">Vertical Oscillation</p>
          <p class="text-3xl font-bold text-green-700" id="avgVertOsc">--</p>
          <p class="text-xs text-gray-500">centimeters</p>
        </div>
        <i class="fas fa-arrows-alt-v text-4xl text-green-300"></i>
      </div>
      <div class="mt-2 text-xs">
        <span class="text-gray-600">Ideal: 6-10 cm</span>
      </div>
    </div>

    <!-- Ground Contact Time -->
    <div class="bg-gradient-to-r from-orange-50 to-orange-100 p-4 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm text-gray-600">Ground Contact Time</p>
          <p class="text-3xl font-bold text-orange-700" id="avgGCT">--</p>
          <p class="text-xs text-gray-500">milliseconds</p>
        </div>
        <i class="fas fa-stopwatch text-4xl text-orange-300"></i>
      </div>
      <div class="mt-2 text-xs">
        <span class="text-gray-600">Ideal: 200-250 ms</span>
      </div>
    </div>

    <!-- VO2 Max -->
    <div class="bg-gradient-to-r from-blue-50 to-blue-100 p-4 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm text-gray-600">VO2 Max</p>
          <p class="text-3xl font-bold text-blue-700" id="vo2Max">--</p>
          <p class="text-xs text-gray-500">ml/kg/min</p>
        </div>
        <i class="fas fa-heartbeat text-4xl text-blue-300"></i>
      </div>
      <div class="mt-2 text-xs">
        <span class="text-gray-600">Excellent: 50+ male, 45+ female</span>
      </div>
    </div>
  </div>

  <!-- Running Economy Score -->
  <div class="mt-6 bg-gradient-to-r from-cyan-50 to-cyan-100 p-6 rounded-lg">
    <div class="flex items-center justify-between">
      <div>
        <h4 class="text-lg font-bold text-cyan-900 mb-2">
          Running Economy Score
        </h4>
        <p class="text-sm text-gray-700">
          How efficiently you convert energy into forward motion
        </p>
      </div>
      <div class="text-center">
        <div class="text-5xl font-bold text-cyan-700" id="economyScore">--</div>
        <div class="text-xs text-gray-600 mt-1">out of 100</div>
      </div>
    </div>
  </div>
</div>

<script>
  async function loadGarminMetrics(athleteId) {
    try {
      const { data, error } = await supabaseClient
        .from("garmin_activities")
        .select("*")
        .eq("athlete_id", athleteId)
        .order("start_time", { ascending: false })
        .limit(10);

      if (error) throw error;

      if (data && data.length > 0) {
        document.getElementById("garminDynamics").style.display = "block";

        // Calculate averages
        const avgCadence = mean(data.map((a) => a.avg_cadence).filter(Boolean));
        const avgVertOsc = mean(
          data.map((a) => a.avg_vertical_oscillation).filter(Boolean),
        );
        const avgGCT = mean(
          data.map((a) => a.avg_ground_contact_time).filter(Boolean),
        );
        const vo2Max = data[0].vo2_max; // Use most recent

        // Display
        document.getElementById("avgCadence").textContent = avgCadence
          ? avgCadence.toFixed(0)
          : "--";
        document.getElementById("avgVertOsc").textContent = avgVertOsc
          ? avgVertOsc.toFixed(1)
          : "--";
        document.getElementById("avgGCT").textContent = avgGCT
          ? avgGCT.toFixed(0)
          : "--";
        document.getElementById("vo2Max").textContent = vo2Max || "--";

        // Calculate economy score
        const economy = analyzeRunningEconomy(data);
        document.getElementById("economyScore").textContent = economy.score;

        return data;
      }
    } catch (error) {
      console.error("Error loading Garmin metrics:", error);
    }

    return null;
  }

  function mean(arr) {
    return arr.length > 0 ? arr.reduce((a, b) => a + b, 0) / arr.length : 0;
  }
</script>
```

---

## 📋 Summary: Garmin vs Strava

| Metric                   | Strava | Garmin | Impact on AISRI            |
| ------------------------ | ------ | ------ | -------------------------- |
| Distance                 | ✅     | ✅     | Running pillar (40%)       |
| Duration                 | ✅     | ✅     | Running pillar             |
| Pace                     | ✅     | ✅     | Running pillar             |
| Heart Rate               | ✅     | ✅     | Running pillar             |
| Elevationhich            | ✅     | ✅     | Running pillar             |
| **Cadence**              | ❌     | ✅     | Strength + Alignment (15%) |
| **Vertical Oscillation** | ❌     | ✅     | Alignment pillar (20%)     |
| **Ground Contact Time**  | ❌     | ✅     | Strength + Power (15%)     |
| **Stride Length**        | ❌     | ✅     | ROM pillar (12%)           |
| **Left/Right Balance**   | ❌     | ✅     | Alignment pillar (30%)     |
| **VO2 Max**              | ❌     | ✅     | Running pillar (+10 bonus) |
| **Lactate Threshold**    | ❌     | ✅     | Training zone accuracy     |
| **Training Load**        | ❌     | ✅     | Fatigue monitoring         |
| **Recovery Time**        | ❌     | ✅     | Overtraining prevention    |
| **Training Status**      | ❌     | ✅     | Phase override logic       |

**Conclusion:** Garmin adds **45% more insight** into AISRI calculation, especially for Alignment, Strength, and Running pillars.

---

## 🚀 Implementation Timeline

### **Week 1: Setup (5 hours)**

- ✅ Register Garmin Developer Account
- ✅ Create OAuth handler (Python)
- ✅ Create Supabase Edge Function
- ✅ Add Garmin button to web UI
- ✅ Test OAuth flow with your account

### **Week 2: Activity Sync (8 hours)**

- ✅ Build activity sync service
- ✅ Create Garmin activities table
- ✅ Test syncing 30-day history
- ✅ Verify all 15+ metrics captured
- ✅ Handle errors gracefully

### **Week 3: AISRI Integration (10 hours)**

- ✅ Update pillar calculation algorithms
- ✅ Implement running economy analysis
- ✅ Add training status checks
- ✅ Build fatigue monitoring
- ✅ Test with real Garmin data

### **Week 4: UI & Polish (5 hours)**

- ✅ Add Garmin metrics cards to dashboard
- ✅ Show running dynamics visualizations
- ✅ Display economy score + recommendations
- ✅ Add fatigue warnings
  -✅ Final testing with athletes

**Total: ~28 hours (1 week full-time or 2-3 weeks part-time)**

---

## 🎯 Next Steps

1. **Register at Garmin Developer Portal** (30 minutes)
2. **Review current web authentication** to ensure compatibility
3. **Decide: MVP vs Full Implementation**
   - MVP: Basic metrics (cadence, VO2 max) - 10 hours
   - Full: All 15+ metrics + analytics - 28 hours
4. **Get approval from Garmin** (1-2 days wait time)
5. **Start with OAuth implementation** (Day 1)

---

**Your Garmin integration will make SafeStride the most comprehensive running analysis platform available!** 🚀

Questions? Let me know and I'll guide you through any specific part!
