// ============================================================================
// Supabase Edge Function: strava-callback
// Handles OAuth redirect from Strava (GET with query params)
// Deploy: Supabase Dashboard → Edge Functions → Deploy
// Redirect URI: https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-callback
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STRAVA_CLIENT_ID = Deno.env.get("STRAVA_CLIENT_ID") ?? "";
const STRAVA_CLIENT_SECRET = Deno.env.get("STRAVA_CLIENT_SECRET") ?? "";

serve(async (req) => {
  try {
    const url = new URL(req.url);
    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");

    if (!code) {
      return new Response("Missing authorization code", { status: 400 });
    }

    console.log(`OAuth callback: athlete ${state}`);

    const tokenResponse = await fetch("https://www.strava.com/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        code,
        grant_type: "authorization_code",
      }),
    });

    if (!tokenResponse.ok) {
      throw new Error(`Token exchange failed: ${await tokenResponse.text()}`);
    }

    const tokenData = await tokenResponse.json();
    const expiresAt = new Date(tokenData.expires_at * 1000).toISOString();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_KEY") ?? "",
    );

    await supabase.from("strava_connections").upsert({
      athlete_id: state || `strava_${tokenData.athlete.id}`,
      strava_athlete_id: tokenData.athlete.id,
      access_token: tokenData.access_token,
      refresh_token: tokenData.refresh_token,
      expires_at: expiresAt,
      athlete_data: tokenData.athlete,
      updated_at: new Date().toISOString(),
    }, { onConflict: "athlete_id" });

    return new Response(`<!DOCTYPE html>
<html><head><title>Connected</title></head>
<body><h1>✅ Connected to Strava</h1>
<p>Athlete: ${tokenData.athlete.firstname} ${tokenData.athlete.lastname}</p>
<p>Close this window.</p>
<script>
if (window.opener) {
  window.opener.postMessage({type:"strava_connected",athlete_id:"${state}"},"*");
  setTimeout(() => window.close(), 2000);
}
</script></body></html>`, {
      status: 200,
      headers: { "Content-Type": "text/html" },
    });
  } catch (error) {
    return new Response(`<!DOCTYPE html>
<html><head><title>Failed</title></head>
<body><h1>❌ Connection Failed</h1><p>${error.message}</p></body></html>`, {
      status: 500,
      headers: { "Content-Type": "text/html" },
    });
  }
});
