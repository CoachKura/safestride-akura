// Modern Deno.serve() pattern for token refresh
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { athleteId } = await req.json()
    
    if (!athleteId) {
      throw new Error('Athlete ID is required')
    }

    console.log('🔄 Refreshing Strava token for athlete:', athleteId)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: connection, error: fetchError } = await supabase
      .from('strava_connections')
      .select('refresh_token')
      .eq('athlete_id', athleteId)
      .single()

    if (fetchError || !connection) {
      throw new Error('Strava connection not found')
    }

    const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: Deno.env.get('STRAVA_CLIENT_ID'),
        client_secret: Deno.env.get('STRAVA_CLIENT_SECRET'),
        refresh_token: connection.refresh_token,
        grant_type: 'refresh_token',
      }),
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      throw new Error('Strava API error: ' + error)
    }

    const tokenData = await tokenResponse.json()
    const expiresAt = new Date(tokenData.expires_at * 1000).toISOString()

    console.log('✅ New tokens received from Strava')

    const { error: updateError } = await supabase
      .from('strava_connections')
      .update({
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq('athlete_id', athleteId)

    if (updateError) {
      throw new Error('Database update error: ' + updateError.message)
    }

    console.log('✅ Updated tokens in database')

    return new Response(
      JSON.stringify({
        success: true,
        access_token: tokenData.access_token,
        expires_at: expiresAt,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Token refresh error:', error.message)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})