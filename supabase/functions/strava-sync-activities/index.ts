// Supabase Edge Function: strava-sync-activities
// Fetches activities from Strava and calculates AISRI scores with ML/AI
// Path: supabase/functions/strava-sync-activities/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { athleteId, daysBack = 30 } = await req.json()

    if (!athleteId) {
      throw new Error('Athlete ID is required')
    }

    console.log(`🔄 Syncing Strava activities for athlete: ${athleteId}`)

    // Step 1: Get Strava connection
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const { data: connection, error: connError } = await supabaseClient
      .from('strava_connections')
      .select('*')
      .eq('athlete_id', athleteId)
      .single()

    if (connError || !connection) {
      throw new Error('Strava connection not found. Please connect Strava first.')
    }

    // Step 2: Check if token is expired and refresh if needed
    let accessToken = connection.access_token
    const expiresAt = new Date(connection.expires_at)
    const now = new Date()

    if (expiresAt <= now) {
      console.log('🔄 Refreshing expired Strava token...')
      accessToken = await refreshStravaToken(connection.refresh_token, supabaseClient, athleteId)
    }

    // Step 3: Fetch activities from Strava
    const afterTimestamp = Math.floor(Date.now() / 1000) - (daysBack * 24 * 60 * 60)
    
    const activitiesResponse = await fetch(
      `https://www.strava.com/api/v3/athlete/activities?after=${afterTimestamp}&per_page=100`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      }
    )

    if (!activitiesResponse.ok) {
      throw new Error(`Failed to fetch Strava activities: ${activitiesResponse.statusText}`)
    }

    const activities = await activitiesResponse.json()
    console.log(`✅ Fetched ${activities.length} activities from Strava`)

    // Step 4: Calculate ML/AI scores for each activity
    const processedActivities = []
    const mlInsights = []

    for (const activity of activities) {
      // Calculate AISRI metrics from activity data
      const metrics = calculateActivityMetrics(activity)
      
      // Save to database
      const { data: savedActivity, error: actError } = await supabaseClient
        .from('strava_activities')
        .upsert({
          athlete_id: athleteId,
          strava_activity_id: activity.id,
          activity_data: activity,
          aisri_score: metrics.aisriContribution,
          ml_insights: metrics.insights,
          created_at: activity.start_date,
        }, {
          onConflict: 'strava_activity_id'
        })
        .select()
        .single()

      if (!actError) {
        processedActivities.push(savedActivity)
        mlInsights.push(metrics.insights)
      }
    }

    // Step 5: Calculate aggregate AISRI score
    const aggregateScore = calculateAggregateAISRI(processedActivities)

    // Step 6: Save overall AISRI score
    const { data: aisriRecord, error: aisriError } = await supabaseClient
      .from('aisri_scores')
      .insert({
        athlete_id: athleteId,
        assessment_date: new Date().toISOString().split('T')[0],
        total_score: aggregateScore.totalScore,
        risk_category: aggregateScore.riskCategory,
        pillar_scores: aggregateScore.pillars,
        ml_insights: {
          summary: aggregateScore.insights,
          activities: mlInsights,
          dataSource: 'strava',
          syncedAt: new Date().toISOString(),
        },
        strava_data_included: true,
      })
      .select()
      .single()

    if (aisriError) {
      console.error('Warning: Could not save AISRI score:', aisriError.message)
    }

    console.log('✅ Activities synced and ML analysis complete')

    return new Response(
      JSON.stringify({
        success: true,
        activitiesProcessed: processedActivities.length,
        aisriScore: aggregateScore,
        activities: processedActivities,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Strava sync error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

// Helper: Refresh Strava token
async function refreshStravaToken(refreshToken, supabase, athleteId) {
  const response = await fetch('https://www.strava.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: "162971",
      client_secret: "ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626",
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }),
  })

  const data = await response.json()
  const expiresAt = new Date(data.expires_at * 1000).toISOString()

  await supabase
    .from('strava_connections')
    .update({
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: expiresAt,
    })
    .eq('athlete_id', athleteId)

  return data.access_token
}

