// Supabase Edge Function: strava-refresh-token
// Automatically refreshes expired Strava access tokens
// Deploy to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRAVA_CLIENT_ID = "162971"
const STRAVA_CLIENT_SECRET = "ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { athleteId, refreshToken } = body

    console.log('🔄 Token refresh request for athlete:', athleteId)

    if (!athleteId || !refreshToken) {
      throw new Error('athleteId and refreshToken are required')
    }

    // Exchange refresh token for new access token
    console.log('📡 Calling Strava token refresh API...')
    const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        grant_type: 'refresh_token',
        refresh_token: refreshToken
      }),
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      console.error('❌ Strava token refresh failed:', error)
      throw new Error(`Token refresh failed: ${error}`)
    }

    const tokenData = await tokenResponse.json()
    console.log('✅ New tokens received from Strava')

    // Update database with new tokens
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const expiresAt = new Date(tokenData.expires_at * 1000).toISOString()

    const { error: dbError } = await supabaseClient
      .from('strava_connections')
      .update({
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq('athlete_id', athleteId)

    if (dbError) {
      console.error('❌ Database update error:', dbError)
      throw new Error(`Database error: ${dbError.message}`)
    }

    console.log('✅ Database updated with new tokens')

    return new Response(
      JSON.stringify({
        success: true,
        expires_at: expiresAt,
        message: 'Token refreshed successfully',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Token refresh error:', error)
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
