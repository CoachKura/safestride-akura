// ============================================================================
// Supabase Edge Function: strava-sync-activities
// Fetches Strava activities and calculates ML/AI AISRI scores
// Deploy to: Supabase Dashboard → Edge Functions
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Load credentials from environment variables (set via: supabase secrets set)
const STRAVA_CLIENT_ID = Deno.env.get("STRAVA_CLIENT_ID") ?? "";
const STRAVA_CLIENT_SECRET = Deno.env.get("STRAVA_CLIENT_SECRET") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { athleteId, daysBack = null } = await req.json();

    if (!athleteId) {
      throw new Error("Athlete ID is required");
    }

    console.log(`🔄 Syncing Strava activities for athlete: ${athleteId}`);

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    );

    // Step 1: Get Strava connection
    const { data: connection, error: connError } = await supabaseClient
      .from("strava_connections")
      .select("*")
      .eq("athlete_id", athleteId)
      .single();

    if (connError || !connection) {
      throw new Error(
        "Strava connection not found. Please connect Strava first.",
      );
    }

    // Step 2: Check if token expired and refresh if needed
    let accessToken = connection.access_token;
    const expiresAt = new Date(connection.expires_at);
    const now = new Date();

    if (expiresAt <= now) {
      console.log("🔄 Refreshing expired Strava token...");
      accessToken = await refreshStravaToken(
        connection.refresh_token,
        supabaseClient,
        athleteId,
      );
    }

    // Step 3: Fetch ALL activities from Strava with pagination
    console.log("📥 Fetching complete activity history from Strava...");
    let allActivities = [];
    let page = 1;
    const perPage = 200; // Maximum allowed by Strava
    let hasMore = true;

    // If daysBack is null, fetch from day 1, otherwise filter
    const afterTimestamp = daysBack
      ? Math.floor(Date.now() / 1000) - daysBack * 24 * 60 * 60
      : 0;

    while (hasMore) {
      const url = `https://www.strava.com/api/v3/athlete/activities?after=${afterTimestamp}&per_page=${perPage}&page=${page}`;

      const activitiesResponse = await fetch(url, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      if (!activitiesResponse.ok) {
        throw new Error(
          `Failed to fetch Strava activities: ${activitiesResponse.statusText}`,
        );
      }

      const activities = await activitiesResponse.json();

      if (activities.length === 0) {
        hasMore = false;
      } else {
        allActivities = allActivities.concat(activities);
        console.log(
          `📄 Page ${page}: Fetched ${activities.length} activities (Total: ${allActivities.length})`,
        );
        page++;

        // Stop if we got less than perPage (means no more pages)
        if (activities.length < perPage) {
          hasMore = false;
        }
      }
    }

    console.log(
      `✅ Fetched ${allActivities.length} total activities from Strava`,
    );

    // Step 4: Calculate personal bests and statistics
    const personalBests = calculatePersonalBests(allActivities);
    const totalDistance = calculateTotalDistance(allActivities);

    console.log(`🏆 Personal Bests:`, personalBests);
    console.log(`📊 Total Distance: ${totalDistance.toFixed(2)} km`);

    // Step 5: Process each activity with ML analysis
    const processedActivities = [];
    const mlInsights = [];

    for (const activity of allActivities) {
      const metrics = calculateActivityMetrics(activity);

      const { data: savedActivity, error: actError } = await supabaseClient
        .from("strava_activities")
        .upsert(
          {
            athlete_id: athleteId,
            strava_activity_id: activity.id,
            activity_data: activity,
            aisri_score: metrics.aisriContribution,
            ml_insights: metrics.insights,
            created_at: activity.start_date,
          },
          {
            onConflict: "strava_activity_id",
          },
        )
        .select()
        .single();

      if (!actError) {
        processedActivities.push(savedActivity);
        mlInsights.push(metrics.insights);
      }
    }

    // Step 6: Calculate aggregate AISRI score
    const aggregateScore = calculateAggregateAISRI(processedActivities);

    // Step 7: Save AISRI score
    const { data: aisriRecord, error: aisriError } = await supabaseClient
      .from("aisri_scores")
      .insert({
        athlete_id: athleteId,
        assessment_date: new Date().toISOString().split("T")[0],
        total_score: aggregateScore.totalScore,
        risk_category: aggregateScore.riskCategory,
        pillar_scores: aggregateScore.pillars,
        ml_insights: {
          summary: aggregateScore.insights,
          activities: mlInsights,
          dataSource: "strava",
          syncedAt: new Date().toISOString(),
          personalBests: personalBests,
          totalDistance: totalDistance,
        },
        strava_data_included: true,
      })
      .select()
      .single();

    console.log("✅ Activities synced and ML analysis complete");

    return new Response(
      JSON.stringify({
        success: true,
        activitiesProcessed: processedActivities.length,
        aisriScore: aggregateScore,
        activities: processedActivities,
        personalBests: personalBests,
        totalDistance: totalDistance,
        athleteProfile: connection.athlete_data,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    console.error("❌ Strava sync error:", error.message);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    );
  }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

async function refreshStravaToken(refreshToken, supabase, athleteId) {
  const response = await fetch("https://www.strava.com/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: STRAVA_CLIENT_ID,
      client_secret: STRAVA_CLIENT_SECRET,
      grant_type: "refresh_token",
      refresh_token: refreshToken,
    }),
  });

  const data = await response.json();
  const expiresAt = new Date(data.expires_at * 1000).toISOString();

  await supabase
    .from("strava_connections")
    .update({
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: expiresAt,
    })
    .eq("athlete_id", athleteId);

  return data.access_token;
}