// Helper: Calculate metrics from single activity
function calculateActivityMetrics(activity) {
  // Extract key metrics
  const distance = activity.distance / 1000 // km
  const duration = activity.moving_time / 60 // minutes
  const avgHR = activity.average_heartrate || 0
  const maxHR = activity.max_heartrate || 0
  const elevationGain = activity.total_elevation_gain || 0
  const pace = duration / distance // min/km
  
  // Calculate HRV proxy (if HR data available)
  const hrVariability = maxHR > 0 && avgHR > 0 ? ((maxHR - avgHR) / maxHR) * 100 : 0

  // ML Pattern Detection
  const insights = {
    trainingLoad: calculateTrainingLoad(distance, duration, avgHR),
    recoveryScore: calculateRecoveryScore(hrVariability, pace),
    performanceIndex: calculatePerformanceIndex(pace, elevationGain, avgHR),
    fatigueLevel: calculateFatigueLevel(duration, avgHR, maxHR),
  }

  // AISRI contribution (Running pillar = 40% of total)
  const runningScore = (
    insights.trainingLoad * 0.3 +
    insights.recoveryScore * 0.3 +
    insights.performanceIndex * 0.2 +
    (100 - insights.fatigueLevel) * 0.2
  )

  const aisriContribution = runningScore * 0.4 // 40% weight for Running pillar

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
  }
}

// ML Calculation: Training Load
function calculateTrainingLoad(distance, duration, avgHR) {
  const intensityFactor = avgHR > 0 ? avgHR / 180 : 0.5 // Normalized
  const load = distance * duration * intensityFactor
  
  // Score 0-100
  if (load < 50) return 40 // Very light
  if (load < 150) return 60 // Light
  if (load < 300) return 80 // Moderate
  if (load < 500) return 90 // Hard
  return 95 // Very hard
}

// ML Calculation: Recovery Score
function calculateRecoveryScore(hrVariability, pace) {
  // Higher HRV = better recovery
  let score = hrVariability * 5 // Scale to 0-100
  
  // Slower pace during easy run = better recovery
  if (pace > 6.5) score += 10 // Easy pace bonus
  if (pace > 7.0) score += 10 // Very easy bonus
  
  return Math.min(Math.max(score, 0), 100)
}

// ML Calculation: Performance Index
function calculatePerformanceIndex(pace, elevationGain, avgHR) {
  // Faster pace = higher performance
  const paceScore = pace < 4.5 ? 100 : pace < 5.5 ? 80 : pace < 6.5 ? 60 : 40
  
  // Elevation handling = performance indicator
  const elevationBonus = elevationGain > 200 ? 10 : elevationGain > 100 ? 5 : 0
  
  // HR efficiency
  const hrEfficiency = avgHR > 0 && avgHR < 160 ? 10 : 0
  
  return Math.min(paceScore + elevationBonus + hrEfficiency, 100)
}

// ML Calculation: Fatigue Level
function calculateFatigueLevel(duration, avgHR, maxHR) {
  // Longer duration + higher HR = more fatigue
  const durationFatigue = duration > 120 ? 40 : duration > 60 ? 25 : 10
  const hrFatigue = avgHR > 0 && maxHR > 0 ? ((avgHR / maxHR) * 50) : 20
  
  return Math.min(durationFatigue + hrFatigue, 100)
}

// Helper: Calculate aggregate AISRI from all activities
function calculateAggregateAISRI(activities) {
  if (!activities || activities.length === 0) {
    return {
      totalScore: 0,
      riskCategory: 'No Data',
      pillars: {},
      insights: 'No activities found',
    }
  }

  // Average AISRI contribution from all activities
  const avgRunningScore = activities.reduce((sum, act) => 
    sum + (act.aisri_score || 0), 0) / activities.length

  // For demo: Other pillars at baseline 70
  const pillars = {
    running: Math.round(avgRunningScore),
    strength: 70,
    rom: 70,
    balance: 70,
    alignment: 70,
    mobility: 70,
  }

  // Weighted total
  const totalScore = Math.round(
    pillars.running * 0.40 +
    pillars.strength * 0.15 +
    pillars.rom * 0.12 +
    pillars.balance * 0.13 +
    pillars.alignment * 0.10 +
    pillars.mobility * 0.10
  )

  // Risk category
  let riskCategory = 'Critical Risk'
  if (totalScore >= 85) riskCategory = 'Very Low Risk'
  else if (totalScore >= 70) riskCategory = 'Low Risk'
  else if (totalScore >= 55) riskCategory = 'Medium Risk'
  else if (totalScore >= 40) riskCategory = 'High Risk'

  return {
    totalScore,
    riskCategory,
    pillars,
    insights: `Analyzed ${activities.length} activities. Running score: ${pillars.running}/100.`,
  }
}
