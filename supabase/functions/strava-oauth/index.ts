// Supabase Edge Function: strava-oauth
// Deploy this to handle Strava OAuth token exchange
// Path: supabase/functions/strava-oauth/index.ts

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
    const { code, athleteId } = body

    console.log('📥 OAuth request received:', { 
      hasCode: !!code, 
      athleteId: athleteId || 'not provided',
      bodyKeys: Object.keys(body)
    })

    if (!code) {
      throw new Error('Authorization code is required')
    }

    console.log('🔄 Exchanging Strava authorization code...')

    // Step 1: Exchange code for tokens
    const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        code,
        grant_type: 'authorization_code',
      }),
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      console.error('❌ Strava token exchange failed:', error)
      throw new Error(`Strava token exchange failed: ${error}`)
    }

    const tokenData = await tokenResponse.json()
    console.log('✅ Strava tokens received for athlete:', tokenData.athlete?.id)

    // Step 2: Calculate expiration timestamp
    const expiresAt = new Date(tokenData.expires_at * 1000).toISOString()

    // Step 3: Save to Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const upsertData = {
      athlete_id: athleteId || `strava_${tokenData.athlete.id}`,
      strava_athlete_id: tokenData.athlete.id,
      access_token: tokenData.access_token,
      refresh_token: tokenData.refresh_token,
      expires_at: expiresAt,
      athlete_data: tokenData.athlete,
      updated_at: new Date().toISOString(),
    }

    console.log('💾 Saving to database with athlete_id:', upsertData.athlete_id)

    const { data: connection, error: dbError } = await supabaseClient
      .from('strava_connections')
      .upsert(upsertData, {
        onConflict: 'athlete_id'
      })
      .select()
      .single()

    if (dbError) {
      console.error('❌ Database error:', dbError)
      throw new Error(`Database error: ${dbError.message}`)
    }

    console.log('✅ Strava connection saved to database')

    return new Response(
      JSON.stringify({
        success: true,
        athlete: tokenData.athlete,
        connectionId: connection.id,
        message: 'Strava connected successfully',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Strava OAuth error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        details: error.toString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