function calculateActivityMetrics(activity) {
  const distance = activity.distance / 1000; // km
  const duration = activity.moving_time / 60; // minutes
  const avgHR = activity.average_heartrate || 0;
  const maxHR = activity.max_heartrate || 0;
  const elevationGain = activity.total_elevation_gain || 0;
  const pace = duration / distance; // min/km

  const hrVariability =
    maxHR > 0 && avgHR > 0 ? ((maxHR - avgHR) / maxHR) * 100 : 0;

  const insights = {
    trainingLoad: calculateTrainingLoad(distance, duration, avgHR),
    recoveryScore: calculateRecoveryScore(hrVariability, pace),
    performanceIndex: calculatePerformanceIndex(pace, elevationGain, avgHR),
    fatigueLevel: calculateFatigueLevel(duration, avgHR, maxHR),
  };

  const runningScore =
    insights.trainingLoad * 0.3 +
    insights.recoveryScore * 0.3 +
    insights.performanceIndex * 0.2 +
    (100 - insights.fatigueLevel) * 0.2;

  const aisriContribution = runningScore * 0.4; // 40% weight

  return {
    aisriContribution: Math.round(aisriContribution * 100) / 100,
    insights: {
      ...insights,
      distance,
      duration,
      pace: Math.round(pace * 100) / 100,
      avgHR,
      hrVariability: Math.round(hrVariability * 100) / 100,
    },
  };
}

function calculateTrainingLoad(distance, duration, avgHR) {
  const intensityFactor = avgHR > 0 ? avgHR / 180 : 0.5;
  const load = distance * duration * intensityFactor;

  if (load < 50) return 40;
  if (load < 150) return 60;
  if (load < 300) return 80;
  if (load < 500) return 90;
  return 95;
}

function calculateRecoveryScore(hrVariability, pace) {
  let score = hrVariability * 5;
  if (pace > 6.5) score += 10;
  if (pace > 7.0) score += 10;
  return Math.min(Math.max(score, 0), 100);
}

function calculatePerformanceIndex(pace, elevationGain, avgHR) {
  const paceScore = pace < 4.5 ? 100 : pace < 5.5 ? 80 : pace < 6.5 ? 60 : 40;
  const elevationBonus = elevationGain > 200 ? 10 : elevationGain > 100 ? 5 : 0;
  const hrEfficiency = avgHR > 0 && avgHR < 160 ? 10 : 0;
  return Math.min(paceScore + elevationBonus + hrEfficiency, 100);
}

function calculateFatigueLevel(duration, avgHR, maxHR) {
  const durationFatigue = duration > 120 ? 40 : duration > 60 ? 25 : 10;
  const hrFatigue = avgHR > 0 && maxHR > 0 ? (avgHR / maxHR) * 50 : 20;
  return Math.min(durationFatigue + hrFatigue, 100);
}

