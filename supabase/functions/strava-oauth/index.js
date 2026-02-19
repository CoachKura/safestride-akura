// ============================================================================
// Supabase Edge Function: strava-oauth
// Handles Strava OAuth token exchange for web authentication
// Deploy to: Supabase Dashboard → Edge Functions
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRAVA_CLIENT_ID = "162971";
const STRAVA_CLIENT_SECRET = "6554eb9bb83f222a585e312c17420221313f85c1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { code, athleteId } = await req.json();

    if (!code) {
      throw new Error("Authorization code is required");
    }

    console.log("🔄 Exchanging Strava authorization code for tokens...");

    // Step 1: Exchange authorization code for access/refresh tokens
    const tokenResponse = await fetch("https://www.strava.com/oauth/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        code,
        grant_type: "authorization_code",
      }),
    });

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text();
      throw new Error(`Strava token exchange failed: ${error}`);
    }

    const tokenData = await tokenResponse.json();
    console.log("✅ Strava tokens received for athlete:", tokenData.athlete.id);

    // Step 2: Calculate token expiration timestamp
    const expiresAt = new Date(tokenData.expires_at * 1000).toISOString();

    // Step 3: Save connection to Supabase
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    );

    const { data: connection, error: dbError } = await supabaseClient
      .from("strava_connections")
      .upsert(
        {
          athlete_id: athleteId || `strava_${tokenData.athlete.id}`,
          strava_athlete_id: tokenData.athlete.id,
          access_token: tokenData.access_token,
          refresh_token: tokenData.refresh_token,
          expires_at: expiresAt,
          athlete_data: tokenData.athlete,
          updated_at: new Date().toISOString(),
        },
        {
          onConflict: "athlete_id",
        },
      )
      .select()
      .single();

    if (dbError) {
      console.error("❌ Database error:", dbError);
      throw new Error(`Database error: ${dbError.message}`);
    }

    console.log("✅ Strava connection saved to database");

    // Step 4: Return success response
    return new Response(
      JSON.stringify({
        success: true,
        athlete: {
          id: tokenData.athlete.id,
          username: tokenData.athlete.username,
          firstname: tokenData.athlete.firstname,
          lastname: tokenData.athlete.lastname,
          city: tokenData.athlete.city,
          state: tokenData.athlete.state,
          country: tokenData.athlete.country,
          profile: tokenData.athlete.profile,
        },
        connectionId: connection.id,
        message: "Strava connected successfully",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    console.error("❌ Strava OAuth error:", error.message);
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
