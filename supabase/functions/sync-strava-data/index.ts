// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function estimateTrainingLoad(activities: Array<Record<string, unknown>>) {
  let totalLoad = 0;
  let totalDistanceKm = 0;
  let totalMovingMin = 0;

  for (const act of activities) {
    const distanceKm = Number(act.distance || 0) / 1000;
    const movingMin = Number(act.moving_time || 0) / 60;
    const avgHr = Number(act.average_heartrate || 140);

    const intensity = Math.max(0.5, Math.min(1.25, avgHr / 160));
    const load = movingMin * intensity;

    totalDistanceKm += distanceKm;
    totalMovingMin += movingMin;
    totalLoad += load;
  }

  return {
    activityCount: activities.length,
    totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
    totalMovingMin: Math.round(totalMovingMin),
    trainingLoad: Math.round(totalLoad),
  };
}

async function refreshTokenIfNeeded(connection: Record<string, unknown>) {
  const expiresAt = connection.expires_at ? new Date(String(connection.expires_at)) : null;
  const isExpired = !expiresAt || expiresAt.getTime() <= Date.now() + 60 * 1000;

  if (!isExpired) {
    return {
      accessToken: String(connection.access_token || ""),
      refreshToken: String(connection.refresh_token || ""),
      expiresAt: String(connection.expires_at || ""),
      refreshed: false,
    };
  }

  const clientId = Deno.env.get("STRAVA_CLIENT_ID") || "";
  const clientSecret = Deno.env.get("STRAVA_CLIENT_SECRET") || "";
  if (!clientId || !clientSecret) {
    throw new Error("Missing STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET for token refresh");
  }

  const resp = await fetch("https://www.strava.com/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: "refresh_token",
      refresh_token: connection.refresh_token,
    }),
  });

  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`Failed to refresh Strava token: ${body}`);
  }

  const data = await resp.json();
  return {
    accessToken: String(data.access_token),
    refreshToken: String(data.refresh_token),
    expiresAt: new Date(Number(data.expires_at) * 1000).toISOString(),
    refreshed: true,
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { success: false, error: "Method not allowed" });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_ANON_KEY") || "";
    if (!supabaseUrl || !serviceRoleKey) {
      return json(500, { success: false, error: "Missing Supabase environment variables" });
    }

    const { userId, daysBack = 14 } = await req.json();
    if (!userId) return json(400, { success: false, error: "userId is required" });

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: connByAthleteId } = await supabase
      .from("strava_connections")
      .select("*")
      .eq("athlete_id", userId)
      .maybeSingle();

    const connection = connByAthleteId;
    if (!connection) {
      return json(404, { success: false, error: "No Strava connection found for this user" });
    }

    const tokenInfo = await refreshTokenIfNeeded(connection);
    if (tokenInfo.refreshed) {
      await supabase
        .from("strava_connections")
        .update({
          access_token: tokenInfo.accessToken,
          refresh_token: tokenInfo.refreshToken,
          expires_at: tokenInfo.expiresAt,
          updated_at: new Date().toISOString(),
        })
        .eq("athlete_id", userId);
    }

    const afterTimestamp = Math.floor(Date.now() / 1000) - Number(daysBack) * 24 * 60 * 60;
    const stravaResp = await fetch(
      `https://www.strava.com/api/v3/athlete/activities?after=${afterTimestamp}&per_page=100`,
      { headers: { Authorization: `Bearer ${tokenInfo.accessToken}` } },
    );

    if (!stravaResp.ok) {
      const body = await stravaResp.text();
      return json(502, { success: false, error: "Failed fetching Strava activities", details: body });
    }

    const activities = (await stravaResp.json()) as Array<Record<string, unknown>>;
    const training = estimateTrainingLoad(activities);

    for (const activity of activities) {
      await supabase.from("strava_activities").upsert(
        {
          athlete_id: userId,
          strava_activity_id: activity.id,
          activity_data: activity,
          aisri_score: Math.min(100, Math.round((training.trainingLoad / Math.max(1, training.activityCount)) * 1.2)),
          ml_insights: {
            trainingLoad: training.trainingLoad,
            distanceKm: training.totalDistanceKm,
            movingMinutes: training.totalMovingMin,
            computedAt: new Date().toISOString(),
          },
          created_at: String(activity.start_date || new Date().toISOString()),
        },
        { onConflict: "strava_activity_id" },
      );
    }

    await supabase
      .from("profiles")
      .update({
        strava_connected: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);

    await supabase
      .from("athlete_onboarding_status")
      .upsert(
        {
          user_id: userId,
          strava_synced_at: new Date().toISOString(),
          current_step: "generating_plan",
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );

    return json(200, {
      success: true,
      tokenRefreshed: tokenInfo.refreshed,
      training,
    });
  } catch (error) {
    return json(500, {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