function calculateAggregateAISRI(activities) {
  if (!activities || activities.length === 0) {
    return {
      totalScore: 0,
      riskCategory: "No Data",
      pillars: {},
      insights: "No activities found",
    };
  }

  const avgRunningScore =
    activities.reduce((sum, act) => sum + (act.aisri_score || 0), 0) /
    activities.length;

  const pillars = {
    running: Math.round(avgRunningScore),
    strength: 70,
    rom: 70,
    balance: 70,
    alignment: 70,
    mobility: 70,
  };

  const totalScore = Math.round(
    pillars.running * 0.4 +
      pillars.strength * 0.15 +
      pillars.rom * 0.12 +
      pillars.balance * 0.13 +
      pillars.alignment * 0.1 +
      pillars.mobility * 0.1,
  );

  let riskCategory = "Critical Risk";
  if (totalScore >= 85) riskCategory = "Very Low Risk";
  else if (totalScore >= 70) riskCategory = "Low Risk";
  else if (totalScore >= 55) riskCategory = "Medium Risk";
  else if (totalScore >= 40) riskCategory = "High Risk";

  return {
    totalScore,
    riskCategory,
    pillars,
    insights: `Analyzed ${activities.length} activities. Running score: ${pillars.running}/100.`,
  };
}

function calculatePersonalBests(activities) {
  const runActivities = activities.filter(
    (a) => a.type === "Run" && a.distance && a.moving_time,
  );

  const distances = {
    "100m": { target: 0.1, tolerance: 0.05 },
    "200m": { target: 0.2, tolerance: 0.05 },
    "400m": { target: 0.4, tolerance: 0.1 },
    "800m": { target: 0.8, tolerance: 0.15 },
    "1km": { target: 1.0, tolerance: 0.2 },
    "1mile": { target: 1.609, tolerance: 0.3 },
    "5km": { target: 5.0, tolerance: 0.5 },
    "10km": { target: 10.0, tolerance: 1.0 },
    "15km": { target: 15.0, tolerance: 1.5 },
    "Half Marathon": { target: 21.0975, tolerance: 2.0 },
    "20 Miler": { target: 32.187, tolerance: 3.0 },
    Marathon: { target: 42.195, tolerance: 4.0 },
  };

  const personalBests = {};

  for (const [distanceName, config] of Object.entries(distances)) {
    const matchingActivities = runActivities.filter((a) => {
      const distanceKm = (a.distance || 0) / 1000;
      return Math.abs(distanceKm - config.target) <= config.tolerance;
    });

    if (matchingActivities.length > 0) {
      const fastest = matchingActivities.reduce((best, current) => {
        const currentPace =
          current.moving_time / ((current.distance || 1) / 1000);
        const bestPace = best.moving_time / ((best.distance || 1) / 1000);
        return currentPace < bestPace ? current : best;
      });

      const timeInSeconds = fastest.moving_time || 0;
      const distanceKm = (fastest.distance || 0) / 1000;
      const pacePerKm = distanceKm > 0 ? timeInSeconds / distanceKm : 0;

      personalBests[distanceName] = {
        time: formatTime(timeInSeconds),
        timeSeconds: timeInSeconds,
        pace: formatPace(pacePerKm),
        paceSeconds: pacePerKm,
        date: fastest.start_date
          ? new Date(fastest.start_date).toISOString().split("T")[0]
          : null,
        activityId: fastest.id,
        distance: distanceKm.toFixed(2) + " km",
      };
    } else {
      personalBests[distanceName] = null;
    }
  }

  // Find longest distance
  if (runActivities.length > 0) {
    const longestRun = runActivities.reduce((longest, current) => {
      return (current.distance || 0) > (longest.distance || 0)
        ? current
        : longest;
    });

    const distanceKm = (longestRun.distance || 0) / 1000;
    personalBests["Longest Distance"] = {
      distance: distanceKm.toFixed(2) + " km",
      date: longestRun.start_date
        ? new Date(longestRun.start_date).toISOString().split("T")[0]
        : null,
      activityId: longestRun.id,
    };
  }

  return personalBests;
}

function calculateTotalDistance(activities) {
  return activities.reduce((total, activity) => {
    return total + (activity.distance || 0) / 1000; // Convert meters to km
  }, 0);
}

function formatTime(seconds) {
  if (!seconds || seconds === 0) return "N/A";

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  }
  return `${minutes}:${String(secs).padStart(2, "0")}`;
}

function formatPace(secondsPerKm) {
  if (!secondsPerKm || secondsPerKm === 0) return "N/A";

  const minutes = Math.floor(secondsPerKm / 60);
  const seconds = Math.floor(secondsPerKm % 60);

  return `${minutes}:${String(seconds).padStart(2, "0")}/km`;
}
